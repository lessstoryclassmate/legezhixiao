import { useEffect, useState, useCallback } from 'react';
import { Observable, Subscription } from 'rxjs';
import { 
  rxdbService, 
  UserDocument, 
  ProjectDocument, 
  ChapterDocument, 
  CharacterDocument, 
  WritingSessionDocument, 
  WritingGoalDocument 
} from '../services/rxdbService';

// 基础 Hook - 数据库状态
export const useRxDB = () => {
  const [isInitialized, setIsInitialized] = useState(false);
  const [syncState, setSyncState] = useState<'idle' | 'syncing' | 'error'>('idle');

  useEffect(() => {
    const initSub = rxdbService.isInitialized().subscribe(setIsInitialized);
    const syncSub = rxdbService.getSyncState().subscribe(setSyncState);

    return () => {
      initSub.unsubscribe();
      syncSub.unsubscribe();
    };
  }, []);

  const forceSync = useCallback(async () => {
    await rxdbService.forcSync();
  }, []);

  const clearCache = useCallback(async () => {
    await rxdbService.clearCache();
  }, []);

  const exportData = useCallback(async () => {
    return await rxdbService.exportData();
  }, []);

  const importData = useCallback(async (data: any) => {
    await rxdbService.importData(data);
  }, []);

  return {
    isInitialized,
    syncState,
    forceSync,
    clearCache,
    exportData,
    importData
  };
};

// 用户相关 Hook
export const useUser = (userId?: string) => {
  const [user, setUser] = useState<UserDocument | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // 获取用户
  const fetchUser = useCallback(async (id: string) => {
    setLoading(true);
    setError(null);
    try {
      const userData = await rxdbService.getUserById(id);
      setUser(userData);
    } catch (err) {
      setError(err instanceof Error ? err.message : '获取用户信息失败');
    } finally {
      setLoading(false);
    }
  }, []);

  // 创建用户
  const createUser = useCallback(async (userData: Omit<UserDocument, 'id' | 'createdAt' | 'updatedAt'>) => {
    setLoading(true);
    setError(null);
    try {
      const newUser = await rxdbService.createUser(userData);
      setUser(newUser);
      return newUser;
    } catch (err) {
      setError(err instanceof Error ? err.message : '创建用户失败');
      throw err;
    } finally {
      setLoading(false);
    }
  }, []);

  // 更新用户
  const updateUser = useCallback(async (id: string, updates: Partial<UserDocument>) => {
    setLoading(true);
    setError(null);
    try {
      const updatedUser = await rxdbService.updateUser(id, updates);
      setUser(updatedUser);
      return updatedUser;
    } catch (err) {
      setError(err instanceof Error ? err.message : '更新用户信息失败');
      throw err;
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    if (userId) {
      fetchUser(userId);
    }
  }, [userId, fetchUser]);

  return {
    user,
    loading,
    error,
    fetchUser,
    createUser,
    updateUser
  };
};

// 项目相关 Hook
export const useProjects = (userId?: string) => {
  const [projects, setProjects] = useState<ProjectDocument[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // 获取用户的所有项目
  const fetchProjects = useCallback(async (uid: string) => {
    setLoading(true);
    setError(null);
    try {
      const projectsData = await rxdbService.getProjectsByUserId(uid);
      setProjects(projectsData);
    } catch (err) {
      setError(err instanceof Error ? err.message : '获取项目列表失败');
    } finally {
      setLoading(false);
    }
  }, []);

  // 创建项目
  const createProject = useCallback(async (projectData: Omit<ProjectDocument, 'id' | 'createdAt' | 'updatedAt'>) => {
    setLoading(true);
    setError(null);
    try {
      const newProject = await rxdbService.createProject(projectData);
      setProjects(prev => [newProject, ...prev]);
      return newProject;
    } catch (err) {
      setError(err instanceof Error ? err.message : '创建项目失败');
      throw err;
    } finally {
      setLoading(false);
    }
  }, []);

  // 更新项目
  const updateProject = useCallback(async (id: string, updates: Partial<ProjectDocument>) => {
    setLoading(true);
    setError(null);
    try {
      const updatedProject = await rxdbService.updateProject(id, updates);
      if (updatedProject) {
        setProjects(prev => prev.map(p => p.id === id ? updatedProject : p));
      }
      return updatedProject;
    } catch (err) {
      setError(err instanceof Error ? err.message : '更新项目失败');
      throw err;
    } finally {
      setLoading(false);
    }
  }, []);

  // 删除项目（软删除）
  const deleteProject = useCallback(async (id: string) => {
    try {
      // 这里可以实现软删除逻辑
      setProjects(prev => prev.filter(p => p.id !== id));
    } catch (err) {
      setError(err instanceof Error ? err.message : '删除项目失败');
      throw err;
    }
  }, []);

  useEffect(() => {
    if (userId) {
      fetchProjects(userId);
    }
  }, [userId, fetchProjects]);

  return {
    projects,
    loading,
    error,
    fetchProjects,
    createProject,
    updateProject,
    deleteProject
  };
};

// 章节相关 Hook
export const useChapters = (projectId?: string) => {
  const [chapters, setChapters] = useState<ChapterDocument[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // 获取项目的所有章节
  const fetchChapters = useCallback(async (pid: string) => {
    setLoading(true);
    setError(null);
    try {
      const chaptersData = await rxdbService.getChaptersByProjectId(pid);
      setChapters(chaptersData);
    } catch (err) {
      setError(err instanceof Error ? err.message : '获取章节列表失败');
    } finally {
      setLoading(false);
    }
  }, []);

  // 创建章节
  const createChapter = useCallback(async (chapterData: Omit<ChapterDocument, 'id' | 'createdAt' | 'updatedAt'>) => {
    setLoading(true);
    setError(null);
    try {
      const newChapter = await rxdbService.createChapter(chapterData);
      setChapters(prev => [...prev, newChapter].sort((a, b) => a.orderIndex - b.orderIndex));
      return newChapter;
    } catch (err) {
      setError(err instanceof Error ? err.message : '创建章节失败');
      throw err;
    } finally {
      setLoading(false);
    }
  }, []);

  // 更新章节
  const updateChapter = useCallback(async (id: string, updates: Partial<ChapterDocument>) => {
    setLoading(true);
    setError(null);
    try {
      const updatedChapter = await rxdbService.updateChapter(id, updates);
      if (updatedChapter) {
        setChapters(prev => prev.map(c => c.id === id ? updatedChapter : c));
      }
      return updatedChapter;
    } catch (err) {
      setError(err instanceof Error ? err.message : '更新章节失败');
      throw err;
    } finally {
      setLoading(false);
    }
  }, []);

  // 重新排序章节
  const reorderChapters = useCallback(async (chapterIds: string[]) => {
    try {
      // 更新章节顺序
      const updatePromises = chapterIds.map((chapterId, index) => 
        rxdbService.updateChapter(chapterId, { orderIndex: index })
      );
      await Promise.all(updatePromises);
      
      // 重新获取章节列表
      if (projectId) {
        await fetchChapters(projectId);
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : '重新排序章节失败');
      throw err;
    }
  }, [projectId, fetchChapters]);

  useEffect(() => {
    if (projectId) {
      fetchChapters(projectId);
    }
  }, [projectId, fetchChapters]);

  return {
    chapters,
    loading,
    error,
    fetchChapters,
    createChapter,
    updateChapter,
    reorderChapters
  };
};

// 角色相关 Hook
export const useCharacters = (projectId?: string) => {
  const [characters, setCharacters] = useState<CharacterDocument[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // 获取项目的所有角色
  const fetchCharacters = useCallback(async (pid: string) => {
    setLoading(true);
    setError(null);
    try {
      const charactersData = await rxdbService.getCharactersByProjectId(pid);
      setCharacters(charactersData);
    } catch (err) {
      setError(err instanceof Error ? err.message : '获取角色列表失败');
    } finally {
      setLoading(false);
    }
  }, []);

  // 创建角色
  const createCharacter = useCallback(async (characterData: Omit<CharacterDocument, 'id' | 'createdAt' | 'updatedAt'>) => {
    setLoading(true);
    setError(null);
    try {
      const newCharacter = await rxdbService.createCharacter(characterData);
      setCharacters(prev => [...prev, newCharacter]);
      return newCharacter;
    } catch (err) {
      setError(err instanceof Error ? err.message : '创建角色失败');
      throw err;
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    if (projectId) {
      fetchCharacters(projectId);
    }
  }, [projectId, fetchCharacters]);

  return {
    characters,
    loading,
    error,
    fetchCharacters,
    createCharacter
  };
};

// 写作会话相关 Hook
export const useWritingSessions = (userId?: string) => {
  const [sessions, setSessions] = useState<WritingSessionDocument[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // 获取用户的写作会话
  const fetchSessions = useCallback(async (uid: string, limit = 50) => {
    setLoading(true);
    setError(null);
    try {
      const sessionsData = await rxdbService.getWritingSessionsByUserId(uid, limit);
      setSessions(sessionsData);
    } catch (err) {
      setError(err instanceof Error ? err.message : '获取写作会话失败');
    } finally {
      setLoading(false);
    }
  }, []);

  // 创建写作会话
  const createSession = useCallback(async (sessionData: Omit<WritingSessionDocument, 'id' | 'createdAt'>) => {
    setLoading(true);
    setError(null);
    try {
      const newSession = await rxdbService.createWritingSession(sessionData);
      setSessions(prev => [newSession, ...prev]);
      return newSession;
    } catch (err) {
      setError(err instanceof Error ? err.message : '创建写作会话失败');
      throw err;
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    if (userId) {
      fetchSessions(userId);
    }
  }, [userId, fetchSessions]);

  return {
    sessions,
    loading,
    error,
    fetchSessions,
    createSession
  };
};

// 写作目标相关 Hook
export const useWritingGoals = (userId?: string) => {
  const [goals, setGoals] = useState<WritingGoalDocument[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // 获取用户的活跃写作目标
  const fetchGoals = useCallback(async (uid: string) => {
    setLoading(true);
    setError(null);
    try {
      const goalsData = await rxdbService.getActiveWritingGoalsByUserId(uid);
      setGoals(goalsData);
    } catch (err) {
      setError(err instanceof Error ? err.message : '获取写作目标失败');
    } finally {
      setLoading(false);
    }
  }, []);

  // 创建写作目标
  const createGoal = useCallback(async (goalData: Omit<WritingGoalDocument, 'id' | 'createdAt' | 'updatedAt'>) => {
    setLoading(true);
    setError(null);
    try {
      const newGoal = await rxdbService.createWritingGoal(goalData);
      setGoals(prev => [newGoal, ...prev]);
      return newGoal;
    } catch (err) {
      setError(err instanceof Error ? err.message : '创建写作目标失败');
      throw err;
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    if (userId) {
      fetchGoals(userId);
    }
  }, [userId, fetchGoals]);

  return {
    goals,
    loading,
    error,
    fetchGoals,
    createGoal
  };
};

// 实时数据 Hook - 使用 RxDB 的响应式特性
export const useReactiveQuery = <T>(observable: Observable<T[]>) => {
  const [data, setData] = useState<T[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let subscription: Subscription;
    
    const db = rxdbService.getDatabase();
    if (db) {
      subscription = observable.subscribe({
        next: (results) => {
          setData(results);
          setLoading(false);
        },
        error: (error) => {
          console.error('响应式查询错误:', error);
          setLoading(false);
        }
      });
    }

    return () => {
      if (subscription) {
        subscription.unsubscribe();
      }
    };
  }, [observable]);

  return { data, loading };
};

// 实时项目数据 Hook
export const useReactiveProjects = (userId: string) => {
  const db = rxdbService.getDatabase();
  
  const observable = db?.projects.find({
    selector: { userId },
    sort: [{ createdAt: 'desc' }]
  }).$;

  return useReactiveQuery<ProjectDocument>(observable || new Observable(() => {}));
};

// 实时章节数据 Hook
export const useReactiveChapters = (projectId: string) => {
  const db = rxdbService.getDatabase();
  
  const observable = db?.chapters.find({
    selector: { projectId },
    sort: [{ orderIndex: 'asc' }]
  }).$;

  return useReactiveQuery<ChapterDocument>(observable || new Observable(() => {}));
};

// 数据统计 Hook
export const useWritingStats = (userId: string) => {
  const [stats, setStats] = useState({
    totalWords: 0,
    totalChapters: 0,
    totalProjects: 0,
    todayWords: 0,
    weekWords: 0,
    monthWords: 0,
    currentStreak: 0
  });
  const [loading, setLoading] = useState(true);

  const calculateStats = useCallback(async () => {
    setLoading(true);
    try {
      const db = rxdbService.getDatabase();
      if (!db) return;

      // 获取用户项目
      const projects = await db.projects.find({
        selector: { userId }
      }).exec();

      // 获取所有章节
      const projectIds = projects.map(p => p.id);
      const chapters = await db.chapters.find({
        selector: { 
          projectId: { $in: projectIds }
        }
      }).exec();

      // 获取写作会话
      const today = new Date();
      const weekAgo = new Date(today.getTime() - 7 * 24 * 60 * 60 * 1000);
      const monthAgo = new Date(today.getTime() - 30 * 24 * 60 * 60 * 1000);
      
      const sessions = await db.writing_sessions.find({
        selector: { userId }
      }).exec();

      // 计算统计数据
      const totalWords = chapters.reduce((sum, chapter) => sum + (chapter.wordCount || 0), 0);
      const totalChapters = chapters.length;
      const totalProjects = projects.length;

      const todayWords = sessions
        .filter(s => new Date(s.createdAt) >= today)
        .reduce((sum, s) => sum + s.wordsWritten, 0);

      const weekWords = sessions
        .filter(s => new Date(s.createdAt) >= weekAgo)
        .reduce((sum, s) => sum + s.wordsWritten, 0);

      const monthWords = sessions
        .filter(s => new Date(s.createdAt) >= monthAgo)
        .reduce((sum, s) => sum + s.wordsWritten, 0);

      // 计算连续写作天数
      const sortedSessions = sessions
        .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
      
      let currentStreak = 0;
      let lastDate = new Date().toDateString();
      
      for (const session of sortedSessions) {
        const sessionDate = new Date(session.createdAt).toDateString();
        if (sessionDate === lastDate) {
          currentStreak++;
          lastDate = new Date(new Date(lastDate).getTime() - 24 * 60 * 60 * 1000).toDateString();
        } else {
          break;
        }
      }

      setStats({
        totalWords,
        totalChapters,
        totalProjects,
        todayWords,
        weekWords,
        monthWords,
        currentStreak
      });
    } catch (error) {
      console.error('计算统计数据失败:', error);
    } finally {
      setLoading(false);
    }
  }, [userId]);

  useEffect(() => {
    calculateStats();
  }, [calculateStats]);

  return { stats, loading, refreshStats: calculateStats };
};

// 搜索 Hook
export const useSearch = () => {
  const [results, setResults] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const search = useCallback(async (query: string, collections: string[] = ['projects', 'chapters', 'characters']) => {
    if (!query.trim()) {
      setResults([]);
      return;
    }

    setLoading(true);
    setError(null);
    try {
      const db = rxdbService.getDatabase();
      if (!db) throw new Error('数据库未初始化');

      const searchResults = [];
      
      // 搜索项目
      if (collections.includes('projects')) {
        const projects = await db.projects.find({
          selector: {
            $or: [
              { title: { $regex: new RegExp(query, 'i') } },
              { description: { $regex: new RegExp(query, 'i') } },
              { tags: { $elemMatch: { $regex: new RegExp(query, 'i') } } }
            ]
          }
        }).exec();
        
        searchResults.push(...projects.map(p => ({ type: 'project', data: p.toJSON() })));
      }

      // 搜索章节
      if (collections.includes('chapters')) {
        const chapters = await db.chapters.find({
          selector: {
            $or: [
              { title: { $regex: new RegExp(query, 'i') } },
              { content: { $regex: new RegExp(query, 'i') } },
              { summary: { $regex: new RegExp(query, 'i') } }
            ]
          }
        }).exec();
        
        searchResults.push(...chapters.map(c => ({ type: 'chapter', data: c.toJSON() })));
      }

      // 搜索角色
      if (collections.includes('characters')) {
        const characters = await db.characters.find({
          selector: {
            $or: [
              { name: { $regex: new RegExp(query, 'i') } },
              { description: { $regex: new RegExp(query, 'i') } }
            ]
          }
        }).exec();
        
        searchResults.push(...characters.map(c => ({ type: 'character', data: c.toJSON() })));
      }

      setResults(searchResults);
    } catch (err) {
      setError(err instanceof Error ? err.message : '搜索失败');
    } finally {
      setLoading(false);
    }
  }, []);

  const clearResults = useCallback(() => {
    setResults([]);
    setError(null);
  }, []);

  return {
    results,
    loading,
    error,
    search,
    clearResults
  };
};
