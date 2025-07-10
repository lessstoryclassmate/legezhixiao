from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
from datetime import datetime
from bson import ObjectId
from app.database import characters_collection, novels_collection
from app.routes.auth import verify_token

router = APIRouter()

class CharacterCreate(BaseModel):
    novel_id: str
    name: str
    description: Optional[str] = None
    age: Optional[int] = None
    gender: Optional[str] = None
    appearance: Optional[str] = None
    personality: Optional[str] = None
    background: Optional[str] = None
    abilities: List[str] = []
    relationships: Dict[str, str] = {}

class CharacterUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    age: Optional[int] = None
    gender: Optional[str] = None
    appearance: Optional[str] = None
    personality: Optional[str] = None
    background: Optional[str] = None
    abilities: Optional[List[str]] = None
    relationships: Optional[Dict[str, str]] = None

class CharacterResponse(BaseModel):
    id: str
    novel_id: str
    name: str
    description: Optional[str]
    age: Optional[int]
    gender: Optional[str]
    appearance: Optional[str]
    personality: Optional[str]
    background: Optional[str]
    abilities: List[str]
    relationships: Dict[str, str]
    appearance_count: int
    created_at: datetime
    updated_at: datetime

# 创建人物
@router.post("/", response_model=CharacterResponse)
async def create_character(character: CharacterCreate, user_id: str = Depends(verify_token)):
    # 验证小说是否存在且属于当前用户
    novel_doc = await novels_collection.find_one({
        "_id": ObjectId(character.novel_id),
        "user_id": ObjectId(user_id)
    })
    
    if not novel_doc:
        raise HTTPException(status_code=404, detail="小说不存在")
    
    # 检查人物名称是否重复
    existing_character = await characters_collection.find_one({
        "novel_id": ObjectId(character.novel_id),
        "name": character.name
    })
    
    if existing_character:
        raise HTTPException(status_code=400, detail="人物名称已存在")
    
    character_doc = {
        "novel_id": ObjectId(character.novel_id),
        "name": character.name,
        "description": character.description,
        "age": character.age,
        "gender": character.gender,
        "appearance": character.appearance,
        "personality": character.personality,
        "background": character.background,
        "abilities": character.abilities,
        "relationships": character.relationships,
        "appearance_count": 0,
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow()
    }
    
    result = await characters_collection.insert_one(character_doc)
    character_doc["id"] = str(result.inserted_id)
    
    return CharacterResponse(**character_doc)

# 获取人物列表
@router.get("/", response_model=List[CharacterResponse])
async def get_characters(
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
    
    cursor = characters_collection.find(
        {"novel_id": ObjectId(novel_id)}
    ).sort("created_at", -1).skip(skip).limit(limit)
    
    characters = []
    async for character_doc in cursor:
        character_doc["id"] = str(character_doc.pop("_id"))
        character_doc["novel_id"] = str(character_doc["novel_id"])
        characters.append(CharacterResponse(**character_doc))
    
    return characters

# 获取单个人物
@router.get("/{character_id}", response_model=CharacterResponse)
async def get_character(character_id: str, user_id: str = Depends(verify_token)):
    character_doc = await characters_collection.find_one({"_id": ObjectId(character_id)})
    
    if not character_doc:
        raise HTTPException(status_code=404, detail="人物不存在")
    
    # 验证小说权限
    novel_doc = await novels_collection.find_one({
        "_id": character_doc["novel_id"],
        "user_id": ObjectId(user_id)
    })
    
    if not novel_doc:
        raise HTTPException(status_code=403, detail="无权访问")
    
    character_doc["id"] = str(character_doc.pop("_id"))
    character_doc["novel_id"] = str(character_doc["novel_id"])
    return CharacterResponse(**character_doc)

# 更新人物
@router.put("/{character_id}", response_model=CharacterResponse)
async def update_character(
    character_id: str,
    character: CharacterUpdate,
    user_id: str = Depends(verify_token)
):
    # 获取原人物
    character_doc = await characters_collection.find_one({"_id": ObjectId(character_id)})
    
    if not character_doc:
        raise HTTPException(status_code=404, detail="人物不存在")
    
    # 验证权限
    novel_doc = await novels_collection.find_one({
        "_id": character_doc["novel_id"],
        "user_id": ObjectId(user_id)
    })
    
    if not novel_doc:
        raise HTTPException(status_code=403, detail="无权访问")
    
    # 构建更新数据
    update_data = {}
    if character.name is not None:
        # 检查名称是否重复
        existing_character = await characters_collection.find_one({
            "novel_id": character_doc["novel_id"],
            "name": character.name,
            "_id": {"$ne": ObjectId(character_id)}
        })
        if existing_character:
            raise HTTPException(status_code=400, detail="人物名称已存在")
        update_data["name"] = character.name
    
    if character.description is not None:
        update_data["description"] = character.description
    if character.age is not None:
        update_data["age"] = character.age
    if character.gender is not None:
        update_data["gender"] = character.gender
    if character.appearance is not None:
        update_data["appearance"] = character.appearance
    if character.personality is not None:
        update_data["personality"] = character.personality
    if character.background is not None:
        update_data["background"] = character.background
    if character.abilities is not None:
        update_data["abilities"] = character.abilities
    if character.relationships is not None:
        update_data["relationships"] = character.relationships
    
    update_data["updated_at"] = datetime.utcnow()
    
    # 更新人物
    await characters_collection.update_one(
        {"_id": ObjectId(character_id)},
        {"$set": update_data}
    )
    
    # 返回更新后的人物
    updated_character = await characters_collection.find_one({"_id": ObjectId(character_id)})
    updated_character["id"] = str(updated_character.pop("_id"))
    updated_character["novel_id"] = str(updated_character["novel_id"])
    return CharacterResponse(**updated_character)

# 删除人物
@router.delete("/{character_id}")
async def delete_character(character_id: str, user_id: str = Depends(verify_token)):
    character_doc = await characters_collection.find_one({"_id": ObjectId(character_id)})
    
    if not character_doc:
        raise HTTPException(status_code=404, detail="人物不存在")
    
    # 验证权限
    novel_doc = await novels_collection.find_one({
        "_id": character_doc["novel_id"],
        "user_id": ObjectId(user_id)
    })
    
    if not novel_doc:
        raise HTTPException(status_code=403, detail="无权访问")
    
    # 删除人物
    await characters_collection.delete_one({"_id": ObjectId(character_id)})
    
    return {"message": "人物已删除"}

# 人物关系图
@router.get("/{character_id}/relationships")
async def get_character_relationships(character_id: str, user_id: str = Depends(verify_token)):
    character_doc = await characters_collection.find_one({"_id": ObjectId(character_id)})
    
    if not character_doc:
        raise HTTPException(status_code=404, detail="人物不存在")
    
    # 验证权限
    novel_doc = await novels_collection.find_one({
        "_id": character_doc["novel_id"],
        "user_id": ObjectId(user_id)
    })
    
    if not novel_doc:
        raise HTTPException(status_code=403, detail="无权访问")
    
    # 获取所有相关人物
    related_character_ids = list(character_doc.get("relationships", {}).keys())
    related_characters = []
    
    if related_character_ids:
        cursor = characters_collection.find({
            "_id": {"$in": [ObjectId(cid) for cid in related_character_ids]}
        })
        
        async for char in cursor:
            related_characters.append({
                "id": str(char["_id"]),
                "name": char["name"],
                "relationship": character_doc["relationships"].get(str(char["_id"]), "未知")
            })
    
    return {
        "character_id": character_id,
        "character_name": character_doc["name"],
        "relationships": related_characters
    }
