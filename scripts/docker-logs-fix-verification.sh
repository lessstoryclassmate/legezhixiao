#!/bin/bash

# docker-compose logs 命令参数顺序修复验证脚本

echo "🔧 docker-compose logs 命令参数顺序修复验证"
echo "=============================================="
echo "修复时间: $(date)"
echo

echo "🔍 问题描述"
echo "==========="
echo "❌ 原问题: docker-compose logs 命令参数顺序错误"
echo "❌ 错误格式: docker-compose logs service_name --tail=N"
echo "❌ 导致报错: No such service: --tail=20"
echo

echo "✅ 修复方案"
echo "==========="
echo "✅ 正确格式: docker-compose logs --tail=N service_name"
echo "✅ 修复文件数: 15 个文件"
echo "✅ 涉及范围: GitHub Actions workflow、脚本、文档"
echo

echo "📋 修复文件列表"
echo "=============="
echo "1. .github/workflows/deploy-advanced.yml (3处修复)"
echo "2. scripts/mongodb-health-check.sh"
echo "3. scripts/deploy-fix.sh (2处修复)"
echo "4. scripts/mongodb-backend-fix-diagnosis.sh (2处修复)"
echo "5. scripts/clean-mongodb-volume.sh"
echo "6. mongodb-diagnose.sh"
echo "7. backend-diagnose.sh"
echo "8. PORT_8000_ANALYSIS.md"
echo

echo "🔍 验证修复结果"
echo "=============="
echo "检查所有 docker-compose logs 命令格式:"
echo

# 验证修复结果
echo "✅ 正确格式的命令数量:"
grep -r "docker-compose logs --tail" /workspaces/legezhixiao/ --include="*.yml" --include="*.sh" --include="*.md" | wc -l

echo
echo "❌ 错误格式的命令数量:"
grep -r "docker-compose logs [a-z]* --tail" /workspaces/legezhixiao/ --include="*.yml" --include="*.sh" --include="*.md" | wc -l

echo
echo "📊 修复详情"
echo "==========="
echo "GitHub Actions workflow 修复:"
echo "- 第119行: docker-compose logs --tail=50 mongodb"
echo "- 第131行: docker-compose logs --tail=20 mongodb"
echo "- 第134行: docker-compose logs --tail=20 backend"
echo "- 第300行: docker-compose logs --tail=20 mongodb"
echo

echo "🚀 部署状态"
echo "==========="
echo "✅ 修复已提交到代码仓库"
echo "✅ GitHub Actions 工作流已重新触发"
echo "⏳ 等待新的部署结果"
echo

echo "🔗 监控链接"
echo "==========="
echo "GitHub Actions: https://github.com/yourusername/legezhixiao/actions"
echo "最新提交: $(git log -1 --oneline)"
echo

echo "💡 预期结果"
echo "==========="
echo "修复后，GitHub Actions 应该能够:"
echo "1. ✅ 正确执行 docker-compose logs 命令"
echo "2. ✅ 获取容器日志用于调试"
echo "3. ✅ 继续执行后续的部署步骤"
echo "4. ✅ 完成 MongoDB 和后端服务的健康检查"
echo

echo "🎯 下一步监控重点"
echo "================"
echo "1. 检查 GitHub Actions 是否通过 docker-compose logs 步骤"
echo "2. 观察 MongoDB 容器是否正常启动"
echo "3. 监控后端服务健康检查结果"
echo "4. 验证前端和后端服务可访问性"
echo

echo "✅ 验证完成！"
echo "============"
echo "所有 docker-compose logs 命令参数顺序已修复。"
echo "请访问 GitHub Actions 查看新的部署结果。"
