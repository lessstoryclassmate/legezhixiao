from fastapi import APIRouter, HTTPException, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel
from typing import Optional
from datetime import datetime, timedelta
import jwt
import bcrypt
from bson import ObjectId
from app.database import users_collection
from app.core.config import settings

router = APIRouter()
security = HTTPBearer()

class UserRegister(BaseModel):
    username: str
    email: str
    password: str

class UserLogin(BaseModel):
    email: str
    password: str

class UserResponse(BaseModel):
    id: str
    username: str
    email: str
    created_at: datetime

class TokenResponse(BaseModel):
    access_token: str
    token_type: str
    expires_in: int

# 创建JWT令牌
def create_access_token(data: dict):
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=settings.JWT_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)
    return encoded_jwt

# 验证JWT令牌
def verify_token(credentials: HTTPAuthorizationCredentials = Depends(security)):
    try:
        payload = jwt.decode(credentials.credentials, settings.JWT_SECRET_KEY, algorithms=[settings.JWT_ALGORITHM])
        user_id = payload.get("sub")
        if user_id is None:
            raise HTTPException(status_code=401, detail="Invalid token")
        return user_id
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expired")
    except jwt.JWTError:
        raise HTTPException(status_code=401, detail="Invalid token")

# 用户注册
@router.post("/register", response_model=UserResponse)
async def register(user: UserRegister):
    # 检查用户是否已存在
    existing_user = await users_collection.find_one({
        "$or": [
            {"email": user.email},
            {"username": user.username}
        ]
    })
    
    if existing_user:
        raise HTTPException(status_code=400, detail="用户已存在")
    
    # 加密密码
    password_hash = bcrypt.hashpw(user.password.encode('utf-8'), bcrypt.gensalt())
    
    # 创建用户
    user_doc = {
        "username": user.username,
        "email": user.email,
        "password_hash": password_hash,
        "is_active": True,
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow()
    }
    
    result = await users_collection.insert_one(user_doc)
    user_doc["id"] = str(result.inserted_id)
    
    return UserResponse(
        id=user_doc["id"],
        username=user_doc["username"],
        email=user_doc["email"],
        created_at=user_doc["created_at"]
    )

# 用户登录
@router.post("/login", response_model=TokenResponse)
async def login(user: UserLogin):
    # 查找用户
    user_doc = await users_collection.find_one({"email": user.email})
    
    if not user_doc:
        raise HTTPException(status_code=400, detail="用户不存在")
    
    # 验证密码
    if not bcrypt.checkpw(user.password.encode('utf-8'), user_doc["password_hash"]):
        raise HTTPException(status_code=400, detail="密码错误")
    
    # 创建访问令牌
    access_token = create_access_token(data={"sub": str(user_doc["_id"])})
    
    return TokenResponse(
        access_token=access_token,
        token_type="bearer",
        expires_in=settings.JWT_EXPIRE_MINUTES * 60
    )

# 获取当前用户信息
@router.get("/me", response_model=UserResponse)
async def get_current_user_info(user_id: str = Depends(verify_token)):
    """获取当前用户信息的接口"""
    user_doc = await users_collection.find_one({"_id": ObjectId(user_id)})
    
    if not user_doc:
        raise HTTPException(status_code=404, detail="用户不存在")
    
    return UserResponse(
        id=str(user_doc["_id"]),
        username=user_doc["username"],
        email=user_doc["email"],
        created_at=user_doc["created_at"]
    )

# 用于依赖注入的函数
async def get_current_user(user_id: str = Depends(verify_token)) -> UserResponse:
    """获取当前用户信息（用于依赖注入）"""
    user_doc = await users_collection.find_one({"_id": ObjectId(user_id)})
    
    if not user_doc:
        raise HTTPException(status_code=404, detail="用户不存在")
    
    return UserResponse(
        id=str(user_doc["_id"]),
        username=user_doc["username"],
        email=user_doc["email"],
        created_at=user_doc["created_at"]
    )
