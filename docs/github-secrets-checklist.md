# GitHub Secrets 配置清单

## 必须配置的 Secrets

### 服务器连接配置
- [ ] `SSH_PRIVATE_KEY` - SSH私钥（用于连接服务器）
- [ ] `DEPLOY_HOST` - 服务器IP地址
- [ ] `DEPLOY_USER` - 服务器用户名（通常是 ubuntu）

### 应用配置
- [ ] `SILICONFLOW_API_KEY` - SiliconFlow API密钥
- [ ] `JWT_SECRET_KEY` - JWT加密密钥（建议使用强密码）

### 数据库配置
- [ ] `MONGO_PASSWORD` - MongoDB密码
- [ ] `REDIS_PASSWORD` - Redis密码
- [ ] `MYSQL_HOST` - MySQL主机地址
- [ ] `MYSQL_USER` - MySQL用户名
- [ ] `MYSQL_PASSWORD` - MySQL密码

## 快速配置指南

### 1. 生成SSH密钥对
```bash
# 运行配置脚本
./scripts/setup-github-actions.sh
```

### 2. 配置GitHub Secrets
1. 进入GitHub仓库
2. 点击 Settings > Secrets and variables > Actions
3. 点击 "New repository secret"
4. 添加上述所有secrets

### 3. 配置服务器
```bash
# 在服务器上执行
echo "your-public-key" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

### 4. 测试部署
```bash
# 推送代码触发部署
git push origin main
```

## 部署流程说明

### 自动触发条件
- 推送代码到 `main` 分支 → 生产环境部署
- 推送代码到 `develop` 分支 → 开发环境部署
- 创建 Pull Request 到 `main` 分支 → 代码检查
- 手动触发 → 支持手动部署

### 部署阶段
1. **代码质量检查** - Python和前端代码检查
2. **构建测试** - Docker镜像构建和基础测试
3. **生产部署** - 部署到生产服务器
4. **健康检查** - 验证服务正常运行
5. **失败回滚** - 自动回滚到上一个版本

### 安全特性
- SSH密钥认证
- 环境变量加密存储
- 自动备份机制
- 失败自动回滚

## 监控和维护

### 查看部署状态
1. 进入GitHub仓库
2. 点击 Actions 选项卡
3. 查看最新的workflow运行记录

### 手动触发部署
1. 进入 Actions 选项卡
2. 选择 "Deploy AI Novel Editor" workflow
3. 点击 "Run workflow"

### 部署失败处理
1. 查看失败的步骤日志
2. 修复问题后重新推送代码
3. 或者手动重新运行失败的workflow

## 高级配置选项

### 多环境部署
- 生产环境：`main` 分支
- 开发环境：`develop` 分支
- 测试环境：可配置 `test` 分支

### 自定义通知
可以添加Slack、钉钉等通知集成

### 定时部署
可以配置定时任务自动部署

### 蓝绿部署
支持零停机部署策略
