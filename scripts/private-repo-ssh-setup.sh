#!/bin/bash
# 私有库SSH访问配置脚本
# 根据需求文档：私钥存放在服务器的地址为：/root/.ssh/id_ed25519，github库已经配置好公钥

# 设置颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置变量 - 严格按照需求文档
SSH_REPO_URL="git@github.com:lessstoryclassmate/legezhixiao.git"
SSH_KEY_PATH="/root/.ssh/id_ed25519"
SSH_PUB_KEY_PATH="/root/.ssh/id_ed25519.pub"
BAIDU_DNS="180.76.76.76"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}    私有库SSH访问配置脚本${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "📋 配置信息："
echo "  私有库地址: $SSH_REPO_URL"
echo "  SSH密钥路径: $SSH_KEY_PATH"
echo "  百度云DNS: $BAIDU_DNS"
echo ""

# 1. 配置DNS
echo -e "${YELLOW}🔧 配置百度云DNS...${NC}"
if ! grep -q "$BAIDU_DNS" /etc/resolv.conf; then
    echo "nameserver $BAIDU_DNS" | sudo tee /etc/resolv.conf > /dev/null
    echo -e "${GREEN}✅ DNS配置完成${NC}"
else
    echo -e "${GREEN}✅ DNS已配置${NC}"
fi

# 2. 检查SSH密钥是否存在
echo -e "${YELLOW}🔑 检查SSH密钥状态...${NC}"
if [ ! -f "$SSH_KEY_PATH" ]; then
    echo -e "${RED}❌ SSH密钥文件不存在: $SSH_KEY_PATH${NC}"
    echo ""
    echo -e "${YELLOW}📝 请按以下步骤生成SSH密钥：${NC}"
    echo "1. 生成SSH密钥："
    echo "   ssh-keygen -t ed25519 -f $SSH_KEY_PATH -N ''"
    echo ""
    echo "2. 将公钥添加到GitHub："
    echo "   cat $SSH_PUB_KEY_PATH"
    echo ""
    echo "3. 复制公钥内容到GitHub设置中的SSH密钥"
    echo "   GitHub -> Settings -> SSH and GPG keys -> New SSH key"
    echo ""
    echo -e "${RED}⚠️  由于库已变为私有，必须正确配置SSH密钥才能访问${NC}"
    exit 1
fi

echo -e "${GREEN}✅ SSH密钥文件存在: $SSH_KEY_PATH${NC}"

# 3. 检查密钥权限
echo -e "${YELLOW}🔒 检查密钥权限...${NC}"
key_permissions=$(stat -c "%a" "$SSH_KEY_PATH")
if [ "$key_permissions" != "600" ]; then
    echo -e "${YELLOW}⚠️  修正密钥权限: $key_permissions -> 600${NC}"
    sudo chmod 600 "$SSH_KEY_PATH"
    echo -e "${GREEN}✅ 权限修正完成${NC}"
else
    echo -e "${GREEN}✅ 密钥权限正确: $key_permissions${NC}"
fi

# 4. 配置SSH客户端
echo -e "${YELLOW}🔧 配置SSH客户端...${NC}"
SSH_CONFIG_DIR="/root/.ssh"
SSH_CONFIG_FILE="$SSH_CONFIG_DIR/config"

# 确保SSH配置目录存在
sudo mkdir -p "$SSH_CONFIG_DIR"

# 创建或更新SSH配置
sudo tee "$SSH_CONFIG_FILE" > /dev/null << EOF
# GitHub私有库SSH配置
Host github.com
    HostName github.com
    User git
    Port 22
    IdentityFile $SSH_KEY_PATH
    IdentitiesOnly yes
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    ServerAliveInterval 60
    ServerAliveCountMax 3
    TCPKeepAlive yes

# 全局SSH配置
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 3
EOF

sudo chmod 600 "$SSH_CONFIG_FILE"
echo -e "${GREEN}✅ SSH配置完成${NC}"

# 5. 测试SSH连接
echo -e "${YELLOW}🔍 测试SSH连接到GitHub...${NC}"
echo "测试命令: ssh -T git@github.com"
echo ""

# 设置Git SSH命令
export GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $SSH_KEY_PATH"

# 测试SSH连接
if timeout 30 ssh -T -o ConnectTimeout=10 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i "$SSH_KEY_PATH" git@github.com 2>&1 | grep -q "successfully authenticated"; then
    echo -e "${GREEN}✅ SSH连接成功！您可以访问私有库${NC}"
    SSH_SUCCESS=true
else
    echo -e "${RED}❌ SSH连接失败${NC}"
    echo ""
    echo -e "${YELLOW}🔧 调试信息：${NC}"
    timeout 10 ssh -T -o ConnectTimeout=10 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i "$SSH_KEY_PATH" git@github.com 2>&1 || true
    echo ""
    echo -e "${YELLOW}📝 可能的解决方案：${NC}"
    echo "1. 检查SSH密钥是否正确生成"
    echo "2. 确认公钥已添加到GitHub账户"
    echo "3. 验证私有库访问权限"
    echo "4. 检查网络连接"
    SSH_SUCCESS=false
fi

# 6. 配置Git全局设置
echo -e "${YELLOW}🔧 配置Git全局设置...${NC}"
sudo -u root git config --global core.sshCommand "ssh -i $SSH_KEY_PATH -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" 2>/dev/null || true
sudo -u root git config --global user.email "deploy@legezhixiao.com" 2>/dev/null || true
sudo -u root git config --global user.name "Deploy Bot" 2>/dev/null || true
echo -e "${GREEN}✅ Git全局配置完成${NC}"

# 7. 测试克隆私有库
if [ "$SSH_SUCCESS" = true ]; then
    echo -e "${YELLOW}🔍 测试克隆私有库...${NC}"
    
    # 创建测试目录
    TEST_DIR="/tmp/test-clone-$(date +%s)"
    
    echo "克隆命令: git clone $SSH_REPO_URL $TEST_DIR"
    
    if timeout 60 git clone "$SSH_REPO_URL" "$TEST_DIR" 2>/dev/null; then
        echo -e "${GREEN}✅ 私有库克隆成功！${NC}"
        
        # 显示克隆信息
        if [ -d "$TEST_DIR" ]; then
            echo "  克隆目录: $TEST_DIR"
            echo "  文件数量: $(find "$TEST_DIR" -type f | wc -l)"
            echo "  目录大小: $(du -sh "$TEST_DIR" | cut -f1)"
        fi
        
        # 清理测试目录
        rm -rf "$TEST_DIR"
    else
        echo -e "${RED}❌ 私有库克隆失败${NC}"
        echo ""
        echo -e "${YELLOW}📝 可能的原因：${NC}"
        echo "1. SSH密钥未正确添加到GitHub"
        echo "2. 没有私有库的访问权限"
        echo "3. 网络连接问题"
        echo "4. 库地址变更"
    fi
fi

# 8. 显示配置摘要
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}    私有库SSH配置摘要${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "📋 配置状态："
echo "  私有库地址: $SSH_REPO_URL"
echo "  SSH密钥路径: $SSH_KEY_PATH"
echo "  SSH配置文件: $SSH_CONFIG_FILE"
echo "  百度云DNS: $BAIDU_DNS"
echo ""

if [ "$SSH_SUCCESS" = true ]; then
    echo -e "${GREEN}✅ 私有库SSH访问配置成功！${NC}"
    echo ""
    echo -e "${YELLOW}📝 后续使用说明：${NC}"
    echo "1. 所有部署脚本将自动使用SSH方式访问私有库"
    echo "2. 如果遇到访问问题，请重新运行此脚本"
    echo "3. 定期检查SSH密钥的有效性"
else
    echo -e "${RED}❌ 私有库SSH访问配置失败${NC}"
    echo ""
    echo -e "${YELLOW}📝 请按以下步骤手动配置：${NC}"
    echo "1. 生成SSH密钥: ssh-keygen -t ed25519 -f $SSH_KEY_PATH -N ''"
    echo "2. 添加公钥到GitHub: cat $SSH_PUB_KEY_PATH"
    echo "3. 重新运行此脚本"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
