<!--
  AI 内容生成模块 - VSCode 风格界面
  支持可调整大小的面板布局，统一的 MD 文件数据交互
-->
<template>
  <div class="ai-content-generator" ref="containerRef">
    <!-- 顶部工具栏 -->
    <div class="toolbar">
      <div class="toolbar-left">
        <button class="btn-icon" @click="toggleFileExplorer" title="切换文件资源管理器">
          <i class="icon-folder"></i>
        </button>
        <button class="btn-icon" @click="newFile" title="新建文件">
          <i class="icon-file-plus"></i>
        </button>
        <button class="btn-icon" @click="saveFile" title="保存文件">
          <i class="icon-save"></i>
        </button>
      </div>
      <div class="toolbar-center">
        <div class="file-tabs">
          <div 
            v-for="file in openFiles" 
            :key="file.id"
            class="file-tab"
            :class="{ active: file.id === activeFileId }"
            @click="setActiveFile(file.id)"
          >
            <span class="tab-label">{{ file.name }}</span>
            <button class="tab-close" @click.stop="closeFile(file.id)">×</button>
          </div>
        </div>
      </div>
      <div class="toolbar-right">
        <select v-model="selectedModule" @change="onModuleChange" class="module-selector">
          <option value="">选择模块</option>
          <option value="plot">情节生成器</option>
          <option value="character">人物生成器</option>
          <option value="world">世界构建</option>
          <option value="analysis">情节分析</option>
          <option value="optimization">文本优化</option>
          <option value="style">风格转换</option>
        </select>
      </div>
    </div>

    <!-- 主内容区域 -->
    <div class="main-content">
      <!-- 左侧：文件资源管理器 -->
      <div 
        class="file-explorer"
        v-show="showFileExplorer"
        :style="{ width: fileExplorerWidth + 'px' }"
      >
        <div class="explorer-header">
          <h3>文件资源管理器</h3>
          <button class="btn-icon" @click="refreshFiles" title="刷新">
            <i class="icon-refresh"></i>
          </button>
        </div>
        <div class="file-tree">
          <div class="file-category" v-for="category in fileCategories" :key="category.key">
            <div class="category-header" @click="toggleCategory(category.key)">
              <i :class="category.expanded ? 'icon-chevron-down' : 'icon-chevron-right'"></i>
              <span>{{ category.name }}</span>
              <span class="file-count">({{ category.files.length }})</span>
            </div>
            <div class="category-files" v-show="category.expanded">
              <div 
                v-for="file in category.files" 
                :key="file.id"
                class="file-item"
                :class="{ active: file.id === activeFileId }"
                @click="openFile(file)"
              >
                <i :class="getFileIcon(file.type)"></i>
                <span class="file-name">{{ file.name }}</span>
                <span class="file-date">{{ formatDate(file.updatedAt) }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 分隔栏 -->
      <div 
        class="resizer"
        v-show="showFileExplorer"
        @mousedown="startResizing"
      ></div>

      <!-- 中间：编辑器区域 -->
      <div class="editor-container">
        <!-- 编辑器 -->
        <div class="editor-panel" :style="{ height: editorHeight + 'px' }">
          <div class="editor-header">
            <div class="editor-title">
              <i :class="getFileIcon(activeFile?.type || 'markdown')"></i>
              <span>{{ activeFile?.name || '未命名文件' }}</span>
            </div>
            <div class="editor-actions">
              <button class="btn-icon" @click="formatContent" title="格式化">
                <i class="icon-format"></i>
              </button>
              <button class="btn-icon" @click="togglePreview" title="预览">
                <i class="icon-eye"></i>
              </button>
            </div>
          </div>
          <div class="editor-content">
            <textarea
              v-if="!showPreview"
              ref="editorRef"
              v-model="editorContent"
              class="markdown-editor"
              placeholder="在这里编写您的内容..."
              @input="onContentChange"
              @keydown="handleKeyDown"
            ></textarea>
            <div v-else class="markdown-preview" v-html="previewContent"></div>
          </div>
        </div>

        <!-- 水平分隔栏 -->
        <div 
          class="horizontal-resizer"
          @mousedown="startHorizontalResizing"
        ></div>

        <!-- AI 对话面板 -->
        <div class="ai-chat-panel" :style="{ height: chatHeight + 'px' }">
          <div class="chat-header">
            <div class="chat-title">
              <i class="icon-robot"></i>
              <span>AI 助手</span>
            </div>
            <div class="chat-actions">
              <button class="btn-icon" @click="clearChat" title="清空对话">
                <i class="icon-trash"></i>
              </button>
              <button class="btn-icon" @click="exportChat" title="导出对话">
                <i class="icon-download"></i>
              </button>
            </div>
          </div>
          
          <div class="chat-messages" ref="chatMessagesRef">
            <div 
              v-for="message in chatMessages" 
              :key="message.id"
              class="message"
              :class="message.sender"
            >
              <div class="message-avatar">
                <i :class="message.sender === 'user' ? 'icon-user' : 'icon-robot'"></i>
              </div>
              <div class="message-content">
                <div class="message-text" v-html="message.content"></div>
                <div class="message-time">{{ formatTime(message.timestamp) }}</div>
              </div>
              <div class="message-actions">
                <button class="btn-icon" @click="insertToEditor(message.content)" title="插入到编辑器">
                  <i class="icon-insert"></i>
                </button>
                <button class="btn-icon" @click="copyMessage(message.content)" title="复制">
                  <i class="icon-copy"></i>
                </button>
              </div>
            </div>
          </div>
          
          <div class="chat-input">
            <div class="input-toolbar">
              <button class="btn-icon" @click="insertTemplate" title="插入模板">
                <i class="icon-template"></i>
              </button>
              <button class="btn-icon" @click="insertContext" title="插入上下文">
                <i class="icon-context"></i>
              </button>
              <select v-model="aiModel" class="model-selector">
                <option value="deepseek-ai/DeepSeek-V3">DeepSeek-V3</option>
                <option value="qwen/Qwen2.5-72B-Instruct">Qwen2.5-72B</option>
                <option value="01-ai/Yi-1.5-34B-Chat">Yi-1.5-34B</option>
              </select>
            </div>
            <div class="input-container">
              <textarea
                v-model="userInput"
                ref="chatInputRef"
                class="chat-textarea"
                placeholder="向 AI 提问或请求帮助..."
                @keydown="handleChatKeyDown"
                @input="adjustTextareaHeight"
              ></textarea>
              <button 
                class="send-btn"
                @click="sendMessage"
                :disabled="!userInput.trim() || isGenerating"
              >
                <i v-if="isGenerating" class="icon-loading"></i>
                <i v-else class="icon-send"></i>
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted, onUnmounted, watch } from 'vue'
import { useRouter } from 'vue-router'
import { marked } from 'marked'

// 接口定义
interface MDFile {
  id: string
  name: string
  type: 'novel' | 'chapter' | 'character' | 'world' | 'plot' | 'analysis' | 'style' | 'template'
  content: string
  path: string
  createdAt: Date
  updatedAt: Date
  tags: string[]
  metadata: Record<string, any>
}

interface ChatMessage {
  id: string
  sender: 'user' | 'ai'
  content: string
  timestamp: Date
  type: 'text' | 'markdown' | 'json'
}

interface FileCategory {
  key: string
  name: string
  files: MDFile[]
  expanded: boolean
}

// 响应式数据
const containerRef = ref<HTMLElement>()
const editorRef = ref<HTMLTextAreaElement>()
const chatMessagesRef = ref<HTMLElement>()
const chatInputRef = ref<HTMLTextAreaElement>()

// 界面状态
const showFileExplorer = ref(true)
const showPreview = ref(false)
const fileExplorerWidth = ref(300)
const editorHeight = ref(400)
const chatHeight = ref(300)

// 文件管理
const openFiles = ref<MDFile[]>([])
const activeFileId = ref<string>('')
const editorContent = ref('')
const selectedModule = ref('')

// AI 聊天
const chatMessages = ref<ChatMessage[]>([])
const userInput = ref('')
const isGenerating = ref(false)
const aiModel = ref('deepseek-ai/DeepSeek-V3')

// 文件分类
const fileCategories = ref<FileCategory[]>([
  {
    key: 'novels',
    name: '小说主文件',
    files: [],
    expanded: true
  },
  {
    key: 'chapters',
    name: '章节内容',
    files: [],
    expanded: true
  },
  {
    key: 'characters',
    name: '人物设定',
    files: [],
    expanded: false
  },
  {
    key: 'worlds',
    name: '世界构建',
    files: [],
    expanded: false
  },
  {
    key: 'plots',
    name: '情节设定',
    files: [],
    expanded: false
  },
  {
    key: 'analysis',
    name: '分析报告',
    files: [],
    expanded: false
  },
  {
    key: 'styles',
    name: '风格模板',
    files: [],
    expanded: false
  },
  {
    key: 'templates',
    name: '模板文件',
    files: [],
    expanded: false
  }
])

// 计算属性
const activeFile = computed(() => {
  return openFiles.value.find(f => f.id === activeFileId.value)
})

const previewContent = computed(() => {
  return marked(editorContent.value || '')
})

// MD 文件命名规范
const MDFileNamingConvention = {
  // 小说主文件: novel-{novelId}-main.md
  novel: (novelId: string) => `novel-${novelId}-main.md`,
  
  // 章节文件: novel-{novelId}-chapter-{chapterNumber}.md
  chapter: (novelId: string, chapterNumber: number) => `novel-${novelId}-chapter-${chapterNumber.toString().padStart(3, '0')}.md`,
  
  // 人物设定: novel-{novelId}-character-{characterName}.md
  character: (novelId: string, characterName: string) => `novel-${novelId}-character-${characterName}.md`,
  
  // 世界构建: novel-{novelId}-world-{worldName}.md
  world: (novelId: string, worldName: string) => `novel-${novelId}-world-${worldName}.md`,
  
  // 情节设定: novel-{novelId}-plot-{plotName}.md
  plot: (novelId: string, plotName: string) => `novel-${novelId}-plot-${plotName}.md`,
  
  // 分析报告: novel-{novelId}-analysis-{analysisType}-{timestamp}.md
  analysis: (novelId: string, analysisType: string, timestamp: string) => `novel-${novelId}-analysis-${analysisType}-${timestamp}.md`,
  
  // 风格模板: style-{styleName}-template.md
  style: (styleName: string) => `style-${styleName}-template.md`,
  
  // 通用模板: template-{templateType}-{templateName}.md
  template: (templateType: string, templateName: string) => `template-${templateType}-${templateName}.md`
}

// 方法
const toggleFileExplorer = () => {
  showFileExplorer.value = !showFileExplorer.value
}

const newFile = () => {
  const type = selectedModule.value || 'novel'
  const fileName = prompt('请输入文件名:') || 'untitled'
  createNewFile(type as any, fileName)
}

const createNewFile = (type: MDFile['type'], name: string) => {
  const newFile: MDFile = {
    id: Date.now().toString(),
    name: name.endsWith('.md') ? name : `${name}.md`,
    type,
    content: getFileTemplate(type),
    path: '',
    createdAt: new Date(),
    updatedAt: new Date(),
    tags: [],
    metadata: {}
  }
  
  openFiles.value.push(newFile)
  activeFileId.value = newFile.id
  editorContent.value = newFile.content
  
  // 添加到相应分类
  const category = fileCategories.value.find(c => c.key === `${type}s`)
  if (category) {
    category.files.push(newFile)
  }
}

const getFileTemplate = (type: MDFile['type']): string => {
  const templates = {
    novel: `# 小说标题

## 基本信息
- 作者: 
- 类型: 
- 状态: 创作中
- 创建时间: ${new Date().toLocaleDateString()}

## 简介


## 大纲


## 标签
`,
    chapter: `# 第X章 章节标题

## 章节信息
- 章节号: 
- 字数: 
- 状态: 草稿
- 创建时间: ${new Date().toLocaleDateString()}

## 内容

`,
    character: `# 人物名称

## 基本信息
- 姓名: 
- 性别: 
- 年龄: 
- 职业: 

## 外貌特征


## 性格特点


## 背景故事


## 人物关系

`,
    world: `# 世界名称

## 世界设定
- 世界类型: 
- 时代背景: 
- 地理环境: 

## 社会结构


## 魔法/科技体系


## 历史背景

`,
    plot: `# 情节名称

## 情节概述


## 关键事件


## 人物冲突


## 情节发展

`,
    analysis: `# 分析报告

## 分析类型
- 类型: 
- 分析时间: ${new Date().toLocaleDateString()}

## 分析结果


## 建议

`,
    style: `# 风格模板

## 风格特点


## 写作技巧


## 示例文本

`,
    template: `# 模板名称

## 模板说明


## 使用方法


## 模板内容

`
  }
  
  return templates[type] || templates.novel
}

const saveFile = async () => {
  if (!activeFile.value) return
  
  try {
    // 保存到服务器
    await saveToServer(activeFile.value)
    
    // 更新本地状态
    activeFile.value.content = editorContent.value
    activeFile.value.updatedAt = new Date()
    
    console.log('文件已保存')
  } catch (error) {
    console.error('保存失败:', error)
  }
}

const saveToServer = async (file: MDFile) => {
  // 实现保存到服务器的逻辑
  const response = await fetch('/api/files', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      ...file,
      content: editorContent.value
    })
  })
  
  if (!response.ok) {
    throw new Error('保存失败')
  }
}

const openFile = (file: MDFile) => {
  if (!openFiles.value.find(f => f.id === file.id)) {
    openFiles.value.push(file)
  }
  activeFileId.value = file.id
  editorContent.value = file.content
}

const closeFile = (fileId: string) => {
  const index = openFiles.value.findIndex(f => f.id === fileId)
  if (index !== -1) {
    openFiles.value.splice(index, 1)
    
    if (activeFileId.value === fileId) {
      activeFileId.value = openFiles.value[0]?.id || ''
      editorContent.value = openFiles.value[0]?.content || ''
    }
  }
}

const setActiveFile = (fileId: string) => {
  activeFileId.value = fileId
  const file = openFiles.value.find(f => f.id === fileId)
  if (file) {
    editorContent.value = file.content
  }
}

const getFileIcon = (type: string): string => {
  const icons = {
    novel: 'icon-book',
    chapter: 'icon-file-text',
    character: 'icon-user',
    world: 'icon-globe',
    plot: 'icon-sitemap',
    analysis: 'icon-chart-bar',
    style: 'icon-paint-brush',
    template: 'icon-template',
    markdown: 'icon-markdown'
  }
  return icons[type] || 'icon-file'
}

const formatDate = (date: Date): string => {
  return date.toLocaleDateString('zh-CN', {
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

const formatTime = (date: Date): string => {
  return date.toLocaleTimeString('zh-CN', {
    hour: '2-digit',
    minute: '2-digit'
  })
}

// 调整大小相关
const startResizing = (e: MouseEvent) => {
  const startX = e.clientX
  const startWidth = fileExplorerWidth.value
  
  const handleMouseMove = (e: MouseEvent) => {
    const deltaX = e.clientX - startX
    fileExplorerWidth.value = Math.max(200, Math.min(600, startWidth + deltaX))
  }
  
  const handleMouseUp = () => {
    document.removeEventListener('mousemove', handleMouseMove)
    document.removeEventListener('mouseup', handleMouseUp)
  }
  
  document.addEventListener('mousemove', handleMouseMove)
  document.addEventListener('mouseup', handleMouseUp)
}

const startHorizontalResizing = (e: MouseEvent) => {
  const startY = e.clientY
  const startEditorHeight = editorHeight.value
  const startChatHeight = chatHeight.value
  
  const handleMouseMove = (e: MouseEvent) => {
    const deltaY = e.clientY - startY
    const newEditorHeight = Math.max(200, startEditorHeight + deltaY)
    const newChatHeight = Math.max(200, startChatHeight - deltaY)
    
    editorHeight.value = newEditorHeight
    chatHeight.value = newChatHeight
  }
  
  const handleMouseUp = () => {
    document.removeEventListener('mousemove', handleMouseMove)
    document.removeEventListener('mouseup', handleMouseUp)
  }
  
  document.addEventListener('mousemove', handleMouseMove)
  document.addEventListener('mouseup', handleMouseUp)
}

// AI 聊天相关
const sendMessage = async () => {
  if (!userInput.value.trim() || isGenerating.value) return
  
  const userMessage: ChatMessage = {
    id: Date.now().toString(),
    sender: 'user',
    content: userInput.value,
    timestamp: new Date(),
    type: 'text'
  }
  
  chatMessages.value.push(userMessage)
  
  const prompt = userInput.value
  userInput.value = ''
  isGenerating.value = true
  
  try {
    const response = await callAI(prompt)
    
    const aiMessage: ChatMessage = {
      id: (Date.now() + 1).toString(),
      sender: 'ai',
      content: response,
      timestamp: new Date(),
      type: 'markdown'
    }
    
    chatMessages.value.push(aiMessage)
  } catch (error) {
    console.error('AI 调用失败:', error)
  } finally {
    isGenerating.value = false
  }
  
  // 滚动到底部
  setTimeout(() => {
    if (chatMessagesRef.value) {
      chatMessagesRef.value.scrollTop = chatMessagesRef.value.scrollHeight
    }
  }, 100)
}

const callAI = async (prompt: string): Promise<string> => {
  const response = await fetch('/api/ai/chat', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: aiModel.value,
      messages: [
        {
          role: 'system',
          content: `你是一个专业的小说写作助手。用户正在使用基于 Markdown 文件的小说创作系统。当前打开的文件是：${activeFile.value?.name || '未命名文件'}。请提供专业的写作建议和内容生成。`
        },
        {
          role: 'user',
          content: prompt
        }
      ],
      context: {
        currentFile: activeFile.value,
        editorContent: editorContent.value,
        selectedModule: selectedModule.value
      }
    })
  })
  
  if (!response.ok) {
    throw new Error('AI 调用失败')
  }
  
  const data = await response.json()
  return data.content
}

const insertToEditor = (content: string) => {
  if (editorRef.value) {
    const textarea = editorRef.value
    const start = textarea.selectionStart
    const end = textarea.selectionEnd
    
    const newContent = editorContent.value.slice(0, start) + content + editorContent.value.slice(end)
    editorContent.value = newContent
    
    // 设置光标位置
    setTimeout(() => {
      textarea.focus()
      textarea.setSelectionRange(start + content.length, start + content.length)
    }, 0)
  }
}

const copyMessage = (content: string) => {
  navigator.clipboard.writeText(content)
}

// 键盘快捷键
const handleKeyDown = (e: KeyboardEvent) => {
  if (e.ctrlKey || e.metaKey) {
    switch (e.key) {
      case 's':
        e.preventDefault()
        saveFile()
        break
      case 'n':
        e.preventDefault()
        newFile()
        break
    }
  }
}

const handleChatKeyDown = (e: KeyboardEvent) => {
  if (e.key === 'Enter' && (e.ctrlKey || e.metaKey)) {
    e.preventDefault()
    sendMessage()
  }
}

// 监听内容变化
watch(editorContent, (newContent) => {
  if (activeFile.value) {
    activeFile.value.content = newContent
  }
})

// 组件挂载
onMounted(() => {
  // 初始化文件
  loadFiles()
  
  // 创建默认文件
  createNewFile('novel', '我的第一本小说')
})

const loadFiles = async () => {
  try {
    const response = await fetch('/api/files')
    const files = await response.json()
    
    // 根据文件类型分类
    files.forEach((file: MDFile) => {
      const category = fileCategories.value.find(c => c.key === `${file.type}s`)
      if (category) {
        category.files.push(file)
      }
    })
  } catch (error) {
    console.error('加载文件失败:', error)
  }
}

// 其他方法
const toggleCategory = (key: string) => {
  const category = fileCategories.value.find(c => c.key === key)
  if (category) {
    category.expanded = !category.expanded
  }
}

const refreshFiles = () => {
  loadFiles()
}

const formatContent = () => {
  // 格式化 Markdown 内容
  // 这里可以添加格式化逻辑
}

const togglePreview = () => {
  showPreview.value = !showPreview.value
}

const clearChat = () => {
  chatMessages.value = []
}

const exportChat = () => {
  const chatContent = chatMessages.value.map(msg => 
    `**${msg.sender === 'user' ? '用户' : 'AI'}** (${formatTime(msg.timestamp)})\n${msg.content}\n\n`
  ).join('')
  
  const blob = new Blob([chatContent], { type: 'text/markdown' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `chat-${new Date().toISOString().slice(0, 10)}.md`
  a.click()
  URL.revokeObjectURL(url)
}

const insertTemplate = () => {
  // 插入模板的逻辑
}

const insertContext = () => {
  // 插入上下文的逻辑
}

const onModuleChange = () => {
  // 模块改变时的逻辑
}

const onContentChange = () => {
  // 内容改变时的逻辑
}

const adjustTextareaHeight = () => {
  if (chatInputRef.value) {
    chatInputRef.value.style.height = 'auto'
    chatInputRef.value.style.height = chatInputRef.value.scrollHeight + 'px'
  }
}
</script>

<style scoped>
.ai-content-generator {
  height: 100vh;
  display: flex;
  flex-direction: column;
  background: #1e1e1e;
  color: #cccccc;
  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
}

.toolbar {
  display: flex;
  align-items: center;
  height: 35px;
  background: #2d2d30;
  border-bottom: 1px solid #3e3e42;
  padding: 0 10px;
}

.toolbar-left,
.toolbar-right {
  display: flex;
  align-items: center;
  gap: 5px;
}

.toolbar-center {
  flex: 1;
  display: flex;
  align-items: center;
}

.btn-icon {
  width: 28px;
  height: 28px;
  border: none;
  background: transparent;
  color: #cccccc;
  cursor: pointer;
  border-radius: 3px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.btn-icon:hover {
  background: #3e3e42;
}

.file-tabs {
  display: flex;
  margin-left: 10px;
}

.file-tab {
  display: flex;
  align-items: center;
  padding: 5px 10px;
  background: #2d2d30;
  border-right: 1px solid #3e3e42;
  cursor: pointer;
  min-width: 120px;
}

.file-tab.active {
  background: #1e1e1e;
}

.file-tab:hover {
  background: #3e3e42;
}

.tab-label {
  flex: 1;
  font-size: 12px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.tab-close {
  width: 16px;
  height: 16px;
  border: none;
  background: transparent;
  color: #cccccc;
  cursor: pointer;
  margin-left: 5px;
}

.module-selector {
  background: #3c3c3c;
  color: #cccccc;
  border: 1px solid #464647;
  border-radius: 3px;
  padding: 4px 8px;
  font-size: 12px;
}

.main-content {
  flex: 1;
  display: flex;
  overflow: hidden;
}

.file-explorer {
  background: #252526;
  border-right: 1px solid #3e3e42;
  display: flex;
  flex-direction: column;
}

.explorer-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px;
  border-bottom: 1px solid #3e3e42;
}

.explorer-header h3 {
  margin: 0;
  font-size: 13px;
  font-weight: 600;
  color: #cccccc;
}

.file-tree {
  flex: 1;
  overflow-y: auto;
  padding: 5px;
}

.file-category {
  margin-bottom: 5px;
}

.category-header {
  display: flex;
  align-items: center;
  padding: 5px;
  cursor: pointer;
  font-size: 12px;
  font-weight: 600;
  color: #cccccc;
}

.category-header:hover {
  background: #2a2d2e;
}

.file-count {
  margin-left: auto;
  font-size: 11px;
  color: #858585;
}

.category-files {
  padding-left: 20px;
}

.file-item {
  display: flex;
  align-items: center;
  padding: 3px 5px;
  cursor: pointer;
  font-size: 12px;
  border-radius: 3px;
}

.file-item:hover {
  background: #2a2d2e;
}

.file-item.active {
  background: #094771;
  color: #ffffff;
}

.file-name {
  flex: 1;
  margin-left: 5px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.file-date {
  font-size: 10px;
  color: #858585;
}

.resizer {
  width: 4px;
  background: #3e3e42;
  cursor: col-resize;
}

.resizer:hover {
  background: #007acc;
}

.editor-container {
  flex: 1;
  display: flex;
  flex-direction: column;
}

.editor-panel {
  display: flex;
  flex-direction: column;
  border-bottom: 1px solid #3e3e42;
}

.editor-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px;
  background: #2d2d30;
  border-bottom: 1px solid #3e3e42;
}

.editor-title {
  display: flex;
  align-items: center;
  gap: 5px;
  font-size: 13px;
  color: #cccccc;
}

.editor-actions {
  display: flex;
  gap: 5px;
}

.editor-content {
  flex: 1;
  position: relative;
}

.markdown-editor {
  width: 100%;
  height: 100%;
  border: none;
  outline: none;
  background: #1e1e1e;
  color: #cccccc;
  font-family: 'Fira Code', 'Consolas', monospace;
  font-size: 14px;
  line-height: 1.5;
  padding: 20px;
  resize: none;
}

.markdown-preview {
  height: 100%;
  overflow-y: auto;
  padding: 20px;
  background: #1e1e1e;
}

.horizontal-resizer {
  height: 4px;
  background: #3e3e42;
  cursor: row-resize;
}

.horizontal-resizer:hover {
  background: #007acc;
}

.ai-chat-panel {
  display: flex;
  flex-direction: column;
  background: #252526;
}

.chat-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px;
  background: #2d2d30;
  border-bottom: 1px solid #3e3e42;
}

.chat-title {
  display: flex;
  align-items: center;
  gap: 5px;
  font-size: 13px;
  color: #cccccc;
}

.chat-actions {
  display: flex;
  gap: 5px;
}

.chat-messages {
  flex: 1;
  overflow-y: auto;
  padding: 10px;
}

.message {
  display: flex;
  gap: 10px;
  margin-bottom: 15px;
}

.message.user {
  flex-direction: row-reverse;
}

.message.user .message-content {
  background: #0e639c;
  align-self: flex-end;
}

.message.ai .message-content {
  background: #2d2d30;
}

.message-avatar {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  background: #3e3e42;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.message-content {
  flex: 1;
  padding: 10px;
  border-radius: 8px;
  max-width: 80%;
}

.message-text {
  font-size: 14px;
  line-height: 1.4;
  word-wrap: break-word;
}

.message-time {
  font-size: 10px;
  color: #858585;
  margin-top: 5px;
}

.message-actions {
  display: flex;
  flex-direction: column;
  gap: 5px;
  opacity: 0;
  transition: opacity 0.2s;
}

.message:hover .message-actions {
  opacity: 1;
}

.chat-input {
  border-top: 1px solid #3e3e42;
  background: #2d2d30;
}

.input-toolbar {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px;
  border-bottom: 1px solid #3e3e42;
}

.model-selector {
  background: #3c3c3c;
  color: #cccccc;
  border: 1px solid #464647;
  border-radius: 3px;
  padding: 4px 8px;
  font-size: 12px;
  margin-left: auto;
}

.input-container {
  display: flex;
  align-items: flex-end;
  gap: 10px;
  padding: 10px;
}

.chat-textarea {
  flex: 1;
  min-height: 40px;
  max-height: 120px;
  border: 1px solid #464647;
  border-radius: 4px;
  background: #3c3c3c;
  color: #cccccc;
  padding: 10px;
  font-size: 14px;
  line-height: 1.4;
  resize: none;
  outline: none;
}

.send-btn {
  width: 40px;
  height: 40px;
  border: none;
  border-radius: 4px;
  background: #007acc;
  color: #ffffff;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
}

.send-btn:hover:not(:disabled) {
  background: #1177bb;
}

.send-btn:disabled {
  background: #464647;
  cursor: not-allowed;
}

/* 图标样式 */
.icon-folder::before { content: '📁'; }
.icon-file-plus::before { content: '📄'; }
.icon-save::before { content: '💾'; }
.icon-refresh::before { content: '🔄'; }
.icon-chevron-down::before { content: '▼'; }
.icon-chevron-right::before { content: '▶'; }
.icon-book::before { content: '📖'; }
.icon-file-text::before { content: '📄'; }
.icon-user::before { content: '👤'; }
.icon-globe::before { content: '🌍'; }
.icon-sitemap::before { content: '🗺️'; }
.icon-chart-bar::before { content: '📊'; }
.icon-paint-brush::before { content: '🎨'; }
.icon-template::before { content: '📋'; }
.icon-markdown::before { content: '📝'; }
.icon-format::before { content: '📐'; }
.icon-eye::before { content: '👁️'; }
.icon-robot::before { content: '🤖'; }
.icon-trash::before { content: '🗑️'; }
.icon-download::before { content: '📥'; }
.icon-insert::before { content: '📥'; }
.icon-copy::before { content: '📋'; }
.icon-context::before { content: '🔗'; }
.icon-send::before { content: '📤'; }
.icon-loading::before { content: '⏳'; }

/* 响应式 */
@media (max-width: 768px) {
  .file-explorer {
    width: 100% !important;
    position: absolute;
    top: 0;
    left: 0;
    z-index: 1000;
  }
  
  .resizer {
    display: none;
  }
}
</style>
