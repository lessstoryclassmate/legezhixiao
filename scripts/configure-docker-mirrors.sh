#!/bin/bash

# Docker 镜像加速器配置脚本
# 用于解决 Docker Hub 镜像拉取超时问题

set -e

echo "🔧 配置 Docker 镜像加速器..."

# 检查是否为 root 用户或有 sudo 权限
if [ "$EUID" -ne 0 ] && ! sudo -n true 2>/dev/null; then
  echo "❌ 需要 root 权限或 sudo 权限来配置 Docker"
  exit 1
fi

# 确保 Docker 已安装
if ! command -v docker &> /dev/null; then
  echo "❌ Docker 未安装，请先安装 Docker"
  exit 1
fi

# 创建 Docker 配置目录
echo "📁 创建 Docker 配置目录..."
sudo mkdir -p /etc/docker

# 备份现有配置
if [ -f "/etc/docker/daemon.json" ]; then
  echo "📦 备份现有 Docker 配置..."
  sudo cp /etc/docker/daemon.json /etc/docker/daemon.json.backup.$(date +%Y%m%d_%H%M%S)
fi

# 创建镜像加速器配置
echo "⚙️ 创建镜像加速器配置..."
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "registry-mirrors": [
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
  "live-restore": true,
  "userland-proxy": false,
  "experimental": false,
  "metrics-addr": "127.0.0.1:9323",
  "default-shm-size": "128M"
}
EOF

echo "✅ 镜像加速器配置文件创建完成"

# 重新加载 systemd 配置
echo "🔄 重新加载 systemd 配置..."
sudo systemctl daemon-reload

# 重启 Docker 服务
echo "🔄 重启 Docker 服务..."
sudo systemctl restart docker

# 等待 Docker 服务启动
echo "⏳ 等待 Docker 服务启动..."
sleep 5

# 验证 Docker 服务状态
echo "🔍 验证 Docker 服务状态..."
if sudo systemctl is-active --quiet docker; then
  echo "✅ Docker 服务正在运行"
else
  echo "❌ Docker 服务启动失败"
  sudo systemctl status docker
  exit 1
fi

# 验证镜像加速器配置
echo "🔍 验证镜像加速器配置..."
if docker info 2>/dev/null | grep -A 10 "Registry Mirrors" | grep -q "ustc.edu.cn"; then
  echo "✅ 镜像加速器配置成功"
  echo "📋 当前配置的镜像加速器："
  docker info 2>/dev/null | grep -A 10 "Registry Mirrors" | sed 's/^/ /'
else
  echo "⚠️ 镜像加速器配置可能未生效"
  echo "📋 当前 Docker 信息："
  docker info 2>/dev/null | grep -A 5 "Registry" || echo "未找到镜像加速器信息"
fi

# 测试镜像拉取
echo "🔍 测试镜像拉取..."
if timeout 120 docker pull alpine:latest; then
  echo "✅ 镜像拉取测试成功"
  docker rmi alpine:latest 2>/dev/null || true
else
  echo "❌ 镜像拉取测试失败"
  echo "可能的原因："
  echo "1. 网络连接问题"
  echo "2. 镜像加速器服务不可用"
  echo "3. Docker 配置问题"
fi

echo "🎉 Docker 镜像加速器配置完成！"
echo ""
echo "📋 使用说明："
echo "- 重启 Docker 服务：sudo systemctl restart docker"
echo "- 查看配置：docker info | grep -A 10 'Registry Mirrors'"
echo "- 测试拉取：docker pull hello-world"
echo ""
echo "📋 镜像加速器列表："
echo "- 中科大镜像：https://docker.mirrors.ustc.edu.cn"
echo "- 网易镜像：https://hub-mirror.c.163.com"
echo "- 腾讯云镜像：https://mirror.ccs.tencentyun.com"
echo "- Docker 中国镜像：https://registry.docker-cn.com"
echo "- Azure 中国镜像：https://dockerhub.azk8s.cn"
