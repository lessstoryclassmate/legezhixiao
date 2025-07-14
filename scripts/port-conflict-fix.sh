#!/bin/bash
# 端口冲突检测和修复脚本
# 专门解决80端口冲突问题

set -e

echo "🔍 开始端口冲突检测和修复..."

# 颜色输出函数
red() { echo -e "\033[31m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
blue() { echo -e "\033[34m$1\033[0m"; }

# 检测端口占用的进程
check_port_usage() {
    local port=$1
    echo "🔍 检查端口 $port 占用情况..."
    
    # 使用多种方法检测端口占用
    if command -v lsof &> /dev/null; then
        lsof_result=$(lsof -i :$port 2>/dev/null || true)
        if [ -n "$lsof_result" ]; then
            echo "📋 lsof 检测结果:"
            echo "$lsof_result"
        fi
    fi
    
    if command -v netstat &> /dev/null; then
        netstat_result=$(netstat -tlnp 2>/dev/null | grep :$port || true)
        if [ -n "$netstat_result" ]; then
            echo "📋 netstat 检测结果:"
            echo "$netstat_result"
        fi
    fi
    
    if command -v ss &> /dev/null; then
        ss_result=$(ss -tlnp | grep :$port || true)
        if [ -n "$ss_result" ]; then
            echo "📋 ss 检测结果:"
            echo "$ss_result"
        fi
    fi
    
    # 检测Docker容器占用
    if command -v docker &> /dev/null; then
        docker_result=$(docker ps --format "table {{.Names}}\t{{.Ports}}" | grep ":$port->" || true)
        if [ -n "$docker_result" ]; then
            echo "📋 Docker容器端口映射:"
            echo "$docker_result"
        fi
    fi
}

# 识别占用端口的服务
identify_service() {
    local port=$1
    echo "🔍 识别端口 $port 的服务类型..."
    
    # 常见服务检测
    if systemctl is-active nginx &>/dev/null; then
        echo "🌐 检测到 Nginx 服务运行中"
        if nginx -T 2>/dev/null | grep -q "listen.*$port"; then
            echo "⚠️ Nginx 正在监听端口 $port"
            return 0
        fi
    fi
    
    if systemctl is-active apache2 &>/dev/null; then
        echo "🌐 检测到 Apache2 服务运行中"
        if grep -r "Listen $port" /etc/apache2/ 2>/dev/null; then
            echo "⚠️ Apache2 正在监听端口 $port"
            return 0
        fi
    fi
    
    if systemctl is-active httpd &>/dev/null; then
        echo "🌐 检测到 httpd 服务运行中"
        if grep -r "Listen $port" /etc/httpd/ 2>/dev/null; then
            echo "⚠️ httpd 正在监听端口 $port"
            return 0
        fi
    fi
    
    # 检查其他可能的服务
    local pid=$(lsof -ti :$port 2>/dev/null | head -1)
    if [ -n "$pid" ]; then
        local process_name=$(ps -p $pid -o comm= 2>/dev/null || echo "未知进程")
        echo "🔍 端口 $port 被进程占用: PID=$pid, 进程名=$process_name"
        
        # 获取完整命令行
        local full_cmd=$(ps -p $pid -o args= 2>/dev/null || echo "无法获取命令行")
        echo "📋 完整命令: $full_cmd"
        
        return 0
    fi
    
    echo "✅ 端口 $port 当前未被占用"
    return 1
}

# 停止冲突的服务
stop_conflicting_services() {
    local port=$1
    echo "🛑 停止端口 $port 的冲突服务..."
    
    # 停止常见的Web服务器
    for service in nginx apache2 httpd lighttpd; do
        if systemctl is-active $service &>/dev/null; then
            echo "停止 $service 服务..."
            sudo systemctl stop $service || true
            sudo systemctl disable $service || true
            echo "✅ $service 已停止并禁用"
        fi
    done
    
    # 停止可能的Docker容器
    if command -v docker &> /dev/null; then
        conflicting_containers=$(docker ps --filter "publish=$port" --format "{{.Names}}" || true)
        if [ -n "$conflicting_containers" ]; then
            echo "停止冲突的Docker容器:"
            echo "$conflicting_containers" | while read container; do
                if [ -n "$container" ]; then
                    echo "停止容器: $container"
                    docker stop "$container" || true
                fi
            done
        fi
    fi
    
    # 强制终止占用端口的进程
    local pids=$(lsof -ti :$port 2>/dev/null || true)
    if [ -n "$pids" ]; then
        echo "强制终止占用端口 $port 的进程:"
        echo "$pids" | while read pid; do
            if [ -n "$pid" ] && [ "$pid" -gt 1 ]; then
                local process_name=$(ps -p $pid -o comm= 2>/dev/null || echo "未知")
                echo "终止进程: PID=$pid, 名称=$process_name"
                sudo kill -TERM $pid 2>/dev/null || true
                sleep 2
                # 如果进程仍然存在，强制杀死
                if kill -0 $pid 2>/dev/null; then
                    echo "强制杀死进程: $pid"
                    sudo kill -KILL $pid 2>/dev/null || true
                fi
            fi
        done
    fi
}

# 配置防火墙规则
configure_firewall() {
    local port=$1
    echo "🔥 配置防火墙规则允许端口 $port..."
    
    # UFW防火墙
    if command -v ufw &> /dev/null; then
        sudo ufw allow $port/tcp 2>/dev/null || true
        echo "✅ UFW: 已允许端口 $port/tcp"
    fi
    
    # iptables防火墙
    if command -v iptables &> /dev/null; then
        sudo iptables -I INPUT -p tcp --dport $port -j ACCEPT 2>/dev/null || true
        echo "✅ iptables: 已允许端口 $port/tcp"
    fi
    
    # firewalld防火墙
    if command -v firewall-cmd &> /dev/null; then
        sudo firewall-cmd --add-port=$port/tcp --permanent 2>/dev/null || true
        sudo firewall-cmd --reload 2>/dev/null || true
        echo "✅ firewalld: 已允许端口 $port/tcp"
    fi
}

# 检查端口是否真正释放
verify_port_free() {
    local port=$1
    echo "🧪 验证端口 $port 是否已释放..."
    
    sleep 3  # 等待进程完全停止
    
    if lsof -i :$port > /dev/null 2>&1; then
        red "❌ 端口 $port 仍被占用"
        return 1
    else
        green "✅ 端口 $port 已成功释放"
        return 0
    fi
}

# 启动我们的服务并测试
start_and_test_service() {
    local port=$1
    echo "🚀 启动我们的服务并测试端口 $port..."
    
    # 确保Docker Compose服务停止
    if [ -f docker-compose.yml ]; then
        docker-compose down || true
        echo "等待容器完全停止..."
        sleep 5
    fi
    
    # 启动服务
    echo "启动 Docker Compose 服务..."
    docker-compose up -d || {
        echo "Docker Compose 启动失败，查看日志..."
        docker-compose logs --tail=20
        return 1
    }
    
    # 等待服务启动
    echo "等待服务启动..."
    sleep 10
    
    # 测试端口连通性
    if curl -f -s --max-time 5 http://localhost:$port > /dev/null 2>&1; then
        green "✅ 端口 $port 服务启动成功"
        return 0
    else
        red "❌ 端口 $port 服务启动失败或无响应"
        return 1
    fi
}

# 生成修复报告
generate_fix_report() {
    echo ""
    echo "================== 端口冲突修复报告 =================="
    echo "修复时间: $(date)"
    echo ""
    
    echo "📋 当前端口状态:"
    for port in 80 8000 8080; do
        echo "端口 $port:"
        if lsof -i :$port > /dev/null 2>&1; then
            lsof -i :$port | head -2
        else
            echo "  未被占用"
        fi
        echo ""
    done
    
    echo "📋 Docker容器状态:"
    if command -v docker &> /dev/null; then
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" || echo "Docker不可用"
    fi
    
    echo ""
    echo "📋 Web服务器状态:"
    for service in nginx apache2 httpd; do
        if systemctl is-active $service &>/dev/null; then
            echo "  $service: 运行中"
        else
            echo "  $service: 已停止"
        fi
    done
    
    echo ""
    echo "🧪 服务连通性测试:"
    for port in 80 8000; do
        if curl -f -s --max-time 3 http://localhost:$port > /dev/null 2>&1; then
            green "✅ 端口 $port 可访问"
        else
            red "❌ 端口 $port 不可访问"
        fi
    done
}

# 主修复流程
main() {
    echo "🚀 开始端口冲突修复流程..."
    echo ""
    
    # 检查关键端口
    critical_ports=(80 8000 8080)
    
    for port in "${critical_ports[@]}"; do
        echo "================== 处理端口 $port =================="
        
        # 检查端口占用
        check_port_usage $port
        
        # 识别服务类型
        if identify_service $port; then
            # 停止冲突服务
            stop_conflicting_services $port
            
            # 验证端口释放
            if ! verify_port_free $port; then
                red "⚠️ 端口 $port 释放失败，可能需要手动处理"
            fi
        fi
        
        # 配置防火墙
        configure_firewall $port
        
        echo ""
    done
    
    # 启动我们的服务
    echo "================== 启动服务 =================="
    if start_and_test_service 80; then
        green "🎉 服务启动成功！"
    else
        red "❌ 服务启动失败，请检查日志"
    fi
    
    # 生成报告
    generate_fix_report
    
    echo ""
    echo "🎯 修复完成建议:"
    echo "1. 检查日志: docker-compose logs"
    echo "2. 查看容器状态: docker ps"
    echo "3. 测试前端: curl http://localhost:80"
    echo "4. 测试后端: curl http://localhost:8000/health"
    echo "5. 如果问题仍然存在，请运行: bash scripts/quick-deploy.sh"
}

# 处理命令行参数
if [ "$1" = "--port" ] && [ -n "$2" ]; then
    port=$2
    echo "🎯 专门处理端口 $port 的冲突..."
    check_port_usage $port
    identify_service $port
    stop_conflicting_services $port
    verify_port_free $port
    configure_firewall $port
else
    # 运行完整流程
    main "$@"
fi
