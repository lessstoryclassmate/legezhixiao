# 本地部署模式说明

## 概述

为了解决Docker镜像下载失败的问题，项目新增了本地部署模式。该模式避免了对Docker镜像源的依赖，使用系统包管理器和本地构建方式进行部署。

## 部署模式

### 1. 自动模式（推荐）
```bash
# 运行quick-deploy.sh，自动检测并选择最佳部署模式
bash scripts/quick-deploy.sh
```

### 2. 强制本地模式
```bash
# 强制使用本地部署模式
FORCE_LOCAL_DEPLOY=true bash scripts/quick-deploy.sh
```

### 3. 直接本地部署
```bash
# 直接运行本地部署脚本
bash scripts/local-deploy.sh
```

## 本地部署特点

### 优势
- ✅ 无需Docker镜像源依赖
- ✅ 使用系统包管理器，稳定可靠
- ✅ 支持百度云DNS优化网络
- ✅ 完善的服务监控和日志
- ✅ 快速启动和轻量级部署

### 技术栈
- **后端**: Python虚拟环境 + Supervisor管理
- **前端**: Node.js构建 + Nginx代理
- **数据库**: 外部MySQL和MongoDB
- **缓存**: 外部Redis
- **DNS**: 百度云DNS优先

## 服务架构

```
Internet → Nginx:80 → Frontend (静态文件)
                   └→ Backend API (Supervisor管理的Python进程)
```

## 部署流程

1. **环境准备**: 安装Python3, Node.js, Nginx, Supervisor
2. **DNS配置**: 设置百度云DNS优化网络连接
3. **项目克隆**: 使用SSH方式克隆项目代码
4. **后端部署**: 创建虚拟环境，安装依赖，配置服务
5. **前端部署**: 使用npm构建，部署到Nginx
6. **服务启动**: 启动Supervisor和Nginx
7. **健康检查**: 验证服务运行状态

## 服务管理

### 查看服务状态
```bash
sudo supervisorctl status
sudo systemctl status nginx
```

### 重启服务
```bash
sudo supervisorctl restart ai-novel-backend
sudo systemctl restart nginx
```

### 查看日志
```bash
sudo supervisorctl tail ai-novel-backend
tail -f /var/log/ai-novel-backend.log
```

### 更新代码
```bash
cd /opt/ai-novel-editor
git pull origin main
bash scripts/local-deploy.sh
```

## 健康检查

### 自动健康检查
```bash
bash scripts/health-check.sh
```

### 手动检查
```bash
# 检查前端
curl http://localhost:80

# 检查后端API
curl http://localhost:8000/health

# 检查端口监听
netstat -tlnp | grep -E ':80|:8000'
```

## 故障排除

### 1. 后端服务启动失败
```bash
# 查看详细日志
sudo supervisorctl tail ai-novel-backend

# 检查Python环境
cd /opt/ai-novel-editor/backend
source venv/bin/activate
python -c "import main"
```

### 2. 前端访问失败
```bash
# 检查Nginx状态
sudo systemctl status nginx

# 检查Nginx配置
sudo nginx -t

# 查看Nginx日志
sudo tail -f /var/log/nginx/error.log
```

### 3. 端口占用
```bash
# 查看端口占用
sudo lsof -i :80
sudo lsof -i :8000

# 杀死占用进程
sudo kill -9 <PID>
```

## 环境变量

### 关键环境变量
- `FORCE_LOCAL_DEPLOY=true`: 强制本地部署模式
- `DEPLOY_DIR`: 部署目录（默认: /opt/ai-novel-editor）
- `FRONTEND_PORT`: 前端端口（默认: 80）
- `BACKEND_PORT`: 后端端口（默认: 8000）

### 数据库连接
- `MONGODB_URL`: MongoDB连接字符串
- `DATABASE_SYSTEM_URL`: 系统数据库连接
- `DATABASE_NOVEL_URL`: 小说数据库连接
- `REDIS_URL`: Redis连接字符串

## 性能优化

### 1. 使用国内镜像源
- Python包: 清华大学源
- Node.js包: 淘宝镜像
- APT包: 默认源

### 2. DNS优化
- 主DNS: 180.76.76.76 (百度云)
- 备用DNS: 223.5.5.5 (阿里云)
- 备用DNS: 8.8.8.8 (Google)

### 3. 服务优化
- Supervisor: 自动重启和监控
- Nginx: 静态文件缓存
- Python: 虚拟环境隔离

## 监控和日志

### 系统监控
- CPU使用率监控
- 内存使用率监控
- 磁盘空间监控
- 网络连接监控

### 日志管理
- 后端日志: /var/log/ai-novel-backend.log
- Nginx日志: /var/log/nginx/
- 系统日志: /var/log/syslog

## 安全考虑

### 1. 服务隔离
- 使用虚拟环境隔离Python依赖
- Nginx反向代理保护后端
- 防火墙规则限制端口访问

### 2. 权限控制
- 使用非root用户运行服务
- 文件权限最小化原则
- SSH密钥安全管理

### 3. 数据安全
- 环境变量加密存储
- 数据库连接加密
- API访问令牌管理

## 总结

本地部署模式提供了一个稳定、可靠的部署方案，避免了Docker镜像源的依赖问题。通过使用系统包管理器和本地构建方式，确保了部署的成功率和系统的稳定性。
