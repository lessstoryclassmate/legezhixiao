#!/bin/bash

# 快速启动示例 - SSH Docker安装脚本
# 此脚本展示如何配置和使用ssh-install-docker.sh

echo "=== SSH Docker安装脚本快速启动 ==="
echo ""

# 检查主脚本是否存在
MAIN_SCRIPT="./scripts/ssh-install-docker.sh"
if [[ ! -f "$MAIN_SCRIPT" ]]; then
    echo "错误：找不到主安装脚本 $MAIN_SCRIPT"
    exit 1
fi

# 检查脚本是否有执行权限
if [[ ! -x "$MAIN_SCRIPT" ]]; then
    echo "添加执行权限到主脚本..."
    chmod +x "$MAIN_SCRIPT"
fi

echo "使用前请确保："
echo "1. ✅ 已将您的RSA私钥替换到脚本中的 SSH_PRIVATE_KEY_CONTENT 变量"
echo "2. ✅ 对应的公钥已添加到目标服务器的 ~/.ssh/authorized_keys"
echo "3. ✅ 目标服务器用户具有sudo权限"
echo "4. ✅ 目标服务器运行Ubuntu系统"
echo ""

# 显示配置提示
echo "配置步骤："
echo "1. 编辑脚本： nano $MAIN_SCRIPT"
echo "2. 找到 SSH_PRIVATE_KEY_CONTENT 变量"
echo "3. 替换为您的实际RSA私钥内容"
echo ""

read -p "已完成配置并准备运行安装脚本? (y/N): " READY
if [[ "$READY" =~ ^[Yy]$ ]]; then
    echo ""
    echo "启动SSH Docker安装脚本..."
    exec "$MAIN_SCRIPT"
else
    echo ""
    echo "请按照上述步骤完成配置后重新运行："
    echo "  ./quick-start.sh"
    echo ""
    echo "详细使用说明请参考："
    echo "  docs/ssh-docker-install-guide.md"
fi
