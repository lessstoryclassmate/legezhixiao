# SSH自动化Docker安装脚本使用说明

## 概述

`ssh-install-docker.sh` 是一个自动化脚本，用于通过SSH连接到远程Ubuntu服务器并自动安装Docker和Docker Compose。该脚本使用内嵌的SSH私钥进行身份验证，无需手动输入密码。

## 功能特性

- ✅ SSH密钥认证，无需密码输入
- ✅ 自动检测和验证SSH连接
- ✅ 完整的Docker CE安装
- ✅ 最新版本Docker Compose安装
- ✅ 用户权限自动配置
- ✅ 安装验证和测试
- ✅ 详细的日志输出
- ✅ 错误处理和恢复
- ✅ 临时文件自动清理

## 使用前准备

### 1. 配置SSH私钥

编辑脚本中的 `SSH_PRIVATE_KEY_CONTENT` 变量，替换为您的实际RSA私钥：

```bash
SSH_PRIVATE_KEY_CONTENT='-----BEGIN RSA PRIVATE KEY-----
您的私钥内容
-----END RSA PRIVATE KEY-----'
```

### 2. 确保服务器要求

- 目标服务器运行Ubuntu系统
- SSH服务已启用（端口22或自定义端口）
- 用户具有sudo权限
- 对应的公钥已添加到服务器的 `~/.ssh/authorized_keys`

## 使用方法

### 基本使用

```bash
./scripts/ssh-install-docker.sh
```

运行脚本后，按提示输入：
- 服务器IP地址
- SSH用户名（默认：ubuntu）
- SSH端口（默认：22）

### 示例运行过程

```bash
$ ./scripts/ssh-install-docker.sh

=== SSH自动化Docker安装脚本 ===

请输入服务器IP地址 (默认: your-server-ip): 192.168.1.100
请输入SSH用户名 (默认: ubuntu): ubuntu
请输入SSH端口 (默认: 22): 22

[INFO] 连接信息：
[INFO]   服务器IP: 192.168.1.100
[INFO]   SSH用户: ubuntu
[INFO]   SSH端口: 22

[INFO] 测试SSH连接到 ubuntu@192.168.1.100:22
[INFO] SSH连接测试成功
确认在远程服务器上安装Docker和Docker Compose? (y/N): y

[INFO] 生成远程安装脚本...
[INFO] 传输安装脚本到远程服务器...
[INFO] 在远程服务器上执行Docker安装...
[INFO] 检测到系统：Ubuntu 22.04.3 LTS
[INFO] 更新系统包列表...
[INFO] 安装必要的依赖包...
[INFO] 添加Docker官方GPG密钥...
[INFO] 添加Docker APT仓库...
[INFO] 更新包列表...
[INFO] 安装Docker CE...
[INFO] 启动并启用Docker服务...
[INFO] 验证Docker安装...
[INFO] 获取Docker Compose最新版本...
[INFO] 下载Docker Compose v2.23.0...
[INFO] 设置执行权限...
[INFO] 创建符号链接...
[INFO] 验证Docker Compose安装...
[INFO] 将用户 ubuntu 添加到docker组...
[INFO] Docker测试成功！
[INFO] Docker Compose验证成功！

=== 安装完成 ===
[INFO] Docker版本：Docker version 24.0.7, build afdd53b
[INFO] Docker Compose版本：Docker Compose version v2.23.0

[INFO] 常用命令：
[INFO]   查看Docker状态：sudo systemctl status docker
[INFO]   启动Docker：sudo systemctl start docker
[INFO]   停止Docker：sudo systemctl stop docker
[INFO]   查看Docker镜像：docker images
[INFO]   查看运行的容器：docker ps

[WARN] 注意：请重新登录或运行 'newgrp docker' 以使用户组更改生效

[INFO] 清理远程临时文件...
[INFO] 清理临时SSH密钥文件

=== 安装完成 ===
[INFO] Docker和Docker Compose已成功安装到远程服务器
[INFO] 请在远程服务器上运行 'newgrp docker' 或重新登录以使用户组更改生效
```

## 安装内容

该脚本将在远程服务器上安装：

1. **Docker CE** (Community Edition)
   - 最新稳定版本
   - 自动启动和开机自启
   - 配置用户权限

2. **Docker Compose**
   - 最新版本（从GitHub获取）
   - 安装到 `/usr/local/bin/docker-compose`
   - 创建符号链接到 `/usr/bin/docker-compose`

3. **系统配置**
   - 添加用户到docker组
   - 启用Docker服务
   - 验证安装完整性

## 安装后验证

安装完成后，您可以在远程服务器上运行以下命令验证：

```bash
# 检查Docker版本
docker --version

# 检查Docker Compose版本
docker-compose --version

# 测试Docker（需要重新登录或运行 newgrp docker）
docker run hello-world

# 检查Docker服务状态
sudo systemctl status docker
```

## 常见问题

### 1. SSH连接失败

**错误信息：** `SSH连接失败，请检查服务器地址、用户名、端口和SSH密钥`

**解决方案：**
- 确认服务器IP地址正确
- 确认SSH用户名和端口正确
- 确认私钥内容正确且对应的公钥已添加到服务器
- 检查服务器SSH服务是否运行

### 2. 权限不足

**错误信息：** `sudo: no tty present and no askpass program specified`

**解决方案：**
- 确保SSH用户具有sudo权限
- 配置用户免密sudo（推荐）：
  ```bash
  echo "username ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/username
  ```

### 3. Docker组权限

**安装后无法运行docker命令**

**解决方案：**
```bash
# 重新登录SSH会话，或者运行：
newgrp docker
```

### 4. 网络连接问题

**Docker镜像下载失败**

**解决方案：**
- 检查服务器网络连接
- 配置Docker镜像加速器（如阿里云、腾讯云等）

## 安全注意事项

1. **私钥安全**
   - 确保脚本文件权限正确（建议600）
   - 不要将包含私钥的脚本提交到公共代码仓库
   - 定期轮换SSH密钥

2. **服务器安全**
   - 使用强密码或仅密钥认证
   - 限制SSH访问IP范围
   - 定期更新系统安全补丁

3. **Docker安全**
   - 不要以root用户运行容器
   - 定期更新Docker和镜像
   - 使用官方或可信的镜像源

## 自定义配置

您可以根据需要修改脚本中的默认配置：

```bash
# 默认配置
DEFAULT_SERVER_IP="your-server-ip"
DEFAULT_SSH_USER="ubuntu"
DEFAULT_SSH_PORT="22"
```

## 故障排除

如果安装过程中遇到问题，可以：

1. 检查脚本输出的错误信息
2. 手动SSH到服务器检查安装状态
3. 查看系统日志：`sudo journalctl -u docker`
4. 重新运行脚本（幂等性设计，可安全重复执行）

## 技术支持

如需技术支持，请提供：
- 完整的错误输出
- 服务器系统信息
- 网络环境描述
