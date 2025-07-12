#!/bin/bash

# Docker 镜像加速器配置和预下载脚本
# 用于解决 Docker 镜像拉取超时问题

set -e

echo "🚀 开始配置 Docker 镜像加速器..."

# 检查 Docker 是否安装
if ! command -v docker &> /dev/null; then
    echo "❌ Docker 未安装，请先安装 Docker"
    exit 1
fi

# 检查 Docker 服务状态
if ! sudo systemctl is-active --quiet docker; then
    echo "🔄 启动 Docker 服务..."
    sudo systemctl start docker
    sleep 5
fi

echo "✅ Docker 服务正在运行"

# 备份现有配置
if [ -f "/etc/docker/daemon.json" ]; then
    echo "📦 备份现有 Docker 配置..."
    sudo cp /etc/docker/daemon.json "/etc/docker/daemon.json.backup.$(date +%s)"
    echo "✅ 备份完成"
fi

# 创建 Docker 配置目录
sudo mkdir -p /etc/docker

# 配置镜像加速器，优先使用官方源
echo "🔧 配置 Docker 镜像加速器..."
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "registry-mirrors": [
    "https://registry-1.docker.io",
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com",
    "https://mirror.ccs.tencentyun.com",
    "https://registry.docker-cn.com",
    "https://dockerhub.azk8s.cn"
  ],
  "max-concurrent-downloads": 10,
  "max-concurrent-uploads": 5,
  "log-driver": "json-file",
  "log-level": "warn",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ],
  "dns": ["8.8.8.8", "114.114.114.114"],
  "insecure-registries": [],
  "live-restore": true,
  "userland-proxy": false,
  "experimental": false
}
EOF

echo "✅ Docker 配置文件已更新"

# 重启 Docker 服务
echo "🔄 重启 Docker 服务以应用配置..."
sudo systemctl daemon-reload
sudo systemctl restart docker

# 等待服务启动
echo "⏳ 等待 Docker 服务启动..."
sleep 15

# 验证服务状态
if sudo systemctl is-active --quiet docker; then
    echo "✅ Docker 服务重启成功"
else
    echo "❌ Docker 服务重启失败"
    sudo systemctl status docker --no-pager
    exit 1
fi

# 验证镜像加速器配置
echo "🔍 验证镜像加速器配置..."
if docker info | grep -A 20 "Registry Mirrors"; then
    echo "✅ 镜像加速器配置成功"
    echo "📋 配置的镜像源："
    docker info | grep -A 20 "Registry Mirrors"
else
    echo "⚠️ 未检测到镜像加速器配置"
    echo "📋 当前 Docker 配置："
    sudo cat /etc/docker/daemon.json
fi

# 测试网络连通性
echo "🔍 测试网络连通性..."

# 测试官方 Docker Hub
echo "🌐 测试官方 Docker Hub..."
if timeout 30 curl -I https://registry-1.docker.io/v2/ 2>/dev/null; then
    echo "✅ 官方 Docker Hub 连通正常"
else
    echo "⚠️ 官方 Docker Hub 连通异常"
fi

# 测试国内镜像源
MIRRORS=(
    "https://docker.mirrors.ustc.edu.cn/v2/"
    "https://hub-mirror.c.163.com/v2/"
)

for mirror in "${MIRRORS[@]}"; do
    echo "🌐 测试镜像源: $mirror"
    if timeout 15 curl -I "$mirror" 2>/dev/null; then
        echo "✅ 镜像源连通正常: $mirror"
    else
        echo "⚠️ 镜像源连通异常: $mirror"
    fi
done

# 预下载常用基础镜像
echo "📦 开始预下载常用基础镜像..."

PRELOAD_IMAGES=(
    "hello-world:latest"
    "alpine:latest"
    "ubuntu:20.04"
    "node:18-alpine"
    "python:3.11-slim"
    "nginx:alpine"
    "redis:alpine"
)

successful_downloads=0
total_images=${#PRELOAD_IMAGES[@]}

for image in "${PRELOAD_IMAGES[@]}"; do
    echo "📦 正在下载镜像: $image"
    
    # 使用超时和重试机制
    if timeout 300 docker pull "$image"; then
        echo "✅ 成功下载: $image"
        ((successful_downloads++))
    else
        echo "❌ 下载失败: $image"
        
        # 尝试清理可能的损坏状态
        docker rmi "$image" 2>/dev/null || true
        
        # 重试一次
        echo "🔄 重试下载: $image"
        if timeout 300 docker pull "$image"; then
            echo "✅ 重试成功: $image"
            ((successful_downloads++))
        else
            echo "❌ 重试仍失败: $image"
        fi
    fi
done

echo "📊 镜像下载结果: $successful_downloads/$total_images 成功"

# 测试镜像拉取功能
echo "🔍 最终测试镜像拉取功能..."
if timeout 120 docker pull hello-world:latest; then
    echo "✅ 镜像拉取功能测试成功"
    
    # 运行测试容器
    if docker run --rm hello-world > /dev/null 2>&1; then
        echo "✅ 容器运行测试成功"
    else
        echo "⚠️ 容器运行测试失败"
    fi
else
    echo "❌ 镜像拉取功能测试失败"
fi

# 显示系统信息
echo "📋 Docker 系统信息："
docker system info | grep -E "(Registry|Storage|Runtime|Kernel)" || true

# 显示已下载的镜像
echo "📋 当前已下载的镜像："
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | head -20

# 显示磁盘使用情况
echo "📋 Docker 磁盘使用情况："
docker system df

echo "🎉 Docker 镜像加速器配置和预下载完成！"
echo ""
echo "📝 使用说明："
echo "1. Docker 已配置多个镜像源，优先使用官方源"
echo "2. 已预下载常用基础镜像，减少构建时间"
echo "3. 如遇到拉取问题，可重新运行此脚本"
echo ""
echo "🔧 故障排除："
echo "- 查看 Docker 状态: sudo systemctl status docker"
echo "- 查看 Docker 配置: sudo cat /etc/docker/daemon.json"
echo "- 查看 Docker 信息: docker info"
echo "- 重启 Docker: sudo systemctl restart docker"
