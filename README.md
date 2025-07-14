# AI小说内容编辑器

基于Vue3 + FastAPI + MongoDB的智能小说创作平台，集成SiliconFlow API的deepseek-v3模型，提供AI辅助的小说创作和编辑功能。

## 🎉 项目状态
**✅ 项目结构已完成清理和验证 (2025-07-12)**
- 已修复所有空文件问题
- 优化为克隆模式部署
- 配置Docker镜像加速
- 完成项目完整性验证
- 移除冗余工作流和配置

## 📦 快速部署
```bash
# 1. 克隆项目
git clone <repository-url>
cd legezhixiao

# 2. 配置环境变量
cp .env.example .env
# 编辑 .env 文件配置数据库等信息

# 3. 一键部署 (生产环境)
docker-compose -f docker-compose.production.yml up -d
```

## 项目架构

```
├── frontend/          # Vue3前端
├── backend/           # FastAPI后端
├── database/          # MongoDB配置
├── docker/            # Docker配置文件
├── scripts/           # 部署脚本
├── .github/           # GitHub Actions配置
└── docs/              # 项目文档
```

## 技术栈

- **前端**: Vue3 + TypeScript + Vite + Element Plus
- **后端**: FastAPI + Python 3.11 + Motor (MongoDB异步驱动)
- **数据库**: MongoDB + MySQL 8.0
- **AI集成**: SiliconFlow API (deepseek-v3)
- **容器化**: Docker + Docker Compose
- **部署**: GitHub Actions + 百度云服务器

## 部署方式

### 1. SSH密钥配置

**重要说明**：所有部署脚本都需要SSH密钥预先存在，不会自动生成密钥以避免覆盖现有配置。

首先配置SSH密钥用于GitHub认证（**必须使用指定路径**）：

```bash
# 生成SSH密钥（必须使用此路径）
ssh-keygen -t ed25519 -f /root/.ssh/id_ed25519 -N ''

# 查看公钥内容
cat /root/.ssh/id_ed25519.pub

# 复制公钥内容，访问以下地址添加到GitHub
# https://github.com/settings/ssh/new
```

**注意：SSH密钥必须存放在 `/root/.ssh/id_ed25519` 路径，所有部署脚本都依赖此路径。**

### 密钥验证

在部署前验证SSH配置：

```bash
# 检查SSH密钥冲突
./scripts/check-ssh-conflicts.sh

# 验证SSH配置
./scripts/validate-ssh-config.sh

# 测试GitHub连接
ssh -T git@github.com
```

### 2. 一键部署

```bash
# 下载统一部署脚本
curl -O https://raw.githubusercontent.com/lessstoryclassmate/legezhixiao/main/scripts/unified-deploy.sh
chmod +x unified-deploy.sh

# 执行完整部署
./unified-deploy.sh --deploy
```

### 3. 分步部署

```bash
# 1. 配置SSH认证
./unified-deploy.sh --setup-ssh

# 2. 配置Docker镜像
./unified-deploy.sh --setup-docker

# 3. 健康检查
./unified-deploy.sh --health-check
```

### 2. GitHub Actions自动部署

推送代码到main分支后，自动触发部署流程：
1. 构建Docker镜像
2. 推送到百度云服务器
3. 更新容器服务

## 快速开始

1. 配置环境变量
2. 运行 `docker-compose up -d`
3. 访问 http://localhost:80

## 功能特性

- 🎯 **章节内容管理**: 智能解析、可视化操作、跨模块校验
- 👥 **人物设定系统**: 立体化角色建模、关系网络分析
- 📖 **剧情管理中枢**: 三维剧情架构、伏笔生命周期管理
- 🌍 **世界设定系统**: 四维世界模型、智能推演
- 🤖 **AI智能助手**: SiliconFlow API集成，实时创作建议
- 👤 **用户系统**: 注册登录、多人协作支持
