#!/usr/bin/env python3
"""
🤖 GitHub Actions 智能错误诊断和自动修复系统
自动分析部署失败日志，识别错误模式，并生成针对性修复方案
"""

import requests
import json
import re
import os
import subprocess
import sys
from datetime import datetime
from typing import Dict, List, Optional, Tuple

class GitHubActionsAnalyzer:
    def __init__(self, token: str, repo_owner: str, repo_name: str):
        """初始化GitHub Actions分析器"""
        self.token = token
        self.repo_owner = repo_owner
        self.repo_name = repo_name
        self.base_url = f"https://api.github.com/repos/{repo_owner}/{repo_name}"
        self.headers = {
            "Authorization": f"token {token}",
            "Accept": "application/vnd.github.v3+json"
        }
        
        # 错误模式定义
        self.error_patterns = {
            'docker_syntax': [
                r'FROM.*error',
                r'as.*error',
                r'dockerfile.*syntax.*error',
                r'unknown instruction',
                r'invalid.*from.*line'
            ],
            'docker_build': [
                r'build.*failed',
                r'docker.*build.*error',
                r'failed to build',
                r'error building image'
            ],
            'network_timeout': [
                r'timeout.*exceeded',
                r'network.*timeout',
                r'connection.*timed.*out',
                r'read.*timeout',
                r'dial.*timeout'
            ],
            'ssh_connection': [
                r'ssh.*connection.*failed',
                r'permission.*denied.*publickey',
                r'connection.*refused',
                r'host.*unreachable',
                r'ssh.*error'
            ],
            'dependency_install': [
                r'npm.*install.*failed',
                r'yarn.*install.*error',
                r'pip.*install.*error',
                r'package.*not.*found',
                r'dependency.*resolution.*failed'
            ],
            'environment_vars': [
                r'secret.*not.*found',
                r'environment.*variable.*not.*set',
                r'missing.*required.*environment',
                r'undefined.*variable'
            ],
            'port_conflict': [
                r'port.*already.*in.*use',
                r'address.*already.*in.*use',
                r'bind.*address.*already.*in.*use'
            ],
            'disk_space': [
                r'no.*space.*left',
                r'disk.*full',
                r'not.*enough.*space'
            ]
        }

    def get_latest_failed_runs(self, limit: int = 5) -> List[Dict]:
        """获取最新的失败运行记录"""
        print("🔍 获取最新的失败部署记录...")
        
        url = f"{self.base_url}/actions/runs"
        params = {
            'status': 'completed',
            'conclusion': 'failure',
            'per_page': limit
        }
        
        try:
            response = requests.get(url, headers=self.headers, params=params)
            response.raise_for_status()
            
            runs = response.json().get('workflow_runs', [])
            print(f"📋 找到 {len(runs)} 个失败的运行记录")
            
            return runs
            
        except requests.RequestException as e:
            print(f"❌ 获取运行记录失败: {e}")
            return []

    def get_run_logs(self, run_id: int) -> str:
        """获取指定运行的所有日志"""
        print(f"📊 获取运行 {run_id} 的详细日志...")
        
        # 获取jobs
        jobs_url = f"{self.base_url}/actions/runs/{run_id}/jobs"
        
        try:
            response = requests.get(jobs_url, headers=self.headers)
            response.raise_for_status()
            
            jobs = response.json().get('jobs', [])
            all_logs = []
            
            for job in jobs:
                if job['conclusion'] == 'failure':
                    job_id = job['id']
                    logs_url = f"{self.base_url}/actions/jobs/{job_id}/logs"
                    
                    try:
                        log_response = requests.get(logs_url, headers=self.headers)
                        if log_response.status_code == 200:
                            all_logs.append(f"=== Job: {job['name']} ===\n")
                            all_logs.append(log_response.text)
                            all_logs.append("\n" + "="*50 + "\n")
                    except requests.RequestException as e:
                        print(f"⚠️ 获取job {job_id} 日志失败: {e}")
            
            return "\n".join(all_logs)
            
        except requests.RequestException as e:
            print(f"❌ 获取jobs失败: {e}")
            return ""

    def analyze_error_patterns(self, logs: str) -> Dict[str, List[str]]:
        """分析日志中的错误模式"""
        print("🔍 分析错误模式...")
        
        detected_errors = {}
        
        for error_type, patterns in self.error_patterns.items():
            matches = []
            for pattern in patterns:
                found = re.findall(pattern, logs, re.IGNORECASE | re.MULTILINE)
                if found:
                    matches.extend(found)
            
            if matches:
                detected_errors[error_type] = matches
                print(f"🚨 检测到 {error_type} 错误: {len(matches)} 个匹配")
        
        return detected_errors

    def generate_fix_strategies(self, detected_errors: Dict[str, List[str]]) -> Dict[str, Dict]:
        """根据检测到的错误生成修复策略"""
        print("🛠️ 生成修复策略...")
        
        strategies = {}
        
        for error_type in detected_errors.keys():
            if error_type == 'docker_syntax':
                strategies[error_type] = {
                    'priority': 'high',
                    'description': 'Docker语法错误',
                    'fixes': [
                        '修正Dockerfile中的FROM语句大小写',
                        '确保使用正确的多阶段构建语法',
                        '检查COPY --from引用的stage名称'
                    ],
                    'script': self._generate_docker_syntax_fix()
                }
            
            elif error_type == 'docker_build':
                strategies[error_type] = {
                    'priority': 'high',
                    'description': 'Docker构建失败',
                    'fixes': [
                        '清理Docker缓存和旧镜像',
                        '检查Dockerfile路径和上下文',
                        '验证依赖文件是否存在'
                    ],
                    'script': self._generate_docker_build_fix()
                }
            
            elif error_type == 'network_timeout':
                strategies[error_type] = {
                    'priority': 'medium',
                    'description': '网络超时问题',
                    'fixes': [
                        '配置国内镜像源加速',
                        '增加网络超时时间',
                        '使用CDN加速下载'
                    ],
                    'script': self._generate_network_fix()
                }
            
            elif error_type == 'ssh_connection':
                strategies[error_type] = {
                    'priority': 'high',
                    'description': 'SSH连接问题',
                    'fixes': [
                        '检查SSH密钥格式和权限',
                        '验证服务器IP和用户名',
                        '确保SSH服务正常运行'
                    ],
                    'script': self._generate_ssh_fix()
                }
            
            elif error_type == 'dependency_install':
                strategies[error_type] = {
                    'priority': 'medium',
                    'description': '依赖安装失败',
                    'fixes': [
                        '使用国内包管理器镜像源',
                        '清理并重新安装依赖',
                        '锁定依赖版本'
                    ],
                    'script': self._generate_dependency_fix()
                }
            
            elif error_type == 'environment_vars':
                strategies[error_type] = {
                    'priority': 'high',
                    'description': '环境变量配置问题',
                    'fixes': [
                        '检查GitHub Secrets配置',
                        '验证环境变量名称拼写',
                        '确保所有必需变量已设置'
                    ],
                    'script': self._generate_env_check()
                }
            
            elif error_type == 'port_conflict':
                strategies[error_type] = {
                    'priority': 'medium',
                    'description': '端口冲突问题',
                    'fixes': [
                        '停止占用端口的服务',
                        '清理Docker容器',
                        '修改端口映射配置'
                    ],
                    'script': self._generate_port_fix()
                }
        
        return strategies

    def _generate_docker_syntax_fix(self) -> str:
        """生成Docker语法修复脚本"""
        return '''#!/bin/bash
# Docker语法错误自动修复
echo "🔧 修复Docker语法错误..."

# 修正FROM语句大小写
find . -name "Dockerfile*" -exec sed -i 's/FROM \\(.*\\) AS \\(.*\\)/FROM \\1 as \\2/g' {} \\;

# 修正COPY --from语句
find . -name "Dockerfile*" -exec sed -i 's/--from=\\([A-Z]\\)/--from=\\L\\1/g' {} \\;

echo "✅ Docker语法修复完成"
'''

    def _generate_docker_build_fix(self) -> str:
        """生成Docker构建修复脚本"""
        return '''#!/bin/bash
# Docker构建错误修复
echo "🔧 修复Docker构建问题..."

# 清理Docker系统
docker system prune -af
docker builder prune -af

# 重新构建
docker-compose build --no-cache

echo "✅ Docker构建修复完成"
'''

    def _generate_network_fix(self) -> str:
        """生成网络问题修复脚本"""
        return '''#!/bin/bash
# 网络问题修复
echo "🌐 配置网络加速..."

# 配置Docker镜像源
sudo mkdir -p /etc/docker
cat > /tmp/daemon.json << 'EOF'
{
  "registry-mirrors": [
    "https://mirror.ccs.tencentyun.com",
    "https://docker.mirrors.ustc.edu.cn"
  ]
}
EOF
sudo mv /tmp/daemon.json /etc/docker/daemon.json
sudo systemctl restart docker

# 配置npm镜像源
npm config set registry https://registry.npmmirror.com
npm config set timeout 300000

# 配置pip镜像源
pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple

echo "✅ 网络配置完成"
'''

    def _generate_ssh_fix(self) -> str:
        """生成SSH修复检查脚本"""
        return '''#!/bin/bash
# SSH连接问题检查
echo "🔐 SSH连接诊断..."

echo "📋 请检查以下配置:"
echo "1. SERVER_SSH_KEY - SSH私钥内容"
echo "2. SERVER_IP - 服务器IP地址"
echo "3. SERVER_USER - SSH用户名"

echo "🧪 测试SSH连接:"
echo "ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no user@server"

echo "✅ SSH检查完成"
'''

    def _generate_dependency_fix(self) -> str:
        """生成依赖修复脚本"""
        return '''#!/bin/bash
# 依赖安装问题修复
echo "📦 修复依赖安装..."

# 清理缓存
npm cache clean --force
yarn cache clean

# 重新安装
npm install --registry=https://registry.npmmirror.com
pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple

echo "✅ 依赖修复完成"
'''

    def _generate_env_check(self) -> str:
        """生成环境变量检查脚本"""
        return '''#!/bin/bash
# 环境变量检查
echo "🌍 环境变量配置检查..."

echo "必需的GitHub Secrets:"
echo "- SERVER_SSH_KEY"
echo "- SERVER_IP"
echo "- SERVER_USER"
echo "- DATABASE_*"
echo "- SILICONFLOW_API_KEY"
echo "- JWT_SECRET_KEY"

echo "✅ 请在GitHub仓库设置中验证这些配置"
'''

    def _generate_port_fix(self) -> str:
        """生成端口问题修复脚本"""
        return '''#!/bin/bash
# 端口冲突修复
echo "🔌 修复端口冲突..."

# 停止现有服务
docker-compose down
docker container prune -f

# 释放端口
sudo fuser -k 80/tcp
sudo fuser -k 8000/tcp

echo "✅ 端口修复完成"
'''

    def create_fix_scripts(self, strategies: Dict[str, Dict]) -> None:
        """创建修复脚本文件"""
        print("📁 生成修复脚本文件...")
        
        for error_type, strategy in strategies.items():
            script_name = f"fix-{error_type.replace('_', '-')}.sh"
            
            with open(script_name, 'w') as f:
                f.write(strategy['script'])
            
            # 添加执行权限
            os.chmod(script_name, 0o755)
            print(f"✅ 创建修复脚本: {script_name}")

    def generate_report(self, run_info: Dict, detected_errors: Dict, strategies: Dict) -> str:
        """生成详细的分析报告"""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        report = f"""# 🤖 GitHub Actions 自动错误分析报告

**生成时间**: {timestamp}
**运行ID**: {run_info.get('id', 'N/A')}
**工作流**: {run_info.get('name', 'N/A')}
**提交**: {run_info.get('head_commit', {}).get('message', 'N/A')[:50]}...

## 🚨 检测到的错误

"""
        
        for error_type, matches in detected_errors.items():
            count = len(matches)
            description = strategies.get(error_type, {}).get('description', error_type)
            priority = strategies.get(error_type, {}).get('priority', 'unknown')
            
            report += f"### {description}\n"
            report += f"- **类型**: {error_type}\n"
            report += f"- **优先级**: {priority}\n"
            report += f"- **匹配数**: {count}\n\n"

        report += "## 🛠️ 修复策略\n\n"
        
        for error_type, strategy in strategies.items():
            report += f"### {strategy['description']}\n"
            report += f"**优先级**: {strategy['priority']}\n\n"
            report += "**修复步骤**:\n"
            for fix in strategy['fixes']:
                report += f"- {fix}\n"
            report += f"\n**修复脚本**: `fix-{error_type.replace('_', '-')}.sh`\n\n"

        report += """## 🚀 快速修复

```bash
# 运行所有修复脚本
for script in fix-*.sh; do
    echo "🔧 运行 $script..."
    ./"$script"
done

# 重新部署
git add .
git commit -m "🔧 自动修复部署问题"
git push
```

## 📞 需要手动处理

- GitHub Secrets配置
- 服务器SSH访问权限
- 网络防火墙设置
- DNS配置

---
*此报告由AI自动生成，基于GitHub Actions日志分析*
"""
        
        return report

    def run_analysis(self) -> None:
        """运行完整的错误分析流程"""
        print("🤖 开始GitHub Actions智能错误分析...")
        
        # 获取失败的运行记录
        failed_runs = self.get_latest_failed_runs(limit=1)
        
        if not failed_runs:
            print("🎉 没有找到失败的部署记录！")
            return
        
        latest_run = failed_runs[0]
        print(f"📋 分析运行: {latest_run['name']} (ID: {latest_run['id']})")
        
        # 获取日志
        logs = self.get_run_logs(latest_run['id'])
        
        if not logs:
            print("❌ 无法获取运行日志")
            return
        
        # 分析错误模式
        detected_errors = self.analyze_error_patterns(logs)
        
        if not detected_errors:
            print("🤔 未检测到已知的错误模式")
            return
        
        # 生成修复策略
        strategies = self.generate_fix_strategies(detected_errors)
        
        # 创建修复脚本
        self.create_fix_scripts(strategies)
        
        # 生成报告
        report = self.generate_report(latest_run, detected_errors, strategies)
        
        with open('deployment-analysis-report.md', 'w') as f:
            f.write(report)
        
        print("📊 分析完成！")
        print("📁 查看报告: deployment-analysis-report.md")
        print("🔧 运行修复脚本: ./fix-*.sh")

def main():
    """主函数"""
    # 从环境变量获取GitHub token
    token = os.getenv('GITHUB_TOKEN')
    if not token:
        print("❌ 请设置GITHUB_TOKEN环境变量")
        print("💡 获取token: https://github.com/settings/tokens")
        sys.exit(1)
    
    # 配置仓库信息（可以从环境变量获取）
    repo_owner = os.getenv('GITHUB_REPOSITORY_OWNER', 'your-username')
    repo_name = os.getenv('GITHUB_REPOSITORY', 'legezhixiao').split('/')[-1]
    
    # 创建分析器并运行
    analyzer = GitHubActionsAnalyzer(token, repo_owner, repo_name)
    analyzer.run_analysis()

if __name__ == "__main__":
    main()
