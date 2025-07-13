#!/bin/bash
# systemd 服务清理脚本
# 确保完全移除所有 AI 小说编辑器相关的 systemd 服务

set -e

echo "🧹 开始清理 systemd 服务冲突..."

# 定义可能的服务名称
POSSIBLE_SERVICES=(
    "ai-novel-editor"
    "ai-novel-editor.service"
    "novel-editor"
    "novel-editor.service"
    "legezhixiao"
    "legezhixiao.service"
    "backend"
    "backend.service"
    "frontend" 
    "frontend.service"
    "novel-backend"
    "novel-backend.service"
    "novel-frontend"
    "novel-frontend.service"
)

# 停止并禁用所有可能的服务
for service in "${POSSIBLE_SERVICES[@]}"; do
    if systemctl list-unit-files | grep -q "^$service"; then
        echo "🛑 发现服务: $service"
        sudo systemctl stop "$service" 2>/dev/null || true
        sudo systemctl disable "$service" 2>/dev/null || true
        echo "  ✅ 已停止并禁用: $service"
    fi
done

# 查找并移除服务文件
SERVICE_PATHS=(
    "/etc/systemd/system"
    "/lib/systemd/system" 
    "/usr/lib/systemd/system"
)

for path in "${SERVICE_PATHS[@]}"; do
    if [ -d "$path" ]; then
        for service in "${POSSIBLE_SERVICES[@]}"; do
            service_file="$path/$service"
            if [ -f "$service_file" ]; then
                echo "🗑️ 移除服务文件: $service_file"
                sudo rm -f "$service_file"
            fi
        done
    fi
done

# 清理可能的定时器文件
for path in "${SERVICE_PATHS[@]}"; do
    if [ -d "$path" ]; then
        find "$path" -name "*novel*" -o -name "*ai-*" | while read -r file; do
            if [[ "$file" == *.service ]] || [[ "$file" == *.timer ]]; then
                echo "🗑️ 移除相关文件: $file"
                sudo rm -f "$file"
            fi
        done
    fi
done

# 重新加载 systemd
echo "🔄 重新加载 systemd 配置..."
sudo systemctl daemon-reload

# 重置失败状态
echo "🔄 重置服务失败状态..."
sudo systemctl reset-failed 2>/dev/null || true

# 检查剩余的相关服务
echo "🔍 检查清理结果..."
remaining_services=$(systemctl list-unit-files | grep -E "(novel|ai-)" | wc -l)
if [ "$remaining_services" -eq 0 ]; then
    echo "✅ 所有相关 systemd 服务已清理完毕"
else
    echo "⚠️ 仍有 $remaining_services 个相关服务残留:"
    systemctl list-unit-files | grep -E "(novel|ai-)" || true
fi

echo "✅ systemd 清理完成"
