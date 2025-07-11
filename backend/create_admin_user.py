#!/usr/bin/env python3
"""
在正确的数据库中创建测试用户
"""

import asyncio
import bcrypt
from datetime import datetime
from motor.motor_asyncio import AsyncIOMotorClient

# 连接到后端使用的数据库
MONGODB_URL = "mongodb://localhost:27017"
DATABASE_NAME = "ai_novel_db"  # 后端使用的数据库

async def create_admin_user():
    """在ai_novel_db中创建admin用户"""
    print("正在连接MongoDB (ai_novel_db)...")
    
    client = AsyncIOMotorClient(MONGODB_URL)
    db = client[DATABASE_NAME]
    users_collection = db.users
    
    try:
        # 检查admin用户是否已存在
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
        
        print(f"✅ Admin用户创建成功！")
        print(f"数据库: {DATABASE_NAME}")
        print(f"用户ID: {user_id}")
        print(f"用户名: admin")
        print(f"邮箱: admin@test.com")
        print(f"密码: 369369")
        
        # 验证用户创建
        created_user = await users_collection.find_one({"_id": result.inserted_id})
        if created_user:
            print(f"✅ 用户验证成功")
        else:
            print(f"❌ 用户验证失败")
            
    except Exception as e:
        print(f"❌ 创建用户时发生错误: {e}")
    finally:
        client.close()
        print("MongoDB连接已关闭")

if __name__ == "__main__":
    asyncio.run(create_admin_user())
