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
    <section class="card modal-panel" id="practiceCard" @click.stop>
      <header class="flex items-center justify-between">
        <h2 id="review-problem-title" class="m-0 mb-1 text-[18px] font-semibold">
          Review your understanding for lesson {{ (problem.lesson_id) }}
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
            <button class="btn primary" :disabled="isRevealed" @click="$emit('check')">
              Check (↵)
            </button>
            <button class="btn secondary" :disabled="isRevealed" @click="$emit('reveal')">
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
  </div>
</template>

<script>
export default {
  name: "ReviewProblem",
  props: {
    show: { type: Boolean, default: false },          // v-model:show
    problem: { type: Object, default: null },

    // state from parent
    isRevealed: { type: Boolean, default: false },
    isLoadingNext: { type: Boolean, default: false },
    resultVisible: { type: Boolean, default: false },
    resultOk: { type: Boolean, default: false },
    resultMessage: { type: String, default: "" },

    // answer two-way bind (v-model:answer)
    answer: { type: String, default: "" },
  },
  emits: ["update:show", "update:answer", "check", "reveal", "close"],
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
  },
  mounted() {
    // focus the input when opened
    this.$nextTick(() => {
      if (this.show && this.$refs.answerInput) {
        this.$refs.answerInput.focus();
      }
    });
  },
  watch: {
    show(val) {
      if (val) {
        this.$nextTick(() => {
          if (this.$refs.answerInput) this.$refs.answerInput.focus();
        });
      }
    },
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
  padding: 16px;   /* keep space from edges on mobile */
  z-index: 50;
}

/* Keep your existing styles */
.modal-backdrop {
  position: absolute;
  inset: 0;
  background: rgba(0,0,0,.35);
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
@keyframes spin { to { transform: rotate(360deg); } }
</style>
