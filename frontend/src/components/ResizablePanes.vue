<template>
  <div class="resizable-panes">
    <div 
      ref="leftPane"
      class="pane left-pane"
      :style="{ width: leftWidth + 'px' }"
    >
      <slot name="left" />
    </div>
    
    <div 
      class="resizer"
      @mousedown="startResize"
      :class="{ 'resizing': isResizing }"
    ></div>
    
    <div 
      class="pane right-pane"
      :style="{ width: rightWidth + 'px' }"
    >
      <slot name="right" />
    </div>
  </div>
</template>

<script lang="ts">
import { defineComponent, ref, computed, onMounted, onUnmounted } from 'vue'

export interface ResizablePanesProps {
  initialLeftWidth?: number
  minLeftWidth?: number
  minRightWidth?: number
}

export default defineComponent({
  name: 'ResizablePanes',
  props: {
    initialLeftWidth: {
      type: Number,
      default: 400
    },
    minLeftWidth: {
      type: Number,
      default: 200
    },
    minRightWidth: {
      type: Number,
      default: 300
    }
  },
  emits: ['resize'],
  setup(props, { emit }) {
    const leftPane = ref<HTMLElement>()
    const isResizing = ref(false)
    const leftWidth = ref(props.initialLeftWidth)
    const containerWidth = ref(1200)

    const rightWidth = computed(() => containerWidth.value - leftWidth.value - 4) // 4px for resizer

    let startX = 0
    let startLeftWidth = 0

    const startResize = (e: MouseEvent) => {
      isResizing.value = true
      startX = e.clientX
      startLeftWidth = leftWidth.value

      document.addEventListener('mousemove', doResize)
      document.addEventListener('mouseup', stopResize)
      document.body.style.cursor = 'col-resize'
      e.preventDefault()
    }

    const doResize = (e: MouseEvent) => {
      if (!isResizing.value) return

      const deltaX = e.clientX - startX
      let newLeftWidth = startLeftWidth + deltaX

      // Apply constraints
      newLeftWidth = Math.max(props.minLeftWidth, newLeftWidth)
      newLeftWidth = Math.min(containerWidth.value - props.minRightWidth - 4, newLeftWidth)

      leftWidth.value = newLeftWidth
      emit('resize', { leftWidth: newLeftWidth, rightWidth: rightWidth.value })
    }

    const stopResize = () => {
      isResizing.value = false
      document.removeEventListener('mousemove', doResize)
      document.removeEventListener('mouseup', stopResize)
      document.body.style.cursor = 'default'
    }

    const updateContainerWidth = () => {
      if (leftPane.value?.parentElement) {
        containerWidth.value = leftPane.value.parentElement.offsetWidth
      }
    }

    onMounted(() => {
      updateContainerWidth()
      window.addEventListener('resize', updateContainerWidth)
    })

    onUnmounted(() => {
      window.removeEventListener('resize', updateContainerWidth)
      document.removeEventListener('mousemove', doResize)
      document.removeEventListener('mouseup', stopResize)
    })

    return {
      leftPane,
      isResizing,
      leftWidth,
      rightWidth,
      startResize
    }
  }
})
</script>

<style scoped>
.resizable-panes {
  display: flex;
  height: 100%;
  overflow: hidden;
}

.pane {
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.left-pane {
  border-right: 1px solid var(--color-border);
}

.right-pane {
  flex: 1;
}

.resizer {
  width: 4px;
  background-color: var(--color-border);
  cursor: col-resize;
  transition: background-color 0.2s;
  position: relative;
}

.resizer:hover,
.resizer.resizing {
  background-color: var(--color-border-hover);
}

.resizer::before {
  content: '';
  position: absolute;
  top: 0;
  left: -2px;
  right: -2px;
  bottom: 0;
  cursor: col-resize;
}

/* 防止文本选择 */
.resizable-panes.resizing * {
  user-select: none;
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
}
</style>
