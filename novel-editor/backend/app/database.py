from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os
from dotenv import load_dotenv

load_dotenv()

# 检查是否为开发环境
is_dev = os.getenv("DEBUG", "True").lower() == "true"

def get_database_url():
    """根据环境配置获取数据库连接URL"""
    
    if is_dev:
        # 开发环境使用SQLite
        return "sqlite:///./novel_editor.db"
    else:
        # 生产环境使用MySQL
        # 优先使用系统数据库配置
        system_host = os.getenv("DATABASE_SYSTEMIP", "172.16.16.3")
        system_port = os.getenv("DATABASE_PORT", "3306")
        system_name = os.getenv("DATABASE_SYSTEM", "novel_data")
        system_user = os.getenv("DATABASE_USER", "lkr")
        system_password = os.getenv("DATABASE_PASSWORD")
        
        if system_password:
            return f"mysql+pymysql://{system_user}:{system_password}@{system_host}:{system_port}/{system_name}?charset=utf8mb4"
        
        # 备用：用户数据库配置
        novel_host = os.getenv("DATABASE_NOVELIP", "172.16.16.2")
        novel_port = os.getenv("DATABASE_PORT", "3306")
        novel_name = os.getenv("DATABASE_NOVELDATA", "novel_user_data")
        novel_user = os.getenv("DATABASE_NOVELUSER", "novel_data_user")
        novel_password = os.getenv("DATABASE_NOVELUSER_PASSWORD")
        
        if novel_password:
            return f"mysql+pymysql://{novel_user}:{novel_password}@{novel_host}:{novel_port}/{novel_name}?charset=utf8mb4"
        
        # 如果都没有配置，回退到SQLite
        print("⚠️ 警告: 未配置生产环境数据库密码，使用SQLite")
        return "sqlite:///./novel_editor.db"

# 获取数据库URL
DATABASE_URL = get_database_url()

if DATABASE_URL.startswith("sqlite"):
    # SQLite配置
    engine = create_engine(
        DATABASE_URL, 
        connect_args={"check_same_thread": False}, 
        echo=True
    )
else:
    # MySQL配置
    engine = create_engine(
        DATABASE_URL, 
        pool_pre_ping=True,
        pool_recycle=3600,
        echo=True,
        connect_args={"charset": "utf8mb4"}
    )

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

# 创建表的函数
def create_tables():
    """创建数据库表"""
    try:
        Base.metadata.create_all(bind=engine)
        print(f"✅ 数据库表创建成功")
    except Exception as e:
        print(f"❌ 数据库表创建失败: {e}")
        raise

# 检查数据库连接
def check_database_connection():
    """检查数据库连接"""
    try:
        db = SessionLocal()
        db.execute("SELECT 1")
        db.close()
        db_type = "MySQL" if "mysql" in DATABASE_URL else "SQLite"
        print(f"✅ {db_type}数据库连接正常")
        return True
    except Exception as e:
        print(f"❌ 数据库连接失败: {e}")
        return False
