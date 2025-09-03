<template>
  <div class="card repl">
    <header class="repl__header">
      <div class="repl__title">
        <h3 class="m-0">Racket REPL</h3>
        <span class="pill small" :class="statusClass">
          <span class="dot" :class="statusClass"></span>{{ statusText }}
        </span>
      </div>
      <div class="repl__actions">
        <button class="btn primary" @click="run">Run ⏵</button>
        <button class="btn secondary" @click="clearOut">Clear Output</button>
        <button class="btn secondary" @click="loadSample">Load Sample</button>
        <button class="btn secondary" title="Reset VM" @click="reset">
          Reset VM
        </button>
      </div>
    </header>

    <div class="content repl__grid">
      <!-- Editor Pane -->
      <section class="repl__pane">
        <div class="repl__paneHeader">
          <strong class="small muted">Program</strong>
          <span class="small muted">
            Tip: <span class="kbd">Ctrl</span>/<span class="kbd">⌘</span> +
            <span class="kbd">Enter</span>
          </span>
        </div>
        <textarea
          v-model="code"
          class="input editor"
          spellcheck="false"
          @keydown="onKeydown"
          aria-label="Scheme program editor"
        />
      </section>

      <!-- Console Pane -->
      <section class="repl__pane">
        <div class="repl__paneHeader">
          <strong class="small muted">Output</strong>
          <span class="small muted">{{ mode === "worker" ? "Worker" : "Main thread" }}</span>
        </div>
        <pre ref="outEl" class="console" aria-live="polite" />
      </section>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onBeforeUnmount } from "vue";

/**
 * Set USE_WORKER = false to run on the main thread (CSP/SES-friendly).
 * To enable worker mode, set it true and place biwascheme-0.8.0-min.js at:
 * src/assets/biwa/biwascheme-0.8.0-min.js
 */
const USE_WORKER = false;

const LS_KEY = "racket-repl-code";
const starter = `(displayln "hello, racket-ish repl!")
(define (fact n) (if (= n 0) 1 (* n (fact (- n 1)))))
(displayln "fact 6 = " (fact 6))
(displayln (map (lambda (x) (* x x)) (range 1 10)))`;

const code = ref(localStorage.getItem(LS_KEY) ?? starter);
const outEl = ref(null);

let worker = null;
let interp = null;
const mode = ref("idle");   // 'idle' | 'worker' | 'main'
const status = ref("idle"); // 'idle' | 'ready' | 'reset' | 'error'

const log = (s, kind = "line") => {
  if (!outEl.value) return;
  const prefix = kind === "error" ? "❌ " : kind === "info" ? "ℹ️ " : "";
  outEl.value.textContent += prefix + s + "\n";
  outEl.value.scrollTop = outEl.value.scrollHeight;
};
const clearOut = () => {
  if (outEl.value) outEl.value.textContent = "";
};

const statusText = computed(() => ({
  idle: "Idle",
  ready: "Ready",
  reset: "VM reset",
  error: "Error"
}[status.value] || "Idle"));

const statusClass = computed(() => ({
  idle: "status--idle",
  ready: "status--ok",
  reset: "status--ok",
  error: "status--err"
}[status.value] || "status--idle"));

const onKeydown = (e) => {
  if ((e.ctrlKey || e.metaKey) && e.key === "Enter") {
    e.preventDefault();
    run();
  }
};

const prelude = `(define (displayln . xs)
  (for-each (lambda (x) (display x)) xs)
  (newline))
(define (range a b)
  (if (> a b) '() (cons a (range (+ a 1) b))))`;

// Worker version (if USE_WORKER true)
const makeWorker = async () => {
  const biwaUrl = new URL("../assets/biwa/biwascheme-0.8.0-min.js", import.meta.url);
  const biwaText = await (await fetch(biwaUrl)).text();

  const WORKER_CORE = `
    (function(){
      if (typeof self.document === 'undefined') {
        self.document = {
          createElement: () => ({ style:{}, appendChild(){}, setAttribute(){}, innerHTML:'' }),
          createTextNode: (t) => ({ nodeType:3, data:String(t) }),
          getElementsByTagName: () => [],
          body: { appendChild(){} }
        };
      }
      const BS = self.BiwaScheme;
      function boot(){
        const I = new BS.Interpreter((e) =>
          postMessage({ type:'error', message: e && e.message ? e.message : String(e) }));
        I.evaluate(${JSON.stringify(prelude)}, function(){});
        return I;
      }
      let I = null;
      try { I = boot(); postMessage({ type:'info', text:'[vm] ready' }); }
      catch (e) { postMessage({ type:'fatal', message: e && e.message ? e.message : String(e) }); return; }

      onmessage = (evt) => {
        const { cmd, code } = evt.data || {};
        if (!I) { postMessage({type:'fatal', message:'Interpreter not initialized'}); return; }
        if (cmd === 'reset') { I = boot(); postMessage({type:'info', text:'[vm] reset'}); return; }
        if (cmd === 'eval') {
          try {
            I.evaluate(code, (result) => {
              const text = BS.to_write ? BS.to_write(result) : String(result);
              postMessage({ type:'result', text });
            });
          } catch (e) {
            postMessage({ type:'error', message: e && e.message ? e.message : String(e) });
          }
        }
      };
    })();
  `;

  const blob = new Blob([biwaText, "\n", WORKER_CORE], { type: "text/javascript" });
  return new Worker(URL.createObjectURL(blob));
};

// Main-thread fallback
const loadBiwaOnMain = () =>
  new Promise((resolve, reject) => {
    if (window.BiwaScheme) return resolve(window.BiwaScheme);
    const s = document.createElement("script");
    s.src = "https://www.biwascheme.org/release/biwascheme-0.8.0-min.js";
    s.onload = () => resolve(window.BiwaScheme);
    s.onerror = reject;
    document.head.appendChild(s);
  });

const bootMainInterp = async () => {
  const BS = await loadBiwaOnMain();
  const I = new BS.Interpreter((e) => {
    status.value = "error";
    log(e && e.message ? e.message : String(e), "error");
  });
  I.evaluate(prelude, function(){});
  return { I, BS };
};

// Run program
const run = async () => {
  localStorage.setItem(LS_KEY, code.value);
  if (mode.value === "worker" && worker) {
    worker.postMessage({ cmd: "eval", code: code.value });
  } else if (mode.value === "main" && interp) {
    const { I, BS } = interp;
    try {
      I.evaluate(code.value, (result) => {
        status.value = "ready";
        const text = BS.to_write ? BS.to_write(result) : String(result);
        log(text);
      });
    } catch (e) {
      status.value = "error";
      log(e && e.message ? e.message : String(e), "error");
    }
  }
};

// Reset interpreter
const reset = () => {
  if (mode.value === "worker" && worker) {
    worker.postMessage({ cmd: "reset" });
  } else if (mode.value === "main" && interp) {
    bootMainInterp().then(({ I, BS }) => {
      interp = { I, BS };
      status.value = "reset";
      log("[vm] reset", "info");
    });
  }
};

// Load sample program
const loadSample = () => {
  code.value = `(displayln "Hi from Jakarta 👋")
(define (fib n) (if (< n 2) n (+ (fib (- n 1)) (fib (- n 2)))))
(displayln "fib 10 = " (fib 10))`;
};

// Lifecycle
onMounted(async () => {
  if (USE_WORKER) {
    try {
      worker = await makeWorker();
      mode.value = "worker";
      worker.onmessage = (e) => {
        const { type, text, message } = e.data || {};
        if (type === "result") { status.value = "ready"; log(String(text)); }
        else if (type === "info") { status.value = text.includes("reset") ? "reset" : "ready"; log(text, "info"); }
        else if (type === "error") { status.value = "error"; log(message, "error"); }
        else if (type === "fatal") { throw new Error(message || "Worker fatal"); }
      };
    } catch (e) {
      // fallback to main thread if worker fails
      mode.value = "main";
      const { I, BS } = await bootMainInterp();
      interp = { I, BS };
      status.value = "ready";
      log("[vm] ready (main thread)", "info");
    }
  } else {
    mode.value = "main";
    const { I, BS } = await bootMainInterp();
    interp = { I, BS };
    status.value = "ready";
    log("[vm] ready (main thread)", "info");
  }
});

onBeforeUnmount(() => {
  worker?.terminate();
  worker = null;
});
</script>

<style scoped>
/* Layout */
.repl { overflow: hidden; }
.repl__header {
  display: flex; align-items: center; justify-content: space-between;
  padding: 14px 16px 0 16px;
}
.repl__title { display: flex; gap: 10px; align-items: center; }
.repl__actions { display: flex; gap: 8px; flex-wrap: wrap; }

.repl__grid { display: grid; gap: 16px; grid-template-columns: 1fr 1fr; }
@media (max-width: 980px) { .repl__grid { grid-template-columns: 1fr; } }

.repl__pane { display: grid; gap: 8px; }
.repl__paneHeader {
  display: flex; align-items: center; justify-content: space-between;
  padding: 0 2px;
}

/* Editor */
.editor {
  min-height: 280px;
  background: hsl(0 0% 8%);
  border: 1px solid hsl(var(--input));
  border-radius: 12px;
  resize: vertical;
}

/* Console */
.console {
  background: hsl(0 0% 10%);
  border: 1px solid hsl(var(--border));
  border-radius: 12px;
  padding: 12px;
  min-height: 180px;
  white-space: pre-wrap;
  font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
  line-height: 1.45;
  overflow: auto;
  box-shadow: inset 0 0 0 1px rgba(255, 255, 255, .02);
}

/* Status pill + dot */
.pill { gap: 6px; }
.dot {
  width: 8px; height: 8px; border-radius: 999px;
  display: inline-block; margin-right: 2px;
  background: hsl(var(--muted-foreground));
}
.status--ok .dot { background: hsl(var(--foreground)); }
.status--err .dot { background: #ff4d4d; }
.status--idle .dot { background: hsl(var(--muted-foreground)); }

.small { font-size: 12px; }
.m-0 { margin: 0; }
.muted { color: hsl(var(--muted-foreground)); }
</style>
