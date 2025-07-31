import { logger } from '../utils/logger';
import { ArangoDBService } from '../services/arangoDBService';

/**
 * 现代化数据库配置 - 基于ArangoDB多模态数据库
 * 替代旧的SQLite+Sequelize架构，提供文档存储+图数据库能力
 */
class DatabaseConfig {
  private static instance: DatabaseConfig;
  public arangoDBService: ArangoDBService | null = null;
  private isConnected: boolean = false;

  private constructor() {}

  public static getInstance(): DatabaseConfig {
    if (!DatabaseConfig.instance) {
      DatabaseConfig.instance = new DatabaseConfig();
    }
    return DatabaseConfig.instance;
  }

  /**
   * 连接ArangoDB多模态数据库
   * 包含文档存储和图数据库功能
   */
  public async connectArangoDB(): Promise<void> {
    try {
      this.arangoDBService = new ArangoDBService();
      await this.arangoDBService.connect();
      
      // 初始化数据库结构
      await this.arangoDBService.initializeDatabase();
      
      this.isConnected = true;
      logger.info('ArangoDB多模态数据库连接成功', {
        url: process.env.ARANGODB_URL || 'http://localhost:8529',
        database: process.env.ARANGODB_DATABASE || 'legezhixiao'
      });
    } catch (error) {
      logger.error('ArangoDB连接失败:', error);
      throw error;
    }
  }

  /**
   * 断开数据库连接
   */
  public async disconnect(): Promise<void> {
    try {
      if (this.arangoDBService) {
        await this.arangoDBService.disconnect();
        this.arangoDBService = null;
      }
      this.isConnected = false;
      logger.info('ArangoDB连接已断开');
    } catch (error) {
      logger.error('断开ArangoDB连接时出错:', error);
    }
  }

  /**
   * 获取ArangoDB服务实例
   */
  public getArangoDBService(): ArangoDBService {
    if (!this.arangoDBService || !this.isConnected) {
      throw new Error('ArangoDB未连接，请先调用connectArangoDB()');
    }
    return this.arangoDBService;
  }

  /**
   * 检查数据库连接状态
   */
  public getConnectionStatus(): {
    arangodb: string;
    isConnected: boolean;
  } {
    return {
      arangodb: this.isConnected ? 'connected' : 'disconnected',
      isConnected: this.isConnected
    };
  }

  /**
   * 健康检查
   */
  public async healthCheck(): Promise<{
    arangodb: boolean;
    collections: string[];
    version: string | null;
  }> {
    if (!this.arangoDBService || !this.isConnected) {
      return {
        arangodb: false,
        collections: [],
        version: null
      };
    }

    try {
      const version = await this.arangoDBService.getVersion();
      const collections = await this.arangoDBService.listCollections();
      
      return {
        arangodb: true,
        collections: collections.map(c => c.name),
        version
      };
    } catch (error) {
      logger.error('数据库健康检查失败:', error);
      return {
        arangodb: false,
        collections: [],
        version: null
      };
    }
  }
}

// 导出单例实例
export const databaseConfig = DatabaseConfig.getInstance();
export default databaseConfig;
