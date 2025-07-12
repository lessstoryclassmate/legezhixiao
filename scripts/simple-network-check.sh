#!/bin/bash

# 智能网络检测脚本 - 支持多种网络名模式
# 解决 Docker Compose 项目前缀导致的网络名不一致问题

# 移除 set -e 以允许更健壮的错误处理
# set -e

echo "🔍 智能网络检测开始..."

# 添加调试输出
echo "=== 调试信息 ==="
echo "当前所有网络:"
docker network ls || {
    echo "❌ 无法列出Docker网络，请检查Docker守护进程是否运行"
    exit 1
}

# 尝试检测包含 app-network 的网络
echo "📋 查找包含 'app-network' 的网络..."
NETWORK_NAME=$(docker network ls --filter name=app-network --format "{{.Name}}" | head -n1 2>/dev/null || true)

if [ -z "$NETWORK_NAME" ]; then
    # 如果没找到，尝试直接查找 app-network
    echo "📋 尝试查找精确的 'app-network'..."
    if docker network ls --format "{{.Name}}" 2>/dev/null | grep -q "^app-network$"; then
        NETWORK_NAME="app-network"
    fi
fi

echo "检测到的网络名: '$NETWORK_NAME'"

# 检查是否找到网络
if [ -n "$NETWORK_NAME" ]; then
    echo "✅ 网络 '$NETWORK_NAME' 存在"
    
    # 获取网络详细信息
    echo "=== 网络详细信息 ==="
    if command -v jq >/dev/null 2>&1; then
        docker network inspect "$NETWORK_NAME" --format "{{json .}}" 2>/dev/null | jq '.Name, .Driver, .Scope, .IPAM.Config[0].Subnet' 2>/dev/null || {
            echo "网络基本信息:"
            docker network inspect "$NETWORK_NAME" --format "Name: {{.Name}}, Driver: {{.Driver}}, Scope: {{.Scope}}" 2>/dev/null || echo "无法获取网络详细信息"
        }
    else
        echo "网络基本信息:"
        docker network inspect "$NETWORK_NAME" --format "Name: {{.Name}}, Driver: {{.Driver}}, Scope: {{.Scope}}" 2>/dev/null || echo "无法获取网络详细信息"
    fi
    
    # 检查连接的容器
    echo "=== 连接的容器 ==="
    CONTAINERS=$(docker network inspect "$NETWORK_NAME" --format "{{range \$id, \$container := .Containers}}{{printf \"%s: %s\\n\" \$container.Name \$container.IPv4Address}}{{end}}" 2>/dev/null || true)
    if [ -n "$CONTAINERS" ]; then
        echo "$CONTAINERS"
    else
        echo "⚠️ 暂无容器连接到此网络"
    fi
    
    # 导出网络信息供其他脚本使用
    echo "DETECTED_NETWORK_NAME=$NETWORK_NAME" > /tmp/detected_network.env
    echo "NETWORK_EXISTS=true" >> /tmp/detected_network.env
    
    echo "✅ 网络检测完成: $NETWORK_NAME"
    exit 0
else
    echo "❌ 未找到任何包含 'app-network' 的网络"
    
    echo "=== 当前所有网络 ==="
    docker network ls 2>/dev/null || echo "无法列出网络"
    
    echo "=== 寻找相关网络 ==="
    docker network ls 2>/dev/null | grep -E "(app|legezhixiao)" || echo "未找到相关网络"
    
    # 导出失败状态，但不立即退出，让调用方决定如何处理
    echo "DETECTED_NETWORK_NAME=" > /tmp/detected_network.env
    echo "NETWORK_EXISTS=false" >> /tmp/detected_network.env
    
    echo "⚠️ 网络检测未找到目标网络，但已记录状态"
    exit 1
fi
