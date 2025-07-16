# GitHub Actions 私有库部署配置指南

## 🔐 私有库访问所需的 GitHub Secrets

由于您的库已从公共库变成私有库，需要在GitHub仓库设置中添加以下Secrets：

### 1. SSH密钥配置

**DEPLOY_SSH_KEY**
```
描述: 用于克隆私有仓库的SSH私钥
内容: /root/.ssh/id_ed25519 文件的完整内容
格式: 
-----BEGIN OPENSSH PRIVATE KEY-----
...私钥内容...
-----END OPENSSH PRIVATE KEY-----
```

**SSH_KNOWN_HOSTS**
```
描述: GitHub的SSH known hosts
内容: github.com的SSH指纹信息
格式: github.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC7vbZ...
```

### 2. 服务器部署配置

**SERVER_IP**
```
描述: 百度云服务器IP地址
内容: 您的服务器IP地址（如：123.456.789.10）
```

**SERVER_USER**
```
描述: 服务器用户名
内容: root
```

**SERVER_SSH_KEY**
```
描述: 连接百度云服务器的SSH私钥
内容: 用于GitHub Actions连接您服务器的SSH私钥
```

**BAIDU_DNS**
```
描述: 百度云DNS服务器
内容: 180.76.76.76
```

**DOCKER_REGISTRY**
```
描述: 百度云Docker镜像仓库
内容: registry.baidubce.com
```

## 🛠️ 配置步骤

### 第一步：生成SSH密钥（如果还未生成）

1. 在您的服务器上生成SSH密钥：
```bash
ssh-keygen -t ed25519 -f /root/.ssh/id_ed25519 -N ''
```

2. 将公钥添加到GitHub：
```bash
cat /root/.ssh/id_ed25519.pub
```

3. 复制公钥内容到GitHub仓库设置中的"Deploy keys"或个人设置中的"SSH keys"

### 第二步：获取SSH Known Hosts

```bash
ssh-keyscan -H github.com
```

### 第三步：在GitHub仓库中添加Secrets

1. 进入您的GitHub仓库
2. 点击 Settings → Secrets and variables → Actions
3. 点击 "New repository secret"
4. 逐个添加上述所有secrets

### 第四步：验证私有库访问

运行以下脚本验证配置：

```bash
# 运行私有库SSH配置脚本
./scripts/private-repo-ssh-setup.sh

# 验证私有库访问
./scripts/verify-private-repo-access.sh
```

## 📋 secrets配置检查清单

- [ ] **DEPLOY_SSH_KEY**: 已添加私钥内容
- [ ] **SSH_KNOWN_HOSTS**: 已添加GitHub SSH指纹
- [ ] **SERVER_IP**: 已添加服务器IP地址
- [ ] **SERVER_USER**: 已设置为root
- [ ] **SERVER_SSH_KEY**: 已添加服务器SSH私钥
- [ ] **BAIDU_DNS**: 已设置为180.76.76.76
- [ ] **DOCKER_REGISTRY**: 已设置为registry.baidubce.com

## 🔧 故障排除

### 问题1：SSH连接失败
- 检查SSH密钥是否正确添加到GitHub
- 确认私钥格式正确（完整的BEGIN/END标记）
- 验证服务器上的SSH密钥文件权限（600）

### 问题2：私有库访问被拒绝
- 确认GitHub账户对私有库有访问权限
- 检查Deploy keys是否正确配置
- 验证SSH密钥是否匹配

### 问题3：部署失败
- 检查服务器SSH连接是否正常
- 确认所有必要的secrets都已配置
- 验证服务器防火墙设置

## 🚀 部署流程

配置完成后，GitHub Actions将自动：

1. **代码检查**: 验证代码质量
2. **配置验证**: 检查Docker和配置文件
3. **安全检查**: 验证SSH密钥和访问权限
4. **自动部署**: 使用SSH连接到服务器进行部署

## 📞 支持

如果遇到问题，请检查：

1. GitHub Actions的执行日志
2. 服务器上的部署日志
3. SSH连接状态
4. 网络连接情况

所有配置都严格按照需求文档中的规范：
- SSH地址：`git@github.com:lessstoryclassmate/legezhixiao.git`
- 密钥路径：`/root/.ssh/id_ed25519`
- 百度云DNS：`180.76.76.76`
- Docker镜像仓库：`registry.baidubce.com`
