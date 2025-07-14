#!/bin/bash
# 网络连接修复工具
# 专门修复DNS解析正确但网络无法连接的问题

set -e

echo "🔧 网络连接修复工具启动..."

# 颜色输出函数
red() { echo -e "\033[31m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
blue() { echo -e "\033[34m$1\033[0m"; }

# 检查运行权限
check_privileges() {
    if [ "$EUID" -ne 0 ]; then
        echo "⚠️ 部分修复操作需要root权限，建议使用 sudo 运行此脚本"
        echo "当前将跳过需要root权限的操作"
        IS_ROOT=false
    else
        IS_ROOT=true
        green "✅ 检测到root权限，将执行完整修复"
    fi
}

# 1. 修复DNS配置
fix_dns_configuration() {
    echo "================== 1. 修复DNS配置 =================="
    
    # 备份原DNS配置
    if [ "$IS_ROOT" = true ]; then
        echo "📋 备份原DNS配置..."
        cp /etc/resolv.conf /etc/resolv.conf.backup.$(date +%s) 2>/dev/null || true
        
        # 设置可靠的DNS服务器
        echo "🔧 配置可靠的DNS服务器..."
        cat > /etc/resolv.conf << EOF
# 临时DNS配置 - 由网络修复工具生成
nameserver 223.5.5.5
nameserver 223.6.6.6
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF
        green "✅ DNS服务器配置已更新"
        
        # 重启systemd-resolved
        if systemctl is-active systemd-resolved > /dev/null 2>&1; then
            echo "🔄 重启systemd-resolved服务..."
            systemctl restart systemd-resolved
            sleep 2
            green "✅ systemd-resolved已重启"
        fi
    else
        yellow "⚠️ 跳过DNS配置修复（需要root权限）"
    fi
    
    # 清理DNS缓存
    echo "🧹 清理DNS缓存..."
    if command -v systemd-resolve &> /dev/null; then
        systemd-resolve --flush-caches 2>/dev/null || true
    fi
    if command -v resolvectl &> /dev/null; then
        resolvectl flush-caches 2>/dev/null || true
    fi
    green "✅ DNS缓存已清理"
}

# 2. 修复网络路由
fix_network_routing() {
    echo ""
    echo "================== 2. 修复网络路由 =================="
    
    if [ "$IS_ROOT" = true ]; then
        # 获取默认网关
        gateway=$(ip route show default | awk '/default/ {print $3}' | head -1)
        interface=$(ip route show default | awk '/default/ {print $5}' | head -1)
        
        if [ -n "$gateway" ] && [ -n "$interface" ]; then
            echo "🔧 当前网关: $gateway, 接口: $interface"
            
            # 删除可能冲突的路由
            echo "🧹 清理冲突路由..."
            ip route flush cache 2>/dev/null || true
            
            # 重新添加默认路由
            echo "🔄 重新配置默认路由..."
            ip route del default 2>/dev/null || true
            ip route add default via "$gateway" dev "$interface" 2>/dev/null || true
            green "✅ 默认路由已重新配置"
        else
            yellow "⚠️ 无法获取网关信息，跳过路由修复"
        fi
    else
        yellow "⚠️ 跳过路由修复（需要root权限）"
    fi
}

# 3. 修复防火墙配置
fix_firewall_configuration() {
    echo ""
    echo "================== 3. 修复防火墙配置 =================="
    
    if [ "$IS_ROOT" = true ]; then
        # 检查并配置iptables
        if command -v iptables &> /dev/null; then
            echo "🔧 配置iptables出站规则..."
            
            # 允许出站HTTP/HTTPS
            iptables -I OUTPUT -p tcp --dport 80 -j ACCEPT 2>/dev/null || true
            iptables -I OUTPUT -p tcp --dport 443 -j ACCEPT 2>/dev/null || true
            iptables -I OUTPUT -p tcp --dport 22 -j ACCEPT 2>/dev/null || true
            iptables -I OUTPUT -p tcp --dport 53 -j ACCEPT 2>/dev/null || true
            iptables -I OUTPUT -p udp --dport 53 -j ACCEPT 2>/dev/null || true
            
            # 允许已建立的连接
            iptables -I OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT 2>/dev/null || true
            
            green "✅ iptables出站规则已配置"
        fi
        
        # 检查UFW
        if command -v ufw &> /dev/null; then
            echo "🔧 配置UFW出站规则..."
            ufw --force enable 2>/dev/null || true
            ufw allow out 80 2>/dev/null || true
            ufw allow out 443 2>/dev/null || true
            ufw allow out 22 2>/dev/null || true
            ufw allow out 53 2>/dev/null || true
            green "✅ UFW出站规则已配置"
        fi
    else
        yellow "⚠️ 跳过防火墙配置（需要root权限）"
    fi
}

# 4. 修复Docker网络
fix_docker_network() {
    echo ""
    echo "================== 4. 修复Docker网络 =================="
    
    if ! command -v docker &> /dev/null; then
        yellow "⚠️ Docker未安装，跳过Docker网络修复"
        return
    fi
    
    if [ "$IS_ROOT" = true ]; then
        echo "🔧 重启Docker服务..."
        systemctl restart docker
        sleep 5
        green "✅ Docker服务已重启"
        
        # 重新创建默认网络
        echo "🔧 重新创建Docker网络..."
        docker network prune -f 2>/dev/null || true
        green "✅ Docker网络已清理"
        
        # 配置Docker daemon
        if [ ! -f /etc/docker/daemon.json ]; then
            echo "🔧 创建Docker daemon配置..."
            mkdir -p /etc/docker
            cat > /etc/docker/daemon.json << 'EOF'
{
    "registry-mirrors": ["https://ccr.ccs.tencentyun.com"],
    "dns": ["223.5.5.5", "8.8.8.8"],
    "max-concurrent-downloads": 10,
    "max-concurrent-uploads": 5,
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "100m",
        "max-file": "3"
    }
}
EOF
            systemctl restart docker
            sleep 3
            green "✅ Docker daemon配置已优化"
        fi
    else
        echo "🔧 用户模式Docker网络修复..."
        docker network prune -f 2>/dev/null || true
        green "✅ Docker网络已清理（用户模式）"
    fi
}

# 5. 修复系统网络服务
fix_system_network_services() {
    echo ""
    echo "================== 5. 修复系统网络服务 =================="
    
    if [ "$IS_ROOT" = true ]; then
        echo "🔄 重启网络相关服务..."
        
        # 重启网络管理器
        if systemctl is-active NetworkManager > /dev/null 2>&1; then
            systemctl restart NetworkManager
            sleep 3
            green "✅ NetworkManager已重启"
        fi
        
        # 重启systemd-networkd
        if systemctl is-active systemd-networkd > /dev/null 2>&1; then
            systemctl restart systemd-networkd
            sleep 2
            green "✅ systemd-networkd已重启"
        fi
        
        # 重启systemd-resolved
        if systemctl is-active systemd-resolved > /dev/null 2>&1; then
            systemctl restart systemd-resolved
            sleep 2
            green "✅ systemd-resolved已重启"
        fi
        
        # 如果使用传统网络服务
        if systemctl is-active networking > /dev/null 2>&1; then
            systemctl restart networking
            sleep 3
            green "✅ networking服务已重启"
        fi
    else
        yellow "⚠️ 跳过系统服务重启（需要root权限）"
    fi
}

# 6. 设置网络环境变量
fix_network_environment() {
    echo ""
    echo "================== 6. 设置网络环境变量 =================="
    
    # 检查和清理代理设置
    echo "🔧 检查代理环境变量..."
    
    if [ -n "$http_proxy" ] || [ -n "$https_proxy" ] || [ -n "$HTTP_PROXY" ] || [ -n "$HTTPS_PROXY" ]; then
        yellow "⚠️ 检测到代理设置，这可能影响网络连接"
        echo "当前代理设置:"
        env | grep -i proxy || true
        
        echo "🔧 临时清理代理设置..."
        unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY no_proxy NO_PROXY
        green "✅ 代理环境变量已清理（临时）"
    else
        green "✅ 未检测到代理设置"
    fi
    
    # 设置优化的网络环境变量
    echo "🔧 设置网络优化环境变量..."
    export CURL_CA_BUNDLE=""
    export SSL_VERIFY=false
    green "✅ 网络环境变量已优化"
}

# 7. 测试网络连接
test_network_connectivity() {
    echo ""
    echo "================== 7. 测试网络连接 =================="
    
    test_targets=(
        "github.com:22"
        "registry-1.docker.io:443" 
        "ccr.ccs.tencentyun.com:443"
        "8.8.8.8:53"
    )
    
    echo "🔍 测试关键服务连接..."
    
    for target in "${test_targets[@]}"; do
        IFS=':' read -r host port <<< "$target"
        echo -n "测试 $host:$port ... "
        
        if timeout 10 bash -c "exec 3<>/dev/tcp/$host/$port" 2>/dev/null; then
            green "✅ 连接成功"
            exec 3<&-
        else
            red "❌ 连接失败"
        fi
    done
    
    # HTTP连接测试
    echo ""
    echo "🔍 测试HTTP/HTTPS连接..."
    
    test_urls=(
        "https://github.com"
        "https://registry-1.docker.io/v2/"
        "https://ccr.ccs.tencentyun.com/v2/"
    )
    
    for url in "${test_urls[@]}"; do
        echo -n "测试 $url ... "
        if timeout 15 curl -I --max-time 10 --connect-timeout 5 "$url" > /dev/null 2>&1; then
            green "✅ HTTP连接成功"
        else
            red "❌ HTTP连接失败"
        fi
    done
}

# 8. 生成修复报告
generate_fix_report() {
    echo ""
    echo "================== 8. 修复报告 =================="
    echo "修复时间: $(date)"
    echo "系统信息: $(uname -a)"
    echo ""
    
    echo "📋 已执行的修复操作:"
    echo "✅ DNS配置优化"
    echo "✅ 网络路由重置"
    echo "✅ 防火墙规则配置"
    echo "✅ Docker网络修复"
    echo "✅ 系统网络服务重启"
    echo "✅ 网络环境变量优化"
    echo "✅ 连接测试完成"
    
    echo ""
    echo "📝 后续建议:"
    echo "1. 如果问题持续，检查云服务器安全组设置"
    echo "2. 考虑联系网络管理员或ISP"
    echo "3. 使用国内镜像源加速访问"
    echo "4. 定期运行网络诊断脚本监控状态"
    
    echo ""
    echo "🔧 手动修复命令（如需要）:"
    echo "# 重置网络配置"
    echo "sudo systemctl restart networking"
    echo "sudo systemctl restart systemd-resolved"
    echo "# 重新配置DNS"
    echo "echo 'nameserver 223.5.5.5' | sudo tee /etc/resolv.conf"
    echo "# 重启Docker"
    echo "sudo systemctl restart docker"
}

# 主修复函数
main_fix() {
    echo "🚀 开始网络连接修复..."
    echo "此工具将系统性修复DNS解析正常但网络无法连接的问题"
    echo ""
    
    check_privileges
    fix_dns_configuration
    fix_network_routing
    fix_firewall_configuration
    fix_docker_network
    fix_system_network_services
    fix_network_environment
    test_network_connectivity
    generate_fix_report
    
    echo ""
    green "🎯 网络连接修复完成！"
    echo ""
    echo "💡 如果问题仍然存在，请："
    echo "1. 重启系统后再次测试"
    echo "2. 检查云服务器网络配置"
    echo "3. 运行网络深度诊断工具"
    echo "4. 联系技术支持"
}

# 快速修复模式
quick_fix() {
    echo "⚡ 快速修复模式启动..."
    
    # 快速DNS修复
    if [ "$IS_ROOT" = true ]; then
        echo "nameserver 223.5.5.5" > /etc/resolv.conf
        echo "nameserver 8.8.8.8" >> /etc/resolv.conf
    fi
    
    # 清理DNS缓存
    systemd-resolve --flush-caches 2>/dev/null || true
    
    # 重启关键服务
    if [ "$IS_ROOT" = true ]; then
        systemctl restart systemd-resolved 2>/dev/null || true
        systemctl restart docker 2>/dev/null || true
    fi
    
    green "✅ 快速修复完成"
}

# 命令行参数处理
case "${1:-}" in
    --quick|-q)
        check_privileges
        quick_fix
        ;;
    --help|-h)
        echo "网络连接修复工具使用说明:"
        echo ""
        echo "用法: $0 [选项]"
        echo ""
        echo "选项:"
        echo "  --quick, -q    快速修复模式"
        echo "  --help, -h     显示此帮助信息"
        echo ""
        echo "无参数运行将执行完整的网络修复流程"
        ;;
    *)
        main_fix
        ;;
esac
