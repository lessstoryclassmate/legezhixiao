#!/bin/bash

# 开发环境启动脚本

set -e  # 出错时退出

echo "启动AI小说编辑器开发环境..."

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

# 快速检查依赖
quick_dependency_check() {
    local missing_deps=false
    
    # 检查Python环境
    if [ ! -d "backend/venv" ]; then
        print_warning "后端虚拟环境缺失"
        missing_deps=true
    fi
    
    # 检查前端依赖
    if [ ! -d "frontend/node_modules" ]; then
        print_warning "前端依赖缺失"
        missing_deps=true
    fi
    
    # 检查系统工具
    if ! command -v python3 &> /dev/null; then
        print_error "Python3未安装"
        missing_deps=true
    fi
    
    if ! command -v node &> /dev/null; then
        print_error "Node.js未安装"
        missing_deps=true
    fi
    
    if ! command -v yarn &> /dev/null; then
        print_error "Yarn未安装"
        missing_deps=true
    fi
    
    if [ "$missing_deps" = true ]; then
        echo ""
        print_warning "检测到缺失的依赖，请先运行依赖安装脚本："
        echo "  ./install-dependencies.sh"
        echo ""
        read -p "是否现在自动运行依赖安装？(y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ./install-dependencies.sh
        else
            exit 1
        fi
    fi
}

# 启动后端服务
start_backend() {
    print_status "启动后端服务..."
    cd "$PROJECT_ROOT/backend"
    
    # 激活虚拟环境
    source venv/bin/activate
    
    # 检查端口是否被占用
    if lsof -Pi :8000 -sTCP:LISTEN -t >/dev/null 2>&1; then
        print_warning "端口8000已被占用，尝试终止现有进程..."
        pkill -f "uvicorn main:app" 2>/dev/null || true
        sleep 2
    fi
    
    # 启动后端服务（后台运行）
    uvicorn main:app --reload --host 0.0.0.0 --port 8000 &
    BACKEND_PID=$!
    
    print_status "后端服务已启动 (PID: $BACKEND_PID)"
    
    # 等待后端启动
    echo "等待后端服务启动..."
    sleep 3
    
    # 验证后端是否正常启动
    if ps -p $BACKEND_PID > /dev/null; then
        print_status "后端服务运行正常"
    else
        print_error "后端服务启动失败"
        exit 1
    fi
    
    cd "$PROJECT_ROOT"
}

# 启动前端服务  
start_frontend() {
    print_status "启动前端服务..."
    cd "$PROJECT_ROOT/frontend"
    
    # 检查端口是否被占用
    if lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null 2>&1; then
        print_warning "端口3000已被占用，尝试终止现有进程..."
        pkill -f "vite" 2>/dev/null || true
        sleep 2
    fi
    
    # 启动前端服务
    yarn dev &
    FRONTEND_PID=$!
    
    print_status "前端服务已启动 (PID: $FRONTEND_PID)"
    
    # 等待前端启动
    echo "等待前端服务启动..."
    sleep 3
    
    # 验证前端是否正常启动
    if ps -p $FRONTEND_PID > /dev/null; then
        print_status "前端服务运行正常"
    else
        print_error "前端服务启动失败"
        exit 1
    fi
    
    cd "$PROJECT_ROOT"
}

# 显示启动信息
show_startup_info() {
    echo ""
    echo "=================================="
    echo -e "${GREEN}🚀 开发环境启动完成！${NC}"
    echo "=================================="
    echo "🌐 前端界面: http://localhost:3000"
    echo "🔌 后端API: http://localhost:8000"
    echo "📖 API文档: http://localhost:8000/docs"
    echo "🔍 Swagger UI: http://localhost:8000/redoc"
    echo ""
    echo "📊 服务状态:"
    echo "  后端进程 PID: $BACKEND_PID"
    echo "  前端进程 PID: $FRONTEND_PID"
    echo ""
    echo "💡 提示:"
    echo "  - 按 Ctrl+C 停止所有服务"
    echo "  - 代码修改会自动热重载"
    echo "  - 查看日志请查看终端输出"
    echo "=================================="
}

# 清理函数
cleanup() {
    echo ""
    print_warning "正在停止服务..."
    
    # 停止后端
    if [ ! -z "$BACKEND_PID" ] && ps -p $BACKEND_PID > /dev/null; then
        kill $BACKEND_PID 2>/dev/null || true
        print_status "后端服务已停止"
    fi
    
    # 停止前端
    if [ ! -z "$FRONTEND_PID" ] && ps -p $FRONTEND_PID > /dev/null; then
        kill $FRONTEND_PID 2>/dev/null || true
        print_status "前端服务已停止"
    fi
    
    # 额外清理
    pkill -f "uvicorn main:app" 2>/dev/null || true
    pkill -f "vite" 2>/dev/null || true
    
    echo -e "${GREEN}👋 服务已全部停止，再见！${NC}"
    exit 0
}

# 主函数
main() {
    # 检查依赖
    quick_dependency_check
    
    # 启动服务
    start_backend
    start_frontend
    
    # 显示信息
    show_startup_info
    
    # 等待用户中断
    trap cleanup INT TERM
    
    # 保持脚本运行并监控进程
    while true; do
        if ! ps -p $BACKEND_PID > /dev/null; then
            print_error "后端服务意外停止"
            cleanup
        fi
        
        if ! ps -p $FRONTEND_PID > /dev/null; then
            print_error "前端服务意外停止"
            cleanup
        fi
        
        sleep 5
    done
}

# 错误处理
trap 'print_error "启动过程中出现错误"; cleanup' ERR

# 运行主函数
main
