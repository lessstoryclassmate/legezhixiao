#!/bin/bash
# 80端口冲突快速检测和修复脚本

echo "🔍 检查80端口冲突情况..."

# 检查80端口占用
echo "📋 当前80端口占用情况:"
echo "=== lsof检查 ==="
sudo lsof -i :80 2>/dev/null || echo "lsof: 端口80未被占用"

echo ""
echo "=== netstat检查 ==="
sudo netstat -tlnp | grep :80 || echo "netstat: 端口80未被占用"

echo ""
echo "=== ss检查 ==="
sudo ss -tlnp | grep :80 || echo "ss: 端口80未被占用"

echo ""
echo "📋 常见Web服务器状态:"
for service in nginx apache2 httpd lighttpd; do
    if systemctl is-active $service &>/dev/null; then
        echo "⚠️ $service: 运行中"
    else
        echo "✅ $service: 已停止"
    fi
done

echo ""
echo "📋 Docker容器80端口映射:"
if command -v docker &> /dev/null; then
    docker ps --format "table {{.Names}}\t{{.Ports}}" | grep ":80->" || echo "无Docker容器占用80端口"
else
    echo "Docker不可用"
fi

echo ""
echo "🔧 解决80端口冲突的建议:"
echo "1. 停止Nginx: sudo systemctl stop nginx && sudo systemctl disable nginx"
echo "2. 停止Apache: sudo systemctl stop apache2 && sudo systemctl disable apache2" 
echo "3. 停止Docker容器: docker stop \$(docker ps -q --filter 'publish=80')"
echo "4. 强制终止进程: sudo lsof -ti :80 | xargs sudo kill -9"
echo ""
echo "💡 快速修复命令:"
echo "sudo systemctl stop nginx apache2 httpd lighttpd 2>/dev/null || true"
echo "sudo systemctl disable nginx apache2 httpd lighttpd 2>/dev/null || true"
echo "sudo lsof -ti :80 | xargs -r sudo kill -9"

# 如果有参数--fix，执行自动修复
if [ "$1" = "--fix" ]; then
    echo ""
    echo "🛠️ 执行自动修复..."
    
    # 停止Web服务器
    for service in nginx apache2 httpd lighttpd; do
        if systemctl is-active $service &>/dev/null; then
            echo "停止 $service..."
            sudo systemctl stop $service 2>/dev/null || true
            sudo systemctl disable $service 2>/dev/null || true
        fi
    done
    
    # 停止Docker容器
    if command -v docker &> /dev/null; then
        conflicting_containers=$(docker ps -q --filter 'publish=80' 2>/dev/null || true)
        if [ -n "$conflicting_containers" ]; then
            echo "停止占用80端口的Docker容器..."
            echo "$conflicting_containers" | xargs docker stop 2>/dev/null || true
        fi
    fi
    
    # 强制终止进程
    pids=$(sudo lsof -ti :80 2>/dev/null || true)
    if [ -n "$pids" ]; then
        echo "强制终止占用80端口的进程..."
        echo "$pids" | xargs sudo kill -9 2>/dev/null || true
    fi
    
    sleep 2
    
    # 验证端口释放
    if sudo lsof -i :80 > /dev/null 2>&1; then
        echo "❌ 80端口仍被占用"
        sudo lsof -i :80
        exit 1
    else
        echo "✅ 80端口已成功释放"
    fi
fi
