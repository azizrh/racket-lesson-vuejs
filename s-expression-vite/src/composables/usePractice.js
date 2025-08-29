// composables/usePractice.js
import { ref, computed, nextTick } from 'vue'

export function usePractice(api, auth, lessons) {
    // State
    const problems = ref([])
    const problemIdx = ref(0)
    const successCount = ref(0)
    const answer = ref("")
    const resultVisible = ref(false)
    const resultOk = ref(false)
    const resultMessage = ref("")
    const showModal = ref(false)
    const showRevealConfirm = ref(false)
    const revealedById = ref({})
    const advanceOnCorrect = ref(true)
    const advanceDelayMs = ref(1500)
    const revealDelayMs = ref(3000)
    const advanceTimerId = ref(null)
    const isLoadingNext = ref(false)

    // Computed
    const currentProblem = computed(() => problems.value[problemIdx.value] || null)

    const isRevealed = computed(() =>
        !!(currentProblem.value && revealedById.value[currentProblem.value.id])
    )

    const prevDisabled = computed(() =>
        !lessons.hasMultipleLessons.value || lessons.atFirstLesson.value
    )

    const nextDisabled = computed(() => {
        const nextId = lessons.nextLessonId()
        return (
            !lessons.hasMultipleLessons.value ||
            lessons.atLastLesson.value ||
            (nextId !== null && !lessons.hasAccessToLesson(nextId))
        )
    })

    // Methods
    const clearAdvanceTimer = () => {
        if (advanceTimerId.value) {
            clearTimeout(advanceTimerId.value)
            advanceTimerId.value = null
        }
    }

    const setResult = (ok, msg) => {
        resultOk.value = !!ok
        resultMessage.value = (ok ? "✅ " : "❌ ") + (msg || "")
        resultVisible.value = true
    }

    const hideResult = () => {
        resultVisible.value = false
    }

    const showProblem = () => {
        clearAdvanceTimer()
        answer.value = ""
        hideResult()
        nextTick(() => {
            // Focus would be handled by parent component
        })
    }

    const nextProblem = () => {
        if (!problems.value.length) return
        clearAdvanceTimer()
        problemIdx.value = (problemIdx.value + 1) % problems.value.length
        showProblem()
    }

    const loadProblemsForLesson = async (lessonId) => {
        problems.value = await api.loadProblems(lessonId)
        problemIdx.value = 0
        successCount.value = 0
        showProblem()
    }

    const check = async () => {
        if (auth.showLogin.value) return
        if (isRevealed.value) {
            setResult(false, "You revealed this one. Try the next problem.")
            return
        }

        const input = (answer.value || "").trim()
        if (!input) {
            setResult(false, "Type your answer first")
            return
        }

        // if (input!=answer.answer_text){
        //     let msg = res.error || "Incorrect."
        //     if (res.details && res.details.failures) {
        //       const f = res.details.failures[0]
        //       if (f && f.expr) msg += `\nFailed test: ${f.expr}`
        //     }
        //     setResult(false, msg)
        //     return
        // }

        try {

            const p = currentProblem.value
            const exact_answer = currentProblem.value.answer_text

            if (!p) {
                setResult(false, "No problem selected")
                return
            }


            const res = await api.backendValidate(p.id, input)
            await api.recordAttempt(auth.username.value, p.id, input, res)

            console.log(input, exact_answer, input == exact_answer)
            if (res.ok && input == exact_answer) {
                const stage = res.stage ? ` (${res.stage})` : ""
                setResult(true, "Correct!" + stage)
                successCount.value++
                if (successCount.value >= 3) showModal.value = true

                if (advanceOnCorrect.value) {
                    clearAdvanceTimer()
                    isLoadingNext.value = true
                    advanceTimerId.value = setTimeout(() => {
                        if (!showModal.value && !auth.showLogin.value) nextProblem()
                        isLoadingNext.value = false
                        clearAdvanceTimer()
                    }, advanceDelayMs.value)
                }
            }
            else if (res.ok && input != exact_answer) {
                let msg = "Incorrect format."
                setResult(false, msg)
            } else {
                let msg = res.error || "Incorrect."
                if (res.details && res.details.failures) {
                    const f = res.details.failures[0]
                    if (f && f.expr) msg += `\nFailed test: ${f.expr}`
                }
                setResult(false, msg)
            }
        } catch (e) {
            setResult(false, e.message || "Backend validation failed.")
        }
    }

    const reveal = () => {
        if (auth.showLogin.value || isRevealed.value) return
        showRevealConfirm.value = true
    }

    const confirmReveal = async () => {
        showRevealConfirm.value = false
        const p = currentProblem.value
        const ans = p?.answer_text || "N/A"
        if (p) {
            revealedById.value[p.id] = true
        }
        setResult(
            true,
            "Answer: " + ans + " — (This problem is marked as revealed and won't count toward your streak)"
        )
        isLoadingNext.value = true
        advanceTimerId.value = setTimeout(() => {
            if (!showModal.value && !auth.showLogin.value) nextProblem()
            isLoadingNext.value = false
            clearAdvanceTimer()
        }, revealDelayMs.value)
    }

    const cancelReveal = () => {
        showRevealConfirm.value = false
    }

    const confirmAdvanceLesson = async () => {
        showModal.value = false
        if (!auth.username.value) {
            setResult(false, "Please sign in first.")
            return
        }

        try {
            const updated = await api.advanceUser(auth.username.value)
            auth.setUser(updated)
            successCount.value = 0
            if (updated.active_lesson) {
                await lessons.setLessonById(updated.active_lesson)
                setResult(true, "Next lesson unlocked!")
            }
        } catch (e) {
            setResult(false, e?.message || "Could not advance to next lesson.")
        }
    }

    const resetStreakAndStay = () => {
        successCount.value = 0
        showModal.value = false
    }

    return {
        // State
        problems,
        problemIdx,
        successCount,
        answer,
        resultVisible,
        resultOk,
        resultMessage,
        showModal,
        showRevealConfirm,
        revealedById,
        isLoadingNext,

        // Computed
        currentProblem,
        isRevealed,
        prevDisabled,
        nextDisabled,

        // Methods
        clearAdvanceTimer,
        setResult,
        hideResult,
        showProblem,
        nextProblem,
        loadProblemsForLesson,
        check,
        reveal,
        confirmReveal,
        cancelReveal,
        confirmAdvanceLesson,
        resetStreakAndStay,
    }
}