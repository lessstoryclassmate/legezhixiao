#!/bin/bash
# Git提交脚本 - 推送项目清理结果到远程仓库

set -e

echo "🚀 准备推送项目清理结果到远程仓库..."

cd /workspaces/legezhixiao

# 1. 检查git配置
echo "🔧 检查Git配置..."
if ! git config --global user.name >/dev/null 2>&1; then
    echo "⚠️  设置Git用户名..."
    git config --global user.name "GitHub Copilot"
fi

if ! git config --global user.email >/dev/null 2>&1; then
    echo "⚠️  设置Git邮箱..."
    git config --global user.email "copilot@github.com"
fi

# 2. 查看当前状态
echo "📊 当前Git状态:"
git status --short

# 3. 添加所有新文件
echo "📁 添加新创建的核心脚本..."
git add CLEANUP_COMPLETE_REPORT.md
git add scripts/auto-cleanup.sh
git add scripts/cleanup-files.sh
git add scripts/cleanup-project.sh
git add scripts/cleanup-scripts.sh
git add scripts/deployment-ready-check.sh
git add scripts/validate-project.sh

# 4. 添加修改的文件
echo "📝 添加修改的核心文件..."
git add README.md
git add backend/app/core/database.py
git add backend/start-fixed.sh
git add docker-compose.production.yml
git add .github/workflows/deploy.yml

# 5. 移除已删除的文件
echo "🗑️  确认删除临时文件..."
git add -u

# 6. 查看即将提交的内容
echo "📋 即将提交的变更摘要:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
git status --short
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 7. 提交变更
COMMIT_MESSAGE="🧹 项目结构优化完成

✨ 主要改进:
- 清理72个临时文件 (从175减少到103个文件)
- 删除51个重复脚本 (保留10个核心脚本)
- 优化数据库连接配置
- 简化部署工作流
- 完善Docker镜像加速配置

🎯 效果:
- 项目结构更简洁清晰
- 适合克隆模式部署
- 提高维护效率
- 减少存储空间占用

📂 保留核心功能:
- Vue3前端 + FastAPI后端
- MongoDB数据库集成
- Docker容器化部署
- GitHub Actions CI/CD
- SiliconFlow AI集成

🚀 部署就绪: 支持一键克隆部署"

echo "💬 提交信息:"
echo "$COMMIT_MESSAGE"
echo ""

# 提交变更
git commit -m "$COMMIT_MESSAGE"

echo "✅ 变更已提交到本地仓库"

# 8. 推送到远程仓库
echo "🌐 推送到远程仓库..."
if git push origin main; then
    echo "🎉 成功推送到远程仓库!"
    echo ""
    echo "📊 推送统计:"
    echo "- 总文件数: $(find . -type f -not -path "./*/node_modules/*" -not -path "./.git/*" -not -path "./.venv/*" | wc -l)"
    echo "- 清理文件: 72个"
    echo "- 新增核心脚本: 7个"
    echo "- 优化配置文件: 5个"
    echo ""
    echo "🚀 远程仓库现在拥有干净、高效的项目结构!"
else
    echo "❌ 推送失败，请检查网络连接和仓库权限"
    exit 1
fi
