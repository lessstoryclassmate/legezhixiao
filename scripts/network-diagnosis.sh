#!/bin/bash
# 网络和 Docker 镜像诊断脚本
# 快速排查 DNS、网络连通性和 Docker 镜像拉取问题

set -e

echo "🌐 开始网络和 Docker 镜像诊断..."

# 1. DNS 诊断
echo "================== DNS 诊断 =================="
echo "当前 DNS 配置:"
cat /etc/resolv.conf

echo ""
echo "测试 DNS 解析:"
dns_targets=(
    "mirror.baidubce.com"
    "registry-1.docker.io" 
    "github.com"
    "google.com"
)

for target in "${dns_targets[@]}"; do
    if nslookup "$target" > /dev/null 2>&1; then
        echo "✅ $target - DNS 解析正常"
    else
        echo "❌ $target - DNS 解析失败"
    fi
done

# 2. 网络连通性测试
echo ""
echo "================== 网络连通性测试 =================="
connectivity_targets=(
    "https://mirror.baidubce.com/v2/"
    "https://registry-1.docker.io/v2/"
    "https://github.com"
)

for target in "${connectivity_targets[@]}"; do
    if curl -s --connect-timeout 10 --max-time 15 "$target" > /dev/null 2>&1; then
        echo "✅ $target - 网络连通正常"
    else
        echo "❌ $target - 网络连通失败"
    fi
done

# 3. Docker 配置检查
echo ""
echo "================== Docker 配置检查 =================="
if command -v docker > /dev/null 2>&1; then
    echo "Docker 版本: $(docker --version)"
    
    if [ -f "/etc/docker/daemon.json" ]; then
        echo "Docker daemon.json 配置:"
        cat /etc/docker/daemon.json
    else
        echo "⚠️ Docker daemon.json 不存在"
    fi
    
    echo ""
    echo "Docker 镜像仓库配置:"
    docker info | grep -E "(Registry|Mirrors)" || echo "未配置镜像加速器"
    
else
    echo "❌ Docker 未安装"
fi

# 4. Docker 镜像拉取测试
echo ""
echo "================== Docker 镜像拉取测试 =================="
if command -v docker > /dev/null 2>&1; then
    test_images=(
        "hello-world"
        "alpine:latest"
    )
    
    for image in "${test_images[@]}"; do
        echo "测试拉取镜像: $image"
        if timeout 60 docker pull "$image" > /dev/null 2>&1; then
            echo "✅ $image - 拉取成功"
            docker rmi "$image" > /dev/null 2>&1 || true
        else
            echo "❌ $image - 拉取失败"
        fi
    done
fi

# 5. 端口检查
echo ""
echo "================== 端口检查 =================="
check_ports=(80 443 8000 3306 27017 6379)

for port in "${check_ports[@]}"; do
    if netstat -tlnp | grep ":$port " > /dev/null 2>&1; then
        echo "⚠️ 端口 $port 已被占用"
        netstat -tlnp | grep ":$port "
    else
        echo "✅ 端口 $port 可用"
    fi
done

# 6. 系统信息
echo ""
echo "💻 6. 系统信息"
echo "   操作系统: $(lsb_release -d 2>/dev/null | cut -f2 || echo "未知")"
echo "   Docker版本: $(docker --version 2>/dev/null || echo "未安装")"
echo "   内存使用: $(free -h | grep Mem | awk '{print $3"/"$2}')"
echo "   磁盘使用: $(df -h / | tail -1 | awk '{print $5" ("$3"/"$2")"}')"

# 7. 生成修复建议
echo ""
echo "================== 修复建议 =================="

# DNS 修复建议
if ! nslookup mirror.baidubce.com > /dev/null 2>&1; then
    echo "🔧 DNS 问题修复建议:"
    echo "  sudo bash -c 'echo -e \"nameserver 223.5.5.5\\nnameserver 180.76.76.76\\nnameserver 8.8.8.8\" > /etc/resolv.conf'"
fi

# Docker 镜像配置建议
if ! docker info | grep -q "mirror.baidubce.com" 2>/dev/null; then
    echo "🔧 Docker 镜像加速器配置建议:"
    echo '  sudo mkdir -p /etc/docker'
    echo '  sudo tee /etc/docker/daemon.json > /dev/null <<EOF'
    echo '  {'
    echo '    "registry-mirrors": ["https://mirror.baidubce.com"]'
    echo '  }'
    echo '  EOF'
    echo '  sudo systemctl restart docker'
fi

# 端口冲突解决建议
for port in 80 8000; do
    if netstat -tlnp | grep ":$port " > /dev/null 2>&1; then
        echo "🔧 端口 $port 冲突解决建议:"
        echo "  检查占用进程: sudo lsof -i :$port"
        echo "  停止冲突服务或修改配置使用其他端口"
    fi
done

echo ""
echo "🎯 诊断完成! 请根据上述结果解决相关问题。"
