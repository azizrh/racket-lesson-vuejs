<template>
  <section class="card" id="practiceCard">
    <header>
      <h2 class="m-0 mb-1 text-[18px] font-semibold">
        Problems &amp; Validator
      </h2>
    </header>
    <div
      style="
        background: #ffff1212;
        padding: 10px;
        margin: 10px;
        border-radius: 4px;
        font-family: monospace;
      "
    >
      <strong>Debug Info:</strong><br />
      currentProblem: {{ currentProblem }}<br />
      answer: {{ answer }}<br />
    </div>
    <div class="content">
      <div class="grid gap-3">
        <div class="panel">
          <div class="muted small">Problem</div>
          <div class="mt-1 text-[22px]">
            {{
              currentProblem
                ? cleanProblemText(currentProblem.prompt_text)
                : "No problems found for this lesson."
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
          :value="answer"
          @input="$emit('update:answer', $event.target.value)"
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
</template>

<script>
export default {
  name: "ProblemCard",
  props: {
    currentProblem: Object,
    answer: String,
    isRevealed: Boolean,
    isLoadingNext: Boolean,
    resultVisible: Boolean,
    resultOk: Boolean,
    resultMessage: String,
  },
  emits: ["update:answer", "check", "reveal"],
  methods: {
    cleanProblemText(raw) {
      if (typeof raw !== "string") return "";
      return raw.replaceAll("\\n", "\n").trim();
    },
  },
  mounted() {
    // Auto-focus input when component mounts
    this.$nextTick(() => {
      if (this.$refs.answerInput) {
        this.$refs.answerInput.focus();
      }
    });
  },
};
</script>
