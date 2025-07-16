#!/bin/bash
# 健康检查脚本 - 本地部署模式
# 检查服务是否正常运行

echo "🔍 开始健康检查..."

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

FRONTEND_PORT="80"
BACKEND_PORT="8000"
HEALTH_CHECK_FAILED=false

# 检查端口监听
echo -e "${BLUE}🔍 检查端口监听...${NC}"
if netstat -tlnp | grep :$FRONTEND_PORT > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 前端端口 $FRONTEND_PORT 监听正常${NC}"
else
    echo -e "${RED}❌ 前端端口 $FRONTEND_PORT 未监听${NC}"
    HEALTH_CHECK_FAILED=true
fi

if netstat -tlnp | grep :$BACKEND_PORT > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 后端端口 $BACKEND_PORT 监听正常${NC}"
else
    echo -e "${RED}❌ 后端端口 $BACKEND_PORT 未监听${NC}"
    HEALTH_CHECK_FAILED=true
fi

# 检查进程状态
echo -e "${BLUE}🔍 检查服务进程...${NC}"
if pgrep -f "uvicorn.*main:app" > /dev/null; then
    echo -e "${GREEN}✅ 后端进程运行正常${NC}"
else
    echo -e "${RED}❌ 后端进程未运行${NC}"
    HEALTH_CHECK_FAILED=true
fi

if pgrep nginx > /dev/null; then
    echo -e "${GREEN}✅ Nginx进程运行正常${NC}"
else
    echo -e "${RED}❌ Nginx进程未运行${NC}"
    HEALTH_CHECK_FAILED=true
fi

# HTTP健康检查
echo -e "${BLUE}🔍 HTTP健康检查...${NC}"

# 检查前端
if curl -f --max-time 10 --connect-timeout 5 http://localhost:$FRONTEND_PORT > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 前端服务健康检查通过${NC}"
else
    echo -e "${RED}❌ 前端服务健康检查失败${NC}"
    HEALTH_CHECK_FAILED=true
fi

# 检查后端健康接口
if curl -f --max-time 10 --connect-timeout 5 http://localhost:$BACKEND_PORT/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 后端API健康检查通过${NC}"
else
    echo -e "${RED}❌ 后端API健康检查失败${NC}"
    HEALTH_CHECK_FAILED=true
    
    # 显示后端服务日志
    echo -e "${YELLOW}🔍 后端服务日志:${NC}"
    if command -v supervisorctl &> /dev/null; then
        supervisorctl tail ai-novel-backend 2>/dev/null || tail -n 20 /var/log/ai-novel-backend.log 2>/dev/null || echo "无法获取后端日志"
    fi
fi

# 检查资源使用情况
echo -e "${BLUE}🔍 检查系统资源...${NC}"
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
MEM_USAGE=$(free | grep Mem | awk '{printf "%.1f", ($3/$2) * 100.0}')
DISK_USAGE=$(df -h / | awk 'NR==2{print $5}' | sed 's/%//')

echo "  CPU使用率: ${CPU_USAGE}%"
echo "  内存使用率: ${MEM_USAGE}%"
echo "  磁盘使用率: ${DISK_USAGE}%"

# 检查是否有资源过载
if (( $(echo "$CPU_USAGE > 80" | bc -l) )); then
    echo -e "${YELLOW}⚠️ CPU使用率过高${NC}"
fi

if (( $(echo "$MEM_USAGE > 80" | bc -l) )); then
    echo -e "${YELLOW}⚠️ 内存使用率过高${NC}"
fi

if [ "$DISK_USAGE" -gt 80 ]; then
    echo -e "${YELLOW}⚠️ 磁盘使用率过高${NC}"
fi

# 总结
echo ""
if [ "$HEALTH_CHECK_FAILED" = true ]; then
    echo -e "${RED}❌ 健康检查失败，请检查服务状态${NC}"
    exit 1
else
    echo -e "${GREEN}✅ 健康检查通过，所有服务运行正常${NC}"
    exit 0
fi
