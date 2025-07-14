#!/bin/bash

# 测试 docker-compose 本地启动脚本
# 用于验证容器配置和启动流程

set -e

PROJECT_DIR="/workspaces/legezhixiao"
cd "$PROJECT_DIR"

echo "🚀 开始测试 Docker Compose 配置..."

# 创建必要的环境文件
if [ ! -f .env ]; then
    echo "📋 创建测试环境文件..."
    cp .env.example .env
    
    # 设置基本的测试环境变量
    echo "
# 测试环境变量
SILICONFLOW_API_KEY=test_key
JWT_SECRET_KEY=test_jwt_secret_key_for_development
MONGO_PASSWORD=test_mongo_password
REDIS_PASSWORD=test_redis_password
DATABASE_SYSTEMHOST=127.0.0.1
DATABASE_USER=test_user
DATABASE_PASSWORD=test_password
DATABASE_NOVELHOST=127.0.0.1
DATABASE_NOVELUSER=test_novel_user
DATABASE_NOVELUSER_PASSWORD=test_novel_password
SERVER_IP=127.0.0.1
" >> .env
fi

# 停止现有容器
echo "🛑 停止现有容器..."
docker-compose down --remove-orphans || true

# 清理旧的镜像和容器
echo "🧹 清理旧的镜像和容器..."
docker system prune -f

# 构建镜像
echo "🔧 构建 Docker 镜像..."
docker-compose build --no-cache

# 启动服务
echo "🚀 启动服务..."
docker-compose up -d

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 30

# 检查容器状态
echo "🔍 检查容器状态..."
docker-compose ps

# 检查每个服务的状态
echo "📊 检查各个服务状态..."
services=("mongodb" "redis" "backend" "frontend")

for service in "${services[@]}"; do
    echo "--- 检查 $service 服务 ---"
    
    # 检查容器是否运行
    if docker-compose ps "$service" | grep -q "Up"; then
        echo "✅ $service 容器正在运行"
    else
        echo "❌ $service 容器未运行"
        echo "📋 $service 容器日志:"
        docker-compose logs "$service" | tail -20
        continue
    fi
    
    # 检查容器日志
    echo "📋 $service 最新日志:"
    docker-compose logs "$service" | tail -5
done

# 等待后端应用启动
echo "⏳ 等待后端应用启动..."
sleep 30

# 检查端口监听
echo "🔍 检查端口监听状态..."
echo "--- 检查端口监听 ---"
netstat -tlnp | grep -E ":80|:8000|:27017|:6379" || echo "某些端口未监听"

# 健康检查
echo "🏥 执行健康检查..."

# 检查后端健康状态
echo "--- 检查后端健康状态 ---"
for i in {1..5}; do
    echo "尝试第 $i 次健康检查..."
    if curl -f -s --max-time 10 http://localhost:8000/health; then
        echo "✅ 后端健康检查成功"
        break
    else
        echo "❌ 后端健康检查失败，等待5秒后重试..."
        sleep 5
    fi
    
    if [ $i -eq 5 ]; then
        echo "❌ 后端健康检查最终失败"
        echo "📋 后端容器详细日志:"
        docker-compose logs backend
        
        # 尝试进入容器检查
        echo "🔍 尝试进入后端容器检查..."
        docker-compose exec -T backend ps aux || echo "无法检查后端容器进程"
        docker-compose exec -T backend netstat -tlnp || echo "无法检查后端容器网络"
        
        echo "❌ 测试失败，停止所有容器"
        docker-compose down
        exit 1
    fi
done

# 检查前端访问
echo "--- 检查前端访问 ---"
if curl -f -s --max-time 10 http://localhost:80 > /dev/null; then
    echo "✅ 前端访问成功"
else
    echo "❌ 前端访问失败"
    echo "📋 前端容器日志:"
    docker-compose logs frontend | tail -10
fi

# 检查数据库连接
echo "--- 检查数据库连接 ---"
if docker-compose exec -T mongodb mongosh --host localhost --port 27017 --eval "db.adminCommand('ping')" > /dev/null 2>&1; then
    echo "✅ MongoDB 连接成功"
else
    echo "❌ MongoDB 连接失败"
fi

if docker-compose exec -T redis redis-cli ping > /dev/null 2>&1; then
    echo "✅ Redis 连接成功"
else
    echo "❌ Redis 连接失败"
fi

echo "🎉 Docker Compose 测试完成！"
echo "📋 服务状态总结:"
docker-compose ps

echo "🔗 访问地址："
echo "- 前端: http://localhost:80"
echo "- 后端: http://localhost:8000"
echo "- API文档: http://localhost:8000/docs"
echo "- 健康检查: http://localhost:8000/health"

echo "🛑 如需停止服务，请运行: docker-compose down"
