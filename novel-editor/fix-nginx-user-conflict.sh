#!/bin/bash

# 🔧 修复nginx用户组冲突问题
echo "🔧 修复nginx用户组冲突..."

echo "🔍 检测到问题: nginx用户组已存在于nginx:alpine基础镜像中"
echo "💡 解决方案: 移除重复的用户组创建命令"

# 备份原文件
if [ -f "frontend/Dockerfile" ]; then
    cp frontend/Dockerfile frontend/Dockerfile.backup
    echo "📋 已备份原Dockerfile: frontend/Dockerfile.backup"
fi

# 修复Dockerfile中的nginx用户组创建问题
if [ -f "frontend/Dockerfile" ]; then
    echo "🔧 修复frontend/Dockerfile..."
    
    # 注释掉或删除nginx用户组创建命令
    sed -i '/addgroup.*nginx/,/adduser.*nginx/c\
# nginx用户和组已存在于基础镜像中，无需重新创建\
# RUN addgroup -g 101 -S nginx && \\\
#     adduser -S nginx -u 101 -G nginx' frontend/Dockerfile
    
    echo "✅ frontend/Dockerfile修复完成"
else
    echo "⚠️ 未找到frontend/Dockerfile文件"
fi

# 检查简化版Dockerfile
if [ -f "frontend/Dockerfile.simple" ]; then
    if grep -q "addgroup.*nginx\|adduser.*nginx" frontend/Dockerfile.simple; then
        echo "🔧 修复frontend/Dockerfile.simple..."
        sed -i '/addgroup.*nginx/,/adduser.*nginx/c\
# nginx用户和组已存在于基础镜像中，无需重新创建' frontend/Dockerfile.simple
        echo "✅ frontend/Dockerfile.simple修复完成"
    else
        echo "✅ frontend/Dockerfile.simple无需修复"
    fi
fi

echo ""
echo "📋 修复说明:"
echo "- nginx:alpine基础镜像已经包含nginx用户和组"
echo "- 尝试重新创建会导致 'group nginx in use' 错误"
echo "- 解决方案是移除或注释掉用户组创建命令"
echo ""
echo "✅ nginx用户组冲突修复完成"
