# 云数据库内网连接配置

## 概述

本次配置将应用架构从本地容器数据库迁移到云数据库，使用内网 IP 地址进行连接。这种架构更适合生产环境，提供更好的性能、可靠性和可扩展性。

## 架构变更

### 之前的架构（本地容器）
```
Frontend Container ← Backend Container ← Local MongoDB Container
                                     ← Local Redis Container
                                     ← Cloud MySQL Database
```

### 现在的架构（云数据库）
```
Frontend Container ← Backend Container ← Cloud MongoDB Database
                                     ← Cloud Redis Database  
                                     ← Cloud MySQL Database
```

## 配置详情

### 1. 云数据库连接地址

**MongoDB 配置**:
- 内网地址: `172.16.16.2:27017`
- 数据库名: `ai_novel_db`
- 连接字符串: `mongodb://172.16.16.2:27017/ai_novel_db`

**Redis 配置**:
- 内网地址: `172.16.16.4:6379`
- 连接字符串: `redis://:password@172.16.16.4:6379`

**MySQL 配置**:
- 系统数据库: `172.16.16.3:3306/novel_data`
- 用户数据库: `172.16.16.2:3306/novel_user_data`

### 2. Docker Compose 配置

**环境变量配置**:
```yaml
backend:
  environment:
    - MONGODB_URL=mongodb://${MONGODB_HOST}:${MONGODB_PORT}/${MONGODB_DATABASE}
    - REDIS_URL=redis://:${REDIS_PASSWORD}@${REDIS_HOST}:${REDIS_PORT}
    - DATABASE_SYSTEM_URL=mysql+aiomysql://${DATABASE_USER}:${DATABASE_PASSWORD}@${DATABASE_SYSTEMHOST}:3306/${DATABASE_SYSTEM}
    - DATABASE_NOVEL_URL=mysql+aiomysql://${DATABASE_NOVELUSER}:${DATABASE_NOVELUSER_PASSWORD}@${DATABASE_NOVELHOST}:3306/${DATABASE_NOVELDATA}
```

**移除的服务**:
- 本地 MongoDB 容器
- 本地 Redis 容器
- 相关的数据卷

### 3. 网络连接配置

**容器网络要求**:
- 后端容器需要能够访问云数据库的内网 IP
- 使用 Docker 桥接网络模式
- 确保宿主机能够路由到云数据库内网地址

**安全组配置**:
- 云数据库安全组需要允许服务器 IP 访问
- 开放相应的数据库端口（27017, 6379, 3306）
- 配置内网访问白名单

## 环境变量配置

### 测试环境变量
```bash
# 云数据库配置
MONGODB_HOST=172.16.16.2
MONGODB_PORT=27017
MONGODB_DATABASE=ai_novel_db
REDIS_HOST=172.16.16.4
REDIS_PORT=6379
REDIS_PASSWORD=Lekairong350702

# MySQL 配置
DATABASE_SYSTEMHOST=172.16.16.3
DATABASE_NOVELHOST=172.16.16.2
```

### 生产环境变量
与测试环境相同，通过 GitHub Secrets 管理敏感信息。

## CI/CD 工作流优化

### 构建阶段改进
1. **移除本地数据库健康检查**: 不再检查本地 MongoDB 容器
2. **添加网络连接测试**: 测试到云数据库的网络连通性
3. **简化容器启动**: 只启动前端和后端容器

### 部署阶段改进
1. **移除数据卷管理**: 不再需要管理本地数据库卷
2. **简化启动流程**: 直接启动所有服务
3. **优化健康检查**: 重点检查后端服务连接状态

## 网络连接验证

### 连接测试命令
```bash
# 测试 MongoDB 连接
ping -c 3 172.16.16.2

# 测试 Redis 连接  
ping -c 3 172.16.16.4

# 测试 MySQL 连接
ping -c 3 172.16.16.3

# 测试端口连通性
telnet 172.16.16.2 27017
telnet 172.16.16.4 6379
telnet 172.16.16.3 3306
```

### 应用层连接测试
```python
# MongoDB 连接测试
import motor.motor_asyncio
client = motor.motor_asyncio.AsyncIOMotorClient('mongodb://172.16.16.2:27017/ai_novel_db')

# Redis 连接测试
import redis
r = redis.Redis(host='172.16.16.4', port=6379, password='password')

# MySQL 连接测试
import aiomysql
conn = await aiomysql.connect(host='172.16.16.3', port=3306, user='user', password='password')
```

## 优势与效果

### 性能优势
- **降低资源消耗**: 不再运行本地数据库容器
- **提高启动速度**: 减少容器启动时间
- **优化内存使用**: 释放本地数据库占用的内存

### 可靠性优势
- **专业数据库服务**: 使用云厂商的专业数据库服务
- **高可用性**: 云数据库提供自动备份和故障转移
- **性能监控**: 云平台提供详细的性能监控

### 安全性优势
- **网络隔离**: 使用内网连接，提高安全性
- **访问控制**: 通过安全组和白名单控制访问
- **数据加密**: 云数据库提供数据传输和存储加密

## 故障排查

### 常见问题

1. **连接超时**
   - 检查安全组配置
   - 验证内网 IP 地址
   - 确认端口开放状态

2. **认证失败**
   - 验证用户名密码
   - 检查数据库权限设置
   - 确认连接字符串格式

3. **网络不通**
   - 检查服务器到数据库的网络路由
   - 验证防火墙设置
   - 测试端口连通性

### 调试命令
```bash
# 检查容器网络
docker network ls
docker network inspect bridge

# 检查环境变量
docker-compose exec backend env | grep -E "(MONGODB|REDIS|DATABASE)"

# 查看容器日志
docker-compose logs backend

# 进入容器调试
docker-compose exec backend bash
```

## 迁移检查清单

- [x] 更新 docker-compose.yml 配置
- [x] 移除本地数据库容器
- [x] 更新环境变量配置
- [x] 修改 CI/CD 工作流
- [x] 添加网络连接测试
- [x] 更新健康检查逻辑
- [x] 创建配置文档

## 后续优化建议

1. **监控配置**: 添加数据库连接监控
2. **缓存优化**: 配置 Redis 缓存策略
3. **连接池**: 优化数据库连接池配置
4. **备份策略**: 配置定期数据备份
5. **性能调优**: 根据实际使用情况调优数据库参数

---

**配置日期**: 2025-07-11  
**版本**: v3.0  
**状态**: 已部署  
**架构**: 云数据库 + 容器化应用
