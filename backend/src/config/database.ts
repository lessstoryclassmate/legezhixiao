import { Sequelize } from 'sequelize';
import { logger } from '../utils/logger';
import { initializeModels, Models } from '../models/index_simple';
import path from 'path';

// 数据库连接配置
class DatabaseConfig {
  private static instance: DatabaseConfig;
  public sequelize: Sequelize | null = null;
  public models: Models | null = null;

  private constructor() {}

  public static getInstance(): DatabaseConfig {
    if (!DatabaseConfig.instance) {
      DatabaseConfig.instance = new DatabaseConfig();
    }
    return DatabaseConfig.instance;
  }

  // 连接 SQLite
  public async connectSQLite(): Promise<void> {
    try {
      const dbPath = process.env.SQLITE_PATH || path.join(process.cwd(), 'data', 'database.sqlite');
      
      // 确保数据目录存在
      const fs = require('fs').promises;
      const dbDir = path.dirname(dbPath);
      await fs.mkdir(dbDir, { recursive: true });
      
      this.sequelize = new Sequelize({
        dialect: 'sqlite',
        storage: dbPath,
        logging: (msg: string) => logger.debug('SQLite:', msg),
        pool: {
          max: 5,
          min: 0,
          acquire: 30000,
          idle: 10000,
        },
        define: {
          timestamps: true,
          underscored: false,
          paranoid: true,
        },
      });

      // 测试连接
      await this.sequelize.authenticate();
      logger.info('SQLite connected successfully');

      // 初始化模型
      this.models = initializeModels(this.sequelize);
      logger.info('Database models initialized');

      // 同步数据库模型
      if (process.env.NODE_ENV === 'development') {
        await this.sequelize.sync({ alter: true });
        logger.info('Database models synchronized');
      }

    } catch (error) {
      logger.error('SQLite connection failed:', error);
      process.exit(1);
    }
  }

  // 断开所有数据库连接
  public async disconnect(): Promise<void> {
    try {
      if (this.sequelize) {
        await this.sequelize.close();
        logger.info('SQLite disconnected');
      }
    } catch (error) {
      logger.error('Error disconnecting from databases:', error);
    }
  }

  // 获取 Sequelize 实例
  public getSequelize(): Sequelize | null {
    return this.sequelize;
  }

  // 获取模型实例
  public getModels(): Models | null {
    return this.models;
  }

  // 检查数据库连接状态
  public getConnectionStatus(): {
    sqlite: string;
  } {
    return {
      sqlite: this.sequelize ? 'connected' : 'disconnected'
    };
  }
}

// 导出单例实例
export const databaseConfig = DatabaseConfig.getInstance();

// 优雅关闭处理
process.on('SIGINT', async () => {
  logger.info('Received SIGINT. Graceful shutdown...');
  await databaseConfig.disconnect();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  logger.info('Received SIGTERM. Graceful shutdown...');
  await databaseConfig.disconnect();
  process.exit(0);
});

export default databaseConfig;
