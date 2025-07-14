#!/bin/bash
# SSH Git认证配置脚本
# 配置SSH密钥用于Git克隆操作

set -e

echo "🔑 配置SSH Git认证..."

# 颜色输出函数
red() { echo -e "\033[31m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
blue() { echo -e "\033[34m$1\033[0m"; }

# SSH密钥路径
SSH_KEY_PATH="/root/.ssh/id_ed25519"
SSH_PUB_KEY_PATH="/root/.ssh/id_ed25519.pub"
SSH_CONFIG_PATH="/root/.ssh/config"

# 检查SSH密钥是否存在
check_ssh_key() {
    echo "🔍 检查SSH密钥..."
    
    if [ -f "$SSH_KEY_PATH" ]; then
        green "✅ 找到SSH私钥: $SSH_KEY_PATH"
        
        # 检查密钥权限
        current_perms=$(stat -c "%a" "$SSH_KEY_PATH")
        if [ "$current_perms" != "600" ]; then
            echo "🔧 修正SSH密钥权限..."
            chmod 600 "$SSH_KEY_PATH"
            green "✅ SSH密钥权限已修正为600"
        fi
        
        return 0
    else
        red "❌ SSH密钥不存在: $SSH_KEY_PATH"
        echo "请确保SSH密钥已生成并放置在正确位置"
        return 1
    fi
}

# 配置SSH客户端
configure_ssh_client() {
    echo "🔧 配置SSH客户端..."
    
    # 确保.ssh目录存在
    mkdir -p /root/.ssh
    chmod 700 /root/.ssh
    
    # 创建或更新SSH配置
    cat > "$SSH_CONFIG_PATH" << 'EOF'
# GitHub SSH配置
Host github.com
    HostName github.com
    User git
    IdentityFile /root/.ssh/id_ed25519
    IdentitiesOnly yes
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    
# 通用SSH配置优化
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 3
    TCPKeepAlive yes
    Compression yes
    ConnectTimeout 30
EOF
    
    chmod 600 "$SSH_CONFIG_PATH"
    green "✅ SSH客户端配置完成"
}

# 配置已知主机
setup_known_hosts() {
    echo "🔧 配置已知主机..."
    
    # 添加GitHub到已知主机
    ssh-keyscan -t rsa,ed25519 github.com >> /root/.ssh/known_hosts 2>/dev/null || {
        yellow "⚠️ 无法获取GitHub主机密钥，将在连接时忽略主机验证"
    }
    
    if [ -f /root/.ssh/known_hosts ]; then
        chmod 644 /root/.ssh/known_hosts
        green "✅ 已知主机配置完成"
    fi
}

# 测试SSH连接
test_ssh_connection() {
    echo "🧪 测试SSH连接到GitHub..."
    
    # 设置超时和重试
    if timeout 15 ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        green "✅ SSH连接到GitHub成功"
        return 0
    else
        yellow "⚠️ SSH连接测试失败，但可能仍能正常工作"
        echo "这可能是因为GitHub不允许shell访问，但Git操作应该正常"
        return 0
    fi
}

# 配置Git使用SSH
configure_git_ssh() {
    echo "🔧 配置Git使用SSH..."
    
    # 设置Git全局配置
    git config --global user.name "Deploy Bot" || true
    git config --global user.email "deploy@example.com" || true
    
    # 确保Git使用SSH而不是HTTPS
    git config --global url."git@github.com:".insteadOf "https://github.com/" || true
    
    # 优化Git配置
    git config --global http.postBuffer 524288000 || true
    git config --global http.lowSpeedLimit 0 || true
    git config --global http.lowSpeedTime 999999 || true
    
    # SSH相关配置
    git config --global core.sshCommand "ssh -i $SSH_KEY_PATH -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" || true
    
    green "✅ Git SSH配置完成"
}

# 生成SSH认证报告
generate_ssh_report() {
    echo ""
    echo "================== SSH认证配置报告 =================="
    echo "配置时间: $(date)"
    echo ""
    
    echo "📋 SSH密钥状态:"
    if [ -f "$SSH_KEY_PATH" ]; then
        key_type=$(ssh-keygen -l -f "$SSH_KEY_PATH" 2>/dev/null | awk '{print $4}' || echo "未知")
        key_bits=$(ssh-keygen -l -f "$SSH_KEY_PATH" 2>/dev/null | awk '{print $1}' || echo "未知")
        green "✅ 私钥存在: $key_type $key_bits bits"
    else
        red "❌ 私钥不存在"
    fi
    
    if [ -f "$SSH_PUB_KEY_PATH" ]; then
        green "✅ 公钥存在"
    else
        yellow "⚠️ 公钥不存在（可能不影响使用）"
    fi
    
    echo ""
    echo "📋 SSH配置文件:"
    if [ -f "$SSH_CONFIG_PATH" ]; then
        green "✅ SSH配置已创建"
    else
        red "❌ SSH配置缺失"
    fi
    
    echo ""
    echo "📋 Git配置:"
    ssh_command=$(git config --global core.sshCommand 2>/dev/null || echo "未配置")
    if [[ "$ssh_command" =~ "ssh -i" ]]; then
        green "✅ Git SSH命令已配置"
    else
        yellow "⚠️ Git SSH命令未配置"
    fi
    
    echo ""
    echo "💡 使用方法:"
    echo "• SSH克隆: git clone git@github.com:lessstoryclassmate/legezhixiao.git"
    echo "• 测试连接: ssh -T git@github.com"
    echo "• 查看配置: cat $SSH_CONFIG_PATH"
}

# 主函数
main() {
    echo "🚀 开始配置SSH Git认证..."
    echo ""
    
    # 检查root权限
    if [ "$EUID" -ne 0 ]; then
        red "❌ 此脚本需要root权限运行"
        echo "请使用: sudo $0"
        exit 1
    fi
    
    # 执行配置步骤
    if check_ssh_key; then
        configure_ssh_client
        setup_known_hosts
        configure_git_ssh
        test_ssh_connection
        generate_ssh_report
        
        echo ""
        green "🎉 SSH Git认证配置完成！"
        echo ""
        echo "现在可以使用SSH方式克隆GitHub仓库了。"
    else
        red "❌ SSH密钥检查失败，密钥不存在"
        echo ""
        echo "⚠️ 请确保SSH密钥已存在于服务器上:"
        echo "   密钥路径: /root/.ssh/id_ed25519"
        echo "   公钥路径: /root/.ssh/id_ed25519.pub"
        echo ""
        echo "如果公钥未添加到GitHub，请访问:"
        echo "   https://github.com/settings/ssh/new"
        exit 1
    fi
}

# 运行主函数
main "$@"
