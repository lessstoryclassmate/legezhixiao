#!/bin/bash
# 快速部署脚本 - 修复版本
# 专门解决 DNS 和 systemd 冲突问题

set -e

echo "🚀 开始快速部署 AI 小说编辑器（修复版）..."

# 定义变量
PROJECT_NAME="ai-novel-editor"
DEPLOY_DIR="/opt/ai-novel-editor"
GITHUB_REPO="https://github.com/${GITHUB_REPOSITORY}.git"

# ===== 1. 修复 DNS 配置（使用腾讯云 DNS）=====
echo "🌐 修复 DNS 配置（使用腾讯云 DNS）..."
echo "原 DNS 配置:"
cat /etc/resolv.conf

# 使用腾讯云公共 DNS（优先腾讯云）
sudo bash -c 'cat > /etc/resolv.conf <<EOF
nameserver 119.29.29.29
nameserver 223.5.5.5
nameserver 8.8.8.8
EOF'
echo "✅ DNS 已设置为腾讯云、阿里云和 Google DNS（优先腾讯云）"

# 验证 DNS 解析
echo "🔍 验证关键域名 DNS 解析..."
for domain in "mirror.ccs.tencentyun.com" "github.com"; do
    if nslookup "$domain" > /dev/null 2>&1; then
        echo "✅ $domain - DNS 解析正常"
    else
        echo "❌ $domain - DNS 解析失败"
        # 尝试另一组 DNS（保持腾讯云优先）
        sudo bash -c 'cat > /etc/resolv.conf <<EOF
nameserver 8.8.8.8
nameserver 119.29.29.29
nameserver 114.114.114.114
EOF'
        sleep 2
        if nslookup "$domain" > /dev/null 2>&1; then
            echo "✅ $domain - 备用 DNS 解析成功"
        else
            echo "❌ $domain - 所有 DNS 解析失败，但继续部署"
        fi
        break
    fi
done

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

# ===== 3. 配置腾讯云 Docker 镜像加速器 =====
echo "🐳 配置腾讯云 Docker 镜像加速器..."

# 测试腾讯云镜像源连通性
echo "🔍 测试腾讯云镜像源连通性..."
if curl -s --connect-timeout 10 https://mirror.ccs.tencentyun.com/v2/ > /dev/null; then
    echo "✅ 腾讯云镜像源可访问"
    REGISTRY_MIRROR="https://mirror.ccs.tencentyun.com"
else
    echo "⚠️ 腾讯云镜像源连通异常，但继续部署"
    REGISTRY_MIRROR="https://mirror.ccs.tencentyun.com"
fi

# 配置腾讯云 Docker 镜像加速器
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "registry-mirrors": [
    "$REGISTRY_MIRROR"
  ],
  "dns": ["119.29.29.29", "223.5.5.5", "8.8.8.8"]
}
EOF
echo "✅ 腾讯云 Docker 镜像加速器已配置"

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

# 确保 SSH 密钥文件存在并具有正确权限
SSH_KEY_PATH="/root/.ssh/id_ed25519"
if [ -f "$SSH_KEY_PATH" ]; then
    echo "✅ SSH 密钥文件存在: $SSH_KEY_PATH"
    # 设置正确的权限
    sudo chmod 600 "$SSH_KEY_PATH"
    sudo chmod 700 /root/.ssh
else
    echo "❌ SSH 密钥文件不存在: $SSH_KEY_PATH"
    echo "💡 请确保密钥文件已正确部署到服务器"
    echo "📋 部署步骤："
    echo "  1. 在服务器上生成 SSH 密钥: ssh-keygen -t ed25519 -f /root/.ssh/id_ed25519"
    echo "  2. 将公钥添加到 GitHub: cat /root/.ssh/id_ed25519.pub"
    echo "  3. 重新运行部署脚本"
    exit 1
fi

# 配置 SSH 客户端
echo "🔧 配置 SSH 客户端..."
sudo mkdir -p /root/.ssh
sudo tee /root/.ssh/config > /dev/null <<EOF
Host github.com
    HostName github.com
    User git
    IdentityFile $SSH_KEY_PATH
    IdentitiesOnly yes
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    ConnectTimeout 30
    ServerAliveInterval 60
    ServerAliveCountMax 3
EOF
sudo chmod 600 /root/.ssh/config

# 配置 Git 全局设置
echo "🔧 配置 Git 全局设置..."
sudo -u root git config --global core.sshCommand "ssh -i $SSH_KEY_PATH -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
sudo -u root git config --global user.name "Deploy Bot" || true
sudo -u root git config --global user.email "deploy@legezhixiao.com" || true

# 测试 SSH 连接
echo "🔍 测试 SSH 连接到 GitHub..."
if sudo -u root ssh -T git@github.com -o ConnectTimeout=10 2>&1 | grep -q "successfully authenticated"; then
    echo "✅ SSH 连接到 GitHub 成功"
    ssh_works=true
else
    echo "⚠️ SSH 连接测试未通过"
    ssh_works=false
fi

# 测试仓库访问
echo "🔍 测试仓库访问权限..."
if sudo -u root git ls-remote "git@github.com:lessstoryclassmate/legezhixiao.git" > /dev/null 2>&1; then
    echo "✅ 仓库访问权限正常"
    repo_access=true
else
    echo "⚠️ 仓库访问权限测试未通过"
    repo_access=false
fi

echo "📥 克隆最新代码..."
sudo mkdir -p "$DEPLOY_DIR"
cd /tmp
rm -rf ai-novel-editor-clone

# 优化 git 克隆参数
git config --global http.postBuffer 524288000
git config --global http.lowSpeedLimit 0
git config --global http.lowSpeedTime 999999

# 使用 SSH 克隆（根据需求文档）
echo "🔄 使用 SSH 克隆代码..."
if [ "$ssh_works" = true ] && [ "$repo_access" = true ]; then
    if sudo -u root git clone "git@github.com:lessstoryclassmate/legezhixiao.git" ai-novel-editor-clone; then
        echo "✅ SSH 代码克隆成功"
        sudo cp -r ai-novel-editor-clone/* "$DEPLOY_DIR"/
        sudo chown -R $USER:$USER "$DEPLOY_DIR"
    else
        echo "❌ SSH 克隆失败，尝试 HTTPS 作为备选..."
        if git clone "https://github.com/lessstoryclassmate/legezhixiao.git" ai-novel-editor-clone; then
            echo "✅ HTTPS 代码克隆成功"
            sudo cp -r ai-novel-editor-clone/* "$DEPLOY_DIR"/
            sudo chown -R $USER:$USER "$DEPLOY_DIR"
        else
            echo "❌ 所有克隆方式都失败"
            exit 1
        fi
    fi
else
    echo "⚠️ SSH 配置存在问题，使用 HTTPS 作为备选..."
    if git clone "https://github.com/lessstoryclassmate/legezhixiao.git" ai-novel-editor-clone; then
        echo "✅ HTTPS 代码克隆成功"
        sudo cp -r ai-novel-editor-clone/* "$DEPLOY_DIR"/
        sudo chown -R $USER:$USER "$DEPLOY_DIR"
    else
        echo "❌ 代码克隆失败"
        echo "🔧 故障排查建议："
        echo "  1. 检查网络连接"
        echo "  2. 验证 GitHub 仓库访问权限"
        echo "  3. 运行 SSH 验证脚本: ./scripts/verify-ssh-config.sh"
        exit 1
    fi
fi

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
if ! sudo docker-compose -f docker-compose.production.yml config > /dev/null; then
    echo "❌ Docker Compose 配置语法错误"
    exit 1
fi

# ===== 9. 仅使用 Docker Compose 启动服务 =====
echo "🚀 使用 Docker Compose 启动服务..."

# 显示当前 Docker 配置
echo "📋 当前 Docker 配置："
sudo docker info | grep -E "(Registry|Mirrors)" || echo "使用默认配置"

# 预拉取基础镜像（通过腾讯云镜像加速器）
echo "📦 预拉取基础镜像（通过腾讯云镜像加速器）..."

# 验证腾讯云镜像加速器配置
echo "🔍 验证腾讯云镜像加速器配置..."
if grep -q "mirror.ccs.tencentyun.com" /etc/docker/daemon.json 2>/dev/null; then
    echo "✅ 腾讯云镜像加速器配置正确"
else
    echo "⚠️ 腾讯云镜像加速器配置异常"
fi

# 基础镜像列表（通过镜像加速器会自动从腾讯云拉取）
BASE_IMAGES=(
    "node:18-alpine"
    "python:3.11-slim" 
    "nginx:alpine"
)

# 拉取基础镜像
for image in "${BASE_IMAGES[@]}"; do
    echo "🔄 拉取镜像: $image（通过腾讯云加速器）"
    if sudo docker pull "$image"; then
        echo "✅ $image 拉取成功"
    else
        echo "❌ $image 拉取失败，构建时会自动拉取"
    fi
done

# 启动服务
echo "🔄 启动 Docker Compose 服务..."
if sudo docker-compose -f docker-compose.production.yml up -d --build 2>&1 | tee /tmp/docker-build.log; then
    echo "✅ Docker Compose 服务启动成功"
else
    echo "❌ Docker Compose 服务启动失败"
    echo "📋 构建日志:"
    tail -30 /tmp/docker-build.log
    exit 1
fi

# ===== 10. 健康检查 =====
echo "⏳ 等待服务启动..."
sleep 20

echo "📊 检查容器状态..."
sudo docker-compose -f docker-compose.production.yml ps

# 检查后端健康状态
echo "🏥 检查后端服务健康状态..."
backend_healthy=false
for i in {1..12}; do
    if curl -f -s http://localhost:8000/health > /dev/null 2>&1; then
        echo "✅ 后端服务健康检查通过"
        backend_healthy=true
        break
    else
        echo "⏳ 后端服务启动中... ($i/12)"
        sleep 10
    fi
done

# 检查前端服务
echo "🌐 检查前端服务..."
frontend_healthy=false
for i in {1..6}; do
    if curl -f -s http://localhost:80 > /dev/null 2>&1; then
        echo "✅ 前端服务健康检查通过"
        frontend_healthy=true
        break
    else
        echo "⏳ 前端服务启动中... ($i/6)"
        sleep 5
    fi
done

# ===== 11. 部署结果总结 =====
echo ""
echo "=================================================================================="
if [ "$backend_healthy" = true ] && [ "$frontend_healthy" = true ]; then
    echo "🎉 部署成功! 所有服务正常运行"
    echo "✅ 后端服务: http://${SERVER_IP:-106.13.216.179}:8000 (健康)"
    echo "✅ 前端服务: http://${SERVER_IP:-106.13.216.179} (健康)"
    exit_code=0
elif [ "$backend_healthy" = true ]; then
    echo "🎯 部署基本成功! 后端正常，前端可能需要更多启动时间"
    echo "✅ 后端服务: http://${SERVER_IP:-106.13.216.179}:8000 (健康)"
    echo "⏳ 前端服务: http://${SERVER_IP:-106.13.216.179} (启动中)"
    exit_code=0
else
    echo "⚠️ 部署完成但后端服务存在问题"
    echo "❌ 后端服务: http://${SERVER_IP:-106.13.216.179}:8000 (异常)"
    echo "📋 后端日志:"
    sudo docker-compose -f docker-compose.production.yml logs backend --tail=30
    exit_code=1
fi

echo "=================================================================================="
echo ""
echo "📝 管理命令:"
echo "  查看日志: sudo docker-compose -f $DEPLOY_DIR/docker-compose.production.yml logs -f"
echo "  重启服务: sudo docker-compose -f $DEPLOY_DIR/docker-compose.production.yml restart"
echo "  停止服务: sudo docker-compose -f $DEPLOY_DIR/docker-compose.production.yml down"
echo "  查看状态: sudo docker-compose -f $DEPLOY_DIR/docker-compose.production.yml ps"

exit $exit_code
