// composables/useReview.js
import { ref, watch } from 'vue'

export function useReview(api, auth, lessons) {
  // State
  const showReview = ref(false)
  const currentProblemForReview = ref(null)
  const reviewAnswer = ref("")
  const reviewIsRevealed = ref(false)
  const reviewLoading = ref(false)
  const reviewResultVisible = ref(false)
  const reviewResultOk = ref(false)
  const reviewResultMessage = ref("")
  const reviewTickerId = ref(null)
  const reviewMinMs = ref(60_000) // 1 min
  const reviewMaxMs = ref(180_000) // 3 min
  const reviewBtnLoading = ref(false)
  const problemsCache = ref(Object.create(null))

  // Auto-close delay after correct
  const reviewAutoCloseMs = ref(800)
  const reviewAutoCloseTimer = ref(null)
  const clearAutoClose = () => {
    if (reviewAutoCloseTimer.value) {
      clearTimeout(reviewAutoCloseTimer.value)
      reviewAutoCloseTimer.value = null
    }
  }

  // Watchers
  watch([() => lessons.currentView.value, () => auth.showLogin.value, () => auth.username.value], () => {
    maybeStartRandomReviewTicker()
  })

  watch(showReview, (val) => {
    if (val) {
      cancelRandomReviewTicker()
    } else {
      clearAutoClose()
      maybeStartRandomReviewTicker()
    }
  })

  // Methods
  const randInt = (min, max) => {
    return Math.floor(Math.random() * (max - min + 1)) + min
  }

  const getProblemsCached = async (lessonId) => {
    if (problemsCache.value[lessonId]) return problemsCache.value[lessonId]
    const probs = await api.loadProblems(lessonId).catch(() => [])
    problemsCache.value[lessonId] = probs
    return probs
  }

  const showReviewFromScheduleIfDue = async () => {
    // don't interrupt modals or existing review
    if (auth.showLogin.value || showReview.value) return
    if (!auth.username.value) return

    const next = await api.fetchNextReviewByUsername(auth.username.value)
    if (!next) return

    const now = Date.now()
    const due = new Date(next.due_at).getTime()
    if (due > now) return // not due yet

    const lessonId = next.lesson_id ?? auth.user.value?.active_lesson ?? lessons.lessons.value[0]?.id
    if (!lessonId) return

    const probs = await getProblemsCached(lessonId)
    if (!probs?.length) return

    const problem = probs[Math.floor(Math.random() * probs.length)]
    openReview(problem)
  }

  const scheduleRandomReviewTicker = () => {
    cancelRandomReviewTicker()
    const delay = randInt(reviewMinMs.value, reviewMaxMs.value)
    reviewTickerId.value = setTimeout(async () => {
      await showReviewFromScheduleIfDue()
      scheduleRandomReviewTicker() // schedule next check
    }, delay)
  }

  const cancelRandomReviewTicker = () => {
    if (reviewTickerId.value) {
      clearTimeout(reviewTickerId.value)
      reviewTickerId.value = null
    }
  }

  const maybeStartRandomReviewTicker = () => {
    if (lessons.currentView.value === "home" && auth.username.value && !auth.showLogin.value && !showReview.value) {
      if (!reviewTickerId.value) scheduleRandomReviewTicker()
    } else {
      cancelRandomReviewTicker()
    }
  }

  const openReview = (problem) => {
    currentProblemForReview.value = problem
    reviewAnswer.value = ""
    reviewIsRevealed.value = false
    reviewResultVisible.value = false
    reviewResultOk.value = false
    reviewResultMessage.value = ""
    showReview.value = true
  }

  const handleReviewCheck = async () => {
    if (reviewLoading.value) return
    if (!currentProblemForReview.value) return

    const text = (reviewAnswer.value || "").trim()
    if (!text) {
      reviewResultVisible.value = true
      reviewResultOk.value = false
      reviewResultMessage.value = "Type your answer first"
      return
    }

    clearAutoClose()

    try {
      reviewLoading.value = true

      // validate
      const res = await api.backendValidate(currentProblemForReview.value.id, text)
      const ok = !!res?.ok

      // RECORD ATTEMPT (positional signature as provided)
      try {
        await api.recordAttempt(
          auth.username.value,
          currentProblemForReview.value.id,
          text,
          res,                // <-- full backend result object
          "review"
        )
      } catch (recErr) {
        console.warn("recordAttempt failed:", recErr)
      }

      // show result
      reviewResultVisible.value = true
      reviewResultOk.value = ok
      reviewResultMessage.value = ok
        ? "✅ Correct!"
        : "❌ " + (res?.error || "Incorrect.")

      // auto-close on correct
      if (ok) {
        reviewAutoCloseTimer.value = setTimeout(() => {
          showReview.value = false
        }, reviewAutoCloseMs.value)
      }
    } catch (e) {
      const msg = e?.message || "Validation failed."

      reviewResultVisible.value = true
      reviewResultOk.value = false
      reviewResultMessage.value = msg

      // still record the failed attempt so nothing is lost
      try {
        await api.recordAttempt(
          auth.username.value,
          currentProblemForReview.value?.id,
          text,
          { ok: false, error: msg, details: null }, // shape compatible with your API
          "review"
        )
      } catch (recErr) {
        console.warn("recordAttempt (error path) failed:", recErr)
      }
    } finally {
      reviewLoading.value = false
    }
  }

  const handleReviewReveal = () => {
    if (!currentProblemForReview.value) return
    reviewIsRevealed.value = true
    const ans = currentProblemForReview.value?.answer_text || "N/A"
    reviewResultVisible.value = true
    reviewResultOk.value = true
    reviewResultMessage.value = "Answer: " + ans + " — (This problem is marked as revealed and won't count toward your streak)"
    // If you also want to auto-close on reveal, uncomment:
    // clearAutoClose()
    // reviewAutoCloseTimer.value = setTimeout(() => { showReview.value = false }, reviewAutoCloseMs.value)
  }

  const triggerReviewNow = async () => {
    if (auth.showLogin.value) return auth.openLogin()
    if (!auth.username.value) return auth.openLogin()

    reviewBtnLoading.value = true
    try {
      const next = await api.fetchNextReviewByUsername(auth.username.value)
      const fallback = auth.user.value?.active_lesson ?? lessons.lessons.value[0]?.id ?? null
      const lessonId = next?.lesson_id ?? fallback
      if (!lessonId) {
        throw new Error("No lessons available to review.")
      }
      const probs = await getProblemsCached(lessonId)
      if (!probs?.length) {
        throw new Error("No problems found for the selected lesson.")
      }
      const problem = probs[Math.floor(Math.random() * probs.length)]
      openReview(problem)
    } catch (e) {
      console.error(e)
      throw e
    } finally {
      reviewBtnLoading.value = false
    }
  }

  return {
    // State
    showReview,
    currentProblemForReview,
    reviewAnswer,
    reviewIsRevealed,
    reviewLoading,
    reviewResultVisible,
    reviewResultOk,
    reviewResultMessage,
    reviewBtnLoading,

    // Methods
    openReview,
    handleReviewCheck,
    handleReviewReveal,
    triggerReviewNow,
    maybeStartRandomReviewTicker,
    cancelRandomReviewTicker,
    scheduleRandomReviewTicker,
  }
}
