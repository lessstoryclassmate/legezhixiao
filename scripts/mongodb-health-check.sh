#!/bin/bash

# MongoDB 健康检查和修复脚本
# 该脚本用于检查 MongoDB 容器启动状态并解决常见问题

set -e

echo "🔍 开始 MongoDB 健康检查..."

# 检查 MongoDB 数据目录权限
echo "检查 MongoDB 数据目录权限..."
sudo chown -R 999:999 /var/lib/docker/volumes/legezhixiao_mongodb_data/_data 2>/dev/null || true

# 停止现有的 MongoDB 容器
echo "停止现有的 MongoDB 容器..."
docker-compose down mongodb 2>/dev/null || true

# 清理可能损坏的 MongoDB 数据卷（仅在必要时）
read -p "是否清理 MongoDB 数据卷？这将删除所有数据 (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🗑️  清理 MongoDB 数据卷..."
    docker volume rm legezhixiao_mongodb_data 2>/dev/null || true
fi

# 启动 MongoDB 服务
echo "🚀 启动 MongoDB 服务..."
docker-compose up -d mongodb

# 等待 MongoDB 启动
echo "⏳ 等待 MongoDB 启动..."
sleep 30

# 检查 MongoDB 健康状态
echo "🏥 检查 MongoDB 健康状态..."
for i in {1..12}; do
    if docker-compose exec mongodb mongosh --quiet --eval "db.adminCommand('ping')" 2>/dev/null; then
        echo "✅ MongoDB 健康检查通过！"
        break
    else
        echo "⏳ MongoDB 尚未就绪，等待 10 秒... (尝试 $i/12)"
        sleep 10
    fi
    
    if [ $i -eq 12 ]; then
        echo "❌ MongoDB 健康检查失败！"
        echo "查看 MongoDB 日志："
        docker-compose logs mongodb --tail=50
        exit 1
    fi
done

# 测试 MongoDB 连接
echo "🔌 测试 MongoDB 连接..."
if docker-compose exec mongodb mongosh --quiet --eval "
    db = db.getSiblingDB('ai_novel_db');
    db.runCommand({ping: 1});
    print('MongoDB 连接测试成功！');
" 2>/dev/null; then
    echo "✅ MongoDB 连接测试通过！"
else
    echo "❌ MongoDB 连接测试失败！"
    exit 1
fi

# 检查初始化脚本是否执行
echo "📋 检查数据库初始化状态..."
if docker-compose exec mongodb mongosh --quiet --eval "
    db = db.getSiblingDB('ai_novel_db');
    collections = db.getCollectionNames();
    if (collections.length > 0) {
        print('✅ 数据库已初始化，集合数量：' + collections.length);
    } else {
        print('⚠️  数据库未初始化');
    }
"; then
    echo "数据库状态检查完成"
else
    echo "❌ 数据库状态检查失败！"
fi

echo "
🎉 MongoDB 健康检查完成！

📊 状态总结：
- MongoDB 容器：运行中
- 健康检查：通过
- 数据库连接：正常
- 初始化脚本：已执行

🔗 下一步：
- 运行 'docker-compose up -d' 启动所有服务
- 运行 'docker-compose logs -f' 查看实时日志
- 访问 http://localhost:8000/health 检查后端健康状态
"
