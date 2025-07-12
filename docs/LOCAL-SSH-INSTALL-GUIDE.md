# 本地SSH连接服务器安装Docker指南

## 🎯 脚本说明
`scripts/local-ssh-install.sh` - 从本地终端通过SSH连接到服务器公网IP，自动安装Docker和Docker Compose

## 🚀 快速使用

### 步骤1: 设置服务器IP
编辑脚本文件，修改第6行：
```bash
nano scripts/local-ssh-install.sh

# 将这行：
DEFAULT_SERVER_IP="your_server_public_ip"
# 改为：
DEFAULT_SERVER_IP="您的实际服务器公网IP"
```

### 步骤2: 执行安装
```bash
# 方法1: 使用默认配置
bash scripts/local-ssh-install.sh

# 方法2: 指定服务器IP
bash scripts/local-ssh-install.sh 192.168.1.100

# 方法3: 指定IP和用户名
bash scripts/local-ssh-install.sh 192.168.1.100 ubuntu

# 方法4: 指定IP、用户名和端口
bash scripts/local-ssh-install.sh 192.168.1.100 ubuntu 2222
```

## 📋 脚本功能

### ✅ 自动配置
- 内置SSH私钥（无需额外配置）
- 自动创建临时密钥文件
- 执行完成后自动清理临时文件

### 🔍 连接验证
- 测试SSH连接可达性
- 获取服务器系统信息
- 验证网络连通性

### 🐳 Docker安装
- 自动检测已安装的Docker
- 安装Docker CE最新版本
- 配置Docker服务自启动
- 优化Docker daemon配置

### 🐙 Docker Compose安装
- 自动获取最新版本
- 支持多架构（x86_64, aarch64）
- 创建系统符号链接

### ⚙️ 系统优化
- 设置vm.max_map_count参数
- 配置Docker日志轮转
- 优化存储驱动设置

## 🔧 使用要求

### 本地环境
- Linux/macOS/WSL终端
- 具有SSH客户端
- 具有SCP命令

### 服务器要求
- Ubuntu 18.04+ 或 Debian 9+
- 开放SSH端口（默认22）
- 具有root权限或sudo权限
- 网络能访问Docker官方仓库

### 网络要求
- 服务器具有公网IP
- 本地能访问服务器公网IP
- 服务器能访问外网（下载Docker）

## 📊 执行流程

```
1. 检查参数配置
   ↓
2. 创建临时SSH密钥
   ↓  
3. 测试SSH连接
   ↓
4. 获取服务器信息
   ↓
5. 上传安装脚本
   ↓
6. 远程执行安装
   ↓
7. 验证安装结果
   ↓
8. 清理临时文件
```

## 🔐 安全特性

- 使用SSH密钥认证（比密码更安全）
- 临时密钥文件权限600
- 执行完成后自动清理临时文件
- 支持自定义SSH端口

## 🐛 故障排除

### SSH连接失败
```bash
# 检查网络连通性
ping your_server_ip

# 检查SSH端口
nc -zv your_server_ip 22

# 手动测试SSH连接
ssh -p 22 root@your_server_ip
```

### 私钥权限问题
```bash
# 检查私钥文件权限
ls -la /tmp/ai_server_key_*.pem

# 手动设置权限
chmod 600 /tmp/ai_server_key_*.pem
```

### Docker安装失败
```bash
# 连接服务器手动检查
ssh root@your_server_ip

# 检查系统版本
lsb_release -a

# 检查网络连接
curl -fsSL https://download.docker.com/linux/ubuntu/gpg
```

## 📝 使用示例

### 示例1: 默认配置
```bash
# 1. 编辑脚本设置服务器IP
nano scripts/local-ssh-install.sh
# 修改: DEFAULT_SERVER_IP="192.168.1.100"

# 2. 执行安装
bash scripts/local-ssh-install.sh
```

### 示例2: 命令行指定
```bash
# 直接指定服务器IP
bash scripts/local-ssh-install.sh 192.168.1.100

# 指定非标准SSH端口
bash scripts/local-ssh-install.sh 192.168.1.100 root 2222
```

### 示例3: Ubuntu用户
```bash
# Ubuntu系统通常使用ubuntu用户
bash scripts/local-ssh-install.sh 192.168.1.100 ubuntu
```

## 🎯 安装完成后

### 验证安装
```bash
# 连接服务器验证
ssh root@your_server_ip

# 检查Docker
docker --version
docker ps

# 检查Docker Compose  
docker-compose --version
```

### 开始使用
```bash
# 1. 上传项目文件
scp -r . root@your_server_ip:/opt/ai-novel-editor/

# 2. 连接服务器
ssh root@your_server_ip

# 3. 进入项目目录
cd /opt/ai-novel-editor

# 4. 启动服务
docker-compose up -d
```

## 💡 提示

- 脚本执行时间约3-5分钟
- 首次运行会下载较多文件
- 建议在网络良好的环境下执行
- 如遇问题可重复执行安装脚本
