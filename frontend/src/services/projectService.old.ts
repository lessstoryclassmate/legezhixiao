/**
 * 项目服务
 * 管理小说项目的CRUD操作和业务逻辑
 * 使用RXDB作为本地存储，与ArangoDB后端同步
 */

import { rxdbService } from './rxdbService';
import { projectAnalyzerService } from './projectAnalyzer';

export interface NovelProject {
  id: string;
  title: string;
  author: string;
  genre: string;
  description: string;
  status: 'planning' | 'writing' | 'editing' | 'completed' | 'published';
  targetWords: number;
  currentWords: number;
  createdAt: string;
  updatedAt: string;
  lastOpenedAt?: string;
  
  // 内容数据
  chapters: Chapter[];
  characters: Character[];
  worldBuilding: WorldBuilding;
  outline: ProjectOutline;
  themes: string[];
  tags: string[];
  
  // 设置
  settings: ProjectSettings;
  
  // 统计数据
  stats?: ProjectStats;
}

export interface Chapter {
  id: string;
  projectId: string;
  number: number;
  title: string;
  content: string;
  wordCount: number;
  status: 'draft' | 'review' | 'completed';
  createdAt: string;
  updatedAt: string;
  notes?: string;
  aiSuggestions?: AISuggestion[];
}

export interface Character {
  id: string;
  projectId: string;
  name: string;
  role: 'main' | 'supporting' | 'minor';
  importance: 'high' | 'medium' | 'low';
  description: string;
  personality: string[];
  background: string;
  goals: string[];
  relationships: { [characterId: string]: string };
  developmentArc: DevelopmentPoint[];
  appearance?: string;
  voice?: string;
  createdAt: string;
  updatedAt: string;
}

export interface DevelopmentPoint {
  chapterId: string;
  description: string;
  type: 'growth' | 'conflict' | 'revelation' | 'change';
}

export interface WorldBuilding {
  setting: string;
  timeframe: string;
  locations: Location[];
  cultures: Culture[];
  timeline: TimelineEvent[];
  rules: WorldRule[];
}

export interface Location {
  id: string;
  name: string;
  description: string;
  type: 'city' | 'building' | 'natural' | 'other';
  significance: string;
}

export interface Culture {
  id: string;
  name: string;
  description: string;
  customs: string[];
  language?: string;
}

export interface TimelineEvent {
  id: string;
  date: string;
  title: string;
  description: string;
  importance: 'high' | 'medium' | 'low';
}

export interface WorldRule {
  id: string;
  category: string;
  description: string;
  examples: string[];
}

export interface ProjectOutline {
  summary: string;
  acts: Act[];
  keyEvents: KeyEvent[];
  themes: Theme[];
}

export interface Act {
  number: number;
  title: string;
  description: string;
  chapters: number[];
  goals: string[];
}

export interface KeyEvent {
  id: string;
  title: string;
  description: string;
  chapterNumber?: number;
  importance: 'high' | 'medium' | 'low';
  type: 'plot' | 'character' | 'world';
}

export interface Theme {
  name: string;
  description: string;
  examples: string[];
}

export interface ProjectSettings {
  autoSave: boolean;
  autoBackup: boolean;
  spellCheck: boolean;
  grammarCheck: boolean;
  aiAssistance: boolean;
  constraintChecking: boolean;
  wordCountTarget: number;
  dailyGoal: number;
  notificationEnabled: boolean;
}

export interface ProjectStats {
  totalWords: number;
  totalChapters: number;
  totalCharacters: number;
  averageChapterLength: number;
  writingProgress: number;
  lastUpdateDate: string;
}

export interface AISuggestion {
  id: string;
  type: 'continuation' | 'improvement' | 'correction' | 'alternative';
  content: string;
  confidence: number;
  context: string;
  createdAt: string;
}

export interface ProjectTemplate {
  id: string;
  name: string;
  description: string;
  genre: string;
  structure: Partial<NovelProject>;
}

export class ProjectService {
  private static instance: ProjectService;
  private currentProject: NovelProject | null = null;

  constructor() {
    // 确保RXDB已初始化
    this.initializeRXDB().catch(console.error);
  }

  static getInstance(): ProjectService {
    if (!ProjectService.instance) {
      ProjectService.instance = new ProjectService();
    }
    return ProjectService.instance;
  }

  /**
   * 初始化RXDB
   */
  private async initializeRXDB() {
    try {
      await rxdbService.initialize();
    } catch (error) {
      console.error('RXDB初始化失败:', error);
    }
  }

  /**
   * 创建新项目
   */
  async createProject(projectData: Partial<NovelProject>): Promise<NovelProject> {
    const defaultSettings: ProjectSettings = {
      autoSave: true,
      autoBackup: true,
      spellCheck: true,
      grammarCheck: true,
      aiAssistance: true,
      constraintChecking: true,
      wordCountTarget: projectData.targetWords || 100000,
      dailyGoal: 1000,
      notificationEnabled: true
    };

    const project: NovelProject = {
      id: `project_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      title: projectData.title || '未命名小说',
      author: projectData.author || '未知作者',
      genre: projectData.genre || '其他',
      description: projectData.description || '',
      status: 'planning',
      targetWords: projectData.targetWords || 100000,
      currentWords: 0,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      
      chapters: [],
      characters: [],
      worldBuilding: {
        setting: '',
        timeframe: '',
        locations: [],
        cultures: [],
        timeline: [],
        rules: []
      },
      outline: {
        summary: '',
        acts: [],
        keyEvents: [],
        themes: []
      },
      themes: projectData.themes || [],
      tags: projectData.tags || [],
      settings: defaultSettings,
      
      ...projectData
    };

    // 保存到RXDB
    const collection = await rxdbService.getCollection('projects');
    if (collection) {
      await collection.insert(project);
    }
    
    return project;
  }

  /**
   * 从模板创建项目
   */
  async createProjectFromTemplate(templateId: string, projectData: Partial<NovelProject>): Promise<NovelProject> {
    const template = await this.getProjectTemplate(templateId);
    if (!template) {
      throw new Error(`Template ${templateId} not found`);
    }

    const mergedData = {
      ...template.structure,
      ...projectData,
      genre: template.genre
    };

    return this.createProject(mergedData);
  }

  /**
   * 获取所有项目
   */
  async getAllProjects(): Promise<NovelProject[]> {
    const collection = await rxdbService.getCollection('projects');
    if (!collection) return [];
    
    const docs = await collection.find().exec();
    return docs.map(doc => doc.toJSON() as NovelProject)
      .sort((a, b) => new Date(b.updatedAt).getTime() - new Date(a.updatedAt).getTime());
  }

  /**
   * 获取单个项目
   */
  async getProject(projectId: string): Promise<NovelProject | null> {
    const collection = await rxdbService.getCollection('projects');
    if (!collection) return null;
    
    const doc = await collection.findOne(projectId).exec();
    if (!doc) return null;
    
    return doc.toJSON() as NovelProject;
  }

  /**
   * 更新项目
   */
  async updateProject(projectId: string, updates: Partial<NovelProject>): Promise<NovelProject | null> {
    const collection = await rxdbService.getCollection('projects');
    if (!collection) return null;
    
    const doc = await collection.findOne(projectId).exec();
    if (!doc) return null;
    
    const updatedData = {
      ...updates,
      updatedAt: new Date().toISOString()
    };

    await doc.patch(updatedData);
    const project = doc.toJSON() as NovelProject;
    
    // 如果是当前项目，更新缓存
    if (this.currentProject && this.currentProject.id === projectId) {
      this.currentProject = project;
    }

    return project;
  }

  /**
   * 删除项目
   */
  async deleteProject(projectId: string): Promise<boolean> {
    try {
      const collection = await rxdbService.getCollection('projects');
      if (!collection) return false;
      
      const doc = await collection.findOne(projectId).exec();
      if (!doc) return false;
      
      await doc.remove();
      
      // 如果删除的是当前项目，清除缓存
      if (this.currentProject && this.currentProject.id === projectId) {
        this.currentProject = null;
      }

      return true;
    } catch (error) {
      console.error('删除项目失败:', error);
      return false;
    }

    return success;
  }

  /**
   * 打开项目
   */
  async openProject(projectId: string): Promise<NovelProject | null> {
    const project = await this.getProject(projectId);
    if (!project) return null;

    // 更新最后打开时间
    await this.updateProject(projectId, {
      lastOpenedAt: new Date().toISOString()
    });

    this.currentProject = project;
    return project;
  }

  /**
   * 获取当前项目
   */
  getCurrentProject(): NovelProject | null {
    return this.currentProject;
  }

  /**
   * 关闭当前项目
   */
  closeCurrentProject(): void {
    this.currentProject = null;
  }

  /**
   * 添加章节
   */
  async addChapter(projectId: string, chapterData: Partial<Chapter>): Promise<Chapter | null> {
    const project = await this.getProject(projectId);
    if (!project) return null;

    const chapter: Chapter = {
      id: `chapter_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      projectId,
      number: project.chapters.length + 1,
      title: chapterData.title || `第${project.chapters.length + 1}章`,
      content: chapterData.content || '',
      wordCount: 0,
      status: 'draft',
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      ...chapterData
    };

    // 计算字数
    chapter.wordCount = this.calculateWordCount(chapter.content);

    // 更新项目
    const updatedChapters = [...project.chapters, chapter];
    const totalWords = updatedChapters.reduce((sum, ch) => sum + ch.wordCount, 0);

    await this.updateProject(projectId, {
      chapters: updatedChapters,
      currentWords: totalWords
    });

    return chapter;
  }

  /**
   * 更新章节
   */
  async updateChapter(projectId: string, chapterId: string, updates: Partial<Chapter>): Promise<Chapter | null> {
    const project = await this.getProject(projectId);
    if (!project) return null;

    const chapterIndex = project.chapters.findIndex(ch => ch.id === chapterId);
    if (chapterIndex === -1) return null;

    const updatedChapter: Chapter = {
      ...project.chapters[chapterIndex],
      ...updates,
      updatedAt: new Date().toISOString()
    };

    // 重新计算字数
    if (updates.content !== undefined) {
      updatedChapter.wordCount = this.calculateWordCount(updatedChapter.content);
    }

    // 更新项目中的章节
    const updatedChapters = [...project.chapters];
    updatedChapters[chapterIndex] = updatedChapter;

    // 重新计算总字数
    const totalWords = updatedChapters.reduce((sum, ch) => sum + ch.wordCount, 0);

    await this.updateProject(projectId, {
      chapters: updatedChapters,
      currentWords: totalWords
    });

    return updatedChapter;
  }

  /**
   * 删除章节
   */
  async deleteChapter(projectId: string, chapterId: string): Promise<boolean> {
    const project = await this.getProject(projectId);
    if (!project) return false;

    const updatedChapters = project.chapters.filter(ch => ch.id !== chapterId);
    
    // 重新编号
    updatedChapters.forEach((chapter, index) => {
      chapter.number = index + 1;
    });

    // 重新计算总字数
    const totalWords = updatedChapters.reduce((sum, ch) => sum + ch.wordCount, 0);

    await this.updateProject(projectId, {
      chapters: updatedChapters,
      currentWords: totalWords
    });

    return true;
  }

  /**
   * 添加角色
   */
  async addCharacter(projectId: string, characterData: Partial<Character>): Promise<Character | null> {
    const project = await this.getProject(projectId);
    if (!project) return null;

    const character: Character = {
      id: `character_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      projectId,
      name: characterData.name || '未命名角色',
      role: characterData.role || 'supporting',
      importance: characterData.importance || 'medium',
      description: characterData.description || '',
      personality: characterData.personality || [],
      background: characterData.background || '',
      goals: characterData.goals || [],
      relationships: characterData.relationships || {},
      developmentArc: characterData.developmentArc || [],
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      ...characterData
    };

    const updatedCharacters = [...project.characters, character];
    await this.updateProject(projectId, { characters: updatedCharacters });

    return character;
  }

  /**
   * 更新角色
   */
  async updateCharacter(projectId: string, characterId: string, updates: Partial<Character>): Promise<Character | null> {
    const project = await this.getProject(projectId);
    if (!project) return null;

    const characterIndex = project.characters.findIndex(ch => ch.id === characterId);
    if (characterIndex === -1) return null;

    const updatedCharacter: Character = {
      ...project.characters[characterIndex],
      ...updates,
      updatedAt: new Date().toISOString()
    };

    const updatedCharacters = [...project.characters];
    updatedCharacters[characterIndex] = updatedCharacter;

    await this.updateProject(projectId, { characters: updatedCharacters });

    return updatedCharacter;
  }

  /**
   * 删除角色
   */
  async deleteCharacter(projectId: string, characterId: string): Promise<boolean> {
    const project = await this.getProject(projectId);
    if (!project) return false;

    const updatedCharacters = project.characters.filter(ch => ch.id !== characterId);
    await this.updateProject(projectId, { characters: updatedCharacters });

    return true;
  }

  /**
   * 获取项目统计
   */
  async getProjectStats(projectId: string): Promise<ProjectStats | null> {
    const project = await this.getProject(projectId);
    if (!project) return null;

    return projectAnalyzerService.analyzeProjectStats(project);
  }

  /**
   * 导出项目
   */
  async exportProject(projectId: string, format: 'json' | 'txt' | 'docx' = 'json'): Promise<string | Blob> {
    const project = await this.getProject(projectId);
    if (!project) throw new Error('Project not found');

    switch (format) {
      case 'json':
        return JSON.stringify(project, null, 2);
      
      case 'txt':
        return this.exportAsText(project);
      
      case 'docx':
        // TODO: 实现DOCX导出
        throw new Error('DOCX export not implemented yet');
      
      default:
        throw new Error(`Unsupported format: ${format}`);
    }
  }

  /**
   * 导入项目
   */
  async importProject(data: string | File): Promise<NovelProject> {
    let projectData: any;

    if (typeof data === 'string') {
      try {
        projectData = JSON.parse(data);
      } catch (error) {
        throw new Error('Invalid JSON format');
      }
    } else {
      // 处理文件导入
      const text = await data.text();
      try {
        projectData = JSON.parse(text);
      } catch (error) {
        throw new Error('Invalid file format');
      }
    }

    // 验证项目数据结构
    if (!projectData.title || !projectData.author) {
      throw new Error('Invalid project data');
    }

    // 生成新的ID
    const newProject = {
      ...projectData,
      id: `project_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    // 重新生成章节和角色ID
    newProject.chapters = newProject.chapters?.map((chapter: any) => ({
      ...chapter,
      id: `chapter_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      projectId: newProject.id
    })) || [];

    newProject.characters = newProject.characters?.map((character: any) => ({
      ...character,
      id: `character_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      projectId: newProject.id
    })) || [];

    return this.createProject(newProject);
  }

  /**
   * 搜索项目
   */
  async searchProjects(query: string): Promise<NovelProject[]> {
    const allProjects = await this.getAllProjects();
    const searchTerm = query.toLowerCase();

    return allProjects.filter(project =>
      project.title.toLowerCase().includes(searchTerm) ||
      project.author.toLowerCase().includes(searchTerm) ||
      project.description.toLowerCase().includes(searchTerm) ||
      project.genre.toLowerCase().includes(searchTerm) ||
      project.tags.some(tag => tag.toLowerCase().includes(searchTerm))
    );
  }

  /**
   * 获取项目模板
   */
  async getProjectTemplate(templateId: string): Promise<ProjectTemplate | null> {
    // TODO: 实现模板管理
    return null;
  }

  /**
   * 获取所有项目模板
   */
  async getAllProjectTemplates(): Promise<ProjectTemplate[]> {
    // TODO: 实现模板管理
    return [];
  }

  // 私有辅助方法

  private calculateWordCount(text: string): number {
    if (!text) return 0;
    // 简单的中文字数统计
    return text.replace(/\s/g, '').length;
  }

  private exportAsText(project: NovelProject): string {
    let output = `${project.title}\n`;
    output += `作者：${project.author}\n`;
    output += `类型：${project.genre}\n`;
    output += `简介：${project.description}\n\n`;

    project.chapters
      .sort((a, b) => a.number - b.number)
      .forEach(chapter => {
        output += `${chapter.title}\n`;
        output += `${chapter.content}\n\n`;
      });

    return output;
  }
}

// 创建单例实例
export const projectService = ProjectService.getInstance();
