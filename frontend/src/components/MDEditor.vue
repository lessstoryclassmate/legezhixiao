<template>
  <div class="md-editor">
    <div class="editor-header">
      <div class="file-tabs">
        <div 
          v-for="tab in openTabs" 
          :key="tab.id"
          class="tab"
          :class="{ active: activeTabId === tab.id, modified: tab.modified }"
          @click="setActiveTab(tab.id)"
        >
          <span class="tab-icon">📄</span>
          <span class="tab-title">{{ tab.name }}</span>
          <span v-if="tab.modified" class="modified-dot">●</span>
          <button 
            @click.stop="closeTab(tab.id)"
            class="tab-close"
            title="关闭"
          >×</button>
        </div>
      </div>
      
      <div class="editor-actions">
        <button 
          @click="saveCurrentFile" 
          class="btn-action"
          :disabled="!activeTab || !activeTab.modified"
          title="保存 (Ctrl+S)"
        >
          💾
        </button>
        <button 
          @click="togglePreview" 
          class="btn-action"
          :class="{ active: showPreview }"
          title="预览"
        >
          👁️
        </button>
        <button 
          @click="formatDocument" 
          class="btn-action"
          title="格式化"
        >
          🎨
        </button>
      </div>
    </div>

    <div class="editor-content" v-if="activeTab">
      <div class="editor-panes" v-if="showPreview">
        <div class="editor-pane">
          <textarea
            ref="editorTextarea"
            v-model="activeTab.content"
            @input="onContentChange"
            @keydown="onKeyDown"
            class="editor-textarea"
            placeholder="开始编写您的Markdown内容..."
            spellcheck="false"
          ></textarea>
        </div>
        <div class="preview-pane">
          <div class="preview-content" v-html="previewHtml"></div>
        </div>
      </div>
      
      <textarea
        v-else
        ref="editorTextarea"
        v-model="activeTab.content"
        @input="onContentChange"
        @keydown="onKeyDown"
        class="editor-textarea full-width"
        placeholder="开始编写您的Markdown内容..."
        spellcheck="false"
      ></textarea>
    </div>

    <div v-else class="empty-editor">
      <div class="empty-content">
        <h3>欢迎使用MD编辑器</h3>
        <p>请从左侧文件管理器选择或创建一个文件开始编辑</p>
        <div class="empty-actions">
          <button @click="$emit('create-file')" class="btn-primary">
            📄 创建新文件
          </button>
        </div>
      </div>
    </div>

    <!-- 状态栏 -->
    <div class="status-bar" v-if="activeTab">
      <div class="status-left">
        <span class="status-item">行 {{ cursorPosition.line }}, 列 {{ cursorPosition.column }}</span>
        <span class="status-item">{{ wordCount }} 字</span>
        <span class="status-item">{{ activeTab.type }}</span>
      </div>
      <div class="status-right">
        <span class="status-item">{{ encoding }}</span>
        <span class="status-item">Markdown</span>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import { defineComponent, ref, computed, watch, nextTick, onMounted, onUnmounted } from 'vue'
import { marked } from 'marked'

interface EditorTab {
  id: string
  name: string
  type: string
  content: string
  modified: boolean
  originalContent: string
  path: string
}

export default defineComponent({
  name: 'MDEditor',
  emits: ['file-saved', 'create-file', 'tab-changed'],
  setup(_, { emit }) {
    const editorTextarea = ref<HTMLTextAreaElement>()
    const openTabs = ref<EditorTab[]>([])
    const activeTabId = ref<string>('')
    const showPreview = ref(false)
    const encoding = ref('UTF-8')

    const cursorPosition = ref({ line: 1, column: 1 })

    const activeTab = computed(() => {
      return openTabs.value.find(tab => tab.id === activeTabId.value)
    })

    const wordCount = computed(() => {
      if (!activeTab.value) return 0
      return activeTab.value.content.replace(/\s/g, '').length
    })

    const previewHtml = computed(() => {
      if (!activeTab.value) return ''
      try {
        return marked(activeTab.value.content)
      } catch (error) {
        return '<p>预览渲染错误</p>'
      }
    })

    const openFile = (file: any) => {
      const existingTab = openTabs.value.find(tab => tab.id === file.id)
      
      if (existingTab) {
        setActiveTab(file.id)
        return
      }

      const tab: EditorTab = {
        id: file.id,
        name: file.name,
        type: file.type,
        content: file.content || '',
        modified: false,
        originalContent: file.content || '',
        path: file.path
      }

      openTabs.value.push(tab)
      setActiveTab(file.id)
    }

    const setActiveTab = (tabId: string) => {
      activeTabId.value = tabId
      emit('tab-changed', activeTab.value)
      
      nextTick(() => {
        if (editorTextarea.value) {
          editorTextarea.value.focus()
          updateCursorPosition()
        }
      })
    }

    const closeTab = (tabId: string) => {
      const tabIndex = openTabs.value.findIndex(tab => tab.id === tabId)
      if (tabIndex === -1) return

      const tab = openTabs.value[tabIndex]
      
      // 检查是否有未保存的更改
      if (tab.modified) {
        const shouldClose = confirm(`文件 "${tab.name}" 有未保存的更改，确定要关闭吗？`)
        if (!shouldClose) return
      }

      openTabs.value.splice(tabIndex, 1)

      // 如果关闭的是当前活动标签，切换到其他标签
      if (activeTabId.value === tabId) {
        if (openTabs.value.length > 0) {
          const newActiveIndex = Math.min(tabIndex, openTabs.value.length - 1)
          setActiveTab(openTabs.value[newActiveIndex].id)
        } else {
          activeTabId.value = ''
        }
      }
    }

    const onContentChange = () => {
      if (!activeTab.value) return
      
      activeTab.value.modified = activeTab.value.content !== activeTab.value.originalContent
      updateCursorPosition()
    }

    const onKeyDown = (event: KeyboardEvent) => {
      // Ctrl+S 保存
      if (event.ctrlKey && event.key === 's') {
        event.preventDefault()
        saveCurrentFile()
        return
      }

      // Tab 键插入
      if (event.key === 'Tab') {
        event.preventDefault()
        insertTab()
        return
      }

      // 自动补全括号和引号
      if (event.key === '(' || event.key === '[' || event.key === '{' || event.key === '"' || event.key === "'") {
        insertPair(event.key)
        return
      }

      setTimeout(updateCursorPosition, 0)
    }

    const insertTab = () => {
      if (!editorTextarea.value) return
      
      const textarea = editorTextarea.value
      const start = textarea.selectionStart
      const end = textarea.selectionEnd
      
      if (start !== end) {
        // 有选中文本，为每行添加缩进
        const selectedText = textarea.value.substring(start, end)
        const indentedText = selectedText.split('\n').map(line => '  ' + line).join('\n')
        
        textarea.setRangeText(indentedText, start, end, 'end')
      } else {
        // 插入两个空格作为缩进
        textarea.setRangeText('  ', start, end, 'end')
      }
      
      onContentChange()
    }

    const insertPair = (char: string) => {
      if (!editorTextarea.value) return
      
      const pairs: { [key: string]: string } = {
        '(': ')',
        '[': ']',
        '{': '}',
        '"': '"',
        "'": "'"
      }
      
      const textarea = editorTextarea.value
      const start = textarea.selectionStart
      const end = textarea.selectionEnd
      const closeChar = pairs[char]
      
      if (start !== end) {
        // 有选中文本，包围选中的文本
        const selectedText = textarea.value.substring(start, end)
        textarea.setRangeText(char + selectedText + closeChar, start, end, 'end')
        textarea.setSelectionRange(start + 1, start + 1 + selectedText.length)
      } else {
        // 插入配对符号
        textarea.setRangeText(char + closeChar, start, end, 'end')
        textarea.setSelectionRange(start + 1, start + 1)
      }
      
      onContentChange()
    }

    const updateCursorPosition = () => {
      if (!editorTextarea.value) return
      
      const textarea = editorTextarea.value
      const text = textarea.value.substring(0, textarea.selectionStart)
      const lines = text.split('\n')
      
      cursorPosition.value = {
        line: lines.length,
        column: lines[lines.length - 1].length + 1
      }
    }

    const saveCurrentFile = async () => {
      if (!activeTab.value || !activeTab.value.modified) return
      
      try {
        // TODO: 调用API保存文件
        console.log('保存文件:', activeTab.value.path, activeTab.value.content)
        
        activeTab.value.originalContent = activeTab.value.content
        activeTab.value.modified = false
        
        emit('file-saved', {
          id: activeTab.value.id,
          content: activeTab.value.content
        })
        
        // 简单的成功提示
        const statusBar = document.querySelector('.status-bar')
        if (statusBar) {
          statusBar.style.backgroundColor = '#4CAF50'
          setTimeout(() => {
            statusBar.style.backgroundColor = ''
          }, 1000)
        }
      } catch (error) {
        console.error('保存文件失败:', error)
        alert('保存文件失败，请重试')
      }
    }

    const togglePreview = () => {
      showPreview.value = !showPreview.value
    }

    const formatDocument = () => {
      if (!activeTab.value) return
      
      // 简单的格式化：标准化换行和缩进
      let content = activeTab.value.content
      
      // 标准化换行
      content = content.replace(/\r\n/g, '\n').replace(/\r/g, '\n')
      
      // 移除多余的空行（最多保留一个空行）
      content = content.replace(/\n{3,}/g, '\n\n')
      
      // 标准化列表缩进
      content = content.replace(/^(\s*)([-*+])\s+/gm, '$1$2 ')
      
      // 标准化标题格式
      content = content.replace(/^(#{1,6})\s*/gm, '$1 ')
      
      activeTab.value.content = content
      onContentChange()
    }

    // 键盘快捷键监听
    const handleGlobalKeyDown = (event: KeyboardEvent) => {
      if (event.ctrlKey) {
        switch (event.key) {
          case 's':
            event.preventDefault()
            saveCurrentFile()
            break
          case 'w':
            if (activeTab.value) {
              event.preventDefault()
              closeTab(activeTab.value.id)
            }
            break
        }
      }
    }

    onMounted(() => {
      document.addEventListener('keydown', handleGlobalKeyDown)
    })

    onUnmounted(() => {
      document.removeEventListener('keydown', handleGlobalKeyDown)
    })

    return {
      editorTextarea,
      openTabs,
      activeTabId,
      activeTab,
      showPreview,
      encoding,
      cursorPosition,
      wordCount,
      previewHtml,
      openFile,
      setActiveTab,
      closeTab,
      onContentChange,
      onKeyDown,
      saveCurrentFile,
      togglePreview,
      formatDocument
    }
  }
})
</script>

<style scoped>
.md-editor {
  display: flex;
  flex-direction: column;
  height: 100%;
  background-color: var(--vscode-editor-background);
}

.editor-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  border-bottom: 1px solid var(--vscode-tab-border);
  background-color: var(--vscode-editorGroupHeader-tabsBackground);
}

.file-tabs {
  display: flex;
  flex: 1;
  overflow-x: auto;
}

.tab {
  display: flex;
  align-items: center;
  padding: 8px 12px;
  background-color: var(--vscode-tab-inactiveBackground);
  color: var(--vscode-tab-inactiveForeground);
  border-right: 1px solid var(--vscode-tab-border);
  cursor: pointer;
  min-width: 120px;
  max-width: 200px;
  position: relative;
  font-size: 13px;
}

.tab:hover {
  background-color: var(--vscode-tab-hoverBackground);
}

.tab.active {
  background-color: var(--vscode-tab-activeBackground);
  color: var(--vscode-tab-activeForeground);
  border-bottom: 2px solid var(--vscode-tab-activeBorder);
}

.tab.modified .tab-title {
  font-style: italic;
}

.tab-icon {
  margin-right: 6px;
  font-size: 12px;
}

.tab-title {
  flex: 1;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.modified-dot {
  color: var(--vscode-gitDecoration-modifiedResourceForeground);
  margin: 0 4px;
  font-size: 16px;
  line-height: 1;
}

.tab-close {
  background: none;
  border: none;
  color: var(--vscode-tab-inactiveForeground);
  cursor: pointer;
  padding: 2px;
  margin-left: 4px;
  border-radius: 2px;
  font-size: 14px;
  line-height: 1;
  opacity: 0.7;
}

.tab-close:hover {
  background-color: var(--vscode-toolbar-hoverBackground);
  opacity: 1;
}

.editor-actions {
  display: flex;
  padding: 4px 8px;
  gap: 4px;
}

.btn-action {
  background: none;
  border: none;
  color: var(--vscode-foreground);
  cursor: pointer;
  padding: 6px 8px;
  border-radius: 3px;
  font-size: 14px;
  transition: background-color 0.2s;
}

.btn-action:hover:not(:disabled) {
  background-color: var(--vscode-toolbar-hoverBackground);
}

.btn-action:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}

.btn-action.active {
  background-color: var(--vscode-button-background);
  color: var(--vscode-button-foreground);
}

.editor-content {
  flex: 1;
  display: flex;
  overflow: hidden;
}

.editor-panes {
  display: flex;
  width: 100%;
  height: 100%;
}

.editor-pane {
  flex: 1;
  border-right: 1px solid var(--vscode-editorGroup-border);
}

.preview-pane {
  flex: 1;
  overflow-y: auto;
  background-color: var(--vscode-editor-background);
}

.preview-content {
  padding: 16px;
  color: var(--vscode-editor-foreground);
  line-height: 1.6;
  font-family: var(--vscode-editor-font-family);
}

.editor-textarea {
  width: 100%;
  height: 100%;
  border: none;
  outline: none;
  resize: none;
  background-color: var(--vscode-editor-background);
  color: var(--vscode-editor-foreground);
  font-family: var(--vscode-editor-font-family);
  font-size: var(--vscode-editor-font-size);
  line-height: 1.5;
  padding: 16px;
  tab-size: 2;
}

.editor-textarea.full-width {
  width: 100%;
}

.empty-editor {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: var(--vscode-editor-background);
}

.empty-content {
  text-align: center;
  color: var(--vscode-descriptionForeground);
  max-width: 400px;
}

.empty-content h3 {
  margin-bottom: 8px;
  color: var(--vscode-foreground);
}

.empty-content p {
  margin-bottom: 16px;
  line-height: 1.5;
}

.empty-actions {
  display: flex;
  justify-content: center;
}

.btn-primary {
  background-color: var(--vscode-button-background);
  color: var(--vscode-button-foreground);
  border: none;
  padding: 8px 16px;
  border-radius: 3px;
  cursor: pointer;
  font-size: 13px;
}

.btn-primary:hover {
  background-color: var(--vscode-button-hoverBackground);
}

.status-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 4px 16px;
  background-color: var(--vscode-statusBar-background);
  color: var(--vscode-statusBar-foreground);
  border-top: 1px solid var(--vscode-statusBar-border);
  font-size: 12px;
  transition: background-color 0.3s;
}

.status-left,
.status-right {
  display: flex;
  gap: 16px;
}

.status-item {
  white-space: nowrap;
}

/* 预览内容样式 */
.preview-content :deep(h1),
.preview-content :deep(h2),
.preview-content :deep(h3),
.preview-content :deep(h4),
.preview-content :deep(h5),
.preview-content :deep(h6) {
  margin-top: 24px;
  margin-bottom: 16px;
  font-weight: 600;
  line-height: 1.25;
}

.preview-content :deep(h1) { font-size: 2em; }
.preview-content :deep(h2) { font-size: 1.5em; }
.preview-content :deep(h3) { font-size: 1.25em; }

.preview-content :deep(p) {
  margin-bottom: 16px;
}

.preview-content :deep(code) {
  background-color: var(--vscode-textCodeBlock-background);
  padding: 2px 4px;
  border-radius: 3px;
  font-family: var(--vscode-editor-font-family);
}

.preview-content :deep(pre) {
  background-color: var(--vscode-textCodeBlock-background);
  padding: 16px;
  border-radius: 6px;
  overflow-x: auto;
  margin-bottom: 16px;
}

.preview-content :deep(blockquote) {
  border-left: 4px solid var(--vscode-textBlockQuote-border);
  padding-left: 16px;
  color: var(--vscode-textBlockQuote-foreground);
  margin: 16px 0;
}

.preview-content :deep(ul),
.preview-content :deep(ol) {
  margin-bottom: 16px;
  padding-left: 20px;
}

.preview-content :deep(li) {
  margin-bottom: 4px;
}
</style>
