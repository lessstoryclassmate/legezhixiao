AI小说内容编辑器项目结构
======================

novel-editor/
├── README.md                    # 项目说明文档
├── deploy.sh                    # K8S部署脚本
├── start-dev.sh                 # 开发环境启动脚本
├── docker-compose.yml           # Docker Compose配置
│
├── backend/                     # FastAPI后端
│   ├── Dockerfile              # 后端Docker镜像构建文件
│   ├── requirements.txt        # Python依赖
│   ├── .env                    # 环境变量配置
│   ├── main.py                 # FastAPI应用入口
│   │
│   └── app/                    # 应用代码
│       ├── __init__.py
│       ├── database.py         # 数据库连接配置
│       │
│       ├── models/             # SQLAlchemy数据模型
│       │   ├── __init__.py
│       │   └── user.py         # 用户、小说、章节等模型
│       │
│       ├── schemas/            # Pydantic数据模式
│       │   ├── __init__.py
│       │   └── schemas.py      # API请求/响应模式
│       │
│       ├── routers/            # API路由
│       │   ├── __init__.py
│       │   ├── auth.py         # 认证相关路由
│       │   ├── users.py        # 用户管理路由
│       │   ├── novels.py       # 小说管理路由
│       │   ├── chapters.py     # 章节管理路由
│       │   ├── characters.py   # 人物管理路由
│       │   ├── plots.py        # 剧情管理路由
│       │   ├── worlds.py       # 世界观管理路由
│       │   └── ai_assistant.py # AI助手路由
│       │
│       ├── services/           # 业务逻辑服务
│       │   ├── __init__.py
│       │   ├── auth_service.py # 认证服务
│       │   └── ai_service.py   # AI服务(SiliconFlow集成)
│       │
│       ├── middleware/         # 中间件
│       │   └── error_handler.py # 错误处理中间件
│       │
│       └── utils/              # 工具函数
│           └── __init__.py
│
├── frontend/                   # Vue3前端
│   ├── Dockerfile              # 前端Docker镜像构建文件
│   ├── nginx.conf              # Nginx配置
│   ├── package.json            # Node.js依赖
│   ├── vite.config.js          # Vite构建配置
│   ├── index.html              # HTML模板
│   │
│   └── src/                    # 源代码
│       ├── main.js             # 应用入口
│       ├── App.vue             # 根组件
│       │
│       ├── router/             # 路由配置
│       │   └── index.js        # Vue Router配置
│       │
│       ├── stores/             # Pinia状态管理
│       │   └── auth.js         # 认证状态管理
│       │
│       ├── views/              # 页面视图
│       │   ├── Home.vue        # 首页
│       │   ├── Login.vue       # 登录页
│       │   ├── Register.vue    # 注册页
│       │   ├── Editor.vue      # 编辑器页面
│       │   ├── Novels.vue      # 小说管理页
│       │   └── Settings.vue    # 设置页
│       │
│       ├── components/         # Vue组件
│       │   └── (待开发)
│       │
│       ├── utils/              # 工具函数
│       │   └── api.js          # API调用封装
│       │
│       └── assets/             # 静态资源
│           └── styles/
│               └── main.scss   # 主样式文件(VSCode主题)
│
└── deployment/                 # 部署配置
    └── k8s-manifest.yaml       # Kubernetes部署清单

核心功能模块
============

1. 用户认证系统
   - JWT令牌认证
   - 用户注册/登录
   - 权限管理

2. 小说管理系统
   - 小说创建/编辑/删除
   - 章节组织管理
   - 版本控制

3. AI智能助手
   - SiliconFlow API集成
   - deepseek-v3和千问模型
   - 内容生成/分析/优化
   - 剧情建议

4. 编辑器功能
   - VSCode风格界面
   - 实时编辑和保存
   - 章节导航
   - AI辅助侧边栏

5. 人物设定系统
   - 人物档案管理
   - 关系网络图
   - 智能生成建议

6. 剧情管理系统
   - 主线/支线规划
   - 伏笔设置和追踪
   - 剧情节点管理

7. 世界观构建
   - 规则体系设定
   - 地理文化背景
   - 一致性校验

技术特点
========

前端技术栈:
- Vue 3 + Composition API
- Element Plus UI库
- Pinia状态管理
- Vue Router 4路由
- Vite构建工具
- SCSS样式预处理
- VSCode主题风格

后端技术栈:
- FastAPI异步框架
- SQLAlchemy ORM
- MySQL双数据库
- JWT认证
- httpx异步HTTP客户端
- SiliconFlow AI API

部署方案:
- Docker容器化
- Kubernetes编排
- Ingress负载均衡
- 支持K3S集群

开发流程
========

1. 环境准备
   - Python 3.11+
   - Node.js 18+
   - Yarn包管理器
   - MySQL 8.0

2. 本地开发
   ```bash
   # 初始化yarn环境
   ./setup-yarn.sh
   
   # 启动开发环境
   ./start-dev.sh
   ```

3. Docker部署
   ```bash
   docker-compose up -d
   ```

4. K8S生产部署
   ```bash
   ./deploy.sh
   ```

访问地址
========
- 前端界面: http://localhost:3000
- 后端API: http://localhost:8000
- API文档: http://localhost:8000/docs

配置说明
========
- 后端配置: backend/.env
- 数据库配置: 双数据库架构
- AI配置: SiliconFlow API密钥
- K8S配置: deployment/k8s-manifest.yaml
