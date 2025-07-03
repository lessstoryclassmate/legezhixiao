#!/bin/bash

# 包状态检查脚本

echo "检查AI小说编辑器包安装状态..."
echo "================================"

PROJECT_ROOT="$(pwd)"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 检查系统工具
check_system_tools() {
    echo "1. 系统工具检查"
    echo "----------------"
    
    # Python
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version 2>&1)
        print_status "Python: $PYTHON_VERSION"
    else
        print_error "Python3: 未安装"
    fi
    
    # Node.js
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version)
        print_status "Node.js: $NODE_VERSION"
    else
        print_error "Node.js: 未安装"
    fi
    
    # npm
    if command -v npm &> /dev/null; then
        NPM_VERSION=$(npm --version)
        print_status "npm: $NPM_VERSION"
    else
        print_error "npm: 未安装"
    fi
    
    # Yarn
    if command -v yarn &> /dev/null; then
        YARN_VERSION=$(yarn --version)
        print_status "Yarn: $YARN_VERSION"
    else
        print_error "Yarn: 未安装"
    fi
    
    # pip
    if command -v pip3 &> /dev/null; then
        PIP_VERSION=$(pip3 --version | cut -d' ' -f2)
        print_status "pip: $PIP_VERSION"
    else
        print_error "pip: 未安装"
    fi
    
    echo ""
}

# 检查后端环境
check_backend_environment() {
    echo "2. 后端环境检查"
    echo "----------------"
    
    cd "$PROJECT_ROOT/backend"
    
    # 虚拟环境
    if [ -d "venv" ]; then
        print_status "Python虚拟环境: 已创建"
        
        # 激活虚拟环境并检查包
        source venv/bin/activate
        
        # 检查关键包
        echo "  检查Python包:"
        
        packages=(
            "fastapi"
            "uvicorn" 
            "sqlalchemy"
            "pydantic"
            "httpx"
            "jose"
            "passlib"
            "pymysql"
            "python-dotenv"
        )
        
        for package in "${packages[@]}"; do
            case $package in
                "python-dotenv")
                    if python -c "from dotenv import load_dotenv" 2>/dev/null; then
                        version=$(pip show python-dotenv 2>/dev/null | grep Version | cut -d' ' -f2)
                        print_status "    $package: $version"
                    else
                        print_error "    $package: 未安装或导入失败"
                    fi
                    ;;
                "jose")
                    if python -c "import jose" 2>/dev/null; then
                        version=$(python -c "import jose; print(getattr(jose, '__version__', 'unknown'))" 2>/dev/null)
                        print_status "    $package: $version"
                    else
                        print_error "    $package: 未安装或导入失败"
                    fi
                    ;;
                *)
                    if python -c "import $package" 2>/dev/null; then
                        version=$(python -c "import $package; print(getattr($package, '__version__', 'unknown'))" 2>/dev/null)
                        print_status "    $package: $version"
                    else
                        print_error "    $package: 未安装或导入失败"
                    fi
                    ;;
            esac
        done
        
        deactivate
    else
        print_error "Python虚拟环境: 未创建"
    fi
    
    cd "$PROJECT_ROOT"
    echo ""
}

# 检查前端环境
check_frontend_environment() {
    echo "3. 前端环境检查"
    echo "----------------"
    
    cd "$PROJECT_ROOT/frontend"
    
    # node_modules
    if [ -d "node_modules" ]; then
        print_status "node_modules: 已安装"
        
        # 检查关键包
        echo "  检查前端包:"
        
        packages=(
            "vue"
            "vue-router" 
            "pinia"
            "element-plus"
            "@element-plus/icons-vue"
            "axios"
            "vite"
            "@vitejs/plugin-vue"
            "monaco-editor"
            "markdown-it"
        )
        
        for package in "${packages[@]}"; do
            if [ -d "node_modules/$package" ]; then
                if [ -f "node_modules/$package/package.json" ]; then
                    version=$(grep '"version"' "node_modules/$package/package.json" | cut -d'"' -f4)
                    print_status "    $package: $version"
                else
                    print_status "    $package: 已安装"
                fi
            else
                print_error "    $package: 未安装"
            fi
        done
    else
        print_error "node_modules: 未安装"
    fi
    
    # yarn.lock
    if [ -f "yarn.lock" ]; then
        print_status "yarn.lock: 存在"
    else
        print_warning "yarn.lock: 不存在（首次安装时会创建）"
    fi
    
    cd "$PROJECT_ROOT"
    echo ""
}

# 检查配置文件
check_config_files() {
    echo "4. 配置文件检查"
    echo "----------------"
    
    # 后端配置
    if [ -f "backend/.env" ]; then
        print_status "后端环境配置: backend/.env 存在"
    else
        print_warning "后端环境配置: backend/.env 不存在"
    fi
    
    if [ -f "backend/requirements.txt" ]; then
        BACKEND_DEPS=$(wc -l < backend/requirements.txt)
        print_status "后端依赖配置: $BACKEND_DEPS 个包"
    else
        print_error "后端依赖配置: requirements.txt 不存在"
    fi
    
    # 前端配置
    if [ -f "frontend/package.json" ]; then
        print_status "前端包配置: package.json 存在"
    else
        print_error "前端包配置: package.json 不存在"
    fi
    
    if [ -f "frontend/vite.config.js" ]; then
        print_status "Vite配置: vite.config.js 存在"
    else
        print_error "Vite配置: vite.config.js 不存在"
    fi
    
    echo ""
}

# 检查端口占用
check_ports() {
    echo "5. 端口检查"
    echo "------------"
    
    # 检查后端端口 8000
    if lsof -Pi :8000 -sTCP:LISTEN -t >/dev/null 2>&1; then
        print_warning "端口 8000: 已被占用"
    else
        print_status "端口 8000: 可用"
    fi
    
    # 检查前端端口 3000
    if lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null 2>&1; then
        print_warning "端口 3000: 已被占用"
    else
        print_status "端口 3000: 可用"
    fi
    
    echo ""
}

# 检查容器化和K8S工具
check_container_tools() {
    echo "6. 容器化和K8S工具检查"
    echo "--------------------"
    
    # Docker
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
        print_status "Docker: $DOCKER_VERSION"
        
        # 检查Docker是否运行
        if docker info &> /dev/null; then
            print_status "Docker服务: 运行中"
        else
            print_warning "Docker服务: 未运行或无权限"
        fi
    else
        print_warning "Docker: 未安装"
    fi
    
    # K3S
    if command -v k3s &> /dev/null; then
        K3S_VERSION=$(sudo k3s --version | head -1 | cut -d' ' -f3)
        print_status "K3S: $K3S_VERSION"
        
        # 检查K3S是否运行
        if pgrep -f "k3s server" > /dev/null; then
            print_status "K3S集群: 运行中"
            
            # 检查kubeconfig
            if [ -f "/etc/rancher/k3s/k3s.yaml" ]; then
                print_status "Kubeconfig: 存在"
                
                # 尝试连接集群
                if sudo KUBECONFIG=/etc/rancher/k3s/k3s.yaml kubectl get nodes &> /dev/null; then
                    print_status "K3S连接: 正常"
                else
                    print_warning "K3S连接: 异常"
                fi
            else
                print_warning "Kubeconfig: 不存在"
            fi
        else
            print_warning "K3S集群: 未运行"
            echo "  启动命令: ./k3s-manager.sh start"
        fi
    else
        print_warning "K3S: 未安装"
        echo "  安装命令: curl -sfL https://get.k3s.io | sudo sh -"
    fi
    
    # kubectl
    if command -v kubectl &> /dev/null; then
        KUBECTL_VERSION=$(kubectl version --client --short 2>/dev/null | cut -d' ' -f3)
        print_status "kubectl: $KUBECTL_VERSION"
    else
        print_warning "kubectl: 未安装"
    fi
    
    echo ""
}

# 生成报告
generate_summary() {
    echo "7. 检查总结"
    echo "============"
    
    local issues=0
    
    # 系统工具检查
    if ! command -v python3 &> /dev/null || ! command -v node &> /dev/null || ! command -v yarn &> /dev/null; then
        print_error "系统工具缺失，请安装必要的工具"
        issues=$((issues + 1))
    fi
    
    # 后端环境检查
    if [ ! -d "backend/venv" ]; then
        print_error "后端环境未配置，请运行 ./install-dependencies.sh"
        issues=$((issues + 1))
    fi
    
    # 前端环境检查
    if [ ! -d "frontend/node_modules" ]; then
        print_error "前端环境未配置，请运行 ./install-dependencies.sh"
        issues=$((issues + 1))
    fi
    
    # 端口检查
    if lsof -Pi :8000 -sTCP:LISTEN -t >/dev/null 2>&1 || lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null 2>&1; then
        print_warning "发现端口被占用，请检查服务状态"
    fi
    
    # 容器化和K8S工具检查
    if ! command -v docker &> /dev/null || ! command -v k3s &> /dev/null; then
        print_error "容器化或K8S工具缺失，请安装必要的工具"
        issues=$((issues + 1))
    fi
    
    if [ $issues -eq 0 ]; then
        echo -e "${GREEN}🎉 所有检查通过！环境配置完整。${NC}"
        echo ""
        echo "可以运行以下命令："
        echo "  ./start-dev.sh    - 启动开发环境"
        echo "  ./deploy.sh       - 部署到生产环境"
    else
        echo -e "${RED}发现 $issues 个问题，请先解决这些问题。${NC}"
        echo ""
        echo "建议运行："
        echo "  ./install-dependencies.sh  - 安装所有依赖"
    fi
}

# 主函数
main() {
    check_system_tools
    check_backend_environment
    check_frontend_environment
    check_config_files
    check_ports
    check_container_tools
    generate_summary
}

# 运行检查
main
