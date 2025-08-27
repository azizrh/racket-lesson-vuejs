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
