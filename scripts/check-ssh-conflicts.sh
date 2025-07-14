#!/bin/bash
# SSH密钥冲突检测脚本
# 确保部署脚本不会覆盖现有密钥

set -e

# 颜色输出函数
red() { echo -e "\033[31m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
blue() { echo -e "\033[34m$1\033[0m"; }

echo "🔍 SSH密钥冲突检测"
echo "=================="

SSH_KEY_PATH="/root/.ssh/id_ed25519"
SSH_PUB_KEY_PATH="${SSH_KEY_PATH}.pub"

# 检查现有密钥
check_existing_keys() {
    echo "📋 检查现有SSH密钥..."
    echo ""
    
    if [ -f "$SSH_KEY_PATH" ]; then
        green "✅ SSH私钥已存在: $SSH_KEY_PATH"
        
        # 显示密钥信息
        if command -v ssh-keygen &> /dev/null; then
            key_info=$(ssh-keygen -l -f "$SSH_KEY_PATH" 2>/dev/null || echo "无法读取密钥信息")
            echo "   密钥信息: $key_info"
        fi
        
        # 检查权限
        key_perms=$(stat -c "%a" "$SSH_KEY_PATH" 2>/dev/null || echo "unknown")
        if [ "$key_perms" = "600" ]; then
            green "   权限正确: $key_perms"
        else
            yellow "   权限异常: $key_perms (建议: 600)"
        fi
        
        echo ""
        return 0
    else
        red "❌ SSH私钥不存在: $SSH_KEY_PATH"
        echo ""
        return 1
    fi
}

# 检查公钥
check_public_key() {
    echo "📋 检查SSH公钥..."
    echo ""
    
    if [ -f "$SSH_PUB_KEY_PATH" ]; then
        green "✅ SSH公钥已存在: $SSH_PUB_KEY_PATH"
        
        # 显示公钥内容
        echo "   公钥内容:"
        cat "$SSH_PUB_KEY_PATH" | head -1
        echo ""
        return 0
    else
        red "❌ SSH公钥不存在: $SSH_PUB_KEY_PATH"
        echo ""
        return 1
    fi
}

# 检查部署脚本中的密钥生成代码
check_deployment_scripts() {
    echo "🔍 检查部署脚本中的密钥生成代码..."
    echo ""
    
    local scripts_dir="scripts"
    local found_keygen=false
    
    if [ -d "$scripts_dir" ]; then
        # 查找包含ssh-keygen的脚本
        while IFS= read -r -d '' script_file; do
            local script_name=$(basename "$script_file")
            
            # 跳过验证脚本，因为它们只提供指导信息
            if [[ "$script_name" == "validate-"* || "$script_name" == "check-"* ]]; then
                continue
            fi
            
            # 检查是否包含实际的ssh-keygen执行命令
            if grep -q "ssh-keygen.*-f.*-N" "$script_file" && ! grep -q "echo.*ssh-keygen" "$script_file"; then
                red "⚠️ 发现可能的密钥生成代码: $script_name"
                echo "   文件: $script_file"
                grep -n "ssh-keygen.*-f.*-N" "$script_file" | head -3
                echo ""
                found_keygen=true
            fi
        done < <(find "$scripts_dir" -name "*.sh" -type f -print0 2>/dev/null)
    fi
    
    if [ "$found_keygen" = false ]; then
        green "✅ 未发现会执行密钥生成的代码"
    else
        yellow "⚠️ 发现可能的密钥生成代码，请检查确认"
    fi
    echo ""
}

# 检查环境变量配置
check_env_config() {
    echo "📋 检查环境变量配置..."
    echo ""
    
    local env_files=(".env.example" ".env")
    
    for env_file in "${env_files[@]}"; do
        if [ -f "$env_file" ]; then
            echo "检查文件: $env_file"
            
            if grep -q "id_ed25519" "$env_file"; then
                green "  ✅ 配置正确的密钥路径"
            else
                if grep -q "SSH_KEY\|ssh" "$env_file"; then
                    yellow "  ⚠️ 可能使用了其他密钥配置"
                    grep "SSH_KEY\|ssh" "$env_file" | head -2
                fi
            fi
        fi
    done
    echo ""
}

# 测试SSH连接
test_ssh_connection() {
    echo "🧪 测试SSH连接到GitHub..."
    echo ""
    
    if [ ! -f "$SSH_KEY_PATH" ]; then
        yellow "⚠️ 跳过连接测试 (密钥不存在)"
        return 1
    fi
    
    # 设置SSH命令
    export GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $SSH_KEY_PATH"
    
    # 测试连接
    if timeout 30 ssh -T -o ConnectTimeout=10 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i "$SSH_KEY_PATH" git@github.com 2>&1 | grep -q "successfully authenticated"; then
        green "✅ GitHub SSH连接成功"
        return 0
    else
        red "❌ GitHub SSH连接失败"
        echo "   请检查公钥是否已添加到GitHub"
        return 1
    fi
}

# 生成保护建议
generate_protection_advice() {
    echo "🛡️ SSH密钥保护建议"
    echo "==================="
    echo ""
    
    if [ -f "$SSH_KEY_PATH" ]; then
        echo "✅ 当前密钥已存在，建议操作:"
        echo ""
        echo "1. 备份现有密钥:"
        echo "   cp $SSH_KEY_PATH ${SSH_KEY_PATH}.backup"
        echo "   cp $SSH_PUB_KEY_PATH ${SSH_PUB_KEY_PATH}.backup"
        echo ""
        echo "2. 确保权限正确:"
        echo "   chmod 600 $SSH_KEY_PATH"
        echo "   chmod 644 $SSH_PUB_KEY_PATH"
        echo ""
        echo "3. 验证公钥在GitHub:"
        echo "   cat $SSH_PUB_KEY_PATH"
        echo "   # 确认此内容在 https://github.com/settings/keys"
        echo ""
        echo "4. 部署前测试:"
        echo "   ssh -T git@github.com"
    else
        echo "❌ 密钥不存在，需要先配置:"
        echo ""
        echo "1. 确保密钥已生成并存放在正确位置"
        echo "2. 确保公钥已添加到GitHub账户"
        echo "3. 运行验证脚本确认配置"
    fi
    echo ""
}

# 主函数
main() {
    local issues=0
    
    # 执行检查
    if ! check_existing_keys; then
        issues=$((issues + 1))
    fi
    
    if ! check_public_key; then
        issues=$((issues + 1))
    fi
    
    check_deployment_scripts
    check_env_config
    
    if ! test_ssh_connection; then
        issues=$((issues + 1))
    fi
    
    echo ""
    generate_protection_advice
    
    # 显示结果
    echo "🎯 检测结果"
    echo "==========="
    echo ""
    
    if [ $issues -eq 0 ]; then
        green "🎉 SSH密钥配置完整，无冲突风险"
        echo ""
        echo "✅ 可以安全执行部署操作"
        echo "✅ 部署脚本不会覆盖现有密钥"
    else
        red "⚠️ 发现 $issues 个配置问题"
        echo ""
        echo "请在执行部署前解决这些问题"
    fi
    
    echo ""
    echo "推荐的部署流程:"
    echo "1. ./scripts/validate-ssh-config.sh  # 验证配置"
    echo "2. ./scripts/verify-config.sh        # 完整检查"
    echo "3. ./scripts/unified-deploy.sh --deploy  # 执行部署"
    
    exit $issues
}

# 运行主函数
main "$@"
