<template>
  <main
    :style="
      showLogin
        ? 'filter: blur(2px); pointer-events:none; user-select:none;'
        : ''
    "
  >
    <!-- <div
      style="
        background: #000000;
        padding: 10px;
        margin: 10px;
        border-radius: 4px;
        font-family: monospace;
      "
    >
      <strong>Debug Info:</strong><br />
      currentProblem: {{ currentProblem }}<br />
    </div> -->
    <!-- LEFT: Lesson text -->
    <LessonCard
      :lessons="lessons"
      :lesson-idx="lessonIdx"
      :selected-lesson-id="selectedLessonId"
      :lesson-body-html="lessonBodyHtml"
      :prev-disabled="prevDisabled"
      :next-disabled="nextDisabled"
      :user="user"
      @set-lesson-by-index="$emit('setLessonByIndex', $event)"
      @set-lesson-by-id="$emit('setLessonById', $event)"
    />

    <!-- RIGHT: Problems & validator -->
    <ProblemCard
      :current-problem="currentProblem"
      :answer="answer"
      :is-revealed="isRevealed"
      :is-loading-next="isLoadingNext"
      :result-visible="resultVisible"
      :result-ok="resultOk"
      :result-message="resultMessage"
      @update:answer="$emit('update:answer', $event)"
      @check="$emit('check')"
      @reveal="$emit('reveal')"
    />
  </main>
</template>

<script>
import LessonCard from "./LessonCard.vue";
import ProblemCard from "./ProblemCard.vue";

export default {
  name: "PracticeView",
  components: {
    LessonCard,
    ProblemCard,
  },
  props: {
    showLogin: Boolean,
    lessons: Array,
    lessonIdx: Number,
    selectedLessonId: String,
    lessonBodyHtml: String,
    currentProblem: Object,
    answer: String,
    isRevealed: Boolean,
    isLoadingNext: Boolean,
    resultVisible: Boolean,
    resultOk: Boolean,
    resultMessage: String,
    prevDisabled: Boolean,
    nextDisabled: Boolean,
    user: Object, // Add user prop
  },
  emits: [
    "setLessonByIndex",
    "setLessonById",
    "update:answer",
    "check",
    "reveal",
  ],
};
</script>
