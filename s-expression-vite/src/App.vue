<template>
  <div class="app">
    <!-- Header -->
<header>
  <div class="wrap">
    <div class="header-left">
      <h1 @click="goHome" class="clickable">S-Expression Practice</h1>
      <nav v-if="currentView === 'practice'" class="nav-breadcrumb">
        <span class="nav-separator">•</span>
        <span class="nav-item">Lesson + Validator</span>
      </nav>
    </div>
    <div class="flex items-center gap-2">
      <button v-if="currentView === 'practice'" class="btn secondary" @click="goHome">
        ← Home
      </button>
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

<div v-if="currentView === 'home'">
  <HomePage 
    :lessons="lessons"
    :user="user"
    :loading="lessonsLoading"
    :error="lessonsError"
    :current-lesson-id="user?.active_lesson"
    @open-login="openLogin"
    @start-lesson="startLesson"
    @retry-load="loadLessonsData"
  />
</div>


    <!-- Main Content -->
    <main v-else-if="currentView === 'practice'" :style="showLogin ? 'filter: blur(2px); pointer-events:none; user-select:none;' : ''">
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
import HomePage from './components/HomePage.vue'

export default {
  name: 'App',
  components: {
    CongratsModal,
    RevealModal,
    LoginModal,
    HomePage
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

      currentView: 'home', // <-- ADD THIS (for routing between home/practice)
      lessonsLoading: false, // <-- ADD THIS
      lessonsError: null,    // <-- ADD THIS

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

    goHome() {
      this.currentView = 'home'
    },

    async startLesson(lessonId) {
      this.currentView = 'practice'
      await this.setLessonById(lessonId)
      this.$nextTick(() => {
        if (this.$refs.answerInput) {
          this.$refs.answerInput.focus()
        }
      })
    },

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
    async loadLessonsData() {
      this.lessonsLoading = true
      this.lessonsError = null
      
      try {
        const lessons = await this.listLessons()
        
        // Enrich lessons with problem counts and estimated times
        for (const lesson of lessons) {
          try {
            const problems = await this.loadProblems(lesson.id)
            lesson.problem_count = problems.length
            lesson.estimated_time = Math.max(5, Math.ceil(problems.length * 2.5))
          } catch (e) {
            lesson.problem_count = 0
            lesson.estimated_time = 15
          }
        }
    
    this.lessons = lessons
  } catch (err) {
    console.error('Failed to load lessons:', err)
    this.lessonsError = err.message || 'Failed to load lessons'
  } finally {
    this.lessonsLoading = false
  }
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
      this.currentView = 'home'  // <-- ADD THIS LINE
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
    await this.loadLessonsData()  // <-- ADD THIS LINE
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
