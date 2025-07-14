#!/bin/bash
# 配置验证脚本 - 验证SSH认证和Docker镜像配置

set -e

# 颜色输出函数
red() { echo -e "\033[31m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
blue() { echo -e "\033[34m$1\033[0m"; }

echo "🔍 乐戈智小说 AI 编辑器 - 配置验证"
echo "========================================"

# 检查SSH配置
check_ssh_config() {
    echo ""
    echo "🔑 检查SSH配置..."
    
    local ssh_key="/root/.ssh/id_ed25519"
    local ssh_config="/root/.ssh/config"
    local issues=0
    
    # 检查SSH密钥
    if [ -f "$ssh_key" ]; then
        green "✅ SSH私钥存在"
        
        # 检查权限
        local perms=$(stat -c "%a" "$ssh_key")
        if [ "$perms" = "600" ]; then
            green "✅ SSH密钥权限正确 (600)"
        else
            red "❌ SSH密钥权限错误: $perms (应为600)"
            issues=$((issues + 1))
        fi
    else
        red "❌ SSH私钥不存在: $ssh_key"
        issues=$((issues + 1))
    fi
    
    # 检查SSH公钥
    if [ -f "${ssh_key}.pub" ]; then
        green "✅ SSH公钥存在"
        echo "📋 公钥内容:"
        cat "${ssh_key}.pub"
    else
        red "❌ SSH公钥不存在: ${ssh_key}.pub"
        issues=$((issues + 1))
    fi
    
    # 检查SSH配置文件
    if [ -f "$ssh_config" ]; then
        green "✅ SSH配置文件存在"
        if grep -q "github.com" "$ssh_config"; then
            green "✅ GitHub SSH配置已设置"
        else
            yellow "⚠️ GitHub SSH配置可能不完整"
        fi
    else
        yellow "⚠️ SSH配置文件不存在"
    fi
    
    return $issues
}

# 测试SSH连接
test_ssh_connection() {
    echo ""
    echo "🧪 测试SSH连接..."
    
    export GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i /root/.ssh/id_ed25519"
    
    if timeout 30 ssh -T -o ConnectTimeout=10 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i "/root/.ssh/id_ed25519" git@github.com 2>&1 | grep -q "successfully authenticated"; then
        green "✅ GitHub SSH连接成功"
        return 0
    else
        red "❌ GitHub SSH连接失败"
        echo "🔧 请检查:"
        echo "   1. SSH密钥是否已添加到GitHub账户"
        echo "   2. 网络连接是否正常"
        echo "   3. SSH密钥格式是否正确"
        return 1
    fi
}

# 测试仓库克隆
test_repo_clone() {
    echo ""
    echo "📦 测试仓库克隆..."
    
    local test_dir="/tmp/ssh-clone-test-$(date +%s)"
    local repo="git@github.com:lessstoryclassmate/legezhixiao.git"
    
    export GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i /root/.ssh/id_ed25519"
    
    mkdir -p "$test_dir"
    cd "$test_dir"
    
    if timeout 60 git clone "$repo" . 2>&1; then
        green "✅ 仓库克隆测试成功"
        local result=0
    else
        red "❌ 仓库克隆测试失败"
        local result=1
    fi
    
    # 清理测试目录
    cd /
    rm -rf "$test_dir"
    
    return $result
}

# 检查Docker配置
check_docker_config() {
    echo ""
    echo "🐳 检查Docker配置..."
    
    local docker_config="/etc/docker/daemon.json"
    local issues=0
    
    # 检查Docker服务
    if systemctl is-active --quiet docker; then
        green "✅ Docker服务运行正常"
    else
        red "❌ Docker服务未运行"
        issues=$((issues + 1))
    fi
    
    # 检查Docker配置文件
    if [ -f "$docker_config" ]; then
        green "✅ Docker配置文件存在"
        
        # 检查镜像配置
        if grep -q "ccr.ccs.tencentyun.com" "$docker_config"; then
            green "✅ 腾讯云镜像配置正确"
        else
            red "❌ 腾讯云镜像配置缺失"
            issues=$((issues + 1))
        fi
        
        echo "📋 当前Docker配置:"
        cat "$docker_config"
    else
        red "❌ Docker配置文件不存在"
        issues=$((issues + 1))
    fi
    
    return $issues
}

# 测试Docker镜像
test_docker_mirror() {
    echo ""
    echo "🧪 测试Docker镜像..."
    
    local test_image="ccr.ccs.tencentyun.com/library/nginx:latest"
    
    echo "尝试拉取测试镜像: $test_image"
    if timeout 120 docker pull "$test_image" 2>&1; then
        green "✅ 腾讯云镜像工作正常"
        
        # 清理测试镜像
        docker rmi "$test_image" &>/dev/null || true
        return 0
    else
        red "❌ 腾讯云镜像测试失败"
        return 1
    fi
}

# 检查网络连接
check_network() {
    echo ""
    echo "🌐 检查网络连接..."
    
    local issues=0
    
    # 测试基本网络连接
    if ping -c 3 8.8.8.8 &>/dev/null; then
        green "✅ 基本网络连接正常"
    else
        red "❌ 基本网络连接失败"
        issues=$((issues + 1))
    fi
    
    # 测试GitHub连接
    if curl -s --connect-timeout 10 https://github.com &>/dev/null; then
        green "✅ GitHub连接正常"
    else
        red "❌ GitHub连接失败"
        issues=$((issues + 1))
    fi
    
    # 测试腾讯云连接
    if curl -s --connect-timeout 10 https://ccr.ccs.tencentyun.com &>/dev/null; then
        green "✅ 腾讯云连接正常"
    else
        red "❌ 腾讯云连接失败"
        issues=$((issues + 1))
    fi
    
    return $issues
}

# 生成配置报告
generate_report() {
    echo ""
    echo "📋 配置验证报告"
    echo "=================="
    
    echo "时间: $(date)"
    echo "主机: $(hostname)"
    echo "IP地址: $(hostname -I | awk '{print $1}')"
    echo ""
    
    echo "SSH配置:"
    echo "  密钥路径: /root/.ssh/id_ed25519"
    echo "  配置文件: /root/.ssh/config"
    echo "  仓库地址: git@github.com:lessstoryclassmate/legezhixiao.git"
    echo ""
    
    echo "Docker配置:"
    echo "  配置文件: /etc/docker/daemon.json"
    echo "  镜像地址: ccr.ccs.tencentyun.com"
    echo "  服务状态: $(systemctl is-active docker 2>/dev/null || echo 'unknown')"
    echo ""
    
    echo "部署脚本:"
    echo "  统一部署: scripts/unified-deploy.sh"
    echo "  SSH配置: scripts/setup-github-ssh.sh"
    echo "  Docker配置: scripts/setup-tencent-docker.sh"
}

# 修复建议
suggest_fixes() {
    local total_issues=$1
    
    if [ $total_issues -gt 0 ]; then
        echo ""
        echo "🔧 修复建议"
        echo "============"
        echo ""
        echo "如果有配置问题，可以尝试以下修复步骤:"
        echo ""
        echo "1. 重新配置SSH认证:"
        echo "   ./scripts/setup-github-ssh.sh"
        echo ""
        echo "2. 重新配置Docker镜像:"
        echo "   ./scripts/setup-tencent-docker.sh"
        echo ""
        echo "3. 执行网络修复:"
        echo "   ./scripts/unified-deploy.sh --fix-network"
        echo ""
        echo "4. 完整重新配置:"
        echo "   ./scripts/unified-deploy.sh --setup-env"
    fi
}

# 主函数
main() {
    local total_issues=0
    
    # 执行各项检查
    check_network
    issues=$?
    total_issues=$((total_issues + issues))
    
    check_ssh_config
    issues=$?
    total_issues=$((total_issues + issues))
    
    test_ssh_connection
    issues=$?
    total_issues=$((total_issues + issues))
    
    test_repo_clone
    issues=$?
    total_issues=$((total_issues + issues))
    
    check_docker_config
    issues=$?
    total_issues=$((total_issues + issues))
    
    test_docker_mirror
    issues=$?
    total_issues=$((total_issues + issues))
    
    # 生成报告
    generate_report
    
    # 显示结果
    echo ""
    echo "========================================"
    if [ $total_issues -eq 0 ]; then
        green "🎉 所有配置验证通过！"
        echo ""
        green "✅ 系统已准备就绪，可以执行部署:"
        echo "   ./scripts/unified-deploy.sh --deploy"
    else
        red "❌ 发现 $total_issues 个配置问题"
        suggest_fixes $total_issues
    fi
    
    exit $total_issues
}

# 运行主函数
main "$@"
