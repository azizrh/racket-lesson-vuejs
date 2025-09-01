<template>
  <!-- Backdrop wrapper (centers modal) -->
  <div
    v-if="show"
    class="fixed inset-0 z-50 flex items-center justify-center"
    role="dialog"
    aria-modal="true"
    aria-labelledby="review-problem-title"
    @click.self="close"
  >
    <!-- Blurred / dimmed backdrop -->
    <div class="modal-backdrop"></div>

    <!-- Dialog -->
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

            <!-- inline loading indicator -->
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
            @keydown.enter.exact.prevent="$emit('check')"
            @keydown.ctrl.enter.exact.prevent="$emit('reveal')"
          />

          <div class="flex items-center gap-2">
            <button
              class="btn primary"
              :disabled="isRevealed"
              @click="$emit('check')"
            >
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

    <!-- Lesson Redirect Modal (appears when user gets answer wrong) -->
    <!-- This modal appears INSIDE the review modal to avoid z-index conflicts -->
    <transition name="fade">
      <div
        v-if="showLessonRedirect"
        class="absolute inset-0 flex items-center justify-center z-10"
        @click.self="closeLessonRedirect"
      >
        <!-- Darker overlay to dim the review modal background -->
        <div class="absolute inset-0 bg-black bg-opacity-50"></div>

        <!-- Lesson redirect popup -->
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

    // state from parent
    isRevealed: { type: Boolean, default: false },
    isLoadingNext: { type: Boolean, default: false },
    resultVisible: { type: Boolean, default: false },
    resultOk: { type: Boolean, default: false },
    resultMessage: { type: String, default: "" },

    // answer two-way bind (v-model:answer)
    answer: { type: String, default: "" },

    // lesson data for redirect
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

      // NEW: track which wrong answer we already handled,
      // so the redirect modal re-appears on each *new* wrong attempt.
      _lastHandledWrongAnswer: null,
      _wrongPopupTimer: null,
    };
  },

  computed: {
    // Proxy to support v-model:answer on the child
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
    // Core logic: show lesson redirect after each *new* wrong attempt.
    // Triggers when either visibility flips or answer changes while we're in a wrong state.
    resultVisible: {
      handler(newVal) {
        this._maybeShowRedirect(newVal, this.resultOk, this.answer);
      },
      immediate: true,
    },
    resultOk(newVal) {
      this._maybeShowRedirect(this.resultVisible, newVal, this.answer);
      if (newVal) {
        // success: clear tracking
        this._lastHandledWrongAnswer = null;
        this.showLessonRedirect = false;
      }
    },
    answer(newAnswer) {
      // If parent keeps resultVisible=true across checks, detect new wrong attempt by answer change
      this._maybeShowRedirect(this.resultVisible, this.resultOk, newAnswer);
    },

    // Reset when problem changes
    problem() {
      this.wrongAnswerCount = 0;
      this.showLessonRedirect = false;
      this._lastHandledWrongAnswer = null;
      this._clearTimer();
    },

    // Reset when modal closes
    show(newVal) {
      if (!newVal) {
        this.showLessonRedirect = false;
        this.wrongAnswerCount = 0;
        this._lastHandledWrongAnswer = null;
        this._clearTimer();
      } else {
        this.$nextTick(() => {
          if (this.$refs.answerInput) this.$refs.answerInput.focus();
        });
      }
    },
  },

  methods: {
    close() {
      this.$emit("update:show", false);
      this.$emit("close");
    },

    cleanProblemText(raw) {
      if (typeof raw !== "string") return "";
      return raw.replaceAll("\\n", "\n").trim();
    },

    goToLesson() {
      this.closeLessonRedirect();
      this.close();
      // Emit event to parent to handle the lesson redirect
      this.$emit("redirect-to-lesson", this.problem.lesson_id);
    },

    tryAgain() {
      this.closeLessonRedirect();
      // Clear the answer and focus input for another attempt
      this.answerProxy = "";
      // Intentionally DO NOT require parent to reset resultVisible;
      // our watcher will detect a *new* wrong state when user checks again.
      this.$nextTick(() => {
        if (this.$refs.answerInput) this.$refs.answerInput.focus();
      });
    },

    closeLessonRedirect() {
      this.showLessonRedirect = false;
    },

    _maybeShowRedirect(isVisible, isOk, currentAnswer) {
      if (!this.show) return;
      if (!isVisible || isOk) return;

      // Only handle once per unique wrong answer string
      const key = String(currentAnswer ?? "");
      if (this._lastHandledWrongAnswer === key) return;

      this._lastHandledWrongAnswer = key;
      this.wrongAnswerCount++;

      // Debounce/Delay to let user read the error text
      this._clearTimer();
      this._wrongPopupTimer = setTimeout(() => {
        if (this.show && this.resultVisible && !this.resultOk) {
          this.showLessonRedirect = true;
        }
      }, 1500);
    },

    _clearTimer() {
      if (this._wrongPopupTimer) {
        clearTimeout(this._wrongPopupTimer);
        this._wrongPopupTimer = null;
      }
    },
  },

  mounted() {
    // focus the input when opened
    this.$nextTick(() => {
      if (this.show && this.$refs.answerInput) {
        this.$refs.answerInput.focus();
      }
    });
  },
  beforeUnmount() {
    this._clearTimer();
  },
};
</script>

<style scoped>
/* Center both axes */
.modal-wrap {
  position: fixed;
  inset: 0;
  display: grid;
  place-items: center;
  padding: 16px; /* keep space from edges on mobile */
  z-index: 50;
}

/* Keep your existing styles */
.modal-backdrop {
  position: absolute;
  inset: 0;
  background: rgba(0, 0, 0, 0.35);
  backdrop-filter: blur(6px);
  -webkit-backdrop-filter: blur(6px);
  pointer-events: none; /* so @click.self works on wrapper */
}

.modal-panel {
  margin-top: 15%;
  width: min(720px, 92vw);
  max-height: 85vh;
  overflow: auto;
  border-radius: 14px;
}

/* Spinner (small) */
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

/* Transition for lesson redirect modal */
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s ease;
}
.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>
