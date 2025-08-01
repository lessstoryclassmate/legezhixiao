#!/bin/bash

# 停止开发服务脚本

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 导入端口工具
source "$SCRIPT_DIR/port-utils.sh"

# 配置
FRONTEND_PORT=5173
BACKEND_PORT=3000
LOG_DIR="$PROJECT_ROOT/logs"

echo "🛑 停止开发服务"
echo "================"

# 从 PID 文件停止服务
if [ -f "$LOG_DIR/backend.pid" ]; then
    BACKEND_PID=$(cat "$LOG_DIR/backend.pid")
    echo "📡 停止后端服务 (PID: $BACKEND_PID)..."
    kill $BACKEND_PID 2>/dev/null || true
    rm -f "$LOG_DIR/backend.pid"
fi

if [ -f "$LOG_DIR/frontend.pid" ]; then
    FRONTEND_PID=$(cat "$LOG_DIR/frontend.pid")
    echo "🌐 停止前端服务 (PID: $FRONTEND_PID)..."
    kill $FRONTEND_PID 2>/dev/null || true
    rm -f "$LOG_DIR/frontend.pid"
fi

# 强制清理端口
echo "🔧 清理端口..."
check_and_kill_port $BACKEND_PORT "后端服务" || true
check_and_kill_port $FRONTEND_PORT "前端服务" || true

echo "✅ 所有服务已停止"
