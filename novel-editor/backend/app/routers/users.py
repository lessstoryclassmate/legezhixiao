from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.database import get_db
from app.schemas.schemas import User, UserUpdate
from app.models.user import User as UserModel
from app.routers.auth import get_current_user

router = APIRouter()

@router.get("/", response_model=List[User])
async def read_users(
    skip: int = 0, 
    limit: int = 100, 
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    """获取用户列表（管理员功能）"""
    # 这里可以添加管理员权限检查
    users = db.query(UserModel).offset(skip).limit(limit).all()
    return users

@router.get("/{user_id}", response_model=User)
async def read_user(
    user_id: int, 
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    """获取指定用户信息"""
    user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if user is None:
        raise HTTPException(status_code=404, detail="用户不存在")
    return user

@router.put("/me", response_model=User)
async def update_user(
    user_update: UserUpdate,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    """更新当前用户信息"""
    for field, value in user_update.dict(exclude_unset=True).items():
        setattr(current_user, field, value)
    
    db.commit()
    db.refresh(current_user)
    return current_user

@router.delete("/me")
async def delete_user(
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    """删除当前用户账户"""
    db.delete(current_user)
    db.commit()
    return {"message": "账户已删除"}
