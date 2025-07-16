#!/bin/bash
# 本地部署脚本 - 避免Docker镜像源依赖
# 使用系统包管理器和本地构建方式部署

set -e

echo "🚀 启动本地部署脚本..."
echo "📋 避免Docker镜像源依赖，使用本地构建方式"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 定义变量
DEPLOY_DIR="/opt/ai-novel-editor"
PROJECT_NAME="ai-novel-editor"
BAIDU_DNS="180.76.76.76"
FRONTEND_PORT="80"
BACKEND_PORT="8000"

echo -e "${BLUE}📋 本地部署配置:${NC}"
echo "  项目名称: $PROJECT_NAME"
echo "  部署目录: $DEPLOY_DIR"
echo "  前端端口: $FRONTEND_PORT"
echo "  后端端口: $BACKEND_PORT"
echo "  DNS配置: $BAIDU_DNS"

# ===== 1. 系统环境准备 =====
echo -e "${BLUE}🔧 1. 系统环境准备...${NC}"

# 更新系统包
echo -e "${BLUE}📦 更新系统包...${NC}"
sudo apt-get update -y

# 安装基础依赖（不依赖Docker镜像源）
echo -e "${BLUE}📦 安装基础依赖...${NC}"
sudo apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    nodejs \
    npm \
    nginx \
    supervisor \
    git \
    curl \
    wget \
    build-essential \
    software-properties-common

echo -e "${GREEN}✅ 基础依赖安装完成${NC}"

# ===== 2. 配置DNS =====
echo -e "${BLUE}🌐 2. 配置DNS...${NC}"

# 备份原DNS配置
if [ -f "/etc/resolv.conf" ]; then
    sudo cp /etc/resolv.conf /etc/resolv.conf.backup
fi

# 设置百度云DNS
sudo bash -c "echo 'nameserver $BAIDU_DNS' > /etc/resolv.conf"
sudo bash -c "echo 'nameserver 223.5.5.5' >> /etc/resolv.conf"
sudo bash -c "echo 'nameserver 8.8.8.8' >> /etc/resolv.conf"

echo -e "${GREEN}✅ DNS配置完成${NC}"

# ===== 3. 进入项目目录 =====
echo -e "${BLUE}📁 3. 进入项目目录...${NC}"

if [ ! -d "$DEPLOY_DIR" ]; then
    echo -e "${RED}❌ 项目目录不存在: $DEPLOY_DIR${NC}"
    echo -e "${YELLOW}💡 请先运行 clone-fix.sh 脚本克隆项目${NC}"
    exit 1
fi

cd "$DEPLOY_DIR"
echo -e "${GREEN}✅ 已进入项目目录: $DEPLOY_DIR${NC}"

# ===== 4. 停止旧服务 =====
echo -e "${BLUE}🛑 4. 停止旧服务...${NC}"

# 停止supervisor管理的服务
sudo supervisorctl stop all 2>/dev/null || true

# 停止nginx
sudo systemctl stop nginx 2>/dev/null || true

# 杀死可能占用端口的进程
sudo lsof -ti:$FRONTEND_PORT | xargs sudo kill -9 2>/dev/null || true
sudo lsof -ti:$BACKEND_PORT | xargs sudo kill -9 2>/dev/null || true

echo -e "${GREEN}✅ 旧服务已停止${NC}"

# ===== 5. 后端部署 =====
echo -e "${BLUE}🐍 5. 后端部署...${NC}"

if [ -d "backend" ]; then
    cd backend
    
    # 创建Python虚拟环境
    echo -e "${BLUE}🔧 创建Python虚拟环境...${NC}"
    python3 -m venv venv
    source venv/bin/activate
    
    # 升级pip
    pip install --upgrade pip
    
    # 安装依赖（使用国内源）
    echo -e "${BLUE}📦 安装Python依赖...${NC}"
    if [ -f "requirements.txt" ]; then
        pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple/
    else
        # 如果没有requirements.txt，安装常见依赖
        pip install -i https://pypi.tuna.tsinghua.edu.cn/simple/ \
            fastapi \
            uvicorn \
            pydantic \
            python-multipart \
            python-jose \
            passlib \
            bcrypt \
            pymongo \
            redis \
            aiomysql \
            sqlalchemy \
            alembic \
            python-dotenv \
            requests \
            aiofiles \
            jinja2
    fi
    
    echo -e "${GREEN}✅ 后端依赖安装完成${NC}"
    
    # 创建环境变量文件
    echo -e "${BLUE}🔧 创建环境变量文件...${NC}"
    cat > .env << 'EOF'
# 数据库配置
MONGODB_HOST=172.16.32.2
MONGODB_PORT=27017
MONGODB_DATABASE=ai_novel_db
MONGODB_URL=mongodb://172.16.32.2:27017/ai_novel_db

# MySQL系统数据库
DATABASE_USER=lkr
DATABASE_PASSWORD=Lekairong350702
DATABASE_SYSTEMHOST=172.16.16.3
DATABASE_PORT=3306
DATABASE_SYSTEM=novel_data
DATABASE_SYSTEM_URL=mysql+aiomysql://lkr:Lekairong350702@172.16.16.3:3306/novel_data

# MySQL用户数据库
DATABASE_NOVELUSER=novel_data_user
DATABASE_NOVELUSER_PASSWORD=Lekairong350702
DATABASE_NOVELHOST=172.16.16.2
DATABASE_NOVELDATA=novel_user_data
DATABASE_NOVEL_URL=mysql+aiomysql://novel_data_user:Lekairong350702@172.16.16.2:3306/novel_user_data

# Redis配置
REDIS_HOST=172.16.32.2
REDIS_PORT=6379
REDIS_PASSWORD=Lekairong350702
REDIS_URL=redis://:Lekairong350702@172.16.32.2:6379

# SiliconFlow API
SILICONFLOW_API_KEY=sk-mjithqmjwccqgffouexthbavtnvftwkqjludpcxhrmeztcib
SILICONFLOW_DEFAULT_MODEL=deepseek-ai/DeepSeek-V3
SILICONFLOW_API_URL=https://api.siliconflow.cn/v1/chat/completions

# JWT配置
JWT_SECRET_KEY=your-secret-key-change-this-in-production

# CORS配置
CORS_ORIGINS=http://localhost:80,http://127.0.0.1:80,http://localhost:8080,http://127.0.0.1:8080,http://106.13.216.179:80,http://106.13.216.179:8080

# MCP服务器配置
MCP_SERVER_NAME=novel-ai-server
MCP_SERVER_PORT=8000
MCP_SERVER_HOST=106.13.216.179
MCP_TOOLS_ENABLED=true
MCP_TOOLS_LIST=novel_generation,character_creation,plot_analysis,content_review,style_transfer

# 小说生成配置
NOVEL_GENERATION_MAX_TOKENS=4096
NOVEL_GENERATION_TEMPERATURE=0.8
NOVEL_GENERATION_TOP_P=0.9
EOF
    
    echo -e "${GREEN}✅ 环境变量文件创建完成${NC}"
    
    # 创建supervisor配置文件
    echo -e "${BLUE}🔧 创建后端服务配置...${NC}"
    sudo tee /etc/supervisor/conf.d/ai-novel-backend.conf > /dev/null << EOF
[program:ai-novel-backend]
command=$DEPLOY_DIR/backend/venv/bin/uvicorn main:app --host 0.0.0.0 --port $BACKEND_PORT --reload
directory=$DEPLOY_DIR/backend
user=root
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/var/log/ai-novel-backend.log
environment=PATH="$DEPLOY_DIR/backend/venv/bin"
EOF
    
    echo -e "${GREEN}✅ 后端服务配置完成${NC}"
    
    cd ..
else
    echo -e "${YELLOW}⚠️ backend目录不存在，跳过后端部署${NC}"
fi

# ===== 6. 前端部署 =====
echo -e "${BLUE}🎨 6. 前端部署...${NC}"

if [ -d "frontend" ]; then
    cd frontend
    
    # 设置npm镜像源
    echo -e "${BLUE}🔧 设置npm镜像源...${NC}"
    npm config set registry https://registry.npmmirror.com
    npm config set disturl https://npmmirror.com/dist
    
    # 安装依赖
    echo -e "${BLUE}📦 安装前端依赖...${NC}"
    npm install
    
    # 构建前端
    echo -e "${BLUE}🔨 构建前端...${NC}"
    npm run build
    
    # 复制构建文件到nginx目录
    echo -e "${BLUE}📁 部署前端文件...${NC}"
    sudo rm -rf /var/www/html/*
    sudo cp -r dist/* /var/www/html/
    
    echo -e "${GREEN}✅ 前端部署完成${NC}"
    
    cd ..
else
    echo -e "${YELLOW}⚠️ frontend目录不存在，跳过前端部署${NC}"
fi

# ===== 7. 配置Nginx =====
echo -e "${BLUE}🌐 7. 配置Nginx...${NC}"

sudo tee /etc/nginx/sites-available/ai-novel-editor << EOF
server {
    listen $FRONTEND_PORT;
    server_name localhost;
    
    root /var/www/html;
    index index.html index.htm;
    
    # 前端静态文件
    location / {
        try_files \$uri \$uri/ /index.html;
    }
    
    # API代理到后端
    location /api/ {
        proxy_pass http://127.0.0.1:$BACKEND_PORT/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # 健康检查
    location /health {
        proxy_pass http://127.0.0.1:$BACKEND_PORT/health;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

# 启用站点
sudo ln -sf /etc/nginx/sites-available/ai-novel-editor /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

echo -e "${GREEN}✅ Nginx配置完成${NC}"

# ===== 8. 启动服务 =====
echo -e "${BLUE}🚀 8. 启动服务...${NC}"

# 重新加载supervisor配置
sudo supervisorctl reread
sudo supervisorctl update

# 启动后端服务
sudo supervisorctl start ai-novel-backend

# 测试nginx配置
sudo nginx -t

# 启动nginx
sudo systemctl start nginx
sudo systemctl enable nginx

echo -e "${GREEN}✅ 服务启动完成${NC}"

# ===== 9. 等待服务启动 =====
echo -e "${BLUE}⏳ 9. 等待服务启动...${NC}"
sleep 30

# ===== 10. 健康检查 =====
echo -e "${BLUE}🔍 10. 健康检查...${NC}"

# 检查后端服务状态
echo -e "${BLUE}🔍 检查后端服务状态...${NC}"
backend_status=$(sudo supervisorctl status ai-novel-backend | awk '{print $2}')
if [ "$backend_status" = "RUNNING" ]; then
    echo -e "${GREEN}✅ 后端服务运行正常${NC}"
else
    echo -e "${RED}❌ 后端服务状态异常: $backend_status${NC}"
    sudo supervisorctl tail ai-novel-backend
fi

# 检查nginx状态
echo -e "${BLUE}🔍 检查nginx状态...${NC}"
if sudo systemctl is-active --quiet nginx; then
    echo -e "${GREEN}✅ Nginx运行正常${NC}"
else
    echo -e "${RED}❌ Nginx状态异常${NC}"
    sudo systemctl status nginx
fi

# 检查端口监听
echo -e "${BLUE}🔍 检查端口监听...${NC}"
if sudo netstat -tlnp | grep :$FRONTEND_PORT > /dev/null; then
    echo -e "${GREEN}✅ 前端端口 $FRONTEND_PORT 监听正常${NC}"
else
    echo -e "${RED}❌ 前端端口 $FRONTEND_PORT 未监听${NC}"
fi

if sudo netstat -tlnp | grep :$BACKEND_PORT > /dev/null; then
    echo -e "${GREEN}✅ 后端端口 $BACKEND_PORT 监听正常${NC}"
else
    echo -e "${RED}❌ 后端端口 $BACKEND_PORT 未监听${NC}"
fi

# 健康检查HTTP请求
echo -e "${BLUE}🔍 HTTP健康检查...${NC}"

# 检查前端
if curl -f --max-time 10 http://localhost:$FRONTEND_PORT > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 前端服务健康检查通过${NC}"
else
    echo -e "${RED}❌ 前端服务健康检查失败${NC}"
fi

# 检查后端健康接口
if curl -f --max-time 10 http://localhost:$BACKEND_PORT/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 后端API健康检查通过${NC}"
else
    echo -e "${RED}❌ 后端API健康检查失败${NC}"
    echo -e "${YELLOW}🔍 后端服务日志:${NC}"
    sudo supervisorctl tail ai-novel-backend
fi

# ===== 11. 总结报告 =====
echo ""
echo "=================================================================================="
echo -e "${GREEN}🎉 本地部署完成！${NC}"
echo "=================================================================================="
echo ""
echo -e "${BLUE}📋 部署摘要:${NC}"
echo "✅ 系统环境准备完成"
echo "✅ DNS配置完成"
echo "✅ 后端服务部署完成"
echo "✅ 前端服务部署完成"
echo "✅ Nginx配置完成"
echo "✅ 服务启动完成"
echo "✅ 健康检查完成"
echo ""
echo -e "${BLUE}🌐 访问地址:${NC}"
echo "  前端应用: http://localhost:$FRONTEND_PORT"
echo "  后端API: http://localhost:$BACKEND_PORT"
echo "  健康检查: http://localhost:$BACKEND_PORT/health"
echo ""
echo -e "${BLUE}🛠️ 管理命令:${NC}"
echo "  查看后端日志: sudo supervisorctl tail ai-novel-backend"
echo "  重启后端: sudo supervisorctl restart ai-novel-backend"
echo "  重启nginx: sudo systemctl restart nginx"
echo "  查看服务状态: sudo supervisorctl status"
echo ""
echo -e "${BLUE}📁 重要文件:${NC}"
echo "  后端配置: /etc/supervisor/conf.d/ai-novel-backend.conf"
echo "  Nginx配置: /etc/nginx/sites-available/ai-novel-editor"
echo "  后端日志: /var/log/ai-novel-backend.log"
echo "  环境变量: $DEPLOY_DIR/backend/.env"
echo ""
echo -e "${GREEN}✅ 本地部署脚本执行完成${NC}"
