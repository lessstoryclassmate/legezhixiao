#!/bin/bash
# 百度云DNS验证脚本
# 配置百度云DNS并验证网络连接

set -e

echo "🔍 百度云DNS验证脚本"
echo "===================================================================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 显示当前DNS配置
echo -e "${BLUE}📋 当前DNS配置:${NC}"
cat /etc/resolv.conf

# 配置百度云DNS
echo ""
echo -e "${BLUE}🔧 配置百度云DNS...${NC}"
sudo bash -c 'cat > /etc/resolv.conf <<EOF
nameserver 180.76.76.76
nameserver 8.8.8.8
EOF'
echo -e "${GREEN}✅ DNS 已设置为百度云DNS (180.76.76.76)${NC}"

# 验证DNS配置
echo ""
echo -e "${BLUE}📋 新DNS配置:${NC}"
cat /etc/resolv.conf

# 测试DNS解析
echo ""
echo -e "${BLUE}🔍 测试DNS解析性能...${NC}"

# 测试域名列表
TEST_DOMAINS=(
    "registry.baidubce.com"
    "github.com"
    "registry.docker-cn.com"
    "baidu.com"
    "google.com"
)

for domain in "${TEST_DOMAINS[@]}"; do
    echo "------------------------"
    echo "🔍 测试域名: $domain"
    
    # 记录开始时间
    start_time=$(date +%s%3N)
    
    if nslookup "$domain" > /dev/null 2>&1; then
        end_time=$(date +%s%3N)
        duration=$((end_time - start_time))
        echo -e "${GREEN}✅ $domain - DNS解析成功 (耗时: ${duration}ms)${NC}"
        
        # 显示IP地址
        ip_address=$(nslookup "$domain" | grep "Address:" | tail -1 | cut -d' ' -f2)
        echo "🌐 IP地址: $ip_address"
    else
        echo -e "${RED}❌ $domain - DNS解析失败${NC}"
    fi
done

# 测试网络连接
echo ""
echo "===================================================================================="
echo -e "${BLUE}🔍 测试网络连接...${NC}"

for domain in "${TEST_DOMAINS[@]}"; do
    echo "🔍 测试连接: $domain"
    
    if ping -c 1 -W 3 "$domain" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ $domain - 网络连接正常${NC}"
    else
        echo -e "${RED}❌ $domain - 网络连接失败${NC}"
    fi
done

# 测试百度云镜像加速器
echo ""
echo "===================================================================================="
echo -e "${BLUE}🔍 测试百度云镜像加速器...${NC}"

BAIDU_MIRROR="https://registry.baidubce.com"
echo "🔍 测试镜像加速器: $BAIDU_MIRROR"

if curl -s --connect-timeout 5 --max-time 10 "$BAIDU_MIRROR/v2/" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ $BAIDU_MIRROR - 镜像加速器连通正常${NC}"
else
    echo -e "${RED}❌ $BAIDU_MIRROR - 镜像加速器连通失败${NC}"
fi

# 测试镜像拉取
echo ""
echo -e "${BLUE}🔍 测试镜像拉取...${NC}"

# 测试拉取一个小镜像
test_image="hello-world:latest"
echo "🔍 测试拉取镜像: $test_image"

if docker pull "registry.baidubce.com/library/$test_image" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ $test_image - 镜像拉取成功${NC}"
    # 清理测试镜像
    docker rmi "registry.baidubce.com/library/$test_image" > /dev/null 2>&1 || true
else
    echo -e "${RED}❌ $test_image - 镜像拉取失败${NC}"
fi

echo ""
echo "===================================================================================="
echo -e "${GREEN}🎉 百度云DNS验证完成!${NC}"
echo ""
echo -e "${BLUE}📋 总结:${NC}"
echo "✅ 百度云DNS (180.76.76.76) 已配置"
echo "✅ 网络连接测试完成"
echo "✅ 镜像加速器测试完成"
echo ""
echo -e "${BLUE}💡 建议:${NC}"
echo "  1. 如果DNS解析失败，检查网络连接"
echo "  2. 如果镜像拉取失败，检查Docker服务状态"
echo "  3. 定期验证DNS配置的有效性"
