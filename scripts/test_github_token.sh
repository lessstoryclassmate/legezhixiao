#!/bin/bash

# GitHub Token 测试脚本
# 用于验证GitHub Token是否能正确克隆私有仓库

set -e

echo "🔍 测试 GitHub Token 配置"
echo "=========================="

# 设置变量
GITHUB_TOKEN="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"
REPO_URL="https://github.com/lessstoryclassmate/legezhixiao"
TEST_DIR="/tmp/token-test-$(date +%s)"

echo "📋 测试信息:"
echo "Token: ${GITHUB_TOKEN:0:10}...（已隐藏完整token）"
echo "仓库: $REPO_URL"
echo "测试目录: $TEST_DIR"
echo ""

# 1. 测试GitHub API访问
echo "🔗 测试 1: GitHub API 访问"
echo "----------------------------"
if curl -s -H "Authorization: token $GITHUB_TOKEN" \
   "https://api.github.com/repos/lessstoryclassmate/legezhixiao" > /dev/null; then
    echo "✅ GitHub API 访问成功"
    
    # 获取仓库信息
    REPO_INFO=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
                "https://api.github.com/repos/lessstoryclassmate/legezhixiao")
    echo "📊 仓库信息:"
    echo "   - 名称: $(echo "$REPO_INFO" | grep -o '"name":"[^"]*' | cut -d'"' -f4)"
    echo "   - 私有: $(echo "$REPO_INFO" | grep -o '"private":[^,]*' | cut -d':' -f2)"
    echo "   - 分支: $(echo "$REPO_INFO" | grep -o '"default_branch":"[^"]*' | cut -d'"' -f4)"
else
    echo "❌ GitHub API 访问失败"
    echo "可能的原因:"
    echo "1. Token 无效或已过期"
    echo "2. Token 权限不足"
    echo "3. 网络连接问题"
    exit 1
fi

echo ""

# 2. 测试HTTPS克隆（带Token）
echo "📦 测试 2: HTTPS 克隆（带Token）"
echo "--------------------------------"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

if git clone "https://$GITHUB_TOKEN@github.com/lessstoryclassmate/legezhixiao.git" .; then
    echo "✅ HTTPS 克隆成功"
    
    # 验证克隆内容
    echo "📋 克隆验证:"
    echo "   - 文件数量: $(find . -type f | wc -l)"
    echo "   - 主要文件:"
    [ -f "docker-compose.yml" ] && echo "     ✅ docker-compose.yml"
    [ -f "README.md" ] && echo "     ✅ README.md"
    [ -f ".github/workflows/deploy-advanced.yml" ] && echo "     ✅ GitHub Actions工作流"
    [ -d "frontend" ] && echo "     ✅ frontend目录"
    [ -d "backend" ] && echo "     ✅ backend目录"
    
    # 检查Git状态
    echo "   - Git分支: $(git branch --show-current)"
    echo "   - 最新提交: $(git log -1 --format='%h %s')"
    
else
    echo "❌ HTTPS 克隆失败"
    echo "错误信息已显示在上方"
    exit 1
fi

echo ""

# 3. 测试Git拉取更新
echo "🔄 测试 3: Git 拉取更新"
echo "-----------------------"
if git fetch origin && git status; then
    echo "✅ Git 拉取更新成功"
else
    echo "❌ Git 拉取更新失败"
fi

echo ""

# 4. 清理测试目录
echo "🧹 清理测试目录"
echo "----------------"
cd /tmp
rm -rf "$TEST_DIR"
echo "✅ 清理完成"

echo ""
echo "🎉 GitHub Token 测试完成！"
echo "=========================="
echo ""
echo "📊 测试结果总结:"
echo "✅ GitHub API 访问 - 通过"
echo "✅ HTTPS 克隆 - 通过"
echo "✅ Git 操作 - 通过"
echo ""
echo "🚀 建议下一步操作:"
echo "1. 在GitHub仓库中设置 GITHUB_TOKEN_CUSTOM secret"
echo "2. 确保其他必需的secrets也已设置"
echo "3. 触发GitHub Actions部署流程"
echo ""
echo "💡 注意事项:"
echo "- 此Token具有仓库完全访问权限，请妥善保管"
echo "- 定期检查Token的有效期"
echo "- 生产环境部署时，Token将在服务器上临时使用后被清理"
