#!/usr/bin/env python3
"""
环境变量一致性检查脚本
检查项目中所有环境变量名称是否一致
"""

import os
import re
import json
from pathlib import Path

def extract_env_vars_from_file(file_path, file_type):
    """从文件中提取环境变量"""
    if not os.path.exists(file_path):
        return []
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    env_vars = []
    
    if file_type == 'env':
        # .env 文件格式: VAR_NAME=value
        pattern = r'^([A-Z_][A-Z0-9_]*)\s*='
        matches = re.findall(pattern, content, re.MULTILINE)
        env_vars = matches
    
    elif file_type == 'docker-compose':
        # docker-compose.yml 格式: ${VAR_NAME}
        pattern = r'\$\{([A-Z_][A-Z0-9_]*)\}'
        matches = re.findall(pattern, content)
        env_vars = matches
    
    elif file_type == 'python':
        # Python 配置文件格式: VAR_NAME: str = "value"
        pattern = r'([A-Z_][A-Z0-9_]*)\s*:\s*(?:str|int|float|bool)'
        matches = re.findall(pattern, content)
        env_vars = matches
    
    elif file_type == 'github-actions':
        # GitHub Actions 格式: ${{ secrets.VAR_NAME }}
        pattern = r'\$\{\{\s*secrets\.([A-Z_][A-Z0-9_]*)\s*\}\}'
        matches = re.findall(pattern, content)
        env_vars = matches
    
    return list(set(env_vars))  # 去重

def main():
    """主函数"""
    project_root = Path(__file__).parent
    
    # 要检查的文件
    files_to_check = [
        ('.env.example', 'env'),
        ('docker-compose.yml', 'docker-compose'),
        ('backend/app/core/config.py', 'python'),
        ('.github/workflows/deploy.yml', 'github-actions'),
    ]
    
    all_env_vars = {}
    
    print("🔍 开始检查环境变量一致性...")
    print("=" * 60)
    
    for file_path, file_type in files_to_check:
        full_path = project_root / file_path
        env_vars = extract_env_vars_from_file(full_path, file_type)
        all_env_vars[file_path] = env_vars
        
        print(f"\n📁 {file_path}:")
        for var in sorted(env_vars):
            print(f"  - {var}")
    
    print("\n" + "=" * 60)
    print("📊 环境变量使用统计:")
    
    # 统计每个环境变量在哪些文件中出现
    var_files = {}
    for file_path, env_vars in all_env_vars.items():
        for var in env_vars:
            if var not in var_files:
                var_files[var] = []
            var_files[var].append(file_path)
    
    # 按环境变量分组显示
    for var in sorted(var_files.keys()):
        files = var_files[var]
        print(f"\n🔧 {var}:")
        for file_path in files:
            print(f"  ✓ {file_path}")
        
        # 检查是否在所有相关文件中都存在
        if len(files) == 1:
            print(f"  ⚠️  警告: 仅在 {files[0]} 中定义")
    
    # 检查缺失的环境变量
    print("\n" + "=" * 60)
    print("🔍 检查缺失的环境变量:")
    
    env_vars_set = set(all_env_vars['.env.example'])
    docker_vars_set = set(all_env_vars['docker-compose.yml'])
    python_vars_set = set(all_env_vars['backend/app/core/config.py'])
    github_vars_set = set(all_env_vars['.github/workflows/deploy.yml'])
    
    # 检查 docker-compose.yml 中使用但 .env.example 中未定义的变量
    missing_in_env = docker_vars_set - env_vars_set
    if missing_in_env:
        print(f"\n❌ docker-compose.yml 中使用但 .env.example 中未定义的变量:")
        for var in sorted(missing_in_env):
            print(f"  - {var}")
    
    # 检查 Python 配置中定义但 .env.example 中未定义的变量
    missing_in_env_from_python = python_vars_set - env_vars_set
    if missing_in_env_from_python:
        print(f"\n❌ Python 配置中定义但 .env.example 中未定义的变量:")
        for var in sorted(missing_in_env_from_python):
            print(f"  - {var}")
    
    # 检查 GitHub Actions 中使用但 .env.example 中未定义的变量
    missing_in_env_from_github = github_vars_set - env_vars_set
    if missing_in_env_from_github:
        print(f"\n❌ GitHub Actions 中使用但 .env.example 中未定义的变量:")
        for var in sorted(missing_in_env_from_github):
            print(f"  - {var}")
    
    print("\n" + "=" * 60)
    print("✅ 环境变量一致性检查完成!")
    
    # 生成报告
    report = {
        'files_checked': files_to_check,
        'env_vars_by_file': all_env_vars,
        'var_usage': var_files,
        'missing_in_env': list(missing_in_env),
        'missing_in_env_from_python': list(missing_in_env_from_python),
        'missing_in_env_from_github': list(missing_in_env_from_github),
    }
    
    with open(project_root / 'env_consistency_report.json', 'w', encoding='utf-8') as f:
        json.dump(report, f, indent=2, ensure_ascii=False)
    
    print(f"📄 详细报告已保存到: env_consistency_report.json")

if __name__ == "__main__":
    main()
