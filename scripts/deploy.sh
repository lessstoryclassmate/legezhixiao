#!/bin/bash

# AI小说编辑器部署脚本
# 支持克隆GitHub仓库的方式部署

set -e

echo "🚀 开始部署AI小说内容编辑器..."

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查Docker是否安装
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker未安装，正在安装...${NC}"
        curl -fsSL https://get.docker.com | sh
        sudo usermod -aG docker $USER
        echo -e "${GREEN}✅ Docker安装完成${NC}"
    else
        echo -e "${GREEN}✅ Docker已安装${NC}"
    fi
}

# 检查Docker Compose是否安装
check_docker_compose() {
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${RED}❌ Docker Compose未安装，正在安装...${NC}"
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        echo -e "${GREEN}✅ Docker Compose安装完成${NC}"
    else
        echo -e "${GREEN}✅ Docker Compose已安装${NC}"
    fi
}

# 检查环境变量文件
check_env_file() {
    if [ ! -f .env ]; then
        echo -e "${YELLOW}⚠️  未找到.env文件，正在创建...${NC}"
        cp .env.example .env
        echo -e "${RED}❌ 请先配置.env文件中的环境变量！${NC}"
        echo -e "${YELLOW}📝 编辑 .env 文件，填写以下必要信息：${NC}"
        echo "   - SILICONFLOW_API_KEY: SiliconFlow API密钥"
        echo "   - JWT_SECRET_KEY: JWT密钥"
        echo "   - MONGO_PASSWORD: MongoDB密码"
        echo "   - REDIS_PASSWORD: Redis密码"
        echo "   - MYSQL_* 相关配置: 百度云数据库信息"
        exit 1
    else
        echo -e "${GREEN}✅ 环境变量文件已存在${NC}"
    fi
}

# 构建和启动服务
build_and_start() {
    echo -e "${YELLOW}🔧 正在构建Docker镜像...${NC}"
    docker-compose build --no-cache
    
    echo -e "${YELLOW}🚀 正在启动服务...${NC}"
    docker-compose up -d
    
    echo -e "${GREEN}✅ 服务启动成功！${NC}"
}

# 检查服务状态
check_services() {
    echo -e "${YELLOW}🔍 检查服务状态...${NC}"
    sleep 10
    
    # 检查前端服务
    if curl -f http://localhost:80 > /dev/null 2>&1; then
        echo -e "${GREEN}✅ 前端服务正常 (http://localhost:80)${NC}"
    else
        echo -e "${RED}❌ 前端服务异常${NC}"
    fi
    
    # 检查后端服务
    if curl -f http://localhost:8000/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ 后端服务正常 (http://localhost:8000)${NC}"
    else
        echo -e "${RED}❌ 后端服务异常${NC}"
    fi
    
    # 显示容器状态
    echo -e "${YELLOW}📊 容器状态：${NC}"
    docker-compose ps
}

# 显示访问信息
show_access_info() {
    echo -e "${GREEN}🎉 部署完成！${NC}"
    echo -e "${YELLOW}📝 访问信息：${NC}"
    echo "   🌐 前端地址: http://localhost:80"
    echo "   🔧 后端API: http://localhost:8000"
    echo "   📚 API文档: http://localhost:8000/docs"
    echo ""
    echo -e "${YELLOW}🛠️  常用命令：${NC}"
    echo "   查看日志: docker-compose logs -f"
    echo "   停止服务: docker-compose down"
    echo "   重启服务: docker-compose restart"
    echo "   更新代码: git pull && docker-compose up -d --build"
}

# 主函数
main() {
    echo -e "${GREEN}🎯 AI小说内容编辑器部署脚本${NC}"
    echo -e "${YELLOW}📁 当前目录: $(pwd)${NC}"
    echo ""
    
    # 检查必要环境
    check_docker
    check_docker_compose
    check_env_file
    
    # 停止现有服务
    if docker-compose ps | grep -q "Up"; then
        echo -e "${YELLOW}🛑 停止现有服务...${NC}"
        docker-compose down
    fi
    
    # 构建和启动
    build_and_start
    
    # 检查服务状态
    check_services
    
    # 显示访问信息
    show_access_info
}

# 处理参数
case "${1:-}" in
    "update")
        echo -e "${YELLOW}🔄 更新模式...${NC}"
        git pull
        docker-compose up -d --build
        ;;
    "logs")
        docker-compose logs -f
        ;;
    "stop")
        docker-compose down
        ;;
    "restart")
        docker-compose restart
        ;;
    *)
        main
        ;;
esac
