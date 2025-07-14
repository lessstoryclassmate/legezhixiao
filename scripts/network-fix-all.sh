#!/bin/bash
# 网络问题一键修复脚本
# 解决DNS、Docker镜像拉取、网络连通性等常见问题

set -e

echo "🚀 开始网络问题一键修复..."

# 颜色输出函数
red() { echo -e "\033[31m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
blue() { echo -e "\033[34m$1\033[0m"; }

# 1. DNS修复
fix_dns() {
    echo "🔧 第1步: 修复DNS配置..."
    
    # 备份原配置
    sudo cp /etc/resolv.conf /etc/resolv.conf.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
    
    # 配置可靠的DNS
    cat > /tmp/resolv.conf.fixed << EOF
# 阿里云DNS (中国大陆优化)
nameserver 223.5.5.5
nameserver 223.6.6.6

# Google DNS (全球通用)  
nameserver 8.8.8.8
nameserver 8.8.4.4

# 配置选项
options timeout:2 attempts:3 rotate single-request-reopen
EOF
    
    sudo cp /tmp/resolv.conf.fixed /etc/resolv.conf
    sudo chmod 644 /etc/resolv.conf
    
    # 重启DNS相关服务
    if systemctl is-active systemd-resolved &>/dev/null; then
        sudo systemctl restart systemd-resolved
    fi
    
    green "✅ DNS配置已修复"
}

# 2. Docker服务配置
fix_docker_service() {
    echo "🐳 第2步: 配置Docker腾讯云镜像加速..."
    
    sudo mkdir -p /etc/docker
    
    # 备份原配置
    if [ -f /etc/docker/daemon.json ]; then
        sudo cp /etc/docker/daemon.json /etc/docker/daemon.json.backup.$(date +%Y%m%d_%H%M%S)
    fi
    
    # 配置腾讯云镜像加速器
    cat > /tmp/docker-daemon.json << EOF
{
  "registry-mirrors": ["https://ccr.ccs.tencentyun.com"],
  "dns": ["223.5.5.5", "8.8.8.8"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "insecure-registries": []
}
EOF
    
    sudo cp /tmp/docker-daemon.json /etc/docker/daemon.json
    
    # 重启Docker
    if systemctl is-active docker &>/dev/null; then
        sudo systemctl restart docker
        echo "等待Docker重启..."
        sleep 5
    fi
    
    green "✅ Docker镜像源已配置"
}

# 3. 网络连通性测试
test_connectivity() {
    echo "🔗 第3步: 测试网络连通性..."
    
    # 测试基本网络
    if ping -c 2 8.8.8.8 > /dev/null 2>&1; then
        green "✅ 基本网络连通"
    else
        red "❌ 基本网络不通，请检查网络配置"
        return 1
    fi
    
    # 测试DNS解析
    test_domains=("github.com" "registry-1.docker.io")
    for domain in "${test_domains[@]}"; do
        if nslookup "$domain" > /dev/null 2>&1; then
            green "✅ $domain 解析成功"
        else
            yellow "⚠️ $domain 解析失败"
        fi
    done
    
    # 测试HTTPS连接
    if curl -s --connect-timeout 10 https://ccr.ccs.tencentyun.com/v2/ > /dev/null; then
        green "✅ 腾讯云镜像可访问"
    else
        yellow "⚠️ 腾讯云镜像访问异常"
    fi
}

# 4. Docker镜像拉取测试
test_docker_pull() {
    echo "🐳 第4步: 测试Docker镜像拉取..."
    
    if ! command -v docker &> /dev/null; then
        yellow "⚠️ Docker未安装，跳过镜像拉取测试"
        return 0
    fi
    
    # 测试拉取小镜像
    echo "拉取测试镜像..."
    if timeout 60 docker pull hello-world > /dev/null 2>&1; then
        green "✅ Docker镜像拉取成功"
        docker rmi hello-world > /dev/null 2>&1 || true
    else
        red "❌ Docker镜像拉取失败"
        echo "检查网络连接和Docker配置..."
    fi
}

# 5. 系统时间同步
fix_time_sync() {
    echo "⏰ 第5步: 修复系统时间同步..."
    
    # 检查时间同步服务
    if systemctl is-active systemd-timesyncd &>/dev/null; then
        sudo systemctl restart systemd-timesyncd
        green "✅ 时间同步服务已重启"
    elif command -v ntpd &> /dev/null; then
        sudo service ntp restart 2>/dev/null || true
        green "✅ NTP服务已重启"
    else
        # 手动同步时间
        if command -v ntpdate &> /dev/null; then
            sudo ntpdate -s time.nist.gov 2>/dev/null || \
            sudo ntpdate -s pool.ntp.org 2>/dev/null || true
            green "✅ 时间已手动同步"
        fi
    fi
}

# 6. 清理系统缓存
clean_cache() {
    echo "🧹 第6步: 清理系统缓存..."
    
    # 清理DNS缓存
    if systemctl is-active systemd-resolved &>/dev/null; then
        sudo systemctl restart systemd-resolved
    fi
    
    if command -v nscd &> /dev/null && pgrep nscd > /dev/null; then
        sudo nscd -i hosts
    fi
    
    # 清理Docker系统
    if command -v docker &> /dev/null; then
        docker system prune -f > /dev/null 2>&1 || true
    fi
    
    green "✅ 系统缓存已清理"
}

# 7. 生成修复报告
generate_report() {
    echo ""
    echo "================== 修复完成报告 =================="
    echo "修复时间: $(date)"
    echo ""
    
    echo "📋 当前DNS配置:"
    cat /etc/resolv.conf | grep nameserver
    echo ""
    
    echo "📋 Docker配置:"
    if [ -f /etc/docker/daemon.json ]; then
        echo "Docker daemon.json 已配置"
    fi
    
    echo ""
    echo "🧪 连通性测试:"
    
    # 快速测试
    if ping -c 1 8.8.8.8 > /dev/null 2>&1; then
        green "✅ 网络连通正常"
    else
        red "❌ 网络连通异常"
    fi
    
    if nslookup github.com > /dev/null 2>&1; then
        green "✅ DNS解析正常"
    else
        red "❌ DNS解析异常"
    fi
    
    if command -v docker &> /dev/null && docker info > /dev/null 2>&1; then
        green "✅ Docker服务正常"
    else
        yellow "⚠️ Docker服务异常或未安装"
    fi
    
    echo ""
    echo "🎯 修复建议:"
    echo "• 如果问题仍然存在，请运行: bash scripts/dns-diagnosis.sh"
    echo "• 检查防火墙设置: sudo ufw status"
    echo "• 检查网络接口: ip addr show"
    echo "• 重启网络服务: sudo systemctl restart networking"
}

# 主修复流程
main() {
    echo "🔧 开始网络问题一键修复流程..."
    echo "这将修复DNS、Docker镜像源、网络连通性等常见问题"
    echo ""
    
    # 检查权限
    if [ "$EUID" -eq 0 ]; then
        echo "检测到root权限，继续执行..."
    else
        echo "需要sudo权限来修复系统配置"
    fi
    
    # 执行修复步骤
    fix_dns
    fix_docker_service  
    fix_time_sync
    clean_cache
    
    echo ""
    echo "⏳ 等待配置生效..."
    sleep 3
    
    # 测试修复结果
    test_connectivity
    test_docker_pull
    
    # 生成报告
    generate_report
    
    echo ""
    green "🎉 网络问题一键修复完成！"
    echo ""
    yellow "⚠️ 注意: 如果在Docker容器中运行，某些修复可能需要重启容器才能生效"
}

# 执行主流程
main "$@"
