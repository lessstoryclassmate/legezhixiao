"""
AI模型配置文件
包含所有支持的AI模型的详细信息和配置
"""

# DeepSeek-V3 作为核心大语言模型的配置
DEEPSEEK_V3_CONFIG = {
    "model_id": "deepseek-ai/DeepSeek-V3", 
    "name": "DeepSeek-V3",
    "provider": "SiliconFlow",
    "description": "DeepSeek最新的大语言模型，具有强大的推理、编程和创作能力",
    "strengths": [
        "强大的逻辑推理能力",
        "优秀的代码生成和理解",
        "高质量的创意写作",
        "深度文本分析",
        "多轮对话理解",
        "中英文双语能力"
    ],
    "use_cases": [
        "小说内容生成",
        "章节分析与优化",
        "剧情发展建议",
        "人物角色设计",
        "文本润色与改写",
        "创意灵感生成"
    ],
    "max_tokens": 8192,
    "supports_thinking": True,
    "temperature_range": [0.1, 1.0],
    "recommended_temperature": {
        "creative_writing": 0.8,
        "analysis": 0.3,
        "optimization": 0.5,
        "character_design": 0.7
    },
    "pricing_tier": "premium"
}

# 备用模型配置
ALTERNATIVE_MODELS_CONFIG = {
    "Qwen/QwQ-32B": {
        "model_id": "Qwen/QwQ-32B",
        "name": "QwQ-32B", 
        "provider": "SiliconFlow",
        "description": "阿里巴巴推出的推理专用模型，擅长逻辑分析和数学推理",
        "strengths": ["数学推理", "逻辑分析", "问题解决", "思维链推理"],
        "use_cases": ["剧情逻辑检查", "情节连贯性分析", "角色动机分析"],
        "max_tokens": 4096,
        "supports_thinking": True,
        "recommended_temperature": {"analysis": 0.2, "reasoning": 0.3},
        "pricing_tier": "standard"
    },
    
    "THUDM/GLM-4-9B-0414": {
        "model_id": "THUDM/GLM-4-9B-0414",
        "name": "GLM-4-9B",
        "provider": "SiliconFlow", 
        "description": "清华智谱AI的对话模型，中文理解能力强",
        "strengths": ["中文理解", "对话生成", "文本创作", "情感分析"],
        "use_cases": ["中文文本优化", "对话场景生成", "情感表达分析"],
        "max_tokens": 2048,
        "supports_thinking": False,
        "recommended_temperature": {"dialogue": 0.7, "emotion": 0.6},
        "pricing_tier": "standard"
    },
    
    "baidu/ERNIE-4.5-300B-A47B": {
        "model_id": "baidu/ERNIE-4.5-300B-A47B",
        "name": "ERNIE-4.5",
        "provider": "SiliconFlow",
        "description": "百度文心大模型，具有丰富的中文知识储备",
        "strengths": ["中文处理", "知识问答", "内容生成", "文化理解"],
        "use_cases": ["历史文化背景生成", "专业知识咨询", "本土化内容创作"],
        "max_tokens": 4096,
        "supports_thinking": False,
        "recommended_temperature": {"knowledge": 0.4, "cultural": 0.6},
        "pricing_tier": "standard"
    }
}

# 任务类型与推荐模型的映射
TASK_MODEL_RECOMMENDATIONS = {
    "novel_generation": {
        "primary": "deepseek-ai/DeepSeek-V3",
        "alternatives": ["THUDM/GLM-4-9B-0414", "baidu/ERNIE-4.5-300B-A47B"],
        "reason": "DeepSeek-V3在创意写作和长文本生成方面表现优异"
    },
    
    "chapter_analysis": {
        "primary": "deepseek-ai/DeepSeek-V3", 
        "alternatives": ["Qwen/QwQ-32B"],
        "reason": "需要深度理解和逻辑分析能力"
    },
    
    "plot_development": {
        "primary": "deepseek-ai/DeepSeek-V3",
        "alternatives": ["Qwen/QwQ-32B", "THUDM/GLM-4-9B-0414"],
        "reason": "结合创意和逻辑推理，DeepSeek-V3最适合"
    },
    
    "text_optimization": {
        "primary": "deepseek-ai/DeepSeek-V3",
        "alternatives": ["THUDM/GLM-4-9B-0414", "baidu/ERNIE-4.5-300B-A47B"],
        "reason": "需要对文本风格和语言美感有深度理解"
    },
    
    "character_design": {
        "primary": "deepseek-ai/DeepSeek-V3",
        "alternatives": ["THUDM/GLM-4-9B-0414"],
        "reason": "人物设计需要创意和心理学理解"
    },
    
    "dialogue_generation": {
        "primary": "THUDM/GLM-4-9B-0414",
        "alternatives": ["deepseek-ai/DeepSeek-V3", "baidu/ERNIE-4.5-300B-A47B"],
        "reason": "GLM-4在对话生成方面有特殊优势"
    }
}

# API调用的默认参数配置
DEFAULT_API_PARAMS = {
    "deepseek-ai/DeepSeek-V3": {
        "temperature": 0.7,
        "max_tokens": 2000,
        "top_p": 0.9,
        "frequency_penalty": 0.1,
        "presence_penalty": 0.1
    },
    
    "Qwen/QwQ-32B": {
        "temperature": 0.3,
        "max_tokens": 1500,
        "top_p": 0.8,
        "enable_thinking": True,
        "thinking_budget": 4096
    },
    
    "THUDM/GLM-4-9B-0414": {
        "temperature": 0.7,
        "max_tokens": 1500,
        "top_p": 0.9
    },
    
    "baidu/ERNIE-4.5-300B-A47B": {
        "temperature": 0.6,
        "max_tokens": 1500,
        "top_p": 0.9
    }
}

def get_model_config(model_id: str) -> dict:
    """获取指定模型的配置信息"""
    if model_id == "deepseek-ai/DeepSeek-V3":
        return DEEPSEEK_V3_CONFIG
    elif model_id in ALTERNATIVE_MODELS_CONFIG:
        return ALTERNATIVE_MODELS_CONFIG[model_id]
    else:
        return {
            "model_id": model_id,
            "name": model_id,
            "description": "未知模型",
            "strengths": [],
            "use_cases": [],
            "max_tokens": 2048,
            "supports_thinking": False,
            "pricing_tier": "unknown"
        }

def get_recommended_model(task_type: str) -> str:
    """根据任务类型获取推荐的模型"""
    recommendation = TASK_MODEL_RECOMMENDATIONS.get(task_type)
    if recommendation:
        return recommendation["primary"]
    return "deepseek-ai/DeepSeek-V3"  # 默认使用DeepSeek-V3

def get_default_params(model_id: str) -> dict:
    """获取模型的默认API参数"""
    return DEFAULT_API_PARAMS.get(model_id, {
        "temperature": 0.7,
        "max_tokens": 2000,
        "top_p": 0.9
    })
