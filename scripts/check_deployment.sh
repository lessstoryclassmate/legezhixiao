#!/bin/bash

# 部署状态检查脚本
# 用于检查CI/CD部署状态和服务健康

set -e

echo "🔍 检查GitHub Actions CI/CD部署状态"
echo "=================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 获取最新commit信息
LATEST_COMMIT=$(git rev-parse HEAD)
BRANCH=$(git rev-parse --abbrev-ref HEAD)

echo -e "${BLUE}📊 当前代码状态:${NC}"
echo "  分支: $BRANCH"
echo "  提交: $LATEST_COMMIT"
echo "  推送时间: $(git log -1 --format='%ci')"
echo ""

# 检查GitHub Actions状态
echo -e "${BLUE}🔄 GitHub Actions 工作流状态:${NC}"
echo "  可以在以下链接查看构建状态:"
echo "  https://github.com/lessstoryclassmate/legezhixiao/actions"
echo ""

# 检查需要的GitHub Secrets
echo -e "${BLUE}🔐 需要的GitHub Secrets:${NC}"
cat << EOF
  以下Secrets需要在GitHub仓库设置中配置:
  
  1. SERVER_SSH_KEY        - 服务器SSH私钥
  2. SERVER_IP            - 百度云服务器IP地址
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
