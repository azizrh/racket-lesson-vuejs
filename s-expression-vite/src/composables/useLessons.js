// composables/useLessons.js
import { ref, computed } from 'vue'
import { marked } from 'marked'

export function useLessons(api, auth) {
  // State
  const lessons = ref([])
  const lessonIdx = ref(0)
  const selectedLessonId = ref(null)
  const lessonBodyHtml = ref("")
  const lessonsLoading = ref(false)
  const lessonsError = ref(null)
  const currentView = ref("home")

  // Computed
  const hasMultipleLessons = computed(() => lessons.value.length > 1)
  
  const currentLesson = computed(() => lessons.value[lessonIdx.value] || null)
  
  const lessonIds = computed(() => lessons.value.map(l => Number(l.id)))
  
  const minLessonId = computed(() => 
    lessonIds.value.length ? Math.min(...lessonIds.value) : null
  )
  
  const maxLessonId = computed(() => 
    lessonIds.value.length ? Math.max(...lessonIds.value) : null
  )
  
  const atFirstLesson = computed(() => 
    !!(currentLesson.value && currentLesson.value.id === minLessonId.value)
  )
  
  const atLastLesson = computed(() => 
    !!(currentLesson.value && currentLesson.value.id === maxLessonId.value)
  )

  // Methods
  const goHome = () => {
    currentView.value = "home"
  }

  const hasAccessToLesson = (id) => {
    return !!auth.user.value?.lessons?.includes(Number(id))
  }

  const nextLessonId = () => {
    if (!lessons.value.length) return null
    const ordered = lessons.value.map(l => l.id)
    const curId = currentLesson.value?.id
    const i = ordered.indexOf(curId)
    return i >= 0 && i < ordered.length - 1 ? ordered[i + 1] : null
  }

  const cleanProblemText = (raw) => {
    if (typeof raw !== "string") return ""
    return raw.replaceAll("\\n", "\n").trim()
  }

  const setLessonBody = (md) => {
    lessonBodyHtml.value = marked.parse(md || "")
  }

  const loadLessonsData = async () => {
    lessonsLoading.value = true
    lessonsError.value = null

    try {
      const lessonsList = await api.listLessons()

      // Enrich lessons with problem counts and estimated times
      for (const lesson of lessonsList) {
        try {
          const problems = await api.loadProblems(lesson.id)
          lesson.problem_count = problems.length
          lesson.estimated_time = Math.max(5, Math.ceil(problems.length * 2.5))
        } catch (e) {
          lesson.problem_count = 0
          lesson.estimated_time = 15
        }
      }

      lessons.value = lessonsList
    } catch (err) {
      console.error("Failed to load lessons:", err)
      lessonsError.value = err.message || "Failed to load lessons"
    } finally {
      lessonsLoading.value = false
    }
  }

  const setLessonById = async (id) => {
    const idx = lessons.value.findIndex(l => l.id === Number(id))
    if (idx >= 0) {
      await setLessonByIndex(idx)
    }
  }

  const setLessonByIndex = async (newIdx) => {
    if (!lessons.value.length) return
    if (newIdx < 0 || newIdx > lessons.value.length - 1) return
    
    const target = lessons.value[newIdx]
    
    if (!hasAccessToLesson(target.id)) {
      // This would need to be handled by parent component for result display
      throw new Error("🔒 Next lesson is locked. Get 3 correct in a row to unlock.")
    }

    lessonIdx.value = newIdx
    selectedLessonId.value = String(target.id)
    const freshLesson = await api.loadLesson(target.id)
    setLessonBody(cleanProblemText(freshLesson.body_md) || "")
    
    return target
  }

  const bootstrapLessons = async () => {
    try {
      lessons.value = await api.listLessons()
      if (lessons.value.length) {
        const preferredId = auth.user.value?.active_lesson || lessons.value[0].id
        selectedLessonId.value = String(preferredId)
        await setLessonById(preferredId)
      } else {
        throw new Error("No lessons found. Please add one in the database.")
      }
    } catch (err) {
      console.error(err)
      throw err
    }
  }

  const startLesson = async (lessonId) => {
    currentView.value = "practice"
    await setLessonById(lessonId)
  }

  return {
    // State
    lessons,
    lessonIdx,
    selectedLessonId,
    lessonBodyHtml,
    lessonsLoading,
    lessonsError,
    currentView,
    
    // Computed
    hasMultipleLessons,
    currentLesson,
    atFirstLesson,
    atLastLesson,
    
    // Methods
    goHome,
    hasAccessToLesson,
    nextLessonId,
    cleanProblemText,
    setLessonBody,
    loadLessonsData,
    setLessonById,
    setLessonByIndex,
    bootstrapLessons,
    startLesson,
  }
}