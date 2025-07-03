# AI小说编辑器 - 容器化部署指南

## 📋 项目概述

AI小说编辑器是一个基于DeepSeek-V3大语言模型的智能小说创作平台，支持完整的容器化部署，可轻松部署到云服务器。

### 🏗️ 技术架构

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   前端服务       │    │   后端API       │    │   AI服务         │
│  React + Vite   │◄──►│   FastAPI      │◄──►│  DeepSeek-V3    │
│  Nginx (80)     │    │  Python (8000) │    │  SiliconFlow    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 ▼
                    ┌─────────────────┐
                    │   数据库服务     │
                    │  SQLite/MySQL   │
                    └─────────────────┘
```

### 🎯 核心功能

- **AI内容生成**: 基于DeepSeek-V3的高质量小说创作
- **章节分析**: 智能分析文本结构和质量
- **剧情建议**: AI驱动的情节发展建议
- **文本优化**: 自动优化文本表达和文学性
- **人物档案**: 智能生成立体人物设定

## 🚀 快速部署

### 方法一：生产环境部署

```bash
# 1. 克隆仓库
git clone <your-repo-url>
cd novel-editor

# 2. 配置环境变量
cp .env.prod.example .env.prod
vim .env.prod  # 编辑配置文件

# 3. 一键部署
chmod +x deploy-prod.sh
./deploy-prod.sh prod
```

### 方法二：开发环境部署

```bash
# 1. 启动开发环境
./deploy-prod.sh dev

# 2. 查看服务状态
./deploy-prod.sh status

# 3. 查看日志
./deploy-prod.sh logs
```

### 方法三：手动部署

```bash
# 生产环境
docker-compose -f docker-compose.prod.yml up -d

# 开发环境
docker-compose -f docker-compose.dev.yml up -d
```

## 🔧 环境配置

### 必需的环境变量

```bash
# AI服务配置
SILICONFLOW_API_KEY=your_api_key_here
DEFAULT_AI_MODEL=deepseek-ai/DeepSeek-V3

# 数据库配置（生产环境）
DATABASE_URL=mysql://user:pass@host:port/dbname

# 应用配置
DEBUG=false  # 生产环境设为false
```

### 获取SiliconFlow API密钥

1. 访问 [SiliconFlow官网](https://siliconflow.cn)
2. 注册账号并申请API密钥
3. 将密钥填入环境变量配置文件

## 📁 部署文件结构

```
novel-editor/
├── docker-compose.prod.yml     # 生产环境配置
├── docker-compose.dev.yml      # 开发环境配置
├── deploy-prod.sh              # 一键部署脚本
├── .env.prod.example           # 生产环境变量模板
├── .env.dev                    # 开发环境变量
├── nginx/
│   └── nginx.conf              # Nginx配置文件
├── backend/
│   ├── Dockerfile              # 后端容器配置
│   └── requirements.txt        # Python依赖
├── frontend/
│   └── Dockerfile              # 前端容器配置
└── DEPLOYMENT_SUMMARY.md       # 详细部署文档
```

## 🎛️ 部署脚本功能

`deploy-prod.sh` 支持以下命令：

```bash
./deploy-prod.sh prod     # 部署生产环境
./deploy-prod.sh dev      # 部署开发环境
./deploy-prod.sh status   # 查看服务状态
./deploy-prod.sh logs     # 查看服务日志
./deploy-prod.sh restart  # 重启所有服务
./deploy-prod.sh stop     # 停止所有服务
./deploy-prod.sh clean    # 清理容器和镜像
./deploy-prod.sh health   # 健康检查
```

## 🔍 服务验证

部署完成后，访问以下地址验证服务：

- **前端页面**: http://your-server
- **API文档**: http://your-server:8000/docs
- **健康检查**: http://your-server:8000/health

## 🌐 云服务器部署

### 环境要求

- **操作系统**: Ubuntu 20.04+ / CentOS 7+
- **内存**: 最少2GB，推荐4GB+
- **存储**: 最少10GB可用空间
- **网络**: 能够访问GitHub和SiliconFlow API

### 部署步骤

1. **安装Docker和Docker Compose**
```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
sudo usermod -aG docker $USER

# 安装Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

2. **克隆并部署**
```bash
git clone <your-repo-url>
cd novel-editor
cp .env.prod.example .env.prod
# 编辑.env.prod文件，填入实际配置
./deploy-prod.sh prod
```

3. **配置防火墙**
```bash
# 开放HTTP端口
sudo ufw allow 80
sudo ufw allow 8000  # 如果需要直接访问API
```

## 📊 监控与维护

### 查看服务状态
```bash
docker-compose ps
./deploy-prod.sh status
```

### 查看日志
```bash
docker-compose logs -f
./deploy-prod.sh logs
```

### 备份数据
```bash
# 备份SQLite数据库
docker cp novel-editor-backend-1:/app/novel_editor.db ./backup/

# 备份MySQL数据库
docker exec mysql-container mysqldump -u user -p dbname > backup.sql
```

## 🔒 安全配置

### 生产环境安全检查

1. **更改默认密码**: 修改数据库和管理员密码
2. **配置HTTPS**: 使用Let's Encrypt或其他SSL证书
3. **设置防火墙**: 只开放必要端口
4. **API密钥安全**: 妥善保管SiliconFlow API密钥
5. **定期更新**: 保持依赖库和系统更新

## 🆘 故障排除

### 常见问题

1. **容器启动失败**
   - 检查环境变量配置
   - 查看容器日志: `docker-compose logs`
   - 验证API密钥有效性

2. **AI服务调用失败**
   - 确认SiliconFlow API密钥正确
   - 检查网络连接
   - 验证模型名称: `deepseek-ai/DeepSeek-V3`

3. **前端无法访问**
   - 检查Nginx配置
   - 验证端口映射
   - 确认前端构建成功

### 调试命令

```bash
# 进入后端容器
docker exec -it novel-editor-backend-1 bash

# 测试AI服务
python test_deepseek_v3.py

# 检查端口占用
netstat -tlnp | grep :80
```

## 📞 支持

如有问题，请检查：

1. [DEPLOYMENT_SUMMARY.md](./DEPLOYMENT_SUMMARY.md) - 详细部署文档
2. [项目Issues](https://github.com/your-repo/issues) - 提交问题
3. Docker日志输出进行问题诊断

---

**🎉 享受AI驱动的小说创作之旅！**
