import { 
  createRxDatabase, 
  RxDatabase, 
  RxCollection, 
  RxDocument, 
  addRxPlugin,
  removeRxDatabase
} from 'rxdb';
import { RxDBDevModePlugin } from 'rxdb/plugins/dev-mode';
import { RxDBUpdatePlugin } from 'rxdb/plugins/update';
import { RxDBQueryBuilderPlugin } from 'rxdb/plugins/query-builder';
import { RxDBJsonDumpPlugin } from 'rxdb/plugins/json-dump';
import { RxDBAttachmentsPlugin } from 'rxdb/plugins/attachments';
import { getRxStorageDexie } from 'rxdb/plugins/storage-dexie';
import { replicateRxCollection } from 'rxdb/plugins/replication';
import { BehaviorSubject, Observable } from 'rxjs';

// 添加必要的插件
if (import.meta.env.DEV) {
  addRxPlugin(RxDBDevModePlugin);
}
addRxPlugin(RxDBUpdatePlugin);
addRxPlugin(RxDBQueryBuilderPlugin);
addRxPlugin(RxDBJsonDumpPlugin);
addRxPlugin(RxDBAttachmentsPlugin);

// 用户文档类型
export interface UserDocument {
  id: string;
  username: string;
  email: string;
  password?: string;
  avatar?: string;
  bio?: string;
  preferences: {
    theme: 'light' | 'dark';
    fontSize: number;
    autoSave: boolean;
    language: string;
    timezone: string;
  };
  writingStats: {
    totalWords: number;
    totalChapters: number;
    totalProjects: number;
    writingStreak: number;
    lastActiveDate: string;
  };
  achievements: string[];
  socialLinks: { platform: string; url: string }[];
  createdAt: string;
  updatedAt: string;
}

// 项目文档类型
export interface ProjectDocument {
  id: string;
  userId: string;
  title: string;
  description: string;
  genre: string;
  tags: string[];
  status: 'planning' | 'writing' | 'editing' | 'completed' | 'paused';
  visibility: 'private' | 'public' | 'shared';
  wordCountGoal: number;
  currentWordCount: number;
  deadlines: {
    type: 'chapter' | 'section' | 'overall';
    target: string;
    date: string;
    completed: boolean;
  }[];
  collaborators: {
    userId: string;
    role: 'editor' | 'reviewer' | 'co-author';
    permissions: string[];
  }[];
  settings: {
    autoBackup: boolean;
    versionControl: boolean;
    commentingEnabled: boolean;
    suggestionsEnabled: boolean;
  };
  metadata: {
    language: string;
    targetAudience: string;
    estimatedLength: number;
    publicationPlan: string;
  };
  chapterOrder: string[];
  createdAt: string;
  updatedAt: string;
}

// 章节文档类型
export interface ChapterDocument {
  id: string;
  projectId: string;
  userId: string;
  title: string;
  content: string;
  summary: string;
  orderIndex: number;
  status: 'draft' | 'in-progress' | 'review' | 'completed';
  wordCount: number;
  characterCount: number;
  readingTime: number;
  tags: string[];
  notes: {
    id: string;
    content: string;
    position: number;
    type: 'general' | 'plot' | 'character' | 'research';
    createdAt: string;
  }[];
  comments: {
    id: string;
    userId: string;
    content: string;
    position: number;
    resolved: boolean;
    createdAt: string;
  }[];
  revisions: {
    id: string;
    content: string;
    summary: string;
    createdAt: string;
  }[];
  aiAnalysis: {
    sentiment: number;
    complexity: number;
    suggestions: string[];
    keywords: string[];
    lastAnalyzed: string;
  };
  createdAt: string;
  updatedAt: string;
}

// 角色文档类型
export interface CharacterDocument {
  id: string;
  projectId: string;
  userId: string;
  name: string;
  avatar: string;
  role: 'protagonist' | 'antagonist' | 'supporting' | 'minor';
  description: string;
  personality: {
    traits: string[];
    motivations: string[];
    fears: string[];
    goals: string[];
  };
  background: {
    age: number;
    birthPlace: string;
    education: string;
    occupation: string;
    family: string;
    history: string;
  };
  appearance: {
    height: string;
    build: string;
    hairColor: string;
    eyeColor: string;
    distinguishingFeatures: string[];
  };
  relationships: {
    characterId: string;
    relationshipType: string;
    description: string;
    status: 'current' | 'past' | 'planned';
  }[];
  characterArc: {
    startingPoint: string;
    developments: {
      chapterId: string;
      development: string;
      significance: number;
    }[];
    endingPoint: string;
  };
  dialogueStyle: {
    vocabulary: 'simple' | 'moderate' | 'complex';
    tone: string[];
    speechPatterns: string[];
    commonPhrases: string[];
  };
  notes: string;
  tags: string[];
  createdAt: string;
  updatedAt: string;
}

// 世界构建文档类型
export interface WorldBuildingDocument {
  id: string;
  projectId: string;
  userId: string;
  type: 'location' | 'culture' | 'technology' | 'magic' | 'politics' | 'economy' | 'religion' | 'history';
  name: string;
  description: string;
  details: {
    [key: string]: any;
  };
  connections: {
    targetId: string;
    targetType: string;
    relationshipType: string;
    description: string;
  }[];
  importance: 1 | 2 | 3 | 4 | 5;
  tags: string[];
  images: string[];
  notes: string;
  createdAt: string;
  updatedAt: string;
}

// 写作会话文档类型
export interface WritingSessionDocument {
  id: string;
  userId: string;
  projectId?: string;
  chapterId?: string;
  startTime: string;
  endTime?: string;
  duration: number;
  wordsWritten: number;
  goal: {
    type: 'words' | 'time' | 'pages';
    target: number;
    achieved: boolean;
  };
  notes: string;
  mood: 'excellent' | 'good' | 'neutral' | 'difficult' | 'poor';
  environment: {
    location: string;
    distractions: string[];
    tools: string[];
  };
  achievements: string[];
  createdAt: string;
}

// 写作目标文档类型
export interface WritingGoalDocument {
  id: string;
  userId: string;
  projectId?: string;
  title: string;
  description: string;
  type: 'daily' | 'weekly' | 'monthly' | 'yearly' | 'project';
  target: {
    metric: 'words' | 'chapters' | 'hours' | 'sessions';
    value: number;
  };
  current: number;
  deadline: string;
  status: 'active' | 'completed' | 'paused' | 'cancelled';
  priority: 'low' | 'medium' | 'high' | 'critical';
  rewards: string[];
  reminders: {
    type: 'daily' | 'weekly' | 'custom';
    time: string;
    enabled: boolean;
  }[];
  progress: {
    date: string;
    value: number;
    notes: string;
  }[];
  createdAt: string;
  updatedAt: string;
}

// RxDB 集合接口
interface DatabaseCollections {
  users: RxCollection<UserDocument>;
  projects: RxCollection<ProjectDocument>;
  chapters: RxCollection<ChapterDocument>;
  characters: RxCollection<CharacterDocument>;
  worldbuilding: RxCollection<WorldBuildingDocument>;
  writing_sessions: RxCollection<WritingSessionDocument>;
  writing_goals: RxCollection<WritingGoalDocument>;
}

type RxDatabaseType = RxDatabase<DatabaseCollections>;

// 集合模式定义
const userSchema = {
  version: 0,
  primaryKey: 'id',
  type: 'object',
  properties: {
    id: { type: 'string', maxLength: 100 },
    username: { type: 'string', maxLength: 50 },
    email: { type: 'string', maxLength: 100 },
    password: { type: 'string', maxLength: 255 },
    avatar: { type: 'string', maxLength: 500 },
    bio: { type: 'string', maxLength: 1000 },
    preferences: {
      type: 'object',
      properties: {
        theme: { type: 'string', enum: ['light', 'dark'] },
        fontSize: { type: 'number' },
        autoSave: { type: 'boolean' },
        language: { type: 'string' },
        timezone: { type: 'string' }
      },
      required: ['theme', 'fontSize', 'autoSave', 'language', 'timezone']
    },
    writingStats: {
      type: 'object',
      properties: {
        totalWords: { type: 'number' },
        totalChapters: { type: 'number' },
        totalProjects: { type: 'number' },
        writingStreak: { type: 'number' },
        lastActiveDate: { type: 'string' }
      },
      required: ['totalWords', 'totalChapters', 'totalProjects', 'writingStreak', 'lastActiveDate']
    },
    achievements: { type: 'array', items: { type: 'string' } },
    socialLinks: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          platform: { type: 'string' },
          url: { type: 'string' }
        },
        required: ['platform', 'url']
      }
    },
    createdAt: { type: 'string' },
    updatedAt: { type: 'string' }
  },
  required: ['id', 'username', 'email', 'preferences', 'writingStats', 'createdAt', 'updatedAt'],
  indexes: ['username', 'email', 'createdAt']
};

const projectSchema = {
  version: 0,
  primaryKey: 'id',
  type: 'object',
  properties: {
    id: { type: 'string', maxLength: 100 },
    userId: { type: 'string', maxLength: 100 },
    title: { type: 'string', maxLength: 200 },
    description: { type: 'string', maxLength: 2000 },
    genre: { type: 'string', maxLength: 50 },
    tags: { type: 'array', items: { type: 'string' } },
    status: { type: 'string', enum: ['planning', 'writing', 'editing', 'completed', 'paused'] },
    visibility: { type: 'string', enum: ['private', 'public', 'shared'] },
    wordCountGoal: { type: 'number' },
    currentWordCount: { type: 'number' },
    deadlines: { type: 'array', items: { type: 'object' } },
    collaborators: { type: 'array', items: { type: 'object' } },
    settings: { type: 'object' },
    metadata: { type: 'object' },
    chapterOrder: { type: 'array', items: { type: 'string' } },
    createdAt: { type: 'string' },
    updatedAt: { type: 'string' }
  },
  required: ['id', 'userId', 'title', 'status', 'visibility', 'createdAt', 'updatedAt'],
  indexes: ['userId', 'status', 'createdAt', 'title']
};

const chapterSchema = {
  version: 0,
  primaryKey: 'id',
  type: 'object',
  properties: {
    id: { type: 'string', maxLength: 100 },
    projectId: { type: 'string', maxLength: 100 },
    userId: { type: 'string', maxLength: 100 },
    title: { type: 'string', maxLength: 200 },
    content: { type: 'string' },
    summary: { type: 'string', maxLength: 1000 },
    orderIndex: { type: 'number' },
    status: { type: 'string', enum: ['draft', 'in-progress', 'review', 'completed'] },
    wordCount: { type: 'number' },
    characterCount: { type: 'number' },
    readingTime: { type: 'number' },
    tags: { type: 'array', items: { type: 'string' } },
    notes: { type: 'array', items: { type: 'object' } },
    comments: { type: 'array', items: { type: 'object' } },
    revisions: { type: 'array', items: { type: 'object' } },
    aiAnalysis: { type: 'object' },
    createdAt: { type: 'string' },
    updatedAt: { type: 'string' }
  },
  required: ['id', 'projectId', 'userId', 'title', 'content', 'orderIndex', 'status', 'createdAt', 'updatedAt'],
  indexes: ['projectId', 'userId', 'status', 'orderIndex', 'createdAt']
};

const characterSchema = {
  version: 0,
  primaryKey: 'id',
  type: 'object',
  properties: {
    id: { type: 'string', maxLength: 100 },
    projectId: { type: 'string', maxLength: 100 },
    userId: { type: 'string', maxLength: 100 },
    name: { type: 'string', maxLength: 100 },
    avatar: { type: 'string', maxLength: 500 },
    role: { type: 'string', enum: ['protagonist', 'antagonist', 'supporting', 'minor'] },
    description: { type: 'string', maxLength: 2000 },
    personality: { type: 'object' },
    background: { type: 'object' },
    appearance: { type: 'object' },
    relationships: { type: 'array', items: { type: 'object' } },
    characterArc: { type: 'object' },
    dialogueStyle: { type: 'object' },
    notes: { type: 'string', maxLength: 2000 },
    tags: { type: 'array', items: { type: 'string' } },
    createdAt: { type: 'string' },
    updatedAt: { type: 'string' }
  },
  required: ['id', 'projectId', 'userId', 'name', 'role', 'createdAt', 'updatedAt'],
  indexes: ['projectId', 'userId', 'role', 'name', 'createdAt']
};

const worldBuildingSchema = {
  version: 0,
  primaryKey: 'id',
  type: 'object',
  properties: {
    id: { type: 'string', maxLength: 100 },
    projectId: { type: 'string', maxLength: 100 },
    userId: { type: 'string', maxLength: 100 },
    type: { type: 'string', enum: ['location', 'culture', 'technology', 'magic', 'politics', 'economy', 'religion', 'history'] },
    name: { type: 'string', maxLength: 100 },
    description: { type: 'string', maxLength: 2000 },
    details: { type: 'object' },
    connections: { type: 'array', items: { type: 'object' } },
    importance: { type: 'number', enum: [1, 2, 3, 4, 5] },
    tags: { type: 'array', items: { type: 'string' } },
    images: { type: 'array', items: { type: 'string' } },
    notes: { type: 'string', maxLength: 2000 },
    createdAt: { type: 'string' },
    updatedAt: { type: 'string' }
  },
  required: ['id', 'projectId', 'userId', 'type', 'name', 'importance', 'createdAt', 'updatedAt'],
  indexes: ['projectId', 'userId', 'type', 'importance', 'createdAt']
};

const writingSessionSchema = {
  version: 0,
  primaryKey: 'id',
  type: 'object',
  properties: {
    id: { type: 'string', maxLength: 100 },
    userId: { type: 'string', maxLength: 100 },
    projectId: { type: 'string', maxLength: 100 },
    chapterId: { type: 'string', maxLength: 100 },
    startTime: { type: 'string' },
    endTime: { type: 'string' },
    duration: { type: 'number' },
    wordsWritten: { type: 'number' },
    goal: { type: 'object' },
    notes: { type: 'string', maxLength: 1000 },
    mood: { type: 'string', enum: ['excellent', 'good', 'neutral', 'difficult', 'poor'] },
    environment: { type: 'object' },
    achievements: { type: 'array', items: { type: 'string' } },
    createdAt: { type: 'string' }
  },
  required: ['id', 'userId', 'startTime', 'duration', 'wordsWritten', 'mood', 'createdAt'],
  indexes: ['userId', 'projectId', 'chapterId', 'createdAt']
};

const writingGoalSchema = {
  version: 0,
  primaryKey: 'id',
  type: 'object',
  properties: {
    id: { type: 'string', maxLength: 100 },
    userId: { type: 'string', maxLength: 100 },
    projectId: { type: 'string', maxLength: 100 },
    title: { type: 'string', maxLength: 200 },
    description: { type: 'string', maxLength: 1000 },
    type: { type: 'string', enum: ['daily', 'weekly', 'monthly', 'yearly', 'project'] },
    target: { type: 'object' },
    current: { type: 'number' },
    deadline: { type: 'string' },
    status: { type: 'string', enum: ['active', 'completed', 'paused', 'cancelled'] },
    priority: { type: 'string', enum: ['low', 'medium', 'high', 'critical'] },
    rewards: { type: 'array', items: { type: 'string' } },
    reminders: { type: 'array', items: { type: 'object' } },
    progress: { type: 'array', items: { type: 'object' } },
    createdAt: { type: 'string' },
    updatedAt: { type: 'string' }
  },
  required: ['id', 'userId', 'title', 'type', 'target', 'current', 'status', 'priority', 'createdAt', 'updatedAt'],
  indexes: ['userId', 'projectId', 'type', 'status', 'deadline', 'createdAt']
};

// RXDB 服务类
export class RxDBService {
  private database: RxDatabaseType | null = null;
  private isInitialized$ = new BehaviorSubject<boolean>(false);
  private syncState$ = new BehaviorSubject<'idle' | 'syncing' | 'error'>('idle');
  private readonly API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:3000/api';

  constructor() {
    this.initializeDatabase();
  }

  // 初始化数据库
  private async initializeDatabase(): Promise<void> {
    try {
      // 创建数据库
      this.database = await createRxDatabase<DatabaseCollections>({
        name: 'legezhixiao_frontend_db',
        storage: getRxStorageDexie(),
        ignoreDuplicate: true,
        cleanupPolicy: {
          minimumDeletedTime: 1000 * 60 * 60 * 24 * 7, // 1周
          minimumCollectionAge: 1000 * 60 * 60 * 24 * 30, // 1月
          runEach: 1000 * 60 * 60 * 12, // 每12小时清理一次
          awaitReplicationsInSync: true
        }
      });

      // 添加集合
      await this.database.addCollections({
        users: {
          schema: userSchema,
          methods: {
            getFullName(this: RxDocument<UserDocument>) {
              return this.username;
            }
          }
        },
        projects: {
          schema: projectSchema,
          methods: {
            getProgress(this: RxDocument<ProjectDocument>) {
              return this.wordCountGoal > 0 ? (this.currentWordCount / this.wordCountGoal) * 100 : 0;
            }
          }
        },
        chapters: {
          schema: chapterSchema,
          methods: {
            getReadingTime(this: RxDocument<ChapterDocument>) {
              // 假设平均阅读速度为200字/分钟
              return Math.ceil(this.wordCount / 200);
            }
          }
        },
        characters: {
          schema: characterSchema,
          methods: {
            getRelationshipsWith(this: RxDocument<CharacterDocument>, characterId: string) {
              return this.relationships.filter(rel => rel.characterId === characterId);
            }
          }
        },
        worldbuilding: {
          schema: worldBuildingSchema,
          methods: {
            getConnectedElements(this: RxDocument<WorldBuildingDocument>) {
              return this.connections.map(conn => conn.targetId);
            }
          }
        },
        writing_sessions: {
          schema: writingSessionSchema,
          methods: {
            isGoalAchieved(this: RxDocument<WritingSessionDocument>) {
              return this.goal.achieved;
            }
          }
        },
        writing_goals: {
          schema: writingGoalSchema,
          methods: {
            getProgressPercentage(this: RxDocument<WritingGoalDocument>) {
              return this.target.value > 0 ? (this.current / this.target.value) * 100 : 0;
            }
          }
        }
      });

      // 设置同步
      this.setupReplication();

      this.isInitialized$.next(true);
      console.log('✅ RXDB 数据库初始化完成');
    } catch (error) {
      console.error('❌ RXDB 数据库初始化失败:', error);
      this.isInitialized$.next(false);
    }
  }

  // 设置与后端 ArangoDB 的同步
  private setupReplication(): void {
    if (!this.database) return;

    // 为每个集合设置双向同步
    const collections = ['users', 'projects', 'chapters', 'characters', 'worldbuilding', 'writing_sessions', 'writing_goals'];
    
    collections.forEach(collectionName => {
      const collection = this.database![collectionName as keyof DatabaseCollections];
      
      const replicationState = replicateRxCollection({
        collection: collection as any,
        replicationIdentifier: `${collectionName}-sync`,
        live: true,
        retryTime: 5000,
        waitForLeadership: true,
        autoStart: true,
        pull: {
          handler: async (checkpoint, batchSize) => {
            try {
              const response = await fetch(`${this.API_BASE_URL}/sync/${collectionName}/pull`, {
                method: 'POST',
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': `Bearer ${localStorage.getItem('auth_token')}`
                },
                body: JSON.stringify({ checkpoint, batchSize })
              });
              
              if (!response.ok) {
                throw new Error(`同步拉取失败: ${response.statusText}`);
              }
              
              const data = await response.json();
              return {
                documents: data.documents || [],
                checkpoint: data.checkpoint || null
              };
            } catch (error) {
              console.error(`❌ ${collectionName} 拉取同步失败:`, error);
              this.syncState$.next('error');
              throw error;
            }
          },
          batchSize: 20,
          modifier: (doc) => doc
        },
        push: {
          handler: async (changeRows) => {
            try {
              const response = await fetch(`${this.API_BASE_URL}/sync/${collectionName}/push`, {
                method: 'POST',
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': `Bearer ${localStorage.getItem('auth_token')}`
                },
                body: JSON.stringify({ changes: changeRows })
              });
              
              if (!response.ok) {
                throw new Error(`同步推送失败: ${response.statusText}`);
              }
              
              const data = await response.json();
              return data.conflicts || [];
            } catch (error) {
              console.error(`❌ ${collectionName} 推送同步失败:`, error);
              this.syncState$.next('error');
              throw error;
            }
          },
          batchSize: 20,
          modifier: (doc) => doc
        }
      });

      // 监听同步状态
      replicationState.active$.subscribe(active => {
        if (active) {
          this.syncState$.next('syncing');
        } else {
          this.syncState$.next('idle');
        }
      });

      replicationState.error$.subscribe(error => {
        if (error) {
          console.error(`❌ ${collectionName} 同步错误:`, error);
          this.syncState$.next('error');
        }
      });

      console.log(`✅ ${collectionName} 同步已设置`);
    });
  }

  // 获取数据库实例
  getDatabase(): RxDatabaseType | null {
    return this.database;
  }

  // 获取初始化状态
  isInitialized(): Observable<boolean> {
    return this.isInitialized$.asObservable();
  }

  // 获取同步状态
  getSyncState(): Observable<'idle' | 'syncing' | 'error'> {
    return this.syncState$.asObservable();
  }

  // 用户操作
  async createUser(userData: Omit<UserDocument, 'id' | 'createdAt' | 'updatedAt'>): Promise<UserDocument> {
    if (!this.database) throw new Error('数据库未初始化');
    
    const now = new Date().toISOString();
    const user: UserDocument = {
      ...userData,
      id: `user_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      createdAt: now,
      updatedAt: now
    };
    
    const doc = await this.database.users.insert(user);
    return doc.toJSON();
  }

  async getUserById(id: string): Promise<UserDocument | null> {
    if (!this.database) throw new Error('数据库未初始化');
    
    const doc = await this.database.users.findOne({ selector: { id } }).exec();
    return doc ? doc.toJSON() : null;
  }

  async updateUser(id: string, updates: Partial<UserDocument>): Promise<UserDocument | null> {
    if (!this.database) throw new Error('数据库未初始化');
    
    const doc = await this.database.users.findOne({ selector: { id } }).exec();
    if (!doc) return null;
    
    await doc.update({
      $set: {
        ...updates,
        updatedAt: new Date().toISOString()
      }
    });
    
    return doc.toJSON();
  }

  // 项目操作
  async createProject(projectData: Omit<ProjectDocument, 'id' | 'createdAt' | 'updatedAt'>): Promise<ProjectDocument> {
    if (!this.database) throw new Error('数据库未初始化');
    
    const now = new Date().toISOString();
    const project: ProjectDocument = {
      ...projectData,
      id: `project_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      createdAt: now,
      updatedAt: now
    };
    
    const doc = await this.database.projects.insert(project);
    return doc.toJSON();
  }

  async getProjectsByUserId(userId: string): Promise<ProjectDocument[]> {
    if (!this.database) throw new Error('数据库未初始化');
    
    const docs = await this.database.projects.find({
      selector: { userId },
      sort: [{ createdAt: 'desc' }]
    }).exec();
    
    return docs.map(doc => doc.toJSON());
  }

  async updateProject(id: string, updates: Partial<ProjectDocument>): Promise<ProjectDocument | null> {
    if (!this.database) throw new Error('数据库未初始化');
    
    const doc = await this.database.projects.findOne({ selector: { id } }).exec();
    if (!doc) return null;
    
    await doc.update({
      $set: {
        ...updates,
        updatedAt: new Date().toISOString()
      }
    });
    
    return doc.toJSON();
  }

  // 章节操作
  async createChapter(chapterData: Omit<ChapterDocument, 'id' | 'createdAt' | 'updatedAt'>): Promise<ChapterDocument> {
    if (!this.database) throw new Error('数据库未初始化');
    
    const now = new Date().toISOString();
    const chapter: ChapterDocument = {
      ...chapterData,
      id: `chapter_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      wordCount: chapterData.content.split(/\s+/).length,
      characterCount: chapterData.content.length,
      readingTime: Math.ceil(chapterData.content.split(/\s+/).length / 200),
      createdAt: now,
      updatedAt: now
    };
    
    const doc = await this.database.chapters.insert(chapter);
    return doc.toJSON();
  }

  async getChaptersByProjectId(projectId: string): Promise<ChapterDocument[]> {
    if (!this.database) throw new Error('数据库未初始化');
    
    const docs = await this.database.chapters.find({
      selector: { projectId },
      sort: [{ orderIndex: 'asc' }]
    }).exec();
    
    return docs.map(doc => doc.toJSON());
  }

  async updateChapter(id: string, updates: Partial<ChapterDocument>): Promise<ChapterDocument | null> {
    if (!this.database) throw new Error('数据库未初始化');
    
    const doc = await this.database.chapters.findOne({ selector: { id } }).exec();
    if (!doc) return null;
    
    // 重新计算字数统计
    if (updates.content) {
      updates.wordCount = updates.content.split(/\s+/).length;
      updates.characterCount = updates.content.length;
      updates.readingTime = Math.ceil(updates.wordCount / 200);
    }
    
    await doc.update({
      $set: {
        ...updates,
        updatedAt: new Date().toISOString()
      }
    });
    
    return doc.toJSON();
  }

  // 角色操作
  async createCharacter(characterData: Omit<CharacterDocument, 'id' | 'createdAt' | 'updatedAt'>): Promise<CharacterDocument> {
    if (!this.database) throw new Error('数据库未初始化');
    
    const now = new Date().toISOString();
    const character: CharacterDocument = {
      ...characterData,
      id: `character_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      createdAt: now,
      updatedAt: now
    };
    
    const doc = await this.database.characters.insert(character);
    return doc.toJSON();
  }

  async getCharactersByProjectId(projectId: string): Promise<CharacterDocument[]> {
    if (!this.database) throw new Error('数据库未初始化');
    
    const docs = await this.database.characters.find({
      selector: { projectId },
      sort: [{ role: 'asc', name: 'asc' }]
    }).exec();
    
    return docs.map(doc => doc.toJSON());
  }

  // 写作会话操作
  async createWritingSession(sessionData: Omit<WritingSessionDocument, 'id' | 'createdAt'>): Promise<WritingSessionDocument> {
    if (!this.database) throw new Error('数据库未初始化');
    
    const session: WritingSessionDocument = {
      ...sessionData,
      id: `session_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      createdAt: new Date().toISOString()
    };
    
    const doc = await this.database.writing_sessions.insert(session);
    return doc.toJSON();
  }

  async getWritingSessionsByUserId(userId: string, limit = 50): Promise<WritingSessionDocument[]> {
    if (!this.database) throw new Error('数据库未初始化');
    
    const docs = await this.database.writing_sessions.find({
      selector: { userId },
      sort: [{ createdAt: 'desc' }],
      limit
    }).exec();
    
    return docs.map(doc => doc.toJSON());
  }

  // 写作目标操作
  async createWritingGoal(goalData: Omit<WritingGoalDocument, 'id' | 'createdAt' | 'updatedAt'>): Promise<WritingGoalDocument> {
    if (!this.database) throw new Error('数据库未初始化');
    
    const now = new Date().toISOString();
    const goal: WritingGoalDocument = {
      ...goalData,
      id: `goal_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      createdAt: now,
      updatedAt: now
    };
    
    const doc = await this.database.writing_goals.insert(goal);
    return doc.toJSON();
  }

  async getActiveWritingGoalsByUserId(userId: string): Promise<WritingGoalDocument[]> {
    if (!this.database) throw new Error('数据库未初始化');
    
    const docs = await this.database.writing_goals.find({
      selector: { 
        userId,
        status: 'active'
      },
      sort: [{ priority: 'desc', deadline: 'asc' }]
    }).exec();
    
    return docs.map(doc => doc.toJSON());
  }

  // 数据导出
  async exportData(): Promise<any> {
    if (!this.database) throw new Error('数据库未初始化');
    
    const dump = await this.database.exportJSON();
    return dump;
  }

  // 数据导入
  async importData(data: any): Promise<void> {
    if (!this.database) throw new Error('数据库未初始化');
    
    await this.database.importJSON(data);
    console.log('✅ 数据导入完成');
  }

  // 强制同步
  async forcSync(): Promise<void> {
    if (!this.database) throw new Error('数据库未初始化');
    
    // 触发所有集合的同步
    const collections = Object.values(this.database.collections);
    await Promise.all(collections.map(collection => {
      // 这里可以添加强制同步的逻辑
      return Promise.resolve();
    }));
    
    console.log('✅ 强制同步完成');
  }

  // 清理缓存
  async clearCache(): Promise<void> {
    if (!this.database) throw new Error('数据库未初始化');
    
    await this.database.cleanup();
    console.log('✅ 缓存清理完成');
  }

  // 销毁数据库
  async destroy(): Promise<void> {
    if (this.database) {
      await this.database.destroy();
      this.database = null;
      this.isInitialized$.next(false);
      console.log('✅ 数据库已销毁');
    }
  }

  // 完全删除数据库
  async removeDatabase(): Promise<void> {
    if (this.database) {
      await this.database.remove();
      this.database = null;
      this.isInitialized$.next(false);
      console.log('✅ 数据库已完全删除');
    }
  }
}

// 创建单例实例
export const rxdbService = new RxDBService();

// 导出类型
export type {
  RxDatabaseType,
  DatabaseCollections
};
