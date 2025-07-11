# Docker 网络架构文档

## 网络配置概览

### 自定义网络设计
- **网络名称**: `app-network`
- **网络类型**: Bridge 网络
- **网络作用域**: 单主机容器通信
- **自动 DNS**: 支持服务名解析

### 服务间通信模式

#### 开发/CI 环境 (docker-compose.yml)
```yaml
networks:
  app-network:
    driver: bridge
```

所有服务连接到 `app-network`:
- `frontend` ↔ `backend:8000`
- `backend` ↔ `mongodb:27017`
- `backend` ↔ `redis:6379`

#### 生产环境 (docker-compose.production.yml)
```yaml
networks:
  app-network:
    driver: bridge
```

容器服务 + 外部数据库:
- `frontend` ↔ `backend:8000` (容器间)
- `backend` ↔ `172.16.32.2:27017` (MongoDB 外部服务器)
- `backend` ↔ `172.16.32.2:6379` (Redis 外部服务器)
- `backend` ↔ `172.16.16.3:3306` (MySQL 系统库)
- `backend` ↔ `172.16.16.2:3306` (MySQL 用户库)

## 网络连通性测试

### CI/CD 自动化测试
1. **网络创建验证**: 确保 `app-network` 正确创建
2. **容器连接验证**: 检查所有服务是否连接到网络
3. **服务发现测试**: 测试服务名解析 (mongodb, redis)
4. **端口连通性测试**: 验证服务间端口可达性

### 诊断脚本功能
- `scripts/ci-container-diagnostics.sh`: 开发/CI 环境网络诊断
- `scripts/production-diagnostics.sh`: 生产环境网络诊断

## 最佳实践

### ✅ 优点
1. **统一网络管理**: 所有服务使用同一个自定义网络
2. **服务发现**: 通过服务名进行通信，无需硬编码 IP
3. **网络隔离**: 自定义网络与默认 bridge 网络隔离
4. **灵活配置**: 支持开发和生产环境不同的网络配置

### 🔧 网络命名规范
- **网络名称**: `{项目名}_app-network`
- **实际网络**: `legezhixiao_app-network`
- **服务发现**: 直接使用服务名 (mongodb, redis, backend, frontend)

### 📊 端口映射策略
```yaml
# 开发环境端口映射
frontend:
  ports:
    - "80:80"      # HTTP 访问
    - "8080:80"    # 备用端口
    
backend:
  ports:
    - "8000:8000"  # API 服务
    - "3000:8000"  # 开发端口
    
mongodb:
  ports:
    - "27017:27017"  # 数据库访问
    
redis:
  ports:
    - "6379:6379"    # 缓存访问
```

## 故障排除

### 常见网络问题
1. **网络不存在**: 检查 docker-compose.yml 网络配置
2. **服务无法通信**: 验证所有服务是否连接到 app-network
3. **DNS 解析失败**: 确保使用正确的服务名
4. **端口不可达**: 检查服务健康状态和端口配置

### 调试命令
```bash
# 查看网络列表
docker network ls

# 检查网络详情
docker network inspect legezhixiao_app-network

# 测试容器间连通性
docker-compose exec backend ping mongodb
docker-compose exec backend ping redis

# 检查容器网络配置
docker-compose exec backend ip addr show
docker-compose exec backend ip route
```

## 环境变量配置

### 开发环境
```bash
# 使用容器服务名
MONGODB_HOST=mongodb
REDIS_HOST=redis
```

### 生产环境
```bash
# 使用外部服务器 IP
MONGODB_HOST=172.16.32.2
REDIS_HOST=172.16.32.2
```

## 健康检查集成

网络配置与健康检查集成，确保：
1. 服务启动前网络就绪
2. 依赖服务网络可达后再启动
3. 网络故障时自动重启

```yaml
backend:
  depends_on:
    mongodb:
      condition: service_healthy
    redis:
      condition: service_healthy
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
```
