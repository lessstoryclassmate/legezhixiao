<template>
  <div class="vscode-editor-layout">
    <!-- 顶部工具栏 -->
    <div class="top-toolbar">
      <div class="toolbar-left">
        <button @click="toggleFileExplorer" class="btn-tool" :class="{ active: showFileExplorer }">
          📁 文件管理器
        </button>
        <button @click="toggleAIChat" class="btn-tool" :class="{ active: showAIChat }">
          🤖 AI助手
        </button>
      </div>
      
      <div class="toolbar-center">
        <div class="novel-selector">
          <select v-model="currentNovelId" @change="onNovelChange">
            <option value="">选择小说项目...</option>
            <option v-for="novel in novels" :key="novel.id" :value="novel.id">
              {{ novel.title }}
            </option>
          </select>
          <button @click="createNewNovel" class="btn-new-novel">+ 新建小说</button>
        </div>
      </div>
      
      <div class="toolbar-right">
        <button @click="saveAll" class="btn-tool" :disabled="!hasUnsavedChanges">
          💾 保存全部
        </button>
        <button @click="openSettings" class="btn-tool">
          ⚙️ 设置
        </button>
      </div>
    </div>

    <!-- 主要内容区域 -->
    <div class="main-content">
      <!-- 左侧面板 -->
      <div v-if="showFileExplorer" class="left-panel" :style="{ width: leftPanelWidth + 'px' }">
        <MDFileExplorer 
          ref="fileExplorer"
          @file-selected="onFileSelected"
          @file-opened="onFileOpened"
          @file-created="onFileCreated"
        />
      </div>

      <!-- 左侧调整器 -->
      <div 
        v-if="showFileExplorer"
        class="left-resizer"
        @mousedown="startLeftResize"
      ></div>

      <!-- 中间编辑器区域 -->
      <div class="editor-area" ref="editorArea">
        <MDEditor 
          ref="mdEditor"
          :current-file="currentFile"
          @file-saved="onFileSaved"
          @create-file="onCreateFile"
          @tab-changed="onTabChanged"
        />
      </div>

      <!-- 右侧调整器 -->
      <div 
        v-if="showAIChat"
        class="right-resizer"
        @mousedown="startRightResize"
      ></div>

      <!-- 右侧AI助手面板 -->
      <div v-if="showAIChat" class="right-panel" :style="{ width: rightPanelWidth + 'px' }">
        <AIChat 
          ref="aiChat"
          :current-file="currentFile"
          @insert-content="onInsertContent"
          @create-file="onCreateFile"
          @update-file="onUpdateFile"
        />
      </div>
    </div>

    <!-- 底部状态栏 -->
    <div class="bottom-status-bar">
      <div class="status-left">
        <span v-if="currentNovel" class="status-item">
          📚 {{ currentNovel.title }}
        </span>
        <span v-if="currentFile" class="status-item">
          📄 {{ currentFile.name }}
        </span>
        <span class="status-item">
          📁 {{ fileCount }} 个文件
        </span>
      </div>
      
      <div class="status-center">
        <span v-if="isProcessing" class="status-item processing">
          ⏳ {{ processingMessage }}
        </span>
      </div>
      
      <div class="status-right">
        <span class="status-item">
          🔗 {{ connectionStatus }}
        </span>
        <span class="status-item">
          🕐 {{ currentTime }}
        </span>
      </div>
    </div>

    <!-- 新建小说对话框 -->
    <div v-if="showNewNovelDialog" class="modal-overlay" @click.self="closeNewNovelDialog">
      <div class="modal">
        <div class="modal-header">
          <h3>新建小说项目</h3>
          <button @click="closeNewNovelDialog" class="btn-close">×</button>
        </div>
        <div class="modal-body">
          <div class="form-group">
            <label>小说标题:</label>
            <input 
              v-model="newNovel.title" 
              type="text" 
              placeholder="请输入小说标题"
              @keyup.enter="confirmCreateNovel"
            />
          </div>
          <div class="form-group">
            <label>小说类型:</label>
            <select v-model="newNovel.genre">
              <option value="fantasy">奇幻</option>
              <option value="romance">言情</option>
              <option value="scifi">科幻</option>
              <option value="historical">历史</option>
              <option value="modern">现代</option>
              <option value="mystery">悬疑</option>
              <option value="other">其他</option>
            </select>
          </div>
          <div class="form-group">
            <label>简介:</label>
            <textarea 
              v-model="newNovel.description" 
              rows="4"
              placeholder="请输入小说简介..."
            ></textarea>
          </div>
        </div>
        <div class="modal-footer">
          <button @click="closeNewNovelDialog" class="btn-secondary">取消</button>
          <button @click="confirmCreateNovel" class="btn-primary">创建</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import { defineComponent, ref, computed, onMounted, onUnmounted, nextTick } from 'vue'
import MDFileExplorer from '@/components/MDFileExplorer.vue'
import MDEditor from '@/components/MDEditor.vue'
import AIChat from '@/components/AIChat.vue'

interface Novel {
  id: string
  title: string
  genre: string
  description: string
  createdAt: string
  updatedAt: string
}

interface MDFile {
  id: string
  name: string
  type: string
  content: string
  modified: boolean
  novelId: string
  path: string
}

export default defineComponent({
  name: 'VSCodeMDEditor',
  components: {
    MDFileExplorer,
    MDEditor,
    AIChat
  },
  setup() {
    const fileExplorer = ref()
    const mdEditor = ref()
    const aiChat = ref()
    const editorArea = ref()

    // 界面状态
    const showFileExplorer = ref(true)
    const showAIChat = ref(true)
    const leftPanelWidth = ref(300)
    const rightPanelWidth = ref(400)
    
    // 数据状态
    const novels = ref<Novel[]>([])
    const currentNovelId = ref('')
    const currentFile = ref<MDFile | null>(null)
    const fileCount = ref(0)
    const hasUnsavedChanges = ref(false)
    const isProcessing = ref(false)
    const processingMessage = ref('')
    const connectionStatus = ref('已连接')
    const currentTime = ref('')

    // 新建小说
    const showNewNovelDialog = ref(false)
    const newNovel = ref({
      title: '',
      genre: 'fantasy',
      description: ''
    })

    const currentNovel = computed(() => {
      return novels.value.find(n => n.id === currentNovelId.value)
    })

    // 面板调整相关
    let isResizingLeft = false
    let isResizingRight = false
    let startX = 0
    let startWidth = 0

    const startLeftResize = (e: MouseEvent) => {
      isResizingLeft = true
      startX = e.clientX
      startWidth = leftPanelWidth.value
      
      document.addEventListener('mousemove', doLeftResize)
      document.addEventListener('mouseup', stopLeftResize)
      document.body.style.cursor = 'col-resize'
      e.preventDefault()
    }

    const doLeftResize = (e: MouseEvent) => {
      if (!isResizingLeft) return
      
      const deltaX = e.clientX - startX
      let newWidth = startWidth + deltaX
      
      newWidth = Math.max(200, Math.min(600, newWidth))
      leftPanelWidth.value = newWidth
    }

    const stopLeftResize = () => {
      isResizingLeft = false
      document.removeEventListener('mousemove', doLeftResize)
      document.removeEventListener('mouseup', stopLeftResize)
      document.body.style.cursor = 'default'
    }

    const startRightResize = (e: MouseEvent) => {
      isResizingRight = true
      startX = e.clientX
      startWidth = rightPanelWidth.value
      
      document.addEventListener('mousemove', doRightResize)
      document.addEventListener('mouseup', stopRightResize)
      document.body.style.cursor = 'col-resize'
      e.preventDefault()
    }

    const doRightResize = (e: MouseEvent) => {
      if (!isResizingRight) return
      
      const deltaX = startX - e.clientX
      let newWidth = startWidth + deltaX
      
      newWidth = Math.max(300, Math.min(800, newWidth))
      rightPanelWidth.value = newWidth
    }

    const stopRightResize = () => {
      isResizingRight = false
      document.removeEventListener('mousemove', doRightResize)
      document.removeEventListener('mouseup', stopRightResize)
      document.body.style.cursor = 'default'
    }

    // 界面操作
    const toggleFileExplorer = () => {
      showFileExplorer.value = !showFileExplorer.value
    }

    const toggleAIChat = () => {
      showAIChat.value = !showAIChat.value
    }

    const onNovelChange = () => {
      // 切换小说时重新加载文件列表
      if (fileExplorer.value) {
        fileExplorer.value.refreshFiles()
      }
    }

    const createNewNovel = () => {
      newNovel.value = {
        title: '',
        genre: 'fantasy',
        description: ''
      }
      showNewNovelDialog.value = true
    }

    const closeNewNovelDialog = () => {
      showNewNovelDialog.value = false
    }

    const confirmCreateNovel = async () => {
      if (!newNovel.value.title.trim()) {
        alert('请输入小说标题')
        return
      }

      isProcessing.value = true
      processingMessage.value = '创建小说项目...'

      try {
        const novel: Novel = {
          id: `novel_${Date.now()}`,
          title: newNovel.value.title,
          genre: newNovel.value.genre,
          description: newNovel.value.description,
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString()
        }

        novels.value.push(novel)
        currentNovelId.value = novel.id

        // 创建小说基础文件
        await createNovelBaseFiles(novel)
        
        closeNewNovelDialog()
      } catch (error) {
        console.error('创建小说失败:', error)
        alert('创建小说失败，请重试')
      } finally {
        isProcessing.value = false
        processingMessage.value = ''
      }
    }

    const createNovelBaseFiles = async (novel: Novel) => {
      const baseFiles = [
        {
          type: 'novel',
          name: '小说信息',
          content: `---
file_type: "novel"
novel_id: "${novel.id}"
title: "${novel.title}"
genre: "${novel.genre}"
description: "${novel.description}"
created_at: "${novel.createdAt}"
updated_at: "${novel.updatedAt}"
status: "draft"
---

# ${novel.title}

## 小说基本信息
- **标题**: ${novel.title}
- **类型**: ${novel.genre}
- **状态**: 创作中
- **字数**: 0

## 故事简介
${novel.description}

## 主要角色
（待补充）

## 创作笔记
（待补充）
`
        }
      ]

      for (const fileData of baseFiles) {
        if (fileExplorer.value) {
          fileExplorer.value.createFile(fileData)
        }
      }
    }

    // 文件操作
    const onFileSelected = (file: MDFile) => {
      currentFile.value = file
    }

    const onFileOpened = (file: MDFile) => {
      currentFile.value = file
      if (mdEditor.value) {
        mdEditor.value.openFile(file)
      }
    }

    const onFileCreated = (file: MDFile) => {
      fileCount.value++
      onFileOpened(file)
    }

    const onFileSaved = (data: { id: string; content: string }) => {
      // TODO: 保存到后端API
      console.log('文件已保存:', data)
      hasUnsavedChanges.value = false
    }

    const onTabChanged = (tab: any) => {
      currentFile.value = tab
      hasUnsavedChanges.value = tab?.modified || false
    }

    const onCreateFile = (fileData: any) => {
      if (fileExplorer.value) {
        fileExplorer.value.createFile(fileData)
      }
    }

    const onUpdateFile = (fileData: any) => {
      if (mdEditor.value) {
        mdEditor.value.updateFile(fileData)
      }
    }

    const onInsertContent = (content: string) => {
      if (mdEditor.value) {
        mdEditor.value.insertContent(content)
      }
    }

    const saveAll = async () => {
      if (mdEditor.value) {
        await mdEditor.value.saveAllFiles()
      }
      hasUnsavedChanges.value = false
    }

    const openSettings = () => {
      // TODO: 实现设置面板
      console.log('打开设置面板')
    }

    // 时间更新
    const updateTime = () => {
      currentTime.value = new Date().toLocaleTimeString('zh-CN', {
        hour: '2-digit',
        minute: '2-digit'
      })
    }

    // 键盘快捷键
    const handleGlobalKeyDown = (e: KeyboardEvent) => {
      if (e.ctrlKey) {
        switch (e.key) {
          case 'b':
            e.preventDefault()
            toggleFileExplorer()
            break
          case 'j':
            e.preventDefault()
            toggleAIChat()
            break
          case 's':
            if (e.shiftKey) {
              e.preventDefault()
              saveAll()
            }
            break
        }
      }
    }

    onMounted(() => {
      // 加载小说列表
      loadNovels()
      
      // 开始时间更新
      updateTime()
      const timeInterval = setInterval(updateTime, 60000)
      
      // 注册全局快捷键
      document.addEventListener('keydown', handleGlobalKeyDown)
      
      // 清理
      onUnmounted(() => {
        clearInterval(timeInterval)
        document.removeEventListener('keydown', handleGlobalKeyDown)
        document.removeEventListener('mousemove', doLeftResize)
        document.removeEventListener('mouseup', stopLeftResize)
        document.removeEventListener('mousemove', doRightResize)
        document.removeEventListener('mouseup', stopRightResize)
      })
    })

    const loadNovels = async () => {
      // TODO: 从API加载小说列表
      // 模拟数据
      novels.value = [
        {
          id: 'novel_001',
          title: '示例小说',
          genre: 'fantasy',
          description: '这是一个示例小说项目',
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString()
        }
      ]
      
      if (novels.value.length > 0) {
        currentNovelId.value = novels.value[0].id
      }
    }

    return {
      fileExplorer,
      mdEditor,
      aiChat,
      editorArea,
      showFileExplorer,
      showAIChat,
      leftPanelWidth,
      rightPanelWidth,
      novels,
      currentNovelId,
      currentNovel,
      currentFile,
      fileCount,
      hasUnsavedChanges,
      isProcessing,
      processingMessage,
      connectionStatus,
      currentTime,
      showNewNovelDialog,
      newNovel,
      startLeftResize,
      startRightResize,
      toggleFileExplorer,
      toggleAIChat,
      onNovelChange,
      createNewNovel,
      closeNewNovelDialog,
      confirmCreateNovel,
      onFileSelected,
      onFileOpened,
      onFileCreated,
      onFileSaved,
      onTabChanged,
      onCreateFile,
      onUpdateFile,
      onInsertContent,
      saveAll,
      openSettings
    }
  }
})
</script>

<style scoped>
.vscode-editor-layout {
  height: 100vh;
  display: flex;
  flex-direction: column;
  background-color: var(--vscode-editor-background);
  color: var(--vscode-foreground);
  font-family: var(--vscode-font-family);
  overflow: hidden;
}

.top-toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 4px 8px;
  background-color: var(--vscode-titleBar-activeBackground);
  border-bottom: 1px solid var(--vscode-titleBar-border);
  min-height: 35px;
}

.toolbar-left,
.toolbar-right {
  display: flex;
  gap: 8px;
  align-items: center;
}

.toolbar-center {
  flex: 1;
  display: flex;
  justify-content: center;
}

.novel-selector {
  display: flex;
  align-items: center;
  gap: 8px;
}

.novel-selector select {
  padding: 4px 8px;
  border: 1px solid var(--vscode-input-border);
  background-color: var(--vscode-input-background);
  color: var(--vscode-input-foreground);
  border-radius: 3px;
  font-size: 12px;
  min-width: 200px;
}

.btn-new-novel {
  padding: 4px 8px;
  background-color: var(--vscode-button-background);
  color: var(--vscode-button-foreground);
  border: none;
  border-radius: 3px;
  cursor: pointer;
  font-size: 11px;
  font-weight: 500;
}

.btn-new-novel:hover {
  background-color: var(--vscode-button-hoverBackground);
}

.btn-tool {
  padding: 4px 8px;
  background: transparent;
  border: 1px solid transparent;
  color: var(--vscode-titleBar-activeForeground);
  cursor: pointer;
  border-radius: 3px;
  font-size: 11px;
  font-weight: 500;
  transition: all 0.2s;
}

.btn-tool:hover {
  background-color: var(--vscode-titleBar-hoverBackground);
}

.btn-tool.active {
  background-color: var(--vscode-button-background);
  color: var(--vscode-button-foreground);
}

.btn-tool:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}

.main-content {
  flex: 1;
  display: flex;
  overflow: hidden;
}

.left-panel {
  background-color: var(--vscode-sideBar-background);
  border-right: 1px solid var(--vscode-sideBar-border);
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.right-panel {
  background-color: var(--vscode-sideBar-background);
  border-left: 1px solid var(--vscode-sideBar-border);
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.left-resizer,
.right-resizer {
  width: 4px;
  background-color: var(--vscode-sideBar-border);
  cursor: col-resize;
  transition: background-color 0.2s;
  position: relative;
}

.left-resizer:hover,
.right-resizer:hover {
  background-color: var(--vscode-focusBorder);
}

.left-resizer::before,
.right-resizer::before {
  content: '';
  position: absolute;
  top: 0;
  left: -2px;
  right: -2px;
  bottom: 0;
  cursor: col-resize;
}

.editor-area {
  flex: 1;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.bottom-status-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 4px 12px;
  background-color: var(--vscode-statusBar-background);
  color: var(--vscode-statusBar-foreground);
  border-top: 1px solid var(--vscode-statusBar-border);
  font-size: 11px;
  min-height: 22px;
}

.status-left,
.status-center,
.status-right {
  display: flex;
  align-items: center;
  gap: 12px;
}

.status-center {
  flex: 1;
  justify-content: center;
}

.status-item {
  white-space: nowrap;
  opacity: 0.9;
}

.status-item.processing {
  color: var(--vscode-statusBar-prominentForeground);
  font-weight: 500;
}

/* 模态框样式 */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(0, 0, 0, 0.6);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal {
  background-color: var(--vscode-editor-background);
  border: 1px solid var(--vscode-contrastBorder);
  border-radius: 6px;
  width: 500px;
  max-width: 90vw;
  box-shadow: 0 12px 40px rgba(0, 0, 0, 0.4);
}

.modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 16px;
  border-bottom: 1px solid var(--vscode-contrastBorder);
  background-color: var(--vscode-titleBar-activeBackground);
}

.modal-header h3 {
  margin: 0;
  font-size: 14px;
  font-weight: 600;
  color: var(--vscode-titleBar-activeForeground);
}

.btn-close {
  border: none;
  background: transparent;
  font-size: 18px;
  cursor: pointer;
  color: var(--vscode-titleBar-activeForeground);
  padding: 2px;
  width: 24px;
  height: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 3px;
}

.btn-close:hover {
  background-color: var(--vscode-titleBar-hoverBackground);
}

.modal-body {
  padding: 16px;
}

.form-group {
  margin-bottom: 14px;
}

.form-group label {
  display: block;
  margin-bottom: 4px;
  font-size: 12px;
  font-weight: 600;
  color: var(--vscode-foreground);
}

.form-group input,
.form-group select,
.form-group textarea {
  width: 100%;
  padding: 6px 8px;
  border: 1px solid var(--vscode-input-border);
  background-color: var(--vscode-input-background);
  color: var(--vscode-input-foreground);
  border-radius: 3px;
  font-size: 13px;
  font-family: var(--vscode-font-family);
}

.form-group textarea {
  resize: vertical;
  min-height: 80px;
  line-height: 1.4;
}

.modal-footer {
  display: flex;
  justify-content: flex-end;
  gap: 8px;
  padding: 12px 16px;
  border-top: 1px solid var(--vscode-contrastBorder);
  background-color: var(--vscode-editor-background);
}

.btn-primary,
.btn-secondary {
  padding: 6px 16px;
  border: none;
  border-radius: 3px;
  cursor: pointer;
  font-size: 12px;
  font-weight: 500;
  transition: background-color 0.2s;
}

.btn-primary {
  background-color: var(--vscode-button-background);
  color: var(--vscode-button-foreground);
}

.btn-primary:hover {
  background-color: var(--vscode-button-hoverBackground);
}

.btn-secondary {
  background-color: var(--vscode-button-secondaryBackground);
  color: var(--vscode-button-secondaryForeground);
}

.btn-secondary:hover {
  background-color: var(--vscode-button-secondaryHoverBackground);
}

/* 响应式设计 */
@media (max-width: 1200px) {
  .left-panel {
    max-width: 250px;
  }
  
  .right-panel {
    max-width: 350px;
  }
}

@media (max-width: 768px) {
  .toolbar-center {
    display: none;
  }
  
  .left-panel,
  .right-panel {
    position: absolute;
    top: 0;
    bottom: 0;
    z-index: 100;
    box-shadow: 0 0 12px rgba(0, 0, 0, 0.3);
  }
  
  .left-panel {
    left: 0;
  }
  
  .right-panel {
    right: 0;
  }
}

/* 防止文本选择 */
.vscode-editor-layout.resizing * {
  user-select: none;
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
}

/* 滚动条样式 */
::-webkit-scrollbar {
  width: 12px;
  height: 12px;
}

::-webkit-scrollbar-track {
  background: var(--vscode-scrollbarSlider-background);
}

::-webkit-scrollbar-thumb {
  background: var(--vscode-scrollbarSlider-background);
  border-radius: 6px;
}

::-webkit-scrollbar-thumb:hover {
  background: var(--vscode-scrollbarSlider-hoverBackground);
}

::-webkit-scrollbar-corner {
  background: var(--vscode-editor-background);
}
</style>
