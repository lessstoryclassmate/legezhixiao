#!/bin/bash

echo "🚀 AI小说编辑器 - 服务器直接部署脚本"
echo "============================================"

# 配置参数
PROJECT_DIR="/opt/ai-novel-editor"
BACKUP_DIR="/opt/backups/ai-novel-editor-$(date +%Y%m%d_%H%M%S)"
GITHUB_REPO="lessstoryclassmate/legezhixiao"
SSH_REPO="git@github.com:${GITHUB_REPO}.git"

# 环境变量配置（请根据实际情况修改）
export SERVER_IP="your_server_ip"
export SILICONFLOW_API_KEY="your_siliconflow_api_key"
export JWT_SECRET_KEY="your_jwt_secret_key"
export REDIS_PASSWORD="Lekairong350702"

# SSH密钥配置
SSH_KEY_PATH="/root/.ssh/id_ed25519"

echo "📋 部署配置:"
echo "项目目录: $PROJECT_DIR"
echo "备份目录: $BACKUP_DIR"
echo "仓库地址: $GITHUB_REPO"
echo "服务器IP: $SERVER_IP"
echo "SSH密钥: $SSH_KEY_PATH"

# 配置Git SSH认证
setup_ssh_auth() {
    echo "🔑 配置SSH认证..."
    
    # 检查SSH密钥是否存在
    if [ ! -f "$SSH_KEY_PATH" ]; then
        echo "❌ SSH密钥不存在: $SSH_KEY_PATH"
        echo "⚠️ 请确保SSH密钥已存在于服务器上"
        echo "   密钥路径: $SSH_KEY_PATH"
        echo "   公钥路径: ${SSH_KEY_PATH}.pub"
        echo ""
        echo "如果公钥未添加到GitHub，请访问:"
        echo "  https://github.com/settings/ssh/new"
        exit 1
    fi
    
    # 设置SSH密钥权限
    chmod 600 "$SSH_KEY_PATH"
    
    # 配置Git使用SSH
    export GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $SSH_KEY_PATH"
    git config --global core.sshCommand "ssh -i $SSH_KEY_PATH -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
    
    echo "✅ SSH认证配置完成"
}

# 检查必要的命令
echo ""
echo "🔍 检查系统环境..."
if ! command -v docker &> /dev/null; then
    echo "❌ Docker未安装，请先运行: bash scripts/install-docker.sh"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose未安装，请先运行: bash scripts/install-docker.sh"
    exit 1
fi

if ! command -v git &> /dev/null; then
    echo "❌ Git未安装，正在安装..."
    sudo apt-get update && sudo apt-get install -y git
fi

echo "✅ 环境检查通过"

# 检测Docker命令权限
echo ""
echo "🔍 检测Docker权限..."
DOCKER_CMD="docker"
COMPOSE_CMD="docker-compose"

if docker ps &> /dev/null; then
    echo "✅ 可以直接运行Docker命令"
elif sudo docker ps &> /dev/null; then
    echo "⚠️ 需要sudo权限运行Docker"
    DOCKER_CMD="sudo docker"
    COMPOSE_CMD="sudo docker-compose"
else
    echo "❌ Docker命令无法执行，请检查安装"
    exit 1
fi

# 创建目录
echo ""
echo "📁 创建部署目录..."
sudo mkdir -p "$PROJECT_DIR"
sudo mkdir -p "$(dirname "$BACKUP_DIR")"
sudo chown $USER:$USER "$PROJECT_DIR"
sudo chown $USER:$USER "$(dirname "$BACKUP_DIR")"

# 备份现有部署
if [ -d "$PROJECT_DIR/.git" ]; then
    echo "📦 备份现有部署..."
    cp -r "$PROJECT_DIR" "$BACKUP_DIR"
    echo "✅ 备份完成: $BACKUP_DIR"
fi

# 进入项目目录
cd "$PROJECT_DIR"

# 配置SSH认证
setup_ssh_auth

# 克隆或更新代码
echo ""
echo "📥 获取最新代码..."
if [ -d ".git" ]; then
    echo "📦 更新现有仓库..."
    if git fetch origin && git reset --hard origin/main && git clean -fd; then
        echo "✅ 代码更新成功"
    else
        echo "❌ 更新失败，重新克隆..."
        cd ..
        rm -rf "$PROJECT_DIR"
        mkdir -p "$PROJECT_DIR"
        cd "$PROJECT_DIR"
        git clone "$SSH_REPO" .
    fi
else
    echo "📦 克隆仓库..."
    if [ "$(ls -A . 2>/dev/null)" ]; then
        echo "⚠️ 目录不为空，清理..."
        find . -maxdepth 1 -not -name '.' -not -name '..' -exec rm -rf {} + 2>/dev/null || true
    fi
    git clone "$SSH_REPO" .
fi

# 创建环境变量文件
echo ""
echo "🔧 配置环境变量..."
cat > .env << EOF
# 服务器配置
SERVER_IP=$SERVER_IP
SERVER_USER=root
SERVER_SSH_PORT=22
SERVER_PORT=22

# AI 服务配置
SILICONFLOW_API_KEY=$SILICONFLOW_API_KEY
SILICONFLOW_DEFAULT_MODEL=deepseek-ai/DeepSeek-V3
SILICONFLOW_API_URL=https://api.siliconflow.cn/v1/chat/completions
JWT_SECRET_KEY=$JWT_SECRET_KEY

# MCP 服务配置
MCP_SERVER_NAME=novel-ai-server
MCP_SERVER_PORT=8000
MCP_SERVER_HOST=$SERVER_IP
MCP_TOOLS_ENABLED=true
MCP_TOOLS_LIST=novel_generation,character_creation,plot_analysis,content_review,style_transfer
NOVEL_GENERATION_MAX_TOKENS=4096
NOVEL_GENERATION_TEMPERATURE=0.8
NOVEL_GENERATION_TOP_P=0.9

# 云数据库配置
MONGODB_HOST=172.16.32.2
MONGODB_PORT=27017
MONGODB_DATABASE=ai_novel_db
REDIS_HOST=172.16.32.2
REDIS_PORT=6379
REDIS_PASSWORD=$REDIS_PASSWORD

# MySQL 数据库配置
DATABASE_PORT=3306
DATABASE_SYSTEMHOST=172.16.16.3
DATABASE_SYSTEM=novel_data
DATABASE_USER=lkr
DATABASE_PASSWORD=Lekairong350702
DATABASE_NOVELHOST=172.16.16.2
DATABASE_NOVELDATA=novel_user_data
DATABASE_NOVELUSER=novel_data_user
DATABASE_NOVELUSER_PASSWORD=Lekairong350702
EOF

echo "✅ 环境变量配置完成"

# 检查数据库连接
echo ""
echo "🔍 检查数据库连接..."
DB_CHECK_FAILED=false

# MongoDB
if timeout 15 bash -c "echo > /dev/tcp/172.16.32.2/27017" 2>/dev/null; then
    echo "✅ MongoDB (172.16.32.2:27017) 可连接"
else
    echo "❌ MongoDB (172.16.32.2:27017) 连接失败"
    DB_CHECK_FAILED=true
fi

# Redis
if timeout 15 bash -c "echo > /dev/tcp/172.16.32.2/6379" 2>/dev/null; then
    echo "✅ Redis (172.16.32.2:6379) 可连接"
else
    echo "❌ Redis (172.16.32.2:6379) 连接失败"
    DB_CHECK_FAILED=true
fi

# MySQL系统库
if timeout 15 bash -c "echo > /dev/tcp/172.16.16.3/3306" 2>/dev/null; then
    echo "✅ MySQL系统库 (172.16.16.3:3306) 可连接"
else
    echo "❌ MySQL系统库连接失败"
    DB_CHECK_FAILED=true
fi

# MySQL用户库
if timeout 15 bash -c "echo > /dev/tcp/172.16.16.2/3306" 2>/dev/null; then
    echo "✅ MySQL用户库 (172.16.16.2:3306) 可连接"
else
    echo "❌ MySQL用户库连接失败"
    DB_CHECK_FAILED=true
fi

if [ "$DB_CHECK_FAILED" = true ]; then
    echo ""
    echo "⚠️⚠️⚠️ 数据库连接检查发现问题 ⚠️⚠️⚠️"
    echo "这可能导致后端服务启动失败！"
    echo "是否继续部署？ (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "❌ 部署已取消"
        exit 1
    fi
fi

# 设置脚本权限
chmod +x scripts/*.sh 2>/dev/null || true

# 提升vm.max_map_count参数
echo ""
echo "⚙️ 配置系统参数..."
sudo sysctl -w vm.max_map_count=1677720

# 停止现有服务
echo ""
echo "🛑 停止现有服务..."
$COMPOSE_CMD -f docker-compose.production.yml down --remove-orphans 2>/dev/null || true

# 清理Docker缓存
echo ""
echo "🧹 清理Docker缓存..."
$DOCKER_CMD container prune -f
$DOCKER_CMD image prune -f

# 构建镜像
echo ""
echo "🔧 构建Docker镜像..."
if $COMPOSE_CMD -f docker-compose.production.yml build --no-cache; then
    echo "✅ 镜像构建成功"
else
    echo "❌ 镜像构建失败"
    exit 1
fi

# 启动服务
echo ""
echo "🚀 启动服务..."
if $COMPOSE_CMD -f docker-compose.production.yml up -d; then
    echo "✅ 服务启动成功"
else
    echo "❌ 服务启动失败"
    exit 1
fi

# 等待服务启动
echo ""
echo "⏳ 等待服务初始化..."
sleep 30

# 检查容器状态
echo ""
echo "🔍 检查容器状态..."
$COMPOSE_CMD -f docker-compose.production.yml ps

# 健康检查
echo ""
echo "🏥 执行健康检查..."
HEALTH_CHECK_SUCCESS=false
for i in {1..5}; do
    echo "第 $i 次检查..."
    if curl -f --max-time 15 --connect-timeout 10 http://localhost:8000/health 2>/dev/null; then
        echo "✅ 后端健康检查通过"
        HEALTH_CHECK_SUCCESS=true
        break
    elif curl -f --max-time 15 --connect-timeout 10 http://localhost:8000/ 2>/dev/null; then
        echo "✅ 后端根路径可访问"
        HEALTH_CHECK_SUCCESS=true
        break
    else
        echo "❌ 第 $i 次检查失败"
        if [ $i -lt 5 ]; then
            sleep 15
        fi
    fi
done

# 显示部署结果
echo ""
echo "=================================================="
if [ "$HEALTH_CHECK_SUCCESS" = true ]; then
    echo "🎉 部署成功！"
    echo "🌐 前端地址: http://$SERVER_IP:80"
    echo "🔧 后端API: http://$SERVER_IP:8000"
    echo "📚 API文档: http://$SERVER_IP:8000/docs"
else
    echo "⚠️ 部署完成但健康检查未通过"
    echo "请检查服务日志: $COMPOSE_CMD -f docker-compose.production.yml logs"
fi

echo ""
echo "📋 有用的命令:"
echo "查看容器状态: $COMPOSE_CMD -f docker-compose.production.yml ps"
echo "查看日志: $COMPOSE_CMD -f docker-compose.production.yml logs"
echo "重启服务: $COMPOSE_CMD -f docker-compose.production.yml restart"
echo "停止服务: $COMPOSE_CMD -f docker-compose.production.yml down"

echo ""
echo "✅ 部署脚本执行完成！"
