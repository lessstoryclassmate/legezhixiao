#!/bin/bash

# 后端应用启动脚本 - 终极修复版本
set -e

echo "🚀 启动 AI 小说编辑器后端服务..."

# 显示重要的环境变量
echo "📋 环境变量检查:"
echo "MONGODB_URL: $MONGODB_URL"
echo "REDIS_URL: $REDIS_URL"

# 简化的 MongoDB 连接测试
echo "等待 MongoDB 连接..."
python3 -c "
import asyncio
from motor.motor_asyncio import AsyncIOMotorClient
import os
import sys

async def test_mongo():
    client = None
    try:
        client = AsyncIOMotorClient(os.getenv('MONGODB_URL'))
        await client.admin.command('ping')
        print('✅ MongoDB 连接成功')
        return True
    except Exception as e:
        print(f'❌ MongoDB 连接失败: {e}')
        return False
    finally:
        if client:
            await client.close()

success = asyncio.run(test_mongo())
sys.exit(0 if success else 1)
"

if [ $? -ne 0 ]; then
    echo "❌ MongoDB 连接失败"
    exit 1
fi

# 简化的 Redis 连接测试
echo "等待 Redis 连接..."
python3 -c "
import redis
import os
from urllib.parse import urlparse
import sys

try:
    redis_url = os.getenv('REDIS_URL')
    parsed = urlparse(redis_url)
    
    host = parsed.hostname or 'redis'
    port = parsed.port or 6379
    password = parsed.password
    
    r = redis.Redis(host=host, port=port, password=password, socket_timeout=5)
    r.ping()
    print('✅ Redis 连接成功')
    sys.exit(0)
except Exception as e:
    print(f'❌ Redis 连接失败: {e}')
    sys.exit(1)
"

if [ $? -ne 0 ]; then
    echo "❌ Redis 连接失败"
    exit 1
fi

echo "✅ 所有数据库连接成功！"
echo "🚀 启动 FastAPI 应用..."

# 启动应用
cd /app
exec uvicorn main:app --host 0.0.0.0 --port 8000 --reload
