#!/bin/bash

echo "🚀 本地SSH连接服务器安装Docker脚本"
echo "===================================="

# 默认配置（请根据实际情况修改）
DEFAULT_SERVER_IP="your_server_public_ip"
DEFAULT_USER="root"
DEFAULT_PORT="22"

# 内置私钥内容
PRIVATE_KEY_CONTENT='-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAyfc/5qK33gCaKWF/CTrXcb+LBgAQE9MkgnDYqMd2dELElaT3
lBa6OeWsC6b4BGLukL50a1MGGSdi6s58HJu7KrCIwljIzZM1Knuj7aF9co6aeQzE
Vnt2rDEYLBDpbOn2WWRqg+GKdw0x6wHrtB0fd8f1VWgFJOsx/TvhzzQ+xngz6V8r
iJoi6CsLsqaTGs7Txi6Ox9Dr4ACQvaWNhf+JAfee+2s9n64/rSky5rq4+uxPd8jA
q3oFRmlQ3JzwmCLMtVcNgLuuPeEHGIZlTOvpjj4m/MjqfEZaCmC3aZpy6X1uRMy3
7cO2sl3S640iCwy5PXBexg5gVAUCq2Um6NTs+QIDAQABAoIBAA1ZlpO8NcMq7wXF
OAx4Iz2Vl67x2h41Wrh0lR2y8ZWFxFDP8r2LMwwYrmKmysYfc/2FWVSuzDxlahhz
RajuclTEDoYqMDvGe0EvowpWHmCwJG3T9jZxOsrvA9YF2Cgm3u3RwWiuQ+TSrnYG
Tno9YpMcWI8orQ5frZI7nxV/MpcTxMybxxIZqfBlSbjgumNAReBHIliNj2vnh08Y
2EwesHI+5Nn/TqWwMDpIyYEe/+WYyFSrmF1PrpLHsHiH3PGtK29goaKwNaW2NFxO
rqXg2vXZgFDDdtZ7nxblE2IBTFThz45l6Gn+rVVfsM8Z14lf0sfsAKqOoiDuXq+a
XzPxNvECgYEA+JGmOfcokOBrLa8XJcQsB7+eE7b+kstvuMt8af8R900+KORngqV1
59Ox8BRc3cub1G9B5IL25ZnFrDBLsAULCnjpa3fNo223IVhtxm1uvK5ZDtdHQnwF
z/0hCUYaLcAxggK4wEUAijwYNLn0Z1Qs9WwVTIGR3m5KlJ36qnQiMC8CgYEA0ADv
zYb/3n7uTxy1Spd7ukO6Kj350zPUfqzkY0ryf+wTk1kxE8wx2QDhpQsRcfXVcukX
szX7rz+IvXrk5yG93lU+iIvGi//r1+RRpmdv42/Sw9x6Wh3kBYevHgA9eQlCNJQD
9rguSzA+KUHADIxdCZCozkZrNguFB9HJG+A6A1cCgYBVzvHzUL9QRCi7vJXhE7ef
dSa85486XcBTqutoLAWnuaKbuz2AfF4XiZ0DpAPrDT7eNwooOI3C9TKoHoQCX7tQ
Ai2SS+lRYa62dDBxL5XqzMUxul9/NBFNm7Sr3udqo85zcz0UIr3s+pHgodEdWpGq
p4UyxAf3IVvdsiu2bCDhQQKBgQChClifU4n+hV+UOLHT0nyktZMI6XrmnhZDDTC1
/2zIxcpSJpfssAdX72rEEVGsXZyonvcOdRkrkZEYwnE+0cziujT0GuPZuIasW8Ur
hKIIAKe5pJXF96Z28ZoPLDhr4VM0yfRXrDmLVQqLfrBmBrZxlWJccgDHkxun9jAy
OOQxeQKBgAzl1CTHjbhRxKw4KQYdSGDGSHr5RQrbeKrNMjVIxvJMdzywDCcGRCX+
APznzfTOjkQbbdUu9c2Q8PvaB9eOSoNxkCfnToydx+ImFpwZu99Syb+WLVQeiVk6
YK83VO9P9C+zJeGs128IfRlS11OhKKJ90750dYbLtVj/j6Lsa80d
-----END RSA PRIVATE KEY-----'

# 显示使用说明
show_usage() {
    echo "使用方法:"
    echo "  方法1: $0                                    # 使用默认配置"
    echo "  方法2: $0 <服务器IP> [用户名] [端口]           # 自定义配置"
    echo ""
    echo "示例:"
    echo "  $0                                          # 使用脚本内的默认IP"
    echo "  $0 192.168.1.100                           # 指定服务器IP"
    echo "  $0 192.168.1.100 ubuntu                    # 指定IP和用户名"
    echo "  $0 192.168.1.100 ubuntu 2222               # 指定IP、用户名和端口"
    echo ""
    echo "当前默认配置:"
    echo "  服务器IP: $DEFAULT_SERVER_IP"
    echo "  用户名: $DEFAULT_USER"
    echo "  端口: $DEFAULT_PORT"
    echo ""
    exit 1
}

# 解析参数
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_usage
fi

# 设置连接参数
SERVER_IP="${1:-$DEFAULT_SERVER_IP}"
SERVER_USER="${2:-$DEFAULT_USER}"
SERVER_PORT="${3:-$DEFAULT_PORT}"

# 检查是否设置了服务器IP
if [ "$SERVER_IP" = "your_server_public_ip" ]; then
    echo "❌ 请先设置服务器公网IP地址！"
    echo ""
    echo "方法1: 编辑脚本文件，修改第6行："
    echo "DEFAULT_SERVER_IP=\"your_server_public_ip\""
    echo "改为："
    echo "DEFAULT_SERVER_IP=\"您的实际服务器公网IP\""
    echo ""
    echo "方法2: 直接在命令行指定IP："
    echo "$0 您的服务器公网IP"
    echo ""
    exit 1
fi

echo "📋 连接配置:"
echo "服务器IP: $SERVER_IP"
echo "用户名: $SERVER_USER"
echo "端口: $SERVER_PORT"

# 创建临时私钥文件
TEMP_KEY_FILE="/tmp/ai_server_key_$(date +%s).pem"
echo "$PRIVATE_KEY_CONTENT" > "$TEMP_KEY_FILE"
chmod 600 "$TEMP_KEY_FILE"

echo "私钥文件: $TEMP_KEY_FILE"

# 清理函数
cleanup() {
    echo ""
    echo "🧹 清理临时文件..."
    rm -f "$TEMP_KEY_FILE" /tmp/remote_install_docker_*.sh
}

# 设置退出时清理
trap cleanup EXIT

# 测试SSH连接
echo ""
echo "🔍 测试SSH连接..."
if ssh -i "$TEMP_KEY_FILE" -o ConnectTimeout=15 -o BatchMode=yes -p "$SERVER_PORT" "$SERVER_USER@$SERVER_IP" "echo 'SSH连接成功'" 2>/dev/null; then
    echo "✅ SSH连接测试成功"
else
    echo "❌ SSH连接失败，请检查:"
    echo "1. 服务器公网IP是否正确: $SERVER_IP"
    echo "2. SSH端口是否正确: $SERVER_PORT"
    echo "3. 用户名是否正确: $SERVER_USER"
    echo "4. 服务器防火墙是否开放SSH端口"
    echo "5. 私钥是否已添加到服务器authorized_keys"
    echo ""
    echo "🔧 手动测试连接:"
    echo "ssh -i $TEMP_KEY_FILE -p $SERVER_PORT $SERVER_USER@$SERVER_IP"
    exit 1
fi

# 检查服务器系统信息
echo ""
echo "🔍 获取服务器系统信息..."
ssh -i "$TEMP_KEY_FILE" -p "$SERVER_PORT" "$SERVER_USER@$SERVER_IP" "
    echo '系统信息:'
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo '  操作系统: '\$NAME \$VERSION
        echo '  发行版ID: '\$ID
    fi
    echo '  内核版本: '$(uname -r)
    echo '  架构: '$(uname -m)
    echo '  主机名: '$(hostname)
"

# 创建远程安装脚本
REMOTE_SCRIPT="/tmp/remote_install_docker_$(date +%s).sh"
cat > "$REMOTE_SCRIPT" << 'REMOTE_SCRIPT_EOF'
#!/bin/bash

echo "🐳 开始在远程服务器安装Docker和Docker Compose"
echo "=============================================="

# 检查root权限
if [ "$EUID" -ne 0 ]; then
    echo "❌ 此脚本需要root权限运行"
    echo "请以root用户登录或使用sudo"
    exit 1
fi

# 检查系统类型
echo "🔍 检查系统兼容性..."
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "当前系统: $NAME $VERSION"
    
    case "$ID" in
        ubuntu|debian)
            echo "✅ 支持的系统类型"
            ;;
        centos|rhel|fedora)
            echo "⚠️ CentOS/RHEL/Fedora系统，脚本需要调整"
            echo "建议手动安装Docker"
            exit 1
            ;;
        *)
            echo "⚠️ 未测试的系统类型: $ID"
            echo "是否继续? (y/N)"
            read -r response
            if [[ ! "$response" =~ ^[Yy]$ ]]; then
                exit 1
            fi
            ;;
    esac
fi

# 更新系统包
echo ""
echo "📦 更新系统包..."
export DEBIAN_FRONTEND=noninteractive
apt-get update

# 安装基础依赖
echo ""
echo "🔧 安装基础依赖..."
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    wget \
    unzip

# 检查Docker状态
echo ""
echo "🐳 检查Docker安装状态..."
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
    echo "✅ Docker已安装，版本: $DOCKER_VERSION"
    
    # 检查Docker服务
    if systemctl is-active --quiet docker; then
        echo "✅ Docker服务正在运行"
    else
        echo "⚠️ Docker服务未运行，启动服务..."
        systemctl start docker
        systemctl enable docker
        sleep 3
    fi
else
    echo "❌ Docker未安装，开始安装..."
    
    # 删除旧版本
    echo "🗑️ 清理旧版本..."
    apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    # 添加Docker官方GPG密钥
    echo "🔑 添加Docker官方GPG密钥..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # 添加Docker仓库
    echo "📚 添加Docker官方仓库..."
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # 更新包索引
    apt-get update
    
    # 安装Docker Engine
    echo "🚀 安装Docker Engine..."
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # 启动Docker服务
    echo "🔧 启动Docker服务..."
    systemctl start docker
    systemctl enable docker
    
    # 等待服务启动
    sleep 5
    
    echo "✅ Docker安装完成"
fi

# 检查Docker Compose
echo ""
echo "🐙 检查Docker Compose状态..."
if command -v docker-compose &> /dev/null; then
    COMPOSE_VERSION=$(docker-compose --version | cut -d' ' -f4 | cut -d',' -f1)
    echo "✅ Docker Compose已安装，版本: $COMPOSE_VERSION"
else
    echo "❌ Docker Compose未安装，开始安装..."
    
    # 获取最新版本
    echo "🔍 获取Docker Compose最新版本..."
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
    
    if [ -z "$COMPOSE_VERSION" ]; then
        echo "⚠️ 无法获取最新版本，使用默认版本"
        COMPOSE_VERSION="v2.21.0"
    fi
    
    echo "目标版本: $COMPOSE_VERSION"
    
    # 下载Docker Compose
    echo "⬇️ 下载Docker Compose..."
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ]; then
        ARCH="x86_64"
    elif [ "$ARCH" = "aarch64" ]; then
        ARCH="aarch64"
    fi
    
    curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-${ARCH}" -o /usr/local/bin/docker-compose
    
    # 设置执行权限
    chmod +x /usr/local/bin/docker-compose
    
    # 创建符号链接
    ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    
    echo "✅ Docker Compose安装完成"
fi

# 配置非root用户权限（如果需要）
echo ""
echo "👤 配置用户权限..."
if [ "$USER" != "root" ] && [ -n "$SUDO_USER" ]; then
    TARGET_USER="$SUDO_USER"
    echo "配置用户 $TARGET_USER 的Docker权限..."
    
    if groups "$TARGET_USER" | grep -q docker; then
        echo "✅ 用户 $TARGET_USER 已在docker组"
    else
        echo "🔧 添加用户 $TARGET_USER 到docker组..."
        usermod -aG docker "$TARGET_USER"
        echo "✅ 用户已添加到docker组"
        echo "⚠️ 用户需要重新登录使权限生效"
    fi
else
    echo "⚠️ 当前为root用户，跳过用户组配置"
fi

# 测试Docker
echo ""
echo "🧪 测试Docker功能..."
if docker run --rm hello-world > /dev/null 2>&1; then
    echo "✅ Docker功能测试成功"
    # 清理测试镜像
    docker rmi hello-world &> /dev/null || true
else
    echo "❌ Docker功能测试失败"
    echo "📋 Docker服务状态:"
    systemctl status docker --no-pager
fi

# 测试Docker Compose
echo ""
echo "🧪 测试Docker Compose..."
if docker-compose --version &> /dev/null; then
    echo "✅ Docker Compose测试成功"
else
    echo "❌ Docker Compose测试失败"
fi

# 系统优化配置
echo ""
echo "⚙️ 配置系统参数..."

# 设置vm.max_map_count（MongoDB等需要）
sysctl -w vm.max_map_count=1677720
if ! grep -q "vm.max_map_count" /etc/sysctl.conf; then
    echo 'vm.max_map_count=1677720' >> /etc/sysctl.conf
    echo "✅ 已永久设置vm.max_map_count"
fi

# 配置Docker daemon
echo "🔧 优化Docker配置..."
mkdir -p /etc/docker
cat > /etc/docker/daemon.json << 'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF

# 重启Docker服务应用配置
systemctl restart docker
sleep 3

# 显示最终状态
echo ""
echo "📊 安装完成状态报告:"
echo "================================"
echo "Docker版本: $(docker --version 2>/dev/null || echo '未安装')"
echo "Docker Compose版本: $(docker-compose --version 2>/dev/null || echo '未安装')"
echo "Docker服务状态: $(systemctl is-active docker 2>/dev/null || echo '未知')"
echo "系统架构: $(uname -m)"
echo "可用内存: $(free -h | grep Mem | awk '{print $7}')"
echo "可用磁盘: $(df -h / | tail -1 | awk '{print $4}')"

# 显示有用的命令
echo ""
echo "🎯 常用Docker命令:"
echo "================================"
echo "查看容器状态: docker ps"
echo "查看镜像列表: docker images"
echo "清理未使用资源: docker system prune"
echo "查看Docker信息: docker info"
echo "查看Docker版本: docker version"

echo ""
echo "✅ Docker和Docker Compose安装配置完成！"
echo ""
echo "🚀 现在可以:"
echo "1. 部署Docker应用"
echo "2. 使用docker-compose管理多容器应用" 
echo "3. 开始部署AI小说编辑器项目"
REMOTE_SCRIPT_EOF

# 上传安装脚本到服务器
echo ""
echo "📤 上传安装脚本到服务器..."
scp -i "$TEMP_KEY_FILE" -P "$SERVER_PORT" "$REMOTE_SCRIPT" "$SERVER_USER@$SERVER_IP:/tmp/"

# 在服务器上执行安装
echo ""
echo "🚀 在服务器上执行Docker安装..."
echo "这可能需要几分钟时间，请耐心等待..."

ssh -i "$TEMP_KEY_FILE" -p "$SERVER_PORT" "$SERVER_USER@$SERVER_IP" "
    chmod +x /tmp/$(basename $REMOTE_SCRIPT)
    /tmp/$(basename $REMOTE_SCRIPT)
    rm -f /tmp/$(basename $REMOTE_SCRIPT)
"

# 验证安装结果
echo ""
echo "🔍 验证安装结果..."
ssh -i "$TEMP_KEY_FILE" -p "$SERVER_PORT" "$SERVER_USER@$SERVER_IP" "
    echo '📋 最终验证:'
    echo '============'
    docker --version
    docker-compose --version
    echo ''
    echo '🐳 Docker服务状态:'
    systemctl status docker --no-pager -l
"

echo ""
echo "🎉 远程Docker安装完成！"
echo ""
echo "📞 连接信息:"
echo "服务器: $SERVER_USER@$SERVER_IP:$SERVER_PORT"
echo ""
echo "🎯 下一步可以:"
echo "1. 上传docker-compose.yml文件"
echo "2. 配置项目环境变量"  
echo "3. 启动AI小说编辑器服务"
echo ""
echo "💡 手动连接服务器:"
echo "ssh -i $TEMP_KEY_FILE -p $SERVER_PORT $SERVER_USER@$SERVER_IP"
