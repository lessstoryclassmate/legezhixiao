# GitHub Secrets 配置指南

## 🔧 部署失败问题解决

### 错误描述
```
2025/07/14 02:37:49 Error: missing server host
```

### 原因分析
GitHub Actions 工作流中的 SSH 部署步骤缺少必要的服务器配置信息，导致无法连接到生产服务器。

## ✅ 解决方案

### 1. 修正工作流配置

已修正 `.github/workflows/deploy-advanced.yml` 中的 secrets 名称，统一使用以下标准命名：

| 修正前 | 修正后 | 说明 |
|--------|--------|------|
| `secrets.HOST` | `secrets.SERVER_IP` | 服务器IP地址 |
| `secrets.USERNAME` | `secrets.SERVER_USER` | 服务器用户名 |
| `secrets.SSH_PRIVATE_KEY` | `secrets.SERVER_SSH_KEY` | SSH私钥 |

### 2. 配置 GitHub Secrets

请在 GitHub 仓库中添加以下 Secrets：

#### 操作步骤：
1. 进入 GitHub 仓库：https://github.com/lessstoryclassmate/legezhixiao
2. 点击 **Settings** 选项卡
3. 在左侧菜单中选择 **Secrets and variables** → **Actions**
4. 点击 **New repository secret** 添加以下配置

#### 必需的 Secrets：

| Secret 名称 | 值 | 说明 |
|-------------|-----|------|
| `SERVER_IP` | `106.13.216.179` | 服务器IP地址 |
| `SERVER_USER` | `root` | 服务器登录用户名 |
| `SERVER_SSH_KEY` | *SSH私钥内容* | SSH私钥（从服务器获取） |
| `SILICONFLOW_API_KEY` | `sk-mjithqmjwccqgffouexthbavtnvftwkqjludpcxhrmeztcib` | SiliconFlow API密钥 |
| `JWT_SECRET_KEY` | *随机字符串* | JWT加密密钥 |
| `REDIS_PASSWORD` | `Lekairong350702` | Redis密码 |

#### 可选的 Secrets（如果使用）：

| Secret 名称 | 值 | 说明 |
|-------------|-----|------|
| `MONGO_PASSWORD` | `Lekairong350702` | MongoDB密码 |
| `DATABASE_PASSWORD` | `Lekairong350702` | 数据库密码 |

### 3. 获取 SSH 私钥

#### 从服务器获取私钥内容：

```bash
# 在服务器上运行以获取私钥内容
cat /root/.ssh/id_ed25519
```

**重要提示**：
- 复制私钥的完整内容，包括 `-----BEGIN OPENSSH PRIVATE KEY-----` 和 `-----END OPENSSH PRIVATE KEY-----`
- 确保包含所有换行符
- 私钥内容应该类似：

```
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAFwAAAAdzc2gtcn
...（私钥内容）...
AAAAB3NzaC1yc2EAAAA...
-----END OPENSSH PRIVATE KEY-----
```

### 4. 验证配置

#### 检查 Secrets 设置：

在 GitHub 仓库的 Settings → Secrets 中，确认以下 secrets 已配置：

- ✅ `SERVER_IP` - 显示为已设置
- ✅ `SERVER_USER` - 显示为已设置  
- ✅ `SERVER_SSH_KEY` - 显示为已设置
- ✅ `SILICONFLOW_API_KEY` - 显示为已设置
- ✅ `JWT_SECRET_KEY` - 显示为已设置
- ✅ `REDIS_PASSWORD` - 显示为已设置

## 🚀 重新部署

### 自动触发
配置完成后，有以下方式触发部署：

1. **推送代码触发**：
   ```bash
   git add .
   git commit -m "fix: update GitHub secrets configuration"
   git push origin main
   ```

2. **手动触发**：
   - 进入 GitHub 仓库的 **Actions** 选项卡
   - 选择要运行的工作流
   - 点击 **Run workflow** 按钮

### 检查部署状态

1. 进入 **Actions** 选项卡查看工作流运行状态
2. 点击具体的工作流运行实例查看详细日志
3. 确认部署步骤成功完成

## 🔍 故障排除

### 常见错误及解决方案

| 错误信息 | 原因 | 解决方案 |
|----------|------|----------|
| `missing server host` | 缺少 SERVER_IP | 添加 SERVER_IP secret |
| `permission denied` | SSH密钥错误 | 检查 SERVER_SSH_KEY 内容 |
| `connection refused` | 服务器无法访问 | 检查服务器IP和SSH服务 |
| `authentication failed` | 用户名或密钥错误 | 验证 SERVER_USER 和 SSH密钥 |

### 调试步骤

1. **验证服务器连接**：
   ```bash
   # 在本地测试SSH连接
   ssh -i /path/to/private/key root@106.13.216.179
   ```

2. **检查密钥格式**：
   ```bash
   # 验证私钥格式
   ssh-keygen -l -f /root/.ssh/id_ed25519
   ```

3. **查看工作流日志**：
   - 在 GitHub Actions 中查看详细的错误信息
   - 检查 SSH 连接步骤的输出

## 📋 配置检查清单

部署前请确认：

- [ ] GitHub Secrets 已正确配置
- [ ] SSH私钥格式正确（包含完整的BEGIN/END标记）
- [ ] 服务器IP地址正确
- [ ] 服务器SSH服务正常运行
- [ ] 工作流文件中的secrets名称已统一
- [ ] API密钥等敏感信息已配置

---

**配置完成后，GitHub Actions 应该能够成功连接并部署到生产服务器。**
