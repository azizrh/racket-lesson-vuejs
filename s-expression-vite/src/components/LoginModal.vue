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
