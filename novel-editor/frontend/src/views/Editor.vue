<template>
  <div class="editor-container">
    <div class="editor-toolbar">
      <el-button-group>
        <el-button :icon="DocumentAdd" @click="newChapter">新章节</el-button>
        <el-button :icon="Document" @click="saveChapter">保存</el-button>
        <el-button :icon="MagicStick" @click="aiAssist">AI助手</el-button>
      </el-button-group>
      
      <div class="toolbar-center">
        <span>字数: {{ wordCount }}</span>
      </div>
      
      <el-button-group>
        <el-button :icon="View" @click="togglePreview">预览</el-button>
        <el-button :icon="Setting" @click="showSettings">设置</el-button>
      </el-button-group>
    </div>
    
    <div class="editor-content">
      <!-- 章节列表侧边栏 -->
      <div class="editor-sidebar">
        <div class="sidebar-header">
          <h3>章节列表</h3>
        </div>
        <div class="chapter-list">
          <div 
            v-for="chapter in chapters" 
            :key="chapter.id"
            :class="['chapter-item', { active: currentChapter?.id === chapter.id }]"
            @click="selectChapter(chapter)"
          >
            <div class="chapter-title">{{ chapter.title }}</div>
            <div class="chapter-meta">{{ chapter.wordCount }}字</div>
          </div>
        </div>
      </div>
      
      <!-- 主编辑区 -->
      <div class="editor-main">
        <div class="chapter-header">
          <el-input 
            v-model="currentChapter.title" 
            placeholder="章节标题"
            size="large"
            class="chapter-title-input"
          />
        </div>
        
        <div class="editor-text" ref="editorRef">
          <el-input
            v-model="currentChapter.content"
            type="textarea"
            :rows="30"
            placeholder="开始您的创作..."
            @input="updateWordCount"
          />
        </div>
      </div>
      
      <!-- AI助手侧边栏 -->
      <div class="ai-assistant" v-if="showAI">
        <div class="ai-header">
          <h3>AI助手</h3>
          <el-button :icon="Close" @click="showAI = false" size="small" />
        </div>
        
        <el-tabs v-model="activeAITab">
          <el-tab-pane label="内容生成" name="generate">
            <div class="ai-panel">
              <el-input
                v-model="aiPrompt"
                type="textarea"
                :rows="3"
                placeholder="描述您想要生成的内容..."
              />
              <el-button 
                type="primary" 
                @click="generateContent"
                :loading="aiLoading"
                style="margin-top: 10px; width: 100%;"
              >
                生成内容
              </el-button>
            </div>
          </el-tab-pane>
          
          <el-tab-pane label="内容分析" name="analyze">
            <div class="ai-panel">
              <el-button 
                @click="analyzeContent"
                :loading="aiLoading"
                style="width: 100%;"
              >
                分析当前内容
              </el-button>
              <div v-if="analysisResult" class="analysis-result">
                {{ analysisResult }}
              </div>
            </div>
          </el-tab-pane>
          
          <el-tab-pane label="剧情建议" name="suggest">
            <div class="ai-panel">
              <el-button 
                @click="suggestPlot"
                :loading="aiLoading"
                style="width: 100%;"
              >
                获取剧情建议
              </el-button>
              <div v-if="plotSuggestions.length" class="suggestions">
                <div 
                  v-for="(suggestion, index) in plotSuggestions" 
                  :key="index"
                  class="suggestion-item"
                >
                  {{ suggestion }}
                </div>
              </div>
            </div>
          </el-tab-pane>
        </el-tabs>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted, computed } from 'vue'
import { useRoute } from 'vue-router'
import {
  DocumentAdd,
  Document,
  MagicStick,
  View,
  Setting,
  Close
} from '@element-plus/icons-vue'
import { api } from '@/utils/api'

const route = useRoute()

// 响应式数据
const chapters = ref([])
const currentChapter = reactive({
  id: null,
  title: '',
  content: '',
  wordCount: 0
})

const showAI = ref(false)
const activeAITab = ref('generate')
const aiPrompt = ref('')
const aiLoading = ref(false)
const analysisResult = ref('')
const plotSuggestions = ref([])

// 计算属性
const wordCount = computed(() => {
  return currentChapter.content ? currentChapter.content.length : 0
})

// 方法
const newChapter = () => {
  const newChapterData = {
    id: Date.now(),
    title: `第${chapters.value.length + 1}章`,
    content: '',
    wordCount: 0
  }
  chapters.value.push(newChapterData)
  selectChapter(newChapterData)
}

const saveChapter = async () => {
  try {
    // 调用API保存章节
    console.log('保存章节:', currentChapter)
  } catch (error) {
    console.error('保存失败:', error)
  }
}

const aiAssist = () => {
  showAI.value = !showAI.value
}

const togglePreview = () => {
  // 切换预览模式
}

const showSettings = () => {
  // 显示设置
}

const selectChapter = (chapter) => {
  Object.assign(currentChapter, chapter)
}

const updateWordCount = () => {
  currentChapter.wordCount = wordCount.value
}

const generateContent = async () => {
  if (!aiPrompt.value.trim()) return
  
  aiLoading.value = true
  try {
    const response = await api.post('/ai/generate', {
      task_type: 'generate',
      content: aiPrompt.value,
      context: {
        current_content: currentChapter.content,
        chapter_title: currentChapter.title
      }
    })
    
    // 将生成的内容追加到当前章节
    currentChapter.content += '\n\n' + response.data.result
    aiPrompt.value = ''
  } catch (error) {
    console.error('AI生成失败:', error)
  } finally {
    aiLoading.value = false
  }
}

const analyzeContent = async () => {
  if (!currentChapter.content.trim()) return
  
  aiLoading.value = true
  try {
    const response = await api.post('/ai/analyze', {
      task_type: 'analyze',
      content: currentChapter.content
    })
    
    analysisResult.value = response.data.result
  } catch (error) {
    console.error('AI分析失败:', error)
  } finally {
    aiLoading.value = false
  }
}

const suggestPlot = async () => {
  aiLoading.value = true
  try {
    const response = await api.post('/ai/suggest', {
      task_type: 'suggest',
      content: currentChapter.content,
      context: {
        characters: [], // 这里应该传入人物列表
        world_setting: '' // 这里应该传入世界观设定
      }
    })
    
    plotSuggestions.value = response.data.suggestions
  } catch (error) {
    console.error('AI建议失败:', error)
  } finally {
    aiLoading.value = false
  }
}

// 生命周期
onMounted(() => {
  // 初始化编辑器
  if (route.params.novelId) {
    // 加载指定小说的章节
  } else {
    // 创建新小说
    newChapter()
  }
})
</script>

<style scoped>
.editor-container {
  height: 100vh;
  display: flex;
  flex-direction: column;
  background-color: var(--vscode-bg-primary);
}

.editor-toolbar {
  background-color: var(--vscode-bg-secondary);
  border-bottom: 1px solid var(--vscode-border);
  padding: 8px 16px;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.toolbar-center {
  color: var(--vscode-text-secondary);
  font-size: 14px;
}

.editor-content {
  flex: 1;
  display: flex;
  overflow: hidden;
}

.editor-sidebar {
  width: 300px;
  background-color: var(--vscode-bg-secondary);
  border-right: 1px solid var(--vscode-border);
  overflow-y: auto;
}

.sidebar-header {
  padding: 16px;
  border-bottom: 1px solid var(--vscode-border);
}

.sidebar-header h3 {
  margin: 0;
  color: var(--vscode-text-primary);
}

.chapter-list {
  padding: 8px;
}

.chapter-item {
  padding: 12px;
  cursor: pointer;
  border-radius: 4px;
  margin-bottom: 4px;
  transition: background-color 0.2s;
}

.chapter-item:hover {
  background-color: var(--vscode-bg-tertiary);
}

.chapter-item.active {
  background-color: var(--vscode-accent);
  color: white;
}

.chapter-title {
  font-weight: 500;
  margin-bottom: 4px;
}

.chapter-meta {
  font-size: 12px;
  opacity: 0.7;
}

.editor-main {
  flex: 1;
  display: flex;
  flex-direction: column;
}

.chapter-header {
  padding: 16px;
  border-bottom: 1px solid var(--vscode-border);
}

.chapter-title-input {
  width: 100%;
}

.editor-text {
  flex: 1;
  padding: 16px;
}

.ai-assistant {
  width: 350px;
  background-color: var(--vscode-bg-secondary);
  border-left: 1px solid var(--vscode-border);
  display: flex;
  flex-direction: column;
}

.ai-header {
  padding: 16px;
  border-bottom: 1px solid var(--vscode-border);
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.ai-header h3 {
  margin: 0;
  color: var(--vscode-text-primary);
}

.ai-panel {
  padding: 16px;
}

.analysis-result,
.suggestions {
  margin-top: 16px;
  padding: 12px;
  background-color: var(--vscode-bg-tertiary);
  border-radius: 4px;
  font-size: 14px;
  line-height: 1.5;
}

.suggestion-item {
  padding: 8px;
  margin-bottom: 8px;
  background-color: var(--vscode-bg-primary);
  border-radius: 4px;
  cursor: pointer;
  transition: background-color 0.2s;
}

.suggestion-item:hover {
  background-color: var(--vscode-bg-tertiary);
}
</style>
