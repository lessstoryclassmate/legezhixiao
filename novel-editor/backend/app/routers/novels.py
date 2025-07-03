from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from app.database import get_db
from app.schemas.schemas import Novel, NovelCreate, NovelUpdate
from app.models.user import Novel as NovelModel, User as UserModel
from app.routers.auth import get_current_user

router = APIRouter()

@router.post("/", response_model=Novel)
async def create_novel(
    novel: NovelCreate,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    """创建新小说"""
    db_novel = NovelModel(**novel.dict(), author_id=current_user.id)
    db.add(db_novel)
    db.commit()
    db.refresh(db_novel)
    return db_novel

@router.get("/", response_model=List[Novel])
async def read_novels(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    """获取当前用户的小说列表"""
    novels = db.query(NovelModel).filter(
        NovelModel.author_id == current_user.id
    ).offset(skip).limit(limit).all()
    return novels

@router.get("/{novel_id}", response_model=Novel)
async def read_novel(
    novel_id: int,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    """获取指定小说"""
    novel = db.query(NovelModel).filter(
        NovelModel.id == novel_id,
        NovelModel.author_id == current_user.id
    ).first()
    if novel is None:
        raise HTTPException(status_code=404, detail="小说不存在")
    return novel

@router.put("/{novel_id}", response_model=Novel)
async def update_novel(
    novel_id: int,
    novel_update: NovelUpdate,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    """更新小说信息"""
    novel = db.query(NovelModel).filter(
        NovelModel.id == novel_id,
        NovelModel.author_id == current_user.id
    ).first()
    if novel is None:
        raise HTTPException(status_code=404, detail="小说不存在")
    
    for field, value in novel_update.dict(exclude_unset=True).items():
        setattr(novel, field, value)
    
    db.commit()
    db.refresh(novel)
    return novel

@router.delete("/{novel_id}")
async def delete_novel(
    novel_id: int,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    """删除小说"""
    novel = db.query(NovelModel).filter(
        NovelModel.id == novel_id,
        NovelModel.author_id == current_user.id
    ).first()
    if novel is None:
        raise HTTPException(status_code=404, detail="小说不存在")
    
    db.delete(novel)
    db.commit()
    return {"message": "小说已删除"}
