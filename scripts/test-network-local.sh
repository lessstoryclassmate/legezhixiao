#!/bin/bash

# 本地测试智能网络检测脚本
echo "🧪 本地测试智能网络检测..."
echo "======================================="

# 确保脚本可执行
chmod +x scripts/detect-network.sh

# 清理之前的测试结果
rm -f /tmp/detected_network.env

echo "=== 环境信息 ==="
echo "当前目录: $PWD"
echo "目录名: $(basename $PWD)"

echo ""
echo "=== 当前 Docker 网络状态 ==="
docker network ls

echo ""
echo "=== 停止现有容器（如果有） ==="
docker-compose down 2>/dev/null || echo "没有运行的容器"

echo ""
echo "=== 启动基础服务以创建网络 ==="
docker-compose up -d --no-deps mongodb redis

echo ""
echo "等待网络创建..."
sleep 5

echo ""
echo "=== 创建后的网络状态 ==="
docker network ls

echo ""
echo "=== 执行智能网络检测 ==="
if bash scripts/detect-network.sh; then
    echo "✅ 网络检测成功!"
    
    if [ -f /tmp/detected_network.env ]; then
        echo ""
        echo "=== 检测结果 ==="
        cat /tmp/detected_network.env
        
        # 验证检测结果
        source /tmp/detected_network.env
        if [ -n "$DETECTED_NETWORK_NAME" ]; then
            echo ""
            echo "=== 验证检测到的网络 ==="
            if docker network inspect "$DETECTED_NETWORK_NAME" >/dev/null 2>&1; then
                echo "✅ 网络 '$DETECTED_NETWORK_NAME' 确实存在"
                
                echo ""
                echo "=== 网络详情 ==="
                docker network inspect "$DETECTED_NETWORK_NAME" | jq '.[0] | {Name, Driver, Scope, Containers}' 2>/dev/null || docker network inspect "$DETECTED_NETWORK_NAME" | grep -A 20 '"Name"'
            else
                echo "❌ 网络 '$DETECTED_NETWORK_NAME' 不存在"
            fi
        else
            echo "❌ 检测结果中没有网络名"
        fi
    else
        echo "❌ 检测结果文件不存在"
    fi
else
    echo "❌ 网络检测失败!"
    echo ""
    echo "=== 调试信息 ==="
    bash scripts/detect-network.sh
fi

echo ""
echo "=== 清理测试环境 ==="
docker-compose down

echo ""
echo "======================================="
echo "🎉 本地网络检测测试完成!"
