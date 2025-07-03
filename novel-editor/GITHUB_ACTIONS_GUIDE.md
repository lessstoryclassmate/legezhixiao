# GitHub Actions 自动部署使用指南

## 🎯 概述

本项目提供了三种GitHub Actions自动部署方案，满足不同用户的需求：

1. **云服务器部署** - 自动部署到您的云服务器
2. **Docker Hub部署** - 构建镜像并发布到Docker Hub
3. **完整CI/CD流水线** - 包含测试、安全扫描、多环境部署

## 🚀 快速开始

### 方案一：Docker Hub自动部署（推荐入门用户）

适合：没有云服务器，希望构建Docker镜像供他人使用

#### 1. 配置Docker Hub

```bash
# 1. 在GitHub仓库设置中添加Secrets:
# Settings > Secrets and variables > Actions > New repository secret

DOCKER_HUB_USERNAME=your_docker_username
DOCKER_HUB_TOKEN=your_docker_access_token
```

#### 2. 推送代码触发构建

```bash
git push origin main
```

#### 3. 使用构建的镜像

构建完成后，任何人都可以使用：

```bash
# 下载部署配置
curl -O https://raw.githubusercontent.com/your-username/novel-editor/main/docker-compose.dockerhub.yml

# 配置环境变量
echo "SILICONFLOW_API_KEY=your_api_key" > .env

# 启动服务
docker-compose -f docker-compose.dockerhub.yml up -d
```

### 方案二：云服务器自动部署

适合：有云服务器，希望自动部署到生产环境

#### 1. 运行配置脚本

```bash
chmod +x setup-github-actions-deploy.sh
./setup-github-actions-deploy.sh
```

脚本会引导您配置：
- SiliconFlow API密钥
- 服务器SSH连接信息
- 通知设置（可选）

#### 2. 自动部署

推送到main分支会自动触发部署：

```bash
git push origin main
```

或手动触发：

```bash
gh workflow run cloud-deploy.yml
```

#### 3. 查看部署状态

```bash
# 查看运行历史
gh run list --workflow=cloud-deploy.yml

# 查看详细日志
gh run view --log
```

## 📋 必需的GitHub Secrets

### 基础配置

| Secret名称 | 描述 | 必需 |
|-----------|------|------|
| `SILICONFLOW_API_KEY` | SiliconFlow API密钥 | ✅ |
| `SECRET_KEY` | 应用密钥（可自动生成） | ✅ |

### Docker Hub部署

| Secret名称 | 描述 | 必需 |
|-----------|------|------|
| `DOCKER_HUB_USERNAME` | Docker Hub用户名 | ✅ |
| `DOCKER_HUB_TOKEN` | Docker Hub访问令牌 | ✅ |

### 云服务器部署

| Secret名称 | 描述 | 必需 |
|-----------|------|------|
| `STAGING_HOST` | 预发布服务器地址 | 可选 |
| `STAGING_USER` | 预发布服务器用户名 | 可选 |
| `STAGING_SSH_KEY` | 预发布服务器SSH私钥 | 可选 |
| `PRODUCTION_HOST` | 生产服务器地址 | ✅ |
| `PRODUCTION_USER` | 生产服务器用户名 | ✅ |
| `PRODUCTION_SSH_KEY` | 生产服务器SSH私钥 | ✅ |

### 可选通知配置

| Secret名称 | 描述 | 必需 |
|-----------|------|------|
| `SLACK_WEBHOOK` | Slack Webhook URL | 可选 |
| `SMTP_SERVER` | 邮件服务器地址 | 可选 |
| `SMTP_USERNAME` | 邮件用户名 | 可选 |
| `SMTP_PASSWORD` | 邮件密码 | 可选 |
| `NOTIFICATION_EMAIL` | 通知邮箱 | 可选 |

## 🔧 工作流详解

### 1. Docker Hub部署流程

```
触发 → 构建镜像 → 推送到Docker Hub → 创建Release → 通知
```

**文件**: `.github/workflows/docker-hub-deploy.yml`

**特点**:
- ✅ 多架构支持 (AMD64/ARM64)
- ✅ 自动版本标签
- ✅ Release发布
- ✅ 缓存优化

### 2. 云服务器部署流程

```
触发 → 构建镜像 → 推送到Registry → 部署到预发布 → 部署到生产 → 健康检查 → 通知
```

**文件**: `.github/workflows/cloud-deploy.yml`

**特点**:
- ✅ 多环境支持
- ✅ 滚动部署
- ✅ 自动备份
- ✅ 健康检查
- ✅ 失败回滚

### 3. 完整CI/CD流程

```
触发 → 代码检查 → 安全扫描 → 构建镜像 → 部署测试 → 部署生产 → 通知
```

**文件**: `.github/workflows/ci-cd.yml`

**特点**:
- ✅ 代码质量检查
- ✅ 安全漏洞扫描
- ✅ 多版本测试
- ✅ 覆盖率报告

## 🎛️ 手动触发部署

### 1. 使用GitHub Web界面

1. 进入仓库的 Actions 标签
2. 选择对应的工作流
3. 点击 "Run workflow"
4. 选择参数并运行

### 2. 使用GitHub CLI

```bash
# 基础触发
gh workflow run cloud-deploy.yml

# 指定目标服务器
gh workflow run cloud-deploy.yml -f target_server=staging
gh workflow run cloud-deploy.yml -f target_server=production

# 查看运行状态
gh run list --workflow=cloud-deploy.yml

# 查看详细日志
gh run view <run_id> --log
```

### 3. 使用REST API

```bash
# 触发部署
curl -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/owner/repo/actions/workflows/cloud-deploy.yml/dispatches \
  -d '{"ref":"main","inputs":{"target_server":"production"}}'
```

## 📊 监控与日志

### 1. 实时监控

```bash
# 查看当前运行的工作流
gh run list --status=in_progress

# 实时查看日志
gh run view --log --refresh
```

### 2. 部署后检查

```bash
# 检查服务状态（在服务器上）
docker-compose -f docker-compose.deploy.yml ps

# 查看服务日志
docker-compose -f docker-compose.deploy.yml logs -f --tail=100

# 健康检查
curl http://localhost:8000/health
```

### 3. 故障排除

```bash
# 查看失败的工作流
gh run list --status=failure

# 下载运行日志
gh run download <run_id>

# 重新运行失败的作业
gh run rerun <run_id>
```

## 🔒 安全最佳实践

### 1. Secrets管理

- ✅ 使用强密码和密钥
- ✅ 定期轮换API密钥
- ✅ 限制SSH密钥权限
- ✅ 使用环境保护规则

### 2. 服务器安全

- ✅ 启用防火墙
- ✅ 定期更新系统
- ✅ 使用非root用户
- ✅ 配置SSH密钥认证

### 3. 部署安全

- ✅ 使用HTTPS
- ✅ 配置SSL证书
- ✅ 设置访问控制
- ✅ 监控异常活动

## 🚨 故障排除

### 常见问题

1. **构建失败**
   ```bash
   # 检查依赖项
   # 查看构建日志
   # 验证Dockerfile语法
   ```

2. **部署失败**
   ```bash
   # 检查服务器连接
   # 验证SSH密钥
   # 检查服务器资源
   ```

3. **服务启动失败**
   ```bash
   # 检查环境变量
   # 查看容器日志
   # 验证网络配置
   ```

### 紧急回滚

```bash
# 在服务器上快速回滚
cd ~/novel-editor-deploy
docker-compose -f docker-compose.deploy.yml down
cp docker-compose.deploy.yml.backup.* docker-compose.deploy.yml
docker-compose -f docker-compose.deploy.yml up -d
```

## 📚 相关资源

- [GitHub Actions文档](https://docs.github.com/en/actions)
- [Docker Hub文档](https://docs.docker.com/docker-hub/)
- [SSH密钥生成指南](https://docs.github.com/en/authentication/connecting-to-github-with-ssh)
- [SiliconFlow API文档](https://docs.siliconflow.cn/)

## 🆘 获取帮助

1. **查看文档**: 项目根目录的相关MD文件
2. **GitHub Issues**: 提交问题和建议
3. **运行日志**: 包含详细的错误信息
4. **社区支持**: GitHub Discussions

---

**🎉 享受自动化部署的便利！**
