#!/bin/bash

# 端口监听测试脚本

echo "=== AI小说内容编辑器 端口监听测试 ==="
echo "时间: $(date)"
echo

# 检查Docker是否运行
if ! command -v docker &> /dev/null; then
    echo "❌ Docker未安装或未启动"
    exit 1
fi

echo "✅ Docker已安装"

# 检查docker-compose是否可用
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose未安装"
    exit 1
fi

echo "✅ Docker Compose已安装"

# 检查是否有.env文件
if [ ! -f .env ]; then
    echo "⚠️  .env文件不存在，将从.env.example复制"
    cp .env.example .env
    echo "请编辑.env文件填写实际配置值"
fi

echo "✅ 环境变量文件检查完成"

# 启动服务
echo
echo "🚀 启动服务..."
docker-compose up -d

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 30

# 检查服务状态
echo
echo "📊 检查服务状态..."
docker-compose ps

# 检查端口监听
echo
echo "🔍 检查端口监听状态..."

# 检查80端口 (前端)
if lsof -i :80 > /dev/null 2>&1 || netstat -tuln | grep :80 > /dev/null 2>&1; then
    echo "✅ 端口80 (前端) 正在监听"
else
    echo "❌ 端口80 (前端) 未监听"
fi

# 检查8000端口 (后端)
if lsof -i :8000 > /dev/null 2>&1 || netstat -tuln | grep :8000 > /dev/null 2>&1; then
    echo "✅ 端口8000 (后端) 正在监听"
else
    echo "❌ 端口8000 (后端) 未监听"
fi

# 检查27017端口 (MongoDB)
if lsof -i :27017 > /dev/null 2>&1 || netstat -tuln | grep :27017 > /dev/null 2>&1; then
    echo "✅ 端口27017 (MongoDB) 正在监听"
else
    echo "❌ 端口27017 (MongoDB) 未监听"
fi

# 检查6379端口 (Redis)
if lsof -i :6379 > /dev/null 2>&1 || netstat -tuln | grep :6379 > /dev/null 2>&1; then
    echo "✅ 端口6379 (Redis) 正在监听"
else
    echo "❌ 端口6379 (Redis) 未监听"
fi

# 测试服务连通性
echo
echo "🌐 测试服务连通性..."

# 测试前端
if curl -s http://localhost:80 > /dev/null 2>&1; then
    echo "✅ 前端服务 (http://localhost:80) 可访问"
else
    echo "❌ 前端服务 (http://localhost:80) 无法访问"
fi

# 测试后端
if curl -s http://localhost:8000 > /dev/null 2>&1; then
    echo "✅ 后端服务 (http://localhost:8000) 可访问"
else
    echo "❌ 后端服务 (http://localhost:8000) 无法访问"
fi

# 测试后端API文档
if curl -s http://localhost:8000/docs > /dev/null 2>&1; then
    echo "✅ 后端API文档 (http://localhost:8000/docs) 可访问"
else
    echo "❌ 后端API文档 (http://localhost:8000/docs) 无法访问"
fi

# 测试健康检查
if curl -s http://localhost:8000/health > /dev/null 2>&1; then
    echo "✅ 健康检查端点 (http://localhost:8000/health) 可访问"
else
    echo "❌ 健康检查端点 (http://localhost:8000/health) 无法访问"
fi

echo
echo "📋 测试完成！"
echo "如需查看详细日志，请运行: docker-compose logs -f"
echo "访问地址:"
echo "  前端: http://localhost:80"
echo "  后端: http://localhost:8000"
echo "  API文档: http://localhost:8000/docs"
echo "  健康检查: http://localhost:8000/health"
