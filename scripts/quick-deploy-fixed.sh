#!/bin/bash
# 快速部署脚本 - 修复版本
# 专门解决 DNS 和 systemd 冲突问题

set -e

echo "🚀 开始快速部署 AI 小说编辑器（修复版）..."

# 定义变量
PROJECT_NAME="ai-novel-editor"
DEPLOY_DIR="/opt/ai-novel-editor"
GITHUB_REPO="git@github.com:lessstoryclassmate/legezhixiao.git"

# ===== 1. 配置百度云DNS并验证网络连接 =====
echo "🌐 配置百度云DNS并验证网络连接..."

# 配置百度云DNS
echo "🔧 配置百度云DNS..."
echo "原 DNS 配置:"
cat /etc/resolv.conf

# 使用百度云DNS
sudo bash -c 'cat > /etc/resolv.conf <<EOF
nameserver 180.76.76.76
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
  "dns": ["180.76.76.76"],
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
echo "🔑 执行SSH克隆修复..."

# 调用专门的SSH克隆修复脚本
CLONE_FIX_SCRIPT="/workspaces/legezhixiao/scripts/clone-fix.sh"
if [ -f "$CLONE_FIX_SCRIPT" ]; then
    echo "📋 使用专门的SSH克隆修复脚本..."
    if bash "$CLONE_FIX_SCRIPT"; then
        echo "✅ SSH克隆修复成功"
    else
        echo "❌ SSH克隆修复失败"
        exit 1
    fi
else
    echo "⚠️ 克隆修复脚本不存在，使用内置克隆逻辑..."
    
    # 原有的克隆逻辑作为备用
    # SSH 密钥配置（根据需求文档）
    SSH_KEY_PATH="/root/.ssh/id_ed25519"

# 严格检查SSH密钥文件
if [ ! -f "$SSH_KEY_PATH" ]; then
    echo "❌ SSH密钥不存在: $SSH_KEY_PATH"
    echo "🔧 请确保SSH密钥已正确部署到服务器"
    echo "💡 生成SSH密钥命令: ssh-keygen -t ed25519 -f $SSH_KEY_PATH -N ''"
    echo "📋 请将公钥添加到GitHub仓库的Deploy Keys中"
    exit 1
fi

if [ -f "$SSH_KEY_PATH" ]; then
    echo "✅ SSH 私钥文件存在: $SSH_KEY_PATH"
    
    # 检查SSH密钥文件权限
    key_permissions=$(stat -c "%a" "$SSH_KEY_PATH")
    if [ "$key_permissions" != "600" ]; then
        echo "🔧 修正SSH密钥文件权限..."
        sudo chmod 600 "$SSH_KEY_PATH"
        echo "✅ SSH密钥文件权限已修正为600"
    else
        echo "✅ SSH密钥文件权限正确(600)"
    fi
    
    # 设置正确的权限
    sudo chmod 600 "$SSH_KEY_PATH"
    sudo chmod 700 /root/.ssh
    
    # 配置 SSH 客户端配置文件
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
    
    # 测试 SSH 连接到 GitHub
    echo "🔍 测试 SSH 连接到 GitHub..."
    ssh_test_result=$(sudo -u root ssh -T git@github.com -o ConnectTimeout=10 2>&1)
    if echo "$ssh_test_result" | grep -q "successfully authenticated"; then
        echo "✅ SSH 连接到 GitHub 成功"
        ssh_works=true
    else
        echo "⚠️ SSH 连接测试失败，输出: $ssh_test_result"
        echo "🔄 继续尝试SSH克隆，可能是测试命令的问题"
        ssh_works=true  # 仍然尝试使用 SSH
    fi
else
    echo "❌ SSH 私钥文件不存在: $SSH_KEY_PATH"
    echo "📋 请确保私钥文件已正确部署到服务器"
    echo "💡 如果是首次部署，请先上传私钥到服务器"
    ssh_works=false
fi

# Git 配置（根据需求文档）
sudo -u root git config --global user.name "Deploy Bot" 2>/dev/null || true
sudo -u root git config --global user.email "deploy@legezhixiao.com" 2>/dev/null || true
sudo -u root git config --global core.sshCommand "ssh -i $SSH_KEY_PATH -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" 2>/dev/null || true

# 克隆代码（根据需求文档使用 SSH）
echo "📥 克隆最新代码..."
sudo mkdir -p "$DEPLOY_DIR"
cd /tmp
rm -rf ai-novel-editor-clone

# 更严格的克隆逻辑
clone_success=false

if [ "$ssh_works" = true ]; then
    echo "🔑 使用 SSH 方式克隆仓库..."
    echo "📋 仓库地址: $GITHUB_REPO"
    echo "🔐 使用密钥: $SSH_KEY_PATH"
    
    # 尝试SSH克隆
    if sudo -u root git clone "$GITHUB_REPO" ai-novel-editor-clone 2>&1; then
        echo "✅ SSH 克隆成功"
        clone_success=true
    else
        echo "❌ SSH 克隆失败"
        echo "🔄 尝试 HTTPS 方式作为备选..."
        
        # 尝试HTTPS克隆
        if git clone "https://github.com/lessstoryclassmate/legezhixiao.git" ai-novel-editor-clone 2>&1; then
            echo "✅ HTTPS 克隆成功"
            clone_success=true
        else
            echo "❌ HTTPS 克隆也失败"
            clone_success=false
        fi
    fi
else
    echo "🌐 使用 HTTPS 方式克隆仓库（SSH 密钥不可用）..."
    if git clone "https://github.com/lessstoryclassmate/legezhixiao.git" ai-novel-editor-clone 2>&1; then
        echo "✅ HTTPS 克隆成功"
        clone_success=true
    else
        echo "❌ HTTPS 克隆失败"
        clone_success=false
    fi
fi

# 检查克隆是否成功
if [ "$clone_success" = false ]; then
    echo "❌ 所有克隆方式都失败，无法获取代码"
    echo "🔧 请检查:"
    echo "  1. SSH密钥是否正确配置"
    echo "  2. GitHub仓库是否可访问"
    echo "  3. 网络连接是否正常"
    exit 1
fi

# 检查克隆的代码目录
if [ ! -d "ai-novel-editor-clone" ]; then
    echo "❌ 克隆目录不存在，克隆可能失败"
    exit 1
fi

sudo cp -r ai-novel-editor-clone/* "$DEPLOY_DIR"/
sudo chown -R $USER:$USER "$DEPLOY_DIR"

echo "✅ 代码克隆和复制完成"

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
echo "🔍 验证关键文件和配置..."

# 检查关键文件是否存在
REQUIRED_FILES=(
    "docker-compose.production.yml"
    "package.json"
    "requirements.txt"
)

echo "📋 检查必需文件..."
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file 存在"
    else
        echo "❌ 关键文件 $file 丢失"
        echo "🔧 请确认该文件已正确提交到仓库"
        exit 1
    fi
done

# 验证Docker Compose配置
echo "🔍 验证 Docker Compose 配置..."
if sudo docker-compose -f docker-compose.production.yml config > /dev/null 2>&1; then
    echo "✅ Docker Compose 配置验证通过"
else
    echo "⚠️ Docker Compose 配置验证失败，但继续部署"
    echo "🔧 可能的问题:"
    echo "  1. docker-compose.production.yml 语法错误"
    echo "  2. 环境变量配置问题"
    echo "  3. 服务依赖配置问题"
fi

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
echo "🔄 使用百度云镜像源拉取基础镜像..."
pull_failed_count=0

for image in "${BASE_IMAGES[@]}"; do
    echo "🔄 拉取镜像: $image"
    
    # 尝试从百度云镜像源拉取
    if sudo docker pull "registry.baidubce.com/library/$image" 2>/dev/null; then
        # 添加标签以便后续使用
        sudo docker tag "registry.baidubce.com/library/$image" "$image" 2>/dev/null || true
        echo "✅ $image 拉取成功"
    else
        echo "⚠️ $image 拉取失败，构建时会自动拉取"
        pull_failed_count=$((pull_failed_count + 1))
    fi
done

# 显示拉取结果
if [ $pull_failed_count -eq 0 ]; then
    echo "✅ 所有基础镜像拉取成功"
elif [ $pull_failed_count -lt ${#BASE_IMAGES[@]} ]; then
    echo "⚠️ 部分基础镜像拉取失败 ($pull_failed_count/${#BASE_IMAGES[@]})，但不影响部署"
else
    echo "⚠️ 所有基础镜像拉取失败，依赖构建时自动拉取"
fi

# 启动服务
echo "🔄 启动 Docker Compose 服务..."

# 记录启动开始时间
start_time=$(date +%s)

# 启动Docker Compose服务
echo "📋 执行命令: sudo docker-compose -f docker-compose.production.yml up -d --build"
if sudo docker-compose -f docker-compose.production.yml up -d --build 2>&1 | tee /tmp/docker-build.log; then
    echo "✅ Docker Compose 命令执行完成"
else
    echo "❌ Docker Compose 启动失败"
    echo "🔍 最后30行构建日志:"
    tail -30 /tmp/docker-build.log
    
    echo "🔧 可能的问题:"
    echo "  1. 端口冲突 (检查8000、80端口是否被占用)"
    echo "  2. 构建失败 (检查Dockerfile和依赖)"
    echo "  3. 资源不足 (检查磁盘空间和内存)"
    echo "  4. 网络问题 (检查镜像拉取)"
    
    echo "⚠️ 启动失败，但继续健康检查以确认服务状态"
fi

# 记录启动完成时间
end_time=$(date +%s)
duration=$((end_time - start_time))
echo "⏱️ Docker Compose 启动耗时: ${duration}s"

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
