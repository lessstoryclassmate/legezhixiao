# 🔑 SSH 密钥配置指南

## 📋 概述

根据需求文档，AI 小说编辑器的部署需要使用 SSH 方式克隆 GitHub 仓库：
- **SSH 地址**: `git@github.com:lessstoryclassmate/legezhixiao.git`
- **密钥路径**: `/root/.ssh/id_ed25519`
- **要求**: GitHub 库已配置公钥

## 🚀 SSH 密钥配置步骤

### 1. 检查现有密钥

```bash
# 检查密钥是否存在
ls -la /root/.ssh/

# 如果存在，检查权限
ls -l /root/.ssh/id_ed25519
```

### 2. 生成新密钥（如果不存在）

```bash
# 生成 ED25519 密钥对
ssh-keygen -t ed25519 -f /root/.ssh/id_ed25519 -N ""

# 设置正确权限
chmod 600 /root/.ssh/id_ed25519
chmod 644 /root/.ssh/id_ed25519.pub
chmod 700 /root/.ssh
```

### 3. 获取公钥内容

```bash
# 显示公钥内容
cat /root/.ssh/id_ed25519.pub
```

### 4. 在 GitHub 中添加公钥

1. 登录 GitHub
2. 进入仓库设置页面：`https://github.com/lessstoryclassmate/legezhixiao/settings`
3. 点击 "Deploy keys" 选项
4. 点击 "Add deploy key"
5. 粘贴公钥内容
6. 勾选 "Allow write access"（如果需要）
7. 点击 "Add key"

### 5. 验证配置

```bash
# 运行 SSH 验证脚本
./scripts/verify-ssh-config.sh

# 或手动测试
ssh -T git@github.com
```

## 🔧 部署脚本更新

### 主要修改

1. **SSH 优先策略**: 部署脚本现在优先使用 SSH 克隆
2. **连接测试**: 部署前自动测试 SSH 连接和仓库访问
3. **详细诊断**: 提供详细的错误信息和故障排查建议
4. **备选方案**: SSH 失败时自动回退到 HTTPS

### 部署脚本功能

- ✅ **quick-deploy-fixed.sh**: 主要部署脚本，包含完整的 SSH 配置
- ✅ **quick-deploy.sh**: 备用部署脚本，同样支持 SSH 优先
- ✅ **verify-ssh-config.sh**: 专门的 SSH 验证工具

## 📊 故障排查

### 常见问题和解决方案

| **问题** | **症状** | **解决方案** |
|----------|----------|--------------|
| 密钥文件不存在 | `SSH 密钥文件不存在` | 按照步骤 2 生成密钥 |
| 权限错误 | `Permission denied` | 执行 `chmod 600 /root/.ssh/id_ed25519` |
| 公钥未添加 | `Permission denied (publickey)` | 按照步骤 4 添加公钥到 GitHub |
| 网络问题 | `Connection timeout` | 检查网络连接和 DNS 设置 |

### 诊断命令

```bash
# 测试 SSH 连接
ssh -T git@github.com

# 测试仓库访问
git ls-remote git@github.com:lessstoryclassmate/legezhixiao.git

# 检查 SSH 配置
cat /root/.ssh/config

# 查看详细连接信息
ssh -vT git@github.com
```

## 🎯 部署流程

### 推荐步骤

1. **准备阶段**
   ```bash
   # 验证 SSH 配置
   ./scripts/verify-ssh-config.sh
   ```

2. **部署阶段**
   ```bash
   # 使用主要部署脚本
   ./scripts/quick-deploy-fixed.sh
   
   # 或使用备用脚本
   ./scripts/quick-deploy.sh
   ```

3. **验证阶段**
   ```bash
   # 检查服务状态
   docker-compose -f docker-compose.production.yml ps
   
   # 验证应用访问
   curl -f http://localhost:80
   ```

## 📝 配置文件示例

### SSH 配置文件 (`/root/.ssh/config`)

```
Host github.com
    HostName github.com
    User git
    IdentityFile /root/.ssh/id_ed25519
    IdentitiesOnly yes
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    ConnectTimeout 30
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

### Git 全局配置

```bash
# 配置 SSH 命令
git config --global core.sshCommand "ssh -i /root/.ssh/id_ed25519 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"

# 配置用户信息
git config --global user.name "Deploy Bot"
git config --global user.email "deploy@legezhixiao.com"
```

## 🔐 安全建议

1. **密钥权限**: 确保私钥文件权限为 600
2. **密钥类型**: 使用 ED25519 密钥（更安全）
3. **访问控制**: 仅授予必要的仓库访问权限
4. **定期更换**: 定期更换部署密钥

## 📞 支持

如果遇到问题，请：

1. 运行 `./scripts/verify-ssh-config.sh` 获取详细诊断
2. 检查 GitHub 仓库的 Deploy keys 设置
3. 确认网络连接正常
4. 查看部署脚本的详细输出日志

---

🎉 **配置完成后，部署脚本将优先使用 SSH 克隆，确保安全和稳定的代码获取！**
