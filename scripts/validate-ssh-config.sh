#!/bin/bash
# SSH密钥配置验证脚本
# 确保所有脚本都使用正确的SSH密钥路径: /root/.ssh/id_ed25519

set -e

# 颜色输出函数
red() { echo -e "\033[31m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
blue() { echo -e "\033[34m$1\033[0m"; }

echo "🔑 SSH密钥配置验证"
echo "=================="

# 预期的SSH密钥路径
EXPECTED_SSH_KEY="/root/.ssh/id_ed25519"
REPO_SSH="git@github.com:lessstoryclassmate/legezhixiao.git"

echo "预期SSH密钥路径: $EXPECTED_SSH_KEY"
echo "仓库SSH地址: $REPO_SSH"
echo ""

# 检查关键脚本中的SSH配置
check_script_ssh_config() {
    local script_path="$1"
    local script_name=$(basename "$script_path")
    
    if [ ! -f "$script_path" ]; then
        red "❌ 脚本不存在: $script_path"
        return 1
    fi
    
    echo "📋 检查脚本: $script_name"
    
    # 检查是否定义了SSH_KEY_PATH
    if grep -q "SSH_KEY_PATH=\"/root/.ssh/id_ed25519\"" "$script_path"; then
        green "  ✅ SSH_KEY_PATH配置正确"
    else
        if grep -q "SSH_KEY_PATH=" "$script_path"; then
            red "  ❌ SSH_KEY_PATH配置错误"
            grep "SSH_KEY_PATH=" "$script_path" | head -3
        else
            yellow "  ⚠️ 未定义SSH_KEY_PATH"
        fi
    fi
    
    # 检查是否使用正确的仓库地址
    if grep -q "$REPO_SSH" "$script_path"; then
        green "  ✅ 仓库地址正确"
    else
        if grep -q "git@github.com" "$script_path"; then
            yellow "  ⚠️ 可能使用了其他仓库地址"
            grep "git@github.com" "$script_path" | head -2
        else
            red "  ❌ 未使用SSH仓库地址"
        fi
    fi
    
    # 检查Git SSH配置
    if grep -q "GIT_SSH_COMMAND.*-i.*ed25519" "$script_path"; then
        green "  ✅ Git SSH配置正确"
    else
        if grep -q "GIT_SSH_COMMAND" "$script_path"; then
            yellow "  ⚠️ Git SSH配置可能不正确"
            grep "GIT_SSH_COMMAND" "$script_path" | head -2
        else
            yellow "  ⚠️ 未配置GIT_SSH_COMMAND"
        fi
    fi
    
    echo ""
}

# 检查主要脚本
echo "🔍 检查主要部署脚本..."
echo ""

check_script_ssh_config "scripts/unified-deploy.sh"
check_script_ssh_config "scripts/setup-github-ssh.sh"
check_script_ssh_config "scripts/direct-deploy.sh"
check_script_ssh_config "scripts/one-click-install.sh"
check_script_ssh_config "scripts/quick-deploy.sh"
check_script_ssh_config "scripts/verify-config.sh"

# 检查环境配置文件
echo "📁 检查环境配置文件..."
echo ""

check_env_config() {
    local env_file="$1"
    local env_name=$(basename "$env_file")
    
    if [ ! -f "$env_file" ]; then
        yellow "⚠️ 文件不存在: $env_file"
        return
    fi
    
    echo "📋 检查配置: $env_name"
    
    if grep -q "id_ed25519" "$env_file"; then
        green "  ✅ 包含ed25519密钥配置"
    else
        if grep -q "id_rsa" "$env_file"; then
            red "  ❌ 仍使用旧的RSA密钥配置"
            grep "id_rsa" "$env_file"
        else
            yellow "  ⚠️ 未找到SSH密钥配置"
        fi
    fi
    echo ""
}

check_env_config ".env.example"
check_env_config ".env"

# 验证服务器上的SSH密钥
echo "🔐 验证服务器SSH密钥..."
echo ""

if [ -f "$EXPECTED_SSH_KEY" ]; then
    green "✅ SSH私钥存在: $EXPECTED_SSH_KEY"
    
    # 检查权限
    key_perms=$(stat -c "%a" "$EXPECTED_SSH_KEY")
    if [ "$key_perms" = "600" ]; then
        green "✅ SSH密钥权限正确: 600"
    else
        red "❌ SSH密钥权限错误: $key_perms (应为600)"
        echo "修复命令: chmod 600 $EXPECTED_SSH_KEY"
    fi
    
    # 检查公钥
    if [ -f "${EXPECTED_SSH_KEY}.pub" ]; then
        green "✅ SSH公钥存在: ${EXPECTED_SSH_KEY}.pub"
        echo "📋 公钥内容:"
        cat "${EXPECTED_SSH_KEY}.pub"
    else
        red "❌ SSH公钥不存在: ${EXPECTED_SSH_KEY}.pub"
    fi
else
    red "❌ SSH私钥不存在: $EXPECTED_SSH_KEY"
    echo ""
    echo "🔧 生成SSH密钥:"
    echo "  ssh-keygen -t ed25519 -f $EXPECTED_SSH_KEY -N ''"
    echo ""
    echo "📝 添加公钥到GitHub:"
    echo "  cat ${EXPECTED_SSH_KEY}.pub"
    echo "  # 访问 https://github.com/settings/ssh/new"
fi

echo ""

# 测试SSH连接
echo "🧪 测试SSH连接..."
echo ""

if [ -f "$EXPECTED_SSH_KEY" ]; then
    export GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $EXPECTED_SSH_KEY"
    
    if timeout 30 ssh -T -o ConnectTimeout=10 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i "$EXPECTED_SSH_KEY" git@github.com 2>&1 | grep -q "successfully authenticated"; then
        green "✅ GitHub SSH连接成功"
    else
        red "❌ GitHub SSH连接失败"
        echo "🔧 请检查:"
        echo "  1. SSH密钥是否已添加到GitHub账户"
        echo "  2. 网络连接是否正常"
        echo "  3. SSH密钥格式是否正确"
    fi
else
    yellow "⚠️ 跳过连接测试 (SSH密钥不存在)"
fi

echo ""

# 生成配置摘要
echo "📊 配置摘要"
echo "============"
echo ""
echo "SSH密钥路径: $EXPECTED_SSH_KEY"
echo "仓库地址: $REPO_SSH"
echo ""
echo "已验证的脚本:"
echo "  - scripts/unified-deploy.sh"
echo "  - scripts/setup-github-ssh.sh"
echo "  - scripts/direct-deploy.sh"
echo "  - scripts/one-click-install.sh"
echo "  - scripts/quick-deploy.sh"
echo "  - scripts/verify-config.sh"
echo ""
echo "环境配置文件:"
echo "  - .env.example"
echo "  - .env"
echo ""

# 提供快速修复建议
echo "🔧 快速配置命令"
echo "================"
echo ""
echo "# 生成SSH密钥"
echo "ssh-keygen -t ed25519 -f $EXPECTED_SSH_KEY -N ''"
echo ""
echo "# 显示公钥 (添加到GitHub)"
echo "cat ${EXPECTED_SSH_KEY}.pub"
echo ""
echo "# 测试连接"
echo "ssh -T git@github.com"
echo ""
echo "# 执行部署"
echo "./scripts/unified-deploy.sh --deploy"

echo ""
green "🎉 SSH配置验证完成！"
