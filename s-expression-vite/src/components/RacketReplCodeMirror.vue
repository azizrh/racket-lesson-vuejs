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
        <button class="btn primary" @click="runEditor">Run Editor</button>
        <button class="btn secondary" @click="clearRepl">Clear REPL</button>
        <button class="btn secondary" title="Load sample" @click="loadSample">
          Load Sample
        </button>
        <button class="btn secondary" title="Reset VM" @click="reset">
          Reset VM
        </button>
      </div>
    </header>

    <div class="content repl__grid">
      <!-- Interactive REPL Pane -->
      <section class="repl__pane">
        <div class="repl__paneHeader">
          <strong class="small muted">Interactive REPL</strong>
          <span class="small muted">Press Enter to evaluate</span>
        </div>
        <div class="repl-container" ref="replContainerEl">
          <div ref="replOutput" class="repl-output">
            <div v-if="replHistory.length === 0" class="welcome">
              Welcome to Racket REPL! Type expressions below.
            </div>
            <div
              v-for="(item, index) in replHistory"
              :key="index"
              class="repl-line"
            >
              <div v-if="item.type === 'input'" class="input-line">
                <span class="prompt">&gt;</span> {{ item.content }}
              </div>
              <div v-else-if="item.type === 'result'" class="result">
                {{ item.content }}
              </div>
              <div v-else-if="item.type === 'error'" class="error">
                {{ item.content }}
              </div>
              <div v-else-if="item.type === 'info'" class="info">
                {{ item.content }}
              </div>
            </div>
          </div>
          <div class="repl-input-container">
            <span class="prompt">&gt;</span>
            <input
              ref="replInput"
              v-model="currentInput"
              class="repl-input"
              placeholder="Type expression and press Enter..."
              @keydown="onReplKeydown"
              autocomplete="off"
            />
          </div>
        </div>
      </section>

      <!-- Multi-line Editor Pane -->
      <section class="repl__pane">
        <div class="repl__paneHeader">
          <strong class="small muted">Multi-line Editor</strong>
          <span class="small muted">
            <span class="kbd">Ctrl</span>/<span class="kbd">⌘</span>
            <span class="kbd">Enter</span> to run
          </span>
        </div>
        <div ref="cmContainer" class="editor"></div>
      </section>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onBeforeUnmount, nextTick, watch } from 'vue'

// CodeMirror imports
import { EditorState } from '@codemirror/state'
import { EditorView, keymap } from '@codemirror/view'
import { defaultHighlightStyle } from '@codemirror/highlight'
import { lineNumbers } from '@codemirror/view'
import { indentWithTab } from '@codemirror/commands'
import { StreamLanguage } from '@codemirror/stream-parser'
import { Scheme } from '@codemirror/legacy-modes/mode/scheme'
import { oneDark } from '@codemirror/theme-one-dark'

// Local component state
const USE_WORKER = false
const LS_KEY = 'racket-repl-code'
const LS_HISTORY_KEY = 'racket-repl-history'

const starter = `(define (factorial n)
  (if (<= n 1)
      1
      (* n (factorial (- n 1)))) )

(factorial 5)

(define (fibonacci n)
  (if (<= n 1)
      n
      (+ (fibonacci (- n 1)) (fibonacci (- n 2)))))

(map fibonacci (range 0 8))`

const code = ref(localStorage.getItem(LS_KEY) ?? starter)
const currentInput = ref('')
const replHistory = ref([])
const commandHistory = ref(
  JSON.parse(localStorage.getItem(LS_HISTORY_KEY) ?? '[]')
)
const historyIndex = ref(-1)
const replOutput = ref(null)
const replInput = ref(null)
const cmContainer = ref(null)
const replContainerEl = ref(null)

// References for height sync
let resizeObserver = null

let worker = null
let interp = null
const mode = ref('idle')
const status = ref('idle')

/**
 * Append a line to the REPL history and scroll to bottom.
 */
const addToRepl = (type, content) => {
  replHistory.value.push({ type, content, timestamp: Date.now() })
  nextTick(() => {
    if (replOutput.value) {
      replOutput.value.scrollTop = replOutput.value.scrollHeight
    }
  })
}

const clearRepl = () => {
  replHistory.value = []
  addToRepl('info', 'REPL cleared')
}

const statusText = computed(() =>
  (
    {
      idle: 'Idle',
      ready: 'Ready',
      reset: 'VM reset',
      error: 'Error',
    }[status.value] || 'Idle'
  )
)

const statusClass = computed(() =>
  (
    {
      idle: 'status--idle',
      ready: 'status--ok',
      reset: 'status--ok',
      error: 'status--err',
    }[status.value] || 'status--idle'
  )
)

const saveHistory = () => {
  localStorage.setItem(
    LS_HISTORY_KEY,
    JSON.stringify(commandHistory.value.slice(0, 100))
  )
}

const onReplKeydown = (e) => {
  if (e.key === 'Enter' && !e.shiftKey) {
    e.preventDefault()
    const input = currentInput.value.trim()
    if (input) {
      addToRepl('input', input)
      if (input !== commandHistory.value[0]) {
        commandHistory.value.unshift(input)
        saveHistory()
      }
      historyIndex.value = -1
      evaluateExpression(input)
      currentInput.value = ''
    }
  } else if (e.key === 'ArrowUp') {
    e.preventDefault()
    if (historyIndex.value < commandHistory.value.length - 1) {
      historyIndex.value++
      currentInput.value = commandHistory.value[historyIndex.value]
    }
  } else if (e.key === 'ArrowDown') {
    e.preventDefault()
    if (historyIndex.value > -1) {
      historyIndex.value--
      currentInput.value =
        historyIndex.value === -1 ? '' : commandHistory.value[historyIndex.value]
    }
  }
}

const onEditorKeydown = (e) => {
  if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') {
    e.preventDefault()
    runEditor()
  }
}

// Prelude helpers
const prelude = `(define (displayln . xs)
  (for-each (lambda (x) (display x)) xs)
  (newline))
(define (range a b)
  (if (> a b) '() (cons a (range (+ a 1) b))))
(define (println . args)
  (for-each display args)
  (newline))`

// Load BiwaScheme if worker mode is disabled
const loadBiwaOnMain = () =>
  new Promise((resolve, reject) => {
    if (window.BiwaScheme) return resolve(window.BiwaScheme)
    const s = document.createElement('script')
    s.src = 'https://www.biwascheme.org/release/biwascheme-0.8.0-min.js'
    s.onload = () => resolve(window.BiwaScheme)
    s.onerror = reject
    document.head.appendChild(s)
  })

const bootMainInterp = async () => {
  const BS = await loadBiwaOnMain()
  const I = new BS.Interpreter((e) => {
    status.value = 'error'
    addToRepl('error', e && e.message ? e.message : String(e))
  })
  I.evaluate(prelude, function () {})
  return { I, BS }
}

const evaluateExpression = async (inputCode) => {
  if (mode.value === 'main' && interp) {
    const { I, BS } = interp
    try {
      I.evaluate(inputCode, (result) => {
        status.value = 'ready'
        if (result !== undefined) {
          const text = BS.to_write ? BS.to_write(result) : String(result)
          addToRepl('result', text)
        }
      })
    } catch (e) {
      status.value = 'error'
      addToRepl('error', e && e.message ? e.message : String(e))
    }
  }
}

const runEditor = async () => {
  localStorage.setItem(LS_KEY, code.value)
  const editorCode = code.value.trim()
  if (editorCode) {
    addToRepl(
      'input',
      `[Editor] ${editorCode.split('\n')[0]}${
        editorCode.split('\n').length > 1 ? '...' : ''
      }`
    )
    const wrappedCode = `(begin ${editorCode})`
    if (mode.value === 'main' && interp) {
      const { I, BS } = interp
      try {
        I.evaluate(wrappedCode, (result) => {
          status.value = 'ready'
          if (result !== undefined) {
            const text = BS.to_write ? BS.to_write(result) : String(result)
            addToRepl('result', text)
          }
        })
      } catch (e) {
        status.value = 'error'
        addToRepl('error', e && e.message ? e.message : String(e))
      }
    }
  }
}

const reset = () => {
  if (mode.value === 'main' && interp) {
    bootMainInterp().then(({ I, BS }) => {
      interp = { I, BS }
      status.value = 'reset'
      addToRepl('info', '[vm] reset')
    })
  }
}

const codeExamples = [
  `(+ 5 3 2)`,
  `(define x 42)`,
  `(* x 2)`,
  `(define (square n) (* n n))`,
  `(square 7)`,
  `(map (lambda (x) (* x x)) (range 1 6))`,
  `(define fruits '(apple banana cherry))`,
  `(displayln "Hello, " "Racket!")`,
]

const loadSample = () => {
  const randomExample = codeExamples[Math.floor(Math.random() * codeExamples.length)]
  currentInput.value = randomExample
  nextTick(() => {
    if (replInput.value) {
      replInput.value.focus()
    }
  })
}

// Height sync: update repl container height to match editor height
const syncHeights = () => {
  if (cmContainer.value && replContainerEl.value) {
    const h = cmContainer.value.offsetHeight
    if (h > 0) {
      replContainerEl.value.style.height = h + 'px'
    }
  }
}

// CodeMirror setup
let cmView = null

const setupCodeMirror = () => {
  if (!cmContainer.value) return
  cmView = new EditorView({
    state: EditorState.create({
      doc: code.value,
      extensions: [
        lineNumbers(),
        keymap.of([indentWithTab]),
        StreamLanguage.define(Scheme),
        defaultHighlightStyle,
        oneDark,
        // Update code ref on changes
        EditorView.updateListener.of((update) => {
          if (update.docChanged) {
            code.value = update.state.doc.toString()
          }
        }),
      ],
    }),
    parent: cmContainer.value,
  })
}

// Update CodeMirror doc when the code ref changes externally
watch(
  code,
  (newVal) => {
    if (cmView && cmView.state.doc.toString() !== newVal) {
      cmView.dispatch({
        changes: { from: 0, to: cmView.state.doc.length, insert: newVal },
      })
    }
  }
)

// Lifecycle hooks
onMounted(async () => {
  mode.value = 'main'
  const { I, BS } = await bootMainInterp()
  interp = { I, BS }
  status.value = 'ready'
  addToRepl('info', '[vm] ready')
  nextTick(() => {
    if (replInput.value) replInput.value.focus()
  })
  await nextTick()
  // Set up CodeMirror after mount
  setupCodeMirror()
  syncHeights()
  // Observe size changes for height sync
  if ('ResizeObserver' in window && cmContainer.value) {
    resizeObserver = new ResizeObserver(() => {
      syncHeights()
    })
    resizeObserver.observe(cmContainer.value)
  } else {
    const i = setInterval(syncHeights, 300)
    resizeObserver = { disconnect: () => clearInterval(i) }
  }
  window.addEventListener('resize', syncHeights)
})

onBeforeUnmount(() => {
  if (worker) {
    worker.terminate()
    worker = null
  }
  if (resizeObserver) {
    resizeObserver.disconnect()
    resizeObserver = null
  }
  window.removeEventListener('resize', syncHeights)
  if (cmView) {
    cmView.destroy()
    cmView = null
  }
})
</script>

<style scoped>
/* Layout */
.repl {
  overflow: hidden;
}
.repl__header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 14px 16px 0 16px;
}
.repl__title {
  display: flex;
  gap: 10px;
  align-items: center;
}
.repl__actions {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}
.repl__grid {
  display: grid;
  gap: 16px;
  grid-template-columns: 1fr 1fr;
}
@media (max-width: 980px) {
  .repl__grid {
    grid-template-columns: 1fr;
  }
}
.repl__pane {
  display: grid;
  gap: 8px;
}
.repl__paneHeader {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 2px;
}
/* REPL Container: height is controlled via syncHeights() */
.repl-container {
  display: flex;
  flex-direction: column;
  min-height: 200px;
  border: 1px solid hsl(var(--border));
  border-radius: 12px;
  background: hsl(0 0% 8%);
  overflow: hidden;
}
.repl-output {
  flex: 1;
  overflow-y: auto;
  padding: 12px;
  font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
  font-size: 13px;
  line-height: 1.5;
}
.repl-input-container {
  display: flex;
  align-items: center;
  padding: 8px 12px;
  border-top: 1px solid hsl(var(--border));
  background: hsl(0 0% 6%);
}
.repl-input {
  flex: 1;
  background: transparent;
  border: none;
  outline: none;
  color: hsl(var(--foreground));
  font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
  font-size: 13px;
  margin-left: 8px;
}
/* REPL Line Styles */
.repl-line {
  margin-bottom: 4px;
}
.input-line {
  color: hsl(var(--foreground));
}
.prompt {
  color: hsl(217 92% 70%);
  user-select: none;
  margin-right: 4px;
}
.result {
  color: hsl(142 76% 73%);
  margin-left: 16px;
}
.error {
  color: hsl(0 84% 70%);
  margin-left: 16px;
}
.info {
  color: hsl(43 96% 76%);
  font-style: italic;
}
.welcome {
  color: hsl(215 20% 65%);
  font-style: italic;
  margin-bottom: 12px;
}
/* Editor */
.editor {
  min-height: 400px;
  background: hsl(0 0% 8%);
  border: 1px solid hsl(var(--input));
  border-radius: 12px;
  resize: vertical;
  /* CodeMirror will take the full size of this container */
}
/* Status pill + dot */
.pill {
  gap: 6px;
}
.dot {
  width: 8px;
  height: 8px;
  border-radius: 999px;
  display: inline-block;
  margin-right: 2px;
  background: hsl(var(--muted-foreground));
}
.status--ok .dot {
  background: hsl(var(--foreground));
}
.status--err .dot {
  background: #ff4d4d;
}
.status--idle .dot {
  background: hsl(var(--muted-foreground));
}
.small {
  font-size: 12px;
}
.m-0 {
  margin: 0;
}
.muted {
  color: hsl(var(--muted-foreground));
}
.kbd {
  padding: 2px 4px;
  background: hsl(var(--muted));
  border-radius: 4px;
  font-size: 11px;
}
</style>