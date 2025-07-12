#!/bin/bash
# 快速部署脚本 - 克隆模式生产环境部署
# 用于GitHub Actions自动部署

set -e

echo "🚀 开始快速部署 AI 小说编辑器..."

# 定义变量
PROJECT_NAME="ai-novel-editor"
DEPLOY_DIR="/opt/ai-novel-editor"
GITHUB_REPO="https://github.com/${GITHUB_REPOSITORY}.git"

# 0. 安装Docker镜像加速器
echo "🐳 配置Docker镜像加速器..."
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com",
    "https://mirrors.tuna.tsinghua.edu.cn/docker-ce",
    "https://registry.docker-cn.com"
  ],
  "max-concurrent-downloads": 10,
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  }
}
EOF

# 重启Docker服务
sudo systemctl daemon-reload
sudo systemctl restart docker

# 1. 停止现有服务
echo "⏹️  停止现有服务..."
if [ -d "$DEPLOY_DIR" ]; then
    cd "$DEPLOY_DIR"
    sudo docker-compose -f docker-compose.production.yml down --remove-orphans || true
fi

# 2. 清理旧版本
echo "🧹 清理旧版本..."
sudo rm -rf "$DEPLOY_DIR"

# 3. 克隆最新代码
echo "📥 克隆最新代码..."
sudo mkdir -p "$DEPLOY_DIR"
cd /tmp
rm -rf ai-novel-editor-clone
git clone "$GITHUB_REPO" ai-novel-editor-clone
sudo cp -r ai-novel-editor-clone/* "$DEPLOY_DIR"/
sudo chown -R $USER:$USER "$DEPLOY_DIR"

# 4. 配置环境变量
echo "🔧 配置环境变量..."
cd "$DEPLOY_DIR"

# 创建.env文件
cat > .env <<EOF
# 服务器配置
SERVER_IP=${SERVER_IP}

# MongoDB 配置 (云数据库)
MONGODB_HOST=mongodb-server
MONGODB_PORT=27017
MONGODB_DATABASE=ai_novel_db

# MySQL 配置 (云数据库)
DATABASE_USER=novel_user
DATABASE_PASSWORD=${DATABASE_PASSWORD:-defaultpass123}
DATABASE_SYSTEMHOST=mysql-system
DATABASE_SYSTEM=novel_system_db

DATABASE_NOVELUSER=novel_data_user
DATABASE_NOVELUSER_PASSWORD=${DATABASE_NOVELUSER_PASSWORD:-novelpass123}
DATABASE_NOVELHOST=mysql-user
DATABASE_NOVELDATA=novel_content_db

# Redis 配置 (云数据库)
REDIS_HOST=redis-server
REDIS_PORT=6379
REDIS_PASSWORD=${REDIS_PASSWORD}

# SiliconFlow API 配置
SILICONFLOW_API_KEY=${SILICONFLOW_API_KEY}
SILICONFLOW_DEFAULT_MODEL=deepseek-v3
SILICONFLOW_API_URL=https://api.siliconflow.cn/v1

# JWT 配置
JWT_SECRET_KEY=${JWT_SECRET_KEY}

# MCP 配置
MCP_SERVER_NAME=novel-editor-mcp
MCP_SERVER_PORT=8001
MCP_SERVER_HOST=localhost
MCP_TOOLS_ENABLED=true
MCP_TOOLS_LIST=character_manager,plot_manager,world_manager

# 小说生成配置
NOVEL_GENERATION_MAX_TOKENS=2048
NOVEL_GENERATION_TEMPERATURE=0.7
NOVEL_GENERATION_TOP_P=0.9
EOF

# 5. 检查配置文件语法
echo "🔍 验证配置文件..."
if ! sudo docker-compose -f docker-compose.production.yml config > /dev/null; then
    echo "❌ Docker Compose配置语法错误"
    exit 1
fi

# 6. 拉取镜像 (使用重试机制)
echo "📦 拉取Docker镜像..."
for i in {1..3}; do
    if sudo docker-compose -f docker-compose.production.yml pull; then
        echo "✅ 镜像拉取成功"
        break
    else
        echo "⚠️  镜像拉取失败，重试 $i/3..."
        sleep 10
    fi
done

# 7. 构建并启动服务
echo "🏗️  构建并启动服务..."
sudo docker-compose -f docker-compose.production.yml up -d --build

# 8. 等待服务启动
echo "⏳ 等待服务启动..."
sleep 30

# 9. 健康检查
echo "🏥 执行健康检查..."
for i in {1..10}; do
    if curl -f http://localhost:8000/health > /dev/null 2>&1; then
        echo "✅ 后端服务健康检查通过"
        break
    else
        echo "⏳ 等待后端服务启动... ($i/10)"
        sleep 10
    fi
done

if curl -f http://localhost:80 > /dev/null 2>&1; then
    echo "✅ 前端服务健康检查通过"
else
    echo "⚠️  前端服务可能未完全启动"
fi

# 10. 显示服务状态
echo "📊 服务状态:"
sudo docker-compose -f docker-compose.production.yml ps

# 11. 显示部署信息
echo ""
echo "🎉 部署完成!"
echo "📍 访问地址:"
echo "  - 前端: http://${SERVER_IP}"
echo "  - API: http://${SERVER_IP}:8000"
echo "  - 健康检查: http://${SERVER_IP}:8000/health"
echo ""
echo "📝 查看日志:"
echo "  sudo docker-compose -f $DEPLOY_DIR/docker-compose.production.yml logs -f"
echo ""
echo "🔄 重启服务:"
echo "  sudo docker-compose -f $DEPLOY_DIR/docker-compose.production.yml restart"
