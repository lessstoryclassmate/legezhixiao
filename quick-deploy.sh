#!/bin/bash

# AI小说编辑器 - 克隆模式快速部署脚本
# 适用于：已安装Docker的环境，直接克隆代码并启动服务

set -e

echo "🚀 AI小说编辑器 - 克隆模式快速部署"
echo "======================================"

# 检查必要工具
echo "🔍 检查环境依赖..."

if ! command -v git &> /dev/null; then
    echo "❌ Git 未安装，请先安装 Git"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo "❌ Docker 未安装，请先安装 Docker"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose 未安装，请先安装 Docker Compose"
    exit 1
fi

echo "✅ 环境检查通过"

# 设置变量
PROJECT_DIR="/opt/ai-novel-editor"
REPO_URL="https://github.com/lessstoryclassmate/legezhixiao.git"

# 创建项目目录
echo "📁 准备项目目录..."
sudo mkdir -p "$PROJECT_DIR"
sudo chown $USER:$USER "$PROJECT_DIR"
cd "$PROJECT_DIR"

# 克隆或更新代码
if [ -d ".git" ]; then
    echo "📦 更新现有代码..."
    git pull origin main
else
    echo "📦 克隆代码仓库..."
    git clone "$REPO_URL" .
fi

# 检查必要文件
echo "🔍 检查配置文件..."
if [ ! -f "docker-compose.production.yml" ]; then
    echo "❌ 缺少 docker-compose.production.yml 文件"
    exit 1
fi

# 创建环境配置文件
echo "🔧 配置环境变量..."
cat > .env << 'EOF'
# AI 服务配置
SILICONFLOW_API_KEY=sk-mjithqmjwccqgffouexthbavtnvftwkqjludpcxhrmeztcib
SILICONFLOW_DEFAULT_MODEL=deepseek-ai/DeepSeek-V3
SILICONFLOW_API_URL=https://api.siliconflow.cn/v1/chat/completions
JWT_SECRET_KEY=your_jwt_secret_key_here

# 数据库配置 (云数据库)
DATABASE_PORT=3306
DATABASE_SYSTEMHOST=172.16.16.3
DATABASE_SYSTEM=novel_data
DATABASE_USER=lkr
DATABASE_PASSWORD=Lekairong350702
DATABASE_NOVELHOST=172.16.16.2
DATABASE_NOVELDATA=novel_user_data
DATABASE_NOVELUSER=novel_data_user
DATABASE_NOVELUSER_PASSWORD=Lekairong350702

# Redis 配置
REDIS_HOST=172.16.32.2
REDIS_PORT=6379
REDIS_PASSWORD=your_redis_password

# MongoDB 配置
MONGODB_HOST=172.16.32.2
MONGODB_PORT=27017
MONGODB_DATABASE=ai_novel_db

# MCP 配置
MCP_SERVER_NAME=novel-ai-server
MCP_SERVER_PORT=8000
MCP_SERVER_HOST=106.13.216.179
MCP_TOOLS_ENABLED=true
MCP_TOOLS_LIST=novel_generation,character_creation,plot_analysis,content_review,style_transfer
NOVEL_GENERATION_MAX_TOKENS=4096
NOVEL_GENERATION_TEMPERATURE=0.8
NOVEL_GENERATION_TOP_P=0.9
EOF

echo "✅ 环境配置完成"

# 停止现有服务
echo "🛑 停止现有服务..."
docker-compose -f docker-compose.production.yml down --remove-orphans 2>/dev/null || true

# 清理旧镜像（可选）
echo "🧹 清理旧镜像..."
docker image prune -f || true

# 启动服务
echo "🚀 启动服务..."
docker-compose -f docker-compose.production.yml up -d --build

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 30

# 检查服务状态
echo "🔍 检查服务状态..."
docker-compose -f docker-compose.production.yml ps

# 健康检查
echo "🔍 健康检查..."
HEALTH_CHECK_PASSED=false

for i in {1..10}; do
    echo "第 $i 次健康检查..."
    
    if curl -f --max-time 10 --connect-timeout 5 http://localhost:8000/health 2>/dev/null; then
        echo "✅ 后端服务健康检查通过"
        HEALTH_CHECK_PASSED=true
        break
    elif curl -f --max-time 10 --connect-timeout 5 http://localhost:8000/ 2>/dev/null; then
        echo "✅ 后端服务根路径可访问"
        HEALTH_CHECK_PASSED=true
        break
    else
        echo "⏳ 等待服务初始化..."
        sleep 10
    fi
done

if [ "$HEALTH_CHECK_PASSED" = true ]; then
    echo ""
    echo "🎉 部署成功！"
    echo "======================================"
    echo "🌐 前端访问地址: http://localhost:80"
    echo "🔧 后端API地址: http://localhost:8000"
    echo "📚 API文档地址: http://localhost:8000/docs"
    echo ""
    echo "💡 有用的命令:"
    echo "  查看日志: docker-compose -f docker-compose.production.yml logs -f"
    echo "  停止服务: docker-compose -f docker-compose.production.yml down"
    echo "  重启服务: docker-compose -f docker-compose.production.yml restart"
    echo ""
else
    echo ""
    echo "⚠️ 部署完成，但健康检查未通过"
    echo "请检查服务日志："
    echo "docker-compose -f docker-compose.production.yml logs"
fi

echo "✅ 克隆模式快速部署完成！"
