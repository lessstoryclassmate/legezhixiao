#!/bin/bash
# 私有库访问验证脚本
# 验证SSH密钥是否正确配置以访问私有GitHub库

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

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}    私有库访问验证脚本${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 1. 基础环境检查
echo -e "${YELLOW}🔍 基础环境检查...${NC}"

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ 请使用root用户运行此脚本${NC}"
    exit 1
fi

# 检查必要命令
for cmd in git ssh ssh-keygen; do
    if ! command -v "$cmd" &> /dev/null; then
        echo -e "${RED}❌ 命令不存在: $cmd${NC}"
        exit 1
    fi
done

echo -e "${GREEN}✅ 基础环境检查通过${NC}"

# 2. SSH密钥文件检查
echo -e "${YELLOW}🔑 SSH密钥文件检查...${NC}"

if [ ! -f "$SSH_KEY_PATH" ]; then
    echo -e "${RED}❌ SSH私钥文件不存在: $SSH_KEY_PATH${NC}"
    echo ""
    echo -e "${YELLOW}📝 生成SSH密钥的步骤：${NC}"
    echo "1. 生成密钥对："
    echo "   ssh-keygen -t ed25519 -f $SSH_KEY_PATH -N ''"
    echo ""
    echo "2. 查看公钥："
    echo "   cat $SSH_PUB_KEY_PATH"
    echo ""
    echo "3. 将公钥添加到GitHub账户的SSH密钥中"
    exit 1
fi

echo -e "${GREEN}✅ SSH私钥文件存在: $SSH_KEY_PATH${NC}"

if [ ! -f "$SSH_PUB_KEY_PATH" ]; then
    echo -e "${RED}❌ SSH公钥文件不存在: $SSH_PUB_KEY_PATH${NC}"
    exit 1
fi

echo -e "${GREEN}✅ SSH公钥文件存在: $SSH_PUB_KEY_PATH${NC}"

# 3. 密钥权限检查
echo -e "${YELLOW}🔒 密钥权限检查...${NC}"

private_key_perms=$(stat -c "%a" "$SSH_KEY_PATH")
if [ "$private_key_perms" != "600" ]; then
    echo -e "${YELLOW}⚠️  修正私钥权限: $private_key_perms -> 600${NC}"
    chmod 600 "$SSH_KEY_PATH"
fi

public_key_perms=$(stat -c "%a" "$SSH_PUB_KEY_PATH")
if [ "$public_key_perms" != "644" ]; then
    echo -e "${YELLOW}⚠️  修正公钥权限: $public_key_perms -> 644${NC}"
    chmod 644 "$SSH_PUB_KEY_PATH"
fi

echo -e "${GREEN}✅ 密钥权限检查通过${NC}"

# 4. 密钥信息显示
echo -e "${YELLOW}📋 密钥信息...${NC}"

echo "🔐 私钥信息："
echo "  文件路径: $SSH_KEY_PATH"
echo "  文件权限: $(stat -c "%a" "$SSH_KEY_PATH")"
echo "  密钥类型: $(head -1 "$SSH_KEY_PATH" | cut -d' ' -f1)"
echo "  密钥指纹: $(ssh-keygen -l -f "$SSH_KEY_PATH" 2>/dev/null || echo '无法获取指纹')"

echo ""
echo "🔓 公钥信息："
echo "  文件路径: $SSH_PUB_KEY_PATH"
echo "  文件权限: $(stat -c "%a" "$SSH_PUB_KEY_PATH")"
echo "  公钥内容:"
echo "    $(cat "$SSH_PUB_KEY_PATH")"

# 5. SSH连接测试
echo ""
echo -e "${YELLOW}🔍 SSH连接测试...${NC}"

# 设置SSH命令
export GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $SSH_KEY_PATH"

echo "测试命令: ssh -T -i $SSH_KEY_PATH git@github.com"
echo ""

# 详细的SSH测试
SSH_TEST_OUTPUT=$(timeout 30 ssh -T -o ConnectTimeout=10 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i "$SSH_KEY_PATH" git@github.com 2>&1)
SSH_TEST_CODE=$?

echo "SSH测试输出:"
echo "$SSH_TEST_OUTPUT"
echo ""

if echo "$SSH_TEST_OUTPUT" | grep -q "successfully authenticated"; then
    echo -e "${GREEN}✅ SSH连接成功！您有GitHub访问权限${NC}"
    SSH_SUCCESS=true
else
    echo -e "${RED}❌ SSH连接失败${NC}"
    echo ""
    echo -e "${YELLOW}📝 可能的原因分析：${NC}"
    
    if echo "$SSH_TEST_OUTPUT" | grep -q "Permission denied"; then
        echo "1. 🔑 SSH密钥未添加到GitHub账户"
        echo "2. 🔑 使用了错误的SSH密钥"
        echo "3. 🔐 私有库访问权限不足"
    elif echo "$SSH_TEST_OUTPUT" | grep -q "Connection timed out"; then
        echo "1. 🌐 网络连接问题"
        echo "2. 🔥 防火墙阻止SSH连接"
        echo "3. 🌍 DNS解析问题"
    elif echo "$SSH_TEST_OUTPUT" | grep -q "Host key verification failed"; then
        echo "1. 🔐 SSH主机密钥验证失败"
        echo "2. 🔧 SSH配置问题"
    else
        echo "1. 🔍 未知错误，请检查网络和SSH配置"
    fi
    
    SSH_SUCCESS=false
fi

# 6. 私有库克隆测试
if [ "$SSH_SUCCESS" = true ]; then
    echo -e "${YELLOW}🔍 私有库克隆测试...${NC}"
    
    # 创建测试目录
    TEST_DIR="/tmp/private-repo-test-$(date +%s)"
    
    echo "克隆命令: git clone $SSH_REPO_URL $TEST_DIR"
    
    # 执行克隆测试
    CLONE_OUTPUT=$(timeout 60 git clone "$SSH_REPO_URL" "$TEST_DIR" 2>&1)
    CLONE_CODE=$?
    
    if [ $CLONE_CODE -eq 0 ] && [ -d "$TEST_DIR" ]; then
        echo -e "${GREEN}✅ 私有库克隆成功！${NC}"
        
        # 显示克隆统计信息
        if [ -d "$TEST_DIR" ]; then
            file_count=$(find "$TEST_DIR" -type f | wc -l)
            dir_size=$(du -sh "$TEST_DIR" 2>/dev/null | cut -f1)
            
            echo "  📁 克隆统计："
            echo "    目录: $TEST_DIR"
            echo "    文件数: $file_count"
            echo "    大小: $dir_size"
            
            # 显示部分文件结构
            echo "  📋 文件结构预览:"
            ls -la "$TEST_DIR" | head -10
        fi
        
        # 清理测试目录
        rm -rf "$TEST_DIR"
        
        echo -e "${GREEN}✅ 私有库访问权限验证成功！${NC}"
    else
        echo -e "${RED}❌ 私有库克隆失败${NC}"
        echo ""
        echo "克隆输出:"
        echo "$CLONE_OUTPUT"
        echo ""
        echo -e "${YELLOW}📝 可能的原因：${NC}"
        echo "1. 🔐 没有私有库的访问权限"
        echo "2. 🔑 SSH密钥配置错误"
        echo "3. 📍 库地址可能已更改"
        echo "4. 🌐 网络连接问题"
    fi
else
    echo -e "${YELLOW}⚠️  跳过私有库克隆测试（SSH连接失败）${NC}"
fi

# 7. 配置建议
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}    配置建议${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

if [ "$SSH_SUCCESS" = true ]; then
    echo -e "${GREEN}✅ 私有库SSH访问配置正确！${NC}"
    echo ""
    echo -e "${YELLOW}📝 建议：${NC}"
    echo "1. 定期检查SSH密钥的有效性"
    echo "2. 备份SSH密钥文件"
    echo "3. 确保服务器安全，保护私钥不被泄露"
    echo "4. 监控GitHub账户的SSH密钥活动"
else
    echo -e "${RED}❌ 私有库SSH访问配置存在问题${NC}"
    echo ""
    echo -e "${YELLOW}📝 解决步骤：${NC}"
    echo "1. 重新生成SSH密钥："
    echo "   ssh-keygen -t ed25519 -f $SSH_KEY_PATH -N ''"
    echo ""
    echo "2. 复制公钥到GitHub："
    echo "   cat $SSH_PUB_KEY_PATH"
    echo ""
    echo "3. 在GitHub中添加SSH密钥："
    echo "   - 登录GitHub"
    echo "   - 进入Settings > SSH and GPG keys"
    echo "   - 点击New SSH key"
    echo "   - 粘贴公钥内容"
    echo ""
    echo "4. 确认对私有库的访问权限"
    echo ""
    echo "5. 重新运行此验证脚本"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
