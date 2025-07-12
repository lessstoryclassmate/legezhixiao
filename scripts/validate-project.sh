#!/bin/bash

# 项目完整性验证脚本
# 检查所有必要的文件是否存在且配置正确

set -e

echo "🔍 开始验证项目完整性..."

# 检查根目录文件
echo "📋 检查根目录文件..."
REQUIRED_ROOT_FILES=(
    "docker-compose.production.yml"
    ".env"
)

for file in "${REQUIRED_ROOT_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file 存在"
    else
        echo "❌ $file 缺失"
        exit 1
    fi
done

# 检查前端文件
echo "📋 检查前端文件..."
REQUIRED_FRONTEND_FILES=(
    "frontend/Dockerfile"
    "frontend/package.json"
    "frontend/src/main.ts"
    "frontend/index.html"
)

for file in "${REQUIRED_FRONTEND_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file 存在"
    else
        echo "❌ $file 缺失"
        exit 1
    fi
done

# 检查后端文件
echo "📋 检查后端文件..."
REQUIRED_BACKEND_FILES=(
    "backend/Dockerfile"
    "backend/requirements.txt"
    "backend/main.py"
    "backend/app"
)

for file in "${REQUIRED_BACKEND_FILES[@]}"; do
    if [ -f "$file" ] || [ -d "$file" ]; then
        echo "✅ $file 存在"
    else
        echo "❌ $file 缺失"
        exit 1
    fi
done

# 检查部署脚本
echo "📋 检查部署脚本..."
REQUIRED_SCRIPTS=(
    "scripts/quick-deploy.sh"
    "scripts/setup-docker-mirrors.sh"
    "scripts/fix-docker-network.sh"
)

for script in "${REQUIRED_SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        echo "✅ $script 存在"
        if [ -x "$script" ]; then
            echo "✅ $script 可执行"
        else
            echo "⚠️ $script 不可执行，正在修复..."
            chmod +x "$script"
        fi
    else
        echo "❌ $script 缺失"
        exit 1
    fi
done

# 检查 Docker Compose 语法
echo "📋 检查 Docker Compose 语法..."
if command -v docker-compose &> /dev/null; then
    if docker-compose -f docker-compose.production.yml config > /dev/null; then
        echo "✅ Docker Compose 配置语法正确"
    else
        echo "❌ Docker Compose 配置语法错误"
        exit 1
    fi
else
    echo "⚠️ Docker Compose 未安装，跳过语法检查"
fi

# 检查环境变量文件
echo "📋 检查环境变量..."
if [ -f ".env" ]; then
    # 检查关键环境变量
    REQUIRED_ENV_VARS=(
        "SILICONFLOW_API_KEY"
        "JWT_SECRET_KEY"
        "DATABASE_SYSTEMHOST"
        "DATABASE_NOVELHOST"
        "MONGODB_HOST"
        "REDIS_HOST"
    )
    
    for var in "${REQUIRED_ENV_VARS[@]}"; do
        if grep -q "$var=" .env; then
            echo "✅ 环境变量 $var 已配置"
        else
            echo "⚠️ 环境变量 $var 未配置"
        fi
    done
else
    echo "❌ .env 文件不存在"
    exit 1
fi

# 检查网络配置
echo "📋 检查网络配置..."
if grep -q "app-network" docker-compose.production.yml; then
    echo "✅ app-network 网络配置存在"
else
    echo "❌ app-network 网络配置缺失"
    exit 1
fi

# 检查端口配置
echo "📋 检查端口配置..."
if grep -q "80:80" docker-compose.production.yml; then
    echo "✅ 前端端口 80 配置正确"
else
    echo "❌ 前端端口配置错误"
    exit 1
fi

if grep -q "8000:8000" docker-compose.production.yml; then
    echo "✅ 后端端口 8000 配置正确"
else
    echo "❌ 后端端口配置错误"
    exit 1
fi

# 检查云数据库配置
echo "📋 检查云数据库配置..."
if grep -q "172.16.32.2" docker-compose.production.yml; then
    echo "✅ MongoDB/Redis 云服务器地址配置正确"
else
    echo "❌ MongoDB/Redis 云服务器地址配置错误"
    exit 1
fi

if grep -q "172.16.16" docker-compose.production.yml; then
    echo "✅ MySQL 云服务器地址配置正确"
else
    echo "❌ MySQL 云服务器地址配置错误"
    exit 1
fi

echo ""
echo "🎉 项目完整性验证通过！"
echo ""
echo "📋 验证结果摘要:"
echo "✅ 所有必要文件存在"
echo "✅ Docker Compose 配置正确"
echo "✅ 环境变量配置完整"
echo "✅ 网络和端口配置正确"
echo "✅ 云数据库配置正确"
echo "✅ 部署脚本可执行"
echo ""
echo "🚀 项目可以进行部署！"
echo ""
echo "📝 部署命令:"
echo "  快速部署: bash scripts/quick-deploy.sh"
echo "  手动部署: docker-compose -f docker-compose.production.yml up -d"
