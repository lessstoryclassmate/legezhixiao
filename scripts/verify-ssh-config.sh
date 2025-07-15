#!/bin/bash
# SSH 配置验证脚本
# 专门用于验证服务器 SSH 私钥配置和 GitHub 连接
# 根据需求文档：私钥存放在 /root/.ssh/id_ed25519

set -e

echo "🔑 SSH 配置验证脚本"
echo "===================================================================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 根据需求文档设置 SSH 配置
SSH_KEY_PATH="/root/.ssh/id_ed25519"
GITHUB_REPO="git@github.com:lessstoryclassmate/legezhixiao.git"

echo -e "${BLUE}📋 验证 SSH 配置...${NC}"
echo "🔐 私钥路径: $SSH_KEY_PATH"
echo "📦 GitHub 仓库: $GITHUB_REPO"

# 检查 SSH 私钥文件
echo ""
echo -e "${BLUE}� 检查 SSH 私钥文件...${NC}"
if [ -f "$SSH_KEY_PATH" ]; then
    echo -e "${GREEN}✅ SSH 私钥文件存在: $SSH_KEY_PATH${NC}"
    
    # 检查文件权限
    perms=$(stat -c %a "$SSH_KEY_PATH")
    if [ "$perms" = "600" ]; then
        echo -e "${GREEN}✅ 文件权限正确: $perms${NC}"
    else
        echo -e "${YELLOW}⚠️ 文件权限需要调整: $perms -> 600${NC}"
        sudo chmod 600 "$SSH_KEY_PATH"
        echo -e "${GREEN}✅ 文件权限已修正${NC}"
    fi
    
    # 检查 .ssh 目录权限
    ssh_dir_perms=$(stat -c %a /root/.ssh)
    if [ "$ssh_dir_perms" = "700" ]; then
        echo -e "${GREEN}✅ .ssh 目录权限正确: $ssh_dir_perms${NC}"
    else
        echo -e "${YELLOW}⚠️ .ssh 目录权限需要调整: $ssh_dir_perms -> 700${NC}"
        sudo chmod 700 /root/.ssh
        echo -e "${GREEN}✅ .ssh 目录权限已修正${NC}"
    fi
    
    # 显示密钥信息
    echo ""
    echo -e "${BLUE}🔍 SSH 密钥信息:${NC}"
    echo "密钥类型: $(head -1 "$SSH_KEY_PATH" | cut -d' ' -f1)"
    echo "密钥指纹: $(ssh-keygen -l -f "$SSH_KEY_PATH" 2>/dev/null || echo '无法获取指纹')"
    
else
    echo -e "${RED}❌ SSH 私钥文件不存在: $SSH_KEY_PATH${NC}"
    echo ""
    echo -e "${YELLOW}💡 解决方案:${NC}"
    echo "1. 检查私钥文件是否已上传到服务器"
    echo "2. 确认文件路径是否正确"
    echo "3. 如果是首次部署，请先生成或上传 SSH 密钥"
    echo ""
    echo -e "${BLUE}📋 生成新密钥的命令:${NC}"
    echo "ssh-keygen -t ed25519 -f $SSH_KEY_PATH -N ''"
    echo "cat ${SSH_KEY_PATH}.pub  # 复制公钥到 GitHub"
    exit 1
fi

# 配置 SSH 客户端
echo ""
echo -e "${BLUE}🔧 配置 SSH 客户端...${NC}"
sudo tee /root/.ssh/config > /dev/null <<EOF
Host github.com
    HostName github.com
    User git
    IdentityFile $SSH_KEY_PATH
    IdentitiesOnly yes
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    ConnectTimeout 30
    ServerAliveInterval 60
    ServerAliveCountMax 3
EOF

sudo chmod 600 /root/.ssh/config
echo -e "${GREEN}✅ SSH 客户端配置完成${NC}"

# 测试 SSH 连接
echo ""
echo -e "${BLUE}🔍 测试 SSH 连接到 GitHub...${NC}"
ssh_test_output=$(sudo -u root ssh -T git@github.com -o ConnectTimeout=10 2>&1 || true)

if echo "$ssh_test_output" | grep -q "successfully authenticated"; then
    echo -e "${GREEN}✅ SSH 连接到 GitHub 成功${NC}"
    echo "📋 认证信息: $(echo "$ssh_test_output" | grep "successfully authenticated")"
    ssh_connection_ok=true
elif echo "$ssh_test_output" | grep -q "Permission denied"; then
    echo -e "${RED}❌ SSH 连接认证失败${NC}"
    echo "📋 错误信息: $ssh_test_output"
    echo ""
    echo -e "${YELLOW}💡 可能的原因:${NC}"
    echo "1. 公钥未正确添加到 GitHub 账户"
    echo "2. 私钥文件损坏或不匹配"
    echo "3. GitHub 账户权限问题"
    ssh_connection_ok=false
elif echo "$ssh_test_output" | grep -q "Could not resolve hostname"; then
    echo -e "${RED}❌ 无法解析 GitHub 主机名${NC}"
    echo "📋 错误信息: $ssh_test_output"
    echo ""
    echo -e "${YELLOW}💡 可能的原因:${NC}"
    echo "1. DNS 解析问题"
    echo "2. 网络连接问题"
    echo "3. 防火墙阻止连接"
    ssh_connection_ok=false
else
    echo -e "${YELLOW}⚠️ SSH 连接测试结果不明确${NC}"
    echo "📋 完整输出: $ssh_test_output"
    ssh_connection_ok=false
fi

# 测试仓库克隆
echo ""
echo -e "${BLUE}🔍 测试仓库克隆...${NC}"
if [ "$ssh_connection_ok" = true ]; then
    echo "📥 尝试克隆仓库..."
    cd /tmp
    rm -rf legezhixiao-ssh-test
    
    if sudo -u root git clone "$GITHUB_REPO" legezhixiao-ssh-test; then
        echo -e "${GREEN}✅ 仓库克隆成功${NC}"
        echo "📋 克隆信息:"
        echo "  - 仓库大小: $(du -sh legezhixiao-ssh-test | cut -f1)"
        echo "  - 最新提交: $(cd legezhixiao-ssh-test && git log --oneline -1)"
        
        # 清理测试克隆
        rm -rf legezhixiao-ssh-test
        echo -e "${GREEN}✅ 测试克隆已清理${NC}"
    else
        echo -e "${RED}❌ 仓库克隆失败${NC}"
        echo ""
        echo -e "${YELLOW}💡 故障排查建议:${NC}"
        echo "1. 检查仓库访问权限"
        echo "2. 确认 SSH 密钥对应的 GitHub 账户有仓库访问权限"
        echo "3. 检查仓库 URL 是否正确"
    fi
else
    echo -e "${YELLOW}⚠️ 跳过仓库克隆测试（SSH 连接失败）${NC}"
fi

# 配置 Git 全局设置
echo ""
echo -e "${BLUE}🔧 配置 Git 全局设置...${NC}"
sudo -u root git config --global user.name "Deploy Bot" 2>/dev/null || true
sudo -u root git config --global user.email "deploy@legezhixiao.com" 2>/dev/null || true
sudo -u root git config --global core.sshCommand "ssh -i $SSH_KEY_PATH -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" 2>/dev/null || true

echo -e "${GREEN}✅ Git 全局配置完成${NC}"

# 显示配置摘要
echo ""
echo "===================================================================================="
echo -e "${BLUE}📋 配置摘要:${NC}"
echo "🔐 SSH 私钥路径: $SSH_KEY_PATH"
echo "📦 GitHub 仓库: $GITHUB_REPO"
echo "🔧 SSH 客户端配置: /root/.ssh/config"
echo "⚙️ Git 配置: 已设置全局用户信息和 SSH 命令"

if [ "$ssh_connection_ok" = true ]; then
    echo ""
    echo -e "${GREEN}🎉 SSH 配置验证完成，所有测试通过！${NC}"
    echo ""
    echo -e "${BLUE}💡 现在可以使用以下命令进行部署:${NC}"
    echo "  ./scripts/quick-deploy-fixed.sh"
    exit 0
else
    echo ""
    echo -e "${RED}⚠️ SSH 配置验证失败，请解决上述问题后重试${NC}"
    echo ""
    echo -e "${BLUE}📞 获取帮助:${NC}"
    echo "1. 检查 GitHub 公钥配置"
    echo "2. 验证网络连接"
    echo "3. 确认仓库访问权限"
    exit 1
fi
        sudo chmod 600 "$SSH_KEY_PATH"
        echo -e "${GREEN}✅ SSH 密钥文件权限已修复为 600${NC}"
    fi
else
    echo -e "${RED}❌ SSH 密钥文件不存在: $SSH_KEY_PATH${NC}"
    echo -e "${YELLOW}💡 请确保密钥文件已正确部署到服务器${NC}"
    exit 1
fi

# 2. 创建/更新 SSH 配置
echo "🔧 配置 SSH 客户端..."
sudo mkdir -p /root/.ssh
sudo chmod 700 /root/.ssh

sudo tee "$SSH_CONFIG_PATH" > /dev/null <<EOF
Host github.com
    HostName github.com
    User git
    IdentityFile $SSH_KEY_PATH
    IdentitiesOnly yes
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    ConnectTimeout 30
    ServerAliveInterval 60
    ServerAliveCountMax 3
EOF

sudo chmod 600 "$SSH_CONFIG_PATH"
echo -e "${GREEN}✅ SSH 配置文件已创建/更新${NC}"

# 3. 测试 SSH 连接
echo "🔍 测试 SSH 连接到 GitHub..."
if sudo -u root ssh -T git@github.com -o ConnectTimeout=10 2>&1 | grep -q "successfully authenticated"; then
    echo -e "${GREEN}✅ SSH 连接到 GitHub 成功${NC}"
    ssh_works=true
else
    echo -e "${YELLOW}⚠️ SSH 连接测试未通过${NC}"
    ssh_works=false
fi

# 4. 测试仓库访问
echo "🔍 测试仓库访问权限..."
if sudo -u root git ls-remote "$GITHUB_REPO" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 仓库访问权限正常${NC}"
    repo_access=true
else
    echo -e "${YELLOW}⚠️ 仓库访问权限测试未通过${NC}"
    repo_access=false
fi

# 5. 配置 Git 全局设置
echo "🔧 配置 Git 全局设置..."
sudo -u root git config --global core.sshCommand "ssh -i $SSH_KEY_PATH -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
sudo -u root git config --global user.name "Deploy Bot" || true
sudo -u root git config --global user.email "deploy@legezhixiao.com" || true

# 6. 显示诊断信息
echo ""
echo "=================================="
echo "📊 SSH 配置诊断结果："
echo "=================================="

if [ "$ssh_works" = true ]; then
    echo -e "${GREEN}✅ SSH 认证正常${NC}"
else
    echo -e "${RED}❌ SSH 认证失败${NC}"
fi

if [ "$repo_access" = true ]; then
    echo -e "${GREEN}✅ 仓库访问正常${NC}"
else
    echo -e "${RED}❌ 仓库访问失败${NC}"
fi

echo ""
echo "💡 配置信息："
echo "  SSH 密钥路径: $SSH_KEY_PATH"
echo "  SSH 配置路径: $SSH_CONFIG_PATH"
echo "  GitHub 仓库: $GITHUB_REPO"

# 7. 故障排查建议
if [ "$ssh_works" = false ] || [ "$repo_access" = false ]; then
    echo ""
    echo "🔧 故障排查建议："
    echo "  1. 检查 SSH 密钥是否正确部署到服务器"
    echo "  2. 验证 GitHub 仓库是否已添加对应的公钥"
    echo "  3. 确认网络连接正常，可以访问 github.com"
    echo "  4. 检查 SSH 密钥格式是否正确"
    echo ""
    echo "🔍 手动测试命令："
    echo "  测试 SSH 连接: sudo -u root ssh -T git@github.com"
    echo "  测试仓库访问: sudo -u root git ls-remote $GITHUB_REPO"
fi

# 8. 返回结果
if [ "$ssh_works" = true ] && [ "$repo_access" = true ]; then
    echo ""
    echo -e "${GREEN}🎉 SSH 配置验证成功！可以进行 SSH 克隆部署。${NC}"
    exit 0
else
    echo ""
    echo -e "${YELLOW}⚠️ SSH 配置存在问题，建议检查后重试。${NC}"
    exit 1
fi
