from fastapi import APIRouter

router = APIRouter()

@router.get("/")
async def read_characters():
    return {"message": "人物管理功能"}

@router.post("/")
async def create_character():
    return {"message": "创建人物功能"}
