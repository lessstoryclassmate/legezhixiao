#!/bin/bash

# 完整的健康检查脚本
# 用于GitHub Actions和生产环境的健康检查

set -e

PROJECT_NAME="AI小说编辑器"
TIMEOUT=300  # 5分钟超时
CHECK_INTERVAL=10  # 10秒检查间隔

echo "🏥 ${PROJECT_NAME} 健康检查开始"
echo "=================================="
echo "超时设置: ${TIMEOUT}秒"
echo "检查间隔: ${CHECK_INTERVAL}秒"
echo ""

# 检查函数
check_service() {
    local service_name="$1"
    local url="$2"
    local max_retries="$3"
    
    echo "🔍 检查 ${service_name}..."
    
    local retry=0
    while [ $retry -lt $max_retries ]; do
        retry=$((retry + 1))
        echo "  尝试 ${retry}/${max_retries}: ${url}"
        
        if curl -f -s --max-time 10 "$url" > /dev/null 2>&1; then
            echo "  ✅ ${service_name} 健康检查成功"
            return 0
        else
            echo "  ❌ ${service_name} 健康检查失败"
            if [ $retry -lt $max_retries ]; then
                echo "  ⏳ 等待 ${CHECK_INTERVAL} 秒后重试..."
                sleep $CHECK_INTERVAL
            fi
        fi
    done
    
    echo "  ❌ ${service_name} 健康检查最终失败"
    return 1
}

# 检查容器状态
check_containers() {
    echo "🐳 检查Docker容器状态"
    echo "-------------------"
    
    if ! docker-compose ps > /dev/null 2>&1; then
        echo "❌ 无法获取容器状态"
        return 1
    fi
    
    local services=("mongodb" "redis" "backend" "frontend")
    local failed_services=()
    
    for service in "${services[@]}"; do
        if docker-compose ps "$service" | grep -q "Up"; then
            echo "✅ $service 容器正在运行"
        else
            echo "❌ $service 容器未运行"
            failed_services+=("$service")
        fi
    done
    
    if [ ${#failed_services[@]} -gt 0 ]; then
        echo "❌ 以下容器未正常运行: ${failed_services[*]}"
        return 1
    fi
    
    echo "✅ 所有容器都在运行"
    return 0
}

# 检查端口监听
check_ports() {
    echo "🔌 检查端口监听状态"
    echo "-------------------"
    
    local ports=("80:前端" "8000:后端API" "27017:MongoDB" "6379:Redis")
    local failed_ports=()
    
    for port_info in "${ports[@]}"; do
        local port=${port_info%:*}
        local name=${port_info#*:}
        
        if netstat -tlnp | grep ":$port " > /dev/null 2>&1; then
            echo "✅ 端口 $port ($name) 正在监听"
        else
            echo "❌ 端口 $port ($name) 未监听"
            failed_ports+=("$port")
        fi
    done
    
    if [ ${#failed_ports[@]} -gt 0 ]; then
        echo "❌ 以下端口未监听: ${failed_ports[*]}"
        return 1
    fi
    
    echo "✅ 所有端口都在监听"
    return 0
}

# 检查服务健康状态
check_services() {
    echo "🌐 检查服务健康状态"
    echo "-------------------"
    
    local max_retries=$((TIMEOUT / CHECK_INTERVAL))
    local failed_services=()
    
    # 检查后端API健康状态
    if ! check_service "后端API" "http://localhost:8000/health" $max_retries; then
        failed_services+=("后端API")
    fi
    
    # 检查前端访问
    if ! check_service "前端页面" "http://localhost:80" $max_retries; then
        failed_services+=("前端页面")
    fi
    
    # 检查API文档
    if ! check_service "API文档" "http://localhost:8000/docs" 3; then
        echo "⚠️ API文档访问失败（非关键）"
    fi
    
    if [ ${#failed_services[@]} -gt 0 ]; then
        echo "❌ 以下服务健康检查失败: ${failed_services[*]}"
        return 1
    fi
    
    echo "✅ 所有服务健康检查通过"
    return 0
}

# 获取详细的健康信息
get_health_details() {
    echo "📊 获取详细健康信息"
    echo "-------------------"
    
    echo "后端健康检查详情:"
    if curl -f -s --max-time 10 http://localhost:8000/health 2>/dev/null; then
        echo ""
    else
        echo "无法获取后端健康信息"
    fi
    
    echo "系统资源使用情况:"
    echo "内存使用:"
    free -h
    echo "磁盘使用:"
    df -h
    
    echo "Docker容器资源使用:"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"
}

# 输出容器日志
dump_logs() {
    echo "📋 输出容器日志"
    echo "----------------"
    
    local services=("backend" "frontend" "mongodb" "redis")
    
    for service in "${services[@]}"; do
        echo "=== $service 容器日志 (最近20行) ==="
        docker-compose logs --tail=20 "$service" 2>/dev/null || echo "无法获取 $service 日志"
        echo ""
    done
}

# 主健康检查流程
main() {
    local start_time=$(date +%s)
    local failed_checks=()
    
    echo "开始时间: $(date)"
    echo ""
    
    # 检查容器状态
    if ! check_containers; then
        failed_checks+=("容器状态")
    fi
    
    echo ""
    
    # 检查端口监听
    if ! check_ports; then
        failed_checks+=("端口监听")
    fi
    
    echo ""
    
    # 检查服务健康状态
    if ! check_services; then
        failed_checks+=("服务健康")
    fi
    
    echo ""
    
    # 获取详细信息
    get_health_details
    
    echo ""
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo "=================================="
    echo "🎯 健康检查完成"
    echo "用时: ${duration}秒"
    echo "结束时间: $(date)"
    
    if [ ${#failed_checks[@]} -eq 0 ]; then
        echo "✅ 所有健康检查通过！"
        echo ""
        echo "🌐 服务访问地址："
        echo "- 前端: http://localhost:80"
        echo "- 后端API: http://localhost:8000"
        echo "- API文档: http://localhost:8000/docs"
        echo "- 健康检查: http://localhost:8000/health"
        return 0
    else
        echo "❌ 以下检查失败: ${failed_checks[*]}"
        echo ""
        echo "故障排除建议："
        echo "1. 检查容器日志: docker-compose logs"
        echo "2. 重启服务: docker-compose restart"
        echo "3. 重新构建: docker-compose build --no-cache"
        echo "4. 检查环境变量: cat .env"
        echo ""
        
        # 输出日志以便调试
        dump_logs
        
        return 1
    fi
}

# 脚本参数处理
case "${1:-}" in
    --timeout)
        TIMEOUT="$2"
        shift 2
        ;;
    --interval)
        CHECK_INTERVAL="$2"
        shift 2
        ;;
    --help)
        echo "用法: $0 [选项]"
        echo "选项:"
        echo "  --timeout N    设置超时时间（秒，默认300）"
        echo "  --interval N   设置检查间隔（秒，默认10）"
        echo "  --help         显示帮助信息"
        exit 0
        ;;
esac

# 运行主函数
main "$@"
