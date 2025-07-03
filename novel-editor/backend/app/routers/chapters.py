from fastapi import APIRouter

router = APIRouter()

@router.get("/")
async def read_chapters():
    return {"message": "章节管理功能"}

@router.post("/")
async def create_chapter():
    return {"message": "创建章节功能"}
