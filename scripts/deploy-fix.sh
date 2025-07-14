#!/bin/bash

# AI小说编辑器项目部署修复脚本
# 解决 MongoDB 容器重启和后端健康检查失败问题

set -e

PROJECT_DIR="/workspaces/legezhixiao"
cd "$PROJECT_DIR"

echo "🚀 开始部署修复流程..."

# 1. 环境检查
echo "
🔍 步骤 1: 环境检查"
echo "当前工作目录: $(pwd)"
echo "Docker 版本: $(docker --version)"
echo "Docker Compose 版本: $(docker-compose --version)"

# 2. 清理现有容器和网络
echo "
🧹 步骤 2: 清理现有容器和网络"
docker-compose down --remove-orphans 2>/dev/null || true
docker system prune -f --volumes 2>/dev/null || true

# 3. 检查端口占用
echo "
🔍 步骤 3: 检查端口占用"
for port in 80 8000 27017 6379; do
    if lsof -i :$port 2>/dev/null; then
        echo "⚠️  端口 $port 被占用"
        # 可选择杀掉占用进程
        # sudo kill -9 $(lsof -t -i:$port) 2>/dev/null || true
    else
        echo "✅ 端口 $port 可用"
    fi
done

# 4. 创建必要的目录和文件
echo "
📁 步骤 4: 创建必要的目录和文件"
mkdir -p backend/logs
mkdir -p database
touch backend/logs/.gitkeep

# 确保 mongo-init.js 存在
if [ ! -f "database/mongo-init.js" ]; then
    echo "❌ database/mongo-init.js 不存在！"
    exit 1
else
    echo "✅ database/mongo-init.js 存在"
fi

# 5. 分阶段启动服务
echo "
🚀 步骤 5: 分阶段启动服务"

# 5.1 启动 MongoDB
echo "启动 MongoDB..."
docker-compose up -d mongodb

# 等待 MongoDB 健康检查
echo "等待 MongoDB 健康检查..."
timeout=180
elapsed=0
while [ $elapsed -lt $timeout ]; do
    if docker-compose exec -T mongodb mongosh --quiet --eval "db.adminCommand('ping')" 2>/dev/null; then
        echo "✅ MongoDB 健康检查通过！"
        break
    else
        echo "⏳ 等待 MongoDB 启动... ($elapsed/$timeout 秒)"
        sleep 10
        elapsed=$((elapsed + 10))
    fi
done

if [ $elapsed -ge $timeout ]; then
    echo "❌ MongoDB 启动超时！"
    echo "MongoDB 日志："
    docker-compose logs --tail=50 mongodb
    exit 1
fi

# 5.2 启动 Redis
echo "启动 Redis..."
docker-compose up -d redis
sleep 10

# 5.3 构建并启动后端
echo "构建并启动后端..."
docker-compose up -d --build backend

# 等待后端健康检查
echo "等待后端健康检查..."
timeout=180
elapsed=0
while [ $elapsed -lt $timeout ]; do
    if curl -f http://localhost:8000/health 2>/dev/null; then
        echo "✅ 后端健康检查通过！"
        break
    else
        echo "⏳ 等待后端启动... ($elapsed/$timeout 秒)"
        sleep 15
        elapsed=$((elapsed + 15))
    fi
done

if [ $elapsed -ge $timeout ]; then
    echo "❌ 后端启动超时！"
    echo "后端日志："
    docker-compose logs --tail=50 backend
    exit 1
fi

# 5.4 启动前端
echo "构建并启动前端..."
docker-compose up -d --build frontend

# 6. 最终健康检查
echo "
🏥 步骤 6: 最终健康检查"
sleep 30

echo "检查所有服务状态："
docker-compose ps

echo "
检查服务健康状态："
services=("mongodb" "redis" "backend" "frontend")
for service in "${services[@]}"; do
    status=$(docker-compose ps -q $service | xargs docker inspect --format='{{.State.Health.Status}}' 2>/dev/null || echo "no-health-check")
    echo "- $service: $status"
done

# 7. 连接测试
echo "
🔌 步骤 7: 连接测试"
echo "测试后端 API..."
if curl -f http://localhost:8000/health 2>/dev/null; then
    echo "✅ 后端 API 可访问"
else
    echo "❌ 后端 API 不可访问"
fi

echo "测试前端页面..."
if curl -f http://localhost:80 2>/dev/null; then
    echo "✅ 前端页面可访问"
else
    echo "❌ 前端页面不可访问"
fi

# 8. 显示访问信息
echo "
🎉 部署完成！

📊 服务状态：
$(docker-compose ps)

🔗 访问地址：
- 前端: http://localhost:80
- 后端: http://localhost:8000
- 后端健康检查: http://localhost:8000/health
- 后端 API 文档: http://localhost:8000/docs

📋 有用命令：
- 查看日志: docker-compose logs -f
- 重启服务: docker-compose restart [service_name]
- 停止服务: docker-compose down
- 查看状态: docker-compose ps

⚠️  注意事项：
- 如果仍有问题，请检查服务器资源（内存、磁盘空间）
- 查看详细日志定位问题：docker-compose logs [service_name]
- MongoDB 数据持久化在 docker volume 中
"
