#!/bin/bash
# 快速部署脚本 - 克隆模式生产环境部署
# 用于GitHub Actions自动部署

set -e

echo "🚀 开始快速部署 AI 小说编辑器..."

# 定义变量
PROJECT_NAME="ai-novel-editor"
DEPLOY_DIR="/opt/ai-novel-editor"
GITHUB_REPO="https://github.com/${GITHUB_REPOSITORY}.git"

# 0. 配置Docker镜像加速器和网络优化
echo "🐳 配置Docker镜像加速器和网络优化..."
sudo mkdir -p /etc/docker

# 检测地区并配置相应的镜像源
echo "🔍 检测 Docker Hub 连接性..."
if curl -s --connect-timeout 5 --max-time 10 https://registry-1.docker.io/v2/ > /dev/null 2>&1; then
    echo "✅ Docker Hub 可直接访问，配置加速器以提高速度"
    # 即使可访问也配置加速器以提高速度和稳定性
    MIRRORS='"https://docker.mirrors.ustc.edu.cn", "https://registry.docker-cn.com", "https://hub-mirror.c.163.com"'
else
    echo "⚠️  Docker Hub 访问受限，配置多个镜像源..."
    # 配置多个国内镜像源，提高成功率
    MIRRORS='"https://docker.mirrors.ustc.edu.cn", "https://hub-mirror.c.163.com", "https://registry.cn-hangzhou.aliyuncs.com", "https://registry.docker-cn.com", "https://dockerproxy.com", "https://mirror.baidubce.com"'
fi

sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "registry-mirrors": [
    ${MIRRORS}
  ],
  "max-concurrent-downloads": 10,
  "max-concurrent-uploads": 5,
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "experimental": false,
  "features": {
    "buildkit": true
  }
}
EOF

# 重启Docker服务
echo "🔄 重启Docker服务..."
sudo systemctl daemon-reload
sudo systemctl restart docker

# 等待Docker服务完全启动
sleep 5

# 验证Docker是否正常工作
echo "🔍 验证Docker服务状态..."
if ! sudo docker info > /dev/null 2>&1; then
    echo "❌ Docker服务启动失败"
    exit 1
fi

echo "✅ Docker服务配置完成"

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
SERVER_IP=${SERVER_IP:-106.13.216.179}

# MongoDB 配置 (云数据库)
MONGODB_HOST=${MONGODB_HOST:-mongodb-server}
MONGODB_PORT=${MONGODB_PORT:-27017}
MONGODB_DATABASE=${MONGODB_DATABASE:-ai_novel_db}

# 系统数据库配置 - 使用实际配置
DATABASE_PORT=${DATABASE_PORT:-3306}
DATABASE_SYSTEMHOST=${DATABASE_SYSTEMHOST:-172.16.16.3}
DATABASE_SYSTEM=${DATABASE_SYSTEM:-novel_data}
DATABASE_USER=${DATABASE_USER:-lkr}
DATABASE_PASSWORD=${DATABASE_PASSWORD:-Lekairong350702}

# 用户数据库配置 - 使用实际配置
DATABASE_NOVELHOST=${DATABASE_NOVELHOST:-172.16.16.2}
DATABASE_NOVELDATA=${DATABASE_NOVELDATA:-novel_user_data}
DATABASE_NOVELUSER=${DATABASE_NOVELUSER:-novel_data_user}
DATABASE_NOVELUSER_PASSWORD=${DATABASE_NOVELUSER_PASSWORD:-Lekairong350702}

# Redis 配置 (云数据库)
REDIS_HOST=${REDIS_HOST:-redis-server}
REDIS_PORT=${REDIS_PORT:-6379}
REDIS_PASSWORD=${REDIS_PASSWORD:-Lekairong350702}

# SiliconFlow API 配置 - 使用实际配置
SILICONFLOW_API_KEY=${SILICONFLOW_API_KEY:-sk-mjithqmjwccqgffouexthbavtnvftwkqjludpcxhrmeztcib}
SILICONFLOW_DEFAULT_MODEL=${SILICONFLOW_DEFAULT_MODEL:-deepseek-ai/DeepSeek-V3}
SILICONFLOW_API_URL=${SILICONFLOW_API_URL:-https://api.siliconflow.cn/v1/chat/completions}

# JWT 配置
JWT_SECRET_KEY=${JWT_SECRET_KEY:-your-secret-key-change-this}

# MCP 配置 - 使用实际配置
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

# 5. 检查配置文件语法
echo "🔍 验证配置文件..."
if ! sudo docker-compose -f docker-compose.production.yml config > /dev/null; then
    echo "❌ Docker Compose配置语法错误"
    exit 1
fi

# 6. 预拉取基础镜像 (使用强化重试机制)
echo "📦 预拉取基础镜像..."

# 定义所需的基础镜像
BASE_IMAGES=(
    "node:18-alpine"
    "python:3.11-slim"
    "nginx:alpine"
)

# 拉取基础镜像的函数
pull_image_with_retry() {
    local image=$1
    local max_attempts=3
    
    echo "🔄 拉取镜像: $image"
    
    for attempt in $(seq 1 $max_attempts); do
        echo "   尝试 $attempt/$max_attempts..."
        
        if timeout 300 sudo docker pull "$image"; then
            echo "   ✅ $image 拉取成功"
            return 0
        else
            echo "   ❌ $image 拉取失败"
            if [ $attempt -lt $max_attempts ]; then
                local wait_time=$((attempt * 5))
                echo "   ⏳ 等待 ${wait_time}s 后重试..."
                sleep $wait_time
                
                # 清理可能的残留下载
                sudo docker system prune -f > /dev/null 2>&1 || true
            fi
        fi
    done
    
    echo "   ❌ $image 拉取失败"
    return 1
}

# 预拉取所有基础镜像
failed_images=()
for image in "${BASE_IMAGES[@]}"; do
    if ! pull_image_with_retry "$image"; then
        failed_images+=("$image")
    fi
done

# 如果有镜像拉取失败，尝试直接使用 docker-compose 构建
if [ ${#failed_images[@]} -gt 0 ]; then
    echo "⚠️  以下镜像拉取失败: ${failed_images[*]}"
    echo "🔄 将在构建阶段处理镜像问题..."
else
    echo "✅ 所有基础镜像拉取成功"
    # 现在拉取应用镜像
    sudo docker-compose -f docker-compose.production.yml pull --ignore-pull-failures || echo "⚠️  应用镜像拉取失败，将使用构建模式"
fi

# 7. 构建并启动服务 (增强错误处理)
echo "🏗️  构建并启动服务..."

# 尝试不同的构建策略
echo "🔄 尝试标准构建模式..."
if sudo docker-compose -f docker-compose.production.yml up -d --build; then
    echo "✅ 标准构建成功"
else
    echo "❌ 标准构建失败，尝试单独构建..."
    
    # 尝试分别构建每个服务
    echo "🔄 分别构建各个服务..."
    
    # 构建后端
    echo "  📦 构建后端服务..."
    if ! sudo docker-compose -f docker-compose.production.yml build backend; then
        echo "  ❌ 后端构建失败"
        # 检查是否可以使用预构建镜像
        echo "  🔄 尝试使用无缓存构建..."
        sudo docker-compose -f docker-compose.production.yml build --no-cache backend || {
            echo "  ❌ 后端无缓存构建也失败"
            exit 1
        }
    fi
    
    # 构建前端
    echo "  🎨 构建前端服务..."
    if ! sudo docker-compose -f docker-compose.production.yml build frontend; then
        echo "  ❌ 前端构建失败"
        echo "  🔄 尝试使用无缓存构建..."
        sudo docker-compose -f docker-compose.production.yml build --no-cache frontend || {
            echo "  ❌ 前端无缓存构建也失败"
            exit 1
        }
    fi
    
    # 启动所有服务
    echo "  🚀 启动所有服务..."
    sudo docker-compose -f docker-compose.production.yml up -d || {
        echo "❌ 服务启动失败"
        echo "📋 检查服务状态："
        sudo docker-compose -f docker-compose.production.yml ps
        echo "📋 检查服务日志："
        sudo docker-compose -f docker-compose.production.yml logs --tail=50
        exit 1
    }
fi

echo "✅ 服务构建和启动完成"

# 8. 等待服务启动并验证
echo "⏳ 等待服务启动..."

# 等待容器启动
sleep 15

# 检查容器状态
echo "📊 检查容器状态..."
if ! sudo docker-compose -f docker-compose.production.yml ps | grep -q "Up"; then
    echo "⚠️  部分容器可能未正常启动"
    echo "📋 容器状态详情："
    sudo docker-compose -f docker-compose.production.yml ps
    echo "📋 容器日志："
    sudo docker-compose -f docker-compose.production.yml logs --tail=20
fi

# 分阶段健康检查
echo "🏥 执行健康检查..."

# 1. 检查后端服务
echo "  🔍 检查后端服务..."
backend_healthy=false
for i in {1..12}; do
    if curl -f -s http://localhost:8000/health > /dev/null 2>&1; then
        echo "  ✅ 后端服务健康检查通过"
        backend_healthy=true
        break
    else
        echo "  ⏳ 后端服务启动中... ($i/12)"
        sleep 10
    fi
done

if [ "$backend_healthy" = false ]; then
    echo "  ❌ 后端服务健康检查失败"
    echo "  📋 后端服务日志："
    sudo docker-compose -f docker-compose.production.yml logs backend --tail=30
fi

# 2. 检查前端服务
echo "  🔍 检查前端服务..."
frontend_healthy=false
for i in {1..6}; do
    if curl -f -s http://localhost:80 > /dev/null 2>&1; then
        echo "  ✅ 前端服务健康检查通过"
        frontend_healthy=true
        break
    else
        echo "  ⏳ 前端服务启动中... ($i/6)"
        sleep 5
    fi
done

if [ "$frontend_healthy" = false ]; then
    echo "  ⚠️  前端服务可能未完全启动"
    echo "  📋 前端服务日志："
    sudo docker-compose -f docker-compose.production.yml logs frontend --tail=20
fi

# 9. 显示最终服务状态
echo ""
echo "📊 最终服务状态:"
sudo docker-compose -f docker-compose.production.yml ps

# 检查是否有失败的服务
if sudo docker-compose -f docker-compose.production.yml ps | grep -q "Exit"; then
    echo ""
    echo "❌ 发现失败的服务，显示详细日志："
    sudo docker-compose -f docker-compose.production.yml logs --tail=50
    exit 1
fi

# 10. 显示部署信息
echo ""
if [ "$backend_healthy" = true ] && [ "$frontend_healthy" = true ]; then
    echo "🎉 部署完成且服务正常!"
elif [ "$backend_healthy" = true ]; then
    echo "🎯 部署完成! (后端正常，前端可能需要更多启动时间)"
else
    echo "⚠️  部署完成但服务可能存在问题，请检查日志"
fi

echo ""
echo "📍 访问地址:"
echo "  - 前端: http://${SERVER_IP:-106.13.216.179}"
echo "  - API: http://${SERVER_IP:-106.13.216.179}:8000"
echo "  - 健康检查: http://${SERVER_IP:-106.13.216.179}:8000/health"
echo ""
echo "📝 有用的命令:"
echo "  查看日志: sudo docker-compose -f $DEPLOY_DIR/docker-compose.production.yml logs -f"
echo "  重启服务: sudo docker-compose -f $DEPLOY_DIR/docker-compose.production.yml restart"
echo "  停止服务: sudo docker-compose -f $DEPLOY_DIR/docker-compose.production.yml down"
echo "  查看状态: sudo docker-compose -f $DEPLOY_DIR/docker-compose.production.yml ps"
echo ""
echo "🔧 故障排除:"
echo "  如果服务无法访问，请检查防火墙设置和端口开放情况"
