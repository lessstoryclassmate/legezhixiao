from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
import httpx
from datetime import datetime
from bson import ObjectId
from app.database import ai_conversations_collection, novels_collection, chapters_collection
from app.routes.auth import verify_token
from app.core.config import settings

router = APIRouter()

class AIRequest(BaseModel):
    novel_id: str
    chapter_id: Optional[str] = None
    prompt: str
    task_type: str  # 'create', 'edit', 'analyze', 'suggest'
    context: Optional[Dict[str, Any]] = None

class AIResponse(BaseModel):
    id: str
    content: str
    task_type: str
    created_at: datetime

class SiliconFlowService:
    def __init__(self):
        self.api_key = settings.SILICONFLOW_API_KEY
        self.api_url = settings.SILICONFLOW_API_URL
        self.model = settings.SILICONFLOW_MODEL
        
    async def chat_completion(self, messages: List[Dict[str, str]], max_tokens: int = 2000) -> str:
        """调用SiliconFlow API进行对话"""
        if not self.api_key:
            raise HTTPException(status_code=500, detail="SiliconFlow API密钥未配置")
        
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }
        
        data = {
            "model": self.model,
            "messages": messages,
            "max_tokens": max_tokens,
            "temperature": 0.7,
            "stream": False
        }
        
        async with httpx.AsyncClient() as client:
            try:
                response = await client.post(
                    f"{self.api_url}/chat/completions",
                    headers=headers,
                    json=data,
                    timeout=60.0
                )
                response.raise_for_status()
                
                result = response.json()
                if "choices" in result and len(result["choices"]) > 0:
                    return result["choices"][0]["message"]["content"]
                else:
                    raise HTTPException(status_code=500, detail="AI响应格式错误")
                    
            except httpx.RequestError as e:
                raise HTTPException(status_code=500, detail=f"API请求失败: {str(e)}")
            except httpx.HTTPStatusError as e:
                raise HTTPException(status_code=500, detail=f"API调用失败: {e.response.status_code}")

siliconflow_service = SiliconFlowService()

# 构建AI提示词
def build_ai_prompt(task_type: str, prompt: str, context: Dict[str, Any] = None) -> List[Dict[str, str]]:
    """根据任务类型构建AI提示词"""
    
    system_prompts = {
        "create": """你是一个专业的小说创作助手，擅长根据用户需求创作高质量的小说内容。
请根据用户的要求创作内容，注意：
1. 保持故事的逻辑性和连贯性
2. 人物性格要鲜明一致
3. 情节发展要合理
4. 语言风格要优美流畅
5. 注意伏笔的埋设和回收""",
        
        "edit": """你是一个专业的小说编辑助手，擅长改进和优化小说内容。
请根据用户的要求编辑内容，注意：
1. 保持原有故事主线
2. 优化语言表达
3. 增强情节张力
4. 完善人物刻画
5. 修正逻辑错误""",
        
        "analyze": """你是一个专业的小说分析师，擅长深度分析小说内容。
请从以下角度分析内容：
1. 剧情结构分析
2. 人物关系分析
3. 主题思想分析
4. 写作技巧分析
5. 改进建议""",
        
        "suggest": """你是一个专业的小说创作顾问，擅长提供创作建议。
请根据现有内容提供建议：
1. 剧情发展建议
2. 人物发展建议
3. 冲突设置建议
4. 伏笔布局建议
5. 风格改进建议"""
    }
    
    system_prompt = system_prompts.get(task_type, system_prompts["suggest"])
    
    messages = [
        {"role": "system", "content": system_prompt}
    ]
    
    # 添加上下文信息
    if context:
        context_info = "相关信息：\n"
        if "novel_title" in context:
            context_info += f"小说标题：{context['novel_title']}\n"
        if "novel_description" in context:
            context_info += f"小说简介：{context['novel_description']}\n"
        if "chapter_title" in context:
            context_info += f"章节标题：{context['chapter_title']}\n"
        if "chapter_content" in context:
            context_info += f"章节内容：{context['chapter_content'][:1000]}...\n"
        if "characters" in context:
            context_info += f"主要人物：{', '.join(context['characters'])}\n"
        
        messages.append({"role": "user", "content": context_info})
    
    # 添加用户请求
    messages.append({"role": "user", "content": prompt})
    
    return messages

# AI助手对话
@router.post("/chat", response_model=AIResponse)
async def ai_chat(request: AIRequest, user_id: str = Depends(verify_token)):
    # 验证小说权限
    novel_doc = await novels_collection.find_one({
        "_id": ObjectId(request.novel_id),
        "user_id": ObjectId(user_id)
    })
    
    if not novel_doc:
        raise HTTPException(status_code=404, detail="小说不存在")
    
    # 构建上下文
    context = {
        "novel_title": novel_doc.get("title", ""),
        "novel_description": novel_doc.get("description", ""),
    }
    
    # 如果指定了章节，获取章节信息
    if request.chapter_id:
        chapter_doc = await chapters_collection.find_one({"_id": ObjectId(request.chapter_id)})
        if chapter_doc:
            context["chapter_title"] = chapter_doc.get("title", "")
            context["chapter_content"] = chapter_doc.get("content", "")
    
    # 合并用户提供的上下文
    if request.context:
        context.update(request.context)
    
    # 构建AI提示词
    messages = build_ai_prompt(request.task_type, request.prompt, context)
    
    # 调用AI服务
    ai_response = await siliconflow_service.chat_completion(messages)
    
    # 保存对话记录
    conversation_doc = {
        "user_id": ObjectId(user_id),
        "novel_id": ObjectId(request.novel_id),
        "chapter_id": ObjectId(request.chapter_id) if request.chapter_id else None,
        "prompt": request.prompt,
        "response": ai_response,
        "task_type": request.task_type,
        "context": context,
        "created_at": datetime.utcnow()
    }
    
    result = await ai_conversations_collection.insert_one(conversation_doc)
    
    return AIResponse(
        id=str(result.inserted_id),
        content=ai_response,
        task_type=request.task_type,
        created_at=conversation_doc["created_at"]
    )

# 获取AI对话历史
@router.get("/conversations", response_model=List[Dict[str, Any]])
async def get_ai_conversations(
    novel_id: str,
    chapter_id: Optional[str] = None,
    limit: int = 20,
    user_id: str = Depends(verify_token)
):
    # 验证权限
    novel_doc = await novels_collection.find_one({
        "_id": ObjectId(novel_id),
        "user_id": ObjectId(user_id)
    })
    
    if not novel_doc:
        raise HTTPException(status_code=404, detail="小说不存在")
    
    # 构建查询条件
    query = {
        "user_id": ObjectId(user_id),
        "novel_id": ObjectId(novel_id)
    }
    
    if chapter_id:
        query["chapter_id"] = ObjectId(chapter_id)
    
    # 获取对话记录
    cursor = ai_conversations_collection.find(query).sort("created_at", -1).limit(limit)
    
    conversations = []
    async for conv in cursor:
        conversations.append({
            "id": str(conv["_id"]),
            "prompt": conv["prompt"],
            "response": conv["response"],
            "task_type": conv["task_type"],
            "created_at": conv["created_at"]
        })
    
    return conversations

# 智能建议
@router.post("/suggestions")
async def get_ai_suggestions(
    novel_id: str,
    chapter_id: Optional[str] = None,
    suggestion_type: str = "plot",  # plot, character, style, foreshadow
    user_id: str = Depends(verify_token)
):
    # 验证权限
    novel_doc = await novels_collection.find_one({
        "_id": ObjectId(novel_id),
        "user_id": ObjectId(user_id)
    })
    
    if not novel_doc:
        raise HTTPException(status_code=404, detail="小说不存在")
    
    # 根据建议类型构建提示词
    suggestion_prompts = {
        "plot": "请基于当前小说内容，提供3-5个具体的剧情发展建议，包括可能的冲突、转折和高潮设置。",
        "character": "请分析当前小说的人物设定，提供人物发展和关系处理的建议。",
        "style": "请分析当前小说的写作风格，提供语言表达和叙述技巧的改进建议。",
        "foreshadow": "请基于当前剧情，建议如何设置和回收伏笔，增强故事的深度和吸引力。"
    }
    
    prompt = suggestion_prompts.get(suggestion_type, suggestion_prompts["plot"])
    
    # 构建请求
    request = AIRequest(
        novel_id=novel_id,
        chapter_id=chapter_id,
        prompt=prompt,
        task_type="suggest"
    )
    
    # 调用AI对话接口
    return await ai_chat(request, user_id)

# 内容分析
@router.post("/analyze")
async def analyze_content(
    novel_id: str,
    chapter_id: Optional[str] = None,
    analysis_type: str = "comprehensive",  # comprehensive, structure, character, theme
    user_id: str = Depends(verify_token)
):
    # 验证权限
    novel_doc = await novels_collection.find_one({
        "_id": ObjectId(novel_id),
        "user_id": ObjectId(user_id)
    })
    
    if not novel_doc:
        raise HTTPException(status_code=404, detail="小说不存在")
    
    # 根据分析类型构建提示词
    analysis_prompts = {
        "comprehensive": "请对当前内容进行全面分析，包括剧情结构、人物刻画、主题表达、写作技巧等方面。",
        "structure": "请分析当前内容的结构，包括开头、发展、高潮、结尾的安排，以及节奏控制。",
        "character": "请深入分析人物刻画，包括性格塑造、对话设计、行为动机等。",
        "theme": "请分析当前内容的主题表达，包括思想深度、价值观念、情感传达等。"
    }
    
    prompt = analysis_prompts.get(analysis_type, analysis_prompts["comprehensive"])
    
    # 构建请求
    request = AIRequest(
        novel_id=novel_id,
        chapter_id=chapter_id,
        prompt=prompt,
        task_type="analyze"
    )
    
    # 调用AI对话接口
    return await ai_chat(request, user_id)
