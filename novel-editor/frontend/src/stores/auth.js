import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { api } from '@/utils/api'

export const useAuthStore = defineStore('auth', () => {
  const token = ref(localStorage.getItem('token'))
  const user = ref(null)

  const isAuthenticated = computed(() => !!token.value)

  const login = async (credentials) => {
    try {
      const response = await api.post('/auth/login', credentials)
      token.value = response.data.access_token
      localStorage.setItem('token', token.value)
      
      // 获取用户信息
      await fetchUser()
      
      return { success: true }
    } catch (error) {
      return { 
        success: false, 
        message: error.response?.data?.detail || '登录失败' 
      }
    }
  }

  const register = async (userData) => {
    try {
      await api.post('/auth/register', userData)
      return { success: true }
    } catch (error) {
      return { 
        success: false, 
        message: error.response?.data?.detail || '注册失败' 
      }
    }
  }

  const logout = () => {
    token.value = null
    user.value = null
    localStorage.removeItem('token')
  }

  const fetchUser = async () => {
    try {
      const response = await api.get('/auth/me')
      user.value = response.data
    } catch (error) {
      logout()
      throw error
    }
  }

  // 初始化时获取用户信息
  if (token.value) {
    fetchUser().catch(() => {
      logout()
    })
  }

  return {
    token,
    user,
    isAuthenticated,
    login,
    register,
    logout,
    fetchUser
  }
})
