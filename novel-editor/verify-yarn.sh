#!/bin/bash

# 验证yarn配置脚本

echo "验证Yarn配置..."
echo "===================="

# 检查yarn是否可用
if command -v yarn &> /dev/null; then
    echo "✅ Yarn可用 - 版本: $(yarn --version)"
else
    echo "❌ Yarn未安装"
    exit 1
fi

# 检查前端目录
if [ -d "frontend" ]; then
    echo "✅ 前端目录存在"
    cd frontend
    
    # 检查package.json
    if [ -f "package.json" ]; then
        echo "✅ package.json存在"
    else
        echo "❌ package.json不存在"
        exit 1
    fi
    
    # 检查node_modules
    if [ -d "node_modules" ]; then
        echo "✅ node_modules存在"
    else
        echo "⚠️  node_modules不存在，需要运行 yarn install"
    fi
    
    # 检查yarn.lock
    if [ -f "yarn.lock" ]; then
        echo "✅ yarn.lock存在"
    else
        echo "⚠️  yarn.lock不存在，首次运行yarn install时会创建"
    fi
    
    cd ..
else
    echo "❌ 前端目录不存在"
    exit 1
fi

echo ""
echo "===================="
echo "验证完成！可以运行:"
echo "./start-dev.sh"
echo "===================="
