#!/bin/bash

# 部署前验证脚本 - 确保所有必要文件存在
# 这个脚本用于在部署过程中验证关键文件的存在

set -e

DEPLOY_DIR="/opt/ai-novel-editor"
REQUIRED_FILES=(
    "docker-compose.production.yml"
    "frontend/Dockerfile"
    "backend/Dockerfile"
    "frontend/package.json"
    "backend/requirements.txt"
)

echo "🔍 部署前文件验证..."

# 检查部署目录是否存在
if [ ! -d "$DEPLOY_DIR" ]; then
    echo "❌ 部署目录 $DEPLOY_DIR 不存在"
    exit 1
fi

cd "$DEPLOY_DIR"

echo "📁 当前目录: $(pwd)"
echo "📋 目录内容:"
ls -la

echo ""
echo "🔎 验证必需文件..."

missing_files=()

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file - 存在"
        # 显示文件大小
        size=$(stat -c%s "$file" 2>/dev/null || echo "未知")
        echo "   文件大小: $size 字节"
    else
        echo "❌ $file - 缺失"
        missing_files+=("$file")
    fi
done

# 检查是否有缺失文件
if [ ${#missing_files[@]} -eq 0 ]; then
    echo ""
    echo "✅ 所有必需文件验证通过"
    echo "🎯 可以安全开始部署"
else
    echo ""
    echo "❌ 以下文件缺失:"
    for file in "${missing_files[@]}"; do
        echo "   - $file"
    done
    echo ""
    echo "🔧 建议解决方案:"
    echo "1. 检查 Git 克隆是否完整"
    echo "2. 确认文件已提交到远程仓库"
    echo "3. 检查 .gitignore 是否误排除了这些文件"
    echo "4. 重新克隆仓库"
    exit 1
fi

# 额外验证 - 检查 docker-compose.production.yml 语法
echo ""
echo "🧪 验证 docker-compose.production.yml 语法..."
if command -v docker-compose >/dev/null 2>&1; then
    if docker-compose -f docker-compose.production.yml config >/dev/null 2>&1; then
        echo "✅ docker-compose.production.yml 语法正确"
    else
        echo "❌ docker-compose.production.yml 语法错误"
        echo "详细错误信息:"
        docker-compose -f docker-compose.production.yml config
        exit 1
    fi
else
    echo "⚠️  docker-compose 未安装，跳过语法检查"
fi

echo ""
echo "🎉 部署前验证完成，所有检查通过！"
