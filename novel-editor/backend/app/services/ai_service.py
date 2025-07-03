import httpx
import json
import os
from typing import Dict, Any, Optional, List
from dotenv import load_dotenv

from app.config.ai_models import (
    get_model_config, 
    get_recommended_model, 
    get_default_params,
    DEEPSEEK_V3_CONFIG,
    ALTERNATIVE_MODELS_CONFIG
)

load_dotenv()

class SiliconFlowService:
    """SiliconFlow API服务 - 使用DeepSeek-V3作为核心大语言模型"""
    
    def __init__(self):
        self.api_key = os.getenv("SILICONFLOW_API_KEY")
        self.base_url = os.getenv("SILICONFLOW_API_URL", "https://api.siliconflow.cn/v1")
        self.default_model = os.getenv("DEFAULT_AI_MODEL", "deepseek-ai/DeepSeek-V3")
        self.headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }
    
    async def chat_completion(
        self, 
        messages: list, 
        model: Optional[str] = None,
        temperature: Optional[float] = None,
        max_tokens: Optional[int] = None,
        **kwargs
    ) -> Dict[str, Any]:
        """聊天完成API调用 - 智能选择最优参数"""
        url = f"{self.base_url}/chat/completions"
        
        # 确定使用的模型
        selected_model = model or self.default_model
        
        # 获取模型的默认参数
        default_params = get_default_params(selected_model)
        
        # 构建请求参数，用户参数优先
        payload = {
            "model": selected_model,
            "messages": messages,
            "temperature": temperature or default_params.get("temperature", 0.7),
            "max_tokens": max_tokens or default_params.get("max_tokens", 2000),
            "stream": False
        }
        
        # 添加模型特定的参数
        for key, value in default_params.items():
            if key not in payload and key not in ["temperature", "max_tokens"]:
                payload[key] = value
        
        # 添加用户提供的额外参数
        payload.update(kwargs)
        
        async with httpx.AsyncClient() as client:
            try:
                response = await client.post(
                    url, 
                    headers=self.headers, 
                    json=payload,
                    timeout=30.0
                )
                response.raise_for_status()
                return response.json()
            except httpx.HTTPStatusError as e:
                raise Exception(f"API调用失败: {e.response.status_code} - {e.response.text}")
            except Exception as e:
                raise Exception(f"请求失败: {str(e)}")
    
    async def generate_novel_content(
        self, 
        prompt: str, 
        context: Optional[Dict[str, Any]] = None,
        model: Optional[str] = None
    ) -> str:
        """生成小说内容 - 使用DeepSeek-V3进行创作"""
        # 为小说生成任务选择最佳模型
        selected_model = model or self.get_recommended_model_for_task("novel_generation")
        
        system_prompt = """你是一个专业的小说创作助手，使用DeepSeek-V3的强大能力为用户创作优质小说内容。请根据用户的要求生成高质量的小说内容。
要求：
1. 文笔流畅优美，情节生动有趣
2. 人物性格鲜明立体，对话自然真实
3. 环境描写细腻入微，氛围营造恰到好处
4. 情节连贯合理，逻辑严密
5. 符合中文小说的写作习惯和审美
6. 充分发挥想象力，创造引人入胜的故事"""
        
        messages = [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": prompt}
        ]
        
        if context:
            context_str = f"上下文信息：{json.dumps(context, ensure_ascii=False, indent=2)}"
            messages.insert(1, {"role": "system", "content": context_str})
        
        # 为创作任务使用较高的温度值以增加创意
        result = await self.chat_completion(messages, model=selected_model, temperature=0.8)
        return result["choices"][0]["message"]["content"]
    
    async def analyze_chapter(
        self, 
        content: str, 
        model: Optional[str] = None
    ) -> Dict[str, Any]:
        """分析章节内容 - 使用DeepSeek-V3进行专业分析"""
        # 为分析任务选择最佳模型
        selected_model = model or self.get_recommended_model_for_task("chapter_analysis")
        
        system_prompt = """你是一个专业的文学分析师，使用DeepSeek-V3的深度理解能力分析小说章节。请分析以下章节内容，提供深入详细的分析报告。
分析维度包括：
1. 情感曲线：描述情感变化的起伏和深层次心理活动
2. 节奏分析：快慢节奏的变化及其对阅读体验的影响
3. 人物关系：涉及的人物及其关系变化、冲突与和解
4. 剧情要点：关键情节点及其对整体故事的推进作用
5. 文学技巧：使用的写作技巧、修辞手法、叙述方式
6. 主题表达：体现的主题思想和价值观
7. 改进建议：具体且可操作的改进意见
8. 创新亮点：文本中的创新元素和亮点

请以JSON格式返回详细的分析结果。"""
        
        messages = [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": f"请分析以下章节内容：\n\n{content}"}
        ]
        
        # 为分析任务使用较低的温度值以保证准确性
        result = await self.chat_completion(messages, model=selected_model, temperature=0.3)
        try:
            # 尝试解析JSON响应
            analysis = json.loads(result["choices"][0]["message"]["content"])
            return analysis
        except json.JSONDecodeError:
            # 如果不是JSON格式，返回原始文本
            return {"analysis": result["choices"][0]["message"]["content"]}
    
    async def suggest_plot_development(
        self, 
        current_plot: str, 
        characters: list,
        world_setting: Optional[str] = None,
        model: Optional[str] = None
    ) -> List[str]:
        """建议剧情发展 - 使用DeepSeek-V3生成创新剧情"""
        system_prompt = """你是一个资深的剧情策划师，使用DeepSeek-V3的创意思维能力。根据当前的剧情发展和人物设定，
提供3-5个有创意且合理的剧情发展方向。每个建议应该：
1. 符合人物性格和动机，体现角色的成长弧线
2. 推动故事向前发展，增加戏剧张力
3. 增加有意义的冲突或巧妙地解决现有冲突
4. 为后续情节留下充足的发展空间
5. 具有创新性和吸引力，能够抓住读者注意力
6. 保持故事的连贯性和逻辑性

请以数组形式返回建议，每个建议包含具体且富有想象力的情节描述。"""
        
        characters_info = "\n".join([f"- {char}" for char in characters])
        world_info = f"\n世界观设定：{world_setting}" if world_setting else ""
        
        prompt = f"""当前剧情：{current_plot}

主要人物：
{characters_info}{world_info}

请提供创新的剧情发展建议："""
        
        messages = [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": prompt}
        ]
        
        result = await self.chat_completion(messages, model=model)
        response_content = result["choices"][0]["message"]["content"]
        
        try:
            # 尝试解析为JSON数组
            suggestions = json.loads(response_content)
            if isinstance(suggestions, list):
                return suggestions
        except json.JSONDecodeError:
            pass
        
        # 如果不是JSON，按行分割返回
        lines = response_content.strip().split('\n')
        suggestions = [line.strip() for line in lines if line.strip() and not line.strip().startswith('#')]
        return suggestions[:5]  # 最多返回5个建议
    
    async def optimize_text(
        self, 
        text: str, 
        optimization_type: str = "general",
        model: Optional[str] = None
    ) -> str:
        """优化文本 - 使用DeepSeek-V3进行专业文本优化"""
        optimization_prompts = {
            "general": """请使用DeepSeek-V3的语言理解能力优化以下文本，使其更加流畅、生动、富有表现力。
                        保持原意不变，提升文学性和可读性，增强语言的感染力和美感。""",
            "dialogue": """请优化以下对话，使其更加自然、符合人物性格，增强表现力和戏剧张力。
                         注意对话的节奏感、个性化表达和情感层次。""",
            "description": """请优化以下描写，使其更加细腻、生动，增强画面感和氛围营造。
                           运用丰富的修辞手法，创造身临其境的阅读体验。""",
            "action": """请优化以下动作场面，使其更加紧凑、激烈，增强代入感和紧张感。
                        注意动作的连贯性、节奏控制和视觉冲击力。"""
        }
        
        system_prompt = optimization_prompts.get(optimization_type, optimization_prompts["general"])
        
        messages = [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": text}
        ]
        
        result = await self.chat_completion(messages, model=model)
        return result["choices"][0]["message"]["content"]
    
    async def generate_character_profile(
        self, 
        character_brief: str, 
        novel_context: Optional[str] = None,
        model: Optional[str] = None
    ) -> Dict[str, Any]:
        """生成人物档案 - 使用DeepSeek-V3创建深度人物设定"""
        system_prompt = """你是一个专业的人物设定师，使用DeepSeek-V3的深度理解能力。根据简要描述，创建详细且立体的人物档案。
人物档案应包括：
1. 基本信息：姓名、年龄、性别、身份、社会地位
2. 外貌特征：详细且具有辨识度的外貌描述，包括体态、气质
3. 性格特点：复杂且矛盾的多层次性格设定，包括表层和深层性格
4. 背景故事：丰富的成长经历、重要转折事件、创伤与成就
5. 能力设定：专业技能、天赋特长、知识领域、弱点缺陷
6. 人际关系：与重要人物的关系网络、情感纽带
7. 内心驱动：深层动机、人生目标、内心恐惧、潜在欲望
8. 成长弧线：在故事中的变化方向、发展潜力
9. 语言特色：说话习惯、口头禅、表达方式
10. 行为模式：典型行为、决策风格、应对压力的方式

请以详细的JSON格式返回立体丰满的人物档案。"""
        
        context_str = f"\n小说背景：{novel_context}" if novel_context else ""
        prompt = f"人物简述：{character_brief}{context_str}\n\n请创建详细深入的人物档案："
        
        messages = [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": prompt}
        ]
        
        result = await self.chat_completion(messages, model=model)
        try:
            profile = json.loads(result["choices"][0]["message"]["content"])
            return profile
        except json.JSONDecodeError:
            return {"profile": result["choices"][0]["message"]["content"]}

    def get_available_models(self) -> List[str]:
        """获取可用的AI模型列表"""
        models = [DEEPSEEK_V3_CONFIG["model_id"]]
        models.extend(list(ALTERNATIVE_MODELS_CONFIG.keys()))
        return models
    
    def get_model_info(self, model_name: str) -> Dict[str, Any]:
        """获取模型信息"""
        return get_model_config(model_name)
    
    def get_recommended_model_for_task(self, task_type: str) -> str:
        """根据任务类型获取推荐模型"""
        return get_recommended_model(task_type)

    async def test_model_connection(self, model_name: Optional[str] = None) -> Dict[str, Any]:
        """测试模型连接"""
        test_model = model_name or self.default_model
        test_messages = [
            {"role": "user", "content": "请回复'连接成功'来测试模型连接。"}
        ]
        
        try:
            result = await self.chat_completion(test_messages, model=test_model, max_tokens=50)
            return {
                "success": True,
                "model": test_model,
                "response": result["choices"][0]["message"]["content"],
                "usage": result.get("usage", {})
            }
        except Exception as e:
            return {
                "success": False,
                "model": test_model,
                "error": str(e)
            }

# 创建全局实例
siliconflow_service = SiliconFlowService()
