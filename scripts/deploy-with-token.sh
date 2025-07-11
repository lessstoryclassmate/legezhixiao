#!/bin/bash

# 修复版部署脚本 - 使用GitHub Token解决私有仓库克隆问题
# 解决 "fatal: could not read Username for 'https://github.com': No such device or address" 错误

set -e

echo "🚀 开始部署AI小说编辑器 (Token认证版本)..."

# 检查必要的环境变量
required_vars=("GITHUB_TOKEN" "GITHUB_REPOSITORY" "SERVER_IP" "MONGO_PASSWORD" "REDIS_PASSWORD" "JWT_SECRET_KEY" "SILICONFLOW_API_KEY")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "❌ 错误: 环境变量 $var 未设置"
        exit 1
    fi
done

echo "✅ 所有必要环境变量已设置"

# 设置部署目录
PROJECT_DIR="/opt/ai-novel-editor"
BACKUP_DIR="/opt/backups/ai-novel-editor-$(date +%Y%m%d_%H%M%S)"

# 创建目录
sudo mkdir -p "$PROJECT_DIR"
sudo mkdir -p "$(dirname "$BACKUP_DIR")"
sudo chown $USER:$USER "$PROJECT_DIR"
sudo chown $USER:$USER "$(dirname "$BACKUP_DIR")"

# 备份现有部署
if [ -d "$PROJECT_DIR/.git" ]; then
  echo "📦 备份现有部署..."
  cp -r "$PROJECT_DIR" "$BACKUP_DIR" 2>/dev/null || echo "⚠️  备份失败，但继续部署..."
elif [ -d "$PROJECT_DIR" ] && [ "$(ls -A "$PROJECT_DIR" 2>/dev/null)" ]; then
  echo "📦 发现非Git目录，创建备份..."
  cp -r "$PROJECT_DIR" "$BACKUP_DIR" 2>/dev/null || echo "⚠️  备份失败，但继续部署..."
fi

# 进入项目目录
cd "$PROJECT_DIR"

# 配置Git认证（临时设置）
echo "🔐 配置Git Token认证..."
git config --global credential.helper store

# 克隆或更新代码（使用Token认证）
if [ -d ".git" ]; then
  echo "📦 更新现有Git仓库..."
  
  # 更新远程URL以包含token
  git remote set-url origin "https://${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
  
  if git fetch origin && git reset --hard origin/main && git clean -fd; then
    echo "✅ 代码更新成功"
  else
    echo "❌ Git更新失败，尝试重新克隆..."
    cd ..
    rm -rf "$PROJECT_DIR"
    mkdir -p "$PROJECT_DIR"
    cd "$PROJECT_DIR"
    
    # 使用Token克隆
    git clone "https://${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git" .
  fi
else
  echo "📦 初始化Git仓库..."
  
  # 清理目录
  if [ "$(ls -A . 2>/dev/null)" ]; then
    echo "⚠️  目录不为空，清理现有文件..."
    find . -maxdepth 1 -not -name '.' -not -name '..' -exec rm -rf {} + 2>/dev/null || true
  fi
  
  echo "🔄 克隆代码仓库 (使用Token认证)..."
  
  # 添加重试机制，使用Token认证
  for i in {1..3}; do
    if git clone "https://${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git" .; then
      echo "✅ 代码克隆成功"
      break
    else
      echo "❌ 克隆失败，尝试第 $i 次重试..."
      sleep 5
      if [ $i -eq 3 ]; then
        echo "❌ 代码克隆最终失败"
        echo "📋 调试信息:"
        echo "  GITHUB_REPOSITORY: $GITHUB_REPOSITORY"
        echo "  GITHUB_TOKEN length: ${#GITHUB_TOKEN}"
        echo "  当前目录: $(pwd)"
        echo "  目录内容: $(ls -la)"
        exit 1
      fi
    fi
  done
fi

# 验证代码克隆成功
if [ ! -f "docker-compose.yml" ]; then
  echo "❌ 关键文件缺失，代码克隆可能失败"
  ls -la
  exit 1
fi
echo "✅ 代码验证通过"

# 清理Git凭据（安全考虑）
echo "🧹 清理Git凭据..."
git config --global --unset credential.helper || true

# 创建环境变量文件
echo "🔧 配置环境变量..."
cat > .env << EOF
# 应用配置
APP_NAME=AI小说内容编辑器
APP_VERSION=1.0.0
DEBUG=false

# 服务器配置
SERVER_IP=$SERVER_IP
SERVER_USER=root
SERVER_SSH_PORT=22
SERVER_PORT=22

# 数据库配置 - 使用统一的MongoDB
MONGODB_URL=mongodb://localhost:27017/ai_novel_db
REDIS_URL=redis://localhost:6379

# SiliconFlow API配置
SILICONFLOW_API_KEY=$SILICONFLOW_API_KEY
SILICONFLOW_API_URL=https://api.siliconflow.cn/v1/chat/completions
SILICONFLOW_DEFAULT_MODEL=deepseek-ai/DeepSeek-V3

# MCP接口配置
MCP_SERVER_NAME=novel-ai-server
MCP_SERVER_PORT=8000
MCP_SERVER_HOST=$SERVER_IP
MCP_TOOLS_ENABLED=true
MCP_TOOLS_LIST=novel_generation,character_creation,plot_analysis,content_review,style_transfer

# 小说生成配置
NOVEL_GENERATION_MAX_TOKENS=4096
NOVEL_GENERATION_TEMPERATURE=0.8
NOVEL_GENERATION_TOP_P=0.9

# JWT配置
JWT_SECRET_KEY=$JWT_SECRET_KEY
JWT_ALGORITHM=HS256
JWT_EXPIRE_MINUTES=10080

# Docker环境变量
MONGO_INITDB_ROOT_USERNAME=admin
MONGO_INITDB_ROOT_PASSWORD=$MONGO_PASSWORD
MONGO_INITDB_DATABASE=ai_novel_db
REDIS_PASSWORD=$REDIS_PASSWORD
EOF

# 设置脚本权限
chmod +x scripts/*.sh 2>/dev/null || true

# 停止现有服务
echo "🛑 停止现有服务..."
docker-compose down || true

# 清理MongoDB数据卷（避免重启问题）
echo "🔍 检查 MongoDB 数据卷状态..."
if docker volume ls | grep -q "legezhixiao_mongodb_data"; then
    echo "发现现有 MongoDB 数据卷，为避免重启问题，将进行清理..."
    docker volume rm legezhixiao_mongodb_data || true
    echo "✅ MongoDB 数据卷已清理"
fi

# 清理Docker缓存
echo "🧹 清理Docker缓存..."
docker system prune -f || true

# 构建Docker镜像
echo "🔧 构建Docker镜像..."
if docker-compose build --no-cache; then
  echo "✅ Docker镜像构建成功"
else
  echo "❌ Docker镜像构建失败"
  exit 1
fi

# 分阶段启动服务
echo "🍃 启动 MongoDB..."
if docker-compose up -d mongodb; then
  echo "✅ MongoDB容器启动命令执行成功"
else
  echo "❌ MongoDB容器启动失败"
  exit 1
fi

echo "⏳ 等待 MongoDB 启动..."
sleep 60

# 检查 MongoDB 健康状态
echo "🔍 检查 MongoDB 健康状态..."
for i in {1..15}; do
    echo "MongoDB健康检查第 $i 次..."
    if docker-compose exec -T mongodb mongosh --quiet --eval "db.adminCommand('ping')" 2>/dev/null; then
        echo "✅ MongoDB 启动成功"
        break
    else
        echo "⏳ 等待 MongoDB 启动... ($i/15)"
        sleep 10
    fi
    
    if [ $i -eq 15 ]; then
        echo "❌ MongoDB 启动失败"
        echo "容器状态："
        docker-compose ps
        echo "MongoDB 日志："
        docker-compose logs --tail=30 mongodb
        exit 1
    fi
done

# 启动其他服务
echo "🚀 启动其他服务..."
if docker-compose up -d; then
  echo "✅ 所有服务启动命令执行成功"
else
  echo "❌ 服务启动失败"
  echo "容器状态："
  docker-compose ps
  echo "查看日志："
  docker-compose logs --tail=20
  exit 1
fi

# 等待服务就绪
echo "⏳ 等待所有服务就绪..."
sleep 30

# 最终状态检查
echo "📊 最终容器状态："
docker-compose ps

echo ""
echo "🎉 部署完成！"
echo "📱 访问信息："
echo "  前端: http://$SERVER_IP:80"
echo "  API: http://$SERVER_IP:8000"
echo "  健康检查: http://$SERVER_IP:8000/health"
echo ""
echo "🔐 测试账号:"
echo "  用户名: admin"
echo "  密码: 369369"
