# 🔐 GitHub Secrets 配置清单

基于您提供的配置信息，请在GitHub仓库中配置以下Secrets：

## 📋 需要配置的GitHub Secrets

### 🌐 服务器配置
```
SERVER_IP = 106.13.216.179
SERVER_USER = root
SERVER_SSH_KEY = [您的SSH私钥内容]
```

### 🗄️ 数据库配置

#### 通用数据库配置
```
DATABASE_PORT = 3306
```

#### 系统数据库
```
DATABASE_SYSTEMIP = 172.16.16.3
DATABASE_SYSTEM = novel_data
DATABASE_USER = lkr
DATABASE_PASSWORD = Lekairong350702
```

#### 用户数据库
```
DATABASE_NOVELIP = 172.16.16.2
DATABASE_NOVELDATA = novel_user_data
DATABASE_NOVELUSER = novel_data_user
DATABASE_NOVELUSER_PASSWORD = Lekairong350702
```

### 🤖 AI服务配置
```
SILICONFLOW_API_KEY = sk-mjithqmjwccqgffouexthbavtnvftwkqjludpcxhrmeztcib
```

### 🔒 安全配置
```
SECRET_KEY = [生成一个强密码作为应用密钥]
JWT_SECRET_KEY = [生成一个强密码作为JWT密钥]
```

## 🛠️ 配置步骤

1. **进入GitHub仓库设置**
   - 访问您的仓库
   - 点击 `Settings` 标签
   - 在左侧菜单选择 `Secrets and variables` → `Actions`

2. **添加Repository Secrets**
   点击 `New repository secret`，逐一添加上述所有配置

3. **验证配置**
   配置完成后，推送代码将自动触发部署

## 🔑 SSH密钥配置

如果您还没有配置SSH密钥，请按以下步骤操作：

### 生成SSH密钥对（本地执行）
```bash
ssh-keygen -t rsa -b 4096 -C "github-actions@novel-editor"
# 建议保存为 ~/.ssh/novel-editor-deploy
```

### 配置服务器（在百度云服务器上执行）
```bash
# 将公钥添加到服务器
cat >> ~/.ssh/authorized_keys << 'EOF'
[您的公钥内容]
EOF

# 设置权限
chmod 600 ~/.ssh/authorized_keys
chmod 700 ~/.ssh
```

### 在GitHub中配置私钥
将私钥内容（包括BEGIN和END行）复制到 `SERVER_SSH_KEY` Secret中

## 🎯 端口配置验证

根据您的配置，确保以下端口在服务器上可用：
- `22`: SSH (已配置)
- `80`: HTTP 前端服务
- `8000`: API 后端服务
- `8080`: 备用HTTP (可选)
- `30080`: 监控/管理 (可选)

## 🔍 配置验证命令

配置完成后，可以在服务器上执行以下命令验证：

```bash
# 检查端口监听
netstat -tlnp | grep -E ":(22|80|8000|8080|30080)"

# 检查Docker服务
systemctl status docker

# 检查防火墙（如果使用）
ufw status # Ubuntu
firewall-cmd --list-all # CentOS
```

## 🚀 触发部署

配置完成后，任何推送到 `main` 分支的代码都会自动触发部署：

```bash
git add .
git commit -m "feat: 触发自动部署测试"
git push origin main
```

## 📊 监控部署状态

1. **GitHub Actions页面**
   - 仓库 → `Actions` 标签
   - 查看工作流运行状态

2. **服务器状态检查**
   ```bash
   # SSH到服务器
   ssh root@106.13.216.179
   
   # 检查服务状态
   cd /root/novel-editor
   docker-compose -f docker-compose.baidu.yml ps
   docker-compose -f docker-compose.baidu.yml logs
   ```

3. **服务访问验证**
   - 前端：http://106.13.216.179
   - API文档：http://106.13.216.179:8000/docs
   - 健康检查：http://106.13.216.179:8000/health

## ⚠️ 注意事项

1. **密钥安全**：请确保SSH私钥和API密钥的安全
2. **网络访问**：确保服务器可以访问GitHub Container Registry
3. **资源限制**：监控服务器资源使用情况
4. **备份策略**：建议定期备份数据库数据

完成配置后，您的AI小说编辑器将支持从GitHub推送代码到百度云服务器的全自动部署！
