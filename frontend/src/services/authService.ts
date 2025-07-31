import type {
    User,
    LoginCredentials,
    RegisterData,
    ResetPasswordData,
    ChangePasswordData
} from '../types'

import {
    UserRole,
    SubscriptionTier
} from '../types'

// 模拟 API 基础 URL（未来使用）
// const API_BASE_URL = '/api/auth'

// 模拟用户数据存储
const MOCK_USERS_KEY = 'mock_users'
const CURRENT_USER_KEY = 'current_user'
const ACCESS_TOKEN_KEY = 'access_token'

class AuthService {
    private users: User[] = []

    constructor() {
        this.loadMockUsers()
    }

    // 加载模拟用户数据
    private loadMockUsers() {
        const savedUsers = localStorage.getItem(MOCK_USERS_KEY)
        if (savedUsers) {
            this.users = JSON.parse(savedUsers)
        } else {
            // 创建默认管理员用户
            const adminUser: User = {
                id: 'admin-001',
                username: 'admin',
                email: 'admin@legezhixiao.com',
                displayName: '系统管理员',
                avatar: '',
                role: UserRole.ADMIN,
                subscription: SubscriptionTier.ENTERPRISE,
                createdAt: new Date('2024-01-01'),
                lastLoginAt: new Date(),
                preferences: {
                    autoSave: true,
                    autoSaveInterval: 30,
                    enableAISuggestions: true,
                    constraintLevel: 'medium',
                    editorTheme: 'vs-light',
                    fontSize: 14,
                    wordWrap: true,
                    theme: 'light',
                    lineHeight: 1.6,
                },
                profile: {
                    bio: '乐阁之晓创作平台管理员',
                    location: '中国',
                    writingStats: {
                        totalWords: 0,
                        totalProjects: 0,
                        publishedProjects: 0,
                        averageWritingTime: 0,
                        dailyGoal: 2000,
                        streakDays: 0
                    }
                }
            }
            this.users = [adminUser]
            this.saveMockUsers()
        }
    }

    // 保存模拟用户数据
    private saveMockUsers() {
        localStorage.setItem(MOCK_USERS_KEY, JSON.stringify(this.users))
    }

    // 生成 JWT 令牌（模拟）
    private generateToken(user: User): string {
        const payload = {
            userId: user.id,
            email: user.email,
            role: user.role,
            exp: Date.now() + 7 * 24 * 60 * 60 * 1000 // 7天过期
        }
        return btoa(JSON.stringify(payload))
    }

    // 验证令牌
    private validateToken(token: string): { userId: string; email: string; role: UserRole } | null {
        try {
            const payload = JSON.parse(atob(token))
            if (payload.exp > Date.now()) {
                return {
                    userId: payload.userId,
                    email: payload.email,
                    role: payload.role
                }
            }
        } catch (error) {
            console.error('Token validation failed:', error)
        }
        return null
    }

    // 用户注册
    async register(data: RegisterData): Promise<{ user: User; token: string }> {
        return new Promise((resolve, reject) => {
            setTimeout(() => {
                // 检查用户名是否已存在
                if (this.users.some(u => u.username === data.username)) {
                    reject(new Error('用户名已存在'))
                    return
                }

                // 检查邮箱是否已存在
                if (this.users.some(u => u.email === data.email)) {
                    reject(new Error('邮箱已被注册'))
                    return
                }

                // 创建新用户
                const newUser: User = {
                    id: `user-${Date.now()}`,
                    username: data.username,
                    email: data.email,
                    displayName: data.displayName,
                    avatar: '',
                    role: UserRole.USER,
                    subscription: SubscriptionTier.FREE,
                    createdAt: new Date(),
                    lastLoginAt: new Date(),
                    preferences: {
                        autoSave: true,
                        autoSaveInterval: 30,
                        enableAISuggestions: true,
                        constraintLevel: 'medium',
                        editorTheme: 'vs-light',
                        fontSize: 14,
                        wordWrap: true,
                        theme: 'light',
                        lineHeight: 1.6,
                    },
                    profile: {
                        writingStats: {
                            totalWords: 0,
                            totalProjects: 0,
                            publishedProjects: 0,
                            averageWritingTime: 0,
                            dailyGoal: 1000,
                            streakDays: 0
                        }
                    }
                }

                this.users.push(newUser)
                this.saveMockUsers()

                const token = this.generateToken(newUser)
                localStorage.setItem(ACCESS_TOKEN_KEY, token)
                localStorage.setItem(CURRENT_USER_KEY, JSON.stringify(newUser))

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
                    localStorage.setItem(ACCESS_TOKEN_KEY, token)
                } else {
                    sessionStorage.setItem(ACCESS_TOKEN_KEY, token)
                }
                
                localStorage.setItem(CURRENT_USER_KEY, JSON.stringify(user))

                resolve({ user, token })
            }, 1000)
        })
    }

    // 用户登出
    async logout(): Promise<void> {
        return new Promise((resolve) => {
            setTimeout(() => {
                localStorage.removeItem(ACCESS_TOKEN_KEY)
                localStorage.removeItem(CURRENT_USER_KEY)
                sessionStorage.removeItem(ACCESS_TOKEN_KEY)
                resolve()
            }, 500)
        })
    }

    // 获取当前用户
    getCurrentUser(): User | null {
        const userStr = localStorage.getItem(CURRENT_USER_KEY)
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
        const token = localStorage.getItem(ACCESS_TOKEN_KEY) || sessionStorage.getItem(ACCESS_TOKEN_KEY)
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
