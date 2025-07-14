# 🧹 部署文件清理计划

## 📋 清理目标

根据项目分析，以下文件存在重复、过时或不再需要的情况，建议清理：

## 🔄 GitHub Actions工作流

### 保留文件
- ✅ `.github/workflows/deploy-advanced.yml` - 最完整的高级部署流程

### 删除文件
- ❌ `.github/workflows/deploy.yml` - 过于复杂，存在冗余
- ❌ `.github/workflows/deploy-fixed.yml` - 临时修复版本，已被高级版本替代

## 📜 部署脚本

### 保留核心脚本
- ✅ `scripts/unified-deploy.sh` - 统一部署入口
- ✅ `scripts/quick-deploy.sh` - 快速部署
- ✅ `scripts/direct-deploy.sh` - 服务器直接部署

### 删除重复脚本
- ❌ `scripts/deploy.sh` - 功能重复
- ❌ `scripts/deploy-with-token.sh` - 已弃用token方式
- ❌ `scripts/deploy-fix.sh` - 临时修复脚本

## 🔧 安装配置脚本

### 保留核心配置
- ✅ `scripts/setup-github-ssh.sh` - SSH配置
- ✅ `scripts/setup-tencent-docker.sh` - Docker镜像配置
- ✅ `scripts/one-click-install.sh` - 一键安装

### 删除重复配置
- ❌ `scripts/configure-docker-mirrors.sh` - 与setup-tencent-docker.sh重复
- ❌ `scripts/setup-docker-mirrors.sh` - 功能重复
- ❌ `scripts/install-docker-backup.sh` - 备份版本，不再需要
- ❌ `scripts/install-docker-fixed.sh` - 临时修复版本
- ❌ `scripts/ssh-install-docker.sh` - 功能重复
- ❌ `scripts/quick-install-with-key.sh` - 空文件
- ❌ `scripts/setup-ssh-git.sh` - 与setup-github-ssh.sh功能重复

## 🔍 检查验证脚本

### 保留核心验证
- ✅ `scripts/verify-config.sh` - 完整配置验证
- ✅ `scripts/validate-ssh-config.sh` - SSH配置验证
- ✅ `scripts/check-github-secrets.sh` - GitHub Secrets检查

### 删除重复检查
- ❌ `scripts/deployment-check.sh` - 功能与verify-config.sh重复
- ❌ `scripts/deployment-verification.sh` - 功能重复
- ❌ `scripts/ssh-key-config-check.sh` - 与validate-ssh-config.sh重复
- ❌ `scripts/env-config-check.sh` - 功能分散，已整合到verify-config.sh

## 🧪 测试诊断脚本

### 保留核心诊断
- ✅ `scripts/network-diagnosis.sh` - 网络诊断
- ✅ `scripts/mongodb-health-check.sh` - 数据库健康检查
- ✅ `scripts/check-docker-images.sh` - Docker镜像检查

### 删除重复诊断
- ❌ `scripts/dns-diagnosis.sh` - 功能已整合到network-diagnosis.sh
- ❌ `scripts/network-deep-diagnosis.sh` - 功能重复
- ❌ `scripts/quick-deploy-diagnosis.sh` - 特定功能，不常用
- ❌ `scripts/test-github-token.sh` - 已弃用token方式
- ❌ `scripts/test_github_token.sh` - 重复文件

## 📚 文档清理

### 保留核心文档
- ✅ `docs/ssh-git-setup-guide.md` - SSH设置指南
- ✅ `DEPLOYMENT_COMPLETE.md` - 部署完成报告

### 删除过时文档
- ❌ `docs/deployment.md` - 过时内容
- ❌ `docs/deployment-test.md` - 测试文档，已整合
- ❌ `docs/deployment-architecture.md` - 架构已稳定，不需要单独文档

## 🗑️ 其他临时文件

### 删除空文件和临时文件
- ❌ `scripts/check_deployment.sh` - 空文件
- ❌ `scripts/check_local.sh` - 空文件
- ❌ `quick-start.sh` - 空文件

## 📊 清理统计

- **工作流**: 删除2个，保留1个
- **部署脚本**: 删除3个，保留3个
- **配置脚本**: 删除8个，保留3个
- **检查脚本**: 删除4个，保留3个
- **诊断脚本**: 删除5个，保留3个
- **文档**: 删除3个，保留多个
- **空文件**: 删除3个

**总计删除**: 约28个重复/过时文件
**保留核心**: 约15个关键文件

## 🎯 清理后的项目结构

```
.github/workflows/
  └── deploy-advanced.yml          # 唯一的部署工作流

scripts/
  ├── unified-deploy.sh            # 统一部署入口
  ├── quick-deploy.sh             # 快速部署
  ├── direct-deploy.sh            # 服务器直接部署
  ├── setup-github-ssh.sh        # SSH配置
  ├── setup-tencent-docker.sh    # Docker配置
  ├── one-click-install.sh       # 一键安装
  ├── verify-config.sh           # 配置验证
  ├── validate-ssh-config.sh     # SSH验证
  ├── check-github-secrets.sh    # Secrets检查
  ├── network-diagnosis.sh       # 网络诊断
  ├── mongodb-health-check.sh    # 数据库检查
  └── check-docker-images.sh     # 镜像检查

docs/
  └── ssh-git-setup-guide.md     # SSH配置指南
```

这样的结构更加清晰，功能明确，避免了重复和混淆。
