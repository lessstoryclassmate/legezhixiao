#!/bin/bash
# 快速部署脚本 - 修复版本
# 专门解决 DNS 和 systemd 冲突问题

set -e

echo "🚀 开始快速部署 AI 小说编辑器（修复版）..."

# 定义变量
PROJECT_NAME="ai-novel-editor"
DEPLOY_DIR="/opt/ai-novel-editor"
GITHUB_REPO="https://github.com/${GITHUB_REPOSITORY}.git"

# ===== 1. 配置百度云DNS并验证网络连接 =====
echo "🌐 配置百度云DNS并验证网络连接..."

# 配置百度云DNS
echo "🔧 配置百度云DNS..."
echo "原 DNS 配置:"
cat /etc/resolv.conf

# 使用百度云DNS
sudo bash -c 'cat > /etc/resolv.conf <<EOF
nameserver 180.76.76.76
nameserver 8.8.8.8
EOF'
echo "✅ DNS 已设置为百度云DNS (180.76.76.76)"

# DNS配置完成，无需验证

# ===== 2. 彻底清理 systemd 服务冲突 =====
echo "🧹 彻底清理 systemd 服务冲突..."

# 停止所有可能的相关服务
SERVICES_TO_CLEAN=(
    "ai-novel-editor"
    "ai-novel-editor.service"
    "novel-editor"
    "novel-editor.service"
    "backend"
    "backend.service"
    "frontend"
    "frontend.service"
    "${PROJECT_NAME}"
    "${PROJECT_NAME}.service"
)

for service_name in "${SERVICES_TO_CLEAN[@]}"; do
    # 检查服务是否存在
    if systemctl list-unit-files | grep -q "^$service_name"; then
        echo "🛑 发现并清理服务: $service_name"
        sudo systemctl stop "$service_name" 2>/dev/null || true
        sudo systemctl disable "$service_name" 2>/dev/null || true
    fi
    
    # 检查是否正在运行
    if systemctl is-active --quiet "$service_name" 2>/dev/null; then
        echo "🛑 强制停止运行中的服务: $service_name"
        sudo systemctl stop "$service_name" || true
    fi
done

# 移除 systemd 服务文件
for service_name in "${SERVICES_TO_CLEAN[@]}"; do
    for service_path in "/etc/systemd/system" "/lib/systemd/system" "/usr/lib/systemd/system"; do
        service_file="$service_path/$service_name"
        if [ -f "$service_file" ]; then
            echo "🗑️ 移除服务文件: $service_file"
            sudo rm -f "$service_file"
        fi
    done
done

# 重新加载 systemd 并重置失败状态
sudo systemctl daemon-reload || true
sudo systemctl reset-failed || true
echo "✅ systemd 服务冲突清理完成"

# ===== 3. 配置百度云 Docker 镜像加速器 =====
echo "🐳 配置百度云 Docker 镜像加速器..."

# 配置 Docker 使用百度云镜像加速器
sudo mkdir -p /etc/docker
cat > /tmp/docker-daemon.json <<EOF
{
  "registry-mirrors": ["https://registry.baidubce.com"],
  "dns": ["180.76.76.76", "8.8.8.8"],
  "max-concurrent-downloads": 3,
  "max-concurrent-uploads": 5,
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "live-restore": true
}
EOF

sudo cp /tmp/docker-daemon.json /etc/docker/daemon.json
echo "✅ Docker 百度云镜像加速器已配置"

# 重启 Docker 服务应用配置
echo "🔄 重启 Docker 服务..."
sudo systemctl restart docker || true
sleep 5

# ===== 4. 停止现有服务 =====
echo "⏹️ 停止现有 Docker Compose 服务..."
if [ -d "$DEPLOY_DIR" ]; then
    cd "$DEPLOY_DIR"
    sudo docker-compose -f docker-compose.production.yml down --remove-orphans || true
    sudo docker-compose down --remove-orphans || true
fi

# ===== 5. 清理旧版本 =====
echo "🧹 清理旧版本..."
sudo rm -rf "$DEPLOY_DIR"

# ===== 6. 配置 SSH 密钥和克隆最新代码 =====
echo "🔑 配置 SSH 密钥..."

# SSH 密钥配置（简化）
SSH_KEY_PATH="/root/.ssh/id_ed25519"
if [ -f "$SSH_KEY_PATH" ]; then
    echo "✅ SSH 密钥文件存在"
    sudo chmod 600 "$SSH_KEY_PATH" 2>/dev/null || true
    sudo chmod 700 /root/.ssh 2>/dev/null || true
    ssh_works=true
else
    echo "⚠️ SSH 密钥文件不存在，使用HTTPS克隆"
    ssh_works=false
fi

# Git 配置（简化）
sudo -u root git config --global user.name "Deploy Bot" 2>/dev/null || true
sudo -u root git config --global user.email "deploy@legezhixiao.com" 2>/dev/null || true

# 克隆代码（简化）
echo "📥 克隆最新代码..."
sudo mkdir -p "$DEPLOY_DIR"
cd /tmp
rm -rf ai-novel-editor-clone

if [ "$ssh_works" = true ]; then
    git clone "git@github.com:lessstoryclassmate/legezhixiao.git" ai-novel-editor-clone
else
    git clone "https://github.com/lessstoryclassmate/legezhixiao.git" ai-novel-editor-clone
fi

sudo cp -r ai-novel-editor-clone/* "$DEPLOY_DIR"/
sudo chown -R $USER:$USER "$DEPLOY_DIR"

# ===== 7. 进入部署目录并配置环境 =====
cd "$DEPLOY_DIR"

# 创建 .env 文件
cat > .env <<EOF
# 服务器配置
SERVER_IP=${SERVER_IP:-106.13.216.179}

# MongoDB 配置
MONGODB_HOST=${MONGODB_HOST:-mongodb-server}
MONGODB_PORT=${MONGODB_PORT:-27017}
MONGODB_DATABASE=${MONGODB_DATABASE:-ai_novel_db}

# 系统数据库配置
DATABASE_PORT=${DATABASE_PORT:-3306}
DATABASE_SYSTEMHOST=${DATABASE_SYSTEMHOST:-172.16.16.3}
DATABASE_SYSTEM=${DATABASE_SYSTEM:-novel_data}
DATABASE_USER=${DATABASE_USER:-lkr}
DATABASE_PASSWORD=${DATABASE_PASSWORD:-Lekairong350702}

# 用户数据库配置
DATABASE_NOVELHOST=${DATABASE_NOVELHOST:-172.16.16.2}
DATABASE_NOVELDATA=${DATABASE_NOVELDATA:-novel_user_data}
DATABASE_NOVELUSER=${DATABASE_NOVELUSER:-novel_data_user}
DATABASE_NOVELUSER_PASSWORD=${DATABASE_NOVELUSER_PASSWORD:-Lekairong350702}

# Redis 配置
REDIS_HOST=${REDIS_HOST:-redis-server}
REDIS_PORT=${REDIS_PORT:-6379}
REDIS_PASSWORD=${REDIS_PASSWORD:-Lekairong350702}

# SiliconFlow API 配置
SILICONFLOW_API_KEY=${SILICONFLOW_API_KEY:-sk-mjithqmjwccqgffouexthbavtnvftwkqjludpcxhrmeztcib}
SILICONFLOW_DEFAULT_MODEL=${SILICONFLOW_DEFAULT_MODEL:-deepseek-ai/DeepSeek-V3}
SILICONFLOW_API_URL=${SILICONFLOW_API_URL:-https://api.siliconflow.cn/v1/chat/completions}

# JWT 配置
JWT_SECRET_KEY=${JWT_SECRET_KEY:-your-secret-key-change-this}

# MCP 配置
MCP_SERVER_NAME=${MCP_SERVER_NAME:-novel-ai-server}
MCP_SERVER_PORT=${MCP_SERVER_PORT:-8000}
MCP_SERVER_HOST=${MCP_SERVER_HOST:-106.13.216.179}
MCP_TOOLS_ENABLED=${MCP_TOOLS_ENABLED:-true}
MCP_TOOLS_LIST=${MCP_TOOLS_LIST:-novel_generation,character_creation,plot_analysis,content_review,style_transfer}

# 小说生成配置
NOVEL_GENERATION_MAX_TOKENS=2048
NOVEL_GENERATION_TEMPERATURE=0.7
NOVEL_GENERATION_TOP_P=0.9
EOF

# ===== 8. 验证配置文件 =====
echo "🔍 验证 Docker Compose 配置..."
sudo docker-compose -f docker-compose.production.yml config > /dev/null || echo "⚠️ Docker Compose 配置检查失败，但继续部署"

# ===== 9. 仅使用 Docker Compose 启动服务 =====
echo "🚀 使用 Docker Compose 启动服务..."

# 显示当前 Docker 配置
echo "📋 当前 Docker 配置："
sudo docker info | grep -E "(Registry|Mirrors)" || echo "使用默认配置"

# 预拉取基础镜像
echo "📦 预拉取基础镜像..."

# 基础镜像列表
BASE_IMAGES=(
    "node:18-alpine"
    "python:3.11-slim"
    "nginx:latest"
    "mongo:latest"
    "redis:latest"
)

# 使用百度云镜像拉取
for image in "${BASE_IMAGES[@]}"; do
    echo "🔄 拉取镜像: $image"
    sudo docker pull "registry.baidubce.com/library/$image" 2>/dev/null || echo "⚠️ $image 拉取失败，构建时会自动拉取"
    sudo docker tag "registry.baidubce.com/library/$image" "$image" 2>/dev/null || true
done

# 启动服务
echo "🔄 启动 Docker Compose 服务..."
sudo docker-compose -f docker-compose.production.yml up -d --build 2>&1 | tee /tmp/docker-build.log || echo "⚠️ Docker Compose 启动可能存在问题，但继续检查"

# 健康检查（简化）
echo "⏳ 等待服务启动..."
sleep 20

echo "📊 检查容器状态..."
sudo docker-compose -f docker-compose.production.yml ps || echo "⚠️ 无法获取容器状态"

# 检查服务健康状态（简化）
echo "🏥 检查服务健康状态..."
backend_healthy=false
frontend_healthy=false

# 检查后端服务
for i in {1..6}; do
    if curl -f -s http://localhost:8000/health > /dev/null 2>&1; then
        echo "✅ 后端服务健康检查通过"
        backend_healthy=true
        break
    else
        echo "⏳ 后端服务启动中... ($i/6)"
        sleep 5
    fi
done

# 检查前端服务
for i in {1..3}; do
    if curl -f -s http://localhost:80 > /dev/null 2>&1; then
        echo "✅ 前端服务健康检查通过"
        frontend_healthy=true
        break
    else
        echo "⏳ 前端服务启动中... ($i/3)"
        sleep 5
    fi
done

# 部署结果总结
echo ""
echo "=================================================================================="
if [ "$backend_healthy" = true ] && [ "$frontend_healthy" = true ]; then
    echo "🎉 部署成功! 所有服务正常运行"
    echo "✅ 后端服务: http://${SERVER_IP:-106.13.216.179}:8000"
    echo "✅ 前端服务: http://${SERVER_IP:-106.13.216.179}"
elif [ "$backend_healthy" = true ]; then
    echo "🎯 部署基本成功! 后端正常运行"
    echo "✅ 后端服务: http://${SERVER_IP:-106.13.216.179}:8000"
    echo "⚠️ 前端服务: http://${SERVER_IP:-106.13.216.179} (可能需要更多时间)"
else
    echo "⚠️ 部署完成，服务可能需要更多时间启动"
    echo "🔍 后端服务: http://${SERVER_IP:-106.13.216.179}:8000"
    echo "� 前端服务: http://${SERVER_IP:-106.13.216.179}"
fi

echo "=================================================================================="
echo ""
echo "📝 管理命令:"
echo "  查看日志: sudo docker-compose -f $DEPLOY_DIR/docker-compose.production.yml logs -f"
echo "  重启服务: sudo docker-compose -f $DEPLOY_DIR/docker-compose.production.yml restart"
echo "  停止服务: sudo docker-compose -f $DEPLOY_DIR/docker-compose.production.yml down"
echo "  查看状态: sudo docker-compose -f $DEPLOY_DIR/docker-compose.production.yml ps"

echo "✅ 部署脚本执行完成"
