# GitHub Actions 自动部署配置说明

## 🎯 概述

您的项目已配置了完整的GitHub Actions自动部署流水线，支持代码推送后自动构建、测试、部署到云服务器。

## 🔧 已配置的工作流

### 1. 主要工作流文件

- **`.github/workflows/cloud-deploy.yml`** - 云服务器自动部署
- **`.github/workflows/ci-cd.yml`** - 完整的CI/CD流水线  
- **`.github/workflows/docker-build.yml`** - Docker镜像构建

### 2. 部署触发条件

- ✅ **自动触发**: 推送到`main`分支时自动部署
- ✅ **手动触发**: 在GitHub Actions页面手动执行
- ✅ **文件变更**: 检测关键文件变更后才执行部署

## 📋 必需的GitHub Secrets

### 🔐 AI服务配置
```
SILICONFLOW_API_KEY=sk-your-api-key-here
```

### 🖥️ 云服务器配置  
```
SERVER_HOST=your-server-ip
SERVER_USER=your-ssh-username
SERVER_SSH_KEY=your-private-ssh-key
SERVER_PORT=22
```

### 🐳 Docker配置 (可选)
```
DOCKER_HUB_USERNAME=your-docker-username
DOCKER_HUB_TOKEN=your-docker-access-token
```

### 🔑 应用配置
```
SECRET_KEY=your-app-secret-key
DATABASE_URL=sqlite:///./novel_editor.db
```

### 📧 通知配置 (可选)
```
NOTIFICATION_EMAIL=your-email@example.com
SLACK_WEBHOOK=your-slack-webhook-url
```

## 🚀 自动部署流程

### 1. 代码推送触发
```bash
git add .
git commit -m "feat: 添加新功能"
git push origin main
```

### 2. GitHub Actions执行流程
1. **🔍 代码检出** - 获取最新代码
2. **🧪 质量检查** - 运行测试和代码检查
3. **🐳 构建镜像** - 构建Docker镜像
4. **📤 推送镜像** - 推送到镜像仓库
5. **🚀 部署服务** - SSH连接服务器执行部署
6. **✅ 健康检查** - 验证服务是否正常运行
7. **📧 通知结果** - 发送部署结果通知

### 3. 部署后验证
- 自动健康检查: `http://your-server:8000/health`
- 前端访问: `http://your-server`
- API文档: `http://your-server:8000/docs`

## 🔍 手动部署

### 在GitHub页面手动触发

1. 进入您的GitHub仓库
2. 点击 **Actions** 选项卡
3. 选择 **Cloud Server Deployment** 工作流
4. 点击 **Run workflow** 
5. 选择目标服务器环境
6. 点击 **Run workflow** 开始部署

### 使用curl触发 (需要配置token)

```bash
curl -X POST \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token YOUR_GITHUB_TOKEN" \
  https://api.github.com/repos/YOUR_USERNAME/novel-editor/actions/workflows/cloud-deploy.yml/dispatches \
  -d '{"ref":"main","inputs":{"target_server":"production"}}'
```

## 📊 监控部署状态

### 1. GitHub Actions界面
- 实时查看部署日志
- 检查每个步骤的执行状态
- 下载部署文件和日志

### 2. 服务器端监控
```bash
# 查看容器状态
docker-compose -f docker-compose.prod.yml ps

# 查看服务日志  
docker-compose -f docker-compose.prod.yml logs -f

# 检查健康状态
curl http://localhost:8000/health
```

### 3. 自动通知
- 邮件通知部署结果
- Slack消息 (如已配置)
- GitHub Actions状态徽章

## 🛠️ 故障排除

### 常见问题及解决方案

#### 1. SSH连接失败
```bash
# 检查SSH密钥格式
cat ~/.ssh/id_rsa

# 确保私钥已添加到GitHub Secrets
# 格式: -----BEGIN OPENSSH PRIVATE KEY-----
```

#### 2. 环境变量缺失
- 检查GitHub仓库 Settings > Secrets and variables > Actions
- 确保所有必需的secrets已配置
- 验证API密钥格式正确

#### 3. 镜像构建失败
```bash
# 检查Dockerfile语法
docker build -t test-image ./backend
docker build -t test-image ./frontend
```

#### 4. 服务启动失败
```bash
# 服务器端调试
docker-compose -f docker-compose.prod.yml logs backend
docker-compose -f docker-compose.prod.yml logs frontend

# 检查端口占用
netstat -tlnp | grep :80
netstat -tlnp | grep :8000
```

## 📈 部署优化建议

### 1. 生产环境优化
- 配置SSL证书 (Let's Encrypt)
- 设置域名和DNS
- 配置防火墙规则
- 启用日志轮转

### 2. 监控告警
- 添加服务监控 (Prometheus + Grafana)
- 配置告警规则
- 设置性能指标收集

### 3. 备份策略
- 数据库定期备份
- 配置文件版本控制
- 镜像版本管理

## 🎉 部署成功示例

成功部署后，您将看到类似输出：

```
🚀 开始部署AI小说编辑器...
⏹️ 停止现有服务...
🧹 清理Docker资源...
📥 拉取最新镜像...
🚀 启动服务...
⏳ 等待服务启动...
✅ 后端服务健康检查通过
✅ 前端服务健康检查通过
🎉 部署完成！

📊 服务状态:
NAME                     STATUS    PORTS
novel-editor-backend     Up        0.0.0.0:8000->8000/tcp
novel-editor-frontend    Up        0.0.0.0:80->80/tcp
```

## 📞 获取帮助

- **查看部署日志**: GitHub Actions > 选择具体运行 > 查看详细日志
- **检查服务状态**: SSH到服务器执行 `./deploy-prod.sh status`
- **重启服务**: SSH到服务器执行 `./deploy-prod.sh restart`

---

**🎉 现在您的AI小说编辑器支持完全自动化的云部署！**

只需推送代码到GitHub，其余的交给自动化流水线处理！
