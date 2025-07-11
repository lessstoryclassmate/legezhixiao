#!/bin/bash

# MongoDB 数据卷清理脚本
# 用于解决 MongoDB 容器频繁重启问题

set -e

echo "🗑️  MongoDB 数据卷清理脚本"
echo "=========================="

PROJECT_NAME="legezhixiao"
MONGODB_VOLUME="${PROJECT_NAME}_mongodb_data"

echo "项目名称: $PROJECT_NAME"
echo "MongoDB 数据卷: $MONGODB_VOLUME"
echo

# 1. 停止所有相关容器
echo "🛑 步骤 1: 停止所有相关容器"
docker-compose down 2>/dev/null || true
echo "✅ 容器已停止"

# 2. 检查数据卷是否存在
echo "
🔍 步骤 2: 检查 MongoDB 数据卷状态"
if docker volume ls | grep -q "$MONGODB_VOLUME"; then
    echo "📋 MongoDB 数据卷信息："
    docker volume inspect "$MONGODB_VOLUME" | jq -r '.[0] | {Name: .Name, Driver: .Driver, Mountpoint: .Mountpoint, CreatedAt: .CreatedAt}'
    
    echo "
📊 数据卷大小："
    docker run --rm -v "$MONGODB_VOLUME:/data" alpine du -sh /data
else
    echo "❌ MongoDB 数据卷不存在"
fi

# 3. 提供选择
echo "
⚠️  警告: 以下操作将清理 MongoDB 数据卷，所有数据将丢失！"
echo "建议仅在开发环境或确认数据可重新生成时执行。"
echo
read -p "是否继续清理 MongoDB 数据卷？(输入 'YES' 确认): " -r
if [[ $REPLY == "YES" ]]; then
    echo "
🗑️  步骤 3: 清理 MongoDB 数据卷"
    
    # 移除数据卷
    docker volume rm "$MONGODB_VOLUME" 2>/dev/null && echo "✅ MongoDB 数据卷已删除" || echo "⚠️  数据卷删除失败或不存在"
    
    # 清理悬空数据卷
    echo "清理悬空数据卷..."
    docker volume prune -f
    
    echo "✅ 数据卷清理完成"
else
    echo "❌ 用户取消操作"
    exit 0
fi

# 4. 重新启动服务
echo "
🚀 步骤 4: 重新启动服务"
echo "启动 MongoDB..."
docker-compose up -d mongodb

echo "等待 MongoDB 启动..."
sleep 30

# 检查 MongoDB 健康状态
echo "检查 MongoDB 健康状态..."
for i in {1..10}; do
    if docker-compose exec -T mongodb mongosh --quiet --eval "db.adminCommand('ping')" 2>/dev/null; then
        echo "✅ MongoDB 启动成功!"
        break
    else
        echo "⏳ 等待 MongoDB 启动... ($i/10)"
        sleep 10
    fi
    
    if [ $i -eq 10 ]; then
        echo "❌ MongoDB 启动失败"
        echo "查看 MongoDB 日志："
        docker-compose logs --tail=20 mongodb
        exit 1
    fi
done

echo "
🎉 MongoDB 数据卷清理和重启完成！"
echo "
📋 后续操作："
echo "1. 启动其他服务: docker-compose up -d"
echo "2. 查看服务状态: docker-compose ps"
echo "3. 查看日志: docker-compose logs -f"
echo "4. 测试连接: curl http://localhost:8000/health"
