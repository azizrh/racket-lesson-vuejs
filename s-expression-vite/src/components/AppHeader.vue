<template>
  <header>
    <div class="wrap">
      <div class="header-left">
        <h1 @click="$emit('goHome')" class="clickable">S-Expression Practice</h1>
        <nav v-if="currentView === 'practice'" class="nav-breadcrumb">
          <span class="nav-separator">•</span>
          <span class="nav-item">Lesson + Validator</span>
        </nav>
      </div>
      <div class="flex items-center gap-2">
        <button
          v-if="currentView === 'practice'"
          class="btn secondary"
          @click="$emit('goHome')"
        >
          ← Home
        </button>
        <span v-if="username" class="pill">
          Signed in as <strong>{{ username }}</strong>
        </span>
        <button v-if="!username" class="btn secondary" @click="$emit('openLogin')">
          Sign in
        </button>
        <button v-if="username" class="btn secondary" @click="$emit('logout')">
          Log out
        </button>
      </div>
    </div>
  </header>
</template>

<script>
export default {
  name: 'AppHeader',
  props: {
    currentView: String,
    username: String,
  },
  emits: ['goHome', 'openLogin', 'logout']
}
</script>