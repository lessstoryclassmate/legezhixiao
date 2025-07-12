"""
数据库配置和连接管理
"""

from motor.motor_asyncio import AsyncIOMotorClient
from pymongo.server_api import ServerApi
import os
from typing import Optional
import asyncio

class DatabaseManager:
    """数据库管理器"""
    
    def __init__(self):
        self.client: Optional[AsyncIOMotorClient] = None
        self.database = None
        
    async def connect_to_mongo(self):
        """连接到MongoDB"""
        try:
            # 从环境变量获取MongoDB连接信息
            mongodb_url = os.getenv("MONGODB_URL", "mongodb://localhost:27017")
            database_name = os.getenv("MONGODB_DATABASE", "ai_novel_db")
            
            # 创建客户端连接
            self.client = AsyncIOMotorClient(
                mongodb_url,
                server_api=ServerApi('1'),
                maxPoolSize=10,
                minPoolSize=1,
                maxIdleTimeMS=45000,
                waitQueueTimeoutMS=5000,
                serverSelectionTimeoutMS=10000,
                connectTimeoutMS=10000,
                socketTimeoutMS=0,
                socketKeepAlive=True,
                heartbeatFrequencyMS=10000,
                retryWrites=True
            )
            
            # 获取数据库实例
            self.database = self.client[database_name]
            
            # 测试连接
            await self.client.admin.command('ping')
            print(f"✅ 成功连接到MongoDB: {database_name}")
            
        except Exception as e:
            print(f"❌ MongoDB连接失败: {e}")
            raise
    
    async def close_mongo_connection(self):
        """关闭MongoDB连接"""
        if self.client:
            self.client.close()
            print("✅ MongoDB连接已关闭")
    
    def get_database(self):
        """获取数据库实例"""
        return self.database
    
    def get_collection(self, collection_name: str):
        """获取集合"""
        if self.database:
            return self.database[collection_name]
        return None

# 全局数据库管理器实例
db_manager = DatabaseManager()

async def get_database():
    """获取数据库实例"""
    return db_manager.get_database()

async def get_collection(collection_name: str):
    """获取指定集合"""
    return db_manager.get_collection(collection_name)
