#!/bin/bash

# 依赖检查和安装脚本

set -e  # 出错时退出

echo "检查和安装AI小说编辑器依赖..."
echo "=================================="

PROJECT_ROOT="$(pwd)"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# 检查系统依赖
check_system_dependencies() {
    echo "检查系统依赖..."
    
    # 检查Python3
    if ! command -v python3 &> /dev/null; then
        print_error "Python3未安装，请先安装Python 3.11+"
        exit 1
    else
        PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
        print_status "Python3已安装 - 版本: $PYTHON_VERSION"
    fi
    
    # 检查pip
    if ! command -v pip3 &> /dev/null && ! command -v pip &> /dev/null; then
        print_error "pip未安装，请先安装pip"
        exit 1
    else
        print_status "pip已安装"
    fi
    
    # 检查Node.js
    if ! command -v node &> /dev/null; then
        print_error "Node.js未安装，请先安装Node.js 18+"
        exit 1
    else
        NODE_VERSION=$(node --version)
        print_status "Node.js已安装 - 版本: $NODE_VERSION"
    fi
    
    # 检查npm
    if ! command -v npm &> /dev/null; then
        print_error "npm未安装，请先安装npm"
        exit 1
    else
        print_status "npm已安装"
    fi
    
    # 检查或安装yarn
    if ! command -v yarn &> /dev/null; then
        print_warning "Yarn未安装，正在安装..."
        npm install -g yarn
        if [ $? -eq 0 ]; then
            print_status "Yarn安装成功"
        else
            print_error "Yarn安装失败"
            exit 1
        fi
    else
        YARN_VERSION=$(yarn --version)
        print_status "Yarn已安装 - 版本: $YARN_VERSION"
    fi
}

# 安装后端依赖
install_backend_dependencies() {
    echo ""
    echo "安装后端依赖..."
    
    cd "$PROJECT_ROOT/backend"
    
    # 创建Python虚拟环境
    if [ ! -d "venv" ]; then
        print_warning "创建Python虚拟环境..."
        python3 -m venv venv
        if [ $? -eq 0 ]; then
            print_status "虚拟环境创建成功"
        else
            print_error "虚拟环境创建失败"
            exit 1
        fi
    else
        print_status "虚拟环境已存在"
    fi
    
    # 激活虚拟环境
    source venv/bin/activate
    
    # 升级pip
    python -m pip install --upgrade pip
    
    # 安装Python依赖
    print_warning "安装Python依赖包..."
    pip install -r requirements.txt
    
    if [ $? -eq 0 ]; then
        print_status "后端依赖安装完成"
    else
        print_error "后端依赖安装失败"
        exit 1
    fi
    
    # 检查关键包
    echo "验证关键Python包..."
    python -c "import fastapi; print(f'FastAPI: {fastapi.__version__}')" 2>/dev/null && print_status "FastAPI已安装" || print_error "FastAPI安装失败"
    python -c "import uvicorn; print(f'Uvicorn: {uvicorn.__version__}')" 2>/dev/null && print_status "Uvicorn已安装" || print_error "Uvicorn安装失败"
    python -c "import sqlalchemy; print(f'SQLAlchemy: {sqlalchemy.__version__}')" 2>/dev/null && print_status "SQLAlchemy已安装" || print_error "SQLAlchemy安装失败"
    python -c "import httpx; print(f'HTTPX: {httpx.__version__}')" 2>/dev/null && print_status "HTTPX已安装" || print_error "HTTPX安装失败"
    
    deactivate
    cd "$PROJECT_ROOT"
}

# 安装前端依赖
install_frontend_dependencies() {
    echo ""
    echo "安装前端依赖..."
    
    cd "$PROJECT_ROOT/frontend"
    
    # 清理可能的缓存问题
    if [ -d "node_modules" ]; then
        print_warning "清理现有node_modules..."
        rm -rf node_modules
    fi
    
    if [ -f "yarn.lock" ]; then
        print_status "使用yarn.lock安装依赖"
    else
        print_warning "首次安装，将生成yarn.lock"
    fi
    
    # 安装依赖
    print_warning "安装前端依赖包..."
    yarn install --frozen-lockfile 2>/dev/null || yarn install
    
    if [ $? -eq 0 ]; then
        print_status "前端依赖安装完成"
    else
        print_error "前端依赖安装失败"
        exit 1
    fi
    
    # 检查关键包
    echo "验证关键前端包..."
    if [ -d "node_modules/vue" ]; then
        print_status "Vue3已安装"
    else
        print_error "Vue3安装失败"
    fi
    
    if [ -d "node_modules/element-plus" ]; then
        print_status "Element Plus已安装"
    else
        print_error "Element Plus安装失败"
    fi
    
    if [ -d "node_modules/vite" ]; then
        print_status "Vite已安装"
    else
        print_error "Vite安装失败"
    fi
    
    cd "$PROJECT_ROOT"
}

# 验证安装
verify_installation() {
    echo ""
    echo "验证安装完整性..."
    
    # 检查后端
    cd "$PROJECT_ROOT/backend"
    if [ -d "venv" ] && [ -f "requirements.txt" ]; then
        print_status "后端环境完整"
    else
        print_error "后端环境不完整"
        exit 1
    fi
    
    # 检查前端
    cd "$PROJECT_ROOT/frontend"
    if [ -d "node_modules" ] && [ -f "package.json" ]; then
        print_status "前端环境完整"
    else
        print_error "前端环境不完整"
        exit 1
    fi
    
    cd "$PROJECT_ROOT"
}

# 主函数
main() {
    check_system_dependencies
    install_backend_dependencies
    install_frontend_dependencies
    verify_installation
    
    echo ""
    echo "=================================="
    echo -e "${GREEN}🎉 所有依赖安装完成！${NC}"
    echo "=================================="
    echo ""
    echo "现在可以运行以下命令："
    echo "  ./start-dev.sh    - 启动开发环境"
    echo "  ./check-project.sh - 检查项目状态"
    echo ""
}

# 错误处理
trap 'echo -e "\n${RED}安装过程中出现错误，请检查上面的错误信息${NC}"; exit 1' ERR

# 运行主函数
main
