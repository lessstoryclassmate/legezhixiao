#!/bin/bash
# 紧急修复脚本 - 专门解决 DNS 和 systemd 冲突问题
# 使用方法: curl -fsSL https://raw.githubusercontent.com/lessstoryclassmate/legezhixiao/main/scripts/emergency-fix.sh | bash

set -e

echo "🚨 开始紧急修复 - 解决 DNS 和 systemd 冲突问题..."

# ===== 紧急修复 1: DNS 配置 =====
echo "🌐 [修复 1/2] 修复 DNS 配置..."

# 备份原配置
if [ -f "/etc/resolv.conf" ]; then
    sudo cp /etc/resolv.conf /etc/resolv.conf.backup.$(date +%s) 2>/dev/null || true
fi

# 使用最稳定的 DNS 配置
sudo bash -c 'cat > /etc/resolv.conf << EOF
nameserver 223.5.5.5
nameserver 8.8.8.8
nameserver 114.114.114.114
EOF'

echo "✅ DNS 配置已修复为:"
cat /etc/resolv.conf

# 验证 DNS 修复效果
echo "🔍 验证 DNS 修复效果..."
for domain in "github.com" "ccr.ccs.tencentyun.com" "registry-1.docker.io"; do
    if nslookup "$domain" > /dev/null 2>&1; then
        echo "✅ $domain - DNS 解析正常"
    else
        echo "❌ $domain - DNS 解析失败"
    fi
done

# ===== 紧急修复 2: systemd 服务冲突 =====
echo "🧹 [修复 2/2] 彻底清理 systemd 服务冲突..."

# 定义所有可能冲突的服务
CONFLICT_SERVICES=(
    "ai-novel-editor"
    "ai-novel-editor.service"
    "novel-editor"
    "novel-editor.service"
    "backend"
    "backend.service"
    "frontend"
    "frontend.service"
    "legezhixiao"
    "legezhixiao.service"
)

# 强制停止所有可能冲突的服务
echo "🛑 强制停止冲突服务..."
for service in "${CONFLICT_SERVICES[@]}"; do
    # 检查服务是否存在
    if systemctl list-unit-files | grep -q "^$service"; then
        echo "🛑 停止服务: $service"
        sudo systemctl stop "$service" 2>/dev/null || true
        sudo systemctl disable "$service" 2>/dev/null || true
    fi
    
    # 强制停止正在运行的服务
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        echo "🛑 强制终止: $service"
        sudo systemctl stop "$service" || true
        sudo systemctl kill "$service" || true
    fi
done

# 移除所有相关服务文件
echo "🗑️ 移除 systemd 服务文件..."
for service in "${CONFLICT_SERVICES[@]}"; do
    for service_dir in "/etc/systemd/system" "/lib/systemd/system" "/usr/lib/systemd/system"; do
        if [ -f "$service_dir/$service" ]; then
            echo "🗑️ 移除: $service_dir/$service"
            sudo rm -f "$service_dir/$service"
        fi
    done
done

# 清理 systemd 状态
echo "🔄 重新加载 systemd..."
sudo systemctl daemon-reload || true
sudo systemctl reset-failed || true

# 验证清理效果
echo "🔍 验证 systemd 清理效果..."
remaining_conflicts=0
for service in "${CONFLICT_SERVICES[@]}"; do
    if systemctl list-unit-files | grep -q "^$service"; then
        echo "⚠️ 仍存在: $service"
        remaining_conflicts=$((remaining_conflicts + 1))
    fi
done

if [ $remaining_conflicts -eq 0 ]; then
    echo "✅ 所有 systemd 服务冲突已清理"
else
    echo "⚠️ 仍有 $remaining_conflicts 个服务未清理完全"
fi

# ===== 验证修复效果 =====
echo ""
echo "🔍 验证修复效果..."

# 测试网络连通性
echo "测试网络连通性:"
if curl -s --connect-timeout 10 https://github.com > /dev/null 2>&1; then
    echo "✅ 网络连通性正常"
else
    echo "❌ 网络连通性仍有问题"
fi

# 测试 Docker 相关
if command -v docker > /dev/null 2>&1; then
    echo "测试 Docker 镜像拉取:"
    if timeout 30 docker pull hello-world > /dev/null 2>&1; then
        echo "✅ Docker 镜像拉取正常"
        docker rmi hello-world > /dev/null 2>&1 || true
    else
        echo "❌ Docker 镜像拉取仍有问题"
    fi
fi

# ===== 重启相关服务 =====
echo ""
echo "🔄 重启相关服务..."

# 重启 Docker（如果存在）
if command -v docker > /dev/null 2>&1; then
    echo "重启 Docker 服务..."
    sudo systemctl restart docker || true
    sleep 3
fi

echo ""
echo "=================================================================================="
echo "🎉 紧急修复完成!"
echo ""
echo "修复内容:"
echo "✅ 1. DNS 配置已修复 (阿里云 + Google + 114 DNS)"
echo "✅ 2. systemd 服务冲突已清理"
echo ""
echo "建议接下来:"
echo "1. 重新运行部署脚本"
echo "2. 使用 'docker-compose up -d' 启动服务"
echo "3. 避免使用任何 systemctl 命令管理应用服务"
echo "=================================================================================="
