#!/bin/bash
# Docker 配置优化脚本
# 确保使用腾讯云镜像加速器而非直接访问腾讯云注册表

set -e

echo "🔧 开始 Docker 配置优化..."

# ===== 1. 备份现有配置 =====
if [ -f /etc/docker/daemon.json ]; then
    echo "📋 备份现有 Docker 配置..."
    sudo cp /etc/docker/daemon.json /etc/docker/daemon.json.backup.$(date +%Y%m%d_%H%M%S)
fi

# ===== 2. 创建优化的 Docker 配置 =====
echo "🚀 创建优化的 Docker 配置..."

sudo mkdir -p /etc/docker
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
  "live-restore": true,
  "default-runtime": "runc",
  "insecure-registries": [],
  "debug": false
}
EOF

echo "✅ Docker 配置已优化"

# ===== 3. 验证配置文件 =====
echo "🔍 验证 Docker 配置文件..."
if python3 -m json.tool /etc/docker/daemon.json > /dev/null 2>&1; then
    echo "✅ Docker 配置文件格式正确"
else
    echo "❌ Docker 配置文件格式错误"
    exit 1
fi

# ===== 4. 重启 Docker 服务 =====
echo "🔄 重启 Docker 服务..."
sudo systemctl restart docker

# 等待 Docker 服务完全启动
echo "⏳ 等待 Docker 服务启动..."
sleep 10

# ===== 5. 验证 Docker 服务状态 =====
echo "📊 验证 Docker 服务状态..."
if sudo systemctl is-active docker > /dev/null 2>&1; then
    echo "✅ Docker 服务运行正常"
else
    echo "❌ Docker 服务启动失败"
    sudo systemctl status docker
    exit 1
fi

# ===== 6. 测试镜像加速器 =====
echo "🔍 测试腾讯云镜像加速器..."

# 测试网络连通性
if curl -s --connect-timeout 10 https://mirror.ccs.tencentyun.com/v2/ > /dev/null; then
    echo "✅ 腾讯云镜像加速器网络连通正常"
else
    echo "⚠️ 腾讯云镜像加速器网络连通异常"
fi

# 测试镜像拉取
echo "🔄 测试基础镜像拉取..."
TEST_IMAGES=(
    "hello-world:latest"
    "alpine:latest"
    "nginx:alpine"
)

for image in "${TEST_IMAGES[@]}"; do
    echo "🔄 测试拉取: $image"
    if timeout 60 sudo docker pull "$image" > /dev/null 2>&1; then
        echo "✅ $image 拉取成功"
        # 清理测试镜像
        sudo docker rmi "$image" > /dev/null 2>&1 || true
    else
        echo "❌ $image 拉取失败"
    fi
done

# ===== 7. 显示 Docker 信息 =====
echo "📋 Docker 配置信息:"
echo "----------------------------------------"
sudo docker info | grep -E "(Registry|Mirrors|DNS)" || echo "使用默认配置"

echo ""
echo "📋 当前 Docker 配置文件:"
echo "----------------------------------------"
cat /etc/docker/daemon.json

echo ""
echo "🎉 Docker 配置优化完成！"
echo "✅ 已配置腾讯云镜像加速器: https://mirror.ccs.tencentyun.com"
echo "✅ 已配置腾讯云 DNS: 119.29.29.29"
echo "✅ 已优化并发下载和日志配置"
echo ""
echo "💡 使用提示:"
echo "  - 现在可以直接使用官方镜像名 (如 node:18-alpine)"
echo "  - 镜像会自动通过腾讯云加速器拉取"
echo "  - 不需要使用 ccr.ccs.tencentyun.com/library/ 前缀"
