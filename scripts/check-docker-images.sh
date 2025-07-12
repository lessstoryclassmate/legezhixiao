#!/bin/bash
# Docker 镜像可用性检查脚本

echo "🔍 检查 Docker 镜像可用性..."

# 定义需要检查的基础镜像
IMAGES=(
    "node:18-alpine"
    "python:3.11-slim"
    "nginx:alpine"
)

# 检查 Docker Hub 连接性
echo "📡 检查 Docker Hub 连接性..."
if curl -s --connect-timeout 10 https://registry-1.docker.io/v2/ > /dev/null; then
    echo "✅ Docker Hub 可访问"
    DOCKER_HUB_ACCESS=true
else
    echo "⚠️  Docker Hub 访问受限"
    DOCKER_HUB_ACCESS=false
fi

# 检查每个镜像
echo ""
echo "🐳 检查基础镜像可用性..."
failed_images=()

for image in "${IMAGES[@]}"; do
    echo "  检查 $image..."
    
    # 尝试获取镜像信息
    if docker manifest inspect "$image" > /dev/null 2>&1; then
        echo "    ✅ $image 可用"
    else
        echo "    ❌ $image 不可用或无法访问"
        failed_images+=("$image")
        
        # 尝试建议替代镜像
        case "$image" in
            "node:18-alpine")
                echo "    💡 建议替代: node:18.20-alpine, node:lts-alpine"
                ;;
            "python:3.11-slim")
                echo "    💡 建议替代: python:3.11.9-slim, python:3.11-slim-bullseye"
                ;;
            "nginx:alpine")
                echo "    💡 建议替代: nginx:1.25-alpine, nginx:stable-alpine"
                ;;
        esac
    fi
done

echo ""
if [ ${#failed_images[@]} -eq 0 ]; then
    echo "🎉 所有基础镜像都可用"
    exit 0
else
    echo "⚠️  以下镜像不可用: ${failed_images[*]}"
    
    if [ "$DOCKER_HUB_ACCESS" = false ]; then
        echo ""
        echo "💡 建议解决方案:"
        echo "1. 配置 Docker 镜像加速器"
        echo "2. 检查网络连接和代理设置"
        echo "3. 使用替代镜像标签"
        echo "4. 考虑使用 GitHub Container Registry 或其他镜像源"
    fi
    
    exit 1
fi
