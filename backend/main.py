from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from contextlib import asynccontextmanager
import os
from dotenv import load_dotenv

# 加载环境变量
load_dotenv()

# 导入路由模块
from app.routes import auth, novels, chapters, characters, ai_assistant
from app.database import mongodb, redis_client
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
    allow_origins=settings.CORS_ORIGINS,
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
    try:
        # 检查MongoDB连接
        await mongodb.admin.command('ping')
        mongodb_status = "healthy"
    except Exception as e:
        mongodb_status = f"unhealthy: {str(e)}"
    
    try:
        # 检查Redis连接
        await redis_client.ping()
        redis_status = "healthy"
    except Exception as e:
        redis_status = f"unhealthy: {str(e)}"
    
    return {
        "status": "healthy",
        "services": {
            "mongodb": mongodb_status,
            "redis": redis_status
        }
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=False,
        log_level="info"
    )
