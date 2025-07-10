<template>
  <div class="novel-editor">
    <!-- 编辑器导航栏 -->
    <div class="editor-navbar">
      <div class="editor-nav-left">
        <button class="nav-btn" @click="goBack">
          <span class="nav-icon">←</span>
          返回
        </button>
        <div class="novel-info">
          <h2 class="novel-title">{{ novel.title }}</h2>
          <span class="novel-status">{{ getStatusLabel(novel.status) }}</span>
        </div>
      </div>
      <div class="editor-nav-right">
        <button class="nav-btn" @click="saveNovel" :disabled="saving">
          <span class="nav-icon">💾</span>
          {{ saving ? '保存中...' : '保存' }}
        </button>
        <button class="nav-btn primary" @click="publishNovel">
          <span class="nav-icon">🚀</span>
          发布
        </button>
      </div>
    </div>

    <div class="editor-container">
      <!-- 左侧章节列表 -->
      <div class="sidebar">
        <div class="sidebar-header">
          <h3>章节列表</h3>
          <button class="btn btn-primary btn-sm" @click="addChapter">
            <span class="btn-icon">+</span>
            新建章节
          </button>
        </div>
        <div class="chapters-list">
          <div
            v-for="chapter in chapters"
            :key="chapter.id"
            :class="['chapter-item', { active: currentChapter?.id === chapter.id }]"
            @click="selectChapter(chapter)"
          >
            <div class="chapter-info">
              <h4 class="chapter-title">{{ chapter.title }}</h4>
              <p class="chapter-meta">{{ chapter.wordCount }}字</p>
            </div>
            <div class="chapter-actions">
              <button class="action-btn" @click.stop="editChapterTitle(chapter)">
                <span class="action-icon">✏️</span>
              </button>
              <button class="action-btn" @click.stop="deleteChapter(chapter)">
                <span class="action-icon">🗑️</span>
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- 主编辑区域 -->
      <div class="main-editor">
        <div v-if="currentChapter" class="editor-panel">
          <!-- 章节标题 -->
          <div class="chapter-header">
            <input
              v-model="currentChapter.title"
              type="text"
              placeholder="章节标题"
              class="chapter-title-input"
            />
            <div class="chapter-stats">
              <span class="stat">字数: {{ currentChapter.wordCount || 0 }}</span>
              <span class="stat">最后修改: {{ formatDate(currentChapter.updatedAt) }}</span>
            </div>
          </div>

          <!-- 工具栏 -->
          <div class="editor-toolbar">
            <div class="toolbar-group">
              <button class="tool-btn" @click="insertText('**', '**')" title="加粗">
                <span class="tool-icon">B</span>
              </button>
              <button class="tool-btn" @click="insertText('*', '*')" title="斜体">
                <span class="tool-icon">I</span>
              </button>
              <button class="tool-btn" @click="insertText('~~', '~~')" title="删除线">
                <span class="tool-icon">S</span>
              </button>
            </div>
            <div class="toolbar-group">
              <button class="tool-btn" @click="insertText('# ', '')" title="标题">
                <span class="tool-icon">H</span>
              </button>
              <button class="tool-btn" @click="insertText('> ', '')" title="引用">
                <span class="tool-icon">""</span>
              </button>
              <button class="tool-btn" @click="insertText('- ', '')" title="列表">
                <span class="tool-icon">•</span>
              </button>
            </div>
            <div class="toolbar-group">
              <button class="tool-btn ai-btn" @click="showAIAssistant = true" title="AI助手">
                <span class="tool-icon">🤖</span>
                AI助手
              </button>
            </div>
          </div>

          <!-- 编辑器主体 -->
          <div class="editor-content">
            <textarea
              ref="editorTextarea"
              v-model="currentChapter.content"
              placeholder="在这里开始您的创作..."
              class="content-editor"
              @input="updateWordCount"
            ></textarea>
            
            <!-- AI助手面板 -->
            <div v-if="showAIAssistant" class="ai-assistant">
              <div class="ai-header">
                <h4>AI创作助手</h4>
                <button class="close-btn" @click="showAIAssistant = false">×</button>
              </div>
              <div class="ai-tools">
                <button class="ai-tool-btn" @click="aiContinue">
                  <span class="ai-icon">✨</span>
                  续写内容
                </button>
                <button class="ai-tool-btn" @click="aiOptimize">
                  <span class="ai-icon">🎨</span>
                  优化文本
                </button>
                <button class="ai-tool-btn" @click="aiSummarize">
                  <span class="ai-icon">📝</span>
                  内容总结
                </button>
              </div>
              <div class="ai-prompt">
                <textarea
                  v-model="aiPrompt"
                  placeholder="输入您的创作需求..."
                  class="ai-prompt-input"
                ></textarea>
                <button class="btn btn-primary" @click="callAI">
                  <span class="btn-icon">🚀</span>
                  生成
                </button>
              </div>
            </div>
          </div>
        </div>
        
        <!-- 无章节时的占位符 -->
        <div v-else class="empty-editor">
          <div class="empty-icon">📝</div>
          <h3>选择或创建章节</h3>
          <p>从左侧章节列表中选择章节开始编辑</p>
          <button class="btn btn-primary" @click="addChapter">
            创建第一章
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, nextTick } from 'vue'
import { useRouter, useRoute } from 'vue-router'

const router = useRouter()
const route = useRoute()

// 编辑器状态
const novel = ref({
  id: 1,
  title: '我的小说',
  status: 'draft'
})

const chapters = ref([
  {
    id: 1,
    title: '第一章 开始',
    content: '这是第一章的内容...',
    wordCount: 156,
    createdAt: '2024-01-15',
    updatedAt: '2024-01-15'
  }
])

const currentChapter = ref(null)
const saving = ref(false)
const showAIAssistant = ref(false)
const aiPrompt = ref('')
const editorTextarea = ref(null)

// 返回小说列表
const goBack = () => {
  router.push('/novels')
}

// 获取状态标签
const getStatusLabel = (status: string) => {
  const labels = {
    draft: '草稿',
    published: '已发布',
    completed: '已完结'
  }
  return labels[status] || '未知'
}

// 选择章节
const selectChapter = (chapter: any) => {
  currentChapter.value = chapter
}

// 添加新章节
const addChapter = () => {
  const newChapter = {
    id: Date.now(),
    title: `第${chapters.value.length + 1}章 未命名`,
    content: '',
    wordCount: 0,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  }
  chapters.value.push(newChapter)
  currentChapter.value = newChapter
}

// 编辑章节标题
const editChapterTitle = (chapter: any) => {
  const newTitle = prompt('请输入新的章节标题:', chapter.title)
  if (newTitle && newTitle.trim()) {
    chapter.title = newTitle.trim()
  }
}

// 删除章节
const deleteChapter = (chapter: any) => {
  if (confirm(`确定要删除章节"${chapter.title}"吗？`)) {
    chapters.value = chapters.value.filter(c => c.id !== chapter.id)
    if (currentChapter.value?.id === chapter.id) {
      currentChapter.value = chapters.value[0] || null
    }
  }
}

// 更新字数统计
const updateWordCount = () => {
  if (currentChapter.value) {
    currentChapter.value.wordCount = currentChapter.value.content.length
    currentChapter.value.updatedAt = new Date().toISOString()
  }
}

// 插入文本
const insertText = (before: string, after: string) => {
  const textarea = editorTextarea.value
  if (!textarea) return
  
  const start = textarea.selectionStart
  const end = textarea.selectionEnd
  const selectedText = textarea.value.substring(start, end)
  const newText = before + selectedText + after
  
  textarea.value = textarea.value.substring(0, start) + newText + textarea.value.substring(end)
  
  // 更新v-model
  if (currentChapter.value) {
    currentChapter.value.content = textarea.value
    updateWordCount()
  }
  
  // 设置光标位置
  nextTick(() => {
    textarea.focus()
    textarea.selectionStart = start + before.length
    textarea.selectionEnd = start + before.length + selectedText.length
  })
}

// AI助手功能
const aiContinue = () => {
  aiPrompt.value = '请继续写下去，保持文章的风格和语调'
  callAI()
}

const aiOptimize = () => {
  aiPrompt.value = '请优化选中的文本，使其更加生动有趣'
  callAI()
}

const aiSummarize = () => {
  aiPrompt.value = '请总结这段内容的主要情节'
  callAI()
}

const callAI = async () => {
  if (!aiPrompt.value.trim()) return
  
  try {
    // 这里应该调用实际的AI API
    const response = await mockAICall(aiPrompt.value)
    
    // 将AI生成的内容插入到编辑器中
    if (currentChapter.value) {
      currentChapter.value.content += '\n\n' + response
      updateWordCount()
    }
    
    showAIAssistant.value = false
    aiPrompt.value = ''
  } catch (error) {
    console.error('AI调用失败:', error)
    alert('AI调用失败，请稍后再试')
  }
}

// 模拟AI调用
const mockAICall = (prompt: string) => {
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve('这是AI生成的内容示例...')
    }, 1000)
  })
}

// 保存小说
const saveNovel = async () => {
  saving.value = true
  try {
    // 这里应该调用保存API
    await new Promise(resolve => setTimeout(resolve, 1000))
    console.log('小说已保存')
  } catch (error) {
    console.error('保存失败:', error)
  } finally {
    saving.value = false
  }
}

// 发布小说
const publishNovel = async () => {
  if (confirm('确定要发布这部小说吗？')) {
    try {
      novel.value.status = 'published'
      await saveNovel()
      alert('小说发布成功！')
    } catch (error) {
      console.error('发布失败:', error)
    }
  }
}

// 格式化日期
const formatDate = (dateString: string) => {
  const date = new Date(dateString)
  return date.toLocaleDateString('zh-CN', {
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

onMounted(() => {
  // 获取小说ID并加载数据
  const novelId = route.params.id
  console.log('编辑小说ID:', novelId)
  
  // 选择第一章
  if (chapters.value.length > 0) {
    currentChapter.value = chapters.value[0]
  }
})
</script>

<style scoped>
.novel-editor {
  height: 100vh;
  display: flex;
  flex-direction: column;
  background: #f5f7fa;
}

.editor-navbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem 2rem;
  background: white;
  border-bottom: 1px solid #e1e8ed;
}

.editor-nav-left {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.editor-nav-right {
  display: flex;
  gap: 0.5rem;
}

.nav-btn {
  padding: 0.5rem 1rem;
  border: 1px solid #e1e8ed;
  border-radius: 6px;
  background: white;
  color: #666;
  cursor: pointer;
  transition: all 0.3s;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 0.9rem;
}

.nav-btn:hover {
  border-color: #409eff;
  color: #409eff;
}

.nav-btn.primary {
  background: #409eff;
  color: white;
  border-color: #409eff;
}

.nav-btn.primary:hover {
  background: #337ecc;
}

.nav-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.nav-icon {
  font-size: 1rem;
}

.novel-info {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.novel-title {
  font-size: 1.2rem;
  color: #2c3e50;
  margin: 0;
}

.novel-status {
  padding: 0.25rem 0.5rem;
  border-radius: 4px;
  font-size: 0.8rem;
  background: #f0f9ff;
  color: #0369a1;
}

.editor-container {
  flex: 1;
  display: flex;
  overflow: hidden;
}

.sidebar {
  width: 300px;
  background: white;
  border-right: 1px solid #e1e8ed;
  display: flex;
  flex-direction: column;
}

.sidebar-header {
  padding: 1rem;
  border-bottom: 1px solid #e1e8ed;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.sidebar-header h3 {
  margin: 0;
  color: #2c3e50;
  font-size: 1.1rem;
}

.btn {
  padding: 0.5rem 1rem;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.3s;
  font-size: 0.9rem;
  display: flex;
  align-items: center;
  gap: 0.3rem;
}

.btn-primary {
  background: #409eff;
  color: white;
}

.btn-primary:hover {
  background: #337ecc;
}

.btn-sm {
  padding: 0.3rem 0.6rem;
  font-size: 0.8rem;
}

.btn-icon {
  font-size: 1rem;
}

.chapters-list {
  flex: 1;
  overflow-y: auto;
}

.chapter-item {
  padding: 1rem;
  border-bottom: 1px solid #f0f0f0;
  cursor: pointer;
  transition: all 0.3s;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.chapter-item:hover {
  background: #f5f7fa;
}

.chapter-item.active {
  background: #ecf5ff;
  border-right: 3px solid #409eff;
}

.chapter-info {
  flex: 1;
}

.chapter-title {
  font-size: 1rem;
  color: #2c3e50;
  margin: 0 0 0.25rem 0;
}

.chapter-meta {
  font-size: 0.8rem;
  color: #666;
  margin: 0;
}

.chapter-actions {
  display: flex;
  gap: 0.25rem;
}

.action-btn {
  padding: 0.25rem;
  border: none;
  border-radius: 4px;
  background: transparent;
  color: #666;
  cursor: pointer;
  transition: all 0.3s;
  font-size: 0.8rem;
}

.action-btn:hover {
  background: #f0f0f0;
  color: #409eff;
}

.action-icon {
  font-size: 0.9rem;
}

.main-editor {
  flex: 1;
  display: flex;
  flex-direction: column;
}

.editor-panel {
  flex: 1;
  display: flex;
  flex-direction: column;
  background: white;
  margin: 1rem;
  border-radius: 8px;
  overflow: hidden;
}

.chapter-header {
  padding: 1rem;
  border-bottom: 1px solid #e1e8ed;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.chapter-title-input {
  flex: 1;
  padding: 0.5rem;
  border: 1px solid #e1e8ed;
  border-radius: 6px;
  font-size: 1.1rem;
  font-weight: 600;
  color: #2c3e50;
}

.chapter-title-input:focus {
  outline: none;
  border-color: #409eff;
}

.chapter-stats {
  display: flex;
  gap: 1rem;
  color: #666;
  font-size: 0.9rem;
}

.stat {
  white-space: nowrap;
}

.editor-toolbar {
  padding: 0.5rem 1rem;
  border-bottom: 1px solid #e1e8ed;
  display: flex;
  gap: 1rem;
}

.toolbar-group {
  display: flex;
  gap: 0.25rem;
}

.tool-btn {
  padding: 0.5rem;
  border: 1px solid #e1e8ed;
  border-radius: 4px;
  background: white;
  color: #666;
  cursor: pointer;
  transition: all 0.3s;
  font-size: 0.9rem;
  display: flex;
  align-items: center;
  gap: 0.3rem;
}

.tool-btn:hover {
  border-color: #409eff;
  color: #409eff;
}

.tool-btn.ai-btn {
  background: #f0f9ff;
  border-color: #0369a1;
  color: #0369a1;
}

.tool-btn.ai-btn:hover {
  background: #0369a1;
  color: white;
}

.tool-icon {
  font-size: 1rem;
  font-weight: bold;
}

.editor-content {
  flex: 1;
  position: relative;
  overflow: hidden;
}

.content-editor {
  width: 100%;
  height: 100%;
  padding: 1rem;
  border: none;
  outline: none;
  resize: none;
  font-size: 1rem;
  line-height: 1.8;
  color: #2c3e50;
  background: white;
}

.ai-assistant {
  position: absolute;
  top: 0;
  right: 0;
  width: 300px;
  height: 100%;
  background: white;
  border-left: 1px solid #e1e8ed;
  display: flex;
  flex-direction: column;
}

.ai-header {
  padding: 1rem;
  border-bottom: 1px solid #e1e8ed;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.ai-header h4 {
  margin: 0;
  color: #2c3e50;
  font-size: 1rem;
}

.close-btn {
  background: none;
  border: none;
  font-size: 1.2rem;
  cursor: pointer;
  color: #666;
  padding: 0.25rem;
  border-radius: 50%;
  transition: all 0.3s;
}

.close-btn:hover {
  background: #f0f0f0;
}

.ai-tools {
  padding: 1rem;
  border-bottom: 1px solid #e1e8ed;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.ai-tool-btn {
  padding: 0.5rem;
  border: 1px solid #e1e8ed;
  border-radius: 6px;
  background: white;
  color: #666;
  cursor: pointer;
  transition: all 0.3s;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 0.9rem;
}

.ai-tool-btn:hover {
  border-color: #409eff;
  color: #409eff;
}

.ai-icon {
  font-size: 1rem;
}

.ai-prompt {
  flex: 1;
  padding: 1rem;
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.ai-prompt-input {
  flex: 1;
  padding: 0.5rem;
  border: 1px solid #e1e8ed;
  border-radius: 6px;
  resize: none;
  font-size: 0.9rem;
  line-height: 1.6;
}

.ai-prompt-input:focus {
  outline: none;
  border-color: #409eff;
}

.empty-editor {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  color: #666;
}

.empty-icon {
  font-size: 4rem;
  margin-bottom: 1rem;
}

.empty-editor h3 {
  font-size: 1.5rem;
  margin-bottom: 0.5rem;
  color: #2c3e50;
}

.empty-editor p {
  margin-bottom: 2rem;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .editor-navbar {
    padding: 0.5rem 1rem;
  }
  
  .editor-nav-left {
    gap: 0.5rem;
  }
  
  .novel-info {
    flex-direction: column;
    align-items: flex-start;
    gap: 0.25rem;
  }
  
  .sidebar {
    width: 250px;
  }
  
  .editor-panel {
    margin: 0.5rem;
  }
  
  .chapter-header {
    flex-direction: column;
    gap: 1rem;
    align-items: flex-start;
  }
  
  .chapter-stats {
    flex-direction: column;
    gap: 0.5rem;
  }
  
  .editor-toolbar {
    flex-wrap: wrap;
    gap: 0.5rem;
  }
  
  .ai-assistant {
    width: 100%;
    position: fixed;
    top: 0;
    left: 0;
    z-index: 1000;
  }
}
</style>
