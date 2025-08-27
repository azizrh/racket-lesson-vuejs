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
