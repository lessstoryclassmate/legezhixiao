<template>
  <div class="home-container">
    <el-container>
      <!-- 侧边栏 -->
      <el-aside width="250px">
        <div class="sidebar">
          <div class="logo">
            <h2>AI小说编辑器</h2>
          </div>
          
          <el-menu
            :default-active="$route.path"
            router
            class="sidebar-menu"
          >
            <el-menu-item index="/">
              <el-icon><House /></el-icon>
              <span>首页</span>
            </el-menu-item>
            
            <el-menu-item index="/novels">
              <el-icon><Document /></el-icon>
              <span>我的小说</span>
            </el-menu-item>
            
            <el-menu-item index="/editor">
              <el-icon><Edit /></el-icon>
              <span>创作中心</span>
            </el-menu-item>
            
            <el-menu-item index="/settings">
              <el-icon><Setting /></el-icon>
              <span>设置</span>
            </el-menu-item>
          </el-menu>
        </div>
      </el-aside>
      
      <!-- 主内容区 -->
      <el-container>
        <!-- 顶部导航 -->
        <el-header height="60px">
          <div class="header">
            <div class="header-left">
              <h3>欢迎回来，{{ authStore.user?.full_name || authStore.user?.username }}</h3>
            </div>
            
            <div class="header-right">
              <el-dropdown @command="handleCommand">
                <span class="user-dropdown">
                  <el-avatar :size="32" :icon="UserFilled" />
                  <el-icon class="el-icon--right"><arrow-down /></el-icon>
                </span>
                <template #dropdown>
                  <el-dropdown-menu>
                    <el-dropdown-item command="profile">个人资料</el-dropdown-item>
                    <el-dropdown-item command="settings">设置</el-dropdown-item>
                    <el-dropdown-item divided command="logout">退出登录</el-dropdown-item>
                  </el-dropdown-menu>
                </template>
              </el-dropdown>
            </div>
          </div>
        </el-header>
        
        <!-- 主内容 -->
        <el-main>
          <div class="main-content">
            <!-- 快速统计 -->
            <div class="stats-grid">
              <el-card class="stat-card">
                <div class="stat-content">
                  <div class="stat-number">{{ stats.novelCount }}</div>
                  <div class="stat-label">总小说数</div>
                </div>
                <el-icon class="stat-icon"><Document /></el-icon>
              </el-card>
              
              <el-card class="stat-card">
                <div class="stat-content">
                  <div class="stat-number">{{ stats.wordCount }}</div>
                  <div class="stat-label">总字数</div>
                </div>
                <el-icon class="stat-icon"><EditPen /></el-icon>
              </el-card>
              
              <el-card class="stat-card">
                <div class="stat-content">
                  <div class="stat-number">{{ stats.chapterCount }}</div>
                  <div class="stat-label">总章节数</div>
                </div>
                <el-icon class="stat-icon"><Files /></el-icon>
              </el-card>
              
              <el-card class="stat-card">
                <div class="stat-content">
                  <div class="stat-number">{{ stats.aiUsage }}</div>
                  <div class="stat-label">AI使用次数</div>
                </div>
                <el-icon class="stat-icon"><MagicStick /></el-icon>
              </el-card>
            </div>
            
            <!-- 快速操作 -->
            <div class="quick-actions">
              <h3>快速操作</h3>
              <div class="action-grid">
                <el-card class="action-card" @click="createNovel">
                  <div class="action-content">
                    <el-icon class="action-icon"><Plus /></el-icon>
                    <h4>创建新小说</h4>
                    <p>开始您的创作之旅</p>
                  </div>
                </el-card>
                
                <el-card class="action-card" @click="continueWriting">
                  <div class="action-content">
                    <el-icon class="action-icon"><Edit /></el-icon>
                    <h4>继续写作</h4>
                    <p>回到最近的创作</p>
                  </div>
                </el-card>
                
                <el-card class="action-card" @click="aiAssist">
                  <div class="action-content">
                    <el-icon class="action-icon"><MagicStick /></el-icon>
                    <h4>AI助手</h4>
                    <p>获取创作灵感</p>
                  </div>
                </el-card>
              </div>
            </div>
            
            <!-- 最近创作 -->
            <div class="recent-works">
              <h3>最近创作</h3>
              <el-table :data="recentWorks" style="width: 100%">
                <el-table-column prop="title" label="小说标题" width="200" />
                <el-table-column prop="lastChapter" label="最新章节" width="180" />
                <el-table-column prop="wordCount" label="字数" width="100" />
                <el-table-column prop="updated_at" label="更新时间" width="180" />
                <el-table-column label="操作" width="200">
                  <template #default="scope">
                    <el-button 
                      type="primary" 
                      size="small"
                      @click="editNovel(scope.row)"
                    >
                      编辑
                    </el-button>
                    <el-button 
                      size="small"
                      @click="viewNovel(scope.row)"
                    >
                      查看
                    </el-button>
                  </template>
                </el-table-column>
              </el-table>
            </div>
          </div>
        </el-main>
      </el-container>
    </el-container>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import {
  House,
  Document,
  Edit,
  Setting,
  UserFilled,
  ArrowDown,
  EditPen,
  Files,
  MagicStick,
  Plus
} from '@element-plus/icons-vue'

const router = useRouter()
const authStore = useAuthStore()

const stats = ref({
  novelCount: 0,
  wordCount: 0,
  chapterCount: 0,
  aiUsage: 0
})

const recentWorks = ref([])

const handleCommand = (command) => {
  switch (command) {
    case 'profile':
      // 跳转到个人资料页面
      break
    case 'settings':
      router.push('/settings')
      break
    case 'logout':
      authStore.logout()
      router.push('/login')
      break
  }
}

const createNovel = () => {
  router.push('/editor')
}

const continueWriting = () => {
  // 跳转到最近编辑的小说
  router.push('/editor')
}

const aiAssist = () => {
  // 打开AI助手
  router.push('/editor')
}

const editNovel = (novel) => {
  router.push(`/editor/${novel.id}`)
}

const viewNovel = (novel) => {
  router.push(`/novels/${novel.id}`)
}

onMounted(async () => {
  // 加载统计数据和最近创作
  // 这里应该调用API获取真实数据
  stats.value = {
    novelCount: 3,
    wordCount: 45000,
    chapterCount: 12,
    aiUsage: 156
  }
  
  recentWorks.value = [
    {
      id: 1,
      title: '修仙传说',
      lastChapter: '第十二章：天劫降临',
      wordCount: 23000,
      updated_at: '2024-01-15 14:30:00'
    },
    {
      id: 2,
      title: '科幻未来',
      lastChapter: '第八章：星际旅行',
      wordCount: 15000,
      updated_at: '2024-01-14 09:20:00'
    },
    {
      id: 3,
      title: '都市传奇',
      lastChapter: '第五章：神秘力量',
      wordCount: 7000,
      updated_at: '2024-01-13 16:45:00'
    }
  ]
})
</script>

<style scoped>
.home-container {
  height: 100vh;
}

.sidebar {
  height: 100vh;
  background-color: var(--vscode-bg-secondary);
  border-right: 1px solid var(--vscode-border);
}

.logo {
  padding: 20px;
  text-align: center;
  border-bottom: 1px solid var(--vscode-border);
}

.logo h2 {
  margin: 0;
  color: var(--vscode-accent);
}

.sidebar-menu {
  border: none;
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0 20px;
  background-color: var(--vscode-bg-secondary);
  border-bottom: 1px solid var(--vscode-border);
}

.header-left h3 {
  margin: 0;
  color: var(--vscode-text-primary);
}

.user-dropdown {
  display: flex;
  align-items: center;
  cursor: pointer;
  gap: 8px;
}

.main-content {
  padding: 20px;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 20px;
  margin-bottom: 30px;
}

.stat-card {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 20px;
}

.stat-content {
  display: flex;
  flex-direction: column;
}

.stat-number {
  font-size: 24px;
  font-weight: bold;
  color: var(--vscode-accent);
}

.stat-label {
  font-size: 14px;
  color: var(--vscode-text-secondary);
  margin-top: 4px;
}

.stat-icon {
  font-size: 32px;
  color: var(--vscode-accent);
}

.quick-actions,
.recent-works {
  margin-bottom: 30px;
}

.quick-actions h3,
.recent-works h3 {
  margin-bottom: 16px;
  color: var(--vscode-text-primary);
}

.action-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 20px;
}

.action-card {
  cursor: pointer;
  transition: all 0.3s ease;
}

.action-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.12);
}

.action-content {
  text-align: center;
  padding: 20px;
}

.action-icon {
  font-size: 48px;
  color: var(--vscode-accent);
  margin-bottom: 16px;
}

.action-content h4 {
  margin: 0 0 8px 0;
  color: var(--vscode-text-primary);
}

.action-content p {
  margin: 0;
  color: var(--vscode-text-secondary);
  font-size: 14px;
}
</style>
