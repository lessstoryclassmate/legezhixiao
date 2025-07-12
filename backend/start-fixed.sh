#!/bin/bash

# 后端应用启动脚本 - 修复版本
set -e

echo "🚀 启动 AI 小说编辑器后端服务..."
echo "⏳ 等待数据库服务启动..."

# 显示重要的环境变量
echo "📋 环境变量检查:"
echo "MONGODB_URL: $MONGODB_URL"
echo "REDIS_URL: $REDIS_URL"

# 等待 MongoDB - 使用环境变量
echo "等待 MongoDB 连接..."
for i in {1..30}; do
    if python3 -c "
import asyncio
from motor.motor_asyncio import AsyncIOMotorClient
import os

async def test():
    try:
        client = AsyncIOMotorClient(os.getenv('MONGODB_URL'))
        await client.admin.command('ping')
        print('✅ MongoDB 连接成功')
        await client.close()
        exit(0)
    except Exception as e:
        print(f'❌ MongoDB 连接失败 (尝试 $i/30): {e}')
        await client.close() if 'client' in locals() else None
        exit(1)

asyncio.run(test())
"; then
        break
    fi
    
    if [ $i -eq 30 ]; then
        echo "❌ MongoDB 连接超时"
        exit 1
    fi
    
    sleep 2
done

# 等待 Redis - 使用环境变量
echo "等待 Redis 连接..."
for i in {1..30}; do
    if python3 -c "
import redis
import os
from urllib.parse import urlparse

try:
    redis_url = os.getenv('REDIS_URL')
    parsed = urlparse(redis_url)
    
    # 提取连接信息
    host = parsed.hostname or 'redis'
    port = parsed.port or 6379
    password = parsed.password
    
    r = redis.Redis(host=host, port=port, password=password, socket_timeout=5)
    r.ping()
    print('✅ Redis 连接成功')
except Exception as e:
    print(f'❌ Redis 连接失败 (尝试 $i/30): {e}')
    exit(1)
"; then
        break
    fi
    
    if [ $i -eq 30 ]; then
        echo "❌ Redis 连接超时"
        exit 1
    fi
    
    sleep 2
done

echo "✅ 所有数据库连接成功！"
echo "🚀 启动 FastAPI 应用..."

# 启动应用
cd /app
exec uvicorn main:app --host 0.0.0.0 --port 8000 --reload
