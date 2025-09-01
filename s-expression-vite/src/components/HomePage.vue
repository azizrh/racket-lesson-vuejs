<template>
  <div class="home-page">
    <!-- Hero Section -->
    <section class="hero">
      <div class="hero-content">
        <h1 class="hero-title">S-Expression Practice</h1>
        <p class="hero-subtitle">Master S-expressions through interactive lessons and real-time validation</p>
        <div v-if="!username" class="hero-actions">
          <button class="btn primary large" @click="$emit('open-login')">
            Get Started
          </button>
        </div>
      </div>
    </section>

    <!-- User Progress -->
    <section v-if="username" class="progress-section">
      <div class="progress-card">
        <div class="progress-header">
          <h2>Your Progress</h2>
          <div class="user-badge">
            <span class="user-icon">👤</span>
            <span>{{ username }}</span>
          </div>
        </div>
        <div class="progress-stats">
          <div class="stat">
            <div class="stat-value">{{ unlockedLessonsCount }}</div>
            <div class="stat-label">Lessons Unlocked</div>
          </div>
          <div class="stat">
            <div class="stat-value">{{ totalLessonsCount }}</div>
            <div class="stat-label">Total Lessons</div>
          </div>
          <div class="stat">
            <div class="stat-value">{{ progressPercentage }}%</div>
            <div class="stat-label">Progress</div>
          </div>
        </div>
        <div class="progress-bar">
          <div class="progress-fill" :style="{ width: progressPercentage + '%' }"></div>
        </div>
      </div>
    </section>

    <!-- Lessons Grid -->
    <section class="lessons-section">
      <div class="lessons-header">
        <h2>Available Lessons</h2>
        <p class="lessons-subtitle">
          {{ username ? 'Click on an unlocked lesson to start practicing' : 'Sign in to track your progress and unlock lessons' }}
        </p>
      </div>

      <div v-if="loading" class="lessons-loading">
        <div class="spinner"></div>
        <p>Loading lessons...</p>
      </div>

      <div v-else-if="error" class="lessons-error">
        <p>❌ {{ error }}</p>
        <button class="btn secondary" @click="$emit('retry-load')">Try Again</button>
      </div>

      <div v-else class="lessons-grid">
        <div 
          v-for="(lesson, index) in lessons" 
          :key="lesson.id"
          class="lesson-card"
          :class="{ 
            'locked': !isLessonUnlocked(lesson.id),
            'current': isCurrentLesson(lesson.id),
            'clickable': isLessonUnlocked(lesson.id)
          }"
          @click="handleLessonClick(lesson)"
        >
          <!-- Lock/Unlock Indicator -->
          <div class="lesson-status">
            <span v-if="isLessonUnlocked(lesson.id)" class="status-icon unlocked">🔓</span>
            <span v-else class="status-icon locked">🔒</span>
          </div>

          <!-- Lesson Number -->
          <div class="lesson-number">{{ index + 1 }}</div>

          <!-- Lesson Content -->
          <div class="lesson-content">
            <h3 class="lesson-title">{{ lesson.title }}</h3>
            <p class="lesson-description">{{ lesson.description || 'Practice S-expression fundamentals' }}</p>
            
            <!-- Current Lesson Badge -->
            <div v-if="isCurrentLesson(lesson.id)" class="current-badge">
              <span>📍 Current Lesson</span>
            </div>

            <!-- Lesson Stats -->
            <div class="lesson-stats">
              <div class="stat-item">
                <span class="stat-icon">📝</span>
                <span>{{ lesson.problem_count || '...' }} Problems</span>
              </div>
              <div class="stat-item">
                <span class="stat-icon">⏱️</span>
                <span>{{ lesson.estimated_time || '15' }} min</span>
              </div>
            </div>
          </div>

          <!-- Action Button -->
          <div class="lesson-action">
            <button 
              v-if="isLessonUnlocked(lesson.id)"
              class="btn primary small"
              @click.stop="$emit('start-lesson', lesson.id)"
            >
              {{ isCurrentLesson(lesson.id) ? 'Continue' : 'Start' }}
            </button>
            <div v-else class="locked-message">
              <span>Complete previous lessons to unlock</span>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Getting Started Section -->
    <section v-if="!username" class="getting-started">
      <div class="getting-started-card">
        <h3>How it works</h3>
        <div class="steps">
          <div class="step">
            <div class="step-number">1</div>
            <div class="step-content">
              <h4>Sign in</h4>
              <p>Create an account to track your progress</p>
            </div>
          </div>
          <div class="step">
            <div class="step-number">2</div>
            <div class="step-content">
              <h4>Learn</h4>
              <p>Work through lessons with interactive examples</p>
            </div>
          </div>
          <div class="step">
            <div class="step-number">3</div>
            <div class="step-content">
              <h4>Practice</h4>
              <p>Solve problems with real-time validation</p>
            </div>
          </div>
          <div class="step">
            <div class="step-number">4</div>
            <div class="step-content">
              <h4>Progress</h4>
              <p>Unlock new lessons as you master concepts</p>
            </div>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>

<script>
export default {
  name: 'HomePage',
  props: {
    lessons: {
      type: Array,
      default: () => []
    },
    user: {
      type: Object,
      default: null
    },
    loading: {
      type: Boolean,
      default: false
    },
    error: {
      type: String,
      default: null
    },
    currentLessonId: {
      type: Number,
      default: null
    }
  },
  
  emits: ['open-login', 'start-lesson', 'retry-load'],

  computed: {
    username() {
      return this.user?.username
    },
    
    unlockedLessonsCount() {
      if (!this.user?.lessons) return 0
      return this.user.lessons.length
    },
    
    totalLessonsCount() {
      return this.lessons.length
    },
    
    progressPercentage() {
      if (this.totalLessonsCount === 0) return 0
      return Math.round((this.unlockedLessonsCount / this.totalLessonsCount) * 100)
    }
  },

  methods: {
    isLessonUnlocked(lessonId) {
      if (!this.user?.lessons) return false
      return this.user.lessons.includes(Number(lessonId))
    },

    isCurrentLesson(lessonId) {
      return this.currentLessonId === lessonId
    },

    handleLessonClick(lesson) {
      if (!this.isLessonUnlocked(lesson.id)) {
        // Show message about needing to unlock
        return
      }
      this.$emit('start-lesson', lesson.id)
    }
  }
}
</script>

<style scoped>
.home-page {
  min-height: 100vh;
  padding: 20px;
  max-width: 1200px;
  margin: 0 auto;
}

/* Hero Section */
.hero {
  text-align: center;
  padding: 40px 10px;
  background: linear-gradient(135deg, hsl(0 0% 8%) 0%, hsl(0 0% 12%) 100%);
  border-radius: var(--radius);
  margin-bottom: 20px;
  border: 1px solid hsl(var(--border));
}

.hero-title {
  font-size: 3rem;
  font-weight: 700;
  margin: 0 0 16px 0;
  background: linear-gradient(135deg, hsl(var(--foreground)) 0%, hsl(var(--muted-foreground)) 100%);
  background-clip: text;
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
}

.hero-subtitle {
  font-size: 1.25rem;
  color: hsl(var(--muted-foreground));
  margin: 0 0 32px 0;
  max-width: 600px;
  margin-left: auto;
  margin-right: auto;
}

.hero-actions {
  display: flex;
  justify-content: center;
  gap: 16px;
}

.btn.large {
  padding: 16px 32px;
  font-size: 1.1rem;
  font-weight: 600;
}

/* Progress Section */
.progress-section {
  margin-bottom: 40px;
}

.progress-card {
  background: hsl(var(--card));
  border: 1px solid hsl(var(--border));
  border-radius: var(--radius);
  padding: 24px;
  box-shadow: 0 4px 12px rgba(0,0,0,.1);
}

.progress-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.progress-header h2 {
  margin: 0;
  font-size: 1.5rem;
}

.user-badge {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 16px;
  background: hsl(0 0% 10%);
  border: 1px solid hsl(var(--border));
  border-radius: 999px;
  font-weight: 500;
}

.user-icon {
  font-size: 1.2rem;
}

.progress-stats {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
  gap: 20px;
  margin-bottom: 16px;
}

.stat {
  text-align: center;
}

.stat-value {
  font-size: 2rem;
  font-weight: 700;
  color: hsl(var(--foreground));
}

.stat-label {
  font-size: 0.875rem;
  color: hsl(var(--muted-foreground));
  margin-top: 4px;
}

.progress-bar {
  height: 8px;
  background: hsl(0 0% 15%);
  border-radius: 4px;
  overflow: hidden;
}

.progress-fill {
  height: 100%;
  background: linear-gradient(90deg, hsl(var(--foreground)) 0%, hsl(var(--muted-foreground)) 100%);
  transition: width 0.3s ease;
}

/* Lessons Section */
.lessons-section {
  margin-bottom: 40px;
}

.lessons-header {
  text-align: center;
  margin-bottom: 32px;
}

.lessons-header h2 {
  font-size: 2rem;
  margin: 0 0 8px 0;
}

.lessons-subtitle {
  color: hsl(var(--muted-foreground));
  margin: 0;
}

.lessons-loading {
  text-align: center;
  padding: 60px 20px;
}

.spinner {
  width: 40px;
  height: 40px;
  border: 3px solid hsl(var(--border));
  border-top: 3px solid hsl(var(--foreground));
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin: 0 auto 16px;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.lessons-error {
  text-align: center;
  padding: 60px 20px;
  color: hsl(var(--muted-foreground));
}

.lessons-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
  gap: 24px;
}

/* Lesson Cards */
.lesson-card {
  background: hsl(var(--card));
  border: 1px solid hsl(var(--border));
  border-radius: var(--radius);
  padding: 24px;
  position: relative;
  transition: all 0.2s ease;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.lesson-card.clickable {
  cursor: pointer;
}

.lesson-card.clickable:hover {
  border-color: hsl(var(--ring));
  box-shadow: 0 8px 24px rgba(0,0,0,.2);
  transform: translateY(-2px);
}

.lesson-card.locked {
  opacity: 0.6;
  background: hsl(0 0% 6%);
}

.lesson-card.current {
  border-color: hsl(var(--foreground));
  box-shadow: 0 0 0 1px hsl(var(--foreground));
}

.lesson-status {
  position: absolute;
  top: 16px;
  right: 16px;
}

.status-icon {
  font-size: 1.5rem;
}

.lesson-number {
  width: 40px;
  height: 40px;
  background: hsl(0 0% 12%);
  border: 1px solid hsl(var(--border));
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 600;
  font-size: 1.1rem;
}

.lesson-content {
  flex: 1;
}

.lesson-title {
  font-size: 1.25rem;
  font-weight: 600;
  margin: 0 0 8px 0;
}

.lesson-description {
  color: hsl(var(--muted-foreground));
  margin: 0 0 12px 0;
  line-height: 1.4;
}

.current-badge {
  display: inline-block;
  background: hsl(var(--foreground));
  color: hsl(var(--background));
  padding: 4px 12px;
  border-radius: 999px;
  font-size: 0.75rem;
  font-weight: 500;
  margin-bottom: 12px;
}

.lesson-stats {
  display: flex;
  gap: 16px;
  margin-top: auto;
}

.stat-item {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 0.875rem;
  color: hsl(var(--muted-foreground));
}

.stat-icon {
  font-size: 1rem;
}

.lesson-action {
  margin-top: auto;
}

.btn.small {
  padding: 8px 16px;
  font-size: 0.875rem;
  width: 100%;
}

.locked-message {
  text-align: center;
  color: hsl(var(--muted-foreground));
  font-size: 0.875rem;
  padding: 8px;
}

/* Getting Started Section */
.getting-started {
  margin-top: 60px;
}

.getting-started-card {
  background: hsl(var(--card));
  border: 1px solid hsl(var(--border));
  border-radius: var(--radius);
  padding: 32px;
  text-align: center;
}

.getting-started-card h3 {
  font-size: 1.5rem;
  margin: 0 0 32px 0;
}

.steps {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 24px;
  max-width: 800px;
  margin: 0 auto;
}

.step {
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
}

.step-number {
  width: 48px;
  height: 48px;
  background: hsl(var(--foreground));
  color: hsl(var(--background));
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 600;
  font-size: 1.25rem;
  margin-bottom: 12px;
}

.step-content h4 {
  margin: 0 0 8px 0;
  font-size: 1.1rem;
}

.step-content p {
  margin: 0;
  color: hsl(var(--muted-foreground));
  line-height: 1.4;
}

/* Responsive */
@media (max-width: 768px) {
  .hero-title {
    font-size: 2rem;
  }
  
  .lessons-grid {
    grid-template-columns: 1fr;
  }
  
  .progress-stats {
    grid-template-columns: repeat(3, 1fr);
  }
  
  .steps {
    grid-template-columns: 1fr;
  }
}
</style>