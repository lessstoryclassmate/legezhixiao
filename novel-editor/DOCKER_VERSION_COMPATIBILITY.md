# 🐳 Docker版本兼容性部署指南

## 🚨 问题描述

您遇到的Docker语法错误主要由以下原因造成：
- Docker引擎版本过旧（< 20.10）
- 大小写敏感性问题
- 多阶段构建语法不被支持

## 🛠️ 解决方案

### 方案1：更新Docker引擎（推荐）

#### Ubuntu/Debian系统：
```bash
# 运行自动更新脚本
./update-docker.sh
```

#### CentOS/RHEL系统：
```bash
# 运行CentOS版本更新脚本
./update-docker-centos.sh
```

#### 手动更新Docker：
```bash
# 检查当前版本
docker --version

# Ubuntu/Debian系统
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# CentOS/RHEL系统
sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 重启Docker服务
sudo systemctl restart docker
```

### 方案2：使用兼容性部署（备用方案）

如果无法更新Docker，使用简化的单阶段构建：

```bash
# 使用兼容性配置部署
docker-compose -f docker-compose.simple.yml up -d --build
```

## 📋 版本要求

| 组件 | 最低版本 | 推荐版本 |
|------|----------|----------|
| Docker Engine | 20.10.0 | 24.0+ |
| Docker Compose | 1.29.0 | 2.20+ |

## 🔍 版本检查命令

```bash
# 检查Docker版本
docker --version
docker compose version

# 检查是否支持多阶段构建
docker build --help | grep -i "target"
```

## 🚀 自动化部署

GitHub Actions现在会：
1. 🔍 检查服务器Docker版本
2. 🆙 自动更新Docker（如果版本过旧）
3. 🐳 使用最新语法进行构建
4. 📦 如果失败，自动回退到兼容模式

## 📁 文件说明

- `Dockerfile` - 最新Docker语法的多阶段构建
- `Dockerfile.simple` - 兼容旧版本的单阶段构建
- `docker-compose.prod.yml` - 生产环境配置（需要Docker 20.10+）
- `docker-compose.simple.yml` - 兼容性配置（支持Docker 18.06+）
- `update-docker.sh` - Ubuntu/Debian Docker更新脚本
- `update-docker-centos.sh` - CentOS/RHEL Docker更新脚本

## 🎯 推荐操作步骤

1. **首先尝试更新Docker：**
   ```bash
   ./update-docker.sh
   ```

2. **如果更新成功，使用标准部署：**
   ```bash
   docker-compose -f docker-compose.prod.yml up -d --build
   ```

3. **如果无法更新，使用兼容性部署：**
   ```bash
   docker-compose -f docker-compose.simple.yml up -d --build
   ```

## ✅ 验证部署

```bash
# 检查服务状态
docker-compose ps

# 检查健康状态
curl http://localhost:8000/health
curl http://localhost/

# 查看日志
docker-compose logs
```

## 🆘 常见问题

### Q: 更新Docker后还是有问题？
A: 重新登录系统或运行 `newgrp docker` 激活用户组权限

### Q: 不想更新Docker怎么办？
A: 使用 `docker-compose.simple.yml` 进行兼容性部署

### Q: 部署后无法访问？
A: 检查防火墙设置和端口映射：
```bash
sudo ufw allow 80
sudo ufw allow 8000
```
