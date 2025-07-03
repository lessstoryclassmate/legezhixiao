from sqlalchemy import Column, Integer, String, Text, DateTime, Boolean, ForeignKey, JSON
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base

class User(Base):
    """用户模型"""
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, index=True, nullable=False)
    email = Column(String(100), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    full_name = Column(String(100))
    is_active = Column(Boolean, default=True)
    is_verified = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # 关系
    novels = relationship("Novel", back_populates="author")
    user_settings = relationship("UserSettings", back_populates="user", uselist=False)

class UserSettings(Base):
    """用户设置模型"""
    __tablename__ = "user_settings"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True)
    theme = Column(String(20), default="dark")  # dark, light
    language = Column(String(10), default="zh-CN")
    ai_model_preference = Column(String(50), default="deepseek-v3")  # deepseek-v3, qwen
    auto_save_interval = Column(Integer, default=30)  # 秒
    settings_json = Column(JSON)  # 其他自定义设置
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # 关系
    user = relationship("User", back_populates="user_settings")

class Novel(Base):
    """小说模型"""
    __tablename__ = "novels"
    
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(200), nullable=False)
    description = Column(Text)
    genre = Column(String(50))  # 类型：玄幻、科幻、都市等
    status = Column(String(20), default="draft")  # draft, writing, completed, published
    cover_image = Column(String(500))  # 封面图片URL
    word_count = Column(Integer, default=0)
    chapter_count = Column(Integer, default=0)
    author_id = Column(Integer, ForeignKey("users.id"))
    is_public = Column(Boolean, default=False)
    novel_metadata = Column(JSON)  # 小说元数据：标签、设定等
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # 关系
    author = relationship("User", back_populates="novels")
    chapters = relationship("Chapter", back_populates="novel", cascade="all, delete-orphan")
    characters = relationship("Character", back_populates="novel", cascade="all, delete-orphan")
    plots = relationship("Plot", back_populates="novel", cascade="all, delete-orphan")
    world_settings = relationship("WorldSetting", back_populates="novel", cascade="all, delete-orphan")

class Chapter(Base):
    """章节模型"""
    __tablename__ = "chapters"
    
    id = Column(Integer, primary_key=True, index=True)
    novel_id = Column(Integer, ForeignKey("novels.id"))
    title = Column(String(200), nullable=False)
    content = Column(Text)
    chapter_number = Column(Integer, nullable=False)
    word_count = Column(Integer, default=0)
    status = Column(String(20), default="draft")  # draft, completed, published
    notes = Column(Text)  # 章节备注
    ai_analysis = Column(JSON)  # AI分析结果：情感曲线、角色关系等
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # 关系
    novel = relationship("Novel", back_populates="chapters")
    plot_points = relationship("PlotPoint", back_populates="chapter")

class Character(Base):
    """人物模型"""
    __tablename__ = "characters"
    
    id = Column(Integer, primary_key=True, index=True)
    novel_id = Column(Integer, ForeignKey("novels.id"))
    name = Column(String(100), nullable=False)
    alias = Column(String(200))  # 别名、称号
    role = Column(String(50))  # 主角、配角、反派等
    description = Column(Text)
    personality = Column(Text)  # 性格描述
    background = Column(Text)  # 背景故事
    appearance = Column(Text)  # 外貌描述
    abilities = Column(JSON)  # 能力设定
    relationships = Column(JSON)  # 人物关系
    character_arc = Column(JSON)  # 人物成长弧线
    avatar = Column(String(500))  # 头像URL
    character_metadata = Column(JSON)  # 其他元数据
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # 关系
    novel = relationship("Novel", back_populates="characters")

class Plot(Base):
    """剧情线模型"""
    __tablename__ = "plots"
    
    id = Column(Integer, primary_key=True, index=True)
    novel_id = Column(Integer, ForeignKey("novels.id"))
    name = Column(String(200), nullable=False)
    plot_type = Column(String(50))  # main, sub, branch 主线、支线、分支
    description = Column(Text)
    status = Column(String(20), default="planned")  # planned, active, completed, abandoned
    priority = Column(Integer, default=1)  # 优先级
    plot_structure = Column(JSON)  # 剧情结构
    foreshadowing = Column(JSON)  # 伏笔设置
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # 关系
    novel = relationship("Novel", back_populates="plots")
    plot_points = relationship("PlotPoint", back_populates="plot")

class PlotPoint(Base):
    """剧情节点模型"""
    __tablename__ = "plot_points"
    
    id = Column(Integer, primary_key=True, index=True)
    plot_id = Column(Integer, ForeignKey("plots.id"))
    chapter_id = Column(Integer, ForeignKey("chapters.id"), nullable=True)
    title = Column(String(200), nullable=False)
    description = Column(Text)
    point_type = Column(String(50))  # setup, conflict, climax, resolution
    order_index = Column(Integer)  # 在剧情线中的顺序
    status = Column(String(20), default="planned")
    plot_metadata = Column(JSON)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # 关系
    plot = relationship("Plot", back_populates="plot_points")
    chapter = relationship("Chapter", back_populates="plot_points")

class WorldSetting(Base):
    """世界观设定模型"""
    __tablename__ = "world_settings"
    
    id = Column(Integer, primary_key=True, index=True)
    novel_id = Column(Integer, ForeignKey("novels.id"))
    category = Column(String(50), nullable=False)  # geography, culture, magic, technology等
    name = Column(String(200), nullable=False)
    description = Column(Text)
    rules = Column(JSON)  # 规则设定
    relationships = Column(JSON)  # 与其他设定的关系
    references = Column(JSON)  # 相关章节引用
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # 关系
    novel = relationship("Novel", back_populates="world_settings")
