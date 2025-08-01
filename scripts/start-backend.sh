#!/bin/bash

# 后端启动器 - 固定端口3000
# 如果端口被占用则自动清理并重新启动

set -e  # 遇到错误立即退出

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 导入端口工具
source "$SCRIPT_DIR/port-utils.sh"

# 配置
BACKEND_PORT=3000
BACKEND_DIR="$PROJECT_ROOT/backend"
LOG_DIR="$PROJECT_ROOT/logs"

echo "🚀 启动后端服务 (固定端口: $BACKEND_PORT)"
echo "============================================"

# 创建日志目录
mkdir -p "$LOG_DIR"

# 检查并清理端口
if ! check_and_kill_port $BACKEND_PORT "后端服务"; then
    echo "❌ 无法清理端口 $BACKEND_PORT，启动失败"
    exit 1
fi

# 切换到后端目录
cd "$BACKEND_DIR"

# 检查 node_modules
if [ ! -d "node_modules" ]; then
    echo "📦 安装后端依赖..."
    npm install
fi

# 检查环境变量文件
if [ ! -f ".env" ] && [ -f ".env.example" ]; then
    echo "📋 复制环境变量配置..."
    cp .env.example .env
fi

# 设置环境变量
export PORT=$BACKEND_PORT
export NODE_ENV=development

# 启动后端服务
echo "⚙️ 启动后端服务..."
echo "   - 端口: $BACKEND_PORT"
echo "   - 环境: $NODE_ENV"
echo "   - 目录: $BACKEND_DIR"
echo "   - 日志: $LOG_DIR/backend.log"

# 启动服务（前台运行）
echo ""
echo "📡 后端服务启动中..."

# 使用 npm dev 脚本启动
npm run dev 2>&1 | tee "$LOG_DIR/backend.log"
