#!/bin/bash
# 智能网络检测脚本 - 解决 CI 环境中网络名称不一致的问题

echo "🔍 智能网络检测开始..."

# 方法1: 从 docker-compose 配置中获取实际网络名
echo "=== 方法1: 从配置获取网络名 ==="
NETWORK_FROM_CONFIG=$(docker-compose config | grep -A 5 "networks:" | grep "name:" | awk '{print $2}' | head -1)
if [ -n "$NETWORK_FROM_CONFIG" ]; then
    echo "从配置找到网络名: $NETWORK_FROM_CONFIG"
fi

# 方法2: 从运行的容器中获取网络名
echo "=== 方法2: 从运行容器获取网络名 ==="
NETWORK_FROM_CONTAINER=""
if docker-compose ps -q | head -1 >/dev/null 2>&1; then
    CONTAINER_ID=$(docker-compose ps -q | head -1)
    if [ -n "$CONTAINER_ID" ]; then
        NETWORK_FROM_CONTAINER=$(docker inspect "$CONTAINER_ID" --format='{{range $net, $conf := .NetworkSettings.Networks}}{{$net}}{{end}}' | grep app | head -1)
        if [ -n "$NETWORK_FROM_CONTAINER" ]; then
            echo "从容器找到网络名: $NETWORK_FROM_CONTAINER"
        fi
    fi
fi

# 方法3: 搜索所有包含 app 的网络
echo "=== 方法3: 搜索现有网络 ==="
NETWORKS_WITH_APP=$(docker network ls --format "{{.Name}}" | grep app | head -1)
if [ -n "$NETWORKS_WITH_APP" ]; then
    echo "找到包含app的网络: $NETWORKS_WITH_APP"
fi

# 确定最终使用的网络名
FINAL_NETWORK=""
for net in "$NETWORK_FROM_CONFIG" "$NETWORK_FROM_CONTAINER" "$NETWORKS_WITH_APP"; do
    if [ -n "$net" ] && docker network inspect "$net" >/dev/null 2>&1; then
        FINAL_NETWORK="$net"
        break
    fi
done

# 如果还是没找到，尝试常见的网络名
if [ -z "$FINAL_NETWORK" ]; then
    echo "=== 方法4: 尝试常见网络名 ==="
    POSSIBLE_NETWORKS=(
        "legezhixiao_app-network"
        "$(basename $PWD | tr '[:upper:]' '[:lower:]' | tr '-' '')_app-network"
        "$(basename $PWD | tr '[:upper:]' '[:lower:]')_app-network"
        "$(basename $PWD)_app-network"
        "app-network"
    )
    
    for net in "${POSSIBLE_NETWORKS[@]}"; do
        if docker network inspect "$net" >/dev/null 2>&1; then
            FINAL_NETWORK="$net"
            echo "找到匹配的网络: $net"
            break
        fi
    done
fi

echo ""
echo "=== 网络检测结果 ==="
if [ -n "$FINAL_NETWORK" ]; then
    echo "✅ 检测到网络: $FINAL_NETWORK"
    
    # 输出网络详情
    echo ""
    echo "=== 网络详细信息 ==="
    docker network inspect "$FINAL_NETWORK" | jq '.[0] | {
        Name: .Name,
        Driver: .Driver,
        Scope: .Scope,
        Subnet: .IPAM.Config[0].Subnet,
        Gateway: .IPAM.Config[0].Gateway,
        ContainerCount: (.Containers | length)
    }' 2>/dev/null || {
        echo "基本信息:"
        docker network inspect "$FINAL_NETWORK" | grep -E '"Name"|"Driver"|"Scope"'
    }
    
    # 检查连接的容器
    echo ""
    echo "=== 连接的容器 ==="
    CONNECTED_CONTAINERS=$(docker network inspect "$FINAL_NETWORK" | jq -r '.[0].Containers | to_entries[] | "\(.value.Name) (\(.value.IPv4Address))"' 2>/dev/null)
    if [ -n "$CONNECTED_CONTAINERS" ]; then
        echo "$CONNECTED_CONTAINERS" | sed 's/^/  ✅ /'
        CONTAINER_COUNT=$(echo "$CONNECTED_CONTAINERS" | wc -l)
        echo "总计: $CONTAINER_COUNT 个容器"
    else
        echo "  ⚠️ 暂无容器连接"
    fi
    
    # 导出网络名供其他脚本使用
    echo "export DETECTED_NETWORK_NAME='$FINAL_NETWORK'" > /tmp/detected_network.env
    echo ""
    echo "✅ 网络检测完成，可以使用: $FINAL_NETWORK"
    exit 0
else
    echo "❌ 未检测到任何app-network相关网络"
    echo ""
    echo "=== 调试信息 ==="
    echo "当前目录: $PWD"
    echo "目录基名: $(basename $PWD)"
    echo ""
    echo "=== 所有可用网络 ==="
    docker network ls
    echo ""
    echo "=== Docker Compose 配置检查 ==="
    docker-compose config | grep -A 10 "networks:" || echo "无网络配置"
    
    exit 1
fi
