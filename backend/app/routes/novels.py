from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
from bson import ObjectId
from app.database import novels_collection
from app.routes.auth import verify_token

router = APIRouter()

class NovelCreate(BaseModel):
    title: str
    description: Optional[str] = None
    genre: Optional[str] = None
    tags: List[str] = []

class NovelUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    genre: Optional[str] = None
    tags: Optional[List[str]] = None
    status: Optional[str] = None

class NovelResponse(BaseModel):
    id: str
    title: str
    description: Optional[str]
    genre: Optional[str]
    tags: List[str]
    status: str
    word_count: int
    chapter_count: int
    created_at: datetime
    updated_at: datetime

# 创建小说
@router.post("/", response_model=NovelResponse)
async def create_novel(novel: NovelCreate, user_id: str = Depends(verify_token)):
    novel_doc = {
        "user_id": ObjectId(user_id),
        "title": novel.title,
        "description": novel.description,
        "genre": novel.genre,
        "tags": novel.tags,
        "status": "draft",
        "word_count": 0,
        "chapter_count": 0,
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow()
    }
    
    result = await novels_collection.insert_one(novel_doc)
    novel_doc["id"] = str(result.inserted_id)
    
    return NovelResponse(**novel_doc)

# 获取用户的小说列表
@router.get("/", response_model=List[NovelResponse])
async def get_novels(
    skip: int = 0,
    limit: int = 20,
    user_id: str = Depends(verify_token)
):
    cursor = novels_collection.find(
        {"user_id": ObjectId(user_id)}
    ).sort("updated_at", -1).skip(skip).limit(limit)
    
    novels = []
    async for novel_doc in cursor:
        novel_doc["id"] = str(novel_doc.pop("_id"))
        novels.append(NovelResponse(**novel_doc))
    
    return novels

# 获取单个小说
@router.get("/{novel_id}", response_model=NovelResponse)
async def get_novel(novel_id: str, user_id: str = Depends(verify_token)):
    novel_doc = await novels_collection.find_one({
        "_id": ObjectId(novel_id),
        "user_id": ObjectId(user_id)
    })
    
    if not novel_doc:
        raise HTTPException(status_code=404, detail="小说不存在")
    
    novel_doc["id"] = str(novel_doc.pop("_id"))
    return NovelResponse(**novel_doc)

# 更新小说
@router.put("/{novel_id}", response_model=NovelResponse)
async def update_novel(
    novel_id: str,
    novel: NovelUpdate,
    user_id: str = Depends(verify_token)
):
    # 构建更新数据
    update_data = {}
    if novel.title is not None:
        update_data["title"] = novel.title
    if novel.description is not None:
        update_data["description"] = novel.description
    if novel.genre is not None:
        update_data["genre"] = novel.genre
    if novel.tags is not None:
        update_data["tags"] = novel.tags
    if novel.status is not None:
        update_data["status"] = novel.status
    
    update_data["updated_at"] = datetime.utcnow()
    
    result = await novels_collection.update_one(
        {"_id": ObjectId(novel_id), "user_id": ObjectId(user_id)},
        {"$set": update_data}
    )
    
    if result.modified_count == 0:
        raise HTTPException(status_code=404, detail="小说不存在")
    
    # 返回更新后的小说
    novel_doc = await novels_collection.find_one({
        "_id": ObjectId(novel_id),
        "user_id": ObjectId(user_id)
    })
    
    novel_doc["id"] = str(novel_doc.pop("_id"))
    return NovelResponse(**novel_doc)

# 删除小说
@router.delete("/{novel_id}")
async def delete_novel(novel_id: str, user_id: str = Depends(verify_token)):
    result = await novels_collection.delete_one({
        "_id": ObjectId(novel_id),
        "user_id": ObjectId(user_id)
    })
    
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="小说不存在")
    
    return {"message": "小说已删除"}
