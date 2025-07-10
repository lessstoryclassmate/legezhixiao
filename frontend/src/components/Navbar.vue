<template>
  <nav class="navbar">
    <div class="navbar-brand">
      <router-link to="/" class="brand-link">
        <span class="brand-icon">✍️</span>
        <span class="brand-text">AI小说编辑器</span>
      </router-link>
    </div>
    
    <div class="navbar-nav">
      <router-link to="/" class="nav-item" active-class="active">
        <span class="nav-icon">🏠</span>
        <span class="nav-text">首页</span>
      </router-link>
      <router-link to="/novels" class="nav-item" active-class="active">
        <span class="nav-icon">📚</span>
        <span class="nav-text">我的小说</span>
      </router-link>
      <router-link to="/characters" class="nav-item" active-class="active">
        <span class="nav-icon">👥</span>
        <span class="nav-text">人物管理</span>
      </router-link>
      <router-link to="/tools" class="nav-item" active-class="active">
        <span class="nav-icon">🔧</span>
        <span class="nav-text">创作工具</span>
      </router-link>
    </div>
    
    <div class="navbar-user">
      <div v-if="user" class="user-info">
        <span class="user-avatar">{{ user.name?.charAt(0) || '用' }}</span>
        <span class="user-name">{{ user.name || '用户' }}</span>
        <button class="btn btn-outline" @click="logout">登出</button>
      </div>
      <div v-else class="auth-buttons">
        <router-link to="/login" class="btn btn-outline">登录</router-link>
        <router-link to="/register" class="btn btn-primary">注册</router-link>
      </div>
    </div>
  </nav>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'

// 用户状态管理
const user = ref<any>(null)
const router = useRouter()

// 检查用户登录状态
const checkAuth = async () => {
  try {
    const token = localStorage.getItem('token')
    if (token) {
      // 这里应该调用API验证token
      // 暂时使用模拟数据
      user.value = {
        name: '创作者',
        id: 1
      }
    }
  } catch (error) {
    console.error('检查用户状态失败:', error)
  }
}

// 登出
const logout = () => {
  localStorage.removeItem('token')
  user.value = null
  router.push('/')
}

onMounted(() => {
  checkAuth()
})
</script>

<style scoped>
.navbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem 2rem;
  background: white;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
  position: sticky;
  top: 0;
  z-index: 1000;
}

.navbar-brand {
  display: flex;
  align-items: center;
}

.brand-link {
  display: flex;
  align-items: center;
  text-decoration: none;
  color: #409eff;
  font-weight: bold;
  font-size: 1.2rem;
}

.brand-icon {
  margin-right: 0.5rem;
  font-size: 1.5rem;
}

.brand-text {
  font-size: 1.2rem;
}

.navbar-nav {
  display: flex;
  gap: 2rem;
}

.nav-item {
  display: flex;
  align-items: center;
  text-decoration: none;
  color: #666;
  padding: 0.5rem 1rem;
  border-radius: 8px;
  transition: all 0.3s;
  position: relative;
}

.nav-item:hover {
  background: #f5f7fa;
  color: #409eff;
}

.nav-item.active {
  color: #409eff;
  background: #ecf5ff;
}

.nav-icon {
  margin-right: 0.5rem;
  font-size: 1.1rem;
}

.nav-text {
  font-size: 0.9rem;
  font-weight: 500;
}

.navbar-user {
  display: flex;
  align-items: center;
}

.user-info {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.user-avatar {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  background: #409eff;
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: bold;
  font-size: 0.9rem;
}

.user-name {
  font-size: 0.9rem;
  color: #333;
  font-weight: 500;
}

.auth-buttons {
  display: flex;
  gap: 0.5rem;
}

.btn {
  padding: 0.5rem 1rem;
  border: none;
  border-radius: 6px;
  font-size: 0.9rem;
  cursor: pointer;
  text-decoration: none;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  transition: all 0.3s;
  font-weight: 500;
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

.btn-primary {
  background: #409eff;
  color: white;
}

.btn-primary:hover {
  background: #337ecc;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .navbar {
    padding: 0.5rem 1rem;
    flex-wrap: wrap;
  }
  
  .navbar-nav {
    order: 3;
    width: 100%;
    margin-top: 1rem;
    justify-content: center;
    gap: 1rem;
  }
  
  .nav-item {
    padding: 0.3rem 0.8rem;
  }
  
  .nav-text {
    display: none;
  }
  
  .nav-icon {
    margin-right: 0;
    font-size: 1.2rem;
  }
  
  .brand-text {
    display: none;
  }
}
</style>
