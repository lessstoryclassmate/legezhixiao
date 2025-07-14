# SSH密钥配置澄清文档

## 🔑 SSH密钥用途明确区分

### 混淆问题说明
之前的文档错误地混淆了两种不同用途的SSH密钥，现在澄清如下：

## 📋 两种SSH密钥的正确用途

### 1. **GitHub Actions → 服务器连接密钥**

**用途**: GitHub Actions workflow 连接到部署服务器  
**GitHub Secret名称**: `SERVER_SSH_KEY`  
**密钥生成位置**: 开发者本地或CI/CD环境  
**密钥存储位置**: GitHub Secrets中  
**对应公钥添加位置**: 服务器的 `/root/.ssh/authorized_keys`  

```bash
# 生成用于GitHub Actions连接服务器的密钥对
ssh-keygen -t ed25519 -f ./github_actions_key -N ''

# 公钥添加到服务器
cat ./github_actions_key.pub >> /root/.ssh/authorized_keys

# 私钥内容添加到GitHub Secrets: SERVER_SSH_KEY
cat ./github_actions_key
```

### 2. **服务器 → GitHub仓库克隆密钥**

**用途**: 服务器上克隆GitHub仓库代码  
**密钥生成位置**: 部署服务器上  
**密钥存储位置**: 服务器的 `/root/.ssh/id_ed25519`  
**对应公钥添加位置**: GitHub账户的SSH keys设置  

```bash
# 在服务器上生成用于克隆GitHub仓库的密钥对
ssh-keygen -t ed25519 -f /root/.ssh/id_ed25519 -N ''

# 公钥添加到GitHub账户
cat /root/.ssh/id_ed25519.pub
# 复制内容到 https://github.com/settings/ssh/new
```

## 🔧 当前配置问题分析

### 问题1：概念混淆
在之前的文档中，错误地建议：
- ❌ 将服务器上的 `/root/.ssh/id_ed25519` 作为 `SERVER_SSH_KEY`
- ❌ 这会导致GitHub Actions无法正确连接服务器

### 问题2：密钥用途错误
- ❌ `SERVER_SSH_KEY` 不应该从服务器获取
- ✅ `SERVER_SSH_KEY` 应该是专门用于连接服务器的密钥

## ✅ 正确的配置方案

### GitHub Secrets 配置

| Secret名称 | 用途 | 正确的值 | 获取方式 |
|------------|------|----------|----------|
| `SERVER_SSH_KEY` | GitHub Actions连接服务器 | 专用的SSH私钥 | 单独生成的密钥对 |
| `SERVER_IP` | 服务器地址 | `106.13.216.179` | 服务器IP |
| `SERVER_USER` | 服务器用户名 | `root` | 服务器用户 |

### 服务器端配置

| 文件路径 | 用途 | 内容 |
|----------|------|------|
| `/root/.ssh/id_ed25519` | 克隆GitHub仓库 | 服务器生成的私钥 |
| `/root/.ssh/id_ed25519.pub` | 克隆GitHub仓库 | 对应公钥(添加到GitHub) |
| `/root/.ssh/authorized_keys` | 接受GitHub Actions连接 | `SERVER_SSH_KEY`对应的公钥 |

## 🔨 修正步骤

### 1. 生成GitHub Actions专用密钥

```bash
# 在本地生成用于GitHub Actions的密钥对
ssh-keygen -t ed25519 -f ./ci_deploy_key -N ''

# 查看私钥（添加到GitHub Secrets: SERVER_SSH_KEY）
cat ./ci_deploy_key

# 查看公钥（添加到服务器）
cat ./ci_deploy_key.pub
```

### 2. 配置服务器接受GitHub Actions连接

```bash
# 在服务器上添加GitHub Actions的公钥
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIxxxx..." >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
```

### 3. 确认服务器仓库克隆密钥

```bash
# 确认服务器上的GitHub克隆密钥存在
ls -la /root/.ssh/id_ed25519*

# 确认公钥已添加到GitHub账户
cat /root/.ssh/id_ed25519.pub
# 访问 https://github.com/settings/ssh/new 确认已添加
```

### 4. 更新GitHub Secrets

在 https://github.com/lessstoryclassmate/legezhixiao/settings/secrets/actions 中：

- `SERVER_SSH_KEY`: **新生成的CI专用私钥内容**（不是服务器上的密钥）
- `SERVER_IP`: `106.13.216.179`
- `SERVER_USER`: `root`

## 🧪 验证连接

### 测试GitHub Actions到服务器连接

```bash
# 使用GitHub Actions密钥测试连接
ssh -i ./ci_deploy_key root@106.13.216.179
```

### 测试服务器到GitHub连接

```bash
# 在服务器上测试GitHub连接
ssh -T git@github.com
```

## 📝 工作流程说明

### 完整的部署流程

1. **GitHub Actions 启动**
   - 使用 `SERVER_SSH_KEY` 连接到服务器
   - 在服务器上执行部署脚本

2. **服务器执行部署**
   - 使用 `/root/.ssh/id_ed25519` 克隆GitHub仓库
   - 构建和启动应用

3. **密钥隔离**
   - GitHub Actions密钥：只用于CI/CD连接服务器
   - 服务器密钥：只用于克隆代码仓库

## ⚠️ 安全考虑

1. **密钥分离**: 两种用途的密钥完全分离，降低安全风险
2. **权限最小化**: 每个密钥只有必要的权限
3. **密钥轮换**: 定期更新密钥，特别是GitHub Actions密钥

---

**修正时间**: $(date)  
**状态**: 需要重新配置GitHub Secrets  
**优先级**: 高 - 影响CI/CD部署功能
