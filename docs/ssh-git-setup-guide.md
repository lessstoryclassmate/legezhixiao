# SSH Git认证配置指南

## 概述

本项目已配置为使用SSH认证方式进行Git仓库克隆，以提高安全性和稳定性。SSH密钥存放在服务器的 `/root/.ssh/id_ed25519` 路径。

## SSH密钥配置

### 1. 生成SSH密钥

如果服务器上还没有SSH密钥，请执行以下命令生成：

```bash
# 生成ED25519密钥（推荐）
ssh-keygen -t ed25519 -f /root/.ssh/id_ed25519 -N ""

# 或生成RSA密钥（备选）
ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_rsa -N ""
```

### 2. 配置密钥权限

```bash
# 设置正确的权限
chmod 700 /root/.ssh
chmod 600 /root/.ssh/id_ed25519
chmod 644 /root/.ssh/id_ed25519.pub
```

### 3. 添加公钥到GitHub

1. 复制公钥内容：
```bash
cat /root/.ssh/id_ed25519.pub
```

2. 登录GitHub，进入Settings → SSH and GPG keys

3. 点击"New SSH key"，粘贴公钥内容

4. 给密钥起个描述性名称，如"AI Novel Editor Deploy Server"

### 4. 测试SSH连接

```bash
ssh -T git@github.com
```

如果看到 "Hi username! You've successfully authenticated" 消息，说明配置成功。

## 自动化配置

项目提供了自动化配置脚本：

```bash
# 运行SSH配置脚本
sudo ./scripts/setup-ssh-git.sh
```

该脚本会：
- ✅ 检查SSH密钥是否存在
- ✅ 配置SSH客户端设置
- ✅ 设置Git使用SSH认证
- ✅ 测试GitHub连接
- ✅ 生成配置报告

## 部署流程更新

### GitHub Actions 流程

1. 🔑 **SSH配置阶段**
   - 上传SSH配置脚本
   - 执行SSH认证配置
   - 验证SSH连接

2. 🐳 **Docker配置阶段**
   - 配置腾讯云镜像加速器
   - 优化Docker设置

3. 🚪 **端口检查阶段**
   - 检查并修复端口冲突
   - 停止冲突服务

4. 🌐 **网络修复阶段**
   - 修复DNS配置
   - 验证网络连通性

5. 🚀 **代码部署阶段**
   - 使用SSH克隆代码
   - 构建和启动服务

### 部署脚本更新

主要部署脚本 `quick-deploy.sh` 已更新为：

```bash
# 使用SSH方式克隆
GITHUB_REPO="git@github.com:${GITHUB_REPOSITORY}.git"

# SSH配置步骤
- 检查SSH密钥存在性
- 设置SSH客户端配置
- 配置Git使用SSH
- 执行SSH克隆
```

## 故障排除

### SSH密钥问题

```bash
# 检查密钥是否存在
ls -la /root/.ssh/

# 检查密钥权限
stat -c "%a %n" /root/.ssh/id_ed25519

# 重新配置SSH
sudo ./scripts/setup-ssh-git.sh
```

### 连接问题

```bash
# 测试SSH连接
ssh -v git@github.com

# 检查SSH配置
cat /root/.ssh/config

# 手动测试克隆
git clone git@github.com:lessstoryclassmate/legezhixiao.git test-clone
```

### Git配置问题

```bash
# 查看Git配置
git config --global --list

# 重置Git SSH配置
git config --global core.sshCommand "ssh -i /root/.ssh/id_ed25519 -o StrictHostKeyChecking=no"
```

## 安全注意事项

### SSH密钥管理

1. **密钥保护**
   - SSH私钥绝不应泄露
   - 定期轮换SSH密钥
   - 使用强密码保护（如需要）

2. **访问控制**
   - 仅在部署服务器上存放私钥
   - 定期审查GitHub SSH密钥列表
   - 删除不再使用的密钥

3. **监控审计**
   - 监控SSH连接日志
   - 审查Git操作记录
   - 设置异常访问告警

## 优势对比

### SSH vs HTTPS

| 特性 | SSH | HTTPS |
|------|-----|-------|
| 安全性 | ✅ 高（密钥认证） | ⚠️ 中（令牌认证） |
| 稳定性 | ✅ 连接稳定 | ⚠️ 可能超时 |
| 性能 | ✅ 传输效率高 | ⚠️ 相对较慢 |
| 配置 | ⚠️ 需要密钥配置 | ✅ 配置简单 |
| 令牌依赖 | ✅ 无需令牌 | ❌ 需要PAT令牌 |

## 维护计划

### 定期检查

- **每月**: 验证SSH连接是否正常
- **每季度**: 检查密钥是否需要轮换
- **每半年**: 审查SSH配置和权限

### 备份恢复

```bash
# 备份SSH配置
tar -czf ssh-backup-$(date +%Y%m%d).tar.gz /root/.ssh/

# 恢复SSH配置（如需要）
tar -xzf ssh-backup-*.tar.gz -C /
chmod 700 /root/.ssh
chmod 600 /root/.ssh/id_ed25519
```

---

通过SSH认证，项目部署将更加安全可靠，避免了令牌过期和网络问题导致的部署失败。
