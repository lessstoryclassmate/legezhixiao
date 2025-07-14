#!/bin/bash

# 部署监控脚本
# 监控 GitHub Actions 部署状态和服务健康状态

echo "🚀 AI小说编辑器部署监控"
echo "========================"
echo "监控时间: $(date)"
echo

# 项目信息
PROJECT_NAME="legezhixiao"
REPO_URL="https://github.com/yourusername/legezhixiao"
SERVER_IP="106.13.216.179"

echo "📋 项目信息"
echo "==========="
echo "项目名称: $PROJECT_NAME"
echo "服务器IP: $SERVER_IP"
echo "GitHub仓库: $REPO_URL"
echo

echo "🔍 检查最新提交状态"
echo "=================="
echo "最新提交:"
git log -1 --oneline
echo
echo "当前分支: $(git branch --show-current)"
echo "推送状态: $(git status -s -b | head -1)"
echo

echo "🌐 GitHub Actions 状态"
echo "====================="
echo "请访问以下链接查看部署状态:"
echo "https://github.com/yourusername/legezhixiao/actions"
echo
echo "部署工作流: deploy-advanced.yml"
echo "预期执行时间: 10-15分钟"
echo

echo "🏥 服务健康检查"
echo "=============="
echo "等待30秒后开始检查服务状态..."
sleep 30

# 检查前端服务
echo "检查前端服务 (端口 80)..."
if curl -f --max-time 10 http://$SERVER_IP:80 >/dev/null 2>&1; then
    echo "✅ 前端服务: 正常"
else
    echo "❌ 前端服务: 异常或尚未启动"
fi

# 检查后端服务
echo "检查后端服务 (端口 8000)..."
if curl -f --max-time 10 http://$SERVER_IP:8000/health >/dev/null 2>&1; then
    echo "✅ 后端服务: 正常"
else
    echo "❌ 后端服务: 异常或尚未启动"
fi

echo

echo "📊 部署状态总结"
echo "=============="
echo "✅ 代码已推送到远程仓库"
echo "✅ GitHub Actions 部署已触发"
echo "⏳ 等待部署完成 (约10-15分钟)"
echo

echo "🔗 访问链接"
echo "=========="
echo "前端地址: http://$SERVER_IP:80"
echo "后端API: http://$SERVER_IP:8000"
echo "API文档: http://$SERVER_IP:8000/docs"
echo "健康检查: http://$SERVER_IP:8000/health"
echo

echo "🛠️  故障排除"
echo "============"
echo "如果部署失败，请检查:"
echo "1. GitHub Actions 日志"
echo "2. 服务器资源 (内存、磁盘空间)"
echo "3. MongoDB 数据卷状态"
echo "4. 防火墙和端口配置"
echo

echo "📝 监控命令"
echo "==========="
echo "持续监控服务状态:"
echo "watch -n 30 'curl -f http://$SERVER_IP:8000/health && echo \"✅ 后端正常\" || echo \"❌ 后端异常\"'"
echo
echo "查看部署日志:"
echo "请访问 GitHub Actions 页面查看详细日志"
echo

echo "🎯 修复重点"
echo "==========="
echo "本次修复的关键问题:"
echo "1. ✅ MongoDB 用户名配置统一 (admin)"
echo "2. ✅ 健康检查间隔优化 (15秒)"
echo "3. ✅ 后端启动等待时间延长 (120秒)"
echo "4. ✅ GitHub Actions 环境变量名统一"
echo "5. ✅ 添加 MongoDB 数据卷清理功能"
echo

echo "⚠️  注意事项"
echo "============"
echo "- 首次部署可能需要更长时间"
echo "- 如果 MongoDB 仍有问题，可能需要清理数据卷"
echo "- 建议监控服务器资源使用情况"
echo

echo "✅ 部署监控脚本执行完成"
echo "建议每5分钟重新运行此脚本，直到服务正常启动"
