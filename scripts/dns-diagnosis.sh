#!/bin/bash
# DNS解析失败详细诊断脚本
# 全面排查DNS配置、网络连通性和解析问题

set -e

echo "🔍 DNS解析失败详细诊断开始..."
echo "时间: $(date)"
echo "主机: $(hostname)"
echo "用户: $(whoami)"
echo ""

# 颜色输出函数
red() { echo -e "\033[31m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
blue() { echo -e "\033[34m$1\033[0m"; }

# 1. 系统网络接口状态
echo "================== 1. 网络接口状态 =================="
if command -v ip &> /dev/null; then
    echo "网络接口:"
    ip addr show | grep -E "^[0-9]+:|inet "
else
    echo "网络接口 (ifconfig):"
    ifconfig | grep -E "^[a-z]|inet "
fi

echo ""
echo "路由表:"
if command -v ip &> /dev/null; then
    ip route show
else
    route -n
fi

# 2. DNS配置检查
echo ""
echo "================== 2. DNS配置检查 =================="
echo "📄 /etc/resolv.conf 内容:"
if [ -f /etc/resolv.conf ]; then
    cat /etc/resolv.conf
    echo ""
    
    # 检查DNS服务器数量
    dns_count=$(grep -c "^nameserver" /etc/resolv.conf || echo "0")
    if [ "$dns_count" -eq 0 ]; then
        red "❌ 未找到DNS服务器配置"
    else
        green "✅ 找到 $dns_count 个DNS服务器"
    fi
else
    red "❌ /etc/resolv.conf 文件不存在"
fi

echo ""
echo "📄 /etc/hosts 关键内容:"
if [ -f /etc/hosts ]; then
    grep -v "^#" /etc/hosts | grep -v "^$" | head -10
else
    red "❌ /etc/hosts 文件不存在"
fi

# 3. DNS服务器可达性测试
echo ""
echo "================== 3. DNS服务器可达性测试 =================="
if [ -f /etc/resolv.conf ]; then
    while read -r line; do
        if [[ $line =~ ^nameserver[[:space:]]+([0-9.]+) ]]; then
            dns_server="${BASH_REMATCH[1]}"
            echo "测试DNS服务器: $dns_server"
            
            # 测试UDP 53端口
            if timeout 5 nc -u -z "$dns_server" 53 2>/dev/null; then
                green "✅ UDP 53端口可达"
            else
                red "❌ UDP 53端口不可达"
            fi
            
            # 测试TCP 53端口
            if timeout 5 nc -z "$dns_server" 53 2>/dev/null; then
                green "✅ TCP 53端口可达"
            else
                yellow "⚠️  TCP 53端口不可达"
            fi
            echo ""
        fi
    done < /etc/resolv.conf
fi

# 4. 常用公共DNS测试
echo "================== 4. 公共DNS服务器测试 =================="
public_dns_servers=(
    "223.5.5.5:阿里云DNS"
    "8.8.8.8:Google DNS"
    "114.114.114.114:114DNS"
    "1.1.1.1:Cloudflare DNS"
)

for dns_info in "${public_dns_servers[@]}"; do
    IFS=':' read -r dns_ip dns_name <<< "$dns_info"
    echo "测试 $dns_name ($dns_ip):"
    
    if timeout 5 nc -u -z "$dns_ip" 53 2>/dev/null; then
        green "✅ 可达"
    else
        red "❌ 不可达"
    fi
done

# 5. 域名解析测试
echo ""
echo "================== 5. 域名解析详细测试 =================="
test_domains=(
    "github.com"
    "registry-1.docker.io" 
    "mirror.baidubce.com"
    "google.com"
    "baidu.com"
)

for domain in "${test_domains[@]}"; do
    echo "解析域名: $domain"
    
    # nslookup测试
    if command -v nslookup &> /dev/null; then
        echo "🔍 nslookup 结果:"
        if nslookup "$domain" 2>&1 | grep -q "NXDOMAIN\|can't find\|No answer"; then
            red "❌ nslookup 解析失败"
        else
            result=$(nslookup "$domain" 2>/dev/null | grep "Address:" | tail -1 | awk '{print $2}')
            if [ -n "$result" ]; then
                green "✅ nslookup 解析成功: $result"
            else
                red "❌ nslookup 解析失败"
            fi
        fi
    fi
    
    # dig测试
    if command -v dig &> /dev/null; then
        echo "🔍 dig 结果:"
        dig_result=$(dig +short "$domain" 2>/dev/null | head -1)
        if [ -n "$dig_result" ]; then
            green "✅ dig 解析成功: $dig_result"
        else
            red "❌ dig 解析失败"
        fi
    fi
    
    # getent测试
    echo "🔍 getent 结果:"
    getent_result=$(getent hosts "$domain" 2>/dev/null | awk '{print $1}' | head -1)
    if [ -n "$getent_result" ]; then
        green "✅ getent 解析成功: $getent_result"
    else
        red "❌ getent 解析失败"
    fi
    
    echo ""
done

# 6. 防火墙和安全组检查
echo "================== 6. 防火墙检查 =================="
# 检查iptables
if command -v iptables &> /dev/null; then
    echo "iptables规则 (仅显示OUTPUT链):"
    iptables -L OUTPUT -n | head -10 || yellow "⚠️  无法读取iptables规则"
else
    yellow "⚠️  iptables 命令不可用"
fi

# 检查ufw
if command -v ufw &> /dev/null; then
    echo ""
    echo "UFW防火墙状态:"
    ufw status || yellow "⚠️  无法获取UFW状态"
fi

# 7. 系统DNS缓存
echo ""
echo "================== 7. DNS缓存检查 =================="
# 检查systemd-resolved
if systemctl is-active systemd-resolved &>/dev/null; then
    echo "systemd-resolved 状态: 运行中"
    echo "DNS统计信息:"
    systemctl status systemd-resolved --no-pager -l | head -5 || true
else
    echo "systemd-resolved 状态: 未运行"
fi

# 检查nscd
if command -v nscd &> /dev/null; then
    if pgrep nscd > /dev/null; then
        echo "nscd (Name Service Cache Daemon): 运行中"
    else
        echo "nscd: 未运行"
    fi
else
    echo "nscd: 未安装"
fi

# 8. 容器环境检查
echo ""
echo "================== 8. 容器环境检查 =================="
if [ -f /.dockerenv ]; then
    echo "🐳 检测到Docker容器环境"
    echo "容器内网络配置可能受主机或容器网络设置影响"
elif [ -f /proc/1/cgroup ] && grep -q docker /proc/1/cgroup; then
    echo "🐳 检测到容器化环境"
else
    echo "🖥️  物理机或虚拟机环境"
fi

# 9. 网络诊断建议
echo ""
echo "================== 9. 诊断建议 =================="
echo "🔧 常见DNS问题解决方案:"
echo "1. 检查 /etc/resolv.conf 是否有有效的nameserver"
echo "2. 测试更换DNS服务器: 223.5.5.5, 8.8.8.8"
echo "3. 检查防火墙是否阻断UDP 53端口"
echo "4. 重启网络服务: systemctl restart networking"
echo "5. 刷新DNS缓存: systemctl restart systemd-resolved"
echo "6. 检查网络连通性: ping 8.8.8.8"

echo ""
echo "🛠️  临时修复DNS的命令:"
echo "# 备份当前配置"
echo "sudo cp /etc/resolv.conf /etc/resolv.conf.backup"
echo ""
echo "# 使用阿里云DNS"
echo "echo 'nameserver 223.5.5.5' | sudo tee /etc/resolv.conf"
echo "echo 'nameserver 8.8.8.8' | sudo tee -a /etc/resolv.conf"

echo ""
green "🎯 DNS诊断完成！请根据上述结果分析具体问题。"
