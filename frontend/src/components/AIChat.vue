<template>
  <div class="ai-chat">
    <div class="chat-header">
      <div class="header-title">
        <i class="icon">🤖</i>
        <h3>AI智能助手</h3>
      </div>
      <div class="header-actions">
        <button 
          @click="clearChat" 
          class="btn-icon"
          title="清空对话"
        >
          🗑️
        </button>
        <button 
          @click="exportChat" 
          class="btn-icon"
          title="导出对话"
        >
          📥
        </button>
        <button 
          @click="toggleSettings" 
          class="btn-icon"
          title="设置"
        >
          ⚙️
        </button>
      </div>
    </div>

    <!-- AI功能选择 -->
    <div class="function-selector">
      <select v-model="selectedFunction" @change="onFunctionChange">
        <option value="">选择AI功能...</option>
        <option value="content_generation">内容生成</option>
        <option value="story_analysis">故事分析</option>
        <option value="character_development">人物发展</option>
        <option value="plot_planning">情节规划</option>
        <option value="worldview_building">世界观构建</option>
        <option value="writing_assistance">写作辅助</option>
        <option value="editing_suggestions">编辑建议</option>
      </select>
    </div>

    <!-- 上下文信息 -->
    <div class="context-info" v-if="contextFiles.length > 0">
      <div class="context-header">
        <span>📎 上下文文件 ({{ contextFiles.length }})</span>
        <button @click="clearContext" class="btn-text">清空</button>
      </div>
      <div class="context-files">
        <div 
          v-for="file in contextFiles" 
          :key="file.id"
          class="context-file"
        >
          <span class="file-icon">📄</span>
          <span class="file-name">{{ file.name }}</span>
          <button 
            @click="removeFromContext(file.id)"
            class="btn-remove"
          >×</button>
        </div>
      </div>
    </div>

    <!-- 消息列表 -->
    <div class="chat-messages" ref="messagesContainer">
      <div 
        v-for="message in messages" 
        :key="message.id"
        class="message"
        :class="{ 'user-message': message.type === 'user', 'ai-message': message.type === 'ai' }"
      >
        <div class="message-header">
          <div class="message-avatar">
            <i v-if="message.type === 'user'" class="icon">👤</i>
            <i v-else class="icon">🤖</i>
          </div>
          <div class="message-meta">
            <span class="message-sender">{{ message.type === 'user' ? '你' : 'AI助手' }}</span>
            <span class="message-time">{{ formatTime(message.timestamp) }}</span>
          </div>
        </div>
        <div class="message-content">
          <div v-if="message.type === 'ai'" class="ai-content" v-html="renderMarkdown(message.content)"></div>
          <div v-else class="user-content">{{ message.content }}</div>
          
          <!-- AI消息的操作按钮 -->
          <div v-if="message.type === 'ai'" class="message-actions">
            <button 
              @click="copyMessage(message.content)"
              class="btn-action"
              title="复制"
            >📋</button>
            <button 
              @click="insertToEditor(message.content)"
              class="btn-action"
              title="插入到编辑器"
            >📝</button>
            <button 
              @click="saveAsFile(message.content)"
              class="btn-action"
              title="保存为文件"
            >💾</button>
            <button 
              @click="regenerateResponse(message.id)"
              class="btn-action"
              title="重新生成"
            >🔄</button>
          </div>
        </div>
      </div>

      <!-- 加载指示器 -->
      <div v-if="isLoading" class="message ai-message loading">
        <div class="message-header">
          <div class="message-avatar">
            <i class="icon">🤖</i>
          </div>
          <div class="message-meta">
            <span class="message-sender">AI助手</span>
            <span class="message-time">正在思考...</span>
          </div>
        </div>
        <div class="message-content">
          <div class="loading-dots">
            <span></span>
            <span></span>
            <span></span>
          </div>
        </div>
      </div>
    </div>

    <!-- 输入区域 -->
    <div class="chat-input">
      <div class="input-toolbar">
        <button 
          @click="addCurrentFileToContext"
          class="btn-tool"
          title="添加当前文件到上下文"
          :disabled="!currentFile"
        >
          📎
        </button>
        <button 
          @click="toggleVoiceInput"
          class="btn-tool"
          title="语音输入"
        >
          🎤
        </button>
        <button 
          @click="openTemplates"
          class="btn-tool"
          title="提示词模板"
        >
          📝
        </button>
      </div>
      
      <div class="input-area">
        <textarea
          ref="inputTextarea"
          v-model="inputMessage"
          @keydown="onInputKeydown"
          @input="onInputChange"
          placeholder="输入您的问题或需求，按 Ctrl+Enter 发送..."
          rows="3"
          class="input-textarea"
        ></textarea>
        
        <div class="input-actions">
          <button 
            @click="sendMessage"
            :disabled="!inputMessage.trim() || isLoading"
            class="btn-send"
          >
            <i v-if="isLoading" class="icon">⏳</i>
            <i v-else class="icon">🚀</i>
            发送
          </button>
        </div>
      </div>
    </div>

    <!-- 设置面板 -->
    <div v-if="showSettings" class="settings-panel">
      <div class="settings-header">
        <h4>AI设置</h4>
        <button @click="toggleSettings" class="btn-close">×</button>
      </div>
      <div class="settings-content">
        <div class="setting-group">
          <label>模型选择:</label>
          <select v-model="aiSettings.model">
            <option value="qwen-plus">通义千问Plus</option>
            <option value="qwen-max">通义千问Max</option>
            <option value="deepseek-chat">DeepSeek Chat</option>
          </select>
        </div>
        <div class="setting-group">
          <label>创造性 ({{ aiSettings.temperature }}):</label>
          <input 
            type="range" 
            min="0" 
            max="1" 
            step="0.1" 
            v-model.number="aiSettings.temperature"
          />
        </div>
        <div class="setting-group">
          <label>最大长度:</label>
          <input 
            type="number" 
            min="100" 
            max="4000" 
            v-model.number="aiSettings.maxTokens"
          />
        </div>
        <div class="setting-group">
          <label>系统提示词:</label>
          <textarea 
            v-model="aiSettings.systemPrompt"
            rows="4"
            placeholder="设置AI的角色和行为..."
          ></textarea>
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import { defineComponent, ref, computed, nextTick, onMounted, watch } from 'vue'
import { marked } from 'marked'

interface ChatMessage {
  id: string
  type: 'user' | 'ai'
  content: string
  timestamp: Date
  function?: string
  context?: any[]
}

interface ContextFile {
  id: string
  name: string
  type: string
  content: string
}

interface AISettings {
  model: string
  temperature: number
  maxTokens: number
  systemPrompt: string
}

export default defineComponent({
  name: 'AIChat',
  props: {
    currentFile: {
      type: Object,
      default: null
    }
  },
  emits: ['insert-content', 'create-file', 'update-file'],
  setup(props, { emit }) {
    const messagesContainer = ref<HTMLElement>()
    const inputTextarea = ref<HTMLTextAreaElement>()
    
    const messages = ref<ChatMessage[]>([])
    const inputMessage = ref('')
    const isLoading = ref(false)
    const showSettings = ref(false)
    const selectedFunction = ref('')
    const contextFiles = ref<ContextFile[]>([])

    const aiSettings = ref<AISettings>({
      model: 'qwen-plus',
      temperature: 0.7,
      maxTokens: 2000,
      systemPrompt: '你是一个专业的小说写作助手，擅长创作指导、情节分析、人物发展和世界观构建。请根据用户的需求提供有针对性的建议和内容。'
    })

    const functionPrompts = {
      content_generation: '请帮我生成小说内容，包括情节、对话或描述。',
      story_analysis: '请分析当前故事的结构、节奏和发展。',
      character_development: '请帮我发展人物性格、背景和成长轨迹。',
      plot_planning: '请协助规划情节走向和关键事件。',
      worldview_building: '请帮我构建完整的世界观设定。',
      writing_assistance: '请提供写作技巧和改进建议。',
      editing_suggestions: '请对文本进行编辑和润色建议。'
    }

    const onFunctionChange = () => {
      if (selectedFunction.value && functionPrompts[selectedFunction.value as keyof typeof functionPrompts]) {
        inputMessage.value = functionPrompts[selectedFunction.value as keyof typeof functionPrompts]
      }
    }

    const addCurrentFileToContext = () => {
      if (!props.currentFile) return
      
      const exists = contextFiles.value.find(f => f.id === props.currentFile.id)
      if (exists) return

      contextFiles.value.push({
        id: props.currentFile.id,
        name: props.currentFile.name,
        type: props.currentFile.type,
        content: props.currentFile.content || ''
      })
    }

    const removeFromContext = (fileId: string) => {
      const index = contextFiles.value.findIndex(f => f.id === fileId)
      if (index > -1) {
        contextFiles.value.splice(index, 1)
      }
    }

    const clearContext = () => {
      contextFiles.value = []
    }

    const sendMessage = async () => {
      const content = inputMessage.value.trim()
      if (!content || isLoading.value) return

      // 添加用户消息
      const userMessage: ChatMessage = {
        id: Date.now().toString(),
        type: 'user',
        content,
        timestamp: new Date(),
        function: selectedFunction.value,
        context: contextFiles.value.map(f => ({ name: f.name, type: f.type, content: f.content }))
      }

      messages.value.push(userMessage)
      inputMessage.value = ''
      isLoading.value = true

      await scrollToBottom()

      try {
        // 构建AI请求
        const aiResponse = await callAI(content, userMessage.context)
        
        // 添加AI消息
        const aiMessage: ChatMessage = {
          id: (Date.now() + 1).toString(),
          type: 'ai',
          content: aiResponse,
          timestamp: new Date()
        }

        messages.value.push(aiMessage)
      } catch (error) {
        console.error('AI调用失败:', error)
        
        const errorMessage: ChatMessage = {
          id: (Date.now() + 1).toString(),
          type: 'ai',
          content: '抱歉，AI服务暂时不可用，请稍后重试。',
          timestamp: new Date()
        }
        
        messages.value.push(errorMessage)
      } finally {
        isLoading.value = false
        await scrollToBottom()
        inputTextarea.value?.focus()
      }
    }

    const callAI = async (message: string, context?: any[]): Promise<string> => {
      // TODO: 实现实际的AI API调用
      // 这里是模拟响应
      await new Promise(resolve => setTimeout(resolve, 1500))
      
      return `这是AI对于"${message}"的回复。\n\n根据您的需求，我建议：\n\n1. **分析当前内容**：首先理解您现有的故事框架\n2. **提供具体建议**：针对性地给出改进意见\n3. **生成新内容**：根据需要创作相关内容\n\n您希望我从哪个方面开始帮助您？`
    }

    const onInputKeydown = (event: KeyboardEvent) => {
      if (event.ctrlKey && event.key === 'Enter') {
        event.preventDefault()
        sendMessage()
      }
    }

    const onInputChange = () => {
      // 自动调整输入框高度
      if (inputTextarea.value) {
        inputTextarea.value.style.height = 'auto'
        inputTextarea.value.style.height = Math.min(inputTextarea.value.scrollHeight, 200) + 'px'
      }
    }

    const scrollToBottom = async () => {
      await nextTick()
      if (messagesContainer.value) {
        messagesContainer.value.scrollTop = messagesContainer.value.scrollHeight
      }
    }

    const formatTime = (timestamp: Date) => {
      return timestamp.toLocaleTimeString('zh-CN', { 
        hour: '2-digit', 
        minute: '2-digit' 
      })
    }

    const renderMarkdown = (content: string) => {
      try {
        return marked(content)
      } catch (error) {
        return content
      }
    }

    const copyMessage = async (content: string) => {
      try {
        await navigator.clipboard.writeText(content)
        // 简单的复制成功提示
        console.log('内容已复制到剪贴板')
      } catch (error) {
        console.error('复制失败:', error)
      }
    }

    const insertToEditor = (content: string) => {
      emit('insert-content', content)
    }

    const saveAsFile = (content: string) => {
      const file = {
        type: selectedFunction.value || 'ai_conv',
        name: `AI对话_${new Date().toLocaleDateString()}`,
        content,
        novelId: 'novel_001' // TODO: 从当前上下文获取
      }
      emit('create-file', file)
    }

    const regenerateResponse = async (messageId: string) => {
      const messageIndex = messages.value.findIndex(m => m.id === messageId)
      if (messageIndex === -1) return

      const aiMessageIndex = messageIndex
      const userMessageIndex = messageIndex - 1

      if (userMessageIndex < 0 || messages.value[userMessageIndex].type !== 'user') return

      const userMessage = messages.value[userMessageIndex]
      
      // 移除旧的AI响应
      messages.value.splice(aiMessageIndex, 1)
      
      isLoading.value = true
      
      try {
        const aiResponse = await callAI(userMessage.content, userMessage.context)
        
        const newAiMessage: ChatMessage = {
          id: Date.now().toString(),
          type: 'ai',
          content: aiResponse,
          timestamp: new Date()
        }

        messages.value.splice(aiMessageIndex, 0, newAiMessage)
      } catch (error) {
        console.error('重新生成失败:', error)
      } finally {
        isLoading.value = false
        await scrollToBottom()
      }
    }

    const clearChat = () => {
      if (confirm('确定要清空所有对话记录吗？')) {
        messages.value = []
        contextFiles.value = []
      }
    }

    const exportChat = () => {
      const chatContent = messages.value.map(msg => {
        const sender = msg.type === 'user' ? '用户' : 'AI助手'
        const time = formatTime(msg.timestamp)
        return `[${time}] ${sender}: ${msg.content}`
      }).join('\n\n')

      const blob = new Blob([chatContent], { type: 'text/plain;charset=utf-8' })
      const url = URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = `AI对话记录_${new Date().toLocaleDateString()}.txt`
      a.click()
      URL.revokeObjectURL(url)
    }

    const toggleSettings = () => {
      showSettings.value = !showSettings.value
    }

    const toggleVoiceInput = () => {
      // TODO: 实现语音输入功能
      console.log('语音输入功能待实现')
    }

    const openTemplates = () => {
      // TODO: 实现提示词模板选择
      console.log('提示词模板功能待实现')
    }

    // 监听当前文件变化
    watch(() => props.currentFile, (newFile) => {
      if (newFile && contextFiles.value.length === 0) {
        // 自动添加当前文件到上下文
        addCurrentFileToContext()
      }
    })

    onMounted(() => {
      inputTextarea.value?.focus()
    })

    return {
      messagesContainer,
      inputTextarea,
      messages,
      inputMessage,
      isLoading,
      showSettings,
      selectedFunction,
      contextFiles,
      aiSettings,
      onFunctionChange,
      addCurrentFileToContext,
      removeFromContext,
      clearContext,
      sendMessage,
      onInputKeydown,
      onInputChange,
      formatTime,
      renderMarkdown,
      copyMessage,
      insertToEditor,
      saveAsFile,
      regenerateResponse,
      clearChat,
      exportChat,
      toggleSettings,
      toggleVoiceInput,
      openTemplates
    }
  }
})
</script>

<style scoped>
.ai-chat {
  display: flex;
  flex-direction: column;
  height: 100%;
  background-color: var(--vscode-sideBar-background);
  border-left: 1px solid var(--vscode-sideBar-border);
}

.chat-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 8px 12px;
  border-bottom: 1px solid var(--vscode-sideBar-border);
  background-color: var(--vscode-sideBarSectionHeader-background);
}

.header-title {
  display: flex;
  align-items: center;
  gap: 8px;
}

.header-title h3 {
  margin: 0;
  font-size: 13px;
  font-weight: 600;
  color: var(--vscode-sideBarSectionHeader-foreground);
}

.header-actions {
  display: flex;
  gap: 4px;
}

.btn-icon {
  width: 24px;
  height: 24px;
  border: none;
  background: transparent;
  color: var(--vscode-sideBarSectionHeader-foreground);
  cursor: pointer;
  border-radius: 3px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 12px;
}

.btn-icon:hover {
  background-color: var(--vscode-toolbar-hoverBackground);
}

.function-selector {
  padding: 8px 12px;
  border-bottom: 1px solid var(--vscode-sideBar-border);
}

.function-selector select {
  width: 100%;
  padding: 4px 8px;
  border: 1px solid var(--vscode-input-border);
  background-color: var(--vscode-input-background);
  color: var(--vscode-input-foreground);
  border-radius: 3px;
  font-size: 12px;
}

.context-info {
  padding: 8px 12px;
  border-bottom: 1px solid var(--vscode-sideBar-border);
  background-color: var(--vscode-editor-background);
}

.context-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 6px;
  font-size: 11px;
  color: var(--vscode-descriptionForeground);
}

.btn-text {
  background: none;
  border: none;
  color: var(--vscode-textLink-foreground);
  cursor: pointer;
  font-size: 10px;
  text-decoration: underline;
}

.context-files {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.context-file {
  display: flex;
  align-items: center;
  padding: 2px 6px;
  background-color: var(--vscode-badge-background);
  color: var(--vscode-badge-foreground);
  border-radius: 12px;
  font-size: 11px;
}

.file-icon {
  margin-right: 4px;
  font-size: 10px;
}

.file-name {
  flex: 1;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.btn-remove {
  background: none;
  border: none;
  color: var(--vscode-badge-foreground);
  cursor: pointer;
  margin-left: 4px;
  padding: 0;
  font-size: 12px;
  opacity: 0.7;
}

.btn-remove:hover {
  opacity: 1;
}

.chat-messages {
  flex: 1;
  overflow-y: auto;
  padding: 8px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.message {
  display: flex;
  flex-direction: column;
  animation: fadeIn 0.3s ease-out;
}

.message-header {
  display: flex;
  align-items: center;
  margin-bottom: 4px;
  gap: 8px;
}

.message-avatar {
  width: 24px;
  height: 24px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 12px;
  flex-shrink: 0;
}

.user-message .message-avatar {
  background-color: var(--vscode-button-background);
  color: var(--vscode-button-foreground);
}

.ai-message .message-avatar {
  background-color: var(--vscode-inputValidation-infoBackground);
  color: var(--vscode-inputValidation-infoForeground);
}

.message-meta {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.message-sender {
  font-size: 11px;
  font-weight: 600;
  color: var(--vscode-foreground);
}

.message-time {
  font-size: 10px;
  color: var(--vscode-descriptionForeground);
}

.message-content {
  padding: 8px 12px;
  border-radius: 8px;
  position: relative;
}

.user-message .message-content {
  background-color: var(--vscode-input-background);
  border: 1px solid var(--vscode-input-border);
  margin-left: 32px;
}

.ai-message .message-content {
  background-color: var(--vscode-textCodeBlock-background);
  border: 1px solid var(--vscode-textBlockQuote-border);
  margin-left: 32px;
}

.user-content {
  font-size: 13px;
  line-height: 1.4;
  color: var(--vscode-foreground);
  white-space: pre-wrap;
}

.ai-content {
  font-size: 13px;
  line-height: 1.5;
  color: var(--vscode-foreground);
}

.message-actions {
  display: flex;
  gap: 4px;
  margin-top: 8px;
  padding-top: 6px;
  border-top: 1px solid var(--vscode-textBlockQuote-border);
}

.btn-action {
  background: none;
  border: 1px solid var(--vscode-button-border);
  color: var(--vscode-button-secondaryForeground);
  cursor: pointer;
  padding: 2px 6px;
  border-radius: 3px;
  font-size: 11px;
  display: flex;
  align-items: center;
  gap: 2px;
}

.btn-action:hover {
  background-color: var(--vscode-button-secondaryHoverBackground);
}

.loading {
  opacity: 0.8;
}

.loading-dots {
  display: flex;
  gap: 4px;
  align-items: center;
}

.loading-dots span {
  width: 6px;
  height: 6px;
  background-color: var(--vscode-foreground);
  border-radius: 50%;
  animation: bounce 1.4s infinite ease-in-out both;
}

.loading-dots span:nth-child(1) { animation-delay: -0.32s; }
.loading-dots span:nth-child(2) { animation-delay: -0.16s; }
.loading-dots span:nth-child(3) { animation-delay: 0s; }

.chat-input {
  border-top: 1px solid var(--vscode-sideBar-border);
  background-color: var(--vscode-input-background);
}

.input-toolbar {
  display: flex;
  gap: 4px;
  padding: 6px 8px;
  border-bottom: 1px solid var(--vscode-input-border);
}

.btn-tool {
  background: none;
  border: none;
  color: var(--vscode-foreground);
  cursor: pointer;
  padding: 4px 6px;
  border-radius: 3px;
  font-size: 12px;
}

.btn-tool:hover:not(:disabled) {
  background-color: var(--vscode-toolbar-hoverBackground);
}

.btn-tool:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}

.input-area {
  display: flex;
  flex-direction: column;
}

.input-textarea {
  border: none;
  background: transparent;
  color: var(--vscode-input-foreground);
  font-family: var(--vscode-font-family);
  font-size: 13px;
  line-height: 1.4;
  padding: 8px 12px;
  resize: none;
  outline: none;
  min-height: 60px;
  max-height: 200px;
}

.input-actions {
  display: flex;
  justify-content: flex-end;
  padding: 6px 8px;
  border-top: 1px solid var(--vscode-input-border);
}

.btn-send {
  background-color: var(--vscode-button-background);
  color: var(--vscode-button-foreground);
  border: none;
  padding: 6px 12px;
  border-radius: 3px;
  cursor: pointer;
  font-size: 12px;
  display: flex;
  align-items: center;
  gap: 4px;
  font-weight: 500;
}

.btn-send:hover:not(:disabled) {
  background-color: var(--vscode-button-hoverBackground);
}

.btn-send:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}

.settings-panel {
  position: absolute;
  top: 0;
  right: 0;
  bottom: 0;
  width: 280px;
  background-color: var(--vscode-sideBar-background);
  border-left: 1px solid var(--vscode-sideBar-border);
  z-index: 100;
  box-shadow: -2px 0 8px rgba(0, 0, 0, 0.1);
}

.settings-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 8px 12px;
  border-bottom: 1px solid var(--vscode-sideBar-border);
  background-color: var(--vscode-sideBarSectionHeader-background);
}

.settings-header h4 {
  margin: 0;
  font-size: 13px;
  font-weight: 600;
  color: var(--vscode-sideBarSectionHeader-foreground);
}

.btn-close {
  background: none;
  border: none;
  color: var(--vscode-sideBarSectionHeader-foreground);
  cursor: pointer;
  font-size: 16px;
  padding: 0;
  width: 20px;
  height: 20px;
}

.settings-content {
  padding: 12px;
}

.setting-group {
  margin-bottom: 12px;
}

.setting-group label {
  display: block;
  margin-bottom: 4px;
  font-size: 11px;
  font-weight: 600;
  color: var(--vscode-foreground);
}

.setting-group select,
.setting-group input[type="number"],
.setting-group input[type="range"],
.setting-group textarea {
  width: 100%;
  padding: 4px 6px;
  border: 1px solid var(--vscode-input-border);
  background-color: var(--vscode-input-background);
  color: var(--vscode-input-foreground);
  border-radius: 3px;
  font-size: 12px;
}

.setting-group textarea {
  resize: vertical;
  min-height: 60px;
  font-family: var(--vscode-font-family);
}

@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@keyframes bounce {
  0%, 80%, 100% {
    transform: scale(0);
  }
  40% {
    transform: scale(1);
  }
}

/* AI内容样式 */
.ai-content :deep(h1),
.ai-content :deep(h2),
.ai-content :deep(h3),
.ai-content :deep(h4) {
  margin: 12px 0 8px 0;
  font-weight: 600;
}

.ai-content :deep(p) {
  margin: 8px 0;
}

.ai-content :deep(ul),
.ai-content :deep(ol) {
  margin: 8px 0;
  padding-left: 16px;
}

.ai-content :deep(li) {
  margin: 4px 0;
}

.ai-content :deep(code) {
  background-color: var(--vscode-textCodeBlock-background);
  padding: 2px 4px;
  border-radius: 3px;
  font-family: var(--vscode-editor-font-family);
  font-size: 12px;
}

.ai-content :deep(pre) {
  background-color: var(--vscode-textCodeBlock-background);
  padding: 8px;
  border-radius: 4px;
  overflow-x: auto;
  margin: 8px 0;
}

.ai-content :deep(blockquote) {
  border-left: 3px solid var(--vscode-textBlockQuote-border);
  padding-left: 8px;
  margin: 8px 0;
  color: var(--vscode-textBlockQuote-foreground);
}
</style>
