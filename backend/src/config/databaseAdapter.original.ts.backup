/**
 * 数据库适配器
 * 提供Sequelize兼容接口，底层使用ArangoDB
 * 这是渐进式迁移的过渡方案
 */

import { Sequelize } from 'sequelize';
import { logger } from '../utils/logger';
import { ArangoDBService } from '../services/arangoDBService';
import { ModelFactory } from '../models/modelProxy';

class DatabaseAdapter {
  private static instance: DatabaseAdapter;
  private sequelize: Sequelize | null = null;
  private arangoDBService: ArangoDBService | null = null;
  private isConnected: boolean = false;

  private constructor() {}

  public static getInstance(): DatabaseAdapter {
    if (!DatabaseAdapter.instance) {
      DatabaseAdapter.instance = new DatabaseAdapter();
    }
    return DatabaseAdapter.instance;
  }

  /**
   * 初始化数据库连接
   * 优先使用ArangoDB，同时保持Sequelize兼容性
   */
  public async initialize(): Promise<void> {
    try {
      // 初始化ArangoDB连接
      this.arangoDBService = new ArangoDBService();
      await this.arangoDBService.connect();
      await this.arangoDBService.initializeDatabase();
      
      this.isConnected = true;
      logger.info('✅ ArangoDB数据库连接成功');

      // 创建一个内存中的SQLite用于Sequelize兼容性
      // 这样现有的模型代码可以继续工作，但实际数据存储在ArangoDB中
      this.sequelize = new Sequelize('sqlite::memory:', {
        dialect: 'sqlite',
        logging: false, // 禁用日志，因为这只是兼容性层
        define: {
          timestamps: true,
          underscored: false,
        }
      });

      await this.sequelize.authenticate();
      logger.info('✅ Sequelize兼容层初始化成功');

    } catch (error) {
      logger.error('❌ 数据库初始化失败:', error);
      throw error;
    }
  }

  /**
   * 获取ArangoDB服务实例
   */
  public getArangoDBService(): ArangoDBService | null {
    return this.arangoDBService;
  }

  /**
   * 获取Sequelize实例（兼容性）
   */
  public getSequelize(): Sequelize | null {
    return this.sequelize;
  }

  /**
   * 获取模型代理 - 新的推荐方式
   */
  public getModel(name: string) {
    return ModelFactory.getModel(name);
  }

  /**
   * 获取所有模型 - 向后兼容
   */
  public get models() {
    return {
      User: ModelFactory.getModel('User'),
      Project: ModelFactory.getModel('Project'),
      Chapter: ModelFactory.getModel('Chapter'),
      Character: ModelFactory.getModel('Character'),
      WorldBuilding: ModelFactory.getModel('WorldBuilding'),
      WritingSession: ModelFactory.getModel('WritingSession'),
      WritingGoal: ModelFactory.getModel('WritingGoal'),
      WritingTemplate: ModelFactory.getModel('WritingTemplate'),
      TimelineEvent: ModelFactory.getModel('TimelineEvent')
    };
  }

  /**
   * 检查连接状态
   */
  public isArangoDBConnected(): boolean {
    return this.isConnected && this.arangoDBService !== null;
  }

  /**
   * 获取连接状态
   */
  public getConnectionStatus() {
    return {
      arangodb: this.arangoDBService ? 'connected' : 'disconnected',
      sequelize_compat: this.sequelize ? 'connected' : 'disconnected'
    };
  }

  /**
   * 断开连接
   */
  public async disconnect(): Promise<void> {
    try {
      if (this.arangoDBService) {
        await this.arangoDBService.disconnect();
        this.arangoDBService = null;
      }

      if (this.sequelize) {
        await this.sequelize.close();
        this.sequelize = null;
      }

      this.isConnected = false;
      logger.info('数据库连接已断开');
    } catch (error) {
      logger.error('断开数据库连接时发生错误:', error);
    }
  }
}

// 导出单例实例
export const databaseAdapter = DatabaseAdapter.getInstance();

// 保持向后兼容性的导出
export const databaseConfig = databaseAdapter;
export default databaseAdapter;
