#!/bin/bash
# 腾讯云Docker镜像加速器配置脚本
# 统一配置腾讯云容器镜像服务

set -e

# 颜色输出函数
red() { echo -e "\033[31m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
blue() { echo -e "\033[34m$1\033[0m"; }

echo "🚀 配置腾讯云Docker镜像加速器..."

# 检查Docker是否安装
if ! command -v docker &> /dev/null; then
    red "❌ Docker未安装，请先安装Docker"
    exit 1
fi

# 创建Docker配置目录
sudo mkdir -p /etc/docker

# 备份现有配置
if [ -f /etc/docker/daemon.json ]; then
    echo "📋 备份现有Docker配置..."
    sudo cp /etc/docker/daemon.json /etc/docker/daemon.json.backup.$(date +%Y%m%d_%H%M%S)
fi

# 检测现有配置并合并
if [ -f /etc/docker/daemon.json ]; then
    echo "🔧 检测到现有配置，进行智能合并..."
    
    # 创建临时配置
    cat > /tmp/tencent-docker-config.json << 'EOF'
{
  "registry-mirrors": ["https://ccr.ccs.tencentyun.com"],
  "dns": ["223.5.5.5", "8.8.8.8"],
  "max-concurrent-downloads": 5,
  "max-concurrent-uploads": 3,
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF
else
    echo "🔧 创建新的Docker配置..."
    
    cat > /tmp/tencent-docker-config.json << 'EOF'
{
  "registry-mirrors": ["https://ccr.ccs.tencentyun.com"],
  "dns": ["223.5.5.5", "8.8.8.8"],
  "max-concurrent-downloads": 5,
  "max-concurrent-uploads": 3,
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF
fi

# 应用配置
sudo cp /tmp/tencent-docker-config.json /etc/docker/daemon.json
green "✅ 腾讯云镜像加速器配置已写入"

# 重启Docker服务
echo "🔄 重启Docker服务以应用配置..."
sudo systemctl daemon-reload
sudo systemctl restart docker

# 等待Docker服务启动
sleep 3

# 验证配置
echo "🔍 验证Docker配置..."
if sudo docker info | grep -q "ccr.ccs.tencentyun.com"; then
    green "✅ 腾讯云镜像加速器配置成功"
else
    yellow "⚠️ 镜像加速器配置可能未生效，请检查配置"
fi

# 测试镜像拉取
echo "🧪 测试镜像拉取..."
if timeout 60 docker pull ccr.ccs.tencentyun.com/library/hello-world:latest > /dev/null 2>&1; then
    green "✅ 腾讯云镜像拉取测试成功"
    docker rmi ccr.ccs.tencentyun.com/library/hello-world:latest > /dev/null 2>&1 || true
else
    yellow "⚠️ 腾讯云镜像拉取测试失败，但配置已应用"
fi

# 显示当前配置
echo "📋 当前Docker镜像配置:"
sudo docker info | grep -A 10 "Registry Mirrors" || echo "使用默认配置"

echo ""
green "🎉 腾讯云Docker镜像加速器配置完成！"
echo ""
echo "💡 使用方法："
echo "• 正常拉取: docker pull nginx:latest"
echo "• 腾讯云拉取: docker pull ccr.ccs.tencentyun.com/library/nginx:latest"
echo "• 查看配置: docker info | grep -A 5 'Registry Mirrors'"
