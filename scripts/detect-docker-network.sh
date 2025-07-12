#!/bin/bash

# Docker 网络检测脚本
# 用于 CI/CD 环境中自动检测和验证 Docker Compose 网络

set -e

echo "🔍 Docker 网络检测开始..."

# 1. 显示当前目录信息
echo "=== 环境信息 ==="
echo "当前目录: $(pwd)"
echo "目录名: $(basename $(pwd))"

# 2. 显示所有网络
echo "=== 所有 Docker 网络 ==="
docker network ls

# 3. 查找 app-network 相关网络
echo "=== 查找 app-network 相关网络 ==="
APP_NETWORKS=$(docker network ls --format "{{.Name}}" | grep -E "(app-network|app_network)" || true)

if [ -n "$APP_NETWORKS" ]; then
    echo "找到以下 app-network 相关网络:"
    echo "$APP_NETWORKS" | sed 's/^/  - /'
    
    # 使用第一个找到的网络
    NETWORK_NAME=$(echo "$APP_NETWORKS" | head -1)
    echo "✅ 选择网络: $NETWORK_NAME"
else
    echo "❌ 未找到 app-network 相关网络"
    echo "尝试查找项目相关网络..."
    
    # 尝试根据项目名查找
    PROJECT_NETWORKS=$(docker network ls --format "{{.Name}}" | grep -v -E "^(bridge|host|none)$" | grep -E "(legezhixiao|app)" || true)
    
    if [ -n "$PROJECT_NETWORKS" ]; then
        echo "找到以下项目相关网络:"
        echo "$PROJECT_NETWORKS" | sed 's/^/  - /'
        NETWORK_NAME=$(echo "$PROJECT_NETWORKS" | head -1)
        echo "✅ 选择网络: $NETWORK_NAME"
    else
        echo "❌ 未找到任何项目相关网络"
        exit 1
    fi
fi

# 4. 检查网络详情
echo "=== 网络详情 ==="
if docker network inspect "$NETWORK_NAME" >/dev/null 2>&1; then
    echo "网络名: $NETWORK_NAME"
    echo "网络驱动: $(docker network inspect "$NETWORK_NAME" | jq -r '.[0].Driver' 2>/dev/null || echo "unknown")"
    echo "网络范围: $(docker network inspect "$NETWORK_NAME" | jq -r '.[0].Scope' 2>/dev/null || echo "unknown")"
    
    # 检查连接的容器
    CONNECTED_CONTAINERS=$(docker network inspect "$NETWORK_NAME" | jq -r '.[0].Containers | keys[]' 2>/dev/null || true)
    
    if [ -n "$CONNECTED_CONTAINERS" ]; then
        echo "=== 已连接的容器 ==="
        echo "$CONNECTED_CONTAINERS" | while read container_id; do
            if [ -n "$container_id" ]; then
                CONTAINER_NAME=$(docker inspect "$container_id" --format '{{.Name}}' 2>/dev/null | sed 's/^\//' || echo "unknown")
                CONTAINER_IP=$(docker network inspect "$NETWORK_NAME" | jq -r ".[0].Containers[\"$container_id\"].IPv4Address" 2>/dev/null || echo "unknown")
                echo "  - $CONTAINER_NAME ($CONTAINER_IP)"
            fi
        done
        
        CONTAINER_COUNT=$(echo "$CONNECTED_CONTAINERS" | wc -l)
        echo "连接的容器总数: $CONTAINER_COUNT"
        
        if [ "$CONTAINER_COUNT" -ge 2 ]; then
            echo "✅ 容器网络连接正常"
        else
            echo "⚠️ 连接的容器数量较少"
        fi
    else
        echo "⚠️ 暂无容器连接到网络"
    fi
    
    # 输出网络名供后续使用
    echo "DETECTED_NETWORK_NAME=$NETWORK_NAME" >> $GITHUB_ENV 2>/dev/null || true
    echo "🎯 检测到的网络名: $NETWORK_NAME"
    
else
    echo "❌ 无法检查网络详情"
    exit 1
fi

echo "✅ Docker 网络检测完成"
