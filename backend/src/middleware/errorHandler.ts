import { Request, Response, NextFunction } from 'express';
import { logger } from '../utils/logger';
import { AppError } from '../types';

// 开发环境错误响应
const sendErrorDev = (err: AppError, res: Response) => {
  res.status(err.statusCode).json({
    success: false,
    error: err,
    message: err.message,
    stack: err.stack,
  });
};

// 生产环境错误响应
const sendErrorProd = (err: AppError, res: Response) => {
  // 操作性错误：发送给客户端
  if (err.isOperational) {
    res.status(err.statusCode).json({
      success: false,
      message: err.message,
    });
  } else {
    // 编程错误：不泄露详细信息
    logger.error('编程错误:', err);
    
    res.status(500).json({
      success: false,
      message: '服务器内部错误',
    });
  }
};

// 处理 MongoDB 转换错误
const handleCastErrorDB = (err: any): AppError => {
  const message = `无效的 ${err.path}: ${err.value}`;
  return new AppError(message, 400);
};

// 处理 MongoDB 重复键错误
const handleDuplicateFieldsDB = (err: any): AppError => {
  const value = err.errmsg.match(/(["'])(\\?.)*?\1/)[0];
  const message = `重复的字段值: ${value}，请使用其他值！`;
  return new AppError(message, 400);
};

// 处理 MongoDB 验证错误
const handleValidationErrorDB = (err: any): AppError => {
  const errors = Object.values(err.errors).map((el: any) => el.message);
  const message = `无效的输入数据: ${errors.join(', ')}`;
  return new AppError(message, 400);
};

// 处理 JWT 错误
const handleJWTError = (): AppError =>
  new AppError('无效的令牌，请重新登录！', 401);

// 处理 JWT 过期错误
const handleJWTExpiredError = (): AppError =>
  new AppError('令牌已过期，请重新登录！', 401);

// 全局错误处理中间件
export const errorHandler = (
  err: any,
  req: Request,
  res: Response,
  next: NextFunction
) => {
  let error = { ...err };
  error.message = err.message;

  // 设置默认状态码
  error.statusCode = err.statusCode || 500;

  // 记录错误
  logger.error('错误详情:', {
    message: err.message,
    stack: err.stack,
    url: req.url,
    method: req.method,
    ip: req.ip,
    userAgent: req.get('User-Agent'),
  });

  // MongoDB 错误处理
  if (err.name === 'CastError') error = handleCastErrorDB(error);
  if (err.code === 11000) error = handleDuplicateFieldsDB(error);
  if (err.name === 'ValidationError') error = handleValidationErrorDB(error);
  if (err.name === 'JsonWebTokenError') error = handleJWTError();
  if (err.name === 'TokenExpiredError') error = handleJWTExpiredError();

  // 发送错误响应
  if (process.env.NODE_ENV === 'development') {
    sendErrorDev(error, res);
  } else {
    sendErrorProd(error, res);
  }
};

export default errorHandler;
