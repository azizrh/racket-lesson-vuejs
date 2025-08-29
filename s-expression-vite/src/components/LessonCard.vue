<template>
  <section class="card" id="lessonCard">
    <header>
      <div class="flex items-center justify-between">
        <h2 class="m-0 text-[18px] font-semibold">Lesson</h2>
      </div>

      <div class="flex items-center gap-2 mt-2">
        <button
          class="btn secondary"
          :disabled="prevDisabled"
          @click="$emit('setLessonByIndex', lessonIdx - 1)"
        >
          ◀ Prev lesson
        </button>
        <select
          aria-label="Choose lesson"
          :value="selectedLessonId"
          @change="$emit('setLessonById', $event.target.value)"
        >
          <option
            v-for="l in lessons"
            :key="l.id"
            :value="String(l.id)"
            :disabled="!hasAccessToLesson(l.id)"
          >
            {{
              (hasAccessToLesson(l.id) ? "" : "🔒 ") +
              `${l.title} (ID ${l.id})`
            }}
          </option>
        </select>
        <button
          class="btn secondary"
          :disabled="nextDisabled"
          @click="$emit('setLessonByIndex', lessonIdx + 1)"
        >
          Next lesson ▶
        </button>
      </div>
    </header>
    <div class="content">
      <div class="grid gap-3">
        <div class="lesson-display" v-html="lessonBodyHtml"></div>
      </div>
    </div>
  </section>
</template>

<script>
export default {
  name: 'LessonCard',
  props: {
    lessons: Array,
    lessonIdx: Number,
    selectedLessonId: String,
    lessonBodyHtml: String,
    prevDisabled: Boolean,
    nextDisabled: Boolean,
    user: Object, // Add user prop to check access
  },
  emits: ['setLessonByIndex', 'setLessonById'],
  methods: {
    hasAccessToLesson(id) {
      return !!this.user?.lessons?.includes(Number(id))
    }
  }
}
</script>