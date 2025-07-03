#!/bin/bash

# 生产环境部署脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 输出函数
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_step() {
    echo -e "${CYAN}🔧 $1${NC}"
}

echo "=========================================="
echo -e "${GREEN}🚀 AI小说编辑器 - 生产环境部署${NC}"
echo "=========================================="
echo ""

PROJECT_ROOT="$(pwd)"
DEPLOY_ENV="${1:-production}"
VERSION="${2:-latest}"

# 检查部署参数
check_deployment_params() {
    print_info "检查部署参数..."
    echo "  环境: $DEPLOY_ENV"
    echo "  版本: $VERSION"
    echo "  项目根目录: $PROJECT_ROOT"
    echo ""
    
    if [[ ! "$DEPLOY_ENV" =~ ^(production|staging)$ ]]; then
        print_error "无效的部署环境: $DEPLOY_ENV (支持: production, staging)"
        exit 1
    fi
}

# 检查必要工具
check_requirements() {
    print_step "检查必要工具..."
    
    local missing_tools=false
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker未安装"
        missing_tools=true
    fi
    
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl未安装"
        missing_tools=true
    fi
    
    if [ "$missing_tools" = true ]; then
        print_error "请安装缺失的工具后重新运行"
        exit 1
    fi
    
    print_status "所有必要工具已安装"
    
    # 显示工具版本
    echo "  Docker: $(docker --version)"
    echo "  kubectl: $(kubectl version --client --short 2>/dev/null || echo 'N/A')"
}

# 构建Docker镜像
build_docker_images() {
    print_step "构建Docker镜像..."
    
    # 构建后端镜像
    print_info "构建后端镜像..."
    cd "$PROJECT_ROOT/backend"
    docker build -t novel-editor-backend:$VERSION .
    docker tag novel-editor-backend:$VERSION novel-editor-backend:latest
    
    # 构建前端镜像
    print_info "构建前端镜像..."
    cd "$PROJECT_ROOT/frontend"
    docker build -t novel-editor-frontend:$VERSION .
    docker tag novel-editor-frontend:$VERSION novel-editor-frontend:latest
    
    cd "$PROJECT_ROOT"
    print_status "Docker镜像构建完成"
}

# 推送镜像到仓库
push_images() {
    print_step "推送镜像到仓库..."
    
    # 这里可以根据实际情况推送到Docker Hub或私有仓库
    # docker push novel-editor-backend:$VERSION
    # docker push novel-editor-frontend:$VERSION
    
    print_warning "镜像推送已跳过 (本地部署)"
    print_info "如需推送到远程仓库，请配置Docker Registry"
}

# 部署数据库
deploy_database() {
    print_step "部署数据库..."
    
    # 检查MySQL容器是否运行
    if docker ps --format 'table {{.Names}}' | grep -q "mysql-system\|mysql-user"; then
        print_warning "MySQL容器已运行，跳过数据库部署"
        return 0
    fi
    
    # 启动MySQL数据库
    print_info "启动MySQL数据库..."
    
    # 系统数据库
    docker run -d \
        --name mysql-system-prod \
        --network novel-editor-network 2>/dev/null || docker network create novel-editor-network \
        -e MYSQL_ROOT_PASSWORD=Lekairong350702 \
        -e MYSQL_DATABASE=novel_data \
        -e MYSQL_USER=lkr \
        -e MYSQL_PASSWORD=Lekairong350702 \
        -p 3307:3306 \
        -v mysql-system-data:/var/lib/mysql \
        mysql:8.0 \
        --character-set-server=utf8mb4 \
        --collation-server=utf8mb4_unicode_ci || true
    
    # 用户数据库
    docker run -d \
        --name mysql-user-prod \
        --network novel-editor-network \
        -e MYSQL_ROOT_PASSWORD=Lekairong350702 \
        -e MYSQL_DATABASE=novel_user_data \
        -e MYSQL_USER=novel_data_user \
        -e MYSQL_PASSWORD=Lekairong350702 \
        -p 3308:3306 \
        -v mysql-user-data:/var/lib/mysql \
        mysql:8.0 \
        --character-set-server=utf8mb4 \
        --collation-server=utf8mb4_unicode_ci || true
    
    print_status "数据库部署完成"
    
    # 等待数据库启动
    print_info "等待数据库启动..."
    sleep 15
    
    # 验证数据库连接
    if docker exec mysql-system-prod mysqladmin ping -h localhost --silent; then
        print_status "系统数据库连接正常"
    else
        print_warning "系统数据库连接检查失败"
    fi
    
    if docker exec mysql-user-prod mysqladmin ping -h localhost --silent; then
        print_status "用户数据库连接正常"
    else
        print_warning "用户数据库连接检查失败"
    fi
}

# 部署应用服务
deploy_application() {
    print_step "部署应用服务..."
    
    # 停止现有容器
    print_info "停止现有服务..."
    docker stop novel-editor-backend-prod novel-editor-frontend-prod 2>/dev/null || true
    docker rm novel-editor-backend-prod novel-editor-frontend-prod 2>/dev/null || true
    
    # 部署后端服务
    print_info "部署后端服务..."
    docker run -d \
        --name novel-editor-backend-prod \
        --network novel-editor-network \
        -p 8000:8000 \
        -e DATABASE_SYSTEM_HOST=mysql-system-prod \
        -e DATABASE_SYSTEM_PORT=3306 \
        -e DATABASE_SYSTEM_NAME=novel_data \
        -e DATABASE_SYSTEM_USER=lkr \
        -e DATABASE_SYSTEM_PASSWORD=Lekairong350702 \
        -e DATABASE_USER_HOST=mysql-user-prod \
        -e DATABASE_USER_PORT=3306 \
        -e DATABASE_USER_NAME=novel_user_data \
        -e DATABASE_USER_USER=novel_data_user \
        -e DATABASE_USER_PASSWORD=Lekairong350702 \
        -e SILICONFLOW_API_KEY=sk-mjithqmjwccqgffouexthbavtnvftwkqjludpcxhrmeztcib \
        -e SECRET_KEY=production-secret-key-$(date +%s) \
        -e ENVIRONMENT=production \
        --restart unless-stopped \
        novel-editor-backend:$VERSION
    
    # 部署前端服务
    print_info "部署前端服务..."
    docker run -d \
        --name novel-editor-frontend-prod \
        --network novel-editor-network \
        -p 3000:3000 \
        -e VITE_API_BASE_URL=http://localhost:8000 \
        -e VITE_ENVIRONMENT=production \
        --restart unless-stopped \
        novel-editor-frontend:$VERSION
    
    print_status "应用服务部署完成"
}

# 配置反向代理
setup_nginx() {
    print_step "配置Nginx反向代理..."
    
    # 创建Nginx配置目录
    mkdir -p /tmp/nginx-conf
    
    # 生成Nginx配置文件
    cat > /tmp/nginx-conf/nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    upstream backend {
        server novel-editor-backend-prod:8000;
    }
    
    upstream frontend {
        server novel-editor-frontend-prod:3000;
    }
    
    server {
        listen 80;
        server_name localhost;
        
        # 前端静态资源
        location / {
            proxy_pass http://frontend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
        
        # API接口
        location /api/ {
            proxy_pass http://backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
        
        # API文档
        location /docs {
            proxy_pass http://backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
        
        location /redoc {
            proxy_pass http://backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
EOF
    
    # 停止现有Nginx容器
    docker stop nginx-novel-editor 2>/dev/null || true
    docker rm nginx-novel-editor 2>/dev/null || true
    
    # 启动Nginx容器
    docker run -d \
        --name nginx-novel-editor \
        --network novel-editor-network \
        -p 80:80 \
        -v /tmp/nginx-conf/nginx.conf:/etc/nginx/nginx.conf:ro \
        --restart unless-stopped \
        nginx:alpine
    
    print_status "Nginx反向代理配置完成"
}

# 健康检查
health_check() {
    print_step "执行健康检查..."
    
    local max_retries=30
    local retry_count=0
    
    print_info "等待服务启动..."
    sleep 10
    
    # 检查后端健康状态
    print_info "检查后端服务..."
    while [ $retry_count -lt $max_retries ]; do
        if curl -f http://localhost:8000/health &>/dev/null; then
            print_status "后端服务健康检查通过"
            break
        fi
        
        retry_count=$((retry_count + 1))
        echo "  重试 $retry_count/$max_retries..."
        sleep 2
    done
    
    if [ $retry_count -eq $max_retries ]; then
        print_error "后端服务健康检查失败"
        return 1
    fi
    
    # 检查前端服务
    print_info "检查前端服务..."
    retry_count=0
    while [ $retry_count -lt $max_retries ]; do
        if curl -f http://localhost:3000 &>/dev/null; then
            print_status "前端服务健康检查通过"
            break
        fi
        
        retry_count=$((retry_count + 1))
        echo "  重试 $retry_count/$max_retries..."
        sleep 2
    done
    
    if [ $retry_count -eq $max_retries ]; then
        print_error "前端服务健康检查失败"
        return 1
    fi
    
    # 检查Nginx
    print_info "检查Nginx代理..."
    if curl -f http://localhost/ &>/dev/null; then
        print_status "Nginx代理健康检查通过"
    else
        print_warning "Nginx代理健康检查失败"
    fi
    
    print_status "所有健康检查完成"
}

# 显示部署结果
show_deployment_result() {
    echo ""
    echo "=========================================="
    echo -e "${GREEN}🎉 生产环境部署完成！${NC}"
    echo "=========================================="
    echo ""
    echo -e "${CYAN}📊 服务状态:${NC}"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" --filter "name=novel-editor"
    echo ""
    echo -e "${CYAN}🌐 访问地址:${NC}"
    echo "  前端界面: http://localhost/"
    echo "  后端API: http://localhost:8000"
    echo "  API文档: http://localhost/docs"
    echo "  Swagger UI: http://localhost/redoc"
    echo ""
    echo -e "${CYAN}🗄️ 数据库:${NC}"
    echo "  系统数据库: localhost:3307"
    echo "  用户数据库: localhost:3308"
    echo ""
    echo -e "${CYAN}🔧 管理命令:${NC}"
    echo "  查看日志: docker logs [容器名]"
    echo "  重启服务: docker restart [容器名]"
    echo "  停止部署: ./deploy-prod.sh stop"
    echo ""
    echo -e "${GREEN}✅ 部署成功完成！${NC}"
}

# 停止部署
stop_deployment() {
    print_step "停止生产环境部署..."
    
    # 停止所有相关容器
    docker stop nginx-novel-editor novel-editor-frontend-prod novel-editor-backend-prod mysql-user-prod mysql-system-prod 2>/dev/null || true
    
    print_status "生产环境已停止"
}

# 清理部署
cleanup_deployment() {
    print_step "清理生产环境部署..."
    
    # 停止并删除容器
    docker stop nginx-novel-editor novel-editor-frontend-prod novel-editor-backend-prod mysql-user-prod mysql-system-prod 2>/dev/null || true
    docker rm nginx-novel-editor novel-editor-frontend-prod novel-editor-backend-prod mysql-user-prod mysql-system-prod 2>/dev/null || true
    
    # 删除网络
    docker network rm novel-editor-network 2>/dev/null || true
    
    # 清理临时文件
    rm -rf /tmp/nginx-conf
    
    print_status "生产环境已清理完成"
}

# 显示帮助信息
show_help() {
    echo "用法: $0 [环境] [版本] [操作]"
    echo ""
    echo "环境:"
    echo "  production  生产环境 (默认)"
    echo "  staging     预发布环境"
    echo ""
    echo "版本:"
    echo "  latest      最新版本 (默认)"
    echo "  v1.0.0      指定版本"
    echo ""
    echo "操作:"
    echo "  deploy      部署 (默认)"
    echo "  stop        停止服务"
    echo "  cleanup     清理部署"
    echo "  status      查看状态"
    echo "  help        显示帮助"
    echo ""
    echo "示例:"
    echo "  $0                          # 部署到生产环境"
    echo "  $0 production v1.0.0        # 部署指定版本到生产环境"
    echo "  $0 staging                  # 部署到预发布环境"
    echo "  $0 production latest stop   # 停止生产环境"
    echo "  $0 production latest cleanup # 清理生产环境"
}

# 查看部署状态
show_status() {
    echo "=========================================="
    echo -e "${CYAN}📊 部署状态检查${NC}"
    echo "=========================================="
    echo ""
    
    echo -e "${BLUE}Docker容器状态:${NC}"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" --filter "name=novel-editor" || echo "  无相关容器运行"
    echo ""
    
    echo -e "${BLUE}数据库状态:${NC}"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" --filter "name=mysql" || echo "  无数据库容器运行"
    echo ""
    
    echo -e "${BLUE}网络状态:${NC}"
    docker network ls --filter "name=novel-editor" || echo "  无相关网络"
    echo ""
    
    echo -e "${BLUE}镜像状态:${NC}"
    docker images --filter "reference=novel-editor*" || echo "  无相关镜像"
}

# 主函数
main() {
    local action="${3:-deploy}"
    
    case "$action" in
        "deploy")
            check_deployment_params
            check_requirements
            build_docker_images
            push_images
            deploy_database
            deploy_application
            setup_nginx
            health_check
            show_deployment_result
            ;;
        "stop")
            stop_deployment
            ;;
        "cleanup")
            cleanup_deployment
            ;;
        "status")
            show_status
            ;;
        "help")
            show_help
            ;;
        *)
            print_error "未知操作: $action"
            show_help
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"
