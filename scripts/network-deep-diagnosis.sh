#!/bin/bash
# 深度网络连接故障诊断脚本
# 专门解决DNS解析正确但网络无法连接的问题

set -e

echo "🔍 开始深度网络连接故障诊断..."

# 颜色输出函数
red() { echo -e "\033[31m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
blue() { echo -e "\033[34m$1\033[0m"; }

# 测试目标域名和IP
test_targets=(
    "github.com:22"
    "registry-1.docker.io:443"
    "ccr.ccs.tencentyun.com:443"
    "google.com:80"
    "8.8.8.8:53"
    "223.5.5.5:53"
)

# 1. 基础网络环境检查
check_network_basics() {
    echo "================== 1. 基础网络环境检查 =================="
    
    # 网络接口状态
    echo "📋 网络接口状态:"
    if command -v ip &> /dev/null; then
        ip addr show | grep -E "^[0-9]+:|inet " | head -10
    else
        ifconfig | grep -E "^[a-z]|inet " | head -10
    fi
    
    echo ""
    echo "📋 默认路由:"
    if command -v ip &> /dev/null; then
        ip route show default
    else
        route -n | grep "^0.0.0.0"
    fi
    
    echo ""
    echo "📋 网关连通性测试:"
    gateway=$(ip route show default | awk '/default/ {print $3}' | head -1)
    if [ -n "$gateway" ]; then
        if ping -c 2 -W 3 "$gateway" > /dev/null 2>&1; then
            green "✅ 网关 $gateway 可达"
        else
            red "❌ 网关 $gateway 不可达"
        fi
    else
        yellow "⚠️ 无法获取默认网关"
    fi
}

# 2. DNS解析详细测试
test_dns_resolution() {
    echo ""
    echo "================== 2. DNS解析详细测试 =================="
    
    test_domains=("github.com" "registry-1.docker.io" "ccr.ccs.tencentyun.com" "google.com")
    
    for domain in "${test_domains[@]}"; do
        echo "🔍 测试域名: $domain"
        
        # nslookup测试
        if command -v nslookup &> /dev/null; then
            nslookup_result=$(nslookup "$domain" 2>/dev/null | grep "Address:" | tail -1 | awk '{print $2}')
            if [ -n "$nslookup_result" ]; then
                green "  ✅ nslookup: $nslookup_result"
            else
                red "  ❌ nslookup: 解析失败"
            fi
        fi
        
        # dig测试
        if command -v dig &> /dev/null; then
            dig_result=$(dig +short "$domain" A 2>/dev/null | head -1)
            if [ -n "$dig_result" ]; then
                green "  ✅ dig: $dig_result"
            else
                red "  ❌ dig: 解析失败"
            fi
        fi
        
        # 测试解析时间
        echo "  ⏱️ 解析时间测试:"
        time_result=$(time nslookup "$domain" 2>&1 | grep real || echo "无法测量")
        echo "    $time_result"
        
        echo ""
    done
}

# 3. TCP连接深度测试
test_tcp_connections() {
    echo "================== 3. TCP连接深度测试 =================="
    
    for target in "${test_targets[@]}"; do
        IFS=':' read -r host port <<< "$target"
        echo "🔗 测试连接: $host:$port"
        
        # 使用多种方法测试连接
        
        # 方法1: nc (netcat)
        if command -v nc &> /dev/null; then
            if timeout 5 nc -z "$host" "$port" 2>/dev/null; then
                green "  ✅ nc: 连接成功"
            else
                red "  ❌ nc: 连接失败"
            fi
        fi
        
        # 方法2: telnet
        if command -v telnet &> /dev/null; then
            if timeout 5 bash -c "echo | telnet $host $port" 2>/dev/null | grep -q "Connected"; then
                green "  ✅ telnet: 连接成功"
            else
                red "  ❌ telnet: 连接失败"
            fi
        fi
        
        # 方法3: bash内置TCP
        if timeout 5 bash -c "exec 3<>/dev/tcp/$host/$port" 2>/dev/null; then
            green "  ✅ bash-tcp: 连接成功"
            exec 3<&-
        else
            red "  ❌ bash-tcp: 连接失败"
        fi
        
        # 方法4: curl (仅HTTPS)
        if [ "$port" = "443" ] || [ "$port" = "80" ]; then
            protocol="http"
            [ "$port" = "443" ] && protocol="https"
            
            if timeout 10 curl -I --max-time 5 --connect-timeout 3 "${protocol}://${host}/" > /dev/null 2>&1; then
                green "  ✅ curl: HTTP连接成功"
            else
                red "  ❌ curl: HTTP连接失败"
            fi
        fi
        
        echo ""
    done
}

# 4. 网络层面故障分析
analyze_network_issues() {
    echo "================== 4. 网络层面故障分析 =================="
    
    # 检查MTU设置
    echo "📋 MTU设置检查:"
    if command -v ip &> /dev/null; then
        ip link show | grep mtu | head -5
    fi
    
    echo ""
    echo "📋 防火墙规则检查:"
    
    # iptables检查
    if command -v iptables &> /dev/null; then
        echo "iptables OUTPUT链:"
        iptables -L OUTPUT -n | head -10 2>/dev/null || echo "无法读取iptables规则"
    fi
    
    # ufw检查
    if command -v ufw &> /dev/null; then
        echo "UFW状态:"
        ufw status 2>/dev/null || echo "UFW不可用或未配置"
    fi
    
    echo ""
    echo "📋 网络统计信息:"
    if command -v netstat &> /dev/null; then
        echo "连接统计:"
        netstat -s | grep -E "(failed|error|timeout)" | head -5 || true
    fi
}

# 5. Docker网络特定检查
check_docker_network() {
    echo ""
    echo "================== 5. Docker网络特定检查 =================="
    
    if ! command -v docker &> /dev/null; then
        yellow "⚠️ Docker未安装，跳过Docker网络检查"
        return
    fi
    
    echo "📋 Docker网络列表:"
    docker network ls 2>/dev/null || echo "无法获取Docker网络信息"
    
    echo ""
    echo "📋 Docker daemon网络配置:"
    if [ -f /etc/docker/daemon.json ]; then
        echo "daemon.json存在:"
        cat /etc/docker/daemon.json | head -20
    else
        echo "daemon.json不存在"
    fi
    
    echo ""
    echo "📋 Docker网桥信息:"
    if command -v ip &> /dev/null; then
        ip addr show docker0 2>/dev/null || echo "docker0网桥不存在"
    fi
}

# 6. 系统资源和性能检查
check_system_resources() {
    echo ""
    echo "================== 6. 系统资源和性能检查 =================="
    
    echo "📋 CPU负载:"
    uptime
    
    echo ""
    echo "📋 内存使用:"
    free -h
    
    echo ""
    echo "📋 磁盘使用:"
    df -h | head -5
    
    echo ""
    echo "📋 网络连接数:"
    if command -v netstat &> /dev/null; then
        echo "当前连接数: $(netstat -an | grep ESTABLISHED | wc -l)"
        echo "监听端口数: $(netstat -tln | grep LISTEN | wc -l)"
    fi
    
    echo ""
    echo "📋 进程检查:"
    echo "高CPU进程:"
    ps aux --sort=-%cpu | head -5
}

# 7. 特定服务连接测试
test_specific_services() {
    echo ""
    echo "================== 7. 特定服务连接测试 =================="
    
    # GitHub连接测试
    echo "🔍 GitHub连接测试:"
    if timeout 10 ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        green "✅ GitHub SSH连接正常"
    else
        yellow "⚠️ GitHub SSH连接异常（可能需要配置SSH密钥）"
    fi
    
    # Docker Hub测试
    echo ""
    echo "🔍 Docker Hub连接测试:"
    if timeout 15 curl -I https://registry-1.docker.io/v2/ > /dev/null 2>&1; then
        green "✅ Docker Hub可访问"
    else
        red "❌ Docker Hub不可访问"
    fi
    
    # 腾讯云镜像测试
    echo ""
    echo "🔍 腾讯云镜像测试:"
    if timeout 15 curl -I https://ccr.ccs.tencentyun.com/v2/ > /dev/null 2>&1; then
        green "✅ 腾讯云镜像可访问"
    else
        red "❌ 腾讯云镜像不可访问"
    fi
}

# 8. 网络质量测试
test_network_quality() {
    echo ""
    echo "================== 8. 网络质量测试 =================="
    
    # 延迟测试
    echo "📊 网络延迟测试:"
    test_hosts=("8.8.8.8" "223.5.5.5" "github.com")
    
    for host in "${test_hosts[@]}"; do
        echo -n "$host: "
        ping_result=$(ping -c 3 -W 3 "$host" 2>/dev/null | grep "avg" | awk -F'/' '{print $5}' || echo "超时")
        if [ "$ping_result" != "超时" ]; then
            green "${ping_result}ms"
        else
            red "超时"
        fi
    done
    
    echo ""
    echo "📊 丢包率测试:"
    for host in "${test_hosts[@]}"; do
        echo -n "$host: "
        loss_rate=$(ping -c 10 -W 2 "$host" 2>/dev/null | grep "packet loss" | awk '{print $6}' || echo "100%")
        if [[ "$loss_rate" =~ "0%" ]]; then
            green "$loss_rate"
        else
            yellow "$loss_rate"
        fi
    done
}

# 9. 生成故障排除建议
generate_troubleshooting_advice() {
    echo ""
    echo "================== 9. 故障排除建议 =================="
    
    echo "🔧 基于诊断结果的建议:"
    echo ""
    
    echo "1. 如果DNS解析正常但TCP连接失败:"
    echo "   - 检查防火墙设置 (iptables, ufw)"
    echo "   - 验证路由表配置"
    echo "   - 检查网络代理设置"
    echo "   - 确认目标服务是否正常运行"
    echo ""
    
    echo "2. 如果特定端口无法访问:"
    echo "   - sudo ufw allow [端口号]"
    echo "   - iptables -I OUTPUT -p tcp --dport [端口号] -j ACCEPT"
    echo "   - 检查云服务器安全组设置"
    echo ""
    
    echo "3. 如果Docker相关连接失败:"
    echo "   - sudo systemctl restart docker"
    echo "   - docker system prune -f"
    echo "   - 检查 /etc/docker/daemon.json 配置"
    echo ""
    
    echo "4. 如果网络质量差:"
    echo "   - 更换DNS服务器"
    echo "   - 使用国内镜像源"
    echo "   - 检查网络运营商问题"
    echo ""
    
    echo "5. 紧急修复命令:"
    echo "   # 重置网络配置"
    echo "   sudo systemctl restart networking"
    echo "   sudo systemctl restart systemd-resolved"
    echo "   # 清理DNS缓存"
    echo "   sudo systemctl flush-dns 2>/dev/null || true"
    echo "   # 重启Docker"
    echo "   sudo systemctl restart docker"
}

# 10. 生成详细报告
generate_detailed_report() {
    echo ""
    echo "================== 10. 诊断报告摘要 =================="
    echo "诊断时间: $(date)"
    echo "系统信息: $(uname -a)"
    echo ""
    
    echo "📋 关键发现:"
    # 这里可以根据之前的测试结果生成智能分析
    
    echo "• DNS解析状态: $(nslookup github.com > /dev/null 2>&1 && echo "正常" || echo "异常")"
    echo "• 网关连通性: $(ping -c 1 -W 2 $(ip route show default | awk '/default/ {print $3}' | head -1) > /dev/null 2>&1 && echo "正常" || echo "异常")"
    echo "• Docker服务: $(systemctl is-active docker 2>/dev/null || echo "未知")"
    echo "• 防火墙状态: $(ufw status 2>/dev/null | grep -q "Status: active" && echo "启用" || echo "禁用/未知")"
    
    echo ""
    echo "📝 下一步行动:"
    echo "1. 根据上述建议进行相应修复"
    echo "2. 如问题持续，检查云服务器网络配置"
    echo "3. 联系网络管理员或云服务提供商"
    echo "4. 考虑使用国内镜像和加速服务"
}

# 主函数
main() {
    echo "🚀 开始深度网络连接故障诊断..."
    echo "此诊断将全面检查DNS、TCP连接、防火墙、Docker网络等"
    echo ""
    
    check_network_basics
    test_dns_resolution
    test_tcp_connections
    analyze_network_issues
    check_docker_network
    check_system_resources
    test_specific_services
    test_network_quality
    generate_troubleshooting_advice
    generate_detailed_report
    
    echo ""
    green "🎯 深度网络诊断完成！"
    echo ""
    echo "💡 如果问题仍然存在，请："
    echo "1. 保存此诊断报告"
    echo "2. 检查云服务器的网络安全组设置"
    echo "3. 联系云服务提供商技术支持"
    echo "4. 考虑更换网络环境或使用代理"
}

# 运行主函数
main "$@"
