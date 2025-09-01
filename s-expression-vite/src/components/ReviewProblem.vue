<template>
  <div
    v-if="show"
    class="fixed inset-0 z-50 flex items-center justify-center"
    role="dialog"
    aria-modal="true"
    aria-labelledby="review-problem-title"
    @click.self="close"
  >
    <div class="modal-backdrop"></div>

    <section class="card modal-panel relative" id="practiceCard" @click.stop>
      <header class="flex items-center justify-between">
        <h2
          id="review-problem-title"
          class="m-0 mb-1 text-[18px] font-semibold"
        >
          Review your understanding for lesson {{ problem.lesson_id }}
        </h2>
        <button class="btn secondary" @click="close">Close ✕</button>
      </header>

      <div class="content">
        <div class="grid gap-3">
          <div class="panel">
            <div class="muted small">Problem</div>
            <div class="mt-1 text-[22px]">
              {{
                problem
                  ? cleanProblemText(problem.prompt_text)
                  : "No problems available."
              }}
            </div>
            <div v-if="isRevealed" class="pill mt-2">
              Revealed — answers for this problem won't be accepted
            </div>
          </div>

          <div class="flex items-center justify-between">
            <label class="muted small" for="answerInput">Your answer</label>

            <div
              v-if="isLoadingNext"
              class="inline-loading flex items-center gap-2"
              aria-live="polite"
            >
              <div class="spinner spinner--sm" aria-hidden="true"></div>
              <span class="muted small">Loading next problem...</span>
            </div>
          </div>

          <input
            id="answerInput"
            class="input"
            placeholder="e.g. (+ 5 4) or Racket code"
            autocomplete="off"
            v-model="answerProxy"
            ref="answerInput"
            :disabled="isRevealed"
            @keydown.enter.exact.prevent="onCheck"
            @keydown.ctrl.enter.exact.prevent="$emit('reveal')"
          />

          <div class="flex items-center gap-2">
            <button class="btn primary" :disabled="isRevealed" @click="onCheck">
              Check (↵)
            </button>
            <button
              class="btn secondary"
              :disabled="isRevealed"
              @click="$emit('reveal')"
            >
              Reveal (Ctrl + ↵)
            </button>
          </div>

          <div
            v-if="resultVisible"
            class="status"
            :class="resultOk ? 'ok' : 'err'"
          >
            {{ resultMessage }}
          </div>
        </div>
      </div>
    </section>

    <!-- Lesson Redirect Modal -->
    <transition name="fade">
      <div
        v-if="showLessonRedirect"
        class="absolute inset-0 flex items-center justify-center z-10"
        @click.self="closeLessonRedirect"
      >
        <div class="absolute inset-0 bg-black bg-opacity-50"></div>
        <div
          class="relative card p-6 w-full max-w-md mx-4 shadow-2xl border-2"
          @click.stop
          style="border-color: hsl(var(--ring))"
        >
          <div class="text-center">
            <div class="text-4xl mb-4">📚</div>
            <h3 class="text-lg font-semibold mb-2">Need a refresher?</h3>
            <p class="text-gray-400 mb-4">
              That wasn't quite right. Would you like to review the lesson for
              this topic?
            </p>
            <div class="text-sm text-gray-500 mb-6">
              This will take you to <strong>{{ lessonTitle }}</strong> to brush
              up on the concepts.
            </div>
            <div class="flex gap-3">
              <button class="btn primary px-4 py-2 flex-1" @click="goToLesson">
                📖 Review Lesson
              </button>
              <button class="btn secondary px-4 py-2" @click="tryAgain">
                Try Again
              </button>
            </div>
            <button
              class="btn secondary px-4 py-2 w-full mt-2 text-sm"
              @click="closeLessonRedirect"
            >
              Skip for now
            </button>
          </div>
        </div>
      </div>
    </transition>
  </div>
</template>

<script>
export default {
  name: "ReviewProblem",
  props: {
    show: { type: Boolean, default: false },
    problem: { type: Object, default: null },
    isRevealed: { type: Boolean, default: false },
    isLoadingNext: { type: Boolean, default: false },
    resultVisible: { type: Boolean, default: false },
    resultOk: { type: Boolean, default: false },
    resultMessage: { type: String, default: "" },
    answer: { type: String, default: "" },
    lessons: { type: Array, default: () => [] },
  },
  emits: [
    "update:show",
    "update:answer",
    "check",
    "reveal",
    "close",
    "redirect-to-lesson",
  ],
  data() {
    return {
      showLessonRedirect: false,
      wrongAnswerCount: 0,
      _wrongPopupTimer: null,
    };
  },
  computed: {
    answerProxy: {
      get() {
        return this.answer;
      },
      set(v) {
        this.$emit("update:answer", v);
      },
    },
    lessonTitle() {
      if (!this.problem?.lesson_id || !this.lessons.length)
        return "Unknown Lesson";
      const lesson = this.lessons.find((l) => l.id === this.problem.lesson_id);
      return lesson ? lesson.title : `Lesson ${this.problem.lesson_id}`;
    },
  },
  watch: {
    // If the result becomes visible and WRONG, schedule the popup (debounced).
    resultVisible(newVal) {
      if (newVal && !this.resultOk) {
        this._scheduleRedirectCheck(); // delay + re-verify before showing
      }
      if (!newVal) {
        this._hideRedirectAndClear();
      }
    },
    // If we become CORRECT at any point, cancel and hide.
    resultOk(newVal) {
      if (newVal) {
        this._hideRedirectAndClear();
      } else if (this.resultVisible) {
        this._scheduleRedirectCheck();
      }
    },
    // Reset on problem change / close
    problem() {
      this._resetState();
    },
    show(v) {
      if (!v) this._resetState();
      else this.$nextTick(() => this.$refs.answerInput?.focus());
    },
  },
  methods: {
    onCheck() {
      // Emit to parent; then schedule a delayed check so we don't flash the popup
      // before parent finishes computing resultOk/resultVisible.
      this.$emit("check");
      this._scheduleRedirectCheck();
    },
    tryAgain() {
      this._hideRedirectAndClear();
      this.answerProxy = "";
      this.$nextTick(() => this.$refs.answerInput?.focus());
      // No popup scheduling here; it’ll schedule after the *next* onCheck if wrong.
    },
    goToLesson() {
      this._hideRedirectAndClear();
      this.$emit("update:show", false);
      this.$emit("close");
      this.$emit("redirect-to-lesson", this.problem.lesson_id);
    },
    close() {
      this.$emit("update:show", false);
      this.$emit("close");
    },
    closeLessonRedirect() {
      this._hideRedirectAndClear();
    },
    cleanProblemText(raw) {
      if (typeof raw !== "string") return "";
      return raw.replaceAll("\\n", "\n").trim();
    },

    // --- helpers ---
    _scheduleRedirectCheck(delay = 900) {
      // debounce; only show if *still* wrong at fire time
      this._clearTimer();
      this._wrongPopupTimer = setTimeout(() => {
        if (!this.show) return;
        if (this.resultVisible && !this.resultOk) {
          this.showLessonRedirect = true;
          this.wrongAnswerCount++;
        }
      }, delay); // small delay so correct results won't flash the popup
    },
    _hideRedirectAndClear() {
      this.showLessonRedirect = false;
      this._clearTimer();
    },
    _clearTimer() {
      if (this._wrongPopupTimer) {
        clearTimeout(this._wrongPopupTimer);
        this._wrongPopupTimer = null;
      }
    },
    _resetState() {
      this.showLessonRedirect = false;
      this.wrongAnswerCount = 0;
      this._clearTimer();
    },
  },
  mounted() {
    this.$nextTick(() => {
      if (this.show) this.$refs.answerInput?.focus();
    });
  },
  beforeUnmount() {
    this._clearTimer();
  },
};
</script>

<style scoped>
.modal-backdrop {
  position: absolute;
  inset: 0;
  background: rgba(0, 0, 0, 0.35);
  backdrop-filter: blur(6px);
  -webkit-backdrop-filter: blur(6px);
  pointer-events: none;
}
.modal-panel {
  margin-top: 15%;
  width: min(720px, 92vw);
  max-height: 85vh;
  overflow: auto;
  border-radius: 14px;
}
.spinner {
  width: 40px;
  height: 40px;
  border: 4px solid #ccc;
  border-top-color: #333;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}
.spinner--sm {
  width: 16px;
  height: 16px;
  border-width: 3px;
}
@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s ease;
}
.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>
