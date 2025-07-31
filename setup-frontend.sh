#!/bin/bash

echo "🚀 设置乐格至效 AI小说创作平台前端开发环境"

# 检查 Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js 未安装。请安装 Node.js 18 或更高版本"
    exit 1
fi

echo "📦 安装前端依赖..."
cd frontend
npm install

echo "🔧 创建环境配置..."
if [ ! -f .env ]; then
    cp ../.env.example .env
    echo "✅ 已创建 .env 文件，请根据需要修改配置"
fi

echo "🎨 设置开发工具..."
# 确保 VS Code 扩展配置正确
echo "建议安装以下 VS Code 扩展："
echo "- GitHub Copilot"
echo "- GitHub Copilot Chat"
echo "- ESLint"
echo "- Prettier"
echo "- TypeScript Hero"

cd ..

echo "✅ 前端开发环境设置完成！"
echo ""
echo "📋 下一步："
echo "1. 编辑 frontend/.env 文件，配置您的API密钥"
echo "2. 运行 'npm run dev' 启动开发服务器"
echo "3. 访问 http://localhost:5173"
echo ""
echo "🚀 快速启动："
echo "cd frontend && npm run dev"
