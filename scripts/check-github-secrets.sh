#!/bin/bash
# GitHub Secrets 验证脚本
# 帮助检查工作流所需的 secrets 是否配置正确

echo "🔍 GitHub Secrets 配置验证"
echo "=========================="

# 从 .env.example 读取需要的变量
ENV_FILE=".env.example"

if [ ! -f "$ENV_FILE" ]; then
    echo "❌ .env.example 文件不存在"
    exit 1
fi

echo "📋 基于 .env.example 分析所需的 GitHub Secrets..."
echo ""

# 需要在GitHub Secrets中配置的变量
REQUIRED_SECRETS=(
    "SERVER_IP"
    "SERVER_USER" 
    "SERVER_SSH_KEY"
    "SILICONFLOW_API_KEY"
    "JWT_SECRET_KEY"
    "REDIS_PASSWORD"
)

OPTIONAL_SECRETS=(
    "MONGO_PASSWORD"
    "DATABASE_PASSWORD"
)

echo "🔑 必需的 GitHub Secrets:"
echo "========================"
for secret in "${REQUIRED_SECRETS[@]}"; do
    if grep -q "^$secret=" "$ENV_FILE"; then
        value=$(grep "^$secret=" "$ENV_FILE" | cut -d'=' -f2 | head -1)
        if [[ "$secret" == *"KEY"* ]] || [[ "$secret" == *"PASSWORD"* ]]; then
            echo "  ✅ $secret = [HIDDEN]"
        else
            echo "  ✅ $secret = $value"
        fi
    else
        echo "  ⚠️ $secret = (未在 .env.example 中找到)"
    fi
done

echo ""
echo "🔧 可选的 GitHub Secrets:"
echo "========================"
for secret in "${OPTIONAL_SECRETS[@]}"; do
    if grep -q "^$secret=" "$ENV_FILE"; then
        echo "  📋 $secret = [CONFIGURED]"
    else
        echo "  📋 $secret = (未配置)"
    fi
done

echo ""
echo "📝 GitHub Secrets 配置步骤:"
echo "=========================="
echo "1. 访问: https://github.com/lessstoryclassmate/legezhixiao/settings/secrets/actions"
echo "2. 点击 'New repository secret'"
echo "3. 添加以下 secrets:"
echo ""

for secret in "${REQUIRED_SECRETS[@]}"; do
    case $secret in
        "SERVER_IP")
            echo "   名称: $secret"
            echo "   值: 106.13.216.179"
            echo ""
            ;;
        "SERVER_USER")
            echo "   名称: $secret"
            echo "   值: root"
            echo ""
            ;;
        "SERVER_SSH_KEY")
            echo "   名称: $secret"
            echo "   值: [专门的GitHub Actions部署SSH私钥内容]"
            echo "   ⚠️  重要: 这应该是专门为GitHub Actions→服务器连接生成的密钥"
            echo "   ⚠️  不要使用服务器上的/root/.ssh/id_ed25519 (那是用于Git克隆的)"
            echo "   生成部署密钥: ssh-keygen -t ed25519 -C 'github-actions-deploy' -f ~/.ssh/deploy_key"
            echo "   获取私钥: cat ~/.ssh/deploy_key"
            echo "   添加公钥到服务器: cat ~/.ssh/deploy_key.pub >> /root/.ssh/authorized_keys"
            echo ""
            ;;
        "SILICONFLOW_API_KEY")
            echo "   名称: $secret"
            echo "   值: sk-mjithqmjwccqgffouexthbavtnvftwkqjludpcxhrmeztcib"
            echo ""
            ;;
        "JWT_SECRET_KEY")
            echo "   名称: $secret"
            echo "   值: [随机生成的安全字符串]"
            echo "   生成命令: openssl rand -base64 32"
            echo ""
            ;;
        "REDIS_PASSWORD")
            echo "   名称: $secret"
            echo "   值: Lekairong350702"
            echo ""
            ;;
    esac
done

echo "🔍 工作流文件检查:"
echo "=================="

# 检查工作流文件中使用的 secrets
WORKFLOW_DIR=".github/workflows"
if [ -d "$WORKFLOW_DIR" ]; then
    echo "检查 GitHub Actions 工作流中使用的 secrets..."
    echo ""
    
    for workflow in "$WORKFLOW_DIR"/*.yml; do
        if [ -f "$workflow" ]; then
            workflow_name=$(basename "$workflow")
            echo "📄 $workflow_name:"
            
            # 提取工作流中使用的 secrets
            secrets_used=$(grep -o 'secrets\.[A-Z_]*' "$workflow" 2>/dev/null | sed 's/secrets\.//' | sort -u)
            
            if [ -n "$secrets_used" ]; then
                while IFS= read -r secret; do
                    if [[ " ${REQUIRED_SECRETS[@]} " =~ " ${secret} " ]]; then
                        echo "   ✅ $secret (必需)"
                    elif [[ " ${OPTIONAL_SECRETS[@]} " =~ " ${secret} " ]]; then
                        echo "   📋 $secret (可选)"
                    else
                        echo "   ⚠️ $secret (未知，请检查)"
                    fi
                done <<< "$secrets_used"
            else
                echo "   📝 未使用 secrets"
            fi
            echo ""
        fi
    done
else
    echo "⚠️ .github/workflows 目录不存在"
fi

echo "🚀 部署验证:"
echo "============"
echo "配置完成后，请执行以下操作验证:"
echo ""
echo "1. 推送代码触发部署:"
echo "   git add ."
echo "   git commit -m 'fix: configure GitHub secrets'"
echo "   git push origin main"
echo ""
echo "2. 查看部署状态:"
echo "   访问: https://github.com/lessstoryclassmate/legezhixiao/actions"
echo ""
echo "3. 检查部署日志，确认没有 'missing server host' 错误"

echo ""
echo "✅ GitHub Secrets 配置指南已生成"
echo "📖 详细说明请查看: GITHUB_SECRETS_GUIDE.md"
