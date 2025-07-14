#!/bin/bash

# 快速启动脚本

set -e

echo "🚀 启动AI小说内容编辑器..."

# 检查是否存在.env文件
if [ ! -f .env ]; then
    echo "⚠️  环境变量文件不存在，正在创建..."
    cp .env.example .env
    echo "❌ 请先配置 .env 文件中的环境变量！"
    exit 1
fi

# 检查Docker是否运行
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker未运行，请先启动Docker"
    exit 1
fi

# 停止现有容器
echo "🛑 停止现有容器..."
docker-compose down

# 构建并启动
echo "🔧 构建和启动服务..."
docker-compose up -d --build

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 15

# 检查服务状态
echo "🔍 检查服务状态..."
docker-compose ps

# 显示访问信息
echo ""
echo "🎉 启动完成！"
echo "🌐 前端地址: http://localhost:80"
echo "🔧 后端API: http://localhost:8000"
echo "📚 API文档: http://localhost:8000/docs"
echo ""
echo "📋 常用命令:"
echo "  查看日志: docker-compose logs -f"
echo "  停止服务: docker-compose down"
echo "  重启服务: docker-compose restart"
