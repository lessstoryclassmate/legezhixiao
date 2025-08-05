import type {
    User,
    LoginCredentials,
    RegisterData,
    ResetPasswordData,
    ChangePasswordData
} from '../types'
// 文件已清空
import {
    UserRole,
    SubscriptionTier
} from '../types'

import { api } from './api'

// API 基础 URL
const API_BASE_URL = '/auth'

// 本地存储键
const CURRENT_USER_KEY = 'current_user'
const ACCESS_TOKEN_KEY = 'access_token'

class AuthService {
    constructor() {
        // 检查本地存储的认证状态
        this.initializeAuth()
    }

    // 初始化认证状态
    private initializeAuth() {
        // const token = localStorage.getItem(ACCESS_TOKEN_KEY)
        // const user = localStorage.getItem(CURRENT_USER_KEY)
        
        if (token && user) {
            // 验证令牌是否过期
            if (this.isTokenValid(token)) {
                // 令牌有效，保持登录状态
                return
            } else {
                // 令牌过期，清除本地存储
                this.logout()
            }
        }
    }

    // 验证令牌有效性
    private isTokenValid(token: string): boolean {
        try {
            const payload = JSON.parse(atob(token.split('.')[1]))
            return payload.exp * 1000 > Date.now()
        } catch (error) {
            return false
        }
    }

    // 用户注册
    async register(data: RegisterData): Promise<{ user: User; token: string }> {
        try {
            const response = await api.post(`${API_BASE_URL}/register`, data)
            
            const { user, token } = response.data
            
            // 存储认证信息
            // localStorage.setItem(ACCESS_TOKEN_KEY, token)
            // localStorage.setItem(CURRENT_USER_KEY, JSON.stringify(user))
            
            return { user, token }
        } catch (error) {
            console.error('注册失败:', error)
            throw error
        }
    }
                            // 用户登录
    async login(credentials: LoginCredentials): Promise<{ user: User; token: string }> {
        try {
            const response = await api.post(`${API_BASE_URL}/login`, credentials)
            
            const { user, token } = response.data
            
            // 存储认证信息
            // localStorage.setItem(ACCESS_TOKEN_KEY, token)
            // localStorage.setItem(CURRENT_USER_KEY, JSON.stringify(user))
            
            return { user, token }
        } catch (error) {
            console.error('登录失败:', error)
            throw error
        }
    }

    // 用户登出
    async logout(): Promise<void> {
        try {
            // const token = localStorage.getItem(ACCESS_TOKEN_KEY)
            if (token) {
                // 通知后端登出
                await api.post(`${API_BASE_URL}/logout`)
            }
        } catch (error) {
            console.error('登出请求失败:', error)
        } finally {
            // 无论后端请求是否成功都清除本地存储
            // localStorage.removeItem(ACCESS_TOKEN_KEY)
            // localStorage.removeItem(CURRENT_USER_KEY)
            sessionStorage.removeItem(ACCESS_TOKEN_KEY)
            sessionStorage.removeItem(CURRENT_USER_KEY)
        }
    }

    // 获取当前用户
    getCurrentUser(): User | null {
        // const userStr = localStorage.getItem(CURRENT_USER_KEY) || sessionStorage.getItem(CURRENT_USER_KEY)
        if (userStr) {
            try {
                const user = JSON.parse(userStr)
                // 转换日期字符串为Date对象
                if (user.createdAt) user.createdAt = new Date(user.createdAt)
                if (user.lastLoginAt) user.lastLoginAt = new Date(user.lastLoginAt)
                return user
            } catch (error) {
                console.error('解析用户数据失败:', error)
                return null
            }
        }
        return null
    }

    // 检查认证状态
    isAuthenticated(): boolean {
        // const token = localStorage.getItem(ACCESS_TOKEN_KEY) || sessionStorage.getItem(ACCESS_TOKEN_KEY)
        return token !== null && this.isTokenValid(token)
    }

    // 刷新用户信息
    async refreshUser(): Promise<User> {
        try {
            const response = await api.get(`${API_BASE_URL}/profile`)
            const user = response.data
            
            // 更新本地存储
            // localStorage.setItem(CURRENT_USER_KEY, JSON.stringify(user))
            
            return user
        } catch (error) {
            console.error('刷新用户信息失败:', error)
            throw error
        }
    }

    // 更新用户资料
    async updateProfile(updates: Partial<User>): Promise<User> {
        try {
            const response = await api.put(`${API_BASE_URL}/profile`, updates)
            const updatedUser = response.data
            
            // 更新本地存储
            // localStorage.setItem(CURRENT_USER_KEY, JSON.stringify(updatedUser))
            
            return updatedUser
        } catch (error) {
            console.error('更新用户资料失败:', error)
            throw error
        }
    }
                    }
                }

                this.users.push(newUser)
                this.saveMockUsers()

                const token = this.generateToken(newUser)
                // localStorage.setItem(ACCESS_TOKEN_KEY, token)
                // localStorage.setItem(CURRENT_USER_KEY, JSON.stringify(newUser))

                resolve({ user: newUser, token })
            }, 1000) // 模拟网络延迟
        })
    }

    // 用户登录
    async login(credentials: LoginCredentials): Promise<{ user: User; token: string }> {
        return new Promise((resolve, reject) => {
            setTimeout(() => {
                const user = this.users.find(u => u.email === credentials.email)
                
                if (!user) {
                    reject(new Error('用户不存在'))
                    return
                }

                // 在真实环境中，这里应该验证密码哈希
                // 现在为了演示，我们跳过密码验证

                // 更新最后登录时间
                user.lastLoginAt = new Date()
                this.saveMockUsers()

                const token = this.generateToken(user)
                
                if (credentials.rememberMe) {
                    // localStorage.setItem(ACCESS_TOKEN_KEY, token)
                } else {
                    sessionStorage.setItem(ACCESS_TOKEN_KEY, token)
                }
                
                // localStorage.setItem(CURRENT_USER_KEY, JSON.stringify(user))

                resolve({ user, token })
            }, 1000)
        })
    }

    // 用户登出
    async logout(): Promise<void> {
        return new Promise((resolve) => {
            setTimeout(() => {
                // localStorage.removeItem(ACCESS_TOKEN_KEY)
                // localStorage.removeItem(CURRENT_USER_KEY)
                sessionStorage.removeItem(ACCESS_TOKEN_KEY)
                resolve()
            }, 500)
        })
    }

    // 获取当前用户
    getCurrentUser(): User | null {
        // const userStr = localStorage.getItem(CURRENT_USER_KEY)
        if (userStr) {
            try {
                return JSON.parse(userStr)
            } catch (error) {
                console.error('Failed to parse current user:', error)
            }
        }
        return null
    }

    // 检查认证状态
    isAuthenticated(): boolean {
        // const token = localStorage.getItem(ACCESS_TOKEN_KEY) || sessionStorage.getItem(ACCESS_TOKEN_KEY)
        if (token) {
            const payload = this.validateToken(token)
            return payload !== null
        }
        return false
    }

    // 刷新用户信息
    async refreshUser(): Promise<User> {
        return new Promise((resolve, reject) => {
            setTimeout(() => {
                const currentUser = this.getCurrentUser()
                if (!currentUser) {
                    reject(new Error('用户未登录'))
                    return
                }

                const updatedUser = this.users.find(u => u.id === currentUser.id)
                if (updatedUser) {
                    localStorage.setItem(CURRENT_USER_KEY, JSON.stringify(updatedUser))
                    resolve(updatedUser)
                } else {
                    reject(new Error('用户不存在'))
                }
            }, 500)
        })
    }

    // 更新用户资料
    async updateProfile(updates: Partial<User>): Promise<User> {
        return new Promise((resolve, reject) => {
            setTimeout(() => {
                const currentUser = this.getCurrentUser()
                if (!currentUser) {
                    reject(new Error('用户未登录'))
                    return
                }

                const userIndex = this.users.findIndex(u => u.id === currentUser.id)
                if (userIndex === -1) {
                    reject(new Error('用户不存在'))
                    return
                }

                // 更新用户信息
                const updatedUser = { ...this.users[userIndex], ...updates }
                this.users[userIndex] = updatedUser
                this.saveMockUsers()
                localStorage.setItem(CURRENT_USER_KEY, JSON.stringify(updatedUser))

                resolve(updatedUser)
            }, 1000)
        })
    }

    // 修改密码
    async changePassword(_data: ChangePasswordData): Promise<void> {
        return new Promise((resolve) => {
            setTimeout(() => {
                // 在真实环境中，这里应该验证当前密码并更新密码哈希
                // 现在为了演示，我们假设操作成功
                resolve()
            }, 1000)
        })
    }

    // 重置密码
    async resetPassword(data: ResetPasswordData): Promise<void> {
        return new Promise((resolve, reject) => {
            setTimeout(() => {
                const user = this.users.find(u => u.email === data.email)
                if (!user) {
                    reject(new Error('邮箱地址不存在'))
                    return
                }

                // 在真实环境中，这里应该发送重置密码邮件
                console.log(`重置密码邮件已发送至: ${data.email}`)
                resolve()
            }, 1000)
        })
    }

    // 验证用户权限
    hasPermission(user: User, permission: string): boolean {
        switch (user.role) {
            case UserRole.ADMIN:
                return true // 管理员拥有所有权限
            case UserRole.PREMIUM:
                return ['read', 'write', 'export', 'ai_advanced'].includes(permission)
            case UserRole.USER:
            default:
                return ['read', 'write'].includes(permission)
        }
    }

    // 检查订阅功能
    hasFeature(user: User, feature: string): boolean {
        switch (user.subscription) {
            case SubscriptionTier.ENTERPRISE:
                return true // 企业版拥有所有功能
            case SubscriptionTier.PREMIUM:
                return ['unlimited_projects', 'ai_suggestions', 'export_advanced', 'collaboration'].includes(feature)
            case SubscriptionTier.BASIC:
                return ['ai_suggestions', 'export_basic'].includes(feature)
            case SubscriptionTier.FREE:
            default:
                return ['basic_editing'].includes(feature)
        }
    }
}

export const authService = new AuthService()
export default authService
