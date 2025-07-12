#!/bin/bash

# SSH自动化Docker安装脚本
# 用途：通过SSH连接到远程服务器并自动安装Docker和Docker Compose

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 默认配置
DEFAULT_SERVER_IP="your-server-ip"
DEFAULT_SSH_USER="ubuntu"
DEFAULT_SSH_PORT="22"

# 内嵌SSH私钥（替换为您的实际私钥）
SSH_PRIVATE_KEY_CONTENT='-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAyour-private-key-content-here
-----END RSA PRIVATE KEY-----'

# 创建临时SSH私钥文件
create_temp_ssh_key() {
    TEMP_KEY_FILE=$(mktemp)
    echo "$SSH_PRIVATE_KEY_CONTENT" > "$TEMP_KEY_FILE"
    chmod 600 "$TEMP_KEY_FILE"
    echo "$TEMP_KEY_FILE"
}

# 清理临时文件
cleanup() {
    if [[ -n "$TEMP_KEY_FILE" && -f "$TEMP_KEY_FILE" ]]; then
        rm -f "$TEMP_KEY_FILE"
        log_info "清理临时SSH密钥文件"
    fi
}

# 设置退出时清理
trap cleanup EXIT

# 检查SSH连接
check_ssh_connection() {
    local server_ip="$1"
    local ssh_user="$2"
    local ssh_port="$3"
    local key_file="$4"
    
    log_info "测试SSH连接到 ${ssh_user}@${server_ip}:${ssh_port}"
    
    if ssh -i "$key_file" -p "$ssh_port" -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$ssh_user@$server_ip" "echo 'SSH连接成功'" > /dev/null 2>&1; then
        log_info "SSH连接测试成功"
        return 0
    else
        log_error "SSH连接失败，请检查服务器地址、用户名、端口和SSH密钥"
        return 1
    fi
}

# 生成远程安装脚本
generate_remote_install_script() {
    cat << 'EOF'
#!/bin/bash

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查系统
check_system() {
    if [[ ! -f /etc/os-release ]]; then
        log_error "无法确定操作系统版本"
        exit 1
    fi
    
    . /etc/os-release
    if [[ "$ID" != "ubuntu" ]]; then
        log_warn "此脚本专为Ubuntu设计，当前系统：$ID"
    fi
    
    log_info "检测到系统：$PRETTY_NAME"
}

# 更新系统包
update_system() {
    log_info "更新系统包列表..."
    sudo apt-get update -y
    
    log_info "安装必要的依赖包..."
    sudo apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release \
        apt-transport-https \
        software-properties-common
}

# 安装Docker
install_docker() {
    log_info "检查Docker是否已安装..."
    if command -v docker &> /dev/null; then
        log_warn "Docker已安装，版本：$(docker --version)"
        return 0
    fi
    
    log_info "添加Docker官方GPG密钥..."
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    log_info "添加Docker APT仓库..."
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    log_info "更新包列表..."
    sudo apt-get update -y
    
    log_info "安装Docker CE..."
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin
    
    log_info "启动并启用Docker服务..."
    sudo systemctl start docker
    sudo systemctl enable docker
    
    log_info "验证Docker安装..."
    sudo docker --version
}

# 安装Docker Compose
install_docker_compose() {
    log_info "检查Docker Compose是否已安装..."
    if command -v docker-compose &> /dev/null; then
        log_warn "Docker Compose已安装，版本：$(docker-compose --version)"
        return 0
    fi
    
    log_info "获取Docker Compose最新版本..."
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
    
    if [[ -z "$COMPOSE_VERSION" ]]; then
        log_warn "无法获取最新版本，使用默认版本 v2.23.0"
        COMPOSE_VERSION="v2.23.0"
    fi
    
    log_info "下载Docker Compose $COMPOSE_VERSION..."
    sudo curl -L "https://github.com/docker/compose/releases/download/$COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    
    log_info "设置执行权限..."
    sudo chmod +x /usr/local/bin/docker-compose
    
    log_info "创建符号链接..."
    sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    
    log_info "验证Docker Compose安装..."
    docker-compose --version
}

# 配置用户权限
configure_user_permissions() {
    local current_user=$(whoami)
    
    log_info "将用户 $current_user 添加到docker组..."
    sudo usermod -aG docker "$current_user"
    
    log_info "配置完成！请重新登录以使用户组更改生效，或运行："
    log_info "newgrp docker"
}

# 验证安装
verify_installation() {
    log_info "验证Docker安装..."
    if sudo docker run --rm hello-world > /dev/null 2>&1; then
        log_info "Docker测试成功！"
    else
        log_error "Docker测试失败"
        return 1
    fi
    
    log_info "验证Docker Compose安装..."
    if docker-compose --version > /dev/null 2>&1; then
        log_info "Docker Compose验证成功！"
    else
        log_error "Docker Compose验证失败"
        return 1
    fi
}

# 显示安装信息
show_installation_info() {
    echo ""
    log_info "=== 安装完成 ==="
    log_info "Docker版本：$(docker --version)"
    log_info "Docker Compose版本：$(docker-compose --version)"
    echo ""
    log_info "常用命令："
    log_info "  查看Docker状态：sudo systemctl status docker"
    log_info "  启动Docker：sudo systemctl start docker"
    log_info "  停止Docker：sudo systemctl stop docker"
    log_info "  查看Docker镜像：docker images"
    log_info "  查看运行的容器：docker ps"
    echo ""
    log_warn "注意：请重新登录或运行 'newgrp docker' 以使用户组更改生效"
}

# 主函数
main() {
    log_info "开始Docker和Docker Compose安装..."
    
    check_system
    update_system
    install_docker
    install_docker_compose
    configure_user_permissions
    verify_installation
    show_installation_info
    
    log_info "安装完成！"
}

# 执行主函数
main "$@"
EOF
}

# 在远程服务器上执行安装
execute_remote_installation() {
    local server_ip="$1"
    local ssh_user="$2"
    local ssh_port="$3"
    local key_file="$4"
    
    log_info "生成远程安装脚本..."
    local remote_script="/tmp/install-docker-remote.sh"
    
    # 将安装脚本传输到远程服务器
    log_info "传输安装脚本到远程服务器..."
    generate_remote_install_script | ssh -i "$key_file" -p "$ssh_port" -o StrictHostKeyChecking=no "$ssh_user@$server_ip" "cat > $remote_script && chmod +x $remote_script"
    
    # 在远程服务器上执行安装脚本
    log_info "在远程服务器上执行Docker安装..."
    ssh -i "$key_file" -p "$ssh_port" -o StrictHostKeyChecking=no "$ssh_user@$server_ip" "bash $remote_script"
    
    # 清理远程脚本
    log_info "清理远程临时文件..."
    ssh -i "$key_file" -p "$ssh_port" -o StrictHostKeyChecking=no "$ssh_user@$server_ip" "rm -f $remote_script"
}

# 主函数
main() {
    echo ""
    log_info "=== SSH自动化Docker安装脚本 ==="
    echo ""
    
    # 获取服务器信息
    read -p "请输入服务器IP地址 (默认: $DEFAULT_SERVER_IP): " SERVER_IP
    SERVER_IP=${SERVER_IP:-$DEFAULT_SERVER_IP}
    
    read -p "请输入SSH用户名 (默认: $DEFAULT_SSH_USER): " SSH_USER
    SSH_USER=${SSH_USER:-$DEFAULT_SSH_USER}
    
    read -p "请输入SSH端口 (默认: $DEFAULT_SSH_PORT): " SSH_PORT
    SSH_PORT=${SSH_PORT:-$DEFAULT_SSH_PORT}
    
    # 验证输入
    if [[ "$SERVER_IP" == "$DEFAULT_SERVER_IP" ]]; then
        log_error "请提供有效的服务器IP地址"
        exit 1
    fi
    
    echo ""
    log_info "连接信息："
    log_info "  服务器IP: $SERVER_IP"
    log_info "  SSH用户: $SSH_USER"
    log_info "  SSH端口: $SSH_PORT"
    echo ""
    
    # 创建临时SSH密钥文件
    TEMP_KEY_FILE=$(create_temp_ssh_key)
    
    # 检查SSH连接
    if ! check_ssh_connection "$SERVER_IP" "$SSH_USER" "$SSH_PORT" "$TEMP_KEY_FILE"; then
        exit 1
    fi
    
    # 确认执行
    read -p "确认在远程服务器上安装Docker和Docker Compose? (y/N): " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        log_info "安装已取消"
        exit 0
    fi
    
    # 执行远程安装
    execute_remote_installation "$SERVER_IP" "$SSH_USER" "$SSH_PORT" "$TEMP_KEY_FILE"
    
    echo ""
    log_info "=== 安装完成 ==="
    log_info "Docker和Docker Compose已成功安装到远程服务器"
    log_info "请在远程服务器上运行 'newgrp docker' 或重新登录以使用户组更改生效"
    echo ""
}

# 检查是否直接运行此脚本
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
