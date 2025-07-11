#!/bin/bash

# CI环境下的容器诊断脚本
echo "🔍 开始容器诊断..."

echo "=== 系统信息 ==="
echo "操作系统: $(uname -a)"
echo "Docker版本: $(docker --version)"
echo "Docker Compose版本: $(docker-compose --version)"
echo "可用内存: $(free -h | head -2)"
echo "磁盘空间: $(df -h / | tail -1)"

echo "=== 容器状态 ==="
docker-compose ps
echo ""

echo "=== 容器日志摘要 ==="
for service in mongodb redis backend frontend; do
  echo "--- $service 日志 (最后10行) ---"
  docker-compose logs --tail=10 $service 2>/dev/null || echo "$service 容器不存在或已停止"
  echo ""
done

echo "=== 网络诊断 ==="
echo "Docker网络列表:"
docker network ls

echo "应用网络详情:"
if docker network inspect app-network >/dev/null 2>&1; then
  docker network inspect app-network | jq '.[] | {Name: .Name, Driver: .Driver, Containers: .Containers}' 2>/dev/null || docker network inspect app-network | head -30
else
  echo "❌ app-network 不存在"
fi

echo "=== 端口检查 ==="
echo "主机端口占用情况:"
netstat -tlnp | grep -E "(27017|6379|8000|80)" || echo "无相关端口占用"

echo "=== 容器内部连接测试 ==="
if docker-compose exec -T backend ping -c 1 mongodb >/dev/null 2>&1; then
  echo "✅ backend -> mongodb 网络连通"
else
  echo "❌ backend -> mongodb 网络不通"
fi

if docker-compose exec -T backend ping -c 1 redis >/dev/null 2>&1; then
  echo "✅ backend -> redis 网络连通"
else
  echo "❌ backend -> redis 网络不通"
fi

echo "=== 服务健康状态 ==="
# MongoDB
if docker-compose exec -T mongodb mongosh --eval "db.adminCommand('ping')" >/dev/null 2>&1; then
  echo "✅ MongoDB 服务正常"
else
  echo "❌ MongoDB 服务异常"
fi

# Redis
if docker-compose exec -T redis redis-cli ping >/dev/null 2>&1; then
  echo "✅ Redis 服务正常"
else
  echo "❌ Redis 服务异常"
fi

# Backend
if curl -f -s http://localhost:8000/health >/dev/null 2>&1; then
  echo "✅ Backend API 正常"
else
  echo "❌ Backend API 异常"
fi

echo "🏁 容器诊断完成"
