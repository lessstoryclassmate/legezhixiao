#!/bin/bash

# GitHub Token 克隆测试脚本
# 验证 Token 是否能正确克隆私有仓库

set -e

echo "🔍 测试 GitHub Token 克隆功能"
echo "==============================="

GITHUB_TOKEN="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"
REPOSITORY="lessstoryclassmate/legezhixiao"
TEST_DIR="/tmp/token-clone-test-$(date +%s)"

echo "📋 测试参数:"
echo "  Token: ${GITHUB_TOKEN:0:10}...${GITHUB_TOKEN: -4}"
echo "  仓库: $REPOSITORY"
echo "  测试目录: $TEST_DIR"

# 创建测试目录
echo ""
echo "📁 创建测试目录..."
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# 测试克隆
echo ""
echo "🔄 测试克隆私有仓库..."
if git clone "https://${GITHUB_TOKEN}@github.com/${REPOSITORY}.git" .; then
    echo "✅ 克隆成功！"
    
    # 验证关键文件
    echo ""
    echo "🔍 验证关键文件..."
    if [ -f "docker-compose.yml" ]; then
        echo "✅ docker-compose.yml 存在"
    else
        echo "❌ docker-compose.yml 不存在"
    fi
    
    if [ -d "frontend" ]; then
        echo "✅ frontend 目录存在"
    else
        echo "❌ frontend 目录不存在"
    fi
    
    if [ -d "backend" ]; then
        echo "✅ backend 目录存在"
    else
        echo "❌ backend 目录不存在"
    fi
    
    echo ""
    echo "📊 仓库信息:"
    echo "当前分支: $(git branch --show-current)"
    echo "最新提交: $(git log -1 --format='%h %s')"
    
else
    echo "❌ 克隆失败！"
    echo ""
    echo "可能的原因:"
    echo "1. Token 已过期或无效"
    echo "2. Token 权限不足（需要 repo 权限）"
    echo "3. 网络连接问题"
    echo "4. 仓库名称错误"
    exit 1
fi

# 测试更新
echo ""
echo "🔄 测试更新操作..."
git remote set-url origin "https://${GITHUB_TOKEN}@github.com/${REPOSITORY}.git"
if git fetch origin; then
    echo "✅ 更新成功！"
else
    echo "❌ 更新失败！"
fi

# 清理测试目录
echo ""
echo "🧹 清理测试环境..."
cd /tmp
rm -rf "$TEST_DIR"

echo ""
echo "🎉 Token 测试完成！"
echo ""
echo "📋 部署脚本中应使用的克隆命令:"
echo "git clone \"https://${GITHUB_TOKEN}@github.com/${REPOSITORY}.git\" ."
echo ""
echo "✅ Token 验证通过，可以用于生产部署"

echo "📋 配置信息:"
echo "  仓库: $GITHUB_REPOSITORY"
echo "  Token长度: ${#GITHUB_TOKEN} 字符"
echo "  Token前缀: ${GITHUB_TOKEN:0:4}..."

# 测试API访问
echo ""
echo "🔗 测试GitHub API访问..."
API_RESPONSE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    "https://api.github.com/repos/$GITHUB_REPOSITORY" \
    -w "%{http_code}")

HTTP_CODE="${API_RESPONSE: -3}"
RESPONSE_BODY="${API_RESPONSE%???}"

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ GitHub API访问成功"
    echo "  仓库名称: $(echo "$RESPONSE_BODY" | grep -o '"name":"[^"]*"' | cut -d'"' -f4)"
    echo "  仓库状态: $(echo "$RESPONSE_BODY" | grep -o '"private":[^,]*' | cut -d':' -f2)"
else
    echo "❌ GitHub API访问失败"
    echo "  HTTP状态码: $HTTP_CODE"
    echo "  响应内容: $RESPONSE_BODY"
    exit 1
fi

# 测试Git克隆
echo ""
echo "📦 测试Git克隆..."
TEST_DIR="/tmp/github-token-test-$(date +%s)"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

if git clone "https://$GITHUB_TOKEN@github.com/$GITHUB_REPOSITORY.git" test-repo; then
    echo "✅ Git克隆成功"
    echo "  克隆目录: $TEST_DIR/test-repo"
    echo "  文件列表:"
    ls -la test-repo/ | head -10
    
    # 清理测试目录
    rm -rf "$TEST_DIR"
    echo "🧹 测试目录已清理"
else
    echo "❌ Git克隆失败"
    echo "  错误可能原因:"
    echo "  1. Token权限不足"
    echo "  2. Token已过期"
    echo "  3. 仓库不存在或无法访问"
    rm -rf "$TEST_DIR"
    exit 1
fi

echo ""
echo "🎉 GitHub Token配置测试完成！"
echo "📋 测试结果:"
echo "  ✅ API访问正常"
echo "  ✅ Git克隆正常"
echo "  ✅ Token配置正确"
echo ""
echo "💡 Token可以正常用于GitHub Actions部署"
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
