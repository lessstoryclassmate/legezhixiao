#!/bin/bash

# AI小说编辑器云服务器一键部署脚本
# 支持Ubuntu/CentOS/Debian等主流Linux发行版

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# 检测操作系统
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$NAME
        OS_VERSION=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si)
        OS_VERSION=$(lsb_release -sr)
    else
        log_error "无法检测操作系统类型"
        exit 1
    fi
    
    log_info "检测到操作系统: $OS $OS_VERSION"
}

# 安装Docker
install_docker() {
    log_info "开始安装Docker..."
    
    if command -v docker &> /dev/null; then
        log_success "Docker已安装，版本: $(docker --version)"
        return 0
    fi
    
    # 卸载旧版本
    case $OS in
        "Ubuntu"*|"Debian"*)
            sudo apt-get remove -y docker docker-engine docker.io containerd runc || true
            sudo apt-get update
            sudo apt-get install -y \
                apt-transport-https \
                ca-certificates \
                curl \
                gnupg \
                lsb-release
            
            # 添加Docker的官方GPG密钥
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            
            # 设置稳定版仓库
            echo \
                "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
                $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io
            ;;
        "CentOS"*|"Red Hat"*)
            sudo yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine
            sudo yum install -y yum-utils
            sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            sudo yum install -y docker-ce docker-ce-cli containerd.io
            sudo systemctl start docker
            sudo systemctl enable docker
            ;;
        *)
            log_error "不支持的操作系统: $OS"
            exit 1
            ;;
    esac
    
    # 将当前用户添加到docker组
    sudo usermod -aG docker $USER
    
    log_success "Docker安装完成"
}

# 安装Docker Compose
install_docker_compose() {
    log_info "开始安装Docker Compose..."
    
    if command -v docker-compose &> /dev/null; then
        log_success "Docker Compose已安装，版本: $(docker-compose --version)"
        return 0
    fi
    
    # 获取最新版本
    DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d'"' -f4)
    
    # 下载并安装
    sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    # 创建软链接
    sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    
    log_success "Docker Compose安装完成，版本: $(docker-compose --version)"
}

# 配置防火墙
configure_firewall() {
    log_info "配置防火墙..."
    
    if command -v ufw &> /dev/null; then
        # Ubuntu/Debian使用ufw
        sudo ufw allow 22/tcp
        sudo ufw allow 80/tcp
        sudo ufw allow 443/tcp
        sudo ufw --force enable
        log_success "UFW防火墙配置完成"
    elif command -v firewall-cmd &> /dev/null; then
        # CentOS/RHEL使用firewalld
        sudo firewall-cmd --permanent --add-service=ssh
        sudo firewall-cmd --permanent --add-service=http
        sudo firewall-cmd --permanent --add-service=https
        sudo firewall-cmd --reload
        log_success "Firewalld防火墙配置完成"
    else
        log_warning "未检测到防火墙管理工具，请手动配置"
    fi
}

# 克隆项目
clone_project() {
    log_info "克隆项目代码..."
    
    # 提示用户输入Git仓库地址
    if [[ -z "$REPO_URL" ]]; then
        echo -n "请输入Git仓库地址: "
        read REPO_URL
    fi
    
    if [[ -d "novel-editor" ]]; then
        log_warning "项目目录已存在，更新代码..."
        cd novel-editor
        git pull origin main
        cd ..
    else
        git clone "$REPO_URL" novel-editor
    fi
    
    cd novel-editor
    log_success "项目代码准备完成"
}

# 配置环境变量
configure_environment() {
    log_info "配置环境变量..."
    
    if [[ ! -f ".env.prod" ]]; then
        cp .env.prod.example .env.prod
        
        echo ""
        log_warning "请配置以下环境变量:"
        echo "1. SILICONFLOW_API_KEY - SiliconFlow API密钥"
        echo "2. DATABASE_URL - 数据库连接字符串（可选，默认使用SQLite）"
        echo ""
        
        echo -n "请输入SiliconFlow API密钥: "
        read API_KEY
        
        if [[ -n "$API_KEY" ]]; then
            sed -i "s/your_siliconflow_api_key_here/$API_KEY/g" .env.prod
            log_success "API密钥配置完成"
        fi
        
        echo ""
        echo -n "是否配置MySQL数据库? (y/N): "
        read configure_mysql
        
        if [[ "$configure_mysql" =~ ^[Yy]$ ]]; then
            echo -n "数据库连接字符串 (mysql://user:pass@host:port/dbname): "
            read db_url
            if [[ -n "$db_url" ]]; then
                sed -i "s|sqlite:///./novel_editor.db|$db_url|g" .env.prod
                log_success "数据库配置完成"
            fi
        fi
    else
        log_success "环境变量配置文件已存在"
    fi
}

# 部署应用
deploy_application() {
    log_info "开始部署应用..."
    
    # 确保脚本可执行
    chmod +x deploy-prod.sh
    
    # 停止现有服务
    ./deploy-prod.sh stop || true
    
    # 清理旧容器和镜像
    log_info "清理旧容器..."
    docker system prune -f
    
    # 部署生产环境
    ./deploy-prod.sh prod
    
    # 等待服务启动
    log_info "等待服务启动..."
    sleep 30
    
    # 健康检查
    ./deploy-prod.sh health
}

# 显示部署结果
show_result() {
    log_success "==================================="
    log_success "   AI小说编辑器部署完成！"
    log_success "==================================="
    echo ""
    echo "🌐 访问地址:"
    echo "   前端页面: http://$(curl -s ifconfig.me || hostname -I | awk '{print $1}')"
    echo "   API文档:  http://$(curl -s ifconfig.me || hostname -I | awk '{print $1}'):8000/docs"
    echo ""
    echo "🔧 管理命令:"
    echo "   查看状态: ./deploy-prod.sh status"
    echo "   查看日志: ./deploy-prod.sh logs"
    echo "   重启服务: ./deploy-prod.sh restart"
    echo "   停止服务: ./deploy-prod.sh stop"
    echo ""
    echo "📚 文档:"
    echo "   部署文档: DOCKER_DEPLOYMENT.md"
    echo "   详细说明: DEPLOYMENT_SUMMARY.md"
    echo ""
    log_success "部署完成！享受AI小说创作之旅！🎉"
}

# 主函数
main() {
    echo ""
    log_info "==================================="
    log_info "  AI小说编辑器云服务器部署脚本"
    log_info "==================================="
    echo ""
    
    # 检测环境
    detect_os
    
    # 安装依赖
    install_docker
    install_docker_compose
    
    # 配置系统
    configure_firewall
    
    # 部署应用
    clone_project
    configure_environment
    deploy_application
    
    # 显示结果
    show_result
}

# 命令行参数处理
while [[ $# -gt 0 ]]; do
    case $1 in
        --repo-url)
            REPO_URL="$2"
            shift 2
            ;;
        --api-key)
            API_KEY="$2"
            shift 2
            ;;
        --help)
            echo "用法: $0 [选项]"
            echo ""
            echo "选项:"
            echo "  --repo-url URL    Git仓库地址"
            echo "  --api-key KEY     SiliconFlow API密钥"
            echo "  --help            显示帮助信息"
            echo ""
            echo "示例:"
            echo "  $0 --repo-url https://github.com/user/novel-editor.git --api-key sk-xxxxx"
            exit 0
            ;;
        *)
            log_error "未知参数: $1"
            exit 1
            ;;
    esac
done

# 运行主函数
main
