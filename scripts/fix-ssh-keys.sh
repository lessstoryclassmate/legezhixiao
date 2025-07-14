#!/bin/bash

# SSH密钥配置修复脚本
# 用于生成正确的GitHub Actions部署密钥

set -e

echo "🔧 SSH密钥配置修复工具"
echo "=========================="

# 检查是否有现有的部署密钥
DEPLOY_KEY_PATH="$HOME/.ssh/github_actions_deploy_key"

if [ -f "$DEPLOY_KEY_PATH" ]; then
    echo "⚠️  发现现有的部署密钥: $DEPLOY_KEY_PATH"
    read -p "是否要重新生成？(y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "使用现有密钥..."
    else
        echo "删除现有密钥并重新生成..."
        rm -f "$DEPLOY_KEY_PATH" "${DEPLOY_KEY_PATH}.pub"
    fi
fi

# 生成新的部署密钥（如果不存在）
if [ ! -f "$DEPLOY_KEY_PATH" ]; then
    echo "🔑 生成GitHub Actions部署密钥..."
    ssh-keygen -t ed25519 -C "github-actions-deploy" -f "$DEPLOY_KEY_PATH" -N ""
    echo "✅ 部署密钥已生成: $DEPLOY_KEY_PATH"
fi

echo ""
echo "📋 配置说明:"
echo "============"

echo ""
echo "1️⃣ GitHub Secrets 配置"
echo "---------------------"
echo "在GitHub仓库 Settings → Secrets and variables → Actions 中设置:"
echo ""
echo "SECRET名称: SERVER_SSH_KEY"
echo "SECRET值："
echo "-----BEGIN OPENSSH PRIVATE KEY-----"
cat "$DEPLOY_KEY_PATH" | grep -v "BEGIN\|END"
echo "-----END OPENSSH PRIVATE KEY-----"

echo ""
echo "2️⃣ 服务器authorized_keys配置"
echo "----------------------------"
echo "在您的服务器上执行以下命令:"
echo ""
echo "mkdir -p /root/.ssh"
echo "chmod 700 /root/.ssh"
echo "echo '$(cat "${DEPLOY_KEY_PATH}.pub")' >> /root/.ssh/authorized_keys"
echo "chmod 600 /root/.ssh/authorized_keys"

echo ""
echo "3️⃣ 服务器Git密钥检查"
echo "-------------------"
echo "确保服务器上有Git克隆密钥（与部署密钥不同）:"
echo ""
echo "# 在服务器上执行"
echo "if [ ! -f /root/.ssh/id_ed25519 ]; then"
echo "    ssh-keygen -t ed25519 -C 'server-git-access' -f /root/.ssh/id_ed25519"
echo "    echo '将以下公钥添加到GitHub账户SSH密钥设置:'"
echo "    cat /root/.ssh/id_ed25519.pub"
echo "fi"

echo ""
echo "4️⃣ 测试连接"
echo "-----------"
echo "测试GitHub Actions部署连接:"
echo "ssh -i $DEPLOY_KEY_PATH root@您的服务器IP"
echo ""
echo "测试服务器Git连接:"
echo "ssh -T git@github.com"

echo ""
echo "🎯 完成后，您的GitHub Actions部署应该能正常工作！"
echo ""
echo "📁 生成的文件:"
echo "   部署私钥: $DEPLOY_KEY_PATH"
echo "   部署公钥: ${DEPLOY_KEY_PATH}.pub"
