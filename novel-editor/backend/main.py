from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer
import uvicorn
import os
from dotenv import load_dotenv

from app.routers import auth, users, novels, chapters, characters, plots, worlds, ai_assistant
from app.database import engine, Base
from app.middleware.error_handler import ErrorHandlerMiddleware

# 加载环境变量
load_dotenv()

# 创建数据库表
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="AI小说内容编辑器",
    description="基于SiliconFlow API的AI辅助小说创作平台",
    version="1.0.0"
)

# 中间件配置
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 生产环境需要配置具体域名
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.add_middleware(ErrorHandlerMiddleware)

security = HTTPBearer()

# 路由注册
app.include_router(auth.router, prefix="/api/v1/auth", tags=["认证"])
app.include_router(users.router, prefix="/api/v1/users", tags=["用户"])
app.include_router(novels.router, prefix="/api/v1/novels", tags=["小说"])
app.include_router(chapters.router, prefix="/api/v1/chapters", tags=["章节"])
app.include_router(characters.router, prefix="/api/v1/characters", tags=["人物"])
app.include_router(plots.router, prefix="/api/v1/plots", tags=["剧情"])
app.include_router(worlds.router, prefix="/api/v1/worlds", tags=["世界观"])
app.include_router(ai_assistant.router, prefix="/api/v1/ai", tags=["AI助手"])

@app.get("/")
async def root():
    return {"message": "AI小说内容编辑器 API"}

@app.get("/health")
async def health_check():
    return {"status": "healthy", "message": "API运行正常"}

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host=os.getenv("HOST", "0.0.0.0"),
        port=int(os.getenv("PORT", 8000)),
        reload=os.getenv("DEBUG", "False").lower() == "true"
    )
