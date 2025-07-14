#!/bin/bash
# DNS解析修复脚本
# 自动检测并修复常见的DNS配置问题

set -e

echo "🔧 开始DNS解析修复..."

# 颜色输出函数
red() { echo -e "\033[31m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
blue() { echo -e "\033[34m$1\033[0m"; }

# 备份原始配置
backup_dns_config() {
    echo "📋 备份原始DNS配置..."
    if [ -f /etc/resolv.conf ]; then
        sudo cp /etc/resolv.conf /etc/resolv.conf.backup.$(date +%Y%m%d_%H%M%S)
        green "✅ 已备份 /etc/resolv.conf"
    fi
}

# 检测当前DNS状态
check_dns_status() {
    echo "🔍 检测当前DNS状态..."
    
    # 检查resolv.conf
    if [ ! -f /etc/resolv.conf ]; then
        red "❌ /etc/resolv.conf 不存在"
        return 1
    fi
    
    # 检查是否有nameserver
    if ! grep -q "^nameserver" /etc/resolv.conf; then
        red "❌ 没有配置DNS服务器"
        return 1
    fi
    
    # 测试DNS解析
    if nslookup github.com > /dev/null 2>&1; then
        green "✅ DNS解析正常"
        return 0
    else
        yellow "⚠️  DNS解析存在问题"
        return 1
    fi
}

# 配置可靠的DNS服务器
configure_reliable_dns() {
    echo "⚙️  配置可靠的DNS服务器..."
    
    # 中国大陆优化的DNS配置
    cat > /tmp/resolv.conf.new << EOF
# 阿里云DNS (中国大陆优化)
nameserver 223.5.5.5
nameserver 223.6.6.6

# Google DNS (全球通用)
nameserver 8.8.8.8
nameserver 8.8.4.4

# Cloudflare DNS (备用)
nameserver 1.1.1.1

# 搜索域和选项
options timeout:2 attempts:3 rotate single-request-reopen
EOF
    
    # 应用新配置
    sudo cp /tmp/resolv.conf.new /etc/resolv.conf
    sudo chmod 644 /etc/resolv.conf
    
    green "✅ 已配置多个可靠的DNS服务器"
}

# 测试DNS服务器可达性
test_dns_connectivity() {
    echo "🔗 测试DNS服务器连通性..."
    
    dns_servers=("223.5.5.5" "8.8.8.8" "1.1.1.1")
    working_dns=()
    
    for dns in "${dns_servers[@]}"; do
        if timeout 5 nc -u -z "$dns" 53 2>/dev/null; then
            green "✅ $dns 可达"
            working_dns+=("$dns")
        else
            red "❌ $dns 不可达"
        fi
    done
    
    if [ ${#working_dns[@]} -eq 0 ]; then
        red "❌ 所有DNS服务器都不可达，可能存在网络问题"
        return 1
    else
        green "✅ 有 ${#working_dns[@]} 个DNS服务器可用"
        return 0
    fi
}

# 处理systemd-resolved冲突
fix_systemd_resolved() {
    echo "🔧 处理systemd-resolved配置..."
    
    if systemctl is-active systemd-resolved &>/dev/null; then
        echo "检测到systemd-resolved正在运行"
        
        # 检查是否是符号链接
        if [ -L /etc/resolv.conf ]; then
            echo "resolv.conf是符号链接，转换为静态文件"
            sudo unlink /etc/resolv.conf
            configure_reliable_dns
        fi
        
        # 配置systemd-resolved使用可靠的DNS
        sudo mkdir -p /etc/systemd/resolved.conf.d
        cat > /tmp/dns-fix.conf << EOF
[Resolve]
DNS=223.5.5.5 8.8.8.8 1.1.1.1
FallbackDNS=114.114.114.114 8.8.4.4
Domains=~.
DNSSEC=allow-downgrade
DNSOverTLS=no
Cache=yes
EOF
        sudo cp /tmp/dns-fix.conf /etc/systemd/resolved.conf.d/dns-fix.conf
        
        sudo systemctl restart systemd-resolved
        green "✅ 已重新配置systemd-resolved"
    else
        echo "systemd-resolved未运行，使用静态配置"
        configure_reliable_dns
    fi
}

# 清理DNS缓存
flush_dns_cache() {
    echo "🧹 清理DNS缓存..."
    
    # 清理systemd-resolved缓存
    if systemctl is-active systemd-resolved &>/dev/null; then
        sudo systemctl restart systemd-resolved
        echo "已重启systemd-resolved"
    fi
    
    # 清理nscd缓存
    if command -v nscd &> /dev/null && pgrep nscd > /dev/null; then
        sudo nscd -i hosts
        echo "已清理nscd缓存"
    fi
    
    green "✅ DNS缓存已清理"
}

# 验证修复结果
verify_dns_fix() {
    echo "🧪 验证DNS修复结果..."
    
    test_domains=("github.com" "registry-1.docker.io" "ccr.ccs.tencentyun.com" "google.com")
    success_count=0
    
    for domain in "${test_domains[@]}"; do
        if nslookup "$domain" > /dev/null 2>&1; then
            green "✅ $domain 解析成功"
            ((success_count++))
        else
            red "❌ $domain 解析失败"
        fi
    done
    
    if [ $success_count -eq ${#test_domains[@]} ]; then
        green "🎉 所有测试域名解析成功！DNS修复完成"
        return 0
    elif [ $success_count -gt 0 ]; then
        yellow "⚠️  部分域名解析成功 ($success_count/${#test_domains[@]})，可能仍存在问题"
        return 1
    else
        red "❌ DNS修复失败，所有域名都无法解析"
        return 1
    fi
}

# Docker daemon DNS配置
configure_docker_dns() {
    echo "🐳 配置Docker DNS..."
    
    sudo mkdir -p /etc/docker
    cat > /tmp/docker-daemon.json << EOF
{
  "registry-mirrors": ["https://ccr.ccs.tencentyun.com"],
  "dns": ["223.5.5.5", "8.8.8.8", "1.1.1.1"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF
    
    if [ -f /etc/docker/daemon.json ]; then
        sudo cp /etc/docker/daemon.json /etc/docker/daemon.json.backup.$(date +%Y%m%d_%H%M%S)
    fi
    
    sudo cp /tmp/docker-daemon.json /etc/docker/daemon.json
    
    # 重启Docker服务
    if systemctl is-active docker &>/dev/null; then
        sudo systemctl restart docker
        green "✅ Docker DNS配置已更新并重启"
    else
        green "✅ Docker DNS配置已更新"
    fi
}

# 主修复流程
main() {
    echo "🚀 开始DNS修复流程..."
    echo ""
    
    # 1. 备份原始配置
    backup_dns_config
    
    # 2. 检查当前状态
    if check_dns_status; then
        echo "DNS已正常工作，进行优化配置..."
    fi
    
    # 3. 测试DNS连通性
    if ! test_dns_connectivity; then
        red "❌ DNS服务器连通性测试失败，可能存在网络问题"
        echo "请检查："
        echo "1. 网络连接是否正常"
        echo "2. 防火墙是否阻断UDP 53端口"
        echo "3. 是否在受限网络环境中"
        exit 1
    fi
    
    # 4. 修复systemd-resolved冲突
    fix_systemd_resolved
    
    # 5. 清理缓存
    flush_dns_cache
    
    # 6. 配置Docker DNS
    if command -v docker &> /dev/null; then
        configure_docker_dns
    fi
    
    echo ""
    echo "⏳ 等待DNS配置生效..."
    sleep 3
    
    # 7. 验证修复结果
    if verify_dns_fix; then
        echo ""
        green "🎉 DNS修复成功完成！"
        echo ""
        echo "📋 当前DNS配置:"
        cat /etc/resolv.conf
        echo ""
        echo "🔧 如果仍有问题，请运行 scripts/dns-diagnosis.sh 进行详细诊断"
    else
        echo ""
        red "❌ DNS修复可能不完整，请检查网络环境或运行详细诊断"
        echo "运行: bash scripts/dns-diagnosis.sh"
        exit 1
    fi
}

# 运行主流程
main "$@"
