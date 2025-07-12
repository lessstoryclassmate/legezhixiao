#!/bin/bash

echo "🐳 Docker & Docker Compose - 一键安装脚本"
echo "============================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置参数
SERVER_IP=""
SERVER_USER="root"
SERVER_SSH_PORT="22"
SSH_KEY_PATH=""  # SSH私钥路径o "� Docker环境 - 一键服务器安装脚本"
echo "======================================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置参数（请根据实际情况修改）
SERVER_IP=""
SERVER_USER="root"
SERVER_SSH_PORT="22"

# 打印函数
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查本地环境
check_local_requirements() {
    print_info "检查本地环境..."
    
    if ! command -v ssh &> /dev/null; then
        print_error "SSH客户端未安装"
        exit 1
    fi
    
    if ! command -v scp &> /dev/null; then
        print_error "SCP命令未找到"
        exit 1
    fi
    
    print_success "本地环境检查通过"
}

# 获取用户配置
get_user_config() {
    echo ""
    echo "📋 请输入服务器连接信息:"
    
    if [ -z "$SERVER_IP" ]; then
        read -p "服务器IP地址: " SERVER_IP
    fi
    
    if [ -z "$SERVER_USER" ]; then
        read -p "服务器用户名 (默认root): " SERVER_USER
        SERVER_USER=${SERVER_USER:-root}
    fi
    
    if [ -z "$SERVER_SSH_PORT" ]; then
        read -p "SSH端口 (默认22): " SERVER_SSH_PORT
        SERVER_SSH_PORT=${SERVER_SSH_PORT:-22}
    fi
    
    if [ -z "$SSH_KEY_PATH" ]; then
        read -p "SSH私钥路径 (默认~/.ssh/id_rsa): " SSH_KEY_PATH
        SSH_KEY_PATH=${SSH_KEY_PATH:-~/.ssh/id_rsa}
        # 展开波浪号
        SSH_KEY_PATH=$(eval echo $SSH_KEY_PATH)
    fi
    
    echo ""
    print_info "连接配置确认:"
    echo "服务器: $SERVER_USER@$SERVER_IP:$SERVER_SSH_PORT"
    echo "SSH密钥: $SSH_KEY_PATH"
    echo ""
    
    # 检查SSH密钥文件
    if [ ! -f "$SSH_KEY_PATH" ]; then
        print_error "SSH密钥文件不存在: $SSH_KEY_PATH"
        print_info "请确保SSH密钥文件存在，或使用 ssh-keygen 生成密钥对"
        exit 1
    fi
    
    read -p "确认配置正确？(y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_error "配置取消"
        exit 1
    fi
}

# 测试SSH连接
test_ssh_connection() {
    print_info "测试SSH连接..."
    
    if ssh -o ConnectTimeout=10 -o BatchMode=yes -p $SERVER_SSH_PORT $SERVER_USER@$SERVER_IP "echo 'SSH连接成功'" 2>/dev/null; then
        print_success "SSH连接测试成功"
    else
        print_error "SSH连接失败，请检查:"
        echo "1. 服务器IP地址是否正确"
        echo "2. 用户名是否正确"
        echo "3. SSH密钥是否已配置"
        echo "4. 服务器是否允许SSH连接"
        exit 1
    fi
}

# 创建远程安装脚本
create_remote_script() {
    print_info "创建远程安装脚本..."
    
    cat > /tmp/remote_install.sh << 'REMOTE_SCRIPT_EOF'
#!/bin/bash

set -e

echo "🔧 开始在服务器上安装AI小说编辑器..."

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 更新系统
print_info "更新系统包..."
apt-get update

# 安装基础依赖
print_info "安装基础依赖..."
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    git \
    net-tools

# 安装Docker
print_info "检查Docker安装状态..."
if ! command -v docker &> /dev/null; then
    print_info "安装Docker..."
    
    # 添加Docker官方GPG密钥
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # 添加Docker仓库
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # 更新包索引并安装Docker
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin
    
    # 启动Docker服务
    systemctl start docker
    systemctl enable docker
    
    print_success "Docker安装完成"
else
    print_success "Docker已安装"
fi

# 安装Docker Compose
print_info "检查Docker Compose安装状态..."
if ! command -v docker-compose &> /dev/null; then
    print_info "安装Docker Compose..."
    
    # 获取最新版本
    DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
    
    # 下载并安装
    curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    
    print_success "Docker Compose安装完成"
else
    print_success "Docker Compose已安装"
fi

# 配置用户权限
print_info "配置Docker权限..."
usermod -aG docker $USER 2>/dev/null || true

# 测试Docker
print_info "测试Docker安装..."
if docker run --rm hello-world > /dev/null 2>&1; then
    print_success "Docker测试成功"
    docker rmi hello-world &> /dev/null || true
else
    print_error "Docker测试失败"
    exit 1
fi

# 创建项目目录
PROJECT_DIR="/opt/ai-novel-editor"
print_info "创建项目目录: $PROJECT_DIR"
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# 克隆代码
print_info "克隆项目代码..."
if [ -d ".git" ]; then
    print_info "更新现有代码..."
    git fetch origin && git reset --hard origin/main && git clean -fd
else
    print_info "克隆新代码..."
    if [ "$(ls -A . 2>/dev/null)" ]; then
        rm -rf ./*
    fi
    git clone https://$PERSONAL_ACCESS_TOKEN@github.com/$GITHUB_REPO .
fi

# 创建环境变量文件
print_info "配置环境变量..."
cat > .env << ENV_EOF
# 服务器配置
SERVER_IP=$SERVER_IP
SERVER_USER=$SERVER_USER
SERVER_SSH_PORT=22
SERVER_PORT=22

# AI 服务配置
SILICONFLOW_API_KEY=$SILICONFLOW_API_KEY
SILICONFLOW_DEFAULT_MODEL=deepseek-ai/DeepSeek-V3
SILICONFLOW_API_URL=https://api.siliconflow.cn/v1/chat/completions
JWT_SECRET_KEY=$JWT_SECRET_KEY

# MCP 服务配置
MCP_SERVER_NAME=novel-ai-server
MCP_SERVER_PORT=8000
MCP_SERVER_HOST=$SERVER_IP
MCP_TOOLS_ENABLED=true
MCP_TOOLS_LIST=novel_generation,character_creation,plot_analysis,content_review,style_transfer
NOVEL_GENERATION_MAX_TOKENS=4096
NOVEL_GENERATION_TEMPERATURE=0.8
NOVEL_GENERATION_TOP_P=0.9

# 云数据库配置
MONGODB_HOST=172.16.32.2
MONGODB_PORT=27017
MONGODB_DATABASE=ai_novel_db
REDIS_HOST=172.16.32.2
REDIS_PORT=6379
REDIS_PASSWORD=$REDIS_PASSWORD

# MySQL 数据库配置
DATABASE_PORT=3306
DATABASE_SYSTEMHOST=172.16.16.3
DATABASE_SYSTEM=novel_data
DATABASE_USER=lkr
DATABASE_PASSWORD=Lekairong350702
DATABASE_NOVELHOST=172.16.16.2
DATABASE_NOVELDATA=novel_user_data
DATABASE_NOVELUSER=novel_data_user
DATABASE_NOVELUSER_PASSWORD=Lekairong350702
ENV_EOF

# 检查数据库连接
print_info "检查数据库连接..."
DB_ISSUES=0

# MongoDB
if ! timeout 10 bash -c "echo > /dev/tcp/172.16.32.2/27017" 2>/dev/null; then
    print_warning "MongoDB (172.16.32.2:27017) 连接失败"
    ((DB_ISSUES++))
fi

# Redis
if ! timeout 10 bash -c "echo > /dev/tcp/172.16.32.2/6379" 2>/dev/null; then
    print_warning "Redis (172.16.32.2:6379) 连接失败"
    ((DB_ISSUES++))
fi

# MySQL系统库
if ! timeout 10 bash -c "echo > /dev/tcp/172.16.16.3/3306" 2>/dev/null; then
    print_warning "MySQL系统库 (172.16.16.3:3306) 连接失败"
    ((DB_ISSUES++))
fi

# MySQL用户库
if ! timeout 10 bash -c "echo > /dev/tcp/172.16.16.2/3306" 2>/dev/null; then
    print_warning "MySQL用户库 (172.16.16.2:3306) 连接失败"
    ((DB_ISSUES++))
fi

if [ $DB_ISSUES -gt 0 ]; then
    print_warning "发现 $DB_ISSUES 个数据库连接问题，但继续部署"
fi

# 设置系统参数
print_info "配置系统参数..."
sysctl -w vm.max_map_count=1677720
echo 'vm.max_map_count=1677720' >> /etc/sysctl.conf

# 设置脚本权限
chmod +x scripts/*.sh 2>/dev/null || true

# 构建和启动服务
print_info "构建Docker镜像..."
docker-compose -f docker-compose.production.yml build --no-cache

print_info "启动服务..."
docker-compose -f docker-compose.production.yml up -d

# 等待服务启动
print_info "等待服务启动..."
sleep 60

# 检查服务状态
print_info "检查服务状态..."
docker-compose -f docker-compose.production.yml ps

# 健康检查
print_info "执行健康检查..."
HEALTH_OK=false
for i in {1..5}; do
    print_info "健康检查第 $i 次..."
    if curl -f --max-time 15 --connect-timeout 10 http://localhost:8000/health 2>/dev/null; then
        print_success "后端健康检查通过"
        HEALTH_OK=true
        break
    elif curl -f --max-time 15 --connect-timeout 10 http://localhost:8000/ 2>/dev/null; then
        print_success "后端根路径可访问"
        HEALTH_OK=true
        break
    else
        print_warning "第 $i 次健康检查失败"
        if [ $i -lt 5 ]; then
            sleep 15
        fi
    fi
done

# 配置防火墙
print_info "配置防火墙..."
ufw allow ssh 2>/dev/null || true
ufw allow 80/tcp 2>/dev/null || true
ufw allow 8000/tcp 2>/dev/null || true

# 显示最终结果
echo ""
echo "=============================================="
if [ "$HEALTH_OK" = true ]; then
    print_success "🎉 AI小说编辑器部署成功！"
    echo ""
    echo "📋 访问信息:"
    echo "🌐 前端地址: http://$SERVER_IP:80"
    echo "🔧 后端API: http://$SERVER_IP:8000"
    echo "📚 API文档: http://$SERVER_IP:8000/docs"
else
    print_warning "⚠️ 部署完成但健康检查未通过"
    echo ""
    echo "📋 故障排查:"
    echo "查看容器状态: docker-compose -f docker-compose.production.yml ps"
    echo "查看服务日志: docker-compose -f docker-compose.production.yml logs"
fi

echo ""
echo "📁 项目目录: $PROJECT_DIR"
echo "⚙️ 环境配置: $PROJECT_DIR/.env"
echo ""
echo "📋 常用命令:"
echo "重启服务: docker-compose -f docker-compose.production.yml restart"
echo "查看日志: docker-compose -f docker-compose.production.yml logs"
echo "停止服务: docker-compose -f docker-compose.production.yml down"

print_success "安装脚本执行完成！"
REMOTE_SCRIPT_EOF

    print_success "远程安装脚本创建完成"
}

# 上传并执行远程脚本
upload_and_execute() {
    print_info "上传安装脚本到服务器..."
    
    # 上传脚本
    if scp -P $SERVER_SSH_PORT /tmp/remote_install.sh $SERVER_USER@$SERVER_IP:/tmp/; then
        print_success "脚本上传成功"
    else
        print_error "脚本上传失败"
        exit 1
    fi
    
    # 执行安装
    print_info "开始远程安装..."
    ssh -p $SERVER_SSH_PORT $SERVER_USER@$SERVER_IP "
        export SERVER_IP='$SERVER_IP'
        export SERVER_USER='$SERVER_USER'
        export SILICONFLOW_API_KEY='$SILICONFLOW_API_KEY'
        export JWT_SECRET_KEY='$JWT_SECRET_KEY'
        export REDIS_PASSWORD='$REDIS_PASSWORD'
        export PERSONAL_ACCESS_TOKEN='$PERSONAL_ACCESS_TOKEN'
        export GITHUB_REPO='$GITHUB_REPO'
        chmod +x /tmp/remote_install.sh
        bash /tmp/remote_install.sh
    "
}

# 主函数
main() {
    echo ""
    print_info "AI小说编辑器一键安装工具"
    echo ""
    
    check_local_requirements
    get_user_config
    test_ssh_connection
    create_remote_script
    upload_and_execute
    
    echo ""
    print_success "🎉 一键安装完成！"
    echo ""
    print_info "后续操作："
    echo "1. 访问 http://$SERVER_IP:80 查看前端界面"
    echo "2. 访问 http://$SERVER_IP:8000/docs 查看API文档"
    echo "3. SSH连接服务器进行管理: ssh $SERVER_USER@$SERVER_IP"
    echo ""
}

# 错误处理
trap 'print_error "脚本执行中断"; exit 1' INT

# 执行主函数
main "$@"
