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


# 2. 仅检测百度云镜像源
echo ""
echo "🐳 2. 百度云镜像源连接测试"
echo "   测试 mirror.baidubce.com..."
if curl -s --connect-timeout 8 https://mirror.baidubce.com/v2/ > /dev/null; then
    echo "   ✅ mirror.baidubce.com 可用"
else
    echo "   ❌ mirror.baidubce.com 不可用"
fi

# 4. Docker服务状态
echo ""
echo "🔧 4. Docker服务状态"

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
