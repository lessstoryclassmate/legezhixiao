<template>
  <div class="auth-container">
    <div class="auth-card">
      <div class="auth-header">
        <h1>{{ isLogin ? '登录' : '注册' }}</h1>
        <p>{{ isLogin ? '欢迎回来！' : '加入我们，开始创作之旅' }}</p>
      </div>
      
      <form @submit.prevent="handleSubmit" class="auth-form">
        <div v-if="!isLogin" class="form-group">
          <label for="name">用户名</label>
          <input
            id="name"
            v-model="form.name"
            type="text"
            required
            placeholder="请输入用户名"
            class="form-input"
          />
        </div>
        
        <div class="form-group">
          <label for="email">邮箱</label>
          <input
            id="email"
            v-model="form.email"
            type="email"
            required
            placeholder="请输入邮箱地址"
            class="form-input"
          />
        </div>
        
        <div class="form-group">
          <label for="password">密码</label>
          <input
            id="password"
            v-model="form.password"
            type="password"
            required
            placeholder="请输入密码"
            class="form-input"
          />
        </div>
        
        <div v-if="!isLogin" class="form-group">
          <label for="confirmPassword">确认密码</label>
          <input
            id="confirmPassword"
            v-model="form.confirmPassword"
            type="password"
            required
            placeholder="请再次输入密码"
            class="form-input"
          />
        </div>
        
        <button type="submit" class="btn btn-primary btn-full" :disabled="loading">
          <span v-if="loading" class="loading-spinner"></span>
          {{ loading ? '处理中...' : (isLogin ? '登录' : '注册') }}
        </button>
      </form>
      
      <div class="auth-footer">
        <p>
          {{ isLogin ? '还没有账号？' : '已有账号？' }}
          <button @click="toggleMode" class="toggle-button">
            {{ isLogin ? '立即注册' : '立即登录' }}
          </button>
        </p>
      </div>
      
      <div class="divider">
        <span>或者</span>
      </div>
      
      <div class="social-auth">
        <button class="btn btn-outline btn-full" @click="demoLogin">
          <span class="demo-icon">🎭</span>
          体验演示账号
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'

const router = useRouter()
const route = useRoute()

// 根据路由判断是登录还是注册
const isLogin = computed(() => route.path === '/login')

// 表单数据
const form = ref({
  name: '',
  email: '',
  password: '',
  confirmPassword: ''
})

const loading = ref(false)

// 切换登录/注册模式
const toggleMode = () => {
  if (isLogin.value) {
    router.push('/register')
  } else {
    router.push('/login')
  }
  // 清空表单
  form.value = {
    name: '',
    email: '',
    password: '',
    confirmPassword: ''
  }
}

// 处理表单提交
const handleSubmit = async () => {
  if (loading.value) return
  
  // 表单验证
  if (!isLogin.value && form.value.password !== form.value.confirmPassword) {
    alert('两次输入的密码不一致')
    return
  }
  
  loading.value = true
  
  try {
    // 这里应该调用实际的API
    await mockAuth()
    
    // 存储token（实际应用中应该从API响应中获取）
    localStorage.setItem('token', 'demo-token')
    
    // 跳转到小说管理页面
    router.push('/novels')
  } catch (error) {
    console.error('认证失败:', error)
    alert('认证失败，请重试')
  } finally {
    loading.value = false
  }
}

// 模拟认证API
const mockAuth = () => {
  return new Promise((resolve) => {
    setTimeout(resolve, 1000)
  })
}

// 演示登录
const demoLogin = async () => {
  loading.value = true
  
  try {
    await mockAuth()
    localStorage.setItem('token', 'demo-token')
    router.push('/novels')
  } catch (error) {
    console.error('演示登录失败:', error)
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.auth-container {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  padding: 2rem;
}

.auth-card {
  background: white;
  border-radius: 12px;
  box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
  width: 100%;
  max-width: 400px;
  padding: 2rem;
}

.auth-header {
  text-align: center;
  margin-bottom: 2rem;
}

.auth-header h1 {
  font-size: 2rem;
  color: #2c3e50;
  margin-bottom: 0.5rem;
}

.auth-header p {
  color: #666;
  font-size: 0.9rem;
}

.auth-form {
  margin-bottom: 2rem;
}

.form-group {
  margin-bottom: 1.5rem;
}

.form-group label {
  display: block;
  margin-bottom: 0.5rem;
  color: #333;
  font-weight: 500;
  font-size: 0.9rem;
}

.form-input {
  width: 100%;
  padding: 0.8rem;
  border: 2px solid #e1e8ed;
  border-radius: 8px;
  font-size: 1rem;
  transition: all 0.3s;
  box-sizing: border-box;
}

.form-input:focus {
  outline: none;
  border-color: #409eff;
  box-shadow: 0 0 0 3px rgba(64, 158, 255, 0.1);
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
  justify-content: center;
  gap: 0.5rem;
  text-decoration: none;
}

.btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.btn-primary {
  background: #409eff;
  color: white;
}

.btn-primary:hover:not(:disabled) {
  background: #337ecc;
  transform: translateY(-2px);
}

.btn-outline {
  background: transparent;
  border: 2px solid #409eff;
  color: #409eff;
}

.btn-outline:hover {
  background: #409eff;
  color: white;
}

.btn-full {
  width: 100%;
}

.loading-spinner {
  width: 16px;
  height: 16px;
  border: 2px solid transparent;
  border-top: 2px solid currentColor;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

.auth-footer {
  text-align: center;
  margin-bottom: 1.5rem;
}

.auth-footer p {
  color: #666;
  font-size: 0.9rem;
}

.toggle-button {
  background: none;
  border: none;
  color: #409eff;
  cursor: pointer;
  font-size: 0.9rem;
  text-decoration: underline;
}

.toggle-button:hover {
  color: #337ecc;
}

.divider {
  text-align: center;
  margin: 1.5rem 0;
  position: relative;
}

.divider::before {
  content: '';
  position: absolute;
  top: 50%;
  left: 0;
  right: 0;
  height: 1px;
  background: #e1e8ed;
}

.divider span {
  background: white;
  padding: 0 1rem;
  color: #666;
  font-size: 0.9rem;
}

.social-auth {
  margin-top: 1rem;
}

.demo-icon {
  font-size: 1.1rem;
}

/* 响应式设计 */
@media (max-width: 480px) {
  .auth-container {
    padding: 1rem;
  }
  
  .auth-card {
    padding: 1.5rem;
  }
  
  .auth-header h1 {
    font-size: 1.5rem;
  }
}
</style>
