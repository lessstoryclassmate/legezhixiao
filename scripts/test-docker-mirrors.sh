#!/bin/bash
# Docker 镜像加速器连通性测试脚本

set -e

echo "🔍 Docker 镜像加速器连通性测试..."

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 镜像加速器列表
REGISTRY_MIRRORS=(
    "https://mirror.baidubce.com"
    "https://docker.mirrors.ustc.edu.cn"
    "https://registry.docker-cn.com"
    "https://mirror.ccs.tencentyun.com"
    "https://reg-mirror.qiniu.com"
    "https://hub-mirror.c.163.com"
)

# 测试镜像加速器连通性
echo "==============================================="
echo -e "${BLUE}🌐 测试镜像加速器连通性...${NC}"
echo "==============================================="

working_mirrors=()
failed_mirrors=()

for mirror in "${REGISTRY_MIRRORS[@]}"; do
    echo -n "测试 $mirror ... "
    
    # 测试连通性
    if curl -s --connect-timeout 5 --max-time 10 "$mirror/v2/" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ 连通正常${NC}"
        working_mirrors+=("$mirror")
        
        # 测试响应时间
        response_time=$(curl -s -w "%{time_total}" -o /dev/null --connect-timeout 5 --max-time 10 "$mirror/v2/" 2>/dev/null || echo "timeout")
        if [ "$response_time" != "timeout" ]; then
            echo "   响应时间: ${response_time}s"
        fi
    else
        echo -e "${RED}❌ 连通失败${NC}"
        failed_mirrors+=("$mirror")
    fi
done

# 显示测试结果
echo ""
echo "==============================================="
echo -e "${BLUE}📊 测试结果统计${NC}"
echo "==============================================="

echo -e "${GREEN}可用镜像源 (${#working_mirrors[@]}个):${NC}"
for mirror in "${working_mirrors[@]}"; do
    echo "  ✅ $mirror"
done

if [ ${#failed_mirrors[@]} -gt 0 ]; then
    echo ""
    echo -e "${RED}不可用镜像源 (${#failed_mirrors[@]}个):${NC}"
    for mirror in "${failed_mirrors[@]}"; do
        echo "  ❌ $mirror"
    done
fi

# 生成推荐配置
echo ""
echo "==============================================="
echo -e "${BLUE}🎯 推荐配置${NC}"
echo "==============================================="

if [ ${#working_mirrors[@]} -gt 0 ]; then
    echo -e "${GREEN}根据测试结果，推荐以下 Docker 配置:${NC}"
    echo ""
    echo "📋 /etc/docker/daemon.json 配置:"
    echo "{"
    echo "  \"registry-mirrors\": ["
    for i in "${!working_mirrors[@]}"; do
        if [ $i -eq $((${#working_mirrors[@]} - 1)) ]; then
            echo "    \"${working_mirrors[i]}\""
        else
            echo "    \"${working_mirrors[i]}\","
        fi
    done
    echo "  ],"
    echo "  \"dns\": [\"119.29.29.29\", \"223.5.5.5\", \"8.8.8.8\"],"
    echo "  \"max-concurrent-downloads\": 10,"
    echo "  \"max-concurrent-uploads\": 5,"
    echo "  \"log-driver\": \"json-file\","
    echo "  \"log-opts\": {"
    echo "    \"max-size\": \"100m\","
    echo "    \"max-file\": \"3\""
    echo "  },"
    echo "  \"storage-driver\": \"overlay2\""
    echo "}"
else
    echo -e "${RED}⚠️ 所有镜像加速器都无法连通！${NC}"
    echo "建议检查网络连接或使用默认配置"
fi

# 提供应用建议
echo ""
echo "==============================================="
echo -e "${BLUE}💡 应用建议${NC}"
echo "==============================================="

if [ ${#working_mirrors[@]} -gt 0 ]; then
    echo "1. 运行 Docker 配置优化脚本:"
    echo "   ./scripts/docker-config-optimizer.sh"
    echo ""
    echo "2. 或手动应用配置后重启 Docker:"
    echo "   sudo systemctl restart docker"
    echo ""
    echo "3. 验证配置是否生效:"
    echo "   docker info | grep -A 10 'Registry Mirrors'"
    echo ""
    echo "4. 测试镜像拉取:"
    echo "   docker pull hello-world:latest"
else
    echo "1. 检查网络连接"
    echo "2. 尝试使用不同的 DNS 服务器"
    echo "3. 检查防火墙设置"
    echo "4. 考虑使用 VPN 或代理"
fi

# 返回结果
if [ ${#working_mirrors[@]} -gt 0 ]; then
    echo ""
    echo -e "${GREEN}🎉 测试完成！找到 ${#working_mirrors[@]} 个可用镜像源。${NC}"
    exit 0
else
    echo ""
    echo -e "${RED}⚠️ 测试完成！没有找到可用的镜像源。${NC}"
    exit 1
fi
