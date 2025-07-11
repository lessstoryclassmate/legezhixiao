# 部署架构说明

## 概述

为了解决 MongoDB 连接超时问题，我们采用了双环境配置策略：

### 开发/测试环境（CI/CD）
- 使用本地 Docker 容器服务
- `docker-compose.yml` 包含 MongoDB 和 Redis 容器
- 环境变量默认指向容器服务名称

### 生产环境
- 使用云数据库服务
- `docker-compose.production.yml` 配置云数据库连接
- `.env.production.template` 包含生产环境配置

## 文件结构

```
├── docker-compose.yml              # 开发/测试环境（包含本地数据库容器）
├── docker-compose.production.yml   # 生产环境（连接云数据库）
├── .env.production.template        # 生产环境配置模板
└── .github/workflows/deploy-advanced.yml  # CI/CD 配置
```

## 数据库配置

### 测试环境
- **MongoDB**: `mongodb:27017` (容器服务)
- **Redis**: `redis:6379` (容器服务)
- **MySQL**: 仍使用云服务（但CI环境可能无法连接）

### 生产环境
- **MongoDB**: `172.16.32.2:27017` (云数据库)
- **Redis**: `172.16.32.2:6379` (云缓存)
- **MySQL 系统库**: `172.16.16.3:3306` (云数据库)
- **MySQL 用户库**: `172.16.16.2:3306` (云数据库)

## 环境变量配置

### 测试环境默认值
```bash
MONGODB_HOST=mongodb
REDIS_HOST=redis
```

### 生产环境覆盖
```bash
MONGODB_HOST=172.16.32.2
REDIS_HOST=172.16.32.2
```

## 部署流程

### CI/CD 测试阶段
1. 创建测试环境配置文件
2. 启动包含本地数据库的 Docker Compose
3. 执行健康检查和连接测试
4. 验证后端服务能正常启动

### 生产部署阶段
1. 使用生产环境配置模板
2. 使用 `docker-compose.production.yml`
3. 连接到云数据库服务
4. 执行健康检查

## 解决的问题

1. **MongoDB 连接超时**: CI/CD 环境现在使用本地 MongoDB 容器
2. **环境隔离**: 测试和生产环境使用不同的数据库配置
3. **容器依赖**: 通过 `depends_on` 和健康检查确保服务启动顺序
4. **网络连接**: 使用 Docker 网络确保容器间通信

## 监控和诊断

### 容器健康检查
- MongoDB: `mongosh --eval "db.adminCommand('ping')"`
- Redis: `redis-cli ping`
- 后端: `curl -f http://localhost:8000/health`

### 网络测试
- 容器间网络连通性测试
- 端口可达性检查
- 服务状态验证
