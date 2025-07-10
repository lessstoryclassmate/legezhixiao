<template>
  <div class="novels-container">
    <!-- 页面头部 -->
    <div class="page-header">
      <div class="header-content">
        <h1>我的小说</h1>
        <p>管理您的创作作品</p>
      </div>
      <div class="header-actions">
        <button class="btn btn-primary" @click="showCreateModal = true">
          <span class="btn-icon">✏️</span>
          创建新小说
        </button>
      </div>
    </div>

    <!-- 筛选和搜索 -->
    <div class="filters">
      <div class="search-box">
        <input
          v-model="searchQuery"
          type="text"
          placeholder="搜索小说..."
          class="search-input"
        />
        <span class="search-icon">🔍</span>
      </div>
      <div class="filter-buttons">
        <button
          v-for="status in statusFilters"
          :key="status.value"
          :class="['filter-btn', { active: selectedStatus === status.value }]"
          @click="selectedStatus = status.value"
        >
          {{ status.label }}
        </button>
      </div>
    </div>

    <!-- 小说列表 -->
    <div class="novels-grid">
      <div
        v-for="novel in filteredNovels"
        :key="novel.id"
        class="novel-card"
        @click="openNovel(novel)"
      >
        <div class="novel-cover">
          <img :src="novel.cover || '/placeholder-cover.jpg'" :alt="novel.title" />
          <div class="novel-status" :class="novel.status">
            {{ getStatusLabel(novel.status) }}
          </div>
        </div>
        <div class="novel-info">
          <h3 class="novel-title">{{ novel.title }}</h3>
          <p class="novel-description">{{ novel.description }}</p>
          <div class="novel-stats">
            <span class="stat">
              <span class="stat-icon">📝</span>
              {{ novel.chapters }}章
            </span>
            <span class="stat">
              <span class="stat-icon">📊</span>
              {{ novel.wordCount }}字
            </span>
            <span class="stat">
              <span class="stat-icon">📅</span>
              {{ formatDate(novel.updatedAt) }}
            </span>
          </div>
        </div>
        <div class="novel-actions">
          <button class="action-btn" @click.stop="editNovel(novel)">
            <span class="action-icon">✏️</span>
            编辑
          </button>
          <button class="action-btn" @click.stop="deleteNovel(novel)">
            <span class="action-icon">🗑️</span>
            删除
          </button>
        </div>
      </div>
    </div>

    <!-- 空状态 -->
    <div v-if="filteredNovels.length === 0" class="empty-state">
      <div class="empty-icon">📚</div>
      <h3>还没有小说</h3>
      <p>开始创作您的第一部小说吧！</p>
      <button class="btn btn-primary" @click="showCreateModal = true">
        创建新小说
      </button>
    </div>

    <!-- 创建小说模态框 -->
    <div v-if="showCreateModal" class="modal-overlay" @click="showCreateModal = false">
      <div class="modal-content" @click.stop>
        <div class="modal-header">
          <h2>创建新小说</h2>
          <button class="close-btn" @click="showCreateModal = false">×</button>
        </div>
        <form @submit.prevent="createNovel" class="modal-form">
          <div class="form-group">
            <label for="title">小说标题</label>
            <input
              id="title"
              v-model="newNovel.title"
              type="text"
              required
              placeholder="请输入小说标题"
              class="form-input"
            />
          </div>
          <div class="form-group">
            <label for="description">小说简介</label>
            <textarea
              id="description"
              v-model="newNovel.description"
              rows="4"
              placeholder="请输入小说简介"
              class="form-textarea"
            ></textarea>
          </div>
          <div class="form-group">
            <label for="genre">小说类型</label>
            <select id="genre" v-model="newNovel.genre" class="form-select">
              <option value="">请选择类型</option>
              <option value="fantasy">奇幻</option>
              <option value="romance">言情</option>
              <option value="mystery">悬疑</option>
              <option value="scifi">科幻</option>
              <option value="historical">历史</option>
              <option value="urban">都市</option>
            </select>
          </div>
          <div class="modal-actions">
            <button type="button" class="btn btn-outline" @click="showCreateModal = false">
              取消
            </button>
            <button type="submit" class="btn btn-primary">
              创建小说
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'

const router = useRouter()

// 数据状态
const novels = ref([
  {
    id: 1,
    title: '修仙之路',
    description: '一个普通少年的修仙传奇故事，从凡人到仙人的蜕变历程。',
    cover: null,
    status: 'draft',
    chapters: 15,
    wordCount: 45000,
    genre: 'fantasy',
    createdAt: '2024-01-15',
    updatedAt: '2024-01-20'
  },
  {
    id: 2,
    title: '都市传说',
    description: '现代都市中隐藏的超自然现象，一个年轻人的冒险故事。',
    cover: null,
    status: 'published',
    chapters: 28,
    wordCount: 78000,
    genre: 'urban',
    createdAt: '2024-01-10',
    updatedAt: '2024-01-25'
  }
])

const searchQuery = ref('')
const selectedStatus = ref('all')
const showCreateModal = ref(false)

// 新小说表单
const newNovel = ref({
  title: '',
  description: '',
  genre: ''
})

// 状态筛选选项
const statusFilters = [
  { value: 'all', label: '全部' },
  { value: 'draft', label: '草稿' },
  { value: 'published', label: '已发布' },
  { value: 'completed', label: '已完结' }
]

// 筛选后的小说列表
const filteredNovels = computed(() => {
  return novels.value.filter(novel => {
    const matchesSearch = novel.title.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
                         novel.description.toLowerCase().includes(searchQuery.value.toLowerCase())
    const matchesStatus = selectedStatus.value === 'all' || novel.status === selectedStatus.value
    return matchesSearch && matchesStatus
  })
})

// 获取状态标签
const getStatusLabel = (status: string) => {
  const labels = {
    draft: '草稿',
    published: '已发布',
    completed: '已完结'
  }
  return labels[status] || '未知'
}

// 格式化日期
const formatDate = (dateString: string) => {
  const date = new Date(dateString)
  return date.toLocaleDateString('zh-CN', {
    year: 'numeric',
    month: 'short',
    day: 'numeric'
  })
}

// 打开小说编辑器
const openNovel = (novel: any) => {
  router.push(`/novel/${novel.id}/edit`)
}

// 编辑小说信息
const editNovel = (novel: any) => {
  // 这里应该打开编辑模态框
  console.log('编辑小说:', novel)
}

// 删除小说
const deleteNovel = (novel: any) => {
  if (confirm(`确定要删除小说"${novel.title}"吗？`)) {
    novels.value = novels.value.filter(n => n.id !== novel.id)
  }
}

// 创建新小说
const createNovel = () => {
  const novel = {
    id: Date.now(),
    title: newNovel.value.title,
    description: newNovel.value.description,
    genre: newNovel.value.genre,
    cover: null,
    status: 'draft',
    chapters: 0,
    wordCount: 0,
    createdAt: new Date().toISOString().split('T')[0],
    updatedAt: new Date().toISOString().split('T')[0]
  }
  
  novels.value.unshift(novel)
  showCreateModal.value = false
  
  // 重置表单
  newNovel.value = {
    title: '',
    description: '',
    genre: ''
  }
  
  // 跳转到编辑页面
  router.push(`/novel/${novel.id}/edit`)
}

onMounted(() => {
  // 检查用户是否已登录
  const token = localStorage.getItem('token')
  if (!token) {
    router.push('/login')
  }
})
</script>

<style scoped>
.novels-container {
  padding: 2rem;
  max-width: 1200px;
  margin: 0 auto;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2rem;
}

.header-content h1 {
  font-size: 2rem;
  color: #2c3e50;
  margin-bottom: 0.5rem;
}

.header-content p {
  color: #666;
  font-size: 1rem;
}

.header-actions {
  display: flex;
  gap: 1rem;
}

.btn {
  padding: 0.8rem 1.5rem;
  border: none;
  border-radius: 8px;
  font-size: 1rem;
  cursor: pointer;
  transition: all 0.3s;
  font-weight: 500;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  text-decoration: none;
}

.btn-primary {
  background: #409eff;
  color: white;
}

.btn-primary:hover {
  background: #337ecc;
  transform: translateY(-2px);
}

.btn-outline {
  background: transparent;
  border: 1px solid #409eff;
  color: #409eff;
}

.btn-outline:hover {
  background: #409eff;
  color: white;
}

.btn-icon {
  font-size: 1.1rem;
}

.filters {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2rem;
  gap: 1rem;
}

.search-box {
  position: relative;
  flex: 1;
  max-width: 400px;
}

.search-input {
  width: 100%;
  padding: 0.8rem 3rem 0.8rem 1rem;
  border: 2px solid #e1e8ed;
  border-radius: 8px;
  font-size: 1rem;
  transition: border-color 0.3s;
  box-sizing: border-box;
}

.search-input:focus {
  outline: none;
  border-color: #409eff;
}

.search-icon {
  position: absolute;
  right: 1rem;
  top: 50%;
  transform: translateY(-50%);
  font-size: 1.2rem;
  color: #666;
}

.filter-buttons {
  display: flex;
  gap: 0.5rem;
}

.filter-btn {
  padding: 0.5rem 1rem;
  border: 1px solid #e1e8ed;
  border-radius: 6px;
  background: white;
  color: #666;
  cursor: pointer;
  transition: all 0.3s;
  font-size: 0.9rem;
}

.filter-btn:hover {
  border-color: #409eff;
  color: #409eff;
}

.filter-btn.active {
  background: #409eff;
  color: white;
  border-color: #409eff;
}

.novels-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 2rem;
}

.novel-card {
  background: white;
  border-radius: 12px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  overflow: hidden;
  transition: all 0.3s;
  cursor: pointer;
}

.novel-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.15);
}

.novel-cover {
  position: relative;
  height: 180px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-size: 3rem;
}

.novel-cover img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.novel-status {
  position: absolute;
  top: 0.5rem;
  right: 0.5rem;
  padding: 0.25rem 0.5rem;
  border-radius: 4px;
  font-size: 0.8rem;
  font-weight: 500;
  background: rgba(255, 255, 255, 0.9);
  color: #333;
}

.novel-status.draft {
  background: rgba(255, 193, 7, 0.9);
}

.novel-status.published {
  background: rgba(40, 167, 69, 0.9);
  color: white;
}

.novel-status.completed {
  background: rgba(108, 117, 125, 0.9);
  color: white;
}

.novel-info {
  padding: 1.5rem;
}

.novel-title {
  font-size: 1.3rem;
  font-weight: 600;
  color: #2c3e50;
  margin-bottom: 0.5rem;
}

.novel-description {
  color: #666;
  font-size: 0.9rem;
  line-height: 1.6;
  margin-bottom: 1rem;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.novel-stats {
  display: flex;
  gap: 1rem;
  margin-bottom: 1rem;
}

.stat {
  display: flex;
  align-items: center;
  gap: 0.3rem;
  color: #666;
  font-size: 0.8rem;
}

.stat-icon {
  font-size: 1rem;
}

.novel-actions {
  display: flex;
  gap: 0.5rem;
  padding: 0 1.5rem 1.5rem;
}

.action-btn {
  flex: 1;
  padding: 0.5rem;
  border: 1px solid #e1e8ed;
  border-radius: 6px;
  background: white;
  color: #666;
  cursor: pointer;
  transition: all 0.3s;
  font-size: 0.9rem;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.3rem;
}

.action-btn:hover {
  border-color: #409eff;
  color: #409eff;
}

.action-icon {
  font-size: 1rem;
}

.empty-state {
  text-align: center;
  padding: 4rem 2rem;
  color: #666;
}

.empty-icon {
  font-size: 4rem;
  margin-bottom: 1rem;
}

.empty-state h3 {
  font-size: 1.5rem;
  margin-bottom: 0.5rem;
  color: #2c3e50;
}

.empty-state p {
  margin-bottom: 2rem;
}

.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal-content {
  background: white;
  border-radius: 12px;
  width: 90%;
  max-width: 500px;
  max-height: 90vh;
  overflow-y: auto;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.5rem 2rem;
  border-bottom: 1px solid #e1e8ed;
}

.modal-header h2 {
  font-size: 1.5rem;
  color: #2c3e50;
}

.close-btn {
  background: none;
  border: none;
  font-size: 1.5rem;
  cursor: pointer;
  color: #666;
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  transition: all 0.3s;
}

.close-btn:hover {
  background: #f5f5f5;
}

.modal-form {
  padding: 2rem;
}

.form-group {
  margin-bottom: 1.5rem;
}

.form-group label {
  display: block;
  margin-bottom: 0.5rem;
  color: #333;
  font-weight: 500;
}

.form-input,
.form-textarea,
.form-select {
  width: 100%;
  padding: 0.8rem;
  border: 2px solid #e1e8ed;
  border-radius: 8px;
  font-size: 1rem;
  transition: border-color 0.3s;
  box-sizing: border-box;
}

.form-input:focus,
.form-textarea:focus,
.form-select:focus {
  outline: none;
  border-color: #409eff;
}

.form-textarea {
  resize: vertical;
  min-height: 100px;
}

.modal-actions {
  display: flex;
  gap: 1rem;
  justify-content: flex-end;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .novels-container {
    padding: 1rem;
  }
  
  .page-header {
    flex-direction: column;
    gap: 1rem;
    align-items: flex-start;
  }
  
  .filters {
    flex-direction: column;
    gap: 1rem;
  }
  
  .search-box {
    max-width: none;
  }
  
  .filter-buttons {
    flex-wrap: wrap;
  }
  
  .novels-grid {
    grid-template-columns: 1fr;
  }
  
  .modal-content {
    width: 95%;
  }
  
  .modal-form {
    padding: 1.5rem;
  }
  
  .modal-actions {
    flex-direction: column;
  }
}
</style>
