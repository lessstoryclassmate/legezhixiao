#!/bin/bash

# GitHub Actions自动部署配置脚本
# 用于设置GitHub Secrets和环境

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo ""
log_info "=========================================="
log_info "  GitHub Actions自动部署配置向导"
log_info "=========================================="
echo ""

# 检查GitHub CLI
if ! command -v gh &> /dev/null; then
    log_error "GitHub CLI未安装，请先安装gh命令行工具"
    echo "安装方法: https://cli.github.com/"
    exit 1
fi

# 检查登录状态
if ! gh auth status &> /dev/null; then
    log_warning "请先登录GitHub CLI"
    gh auth login
fi

# 获取当前仓库信息
REPO_OWNER=$(gh repo view --json owner --jq '.owner.login')
REPO_NAME=$(gh repo view --json name --jq '.name')
REPO_FULL_NAME="$REPO_OWNER/$REPO_NAME"

log_info "当前仓库: $REPO_FULL_NAME"
echo ""

# 设置必需的Secrets
log_info "开始配置GitHub Secrets..."
echo ""

# AI服务配置
log_info "1. 配置AI服务密钥"
echo -n "请输入SiliconFlow API密钥: "
read -s SILICONFLOW_API_KEY
echo ""

if [[ -n "$SILICONFLOW_API_KEY" ]]; then
    gh secret set SILICONFLOW_API_KEY --body "$SILICONFLOW_API_KEY"
    gh secret set PRODUCTION_SILICONFLOW_API_KEY --body "$SILICONFLOW_API_KEY"
    log_success "AI服务密钥配置完成"
else
    log_error "AI服务密钥不能为空"
    exit 1
fi
echo ""

# 应用密钥配置
log_info "2. 配置应用密钥"
echo -n "请输入应用密钥 (留空将自动生成): "
read SECRET_KEY

if [[ -z "$SECRET_KEY" ]]; then
    SECRET_KEY=$(openssl rand -hex 32)
    log_info "已自动生成应用密钥"
fi

gh secret set SECRET_KEY --body "$SECRET_KEY"
gh secret set PRODUCTION_SECRET_KEY --body "$SECRET_KEY"
log_success "应用密钥配置完成"
echo ""

# 服务器配置
log_info "3. 配置部署服务器"
echo ""

# 预发布服务器
log_info "3.1 预发布服务器配置"
echo -n "预发布服务器IP/域名: "
read STAGING_HOST

echo -n "预发布服务器用户名 (默认: ubuntu): "
read STAGING_USER
STAGING_USER=${STAGING_USER:-ubuntu}

echo -n "预发布服务器SSH端口 (默认: 22): "
read STAGING_PORT
STAGING_PORT=${STAGING_PORT:-22}

echo -n "预发布服务器SSH私钥路径 (如: ~/.ssh/id_rsa): "
read SSH_KEY_PATH

if [[ -f "$SSH_KEY_PATH" ]]; then
    STAGING_SSH_KEY=$(cat "$SSH_KEY_PATH")
    gh secret set STAGING_HOST --body "$STAGING_HOST"
    gh secret set STAGING_USER --body "$STAGING_USER"
    gh secret set STAGING_PORT --body "$STAGING_PORT"
    gh secret set STAGING_SSH_KEY --body "$STAGING_SSH_KEY"
    log_success "预发布服务器配置完成"
else
    log_warning "SSH私钥文件不存在，跳过预发布服务器配置"
fi
echo ""

# 生产服务器
log_info "3.2 生产服务器配置"
echo -n "生产服务器IP/域名: "
read PRODUCTION_HOST

echo -n "生产服务器用户名 (默认: ubuntu): "
read PRODUCTION_USER
PRODUCTION_USER=${PRODUCTION_USER:-ubuntu}

echo -n "生产服务器SSH端口 (默认: 22): "
read PRODUCTION_PORT
PRODUCTION_PORT=${PRODUCTION_PORT:-22}

echo -n "生产服务器SSH私钥路径 (如: ~/.ssh/id_rsa_prod): "
read PROD_SSH_KEY_PATH

if [[ -f "$PROD_SSH_KEY_PATH" ]]; then
    PRODUCTION_SSH_KEY=$(cat "$PROD_SSH_KEY_PATH")
    gh secret set PRODUCTION_HOST --body "$PRODUCTION_HOST"
    gh secret set PRODUCTION_USER --body "$PRODUCTION_USER"
    gh secret set PRODUCTION_PORT --body "$PRODUCTION_PORT"
    gh secret set PRODUCTION_SSH_KEY --body "$PRODUCTION_SSH_KEY"
    log_success "生产服务器配置完成"
else
    log_warning "SSH私钥文件不存在，跳过生产服务器配置"
fi
echo ""

# 可选配置
log_info "4. 可选配置"
echo ""

# 数据库配置
echo -n "是否配置生产环境数据库 (MySQL)? (y/N): "
read configure_db

if [[ "$configure_db" =~ ^[Yy]$ ]]; then
    echo -n "数据库连接字符串 (mysql://user:pass@host:port/dbname): "
    read DATABASE_URL
    if [[ -n "$DATABASE_URL" ]]; then
        gh secret set PRODUCTION_DATABASE_URL --body "$DATABASE_URL"
        log_success "数据库配置完成"
    fi
fi
echo ""

# 通知配置
echo -n "是否配置Slack通知? (y/N): "
read configure_slack

if [[ "$configure_slack" =~ ^[Yy]$ ]]; then
    echo -n "Slack Webhook URL: "
    read SLACK_WEBHOOK
    if [[ -n "$SLACK_WEBHOOK" ]]; then
        gh secret set SLACK_WEBHOOK --body "$SLACK_WEBHOOK"
        log_success "Slack通知配置完成"
    fi
fi
echo ""

# 邮件通知配置
echo -n "是否配置邮件通知? (y/N): "
read configure_email

if [[ "$configure_email" =~ ^[Yy]$ ]]; then
    echo -n "SMTP服务器地址: "
    read SMTP_SERVER
    echo -n "SMTP端口: "
    read SMTP_PORT
    echo -n "SMTP用户名: "
    read SMTP_USERNAME
    echo -n "SMTP密码: "
    read -s SMTP_PASSWORD
    echo ""
    echo -n "通知邮箱地址: "
    read NOTIFICATION_EMAIL
    
    if [[ -n "$SMTP_SERVER" && -n "$SMTP_USERNAME" && -n "$NOTIFICATION_EMAIL" ]]; then
        gh secret set SMTP_SERVER --body "$SMTP_SERVER"
        gh secret set SMTP_PORT --body "$SMTP_PORT"
        gh secret set SMTP_USERNAME --body "$SMTP_USERNAME"
        gh secret set SMTP_PASSWORD --body "$SMTP_PASSWORD"
        gh secret set NOTIFICATION_EMAIL --body "$NOTIFICATION_EMAIL"
        log_success "邮件通知配置完成"
    fi
fi
echo ""

# 创建环境
log_info "5. 创建部署环境"

# 检查并创建环境
create_environment() {
    local env_name=$1
    local description=$2
    
    if gh api "repos/$REPO_FULL_NAME/environments/$env_name" &> /dev/null; then
        log_info "环境 '$env_name' 已存在"
    else
        log_info "创建环境 '$env_name'..."
        gh api --method PUT "repos/$REPO_FULL_NAME/environments/$env_name" \
            --field "wait_timer=0" \
            --field "prevent_self_review=false" \
            --field "reviewers=[]" \
            --field "deployment_branch_policy={\"protected_branches\":true,\"custom_branch_policies\":false}" > /dev/null
        log_success "环境 '$env_name' 创建完成"
    fi
}

create_environment "staging" "预发布环境"
create_environment "production" "生产环境"
echo ""

# 启用GitHub Container Registry
log_info "6. 启用GitHub Container Registry"
log_info "确保您的仓库已启用 GitHub Packages"
echo ""

# 生成配置总结
log_info "=========================================="
log_success "  GitHub Actions自动部署配置完成！"
log_info "=========================================="
echo ""

echo "📋 配置总结:"
echo "• 仓库: $REPO_FULL_NAME"
echo "• AI服务: SiliconFlow DeepSeek-V3"
echo "• 预发布服务器: ${STAGING_HOST:-未配置}"
echo "• 生产服务器: ${PRODUCTION_HOST:-未配置}"
echo "• Slack通知: ${SLACK_WEBHOOK:+已配置}"
echo "• 邮件通知: ${NOTIFICATION_EMAIL:+已配置}"
echo ""

echo "🚀 部署流程:"
echo "1. 推送代码到main分支触发自动部署"
echo "2. 或使用手动触发: gh workflow run cloud-deploy.yml"
echo "3. 查看部署状态: gh run list --workflow=cloud-deploy.yml"
echo ""

echo "🌐 访问地址 (部署完成后):"
echo "• 预发布: http://${STAGING_HOST:-your-staging-server}"
echo "• 生产环境: http://${PRODUCTION_HOST:-your-production-server}"
echo ""

echo "📚 相关文档:"
echo "• GitHub Actions工作流: .github/workflows/cloud-deploy.yml"
echo "• 云部署指南: CLOUD_DEPLOYMENT_GUIDE.md"
echo "• 部署总结: DEPLOYMENT_SUMMARY.md"
echo ""

# 创建快速命令脚本
cat > github-actions-commands.sh << 'EOF'
#!/bin/bash

# GitHub Actions 快速命令

echo "GitHub Actions 快速命令:"
echo ""

echo "🚀 触发部署:"
echo "gh workflow run cloud-deploy.yml"
echo "gh workflow run cloud-deploy.yml --field target_server=staging"
echo "gh workflow run cloud-deploy.yml --field target_server=production"
echo ""

echo "📊 查看运行状态:"
echo "gh run list --workflow=cloud-deploy.yml"
echo "gh run view --log"
echo ""

echo "🔍 查看Secrets:"
echo "gh secret list"
echo ""

echo "🔧 更新Secret:"
echo "gh secret set SECRET_NAME --body 'SECRET_VALUE'"
echo ""

echo "📋 查看环境:"
echo "gh api repos/:owner/:repo/environments"
echo ""
EOF

chmod +x github-actions-commands.sh

log_success "快速命令脚本已生成: github-actions-commands.sh"
echo ""

log_warning "重要提醒:"
echo "1. 确保服务器已安装Docker和Docker Compose"
echo "2. 确保防火墙已开放80和443端口"
echo "3. 推送代码到main分支将触发自动部署"
echo "4. 首次部署可能需要较长时间"
echo ""

log_success "配置完成！现在可以享受自动化部署了！🎉"
