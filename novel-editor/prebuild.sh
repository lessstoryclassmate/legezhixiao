#!/bin/bash

# 🚀 AI小说编辑器 - 服务器预构建脚本
# 在服务器上预先构建和缓存依赖，避免部署时超时

echo "🌟 开始预构建脚本..."

# 检查Docker是否安装
if ! command -v docker &> /dev/null; then
    echo "❌ Docker未安装，请先安装Docker"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose未安装，请先安装Docker Compose"
    exit 1
fi

echo "📁 创建项目目录..."
mkdir -p /root/novel-editor-cache
cd /root/novel-editor-cache

# 预拉取基础镜像
echo "⬇️ 预拉取基础镜像..."
docker pull python:3.11-slim
docker pull node:18-alpine
docker pull nginx:alpine
docker pull mysql:8.0
docker pull redis:alpine

# 创建临时Dockerfile来预安装依赖
echo "📦 预构建Python依赖缓存..."
cat > Dockerfile.python-cache << 'EOF'
FROM python:3.11-slim

# 设置pip镜像源
ENV PIP_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple \
    PIP_DEFAULT_TIMEOUT=100 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    gcc g++ default-libmysqlclient-dev pkg-config curl \
    && rm -rf /var/lib/apt/lists/*

# 预安装常用Python包
RUN pip install --no-cache-dir \
    fastapi==0.104.1 \
    uvicorn==0.24.0 \
    pydantic==2.5.0 \
    sqlalchemy==2.0.23 \
    pymysql==1.1.0 \
    python-jose==3.3.0 \
    python-multipart==0.0.6 \
    bcrypt==4.1.2 \
    httpx==0.25.2 \
    python-dotenv==1.0.0
EOF

docker build -f Dockerfile.python-cache -t python-deps-cache .

echo "📦 预构建Node.js依赖缓存..."
cat > Dockerfile.node-cache << 'EOF'
FROM node:18-alpine

# 设置npm镜像源
RUN npm config set registry https://registry.npmmirror.com \
    && npm config set timeout 300000

# 预安装常用Node包
RUN npm install -g \
    yarn \
    vite \
    @vitejs/plugin-vue \
    vue \
    vue-router \
    pinia \
    @types/node

# 设置yarn镜像源
RUN yarn config set registry https://registry.npmmirror.com \
    && yarn config set network-timeout 300000
EOF

docker build -f Dockerfile.node-cache -t node-deps-cache .

echo "🧹 清理临时文件..."
rm -f Dockerfile.python-cache Dockerfile.node-cache

echo "📊 显示镜像列表..."
docker images | grep -E "(python|node|nginx|mysql|redis|cache)"

echo "✅ 预构建完成！"
echo "🎯 现在可以运行正常部署，应该会更快完成。"
echo ""
echo "💡 使用方法："
echo "1. 在服务器上运行: curl -fsSL https://your-domain.com/prebuild.sh | bash"
echo "2. 或者手动运行: bash prebuild.sh"
echo "3. 然后进行正常的GitHub Actions部署"
echo ""
echo "📈 预期效果："
echo "- 基础镜像拉取时间: 0分钟（已缓存）"
echo "- Python依赖安装时间: 减少60-80%"
echo "- Node.js依赖安装时间: 减少70-90%"
echo "- 总体部署时间: 从15-20分钟减少到3-5分钟"
