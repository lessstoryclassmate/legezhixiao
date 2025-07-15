#!/bin/bash
# 验证 Docker 镜像配置正确性

set -e

echo "🔍 验证 Docker 镜像配置..."

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. 检查 Dockerfile 配置
echo "📋 检查 Dockerfile 配置..."
dockerfile_correct=true

# 检查前端 Dockerfile
if grep -q "FROM node:18-alpine" /workspaces/legezhixiao/frontend/Dockerfile; then
    echo -e "${GREEN}✅ frontend/Dockerfile 使用正确的官方镜像${NC}"
else
    echo -e "${RED}❌ frontend/Dockerfile 镜像配置有误${NC}"
    dockerfile_correct=false
fi

# 检查后端 Dockerfile
if grep -q "FROM python:3.11-slim" /workspaces/legezhixiao/backend/Dockerfile; then
    echo -e "${GREEN}✅ backend/Dockerfile 使用正确的官方镜像${NC}"
else
    echo -e "${RED}❌ backend/Dockerfile 镜像配置有误${NC}"
    dockerfile_correct=false
fi

# 检查 MongoDB Dockerfile
if grep -q "FROM mongo:5.0" /workspaces/legezhixiao/mongodb/Dockerfile; then
    echo -e "${GREEN}✅ mongodb/Dockerfile 使用正确的官方镜像${NC}"
else
    echo -e "${RED}❌ mongodb/Dockerfile 镜像配置有误${NC}"
    dockerfile_correct=false
fi

# 检查 Redis Dockerfile
if grep -q "FROM redis:7-alpine" /workspaces/legezhixiao/redis/Dockerfile; then
    echo -e "${GREEN}✅ redis/Dockerfile 使用正确的官方镜像${NC}"
else
    echo -e "${RED}❌ redis/Dockerfile 镜像配置有误${NC}"
    dockerfile_correct=false
fi

# 2. 检查部署脚本配置
echo ""
echo "📋 检查部署脚本配置..."
script_correct=true

# 检查 quick-deploy-fixed.sh
if grep -q "mirror.ccs.tencentyun.com" /workspaces/legezhixiao/scripts/quick-deploy-fixed.sh; then
    echo -e "${GREEN}✅ quick-deploy-fixed.sh 使用正确的镜像加速器${NC}"
else
    echo -e "${RED}❌ quick-deploy-fixed.sh 镜像加速器配置有误${NC}"
    script_correct=false
fi

# 检查 quick-deploy.sh
if grep -q "mirror.ccs.tencentyun.com" /workspaces/legezhixiao/scripts/quick-deploy.sh; then
    echo -e "${GREEN}✅ quick-deploy.sh 使用正确的镜像加速器${NC}"
else
    echo -e "${RED}❌ quick-deploy.sh 镜像加速器配置有误${NC}"
    script_correct=false
fi

# 3. 检查是否还有使用旧注册表的地方
echo ""
echo "📋 检查是否还有使用旧注册表的关键文件..."
old_registry_usage=false

# 检查 Dockerfile 中是否还有旧的注册表地址
if grep -r "ccr.ccs.tencentyun.com/library" /workspaces/legezhixiao/frontend/Dockerfile /workspaces/legezhixiao/backend/Dockerfile /workspaces/legezhixiao/mongodb/Dockerfile /workspaces/legezhixiao/redis/Dockerfile 2>/dev/null; then
    echo -e "${RED}❌ 发现 Dockerfile 中还在使用旧的注册表地址${NC}"
    old_registry_usage=true
else
    echo -e "${GREEN}✅ 所有 Dockerfile 都使用官方镜像名${NC}"
fi

# 4. 总结
echo ""
echo "=================================="
echo "📊 配置验证结果："
echo "=================================="

if [ "$dockerfile_correct" = true ]; then
    echo -e "${GREEN}✅ Dockerfile 配置正确${NC}"
else
    echo -e "${RED}❌ Dockerfile 配置有误${NC}"
fi

if [ "$script_correct" = true ]; then
    echo -e "${GREEN}✅ 部署脚本配置正确${NC}"
else
    echo -e "${RED}❌ 部署脚本配置有误${NC}"
fi

if [ "$old_registry_usage" = false ]; then
    echo -e "${GREEN}✅ 已完全移除旧注册表地址${NC}"
else
    echo -e "${RED}❌ 还有旧注册表地址需要清理${NC}"
fi

# 5. 给出建议
echo ""
echo "💡 配置建议："
echo "  1. 使用官方镜像名：node:18-alpine, python:3.11-slim, nginx:alpine"
echo "  2. 配置腾讯云镜像加速器：https://mirror.ccs.tencentyun.com"
echo "  3. 配置腾讯云 DNS：119.29.29.29"
echo "  4. 避免使用 ccr.ccs.tencentyun.com/library/ 前缀"

if [ "$dockerfile_correct" = true ] && [ "$script_correct" = true ] && [ "$old_registry_usage" = false ]; then
    echo ""
    echo -e "${GREEN}🎉 所有配置都已正确设置！可以进行部署了。${NC}"
    exit 0
else
    echo ""
    echo -e "${YELLOW}⚠️ 还有一些配置需要调整，请检查上述错误。${NC}"
    exit 1
fi
