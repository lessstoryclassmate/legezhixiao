#!/bin/bash

# Nginx配置测试脚本

echo "=== Nginx配置测试 ==="
echo "时间: $(date)"
echo

# 检查nginx配置语法
echo "🔍 检查Nginx配置语法..."
if command -v nginx &> /dev/null; then
    nginx -t -c /workspaces/legezhixiao/frontend/nginx.conf
    if [ $? -eq 0 ]; then
        echo "✅ Nginx配置语法正确"
    else
        echo "❌ Nginx配置语法错误"
        exit 1
    fi
else
    echo "⚠️  本地未安装Nginx，跳过语法检查"
fi

# 检查Docker是否可用
echo
echo "🔍 检查Docker环境..."
if ! command -v docker &> /dev/null; then
    echo "❌ Docker未安装"
    exit 1
fi

echo "✅ Docker已安装"

# 检查docker-compose是否可用
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose未安装"
    exit 1
fi

echo "✅ Docker Compose已安装"

# 检查前端构建文件
echo
echo "🔍 检查前端构建配置..."

# 检查必要的前端文件
FRONTEND_FILES=(
    "frontend/Dockerfile"
    "frontend/package.json"
    "frontend/nginx.conf"
    "frontend/vite.config.ts"
    "frontend/tsconfig.json"
    "frontend/src/main.ts"
    "frontend/src/App.vue"
    "frontend/index.html"
)

for file in "${FRONTEND_FILES[@]}"; do
    if [ -f "/workspaces/legezhixiao/$file" ]; then
        echo "✅ $file 存在"
    else
        echo "❌ $file 不存在"
    fi
done

# 检查错误页面
ERROR_PAGES=(
    "frontend/public/404.html"
    "frontend/public/50x.html"
    "frontend/public/api_error.html"
)

echo
echo "🔍 检查错误页面..."
for page in "${ERROR_PAGES[@]}"; do
    if [ -f "/workspaces/legezhixiao/$page" ]; then
        echo "✅ $page 存在"
    else
        echo "❌ $page 不存在"
    fi
done

# 检查环境变量配置
echo
echo "🔍 检查环境变量配置..."
if [ -f "/workspaces/legezhixiao/.env.example" ]; then
    echo "✅ .env.example 存在"
    
    # 创建.env文件如果不存在
    if [ ! -f "/workspaces/legezhixiao/.env" ]; then
        echo "⚠️  .env文件不存在，从.env.example复制"
        cp /workspaces/legezhixiao/.env.example /workspaces/legezhixiao/.env
    fi
    echo "✅ .env 文件已准备"
else
    echo "❌ .env.example 不存在"
fi

# 测试前端构建
echo
echo "🔍 测试前端Docker构建..."
cd /workspaces/legezhixiao

# 构建前端镜像
echo "🏗️  构建前端镜像..."
docker build -t ai-novel-frontend ./frontend

if [ $? -eq 0 ]; then
    echo "✅ 前端Docker镜像构建成功"
    
    # 测试运行前端容器
    echo "🚀 测试运行前端容器..."
    docker run -d --name test-frontend -p 8080:80 ai-novel-frontend
    
    if [ $? -eq 0 ]; then
        echo "✅ 前端容器启动成功"
        
        # 等待容器启动
        sleep 5
        
        # 测试连接
        if curl -s http://localhost:8080 > /dev/null 2>&1; then
            echo "✅ 前端服务可访问 (http://localhost:8080)"
        else
            echo "❌ 前端服务无法访问"
            docker logs test-frontend
        fi
        
        # 清理测试容器
        docker stop test-frontend
        docker rm test-frontend
    else
        echo "❌ 前端容器启动失败"
        docker logs test-frontend
    fi
    
    # 清理测试镜像
    docker rmi ai-novel-frontend
else
    echo "❌ 前端Docker镜像构建失败"
fi

echo
echo "📋 Nginx配置测试完成！"
echo
echo "如果所有测试都通过，您可以运行以下命令启动完整服务："
echo "  docker-compose up -d"
echo
echo "访问地址："
echo "  外网端口: http://106.13.216.179:80"
echo "  监听端口: http://106.13.216.179:8080"
echo "  本地访问: http://localhost:80"
echo "  API文档: http://localhost:8000/docs"
