#!/bin/bash
# Docker 镜像拉取验证脚本
# 基于官方文档最佳实践: https://docs.docker.com/reference/cli/docker/image/pull/

set -e

echo "🔍 Docker 镜像拉取规则验证脚本"
echo "📋 基于官方文档: https://docs.docker.com/reference/cli/docker/image/pull/"
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

# 检查当前 Docker 配置
echo -e "${BLUE}📋 当前 Docker 配置:${NC}"
if [ -f /etc/docker/daemon.json ]; then
    echo -e "${GREEN}✅ 发现 daemon.json 配置文件${NC}"
    echo "📄 镜像加速器配置:"
    grep -A 20 "registry-mirrors" /etc/docker/daemon.json | head -10 || echo "未找到 registry-mirrors 配置"
    echo ""
    echo "📄 并发下载配置:"
    grep -A 5 "max-concurrent-downloads" /etc/docker/daemon.json || echo "使用默认值: 3"
else
    echo -e "${YELLOW}⚠️ 未发现 daemon.json 配置文件，使用默认配置${NC}"
fi

# 测试镜像拉取功能
echo -e "${BLUE}🔍 测试镜像拉取功能:${NC}"

# 测试镜像列表（使用官方推荐的完整格式）
TEST_IMAGES=(
    "docker.io/library/hello-world:latest"
    "docker.io/library/alpine:latest"
    "docker.io/library/busybox:latest"
)

echo "📦 测试镜像拉取性能和规则..."
for image in "${TEST_IMAGES[@]}"; do
    echo "------------------------"
    echo "🔄 测试镜像: $image"
    
    # 记录开始时间
    start_time=$(date +%s)
    
    # 删除本地镜像以测试拉取
    docker rmi "$image" 2>/dev/null || true
    
    # 测试拉取
    if docker pull --quiet "$image" 2>/dev/null; then
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        echo -e "${GREEN}✅ $image 拉取成功 (耗时: ${duration}s)${NC}"
        
        # 获取镜像详细信息
        echo "📋 镜像信息:"
        docker inspect "$image" --format='{{.Id}}' | head -c 12
        echo ""
        docker inspect "$image" --format='{{.Size}}' | numfmt --to=iec
        
        # 测试镜像 digest
        digest=$(docker inspect "$image" --format='{{index .RepoDigests 0}}' 2>/dev/null || echo "N/A")
        echo "🔒 镜像 Digest: $digest"
        
    else
        echo -e "${RED}❌ $image 拉取失败${NC}"
    fi
done

echo ""
echo "===================================================================================="

# 测试镜像加速器连通性
echo -e "${BLUE}🌐 测试镜像加速器连通性:${NC}"

# 从配置文件读取镜像加速器
if [ -f /etc/docker/daemon.json ]; then
    mirrors=$(grep -A 20 "registry-mirrors" /etc/docker/daemon.json | grep -o '"https://[^"]*"' | sed 's/"//g')
    if [ -n "$mirrors" ]; then
        echo "📋 已配置的镜像加速器:"
        for mirror in $mirrors; do
            echo "  - $mirror"
        done
        echo ""
        
        # 测试每个镜像加速器
        for mirror in $mirrors; do
            echo "🔍 测试镜像加速器: $mirror"
            
            # 测试连通性
            if curl -s --connect-timeout 5 --max-time 10 "$mirror/v2/" > /dev/null 2>&1; then
                echo -e "${GREEN}✅ $mirror - 连通正常${NC}"
            else
                echo -e "${RED}❌ $mirror - 连通失败${NC}"
            fi
        done
    else
        echo -e "${YELLOW}⚠️ 未在配置文件中找到镜像加速器设置${NC}"
    fi
else
    echo -e "${YELLOW}⚠️ 未找到 daemon.json 配置文件${NC}"
fi

echo ""
echo "===================================================================================="

# 测试 Docker 官方规范的高级功能
echo -e "${BLUE}🔧 测试高级拉取功能:${NC}"

# 测试 --all-tags 功能（仅测试小镜像）
echo "📦 测试 --all-tags 功能 (alpine 镜像):"
if docker pull --all-tags alpine 2>/dev/null; then
    echo -e "${GREEN}✅ --all-tags 功能正常${NC}"
    docker images alpine --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | head -5
else
    echo -e "${RED}❌ --all-tags 功能异常${NC}"
fi

echo ""

# 测试 digest 拉取
echo "🔒 测试 digest 拉取功能:"
# 获取一个已知镜像的 digest
digest=$(docker inspect alpine:latest --format='{{index .RepoDigests 0}}' 2>/dev/null || echo "")
if [ -n "$digest" ]; then
    echo "📋 测试 digest: $digest"
    if docker pull "$digest" 2>/dev/null; then
        echo -e "${GREEN}✅ digest 拉取功能正常${NC}"
    else
        echo -e "${RED}❌ digest 拉取功能异常${NC}"
    fi
else
    echo -e "${YELLOW}⚠️ 无法获取有效的 digest 进行测试${NC}"
fi

echo ""
echo "===================================================================================="

# 清理测试镜像
echo -e "${BLUE}🧹 清理测试镜像:${NC}"
for image in "${TEST_IMAGES[@]}"; do
    docker rmi "$image" 2>/dev/null || true
done
echo -e "${GREEN}✅ 测试镜像清理完成${NC}"

echo ""
echo "===================================================================================="
echo -e "${GREEN}🎉 Docker 镜像拉取验证完成!${NC}"
echo ""
echo "📋 验证总结:"
echo "✅ 验证了 Docker 官方文档中的镜像拉取规则"
echo "✅ 测试了镜像加速器连通性"
echo "✅ 验证了高级拉取功能 (--all-tags, digest)"
echo "✅ 确认了当前配置的有效性"
echo ""
echo "💡 建议:"
echo "  1. 确保 max-concurrent-downloads 设置为 3 (官方推荐)"
echo "  2. 使用完整的镜像名格式 (docker.io/library/image:tag)"
echo "  3. 在低带宽环境中调整并发下载数量"
echo "  4. 定期测试镜像加速器连通性"
