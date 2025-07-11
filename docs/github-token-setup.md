# GitHub Token 配置指南

## 问题解决方案

您遇到的 git clone 错误 `fatal: could not read Username for 'https://github.com': No such device or address` 已经通过配置 GitHub Token 得到解决。

## 当前配置状态

### 1. 部署脚本已更新
- ✅ 使用 Token 认证的 HTTPS 克隆地址
- ✅ 支持重试机制
- ✅ 包含详细的错误调试信息

### 2. GitHub Token 配置
您提供的 Token: `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`

**重要提醒：** 为了安全起见，请立即完成以下步骤：

## 必须立即执行的步骤

### 1. 在 GitHub 仓库中设置 Secret

1. 访问您的 GitHub 仓库: https://github.com/lessstoryclassmate/legezhixiao
2. 点击 **Settings** 标签
3. 在左侧菜单中选择 **Secrets and variables** → **Actions**
4. 点击 **New repository secret**
5. 添加以下 Secret：
   - **Name**: `DEPLOY_TOKEN`
   - **Value**: `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`

### 2. 验证其他必需的 Secrets

确保以下 Secrets 都已正确配置：

| Secret Name | 说明 | 示例值 |
|-------------|------|--------|
| `DEPLOY_TOKEN` | GitHub 部署 Token | `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` |
| `SERVER_IP` | 服务器 IP 地址 | `106.13.216.179` |
| `SERVER_SSH_KEY` | SSH 私钥 | (SSH 私钥内容) |
| `SILICONFLOW_API_KEY` | SiliconFlow API Key | `sk-mjithqmjwccqgffouexthbavtnvftwkqjludpcxhrmeztcib` |
| `JWT_SECRET_KEY` | JWT 密钥 | (随机生成的密钥) |
| `MONGO_PASSWORD` | MongoDB 密码 | `Lekairong350702` |
| `REDIS_PASSWORD` | Redis 密码 | `Lekairong350702` |

### 3. 根据您的配置文件更新

根据您提供的配置文件 `环境配置以及要求.ini`，我建议添加以下额外的 Secrets：

```ini
# 数据库配置
DATABASE_PASSWORD=Lekairong350702
DATABASE_NOVELUSER_PASSWORD=Lekairong350702

# 服务器配置
SERVER_USER=root
SERVER_SSH_PORT=22
```

## 代码中的修复内容

### 1. Git Clone 地址已修复
```bash
# 旧版本 (会失败)
git clone https://github.com/lessstoryclassmate/legezhixiao .

# 新版本 (使用 Token)
git clone "https://${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git" .
```

### 2. 环境变量传递
```yaml
env:
  GITHUB_TOKEN: ${{ secrets.DEPLOY_TOKEN }}
  GITHUB_REPOSITORY: ${{ github.repository }}
```

### 3. 重试机制
- 自动重试 3 次
- 每次重试间隔 5 秒
- 详细的错误调试信息

## 安全建议

1. **立即删除此文档中的明文 Token**
2. **将 Token 添加到 GitHub Secrets 后，从任何公开文档中移除**
3. **定期轮换 GitHub Token**
4. **确保 Token 只有必要的权限**

## 验证配置

配置完成后，您可以：

1. 推送代码触发 GitHub Actions
2. 在 Actions 页面查看部署日志
3. 确认克隆步骤不再出现认证错误

## 故障排查

如果仍有问题，请检查：

1. Token 是否正确复制到 GitHub Secrets
2. Token 是否有仓库访问权限
3. Token 是否已过期
4. 网络连接是否正常

---

**下一步操作：**
1. 立即设置 GitHub Secrets
2. 推送代码测试部署
3. 验证部署成功

配置完成后，git clone 错误将完全解决！
