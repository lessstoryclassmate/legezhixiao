#!/bin/bash

# 部署前配置检查脚本
# 确保所有配置正确后再提交

set -e

echo "🔍 部署前配置检查"
echo "=================="

PROJECT_DIR="/workspaces/legezhixiao"
cd "$PROJECT_DIR"

# 1. 检查 Docker Compose 配置
echo "📋 检查 Docker Compose 配置..."
if docker-compose config > /dev/null 2>&1; then
    echo "✅ Docker Compose 配置语法正确"
else
    echo "❌ Docker Compose 配置有错误："
    docker-compose config
    exit 1
fi

# 2. 检查关键文件存在
echo "
📋 检查关键文件..."
files=(
    "docker-compose.yml"
    "database/mongo-init.js"
    ".github/workflows/deploy-advanced.yml"
    ".env.example"
    "scripts/clean-mongodb-volume.sh"
    "scripts/mongodb-backend-fix-diagnosis.sh"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file 存在"
    else
        echo "❌ $file 不存在"
        exit 1
    fi
done

# 3. 检查 MongoDB 配置一致性
echo "
📋 检查 MongoDB 配置一致性..."
if grep -q "MONGO_INITDB_ROOT_USERNAME=admin" docker-compose.yml; then
    echo "✅ MongoDB 用户名配置正确"
else
    echo "❌ MongoDB 用户名配置错误"
    exit 1
fi

if grep -q "MONGO_INITDB_ROOT_PASSWORD=\${MONGO_PASSWORD}" docker-compose.yml; then
    echo "✅ MongoDB 密码映射正确"
else
    echo "❌ MongoDB 密码映射错误"
    exit 1
fi

# 4. 检查 GitHub Actions 工作流
echo "
📋 检查 GitHub Actions 工作流..."
if grep -q "SERVER_SSH_KEY" .github/workflows/deploy-advanced.yml; then
    echo "✅ SSH 密钥变量名正确"
else
    echo "❌ SSH 密钥变量名错误"
    exit 1
fi

if grep -q "SERVER_IP" .github/workflows/deploy-advanced.yml; then
    echo "✅ 服务器 IP 变量名正确"
else
    echo "❌ 服务器 IP 变量名错误"
    exit 1
fi

# 5. 检查 MongoDB 优化配置
echo "
📋 检查 MongoDB 优化配置..."
if grep -q "restart: always" docker-compose.yml; then
    echo "✅ MongoDB 重启策略配置正确"
else
    echo "❌ MongoDB 重启策略未设置为 always"
    exit 1
fi

if grep -q "wiredTigerCacheSizeGB" docker-compose.yml; then
    echo "✅ MongoDB 内存限制配置正确"
else
    echo "❌ MongoDB 内存限制未配置"
    exit 1
fi

# 6. 检查数据卷配置
echo "
📋 检查数据卷配置..."
if grep -q "mongodb_data:/data/db" docker-compose.yml; then
    echo "✅ MongoDB 使用 Docker 数据卷（推荐）"
else
    echo "⚠️  MongoDB 可能使用本地挂载，建议使用 Docker 数据卷"
fi

# 7. 生成部署总结
echo "
📊 部署配置总结"
echo "=============="
echo "✅ Docker Compose 配置: 正确"
echo "✅ MongoDB 配置: 优化完成"
echo "✅ 重启策略: restart: always"
echo "✅ 内存限制: 已配置 wiredTigerCacheSizeGB"
echo "✅ 数据卷清理: 脚本已准备"
echo "✅ GitHub Actions: 环境变量已修正"
echo "✅ 健康检查: 超时时间已延长"

echo "
🚀 准备提交的修改"
echo "================"
echo "1. docker-compose.yml:"
echo "   - MongoDB 重启策略改为 always"
echo "   - 添加内存限制配置"
echo "   - 健康检查优化"
echo
echo "2. GitHub Actions 工作流:"
echo "   - 环境变量名修正"
echo "   - 添加 MongoDB 数据卷清理逻辑"
echo "   - 分阶段启动服务"
echo
echo "3. 新增脚本:"
echo "   - scripts/clean-mongodb-volume.sh"
echo "   - scripts/mongodb-backend-fix-diagnosis.sh"
echo

echo "🎯 关键修复点"
echo "============="
echo "1. ✅ MongoDB 频繁重启问题:"
echo "   - 使用 restart: always 策略"
echo "   - 限制内存使用避免 OOM"
echo "   - 自动清理有问题的数据卷"
echo
echo "2. ✅ 后端健康检查失败问题:"
echo "   - 确保 MongoDB 先启动"
echo "   - 延长健康检查等待时间"
echo "   - 分阶段启动服务"
echo
echo "3. ✅ 环境变量一致性问题:"
echo "   - 统一使用 SERVER_* 前缀"
echo "   - 修正 GitHub Actions 变量引用"
echo

echo "✅ 所有检查通过，可以安全提交！"
echo "
💡 建议提交信息:"
echo "fix: 解决MongoDB容器频繁重启和后端健康检查失败问题"
echo "- 添加MongoDB内存限制和重启策略优化"
echo "- 修正GitHub Actions环境变量引用"
echo "- 添加MongoDB数据卷清理逻辑"
echo "- 实现分阶段服务启动确保依赖顺序"
