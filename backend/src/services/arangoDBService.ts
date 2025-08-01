/**
 * ArangoDB服务 - 多模型数据库服务
 * 基于GitHub最佳实践: https://github.com/arangodb/arangodb-javascript-driver
 * 
 * 功能:
 * 1. 文档存储 (替代SQLite)
 * 2. 图数据库 (替代Neo4j) 
 * 3. 键值存储 (缓存和配置)
 * 4. 全文搜索
 * 5. AI约束引擎数据支持
 */

import { Database, aql } from 'arangojs';
import { logger } from '../utils/logger';

// 数据类型定义
export interface UserDocument {
  _key?: string;
  _id?: string;
  _rev?: string;
  email: string;
  username: string;
  passwordHash: string;
  profile: {
    avatar?: string;
    displayName?: string;
    bio?: string;
  };
  settings: {
    theme: 'light' | 'dark';
    language: string;
    autoSave: boolean;
  };
  createdAt: string;
  updatedAt: string;
}

export interface ProjectDocument {
  _key?: string;
  _id?: string;
  _rev?: string;
  title: string;
  description?: string;
  userId: string;
  genre?: string;
  status: 'planning' | 'writing' | 'editing' | 'completed';
  targetWords?: number;
  currentWords: number;
  coverImage?: string;
  tags: string[];
  isPublic: boolean;
  settings: {
    aiEnabled: boolean;
    constraintsEnabled: boolean;
    knowledgeGraphEnabled: boolean;
  };
  createdAt: string;
  updatedAt: string;
}

export interface ChapterDocument {
  _key?: string;
  _id?: string;
  _rev?: string;
  projectId: string;
  title: string;
  content: string;
  wordCount: number;
  chapterNumber: number;
  status: 'draft' | 'reviewing' | 'completed';
  notes?: string;
  outline?: string;
  tags: string[];
  createdAt: string;
  updatedAt: string;
}

export interface CharacterDocument {
  _key?: string;
  _id?: string;
  _rev?: string;
  projectId: string;
  name: string;
  description?: string;
  age?: number;
  gender?: string;
  occupation?: string;
  personality: string[];
  background?: string;
  avatar?: string;
  tags: string[];
  importance: 'main' | 'supporting' | 'minor';
  createdAt: string;
  updatedAt: string;
}

export interface LocationDocument {
  _key?: string;
  _id?: string;
  _rev?: string;
  projectId: string;
  name: string;
  description?: string;
  type: 'city' | 'building' | 'natural' | 'fictional';
  parentLocation?: string;
  coordinates?: { lat: number; lng: number };
  tags: string[];
  createdAt: string;
  updatedAt: string;
}

export interface KnowledgeGraphEdge {
  _key?: string;
  _id?: string;
  _rev?: string;
  _from: string;
  _to: string;
  relationshipType: string;
  strength: number; // 0-100
  description?: string;
  timeline?: string;
  tags: string[];
  createdAt: string;
  updatedAt: string;
}

// ArangoDB集合接口
interface ArangoCollections {
  // 文档集合 (替代SQLite表)
  users: any;
  projects: any;
  chapters: any;
  characters: any;
  locations: any;
  events: any;
  concepts: any;
  themes: any;
  
  // 边集合 (知识图谱关系)
  characterRelations: any;
  plotConnections: any;
  worldRelations: any;
  themeConnections: any;
}

export class ArangoDBService {
  private db: Database;
  private collections: Partial<ArangoCollections> = {};
  private knowledgeGraph: any | null = null;
  private isInitialized = false;

  constructor() {
    const config = {
      url: process.env.ARANGO_URL || 'http://localhost:8529',
      databaseName: '_system', // 先连接到系统数据库
      auth: process.env.ARANGO_NO_AUTH === '1' ? undefined : {
        username: process.env.ARANGO_USER || 'root',
        password: process.env.ARANGO_PASSWORD || 'password'
      }
    };

    logger.info('🔧 ArangoDB配置:', {
      url: config.url,
      databaseName: config.databaseName,
      auth: config.auth ? `${config.auth.username}:***` : 'none'
    });

    this.db = new Database(config);
  }

  // 连接方法（兼容性）
  async connect(): Promise<void> {
    await this.initialize();
  }

  // 初始化数据库方法（兼容性）
  async initializeDatabase(): Promise<void> {
    await this.initialize();
  }

  // 断开连接方法
  async disconnect(): Promise<void> {
    if (this.db) {
      // ArangoDB驱动会自动处理连接池的清理
      this.isInitialized = false;
      logger.info('✅ ArangoDB连接已断开');
    }
  }

  async initialize(): Promise<void> {
    if (this.isInitialized) return;

    try {
      // 测试连接到系统数据库
      await this.testConnection();
      
      // 创建项目数据库
      await this.createDatabaseIfNotExists();
      
      // 重新测试连接到项目数据库
      await this.testConnection();
      
      // 初始化集合
      await this.initializeCollections();
      
      // 创建知识图谱
      await this.initializeKnowledgeGraph();
      
      // 创建索引
      await this.createIndexes();
      
      this.isInitialized = true;
      logger.info('✅ ArangoDB初始化完成');
    } catch (error) {
      logger.error('❌ ArangoDB初始化失败:', error);
      throw error;
    }
  }

  private async testConnection(): Promise<void> {
    try {
      logger.info(`🔗 尝试连接ArangoDB数据库: ${this.db.name}`);
      const version = await this.db.version();
      logger.info(`✅ ArangoDB连接成功, 版本: ${version.version}`);
    } catch (error: any) {
      logger.error('❌ ArangoDB连接失败:', {
        message: error.message,
        code: error.code,
        statusCode: error.statusCode,
        database: this.db.name
      });
      throw new Error(`无法连接到ArangoDB服务器: ${error.message}`);
    }
  }

  private async createDatabaseIfNotExists(): Promise<void> {
    try {
      const targetDatabase = process.env.ARANGO_DB_NAME || 'legezhixiao';
      const databases = await this.db.listDatabases();
      
      if (!databases.includes(targetDatabase)) {
        await this.db.createDatabase(targetDatabase);
        logger.info(`✅ 创建数据库: ${targetDatabase}`);
      } else {
        logger.info(`ℹ️  使用现有数据库: ${targetDatabase}`);
      }
      
      // 切换到项目数据库
      this.db = new Database({
        url: process.env.ARANGO_URL || 'http://localhost:8529',
        databaseName: targetDatabase,
        auth: process.env.ARANGO_NO_AUTH === '1' ? undefined : {
          username: process.env.ARANGO_USER || 'root',
          password: process.env.ARANGO_PASSWORD || 'password',
        },
      });
      
      logger.info(`🔄 已切换到数据库: ${targetDatabase}`);
    } catch (error) {
      logger.error('❌ 数据库创建/切换失败:', error);
      throw error;
    }
  }

  private async initializeCollections(): Promise<void> {
    // 文档集合配置
    const documentCollections = [
      'users', 'projects', 'chapters', 'characters', 
      'locations', 'events', 'concepts', 'themes'
    ];

    // 边集合配置
    const edgeCollections = [
      'characterRelations', 'plotConnections', 
      'worldRelations', 'themeConnections'
    ];

    // 创建文档集合
    for (const collectionName of documentCollections) {
      try {
        const collection = this.db.collection(collectionName);
        if (!await collection.exists()) {
          await collection.create();
          logger.info(`✅ 创建文档集合: ${collectionName}`);
        }
        (this.collections as any)[collectionName] = collection;
      } catch (error) {
        logger.error(`❌ 创建文档集合失败 ${collectionName}:`, error);
      }
    }

    // 创建边集合
    for (const collectionName of edgeCollections) {
      try {
        const collection = this.db.collection(collectionName);
        if (!await collection.exists()) {
          await collection.create();
          logger.info(`✅ 创建边集合: ${collectionName}`);
        }
        (this.collections as any)[collectionName] = collection;
      } catch (error) {
        logger.error(`❌ 创建边集合失败 ${collectionName}:`, error);
      }
    }
  }

  private async initializeKnowledgeGraph(): Promise<void> {
    try {
      this.knowledgeGraph = this.db.graph('legezhixiao_knowledge_graph');
      
      if (!await this.knowledgeGraph.exists()) {
        await this.knowledgeGraph.create([
          {
            collection: 'characterRelations',
            from: ['characters'],
            to: ['characters', 'locations', 'events']
          },
          {
            collection: 'plotConnections',
            from: ['events', 'chapters'],
            to: ['events', 'characters', 'locations', 'themes']
          },
          {
            collection: 'worldRelations',
            from: ['locations'],
            to: ['locations', 'concepts', 'themes']
          },
          {
            collection: 'themeConnections',
            from: ['themes', 'concepts'],
            to: ['characters', 'events', 'locations']
          }
        ]);
        logger.info('✅ 创建知识图谱: legezhixiao_knowledge_graph');
      }
    } catch (error) {
      logger.error('❌ 知识图谱初始化失败:', error);
    }
  }

  private async createIndexes(): Promise<void> {
    try {
      // 用户索引
      await this.collections.users!.ensureIndex({
        type: 'persistent',
        fields: ['email'],
        unique: true,
        name: 'email_unique_idx'
      });

      // 项目索引
      await this.collections.projects!.ensureIndex({
        type: 'persistent',
        fields: ['userId', 'status'],
        name: 'user_status_idx'
      });

      // 章节索引
      await this.collections.chapters!.ensureIndex({
        type: 'persistent',
        fields: ['projectId', 'chapterNumber'],
        name: 'project_chapter_idx'
      });

      // 角色索引
      await this.collections.characters!.ensureIndex({
        type: 'persistent',
        fields: ['projectId', 'importance'],
        name: 'project_importance_idx'
      });

      // 全文搜索索引
      await this.collections.chapters!.ensureIndex({
        type: 'fulltext',
        fields: ['title', 'content'],
        name: 'chapter_fulltext_idx'
      });

      await this.collections.characters!.ensureIndex({
        type: 'fulltext',
        fields: ['name', 'description', 'background'],
        name: 'character_fulltext_idx'
      });

      // 图查询优化索引
      await this.collections.characterRelations!.ensureIndex({
        type: 'persistent',
        fields: ['relationshipType', 'strength'],
        name: 'relation_type_strength_idx'
      });

      logger.info('✅ 创建所有索引完成');
    } catch (error) {
      logger.error('❌ 创建索引失败:', error);
    }
  }

  // ==================== 用户管理 ====================
  async createUser(userData: Omit<UserDocument, '_key' | '_id' | '_rev' | 'createdAt' | 'updatedAt'>): Promise<UserDocument> {
    const now = new Date().toISOString();
    const user: UserDocument = {
      ...userData,
      createdAt: now,
      updatedAt: now
    };

    const result = await this.collections.users!.save(user);
    return { ...user, _key: result._key, _id: result._id, _rev: result._rev };
  }

  async getUserByEmail(email: string): Promise<UserDocument | null> {
    const cursor = await this.db.query(aql`
      FOR user IN users
      FILTER user.email == ${email}
      RETURN user
    `);
    
    const users = await cursor.all();
    return users.length > 0 ? users[0] : null;
  }

  async updateUser(userId: string, updateData: Partial<UserDocument>): Promise<UserDocument> {
    const result = await this.collections.users!.update(userId, {
      ...updateData,
      updatedAt: new Date().toISOString()
    }, { returnNew: true });
    
    return result.new as UserDocument;
  }

  // ==================== 项目管理 ====================
  async createProject(projectData: Omit<ProjectDocument, '_key' | '_id' | '_rev' | 'createdAt' | 'updatedAt'>): Promise<ProjectDocument> {
    const now = new Date().toISOString();
    const project: ProjectDocument = {
      ...projectData,
      currentWords: 0,
      tags: projectData.tags || [],
      settings: {
        aiEnabled: projectData.settings?.aiEnabled ?? true,
        constraintsEnabled: projectData.settings?.constraintsEnabled ?? true,
        knowledgeGraphEnabled: projectData.settings?.knowledgeGraphEnabled ?? true,
      },
      createdAt: now,
      updatedAt: now
    };

    const result = await this.collections.projects!.save(project);
    return { ...project, _key: result._key, _id: result._id, _rev: result._rev };
  }

  async getProjectsByUser(userId: string): Promise<ProjectDocument[]> {
    const cursor = await this.db.query(aql`
      FOR project IN projects
      FILTER project.userId == ${userId}
      SORT project.updatedAt DESC
      RETURN project
    `);
    
    return cursor.all();
  }

  async getProjectWithStats(projectId: string): Promise<any> {
    const cursor = await this.db.query(aql`
      LET project = DOCUMENT('projects', ${projectId})
      
      LET chapters = (
        FOR chapter IN chapters
        FILTER chapter.projectId == ${projectId}
        RETURN chapter
      )
      
      LET characters = (
        FOR character IN characters
        FILTER character.projectId == ${projectId}
        RETURN character
      )
      
      LET locations = (
        FOR location IN locations
        FILTER location.projectId == ${projectId}
        RETURN location
      )
      
      LET totalWords = SUM(chapters[*].wordCount)
      LET completedChapters = LENGTH(chapters[FILTER CURRENT.status == 'completed'])
      LET mainCharacters = LENGTH(characters[FILTER CURRENT.importance == 'main'])
      
      RETURN MERGE(project, {
        stats: {
          totalChapters: LENGTH(chapters),
          completedChapters: completedChapters,
          totalWords: totalWords,
          totalCharacters: LENGTH(characters),
          mainCharacters: mainCharacters,
          totalLocations: LENGTH(locations),
          completionRate: completedChapters / LENGTH(chapters) * 100 || 0,
          averageChapterLength: totalWords / LENGTH(chapters) || 0
        },
        chapters: chapters,
        characters: characters,
        locations: locations
      })
    `);

    const results = await cursor.all();
    return results[0];
  }

  // ==================== 章节管理 ====================
  async createChapter(chapterData: Omit<ChapterDocument, '_key' | '_id' | '_rev' | 'createdAt' | 'updatedAt'>): Promise<ChapterDocument> {
    const now = new Date().toISOString();
    const chapter: ChapterDocument = {
      ...chapterData,
      wordCount: chapterData.content ? chapterData.content.length : 0,
      tags: chapterData.tags || [],
      createdAt: now,
      updatedAt: now
    };

    const result = await this.collections.chapters!.save(chapter);
    
    // 更新项目字数统计
    await this.updateProjectWordCount(chapterData.projectId);
    
    return { ...chapter, _key: result._key, _id: result._id, _rev: result._rev };
  }

  async updateChapter(chapterId: string, updateData: Partial<ChapterDocument>): Promise<ChapterDocument> {
    // 计算新的字数
    if (updateData.content) {
      updateData.wordCount = updateData.content.length;
    }

    const result = await this.collections.chapters!.update(chapterId, {
      ...updateData,
      updatedAt: new Date().toISOString()
    }, { returnNew: true });
    
    // 如果更新了内容，重新计算项目字数
    if (updateData.content && result.new) {
      await this.updateProjectWordCount(result.new.projectId);
    }
    
    return result.new as ChapterDocument;
  }

  private async updateProjectWordCount(projectId: string): Promise<void> {
    const cursor = await this.db.query(aql`
      LET chapters = (
        FOR chapter IN chapters
        FILTER chapter.projectId == ${projectId}
        RETURN chapter.wordCount
      )
      LET totalWords = SUM(chapters)
      
      UPDATE ${projectId} WITH { 
        currentWords: totalWords,
        updatedAt: ${new Date().toISOString()}
      } IN projects
      
      RETURN NEW.currentWords
    `);
    
    await cursor.all();
  }

  // ==================== 角色管理 ====================
  async createCharacter(characterData: Omit<CharacterDocument, '_key' | '_id' | '_rev' | 'createdAt' | 'updatedAt'>): Promise<CharacterDocument> {
    const now = new Date().toISOString();
    const character: CharacterDocument = {
      ...characterData,
      personality: characterData.personality || [],
      tags: characterData.tags || [],
      importance: characterData.importance || 'minor',
      createdAt: now,
      updatedAt: now
    };

    const result = await this.collections.characters!.save(character);
    return { ...character, _key: result._key, _id: result._id, _rev: result._rev };
  }

  // ==================== 知识图谱操作 (替代Neo4j) ====================
  async createCharacterRelation(
    fromCharacterId: string,
    toCharacterId: string, 
    relationshipType: string,
    properties: Partial<KnowledgeGraphEdge> = {}
  ): Promise<KnowledgeGraphEdge> {
    const now = new Date().toISOString();
    const relation: KnowledgeGraphEdge = {
      _from: `characters/${fromCharacterId}`,
      _to: `characters/${toCharacterId}`,
      relationshipType,
      strength: properties.strength || 50,
      description: properties.description,
      timeline: properties.timeline,
      tags: properties.tags || [],
      createdAt: now,
      updatedAt: now
    };

    const result = await this.collections.characterRelations!.save(relation);
    return { ...relation, _key: result._key, _id: result._id, _rev: result._rev };
  }

  async getCharacterNetwork(projectId: string): Promise<any> {
    const cursor = await this.db.query(aql`
      // 获取项目所有角色
      LET characters = (
        FOR char IN characters
        FILTER char.projectId == ${projectId}
        RETURN char
      )
      
      // 获取角色关系网络
      LET relations = (
        FOR char IN characters
          FOR v, e, p IN 1..2 ANY char characterRelations
          FILTER v.projectId == ${projectId}
          RETURN {
            from: char,
            to: v,
            edge: e,
            path: p
          }
      )
      
      // 计算网络指标
      LET centralityScores = (
        FOR char IN characters
          LET connections = (
            FOR rel IN relations
            FILTER rel.from._key == char._key OR rel.to._key == char._key
            RETURN rel
          )
          RETURN {
            character: char,
            centrality: LENGTH(connections),
            importance: LENGTH(connections) > 3 ? 'high' : (LENGTH(connections) > 1 ? 'medium' : 'low')
          }
      )
      
      RETURN {
        characters: characters,
        relations: relations,
        centralityScores: centralityScores,
        networkStats: {
          totalCharacters: LENGTH(characters),
          totalRelations: LENGTH(relations),
          averageConnections: AVG(centralityScores[*].centrality),
          mostConnectedCharacter: FIRST(
            FOR score IN centralityScores
            SORT score.centrality DESC
            LIMIT 1
            RETURN score.character
          )
        }
      }
    `);

    const results = await cursor.all();
    return results[0];
  }

  // ==================== AI约束引擎支持 ====================
  async getConstraintAnalysisData(projectId: string): Promise<any> {
    const cursor = await this.db.query(aql`
      LET project = DOCUMENT('projects', ${projectId})
      
      LET characters = (
        FOR char IN characters
        FILTER char.projectId == ${projectId}
        RETURN char
      )
      
      LET chapters = (
        FOR chapter IN chapters
        FILTER chapter.projectId == ${projectId}
        SORT chapter.chapterNumber ASC
        RETURN chapter
      )
      
      LET plotConnections = (
        FOR v, e IN 1..3 ANY DOCUMENT('events', 'main_plot') plotConnections
        FILTER v.projectId == ${projectId}
        RETURN {
          from: v,
          relationship: e
        }
      )
      
      LET characterConsistency = (
        FOR char IN characters
          LET mentions = (
            FOR chapter IN chapters
            FILTER CONTAINS(LOWER(chapter.content), LOWER(char.name))
            RETURN {
              chapter: chapter.chapterNumber,
              title: chapter.title,
              mentionCount: LENGTH(SPLIT(LOWER(chapter.content), LOWER(char.name))) - 1
            }
          )
          RETURN {
            character: char,
            totalMentions: SUM(mentions[*].mentionCount),
            chapterAppearances: LENGTH(mentions),
            consistency: char.importance == 'main' ? 
              (LENGTH(mentions) / LENGTH(chapters) > 0.5 ? 'good' : 'poor') :
              (LENGTH(mentions) > 0 ? 'good' : 'acceptable')
          }
      )
      
      RETURN {
        project: project,
        worldConsistency: {
          characters: characters,
          locations: (FOR loc IN locations FILTER loc.projectId == ${projectId} RETURN loc),
          timeline: chapters
        },
        characterConsistency: characterConsistency,
        plotConsistency: plotConnections,
        themeConsistency: project.tags || [],
        constraintSuggestions: {
          characterDevelopment: characterConsistency[FILTER CURRENT.consistency == 'poor'],
          plotHoles: [], // TODO: 实现情节漏洞检测
          worldBuildingGaps: [] // TODO: 实现世界观缺口检测
        }
      }
    `);

    const results = await cursor.all();
    return results[0];
  }

  // ==================== 全文搜索 ====================
  async searchContent(projectId: string, query: string): Promise<any> {
    const cursor = await this.db.query(aql`
      // 搜索章节内容
      LET chapterResults = (
        FOR doc IN FULLTEXT(chapters, 'title,content', ${query})
        FILTER doc.projectId == ${projectId}
        RETURN {
          type: 'chapter',
          document: doc,
          score: BM25(doc)
        }
      )
      
      // 搜索角色信息
      LET characterResults = (
        FOR doc IN FULLTEXT(characters, 'name,description,background', ${query})
        FILTER doc.projectId == ${projectId}
        RETURN {
          type: 'character',
          document: doc,
          score: BM25(doc)
        }
      )
      
      LET allResults = UNION(chapterResults, characterResults)
      
      RETURN {
        results: (
          FOR result IN allResults
          SORT result.score DESC
          LIMIT 20
          RETURN result
        ),
        totalResults: LENGTH(allResults),
        query: ${query}
      }
    `);

    const results = await cursor.all();
    return results[0];
  }

  // ==================== 数据导出和备份 ====================
  async exportProjectData(projectId: string): Promise<any> {
    const cursor = await this.db.query(aql`
      LET project = DOCUMENT('projects', ${projectId})
      LET chapters = (FOR c IN chapters FILTER c.projectId == ${projectId} RETURN c)
      LET characters = (FOR c IN characters FILTER c.projectId == ${projectId} RETURN c)
      LET locations = (FOR l IN locations FILTER l.projectId == ${projectId} RETURN l)
      
      RETURN {
        project: project,
        chapters: chapters,
        characters: characters,
        locations: locations,
        exportedAt: ${new Date().toISOString()},
        version: '1.0'
      }
    `);

    const results = await cursor.all();
    return results[0];
  }

  // ==================== 健康检查和统计 ====================
  async getHealthStats(): Promise<any> {
    const cursor = await this.db.query(aql`
      RETURN {
        collections: {
          users: LENGTH(users),
          projects: LENGTH(projects),
          chapters: LENGTH(chapters),
          characters: LENGTH(characters),
          locations: LENGTH(locations)
        },
        relationships: {
          characterRelations: LENGTH(characterRelations),
          plotConnections: LENGTH(plotConnections),
          worldRelations: LENGTH(worldRelations)
        },
        storage: {
          // ArangoDB存储统计
        },
        lastUpdated: ${new Date().toISOString()}
      }
    `);

    const results = await cursor.all();
    return results[0];
  }

  // ==================== 通用数据操作方法 ====================
  async createDocument(collection: string, data: any): Promise<any> {
    const now = new Date().toISOString();
    const document = {
      ...data,
      createdAt: data.createdAt || now,
      updatedAt: now
    };

    const result = await this.db.collection(collection).save(document);
    return { ...document, _key: result._key, _id: result._id, _rev: result._rev };
  }

  async getDocument(collection: string, key: string): Promise<any> {
    try {
      return await this.db.collection(collection).document(key);
    } catch (error: any) {
      if (error.code === 404) {
        return null;
      }
      throw error;
    }
  }

  async updateDocument(collection: string, key: string, data: any): Promise<any> {
    const updateData = {
      ...data,
      updatedAt: new Date().toISOString()
    };

    const result = await this.db.collection(collection).update(key, updateData, { returnNew: true });
    return result.new;
  }

  async deleteDocument(collection: string, key: string): Promise<boolean> {
    try {
      await this.db.collection(collection).remove(key);
      return true;
    } catch (error: any) {
      if (error.code === 404) {
        return false;
      }
      throw error;
    }
  }

  async queryDocuments(collection: string, filter: any = {}): Promise<any[]> {
    const filterQuery = Object.keys(filter).length > 0 
      ? `FILTER ${Object.keys(filter).map(key => `doc.${key} == @${key}`).join(' AND ')}`
      : '';

    const cursor = await this.db.query(`
      FOR doc IN ${collection}
      ${filterQuery}
      RETURN doc
    `, filter);

    return cursor.all();
  }

  async query(aqlQuery: string, bindVars: any = {}): Promise<any[]> {
    const cursor = await this.db.query(aqlQuery, bindVars);
    return cursor.all();
  }
}

// 导出单例实例
export const arangoDBService = new ArangoDBService();
