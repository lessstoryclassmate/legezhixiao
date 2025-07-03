from pydantic import BaseModel, EmailStr
from typing import Optional, List, Dict, Any
from datetime import datetime

# 用户相关模式
class UserBase(BaseModel):
    username: str
    email: EmailStr
    full_name: Optional[str] = None

class UserCreate(UserBase):
    password: str

class UserUpdate(BaseModel):
    username: Optional[str] = None
    email: Optional[EmailStr] = None
    full_name: Optional[str] = None
    is_active: Optional[bool] = None

class UserInDB(UserBase):
    id: int
    is_active: bool
    is_verified: bool
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

class User(UserInDB):
    pass

# 用户设置模式
class UserSettingsBase(BaseModel):
    theme: str = "dark"
    language: str = "zh-CN"
    ai_model_preference: str = "deepseek-v3"
    auto_save_interval: int = 30
    settings_json: Optional[Dict[str, Any]] = None

class UserSettingsCreate(UserSettingsBase):
    pass

class UserSettingsUpdate(BaseModel):
    theme: Optional[str] = None
    language: Optional[str] = None
    ai_model_preference: Optional[str] = None
    auto_save_interval: Optional[int] = None
    settings_json: Optional[Dict[str, Any]] = None

class UserSettings(UserSettingsBase):
    id: int
    user_id: int
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

# 小说相关模式
class NovelBase(BaseModel):
    title: str
    description: Optional[str] = None
    genre: Optional[str] = None
    cover_image: Optional[str] = None
    is_public: bool = False
    novel_metadata: Optional[Dict[str, Any]] = None

class NovelCreate(NovelBase):
    pass

class NovelUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    genre: Optional[str] = None
    status: Optional[str] = None
    cover_image: Optional[str] = None
    is_public: Optional[bool] = None
    novel_metadata: Optional[Dict[str, Any]] = None

class Novel(NovelBase):
    id: int
    status: str
    word_count: int
    chapter_count: int
    author_id: int
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

# 章节相关模式
class ChapterBase(BaseModel):
    title: str
    content: Optional[str] = None
    chapter_number: int
    notes: Optional[str] = None

class ChapterCreate(ChapterBase):
    novel_id: int

class ChapterUpdate(BaseModel):
    title: Optional[str] = None
    content: Optional[str] = None
    notes: Optional[str] = None
    status: Optional[str] = None

class Chapter(ChapterBase):
    id: int
    novel_id: int
    word_count: int
    status: str
    ai_analysis: Optional[Dict[str, Any]] = None
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

# 人物相关模式
class CharacterBase(BaseModel):
    name: str
    alias: Optional[str] = None
    role: Optional[str] = None
    description: Optional[str] = None
    personality: Optional[str] = None
    background: Optional[str] = None
    appearance: Optional[str] = None
    avatar: Optional[str] = None
    abilities: Optional[Dict[str, Any]] = None
    relationships: Optional[Dict[str, Any]] = None
    character_arc: Optional[Dict[str, Any]] = None
    character_metadata: Optional[Dict[str, Any]] = None

class CharacterCreate(CharacterBase):
    novel_id: int

class CharacterUpdate(BaseModel):
    name: Optional[str] = None
    alias: Optional[str] = None
    role: Optional[str] = None
    description: Optional[str] = None
    personality: Optional[str] = None
    background: Optional[str] = None
    appearance: Optional[str] = None
    avatar: Optional[str] = None
    abilities: Optional[Dict[str, Any]] = None
    relationships: Optional[Dict[str, Any]] = None
    character_arc: Optional[Dict[str, Any]] = None
    character_metadata: Optional[Dict[str, Any]] = None

class Character(CharacterBase):
    id: int
    novel_id: int
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

# 剧情相关模式
class PlotBase(BaseModel):
    name: str
    plot_type: str = "main"
    description: Optional[str] = None
    priority: int = 1
    plot_structure: Optional[Dict[str, Any]] = None
    foreshadowing: Optional[Dict[str, Any]] = None

class PlotCreate(PlotBase):
    novel_id: int

class PlotUpdate(BaseModel):
    name: Optional[str] = None
    plot_type: Optional[str] = None
    description: Optional[str] = None
    status: Optional[str] = None
    priority: Optional[int] = None
    plot_structure: Optional[Dict[str, Any]] = None
    foreshadowing: Optional[Dict[str, Any]] = None

class Plot(PlotBase):
    id: int
    novel_id: int
    status: str
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

# 世界观相关模式
class WorldSettingBase(BaseModel):
    category: str
    name: str
    description: Optional[str] = None
    rules: Optional[Dict[str, Any]] = None
    relationships: Optional[Dict[str, Any]] = None
    references: Optional[Dict[str, Any]] = None

class WorldSettingCreate(WorldSettingBase):
    novel_id: int

class WorldSettingUpdate(BaseModel):
    category: Optional[str] = None
    name: Optional[str] = None
    description: Optional[str] = None
    rules: Optional[Dict[str, Any]] = None
    relationships: Optional[Dict[str, Any]] = None
    references: Optional[Dict[str, Any]] = None

class WorldSetting(WorldSettingBase):
    id: int
    novel_id: int
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

# 认证相关模式
class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    username: Optional[str] = None

class LoginRequest(BaseModel):
    username: str
    password: str

# AI助手相关模式
class AIRequest(BaseModel):
    task_type: str  # generate, analyze, suggest, optimize
    content: str
    context: Optional[Dict[str, Any]] = None
    model: str = "deepseek-v3"

class AIResponse(BaseModel):
    result: str
    response_metadata: Optional[Dict[str, Any]] = None
    tokens_used: Optional[int] = None
