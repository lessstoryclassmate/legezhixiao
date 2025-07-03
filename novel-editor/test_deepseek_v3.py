#!/usr/bin/env python3
"""
测试DeepSeek-V3集成的脚本
"""

import asyncio
import sys
import os

# 添加项目路径
sys.path.append('/workspaces/legezhixiao/novel-editor/backend')

from app.services.ai_service import siliconflow_service

async def test_deepseek_v3():
    """测试DeepSeek-V3集成"""
    
    print("🧪 开始测试DeepSeek-V3集成...")
    print(f"📋 默认模型: {siliconflow_service.default_model}")
    print(f"🔑 API密钥已配置: {'是' if siliconflow_service.api_key else '否'}")
    
    # 测试1: 获取可用模型列表
    print("\n1️⃣ 测试获取可用模型列表:")
    try:
        models = siliconflow_service.get_available_models()
        for i, model in enumerate(models, 1):
            info = siliconflow_service.get_model_info(model)
            print(f"   {i}. {info['name']} ({model})")
            print(f"      描述: {info['description']}")
    except Exception as e:
        print(f"   ❌ 错误: {e}")
    
    # 测试2: 测试模型连接
    print("\n2️⃣ 测试DeepSeek-V3连接:")
    try:
        result = await siliconflow_service.test_model_connection()
        if result['success']:
            print(f"   ✅ 连接成功! 响应: {result['response']}")
            print(f"   📊 使用情况: {result.get('usage', {})}")
        else:
            print(f"   ❌ 连接失败: {result['error']}")
    except Exception as e:
        print(f"   ❌ 测试连接时出错: {e}")
    
    # 测试3: 小说内容生成
    print("\n3️⃣ 测试小说内容生成:")
    try:
        prompt = "请写一个关于古代武侠的开头段落，描述一位年轻剑客第一次踏入江湖的场景。"
        content = await siliconflow_service.generate_novel_content(prompt)
        print(f"   ✅ 生成成功!")
        print(f"   📝 内容预览: {content[:100]}...")
    except Exception as e:
        print(f"   ❌ 生成失败: {e}")
    
    # 测试4: 文本分析
    print("\n4️⃣ 测试章节分析:")
    try:
        test_text = "夕阳西下，断肠人在天涯。年轻的剑客李逍遥背着包袱，一步一步地走向前方未知的道路。"
        analysis = await siliconflow_service.analyze_chapter(test_text)
        print(f"   ✅ 分析成功!")
        print(f"   📊 分析结果: {str(analysis)[:100]}...")
    except Exception as e:
        print(f"   ❌ 分析失败: {e}")
    
    # 测试5: 剧情建议
    print("\n5️⃣ 测试剧情发展建议:")
    try:
        current_plot = "主角刚刚进入江湖，遇到了一个神秘的老人"
        characters = ["李逍遥（年轻剑客）", "神秘老人"]
        suggestions = await siliconflow_service.suggest_plot_development(
            current_plot, characters, "古代武侠世界"
        )
        print(f"   ✅ 建议生成成功!")
        for i, suggestion in enumerate(suggestions[:3], 1):
            print(f"   {i}. {suggestion[:80]}...")
    except Exception as e:
        print(f"   ❌ 建议生成失败: {e}")
    
    print("\n🎉 DeepSeek-V3集成测试完成!")

if __name__ == "__main__":
    asyncio.run(test_deepseek_v3())
