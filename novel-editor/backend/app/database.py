from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os
from dotenv import load_dotenv

load_dotenv()

# 检查是否为开发环境
is_dev = os.getenv("DEBUG", "True").lower() == "true"

if is_dev:
    # 开发环境使用SQLite
    DATABASE_URL = "sqlite:///./novel_editor.db"
    engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False}, echo=True)
else:
    # 生产环境使用MySQL
    SYSTEM_DATABASE_URL = f"mysql+pymysql://{os.getenv('DATABASE_SYSTEM_USER')}:{os.getenv('DATABASE_SYSTEM_PASSWORD')}@{os.getenv('DATABASE_SYSTEM_HOST')}:{os.getenv('DATABASE_SYSTEM_PORT')}/{os.getenv('DATABASE_SYSTEM_NAME')}"
    engine = create_engine(SYSTEM_DATABASE_URL, echo=True)

# 创建会话工厂
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# 创建基类
Base = declarative_base()

# 依赖注入
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
