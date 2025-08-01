#!/bin/bash

# 主启动器 - 启动完整的开发环境
# 前端：端口5173，后端：端口3000

set -e  # 遇到错误立即退出

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 导入端口工具
source "$SCRIPT_DIR/port-utils.sh"

# 配置
FRONTEND_PORT=5173
BACKEND_PORT=3000
LOG_DIR="$PROJECT_ROOT/logs"

echo "🚀 启动乐格智小开发环境"
echo "========================"
echo "前端: http://localhost:$FRONTEND_PORT"
echo "后端: http://localhost:$BACKEND_PORT"
echo "========================"

# 创建日志目录
mkdir -p "$LOG_DIR"

# 检查必要的命令
command -v node >/dev/null 2>&1 || { echo "❌ Node.js 未安装"; exit 1; }
command -v npm >/dev/null 2>&1 || { echo "❌ npm 未安装"; exit 1; }

# 检查并清理端口
echo "🔍 检查端口状态..."
check_and_kill_port $BACKEND_PORT "后端服务"
check_and_kill_port $FRONTEND_PORT "前端服务"

echo ""
echo "⚙️ 启动服务..."

# 启动后端服务（后台）
echo "📡 启动后端服务..."
cd "$PROJECT_ROOT"
"$SCRIPT_DIR/start-backend.sh" > "$LOG_DIR/backend-full.log" 2>&1 &
BACKEND_PID=$!

# 等待后端启动
if wait_for_port $BACKEND_PORT "后端服务" 30; then
    echo "✅ 后端服务启动成功 (PID: $BACKEND_PID)"
else
    echo "❌ 后端服务启动失败"
    kill $BACKEND_PID 2>/dev/null || true
    exit 1
fi

# 启动前端服务（后台）
echo "🌐 启动前端服务..."
"$SCRIPT_DIR/start-frontend.sh" > "$LOG_DIR/frontend-full.log" 2>&1 &
FRONTEND_PID=$!

# 等待前端启动
if wait_for_port $FRONTEND_PORT "前端服务" 30; then
    echo "✅ 前端服务启动成功 (PID: $FRONTEND_PID)"
else
    echo "❌ 前端服务启动失败"
    kill $FRONTEND_PID 2>/dev/null || true
    kill $BACKEND_PID 2>/dev/null || true
    exit 1
fi

echo ""
echo "🎉 开发环境启动完成！"
echo "========================"
echo "📱 前端: http://localhost:$FRONTEND_PORT"
echo "🔧 后端: http://localhost:$BACKEND_PORT"
echo "📊 日志目录: $LOG_DIR"
echo "========================"
echo ""
echo "💡 提示："
echo "   - 按 Ctrl+C 停止所有服务"
echo "   - 查看后端日志: tail -f $LOG_DIR/backend-full.log"
echo "   - 查看前端日志: tail -f $LOG_DIR/frontend-full.log"
echo ""

# 创建进程 ID 文件
echo $BACKEND_PID > "$LOG_DIR/backend.pid"
echo $FRONTEND_PID > "$LOG_DIR/frontend.pid"

# 设置信号处理，确保退出时清理进程
cleanup() {
    echo ""
    echo "🛑 正在停止服务..."
    kill $BACKEND_PID 2>/dev/null || true
    kill $FRONTEND_PID 2>/dev/null || true
    rm -f "$LOG_DIR/backend.pid" "$LOG_DIR/frontend.pid"
    echo "✅ 服务已停止"
    exit 0
}

trap cleanup SIGINT SIGTERM

# 等待进程结束
wait
