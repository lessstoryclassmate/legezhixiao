#!/bin/bash
# 网络和Docker连接诊断脚本

echo "🔍 网络和Docker连接诊断..."
echo "================================="

# 1. 基础网络连接测试
echo "📡 1. 基础网络连接测试"
echo "   测试外网连接..."
if ping -c 3 8.8.8.8 > /dev/null 2>&1; then
    echo "   ✅ 外网连接正常"
else
    echo "   ❌ 外网连接失败"
fi

echo "   测试DNS解析..."
if nslookup google.com > /dev/null 2>&1; then
    echo "   ✅ DNS解析正常"
else
    echo "   ❌ DNS解析失败"
fi

# 2. Docker Hub 连接测试
echo ""
echo "🐳 2. Docker Hub 连接测试"
echo "   测试Docker Hub域名解析..."
if nslookup registry-1.docker.io > /dev/null 2>&1; then
    echo "   ✅ Docker Hub域名解析正常"
    
    echo "   测试Docker Hub连接..."
    if curl -s --connect-timeout 10 https://registry-1.docker.io/v2/ > /dev/null; then
        echo "   ✅ Docker Hub连接正常"
    else
        echo "   ❌ Docker Hub连接失败"
    fi
else
    echo "   ❌ Docker Hub域名解析失败"
fi

# 3. 镜像源测试
echo ""
echo "🌐 3. 镜像源连接测试"
MIRRORS=(
    "registry.cn-hangzhou.aliyuncs.com"
    "docker.mirrors.ustc.edu.cn"
    "hub-mirror.c.163.com"
)

for mirror in "${MIRRORS[@]}"; do
    echo "   测试 $mirror..."
    if curl -s --connect-timeout 5 "https://$mirror/v2/" > /dev/null 2>&1; then
        echo "   ✅ $mirror 可用"
    else
        echo "   ❌ $mirror 不可用"
    fi
done

# 4. Docker服务状态
echo ""
echo "🔧 4. Docker服务状态"
if systemctl is-active --quiet docker; then
    echo "   ✅ Docker服务运行中"
    
    echo "   Docker配置："
    if [ -f /etc/docker/daemon.json ]; then
        echo "   当前配置："
        cat /etc/docker/daemon.json | jq . 2>/dev/null || cat /etc/docker/daemon.json
    else
        echo "   使用默认配置"
    fi
else
    echo "   ❌ Docker服务未运行"
fi

# 5. 镜像拉取测试
echo ""
echo "📦 5. 镜像拉取测试"
echo "   测试拉取小镜像..."
if timeout 60 docker pull alpine:latest > /dev/null 2>&1; then
    echo "   ✅ 镜像拉取成功"
    docker image rm alpine:latest > /dev/null 2>&1
else
    echo "   ❌ 镜像拉取失败"
fi

# 6. 系统信息
echo ""
echo "💻 6. 系统信息"
echo "   操作系统: $(lsb_release -d 2>/dev/null | cut -f2 || echo "未知")"
echo "   Docker版本: $(docker --version 2>/dev/null || echo "未安装")"
echo "   内存使用: $(free -h | grep Mem | awk '{print $3"/"$2}')"
echo "   磁盘使用: $(df -h / | tail -1 | awk '{print $5" ("$3"/"$2")"}')"

echo ""
echo "📋 诊断完成"
echo "如果发现问题，请检查网络连接、DNS配置和防火墙设置"
