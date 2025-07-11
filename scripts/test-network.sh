#!/bin/bash
# Docker 网络配置测试脚本

echo "🔍 Docker 网络配置测试"
echo "=========================="

# 基本信息
PROJECT_DIR=$(basename $PWD)
NETWORK_NAME="${PROJECT_DIR,,}_app-network"  # 转换为小写

echo "项目目录: $PROJECT_DIR"
echo "期望网络名: $NETWORK_NAME"
echo ""

# 1. 检查 docker-compose 配置
echo "=== 1. Docker Compose 配置验证 ==="
if docker-compose config >/dev/null 2>&1; then
  echo "✅ docker-compose.yml 配置有效"
  
  # 检查网络配置
  if docker-compose config | grep -q "app-network"; then
    echo "✅ app-network 配置存在"
    echo "网络详情:"
    docker-compose config | grep -A 5 "networks:" | tail -6
  else
    echo "❌ app-network 配置缺失"
    exit 1
  fi
else
  echo "❌ docker-compose.yml 配置无效"
  exit 1
fi

echo ""

# 2. 测试网络创建
echo "=== 2. 网络创建测试 ==="
echo "启动 MongoDB 和 Redis 服务..."
docker-compose up -d --no-deps mongodb redis

sleep 10

echo "检查网络是否创建..."
if docker network inspect "$NETWORK_NAME" >/dev/null 2>&1; then
  echo "✅ 网络创建成功: $NETWORK_NAME"
  
  # 显示网络信息
  echo ""
  echo "网络详细信息:"
  docker network inspect "$NETWORK_NAME" | jq '.[0] | {
    Name: .Name,
    Driver: .Driver,
    Scope: .Scope,
    Subnet: .IPAM.Config[0].Subnet,
    Gateway: .IPAM.Config[0].Gateway,
    ContainerCount: (.Containers | length)
  }' 2>/dev/null || docker network inspect "$NETWORK_NAME" | head -15
else
  echo "❌ 网络创建失败"
  echo "可用网络列表:"
  docker network ls
  exit 1
fi

echo ""

# 3. 容器网络连接测试
echo "=== 3. 容器网络连接测试 ==="
CONTAINERS=$(docker network inspect "$NETWORK_NAME" | jq -r '.[0].Containers | to_entries[] | .value.Name' 2>/dev/null)

if [ -n "$CONTAINERS" ]; then
  echo "已连接的容器:"
  echo "$CONTAINERS" | sed 's/^/  ✅ /'
  
  # 测试容器间连通性
  echo ""
  echo "=== 4. 服务发现测试 ==="
  
  # 从 MongoDB 容器测试 Redis 连接
  echo -n "MongoDB -> Redis 连通性: "
  if docker-compose exec -T mongodb timeout 5 bash -c "echo >/dev/tcp/redis/6379" 2>/dev/null; then
    echo "✅ 可达"
  else
    echo "❌ 不可达"
  fi
  
  # 从 Redis 容器测试 MongoDB 连接
  echo -n "Redis -> MongoDB 连通性: "
  if docker-compose exec -T redis timeout 5 bash -c "echo >/dev/tcp/mongodb/27017" 2>/dev/null; then
    echo "✅ 可达"
  else
    echo "❌ 不可达"
  fi
  
  # DNS 解析测试
  echo ""
  echo "=== 5. DNS 解析测试 ==="
  echo -n "MongoDB 容器解析 'redis': "
  REDIS_IP=$(docker-compose exec -T mongodb nslookup redis 2>/dev/null | grep -A1 "Name:" | grep "Address:" | awk '{print $2}' | head -1)
  if [ -n "$REDIS_IP" ]; then
    echo "✅ $REDIS_IP"
  else
    echo "❌ 解析失败"
  fi
  
  echo -n "Redis 容器解析 'mongodb': "
  MONGODB_IP=$(docker-compose exec -T redis nslookup mongodb 2>/dev/null | grep -A1 "Name:" | grep "Address:" | awk '{print $2}' | head -1)
  if [ -n "$MONGODB_IP" ]; then
    echo "✅ $MONGODB_IP"
  else
    echo "❌ 解析失败"
  fi
else
  echo "⚠️ 没有容器连接到网络"
fi

echo ""

# 6. 清理测试环境
echo "=== 6. 清理测试环境 ==="
echo "停止测试容器..."
docker-compose down

echo ""
echo "🎉 网络配置测试完成！"
echo ""
echo "总结:"
echo "- 自定义网络: $NETWORK_NAME"
echo "- 网络类型: bridge"
echo "- 服务发现: 通过服务名"
echo "- 通信方式: 容器间直接通信"
