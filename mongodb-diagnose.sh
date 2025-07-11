#!/bin/bash
echo "🍃 MongoDB 容器诊断"
echo "==================="

# 检查 MongoDB 容器状态
echo "MongoDB 容器状态："
docker-compose ps mongodb 2>/dev/null || echo "容器未运行"

echo
echo "MongoDB 容器日志 (最近50行)："
docker-compose logs mongodb --tail=50 2>/dev/null || echo "无法获取日志"

echo
echo "MongoDB 容器详细信息："
docker inspect $(docker-compose ps -q mongodb 2>/dev/null) 2>/dev/null | jq -r '.[0].State' || echo "无法获取容器信息"

echo
echo "MongoDB 数据卷信息："
docker volume inspect legezhixiao_mongodb_data 2>/dev/null || echo "数据卷不存在"

echo
echo "MongoDB 进程信息："
docker-compose exec mongodb ps aux 2>/dev/null || echo "无法获取进程信息"

echo
echo "MongoDB 连接测试："
docker-compose exec mongodb mongosh --quiet --eval "db.adminCommand('ping')" 2>/dev/null || echo "连接失败"
