# GitHub Secrets 配置指南

## 必需的 GitHub Secrets

在GitHub仓库中设置以下Secrets（路径：仓库 → Settings → Secrets and variables → Actions）

### 🔐 认证相关

#### GITHUB_TOKEN_CUSTOM
- **值**: `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`
- **用途**: 用于在服务器上克隆私有仓库
- **权限要求**: repo (Full control of private repositories)

#### SERVER_SSH_KEY
- **值**: 你的SSH私钥内容（完整的私钥文件内容）
- **用途**: SSH连接到百度云服务器
- **格式**: 
```
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAABlwAAAAdzc2gtcn
...完整的私钥内容...
-----END OPENSSH PRIVATE KEY-----
```

### 🌐 服务器配置

#### SERVER_IP
- **值**: `106.13.216.179`
- **用途**: 百度云服务器IP地址

#### SERVER_USER
- **值**: `root`
- **用途**: 服务器登录用户名

#### SERVER_SSH_PORT
- **值**: `22`
- **用途**: SSH连接端口

### 🔑 API密钥

#### SILICONFLOW_API_KEY
- **值**: `sk-mjithqmjwccqgffouexthbavtnvftwkqjludpcxhrmeztcib`
- **用途**: SiliconFlow AI API调用

#### JWT_SECRET_KEY
- **值**: `your-super-secret-jwt-key-at-least-32-characters-long`
- **用途**: JWT Token签名密钥
- **要求**: 至少32个字符的随机字符串

### 💾 数据库配置

#### MONGO_PASSWORD
- **值**: `Lekairong350702`
- **用途**: MongoDB数据库密码

#### REDIS_PASSWORD
- **值**: `Lekairong350702`
- **用途**: Redis缓存密码

## 配置步骤

### 1. 创建GitHub Token（如果还没有）
1. 访问 GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. 点击 "Generate new token (classic)"
3. 设置权限：
   - ✅ repo (Full control of private repositories)
   - ✅ workflow (Update GitHub Action workflows)
4. 复制生成的token

### 2. 设置GitHub Secrets
1. 打开仓库页面
2. 点击 Settings → Secrets and variables → Actions
3. 点击 "New repository secret"
4. 逐一添加上述所有secrets

### 3. 验证配置
运行GitHub Actions工作流，检查是否能成功克隆代码和部署。

## 注意事项

⚠️ **安全提醒**:
- GitHub Token 具有访问私有仓库的权限，请妥善保管
- SSH私钥是服务器访问凭证，不要泄露
- 定期更新密码和密钥

⚠️ **Token权限**:
- 确保GitHub Token有 `repo` 权限
- Token过期后需要重新生成并更新

⚠️ **网络配置**:
- 确保服务器防火墙允许SSH连接（端口22）
- 确保服务器可以访问GitHub.com

## 故障排查

### 克隆失败问题
```bash
fatal: could not read Username for 'https://github.com': No such device or address
```
**解决方案**: 检查 `GITHUB_TOKEN_CUSTOM` 是否正确设置

### SSH连接失败
```bash
Permission denied (publickey)
```
**解决方案**: 检查 `SERVER_SSH_KEY` 格式和内容是否正确

### 部署权限问题
```bash
Permission denied
```
**解决方案**: 确保SSH密钥对应的公钥已添加到服务器的 `~/.ssh/authorized_keys`

## 测试命令

### 本地测试GitHub Token
```bash
# 测试Token是否有效
curl -H "Authorization: token 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" \
     https://api.github.com/repos/lessstoryclassmate/legezhixiao

# 测试克隆（本地）
git clone https://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@github.com/lessstoryclassmate/legezhixiao.git
```

### 服务器SSH测试
```bash
# 测试SSH连接
ssh -i /path/to/private/key root@106.13.216.179

# 测试SSH密钥
ssh-keygen -y -f /path/to/private/key
```
