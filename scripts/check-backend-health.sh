#!/bin/bash

# 后端API健康检查脚本
echo "🩺 后端API健康检查开始..."
echo "==============================="

# 配置
BACKEND_HOST=${1:-localhost}
BACKEND_PORT=${2:-8000}
MAX_RETRIES=${3:-15}
RETRY_INTERVAL=${4:-10}

echo "检查配置:"
echo "  主机: $BACKEND_HOST"
echo "  端口: $BACKEND_PORT"
echo "  最大重试: $MAX_RETRIES 次"
echo "  重试间隔: $RETRY_INTERVAL 秒"

# 函数：检查端口是否开放
check_port() {
    local host=$1
    local port=$2
    timeout 5 bash -c "</dev/tcp/$host/$port" 2>/dev/null
}

# 函数：检查HTTP健康端点
check_health_endpoint() {
    local url=$1
    curl -f -s --max-time 10 "$url" >/dev/null 2>&1
}

# 函数：获取详细健康信息
get_health_details() {
    local url=$1
    echo "=== 健康端点详细信息 ==="
    curl -s --max-time 10 "$url" | jq . 2>/dev/null || curl -s --max-time 10 "$url"
}

echo ""
echo "🔍 开始健康检查循环..."

for i in $(seq 1 $MAX_RETRIES); do
    echo ""
    echo "=== 第 $i/$MAX_RETRIES 次检查 ==="
    
    # 1. 检查端口连通性
    if check_port "$BACKEND_HOST" "$BACKEND_PORT"; then
        echo "✅ 端口 $BACKEND_PORT 可访问"
        
        # 2. 检查HTTP健康端点
        HEALTH_URL="http://$BACKEND_HOST:$BACKEND_PORT/health"
        if check_health_endpoint "$HEALTH_URL"; then
            echo "✅ 健康端点响应正常"
            
            # 3. 获取详细健康信息
            get_health_details "$HEALTH_URL"
            
            # 4. 测试其他关键端点
            echo ""
            echo "=== 测试其他关键端点 ==="
            
            # API根路径
            if curl -f -s --max-time 5 "http://$BACKEND_HOST:$BACKEND_PORT/" >/dev/null 2>&1; then
                echo "✅ API根路径可访问"
            else
                echo "⚠️ API根路径访问失败"
            fi
            
            # API文档
            if curl -f -s --max-time 5 "http://$BACKEND_HOST:$BACKEND_PORT/docs" >/dev/null 2>&1; then
                echo "✅ API文档可访问"
            else
                echo "⚠️ API文档访问失败"
            fi
            
            # OpenAPI规范
            if curl -f -s --max-time 5 "http://$BACKEND_HOST:$BACKEND_PORT/openapi.json" >/dev/null 2>&1; then
                echo "✅ OpenAPI规范可访问"
            else
                echo "⚠️ OpenAPI规范访问失败"
            fi
            
            echo ""
            echo "🎉 后端API健康检查通过！"
            echo "✅ 服务已就绪，可以正常使用"
            echo "🌐 API地址: http://$BACKEND_HOST:$BACKEND_PORT"
            echo "📚 文档地址: http://$BACKEND_HOST:$BACKEND_PORT/docs"
            exit 0
            
        else
            echo "❌ 健康端点无响应"
            
            # 尝试获取错误详情
            echo "=== 错误详情 ==="
            HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$HEALTH_URL" 2>/dev/null || echo "000")
            echo "HTTP状态码: $HTTP_CODE"
            
            if [ "$HTTP_CODE" != "000" ]; then
                echo "响应内容:"
                curl -s --max-time 5 "$HEALTH_URL" 2>/dev/null || echo "无法获取响应内容"
            fi
        fi
        
    else
        echo "❌ 端口 $BACKEND_PORT 不可访问"
        
        # 端口诊断
        echo "=== 端口诊断 ==="
        if command -v netstat >/dev/null 2>&1; then
            echo "主机监听端口:"
            netstat -tlnp | grep ":$BACKEND_PORT " || echo "端口 $BACKEND_PORT 未在监听"
        fi
        
        if command -v ss >/dev/null 2>&1; then
            echo "套接字状态:"
            ss -tlnp | grep ":$BACKEND_PORT " || echo "端口 $BACKEND_PORT 未在监听"
        fi
    fi
    
    if [ $i -lt $MAX_RETRIES ]; then
        echo "⏳ 等待 $RETRY_INTERVAL 秒后重试..."
        sleep $RETRY_INTERVAL
    fi
done

echo ""
echo "❌ 后端API健康检查失败"
echo "经过 $MAX_RETRIES 次尝试，服务仍然不可用"
echo ""
echo "🔍 故障排除建议:"
echo "1. 检查后端容器是否正在运行: docker-compose ps backend"
echo "2. 查看后端容器日志: docker-compose logs backend"
echo "3. 检查端口映射: docker-compose port backend 8000"
echo "4. 检查网络连接: docker network ls && docker network inspect <network_name>"
echo "5. 验证环境变量: docker-compose exec backend env | grep -E '(MONGODB|REDIS|DATABASE)'"
echo ""

exit 1
