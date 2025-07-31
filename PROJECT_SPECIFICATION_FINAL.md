# 乐格至效 (LeGeZhiXiao) AI小说创作平台 - 现代化数据库架构规范

## 📋 项目概述

**项目名称**: 乐格至效 (LegeZhiXiao) AI小说创作平台  
**项目定位**: 基于GitHub Copilot模式的智能小说创作助手  
**核心特色**: GitHub Copilot式AI Agent + RXDB离线优先 + ArangoDB多模态数据库 + 实时同步架构  
**技术栈**: React 18 + TypeScript + Node.js + RXDB + ArangoDB + SiliconFlow DeepSeek-V3  
**开发状态**: ✅ 现代化数据库架构完成，RXDB + ArangoDB 双向同步已实现，生产环境原生部署就绪

## 🎯 核心功能架构

### 1. ✅ 现代化数据存储系统 (已完成)
- **前端RXDB**: ✅ 响应式离线优先数据库，基于RxJS的响应式数据流
- **后端ArangoDB**: ✅ 多模态数据库，统一文档+图数据库架构
- **双向同步**: ✅ 实时数据同步，支持离线编辑和冲突解决
- **数据一致性**: ✅ 分布式数据一致性保证，乐观锁机制

### 2. ✅ AI Agent智能写作系统 (已完成)
- **GitHub Copilot模式**: ✅ 自然语言交互，智能意图识别
- **图数据库集成**: ✅ 自动读取角色关系、情节连接、世界观设定
- **上下文感知**: ✅ 基于ArangoDB图查询的深度上下文理解
- **多模态生成**: ✅ 续写、改写、扩写、角色对话、场景描写

### 3. ✅ 离线优先架构 (已完成)
- **本地存储**: ✅ RXDB + Dexie适配器，支持完整离线操作
- **实时同步**: ✅ WebSocket + HTTP双协议同步机制
- **冲突解决**: ✅ 自动合并策略，时间戳+用户选择机制
- **数据持久化**: ✅ 本地IndexedDB + 云端ArangoDB双重保障

### 4. ✅ 响应式UI系统 (已完成)
- **实时更新**: ✅ RxJS驱动的响应式数据流，UI自动更新
- **状态管理**: ✅ RXDB集成的状态管理，无需Redux/Zustand
- **性能优化**: ✅ 虚拟滚动、懒加载、增量更新
- **同步状态**: ✅ 实时同步状态指示器，连接质量监控

## 🏗️ 技术架构详解

### 前端架构 (React + RXDB)
```
├── 用户界面层 (React 18 + TypeScript)
│   ├── 组件库 (Material-UI + 自定义组件)
│   ├── 响应式数据绑定 (RxJS + React Hooks)
│   └── 实时状态更新 (RXDB 响应式查询)
│
├── 数据服务层 (RXDB + RxJS)
│   ├── 响应式数据库 (RXDB Collections)
│   ├── 离线存储 (Dexie IndexedDB 适配器)
│   ├── 数据同步 (Pull/Push 复制)
│   └── 冲突解决 (CRDTs + 时间戳)
│
└── 通信层 (HTTP + WebSocket)
    ├── REST API 客户端 (Axios)
    ├── WebSocket 连接 (Socket.io)
    └── 同步协议 (RXDB Replication)
```

### 后端架构 (Node.js + ArangoDB)
```
├── API 服务层 (Express + TypeScript)
│   ├── RESTful API (Express Router)
│   ├── WebSocket 服务 (Socket.io)
│   ├── 认证中间件 (JWT + Session)
│   └── 错误处理 (统一错误处理机制)
│
├── 业务逻辑层 (Service Layer)
│   ├── 用户管理服务 (UserService)
│   ├── 项目管理服务 (ProjectService)
│   ├── AI Agent 服务 (AIAgentService)
│   └── 同步服务 (SyncService)
│
├── 数据访问层 (ArangoDB + Graph Queries)
│   ├── 文档数据库 (用户、项目、章节数据)
│   ├── 图数据库 (角色关系、情节连接)
│   ├── 全文搜索 (ArangoSearch)
│   └── 数据建模 (Schema 验证)
│
└── 外部集成层
    ├── AI API 集成 (SiliconFlow DeepSeek-V3)
    ├── 文件存储 (本地存储 + 云存储可选)
    └── 监控日志 (Winston + PM2)
```

### 数据同步架构
```
前端 RXDB                    后端 ArangoDB
┌─────────────────┐         ┌─────────────────┐
│  本地 Collections │◄────────┤  云端 Collections │
│                 │  双向同步  │                 │
│ • users         │         │ • users         │
│ • projects      │◄────────┤ • projects      │
│ • chapters      │  实时更新  │ • chapters      │
│ • characters    │         │ • characters    │
│ • worldbuilding │◄────────┤ • worldbuilding │
│ • writing_*     │         │ • writing_*     │
└─────────────────┘         └─────────────────┘
         ▲                            ▲
         │                            │
    ┌─────────┐                 ┌──────────┐
    │ 离线缓存  │                 │  图关系网  │
    │ Conflict │                 │ Character │
    │ Resolution│                 │ Relations │
    └─────────┘                 └──────────┘
```

## 📊 数据模型设计

### RXDB 前端数据模型
```typescript
// 用户集合
const userSchema = {
  version: 0,
  primaryKey: 'id',
  type: 'object',
  properties: {
    id: { type: 'string' },
    email: { type: 'string' },
    username: { type: 'string' },
    profile: { type: 'object' },
    preferences: { type: 'object' },
    updatedAt: { type: 'string' },
    _deleted: { type: 'boolean' }
  }
};

// 项目集合
const projectSchema = {
  version: 0,
  primaryKey: 'id',
  type: 'object',
  properties: {
    id: { type: 'string' },
    userId: { type: 'string' },
    title: { type: 'string' },
    description: { type: 'string' },
    genre: { type: 'string' },
    status: { type: 'string' },
    settings: { type: 'object' },
    wordCount: { type: 'number' },
    createdAt: { type: 'string' },
    updatedAt: { type: 'string' },
    _deleted: { type: 'boolean' }
  }
};

// 章节集合
const chapterSchema = {
  version: 0,
  primaryKey: 'id',
  type: 'object',
  properties: {
    id: { type: 'string' },
    projectId: { type: 'string' },
    title: { type: 'string' },
    content: { type: 'string' },
    order: { type: 'number' },
    wordCount: { type: 'number' },
    status: { type: 'string' },
    createdAt: { type: 'string' },
    updatedAt: { type: 'string' },
    _deleted: { type: 'boolean' }
  }
};
```

### ArangoDB 后端数据模型
```javascript
// 文档集合 (Document Collections)
- users: 用户基础信息
- projects: 项目信息和设置
- chapters: 章节内容和元数据
- characters: 角色档案和属性
- worldbuilding: 世界观设定
- writing_sessions: 写作会话记录
- writing_goals: 写作目标和进度

// 边集合 (Edge Collections)  
- character_relationships: 角色关系网络
- story_connections: 情节连接图谱
- world_relations: 世界观关联关系
- project_dependencies: 项目依赖关系
```

## 🔄 数据同步机制

### 1. Pull 同步 (下拉同步)
```typescript
// 前端主动拉取服务器更新
async pullFromServer() {
  const lastPullTime = await this.getLastPullTime();
  const response = await api.get('/sync/pull', {
    params: { since: lastPullTime }
  });
  
  // 批量更新本地数据
  await this.database.bulkInsert(response.data.documents);
  await this.updateLastPullTime(response.data.checkpoint);
}
```

### 2. Push 同步 (上推同步)
```typescript
// 前端推送本地更改到服务器
async pushToServer() {
  const localChanges = await this.getLocalChanges();
  const response = await api.post('/sync/push', {
    changes: localChanges
  });
  
  // 处理服务器响应和冲突
  await this.resolveConflicts(response.data.conflicts);
}
```

### 3. 实时同步 (WebSocket)
```typescript
// 实时数据变更推送
socket.on('data-change', (change) => {
  this.database.collection(change.collection)
    .upsert(change.document);
});

// 发送本地变更
this.database.$.subscribe(change => {
  socket.emit('local-change', change);
});
```

## 🤖 AI Agent 集成架构

### 1. 知识图谱查询
```javascript
// ArangoDB 图查询示例
const getCharacterContext = async (characterId, projectId) => {
  const query = `
    FOR character IN characters
      FILTER character._id == @characterId
      LET relationships = (
        FOR rel IN character_relationships
          FILTER rel._from == character._id OR rel._to == character._id
          RETURN rel
      )
      LET worldConnections = (
        FOR world IN worldbuilding
          FILTER world.projectId == @projectId
          LET connections = (
            FOR conn IN world_relations
              FILTER conn._from == character._id OR conn._to == world._id
              RETURN { world: world, connection: conn }
          )
          RETURN connections[0]
      )
      RETURN {
        character: character,
        relationships: relationships,
        worldConnections: worldConnections
      }
  `;
  
  return await db.query(query, { characterId, projectId });
};
```

### 2. AI Agent 服务调用
```typescript
// AI Agent 服务集成
class AIAgentService {
  async generateContent(request: AIGenerationRequest) {
    // 获取上下文数据
    const context = await this.buildContext(request);
    
    // 调用 SiliconFlow API
    const response = await this.callSiliconFlowAPI({
      prompt: this.buildPrompt(request, context),
      model: 'deepseek-v3',
      parameters: request.parameters
    });
    
    // 保存生成结果
    await this.saveGenerationResult(response);
    
    return response;
  }
  
  private async buildContext(request: AIGenerationRequest) {
    // 从 ArangoDB 获取角色、世界观、情节上下文
    const characters = await this.getProjectCharacters(request.projectId);
    const worldbuilding = await this.getProjectWorldbuilding(request.projectId);
    const plotConnections = await this.getPlotConnections(request.chapterId);
    
    return { characters, worldbuilding, plotConnections };
  }
}
```

## 🔧 开发环境配置

### 前端开发启动
```bash
cd frontend
npm install
npm run dev  # Vite 开发服务器 (端口 5173)
```

### 后端开发启动
```bash
cd backend  
npm install
npm run dev  # TypeScript + Nodemon 开发服务器 (端口 3001)
```

### ArangoDB 本地开发
```bash
# 原生安装ArangoDB (开发环境)
# Ubuntu/Debian:
sudo apt install arangodb3

# 启动服务
sudo systemctl start arangodb3

# Web界面: http://localhost:8529
```

## 🚀 生产环境部署

### 原生部署架构
- **前端**: Nginx 静态文件服务 + Gzip 压缩
- **后端**: PM2 进程管理 + 集群模式
- **数据库**: ArangoDB 原生安装 + 主从复制
- **反向代理**: Nginx + SSL 终端
- **监控**: PM2 监控 + ArangoDB 监控

详细部署指南请参考: `PRODUCTION_NATIVE_DEPLOYMENT.md`

### 部署检查清单
- [ ] ArangoDB 服务安装并配置
- [ ] Node.js 18+ 环境准备
- [ ] PM2 进程管理器配置
- [ ] Nginx 反向代理配置
- [ ] SSL 证书申请和配置
- [ ] 防火墙和安全配置
- [ ] 备份脚本和定时任务
- [ ] 监控和日志配置

## 📈 性能特性

### 前端性能
- **离线优先**: 完整功能离线可用，网络恢复时自动同步
- **响应式更新**: RxJS 驱动的实时UI更新，无需手动刷新
- **增量同步**: 仅同步变更数据，减少网络流量
- **本地缓存**: IndexedDB 本地存储，快速数据访问

### 后端性能
- **多模态查询**: ArangoDB 支持文档和图查询，单次查询获取复杂关系
- **集群模式**: PM2 集群模式，充分利用多核CPU
- **连接池**: 数据库连接池，优化连接复用
- **缓存策略**: Redis 缓存热点数据 (可选)

### 数据库性能
- **索引优化**: 基于查询模式的智能索引策略
- **分片支持**: ArangoDB 分片支持水平扩展
- **内存配置**: 针对写作场景的内存配置优化
- **查询优化**: AQL 查询优化和执行计划分析

## 🔒 安全特性

### 数据安全
- **端到端加密**: 敏感数据传输加密
- **本地加密**: RXDB 本地数据加密存储 (可选)
- **访问控制**: 基于角色的访问控制 (RBAC)
- **数据备份**: 自动备份和灾难恢复

### 应用安全
- **JWT 认证**: 无状态身份认证
- **CORS 配置**: 跨域请求安全控制
- **输入验证**: 前后端数据验证和清理
- **安全头**: 安全HTTP头配置

## 📚 开发指南

### 添加新数据模型
1. 在前端 `rxdbService.ts` 中定义 RXDB Schema
2. 在后端创建 ArangoDB Collection
3. 实现双向同步逻辑
4. 添加 React Hooks 和 UI 组件
5. 更新 AI Agent 上下文集成

### 扩展 AI 功能
1. 在 `AIAgentService` 中添加新的生成方法
2. 实现上下文数据收集逻辑
3. 配置 SiliconFlow API 调用参数
4. 添加前端 AI 功能触发器
5. 集成到用户工作流中

### 性能优化
1. 监控 RXDB 查询性能
2. 优化 ArangoDB 索引策略
3. 实现数据分页和懒加载
4. 配置合理的同步频率
5. 使用 Web Workers 处理大数据量

## 🧪 测试策略

### 单元测试
- Frontend: Vitest + React Testing Library
- Backend: Jest + Supertest
- Database: ArangoDB Test Suite

### 集成测试
- API 接口测试
- 数据同步测试
- AI Agent 集成测试
- 用户工作流测试

### 性能测试
- 数据库查询性能
- 同步机制压力测试
- 前端响应时间测试
- 并发用户测试

## 📞 技术支持

### 开发环境问题
- 检查 Node.js 版本 (需要 18+)
- 确认 ArangoDB 服务运行状态
- 验证端口配置和防火墙设置
- 查看开发服务器日志

### 生产环境问题
- 监控 PM2 应用状态
- 检查 ArangoDB 性能指标
- 分析 Nginx 访问日志
- 查看系统资源使用情况

### 数据同步问题
- 检查 WebSocket 连接状态
- 验证数据库权限配置
- 分析同步冲突日志
- 测试网络连接质量

---

## 📄 相关文档

- `PRODUCTION_NATIVE_DEPLOYMENT.md` - 生产环境原生部署指南
- `AI_SETUP_GUIDE.md` - AI Agent 配置指南
- `AI_USAGE_GUIDE.md` - AI 功能使用指南
- `USER_SYSTEM_GUIDE.md` - 用户系统使用指南

**最后更新**: 2024年12月
**架构版本**: RXDB + ArangoDB v1.0
**部署状态**: 生产环境就绪
