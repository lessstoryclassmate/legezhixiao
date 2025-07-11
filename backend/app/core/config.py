from pydantic_settings import BaseSettings
from typing import List, Union
import os
from pydantic import field_validator, ValidationInfo

class Settings(BaseSettings):
    # 应用配置
    APP_NAME: str = "AI小说内容编辑器"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = False
    
    # 服务器配置
    SERVER_IP: str = "106.13.216.179"
    SERVER_USER: str = "root"
    SERVER_SSH_PORT: int = 22
    SERVER_PORT: int = 22
    
    # 数据库配置
    MONGODB_URL: str = "mongodb://localhost:27017/ai_novel_db"
    REDIS_URL: str = "redis://localhost:6379"
    
    # SiliconFlow API配置
    SILICONFLOW_API_KEY: str = "sk-mjithqmjwccqgffouexthbavtnvftwkqjludpcxhrmeztcib"
    SILICONFLOW_API_URL: str = "https://api.siliconflow.cn/v1/chat/completions"
    SILICONFLOW_DEFAULT_MODEL: str = "deepseek-ai/DeepSeek-V3"
    
    # MCP接口配置
    MCP_SERVER_NAME: str = "novel-ai-server"
    MCP_SERVER_PORT: int = 8000
    MCP_SERVER_HOST: str = "106.13.216.179"
    MCP_TOOLS_ENABLED: bool = True
    MCP_TOOLS_LIST: str = "novel_generation,character_creation,plot_analysis,content_review,style_transfer"
    
    # 小说生成相关配置
    NOVEL_GENERATION_MAX_TOKENS: int = 4096
    NOVEL_GENERATION_TEMPERATURE: float = 0.8
    NOVEL_GENERATION_TOP_P: float = 0.9
    
    # JWT配置
    JWT_SECRET_KEY: str = "your-secret-key-here"
    JWT_ALGORITHM: str = "HS256"
    JWT_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7天
    
    # CORS配置
    CORS_ORIGINS: Union[str, List[str]] = [
        "http://localhost:80",
        "http://127.0.0.1:80",
        "http://localhost:8080",
        "http://127.0.0.1:8080",
        "http://localhost:3000",
        "http://127.0.0.1:3000",
        "http://106.13.216.179:80",
        "http://106.13.216.179:8080"
    ]
    
    def get_cors_origins(self) -> List[str]:
        if isinstance(self.CORS_ORIGINS, str):
            return [url.strip() for url in self.CORS_ORIGINS.split(',') if url.strip()]
        elif isinstance(self.CORS_ORIGINS, list):
            return self.CORS_ORIGINS
        else:
            return [
                "http://localhost:80",
                "http://127.0.0.1:80",
                "http://localhost:8080",
                "http://127.0.0.1:8080"
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
