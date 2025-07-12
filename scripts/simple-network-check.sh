#!/bin/bash

# 简单网络检测脚本 - 直接检查 app-network
# 避免复杂的目录名和前缀逻辑

set -e

echo "🔍 简单网络检测开始..."

# 固定使用 app-network（与 docker-compose.yml 一致）
NETWORK_NAME="app-network"

echo "📋 检查目标网络: $NETWORK_NAME"

# 检查网络是否存在
if docker network ls --format "{{.Name}}" | grep -q "^${NETWORK_NAME}$"; then
    echo "✅ 网络 '$NETWORK_NAME' 存在"
    
    # 获取网络详细信息
    echo "=== 网络详细信息 ==="
    docker network inspect "$NETWORK_NAME" --format "{{json .}}" | jq '.Name, .Driver, .Scope, .IPAM.Config[0].Subnet' 2>/dev/null || {
        echo "网络基本信息:"
        docker network inspect "$NETWORK_NAME" --format "Name: {{.Name}}, Driver: {{.Driver}}, Scope: {{.Scope}}"
    }
    
    # 检查连接的容器
    echo "=== 连接的容器 ==="
    CONTAINERS=$(docker network inspect "$NETWORK_NAME" --format "{{range \$id, \$container := .Containers}}{{printf \"%s: %s\\n\" \$container.Name \$container.IPv4Address}}{{end}}")
    if [ -n "$CONTAINERS" ]; then
        echo "$CONTAINERS"
    else
        echo "⚠️ 暂无容器连接到此网络"
    fi
    
    # 导出网络信息供其他脚本使用
    echo "DETECTED_NETWORK_NAME=$NETWORK_NAME" > /tmp/detected_network.env
    echo "NETWORK_EXISTS=true" >> /tmp/detected_network.env
    
    echo "✅ 网络检测完成"
    exit 0
else
    echo "❌ 网络 '$NETWORK_NAME' 不存在"
    
    echo "=== 当前所有网络 ==="
    docker network ls
    
    echo "=== 寻找相关网络 ==="
    docker network ls | grep -i app || echo "未找到包含 'app' 的网络"
    
    # 导出失败状态
    echo "DETECTED_NETWORK_NAME=" > /tmp/detected_network.env
    echo "NETWORK_EXISTS=false" >> /tmp/detected_network.env
    
    echo "❌ 网络检测失败"
    exit 1
fi
