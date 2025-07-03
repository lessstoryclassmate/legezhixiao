#!/bin/bash

# 项目结构验证脚本

echo "验证AI小说编辑器项目结构..."
echo "================================"

PROJECT_ROOT="/workspaces/legezhixiao/novel-editor"

# 检查主要目录
check_directory() {
    if [ -d "$1" ]; then
        echo "✅ $1"
    else
        echo "❌ $1 (缺失)"
    fi
}

# 检查主要文件
check_file() {
    if [ -f "$1" ]; then
        echo "✅ $1"
    else
        echo "❌ $1 (缺失)"
    fi
}

echo "检查主要目录..."
check_directory "$PROJECT_ROOT/backend"
check_directory "$PROJECT_ROOT/frontend"
check_directory "$PROJECT_ROOT/deployment"
check_directory "$PROJECT_ROOT/backend/app"
check_directory "$PROJECT_ROOT/backend/app/models"
check_directory "$PROJECT_ROOT/backend/app/routers"
check_directory "$PROJECT_ROOT/backend/app/services"
check_directory "$PROJECT_ROOT/backend/app/schemas"
check_directory "$PROJECT_ROOT/frontend/src"
check_directory "$PROJECT_ROOT/frontend/src/views"
check_directory "$PROJECT_ROOT/frontend/src/stores"
check_directory "$PROJECT_ROOT/frontend/src/utils"

echo ""
echo "检查主要配置文件..."
check_file "$PROJECT_ROOT/backend/requirements.txt"
check_file "$PROJECT_ROOT/backend/.env"
check_file "$PROJECT_ROOT/backend/main.py"
check_file "$PROJECT_ROOT/backend/Dockerfile"
check_file "$PROJECT_ROOT/frontend/package.json"
check_file "$PROJECT_ROOT/frontend/vite.config.js"
check_file "$PROJECT_ROOT/frontend/Dockerfile"
check_file "$PROJECT_ROOT/docker-compose.yml"
check_file "$PROJECT_ROOT/deployment/k8s-manifest.yaml"

echo ""
echo "检查核心代码文件..."
check_file "$PROJECT_ROOT/backend/app/database.py"
check_file "$PROJECT_ROOT/backend/app/models/user.py"
check_file "$PROJECT_ROOT/backend/app/services/ai_service.py"
check_file "$PROJECT_ROOT/backend/app/services/auth_service.py"
check_file "$PROJECT_ROOT/backend/app/routers/auth.py"
check_file "$PROJECT_ROOT/backend/app/routers/ai_assistant.py"
check_file "$PROJECT_ROOT/frontend/src/main.js"
check_file "$PROJECT_ROOT/frontend/src/App.vue"
check_file "$PROJECT_ROOT/frontend/src/views/Login.vue"
check_file "$PROJECT_ROOT/frontend/src/views/Editor.vue"
check_file "$PROJECT_ROOT/frontend/src/stores/auth.js"
check_file "$PROJECT_ROOT/frontend/src/utils/api.js"

echo ""
echo "检查脚本文件..."
check_file "$PROJECT_ROOT/start-dev.sh"
check_file "$PROJECT_ROOT/deploy.sh"

echo ""
echo "文件权限检查..."
if [ -x "$PROJECT_ROOT/start-dev.sh" ]; then
    echo "✅ start-dev.sh 有执行权限"
else
    echo "❌ start-dev.sh 缺少执行权限"
fi

if [ -x "$PROJECT_ROOT/deploy.sh" ]; then
    echo "✅ deploy.sh 有执行权限"
else
    echo "❌ deploy.sh 缺少执行权限"
fi

echo ""
echo "================================"
echo "项目结构验证完成！"
echo ""
echo "下一步操作："
echo "1. 配置数据库连接 (backend/.env)"
echo "2. 启动开发环境: ./start-dev.sh"
echo "3. 或使用Docker: docker-compose up -d"
echo "4. 生产部署: ./deploy.sh"
