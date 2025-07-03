# 🐳 Docker部署配置指南

## 📋 概述

本指南详细介绍如何使用GitHub Actions和Docker进行AI小说编辑器的自动化部署。

## 🏗️ Docker镜像构建策略

### 1. 多阶段构建配置

#### 后端Dockerfile (backend/Dockerfile)
```dockerfile
# 开发阶段
FROM python:3.11-slim as development
WORKDIR /app
COPY requirements-dev.txt requirements.txt ./
RUN pip install --no-cache-dir -r requirements-dev.txt
COPY . .
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]

# 生产阶段
FROM python:3.11-slim as production
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

#### 前端Dockerfile (frontend/Dockerfile)
```dockerfile
# 构建阶段
FROM node:18-alpine as build
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build

# 生产阶段
FROM nginx:alpine as production
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

## 🚀 GitHub Actions部署流程

### 工作流文件: `.github/workflows/docker-deploy.yml`

#### 阶段1: 构建Docker镜像
```yaml
build:
  runs-on: ubuntu-latest
  steps:
  - name: 构建后端镜像
    uses: docker/build-push-action@v5
    with:
      context: ./backend
      target: production
      push: true
      tags: ghcr.io/user/novel-editor-backend:latest
      
  - name: 构建前端镜像  
    uses: docker/build-push-action@v5
    with:
      context: ./frontend
      target: production
      push: true
      tags: ghcr.io/user/novel-editor-frontend:latest
```

#### 阶段2: 部署到服务器
```yaml
deploy:
  needs: build
  steps:
  - name: 部署到百度云服务器
    run: |
      ssh user@server << 'EOF'
        docker pull ghcr.io/user/novel-editor-backend:latest
        docker pull ghcr.io/user/novel-editor-frontend:latest
        docker-compose -f docker-compose.deploy.yml up -d
      EOF
```

## 📦 容器编排配置

### Docker Compose部署文件
```yaml
version: '3.8'

services:
  backend:
    image: ghcr.io/user/novel-editor-backend:latest
    container_name: novel-editor-backend
    restart: unless-stopped
    environment:
      - DATABASE_SYSTEMIP=172.16.16.3
      - DATABASE_PASSWORD=${DATABASE_PASSWORD}
      - SILICONFLOW_API_KEY=${SILICONFLOW_API_KEY}
    ports:
      - "8000:8000"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  frontend:
    image: ghcr.io/user/novel-editor-frontend:latest
    container_name: novel-editor-frontend
    restart: unless-stopped
    ports:
      - "80:80"
    depends_on:
      backend:
        condition: service_healthy

  redis:
    image: redis:7-alpine
    container_name: novel-editor-redis
    restart: unless-stopped
    volumes:
      - redis_data:/data

volumes:
  redis_data:
```

## 🔐 GitHub Secrets配置

### 必需的Secrets列表
```bash
# 服务器配置
SERVER_IP=106.13.216.179
SERVER_USER=root
SERVER_SSH_KEY=<SSH私钥内容>

# 数据库配置
DATABASE_SYSTEMIP=172.16.16.3
DATABASE_SYSTEM=novel_data
DATABASE_USER=lkr
DATABASE_PASSWORD=Lekairong350702
DATABASE_NOVELIP=172.16.16.2
DATABASE_NOVELDATA=novel_user_data
DATABASE_NOVELUSER=novel_data_user
DATABASE_NOVELUSER_PASSWORD=Lekairong350702

# AI服务配置
SILICONFLOW_API_KEY=sk-mjithqmjwccqgffouexthbavtnvftwkqjludpcxhrmeztcib

# 安全配置
JWT_SECRET_KEY=<生成的JWT密钥>

# 容器注册表配置 (自动提供)
GITHUB_TOKEN=<自动生成>
```

## 🎯 部署触发方式

### 1. 自动触发
- **推送到main分支**: 自动构建和部署
- **Pull Request**: 仅构建镜像进行测试

### 2. 手动触发
```bash
# 在GitHub仓库页面
Actions → 🐳 Docker Build and Deploy → Run workflow
```

### 3. 本地测试
```bash
# 本地构建测试
docker build -t novel-editor-backend ./backend
docker build -t novel-editor-frontend ./frontend

# 本地运行测试
docker-compose -f docker-compose.dev.yml up -d
```

## 📊 部署监控和验证

### 自动化健康检查
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

### 部署后验证命令
```bash
# 检查容器状态
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# 查看服务日志
docker-compose logs -f --tail=50

# 资源使用监控
docker stats --no-stream

# 健康检查验证
curl -f http://106.13.216.179:8000/health
curl -f http://106.13.216.179/
```

## 🚨 故障排除

### 常见问题和解决方案

#### 1. 镜像构建失败
```bash
# 清理构建缓存
docker builder prune

# 重新构建
docker build --no-cache -t image-name .
```

#### 2. 容器启动失败
```bash
# 查看详细日志
docker logs container-name

# 检查环境变量
docker exec container-name env
```

#### 3. 网络连接问题
```bash
# 检查网络配置
docker network ls
docker network inspect bridge

# 重启网络
docker-compose down && docker-compose up -d
```

#### 4. 数据库连接失败
```bash
# 验证数据库连接
docker exec backend-container python -c "
import os
print('DB Host:', os.getenv('DATABASE_SYSTEMIP'))
print('DB User:', os.getenv('DATABASE_USER'))
"
```

## 🔄 更新和回滚策略

### 滚动更新
```bash
# GitHub Actions自动执行
docker pull new-image:tag
docker-compose up -d --no-deps service-name
```

### 快速回滚
```bash
# 回滚到上一个版本
docker tag current-image:latest current-image:backup
docker pull previous-image:tag
docker tag previous-image:tag current-image:latest
docker-compose up -d --no-deps service-name
```

## 📈 性能优化

### 镜像优化
- 使用多阶段构建减少镜像大小
- 利用Docker层缓存加速构建
- 移除不必要的依赖和文件

### 运行时优化
- 配置适当的健康检查间隔
- 设置资源限制 (CPU/内存)
- 使用Redis缓存提升性能

## 🎉 部署成功验证

部署完成后，验证以下服务：

- **前端**: http://106.13.216.179
- **API文档**: http://106.13.216.179:8000/docs
- **健康检查**: http://106.13.216.179:8000/health
- **AI服务**: 通过前端测试小说创作功能

---

**🚀 现在您已经拥有了完整的Docker化自动部署流程！**
