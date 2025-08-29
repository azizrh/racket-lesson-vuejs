<template>
  <div class="app">
    <!-- Header -->
    <AppHeader
      :current-view="currentView"
      :username="username"
      @go-home="goHome"
      @open-login="openLogin"
      @logout="logout"
    />

    <div v-if="currentView === 'home'">
      <!-- Test button to trigger review -->
      <button
        class="btn primary"
        :disabled="reviewBtnLoading"
        @click="triggerReviewNow"
        style="margin: 10px"
      >
        <span v-if="reviewBtnLoading">Loading…</span>
        <span v-else>Test Review Modal</span>
      </button>

      <!-- Debug Info -->
      <div
        style="
          background: #000000;
          padding: 10px;
          margin: 10px;
          border-radius: 4px;
          font-family: monospace;
        "
      >
        <strong>Debug Info:</strong><br />
        showReview: {{ showReview }}<br />
        currentProblemForReview: {{ currentProblemForReview }}<br />
        currentView: {{ currentView }}<br />
        username: {{ username }}<br />
        currentProblem: {{ currentProblem }}<br />
      </div>

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

      <ReviewProblem
        v-model:show="showReview"
        :problem="currentProblemForReview"
        v-model:answer="reviewAnswer"
        :isRevealed="reviewIsRevealed"
        :isLoadingNext="reviewLoading"
        :resultVisible="reviewResultVisible"
        :resultOk="reviewResultOk"
        :resultMessage="reviewResultMessage"
        @check="handleReviewCheck"
        @reveal="handleReviewReveal"
      />
    </div>

    <!-- Practice View -->
    <PracticeView
      v-else-if="currentView === 'practice'"
      :show-login="showLogin"
      :lessons="lessons"
      :lesson-idx="lessonIdx"
      :selected-lesson-id="selectedLessonId"
      :lesson-body-html="lessonBodyHtml"
      :current-problem="currentProblem"
      :answer="answer"
      :is-revealed="isRevealed"
      :is-loading-next="isLoadingNext"
      :result-visible="resultVisible"
      :result-ok="resultOk"
      :result-message="resultMessage"
      :prev-disabled="prevDisabled"
      :next-disabled="nextDisabled"
      :user="user"
      @set-lesson-by-index="setLessonByIndex"
      @set-lesson-by-id="setLessonById"
      @update:answer="answer = $event"
      @check="check"
      @reveal="reveal"
    />

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
import { watch } from 'vue' // 🔹 NEW
import { useAuth } from "./composables/useAuth";
import { useLessons } from "./composables/useLessons";
import { usePractice } from "./composables/usePractice";
import { useReview } from "./composables/useReview";
import { useApi } from "./composables/useApi";
import { useLoginHandler } from "./composables/useLoginHandler";

import AppHeader from "./components/AppHeader.vue";
import PracticeView from "./components/PracticeView.vue";
import CongratsModal from "./components/CongratsModal.vue";
import RevealModal from "./components/RevealModal.vue";
import LoginModal from "./components/LoginModal.vue";
import HomePage from "./components/HomePage.vue";
import ReviewProblem from "./components/ReviewProblem.vue";

export default {
  name: "App",
  components: {
    AppHeader,
    PracticeView,
    CongratsModal,
    RevealModal,
    LoginModal,
    HomePage,
    ReviewProblem,
  },

  setup() {
    // Composables
    const auth = useAuth();
    const api = useApi();
    const lessons = useLessons(api, auth);
    const practice = usePractice(api, auth, lessons);
    const review = useReview(api, auth, lessons);
    const loginHandler = useLoginHandler(api, auth, lessons);

    // Provide hasAccessToLesson for child components (kept as-is)
    const provide = {
      hasAccessToLesson: lessons.hasAccessToLesson,
    };

    // Initialize app
    const initialize = async () => {
      auth.loadLocalUser();
      await lessons.loadLessonsData();

      if (auth.username.value) {
        try {
          auth.user.value = await api.getUserByUsername(auth.username.value);
          auth.userId.value = auth.user.value?.user_id || null;
          await lessons.bootstrapLessons();

          // 🔹 NEW: Preload problems for the initial lesson so PracticeView has data
          const initialLessonId =
            auth.user.value?.active_lesson ??
            lessons.lessons.value?.[0]?.id ??
            null;

          if (initialLessonId != null) {
            await practice.loadProblemsForLesson(Number(initialLessonId));
          }
        } catch (e) {
          console.warn("Stored username invalid, clearing.", e);
          auth.logout(true);
          auth.openLogin();
        }
      } else {
        auth.openLogin();
      }

      review.maybeStartRandomReviewTicker();
    };

    // 🔹 NEW: When user navigates to 'practice', ensure problems are loaded once
    watch(
      () => lessons.currentView.value,
      async (v) => {
        if (v === 'practice' && !practice.currentProblem.value) {
          const id =
            lessons.selectedLessonId?.value ??
            auth.user.value?.active_lesson ??
            lessons.lessons.value?.[0]?.id ??
            null;
          if (id != null) {
            await practice.loadProblemsForLesson(Number(id));
          }
        }
      },
      { immediate: false }
    );

    return {
      // Auth
      ...auth,

      // Lessons
      ...lessons,

      // Practice
      ...practice,

      // Review
      ...review,

      // Login
      ...loginHandler,

      // Custom handlers
      setLessonByIndex: async (newIdx) => {
        try {
          const target = await lessons.setLessonByIndex(newIdx);
          await practice.loadProblemsForLesson(target.id);
        } catch (e) {
          practice.setResult(false, e.message);
        }
      },
      setLessonById: async (id) => {
        try {
          await lessons.setLessonById(id);
          await practice.loadProblemsForLesson(Number(id));
        } catch (e) {
          practice.setResult(false, e.message);
        }
      },

      // Initialize
      initialize,

      // Provide
      provide,
    };
  },

  async mounted() {
    await this.initialize();
  },

  beforeUnmount() {
    this.cancelRandomReviewTicker?.();
    this.clearAdvanceTimer?.();
  },
};
</script>
