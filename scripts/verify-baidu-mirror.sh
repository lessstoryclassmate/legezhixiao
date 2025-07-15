#!/bin/bash
# 百度云 Docker 镜像拉取验证脚本
# 专门用于验证百度云镜像加速器配置和镜像拉取

set -e

echo "🔍 百度云 Docker 镜像拉取验证脚本"
echo "===================================================================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 验证Docker是否运行
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker 服务未运行或无权限访问${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Docker 服务运行正常${NC}"

# 检查百度云镜像加速器配置
echo -e "${BLUE}📋 检查百度云镜像加速器配置:${NC}"
if [ -f /etc/docker/daemon.json ]; then
    echo -e "${GREEN}✅ 发现 daemon.json 配置文件${NC}"
    echo "📄 当前配置内容:"
    cat /etc/docker/daemon.json | grep -A 5 -B 5 "mirror.baidubce.com" || echo "未找到百度云镜像配置"
else
    echo -e "${YELLOW}⚠️ 未发现 daemon.json 配置文件${NC}"
fi

# 测试百度云镜像加速器连通性
echo -e "${BLUE}🌐 测试百度云镜像加速器连通性:${NC}"
BAIDU_MIRROR="https://mirror.baidubce.com"

echo "🔍 测试连通性: $BAIDU_MIRROR"
if curl -s --connect-timeout 5 --max-time 10 "$BAIDU_MIRROR/v2/" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ $BAIDU_MIRROR - 连通正常${NC}"
else
    echo -e "${RED}❌ $BAIDU_MIRROR - 连通失败${NC}"
fi

# 测试百度云镜像拉取功能
echo -e "${BLUE}🔍 测试百度云镜像拉取功能:${NC}"

# 测试镜像列表（使用简单格式）
TEST_IMAGES=(
    "hello-world:latest"
    "alpine:latest"
    "nginx:latest"
)

echo "📦 测试百度云镜像拉取..."
for image in "${TEST_IMAGES[@]}"; do
    echo "------------------------"
    echo "🔄 测试镜像: $image"
    
    # 记录开始时间
    start_time=$(date +%s)
    
    # 删除本地镜像以测试拉取
    docker rmi "$image" 2>/dev/null || true
    docker rmi "mirror.baidubce.com/library/$image" 2>/dev/null || true
    
    # 测试从百度云镜像拉取
    if docker pull "mirror.baidubce.com/library/$image" 2>/dev/null; then
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        echo -e "${GREEN}✅ $image 通过百度云镜像拉取成功 (耗时: ${duration}s)${NC}"
        
        # 为镜像添加常规标签
        docker tag "mirror.baidubce.com/library/$image" "$image"
        echo "🏷️ 已为镜像添加标签: $image"
        
        # 获取镜像详细信息
        echo "📋 镜像信息:"
        docker inspect "$image" --format='{{.Id}}' | head -c 12
        echo ""
        docker inspect "$image" --format='{{.Size}}' | numfmt --to=iec
        
    else
        echo -e "${RED}❌ $image 通过百度云镜像拉取失败${NC}"
        
        # 尝试直接拉取作为对比
        echo "🔄 尝试直接拉取进行对比..."
        if docker pull "$image" 2>/dev/null; then
            echo -e "${YELLOW}⚠️ $image 直接拉取成功，但百度云镜像拉取失败${NC}"
        else
            echo -e "${RED}❌ $image 直接拉取也失败${NC}"
        fi
    fi
done

echo ""
echo "===================================================================================="

# 测试常用基础镜像
echo -e "${BLUE}🔧 测试常用基础镜像:${NC}"

# 项目相关的基础镜像
PROJECT_IMAGES=(
    "node:18-alpine"
    "python:3.11-slim"
    "mongo:latest"
    "redis:latest"
)

echo "📦 测试项目相关基础镜像:"
for image in "${PROJECT_IMAGES[@]}"; do
    echo "🔍 测试镜像: $image"
    
    # 检查百度云镜像是否可用
    if docker pull "mirror.baidubce.com/library/$image" 2>/dev/null; then
        echo -e "${GREEN}✅ $image - 百度云镜像可用${NC}"
        # 添加标签
        docker tag "mirror.baidubce.com/library/$image" "$image"
        # 清理
        docker rmi "mirror.baidubce.com/library/$image" 2>/dev/null || true
        docker rmi "$image" 2>/dev/null || true
    else
        echo -e "${RED}❌ $image - 百度云镜像不可用${NC}"
    fi
done

echo ""
echo "===================================================================================="

# 检查 Docker 配置有效性
echo -e "${BLUE}🔧 检查 Docker 配置有效性:${NC}"

# 检查镜像加速器是否生效
echo "📋 检查镜像加速器配置是否生效:"
docker_info=$(docker info 2>/dev/null | grep -A 10 -i "registry")
if echo "$docker_info" | grep -q "mirror.baidubce.com"; then
    echo -e "${GREEN}✅ 百度云镜像加速器配置已生效${NC}"
else
    echo -e "${YELLOW}⚠️ 百度云镜像加速器配置可能未生效${NC}"
fi

echo ""
echo "===================================================================================="

# 清理测试镜像
echo -e "${BLUE}🧹 清理测试镜像:${NC}"
for image in "${TEST_IMAGES[@]}"; do
    docker rmi "$image" 2>/dev/null || true
    docker rmi "mirror.baidubce.com/library/$image" 2>/dev/null || true
done
echo -e "${GREEN}✅ 测试镜像清理完成${NC}"

echo ""
echo "===================================================================================="
echo -e "${GREEN}🎉 百度云 Docker 镜像拉取验证完成!${NC}"
echo ""
echo "📋 验证总结:"
echo "✅ 验证了百度云镜像加速器连通性"
echo "✅ 测试了通过百度云镜像拉取功能"
echo "✅ 验证了常用基础镜像可用性"
echo "✅ 确认了 Docker 配置有效性"
echo ""
echo "💡 使用方法:"
echo "  1. 拉取镜像: docker pull mirror.baidubce.com/library/nginx:latest"
echo "  2. 添加标签: docker tag mirror.baidubce.com/library/nginx:latest nginx:latest"
echo "  3. 使用镜像: docker run nginx:latest"
echo ""
echo "🔧 建议:"
echo "  1. 确保 /etc/docker/daemon.json 包含百度云镜像配置"
echo "  2. 定期测试镜像拉取功能"
echo "  3. 为拉取的镜像添加常规标签方便使用"
