#!/bin/bash

echo "🚀 直接在服务器上安装Docker和Docker Compose"
echo "=================================================="

# 检查是否以root权限运行
if [ "$EUID" -ne 0 ]; then
  echo "⚠️ 建议以root权限运行此脚本: sudo bash $0"
  echo "继续以当前用户权限执行..."
fi

# 系统信息
echo "🔍 系统信息:"
echo "操作系统: $(lsb_release -d | cut -f2)"
echo "内核版本: $(uname -r)"
echo "架构: $(uname -m)"

# 更新系统包
echo ""
echo "📦 更新系统包..."
sudo apt-get update

# 安装必要的依赖包
echo ""
echo "🔧 安装必要的依赖包..."
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common

# 检查Docker是否已安装
echo ""
echo "🐳 检查Docker安装状态..."
if command -v docker &> /dev/null; then
    echo "✅ Docker已安装: $(docker --version)"
    
    # 检查Docker服务状态
        echo "请确保 Docker 已经启动。建议使用 Docker Compose 管理所有服务。"

# 检查Docker Compose是否已安装
echo ""
echo "🐙 检查Docker Compose安装状态..."
if command -v docker-compose &> /dev/null; then
    echo "✅ Docker Compose已安装: $(docker-compose --version)"
else
    echo "❌ Docker Compose未安装，开始安装..."
echo "Docker服务状态: '未知' (已移除 systemctl 检查，请用 docker info 检查状态)"
    # 获取最新版本号
    echo "🔍 获取Docker Compose最新版本..."
    DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
    echo "📋 最新版本: $DOCKER_COMPOSE_VERSION"
    
    # 下载Docker Compose
    echo "⬬ 下载Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    
    # 添加执行权限
    sudo chmod +x /usr/local/bin/docker-compose
    
    # 创建符号链接到/usr/bin
    sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    
    echo "✅ Docker Compose安装完成: $(docker-compose --version)"
fi

# 配置用户权限
echo ""
echo "👤 配置用户权限..."
CURRENT_USER=$(whoami)
if groups $CURRENT_USER | grep -q docker; then
    echo "✅ 用户 $CURRENT_USER 已在docker组中"
else
    echo "🔧 将用户 $CURRENT_USER 添加到docker组..."
    sudo usermod -aG docker $CURRENT_USER
    echo "✅ 用户已添加到docker组"
    echo "⚠️ 请重新登录或运行 'newgrp docker' 使权限生效"
fi

# 测试Docker命令
echo ""
echo "🧪 测试Docker命令..."
if sudo docker run --rm hello-world > /dev/null 2>&1; then
    echo "✅ Docker命令测试成功"
    
    # 清理测试镜像
    sudo docker rmi hello-world &> /dev/null || true
else
    echo "❌ Docker命令测试失败"
    echo "请检查Docker安装和服务状态"
fi

# 测试Docker Compose命令
echo ""
echo "🧪 测试Docker Compose命令..."
if docker-compose --version &> /dev/null; then
    echo "✅ Docker Compose命令测试成功"
else
    echo "❌ Docker Compose命令测试失败"
fi

# 显示系统信息
echo ""
echo "📊 安装完成后的系统状态:"
echo "Docker版本: $(docker --version 2>/dev/null || echo '未安装')"
echo "Docker Compose版本: $(docker-compose --version 2>/dev/null || echo '未安装')"
echo "Docker服务状态: $(docker info >/dev/null 2>&1 && echo '运行中' || echo '未知')"
echo "当前用户: $CURRENT_USER"
echo "用户组: $(groups $CURRENT_USER)"

# 提供后续操作建议
echo ""
echo "🎯 后续操作建议:"
echo "1. 如果是首次安装，请重新登录终端使docker组权限生效"
echo "2. 或者运行: newgrp docker"
echo "3. 测试权限: docker ps"
echo "4. 现在可以运行AI小说编辑器的部署脚本了"

echo ""
echo "✅ Docker和Docker Compose安装配置完成！"

