#!/bin/bash
# 统一部署脚本 - 包含完整的环境配置和部署流程
# 支持SSH认证和腾讯云镜像配置

set -e

# 颜色输出函数
red() { echo -e "\033[31m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
blue() { echo -e "\033[34m$1\033[0m"; }

# 配置变量
SSH_REPO="git@github.com:lessstoryclassmate/legezhixiao.git"
SSH_KEY_PATH="/root/.ssh/id_ed25519"
PROJECT_DIR="/tmp/legezhixiao-$(date +%s)"
DOCKER_MIRROR="ccr.ccs.tencentyun.com"

# 使用说明
usage() {
    echo "统一部署脚本 - 乐戈智小说 AI 编辑器"
    echo ""
    echo "使用方法:"
    echo "  $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --setup-ssh      配置SSH密钥和GitHub认证"
    echo "  --setup-docker   配置腾讯云Docker镜像"
    echo "  --setup-env      配置完整环境(Docker + SSH)"
    echo "  --deploy         执行完整部署"
    echo "  --fix-network    修复网络连接问题" 
    echo "  --health-check   执行健康检查"
    echo "  --help          显示此帮助信息"
    echo ""
    echo "环境变量 (可选):"
    echo "  SILICONFLOW_API_KEY    SiliconFlow API密钥"
    echo "  JWT_SECRET_KEY         JWT密钥"
    echo "  REDIS_PASSWORD         Redis密码"
}

# 环境检查
check_environment() {
    echo "🔍 检查部署环境..."
    
    # 检查操作系统
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "操作系统: $NAME $VERSION"
    fi
    
    # 检查必要命令
    for cmd in git curl wget docker; do
        if ! command -v $cmd &> /dev/null; then
            red "❌ 缺少必要命令: $cmd"
            echo "请先安装 $cmd"
            exit 1
        fi
    done
    
    green "✅ 基础环境检查通过"
}

# 配置SSH认证
setup_ssh() {
    echo "🔑 配置SSH认证..."
    
    # 检查SSH密钥
    if [ ! -f "$SSH_KEY_PATH" ]; then
        red "❌ SSH密钥不存在: $SSH_KEY_PATH"
        echo ""
        echo "⚠️ 请确保SSH密钥已存在于服务器上"
        echo "   密钥路径: $SSH_KEY_PATH"
        echo "   公钥路径: ${SSH_KEY_PATH}.pub"
        echo ""
        echo "如果公钥未添加到GitHub，请访问:"
        echo "  https://github.com/settings/ssh/new"
        exit 1
    fi
    
    # 配置SSH客户端
    mkdir -p /root/.ssh
    chmod 700 /root/.ssh
    chmod 600 "$SSH_KEY_PATH"
    
    # 创建SSH配置
    cat > /root/.ssh/config << EOF
Host github.com
    HostName github.com
    User git
    IdentityFile $SSH_KEY_PATH
    IdentitiesOnly yes
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    AddKeysToAgent yes
EOF
    chmod 600 /root/.ssh/config
    
    # 测试SSH连接
    export GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $SSH_KEY_PATH"
    
    if timeout 30 ssh -T -o ConnectTimeout=10 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i "$SSH_KEY_PATH" git@github.com 2>&1 | grep -q "successfully authenticated"; then
        green "✅ SSH认证配置成功"
    else
        yellow "⚠️ SSH连接测试未完全成功，但可能仍可正常工作"
    fi
}

# 配置腾讯云Docker镜像
setup_docker() {
    echo "🐳 配置腾讯云Docker镜像..."
    
    # 停止Docker服务
    systemctl stop docker 2>/dev/null || true
    
    # 备份原配置
    if [ -f /etc/docker/daemon.json ]; then
        cp /etc/docker/daemon.json /etc/docker/daemon.json.backup.$(date +%s)
    fi
    
    # 创建Docker配置目录
    mkdir -p /etc/docker
    
    # 配置腾讯云镜像
    cat > /etc/docker/daemon.json << EOF
{
  "registry-mirrors": [
    "https://ccr.ccs.tencentyun.com"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF
    
    # 重启Docker服务
    systemctl daemon-reload
    systemctl start docker
    systemctl enable docker
    
    # 等待Docker启动
    echo "等待Docker服务启动..."
    sleep 5
    
    # 测试Docker镜像
    if docker pull ccr.ccs.tencentyun.com/library/nginx:latest &>/dev/null; then
        green "✅ 腾讯云Docker镜像配置成功"
        docker rmi ccr.ccs.tencentyun.com/library/nginx:latest &>/dev/null || true
    else
        yellow "⚠️ 腾讯云镜像测试失败，但Docker服务正常"
    fi
}

# 修复网络连接
fix_network() {
    echo "🔧 修复网络连接..."
    
    # 刷新DNS缓存
    if command -v systemd-resolve &> /dev/null; then
        systemd-resolve --flush-caches
    fi
    
    # 重启网络服务
    if command -v systemctl &> /dev/null; then
        systemctl restart systemd-resolved 2>/dev/null || true
    fi
    
    # 测试网络连接
    echo "测试网络连接..."
    if ping -c 3 8.8.8.8 &>/dev/null; then
        green "✅ 网络连接正常"
    else
        yellow "⚠️ 网络连接可能有问题"
    fi
    
    # 测试GitHub连接
    if curl -s --connect-timeout 10 https://github.com &>/dev/null; then
        green "✅ GitHub连接正常"
    else
        yellow "⚠️ GitHub连接可能有问题"
    fi
}

# 克隆项目代码
clone_project() {
    echo "📦 克隆项目代码..."
    
    # 设置Git SSH命令
    export GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $SSH_KEY_PATH"
    
    # 创建临时目录
    mkdir -p "$PROJECT_DIR"
    cd "$PROJECT_DIR"
    
    # 克隆代码
    if git clone "$SSH_REPO" .; then
        green "✅ 项目代码克隆成功"
        return 0
    else
        red "❌ 项目代码克隆失败"
        return 1
    fi
}

# 构建和启动服务
deploy_services() {
    echo "🚀 部署服务..."
    
    if [ ! -d "$PROJECT_DIR" ] || [ ! -f "$PROJECT_DIR/docker-compose.yml" ]; then
        red "❌ 项目目录或docker-compose.yml不存在"
        return 1
    fi
    
    cd "$PROJECT_DIR"
    
    # 设置环境变量
    if [ -n "$SILICONFLOW_API_KEY" ]; then
        export SILICONFLOW_API_KEY
    fi
    if [ -n "$JWT_SECRET_KEY" ]; then
        export JWT_SECRET_KEY
    fi
    if [ -n "$REDIS_PASSWORD" ]; then
        export REDIS_PASSWORD
    fi
    
    # 停止现有服务
    echo "停止现有服务..."
    docker-compose down --remove-orphans 2>/dev/null || true
    
    # 构建和启动服务
    echo "构建和启动服务..."
    if docker-compose up --build -d; then
        green "✅ 服务部署成功"
        
        # 等待服务启动
        echo "等待服务启动..."
        sleep 10
        
        # 检查服务状态
        docker-compose ps
        
        return 0
    else
        red "❌ 服务部署失败"
        return 1
    fi
}

# 健康检查
health_check() {
    echo "🏥 执行健康检查..."
    
    # 检查Docker服务
    if systemctl is-active --quiet docker; then
        green "✅ Docker服务运行正常"
    else
        red "❌ Docker服务未运行"
    fi
    
    # 检查容器状态
    if [ -d "$PROJECT_DIR" ]; then
        cd "$PROJECT_DIR"
        echo "📋 容器状态:"
        docker-compose ps 2>/dev/null || echo "无法获取容器状态"
    fi
    
    # 检查端口占用
    echo "📋 端口占用情况:"
    for port in 80 443 3000 5000 6379; do
        if netstat -tlnp | grep -q ":$port "; then
            echo "端口 $port: 已占用"
        else
            echo "端口 $port: 未占用"
        fi
    done
    
    # 检查服务响应
    if curl -s --connect-timeout 5 http://localhost &>/dev/null; then
        green "✅ 服务响应正常"
    else
        yellow "⚠️ 服务可能未完全启动"
    fi
}

# 清理函数
cleanup() {
    echo "🧹 清理临时文件..."
    if [ -n "$PROJECT_DIR" ] && [ -d "$PROJECT_DIR" ]; then
        cd /
        rm -rf "$PROJECT_DIR"
        echo "✅ 临时文件清理完成"
    fi
}

# 主函数
main() {
    case "${1:-}" in
        --setup-ssh)
            check_environment
            setup_ssh
            ;;
        --setup-docker)
            check_environment
            setup_docker
            ;;
        --setup-env)
            check_environment
            setup_ssh
            setup_docker
            ;;
        --deploy)
            check_environment
            setup_ssh
            setup_docker
            clone_project
            deploy_services
            health_check
            ;;
        --fix-network)
            fix_network
            ;;
        --health-check)
            health_check
            ;;
        --help)
            usage
            ;;
        *)
            echo "🎯 乐戈智小说 AI 编辑器 - 统一部署脚本"
            echo ""
            usage
            exit 1
            ;;
    esac
}

# 错误处理
trap cleanup EXIT

# 运行主函数
main "$@"
