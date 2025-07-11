#!/bin/bash

# 快速检查部署状态脚本
# 验证所有服务是否正常运行

set -e

echo "🔍 检查乐极智效服务部署状态"
echo "=================================="

SERVER_IP="106.13.216.179"
BASE_URL="http://$SERVER_IP"

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

# 检查服务器连通性
echo "🌐 检查服务器连通性..."
if ping -c 3 $SERVER_IP > /dev/null 2>&1; then
    print_status "OK" "服务器 $SERVER_IP 可达"
else
    print_status "ERROR" "服务器 $SERVER_IP 不可达"
    exit 1
fi

# 检查前端服务
echo ""
echo "🎨 检查前端服务..."
FRONTEND_URL="$BASE_URL:80"
if curl -s -f "$FRONTEND_URL" > /dev/null; then
    print_status "OK" "前端服务运行正常 - $FRONTEND_URL"
    
    # 检查前端页面内容
    FRONTEND_CONTENT=$(curl -s "$FRONTEND_URL" | head -10)
    if echo "$FRONTEND_CONTENT" | grep -q "乐极智效" || echo "$FRONTEND_CONTENT" | grep -q "Vue"; then
        print_status "OK" "前端页面内容正确"
    else
        print_status "WARN" "前端页面内容可能不正确"
    fi
else
    print_status "ERROR" "前端服务不可用 - $FRONTEND_URL"
fi

# 检查后端API服务
echo ""
echo "🔧 检查后端API服务..."
API_HEALTH_URL="$BASE_URL:8001/health"
if HEALTH_RESPONSE=$(curl -s -f "$API_HEALTH_URL" 2>/dev/null); then
    print_status "OK" "后端API健康检查通过 - $API_HEALTH_URL"
    
    # 解析健康检查响应
    if echo "$HEALTH_RESPONSE" | grep -q '"status":"healthy"'; then
        print_status "OK" "API服务状态正常"
    else
        print_status "WARN" "API服务状态异常: $HEALTH_RESPONSE"
    fi
    
    if echo "$HEALTH_RESPONSE" | grep -q '"database":"connected"'; then
        print_status "OK" "数据库连接正常"
    else
        print_status "ERROR" "数据库连接异常"
    fi
    
    if echo "$HEALTH_RESPONSE" | grep -q '"redis":"connected"'; then
        print_status "OK" "Redis连接正常"
    else
        print_status "WARN" "Redis连接异常"
    fi
else
    print_status "ERROR" "后端API健康检查失败 - $API_HEALTH_URL"
fi

# 检查认证服务
echo ""
echo "🔐 检查认证服务..."
LOGIN_URL="$BASE_URL:8001/auth/login"
LOGIN_DATA='{"username":"admin","password":"369369"}'

if LOGIN_RESPONSE=$(curl -s -X POST "$LOGIN_URL" \
    -H "Content-Type: application/json" \
    -d "$LOGIN_DATA" 2>/dev/null); then
    
    if echo "$LOGIN_RESPONSE" | grep -q '"access_token"'; then
        print_status "OK" "用户认证服务正常"
        print_status "OK" "测试用户 admin/369369 登录成功"
    else
        print_status "ERROR" "用户认证失败: $LOGIN_RESPONSE"
    fi
else
    print_status "ERROR" "无法连接认证服务 - $LOGIN_URL"
fi

# 检查API文档
echo ""
echo "📚 检查API文档..."
DOCS_URL="$BASE_URL:8001/docs"
if curl -s -f "$DOCS_URL" > /dev/null; then
    print_status "OK" "API文档可访问 - $DOCS_URL"
else
    print_status "WARN" "API文档不可访问 - $DOCS_URL"
fi

# 检查端口占用
echo ""
echo "🔌 检查端口状态..."
check_port() {
    local port=$1
    local service=$2
    if nc -z $SERVER_IP $port 2>/dev/null; then
        print_status "OK" "$service 端口 $port 开放"
    else
        print_status "ERROR" "$service 端口 $port 未开放"
    fi
}

check_port 80 "前端HTTP"
check_port 8001 "后端API"

# 性能检查
echo ""
echo "⚡ 性能检查..."
RESPONSE_TIME=$(curl -o /dev/null -s -w '%{time_total}' "$FRONTEND_URL" || echo "failed")
if [ "$RESPONSE_TIME" != "failed" ] && (( $(echo "$RESPONSE_TIME < 2.0" | bc -l 2>/dev/null || echo 0) )); then
    print_status "OK" "前端响应时间: ${RESPONSE_TIME}s"
elif [ "$RESPONSE_TIME" != "failed" ]; then
    print_status "WARN" "前端响应时间较慢: ${RESPONSE_TIME}s"
else
    print_status "ERROR" "前端响应时间测试失败"
fi

# 总结
echo ""
echo "📊 部署状态总结"
echo "=================================="
echo -e "🌐 服务器地址: ${BLUE}$SERVER_IP${NC}"
echo -e "🎨 前端访问: ${BLUE}$BASE_URL:80${NC}"
echo -e "🔧 API访问: ${BLUE}$BASE_URL:8001${NC}"
echo -e "📚 API文档: ${BLUE}$BASE_URL:8001/docs${NC}"
echo -e "🔐 测试用户: ${BLUE}admin / 369369${NC}"
echo ""
echo -e "${GREEN}✨ 检查完成！请在浏览器中访问 $BASE_URL 体验乐极智效编辑器${NC}"
  3. SERVER_USER          - 服务器用户名 (通常是root)
  4. SILICONFLOW_API_KEY  - SiliconFlow API密钥
  5. JWT_SECRET_KEY       - JWT加密密钥
  6. MONGO_PASSWORD       - MongoDB密码
  7. REDIS_PASSWORD       - Redis密码

  配置路径: GitHub仓库 → Settings → Secrets and variables → Actions
EOF
echo ""

# 服务器要求检查
echo -e "${BLUE}💻 服务器环境要求:${NC}"
cat << EOF
  确保百度云服务器满足以下要求:
  
  1. ✅ 操作系统: Ubuntu 20.04+ 或 CentOS 7+
  2. ✅ Docker: 20.10+
  3. ✅ Docker Compose: 2.0+
  4. ✅ 内存: 至少 2GB
  5. ✅ 存储: 至少 10GB 可用空间
  6. ✅ 端口开放: 80, 8000, 22 (SSH)
  
  网络安全组配置:
  - 入站规则: 允许 TCP 80 (HTTP)
  - 入站规则: 允许 TCP 8000 (API)
  - 入站规则: 允许 TCP 22 (SSH)
EOF
echo ""

# 部署后验证脚本
echo -e "${BLUE}✅ 部署成功后的验证步骤:${NC}"
cat << 'EOF'
  部署完成后，可以使用以下命令验证:
  
  # 1. 检查前端服务
  curl -I http://YOUR_SERVER_IP:80
  
  # 2. 检查后端API
  curl http://YOUR_SERVER_IP:8000/health
  
  # 3. 检查API文档
  curl -I http://YOUR_SERVER_IP:8000/docs
  
  # 4. 测试登录API
  curl -X POST "http://YOUR_SERVER_IP:8000/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"email": "admin@test.com", "password": "369369"}'
  
  # 5. 访问VSCode风格编辑器
  # 浏览器访问: http://YOUR_SERVER_IP:80/editor
EOF
echo ""

# 故障排除
echo -e "${BLUE}🔧 故障排除:${NC}"
cat << 'EOF'
  如果部署失败，检查以下内容:
  
  1. GitHub Actions日志:
     - 在GitHub仓库页面查看Actions标签
     - 查看具体的错误信息
  
  2. 服务器连接:
     ssh your_user@your_server_ip
     
  3. Docker服务:
     systemctl status docker
     docker-compose ps
     
  4. 查看应用日志:
     cd /opt/ai-novel-editor
     docker-compose logs --tail=50
     
  5. 重启服务:
     docker-compose restart
     
  6. 清理重建:
     docker-compose down
     docker system prune -f
     docker-compose up -d --build
EOF
echo ""

echo -e "${GREEN}🚀 准备部署到百度云!${NC}"
echo "一旦GitHub Secrets配置完成，推送到main分支即可触发自动部署。"
echo ""

# 如果有参数，可以执行实时监控
if [ "$1" == "--monitor" ]; then
    echo -e "${YELLOW}📡 开始监控部署状态...${NC}"
    echo "按 Ctrl+C 停止监控"
    
    while true; do
        echo -e "\n$(date '+%H:%M:%S') - 检查服务状态..."
        
        # 这里需要替换为实际的服务器IP
        if [ -n "${SERVER_IP}" ]; then
            # 检查前端
            if curl -s --max-time 5 "http://${SERVER_IP}:80" > /dev/null 2>&1; then
                echo -e "${GREEN}✅ 前端服务正常${NC}"
            else
                echo -e "${RED}❌ 前端服务异常${NC}"
            fi
            
            # 检查后端
            if curl -s --max-time 5 "http://${SERVER_IP}:8000/health" > /dev/null 2>&1; then
                echo -e "${GREEN}✅ 后端API正常${NC}"
            else
                echo -e "${RED}❌ 后端API异常${NC}"
            fi
        else
            echo -e "${YELLOW}⚠️  请设置 SERVER_IP 环境变量来启用实时监控${NC}"
            break
        fi
        
        sleep 30
    done
fi
