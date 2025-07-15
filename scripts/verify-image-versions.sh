#!/bin/bash
# Docker 镜像版本匹配验证脚本
# 确保预拉取的镜像版本与 Dockerfile 中使用的版本一致

set -e

echo "🔍 Docker 镜像版本匹配验证脚本"
echo "===================================================================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目根目录
PROJECT_ROOT="/workspaces/legezhixiao"
cd "$PROJECT_ROOT"

# 函数：从 Dockerfile 中提取镜像名称和标签
extract_dockerfile_images() {
    local dockerfile_path="$1"
    if [ ! -f "$dockerfile_path" ]; then
        echo -e "${RED}❌ Dockerfile 不存在: $dockerfile_path${NC}"
        return 1
    fi
    
    # 提取 FROM 指令中的镜像名称
    grep -E "^FROM " "$dockerfile_path" | sed 's/FROM //' | sed 's/ AS .*//' | sed 's/--platform=[^ ]* //' | sort | uniq
}

# 函数：标准化镜像名称（添加 docker.io/library/ 前缀）
normalize_image_name() {
    local image="$1"
    
    # 如果已经是完整格式，直接返回
    if [[ "$image" == *"/"* ]]; then
        echo "$image"
        return
    fi
    
    # 如果是官方镜像，添加 docker.io/library/ 前缀
    echo "docker.io/library/$image"
}

# 函数：检查镜像是否在 Docker Hub 上存在
check_image_exists() {
    local image="$1"
    local image_name=$(echo "$image" | cut -d':' -f1)
    local tag=$(echo "$image" | cut -d':' -f2)
    
    # 如果没有指定标签，默认为 latest
    if [ "$image_name" = "$tag" ]; then
        tag="latest"
    fi
    
    # 检查镜像是否存在（使用 docker manifest inspect）
    if docker manifest inspect "$image" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# 函数：获取镜像的可用标签
get_available_tags() {
    local image_name="$1"
    echo "🔍 获取 $image_name 的可用标签..."
    
    # 使用 Docker Hub API 获取标签信息
    local repo_name=$(echo "$image_name" | sed 's/docker.io\/library\///')
    local api_url="https://hub.docker.com/v2/repositories/library/$repo_name/tags/?page_size=100"
    
    if command -v curl > /dev/null 2>&1; then
        curl -s "$api_url" | grep -o '"name":"[^"]*"' | cut -d'"' -f4 | head -20
    else
        echo "curl 命令不可用，无法获取标签信息"
    fi
}

echo -e "${BLUE}📋 扫描项目中的 Dockerfile 文件...${NC}"

# 扫描所有 Dockerfile
dockerfile_list=(
    "frontend/Dockerfile"
    "backend/Dockerfile"
    "mongodb/Dockerfile"
    "redis/Dockerfile"
)

declare -A actual_images
declare -A image_sources

echo "📁 发现的 Dockerfile 文件:"
for dockerfile in "${dockerfile_list[@]}"; do
    if [ -f "$dockerfile" ]; then
        echo "  ✅ $dockerfile"
        # 提取镜像
        images=$(extract_dockerfile_images "$dockerfile")
        for image in $images; do
            normalized_image=$(normalize_image_name "$image")
            actual_images["$normalized_image"]=1
            image_sources["$normalized_image"]="$dockerfile"
        done
    else
        echo "  ❌ $dockerfile (文件不存在)"
    fi
done

echo ""
echo -e "${BLUE}📦 实际使用的镜像列表:${NC}"
for image in "${!actual_images[@]}"; do
    echo "  📦 $image (来源: ${image_sources[$image]})"
done

echo ""
echo -e "${BLUE}🔍 验证镜像可用性...${NC}"

verified_images=()
failed_images=()

for image in "${!actual_images[@]}"; do
    echo "🔄 检查镜像: $image"
    
    if check_image_exists "$image"; then
        echo -e "${GREEN}✅ $image - 镜像存在且可用${NC}"
        verified_images+=("$image")
    else
        echo -e "${RED}❌ $image - 镜像不存在或标签错误${NC}"
        failed_images+=("$image")
        
        # 尝试获取可用标签
        image_name=$(echo "$image" | cut -d':' -f1)
        echo -e "${YELLOW}💡 尝试获取 $image_name 的可用标签...${NC}"
        get_available_tags "$image_name"
    fi
done

echo ""
echo "===================================================================================="
echo -e "${BLUE}📊 验证结果总结:${NC}"
echo "✅ 可用镜像: ${#verified_images[@]}"
echo "❌ 问题镜像: ${#failed_images[@]}"

if [ ${#failed_images[@]} -gt 0 ]; then
    echo ""
    echo -e "${RED}❌ 以下镜像存在问题:${NC}"
    for image in "${failed_images[@]}"; do
        echo "  - $image"
    done
fi

echo ""
echo -e "${BLUE}🔧 生成优化后的镜像列表...${NC}"

# 生成用于部署脚本的镜像列表
cat > /tmp/optimized-images.txt <<EOF
# 优化后的镜像列表（与 Dockerfile 完全匹配）
# 生成时间: $(date)
# 验证状态: ${#verified_images[@]}/${#actual_images[@]} 可用

BASE_IMAGES=(
EOF

for image in "${verified_images[@]}"; do
    echo "    \"$image\"" >> /tmp/optimized-images.txt
done

cat >> /tmp/optimized-images.txt <<EOF
)
EOF

echo "📋 优化后的镜像列表已保存到: /tmp/optimized-images.txt"
echo ""
cat /tmp/optimized-images.txt

# 如果有问题镜像，生成修复建议
if [ ${#failed_images[@]} -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}💡 修复建议:${NC}"
    
    for image in "${failed_images[@]}"; do
        echo "------------------------"
        echo "🔧 镜像: $image"
        echo "📁 来源: ${image_sources[$image]}"
        
        # 提取基础镜像名和标签
        base_image=$(echo "$image" | cut -d':' -f1)
        current_tag=$(echo "$image" | cut -d':' -f2)
        
        echo "💡 建议的修复方案:"
        echo "  1. 检查标签是否正确: $current_tag"
        echo "  2. 尝试使用 latest 标签: ${base_image}:latest"
        echo "  3. 查看 Docker Hub 页面获取正确标签"
        echo "  4. 更新 ${image_sources[$image]} 中的镜像标签"
    done
fi

echo ""
echo "===================================================================================="
echo -e "${GREEN}🎉 镜像版本匹配验证完成!${NC}"

# 返回退出代码
if [ ${#failed_images[@]} -gt 0 ]; then
    exit 1
else
    exit 0
fi
