#!/bin/bash

# 本地开发环境检查脚本
# 验证本地服务是否正常运行

set -e

echo "🔍 检查本地开发环境状态"
echo "========================="

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    local status=$1
    local message=$2
    if [ "$status" = "OK" ]; then
        echo -e "${GREEN}✅ $message${NC}"
    elif [ "$status" = "WARN" ]; then
        echo -e "${YELLOW}⚠️  $message${NC}"
    else
        echo -e "${RED}❌ $message${NC}"
    fi
}

# 检查Docker
echo "🐳 检查Docker环境..."
if command -v docker &> /dev/null; then
    print_status "OK" "Docker已安装"
    
    if docker info &> /dev/null; then
        print_status "OK" "Docker服务运行正常"
    else
        print_status "ERROR" "Docker服务未运行"
    fi
else
    print_status "ERROR" "Docker未安装"
fi

# 检查Docker Compose
if command -v docker-compose &> /dev/null; then
    print_status "OK" "Docker Compose已安装"
else
    print_status "ERROR" "Docker Compose未安装"
fi

# 检查项目文件
echo ""
echo "📁 检查项目文件..."
if [ -f "docker-compose.yml" ]; then
    print_status "OK" "docker-compose.yml 存在"
else
    print_status "ERROR" "docker-compose.yml 不存在"
fi

if [ -f "frontend/package.json" ]; then
    print_status "OK" "frontend/package.json 存在"
else
    print_status "ERROR" "frontend/package.json 不存在"
fi

if [ -f "backend/main.py" ]; then
    print_status "OK" "backend/main.py 存在"
else
    print_status "ERROR" "backend/main.py 不存在"
fi

# 检查容器状态
echo ""
echo "📦 检查Docker容器状态..."
if docker-compose ps &> /dev/null; then
    RUNNING_CONTAINERS=$(docker-compose ps --services --filter "status=running" 2>/dev/null || echo "")
    
    if echo "$RUNNING_CONTAINERS" | grep -q "mongodb"; then
        print_status "OK" "MongoDB容器运行中"
    else
        print_status "WARN" "MongoDB容器未运行"
    fi
    
    if echo "$RUNNING_CONTAINERS" | grep -q "redis"; then
        print_status "OK" "Redis容器运行中"
    else
        print_status "WARN" "Redis容器未运行"
    fi
    
    if echo "$RUNNING_CONTAINERS" | grep -q "backend"; then
        print_status "OK" "后端容器运行中"
    else
        print_status "WARN" "后端容器未运行"
    fi
    
    if echo "$RUNNING_CONTAINERS" | grep -q "frontend"; then
        print_status "OK" "前端容器运行中"
    else
        print_status "WARN" "前端容器未运行"
    fi
else
    print_status "WARN" "Docker Compose未启动或配置错误"
fi

# 检查本地服务
echo ""
echo "🌐 检查本地服务..."
check_local_service() {
    local port=$1
    local service=$2
    if curl -s -f "http://localhost:$port" > /dev/null 2>&1; then
        print_status "OK" "$service 服务可访问 (localhost:$port)"
    else
        print_status "WARN" "$service 服务不可访问 (localhost:$port)"
    fi
}

check_local_service 80 "前端"
check_local_service 8001 "后端API"

# 检查API健康状态
echo ""
echo "🔧 检查API健康状态..."
if HEALTH_RESPONSE=$(curl -s "http://localhost:8001/health" 2>/dev/null); then
    print_status "OK" "API健康检查可访问"
    
    if echo "$HEALTH_RESPONSE" | grep -q '"status":"healthy"'; then
        print_status "OK" "API服务状态正常"
    else
        print_status "WARN" "API服务状态异常"
    fi
else
    print_status "WARN" "API健康检查不可访问"
fi

# 检查环境变量
echo ""
echo "🔧 检查环境变量..."
if [ -f ".env" ]; then
    print_status "OK" ".env 文件存在"
else
    print_status "WARN" ".env 文件不存在"
fi

# 检查Git状态
echo ""
echo "📝 检查Git状态..."
if git status &> /dev/null; then
    print_status "OK" "Git仓库正常"
    
    UNCOMMITTED=$(git status --porcelain | wc -l)
    if [ "$UNCOMMITTED" -eq 0 ]; then
        print_status "OK" "没有未提交的更改"
    else
        print_status "WARN" "有 $UNCOMMITTED 个未提交的更改"
    fi
    
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    print_status "OK" "当前分支: $CURRENT_BRANCH"
else
    print_status "ERROR" "不在Git仓库中"
fi

# 启动建议
echo ""
echo "🚀 启动建议"
echo "========================="
echo "如果服务未运行，请执行以下命令："
echo ""
echo -e "${BLUE}# 启动所有服务${NC}"
echo "docker-compose up -d"
echo ""
echo -e "${BLUE}# 查看服务日志${NC}"
echo "docker-compose logs -f"
echo ""
echo -e "${BLUE}# 重新构建服务${NC}"
echo "docker-compose up --build -d"
echo ""
echo -e "${BLUE}# 停止所有服务${NC}"
echo "docker-compose down"
echo ""
echo "服务运行后可以访问："
echo -e "🎨 前端: ${BLUE}http://localhost:80${NC}"
echo -e "🔧 API: ${BLUE}http://localhost:8001${NC}"
echo -e "📚 API文档: ${BLUE}http://localhost:8001/docs${NC}"
