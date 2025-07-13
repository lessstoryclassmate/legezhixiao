# GitHub Actions 自动部署配置指南

## 概述

GitHub Actions 是 GitHub 提供的持续集成/持续部署(CI/CD)平台，可以自动化构建、测试和部署流程。本项目配置了完整的自动部署流水线，当您推送代码到主分支时，会自动部署到百度云服务器。

## 部署流程图

```mermaid
graph LR
    A[推送代码到main分支] --> B[触发GitHub Actions]
    B --> C[检出代码]
    C --> D[设置SSH连接]
    D --> E[连接服务器]
    E --> F[克隆/更新代码]
    F --> G[配置环境变量]
    G --> H[执行部署脚本]
    H --> I[健康检查]
    I --> J[部署完成]
```

## 配置步骤

### 1. 设置GitHub Secrets

在您的GitHub仓库中配置以下Secrets：

#### 进入仓库设置
1. 打开GitHub仓库
2. 点击 `Settings` 选项卡
3. 在左侧菜单中选择 `Secrets and variables` > `Actions`
4. 点击 `New repository secret`

#### 必需的Secrets配置

| Secret名称 | 描述 | 示例值 |
|-----------|------|--------|
| `SSH_PRIVATE_KEY` | SSH私钥 | `-----BEGIN OPENSSH PRIVATE KEY-----...` |
| `DEPLOY_HOST` | 服务器IP地址 | `123.456.789.123` |
| `DEPLOY_USER` | 服务器用户名 | `ubuntu` |
| `SILICONFLOW_API_KEY` | SiliconFlow API密钥 | `sk-xxxxxxxxxxxxxxxx` |
| `JWT_SECRET_KEY` | JWT加密密钥 | `your-super-secret-jwt-key` |
| `MONGO_PASSWORD` | MongoDB密码 | `your-mongodb-password` |
| `REDIS_PASSWORD` | Redis密码 | `your-redis-password` |
| `MYSQL_HOST` | MySQL主机地址 | `your-mysql-host.com` |
| `MYSQL_USER` | MySQL用户名 | `your-mysql-user` |
| `MYSQL_PASSWORD` | MySQL密码 | `your-mysql-password` |

### 2. 生成SSH密钥对

在本地生成SSH密钥对：

```bash
# 生成SSH密钥对
ssh-keygen -t ed25519 -C "your-email@example.com" -f ~/.ssh/deploy_key

# 查看私钥内容（复制到GitHub Secrets）
cat ~/.ssh/deploy_key

# 查看公钥内容（添加到服务器）
cat ~/.ssh/deploy_key.pub
```

### 3. 配置服务器SSH

将公钥添加到服务器：

```bash
# 连接到服务器
ssh ubuntu@your-server-ip

# 添加公钥到authorized_keys
echo "your-public-key-content" >> ~/.ssh/authorized_keys

# 设置正确的权限
chmod 600 ~/.ssh/authorized_keys
chmod 700 ~/.ssh
```

### 4. 测试SSH连接

```bash
# 使用私钥测试连接
ssh -i ~/.ssh/deploy_key ubuntu@your-server-ip
```

## 工作流程文件详解

### 触发条件

```yaml
on:
  push:
    branches: [ main ]    # 推送到main分支时触发
  pull_request:
    branches: [ main ]    # 创建PR到main分支时触发
```

### 主要步骤

#### 1. 检出代码
```yaml
- name: Checkout code
  uses: actions/checkout@v4
```

#### 2. 设置SSH连接
```yaml
- name: Setup SSH
  uses: webfactory/ssh-agent@v0.8.0
  with:
    ssh-private-key: ${{ secrets.SSH_PRIVATE_KEY }}
```

#### 3. 部署到服务器
```yaml
- name: Deploy to server
  env:
    DEPLOY_HOST: ${{ secrets.DEPLOY_HOST }}
    # ... 其他环境变量
  run: |
    ssh ${{ secrets.DEPLOY_USER }}@${{ secrets.DEPLOY_HOST }} '
      # 部署命令
    '
```

#### 4. 健康检查
```yaml
- name: Health Check
  run: |
    sleep 30
    curl -f http://${{ secrets.DEPLOY_HOST }}:80 || exit 1
    curl -f http://${{ secrets.DEPLOY_HOST }}:8000/health || exit 1
```

## 部署流程

### 自动部署触发

当您推送代码到main分支时：

```bash
# 提交代码
git add .
git commit -m "feat: 添加新功能"
git push origin main
```

### 部署监控

1. **查看部署状态**
   - 在GitHub仓库中点击 `Actions` 选项卡
   - 查看最新的workflow运行状态

2. **查看部署日志**
   - 点击具体的workflow运行记录
   - 查看每个步骤的详细日志

3. **部署失败处理**
   - 检查错误日志
   - 修复问题后重新推送代码
   - 或手动重新运行workflow

## 服务器端自动化

### 部署脚本执行

服务器端会自动执行以下操作：

```bash
# 1. 创建项目目录
PROJECT_DIR="/opt/ai-novel-editor"
sudo mkdir -p $PROJECT_DIR
sudo chown $USER:$USER $PROJECT_DIR

# 2. 克隆或更新代码
if [ -d ".git" ]; then
    git pull origin main
else
    git clone https://github.com/your-username/ai-novel-editor.git .
fi

# 3. 配置环境变量
cat > .env << EOF
SILICONFLOW_API_KEY=${{ secrets.SILICONFLOW_API_KEY }}
JWT_SECRET_KEY=${{ secrets.JWT_SECRET_KEY }}
# ... 其他环境变量
EOF

# 4. 执行部署脚本
chmod +x scripts/deploy.sh
./scripts/deploy.sh

# 5. 检查服务状态
docker-compose ps
```

### 零停机部署

部署过程中会：
1. 先构建新的容器镜像
2. 启动新容器
3. 健康检查通过后停止旧容器
4. 实现服务的平滑切换

## 环境变量管理

### 开发环境 vs 生产环境

```yaml
# 开发环境配置
CORS_ORIGINS=http://localhost:3000,http://localhost:80

# 生产环境配置（自动设置）
CORS_ORIGINS=https://your-domain.com
```

### 敏感信息安全

- 所有敏感信息都存储在GitHub Secrets中
- 不会在日志中显示敏感信息
- 使用加密传输和存储

## 监控和告警

### 健康检查

自动检查服务状态：

```bash
# 检查前端服务
curl -f http://your-server:80

# 检查后端API
curl -f http://your-server:8000/health

# 检查数据库连接
curl -f http://your-server:8000/health | jq '.services'
```

### 部署通知

可以配置Slack、钉钉等通知：

```yaml
- name: Notify deployment
  if: always()
  run: |
    if [ "${{ job.status }}" == "success" ]; then
      echo "✅ 部署成功"
    else
      echo "❌ 部署失败"
    fi
```

## 常见问题解决

### 1. SSH连接失败

**问题**: `Permission denied (publickey)`

**解决方案**:
```bash
# 检查SSH密钥格式
ssh-keygen -t ed25519 -C "deploy@github-actions"

# 确保服务器SSH配置正确
sudo nano /etc/ssh/sshd_config
# 设置: PubkeyAuthentication yes
如需重启 SSH 服务请参考系统文档，所有业务服务推荐用 Docker Compose 管理。
```

### 2. 部署超时

**问题**: 部署过程中超时

**解决方案**:
```yaml
- name: Deploy to server
  timeout-minutes: 30  # 设置超时时间
```

### 3. 容器启动失败

**问题**: Docker容器无法启动

**解决方案**:
```bash
# 检查容器日志
docker-compose logs

# 检查磁盘空间
df -h

# 清理Docker缓存
docker system prune -f
```

### 4. 环境变量缺失

**问题**: 应用启动时环境变量未设置

**解决方案**:
1. 检查GitHub Secrets配置
2. 确保变量名称正确
3. 重新运行workflow

## 高级配置

### 多环境部署

```yaml
strategy:
  matrix:
    environment: [staging, production]
    
steps:
  - name: Deploy to ${{ matrix.environment }}
    env:
      DEPLOY_HOST: ${{ secrets[format('DEPLOY_HOST_{0}', matrix.environment)] }}
```

### 条件部署

```yaml
- name: Deploy to production
  if: github.ref == 'refs/heads/main' && github.event_name == 'push'
```

### 回滚机制

```yaml
- name: Rollback on failure
  if: failure()
  run: |
    ssh ${{ secrets.DEPLOY_USER }}@${{ secrets.DEPLOY_HOST }} '
      cd /opt/ai-novel-editor
      git checkout HEAD~1
      ./scripts/deploy.sh
    '
```

## 最佳实践

1. **分支策略**: 使用main分支进行生产部署
2. **版本标签**: 为重要版本打标签
3. **测试集成**: 在部署前运行自动化测试
4. **备份策略**: 部署前自动备份数据
5. **监控告警**: 配置部署状态通知
6. **文档更新**: 保持部署文档的及时更新

通过这套完整的CI/CD流程，您可以实现：
- 🚀 **自动化部署**: 推送代码即可自动部署
- 🔒 **安全可靠**: 使用SSH密钥和加密传输
- 📊 **状态监控**: 实时查看部署状态和日志
- 🔄 **零停机**: 平滑的服务更新切换
- 🛡️ **故障恢复**: 自动健康检查和回滚机制
