#!/bin/bash

# GitHub Token 测试脚本
# 用于测试 GITHUB_TOKEN 是否可以正常访问私有仓库

echo "🔍 GitHub Token 权限测试"
echo "========================"

# 检查环境变量
if [ -z "$GITHUB_TOKEN" ]; then
    echo "❌ GITHUB_TOKEN 环境变量未设置"
    echo "请在GitHub Actions中确保设置了 GITHUB_TOKEN"
    exit 1
fi

if [ -z "$GITHUB_REPOSITORY" ]; then
    echo "❌ GITHUB_REPOSITORY 环境变量未设置"
    echo "应该格式为: owner/repo"
    exit 1
fi

echo "✅ 环境变量检查通过"
echo "  GITHUB_REPOSITORY: $GITHUB_REPOSITORY"
echo "  GITHUB_TOKEN length: ${#GITHUB_TOKEN}"

# 测试API访问
echo ""
echo "🌐 测试GitHub API访问..."
API_RESPONSE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/$GITHUB_REPOSITORY")

if echo "$API_RESPONSE" | grep -q '"private": true'; then
    echo "✅ 私有仓库API访问成功"
elif echo "$API_RESPONSE" | grep -q '"private": false'; then
    echo "✅ 公开仓库API访问成功"
else
    echo "❌ API访问失败"
    echo "响应: $API_RESPONSE"
    exit 1
fi

# 测试Git克隆
echo ""
echo "📦 测试Git克隆访问..."
TEST_DIR="/tmp/github-token-test-$(date +%s)"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

if git clone "https://${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git" . 2>/dev/null; then
    echo "✅ Git克隆测试成功"
    echo "  仓库文件数量: $(ls -1 | wc -l)"
    echo "  关键文件检查:"
    [ -f "docker-compose.yml" ] && echo "    ✅ docker-compose.yml"
    [ -f "README.md" ] && echo "    ✅ README.md"
    [ -d "frontend" ] && echo "    ✅ frontend/"
    [ -d "backend" ] && echo "    ✅ backend/"
else
    echo "❌ Git克隆测试失败"
    echo "尝试诊断问题..."
    
    # 尝试其他格式
    echo "尝试不同的URL格式..."
    if git clone "https://oauth2:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git" . 2>/dev/null; then
        echo "✅ 使用oauth2格式成功"
    else
        echo "❌ 所有格式都失败"
    fi
fi

# 清理测试目录
cd /tmp
rm -rf "$TEST_DIR"

echo ""
echo "📋 建议检查项目"
echo "==============="
echo "1. 确保 GITHUB_TOKEN 有仓库访问权限"
echo "2. 如果是私有仓库，确保token有 'repo' 权限"
echo "3. 检查token是否过期"
echo "4. 确保GitHub Actions有访问私有仓库的权限"

echo ""
echo "🔗 GitHub Token权限设置："
echo "  Settings → Developer settings → Personal access tokens"
echo "  需要权限: repo (完整仓库访问权限)"
