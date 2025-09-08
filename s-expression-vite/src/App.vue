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

      <RacketRepl/>

      <!-- Debug Info (optional) -->
      <!--
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
      -->

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
        ref="reviewModal"                
        v-model:show="showReview"
        :problem="currentProblemForReview"
        v-model:answer="reviewAnswer"
        :isRevealed="reviewIsRevealed"
        :isLoadingNext="reviewLoading"
        :resultVisible="reviewResultVisible"
        :resultOk="reviewResultOk"
        :resultMessage="reviewResultMessage"
        :lessons="lessons"
        @check="handleReviewCheck"
        @reveal="handleReviewReveal"
        @redirect-to-lesson="handleLessonRedirect"
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
import { watch } from "vue";
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
import RacketRepl from "./components/RacketRepl.vue";

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
    RacketRepl,
  },

  setup() {
    // Composables
    const auth = useAuth();
    const api = useApi();
    const lessons = useLessons(api, auth);
    const practice = usePractice(api, auth, lessons);
    const review = useReview(api, auth, lessons);
    const loginHandler = useLoginHandler(api, auth, lessons);

    // Provide hasAccessToLesson for child components
    const provide = {
      hasAccessToLesson: lessons.hasAccessToLesson,
    };

    const handleLessonRedirect = async (lessonId) => {
      console.log("handleLessonRedirect called with lessonId:", lessonId);
      try {
        lessons.currentView.value = "practice";

        const lessonIndex = lessons.lessons.value.findIndex(
          (l) => l.id === lessonId
        );
        console.log("Found lesson at index:", lessonIndex);

        if (lessonIndex === -1) throw new Error("Lesson not found");

        await lessons.setLessonByIndex(lessonIndex);
        await practice.loadProblemsForLesson(lessonId);

        practice.setResult(
          true,
          `📚 Switched to "${lessons.currentLesson.value?.title}" - review the lesson content to better understand this topic!`
        );

        setTimeout(() => {
          const lessonElement = document.getElementById("lessonCard");
          if (lessonElement) {
            lessonElement.scrollIntoView({ behavior: "smooth", block: "start" });
          }
        }, 100);
      } catch (error) {
        console.error("Failed to redirect to lesson:", error);
        practice.setResult(false, "Failed to load the lesson. Please try again.");
      }
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

          // Preload problems for the initial lesson
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

    // Load problems on first enter to practice view (if not loaded yet)
    watch(
      () => lessons.currentView.value,
      async (v) => {
        if (v === "practice" && !practice.currentProblem.value) {
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

      handleLessonRedirect,

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

  methods: {
    // ✅ Global Esc handler with a clear close priority
    _onGlobalKey(e) {
      if (e.key !== "Escape") return;

      // 1) If nested redirect modal inside ReviewProblem is open, close it first
      const rp = this.$refs.reviewModal;
      if (
        this.showReview &&
        rp &&
        typeof rp.closeLessonRedirect === "function" &&
        rp.showLessonRedirect
      ) {
        rp.closeLessonRedirect();
        e.preventDefault();
        return;
      }

      // 2) Otherwise close the main ReviewProblem modal
      if (this.showReview) {
        this.showReview = false;
        e.preventDefault();
        return;
      }

      // 3) Fall back to other modals (order can be adjusted)
      if (this.showRevealConfirm) {
        this.showRevealConfirm = false;
        e.preventDefault();
        return;
      }
      if (this.showModal) {
        this.showModal = false;
        e.preventDefault();
        return;
      }
      if (this.showLogin) {
        this.showLogin = false;
        e.preventDefault();
        return;
      }
    },
  },

  async mounted() {
    await this.initialize();
    // Attach global key listener for Esc
    window.addEventListener("keydown", this._onGlobalKey);
  },

  beforeUnmount() {
    this.cancelRandomReviewTicker?.();
    this.clearAdvanceTimer?.();
    // Clean up listener
    window.removeEventListener("keydown", this._onGlobalKey);
  },
};
</script>
