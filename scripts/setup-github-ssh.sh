#!/bin/bash
# SSH密钥配置脚本
# 配置GitHub SSH认证

set -e

# 颜色输出函数
red() { echo -e "\033[31m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
blue() { echo -e "\033[34m$1\033[0m"; }

echo "🔑 配置GitHub SSH认证..."

# SSH密钥路径
SSH_KEY_PATH="/root/.ssh/id_ed25519"
SSH_PUB_KEY_PATH="/root/.ssh/id_ed25519.pub"
SSH_CONFIG_PATH="/root/.ssh/config"

# 检查SSH密钥是否存在
check_ssh_key() {
    echo "🔍 检查SSH密钥..."
    
    if [ -f "$SSH_KEY_PATH" ]; then
        green "✅ SSH私钥存在: $SSH_KEY_PATH"
        
        # 检查密钥权限
        key_perms=$(stat -c "%a" "$SSH_KEY_PATH")
        if [ "$key_perms" != "600" ]; then
            echo "🔧 修正SSH密钥权限..."
            chmod 600 "$SSH_KEY_PATH"
            green "✅ SSH密钥权限已修正为600"
        fi
        
        return 0
    else
        red "❌ SSH密钥不存在: $SSH_KEY_PATH"
        return 1
    fi
}

# 配置SSH客户端
configure_ssh_client() {
    echo "🔧 配置SSH客户端..."
    
    # 确保.ssh目录存在且权限正确
    mkdir -p /root/.ssh
    chmod 700 /root/.ssh
    
    # 创建SSH配置文件
    cat > "$SSH_CONFIG_PATH" << EOF
# GitHub SSH配置
Host github.com
    HostName github.com
    User git
    IdentityFile $SSH_KEY_PATH
    IdentitiesOnly yes
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    AddKeysToAgent yes
    
# SSH连接优化
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 10
    TCPKeepAlive yes
    Compression yes
    ConnectTimeout 30
EOF
    
    chmod 600 "$SSH_CONFIG_PATH"
    green "✅ SSH配置文件已创建"
}

# 启动SSH Agent并添加密钥
setup_ssh_agent() {
    echo "🔑 配置SSH Agent..."
    
    # 启动SSH Agent（如果未运行）
    if [ -z "$SSH_AUTH_SOCK" ]; then
        eval "$(ssh-agent -s)"
        echo "✅ SSH Agent已启动"
    fi
    
    # 添加SSH密钥到Agent
    if ssh-add -l &>/dev/null; then
        echo "📋 当前SSH Agent中的密钥:"
        ssh-add -l
    fi
    
    # 添加我们的密钥
    if [ -f "$SSH_KEY_PATH" ]; then
        ssh-add "$SSH_KEY_PATH" 2>/dev/null || {
            echo "⚠️ 添加SSH密钥可能需要密码"
            ssh-add "$SSH_KEY_PATH"
        }
        green "✅ SSH密钥已添加到Agent"
    fi
}

# 测试GitHub连接
test_github_connection() {
    echo "🧪 测试GitHub SSH连接..."
    
    # 设置SSH选项以避免交互
    export GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $SSH_KEY_PATH"
    
    echo "尝试连接到GitHub..."
    if timeout 30 ssh -T -o ConnectTimeout=10 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i "$SSH_KEY_PATH" git@github.com 2>&1 | grep -q "successfully authenticated"; then
        green "✅ GitHub SSH连接成功"
        return 0
    else
        echo "📋 SSH连接测试输出:"
        timeout 10 ssh -T -o ConnectTimeout=10 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i "$SSH_KEY_PATH" git@github.com 2>&1 || true
        yellow "⚠️ GitHub SSH连接测试未完全成功，但可能仍可正常工作"
        return 1
    fi
}

# 添加GitHub到known_hosts
add_github_to_known_hosts() {
    echo "🔐 添加GitHub到known_hosts..."
    
    # 获取GitHub SSH公钥
    if ! grep -q "github.com" /root/.ssh/known_hosts 2>/dev/null; then
        ssh-keyscan -H github.com >> /root/.ssh/known_hosts 2>/dev/null || true
        green "✅ GitHub已添加到known_hosts"
    else
        echo "✅ GitHub已存在于known_hosts中"
    fi
}

# 测试仓库克隆
test_repo_clone() {
    echo "📦 测试仓库克隆..."
    
    local test_dir="/tmp/ssh-test-$(date +%s)"
    mkdir -p "$test_dir"
    cd "$test_dir"
    
    # 设置Git配置
    export GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $SSH_KEY_PATH"
    
    echo "测试克隆仓库..."
    if timeout 60 git clone git@github.com:lessstoryclassmate/legezhixiao.git . 2>&1; then
        green "✅ 仓库克隆测试成功"
        clone_success=true
    else
        red "❌ 仓库克隆测试失败"
        clone_success=false
    fi
    
    # 清理测试目录
    cd /
    rm -rf "$test_dir"
    
    return $( [ "$clone_success" = true ] && echo 0 || echo 1 )
}

# 生成SSH密钥使用说明
generate_ssh_instructions() {
    echo ""
    echo "================== SSH密钥配置说明 =================="
    echo ""
    
    if [ ! -f "$SSH_KEY_PATH" ]; then
        yellow "⚠️ SSH密钥不存在: $SSH_KEY_PATH"
        echo ""
        echo "请确保SSH密钥已存在于以下路径:"
        echo "   私钥: $SSH_KEY_PATH"
        echo "   公钥: $SSH_PUB_KEY_PATH"
        echo ""
        echo "如果公钥未添加到GitHub，请:"
        echo "   1. 查看公钥内容: cat $SSH_PUB_KEY_PATH"
        echo "   2. 访问 https://github.com/settings/ssh/new"
        echo "   3. 粘贴公钥内容"
        echo "   - 点击 'Add SSH key'"
        echo ""
        echo "4. 重新运行此脚本验证配置"
    else
        echo "📋 当前SSH密钥信息:"
        echo "私钥: $SSH_KEY_PATH"
        if [ -f "$SSH_PUB_KEY_PATH" ]; then
            echo "公钥: $SSH_PUB_KEY_PATH"
            echo ""
            echo "🔑 公钥内容 (添加到GitHub):"
            echo "----------------------------------------"
            cat "$SSH_PUB_KEY_PATH" 2>/dev/null || echo "无法读取公钥文件"
            echo "----------------------------------------"
        fi
    fi
    
    echo ""
    echo "📖 GitHub SSH密钥配置地址:"
    echo "https://github.com/settings/ssh/new"
}

# 主函数
main() {
    echo "🚀 开始SSH密钥配置..."
    echo ""
    
    # 检查SSH密钥
    if ! check_ssh_key; then
        generate_ssh_instructions
        exit 1
    fi
    
    # 配置SSH
    configure_ssh_client
    add_github_to_known_hosts
    setup_ssh_agent
    
    echo ""
    echo "🧪 进行连接测试..."
    
    # 测试连接
    if test_github_connection; then
        echo ""
        if test_repo_clone; then
            green "🎉 SSH配置完全成功！"
            echo ""
            echo "✅ 现在可以使用SSH方式克隆仓库:"
            echo "   git clone git@github.com:lessstoryclassmate/legezhixiao.git"
        else
            yellow "⚠️ SSH连接成功但克隆测试失败，请检查仓库权限"
        fi
    else
        yellow "⚠️ SSH连接测试未完全成功"
        echo ""
        echo "🔧 故障排除建议:"
        echo "1. 确认SSH密钥已添加到GitHub账户"
        echo "2. 检查服务器网络连接"
        echo "3. 验证SSH密钥格式正确"
        
        generate_ssh_instructions
    fi
    
    echo ""
    echo "📋 配置摘要:"
    echo "SSH密钥: $SSH_KEY_PATH"
    echo "SSH配置: $SSH_CONFIG_PATH"
    echo "仓库地址: git@github.com:lessstoryclassmate/legezhixiao.git"
}

# 运行主函数
main "$@"
