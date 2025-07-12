#!/bin/bash

echo "🔍 快速部署问题诊断脚本"
echo "==============================="

# 检查Docker环境
echo ""
echo "🐳 检查Docker环境..."
echo "Docker版本: $(docker --version 2>/dev/null || echo "❌ Docker未安装")"
echo "Docker Compose版本: $(docker-compose --version 2>/dev/null || echo "❌ Docker Compose未安装")"

# 检查Docker服务状态
echo ""
echo "🔍 检查Docker服务状态..."
if systemctl is-active --quiet docker; then
  echo "✅ Docker服务正在运行"
else
  echo "❌ Docker服务未运行"
  echo "尝试启动: sudo systemctl start docker"
fi

# 检查Docker权限
echo ""
echo "🔐 检查Docker权限..."
if docker ps >/dev/null 2>&1; then
  echo "✅ 可以直接运行docker命令"
  DOCKER_CMD="docker"
  COMPOSE_CMD="docker-compose"
elif sudo docker ps >/dev/null 2>&1; then
  echo "⚠️ 需要sudo权限运行docker"
  DOCKER_CMD="sudo docker"
  COMPOSE_CMD="sudo docker-compose"
else
  echo "❌ Docker命令无法执行"
  exit 1
fi

# 检查数据库连接
echo ""
echo "🗄️ 检查数据库连接..."

# MongoDB
if timeout 15 bash -c "echo > /dev/tcp/172.16.32.2/27017" 2>/dev/null; then
  echo "✅ MongoDB (172.16.32.2:27017) 可连接"
else
  echo "❌ MongoDB (172.16.32.2:27017) 连接失败"
fi

# Redis
if timeout 15 bash -c "echo > /dev/tcp/172.16.32.2/6379" 2>/dev/null; then
  echo "✅ Redis (172.16.32.2:6379) 可连接"
else
  echo "❌ Redis (172.16.32.2:6379) 连接失败"
fi

# MySQL 系统库
if timeout 15 bash -c "echo > /dev/tcp/172.16.16.3/3306" 2>/dev/null; then
  echo "✅ MySQL 系统库 (172.16.16.3:3306) 可连接"
else
  echo "❌ MySQL 系统库连接失败"
fi

# MySQL 用户库  
if timeout 15 bash -c "echo > /dev/tcp/172.16.16.2/3306" 2>/dev/null; then
  echo "✅ MySQL 用户库 (172.16.16.2:3306) 可连接"
else
  echo "❌ MySQL 用户库连接失败"
fi

# 检查当前容器状态
echo ""
echo "📦 检查当前容器状态..."
if [ -f "docker-compose.production.yml" ]; then
  echo "容器状态:"
  $COMPOSE_CMD -f docker-compose.production.yml ps
  
  echo ""
  echo "🔍 检查后端容器日志 (最后20行):"
  $COMPOSE_CMD -f docker-compose.production.yml logs --tail=20 backend 2>/dev/null || echo "❌ 无法获取后端日志"
else
  echo "❌ docker-compose.production.yml 文件不存在"
fi

# 检查端口占用
echo ""
echo "🔌 检查端口占用..."
echo "端口80: $(netstat -tlnp 2>/dev/null | grep :80 | head -1 || echo "空闲")"
echo "端口8000: $(netstat -tlnp 2>/dev/null | grep :8000 | head -1 || echo "空闲")"

# 系统资源检查
echo ""
echo "💻 系统资源检查..."
echo "内存使用: $(free -h | grep Mem | awk '{print $3"/"$2}')"
echo "磁盘使用: $(df -h / | tail -1 | awk '{print $3"/"$2" ("$5")"}')"

echo ""
echo "🎯 快速修复建议:"
echo "1. 如果Docker服务未运行: sudo systemctl start docker"
echo "2. 如果权限不足: sudo usermod -aG docker $USER && newgrp docker"
echo "3. 如果数据库连接失败: 检查数据库服务器状态和防火墙"
echo "4. 如果容器启动失败: 查看具体错误日志"

echo ""
echo "==============================="
echo "✅ 诊断完成"
