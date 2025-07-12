# 服务器直接部署指南

## 🎯 概述
提供两个脚本直接在服务器上安装Docker环境并部署AI小说编辑器，无需CI/CD流程。

## 📋 脚本说明

### 1. Docker安装脚本 (`scripts/install-docker.sh`)
**用途**: 在Ubuntu服务器上安装Docker和Docker Compose

**功能**:
- ✅ 自动检测系统版本和架构
- ✅ 安装Docker CE最新版本
- ✅ 安装Docker Compose最新版本
- ✅ 配置用户权限
- ✅ 测试安装结果

### 2. 直接部署脚本 (`scripts/direct-deploy.sh`)
**用途**: 在已安装Docker的服务器上直接部署应用

**功能**:
- ✅ 自动克隆/更新代码
- ✅ 配置环境变量
- ✅ 检查数据库连接
- ✅ 构建和启动服务
- ✅ 执行健康检查

## 🚀 使用方法

### 方法一：分步执行

```bash
# 1. 连接到服务器
ssh your_user@your_server_ip

# 2. 克隆仓库（首次）
git clone https://github.com/lessstoryclassmate/legezhixiao.git
cd legezhixiao

# 3. 安装Docker环境
sudo bash scripts/install-docker.sh

# 4. 重新登录使docker权限生效
exit
ssh your_user@your_server_ip
cd legezhixiao

# 5. 编辑部署脚本中的环境变量
nano scripts/direct-deploy.sh
# 修改以下变量：
# export SERVER_IP="your_actual_server_ip"
# export SILICONFLOW_API_KEY="your_actual_api_key"
# export JWT_SECRET_KEY="your_actual_jwt_secret"

# 6. 执行部署
bash scripts/direct-deploy.sh
```

### 方法二：一键执行

```bash
# 1. 连接到服务器
ssh your_user@your_server_ip

# 2. 下载并执行安装脚本
curl -sSL https://raw.githubusercontent.com/lessstoryclassmate/legezhixiao/main/scripts/install-docker.sh | sudo bash

# 3. 重新登录
exit
ssh your_user@your_server_ip

# 4. 下载并配置部署脚本
curl -sSL https://raw.githubusercontent.com/lessstoryclassmate/legezhixiao/main/scripts/direct-deploy.sh -o deploy.sh
chmod +x deploy.sh

# 5. 编辑环境变量
nano deploy.sh
# 修改脚本开头的环境变量配置

# 6. 执行部署
bash deploy.sh
```

## ⚙️ 环境变量配置

在执行部署脚本前，需要修改以下环境变量：

```bash
# 必须修改的变量
export SERVER_IP="your_server_ip"              # 服务器公网IP
export SILICONFLOW_API_KEY="your_api_key"      # AI服务API密钥
export JWT_SECRET_KEY="your_jwt_secret"        # JWT密钥

# 可选修改的变量
export REDIS_PASSWORD="Lekairong350702"        # Redis密码
```

## 🔍 验证安装

### 检查Docker安装
```bash
# 检查Docker版本
docker --version
docker-compose --version

# 检查Docker服务状态
sudo systemctl status docker

# 测试Docker权限
docker ps
```

### 检查部署状态
```bash
# 进入项目目录
cd /opt/ai-novel-editor

# 查看容器状态
docker-compose -f docker-compose.production.yml ps

# 查看服务日志
docker-compose -f docker-compose.production.yml logs

# 测试服务访问
curl http://localhost:8000/health
curl http://localhost:80
```

## 🔧 常用操作

### 重启服务
```bash
cd /opt/ai-novel-editor
docker-compose -f docker-compose.production.yml restart
```

### 更新代码
```bash
cd /opt/ai-novel-editor
git pull origin main
docker-compose -f docker-compose.production.yml down
docker-compose -f docker-compose.production.yml build --no-cache
docker-compose -f docker-compose.production.yml up -d
```

### 查看日志
```bash
cd /opt/ai-novel-editor
# 查看所有服务日志
docker-compose -f docker-compose.production.yml logs

# 查看特定服务日志
docker-compose -f docker-compose.production.yml logs backend
docker-compose -f docker-compose.production.yml logs frontend
```

### 停止服务
```bash
cd /opt/ai-novel-editor
docker-compose -f docker-compose.production.yml down
```

## 🐛 故障排除

### Docker权限问题
```bash
# 将用户添加到docker组
sudo usermod -aG docker $USER

# 重新登录或执行
newgrp docker

# 测试权限
docker ps
```

### 端口占用问题
```bash
# 检查端口占用
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :8000

# 停止占用端口的进程
sudo fuser -k 80/tcp
sudo fuser -k 8000/tcp
```

### 数据库连接问题
```bash
# 测试数据库连接
nc -zv 172.16.32.2 27017  # MongoDB
nc -zv 172.16.32.2 6379   # Redis
nc -zv 172.16.16.3 3306   # MySQL系统库
nc -zv 172.16.16.2 3306   # MySQL用户库
```

### 容器启动失败
```bash
cd /opt/ai-novel-editor

# 查看构建日志
docker-compose -f docker-compose.production.yml build --no-cache

# 查看启动日志
docker-compose -f docker-compose.production.yml up

# 进入容器调试
docker-compose -f docker-compose.production.yml exec backend bash
```

## 📊 性能优化

### 系统参数调优
```bash
# MongoDB相关
sudo sysctl -w vm.max_map_count=1677720

# 添加到永久配置
echo 'vm.max_map_count=1677720' | sudo tee -a /etc/sysctl.conf
```

### Docker资源限制
编辑 `docker-compose.production.yml` 添加资源限制：
```yaml
services:
  backend:
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: '0.5'
```

## 🔐 安全建议

1. **防火墙配置**
```bash
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 8000/tcp
sudo ufw enable
```

2. **定期更新**
```bash
sudo apt-get update && sudo apt-get upgrade
```

3. **备份策略**
```bash
# 数据库备份
docker-compose -f docker-compose.production.yml exec backend python backup.py

# 代码备份
tar -czf backup-$(date +%Y%m%d).tar.gz /opt/ai-novel-editor
```

## 📞 支持

如遇问题，请提供以下信息：
- 系统版本: `lsb_release -a`
- Docker版本: `docker --version`
- 容器状态: `docker-compose ps`
- 服务日志: `docker-compose logs`
