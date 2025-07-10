# 开发环境配置

## 项目结构

```
ai-novel-editor/
├── README.md                    # 项目说明
├── .env.example                 # 环境变量示例
├── .gitignore                   # Git忽略文件
├── docker-compose.yml           # Docker编排文件
├── start.sh                     # 快速启动脚本
├── frontend/                    # 前端项目
│   ├── Dockerfile              # 前端Docker文件
│   ├── package.json            # 前端依赖
│   └── nginx.conf              # Nginx配置
├── backend/                     # 后端项目
│   ├── Dockerfile              # 后端Docker文件
│   ├── requirements.txt        # Python依赖
│   ├── main.py                 # 主应用入口
│   └── app/                    # 应用代码
│       ├── core/               # 核心配置
│       ├── database/           # 数据库连接
│       └── routes/             # API路由
├── database/                    # 数据库配置
│   └── mongo-init.js           # MongoDB初始化脚本
├── scripts/                     # 部署脚本
│   ├── deploy.sh               # 本地部署脚本
│   └── github-deploy.sh        # GitHub克隆部署脚本
├── .github/                     # GitHub Actions
│   └── workflows/
│       └── deploy.yml          # 自动部署流程
└── docs/                        # 文档
    └── deployment.md           # 部署说明
```

## 快速开始

### 1. 环境准备

确保系统已安装：
- Docker
- Docker Compose
- Git

### 2. 克隆项目

```bash
git clone https://github.com/your-username/ai-novel-editor.git
cd ai-novel-editor
```

### 3. 配置环境变量

```bash
cp .env.example .env
# 编辑 .env 文件，填写必要配置
```

### 4. 启动服务

```bash
# 使用快速启动脚本
./start.sh

# 或手动启动
docker-compose up -d
```

### 5. 访问应用

- 前端：http://localhost:80
- 后端API：http://localhost:8000
- API文档：http://localhost:8000/docs

## 开发说明

### 前端开发

前端使用Vue3 + TypeScript + Vite构建，主要特性：

- **组件化开发**：模块化UI组件
- **状态管理**：Pinia状态管理
- **路由管理**：Vue Router
- **UI框架**：Element Plus
- **图表库**：ECharts
- **编辑器**：CodeMirror
- **主题**：VSCode风格设计

### 后端开发

后端使用FastAPI + MongoDB构建，主要特性：

- **异步支持**：全异步API设计
- **数据验证**：Pydantic模型验证
- **JWT认证**：用户认证系统
- **MongoDB**：NoSQL数据库
- **Redis缓存**：会话和缓存管理
- **AI集成**：SiliconFlow API集成

### 数据库设计

#### MongoDB集合结构

1. **users** - 用户信息
2. **novels** - 小说基本信息
3. **chapters** - 章节内容
4. **characters** - 人物设定
5. **worldviews** - 世界观设定
6. **plots** - 剧情管理
7. **foreshadows** - 伏笔管理
8. **ai_conversations** - AI对话记录

### API接口

#### 认证相关
- `POST /auth/register` - 用户注册
- `POST /auth/login` - 用户登录
- `GET /auth/me` - 获取当前用户信息

#### 小说管理
- `POST /novels/` - 创建小说
- `GET /novels/` - 获取小说列表
- `GET /novels/{novel_id}` - 获取单个小说
- `PUT /novels/{novel_id}` - 更新小说
- `DELETE /novels/{novel_id}` - 删除小说

#### 章节管理
- `POST /chapters/` - 创建章节
- `GET /chapters/` - 获取章节列表
- `GET /chapters/{chapter_id}` - 获取单个章节
- `PUT /chapters/{chapter_id}` - 更新章节
- `DELETE /chapters/{chapter_id}` - 删除章节
- `GET /chapters/{chapter_id}/dna` - 获取章节DNA分析

#### 人物管理
- `POST /characters/` - 创建人物
- `GET /characters/` - 获取人物列表
- `GET /characters/{character_id}` - 获取单个人物
- `PUT /characters/{character_id}` - 更新人物
- `DELETE /characters/{character_id}` - 删除人物
- `GET /characters/{character_id}/relationships` - 获取人物关系

#### AI助手
- `POST /ai/chat` - AI对话
- `GET /ai/conversations` - 获取对话历史
- `POST /ai/suggestions` - 获取智能建议
- `POST /ai/analyze` - 内容分析

## 部署方式

### 1. 本地开发部署

```bash
# 快速启动
./start.sh

# 或分步执行
docker-compose up -d
```

### 2. 服务器部署

```bash
# 使用部署脚本
./scripts/deploy.sh

# 或使用GitHub克隆部署
curl -fsSL https://raw.githubusercontent.com/your-username/ai-novel-editor/main/scripts/github-deploy.sh | bash
```

### 3. GitHub Actions自动部署

配置GitHub Secrets后，推送代码到main分支自动部署。

详细部署说明请参考 [deployment.md](docs/deployment.md)

## 技术栈

### 前端
- Vue3 + TypeScript
- Vite构建工具
- Element Plus UI框架
- Pinia状态管理
- Vue Router路由
- ECharts图表
- CodeMirror编辑器

### 后端
- FastAPI异步框架
- MongoDB数据库
- Redis缓存
- Motor异步驱动
- Pydantic数据验证
- JWT认证
- SiliconFlow API集成

### 部署
- Docker容器化
- Docker Compose编排
- Nginx反向代理
- GitHub Actions CI/CD
- 百度云服务器部署

## 核心功能

### 1. 章节内容管理
- 智能解析层：结构化剧情DNA模型
- 用户操作层：三维章节导航器
- 跨模块校验层：一致性检查
- 输出系统：多格式导出

### 2. 人物设定系统
- 立体化角色建模
- 关系网络分析
- 基因编辑器
- 关系模拟器

### 3. AI智能助手
- 实时创作建议
- 内容分析评估
- 智能续写功能
- 剧情优化建议

### 4. 协作功能
- 多人协作编辑
- 版本控制系统
- 冲突解决机制
- 实时同步更新

## 贡献指南

1. Fork项目
2. 创建特性分支
3. 提交代码变更
4. 创建Pull Request

## 许可证

MIT License

## 联系方式

- 项目地址：https://github.com/your-username/ai-novel-editor
- 问题反馈：https://github.com/your-username/ai-novel-editor/issues
