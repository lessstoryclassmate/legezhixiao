# 部署说明文档

## 部署方式选择

### 1. 本地克隆部署（推荐）

适用于快速部署和测试：

```bash
# 克隆项目
git clone https://github.com/your-username/ai-novel-editor.git
cd ai-novel-editor

# 配置环境变量
cp .env.example .env
# 编辑 .env 文件，填写必要配置

# 启动服务
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

### 2. 百度云服务器克隆部署

适用于生产环境：

```bash
# 在服务器上执行
curl -fsSL https://raw.githubusercontent.com/your-username/ai-novel-editor/main/scripts/github-deploy.sh | bash
```

### 3. GitHub Actions自动部署

适用于持续集成：

1. 配置GitHub Secrets：
   - `SSH_PRIVATE_KEY`: SSH私钥
   - `DEPLOY_HOST`: 服务器IP
   - `DEPLOY_USER`: 服务器用户名
   - `SILICONFLOW_API_KEY`: API密钥
   - `JWT_SECRET_KEY`: JWT密钥
   - `MONGO_PASSWORD`: MongoDB密码
   - `REDIS_PASSWORD`: Redis密码
   - `MYSQL_*`: 数据库配置

2. 推送代码到main分支自动触发部署

## 环境要求

### 最低配置
- **CPU**: 2核
- **内存**: 4GB
- **磁盘**: 20GB
- **操作系统**: Ubuntu 20.04+

### 推荐配置
- **CPU**: 4核
- **内存**: 8GB
- **磁盘**: 50GB
- **操作系统**: Ubuntu 24.04 LTS

## 服务端口

- **前端**: 80 (HTTP)
- **后端**: 8000 (API)
- **MongoDB**: 27017
- **Redis**: 6379

## 配置文件

### .env 环境变量
```env
# SiliconFlow API配置
SILICONFLOW_API_KEY=your_api_key_here

# 数据库配置
MONGO_PASSWORD=your_mongodb_password
REDIS_PASSWORD=your_redis_password

# MySQL云数据库配置
MYSQL_HOST=your_mysql_host
MYSQL_PASSWORD=your_mysql_password

# JWT配置
JWT_SECRET_KEY=your_jwt_secret_key
```

## 常用命令

### 服务管理
```bash
# 启动服务
docker-compose up -d

# 停止服务
docker-compose down

# 重启服务
docker-compose restart

# 查看状态
docker-compose ps

# 查看日志
docker-compose logs -f
```

### 更新部署
```bash
# 更新代码
git pull origin main

# 重新构建并启动
docker-compose up -d --build
```

### 备份与恢复
```bash
# 备份数据库
docker exec mongodb mongodump --out /backup

# 恢复数据库
docker exec mongodb mongorestore /backup
```

## 故障排查

### 1. 服务启动失败
```bash
# 查看容器日志
docker-compose logs

# 检查端口占用
netstat -tlnp | grep :80
netstat -tlnp | grep :8000
```

### 2. 网络连接问题
```bash
# 检查防火墙状态
sudo ufw status

# 检查Docker网络
docker network ls
```

### 3. 数据库连接问题
```bash
# 检查MongoDB连接
docker exec mongodb mongo --eval "db.runCommand('ping')"

# 检查Redis连接
docker exec redis redis-cli ping
```

## 监控与日志

### 系统监控
```bash
# 查看系统资源
htop
df -h
free -h

# 查看Docker资源使用
docker stats
```

### 日志管理
```bash
# 查看应用日志
tail -f /var/log/ai-novel-editor-deploy.log

# 查看Nginx日志
docker exec frontend tail -f /var/log/nginx/access.log
```

## 安全建议

1. **防火墙配置**：只开放必要端口
2. **SSL证书**：生产环境使用HTTPS
3. **定期备份**：设置自动备份任务
4. **监控告警**：配置服务监控和告警
5. **定期更新**：保持系统和依赖更新

## 扩展配置

### 反向代理（可选）
如需使用Nginx作为反向代理：

```nginx
server {
    listen 80;
    server_name your-domain.com;
    
    location / {
        proxy_pass http://localhost:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    
    location /api {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### SSL证书配置
```bash
# 安装Certbot
sudo apt install certbot python3-certbot-nginx

# 获取SSL证书
sudo certbot --nginx -d your-domain.com
```
