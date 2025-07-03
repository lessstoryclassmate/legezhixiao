#!/bin/bash

# 百度云服务器直接部署脚本
# 服务器: 106.13.216.179
# 用户: root

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 服务器配置
SERVER_IP="106.13.216.179"
SERVER_USER="root"
DEPLOY_PATH="/root/novel-editor"

# 检查SSH连接
check_ssh_connection() {
    log_info "检查SSH连接到百度云服务器..."
    
    if ssh -o ConnectTimeout=10 $SERVER_USER@$SERVER_IP "echo '连接成功'" 2>/dev/null; then
        log_success "SSH连接正常"
        return 0
    else
        log_error "SSH连接失败，请检查："
        echo "1. 服务器IP是否正确: $SERVER_IP"
        echo "2. SSH密钥是否配置正确"
        echo "3. 服务器是否允许SSH连接"
        return 1
    fi
}

# 创建生产环境配置
create_production_config() {
    log_info "创建生产环境配置文件..."
    
    cat > .env.prod << EOF
# AI小说编辑器 - 百度云服务器生产环境配置
# 生成时间: $(date)

# ===========================================
# 应用基本配置
# ===========================================
DEBUG=false
ENVIRONMENT=production
APP_NAME=AI小说编辑器
APP_VERSION=1.0.0

# ===========================================
# 网络配置
# ===========================================
FRONTEND_PORT=80
BACKEND_PORT=8000
SERVER_HOST=$SERVER_IP

# ===========================================
# 数据库配置 (百度云MySQL)
# ===========================================
DATABASE_PORT=3306

# 系统数据库
DATABASE_SYSTEMIP=172.16.16.3
DATABASE_SYSTEM=novel_data
DATABASE_USER=lkr
DATABASE_PASSWORD=Lekairong350702

# 用户数据库
DATABASE_NOVELIP=172.16.16.2
DATABASE_NOVELDATA=novel_user_data
DATABASE_NOVELUSER=novel_data_user
DATABASE_NOVELUSER_PASSWORD=Lekairong350702

# ===========================================
# AI服务配置
# ===========================================
SILICONFLOW_API_KEY=sk-mjithqmjwccqgffouexthbavtnvftwkqjludpcxhrmeztcib
SILICONFLOW_API_URL=https://api.siliconflow.cn/v1
DEFAULT_AI_MODEL=deepseek-ai/DeepSeek-V3

# 备用AI模型
ALTERNATIVE_MODELS=Qwen/QwQ-32B,THUDM/GLM-4-9B-0414,baidu/ERNIE-4.5-300B-A47B

# ===========================================
# 安全配置
# ===========================================
SECRET_KEY=baidu-cloud-novel-editor-secret-key-2025
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# ===========================================
# 日志配置
# ===========================================
LOG_LEVEL=INFO
LOG_FILE=/app/logs/app.log

# ===========================================
# CORS配置
# ===========================================
CORS_ORIGINS=["http://$SERVER_IP", "https://$SERVER_IP", "http://localhost", "http://127.0.0.1"]

EOF

    log_success "生产环境配置文件创建完成"
}

# 部署到百度云服务器
deploy_to_baidu_cloud() {
    log_info "开始部署到百度云服务器..."
    
    # 上传项目文件
    log_info "上传项目文件到服务器..."
    rsync -avz --exclude='node_modules' --exclude='.git' --exclude='__pycache__' \
          ./ $SERVER_USER@$SERVER_IP:$DEPLOY_PATH/
    
    # 在服务器上执行部署
    ssh $SERVER_USER@$SERVER_IP << 'DEPLOY_SCRIPT'
        set -e
        
        cd /root/novel-editor
        
        echo "📋 当前部署路径: $(pwd)"
        echo "📁 项目文件列表:"
        ls -la
        
        echo "🔧 检查Docker环境..."
        if ! command -v docker &> /dev/null; then
            echo "安装Docker..."
            curl -fsSL https://get.docker.com -o get-docker.sh
            sh get-docker.sh
            systemctl start docker
            systemctl enable docker
        fi
        
        if ! command -v docker-compose &> /dev/null; then
            echo "安装Docker Compose..."
            curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            chmod +x /usr/local/bin/docker-compose
        fi
        
        echo "🛑 停止现有服务..."
        docker-compose -f docker-compose.prod.yml down || true
        
        echo "🧹 清理旧容器和镜像..."
        docker system prune -f
        
        echo "🏗️ 构建Docker镜像..."
        docker-compose -f docker-compose.prod.yml build --no-cache
        
        echo "🚀 启动服务..."
        docker-compose -f docker-compose.prod.yml up -d
        
        echo "⏳ 等待服务启动..."
        sleep 45
        
        echo "🔍 检查服务状态..."
        docker-compose -f docker-compose.prod.yml ps
        
        echo "💓 健康检查..."
        curl -f http://localhost:8000/health || echo "Backend health check pending..."
        curl -f http://localhost/ || echo "Frontend health check pending..."
        
        echo "📊 显示服务日志..."
        docker-compose -f docker-compose.prod.yml logs --tail=20
        
        echo "🔥 配置防火墙..."
        ufw allow 22/tcp  # SSH
        ufw allow 80/tcp  # HTTP
        ufw allow 443/tcp # HTTPS
        ufw allow 8000/tcp # API
        ufw --force enable || echo "防火墙配置完成"
        
        echo "🎉 部署完成！"
        echo "前端地址: http://106.13.216.179"
        echo "API文档: http://106.13.216.179:8000/docs"
        echo "健康检查: http://106.13.216.179:8000/health"
DEPLOY_SCRIPT
}

# 验证部署结果
verify_deployment() {
    log_info "验证部署结果..."
    
    echo "🌐 服务地址验证:"
    echo "  前端页面: http://$SERVER_IP"
    echo "  API文档: http://$SERVER_IP:8000/docs"
    echo "  健康检查: http://$SERVER_IP:8000/health"
    
    log_info "远程服务状态检查:"
    ssh $SERVER_USER@$SERVER_IP << 'VERIFY_SCRIPT'
        echo "🔍 容器状态:"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        
        echo "📈 资源使用:"
        docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"
        
        echo "🔧 系统信息:"
        echo "  系统: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
        echo "  内存: $(free -h | grep Mem | awk '{print $2}')"
        echo "  磁盘: $(df -h / | tail -1 | awk '{print $4}' | sed 's/%/% 可用/')"
        
        echo "🌐 网络测试:"
        curl -s -o /dev/null -w "前端响应时间: %{time_total}s\n" http://localhost/ || echo "前端未响应"
        curl -s -o /dev/null -w "API响应时间: %{time_total}s\n" http://localhost:8000/health || echo "API未响应"
VERIFY_SCRIPT
}

# 主部署流程
main() {
    echo ""
    log_info "=============================================="
    log_info "   AI小说编辑器 - 百度云服务器直接部署"
    log_info "=============================================="
    echo ""
    
    # 检查SSH连接
    if ! check_ssh_connection; then
        exit 1
    fi
    
    # 创建配置文件
    create_production_config
    
    # 执行部署
    deploy_to_baidu_cloud
    
    # 验证部署
    verify_deployment
    
    echo ""
    log_success "🎉 百度云服务器部署完成！"
    echo ""
    echo "📍 访问地址:"
    echo "  🌐 前端页面: http://$SERVER_IP"
    echo "  📖 API文档: http://$SERVER_IP:8000/docs"
    echo "  💓 健康检查: http://$SERVER_IP:8000/health"
    echo ""
    echo "🔧 管理命令:"
    echo "  重启服务: ssh $SERVER_USER@$SERVER_IP 'cd $DEPLOY_PATH && docker-compose -f docker-compose.prod.yml restart'"
    echo "  查看日志: ssh $SERVER_USER@$SERVER_IP 'cd $DEPLOY_PATH && docker-compose -f docker-compose.prod.yml logs -f'"
    echo "  停止服务: ssh $SERVER_USER@$SERVER_IP 'cd $DEPLOY_PATH && docker-compose -f docker-compose.prod.yml down'"
    echo ""
}

# 命令行参数处理
case "${1:-}" in
    "check")
        check_ssh_connection
        ;;
    "config")
        create_production_config
        ;;
    "deploy")
        deploy_to_baidu_cloud
        ;;
    "verify")
        verify_deployment
        ;;
    *)
        main
        ;;
esac
