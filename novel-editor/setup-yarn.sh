#!/bin/bash

# Yarn安装和项目初始化脚本

echo "检查和安装Yarn包管理器..."

# 检查是否已安装yarn
if command -v yarn &> /dev/null; then
    echo "✅ Yarn已安装"
    yarn --version
else
    echo "📦 正在安装Yarn..."
    
    # 检查npm是否可用
    if command -v npm &> /dev/null; then
        npm install -g yarn
        echo "✅ Yarn安装完成"
    else
        echo "❌ 错误: npm未安装，无法安装yarn"
        echo "请先安装Node.js和npm"
        exit 1
    fi
fi

# 进入前端目录
cd frontend

# 检查是否有yarn.lock文件，如果没有则从package.json初始化
if [ ! -f "yarn.lock" ]; then
    echo "🔄 初始化Yarn项目..."
    yarn install
else
    echo "✅ yarn.lock文件存在"
fi

echo ""
echo "========================="
echo "Yarn配置完成！"
echo "========================="
echo ""
echo "可用的yarn命令："
echo "  yarn dev      - 启动开发服务器"
echo "  yarn build    - 构建生产版本"
echo "  yarn preview  - 预览构建结果"
echo "  yarn lint     - 代码检查"
echo ""
echo "现在可以运行 ./start-dev.sh 启动开发环境"
