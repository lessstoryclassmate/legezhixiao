#!/bin/bash

# AI小说编辑器 - 百度云服务器直接部署脚本
# 目标服务器: 106.13.216.179
# 用户: root
# 数据库: MySQL 8.0 (内网)

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
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
SERVER_PORT="22"
DEPLOY_PATH="/root/novel-editor"

# 检查本地环境
check_local_environment() {
    log_info "检查本地部署环境..."
    
    # 检查必要工具
    if ! command -v ssh &> /dev/null; then
        log_error "SSH客户端未安装"
        exit 1
    fi
    
    if ! command -v scp &> /dev/null; then
        log_error "SCP工具未安装"
        exit 1
    fi
    
    # 检查SSH密钥
    if [ ! -f ~/.ssh/id_rsa ]; then
        log_warning "SSH密钥不存在，请确保已配置SSH免密登录"
        echo -n "是否继续使用密码登录? (y/N): "
        read continue_with_password
        if [[ ! "$continue_with_password" =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    log_success "本地环境检查完成"
}

# 创建部署包
create_deployment_package() {
    log_info "创建部署包..."
    
    # 创建临时部署目录
    TEMP_DIR=$(mktemp -d)
    DEPLOY_PACKAGE="$TEMP_DIR/novel-editor-deploy"
    
    mkdir -p "$DEPLOY_PACKAGE"
    
    # 复制必要文件
    cp -r backend/ "$DEPLOY_PACKAGE/"
    cp -r frontend/ "$DEPLOY_PACKAGE/"
    cp -r nginx/ "$DEPLOY_PACKAGE/"
    cp docker-compose.prod.yml "$DEPLOY_PACKAGE/"
    cp .env.prod.example "$DEPLOY_PACKAGE/"
    
    # 创建百度云专用环境配置
    cat > "$DEPLOY_PACKAGE/.env.prod" << EOF
# AI小说编辑器 - 百度云生产环境配置
# 生成时间: $(date)

# ===========================================
# 应用基本配置
# ===========================================
APP_NAME=AI小说编辑器
APP_VERSION=1.0.0
DEBUG=false
ENVIRONMENT=production

# ===========================================
# 网络配置
# ===========================================
FRONTEND_PORT=80
FRONTEND_HTTPS_PORT=443
BACKEND_PORT=8000

# ===========================================
# 数据库配置（百度云内网）
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
# 百度云服务器配置
# ===========================================
SERVER_IP=106.13.216.179
CORS_ORIGINS=["http://106.13.216.179", "https://106.13.216.179"]

# ===========================================
# 性能配置
# ===========================================
WORKERS=4
MAX_CONNECTIONS=1000
KEEPALIVE_TIMEOUT=5
EOF

    # 创建百度云专用部署脚本
    cat > "$DEPLOY_PACKAGE/deploy-baidu.sh" << 'DEPLOY_SCRIPT'
#!/bin/bash

# 百度云服务器部署脚本
set -e

echo "🚀 开始部署AI小说编辑器到百度云服务器..."

# 检查Docker和Docker Compose
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

# 停止现有服务
echo "停止现有服务..."
docker-compose -f docker-compose.prod.yml down || true

# 清理旧容器和镜像
echo "清理系统..."
docker system prune -f

# 构建并启动服务
echo "构建并启动服务..."
docker-compose -f docker-compose.prod.yml up -d --build

# 等待服务启动
echo "等待服务启动..."
sleep 45

# 检查服务状态
echo "检查服务状态..."
docker-compose -f docker-compose.prod.yml ps

# 健康检查
echo "进行健康检查..."
if curl -f http://localhost:8000/health; then
    echo "✅ 后端服务健康检查通过"
else
    echo "❌ 后端服务健康检查失败"
fi

if curl -f http://localhost/; then
    echo "✅ 前端服务健康检查通过"
else
    echo "❌ 前端服务健康检查失败"
fi

echo "🎉 部署完成！"
echo "前端地址: http://106.13.216.179"
echo "API文档: http://106.13.216.179:8000/docs"
echo "健康检查: http://106.13.216.179:8000/health"
DEPLOY_SCRIPT

    chmod +x "$DEPLOY_PACKAGE/deploy-baidu.sh"
    
    echo "$DEPLOY_PACKAGE"
}

# 上传文件到服务器
upload_to_server() {
    local deploy_package=$1
    
    log_info "上传部署包到百度云服务器..."
    
    # 创建远程目录
    ssh -p $SERVER_PORT $SERVER_USER@$SERVER_IP "mkdir -p $DEPLOY_PATH"
    
    # 上传部署包
    scp -P $SERVER_PORT -r "$deploy_package/"* "$SERVER_USER@$SERVER_IP:$DEPLOY_PATH/"
    
    log_success "文件上传完成"
}

# 执行远程部署
execute_remote_deployment() {
    log_info "在百度云服务器上执行部署..."
    
    ssh -p $SERVER_PORT $SERVER_USER@$SERVER_IP << 'REMOTE_SCRIPT'
        cd /root/novel-editor
        
        echo "🔍 当前工作目录: $(pwd)"
        echo "📁 文件列表:"
        ls -la
        
        # 确保脚本可执行
        chmod +x deploy-baidu.sh
        
        # 执行部署
        ./deploy-baidu.sh
REMOTE_SCRIPT
    
    log_success "远程部署执行完成"
}

# 验证部署结果
verify_deployment() {
    log_info "验证部署结果..."
    
    # 检查服务状态
    ssh -p $SERVER_PORT $SERVER_USER@$SERVER_IP << 'VERIFY_SCRIPT'
        echo "🔍 验证部署状态..."
        
        echo "📊 Docker容器状态:"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        
        echo "📈 资源使用情况:"
        docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"
        
        echo "🌐 网络连接测试:"
        netstat -tlnp | grep -E ":(80|8000|3306)" || echo "端口监听检查"
        
        echo "💾 磁盘使用情况:"
        df -h | grep -E "(/$|/var)" || echo "磁盘空间检查"
VERIFY_SCRIPT
    
    # 本地连接测试
    log_info "本地连接测试..."
    
    if curl -f -m 10 "http://$SERVER_IP:8000/health" > /dev/null 2>&1; then
        log_success "后端API连接成功"
    else
        log_warning "后端API连接失败，可能需要等待更长时间"
    fi
    
    if curl -f -m 10 "http://$SERVER_IP/" > /dev/null 2>&1; then
        log_success "前端页面连接成功"
    else
        log_warning "前端页面连接失败，可能需要等待更长时间"
    fi
}

# 显示部署结果
show_deployment_result() {
    log_success "=========================================="
    log_success "   🎉 百度云部署完成！"
    log_success "=========================================="
    echo ""
    echo "🌐 访问地址:"
    echo "   前端页面: http://106.13.216.179"
    echo "   API文档:  http://106.13.216.179:8000/docs"
    echo "   健康检查: http://106.13.216.179:8000/health"
    echo ""
    echo "🔧 管理命令 (在服务器上执行):"
    echo "   查看状态: docker-compose -f docker-compose.prod.yml ps"
    echo "   查看日志: docker-compose -f docker-compose.prod.yml logs"
    echo "   重启服务: docker-compose -f docker-compose.prod.yml restart"
    echo "   停止服务: docker-compose -f docker-compose.prod.yml down"
    echo ""
    echo "📊 服务配置:"
    echo "   数据库: 172.16.16.3:3306 (系统) / 172.16.16.2:3306 (用户)"
    echo "   AI模型: DeepSeek-V3 (SiliconFlow)"
    echo "   端口: 80 (前端), 8000 (后端), 22 (SSH), 30080 (备用)"
    echo ""
    log_success "部署成功！享受AI小说创作之旅！🎨"
}

# 主函数
main() {
    echo ""
    log_info "=========================================="
    log_info "  AI小说编辑器 - 百度云直接部署"
    log_info "=========================================="
    echo ""
    
    # 检查本地环境
    check_local_environment
    
    # 创建部署包
    DEPLOY_PACKAGE=$(create_deployment_package)
    
    # 上传到服务器
    upload_to_server "$DEPLOY_PACKAGE"
    
    # 执行远程部署
    execute_remote_deployment
    
    # 验证部署结果
    verify_deployment
    
    # 显示结果
    show_deployment_result
    
    # 清理临时文件
    rm -rf "$(dirname "$DEPLOY_PACKAGE")"
}

# 命令行参数处理
case "${1:-}" in
    --help|-h)
        echo "用法: $0 [选项]"
        echo ""
        echo "选项:"
        echo "  --help, -h     显示帮助信息"
        echo "  --check        仅检查连接，不执行部署"
        echo ""
        echo "示例:"
        echo "  $0             执行完整部署"
        echo "  $0 --check     检查服务器连接"
        exit 0
        ;;
    --check)
        log_info "检查服务器连接..."
        if ssh -p $SERVER_PORT -o ConnectTimeout=10 $SERVER_USER@$SERVER_IP "echo '连接成功'"; then
            log_success "服务器连接正常"
        else
            log_error "服务器连接失败"
            exit 1
        fi
        exit 0
        ;;
    "")
        main
        ;;
    *)
        log_error "未知参数: $1"
        echo "使用 --help 查看帮助信息"
        exit 1
        ;;
esac
