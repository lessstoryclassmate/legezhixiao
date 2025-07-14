#!/bin/bash

# 端口监听检查脚本
# 用于检查和诊断端口8000的监听状态

set -e

echo "🔍 AI小说编辑器端口监听检查工具"
echo "=================================="

# 检查是否在项目目录
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ 错误：请在项目根目录运行此脚本"
    exit 1
fi

# 检查Docker是否运行
if ! docker info > /dev/null 2>&1; then
    echo "❌ 错误：Docker 未运行"
    exit 1
fi

# 检查docker-compose是否可用
if ! command -v docker-compose &> /dev/null; then
    echo "❌ 错误：docker-compose 未安装"
    exit 1
fi

echo "📋 1. 检查Docker容器状态"
echo "------------------------"
docker-compose ps

echo ""
echo "📋 2. 检查端口监听状态"
echo "----------------------"
echo "检查端口8000（后端API）:"
if netstat -tlnp | grep :8000; then
    echo "✅ 端口8000正在监听"
else
    echo "❌ 端口8000未监听"
fi

echo ""
echo "检查端口80（前端）:"
if netstat -tlnp | grep :80; then
    echo "✅ 端口80正在监听"
else
    echo "❌ 端口80未监听"
fi

echo ""
echo "检查端口27017（MongoDB）:"
if netstat -tlnp | grep :27017; then
    echo "✅ 端口27017正在监听"
else
    echo "❌ 端口27017未监听"
fi

echo ""
echo "检查端口6379（Redis）:"
if netstat -tlnp | grep :6379; then
    echo "✅ 端口6379正在监听"
else
    echo "❌ 端口6379未监听"
fi

echo ""
echo "📋 3. 检查Docker端口映射"
echo "------------------------"
services=("backend" "frontend" "mongodb" "redis")
for service in "${services[@]}"; do
    echo "检查 $service 端口映射:"
    container_id=$(docker-compose ps -q "$service")
    if [ -n "$container_id" ]; then
        docker port "$container_id" 2>/dev/null || echo "无端口映射"
    else
        echo "容器未运行"
    fi
done

echo ""
echo "📋 4. 检查后端容器详细状态"
echo "------------------------"
backend_container=$(docker-compose ps -q backend)
if [ -n "$backend_container" ]; then
    echo "后端容器ID: $backend_container"
    
    echo "容器状态:"
    docker inspect "$backend_container" --format='{{.State.Status}}' 2>/dev/null || echo "无法获取状态"
    
    echo "容器健康状态:"
    docker inspect "$backend_container" --format='{{.State.Health.Status}}' 2>/dev/null || echo "无健康检查"
    
    echo "容器内部进程:"
    docker exec "$backend_container" ps aux 2>/dev/null || echo "无法检查进程"
    
    echo "容器内部网络监听:"
    docker exec "$backend_container" netstat -tlnp 2>/dev/null || echo "无法检查网络"
    
    echo "最新日志 (最近20行):"
    docker logs "$backend_container" --tail=20 2>/dev/null || echo "无法获取日志"
else
    echo "❌ 后端容器未运行"
fi

echo ""
echo "📋 5. 尝试连接测试"
echo "-------------------"
echo "测试后端健康检查端点:"
if curl -f -s --max-time 5 http://localhost:8000/health > /dev/null; then
    echo "✅ 后端健康检查成功"
    echo "健康检查响应:"
    curl -s http://localhost:8000/health | jq '.' 2>/dev/null || curl -s http://localhost:8000/health
else
    echo "❌ 后端健康检查失败"
fi

echo ""
echo "测试前端访问:"
if curl -f -s --max-time 5 http://localhost:80 > /dev/null; then
    echo "✅ 前端访问成功"
else
    echo "❌ 前端访问失败"
fi

echo ""
echo "📋 6. 环境变量检查"
echo "-------------------"
if [ -f ".env" ]; then
    echo "✅ .env 文件存在"
    echo "关键环境变量:"
    grep -E "^(MONGO_PASSWORD|REDIS_PASSWORD|SILICONFLOW_API_KEY)" .env 2>/dev/null || echo "未找到关键环境变量"
else
    echo "❌ .env 文件不存在"
fi

echo ""
echo "📋 7. 故障排除建议"
echo "-------------------"
if ! netstat -tlnp | grep :8000 > /dev/null; then
    echo "🔧 端口8000未监听，建议的排除步骤:"
    echo "1. 检查后端容器是否正在运行: docker-compose ps backend"
    echo "2. 查看后端容器日志: docker-compose logs backend"
    echo "3. 重启后端容器: docker-compose restart backend"
    echo "4. 重新构建后端容器: docker-compose build --no-cache backend"
    echo "5. 检查环境变量配置: cat .env"
    echo "6. 检查数据库连接: 确保MongoDB和Redis正常运行"
fi

echo ""
echo "📋 8. 完整的日志信息"
echo "-------------------"
echo "输出所有容器的日志 (最近10行):"
docker-compose logs --tail=10

echo ""
echo "🎯 检查完成！"
echo "如果问题仍然存在，请："
echo "1. 运行 'docker-compose down && docker-compose up -d' 重启所有服务"
echo "2. 检查服务器防火墙设置"
echo "3. 验证所有依赖服务是否正常运行"
