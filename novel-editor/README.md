# AI小说编辑器 (Novel Editor)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue)](https://www.docker.com/)
[![AI](https://img.shields.io/badge/AI-DeepSeek--V3-green)](https://siliconflow.cn/)

一个基于DeepSeek-V3大语言模型的智能小说创作平台，支持AI辅助创作、章节分析、剧情建议等功能，完整的容器化部署解决方案。

## ✨ 特性

- 🤖 **AI智能创作** - 基于DeepSeek-V3的高质量小说内容生成
- 📊 **章节分析** - 深度分析文本结构、情感和文学技巧
- � **剧情建议** - AI驱动的故事发展建议
- ✨ **文本优化** - 自动提升文本的文学性和表现力
- 👥 **人物档案** - 智能生成立体的人物设定
- 🐳 **容器化部署** - 完整的Docker容器化解决方案
- 🎭 **剧情管理**: 多线程剧情规划和伏笔追踪
- 🌍 **世界观构建**: 完整的世界观设定和一致性校验
- 📊 **数据分析**: 创作统计和AI分析报告

## 技术架构

### 前端
- **框架**: Vue 3 + Composition API
- **UI库**: Element Plus
- **状态管理**: Pinia
- **路由**: Vue Router 4
- **构建工具**: Vite
- **样式**: SCSS + VSCode主题

### 后端
- **框架**: FastAPI
- **数据库**: MySQL 8.0 (双数据库配置)
- **ORM**: SQLAlchemy
- **认证**: JWT
- **AI服务**: SiliconFlow API
- **异步**: httpx

### 部署
- **容器化**: Docker + Docker Compose
- **编排**: Kubernetes (K3S)
- **入口**: Ingress
- **负载均衡**: Traefik

## 快速开始

### 环境要求

- Python 3.11+
- Node.js 18+
- Yarn (包管理器)
- MySQL 8.0
- Docker (可选)

### 后端启动

```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### 前端启动

```bash
cd frontend
yarn install
yarn dev
```

### 环境初始化

```bash
# 安装和配置yarn
./setup-yarn.sh

# 启动完整开发环境
./start-dev.sh
```

### Docker启动

```bash
docker-compose up -d
```

## 配置说明

### 环境变量

参考 `backend/.env` 文件配置：

- 数据库连接信息
- SiliconFlow API密钥
- JWT密钥
- 其他应用配置

### 数据库配置

系统使用双数据库架构：
- **系统数据库**: 存储应用元数据、用户信息等
- **用户数据库**: 存储用户创作内容

## API文档

启动后端服务后，访问 `http://localhost:8000/docs` 查看完整的API文档。

## 主要功能模块

### 1. 用户认证
- 用户注册/登录
- JWT令牌管理
- 权限控制

### 2. 小说管理
- 创建/编辑/删除小说
- 章节组织
- 版本控制

### 3. AI助手
- 内容生成
- 文本分析
- 剧情建议
- 文本优化

### 4. 人物管理
- 人物档案
- 关系网络
- 成长轨迹

### 5. 剧情管理
- 主线/支线规划
- 伏笔设置
- 节点管理

### 6. 世界观设定
- 规则体系
- 地理设定
- 文化背景

## 部署指南

### Kubernetes部署

1. 构建镜像:
```bash
docker build -t novel-editor-backend:latest ./backend
docker build -t novel-editor-frontend:latest ./frontend
```

2. 部署到K8S:
```bash
kubectl apply -f deployment/k8s-manifest.yaml
```

3. 配置Ingress根据实际域名调整

## 开发指南

### 目录结构

```
novel-editor/
├── backend/                 # 后端代码
│   ├── app/
│   │   ├── models/         # 数据模型
│   │   ├── routers/        # API路由
│   │   ├── services/       # 业务逻辑
│   │   ├── schemas/        # Pydantic模型
│   │   └── utils/          # 工具函数
│   ├── main.py             # 应用入口
│   └── requirements.txt    # Python依赖
├── frontend/               # 前端代码
│   ├── src/
│   │   ├── components/     # Vue组件
│   │   ├── views/          # 页面视图
│   │   ├── stores/         # 状态管理
│   │   └── utils/          # 工具函数
│   └── package.json        # Node.js依赖
└── deployment/             # 部署配置
    └── k8s-manifest.yaml   # K8S部署文件
```

### 贡献指南

1. Fork项目
2. 创建功能分支
3. 提交更改
4. 创建Pull Request

## 许可证

MIT License

## 支持

如有问题，请创建Issue或联系开发团队。
