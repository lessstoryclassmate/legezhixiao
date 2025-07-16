#!/bin/bash
# 私有库部署脚本 - 专门为私有GitHub库设计
# 根据需求文档：使用SSH方式克隆私有库进行部署

set -e  # 遇到错误立即退出

# 设置颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置变量 - 严格按照需求文档
SSH_REPO_URL="git@github.com:lessstoryclassmate/legezhixiao.git"
SSH_KEY_PATH="/root/.ssh/id_ed25519"
BAIDU_DNS="180.76.76.76"
DOCKER_REGISTRY="registry.baidubce.com"
DEPLOY_DIR="/opt/ai-novel-editor"
BACKUP_DIR="/opt/backups/ai-novel-editor"

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}     AI小说编辑器 - 私有库部署脚本${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""
echo "📋 部署信息："
echo "  私有库地址: $SSH_REPO_URL"
echo "  SSH密钥路径: $SSH_KEY_PATH"
echo "  部署目录: $DEPLOY_DIR"
echo "  备份目录: $BACKUP_DIR"
echo "  百度云DNS: $BAIDU_DNS"
echo "  Docker镜像仓库: $DOCKER_REGISTRY"
echo ""

# 1. 系统环境准备
echo -e "${YELLOW}🔧 系统环境准备...${NC}"

# 配置百度云DNS
if ! grep -q "$BAIDU_DNS" /etc/resolv.conf; then
    echo "nameserver $BAIDU_DNS" | sudo tee /etc/resolv.conf > /dev/null
    echo "nameserver 223.5.5.5" | sudo tee -a /etc/resolv.conf > /dev/null
    echo -e "${GREEN}✅ DNS配置完成${NC}"
else
    echo -e "${GREEN}✅ DNS已配置${NC}"
fi

# 安装必要工具
echo -e "${YELLOW}📦 安装必要工具...${NC}"
apt-get update -qq
apt-get install -y git docker.io docker-compose curl wget jq supervisor nginx

# 启动Docker服务
systemctl start docker
systemctl enable docker

echo -e "${GREEN}✅ 系统环境准备完成${NC}"

# 2. SSH密钥验证
echo -e "${YELLOW}🔑 SSH密钥验证...${NC}"

if [ ! -f "$SSH_KEY_PATH" ]; then
    echo -e "${RED}❌ SSH密钥文件不存在: $SSH_KEY_PATH${NC}"
    echo ""
    echo -e "${YELLOW}📝 请先配置SSH密钥：${NC}"
    echo "1. 生成SSH密钥: ssh-keygen -t ed25519 -f $SSH_KEY_PATH -N ''"
    echo "2. 将公钥添加到GitHub: cat ${SSH_KEY_PATH}.pub"
    echo "3. 运行验证脚本: ./scripts/verify-private-repo-access.sh"
    exit 1
fi

# 检查密钥权限
chmod 600 "$SSH_KEY_PATH"
echo -e "${GREEN}✅ SSH密钥验证通过${NC}"

# 3. 配置SSH客户端
echo -e "${YELLOW}🔧 配置SSH客户端...${NC}"

mkdir -p /root/.ssh
tee /root/.ssh/config > /dev/null << EOF
# GitHub私有库SSH配置
Host github.com
    HostName github.com
    User git
    Port 22
    IdentityFile $SSH_KEY_PATH
    IdentitiesOnly yes
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    ServerAliveInterval 60
    ServerAliveCountMax 3
EOF

chmod 600 /root/.ssh/config
echo -e "${GREEN}✅ SSH客户端配置完成${NC}"

# 4. 测试私有库访问
echo -e "${YELLOW}🔍 测试私有库访问...${NC}"

export GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $SSH_KEY_PATH"

if timeout 30 ssh -T -o ConnectTimeout=10 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i "$SSH_KEY_PATH" git@github.com 2>&1 | grep -q "successfully authenticated"; then
    echo -e "${GREEN}✅ 私有库访问权限验证成功${NC}"
else
    echo -e "${RED}❌ 私有库访问权限验证失败${NC}"
    echo ""
    echo -e "${YELLOW}📝 请检查：${NC}"
    echo "1. SSH密钥是否正确添加到GitHub"
    echo "2. 是否有私有库的访问权限"
    echo "3. 网络连接是否正常"
    exit 1
fi

# 5. 创建备份
if [ -d "$DEPLOY_DIR" ]; then
    echo -e "${YELLOW}💾 创建备份...${NC}"
    
    mkdir -p "$BACKUP_DIR"
    BACKUP_FILE="$BACKUP_DIR/backup-$(date +%Y%m%d-%H%M%S).tar.gz"
    
    tar -czf "$BACKUP_FILE" -C "$(dirname "$DEPLOY_DIR")" "$(basename "$DEPLOY_DIR")" 2>/dev/null || true
    
    if [ -f "$BACKUP_FILE" ]; then
        echo -e "${GREEN}✅ 备份创建成功: $BACKUP_FILE${NC}"
    else
        echo -e "${YELLOW}⚠️  备份创建失败或跳过${NC}"
    fi
fi

# 6. 停止现有服务
echo -e "${YELLOW}🛑 停止现有服务...${NC}"

# 停止Docker容器
docker-compose -f "$DEPLOY_DIR/docker-compose.production.yml" down 2>/dev/null || true
docker-compose -f "$DEPLOY_DIR/docker-compose.yml" down 2>/dev/null || true

# 停止系统服务
systemctl stop ai-novel-editor 2>/dev/null || true
systemctl stop nginx 2>/dev/null || true
systemctl stop supervisor 2>/dev/null || true

echo -e "${GREEN}✅ 现有服务已停止${NC}"

# 7. 克隆私有库
echo -e "${YELLOW}📥 克隆私有库...${NC}"

# 删除旧目录
rm -rf "$DEPLOY_DIR"
mkdir -p "$(dirname "$DEPLOY_DIR")"

# 克隆私有库
if timeout 120 git clone "$SSH_REPO_URL" "$DEPLOY_DIR"; then
    echo -e "${GREEN}✅ 私有库克隆成功${NC}"
    
    # 显示克隆信息
    cd "$DEPLOY_DIR"
    echo "  提交哈希: $(git rev-parse HEAD)"
    echo "  分支: $(git rev-parse --abbrev-ref HEAD)"
    echo "  最后提交: $(git log -1 --pretty=format:'%h - %s (%cr) <%an>')"
    echo "  文件数量: $(find . -type f | wc -l)"
else
    echo -e "${RED}❌ 私有库克隆失败${NC}"
    exit 1
fi

# 8. 配置Docker镜像仓库
echo -e "${YELLOW}🐳 配置Docker镜像仓库...${NC}"

# 配置Docker daemon使用百度云镜像仓库
tee /etc/docker/daemon.json > /dev/null << EOF
{
    "registry-mirrors": [
        "https://$DOCKER_REGISTRY"
    ],
    "insecure-registries": [
        "$DOCKER_REGISTRY"
    ]
}
EOF

systemctl restart docker
sleep 5

echo -e "${GREEN}✅ Docker镜像仓库配置完成${NC}"

# 9. 检查部署模式
echo -e "${YELLOW}🔍 检查部署模式...${NC}"

cd "$DEPLOY_DIR"

# 检查Docker是否可用
if command -v docker &> /dev/null && docker info &> /dev/null; then
    echo -e "${GREEN}✅ Docker可用，使用容器化部署${NC}"
    DEPLOY_MODE="docker"
else
    echo -e "${YELLOW}⚠️  Docker不可用，使用本地部署模式${NC}"
    DEPLOY_MODE="local"
fi

# 10. 执行部署
echo -e "${YELLOW}🚀 执行部署...${NC}"

if [ "$DEPLOY_MODE" = "docker" ]; then
    # Docker容器化部署
    echo -e "${BLUE}📦 Docker容器化部署...${NC}"
    
    # 构建镜像
    if [ -f "docker-compose.production.yml" ]; then
        echo "使用生产环境配置..."
        docker-compose -f docker-compose.production.yml build --no-cache
        docker-compose -f docker-compose.production.yml up -d
    else
        echo "使用开发环境配置..."
        docker-compose build --no-cache
        docker-compose up -d
    fi
    
    # 等待服务启动
    sleep 10
    
    # 检查容器状态
    if docker-compose ps | grep -q "Up"; then
        echo -e "${GREEN}✅ Docker容器部署成功${NC}"
    else
        echo -e "${RED}❌ Docker容器部署失败${NC}"
        docker-compose logs
        exit 1
    fi
    
else
    # 本地部署模式
    echo -e "${BLUE}🏠 本地部署模式...${NC}"
    
    if [ -f "scripts/local-deploy.sh" ]; then
        chmod +x scripts/local-deploy.sh
        ./scripts/local-deploy.sh
    else
        echo -e "${RED}❌ 本地部署脚本不存在${NC}"
        exit 1
    fi
fi

# 11. 配置Nginx
echo -e "${YELLOW}🌐 配置Nginx...${NC}"

tee /etc/nginx/sites-available/ai-novel-editor > /dev/null << EOF
server {
    listen 80;
    server_name _;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    location /api {
        proxy_pass http://localhost:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

ln -sf /etc/nginx/sites-available/ai-novel-editor /etc/nginx/sites-enabled/
nginx -t && systemctl restart nginx

echo -e "${GREEN}✅ Nginx配置完成${NC}"

# 12. 健康检查
echo -e "${YELLOW}🏥 健康检查...${NC}"

# 等待服务完全启动
sleep 15

# 检查端口
if netstat -tuln | grep -q ":80"; then
    echo -e "${GREEN}✅ 端口80已监听${NC}"
else
    echo -e "${RED}❌ 端口80未监听${NC}"
fi

# 检查HTTP响应
if curl -f -s -o /dev/null http://localhost/ 2>/dev/null; then
    echo -e "${GREEN}✅ HTTP服务响应正常${NC}"
else
    echo -e "${YELLOW}⚠️  HTTP服务响应异常${NC}"
fi

# 13. 部署完成
echo ""
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}           部署完成摘要${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""
echo -e "${GREEN}✅ AI小说编辑器私有库部署完成！${NC}"
echo ""
echo "📋 部署信息："
echo "  私有库地址: $SSH_REPO_URL"
echo "  部署目录: $DEPLOY_DIR"
echo "  部署模式: $DEPLOY_MODE"
echo "  访问地址: http://$(curl -s ifconfig.me):80"
echo "  本地访问: http://localhost:80"
echo ""
echo "🔧 服务状态："
if [ "$DEPLOY_MODE" = "docker" ]; then
    echo "  Docker容器:"
    docker-compose ps 2>/dev/null || echo "    无容器信息"
else
    echo "  本地服务:"
    systemctl is-active supervisor 2>/dev/null || echo "    Supervisor: $(systemctl is-active supervisor 2>/dev/null || echo '未知')"
fi
echo "  Nginx: $(systemctl is-active nginx 2>/dev/null || echo '未知')"
echo ""
echo "📝 后续操作："
echo "1. 检查应用运行状态"
echo "2. 验证功能是否正常"
echo "3. 配置域名解析（如需要）"
echo "4. 设置SSL证书（如需要）"
echo ""
echo -e "${BLUE}============================================${NC}"
