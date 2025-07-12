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

### 1. 克隆仓库部署

```bash
# 克隆项目
git clone https://github.com/your-username/ai-novel-editor.git
cd ai-novel-editor

# 启动服务
chmod +x scripts/deploy.sh
./scripts/deploy.sh
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
