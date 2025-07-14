# SSH密钥正确使用指南 🔑

## 重要说明：两种完全不同的SSH密钥

### ❌ 之前的混淆
之前的文档错误地将两种不同用途的SSH密钥混为一谈。这是**错误的**！

### ✅ 正确的区分

## 1. GitHub Actions → 服务器连接密钥

### 用途
- **GitHub Actions 连接到您的服务器**
- 用于部署过程中的SSH连接

### 位置
- 存储在 **GitHub Secrets** 中作为 `SERVER_SSH_KEY`
- 这是一个独立的密钥对，专门用于部署

### 配置步骤
```bash
# 1. 在您的本地机器或服务器上生成部署密钥
ssh-keygen -t ed25519 -C "github-actions-deploy" -f ~/.ssh/deploy_key

# 2. 将公钥添加到服务器的authorized_keys
cat ~/.ssh/deploy_key.pub >> /root/.ssh/authorized_keys

# 3. 将私钥内容复制到GitHub Secrets
cat ~/.ssh/deploy_key
```

### GitHub Secrets配置
```
SERVER_SSH_KEY = [deploy_key的私钥内容]
SERVER_IP = [您的服务器IP]
SERVER_USER = root
```

## 2. 服务器 → GitHub仓库克隆密钥

### 用途
- **服务器克隆/拉取GitHub仓库代码**
- 用于`git clone`和`git pull`操作

### 位置
- 存储在 **服务器文件系统** `/root/.ssh/id_ed25519`
- 公钥需要添加到GitHub账户的SSH密钥

### 配置步骤
```bash
# 1. 在服务器上生成Git操作密钥
ssh-keygen -t ed25519 -C "server-git-access" -f /root/.ssh/id_ed25519

# 2. 将公钥添加到GitHub账户
cat /root/.ssh/id_ed25519.pub
# 复制输出内容，在GitHub设置中添加SSH密钥

# 3. 测试Git访问
ssh -T git@github.com
```

## 密钥使用流程图

```
GitHub Actions (部署)
       ↓ [使用 SERVER_SSH_KEY]
    服务器 (Ubuntu 24.04)
       ↓ [使用 /root/.ssh/id_ed25519]
    GitHub仓库 (代码克隆)
```

## 关键区别总结

| 用途 | 密钥位置 | GitHub配置 | 服务器配置 |
|------|----------|-------------|------------|
| **GitHub Actions → 服务器** | GitHub Secrets: `SERVER_SSH_KEY` | 在Secrets中设置私钥 | 在`authorized_keys`中添加公钥 |
| **服务器 → GitHub仓库** | 服务器: `/root/.ssh/id_ed25519` | 在账户设置中添加公钥 | 生成并存储私钥 |

## 重要提醒

⚠️ **绝对不要**将服务器上的`/root/.ssh/id_ed25519`私钥内容放入GitHub Secrets中！

✅ **正确做法**：
1. 为GitHub Actions部署创建专门的密钥对
2. 为服务器Git操作创建专门的密钥对  
3. 两者完全分离，互不干扰

## 下一步行动

1. **生成GitHub Actions部署密钥**
2. **确认服务器Git密钥配置正确**
3. **更新GitHub Secrets使用正确的部署密钥**
4. **测试两种连接都正常工作**
