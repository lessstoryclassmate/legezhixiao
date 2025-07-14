#!/bin/bash
# 网络问题一键解决方案
# DNS解析正确但网络无法连接的完整解决方案

set -e

# 脚本路径
SCRIPT_DIR="/workspaces/legezhixiao/scripts"
DIAGNOSIS_SCRIPT="$SCRIPT_DIR/network-deep-diagnosis.sh"
FIX_SCRIPT="$SCRIPT_DIR/network-connection-fix.sh"

# 颜色输出函数
red() { echo -e "\033[31m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
blue() { echo -e "\033[34m$1\033[0m"; }

# 显示标题
show_banner() {
    echo "================================="
    echo "🌐 网络问题一键解决方案"
    echo "================================="
    echo "专门解决：DNS解析正确但网络无法连接"
    echo ""
}

# 显示菜单
show_menu() {
    echo "请选择操作："
    echo "1) 🔍 运行网络深度诊断"
    echo "2) 🔧 运行网络连接修复"
    echo "3) ⚡ 快速修复（推荐）"
    echo "4) 🎯 完整诊断+修复"
    echo "5) 📊 查看网络状态"
    echo "6) 🆘 紧急修复模式"
    echo "0) 退出"
    echo ""
    echo -n "请输入选择 [0-6]: "
}

# 网络快速检查
quick_network_check() {
    echo "🔍 快速网络状态检查..."
    echo ""
    
    # DNS测试
    echo -n "DNS解析测试 (github.com): "
    if nslookup github.com > /dev/null 2>&1; then
        green "✅ 正常"
    else
        red "❌ 失败"
    fi
    
    # 网关连通性
    echo -n "网关连通性测试: "
    gateway=$(ip route show default | awk '/default/ {print $3}' | head -1)
    if [ -n "$gateway" ] && ping -c 1 -W 2 "$gateway" > /dev/null 2>&1; then
        green "✅ 正常"
    else
        red "❌ 失败"
    fi
    
    # TCP连接测试
    echo -n "TCP连接测试 (github.com:22): "
    if timeout 5 bash -c "exec 3<>/dev/tcp/github.com/22" 2>/dev/null; then
        green "✅ 正常"
        exec 3<&-
    else
        red "❌ 失败"
    fi
    
    # HTTP连接测试
    echo -n "HTTP连接测试 (github.com): "
    if timeout 10 curl -I --max-time 5 https://github.com > /dev/null 2>&1; then
        green "✅ 正常"
    else
        red "❌ 失败"
    fi
    
    echo ""
}

# 运行诊断
run_diagnosis() {
    echo "🔍 启动网络深度诊断..."
    if [ -f "$DIAGNOSIS_SCRIPT" ]; then
        bash "$DIAGNOSIS_SCRIPT"
    else
        red "❌ 诊断脚本不存在: $DIAGNOSIS_SCRIPT"
        return 1
    fi
}

# 运行修复
run_fix() {
    echo "🔧 启动网络连接修复..."
    if [ -f "$FIX_SCRIPT" ]; then
        bash "$FIX_SCRIPT"
    else
        red "❌ 修复脚本不存在: $FIX_SCRIPT"
        return 1
    fi
}

# 快速修复
quick_fix() {
    echo "⚡ 快速修复模式..."
    if [ -f "$FIX_SCRIPT" ]; then
        bash "$FIX_SCRIPT" --quick
    else
        # 内置快速修复
        echo "🔧 执行内置快速修复..."
        
        if [ "$EUID" -eq 0 ]; then
            # DNS修复
            echo "nameserver 223.5.5.5" > /etc/resolv.conf
            echo "nameserver 8.8.8.8" >> /etc/resolv.conf
            
            # 重启关键服务
            systemctl restart systemd-resolved 2>/dev/null || true
            systemctl restart docker 2>/dev/null || true
            
            # 清理DNS缓存
            systemd-resolve --flush-caches 2>/dev/null || true
            
            green "✅ 快速修复完成"
        else
            yellow "⚠️ 需要root权限进行快速修复"
            echo "请使用: sudo $0"
        fi
    fi
}

# 完整诊断+修复
full_diagnosis_and_fix() {
    echo "🎯 开始完整诊断和修复流程..."
    echo ""
    
    echo "第一阶段：网络诊断"
    echo "==================="
    run_diagnosis
    
    echo ""
    echo "第二阶段：问题修复"
    echo "==================="
    run_fix
    
    echo ""
    echo "第三阶段：修复验证"
    echo "==================="
    quick_network_check
    
    green "🎯 完整诊断和修复流程完成！"
}

# 紧急修复模式
emergency_fix() {
    echo "🆘 紧急修复模式启动..."
    echo "将强制重置所有网络配置"
    echo ""
    
    if [ "$EUID" -ne 0 ]; then
        red "❌ 紧急修复需要root权限"
        echo "请使用: sudo $0"
        return 1
    fi
    
    echo "⚠️ 警告：此操作将重置网络配置"
    echo -n "是否继续？[y/N]: "
    read -r confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo "🔧 执行紧急修复..."
        
        # 强制重置DNS
        cat > /etc/resolv.conf << EOF
nameserver 223.5.5.5
nameserver 223.6.6.6
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF
        
        # 重启所有网络服务
        systemctl restart networking 2>/dev/null || true
        systemctl restart NetworkManager 2>/dev/null || true
        systemctl restart systemd-resolved 2>/dev/null || true
        systemctl restart systemd-networkd 2>/dev/null || true
        systemctl restart docker 2>/dev/null || true
        
        # 清理网络缓存
        ip route flush cache 2>/dev/null || true
        systemd-resolve --flush-caches 2>/dev/null || true
        
        # 重新配置防火墙
        iptables -F OUTPUT 2>/dev/null || true
        iptables -A OUTPUT -j ACCEPT 2>/dev/null || true
        
        green "✅ 紧急修复完成"
        echo "建议重启系统以确保所有配置生效"
    else
        echo "紧急修复已取消"
    fi
}

# 主菜单循环
main_menu() {
    while true; do
        show_banner
        quick_network_check
        show_menu
        
        read -r choice
        echo ""
        
        case $choice in
            1)
                run_diagnosis
                ;;
            2)
                run_fix
                ;;
            3)
                quick_fix
                ;;
            4)
                full_diagnosis_and_fix
                ;;
            5)
                quick_network_check
                ;;
            6)
                emergency_fix
                ;;
            0)
                echo "👋 再见！"
                exit 0
                ;;
            *)
                red "❌ 无效选择，请输入 0-6"
                ;;
        esac
        
        echo ""
        echo "按 Enter 键继续..."
        read -r
        clear
    done
}

# 命令行参数处理
case "${1:-}" in
    --diagnosis|-d)
        show_banner
        run_diagnosis
        ;;
    --fix|-f)
        show_banner
        run_fix
        ;;
    --quick|-q)
        show_banner
        quick_fix
        ;;
    --full|-a)
        show_banner
        full_diagnosis_and_fix
        ;;
    --emergency|-e)
        show_banner
        emergency_fix
        ;;
    --check|-c)
        show_banner
        quick_network_check
        ;;
    --help|-h)
        echo "网络问题一键解决方案"
        echo ""
        echo "用法: $0 [选项]"
        echo ""
        echo "选项:"
        echo "  --diagnosis, -d    运行网络诊断"
        echo "  --fix, -f          运行网络修复"
        echo "  --quick, -q        快速修复"
        echo "  --full, -a         完整诊断+修复"
        echo "  --emergency, -e    紧急修复模式"
        echo "  --check, -c        快速网络检查"
        echo "  --help, -h         显示此帮助"
        echo ""
        echo "无参数运行将显示交互式菜单"
        ;;
    *)
        main_menu
        ;;
esac
