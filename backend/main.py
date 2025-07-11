from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from contextlib import asynccontextmanager
from datetime import datetime
import os
from dotenv import load_dotenv

# 加载环境变量
load_dotenv()

# 导入路由模块
from app.routes import auth, novels, chapters, characters, ai_assistant
from app.api import md_files
from app.database import mongodb, redis_client, mongodb_client
from app.core.config import settings

# 创建应用实例
@asynccontextmanager
async def lifespan(app: FastAPI):
    # 启动时执行
    print("🚀 启动AI小说内容编辑器...")
    print(f"📊 MongoDB: {settings.MONGODB_URL}")
    print(f"🔄 Redis: {settings.REDIS_URL}")
    yield
    # 关闭时执行
    print("🛑 关闭AI小说内容编辑器...")

app = FastAPI(
    title="AI小说内容编辑器",
    description="基于SiliconFlow API的智能小说创作平台",
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc"
)

# 配置CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.get_cors_origins(),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 注册路由
app.include_router(auth.router, prefix="/auth", tags=["认证"])
app.include_router(novels.router, prefix="/novels", tags=["小说管理"])
app.include_router(chapters.router, prefix="/chapters", tags=["章节管理"])
app.include_router(characters.router, prefix="/characters", tags=["人物管理"])
app.include_router(ai_assistant.router, prefix="/ai", tags=["AI助手"])
app.include_router(md_files.router, prefix="/api", tags=["MD文件管理"])

# 根路径
@app.get("/")
async def root():
    return {
        "message": "AI小说内容编辑器 API",
        "version": "1.0.0",
        "docs": "/docs"
    }

# 健康检查
@app.get("/health")
async def health_check():
    """
    健康检查端点，检查服务和依赖状态
    即使某些依赖不可用，也会返回部分状态信息
    """
    health_status = {
        "status": "healthy",
        "services": {},
        "timestamp": str(datetime.now())
    }
    
    # 检查MongoDB连接
    try:
        await mongodb_client.get_database('admin').command('ping')
        health_status["services"]["mongodb"] = "healthy"
    except Exception as e:
        health_status["services"]["mongodb"] = f"unhealthy: {str(e)}"
        health_status["status"] = "degraded"
    
    # 检查Redis连接
    try:
        await redis_client.ping()
        health_status["services"]["redis"] = "healthy"
    except Exception as e:
        health_status["services"]["redis"] = f"unhealthy: {str(e)}"
        health_status["status"] = "degraded"
    
    return health_status

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=False,
        log_level="info"
    )
