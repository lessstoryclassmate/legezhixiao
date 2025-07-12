#!/bin/bash

# Docker 网络超时问题修复脚本
# 解决 Docker 镜像拉取超时和网络连接问题

set -e

echo "🔧 开始修复 Docker 网络超时问题..."

# 检查系统信息
echo "📋 系统信息："
echo "操作系统: $(lsb_release -d 2>/dev/null | cut -f2 || uname -a)"
echo "内核版本: $(uname -r)"
echo "网络接口:"
ip addr show | grep -E "inet.*scope global" | awk '{print $2, $NF}' || true

# 检查 Docker 状态
echo "🔍 检查 Docker 状态..."
if command -v docker &> /dev/null; then
    echo "✅ Docker 已安装: $(docker --version)"
    
    if sudo systemctl is-active --quiet docker; then
        echo "✅ Docker 服务正在运行"
    else
        echo "🔄 启动 Docker 服务..."
        sudo systemctl start docker
        sleep 5
    fi
else
    echo "❌ Docker 未安装"
    exit 1
fi

# 备份现有 Docker 配置
echo "📦 备份现有配置..."
if [ -f "/etc/docker/daemon.json" ]; then
    sudo cp /etc/docker/daemon.json "/etc/docker/daemon.json.backup.$(date +%s)"
    echo "✅ 已备份现有配置"
fi

# 优化系统网络参数
echo "🔧 优化系统网络参数..."
sudo sysctl -w net.core.rmem_max=26214400
sudo sysctl -w net.core.rmem_default=26214400
sudo sysctl -w net.core.wmem_max=26214400
sudo sysctl -w net.core.wmem_default=26214400
sudo sysctl -w net.core.netdev_max_backlog=2048
sudo sysctl -w net.ipv4.tcp_rmem="4096 65536 26214400"
sudo sysctl -w net.ipv4.tcp_wmem="4096 65536 26214400"
sudo sysctl -w net.ipv4.tcp_congestion_control=bbr
sudo sysctl -w net.ipv4.tcp_window_scaling=1
echo "✅ 网络参数优化完成"

# 创建优化的 Docker 配置
echo "🔧 创建优化的 Docker 配置..."
sudo mkdir -p /etc/docker
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
  "max-concurrent-downloads": 6,
  "max-concurrent-uploads": 3,
  "max-download-attempts": 5,
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
  "dns": ["8.8.8.8", "114.114.114.114", "223.5.5.5"],
  "dns-opts": ["timeout:3", "attempts:2"],
  "insecure-registries": [],
  "live-restore": true,
  "userland-proxy": false,
  "experimental": false,
  "default-network-opts": {
    "bridge": {
      "com.docker.network.driver.mtu": "1450"
    }
  }
}
EOF

echo "✅ Docker 配置已更新"

# 重启 Docker 服务
echo "🔄 重启 Docker 服务..."
sudo systemctl daemon-reload
sudo systemctl restart docker

# 等待服务完全启动
echo "⏳ 等待 Docker 服务完全启动..."
sleep 20

# 验证 Docker 服务
if sudo systemctl is-active --quiet docker; then
    echo "✅ Docker 服务启动成功"
else
    echo "❌ Docker 服务启动失败"
    sudo systemctl status docker --no-pager
    exit 1
fi

# 清理 Docker 缓存
echo "🧹 清理 Docker 缓存..."
docker system prune -f --volumes || true
docker builder prune -f || true

# 测试网络连通性
echo "🌐 测试网络连通性..."

# 测试基本网络
echo "🔍 测试基本网络连通性..."
if ping -c 3 8.8.8.8 > /dev/null 2>&1; then
    echo "✅ 基本网络连通正常"
else
    echo "❌ 基本网络连通异常"
fi

# 测试 DNS 解析
echo "🔍 测试 DNS 解析..."
if nslookup registry-1.docker.io > /dev/null 2>&1; then
    echo "✅ DNS 解析正常"
else
    echo "❌ DNS 解析异常"
fi

# 测试 Docker Hub 连通性
echo "🔍 测试 Docker Hub 连通性..."
REGISTRIES=(
    "https://registry-1.docker.io/v2/"
    "https://docker.mirrors.ustc.edu.cn/v2/"
    "https://hub-mirror.c.163.com/v2/"
)

working_registries=0
for registry in "${REGISTRIES[@]}"; do
    echo "🌐 测试: $registry"
    if timeout 15 curl -f -s "$registry" > /dev/null 2>&1; then
        echo "✅ 连通正常: $registry"
        ((working_registries++))
    else
        echo "❌ 连通异常: $registry"
    fi
done

if [ $working_registries -eq 0 ]; then
    echo "❌ 所有镜像源都不可达，请检查网络配置"
    exit 1
else
    echo "✅ 有 $working_registries 个镜像源可用"
fi

# 测试镜像拉取（带重试机制）
echo "🔍 测试镜像拉取功能..."
test_image="hello-world:latest"

for attempt in {1..3}; do
    echo "🔄 第 $attempt 次拉取尝试: $test_image"
    
    if timeout 180 docker pull "$test_image"; then
        echo "✅ 镜像拉取测试成功"
        
        # 测试容器运行
        if docker run --rm "$test_image" > /dev/null 2>&1; then
            echo "✅ 容器运行测试成功"
        else
            echo "⚠️ 容器运行测试失败"
        fi
        
        # 清理测试镜像
        docker rmi "$test_image" 2>/dev/null || true
        break
    else
        echo "❌ 第 $attempt 次拉取失败"
        
        if [ $attempt -lt 3 ]; then
            echo "⏳ 等待 30 秒后重试..."
            sleep 30
            
            # 清理可能的损坏状态
            docker rmi "$test_image" 2>/dev/null || true
            docker system prune -f || true
        else
            echo "❌ 所有拉取尝试都失败了"
        fi
    fi
done

# 优化 Docker 网络设置
echo "🔧 优化 Docker 网络设置..."

# 删除默认网络（如果存在问题）
docker network prune -f || true

# 创建优化的网络
if ! docker network ls | grep -q "optimized-network"; then
    docker network create \
        --driver bridge \
        --opt com.docker.network.driver.mtu=1450 \
        --opt com.docker.network.bridge.enable_icc=true \
        --opt com.docker.network.bridge.enable_ip_masquerade=true \
        optimized-network || true
fi

# 显示网络配置
echo "📋 当前 Docker 网络配置："
docker network ls
echo ""

# 显示 Docker 系统信息
echo "📋 Docker 系统信息："
docker system info | grep -E "(Registry|Storage|Runtime|Network)" || true
echo ""

# 显示配置文件内容
echo "📋 当前 Docker 配置："
sudo cat /etc/docker/daemon.json
echo ""

# 创建网络修复的便捷命令
echo "🔧 创建网络修复便捷命令..."
sudo tee /usr/local/bin/fix-docker-network > /dev/null <<'EOF'
#!/bin/bash
echo "🔧 快速修复 Docker 网络问题..."
sudo systemctl restart docker
sleep 10
docker system prune -f
echo "✅ Docker 网络修复完成"
EOF

sudo chmod +x /usr/local/bin/fix-docker-network
echo "✅ 已创建 fix-docker-network 命令"

echo "🎉 Docker 网络超时问题修复完成！"
echo ""
echo "📝 修复摘要："
echo "✅ 优化了系统网络参数"
echo "✅ 配置了多个镜像源"
echo "✅ 优化了 Docker 配置"
echo "✅ 清理了 Docker 缓存"
echo "✅ 测试了网络连通性"
echo "✅ 创建了便捷修复命令"
echo ""
echo "🚀 现在可以重新尝试部署!"
echo ""
echo "💡 如果问题持续存在："
echo "1. 运行: fix-docker-network"
echo "2. 检查防火墙设置"
echo "3. 联系网络管理员检查网络策略"
