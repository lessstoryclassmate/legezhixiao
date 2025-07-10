from pydantic_settings import BaseSettings
from typing import List
import os

class Settings(BaseSettings):
    # 应用配置
    APP_NAME: str = "AI小说内容编辑器"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = False
    
    # 数据库配置
    MONGODB_URL: str = "mongodb://localhost:27017/ai_novel_db"
    MYSQL_URL: str = "mysql+aiomysql://user:password@localhost:3306/ai_novel_cloud"
    REDIS_URL: str = "redis://localhost:6379"
    
    # SiliconFlow API配置
    SILICONFLOW_API_KEY: str = ""
    SILICONFLOW_API_URL: str = "https://api.siliconflow.cn/v1"
    SILICONFLOW_MODEL: str = "deepseek-v3"
    
    # JWT配置
    JWT_SECRET_KEY: str = "your-secret-key-here"
    JWT_ALGORITHM: str = "HS256"
    JWT_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7天
    
    # CORS配置
    CORS_ORIGINS: List[str] = [
        "http://localhost:80",
        "http://127.0.0.1:80",
        "http://localhost:3000",
        "http://127.0.0.1:3000"
    ]
    
    # 文件上传配置
    UPLOAD_DIR: str = "uploads"
    MAX_FILE_SIZE: int = 10 * 1024 * 1024  # 10MB
    ALLOWED_EXTENSIONS: List[str] = [".txt", ".md", ".docx", ".pdf"]
    
    # 分页配置
    DEFAULT_PAGE_SIZE: int = 20
    MAX_PAGE_SIZE: int = 100
    
    # 缓存配置
    CACHE_TTL: int = 3600  # 1小时
    
    # 日志配置
    LOG_LEVEL: str = "INFO"
    LOG_FILE: str = "logs/app.log"
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = True

# 全局配置实例
settings = Settings()

# 确保上传目录存在
os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
os.makedirs(os.path.dirname(settings.LOG_FILE), exist_ok=True)
