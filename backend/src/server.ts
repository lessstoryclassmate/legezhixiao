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

// 导入配置和工具
import { logger, stream } from './utils/logger';
import databaseConfig from './config/database';
import { errorHandler } from './middleware/errorHandler';
import { notFound } from './middleware/notFound';

// 导入路由
import authRoutes from './routes/auth';
import userRoutes from './routes/user';
import projectRoutes from './routes/project';
import chapterRoutes from './routes/chapter';
import aiRoutes from './routes/ai';
import writingRoutes from './routes/writing';
import writingStatsRoutes from './routes/writingStats';

// 加载环境变量
dotenv.config();

const app = express();
const server = createServer(app);
const io = new SocketIOServer(server, {
  cors: {
    origin: process.env.CORS_ORIGIN || "http://localhost:5173",
    methods: ["GET", "POST"],
    credentials: true
  }
});

// 基础配置
const PORT = process.env.PORT || 3001;
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
      health: '/health'
    }
  });
});

// Socket.IO 连接处理
io.on('connection', (socket) => {
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
  socket.on('text-change', (data) => {
    socket.to(`project-${data.projectId}`).emit('text-change', {
      ...data,
      socketId: socket.id
    });
  });

  // 光标位置同步
  socket.on('cursor-change', (data) => {
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
    await databaseConfig.connectSQLite();

    // 创建上传目录
    const uploadsDir = path.join(__dirname, '../uploads');
    const avatarsDir = path.join(uploadsDir, 'avatars');
    const assetsDir = path.join(__dirname, '../assets');

    // 确保目录存在
    const fs = require('fs').promises;
    await fs.mkdir(uploadsDir, { recursive: true });
    await fs.mkdir(avatarsDir, { recursive: true });
    await fs.mkdir(assetsDir, { recursive: true });

    // 启动服务器
    server.listen(PORT, () => {
      logger.info(`🚀 服务器运行在 http://localhost:${PORT}`);
      logger.info(`📖 API 文档: http://localhost:${PORT}/api`);
      logger.info(`🔧 环境: ${NODE_ENV}`);
      logger.info(`💾 数据库状态:`, databaseConfig.getConnectionStatus());
    });

  } catch (error) {
    logger.error('服务器启动失败:', error);
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
