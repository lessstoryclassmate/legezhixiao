from fastapi import APIRouter

router = APIRouter()

@router.get("/")
async def read_worlds():
    return {"message": "世界观管理功能"}

@router.post("/")
async def create_world():
    return {"message": "创建世界观功能"}
