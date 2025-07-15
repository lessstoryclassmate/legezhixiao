#!/bin/bash
# SSH 密钥验证和配置脚本
# 确保 GitHub SSH 访问正确配置

set -e

echo "🔑 验证 SSH 密钥配置..."

# 定义路径
SSH_KEY_PATH="/root/.ssh/id_ed25519"
SSH_CONFIG_PATH="/root/.ssh/config"
GITHUB_REPO="git@github.com:lessstoryclassmate/legezhixiao.git"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. 检查 SSH 密钥文件
echo "📋 检查 SSH 密钥文件..."
if [ -f "$SSH_KEY_PATH" ]; then
    echo -e "${GREEN}✅ SSH 密钥文件存在: $SSH_KEY_PATH${NC}"
    
    # 检查文件权限
    key_perms=$(stat -c "%a" "$SSH_KEY_PATH")
    if [ "$key_perms" = "600" ]; then
        echo -e "${GREEN}✅ SSH 密钥文件权限正确: 600${NC}"
    else
        echo -e "${YELLOW}⚠️ SSH 密钥文件权限不正确: $key_perms，正在修复...${NC}"
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
