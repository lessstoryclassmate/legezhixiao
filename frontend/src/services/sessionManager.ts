/**
 * 会话管理服务
 * 管理用户会话、写作状态和应用状态
 */

export interface UserSession {
  id: string;
  userId: string;
  username: string;
  email?: string;
  role: 'user' | 'admin' | 'premium';
  preferences: UserPreferences;
  createdAt: string;
  lastActiveAt: string;
  expiresAt: string;
}

export interface UserPreferences {
  theme: 'light' | 'dark' | 'auto';
  language: 'zh-CN' | 'en-US';
  fontSize: number;
  fontFamily: string;
  editorSettings: EditorSettings;
  aiSettings: AISettings;
  notificationSettings: NotificationSettings;
}

export interface EditorSettings {
  showLineNumbers: boolean;
  wordWrap: boolean;
  autoSave: boolean;
  autoComplete: boolean;
  spellCheck: boolean;
  grammarCheck: boolean;
  focusMode: boolean;
  typewriterMode: boolean;
}

export interface AISettings {
  enabled: boolean;
  autoSuggestions: boolean;
  suggestionDelay: number;
  provider: string;
  model: string;
  temperature: number;
  maxTokens: number;
}

export interface NotificationSettings {
  enabled: boolean;
  writingReminders: boolean;
  goalAchievements: boolean;
  systemUpdates: boolean;
  emailNotifications: boolean;
}

export interface WritingSession {
  id: string;
  projectId: string;
  chapterId?: string;
  startTime: string;
  endTime?: string;
  wordsWritten: number;
  timeSpent: number; // 毫秒
  keystrokes: number;
  goals: SessionGoal[];
  achievements: Achievement[];
  status: 'active' | 'paused' | 'completed';
}

export interface SessionGoal {
  type: 'words' | 'time' | 'chapters';
  target: number;
  current: number;
  completed: boolean;
}

export interface Achievement {
  id: string;
  type: string;
  title: string;
  description: string;
  unlockedAt: string;
  points: number;
}

export interface AppState {
  currentProject?: string;
  currentChapter?: string;
  currentSession?: string;
  sidebar: {
    collapsed: boolean;
    activePanel: string;
  };
  editor: {
    cursorPosition: number;
    scrollPosition: number;
    selectedText?: string;
  };
  ai: {
    panelOpen: boolean;
    lastSuggestion?: string;
    contextLength: number;
  };
}

export class SessionManagerService {
  private static instance: SessionManagerService;
  private currentSession: UserSession | null = null;
  private currentWritingSession: WritingSession | null = null;
  private appState: AppState;
  private sessionCheckInterval: NodeJS.Timeout | null = null;
  private autoSaveInterval: NodeJS.Timeout | null = null;

  constructor() {
    this.appState = this.getDefaultAppState();
    this.initializeFromStorage();
    this.startSessionMonitoring();
  }

  static getInstance(): SessionManagerService {
    if (!SessionManagerService.instance) {
      SessionManagerService.instance = new SessionManagerService();
    }
    return SessionManagerService.instance;
  }

  /**
   * 用户登录
   */
  async login(credentials: { username: string; password: string }): Promise<UserSession> {
    try {
      // TODO: 实际的登录API调用
      const response = await this.mockLogin(credentials);
      
      this.currentSession = response;
      this.saveSessionToStorage();
      this.startSessionMonitoring();
      
      return response;
    } catch (error) {
      console.error('Login failed:', error);
      throw error;
    }
  }

  /**
   * 用户登出
   */
  async logout(): Promise<void> {
    try {
      if (this.currentWritingSession) {
        await this.endWritingSession();
      }

      // TODO: 实际的登出API调用
      await this.mockLogout();

      this.currentSession = null;
      this.clearSessionStorage();
      this.stopSessionMonitoring();
    } catch (error) {
      console.error('Logout failed:', error);
      throw error;
    }
  }

  /**
   * 获取当前用户会话
   */
  getCurrentSession(): UserSession | null {
    return this.currentSession;
  }

  /**
   * 检查会话是否有效
   */
  isSessionValid(): boolean {
    if (!this.currentSession) return false;
    
    const now = new Date();
    const expiresAt = new Date(this.currentSession.expiresAt);
    
    return now < expiresAt;
  }

  /**
   * 刷新会话
   */
  async refreshSession(): Promise<UserSession | null> {
    if (!this.currentSession) return null;

    try {
      // TODO: 实际的会话刷新API调用
      const refreshedSession = await this.mockRefreshSession(this.currentSession.id);
      
      this.currentSession = refreshedSession;
      this.saveSessionToStorage();
      
      return refreshedSession;
    } catch (error) {
      console.error('Session refresh failed:', error);
      await this.logout();
      return null;
    }
  }

  /**
   * 更新用户偏好设置
   */
  async updatePreferences(preferences: Partial<UserPreferences>): Promise<void> {
    if (!this.currentSession) return;

    this.currentSession.preferences = {
      ...this.currentSession.preferences,
      ...preferences
    };

    this.saveSessionToStorage();
    
    // TODO: 同步到服务器
    await this.mockUpdatePreferences(this.currentSession.id, this.currentSession.preferences);
  }

  /**
   * 开始写作会话
   */
  async startWritingSession(projectId: string, chapterId?: string): Promise<WritingSession> {
    if (this.currentWritingSession) {
      await this.endWritingSession();
    }

    const session: WritingSession = {
      id: `session_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      projectId,
      chapterId,
      startTime: new Date().toISOString(),
      wordsWritten: 0,
      timeSpent: 0,
      keystrokes: 0,
      goals: this.generateSessionGoals(),
      achievements: [],
      status: 'active'
    };

    this.currentWritingSession = session;
    this.startAutoSave();
    
    return session;
  }

  /**
   * 暂停写作会话
   */
  pauseWritingSession(): void {
    if (this.currentWritingSession) {
      this.currentWritingSession.status = 'paused';
      this.stopAutoSave();
    }
  }

  /**
   * 恢复写作会话
   */
  resumeWritingSession(): void {
    if (this.currentWritingSession) {
      this.currentWritingSession.status = 'active';
      this.startAutoSave();
    }
  }

  /**
   * 结束写作会话
   */
  async endWritingSession(): Promise<WritingSession | null> {
    if (!this.currentWritingSession) return null;

    this.currentWritingSession.endTime = new Date().toISOString();
    this.currentWritingSession.status = 'completed';
    
    const startTime = new Date(this.currentWritingSession.startTime);
    const endTime = new Date(this.currentWritingSession.endTime);
    this.currentWritingSession.timeSpent = endTime.getTime() - startTime.getTime();

    // 检查目标完成情况
    this.updateGoalProgress();
    
    // 检查成就
    await this.checkAchievements();

    const completedSession = { ...this.currentWritingSession };
    
    // 保存会话记录
    await this.saveWritingSession(completedSession);
    
    this.currentWritingSession = null;
    this.stopAutoSave();
    
    return completedSession;
  }

  /**
   * 获取当前写作会话
   */
  getCurrentWritingSession(): WritingSession | null {
    return this.currentWritingSession;
  }

  /**
   * 更新写作进度
   */
  updateWritingProgress(wordsAdded: number, keystrokesAdded: number = 0): void {
    if (!this.currentWritingSession) return;

    this.currentWritingSession.wordsWritten += wordsAdded;
    this.currentWritingSession.keystrokes += keystrokesAdded;

    // 更新目标进度
    this.updateGoalProgress();
  }

  /**
   * 获取应用状态
   */
  getAppState(): AppState {
    return { ...this.appState };
  }

  /**
   * 更新应用状态
   */
  updateAppState(updates: Partial<AppState>): void {
    this.appState = {
      ...this.appState,
      ...updates
    };
    
    this.saveAppStateToStorage();
  }

  /**
   * 获取用户写作统计
   */
  async getUserStats(period: 'day' | 'week' | 'month' | 'year' = 'week'): Promise<any> {
    // TODO: 实现统计数据获取
    return {
      totalWords: 0,
      totalTime: 0,
      averageDaily: 0,
      streak: 0,
      achievements: []
    };
  }

  /**
   * 获取用户成就
   */
  async getUserAchievements(): Promise<Achievement[]> {
    // TODO: 实现成就系统
    return [];
  }

  // 私有方法

  private getDefaultAppState(): AppState {
    return {
      sidebar: {
        collapsed: false,
        activePanel: 'project'
      },
      editor: {
        cursorPosition: 0,
        scrollPosition: 0
      },
      ai: {
        panelOpen: false,
        contextLength: 1000
      }
    };
  }

  private initializeFromStorage(): void {
    try {
      const sessionData = localStorage.getItem('user_session');
      if (sessionData) {
        const session = JSON.parse(sessionData);
        if (this.isSessionDataValid(session)) {
          this.currentSession = session;
        }
      }

      const appStateData = localStorage.getItem('app_state');
      if (appStateData) {
        const state = JSON.parse(appStateData);
        this.appState = { ...this.appState, ...state };
      }
    } catch (error) {
      console.error('Failed to initialize from storage:', error);
    }
  }

  private saveSessionToStorage(): void {
    if (this.currentSession) {
      localStorage.setItem('user_session', JSON.stringify(this.currentSession));
    }
  }

  private saveAppStateToStorage(): void {
    localStorage.setItem('app_state', JSON.stringify(this.appState));
  }

  private clearSessionStorage(): void {
    localStorage.removeItem('user_session');
    localStorage.removeItem('app_state');
  }

  private startSessionMonitoring(): void {
    if (this.sessionCheckInterval) return;

    this.sessionCheckInterval = setInterval(() => {
      if (!this.isSessionValid()) {
        this.logout();
      }
    }, 60000); // 每分钟检查一次
  }

  private stopSessionMonitoring(): void {
    if (this.sessionCheckInterval) {
      clearInterval(this.sessionCheckInterval);
      this.sessionCheckInterval = null;
    }
  }

  private startAutoSave(): void {
    if (this.autoSaveInterval) return;

    this.autoSaveInterval = setInterval(() => {
      if (this.currentWritingSession) {
        // TODO: 实现自动保存逻辑
        console.log('Auto-saving session...');
      }
    }, 30000); // 每30秒自动保存
  }

  private stopAutoSave(): void {
    if (this.autoSaveInterval) {
      clearInterval(this.autoSaveInterval);
      this.autoSaveInterval = null;
    }
  }

  private generateSessionGoals(): SessionGoal[] {
    // 根据用户偏好生成会话目标
    return [
      {
        type: 'words',
        target: 500,
        current: 0,
        completed: false
      },
      {
        type: 'time',
        target: 30 * 60 * 1000, // 30分钟
        current: 0,
        completed: false
      }
    ];
  }

  private updateGoalProgress(): void {
    if (!this.currentWritingSession) return;

    this.currentWritingSession.goals.forEach(goal => {
      switch (goal.type) {
        case 'words':
          goal.current = this.currentWritingSession!.wordsWritten;
          goal.completed = goal.current >= goal.target;
          break;
        case 'time':
          const timeSpent = Date.now() - new Date(this.currentWritingSession!.startTime).getTime();
          goal.current = timeSpent;
          goal.completed = goal.current >= goal.target;
          break;
      }
    });
  }

  private async checkAchievements(): Promise<void> {
    if (!this.currentWritingSession) return;

    // TODO: 实现成就检查逻辑
    const newAchievements: Achievement[] = [];

    // 示例：连续写作成就
    if (this.currentWritingSession.wordsWritten >= 1000) {
      newAchievements.push({
        id: `achievement_${Date.now()}`,
        type: 'words_milestone',
        title: '千字达人',
        description: '单次写作达到1000字',
        unlockedAt: new Date().toISOString(),
        points: 100
      });
    }

    this.currentWritingSession.achievements.push(...newAchievements);
  }

  private async saveWritingSession(session: WritingSession): Promise<void> {
    try {
      // TODO: 保存到数据库
      console.log('Saving writing session:', session);
    } catch (error) {
      console.error('Failed to save writing session:', error);
    }
  }

  private isSessionDataValid(session: any): boolean {
    return session && 
           session.id && 
           session.userId && 
           session.expiresAt &&
           new Date(session.expiresAt) > new Date();
  }

  // Mock API 方法 (实际使用时替换为真实API)

  private async mockLogin(credentials: { username: string; password: string }): Promise<UserSession> {
    // 模拟API延迟
    await new Promise(resolve => setTimeout(resolve, 1000));

    const session: UserSession = {
      id: `session_${Date.now()}`,
      userId: `user_${credentials.username}`,
      username: credentials.username,
      email: `${credentials.username}@example.com`,
      role: 'user',
      preferences: {
        theme: 'light',
        language: 'zh-CN',
        fontSize: 14,
        fontFamily: 'Arial',
        editorSettings: {
          showLineNumbers: true,
          wordWrap: true,
          autoSave: true,
          autoComplete: true,
          spellCheck: true,
          grammarCheck: true,
          focusMode: false,
          typewriterMode: false
        },
        aiSettings: {
          enabled: true,
          autoSuggestions: true,
          suggestionDelay: 1000,
          provider: 'siliconflow',
          model: 'deepseek-ai/DeepSeek-V3',
          temperature: 0.7,
          maxTokens: 1000
        },
        notificationSettings: {
          enabled: true,
          writingReminders: true,
          goalAchievements: true,
          systemUpdates: true,
          emailNotifications: false
        }
      },
      createdAt: new Date().toISOString(),
      lastActiveAt: new Date().toISOString(),
      expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString() // 24小时后过期
    };

    return session;
  }

  private async mockLogout(): Promise<void> {
    await new Promise(resolve => setTimeout(resolve, 500));
  }

  private async mockRefreshSession(sessionId: string): Promise<UserSession> {
    if (!this.currentSession) throw new Error('No session to refresh');
    
    await new Promise(resolve => setTimeout(resolve, 500));
    
    return {
      ...this.currentSession,
      lastActiveAt: new Date().toISOString(),
      expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString()
    };
  }

  private async mockUpdatePreferences(sessionId: string, preferences: UserPreferences): Promise<void> {
    await new Promise(resolve => setTimeout(resolve, 500));
    console.log('Preferences updated on server:', preferences);
  }
}

// 创建单例实例
export const sessionManager = SessionManagerService.getInstance();
