#!/usr/bin/env python3
"""
创建测试用户脚本
用户名：admin
密码：369369
"""

import asyncio
import bcrypt
from datetime import datetime
from motor.motor_asyncio import AsyncIOMotorClient
import os

# MongoDB连接配置
MONGODB_URL = "mongodb://localhost:27017"
DATABASE_NAME = "ai_novel_editor"

async def create_test_user():
    """创建测试用户"""
    print("正在连接MongoDB...")
    
    # 连接MongoDB
    client = AsyncIOMotorClient(MONGODB_URL)
    db = client[DATABASE_NAME]
    users_collection = db.users
    
    try:
        # 检查用户是否已存在
        existing_user = await users_collection.find_one({
            "$or": [
                {"email": "admin@test.com"},
                {"username": "admin"}
            ]
        })
        
        if existing_user:
            print("用户 'admin' 已存在，正在删除旧用户...")
            await users_collection.delete_one({"_id": existing_user["_id"]})
        
        # 加密密码
        password = "369369"
        password_hash = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())
        
        # 创建用户文档
        user_doc = {
            "username": "admin",
            "email": "admin@test.com",
            "password_hash": password_hash,
            "is_active": True,
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow()
        }
        
        # 插入用户
        result = await users_collection.insert_one(user_doc)
        user_id = str(result.inserted_id)
        
        print(f"✅ 测试用户创建成功！")
        print(f"用户ID: {user_id}")
        print(f"用户名: admin")
        print(f"邮箱: admin@test.com")
        print(f"密码: 369369")
        print(f"创建时间: {user_doc['created_at']}")
        
        # 验证用户创建成功
        created_user = await users_collection.find_one({"_id": result.inserted_id})
        if created_user:
            print(f"✅ 用户验证成功，数据库中存在用户记录")
        else:
            print(f"❌ 用户验证失败")
            
    except Exception as e:
        print(f"❌ 创建用户时发生错误: {e}")
    finally:
        # 关闭连接
        client.close()
        print("MongoDB连接已关闭")

async def main():
    """主函数"""
    print("=== 创建测试用户脚本 ===")
    
    # 创建用户
    await create_test_user()
    
    print("\n=== 用户创建完成 ===")
    print("请使用以下信息登录：")
    print("用户名: admin")
    print("邮箱: admin@test.com") 
    print("密码: 369369")

if __name__ == "__main__":
    asyncio.run(main())
