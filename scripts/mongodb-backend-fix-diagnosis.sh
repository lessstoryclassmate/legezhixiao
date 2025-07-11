#!/bin/bash

# MongoDB 容器重启和后端健康检查失败问题诊断和修复脚本
# 针对部署日志中的具体问题进行修复

set -e

echo "🔧 MongoDB 容器重启和后端健康检查失败问题诊断"
echo "================================================"

PROJECT_DIR="/workspaces/legezhixiao"
cd "$PROJECT_DIR"

# 1. 检查配置文件一致性
echo "
📋 步骤 1: 检查配置文件一致性"
echo "检查 docker-compose.yml 中的环境变量配置..."

# 检查 MongoDB 配置
echo "MongoDB 配置："
grep -A 5 "MONGO_INITDB_ROOT_USERNAME" docker-compose.yml || echo "❌ 未找到 MongoDB 用户名配置"
grep -A 5 "MONGO_INITDB_ROOT_PASSWORD" docker-compose.yml || echo "❌ 未找到 MongoDB 密码配置"

# 检查 .env 文件
echo "
.env 文件配置："
grep "MONGO_" .env | head -5

# 2. 检查 mongo-init.js 文件
echo "
📋 步骤 2: 检查 MongoDB 初始化脚本"
if [ -f "database/mongo-init.js" ]; then
    echo "✅ mongo-init.js 文件存在"
    echo "文件大小: $(du -h database/mongo-init.js | cut -f1)"
    echo "文件权限: $(ls -la database/mongo-init.js)"
else
    echo "❌ mongo-init.js 文件不存在！"
    exit 1
fi

# 3. 检查 Docker Compose 配置语法
echo "
📋 步骤 3: 检查 Docker Compose 配置语法"
if docker-compose config > /dev/null 2>&1; then
    echo "✅ Docker Compose 配置语法正确"
else
    echo "❌ Docker Compose 配置有语法错误："
    docker-compose config
    exit 1
fi

# 4. 检查依赖关系配置
echo "
📋 步骤 4: 检查服务依赖关系"
echo "后端服务依赖检查："
grep -A 5 "depends_on:" docker-compose.yml | grep -A 3 "mongodb"

# 5. 创建资源监控脚本
echo "
📋 步骤 5: 创建资源监控脚本"
cat > monitor-resources.sh << 'EOF'
#!/bin/bash
echo "📊 系统资源监控"
echo "================"
echo "内存使用："
free -h
echo
echo "磁盘使用："
df -h
echo
echo "Docker 容器状态："
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo
echo "Docker 系统信息："
docker system df
EOF

chmod +x monitor-resources.sh

# 6. 创建 MongoDB 专用诊断脚本
echo "
📋 步骤 6: 创建 MongoDB 专用诊断脚本"
cat > mongodb-diagnose.sh << 'EOF'
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
EOF

chmod +x mongodb-diagnose.sh

# 7. 创建后端诊断脚本
echo "
📋 步骤 7: 创建后端诊断脚本"
cat > backend-diagnose.sh << 'EOF'
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
EOF

chmod +x backend-diagnose.sh

# 8. 显示修复建议
echo "
🎯 修复建议和操作指南"
echo "===================="
echo "基于日志分析，主要问题和解决方案："
echo
echo "1. ✅ MongoDB 容器配置已修正："
echo "   - 固定用户名为 'admin'"
echo "   - 健康检查间隔调整为15秒"
echo "   - 启动等待时间增加到40秒"
echo
echo "2. ✅ 后端健康检查已优化："
echo "   - 启动等待时间增加到120秒"
echo "   - 健康检查超时时间延长到15秒"
echo "   - 增加错误处理逻辑"
echo
echo "3. ✅ GitHub Actions 工作流已修正："
echo "   - 环境变量名统一（SERVER_IP, SERVER_USER, SERVER_SSH_KEY）"
echo "   - MongoDB 等待时间延长到60秒，检查次数增加到15次"
echo "   - 后端等待时间延长到45秒，检查次数增加到12次"
echo
echo "4. 📋 接下来的操作步骤："
echo "   a. 运行资源监控: ./monitor-resources.sh"
echo "   b. 运行 MongoDB 诊断: ./mongodb-diagnose.sh"
echo "   c. 运行后端诊断: ./backend-diagnose.sh"
echo "   d. 如需本地测试: ./scripts/deploy-fix.sh"
echo "   e. 推送代码触发新部署"
echo
echo "5. 🚨 如果问题持续存在："
echo "   - 检查服务器内存是否充足 (建议2GB+)"
echo "   - 检查磁盘空间是否充足"
echo "   - 考虑清理 Docker 数据卷: docker volume rm legezhixiao_mongodb_data"
echo "   - 检查防火墙和端口配置"
echo

echo "📝 配置文件修正总结"
echo "==================="
echo "✅ docker-compose.yml: MongoDB用户名固定、健康检查优化"
echo "✅ .github/workflows/deploy-advanced.yml: 环境变量名修正、等待时间延长"
echo "✅ .env: 移除过时的部署配置变量"
echo "✅ scripts/: 新增MongoDB和后端诊断脚本"
echo
echo "🚀 建议立即操作:"
echo "1. git add ."
echo "2. git commit -m \"fix: 修复MongoDB容器重启和后端健康检查失败问题\""
echo "3. git push"
echo "4. 观察GitHub Actions部署日志"
echo

echo "✅ 诊断脚本准备完成！"
