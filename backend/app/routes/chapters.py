from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
from datetime import datetime
from bson import ObjectId
from app.database import chapters_collection, novels_collection
from app.routes.auth import verify_token

router = APIRouter()

class ChapterCreate(BaseModel):
    novel_id: str
    title: str
    content: str
    order: Optional[int] = None

class ChapterUpdate(BaseModel):
    title: Optional[str] = None
    content: Optional[str] = None
    order: Optional[int] = None

class ChapterResponse(BaseModel):
    id: str
    novel_id: str
    title: str
    content: str
    order: int
    word_count: int
    dna_analysis: Optional[Dict[str, Any]] = None
    created_at: datetime
    updated_at: datetime

class ChapterDNA(BaseModel):
    key_characters: List[str]
    time_location: Dict[str, Any]
    plot_type: str
    energy_curve: int
    foreshadows: List[str]

# 分析章节DNA
def analyze_chapter_dna(content: str) -> Dict[str, Any]:
    """
    分析章节内容，提取剧情DNA
    这里是简化版本，实际应该使用NLP技术
    """
    # 简单的字数统计
    word_count = len(content)
    
    # 模拟DNA分析
    return {
        "key_characters": [],  # 关键角色
        "time_location": {     # 时空坐标
            "world_map_id": None,
            "time_stamp": None
        },
        "plot_type": "日常",    # 剧情类型
        "energy_curve": min(100, word_count // 10),  # 能量曲线
        "foreshadows": []      # 伏笔触达
    }

# 创建章节
@router.post("/", response_model=ChapterResponse)
async def create_chapter(chapter: ChapterCreate, user_id: str = Depends(verify_token)):
    # 验证小说是否存在且属于当前用户
    novel_doc = await novels_collection.find_one({
        "_id": ObjectId(chapter.novel_id),
        "user_id": ObjectId(user_id)
    })
    
    if not novel_doc:
        raise HTTPException(status_code=404, detail="小说不存在")
    
    # 如果未指定顺序，自动分配
    if chapter.order is None:
        last_chapter = await chapters_collection.find_one(
            {"novel_id": ObjectId(chapter.novel_id)},
            sort=[("order", -1)]
        )
        chapter.order = (last_chapter["order"] + 1) if last_chapter else 1
    
    # 分析章节DNA
    word_count = len(chapter.content)
    dna_analysis = analyze_chapter_dna(chapter.content)
    
    chapter_doc = {
        "novel_id": ObjectId(chapter.novel_id),
        "title": chapter.title,
        "content": chapter.content,
        "order": chapter.order,
        "word_count": word_count,
        "dna_analysis": dna_analysis,
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow()
    }
    
    result = await chapters_collection.insert_one(chapter_doc)
    chapter_doc["id"] = str(result.inserted_id)
    
    # 更新小说的章节数和字数
    await novels_collection.update_one(
        {"_id": ObjectId(chapter.novel_id)},
        {
            "$inc": {
                "chapter_count": 1,
                "word_count": word_count
            },
            "$set": {"updated_at": datetime.utcnow()}
        }
    )
    
    return ChapterResponse(**chapter_doc)

# 获取章节列表
@router.get("/", response_model=List[ChapterResponse])
async def get_chapters(
    novel_id: str,
    skip: int = 0,
    limit: int = 50,
    user_id: str = Depends(verify_token)
):
    # 验证小说权限
    novel_doc = await novels_collection.find_one({
        "_id": ObjectId(novel_id),
        "user_id": ObjectId(user_id)
    })
    
    if not novel_doc:
        raise HTTPException(status_code=404, detail="小说不存在")
    
    cursor = chapters_collection.find(
        {"novel_id": ObjectId(novel_id)}
    ).sort("order", 1).skip(skip).limit(limit)
    
    chapters = []
    async for chapter_doc in cursor:
        chapter_doc["id"] = str(chapter_doc.pop("_id"))
        chapter_doc["novel_id"] = str(chapter_doc["novel_id"])
        chapters.append(ChapterResponse(**chapter_doc))
    
    return chapters

# 获取单个章节
@router.get("/{chapter_id}", response_model=ChapterResponse)
async def get_chapter(chapter_id: str, user_id: str = Depends(verify_token)):
    chapter_doc = await chapters_collection.find_one({"_id": ObjectId(chapter_id)})
    
    if not chapter_doc:
        raise HTTPException(status_code=404, detail="章节不存在")
    
    # 验证小说权限
    novel_doc = await novels_collection.find_one({
        "_id": chapter_doc["novel_id"],
        "user_id": ObjectId(user_id)
    })
    
    if not novel_doc:
        raise HTTPException(status_code=403, detail="无权访问")
    
    chapter_doc["id"] = str(chapter_doc.pop("_id"))
    chapter_doc["novel_id"] = str(chapter_doc["novel_id"])
    return ChapterResponse(**chapter_doc)

# 更新章节
@router.put("/{chapter_id}", response_model=ChapterResponse)
async def update_chapter(
    chapter_id: str,
    chapter: ChapterUpdate,
    user_id: str = Depends(verify_token)
):
    # 获取原章节
    chapter_doc = await chapters_collection.find_one({"_id": ObjectId(chapter_id)})
    
    if not chapter_doc:
        raise HTTPException(status_code=404, detail="章节不存在")
    
    # 验证权限
    novel_doc = await novels_collection.find_one({
        "_id": chapter_doc["novel_id"],
        "user_id": ObjectId(user_id)
    })
    
    if not novel_doc:
        raise HTTPException(status_code=403, detail="无权访问")
    
    # 构建更新数据
    update_data = {}
    if chapter.title is not None:
        update_data["title"] = chapter.title
    if chapter.content is not None:
        update_data["content"] = chapter.content
        update_data["word_count"] = len(chapter.content)
        update_data["dna_analysis"] = analyze_chapter_dna(chapter.content)
    if chapter.order is not None:
        update_data["order"] = chapter.order
    
    update_data["updated_at"] = datetime.utcnow()
    
    # 更新章节
    await chapters_collection.update_one(
        {"_id": ObjectId(chapter_id)},
        {"$set": update_data}
    )
    
    # 如果内容发生变化，更新小说字数
    if chapter.content is not None:
        word_count_diff = len(chapter.content) - chapter_doc["word_count"]
        await novels_collection.update_one(
            {"_id": chapter_doc["novel_id"]},
            {
                "$inc": {"word_count": word_count_diff},
                "$set": {"updated_at": datetime.utcnow()}
            }
        )
    
    # 返回更新后的章节
    updated_chapter = await chapters_collection.find_one({"_id": ObjectId(chapter_id)})
    updated_chapter["id"] = str(updated_chapter.pop("_id"))
    updated_chapter["novel_id"] = str(updated_chapter["novel_id"])
    return ChapterResponse(**updated_chapter)

# 删除章节
@router.delete("/{chapter_id}")
async def delete_chapter(chapter_id: str, user_id: str = Depends(verify_token)):
    chapter_doc = await chapters_collection.find_one({"_id": ObjectId(chapter_id)})
    
    if not chapter_doc:
        raise HTTPException(status_code=404, detail="章节不存在")
    
    # 验证权限
    novel_doc = await novels_collection.find_one({
        "_id": chapter_doc["novel_id"],
        "user_id": ObjectId(user_id)
    })
    
    if not novel_doc:
        raise HTTPException(status_code=403, detail="无权访问")
    
    # 删除章节
    await chapters_collection.delete_one({"_id": ObjectId(chapter_id)})
    
    # 更新小说统计
    await novels_collection.update_one(
        {"_id": chapter_doc["novel_id"]},
        {
            "$inc": {
                "chapter_count": -1,
                "word_count": -chapter_doc["word_count"]
            },
            "$set": {"updated_at": datetime.utcnow()}
        }
    )
    
    return {"message": "章节已删除"}

# 章节DNA分析
@router.get("/{chapter_id}/dna", response_model=ChapterDNA)
async def get_chapter_dna(chapter_id: str, user_id: str = Depends(verify_token)):
    chapter_doc = await chapters_collection.find_one({"_id": ObjectId(chapter_id)})
    
    if not chapter_doc:
        raise HTTPException(status_code=404, detail="章节不存在")
    
    # 验证权限
    novel_doc = await novels_collection.find_one({
        "_id": chapter_doc["novel_id"],
        "user_id": ObjectId(user_id)
    })
    
    if not novel_doc:
        raise HTTPException(status_code=403, detail="无权访问")
    
    dna_data = chapter_doc.get("dna_analysis", {})
    return ChapterDNA(
        key_characters=dna_data.get("key_characters", []),
        time_location=dna_data.get("time_location", {}),
        plot_type=dna_data.get("plot_type", "未知"),
        energy_curve=dna_data.get("energy_curve", 0),
        foreshadows=dna_data.get("foreshadows", [])
    )
