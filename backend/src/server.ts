import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import compression from 'compression';
import rateLimit from 'express-rate-limit';
import dotenv from 'dotenv';
import path from 'path';
import { createServer } from 'http';
import { Server as SocketIOServer } from 'socket.io';

// 导入错误处理工具
import { logError, safeRequire, startupStep } from './utils/errorLogger';

// 加载环境变量
dotenv.config();

console.log('\n🚀 乐格智小后端服务器启动中...\n');

// 导入配置和工具
let logger: any, stream: any;
let databaseConfig: any;
let errorHandler: any, notFound: any;

try {
  const path = require('path');
  const loggerPath = path.join(__dirname, 'utils', 'logger');
  console.log(`🔍 正在导入模块: ${loggerPath}`);
  const loggerModule = require(loggerPath);
  logger = loggerModule.logger;
  stream = loggerModule.stream;
  console.log('✅ logger 导入成功');
} catch (error) {
  console.error('❌ 无法启动：日志模块导入失败');
  console.error('错误详情:', error);
  process.exit(1);
}

try {
  const path = require('path');
  const dbConfigPath = path.join(__dirname, 'config', 'database');
  console.log(`🔍 正在导入模块: ${dbConfigPath}`);
  databaseConfig = require(dbConfigPath).default;
  console.log('✅ database config 导入成功');
} catch (error) {
  logError('数据库配置导入', error);
  process.exit(1);
}

try {
  const path = require('path');
  const errorHandlerPath = path.join(__dirname, 'middleware', 'errorHandler');
  const notFoundPath = path.join(__dirname, 'middleware', 'notFound');
  console.log(`🔍 正在导入模块: ${errorHandlerPath}`);
  console.log(`🔍 正在导入模块: ${notFoundPath}`);
  errorHandler = require(errorHandlerPath).errorHandler;
  notFound = require(notFoundPath).notFound;
  console.log('✅ middleware 导入成功');
} catch (error) {
  logError('中间件导入', error);
  process.exit(1);
}

// 导入路由
let authRoutes: any, userRoutes: any, projectRoutes: any, chapterRoutes: any;
let aiRoutes: any, writingRoutes: any, writingStatsRoutes: any, logRoutes: any, uploadRoutes: any;

try {
  console.log('导入路由模块...');
  const path = require('path');
  
  authRoutes = require(path.join(__dirname, 'routes', 'auth')).default;
  console.log('✅ auth routes 导入成功');
  
  userRoutes = require(path.join(__dirname, 'routes', 'user')).default;
  console.log('✅ user routes 导入成功');
  
  projectRoutes = require(path.join(__dirname, 'routes', 'project')).default;
  console.log('✅ project routes 导入成功');
  
  chapterRoutes = require(path.join(__dirname, 'routes', 'chapter.new')).default;
  console.log('✅ chapter routes 导入成功');
  
  aiRoutes = require(path.join(__dirname, 'routes', 'ai')).default;
  console.log('✅ ai routes 导入成功');
  
  writingRoutes = require(path.join(__dirname, 'routes', 'writing')).default;
  console.log('✅ writing routes 导入成功');
  
  writingStatsRoutes = require(path.join(__dirname, 'routes', 'writingStats')).default;
  console.log('✅ writingStats routes 导入成功');
  
  logRoutes = require(path.join(__dirname, 'routes', 'logs')).default;
  console.log('✅ logs routes 导入成功');
  
  uploadRoutes = require(path.join(__dirname, 'routes', 'upload')).default;
  console.log('✅ upload routes 导入成功');
  
  console.log('✅ 所有路由模块导入成功');
} catch (error) {
  logError('路由导入', error);
  process.exit(1);
}

// 添加调试日志
console.log('=== 服务器启动调试信息 ===');
console.log('环境变量已加载');
console.log('NODE_ENV:', process.env.NODE_ENV);
console.log('PORT:', process.env.PORT);

let app: express.Application;
let server: any;
let io: any;

try {
  console.log('创建 Express 应用...');
  app = express();
  
  console.log('创建 HTTP 服务器...');
  server = createServer(app);
  
  console.log('创建 Socket.IO 服务器...');
  io = new SocketIOServer(server, {
    cors: {
      origin: process.env.CORS_ORIGIN || "http://localhost:5173",
      methods: ["GET", "POST"],
      credentials: true
    }
  });
  console.log('Socket.IO 服务器创建成功');
} catch (error) {
  console.error('初始化服务器组件时出错:', error);
  process.exit(1);
}

// 基础配置
const PORT = process.env.PORT || 3000;
const NODE_ENV = process.env.NODE_ENV || 'development';

// 安全中间件
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
  crossOriginEmbedderPolicy: false,
}));

// CORS 配置
app.use(cors({
  origin: process.env.CORS_ORIGIN || "http://localhost:5173",
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'x-csrf-token'],
}));

// 限流配置
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW || '15') * 60 * 1000, // 15分钟
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS || '100'), // 最大请求数
  message: {
    error: '请求过于频繁，请稍后再试',
    statusCode: 429
  },
  standardHeaders: true,
  legacyHeaders: false,
});

app.use('/api/', limiter);

// 请求日志
app.use(morgan('combined', { stream }));

// 解析中间件
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// 压缩响应
app.use(compression());

// 静态文件服务
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));
app.use('/assets', express.static(path.join(__dirname, '../assets')));

// 根路径重定向到API文档
app.get('/', (req, res) => {
  res.redirect('/api');
});

// favicon处理
app.get('/favicon.ico', (req, res) => {
  res.status(204).send();
});

// 健康检查端点
app.get('/health', (req, res) => {
  const dbStatus = databaseConfig.getConnectionStatus();
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    environment: NODE_ENV,
    uptime: process.uptime(),
    databases: dbStatus,
    version: process.env.npm_package_version || '1.0.0'
  });
});

// API 路由
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/projects', projectRoutes);
app.use('/api/chapters', chapterRoutes);
app.use('/api/ai', aiRoutes);
app.use('/api/writing', writingRoutes);
app.use('/api/stats', writingStatsRoutes);
app.use('/api/logs', logRoutes);
app.use('/api/upload', uploadRoutes);

// API 根路径
app.get('/api', (req, res) => {
  res.json({
    message: '乐格智小 API 服务器',
    version: '1.0.0',
    status: 'running',
    endpoints: {
      auth: '/api/auth',
      users: '/api/users',
      projects: '/api/projects',
      chapters: '/api/chapters',
      ai: '/api/ai',
      writing: '/api/writing',
      stats: '/api/stats',
      logs: '/api/logs',
      upload: '/api/upload',
      health: '/health'
    }
  });
});

// Socket.IO 连接处理
io.on('connection', (socket: any) => {
  logger.info(`用户连接: ${socket.id}`);

  // 用户加入项目房间
  socket.on('join-project', (projectId: string) => {
    socket.join(`project-${projectId}`);
    logger.info(`用户 ${socket.id} 加入项目 ${projectId}`);
  });

  // 用户离开项目房间
  socket.on('leave-project', (projectId: string) => {
    socket.leave(`project-${projectId}`);
    logger.info(`用户 ${socket.id} 离开项目 ${projectId}`);
  });

  // 实时编辑同步
  socket.on('text-change', (data: any) => {
    socket.to(`project-${data.projectId}`).emit('text-change', {
      ...data,
      socketId: socket.id
    });
  });

  // 光标位置同步
  socket.on('cursor-change', (data: any) => {
    socket.to(`project-${data.projectId}`).emit('cursor-change', {
      ...data,
      socketId: socket.id
    });
  });

  // 用户断开连接
  socket.on('disconnect', () => {
    logger.info(`用户断开连接: ${socket.id}`);
  });
});

// 404 处理
app.use(notFound);

// 错误处理
app.use(errorHandler);

// 服务器启动函数
async function startServer() {
  try {
    // 连接数据库
    await startupStep('连接数据库', async () => {
      await databaseConfig.connectSQLite();
    });

    // 创建上传目录
    await startupStep('创建上传目录', async () => {
      const uploadsDir = path.join(__dirname, '../uploads');
      const avatarsDir = path.join(uploadsDir, 'avatars');
      const assetsDir = path.join(__dirname, '../assets');

      // 确保目录存在
      const fs = require('fs').promises;
      await fs.mkdir(uploadsDir, { recursive: true });
      await fs.mkdir(avatarsDir, { recursive: true });
      await fs.mkdir(assetsDir, { recursive: true });
    });

    // 启动服务器
    await startupStep('启动HTTP服务器', () => {
      return new Promise<void>((resolve, reject) => {
        server.listen(PORT, (err?: Error) => {
          if (err) {
            reject(err);
          } else {
            logger.info(`🚀 服务器运行在 http://localhost:${PORT}`);
            logger.info(`📖 API 文档: http://localhost:${PORT}/api`);
            logger.info(`🔧 环境: ${NODE_ENV}`);
            logger.info(`💾 数据库状态:`, databaseConfig.getConnectionStatus());
            resolve();
          }
        });
      });
    });

  } catch (error) {
    logError('服务器启动', error);
    process.exit(1);
  }
}

// 优雅关闭处理
process.on('SIGTERM', async () => {
  logger.info('收到 SIGTERM 信号，开始优雅关闭...');
  server.close(async () => {
    await databaseConfig.disconnect();
    logger.info('服务器已关闭');
    process.exit(0);
  });
});

process.on('SIGINT', async () => {
  logger.info('收到 SIGINT 信号，开始优雅关闭...');
  server.close(async () => {
    await databaseConfig.disconnect();
    logger.info('服务器已关闭');
    process.exit(0);
  });
});

// 未捕获异常处理
process.on('uncaughtException', (error) => {
  logger.error('未捕获异常:', error);
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  logger.error('未处理的 Promise 拒绝:', reason);
  logger.error('Promise:', promise);
  process.exit(1);
});

// 启动服务器
if (require.main === module) {
  startServer();
}

export { app, server, io };
export default app;
