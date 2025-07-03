# GitHub Actions 部署指南

本文档详细介绍如何配置和使用GitHub Actions进行AI小说编辑器的CI/CD部署。

## 📋 概述

我们的GitHub Actions工作流包括：

- **CI/CD Pipeline** (`ci-cd.yml`) - 主要的持续集成和部署流水线
- **Docker Build** (`docker-build.yml`) - Docker镜像构建和发布
- **Dependency Updates** (`dependency-updates.yml`) - 自动依赖更新
- **Code Quality** (`code-quality.yml`) - 代码质量检查
- **K8S Deployment** (`k8s-deploy.yml`) - Kubernetes部署
- **Monitoring** (`monitoring.yml`) - 监控和告警

## 🔧 必需的Secrets配置

在GitHub仓库的Settings > Secrets and variables > Actions中配置以下secrets：

### 基础配置
```
GITHUB_TOKEN            # GitHub提供，用于访问仓库
```

### 应用密钥
```
SECRET_KEY              # 应用密钥，用于JWT等加密
SILICONFLOW_API_KEY     # SiliconFlow API密钥
MYSQL_ROOT_PASSWORD     # MySQL root密码
```

### Kubernetes配置
```
KUBE_CONFIG_DEV         # 开发环境K8S配置文件(base64编码)
KUBE_CONFIG_PROD        # 生产环境K8S配置文件(base64编码)
```

### 通知配置 (可选)
```
SLACK_WEBHOOK           # Slack通知webhook URL
SONAR_TOKEN            # SonarQube分析token
```

## 🚀 工作流详解

### 1. CI/CD Pipeline (ci-cd.yml)

**触发条件：**
- push到main或develop分支
- 向main分支提交PR
- 手动触发

**主要步骤：**

#### 代码质量检查 (lint-and-test)
- 多版本Node.js和Python测试
- 前端：yarn lint, 类型检查, 单元测试, 构建测试
- 后端：black格式检查, flake8代码检查, mypy类型检查, pytest单元测试
- 测试覆盖率上传到Codecov

#### 安全扫描 (security-scan)
- Trivy漏洞扫描
- SARIF格式报告上传

#### Docker构建 (build-and-push)
- 构建多架构Docker镜像 (amd64, arm64)
- 推送到GitHub Container Registry
- 只在main和develop分支触发

#### 部署 (deploy-dev/deploy-prod)
- develop分支自动部署到开发环境
- main分支自动部署到生产环境
- 部署健康检查和验证

### 2. Docker Build (docker-build.yml)

**触发条件：**
- 推送版本标签 (v*)
- 手动触发

**功能：**
- 构建带版本标签的Docker镜像
- 自动创建GitHub Release
- 包含部署清单文件

### 3. Dependency Updates (dependency-updates.yml)

**触发条件：**
- 每周一凌晨2点自动运行
- 手动触发

**功能：**
- 自动更新前端和后端依赖
- 运行测试验证更新
- 自动创建PR
- 安全审计报告

### 4. Code Quality (code-quality.yml)

**触发条件：**
- push到main或develop分支
- 向main分支提交PR

**功能：**
- ESLint/Prettier/TypeScript检查
- Black/Flake8/MyPy/Bandit检查
- SonarQube代码分析
- Lighthouse性能测试
- Artillery负载测试

### 5. K8S Deployment (k8s-deploy.yml)

**功能：**
- 可重用的Kubernetes部署工作流
- 支持多环境配置
- 自动ConfigMap和Secret管理
- 健康检查和回滚机制

### 6. Monitoring (monitoring.yml)

**触发条件：**
- 每15分钟自动运行
- 手动触发

**功能：**
- 健康检查 (多环境)
- 性能监控 (响应时间)
- 资源监控 (CPU/内存使用)
- Slack告警通知

## ⚙️ 环境配置

### 开发环境 (development)
- 命名空间：`development`
- 副本数：1
- 资源限制：较低
- 自动部署：develop分支

### 生产环境 (production)
- 命名空间：`production`
- 副本数：3
- 资源限制：较高
- 自动部署：main分支
- 严格的健康检查

## 🔒 安全最佳实践

1. **密钥管理**
   - 使用GitHub Secrets存储敏感信息
   - K8S Secret分离敏感配置
   - 定期轮换API密钥

2. **镜像安全**
   - Trivy漏洞扫描
   - 多架构镜像支持
   - 镜像签名 (可选)

3. **访问控制**
   - 环境保护规则
   - 审批流程 (生产环境)
   - RBAC权限控制

## 📊 监控和告警

### 健康检查
- HTTP状态码检查
- 响应时间监控
- 资源使用监控

### 告警策略
- 服务不可用立即告警
- 性能降级警告
- 资源使用过高告警

### 通知渠道
- Slack集成
- 邮件通知 (可配置)
- GitHub Issues自动创建

## 🚀 部署流程

### 自动部署
1. 开发者推送代码到develop/main分支
2. 自动触发CI/CD流水线
3. 代码质量检查和测试
4. Docker镜像构建和推送
5. 自动部署到对应环境
6. 健康检查和验证
7. 通知部署结果

### 手动部署
1. 在Actions页面选择相应工作流
2. 点击"Run workflow"
3. 选择分支和参数
4. 监控部署进度
5. 验证部署结果

### 回滚流程
1. 检测到部署失败自动回滚
2. 手动回滚到指定版本
3. 紧急情况下的快速回滚

## 🔧 故障排查

### 常见问题

1. **镜像拉取失败**
   - 检查GitHub Container Registry权限
   - 验证镜像标签正确性

2. **Kubernetes连接失败**
   - 验证KUBE_CONFIG配置
   - 检查集群网络连接

3. **部署超时**
   - 检查资源配额
   - 验证镜像大小和拉取速度

4. **健康检查失败**
   - 检查应用启动时间
   - 验证健康检查端点

### 调试技巧

1. **查看日志**
   ```bash
   kubectl logs -f deployment/novel-editor-backend -n production
   ```

2. **检查事件**
   ```bash
   kubectl get events -n production --sort-by='.lastTimestamp'
   ```

3. **资源状态**
   ```bash
   kubectl describe pod <pod-name> -n production
   ```

## 📝 版本发布

### 语义化版本
- `v1.0.0` - 主要版本
- `v1.1.0` - 功能版本  
- `v1.1.1` - 修复版本

### 发布流程
1. 更新版本号和CHANGELOG
2. 创建并推送版本标签
3. 自动构建发布镜像
4. 创建GitHub Release
5. 生产环境部署验证

## 🤝 贡献指南

1. Fork项目并创建功能分支
2. 提交代码前运行本地测试
3. 确保CI/CD流水线通过
4. 创建PR并等待审核
5. 合并后自动部署

## 📞 支持联系

如有问题，请：
1. 查看GitHub Actions运行日志
2. 检查本文档的故障排查部分
3. 创建Issue描述问题
4. 联系运维团队

---

**注意：** 首次配置需要系统管理员设置Kubernetes集群和相关Secrets。
