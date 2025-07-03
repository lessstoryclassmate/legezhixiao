#!/bin/bash

# 🐳 Docker引擎版本更新脚本
# 用于解决Docker语法兼容性问题

set -e

echo "🔍 检查当前Docker版本..."
docker --version || echo "Docker未安装或无法运行"
docker-compose --version || echo "Docker Compose未安装或无法运行"

echo ""
echo "📋 当前系统信息:"
cat /etc/os-release | grep -E "^(NAME|VERSION)="
uname -a

echo ""
echo "🛑 停止当前Docker服务..."
sudo systemctl stop docker || true

echo ""
echo "🗑️ 移除旧版本Docker..."
sudo apt-get remove -y docker docker-engine docker.io containerd runc || true
sudo apt-get remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || true

echo ""
echo "🧹 清理Docker数据（可选，谨慎操作）..."
read -p "是否清理所有Docker数据？这将删除所有容器、镜像、卷和网络 (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo rm -rf /var/lib/docker
    sudo rm -rf /var/lib/containerd
    echo "✅ Docker数据已清理"
else
    echo "⏭️ 跳过数据清理"
fi

echo ""
echo "📦 更新软件包列表..."
sudo apt-get update

echo ""
echo "📋 安装必要的依赖..."
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

echo ""
echo "🔑 添加Docker官方GPG密钥..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo ""
echo "📋 添加Docker官方APT源..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo ""
echo "🔄 更新软件包列表..."
sudo apt-get update

echo ""
echo "📋 检查可用的Docker版本..."
apt-cache madison docker-ce | head -5

echo ""
echo "🚀 安装最新版本的Docker..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo ""
echo "🔧 启动并启用Docker服务..."
sudo systemctl start docker
sudo systemctl enable docker

echo ""
echo "👥 将当前用户添加到docker组..."
sudo usermod -aG docker $USER

echo ""
echo "✅ 验证Docker安装..."
sudo docker --version
sudo docker compose version

echo ""
echo "🧪 测试Docker运行..."
sudo docker run --rm hello-world

echo ""
echo "🎉 Docker更新完成！"
echo ""
echo "📋 新版本信息:"
echo "Docker Engine: $(sudo docker --version)"
echo "Docker Compose: $(sudo docker compose version)"
echo ""
echo "⚠️  注意："
echo "1. 请重新登录以使docker组权限生效"
echo "2. 或者运行: newgrp docker"
echo "3. 然后就可以不用sudo运行docker命令了"
echo ""
echo "🚀 现在可以重新尝试部署了！"
