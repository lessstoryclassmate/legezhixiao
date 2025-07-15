#!/bin/bash
# Docker镜像加速器配置验证和优化脚本

set -e

echo "🔧 Docker镜像加速器配置验证和优化"
echo "=============================="

# 检查当前Docker daemon配置
echo "📋 当前Docker daemon配置："
if [ -f /etc/docker/daemon.json ]; then
    cat /etc/docker/daemon.json
else
    echo "❌ /etc/docker/daemon.json 文件不存在"
fi

echo ""
echo "🔄 优化Docker daemon配置..."

# 创建优化的配置
sudo mkdir -p /etc/docker

# 备份现有配置
if [ -f /etc/docker/daemon.json ]; then
    sudo cp /etc/docker/daemon.json /etc/docker/daemon.json.backup.$(date +%Y%m%d_%H%M%S)
    echo "✅ 已备份现有配置"
fi

# 写入优化的配置
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "registry-mirrors": [
    "https://mirror.ccs.tencentyun.com"
  ],
  "dns": ["119.29.29.29", "223.5.5.5", "8.8.8.8"],
  "max-concurrent-downloads": 10,
  "max-concurrent-uploads": 5,
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "data-root": "/var/lib/docker"
}
EOF

echo "✅ Docker daemon配置已优化"

# 重启Docker服务
echo "🔄 重启Docker服务..."
sudo systemctl restart docker

# 等待Docker服务启动
echo "⏳ 等待Docker服务启动..."
sleep 10

# 验证Docker服务状态
if sudo systemctl is-active --quiet docker; then
    echo "✅ Docker服务运行正常"
else
    echo "❌ Docker服务启动失败"
    sudo systemctl status docker
    exit 1
fi

# 验证镜像加速器
echo "🔍 验证腾讯云镜像加速器..."
if curl -s --connect-timeout 10 https://mirror.ccs.tencentyun.com/v2/ > /dev/null; then
    echo "✅ 腾讯云镜像加速器网络连通性正常"
else
    echo "⚠️ 腾讯云镜像加速器网络连通性异常"
fi

# 测试镜像拉取
echo "🧪 测试镜像拉取（使用官方镜像名 + 镜像加速器）..."

TEST_IMAGES=(
    "hello-world:latest"
    "alpine:latest"
    "nginx:alpine"
)

for image in "${TEST_IMAGES[@]}"; do
    echo "🔄 测试拉取: $image"
    if timeout 60 sudo docker pull "$image" > /dev/null 2>&1; then
        echo "✅ $image 拉取成功"
        sudo docker rmi "$image" > /dev/null 2>&1 || true
    else
        echo "❌ $image 拉取失败"
    fi
done

# 显示Docker信息
echo ""
echo "📊 Docker配置信息："
sudo docker info | grep -A 10 "Registry Mirrors:" || echo "未找到镜像源配置信息"

echo ""
echo "🎉 Docker镜像加速器配置验证完成！"
echo ""
echo "💡 重要提示："
echo "  1. 现在使用官方镜像名（如 node:18-alpine）"
echo "  2. 镜像会自动通过腾讯云加速器下载"
echo "  3. 不要再使用 ccr.ccs.tencentyun.com/library/ 前缀"
echo ""
echo "🔧 使用示例："
echo "  docker pull node:18-alpine    ✅ 正确"
echo "  docker pull python:3.11-slim  ✅ 正确"
echo "  docker pull nginx:alpine       ✅ 正确"
