# 云服务器部署使用说明

## 🎯 概述

本项目已完成完整的容器化部署配置，您可以通过以下几种方式将AI小说编辑器部署到云服务器：

## 🚀 方式一：一键云部署（推荐）

### 1. 下载部署脚本

```bash
# 在云服务器上执行
curl -sSL https://raw.githubusercontent.com/your-username/novel-editor/main/cloud-deploy.sh -o cloud-deploy.sh
chmod +x cloud-deploy.sh
```

### 2. 执行一键部署

```bash
# 基础部署（交互式配置）
./cloud-deploy.sh

# 或带参数部署
./cloud-deploy.sh \
  --repo-url https://github.com/your-username/novel-editor.git \
  --api-key your_siliconflow_api_key
```

### 3. 部署完成

脚本会自动：
- 检测操作系统并安装Docker、Docker Compose
- 配置防火墙开放必要端口
- 克隆项目代码
- 配置环境变量
- 启动所有服务
- 进行健康检查

## 🛠️ 方式二：手动部署

### 1. 环境准备

```bash
# 安装Docker (Ubuntu/Debian)
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
sudo usermod -aG docker $USER

# 安装Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### 2. 克隆项目

```bash
git clone https://github.com/your-username/novel-editor.git
cd novel-editor
```

### 3. 配置环境

```bash
# 复制环境变量模板
cp .env.prod.example .env.prod

# 编辑配置文件
vim .env.prod
```

必需配置：
```bash
SILICONFLOW_API_KEY=your_api_key_here
DEFAULT_AI_MODEL=deepseek-ai/DeepSeek-V3
DEBUG=false
```

### 4. 启动服务

```bash
# 生产环境部署
./deploy-prod.sh prod

# 或使用Docker Compose
docker-compose -f docker-compose.prod.yml up -d
```

## 🔧 方式三：GitHub Actions自动部署

### 1. 配置GitHub Secrets

在您的GitHub仓库中设置以下Secrets：

```
DOCKER_HUB_USERNAME=your_docker_username
DOCKER_HUB_TOKEN=your_docker_token
SERVER_HOST=your_server_ip
SERVER_USER=your_server_user
SERVER_SSH_KEY=your_private_ssh_key
SILICONFLOW_API_KEY=your_api_key
```

### 2. 推送代码触发部署

```bash
git push origin main
```

GitHub Actions会自动：
- 构建Docker镜像
- 推送到Docker Hub
- SSH到服务器部署最新版本

## 🌐 访问服务

部署完成后，通过以下地址访问：

- **前端页面**: `http://your-server-ip`
- **API文档**: `http://your-server-ip:8000/docs`
- **健康检查**: `http://your-server-ip:8000/health`

## 📋 管理命令

```bash
# 查看服务状态
./deploy-prod.sh status

# 查看日志
./deploy-prod.sh logs

# 重启服务
./deploy-prod.sh restart

# 停止服务
./deploy-prod.sh stop

# 更新代码并重新部署
git pull origin main
./deploy-prod.sh restart
```

## 🔒 安全配置

### 1. 防火墙配置

```bash
# Ubuntu/Debian (UFW)
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

# CentOS/RHEL (firewalld)
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
```

### 2. SSL证书（可选）

```bash
# 安装Certbot
sudo apt install certbot python3-certbot-nginx

# 获取SSL证书
sudo certbot --nginx -d your-domain.com

# 自动续期
sudo crontab -e
# 添加：0 12 * * * /usr/bin/certbot renew --quiet
```

### 3. 反向代理配置

如需要自定义域名和HTTPS，可以配置Nginx反向代理：

```nginx
server {
    listen 80;
    server_name your-domain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl;
    server_name your-domain.com;
    
    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
    
    location / {
        proxy_pass http://localhost:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    location /api/ {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## 📊 监控与维护

### 1. 系统监控

```bash
# 查看容器状态
docker ps

# 查看资源使用
docker stats

# 查看磁盘使用
df -h

# 查看内存使用
free -h
```

### 2. 日志管理

```bash
# 查看应用日志
docker-compose logs -f --tail=100

# 查看特定服务日志
docker-compose logs backend
docker-compose logs frontend

# 清理日志
docker system prune -f
```

### 3. 备份策略

```bash
# 备份数据库
docker exec novel-editor-backend-1 sqlite3 /app/novel_editor.db .dump > backup_$(date +%Y%m%d).sql

# 备份环境配置
cp .env.prod backup/.env.prod.$(date +%Y%m%d)

# 定期备份脚本
cat > backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/home/backup/novel-editor"
mkdir -p $BACKUP_DIR
docker exec novel-editor-backend-1 sqlite3 /app/novel_editor.db .dump > $BACKUP_DIR/db_$(date +%Y%m%d_%H%M%S).sql
find $BACKUP_DIR -name "db_*.sql" -mtime +7 -delete
EOF

chmod +x backup.sh
# 添加到crontab
echo "0 2 * * * /path/to/backup.sh" | crontab -
```

## 🆘 故障排除

### 常见问题及解决方案

1. **容器启动失败**
```bash
# 查看详细错误
docker-compose logs

# 重新构建容器
docker-compose build --no-cache
docker-compose up -d
```

2. **AI服务调用失败**
```bash
# 测试API连接
python test_deepseek_v3.py

# 检查API密钥配置
grep SILICONFLOW_API_KEY .env.prod
```

3. **端口被占用**
```bash
# 查看端口占用
netstat -tlnp | grep :80
netstat -tlnp | grep :8000

# 停止占用进程
sudo kill -9 <PID>
```

4. **内存不足**
```bash
# 清理Docker缓存
docker system prune -af

# 增加swap空间
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

## 📞 技术支持

- **项目文档**: [DOCKER_DEPLOYMENT.md](./DOCKER_DEPLOYMENT.md)
- **详细部署**: [DEPLOYMENT_SUMMARY.md](./DEPLOYMENT_SUMMARY.md)
- **GitHub Issues**: https://github.com/your-username/novel-editor/issues

---

**🎉 享受AI驱动的小说创作体验！**
