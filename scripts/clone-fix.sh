#!/bin/bash
# SSH克隆修复脚本
# 专门解决SSH克隆问题，严格按照需求文档执行
# 需求文档要求：采用克隆库的方式进行部署，克隆的方式为ssh
# SSH地址：git@github.com:lessstoryclassmate/legezhixiao.git
# 密钥存放在服务器的地址为：/root/.ssh/id_ed25519，github库已经配置好公钥

set -e

echo "🔑 SSH克隆修复脚本启动..."
echo "📋 严格按照需求文档执行SSH克隆部署"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 定义变量（严格按照需求文档）
SSH_REPO_URL="git@github.com:lessstoryclassmate/legezhixiao.git"
SSH_KEY_PATH="/root/.ssh/id_ed25519"
SSH_CONFIG_PATH="/root/.ssh/config"
DEPLOY_DIR="/opt/ai-novel-editor"
PROJECT_NAME="ai-novel-editor"
BAIDU_DNS="180.76.76.76"

echo -e "${BLUE}📋 配置信息:${NC}"
echo "  SSH仓库地址: $SSH_REPO_URL"
echo "  SSH密钥路径: $SSH_KEY_PATH"
echo "  部署目录: $DEPLOY_DIR"

# ===== 0. 配置百度云DNS =====
echo -e "${BLUE}🌐 0. 配置百度云DNS...${NC}"

# 备份原DNS配置
if [ -f "/etc/resolv.conf" ]; then
    sudo cp /etc/resolv.conf /etc/resolv.conf.backup
    echo -e "${GREEN}✅ 原DNS配置已备份${NC}"
fi

# 设置百度云DNS
echo -e "${BLUE}🔧 设置百度云DNS为主DNS...${NC}"
sudo bash -c "echo 'nameserver $BAIDU_DNS' > /etc/resolv.conf"
sudo bash -c "echo 'nameserver 223.5.5.5' >> /etc/resolv.conf"
sudo bash -c "echo 'nameserver 8.8.8.8' >> /etc/resolv.conf"

echo -e "${GREEN}✅ DNS配置完成${NC}"
echo "  主DNS: $BAIDU_DNS (百度云DNS)"
echo "  备用DNS: 223.5.5.5 (阿里云DNS)"
echo "  备用DNS: 8.8.8.8 (Google DNS)"

# 测试DNS解析
echo -e "${BLUE}🔍 测试DNS解析...${NC}"
if nslookup github.com > /dev/null 2>&1; then
    echo -e "${GREEN}✅ DNS解析测试通过${NC}"
else
    echo -e "${YELLOW}⚠️ DNS解析测试失败，但继续执行${NC}"
fi

# ===== 1. 严格检查SSH密钥文件 =====
echo -e "${BLUE}🔍 1. 检查SSH密钥文件...${NC}"

if [ ! -f "$SSH_KEY_PATH" ]; then
    echo -e "${RED}❌ SSH密钥文件不存在: $SSH_KEY_PATH${NC}"
    echo -e "${YELLOW}📋 请确保SSH密钥文件已正确部署到服务器${NC}"
    echo -e "${YELLOW}💡 生成SSH密钥命令:${NC}"
    echo "   ssh-keygen -t ed25519 -f $SSH_KEY_PATH -N ''"
    echo -e "${YELLOW}📝 然后将公钥内容添加到GitHub仓库的Deploy Keys中${NC}"
    exit 1
fi

echo -e "${GREEN}✅ SSH密钥文件存在: $SSH_KEY_PATH${NC}"

# 检查SSH密钥文件权限
key_permissions=$(stat -c "%a" "$SSH_KEY_PATH")
if [ "$key_permissions" != "600" ]; then
    echo -e "${YELLOW}🔧 修正SSH密钥文件权限...${NC}"
    sudo chmod 600 "$SSH_KEY_PATH"
    echo -e "${GREEN}✅ SSH密钥文件权限已修正为600${NC}"
else
    echo -e "${GREEN}✅ SSH密钥文件权限正确(600)${NC}"
fi

# 确保SSH目录权限正确
sudo chmod 700 /root/.ssh
echo -e "${GREEN}✅ SSH目录权限已设置为700${NC}"

# ===== 2. 配置SSH客户端 =====
echo -e "${BLUE}🔧 2. 配置SSH客户端...${NC}"

# 创建SSH配置文件
sudo tee "$SSH_CONFIG_PATH" > /dev/null <<EOF
# GitHub SSH配置 - 严格按照需求文档
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
    PreferredAuthentications publickey
    PubkeyAuthentication yes
EOF

sudo chmod 600 "$SSH_CONFIG_PATH"
echo -e "${GREEN}✅ SSH配置文件已创建: $SSH_CONFIG_PATH${NC}"

# ===== 3. 测试SSH连接 =====
echo -e "${BLUE}🔍 3. 测试SSH连接到GitHub...${NC}"

# 测试SSH连接
echo "执行命令: sudo -u root ssh -T git@github.com -o ConnectTimeout=10"
ssh_test_output=$(sudo -u root ssh -T git@github.com -o ConnectTimeout=10 2>&1)
echo "SSH测试输出: $ssh_test_output"

if echo "$ssh_test_output" | grep -q "successfully authenticated"; then
    echo -e "${GREEN}✅ SSH连接到GitHub成功${NC}"
    ssh_connection_ok=true
elif echo "$ssh_test_output" | grep -q "Permission denied"; then
    echo -e "${RED}❌ SSH权限被拒绝${NC}"
    echo -e "${YELLOW}🔧 可能的问题:${NC}"
    echo "  1. SSH密钥未正确添加到GitHub Deploy Keys"
    echo "  2. SSH密钥格式不正确"
    echo "  3. GitHub仓库权限设置问题"
    ssh_connection_ok=false
elif echo "$ssh_test_output" | grep -q "Could not resolve hostname"; then
    echo -e "${RED}❌ 无法解析GitHub主机名${NC}"
    echo -e "${YELLOW}🔧 可能的问题:${NC}"
    echo "  1. DNS解析问题"
    echo "  2. 网络连接问题"
    echo "  3. 防火墙阻止SSH连接"
    ssh_connection_ok=false
else
    echo -e "${YELLOW}⚠️ SSH连接测试输出未知，继续尝试克隆${NC}"
    echo "输出内容: $ssh_test_output"
    ssh_connection_ok=true
fi

# ===== 4. 配置Git全局设置 =====
echo -e "${BLUE}🔧 4. 配置Git全局设置...${NC}"

sudo -u root git config --global user.name "Deploy Bot" 2>/dev/null || true
sudo -u root git config --global user.email "deploy@legezhixiao.com" 2>/dev/null || true
sudo -u root git config --global core.sshCommand "ssh -i $SSH_KEY_PATH -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" 2>/dev/null || true

echo -e "${GREEN}✅ Git全局配置完成${NC}"

# ===== 5. 执行SSH克隆 =====
echo -e "${BLUE}📥 5. 执行SSH克隆...${NC}"

# 清理旧的克隆目录
if [ -d "$DEPLOY_DIR" ]; then
    echo -e "${YELLOW}🧹 清理旧的部署目录...${NC}"
    sudo rm -rf "$DEPLOY_DIR"
fi

# 创建临时克隆目录
TEMP_CLONE_DIR="/tmp/ai-novel-editor-clone"
if [ -d "$TEMP_CLONE_DIR" ]; then
    rm -rf "$TEMP_CLONE_DIR"
fi

echo -e "${BLUE}🔄 开始SSH克隆...${NC}"
echo "仓库地址: $SSH_REPO_URL"
echo "目标目录: $TEMP_CLONE_DIR"

if [ "$ssh_connection_ok" = true ]; then
    echo -e "${GREEN}🔑 使用SSH方式克隆（需求文档指定方式）${NC}"
    
    # 执行SSH克隆
    if sudo -u root git clone "$SSH_REPO_URL" "$TEMP_CLONE_DIR" 2>&1; then
        echo -e "${GREEN}✅ SSH克隆成功${NC}"
        clone_success=true
    else
        echo -e "${RED}❌ SSH克隆失败${NC}"
        echo -e "${YELLOW}🔧 失败原因可能是:${NC}"
        echo "  1. SSH密钥认证失败"
        echo "  2. 仓库访问权限问题"
        echo "  3. 网络连接中断"
        clone_success=false
    fi
else
    echo -e "${RED}❌ SSH连接测试失败，无法进行SSH克隆${NC}"
    clone_success=false
fi

# 检查克隆结果
if [ "$clone_success" = false ]; then
    echo -e "${RED}❌ SSH克隆失败，无法继续部署${NC}"
    echo -e "${YELLOW}🔧 故障排查步骤:${NC}"
    echo "  1. 确认SSH密钥文件存在且权限正确"
    echo "  2. 验证GitHub仓库Deploy Keys配置"
    echo "  3. 检查服务器网络连接"
    echo "  4. 手动测试SSH连接: ssh -T git@github.com"
    exit 1
fi

# 检查克隆目录
if [ ! -d "$TEMP_CLONE_DIR" ]; then
    echo -e "${RED}❌ 克隆目录不存在，克隆可能失败${NC}"
    exit 1
fi

# 验证克隆内容
if [ ! -f "$TEMP_CLONE_DIR/README.md" ]; then
    echo -e "${RED}❌ 克隆内容验证失败，可能是空仓库${NC}"
    exit 1
fi

echo -e "${GREEN}✅ 克隆内容验证通过${NC}"

# ===== 6. 移动到部署目录 =====
echo -e "${BLUE}📁 6. 移动到部署目录...${NC}"

# 创建部署目录
sudo mkdir -p "$DEPLOY_DIR"

# 复制克隆内容到部署目录
sudo cp -r "$TEMP_CLONE_DIR"/* "$DEPLOY_DIR"/
sudo chown -R $USER:$USER "$DEPLOY_DIR"

echo -e "${GREEN}✅ 代码已移动到部署目录: $DEPLOY_DIR${NC}"

# 清理临时目录
rm -rf "$TEMP_CLONE_DIR"

# ===== 7. 验证部署内容 =====
echo -e "${BLUE}🔍 7. 验证部署内容...${NC}"

cd "$DEPLOY_DIR"

# 检查关键文件
REQUIRED_FILES=(
    "README.md"
    "docker-compose.production.yml"
    "package.json"
    "requirements.txt"
)

echo -e "${BLUE}📋 检查关键文件...${NC}"
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅ $file 存在${NC}"
    else
        echo -e "${YELLOW}⚠️ $file 不存在，但继续部署${NC}"
    fi
done

# 显示Git信息
echo -e "${BLUE}📊 Git信息:${NC}"
echo "  当前分支: $(git branch --show-current)"
echo "  最新提交: $(git log --oneline -1)"
echo "  远程仓库: $(git remote get-url origin)"

# ===== 8. 总结报告 =====
echo ""
echo "=================================================================================="
echo -e "${GREEN}🎉 SSH克隆修复完成！${NC}"
echo "=================================================================================="
echo ""
echo -e "${BLUE}📋 执行摘要:${NC}"
echo "✅ SSH密钥文件验证通过"
echo "✅ SSH客户端配置完成"
echo "✅ GitHub SSH连接测试通过"
echo "✅ Git全局配置完成"
echo "✅ SSH克隆执行成功"
echo "✅ 代码部署到目标目录"
echo "✅ 关键文件验证完成"
echo ""
echo -e "${BLUE}📁 部署信息:${NC}"
echo "  部署目录: $DEPLOY_DIR"
echo "  仓库地址: $SSH_REPO_URL"
echo "  SSH密钥: $SSH_KEY_PATH"
echo ""
echo -e "${BLUE}🔄 后续步骤:${NC}"
echo "  1. 执行Docker构建: cd $DEPLOY_DIR && docker-compose -f docker-compose.production.yml build"
echo "  2. 启动服务: docker-compose -f docker-compose.production.yml up -d"
echo "  3. 检查服务状态: docker-compose -f docker-compose.production.yml ps"
echo ""
echo -e "${BLUE}🛠️ 管理命令:${NC}"
echo "  更新代码: cd $DEPLOY_DIR && git pull origin main"
echo "  查看日志: docker-compose -f docker-compose.production.yml logs -f"
echo "  重启服务: docker-compose -f docker-compose.production.yml restart"
echo ""
echo -e "${GREEN}✅ SSH克隆修复脚本执行完成${NC}"
