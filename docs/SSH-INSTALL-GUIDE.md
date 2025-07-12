# SSH密钥安装Docker指南

## 🎯 概述
通过SSH密钥认证远程连接服务器，自动安装Docker和Docker Compose。

## 📁 脚本文件
- `scripts/ssh-install-docker.sh` - 通用SSH安装脚本
- `scripts/quick-install-with-key.sh` - 使用内置密钥的快速安装脚本

## 🚀 使用方法

### 方法一：使用快速安装脚本（推荐）

1. **编辑配置**
```bash
# 编辑快速安装脚本
nano scripts/quick-install-with-key.sh

# 修改第6行的服务器IP
SERVER_IP="your_server_ip_here"  # 改为您的实际服务器IP
```

2. **执行安装**
```bash
# 在项目根目录下执行
bash scripts/quick-install-with-key.sh
```

### 方法二：使用通用安装脚本

```bash
# 语法
bash scripts/ssh-install-docker.sh <服务器IP> <用户名> <私钥文件路径>

# 示例
bash scripts/ssh-install-docker.sh 192.168.1.100 root /path/to/private_key.pem
```

## 📋 脚本功能

### 🔍 连接检查
- ✅ 验证SSH连接
- ✅ 检查私钥文件权限
- ✅ 测试服务器可达性

### 🐳 Docker安装
- ✅ 检测已安装的Docker版本
- ✅ 自动安装Docker CE最新版
- ✅ 配置Docker服务自启动
- ✅ 添加用户到docker组

### 🐙 Docker Compose安装
- ✅ 检测已安装的版本
- ✅ 自动获取最新版本
- ✅ 下载并安装到系统路径
- ✅ 创建符号链接

### ⚙️ 系统优化
- ✅ 设置vm.max_map_count参数（MongoDB需要）
- ✅ 配置Docker服务
- ✅ 测试安装结果

## 🔧 服务器要求

### 系统支持
- ✅ Ubuntu 18.04+
- ✅ Debian 9+
- ⚠️ 其他系统需要手动确认

### 网络要求
- ✅ 能访问Docker官方仓库
- ✅ 能访问GitHub（下载Docker Compose）
- ✅ SSH端口22可访问

### 权限要求
- ✅ 具有sudo权限或root权限
- ✅ 能安装系统包

## 🔐 安全注意事项

### 私钥安全
- 🔒 脚本会自动设置私钥文件权限为600
- 🔒 快速安装脚本使用临时密钥文件
- 🔒 安装完成后自动清理临时文件

### 连接安全
- ✅ 使用SSH密钥认证（比密码更安全）
- ✅ 支持ConnectTimeout超时设置
- ✅ 使用BatchMode避免交互提示

## 📊 安装验证

### 检查Docker
```bash
# 连接服务器检查
ssh -i your_private_key user@server_ip

# 检查Docker版本
docker --version

# 检查Docker服务状态
sudo systemctl status docker

# 测试Docker运行
docker run hello-world
```

### 检查Docker Compose
```bash
# 检查版本
docker-compose --version

# 测试命令
docker-compose --help
```

## 🐛 故障排除

### SSH连接失败
```bash
# 1. 检查服务器IP和端口
ping your_server_ip
nc -zv your_server_ip 22

# 2. 检查私钥文件
ls -la /path/to/private_key
chmod 600 /path/to/private_key

# 3. 手动测试SSH连接
ssh -i /path/to/private_key user@server_ip
```

### Docker安装失败
```bash
# 1. 检查系统版本
lsb_release -a

# 2. 检查网络连接
curl -fsSL https://download.docker.com/linux/ubuntu/gpg

# 3. 手动安装测试
sudo apt-get update
sudo apt-get install docker-ce
```

### 权限问题
```bash
# 1. 检查用户组
groups $USER

# 2. 重新添加到docker组
sudo usermod -aG docker $USER

# 3. 重新登录或刷新组
newgrp docker
```

## 🔄 后续操作

### 部署应用
安装完成后，可以：
1. 上传docker-compose.yml文件
2. 配置环境变量
3. 启动AI小说编辑器服务

### 维护操作
```bash
# 更新Docker
sudo apt-get update && sudo apt-get upgrade docker-ce

# 更新Docker Compose
# (脚本会自动安装最新版本)

# 清理Docker资源
docker system prune -f
```

## 📞 支持信息

如遇问题，请提供：
- 服务器系统信息: `lsb_release -a`
- SSH连接测试结果
- 脚本执行日志
- 错误信息截图
