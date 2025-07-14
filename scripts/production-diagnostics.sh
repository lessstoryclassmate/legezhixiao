#!/bin/bash
# 生产环境诊断脚本
# 用于测试独立MongoDB、Redis、MySQL服务器连接

echo "🚀 生产环境数据库服务诊断开始..."
echo "当前时间: $(date)"
echo ""

# 检查环境变量
echo "=== 环境变量检查 ==="
echo "NODE_ENV: ${NODE_ENV:-未设置}"
echo "部署模式: $([ -f 'docker-compose.production.yml' ] && echo '生产环境(外部数据库)' || echo '开发环境(容器数据库)')"

# 检查数据库连接配置
echo ""
echo "=== 数据库连接配置 ==="
echo "MONGODB_HOST: ${MONGODB_HOST:-❌ 未设置}"
echo "REDIS_HOST: ${REDIS_HOST:-❌ 未设置}"
echo "DATABASE_SYSTEMHOST: ${DATABASE_SYSTEMHOST:-❌ 未设置}"
echo "DATABASE_NOVELHOST: ${DATABASE_NOVELHOST:-❌ 未设置}"

# Docker 网络环境检查
echo ""
echo "=== Docker 网络环境检查 ==="
if docker network ls >/dev/null 2>&1; then
  echo "Docker 环境可用"
  
  # 使用智能网络检测脚本
  if [ -f "scripts/detect-network.sh" ]; then
    echo "🔍 执行智能网络检测..."
    chmod +x scripts/detect-network.sh
    
    if bash scripts/detect-network.sh; then
      echo "✅ 智能网络检测成功"
      
      # 加载检测结果
      if [ -f "/tmp/detected_network.env" ]; then
        source /tmp/detected_network.env
        echo "检测到的网络名: $DETECTED_NETWORK_NAME"
        
        # 显示网络详情
        if docker network inspect "$DETECTED_NETWORK_NAME" >/dev/null 2>&1; then
          echo "✅ 网络验证成功"
          
          # 显示网络中的容器服务
          CONTAINERS=$(docker network inspect "$DETECTED_NETWORK_NAME" | jq -r '.[0].Containers | to_entries[] | .value.Name' 2>/dev/null)
          if [ -n "$CONTAINERS" ]; then
            echo "网络中的容器服务:"
            echo "$CONTAINERS" | sed 's/^/  - /'
            echo "✅ 容器服务使用 Docker 网络进行通信"
          fi
        else
          echo "❌ 网络验证失败"
        fi
      else
        echo "❌ 网络检测结果文件不存在"
      fi
    else
      echo "❌ 智能网络检测失败，使用传统方法..."
      
      # 传统检测方法（后备方案）
      PROJECT_PREFIX=$(basename $PWD 2>/dev/null | tr '[:upper:]' '[:lower:]')
      NETWORK_NAME="${PROJECT_PREFIX}_app-network"
      
      if docker network inspect "$NETWORK_NAME" >/dev/null 2>&1; then
        echo "✅ 找到 Docker 网络（传统方法）: $NETWORK_NAME"
      else
        echo "⚠️  未找到 Docker 网络: $NETWORK_NAME"
      fi
    fi
  else
    echo "❌ 智能网络检测脚本不存在，使用传统方法..."
    
    # 传统检测方法
    PROJECT_PREFIX=$(basename $PWD 2>/dev/null | tr '[:upper:]' '[:lower:]')
    NETWORK_NAME="${PROJECT_PREFIX}_app-network"
    
    if docker network inspect "$NETWORK_NAME" >/dev/null 2>&1; then
      echo "✅ 找到 Docker 网络（传统方法）: $NETWORK_NAME"
    else
      echo "⚠️  未找到 Docker 网络: $NETWORK_NAME"
    fi
  fi
else
  echo "⚠️  非 Docker 环境或 Docker 不可用"
fi

# 显示数据库配置信息
echo "=== 数据库服务配置 ==="
echo "📊 MongoDB: ${MONGODB_HOST:-未配置}:${MONGODB_PORT:-27017}/${MONGODB_DATABASE:-ai_novel_db}"
echo "🗄️  Redis: ${REDIS_HOST:-未配置}:${REDIS_PORT:-6379}"
echo "🐬 MySQL系统库: ${DATABASE_SYSTEMHOST:-未配置}:${DATABASE_PORT:-3306}/${DATABASE_SYSTEM:-novel_data}"
echo "🐬 MySQL用户库: ${DATABASE_NOVELHOST:-未配置}:${DATABASE_PORT:-3306}/${DATABASE_NOVELDATA:-novel_user_data}"
echo ""

# 网络连通性测试
echo "=== 网络连通性测试 ==="

# 测试 MongoDB 连接
if [ -n "$MONGODB_HOST" ]; then
  echo "测试 MongoDB ($MONGODB_HOST:${MONGODB_PORT:-27017}) 连接..."
  
  # 检查端口连接
  if timeout 10 bash -c "</dev/tcp/$MONGODB_HOST/${MONGODB_PORT:-27017}" 2>/dev/null; then
    echo "✅ MongoDB 端口 ${MONGODB_PORT:-27017} 可达"
    
    # 尝试MongoDB连接测试（如果mongosh可用）
    if command -v mongosh >/dev/null 2>&1; then
      if mongosh --host $MONGODB_HOST:${MONGODB_PORT:-27017} --eval "db.adminCommand('ping')" >/dev/null 2>&1; then
        echo "✅ MongoDB 服务响应正常"
      else
        echo "⚠️  MongoDB 端口可达但服务响应异常"
      fi
    else
      echo "ℹ️  mongosh 不可用，无法测试MongoDB服务响应"
    fi
  else
    echo "❌ MongoDB 端口 ${MONGODB_PORT:-27017} 不可达"
    echo "建议检查："
    echo "- MongoDB 容器状态: docker compose ps"
    echo "- 防火墙设置: ssh $MONGODB_HOST 'sudo ufw status | grep 27017'"
    echo "- 绑定地址配置: ssh $MONGODB_HOST 'grep bindIp /etc/mongod.conf'"
  fi
else
  echo "⚠️  未找到 MongoDB 连接信息"
fi

echo ""

# 测试 Redis 连接
if [ -n "$REDIS_HOST" ]; then
  echo "测试 Redis ($REDIS_HOST:${REDIS_PORT:-6379}) 连接..."
  
  # 检查端口连接
  if timeout 10 bash -c "</dev/tcp/$REDIS_HOST/${REDIS_PORT:-6379}" 2>/dev/null; then
    echo "✅ Redis 端口 ${REDIS_PORT:-6379} 可达"
    
    # 尝试Redis连接测试（如果redis-cli可用）
    if command -v redis-cli >/dev/null 2>&1; then
      if redis-cli -h $REDIS_HOST -p ${REDIS_PORT:-6379} ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} ping >/dev/null 2>&1; then
        echo "✅ Redis 服务响应正常"
      else
        echo "⚠️  Redis 端口可达但服务响应异常（可能是密码问题）"
      fi
    else
      echo "ℹ️  redis-cli 不可用，无法测试Redis服务响应"
    fi
  else
    echo "❌ Redis 端口 ${REDIS_PORT:-6379} 不可达"
    echo "建议检查："
    echo "- Redis 容器状态: docker compose ps"
    echo "- 防火墙设置: ssh $REDIS_HOST 'sudo ufw status | grep 6379'"
    echo "- 绑定地址配置: ssh $REDIS_HOST 'grep bind /etc/redis/redis.conf'"
  fi
else
  echo "⚠️  未找到 Redis 连接信息"
fi

echo ""

# 测试 MySQL 连接
echo "测试 MySQL 数据库连接..."

# 测试系统数据库
if [ -n "$DATABASE_SYSTEMHOST" ]; then
  echo "测试 MySQL 系统库 ($DATABASE_SYSTEMHOST:${DATABASE_PORT:-3306}) 连接..."
  
  if timeout 10 bash -c "</dev/tcp/$DATABASE_SYSTEMHOST/${DATABASE_PORT:-3306}" 2>/dev/null; then
    echo "✅ MySQL 系统库端口 ${DATABASE_PORT:-3306} 可达"
    
    # 尝试MySQL连接测试（如果mysql客户端可用）
    if command -v mysql >/dev/null 2>&1; then
      if mysql -h $DATABASE_SYSTEMHOST -P ${DATABASE_PORT:-3306} -u ${DATABASE_USER:-root} ${DATABASE_PASSWORD:+-p"$DATABASE_PASSWORD"} -e "SELECT 1;" >/dev/null 2>&1; then
        echo "✅ MySQL 系统库认证成功"
      else
        echo "⚠️  MySQL 系统库端口可达但认证失败"
      fi
    else
      echo "ℹ️  mysql 客户端不可用，无法测试数据库认证"
    fi
  else
    echo "❌ MySQL 系统库端口 ${DATABASE_PORT:-3306} 不可达"
  fi
else
  echo "⚠️  未找到 MySQL 系统库连接信息"
fi

# 测试用户数据库
if [ -n "$DATABASE_NOVELHOST" ]; then
  echo "测试 MySQL 用户库 ($DATABASE_NOVELHOST:${DATABASE_PORT:-3306}) 连接..."
  
  if timeout 10 bash -c "</dev/tcp/$DATABASE_NOVELHOST/${DATABASE_PORT:-3306}" 2>/dev/null; then
    echo "✅ MySQL 用户库端口 ${DATABASE_PORT:-3306} 可达"
    
    if command -v mysql >/dev/null 2>&1; then
      if mysql -h $DATABASE_NOVELHOST -P ${DATABASE_PORT:-3306} -u ${DATABASE_NOVELUSER:-root} ${DATABASE_NOVELUSER_PASSWORD:+-p"$DATABASE_NOVELUSER_PASSWORD"} -e "SELECT 1;" >/dev/null 2>&1; then
        echo "✅ MySQL 用户库认证成功"
      else
        echo "⚠️  MySQL 用户库端口可达但认证失败"
      fi
    else
      echo "ℹ️  mysql 客户端不可用，无法测试数据库认证"
    fi
  else
    echo "❌ MySQL 用户库端口 ${DATABASE_PORT:-3306} 不可达"
  fi
else
  echo "⚠️  未找到 MySQL 用户库连接信息"
fi

echo ""

# 应用程序健康检查
echo "=== 应用程序健康检查 ==="

# 检查 Backend API
if curl -f -s ${BACKEND_URL:-http://localhost:8000}/health >/dev/null 2>&1; then
  echo "✅ Backend API 健康检查通过"
else
  echo "❌ Backend API 健康检查失败"
fi

# 检查 Frontend (如果有的话)
if curl -f -s ${FRONTEND_URL:-http://localhost:3000} >/dev/null 2>&1; then
  echo "✅ Frontend 可访问"
else
  echo "⚠️  Frontend 不可访问或未配置"
fi

echo ""

# 云服务特定检查
echo "=== 独立数据库服务器状态检查 ==="

echo "当前架构："
echo "📊 MongoDB: 独立服务器 ($MONGODB_HOST)"
echo "🗄️  Redis: 独立服务器 ($REDIS_HOST)" 
echo "🐬 MySQL: 独立数据库服务器 ($DATABASE_SYSTEMHOST, $DATABASE_NOVELHOST)"
echo ""

echo "建议检查项目："
echo "1. 服务器资源状态"
echo "   - CPU、内存、磁盘使用情况"
echo "   - 网络连接数和带宽"

echo "2. 数据库服务状态"
echo "   - MongoDB: docker compose ps"
echo "   - Redis: docker compose ps"
echo "   - MySQL: docker compose ps"

echo "3. 网络配置"
echo "   - 防火墙规则 (ufw status)"
echo "   - 服务监听地址 (netstat -tlnp)"
echo "   - 网络延迟 (ping 测试)"

echo "4. 数据库配置"
echo "   - MongoDB: /etc/mongod.conf (bindIp, port)"
echo "   - Redis: /etc/redis/redis.conf (bind, port, requirepass)"
echo "   - MySQL: /etc/mysql/mysql.conf.d/*.cnf (bind-address, port)"

echo ""

# 系统资源检查
echo "=== 系统资源检查 ==="
echo "CPU 使用率:"
top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//' || echo "无法获取 CPU 信息"

echo "内存使用情况:"
free -h 2>/dev/null || echo "无法获取内存信息"

echo "磁盘使用情况:"
df -h 2>/dev/null || echo "无法获取磁盘信息"

echo ""

echo "🏁 生产环境诊断完成"
echo ""
echo "=== 故障排除建议 ==="
echo "1. 独立数据库服务器连接失败："
echo "   - 检查服务器网络连通性: ping <server_ip>"
echo "   - 验证防火墙端口开放: telnet <server_ip> <port>"
echo "   - 确认服务监听状态: netstat -tlnp | grep <port>"
echo "   - 检查服务运行状态: docker compose ps"
echo ""
echo "2. MongoDB (172.16.32.2:27017) 问题："
echo "   - 容器状态: docker compose ps | grep mongo"
echo "   - 配置检查: grep bindIp /etc/mongod.conf"
echo "   - 日志查看: sudo tail -f /var/log/mongodb/mongod.log"
echo "   - 防火墙: sudo ufw allow 27017"
echo ""
echo "3. Redis (172.16.32.2:6379) 问题："
echo "   - 容器状态: docker compose ps | grep redis"
echo "   - 配置检查: grep bind /etc/redis/redis.conf"
echo "   - 密码验证: redis-cli -h 172.16.32.2 -a <password> ping"
echo "   - 防火墙: sudo ufw allow 6379"
echo ""
echo "4. MySQL (172.16.16.x:3306) 问题："
echo "   - 容器状态: docker compose ps | grep mysql"
echo "   - 用户权限: GRANT ALL ON *.* TO 'user'@'%' IDENTIFIED BY 'password';"
echo "   - 绑定地址: grep bind-address /etc/mysql/mysql.conf.d/mysqld.cnf"
echo "   - 防火墙: sudo ufw allow 3306"
echo ""
echo "5. 应用程序问题："
echo "   - 查看应用日志: docker-compose logs backend"
echo "   - 检查环境变量: docker-compose exec backend env | grep DATABASE"
echo "   - 验证连接字符串格式和认证信息"
echo ""
echo "6. 网络问题："
echo "   - 内网连通性: ping 172.16.32.2, ping 172.16.16.2"
echo "   - 路由检查: traceroute <target_ip>"
echo "   - DNS解析: nslookup <hostname>"
echo "   - 端口扫描: nmap -p <port> <target_ip>"
