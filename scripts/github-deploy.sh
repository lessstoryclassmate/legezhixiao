#!/bin/bash

# GitHub仓库克隆部署脚本
# 适用于百度云服务器Ubuntu 24.04 LTS

set -e

# 配置变量
REPO_URL="https://github.com/your-username/ai-novel-editor.git"
PROJECT_NAME="ai-novel-editor"
DEPLOY_DIR="/opt/${PROJECT_NAME}"
BACKUP_DIR="/opt/backups/${PROJECT_NAME}"
LOG_FILE="/var/log/${PROJECT_NAME}-deploy.log"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}" | tee -a "$LOG_FILE"
}

# 检查系统环境
        apt-transport-https \
        ca-certificates \
        gnupg \
        lsb-release
    
    log "基础依赖安装完成"
}

# 安装Docker
install_docker() {
    if command -v docker &> /dev/null; then
        log "Docker已安装，跳过安装"
        return
    fi
    
    log "安装Docker..."
    
    # 添加Docker官方GPG密钥
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # 添加Docker仓库
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # 安装Docker
    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
    
    # 启动Docker服务
    
    # 添加用户到docker组
    sudo usermod -aG docker $USER
    
    log "Docker安装完成"
}

# 安装Docker Compose
install_docker_compose() {
    if command -v docker-compose &> /dev/null; then
        log "Docker Compose已安装，跳过安装"
        return
    fi
    
    log "安装Docker Compose..."
    
    # 下载Docker Compose
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
    sudo curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    
    # 设置执行权限
    sudo chmod +x /usr/local/bin/docker-compose
    
    # 创建软链接
    sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    
    log "Docker Compose安装完成"
}

# 克隆或更新代码
clone_or_update_code() {
    log "处理代码仓库..."
    
    # 创建部署目录
    sudo mkdir -p "$DEPLOY_DIR"
    sudo chown $USER:$USER "$DEPLOY_DIR"
    
    if [[ -d "$DEPLOY_DIR/.git" ]]; then
        log "更新现有代码..."
        cd "$DEPLOY_DIR"
        git pull origin main
    else
        log "克隆代码仓库..."
        git clone "$REPO_URL" "$DEPLOY_DIR"
        cd "$DEPLOY_DIR"
    fi
    
    log "代码处理完成"
}

# 备份现有部署
backup_deployment() {
    if [[ -d "$DEPLOY_DIR" ]] && [[ -f "$DEPLOY_DIR/docker-compose.yml" ]]; then
        log "备份现有部署..."
        
        # 创建备份目录
        sudo mkdir -p "$BACKUP_DIR"
        BACKUP_NAME="${PROJECT_NAME}-$(date +%Y%m%d_%H%M%S)"
        
        # 停止现有服务
        cd "$DEPLOY_DIR"
        docker-compose down || true
        
        # 备份数据卷
        sudo cp -r "$DEPLOY_DIR" "${BACKUP_DIR}/${BACKUP_NAME}"
        
        log "备份完成: ${BACKUP_DIR}/${BACKUP_NAME}"
    fi
}

# 配置环境变量
setup_environment() {
    log "配置环境变量..."
    
    cd "$DEPLOY_DIR"
    
    if [[ ! -f .env ]]; then
        if [[ -f .env.example ]]; then
            cp .env.example .env
            warning "请编辑 .env 文件配置必要的环境变量"
        else
            error "未找到环境变量配置文件"
            exit 1
        fi
    fi
    
    log "环境变量配置完成"
}

# 部署应用
deploy_application() {
    log "开始部署应用..."
    
    cd "$DEPLOY_DIR"
    
    # 构建并启动服务
    docker-compose build --no-cache
    docker-compose up -d
    
    # 等待服务启动
    sleep 30
    
    log "应用部署完成"
}

# 健康检查
health_check() {
    log "执行健康检查..."
    
    # 检查容器状态
    cd "$DEPLOY_DIR"
    if ! docker-compose ps | grep -q "Up"; then
        error "服务启动失败"
        docker-compose logs
        exit 1
    fi
    
    # 检查前端服务
    if curl -f http://localhost:80 > /dev/null 2>&1; then
        log "前端服务正常"
    else
        error "前端服务异常"
        exit 1
    fi
    
    # 检查后端服务
    if curl -f http://localhost:8000/health > /dev/null 2>&1; then
        log "后端服务正常"
    else
        error "后端服务异常"
        exit 1
    fi
    
    log "健康检查通过"
}

# 配置防火墙
configure_firewall() {
    log "配置防火墙..."
    
    # 启用UFW
    sudo ufw --force enable
    
    # 允许SSH
    sudo ufw allow ssh
    
    # 允许HTTP
    sudo ufw allow 80/tcp
    
    # 允许HTTPS（预留）
    sudo ufw allow 443/tcp
    
    log "防火墙配置完成"
}

# 已移除 systemd 相关配置函数，全部由 Docker Compose 管理。

# 显示部署信息
show_deployment_info() {
    log "部署完成！"
    echo -e "${BLUE}===========================================${NC}"
    echo -e "${GREEN}🎉 AI小说内容编辑器部署成功！${NC}"
    echo -e "${BLUE}===========================================${NC}"
    echo -e "${YELLOW}📝 访问信息：${NC}"
    echo "   🌐 应用地址: http://$(curl -s ifconfig.me):80"
    echo "   🔧 后端API: http://$(curl -s ifconfig.me):8000"
    echo "   📚 API文档: http://$(curl -s ifconfig.me):8000/docs"
    echo ""
    echo -e "${YELLOW}🛠️  管理命令：${NC}"
    echo "   查看日志: docker-compose logs -f"
    echo ""
    echo -e "${YELLOW}📁 重要路径：${NC}"
    echo "   部署目录: ${DEPLOY_DIR}"
    echo "   备份目录: ${BACKUP_DIR}"
    echo "   日志文件: ${LOG_FILE}"
    echo -e "${BLUE}===========================================${NC}"
}

# 主函数
main() {
    log "开始部署AI小说内容编辑器..."
    
    # 检查是否为root用户
    if [[ $EUID -eq 0 ]]; then
        error "请不要使用root用户运行此脚本"
        exit 1
    fi
    
    # 创建日志目录
    sudo mkdir -p $(dirname "$LOG_FILE")
    sudo touch "$LOG_FILE"
    sudo chown $USER:$USER "$LOG_FILE"
    
    # 执行部署步骤
    check_system
    install_dependencies
    install_docker
    install_docker_compose
    backup_deployment
    clone_or_update_code
    setup_environment
    deploy_application
    health_check
    configure_firewall
    show_deployment_info
    
    log "部署流程完成"
}

# 处理命令行参数
case "${1:-}" in
    "update")
        log "执行更新操作..."
        clone_or_update_code
        deploy_application
        health_check
        ;;
    "backup")
        backup_deployment
        ;;
    "logs")
        tail -f "$LOG_FILE"
        ;;
    "status")
        cd "$DEPLOY_DIR"
        docker-compose ps
        ;;
    *)
        main
        ;;
esac
