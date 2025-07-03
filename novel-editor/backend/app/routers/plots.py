from fastapi import APIRouter

router = APIRouter()

@router.get("/")
async def read_plots():
    return {"message": "剧情管理功能"}

@router.post("/")
async def create_plot():
    return {"message": "创建剧情功能"}
