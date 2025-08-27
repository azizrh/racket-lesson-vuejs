#!/bin/bash

# S-Expression Vite Project Setup Script
# Run with: ./setup-vite-project.sh

set -e  # Exit on any error

PROJECT_NAME="s-expression-vite"
echo "🚀 Setting up $PROJECT_NAME project..."

# Create project directory
if [ -d "$PROJECT_NAME" ]; then
    echo "❌ Directory $PROJECT_NAME already exists!"
    read -p "Do you want to remove it and continue? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$PROJECT_NAME"
        echo "🗑️  Removed existing directory"
    else
        echo "❌ Aborting setup"
        exit 1
    fi
fi

mkdir "$PROJECT_NAME"
cd "$PROJECT_NAME"

# Create directory structure
echo "📁 Creating directory structure..."
mkdir -p src/components
mkdir -p public

# Create package.json
echo "📦 Creating package.json..."
cat > package.json << 'EOF'
{
  "name": "s-expression-practice",
  "private": true,
  "version": "0.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "vue": "^3.4.0",
    "marked": "^11.0.0"
  },
  "devDependencies": {
    "@vitejs/plugin-vue": "^5.0.0",
    "vite": "^5.0.0"
  }
}
EOF

# Create vite.config.js
echo "⚙️  Creating vite.config.js..."
cat > vite.config.js << 'EOF'
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  server: {
    port: 3000,
    proxy: {
      '/api': {
        target: 'http://localhost:8000',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api/, '')
      }
    }
  },
  build: {
    outDir: 'dist',
    assetsDir: 'assets'
  }
})
EOF

# Create index.html
echo "🌐 Creating index.html..."
cat > index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/vite.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>S-Expression Practice</title>
    <script src="https://cdn.tailwindcss.com"></script>
  </head>
  <body>
    <div id="app"></div>
    <script type="module" src="/src/main.js"></script>
  </body>
</html>
EOF

# Create .env files
echo "🔧 Creating environment files..."
cat > .env << 'EOF'
VITE_API_BASE=http://localhost:8000
EOF

cat > .env.example << 'EOF'
# Copy this to .env and adjust values as needed
VITE_API_BASE=http://localhost:8000
EOF

# Create .gitignore
echo "📝 Creating .gitignore..."
cat > .gitignore << 'EOF'
# Logs
logs
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*
pnpm-debug.log*
lerna-debug.log*

node_modules
dist
dist-ssr
*.local

# Editor directories and files
.vscode/*
!.vscode/extensions.json
.idea
.DS_Store
*.suo
*.ntvs*
*.njsproj
*.sln
*.sw?

# Environment files
.env.local
.env.*.local
EOF

# Create Dockerfile.dev
echo "🐳 Creating Dockerfile.dev..."
cat > Dockerfile.dev << 'EOF'
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .

EXPOSE 3000

CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0"]
EOF

# Create README.md
echo "📖 Creating README.md..."
cat > README.md << 'EOF'
# S-Expression Practice App

A Vue.js + Vite application for practicing S-expressions with real-time validation.

## Development

```bash
# Install dependencies
npm install

# Start development server
npm run dev
```

## Docker

```bash
# Development with Docker
docker-compose --profile development up

# Production with Docker
npm run build
docker-compose --profile production up
```

## Project Structure

```
s-expression-vite/
├── src/
│   ├── components/     # Vue components
│   ├── App.vue        # Main app component
│   ├── main.js        # Entry point
│   └── style.css      # Global styles
├── public/            # Static assets
├── index.html         # HTML entry point
└── vite.config.js     # Vite configuration
```
EOF

# Create src/main.js
echo "🎯 Creating src/main.js..."
cat > src/main.js << 'EOF'
import { createApp } from 'vue'
import App from './App.vue'
import './style.css'

createApp(App).mount('#app')
EOF

# Create src/style.css
echo "🎨 Creating src/style.css..."
cat > src/style.css << 'EOF'
/* =====================
   shadcn-inspired tokens (grayscale)
   ===================== */
:root{
  /* HSL values only; we use them via hsl(var(--token)) */
  --background: 0 0% 6%;      /* ~#0f0f0f */
  --foreground: 0 0% 96%;     /* ~#f5f5f5 */
  --muted-foreground: 0 0% 65%;
  --card: 0 0% 9%;            /* ~#171717 */
  --popover: 0 0% 10%;
  --border: 0 0% 20%;
  --input: 0 0% 22%;
  --ring: 0 0% 45%;
  --radius: 16px;
  --sticky-top: 86px;         /* computed on init */
}

/* Base */
*{box-sizing:border-box}
body{
  margin:0;
  font:16px/1.5 system-ui, Segoe UI, Roboto, Helvetica, Arial;
  color: hsl(var(--foreground));
  background:
    radial-gradient(1200px 600px at 70% -10%, rgba(255,255,255,0.04), transparent),
    linear-gradient(180deg, hsl(var(--background)), hsl(0 0% 8%) 40%, hsl(0 0% 10%));
}

a { color: inherit; text-decoration: none; }

/* Header */
header{
  position:sticky; top:0; z-index:50;
  border-bottom:1px solid hsl(var(--border));
  background: rgba(0,0,0,.25);
  backdrop-filter: blur(8px);
}
header .wrap{ 
  display:flex; align-items:center; justify-content:space-between; 
  gap:.75rem; padding:18px 20px; max-width: 1100px; margin: 0 auto; 
}
header h1{ 
  margin:0; font-size:15px; letter-spacing:.25px; 
  color: hsl(var(--muted-foreground)); font-weight:600; 
}

/* Layout */
main{ 
  display:grid; gap:18px; padding:18px; 
  grid-template-columns: 1fr 1fr; align-items:start; 
  max-width:1100px; margin:0 auto; 
}
@media (max-width: 980px){ 
  main{ grid-template-columns:1fr } 
}
header .wrap,
main { max-width: min(92rem, 95vw); }

/* Card */
.card{ 
  background:hsl(var(--card)); border:1px solid hsl(var(--border)); 
  border-radius:var(--radius); box-shadow:0 10px 30px rgba(0,0,0,.35); 
}
.card header{ 
  position:static; background:transparent; border:0; padding:16px 16px 0 
}
.card .content{ padding:16px }

/* Text helpers */
.muted{ color: hsl(var(--muted-foreground)); }
.small{ font-size:12px }
.kbd{ 
  font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace; 
  background:hsl(0 0% 10%); border:1px solid hsl(var(--border)); 
  border-bottom-width:2px; border-radius:6px; padding:2px 6px; 
  color:hsl(var(--foreground)); 
}

/* Inputs */
textarea, input, select, button { font: inherit; color: inherit; }
textarea, .input{
  width:100%; min-height: unset;
  background:hsl(0 0% 8%);
  border:1px solid hsl(var(--input));
  border-radius:12px; padding:12px; color: hsl(var(--foreground));
}
textarea{ min-height:300px }
select{
  background:hsl(0 0% 8%);
  min-height:50px;
  text-align-last: left;
  border:3px solid hsl(var(--input));
  border-radius:10px; padding:8px 16px 8px 16px; color:hsl(var(--foreground));
}
.input:focus, textarea:focus, select:focus { 
  outline: 2px solid hsl(var(--ring)); outline-offset: 2px; 
}

/* Badges/Pills */
.pill{ 
  display:inline-flex; gap:8px; align-items:center; padding:6px 10px; 
  border:1px solid hsl(var(--border)); background:hsl(0 0% 8%); 
  border-radius:999px; font-size:12px; color:hsl(var(--muted-foreground)); 
}

/* Panels */
.panel{ 
  background:hsl(0 0% 8%); border:1px dashed hsl(var(--input)); 
  border-radius:12px; padding:12px 
}

/* Buttons (shadcn-like: primary / ghost) */
.btn{ 
  display:inline-flex; align-items:center; gap:.5rem; 
  border-radius:12px; padding:10px 14px; cursor:pointer; 
  border:1px solid hsl(var(--border)); 
  transition: transform .15s ease, background-color .2s ease, border-color .2s ease, opacity .2s ease; 
}
.btn:active{ transform: translateY(1px); }
.btn[disabled]{ opacity:.6; cursor:not-allowed }
.btn:focus-visible{ outline:2px solid hsl(var(--ring)); outline-offset:2px; }

/* primary = high-contrast */
.btn.primary{ 
  background: hsl(var(--foreground)); color: hsl(var(--background)); 
  border-color: hsl(0 0% 80%); 
}
.btn.primary:hover{ background: hsl(0 0% 92%); }

/* secondary (ghost) */
.btn.secondary{ 
  background: hsl(0 0% 10%); color: hsl(var(--foreground)); 
  border-color: hsl(var(--input)); 
}
.btn.secondary:hover{ background: hsl(0 0% 12%); }

/* Status (monochrome) */
.status{ 
  border-radius:12px; padding:12px; border:1px solid hsl(var(--border)); 
  background:hsl(0 0% 10%); 
}
.status.ok{ /* keep monochrome; success icon comes from text */ }
.status.err{ /* same base; relies on ❌ prefix */ }

code{ 
  background:hsl(0 0% 10%); border:1px solid hsl(var(--border)); 
  border-radius:8px; padding:1px 6px 
}

@media (min-width: 981px){
  #practiceCard{ position: sticky; top: var(--sticky-top); align-self: start; }
}

/* Modal */
.modal{ 
  display:flex; position:fixed; z-index:100; left:0; top:0; 
  width:100%; height:100%; background:rgba(0,0,0,.6); 
  align-items:center; justify-content:center; padding: 16px; 
}
.modal-content{ 
  background:hsl(var(--card)); padding:20px; border-radius:16px; 
  max-width:520px; width:100%; text-align:center; 
  border:1px solid hsl(var(--border)); outline:none; 
  box-shadow: 0 20px 60px rgba(0,0,0,.5); 
}
.modal-content h2{ margin:4px 0 10px }

/* Lesson text */
.lesson-display { 
  white-space: pre-wrap; background:hsl(0 0% 8%); 
  border:1px solid hsl(var(--input)); border-radius:12px; 
  padding:12px; color: hsl(var(--foreground)); 
}
.lesson-display p { margin: 0 0 0.5em; }
.lesson-display code { 
  font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace; 
  background:hsl(0 0% 10%); border:1px solid hsl(var(--border)); 
  border-radius:6px; padding:2px 4px; 
}

/* Vue transitions */
.fade-enter-active, .fade-leave-active { 
  transition: opacity 0.3s ease; 
}
.fade-enter-from, .fade-leave-to { 
  opacity: 0; 
}
.scale-enter-active, .scale-leave-active { 
  transition: transform 0.3s ease, opacity 0.3s ease; 
}
.scale-enter-from, .scale-leave-to { 
  transform: scale(0.95); opacity: 0; 
}

/* Utility classes */
.grid { display: grid; }
.flex { display: flex; }
.items-center { align-items: center; }
.justify-center { justify-content: center; }
.justify-between { justify-content: space-between; }
.gap-2 { gap: 0.5rem; }
.gap-3 { gap: 0.75rem; }
.mt-1 { margin-top: 0.25rem; }
.mt-2 { margin-top: 0.5rem; }
.mt-3 { margin-top: 0.75rem; }
.mb-1 { margin-bottom: 0.25rem; }
.-mt-1 { margin-top: -0.25rem; }
.m-0 { margin: 0; }
.text-left { text-align: left; }
.font-semibold { font-weight: 600; }
.flex-1 { flex: 1; }
.text-\[18px\] { font-size: 18px; }
.text-\[22px\] { font-size: 22px; }
EOF

# Create src/App.vue (main component)
echo "🧩 Creating src/App.vue..."
cat > src/App.vue << 'EOF'
<template>
  <div class="app">
    <!-- Header -->
    <header>
      <div class="wrap">
        <h1>S-Expression Practice • Lesson + Validator</h1>
        <div class="flex items-center gap-2">
          <span v-if="username" class="pill">
            Signed in as <strong>{{ username }}</strong>
          </span>
          <button v-if="!username" class="btn secondary" @click="openLogin()">
            Sign in
          </button>
          <button v-if="username" class="btn secondary" @click="logout()">
            Log out
          </button>
        </div>
      </div>
    </header>

    <!-- Main Content -->
    <main :style="showLogin ? 'filter: blur(2px); pointer-events:none; user-select:none;' : ''">
      <!-- LEFT: Lesson text -->
      <section class="card" id="lessonCard">
        <header>
          <div class="flex items-center justify-between">
            <h2 class="m-0 text-[18px] font-semibold">Lesson</h2>
          </div>
          <div class="flex items-center gap-2 mt-2">
            <button 
              class="btn secondary" 
              :disabled="!hasMultipleLessons" 
              @click="setLessonByIndex(lessonIdx - 1)"
            >
              ◀ Prev lesson
            </button>
            <select 
              aria-label="Choose lesson" 
              v-model="selectedLessonId" 
              @change="setLessonById(selectedLessonId)"
            >
              <option 
                v-for="l in lessons" 
                :key="l.id"
                :value="String(l.id)" 
                :disabled="!hasAccessToLesson(l.id)"
              >
                {{ (hasAccessToLesson(l.id) ? '' : '🔒 ') + `${l.title} (ID ${l.id})` }}
              </option>
            </select>
            <button 
              class="btn secondary" 
              :disabled="!hasMultipleLessons || !hasAccessToLesson(nextLessonId())" 
              @click="setLessonByIndex(lessonIdx + 1)"
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

      <!-- RIGHT: Problems & validator -->
      <section class="card" id="practiceCard">
        <header>
          <h2 class="m-0 mb-1 text-[18px] font-semibold">Problems &amp; Validator</h2>
        </header>
        <div class="content">
          <div class="grid gap-3">
            <div class="panel">
              <div class="muted small">Problem</div>
              <div class="mt-1 text-[22px]">
                {{ currentProblem ? cleanProblemText(currentProblem.prompt_text) : 'No problems found for this lesson.' }}
              </div>
              <div v-if="isRevealed" class="pill mt-2">
                Revealed — answers for this problem won't be accepted
              </div>
            </div>

            <label class="muted small" for="answerInput">Your answer</label>
            <input 
              id="answerInput" 
              class="input" 
              placeholder="e.g. (+ 5 4) or Racket code" 
              autocomplete="off" 
              v-model="answer" 
              ref="answerInput" 
              :disabled="isRevealed"
              @keydown.enter.exact.prevent="check"
              @keydown.ctrl.enter.exact.prevent="reveal"
            />

            <div class="flex items-center gap-2">
              <button class="btn primary" :disabled="isRevealed" @click="check">
                Check (↵)
              </button>
              <button class="btn secondary" :disabled="isRevealed" @click="reveal">
                Reveal (Ctrl + ↵)
              </button>
            </div>

            <div v-if="resultVisible" class="status" :class="resultOk ? 'ok' : 'err'">
              {{ resultMessage }}
            </div>
          </div>
        </div>
      </section>
    </main>

    <!-- Modals -->
    <CongratsModal 
      v-model:show="showModal"
      @advance="confirmAdvanceLesson"
      @reset="resetStreakAndStay"
    />
    
    <RevealModal 
      v-model:show="showRevealConfirm"
      @confirm="confirmReveal"
      @cancel="cancelReveal"
    />
    
    <LoginModal 
      v-model:show="showLogin"
      v-model:username="loginUsername"
      :error="loginError"
      @login="loginWithUsername"
    />
  </div>
</template>

<script>
import { marked } from 'marked'
import CongratsModal from './components/CongratsModal.vue'
import RevealModal from './components/RevealModal.vue'
import LoginModal from './components/LoginModal.vue'

export default {
  name: 'App',
  components: {
    CongratsModal,
    RevealModal,
    LoginModal
  },
  
  data() {
    return {
      // Config
      API_BASE: import.meta.env.VITE_API_BASE || "/api",

      // User/Auth State
      username: null,
      userId: null,
      user: null,
      showLogin: false,
      loginUsername: '',
      loginError: '',

      // Lesson/Practice State
      lessons: [],
      lessonIdx: 0,
      problems: [],
      problemIdx: 0,
      successCount: 0,
      selectedLessonId: null,
      answer: '',
      lessonBodyHtml: '',
      resultVisible: false,
      resultOk: false,
      resultMessage: '',
      showModal: false,
      showRevealConfirm: false,
      revealedById: {},

      // Auto-advance
      advanceOnCorrect: true,
      advanceDelayMs: 3000,
      advanceTimerId: null,
    }
  },

  computed: {
    hasMultipleLessons() {
      return this.lessons.length > 1
    },
    currentLesson() {
      return this.lessons[this.lessonIdx] || null
    },
    currentProblem() {
      return this.problems[this.problemIdx] || null
    },
    isRevealed() {
      return !!(this.currentProblem && this.revealedById[this.currentProblem.id])
    }
  },

  methods: {
    hasAccessToLesson(id) {
      return !!this.user?.lessons?.includes(Number(id))
    },

    nextLessonId() {
      if (!this.lessons.length) return null
      const ordered = this.lessons.map(l => l.id)
      const curId = this.currentLesson?.id
      const i = ordered.indexOf(curId)
      return (i >= 0 && i < ordered.length - 1) ? ordered[i + 1] : null
    },

    clearAdvanceTimer() {
      if (this.advanceTimerId) {
        clearTimeout(this.advanceTimerId)
        this.advanceTimerId = null
      }
    },

    // API calls
    async listLessons() {
      const res = await fetch(`${this.API_BASE}/lessons`)
      if (!res.ok) throw new Error('Failed to list lessons')
      return await res.json()
    },

    async loadLesson(lessonId) {
      const res = await fetch(`${this.API_BASE}/lessons/${lessonId}`)
      if (!res.ok) throw new Error('Lesson not found')
      return await res.json()
    },

    async loadProblems(lessonId) {
      const res = await fetch(`${this.API_BASE}/lessons/${lessonId}/problems`)
      if (!res.ok) throw new Error('Failed to load problems')
      return await res.json()
    },

    async backendValidate(problemId, submission) {
      const res = await fetch(`${this.API_BASE}/validate`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ problem_id: problemId, submission })
      })
      if (!res.ok) {
        const text = await res.text().catch(() => "")
        throw new Error(`Backend error (${res.status}): ${text || 'unknown'}`)
      }
      return await res.json()
    },

    async recordAttempt(problemId, submission, backendResult) {
      if (!this.username) return
      try {
        await fetch(`${this.API_BASE}/attempts`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            username: this.username,
            problem_id: problemId,
            submitted_text: submission,
            is_correct: !!backendResult.ok,
            stage: backendResult.stage || null,
            error_reason: backendResult.ok ? null : (backendResult.error || null),
            details: backendResult.details || null
          })
        })
      } catch (e) {
        console.warn('Failed to record attempt:', e)
      }
    },

    async getUserByUsername(uname) {
      const res = await fetch(`${this.API_BASE}/users/by-username/${encodeURIComponent(uname)}`)
      if (!res.ok) {
        const text = await res.text().catch(() => '')
        throw new Error(text || `Failed to load user (${res.status})`)
      }
      return await res.json()
    },

    async loginWithUsername() {
      this.loginError = ''
      const uname = (this.loginUsername || '').trim()
      if (!uname) {
        this.loginError = 'Please enter a username.'
        return
      }
      try {
        const res = await fetch(`${this.API_BASE}/login`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ username: uname })
        })
        if (!res.ok) {
          const text = await res.text().catch(() => '')
          throw new Error(text || `Login failed (${res.status})`)
        }
        const user = await res.json()
        this.setUser(user)
        this.closeLogin()
        await this.bootstrapLessons()
      } catch (e) {
        console.error(e)
        this.loginError = e?.message || 'Failed to log in.'
      }
    },

    // User management
    setUser(user) {
      this.user = user || null
      this.username = user?.username || null
      this.userId = user?.user_id || null
      if (this.username) {
        localStorage.setItem('username', this.username)
      }
    },

    loadLocalUser() {
      const raw = localStorage.getItem('username')
      this.username = raw || null
    },

    logout(silent = false) {
      localStorage.removeItem('username')
      this.user = null
      this.username = null
      this.userId = null
      this.answer = ''
      this.problems = []
      this.lessons = []
      this.lessonIdx = 0
      this.problemIdx = 0
      if (!silent) this.openLogin()
    },

    openLogin() {
      this.showLogin = true
      this.loginUsername = this.username || ''
      this.loginError = ''
    },

    closeLogin() {
      this.showLogin = false
    },

    // Helpers
    cleanProblemText(raw) {
      if (typeof raw !== 'string') return ''
      return raw.replaceAll('\\n', '\n').trim()
    },

    setLessonBody(md) {
      this.lessonBodyHtml = marked.parse(md || '')
    },

    setResult(ok, msg) {
      this.resultOk = !!ok
      this.resultMessage = (ok ? '✅ ' : '❌ ') + (msg || '')
      this.resultVisible = true
    },

    hideResult() {
      this.resultVisible = false
    },

    // Main actions
    async check() {
      if (this.showLogin) return
      if (this.isRevealed) {
        this.setResult(false, 'You revealed this one. Try the next problem.')
        return
      }
      const input = (this.answer || '').trim()
      if (!input) {
        this.setResult(false, 'Type your answer first')
        return
      }
      try {
        const p = this.currentProblem
        if (!p) {
          this.setResult(false, 'No problem selected')
          return
        }
        const res = await this.backendValidate(p.id, input)
        this.recordAttempt(p.id, input, res)
        if (res.ok) {
          const stage = res.stage ? ` (${res.stage})` : ''
          this.setResult(true, 'Correct!' + stage)
          this.successCount++
          if (this.successCount >= 3) {
            this.showModal = true
          }
          if (this.advanceOnCorrect) {
            this.clearAdvanceTimer()
            this.advanceTimerId = setTimeout(() => {
              if (!this.showModal && !this.showLogin) {
                this.nextProblem()
              }
              this.clearAdvanceTimer()
            }, this.advanceDelayMs)
          }
        } else {
          let msg = res.error || 'Incorrect.'
          if (res.details && res.details.failures) {
            const f = res.details.failures[0]
            if (f && f.expr) msg += `\nFailed test: ${f.expr}`
          }
          this.setResult(false, msg)
        }
      } catch (e) {
        this.setResult(false, e.message || 'Backend validation failed.')
      }
    },

    reveal() {
      if (this.showLogin) return
      if (this.isRevealed) return
      this.showRevealConfirm = true
    },

    async confirmReveal() {
      this.showRevealConfirm = false
      const p = this.currentProblem
      const ans = p?.answer_text || 'N/A'
      if (p) {
        this.revealedById[p.id] = true
      }
                this.setResult(true, 'Answer: ' + ans + ' — (This problem is marked as revealed and won\'t count toward your streak)')
      this.clearAdvanceTimer()
      this.advanceTimerId = setTimeout(() => {
        if (!this.showModal && !this.showLogin) {
          this.nextProblem()
        }
        this.clearAdvanceTimer()
      }, this.advanceDelayMs)
    },

    cancelReveal() {
      this.showRevealConfirm = false
    },

    async confirmAdvanceLesson() {
      this.showModal = false
      if (!this.username) {
        this.setResult(false, 'Please sign in first.')
        return
      }
      try {
        const res = await fetch(`${this.API_BASE}/users/by-username/${encodeURIComponent(this.username)}/advance`, {
          method: 'POST'
        })
        if (!res.ok) {
          const text = await res.text().catch(() => '')
          throw new Error(text || `Advance failed (${res.status})`)
        }
        const updated = await res.json()
        this.user = updated
        this.username = updated.username
        this.userId = updated.user_id
        localStorage.setItem('username', this.username)
        this.successCount = 0
        if (updated.active_lesson) {
          await this.setLessonById(updated.active_lesson)
          this.setResult(true, 'Next lesson unlocked!')
        }
      } catch (e) {
        this.setResult(false, e?.message || 'Could not advance to next lesson.')
      }
    },

    resetStreakAndStay() {
      this.successCount = 0
      this.showModal = false
    },

    // Lesson/Problem navigation
    async setLessonByIndex(newIdx) {
      if (!this.lessons.length) return
      const idx = (newIdx + this.lessons.length) % this.lessons.length
      const target = this.lessons[idx]
      if (!this.hasAccessToLesson(target.id)) {
        this.setResult(false, '🔒 Next lesson is locked. Get 3 correct in a row to unlock.')
        return
      }
      this.lessonIdx = idx
      this.selectedLessonId = String(target.id)
      const freshLesson = await this.loadLesson(target.id)
      this.setLessonBody(this.cleanProblemText(freshLesson.body_md) || '')
      this.problems = await this.loadProblems(target.id)
      this.problemIdx = 0
      this.successCount = 0
      this.showProblem()
    },

    async setLessonById(id) {
      const idx = this.lessons.findIndex(l => l.id === Number(id))
      if (idx >= 0) {
        await this.setLessonByIndex(idx)
      }
    },

    showProblem() {
      this.clearAdvanceTimer()
      this.answer = ''
      this.hideResult()
      this.$nextTick(() => {
        if (!this.showLogin && this.$refs.answerInput) {
          this.$refs.answerInput.focus()
        }
      })
    },

    nextProblem() {
      if (!this.problems.length) return
      this.clearAdvanceTimer()
      this.problemIdx = (this.problemIdx + 1) % this.problems.length
      this.showProblem()
    },

    async bootstrapLessons() {
      try {
        this.lessons = await this.listLessons()
        if (this.lessons.length) {
          const preferredId = this.user?.active_lesson || this.lessons[0].id
          this.selectedLessonId = String(preferredId)
          await this.setLessonById(preferredId)
        } else {
          this.setResult(false, 'No lessons found. Please add one in the database.')
        }
      } catch (err) {
        console.error(err)
        this.setResult(false, err?.message || 'Failed to load lessons.')
      }
    }
  },

  async mounted() {
    // Initialize app
    this.loadLocalUser()
    if (this.username) {
      try {
        this.user = await this.getUserByUsername(this.username)
        this.userId = this.user?.user_id || null
        await this.bootstrapLessons()
      } catch (e) {
        console.warn('Stored username invalid, clearing.', e)
        this.logout(true)
        this.openLogin()
      }
    } else {
      this.openLogin()
    }
  },

  beforeUnmount() {
    this.clearAdvanceTimer()
  }
}
</script>
EOF

# Create components
echo "🧩 Creating Vue components..."

# CongratsModal.vue
cat > src/components/CongratsModal.vue << 'EOF'
<template>
  <transition name="fade">
    <div v-if="show" class="modal">
      <transition name="scale">
        <div class="modal-content">
          <h2>🎉 Congratulations!</h2>
          <p>You solved 3 problems correctly in a row!</p>
          <div class="flex justify-center gap-2 mt-3">
            <button class="btn primary" @click="$emit('advance')">
              Unlock next lesson
            </button>
            <button class="btn secondary" @click="$emit('reset')">
              Stay &amp; reset
            </button>
          </div>
        </div>
      </transition>
    </div>
  </transition>
</template>

<script>
export default {
  name: 'CongratsModal',
  props: {
    show: Boolean
  },
  emits: ['update:show', 'advance', 'reset']
}
</script>
EOF

# RevealModal.vue
cat > src/components/RevealModal.vue << 'EOF'
<template>
  <transition name="fade">
    <div v-if="show" class="modal">
      <transition name="scale">
        <div 
          class="modal-content" 
          tabindex="0"
          ref="modalContent"
          @keydown.escape.prevent="$emit('cancel')"
          @keydown.enter.prevent="$emit('confirm')"
        >
          <h2>Reveal answer?</h2>
          <p class="muted small -mt-1">
            If you reveal, this problem will be skipped and we'll move to the next problem. 
            It won't count toward your streak.
          </p>
          <div class="flex justify-center gap-2 mt-3">
            <button class="btn primary" @click="$emit('confirm')">
              Reveal &amp; Skip to Next Problem
            </button>
            <button class="btn secondary" @click="$emit('cancel')">Cancel</button>
          </div>
        </div>
      </transition>
    </div>
  </transition>
</template>

<script>
export default {
  name: 'RevealModal',
  props: {
    show: Boolean
  },
  emits: ['update:show', 'confirm', 'cancel'],
  
  watch: {
    show(newVal) {
      if (newVal) {
        this.$nextTick(() => {
          this.$refs.modalContent?.focus()
        })
      }
    }
  }
}
</script>
EOF

# LoginModal.vue
cat > src/components/LoginModal.vue << 'EOF'
<template>
  <transition name="fade">
    <div v-if="show" class="modal" @click.self="$emit('update:show', false)">
      <transition name="scale">
        <div class="modal-content" @keydown.enter.prevent="$emit('login')">
          <h2>Sign in</h2>
          <p class="muted small -mt-1">
            Enter a username to start or continue. We'll create your account if it doesn't exist.
          </p>

          <div class="grid gap-3 text-left mt-3">
            <div class="panel">
              <div class="flex items-center gap-2">
                <input 
                  class="input flex-1" 
                  placeholder="Your username (e.g. alice)" 
                  :value="username"
                  @input="$emit('update:username', $event.target.value)"
                  ref="usernameInput"
                />
                <button class="btn secondary" @click="$emit('login')">Continue</button>
              </div>
            </div>
            <div v-if="error" class="status small">{{ error }}</div>
          </div>
        </div>
      </transition>
    </div>
  </transition>
</template>

<script>
export default {
  name: 'LoginModal',
  props: {
    show: Boolean,
    username: String,
    error: String
  },
  emits: ['update:show', 'update:username', 'login'],
  
  watch: {
    show(newVal) {
      if (newVal) {
        this.$nextTick(() => {
          this.$refs.usernameInput?.focus()
        })
      }
    }
  }
}
</script>
EOF

echo "✅ Project setup complete!"
echo ""
echo "📂 Created project structure:"
echo "   s-expression-vite/"
echo "   ├── src/"
echo "   │   ├── components/"
echo "   │   │   ├── CongratsModal.vue"
echo "   │   │   ├── LoginModal.vue"
echo "   │   │   └── RevealModal.vue"
echo "   │   ├── App.vue"
echo "   │   ├── main.js"
echo "   │   └── style.css"
echo "   ├── public/"
echo "   ├── package.json"
echo "   ├── vite.config.js"
echo "   ├── index.html"
echo "   ├── .env"
echo "   └── Dockerfile.dev"
echo ""
echo "🚀 Next steps:"
echo "   cd $PROJECT_NAME"
echo "   npm install"
echo "   npm run dev"
echo ""
echo "💡 Your app will be available at: http://localhost:3000"
echo "🔗 Make sure your backend API is running at: http://localhost:8000"
echo ""
echo "🐳 For Docker development:"
echo "   docker-compose --profile development up"