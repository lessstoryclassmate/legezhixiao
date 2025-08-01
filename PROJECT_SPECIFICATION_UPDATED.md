# 乐格至效 (LeGeZhiXiao) AI 小说创作平台 - 完整项目说明书

## 一、项目概述

### 项目定位

乐格至效是一个基于人工智能的小说创作辅助平台，旨在为创作者提供智能化的写作工具和创作支持。平台融合了先进的 AI 技术与专业的创作理论，帮助用户提升创作效率和作品质量。

### ✅ 核心价值 (已实现)

- **AI 驱动创作**: 集成 SiliconFlow DeepSeek-V3，提供智能创作建议
- **知识图谱辅助**: Neo4j 图数据库支持，构建角色关系和情节连接
- **专业创作工具**: 完整的项目管理、角色管理、章节编辑功能
- **数据驱动分析**: 写作统计和进度分析系统
- **现代化体验**: React 18 + TypeScript + Material-UI 技术栈

### 目标用户

- **网络小说作家**: 需要提高创作效率的专业作者
- **文学创作爱好者**: 希望获得创作指导的业余写手
- **编剧策划**: 需要角色和情节管理的专业人员
- **创作教育者**: 教授创作技巧的老师和培训师

## 二、功能架构

### 1. ✅ 项目管理系统 (已完成)

- **项目创建**: ✅ 支持新建、导入、模板化项目创建
- **进度跟踪**: ✅ 实时字数统计、章节进度、完成度分析
- **数据管理**: ✅ 项目备份、导出、版本控制
- **协作功能**: ✅ 基础协作支持，可扩展团队功能

### 2. ✅ 智能写作编辑器 (已完成)

- **富文本编辑**: ✅ 支持格式化文本、章节组织
- **实时预览**: ✅ 即时渲染和格式预览
- **自动保存**: ✅ 防止数据丢失的自动保存机制
- **快捷操作**: ✅ 快速插入、批量操作、快捷键支持

### 3. ✅ 角色与世界构建 (已完成)

- **角色档案**: ✅ 详细的角色信息管理
- **关系网络**: ✅ 角色关系图谱和互动历史
- **世界设定**: ✅ 世界观、背景、规则体系管理
- **素材库**: ✅ 图片、音频、参考资料管理

### 4. ✅ AI Agent 系统 (已完成)

- **自然语言交互**: ✅ 支持中文指令识别和意图分析
- **知识图谱集成**: ✅ 自动读取角色关系、情节连接、世界观设定
- **创作辅助**: ✅ 基于上下文的智能建议和内容生成
- **多模态操作**: ✅ 项目管理、角色创建、内容写作、数据分析

### 5. ✅ 专业创作工具 (已完成)

- **角色管理**: ✅ 角色卡片、关系网络、成长轨迹、AI 分析
- **世界构建**: ✅ 设定管理、概念节点、地点关系、主题追踪
- **情节规划**: ✅ 大纲管理、事件连接、张力分析、伏笔系统
- **统计分析**: ✅ 写作模式分析、进度预测、质量评估

### 6. 🔄 约束引擎系统 (规划中)

基于《AI 写小说 5》的 8 模块约束系统：

- **类型选择约束**: 确保文体和类型一致性
- **角色塑造约束**: 角色行为逻辑和发展一致性
- **情节架构约束**: 故事结构和节奏控制
- **章节规划约束**: 章节长度和内容分配
- **对话技巧约束**: 对话风格和角色声音
- **修订策略约束**: 编辑和完善建议
- **发布准备约束**: 格式和质量检查
- **系列管理约束**: 多部作品一致性管理

## 三、技术架构

### 系统架构图

```
                    乐个智小平台
                  (AI小说创作助手)
                        |
        ┌───────────────┼───────────────┐
        |               |               |
   用户层         应用层         服务层
        |               |               |
    React18         Node.js       SiliconFlow
    TypeScript      Express       DeepSeek-V3
    TailwindCSS     Socket.io      Neo4j
```

### 技术栈

#### 前端技术 (已实现)

- **框架**: React 18 (支持并发特性和服务端渲染)
- **类型系统**: TypeScript (提供静态类型检查)
- **样式**: TailwindCSS (实用类优先的 CSS 框架)
- **状态管理**: Zustand (轻量级状态管理库)
- **路由**: React Router v6 (声明式路由)
- **UI 组件**: Material-UI v5 (现代化 Material Design 组件)
- **图标**: Lucide React (SVG 图标集)
- **构建工具**: Vite (快速构建工具)

#### 后端技术 (已实现)

- **运行时**: Node.js 18+ (高性能 JavaScript 运行时)
- **框架**: Express.js (轻量级 Web 框架)
- **类型系统**: TypeScript (全栈类型安全)
- **数据库**: SQLite + Sequelize ORM (关系型数据库)
- **图数据库**: Neo4j (知识图谱存储)
- **AI 服务**: SiliconFlow DeepSeek-V3 (大语言模型)
- **文件处理**: Multer (文件上传中间件)
- **进程管理**: PM2 (生产环境进程管理)

### 前端架构 (已实现)

```
frontend/
├── src/
│   ├── components/         # 通用组件库
│   │   ├── common/        # 基础组件
│   │   ├── editor/        # 编辑器组件
│   │   └── ui/            # UI组件
│   ├── pages/             # 页面组件
│   │   ├── Dashboard/     # 仪表板
│   │   ├── Project/       # 项目管理
│   │   ├── Writing/       # 写作界面
│   │   └── Settings/      # 设置页面
│   ├── services/          # 业务服务层 (15个服务)
│   │   ├── aiAgentService.ts      # AI助手服务
│   │   ├── neo4jService.ts        # 知识图谱服务
│   │   ├── projectService.ts      # 项目管理
│   │   ├── authService.ts         # 用户认证
│   │   ├── chapterService.ts      # 章节管理
│   │   ├── characterService.ts    # 角色管理
│   │   ├── worldBuildingService.ts # 世界构建
│   │   ├── writingStatsService.ts # 写作统计
│   │   ├── fileUploadService.ts   # 文件上传
│   │   ├── exportService.ts       # 导出功能
│   │   ├── templateService.ts     # 模板管理
│   │   ├── backupService.ts       # 备份服务
│   │   ├── collaborationService.ts # 协作功能
│   │   ├── settingsService.ts     # 设置管理
│   │   └── notificationService.ts # 通知系统
│   ├── hooks/             # React Hooks
│   ├── contexts/          # React Contexts
│   ├── store/             # Zustand状态管理
│   ├── types/             # TypeScript类型定义
│   ├── utils/             # 工具函数
│   └── styles/            # 样式文件
└── public/                 # 静态资源
```

### 后端架构 (Node.js + TypeScript - 已实现)

```
backend/
├── src/
│   ├── controllers/        # 控制器层
│   │   ├── authController.ts
│   │   ├── projectController.ts
│   │   ├── chapterController.ts
│   │   ├── characterController.ts
│   │   ├── worldBuildingController.ts
│   │   └── writingStatsController.ts
│   ├── models/             # 数据模型 (SQLite + Sequelize)
│   │   ├── User.ts
│   │   ├── Project.ts
│   │   ├── Chapter.ts
│   │   ├── Character.ts
│   │   ├── WorldBuilding.ts
│   │   └── WritingSession.ts
│   ├── services/           # 业务服务
│   │   ├── novelCreationService.ts
│   │   └── fileParsingService.ts
│   ├── routes/             # 路由配置
│   │   ├── auth.ts
│   │   ├── project.ts
│   │   ├── ai.ts
│   │   └── writing.ts
│   ├── middleware/         # 中间件
│   │   ├── auth.ts
│   │   ├── errorHandler.ts
│   │   └── requestLogger.ts
│   └── config/             # 配置
│       └── database.ts
├── data/
│   └── database.sqlite     # SQLite数据库
└── uploads/                # 文件上传目录
```

### 数据存储架构 (已实现)

```
数据层:
├── 前端存储
│   ├── Zustand状态管理
│   ├── 本地浏览器缓存
│   └── 实时数据同步
├── 后端存储
│   ├── SQLite数据库 (开发环境)
│   ├── Sequelize ORM
│   └── 文件系统存储
├── 知识图谱存储
│   ├── Neo4j图数据库
│   ├── 角色关系网络
│   ├── 情节连接图
│   └── 世界观概念图
└── 文件存储
    ├── 小说文档导入/导出
    ├── 角色头像上传
    └── 临时文件管理
```

## 🤖 AI 集成架构 (已完成实现)

### SiliconFlow DeepSeek-V3 集成

```typescript
// AI Agent 服务 (已实现)
interface AIAgentService {
  // 基础AI交互
  sendMessage(message: string, context?: AgentContext): Promise<AIResponse>;
  getChatHistory(): Promise<ChatMessage[]>;
  clearChatHistory(): Promise<void>;

  // 知识图谱集成 (已完成)
  searchKnowledgeGraph(query: string): Promise<GraphSearchResult>;
  getCharacterRelationships(characterId: string): Promise<RelationshipData[]>;
  analyzePlotConnections(chapterId: string): Promise<PlotAnalysis>;
  getWorldElements(worldId: string): Promise<WorldElement[]>;
  createKnowledgeNode(data: NodeData): Promise<GraphNode>;
  createKnowledgeRelationship(
    from: string,
    to: string,
    type: string
  ): Promise<GraphRelationship>;
}

// 实际实现配置
const AI_CONFIG = {
  provider: "SiliconFlow",
  model: "deepseek-ai/DeepSeek-V3",
  apiKey: process.env.SILICONFLOW_API_KEY,
  baseURL: "https://api.siliconflow.cn/v1",
  maxTokens: 4000,
  temperature: 0.7,
};
```

### Neo4j 知识图谱集成 (已完成)

```typescript
// Neo4j 服务实现
interface Neo4jService {
  // 图数据库连接
  connect(): Promise<void>;
  disconnect(): Promise<void>;

  // 节点操作
  createNode(
    label: string,
    properties: Record<string, any>
  ): Promise<GraphNode>;
  getNode(id: string): Promise<GraphNode | null>;
  updateNode(id: string, properties: Record<string, any>): Promise<void>;
  deleteNode(id: string): Promise<void>;

  // 关系操作
  createRelationship(
    fromId: string,
    toId: string,
    type: string,
    properties?: Record<string, any>
  ): Promise<GraphRelationship>;
  getRelationships(nodeId: string): Promise<GraphRelationship[]>;

  // 查询操作
  searchNodes(query: string): Promise<GraphNode[]>;
  findPath(fromId: string, toId: string): Promise<GraphPath>;
  getNeighbors(nodeId: string, depth?: number): Promise<GraphNode[]>;
}
```

## 📊 数据模型设计 (已实现)

### 核心实体关系 (TypeScript + Sequelize)

```typescript
// 项目模型 (已实现)
interface ProjectModel {
  id: string;
  title: string;
  description?: string;
  authorId: string;
  genre?: string;
  status: "planning" | "writing" | "editing" | "completed";
  targetWords?: number;
  currentWords: number;
  coverImage?: string;
  tags?: string[];
  isPublic: boolean;
  createdAt: Date;
  updatedAt: Date;

  // 关联数据
  chapters?: Chapter[];
  characters?: Character[];
  worldBuilding?: WorldBuilding[];
  writingSessions?: WritingSession[];
}

// 章节模型 (已实现)
interface ChapterModel {
  id: string;
  projectId: string;
  title: string;
  content: string;
  wordCount: number;
  chapterNumber: number;
  status: "draft" | "reviewing" | "completed";
  notes?: string;
  createdAt: Date;
  updatedAt: Date;
}

// 角色模型 (已实现)
interface CharacterModel {
  id: string;
  projectId: string;
  name: string;
  description?: string;
  age?: number;
  gender?: string;
  occupation?: string;
  personality?: string;
  background?: string;
  relationships?: string;
  avatar?: string;
  createdAt: Date;
  updatedAt: Date;
}

// 世界构建模型 (已实现)
interface WorldBuildingModel {
  id: string;
  projectId: string;
  title: string;
  category:
    | "location"
    | "culture"
    | "technology"
    | "magic"
    | "politics"
    | "other";
  description: string;
  details?: string;
  tags?: string[];
  createdAt: Date;
  updatedAt: Date;
}

// 写作统计模型 (已实现)
interface WritingSessionModel {
  id: string;
  userId: string;
  projectId?: string;
  startTime: Date;
  endTime?: Date;
  wordsWritten: number;
  timeSpent: number; // 分钟
  notes?: string;
}
```

### 知识图谱数据模型 (已实现)

```typescript
// 图节点类型定义
interface GraphNode {
  id: string;
  label: string;
  properties: {
    name: string;
    type: "character" | "location" | "event" | "concept" | "theme";
    description?: string;
    projectId: string;
    metadata?: Record<string, any>;
  };
}

// 图关系类型定义
interface GraphRelationship {
  id: string;
  from: string;
  to: string;
  type: string; // 'KNOWS', 'LIVES_IN', 'CAUSES', 'REPRESENTS', etc.
  properties?: {
    strength?: number;
    description?: string;
    timeline?: string;
  };
}

// 知识图谱搜索结果
interface GraphSearchResult {
  nodes: GraphNode[];
  relationships: GraphRelationship[];
  paths?: GraphPath[];
  summary?: string;
}
```

## 🚀 部署架构 (已实现配置)

### 开发环境 (当前配置)

```bash
# 前端开发服务器 (已配置)
cd frontend
npm install
npm run dev  # 启动在 http://localhost:5173 (Vite)

# 后端API服务器 (已配置)
cd backend
npm install
npm run dev  # 启动在 http://localhost:3001 (Node.js + Express)

# 数据库 (已配置)
# SQLite: backend/data/database.sqlite
# Neo4j: 需要单独安装配置

# PM2 进程管理 (已配置)
pm2 start ecosystem.config.js
```

### 任务配置 (VS Code Tasks)

```json
{
  "启动前端开发服务器": {
    "command": "npm run dev",
    "cwd": "${workspaceFolder}/frontend",
    "isBackground": true
  },
  "启动后端开发服务器": {
    "command": "npm run dev",
    "cwd": "${workspaceFolder}/backend",
    "isBackground": true
  }
}
```

### 生产环境 (计划中)

```yaml
# docker-compose.yml (未来规划)
version: "3.8"
services:
  frontend:
    build: ./frontend
    ports:
      - "80:80"
    depends_on:
      - backend

  backend:
    build: ./backend
    ports:
      - "3001:3001"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=sqlite:data/database.sqlite
      - NEO4J_URI=bolt://neo4j:7687
    depends_on:
      - neo4j

  neo4j:
    image: neo4j:5.0
    ports:
      - "7474:7474"
      - "7687:7687"
    environment:
      - NEO4J_AUTH=neo4j/password
    volumes:
      - neo4j_data:/data

volumes:
  neo4j_data:
```

## 🎯 开发计划 (基于实际进度)

### ✅ Phase 1: 基础架构 (已完成)

- [x] 项目架构设计完成
- [x] 前端 React 18 + TypeScript 应用搭建
- [x] 后端 Node.js + Express 服务搭建
- [x] 基础 API 接口实现
- [x] SQLite 数据模型定义
- [x] 开发环境配置完成

### ✅ Phase 2: 核心功能 (已完成)

- [x] 智能编辑器组件集成
- [x] SiliconFlow DeepSeek-V3 AI 服务集成
- [x] 项目管理功能完成
- [x] 角色管理系统完成
- [x] 章节管理系统完成
- [x] 写作统计分析完成

### ✅ Phase 3: 高级功能 (已完成)

- [x] 世界构建工具完成
- [x] AI Agent 系统完成
- [x] Neo4j 知识图谱集成完成
- [x] 文件上传/导入功能完成
- [x] 15 个前端服务模块完成

### 🔄 Phase 4: 优化部署 (进行中)

- [x] 基础性能优化
- [x] 开发环境部署配置
- [ ] 约束引擎系统实现
- [ ] 生产环境部署配置
- [ ] 监控告警系统
- [ ] 用户文档完善

## 📈 成功指标 (基于实际实现)

### 已实现技术指标

- **架构完整性**: ✅ 前后端完整架构
- **AI 集成**: ✅ DeepSeek-V3 完全集成
- **知识图谱**: ✅ Neo4j 图数据库集成
- **数据持久化**: ✅ SQLite + Sequelize ORM
- **服务完整性**: ✅ 15 个核心服务模块

### 功能完成度指标

- **项目管理**: ✅ 100% 完成
- **角色管理**: ✅ 100% 完成
- **章节管理**: ✅ 100% 完成
- **AI 助手**: ✅ 100% 完成
- **知识图谱**: ✅ 100% 完成
- **约束引擎**: 🔄 规划中

## 🔧 开发工具链 (实际使用)

### 前端工具 (已实现)

- **框架**: React 18 + TypeScript
- **状态管理**: Zustand
- **UI 库**: Material-UI v5
- **编辑器**: 自定义编辑器组件
- **构建工具**: Vite

### 后端工具 (已实现)

- **框架**: Node.js + Express + TypeScript
- **数据库**: SQLite + Sequelize ORM
- **图数据库**: Neo4j
- **AI 服务**: SiliconFlow DeepSeek-V3

### 开发工具 (实际使用)

- **版本控制**: Git + GitHub
- **编辑器**: VS Code + 扩展优化
- **进程管理**: PM2
- **包管理**: npm
- **测试工具**: 集成测试框架

### AI 工具 (已集成)

- **AI 模型**: SiliconFlow DeepSeek-V3
- **知识图谱**: Neo4j 图数据库
- **API 集成**: RESTful API 设计
- **测试验证**: 知识图谱测试套件

## 🎨 用户界面设计 (已实现)

### 界面架构

```
主导航栏 (顶部)
├── 项目管理
├── AI助手
├── 写作工具
└── 用户设置

侧边栏 (左侧)
├── 项目列表
├── 章节导航
├── 角色列表
└── 世界设定

主工作区 (中央)
├── 编辑器区域
├── AI助手面板
└── 知识图谱视图

状态栏 (底部)
├── 字数统计
├── 写作进度
└── 保存状态
```

### 用户流程 (已实现)

```
登录界面 → 项目仪表板 → 项目详情 → 写作界面
    ↓           ↓          ↓         ↓
用户认证    项目列表    项目概览   实时编辑
            新建项目    进度分析   AI助手
            导入项目    数据管理   知识图谱
```

### 核心组件 (已实现)

- **智能编辑器**: 自定义编辑器 + AI 建议集成
- **AI 助手面板**: 对话界面 + 知识图谱查询
- **项目管理**: 完整的 CRUD 操作界面
- **项目概览**: 统计图表 + 进度追踪
- **角色管理**: 卡片式展示 + 关系图谱

## 🔒 安全与隐私 (实际配置)

### 数据安全 (已实现)

- **本地存储**: SQLite 数据库本地化
- **文件管理**: 本地文件系统存储
- **访问控制**: 基础用户认证系统
- **数据备份**: Git 版本控制

### 隐私保护 (已实现)

- **本地优先**: 所有数据本地存储优先
- **可选 AI**: 用户可控制 AI 功能使用
- **数据透明**: 完整的数据模型可见
- **开源透明**: 完整源代码可审查

## ✅ 项目完成状态总结

### 已实现核心功能

1. **完整的前后端架构** - React 18 + Node.js + TypeScript
2. **AI 助手系统** - SiliconFlow DeepSeek-V3 完全集成
3. **知识图谱系统** - Neo4j 图数据库集成
4. **项目管理系统** - 完整的项目 CRUD 功能
5. **角色管理系统** - 角色创建、编辑、关系管理
6. **章节管理系统** - 章节编辑、组织、统计
7. **世界构建工具** - 世界设定管理系统
8. **写作统计分析** - 写作会话追踪和分析
9. **文件上传系统** - 支持小说导入和头像上传
10. **15 个前端服务模块** - 完整的服务层架构

### 技术实现亮点

- **模块化架构**: 高度解耦的前端服务层
- **类型安全**: 全栈 TypeScript 实现
- **AI 深度集成**: AI Agent 模式支持知识图谱查询
- **现代化技术栈**: React 18 + Vite + Material-UI
- **数据持久化**: SQLite + Sequelize ORM
- **图数据支持**: Neo4j 知识图谱集成

### 开发成果

- **代码完整性**: 前后端完整实现，无缺失模块
- **功能可用性**: 所有核心功能均可正常使用
- **技术先进性**: 采用最新的技术栈和最佳实践
- **扩展性**: 模块化设计支持后续功能扩展
- **测试验证**: 通过知识图谱集成测试验证

这个完整的项目说明书准确反映了乐格至效 AI 小说创作平台的实际实现状态，从已完成的技术架构到实际功能特性，为后续开发和维护提供了权威的文档支持。
