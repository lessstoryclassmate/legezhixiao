from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.schemas.schemas import AIRequest, AIResponse
from app.models.user import User as UserModel
from app.routers.auth import get_current_user
from app.services.ai_service import siliconflow_service

router = APIRouter()

@router.post("/generate", response_model=AIResponse)
async def generate_content(
    request: AIRequest,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    """AI内容生成"""
    try:
        result = await siliconflow_service.generate_novel_content(
            prompt=request.content,
            context=request.context,
            model=request.model
        )
        return AIResponse(result=result, response_metadata={"task_type": request.task_type})
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"AI生成失败: {str(e)}")

@router.post("/analyze", response_model=AIResponse)
async def analyze_content(
    request: AIRequest,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    """AI内容分析"""
    try:
        result = await siliconflow_service.analyze_chapter(
            content=request.content,
            model=request.model
        )
        return AIResponse(result=str(result), response_metadata={"task_type": request.task_type})
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"AI分析失败: {str(e)}")

@router.post("/suggest")
async def suggest_plot(
    request: AIRequest,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    """AI剧情建议"""
    try:
        context = request.context or {}
        characters = context.get("characters", [])
        world_setting = context.get("world_setting")
        
        suggestions = await siliconflow_service.suggest_plot_development(
            current_plot=request.content,
            characters=characters,
            world_setting=world_setting,
            model=request.model
        )
        return {"suggestions": suggestions}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"AI建议失败: {str(e)}")

@router.post("/optimize", response_model=AIResponse)
async def optimize_text(
    request: AIRequest,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    """AI文本优化"""
    try:
        optimization_type = request.context.get("type", "general") if request.context else "general"
        result = await siliconflow_service.optimize_text(
            text=request.content,
            optimization_type=optimization_type,
            model=request.model
        )
        return AIResponse(result=result, response_metadata={"task_type": request.task_type})
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"AI优化失败: {str(e)}")

@router.get("/models")
async def get_available_models(
    current_user: UserModel = Depends(get_current_user)
):
    """获取可用的AI模型列表"""
    try:
        models = siliconflow_service.get_available_models()
        model_details = []
        for model in models:
            info = siliconflow_service.get_model_info(model)
            model_details.append({
                "id": model,
                "name": info["name"],
                "description": info["description"],
                "strengths": info["strengths"],
                "max_tokens": info["max_tokens"],
                "supports_thinking": info["supports_thinking"],
                "is_default": model == siliconflow_service.default_model
            })
        return {"models": model_details}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"获取模型列表失败: {str(e)}")

@router.post("/models/test")
async def test_model(
    request: dict,
    current_user: UserModel = Depends(get_current_user)
):
    """测试指定模型的连接"""
    try:
        model_name = request.get("model")
        result = await siliconflow_service.test_model_connection(model_name)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"模型测试失败: {str(e)}")

@router.post("/character-profile", response_model=AIResponse)
async def generate_character_profile(
    request: AIRequest,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    """AI生成人物档案"""
    try:
        novel_context = request.context.get("novel_context") if request.context else None
        result = await siliconflow_service.generate_character_profile(
            character_brief=request.content,
            novel_context=novel_context,
            model=request.model
        )
        return AIResponse(result=str(result), response_metadata={"task_type": "character_profile"})
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"AI人物档案生成失败: {str(e)}")
