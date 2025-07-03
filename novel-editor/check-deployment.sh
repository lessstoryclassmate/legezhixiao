#!/bin/bash

# GitHub Actions部署状态检查脚本
# 用于验证自动部署是否成功

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 服务器配置
SERVER_HOST=${SERVER_HOST:-"localhost"}
BACKEND_PORT=${BACKEND_PORT:-"8000"}
FRONTEND_PORT=${FRONTEND_PORT:-"80"}

# 检查参数
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    echo "用法: $0 [服务器IP]"
    echo ""
    echo "示例:"
    echo "  $0                    # 检查本地服务"
    echo "  $0 192.168.1.100     # 检查指定服务器"
    echo ""
    exit 0
fi

if [[ -n "$1" ]]; then
    SERVER_HOST="$1"
fi

log_info "开始检查部署状态..."
log_info "目标服务器: $SERVER_HOST"

# 检查后端服务
check_backend() {
    log_info "检查后端服务..."
    
    BACKEND_URL="http://$SERVER_HOST:$BACKEND_PORT"
    
    # 检查健康状态
    if curl -f -s "$BACKEND_URL/health" > /dev/null; then
        log_success "后端健康检查通过"
        
        # 获取详细健康信息
        health_response=$(curl -s "$BACKEND_URL/health")
        echo "  健康状态: $health_response"
    else
        log_error "后端健康检查失败"
        return 1
    fi
    
    # 检查API文档
    if curl -f -s "$BACKEND_URL/docs" > /dev/null; then
        log_success "API文档可访问"
    else
        log_warning "API文档访问失败"
    fi
    
    # 检查AI模型接口
    if curl -f -s "$BACKEND_URL/api/v1/ai/models" > /dev/null; then
        log_success "AI模型接口可用"
        
        # 获取模型列表
        models_response=$(curl -s "$BACKEND_URL/api/v1/ai/models")
        echo "  可用模型: $models_response"
    else
        log_warning "AI模型接口访问失败"
    fi
}

# 检查前端服务
check_frontend() {
    log_info "检查前端服务..."
    
    FRONTEND_URL="http://$SERVER_HOST:$FRONTEND_PORT"
    
    # 检查前端页面
    response_code=$(curl -s -o /dev/null -w "%{http_code}" "$FRONTEND_URL")
    
    if [[ "$response_code" == "200" ]]; then
        log_success "前端页面可访问 (HTTP $response_code)"
    else
        log_error "前端页面访问失败 (HTTP $response_code)"
        return 1
    fi
    
    # 检查前端静态资源
    if curl -f -s "$FRONTEND_URL/assets/" > /dev/null 2>&1; then
        log_success "前端静态资源可访问"
    else
        log_warning "前端静态资源访问可能有问题"
    fi
}

# 检查容器状态
check_containers() {
    log_info "检查容器状态..."
    
    if command -v docker > /dev/null 2>&1; then
        # 检查容器运行状态
        containers=$(docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep novel-editor || true)
        
        if [[ -n "$containers" ]]; then
            log_success "发现运行中的容器:"
            echo "$containers"
        else
            log_warning "未发现运行中的novel-editor容器"
        fi
        
        # 检查镜像
        images=$(docker images | grep novel-editor || true)
        if [[ -n "$images" ]]; then
            log_success "发现镜像:"
            echo "$images"
        fi
    else
        log_warning "Docker命令不可用，跳过容器检查"
    fi
}

# 性能测试
performance_test() {
    log_info "执行基础性能测试..."
    
    # 测试后端响应时间
    backend_time=$(curl -o /dev/null -s -w "%{time_total}" "http://$SERVER_HOST:$BACKEND_PORT/health" || echo "失败")
    if [[ "$backend_time" != "失败" ]]; then
        log_success "后端响应时间: ${backend_time}秒"
    else
        log_error "后端响应时间测试失败"
    fi
    
    # 测试前端响应时间
    frontend_time=$(curl -o /dev/null -s -w "%{time_total}" "http://$SERVER_HOST:$FRONTEND_PORT" || echo "失败")
    if [[ "$frontend_time" != "失败" ]]; then
        log_success "前端响应时间: ${frontend_time}秒"
    else
        log_error "前端响应时间测试失败"
    fi
}

# AI功能测试
ai_test() {
    log_info "测试AI功能..."
    
    # 测试AI内容生成接口
    test_payload='{"prompt": "写一个简短的故事开头", "max_tokens": 50}'
    
    response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "$test_payload" \
        "http://$SERVER_HOST:$BACKEND_PORT/api/v1/ai/generate" || echo "失败")
    
    if [[ "$response" != "失败" ]] && [[ $(echo "$response" | jq -r '.status' 2>/dev/null) == "success" ]]; then
        log_success "AI内容生成功能正常"
        echo "  生成内容: $(echo "$response" | jq -r '.generated_text' 2>/dev/null | head -c 100)..."
    else
        log_warning "AI内容生成功能测试失败或API密钥未配置"
        echo "  响应: $response"
    fi
}

# 主检查流程
main() {
    echo ""
    log_info "======================================"
    log_info "   AI小说编辑器部署状态检查"
    log_info "======================================"
    echo ""
    
    # 执行检查
    check_backend
    echo ""
    
    check_frontend
    echo ""
    
    check_containers
    echo ""
    
    performance_test
    echo ""
    
    ai_test
    echo ""
    
    # 总结
    log_info "======================================"
    log_success "部署状态检查完成！"
    log_info "======================================"
    echo ""
    echo "📊 访问地址:"
    echo "  前端页面: http://$SERVER_HOST:$FRONTEND_PORT"
    echo "  API文档:  http://$SERVER_HOST:$BACKEND_PORT/docs"
    echo "  健康检查: http://$SERVER_HOST:$BACKEND_PORT/health"
    echo ""
    echo "🔧 如需管理服务:"
    echo "  查看状态: ./deploy-prod.sh status"
    echo "  查看日志: ./deploy-prod.sh logs"
    echo "  重启服务: ./deploy-prod.sh restart"
    echo ""
}

# 运行主函数
main
