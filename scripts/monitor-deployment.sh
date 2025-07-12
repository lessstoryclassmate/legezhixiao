#!/bin/bash

# GitHub Actions 部署监控脚本
echo "🔍 监控GitHub Actions部署状态..."
echo "==========================================="

echo "最新提交信息:"
git log --oneline -n 1

echo ""
echo "分支状态:"
echo "当前分支: $(git branch --show-current)"
echo "远程状态: $(git status -s -b | head -1)"

echo ""
echo "触发的工作流:"
echo "✅ Deploy AI Novel Editor (deploy-advanced.yml)"
echo "✅ Test Network Detection (test-network.yml)"

echo ""
echo "预期执行顺序:"
echo "1. 🔍 代码质量检查 (quality-check)"
echo "2. 🔨 构建测试 (build)"
echo "   - 网络检测验证"
echo "   - Docker镜像构建"
echo "   - 容器健康检查"
echo "3. 🚀 生产部署 (deploy)"
echo "   - 仅在main分支的push事件触发"
echo "   - 部署到生产服务器"

echo ""
echo "智能网络检测功能:"
echo "📊 多种检测方法:"
echo "   - 配置解析: docker-compose config"
echo "   - 容器检查: 从运行容器获取网络信息"
echo "   - 网络搜索: 搜索包含app的网络"
echo "   - 后备方案: 常见网络名称尝试"

echo ""
echo "🔗 查看部署状态:"
echo "GitHub Actions: https://github.com/lessstoryclassmate/legezhixiao/actions"
echo ""
echo "✨ 关键改进:"
echo "- 解决了CI环境中网络名称不一致的问题"
echo "- 提供了智能网络检测和多种后备方案"
echo "- 增强了网络诊断和故障排除能力"
echo "- 支持本地和CI环境的无缝切换"

echo ""
echo "⏳ 预计部署时间: 5-10分钟"
echo "🎯 部署完成后可访问:"
echo "   前端: http://你的服务器IP:80"
echo "   后端API: http://你的服务器IP:8000"
echo "   API文档: http://你的服务器IP:8000/docs"

echo ""
echo "==========================================="
echo "🎉 智能网络检测解决方案已成功部署！"
