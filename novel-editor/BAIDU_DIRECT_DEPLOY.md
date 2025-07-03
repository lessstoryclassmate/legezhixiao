# 🚀 百度云服务器直接部署指南

## 📋 快速部署概述

本指南提供三种方式直接部署AI小说编辑器到百度云服务器 (106.13.216.179)：

## 🎯 方式一：一键自动部署（推荐）

### 使用自动部署脚本
```bash
# 在本地项目目录执行
chmod +x deploy-baidu-direct.sh
./deploy-baidu-direct.sh
```

### 脚本功能
- ✅ 自动检查本地环境
- ✅ 创建百度云专用配置
- ✅ 上传文件到服务器
- ✅ 远程执行部署命令
- ✅ 自动验证部署结果

## 🔧 方式二：手动SSH部署

### 步骤1：SSH连接到服务器
```bash
ssh root@106.13.216.179
```

### 步骤2：准备部署环境
```bash
# 创建项目目录
mkdir -p /root/novel-editor
cd /root/novel-editor

# 安装Docker (如果未安装)
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
systemctl start docker
systemctl enable docker

# 安装Docker Compose
curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
```

### 步骤3：从GitHub获取代码
```bash
# 克隆仓库
git clone https://github.com/lessstoryclassmate/legezhixiao.git
cp -r legezhixiao/novel-editor/* ./
```

### 步骤4：配置环境变量
```bash
# 创建生产环境配置
cat > .env.prod << 'EOF'
# 应用配置
DEBUG=false
ENVIRONMENT=production

# 数据库配置 (百度云内网)
DATABASE_PORT=3306
DATABASE_SYSTEMIP=172.16.16.3
DATABASE_SYSTEM=novel_data
DATABASE_USER=lkr
DATABASE_PASSWORD=Lekairong350702
DATABASE_NOVELIP=172.16.16.2
DATABASE_NOVELDATA=novel_user_data
DATABASE_NOVELUSER=novel_data_user
DATABASE_NOVELUSER_PASSWORD=Lekairong350702

# AI服务配置
SILICONFLOW_API_KEY=sk-mjithqmjwccqgffouexthbavtnvftwkqjludpcxhrmeztcib
SILICONFLOW_API_URL=https://api.siliconflow.cn/v1
DEFAULT_AI_MODEL=deepseek-ai/DeepSeek-V3

# 安全配置
SECRET_KEY=baidu-cloud-novel-editor-secret-key-2025
EOF
```

### 步骤5：启动服务
```bash
# 构建并启动
docker-compose -f docker-compose.prod.yml up -d --build

# 检查状态
docker-compose ps
```

## 🎯 访问信息

### 部署成功后的访问地址
- **前端页面**: http://106.13.216.179
- **API文档**: http://106.13.216.179:8000/docs
- **健康检查**: http://106.13.216.179:8000/health

---

**🎉 现在可以直接部署到百度云服务器了！**
