# 🌐 百度云服务器直接部署指南

## 📋 概述

本指南提供了直接部署AI小说编辑器到百度云服务器的方法，无需GitHub Actions，适合快速部署和测试。

## 🎯 百度云服务器信息

- **服务器IP**: 106.13.216.179
- **用户**: root
- **系统**: BaiduLinux
- **开放端口**: 22, 80, 8000, 8080, 30080

## 🚀 三种直接部署方式

### 方式一：一键部署脚本（推荐）

```bash
# 1. 执行一键部署
./deploy-baidu-cloud.sh

# 或分步执行
./deploy-baidu-cloud.sh check    # 检查SSH连接
./deploy-baidu-cloud.sh config   # 创建配置文件
./deploy-baidu-cloud.sh deploy   # 执行部署
./deploy-baidu-cloud.sh verify   # 验证部署
```

### 方式二：手动SSH部署

```bash
# 1. SSH连接到服务器
ssh root@106.13.216.179

# 2. 在服务器上创建目录
mkdir -p /root/novel-editor
cd /root/novel-editor

# 3. 克隆项目（如果服务器有Git）
git clone https://github.com/lessstoryclassmate/legezhixiao.git .

# 4. 或者从本地上传文件
# 在本地执行：
rsync -avz --exclude='node_modules' --exclude='.git' \
      ./ root@106.13.216.179:/root/novel-editor/

# 5. 在服务器上部署
cd /root/novel-editor/novel-editor
./deploy-prod.sh prod
```

### 方式三：Docker直接部署

```bash
# 1. SSH连接到服务器
ssh root@106.13.216.179

# 2. 安装Docker (如果未安装)
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
systemctl start docker
systemctl enable docker

# 3. 安装Docker Compose
curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# 4. 创建项目目录和配置
mkdir -p /root/novel-editor
cd /root/novel-editor

# 5. 创建环境配置
cat > .env.prod << 'EOF'
DEBUG=false
DATABASE_SYSTEMIP=172.16.16.3
DATABASE_SYSTEM=novel_data
DATABASE_USER=lkr
DATABASE_PASSWORD=Lekairong350702
DATABASE_NOVELIP=172.16.16.2
DATABASE_NOVELDATA=novel_user_data
DATABASE_NOVELUSER=novel_data_user
DATABASE_NOVELUSER_PASSWORD=Lekairong350702
SILICONFLOW_API_KEY=sk-mjithqmjwccqgffouexthbavtnvftwkqjludpcxhrmeztcib
SECRET_KEY=baidu-cloud-novel-editor-secret-key-2025
EOF

# 6. 上传或创建docker-compose.prod.yml文件

# 7. 启动服务
docker-compose -f docker-compose.prod.yml up -d --build
```

## 📦 快速部署命令组合

### 从本地一键部署到百度云
```bash
# 确保有SSH密钥访问权限
ssh-copy-id root@106.13.216.179  # 首次配置SSH密钥

# 执行一键部署
./deploy-baidu-cloud.sh
```

### 从服务器直接部署
```bash
# SSH到服务器
ssh root@106.13.216.179

# 快速安装和启动
curl -sSL https://raw.githubusercontent.com/lessstoryclassmate/legezhixiao/main/novel-editor/deploy-baidu-cloud.sh | bash
```

## 🔧 服务器环境配置

### 系统要求检查
```bash
# 检查系统信息
cat /etc/os-release
free -h
df -h
docker --version
docker-compose --version
```

### 防火墙配置
```bash
# 开放必要端口
ufw allow 22/tcp   # SSH
ufw allow 80/tcp   # HTTP前端
ufw allow 8000/tcp # API后端
ufw --force enable

# 检查端口状态
netstat -tlnp | grep -E ':(22|80|8000)'
```

### 数据库连接测试
```bash
# 测试系统数据库连接
mysql -h 172.16.16.3 -P 3306 -u lkr -p novel_data

# 测试用户数据库连接
mysql -h 172.16.16.2 -P 3306 -u novel_data_user -p novel_user_data
```

## 📊 部署后验证

### 服务状态检查
```bash
# 检查容器状态
docker ps

# 检查服务日志
docker-compose logs -f --tail=50

# 资源使用情况
docker stats --no-stream
```

### 功能验证
```bash
# 健康检查
curl -f http://106.13.216.179:8000/health

# 前端访问测试
curl -I http://106.13.216.179

# API文档访问
curl -f http://106.13.216.179:8000/docs
```

## 🌐 访问地址

部署完成后，通过以下地址访问：

- **🏠 前端页面**: http://106.13.216.179
- **📖 API文档**: http://106.13.216.179:8000/docs  
- **💓 健康检查**: http://106.13.216.179:8000/health
- **🔍 交互式API**: http://106.13.216.179:8000/redoc

## 🔄 常用管理命令

### 服务管理
```bash
# 重启所有服务
ssh root@106.13.216.179 'cd /root/novel-editor && docker-compose -f docker-compose.prod.yml restart'

# 查看实时日志
ssh root@106.13.216.179 'cd /root/novel-editor && docker-compose -f docker-compose.prod.yml logs -f'

# 停止服务
ssh root@106.13.216.179 'cd /root/novel-editor && docker-compose -f docker-compose.prod.yml down'

# 更新并重启
ssh root@106.13.216.179 'cd /root/novel-editor && git pull && docker-compose -f docker-compose.prod.yml up -d --build'
```

### 监控命令
```bash
# 系统资源监控
ssh root@106.13.216.179 'top -n 1'
ssh root@106.13.216.179 'df -h'
ssh root@106.13.216.179 'free -h'

# 容器监控
ssh root@106.13.216.179 'docker stats --no-stream'
```

## 🆘 故障排除

### 常见问题

1. **SSH连接失败**
   ```bash
   # 检查SSH密钥
   ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
   ssh-copy-id root@106.13.216.179
   ```

2. **端口被占用**
   ```bash
   # 检查端口占用
   ssh root@106.13.216.179 'netstat -tlnp | grep :80'
   ssh root@106.13.216.179 'netstat -tlnp | grep :8000'
   ```

3. **数据库连接失败**
   ```bash
   # 在服务器上测试数据库连接
   ssh root@106.13.216.179 'telnet 172.16.16.3 3306'
   ```

4. **Docker问题**
   ```bash
   # 重启Docker服务
   ssh root@106.13.216.179 'systemctl restart docker'
   
   # 清理Docker缓存
   ssh root@106.13.216.179 'docker system prune -af'
   ```

## 💡 优势和特点

### ✅ 直接部署优势
- **快速**: 绕过CI/CD，直接部署
- **简单**: 一条命令完成部署
- **灵活**: 可以随时调试和修改
- **实时**: 立即看到部署结果

### ✅ 百度云服务器特点
- **稳定**: 百度云基础设施可靠
- **内网数据库**: 高速数据库访问
- **固定IP**: 106.13.216.179 固定访问地址
- **端口开放**: 已配置必要端口访问

---

**🎉 现在您可以直接在百度云服务器上快速部署AI小说编辑器了！**

**推荐使用方式一的一键部署脚本，最简单高效！**
