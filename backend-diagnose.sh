#!/bin/bash
echo "🔧 后端服务诊断"
echo "================"

# 检查后端容器状态
echo "后端容器状态："
docker-compose ps backend 2>/dev/null || echo "容器未运行"

echo
echo "后端容器日志 (最近50行)："
docker-compose logs backend --tail=50 2>/dev/null || echo "无法获取日志"

echo
echo "后端健康检查："
curl -f --max-time 10 http://localhost:8000/health 2>/dev/null && echo "✅ 后端健康" || echo "❌ 后端异常"

echo
echo "后端端口监听："
netstat -tlpn | grep :8000 || echo "端口8000未监听"

echo
echo "后端环境变量："
docker-compose exec backend printenv | grep -E "(MONGODB|DATABASE|REDIS)" 2>/dev/null || echo "无法获取环境变量"
