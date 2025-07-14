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
  if docker-compose ps $service 2>/dev/null | grep -q "Up"; then
    docker-compose logs --tail=10 $service 2>/dev/null || echo "$service 容器日志获取失败"
  else
    echo "$service 容器不存在或已停止（生产环境可能使用云服务）"
  fi
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
  if docker-compose ps $service 2>/dev/null | grep -q "Up"; then
    # 优先使用 ip 命令，回退到其他命令
    docker-compose exec -T $service ip addr show 2>/dev/null || \
    docker-compose exec -T $service ifconfig 2>/dev/null || \
    docker-compose exec -T $service cat /proc/net/dev 2>/dev/null || \
    echo "$service 容器网络接口信息获取失败"
  else
    echo "$service 容器未运行或不存在（可能使用云服务）"
  fi
done

echo "=== 端口检查 ==="
echo "主机端口占用情况:"
netstat -tlnp | grep -E "(27017|6379|8000|80)" || echo "无相关端口占用"

echo "=== 容器内部连接测试 ==="
# 检查 MongoDB 连接（如果容器存在）
if docker-compose ps mongodb 2>/dev/null | grep -q "Up"; then
  if docker-compose exec -T backend ping -c 1 mongodb >/dev/null 2>&1; then
    echo "✅ backend -> mongodb 网络连通（本地容器）"
  else
    echo "❌ backend -> mongodb 网络不通（本地容器）"
  fi
else
  echo "ℹ️  MongoDB 容器不存在，跳过本地连接测试（生产环境使用独立MongoDB服务器）"
fi

# 检查 Redis 连接（如果容器存在）
if docker-compose ps redis 2>/dev/null | grep -q "Up"; then
  if docker-compose exec -T backend ping -c 1 redis >/dev/null 2>&1; then
    echo "✅ backend -> redis 网络连通（本地容器）"
  else
    echo "❌ backend -> redis 网络不通（本地容器）"
  fi
else
  echo "ℹ️  Redis 容器不存在，跳过本地连接测试（生产环境使用独立Redis服务器）"
fi

echo "=== Docker 网络诊断 ==="
echo "当前网络列表:"
docker network ls

echo ""
echo "=== app-network 网络详情 ==="
PROJECT_PREFIX=$(basename $PWD | tr '[:upper:]' '[:lower:]')
NETWORK_NAME="${PROJECT_PREFIX}_app-network"

if docker network inspect "$NETWORK_NAME" >/dev/null 2>&1; then
  echo "✅ 找到网络: $NETWORK_NAME"
  
  # 显示网络基本信息
  echo "网络驱动: $(docker network inspect "$NETWORK_NAME" | jq -r '.[0].Driver')"
  echo "网络子网: $(docker network inspect "$NETWORK_NAME" | jq -r '.[0].IPAM.Config[0].Subnet // "未配置"')"
  
  # 显示连接的容器
  echo ""
  echo "连接的容器:"
  CONTAINERS=$(docker network inspect "$NETWORK_NAME" | jq -r '.[0].Containers | to_entries[] | "\(.value.Name) - \(.value.IPv4Address)"' 2>/dev/null)
  if [ -n "$CONTAINERS" ]; then
    echo "$CONTAINERS"
  else
    echo "暂无容器连接到此网络"
  fi
  
  echo ""
  echo "=== 服务间网络连通性测试 ==="
  
  # 测试从 backend 容器访问其他服务
  if docker-compose ps backend 2>/dev/null | grep -q "Up"; then
    echo "从 backend 容器测试网络连通性:"
    
    # 测试 MongoDB 连接
    echo -n "MongoDB (mongodb:27017): "
    if docker-compose exec -T backend timeout 5 bash -c "echo >/dev/tcp/mongodb/27017" 2>/dev/null; then
      echo "✅ 可达"
    else
      echo "❌ 不可达"
    fi
    
    # 测试 Redis 连接
    echo -n "Redis (redis:6379): "
    if docker-compose exec -T backend timeout 5 bash -c "echo >/dev/tcp/redis/6379" 2>/dev/null; then
      echo "✅ 可达"
    else
      echo "❌ 不可达"
    fi
    
    # 显示 backend 容器的网络配置
    echo ""
    echo "Backend 容器网络接口:"
    docker-compose exec -T backend ip addr show 2>/dev/null || docker-compose exec -T backend ifconfig 2>/dev/null || echo "无法获取网络接口信息"
    
    echo ""
    echo "Backend 容器路由表:"
    docker-compose exec -T backend ip route 2>/dev/null || docker-compose exec -T backend route -n 2>/dev/null || echo "无法获取路由信息"
    
    echo ""
    echo "Backend 容器 DNS 解析测试:"
    echo -n "解析 mongodb: "
    docker-compose exec -T backend nslookup mongodb 2>/dev/null | grep -A1 "Name:" | tail -1 || echo "DNS 解析失败"
    echo -n "解析 redis: "
    docker-compose exec -T backend nslookup redis 2>/dev/null | grep -A1 "Name:" | tail -1 || echo "DNS 解析失败"
  else
    echo "⚠️ Backend 容器未运行，跳过网络连通性测试"
  fi
else
  echo "❌ 未找到网络: $NETWORK_NAME"
  echo "可用的网络:"
  docker network ls | grep -v "bridge\|host\|none"
fi

echo "Backend DNS解析:"
# 只有在 MongoDB 容器存在时才进行 DNS 解析测试
if docker-compose ps mongodb 2>/dev/null | grep -q "Up"; then
  docker-compose exec -T backend nslookup mongodb 2>/dev/null || docker-compose exec -T backend host mongodb 2>/dev/null || echo "本地 MongoDB DNS解析检查失败"
else
  echo "ℹ️  MongoDB 容器不存在，跳过本地DNS解析测试"
fi

echo "=== 服务健康状态 ==="
# MongoDB - 只检查本地容器（如果存在）
if docker-compose ps mongodb 2>/dev/null | grep -q "Up"; then
  if docker-compose exec -T mongodb mongosh --eval "db.adminCommand('ping')" >/dev/null 2>&1; then
    echo "✅ MongoDB 本地容器服务正常"
  else
    echo "❌ MongoDB 本地容器服务异常"
  fi
else
  echo "ℹ️  MongoDB 本地容器不存在（使用云服务）"
fi

# Redis - 只检查本地容器（如果存在）
if docker-compose ps redis 2>/dev/null | grep -q "Up"; then
  if docker-compose exec -T redis redis-cli ping >/dev/null 2>&1; then
    echo "✅ Redis 本地容器服务正常"
  else
    echo "❌ Redis 本地容器服务异常"
  fi
else
  echo "ℹ️  Redis 本地容器不存在（使用独立Redis服务器）"
fi

# Backend
if curl -f -s http://localhost:8000/health >/dev/null 2>&1; then
  echo "✅ Backend API 正常"
else
  echo "❌ Backend API 异常"
fi

echo "🏁 容器诊断完成"

echo ""
echo "=== 排错建议 ==="
echo "1. 如果容器未启动，检查 docker-compose.yml 文件"
echo "2. 如果网络连接失败，检查容器间网络配置"
echo "3. 如果在 CI 环境中运行，确保 Docker 服务已启动"
echo "4. 如果是生产环境，检查独立数据库服务器（MongoDB: 172.16.32.2、Redis: 172.16.32.2、MySQL: 172.16.16.x）连接配置"
echo "5. 检查环境变量是否正确配置（本地容器 vs 云服务）"
echo "6. 独立服务器连接问题：检查网络连通性、防火墙规则、服务状态"
echo "7. 使用 'docker-compose logs [service]' 查看详细日志"
