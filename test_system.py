#!/usr/bin/env python3
"""
测试VSCode MD编辑器系统的完整功能
"""

import requests
import json
import time
from datetime import datetime

# API基础URL
BASE_URL = "http://localhost:8000"

def test_health_check():
    """测试健康检查"""
    print("=== 测试健康检查 ===")
    try:
        response = requests.get(f"{BASE_URL}/health")
        print(f"状态码: {response.status_code}")
        print(f"响应: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")
        return response.status_code == 200
    except Exception as e:
        print(f"错误: {e}")
        return False

def test_register_user():
    """测试用户注册"""
    print("\n=== 测试用户注册 ===")
    user_data = {
        "username": f"test_user_{int(time.time())}",
        "email": f"test_{int(time.time())}@example.com",
        "password": "test123456"
    }
    
    try:
        response = requests.post(f"{BASE_URL}/auth/register", json=user_data)
        print(f"状态码: {response.status_code}")
        print(f"响应: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")
        return response.status_code in [200, 201], user_data
    except Exception as e:
        print(f"错误: {e}")
        return False, user_data

def test_login_user(user_data):
    """测试用户登录"""
    print("\n=== 测试用户登录 ===")
    login_data = {
        "username": user_data["username"],
        "password": user_data["password"]
    }
    
    try:
        response = requests.post(f"{BASE_URL}/auth/login", data=login_data)
        print(f"状态码: {response.status_code}")
        result = response.json()
        print(f"响应: {json.dumps(result, indent=2, ensure_ascii=False)}")
        
        if response.status_code == 200 and "access_token" in result:
            return True, result["access_token"]
        return False, None
    except Exception as e:
        print(f"错误: {e}")
        return False, None

def test_md_files_api(token):
    """测试MD文件API"""
    print("\n=== 测试MD文件API ===")
    headers = {"Authorization": f"Bearer {token}"}
    
    # 获取文件列表
    try:
        response = requests.get(f"{BASE_URL}/api/files", headers=headers)
        print(f"获取文件列表 - 状态码: {response.status_code}")
        print(f"响应: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")
        
        # 创建新文件
        new_file_data = {
            "name": f"test_novel_{int(time.time())}.md",
            "type": "novel",
            "content": "# 测试小说\n\n这是一个测试小说的内容。\n\n## 第一章\n\n测试章节内容...",
            "novel_id": None,
            "metadata": {
                "title": "测试小说",
                "author": "测试作者",
                "genre": "科幻",
                "description": "这是一个用于测试的小说"
            }
        }
        
        response = requests.post(f"{BASE_URL}/api/files", headers=headers, json=new_file_data)
        print(f"创建文件 - 状态码: {response.status_code}")
        if response.status_code in [200, 201]:
            result = response.json()
            print(f"响应: {json.dumps(result, indent=2, ensure_ascii=False)}")
            return True, result.get("id") or result.get("file_id")
        else:
            print(f"创建文件失败: {response.text}")
            return False, None
            
    except Exception as e:
        print(f"错误: {e}")
        return False, None

def test_frontend_access():
    """测试前端访问"""
    print("\n=== 测试前端访问 ===")
    
    # 测试主页
    try:
        response = requests.get("http://localhost:8080/")
        print(f"前端主页 - 状态码: {response.status_code}")
        
        # 测试编辑器页面
        response = requests.get("http://localhost:8080/editor")
        print(f"VSCode编辑器页面 - 状态码: {response.status_code}")
        
        return response.status_code == 200
    except Exception as e:
        print(f"错误: {e}")
        return False

def main():
    """主测试函数"""
    print("🚀 开始测试VSCode MD编辑器系统")
    print(f"测试时间: {datetime.now()}")
    
    # 1. 测试健康检查
    if not test_health_check():
        print("❌ 健康检查失败")
        return
    
    # 2. 测试前端访问
    if not test_frontend_access():
        print("❌ 前端访问失败")
        return
    
    # 3. 测试用户注册
    register_success, user_data = test_register_user()
    if not register_success:
        print("❌ 用户注册失败")
        return
    
    # 4. 测试用户登录
    login_success, token = test_login_user(user_data)
    if not login_success:
        print("❌ 用户登录失败")
        return
    
    # 5. 测试MD文件API
    api_success, file_id = test_md_files_api(token)
    if not api_success:
        print("❌ MD文件API测试失败")
        return
    
    print("\n✅ 所有测试通过！")
    print("🎉 VSCode MD编辑器系统运行正常")
    print("\n📌 访问地址:")
    print(f"  - 前端主页: http://localhost:8080/")
    print(f"  - VSCode编辑器: http://localhost:8080/editor")
    print(f"  - API文档: http://localhost:8000/docs")
    print(f"  - 健康检查: http://localhost:8000/health")

if __name__ == "__main__":
    main()
