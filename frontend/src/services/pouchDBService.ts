/**
 * PouchDB数据库服务
 * 提供本地数据存储和同步功能
 */

import PouchDB from 'pouchdb';
import { v4 as uuidv4 } from 'uuid';

export interface DBDocument {
  _id: string;
  _rev?: string;
  type: string;
  data: any;
  createdAt: string;
  updatedAt: string;
}

export interface SyncOptions {
  live?: boolean;
  retry?: boolean;
  continuous?: boolean;
}

export class PouchDBService {
  private localDB: PouchDB.Database;
  private remoteDB?: PouchDB.Database;
  private dbName: string;

  constructor(dbName: string = 'legezhixiao_novels') {
    this.dbName = dbName;
    this.localDB = new PouchDB(dbName);
  }

  /**
   * 初始化数据库连接
   */
  async initialize(): Promise<void> {
    try {
      const info = await this.localDB.info();
      console.log('PouchDB initialized:', info);
    } catch (error) {
      console.error('Failed to initialize PouchDB:', error);
      throw error;
    }
  }

  /**
   * 创建文档
   */
  async create(type: string, data: any): Promise<DBDocument> {
    const doc: DBDocument = {
      _id: uuidv4(),
      type,
      data,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    try {
      const result = await this.localDB.put(doc);
      return { ...doc, _rev: result.rev };
    } catch (error) {
      console.error('Failed to create document:', error);
      throw error;
    }
  }

  /**
   * 读取文档
   */
  async read(id: string): Promise<DBDocument | null> {
    try {
      const doc = await this.localDB.get(id) as DBDocument;
      return doc;
    } catch (error: any) {
      if (error.status === 404) {
        return null;
      }
      console.error('Failed to read document:', error);
      throw error;
    }
  }

  /**
   * 更新文档
   */
  async update(id: string, data: any): Promise<DBDocument> {
    try {
      const existingDoc = await this.localDB.get(id) as DBDocument;
      const updatedDoc: DBDocument = {
        ...existingDoc,
        data: { ...existingDoc.data, ...data },
        updatedAt: new Date().toISOString()
      };

      const result = await this.localDB.put(updatedDoc);
      return { ...updatedDoc, _rev: result.rev };
    } catch (error) {
      console.error('Failed to update document:', error);
      throw error;
    }
  }

  /**
   * 删除文档
   */
  async delete(id: string): Promise<boolean> {
    try {
      const doc = await this.localDB.get(id);
      await this.localDB.remove(doc);
      return true;
    } catch (error) {
      console.error('Failed to delete document:', error);
      return false;
    }
  }

  /**
   * 查询文档
   */
  async query(type?: string, options?: any): Promise<DBDocument[]> {
    try {
      const result = await this.localDB.allDocs({
        include_docs: true,
        ...options
      });

      let docs = result.rows
        .map(row => row.doc as DBDocument)
        .filter(doc => doc && !doc._id.startsWith('_design/'));

      if (type) {
        docs = docs.filter(doc => doc.type === type);
      }

      return docs;
    } catch (error) {
      console.error('Failed to query documents:', error);
      throw error;
    }
  }

  /**
   * 设置远程数据库同步
   */
  setRemoteDB(remoteUrl: string): void {
    this.remoteDB = new PouchDB(remoteUrl);
  }

  /**
   * 同步到远程数据库
   */
  async syncToRemote(options: SyncOptions = {}): Promise<void> {
    if (!this.remoteDB) {
      throw new Error('Remote database not configured');
    }

    try {
      await this.localDB.sync(this.remoteDB, {
        live: options.live || false,
        retry: options.retry || false,
        continuous: options.continuous || false
      });
    } catch (error) {
      console.error('Failed to sync to remote:', error);
      throw error;
    }
  }

  /**
   * 从远程数据库同步
   */
  async syncFromRemote(options: SyncOptions = {}): Promise<void> {
    if (!this.remoteDB) {
      throw new Error('Remote database not configured');
    }

    try {
      await this.localDB.replicate.from(this.remoteDB, options);
    } catch (error) {
      console.error('Failed to sync from remote:', error);
      throw error;
    }
  }

  /**
   * 获取数据库信息
   */
  async getInfo(): Promise<any> {
    return await this.localDB.info();
  }

  /**
   * 清空数据库
   */
  async clear(): Promise<void> {
    try {
      await this.localDB.destroy();
      this.localDB = new PouchDB(this.dbName);
    } catch (error) {
      console.error('Failed to clear database:', error);
      throw error;
    }
  }

  /**
   * 关闭数据库连接
   */
  async close(): Promise<void> {
    try {
      await this.localDB.close();
      if (this.remoteDB) {
        await this.remoteDB.close();
      }
    } catch (error) {
      console.error('Failed to close database:', error);
      throw error;
    }
  }
}

// 创建单例实例
export const pouchDBService = new PouchDBService();
