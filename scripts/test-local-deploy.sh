#!/bin/bash
# 本地部署测试脚本

echo "🧪 本地部署模式测试..."

# 设置测试环境变量
export FORCE_LOCAL_DEPLOY=true
export DEPLOY_DIR="/opt/ai-novel-editor"

# 检查项目目录
if [ ! -d "$DEPLOY_DIR" ]; then
    echo "❌ 项目目录不存在，请先运行 clone-fix.sh"
    exit 1
fi

# 检查脚本文件
if [ ! -f "$DEPLOY_DIR/scripts/local-deploy.sh" ]; then
    echo "❌ local-deploy.sh 不存在"
    exit 1
fi

echo "✅ 测试环境准备完成"
echo "🚀 开始本地部署测试..."

# 模拟部署过程
cd "$DEPLOY_DIR"
bash scripts/local-deploy.sh

echo "🔍 测试完成，检查部署结果..."
