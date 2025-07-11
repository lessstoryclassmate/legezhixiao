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
  echo "✅ app-network 网络存在"
  echo "网络配置:"
  docker network inspect app-network | jq '.[] | {Name: .Name, Driver: .Driver, Subnet: .IPAM.Config[0].Subnet, Gateway: .IPAM.Config[0].Gateway, Containers: (.Containers | keys)}' 2>/dev/null || docker network inspect app-network | head -30
  
  echo "连接到网络的容器:"
  docker network inspect app-network | jq '.[] | .Containers | to_entries[] | {Name: .value.Name, IPv4Address: .value.IPv4Address}' 2>/dev/null || echo "无法解析容器信息"
else
  echo "❌ app-network 不存在"
  echo "检查 Docker Compose 配置:"
  docker-compose config | grep -A 5 networks: || echo "无法获取网络配置"
fi

echo "=== Docker Compose 服务状态 ==="
docker-compose ps --format "table"

echo "=== 容器网络接口 ==="
for service in mongodb redis backend; do
  echo "--- $service 网络接口 ---"
  if docker-compose ps $service | grep -q "Up"; then
    # 优先使用 ip 命令，回退到其他命令
    docker-compose exec -T $service ip addr show 2>/dev/null || \
    docker-compose exec -T $service ifconfig 2>/dev/null || \
    docker-compose exec -T $service cat /proc/net/dev 2>/dev/null || \
    echo "$service 容器网络接口信息获取失败"
  else
    echo "$service 容器未运行"
  fi
done

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

echo "=== 容器网络信息 ==="
echo "Backend 容器网络信息:"
docker-compose exec -T backend ip addr show 2>/dev/null || docker-compose exec -T backend ifconfig 2>/dev/null || echo "无法获取网络接口信息"

echo "Backend 路由表:"
docker-compose exec -T backend ip route 2>/dev/null || docker-compose exec -T backend route -n 2>/dev/null || echo "无法获取路由信息"

echo "Backend DNS解析:"
docker-compose exec -T backend nslookup mongodb 2>/dev/null || docker-compose exec -T backend host mongodb 2>/dev/null || echo "DNS解析检查失败"

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
