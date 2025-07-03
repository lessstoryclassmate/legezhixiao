#!/bin/bash

# GitHub Actions 快速部署设置脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 输出函数
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

echo "=========================================="
echo "🚀 AI小说编辑器 GitHub Actions 部署设置"
echo "=========================================="
echo ""

# 检查必要工具
check_requirements() {
    print_info "检查必要工具..."
    
    local missing_tools=false
    
    if ! command -v git &> /dev/null; then
        print_error "Git未安装"
        missing_tools=true
    fi
    
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl未安装"
        missing_tools=true
    fi
    
    if ! command -v base64 &> /dev/null; then
        print_error "base64未安装"
        missing_tools=true
    fi
    
    if [ "$missing_tools" = true ]; then
        print_error "请安装缺失的工具后重新运行"
        exit 1
    fi
    
    print_status "所有必要工具已安装"
}

# 生成Secrets配置
generate_secrets() {
    print_info "生成GitHub Secrets配置..."
    
    SECRETS_FILE="github-secrets.txt"
    
    cat > $SECRETS_FILE << EOF
# GitHub Actions Secrets 配置
# 请在 GitHub 仓库的 Settings > Secrets and variables > Actions 中添加以下secrets:

# === 基础配置 ===
# GITHUB_TOKEN 由GitHub自动提供，无需手动添加

# === 应用密钥 ===
SECRET_KEY=$(openssl rand -hex 32)
SILICONFLOW_API_KEY=sk-your-siliconflow-api-key-here
MYSQL_ROOT_PASSWORD=$(openssl rand -base64 32)

# === Kubernetes配置 ===
# 开发环境K8S配置 (需要base64编码)
# KUBE_CONFIG_DEV=\$(cat /path/to/dev-kubeconfig.yaml | base64 -w 0)

# 生产环境K8S配置 (需要base64编码)  
# KUBE_CONFIG_PROD=\$(cat /path/to/prod-kubeconfig.yaml | base64 -w 0)

# === 通知配置 (可选) ===
# SLACK_WEBHOOK=https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK
# SONAR_TOKEN=your-sonarqube-token-here

# === 使用说明 ===
# 1. 复制上述配置到GitHub仓库的Secrets中
# 2. 替换示例值为实际值
# 3. 对于K8S配置，使用命令：cat kubeconfig.yaml | base64 -w 0
# 4. 确保所有必需的secrets都已配置
EOF

    print_status "Secrets配置已生成到 $SECRETS_FILE"
    print_warning "请编辑 $SECRETS_FILE 并将配置添加到GitHub Secrets中"
}

# 生成Kubernetes配置
generate_k8s_config() {
    print_info "生成Kubernetes配置示例..."
    
    # 创建开发环境配置
    cat > deployment/dev-configmap.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: novel-editor-config
  namespace: development
data:
  ENVIRONMENT: "development"
  DATABASE_SYSTEM_HOST: "mysql-system.development.svc.cluster.local"
  DATABASE_SYSTEM_PORT: "3306"
  DATABASE_SYSTEM_NAME: "novel_data_dev"
  DATABASE_USER_HOST: "mysql-user.development.svc.cluster.local"
  DATABASE_USER_PORT: "3306"
  DATABASE_USER_NAME: "novel_user_data_dev"
  DATABASE_USER_USER: "novel_data_user"
---
apiVersion: v1
kind: Secret
metadata:
  name: novel-editor-secrets
  namespace: development
type: Opaque
stringData:
  SECRET_KEY: "your-secret-key-here"
  SILICONFLOW_API_KEY: "your-api-key-here"
  MYSQL_ROOT_PASSWORD: "your-mysql-password-here"
  DATABASE_SYSTEM_PASSWORD: "your-system-db-password"
  DATABASE_USER_PASSWORD: "your-user-db-password"
EOF

    # 创建生产环境配置
    cat > deployment/prod-configmap.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: novel-editor-config
  namespace: production
data:
  ENVIRONMENT: "production"
  DATABASE_SYSTEM_HOST: "mysql-system.production.svc.cluster.local"
  DATABASE_SYSTEM_PORT: "3306"
  DATABASE_SYSTEM_NAME: "novel_data"
  DATABASE_USER_HOST: "mysql-user.production.svc.cluster.local"
  DATABASE_USER_PORT: "3306"
  DATABASE_USER_NAME: "novel_user_data"
  DATABASE_USER_USER: "novel_data_user"
---
apiVersion: v1
kind: Secret
metadata:
  name: novel-editor-secrets
  namespace: production
type: Opaque
stringData:
  SECRET_KEY: "your-production-secret-key-here"
  SILICONFLOW_API_KEY: "your-api-key-here"
  MYSQL_ROOT_PASSWORD: "your-mysql-password-here"
  DATABASE_SYSTEM_PASSWORD: "your-system-db-password"
  DATABASE_USER_PASSWORD: "your-user-db-password"
EOF

    print_status "Kubernetes配置示例已生成"
}

# 验证工作流文件
validate_workflows() {
    print_info "验证GitHub Actions工作流文件..."
    
    local workflow_dir=".github/workflows"
    local workflows=(
        "ci-cd.yml"
        "docker-build.yml"
        "dependency-updates.yml"
        "code-quality.yml"
        "k8s-deploy.yml"
        "monitoring.yml"
    )
    
    for workflow in "${workflows[@]}"; do
        if [ -f "$workflow_dir/$workflow" ]; then
            print_status "$workflow 存在"
        else
            print_error "$workflow 不存在"
        fi
    done
}

# 生成部署检查清单
generate_checklist() {
    print_info "生成部署检查清单..."
    
    cat > DEPLOYMENT_CHECKLIST.md << EOF
# 🚀 GitHub Actions 部署检查清单

## 📋 部署前检查

### ✅ GitHub仓库配置
- [ ] 仓库已创建并推送代码
- [ ] 启用GitHub Actions
- [ ] 配置Branch Protection Rules (main分支)
- [ ] 设置Environment (development, production)

### ✅ Secrets配置
- [ ] SECRET_KEY
- [ ] SILICONFLOW_API_KEY  
- [ ] MYSQL_ROOT_PASSWORD
- [ ] KUBE_CONFIG_DEV (base64编码)
- [ ] KUBE_CONFIG_PROD (base64编码)
- [ ] SLACK_WEBHOOK (可选)
- [ ] SONAR_TOKEN (可选)

### ✅ Kubernetes集群准备
- [ ] 开发环境集群已准备就绪
- [ ] 生产环境集群已准备就绪
- [ ] kubectl访问权限已配置
- [ ] 命名空间已创建 (development, production)
- [ ] RBAC权限已配置
- [ ] Ingress Controller已安装

### ✅ Docker Registry
- [ ] GitHub Container Registry已启用
- [ ] 镜像推送权限已配置
- [ ] 多架构构建支持已启用

### ✅ 应用配置
- [ ] 数据库连接配置正确
- [ ] API密钥配置正确
- [ ] 健康检查端点已实现
- [ ] 日志配置已优化

## 🔄 部署流程

### 1️⃣ 初始部署
1. 推送代码到GitHub
2. 检查CI/CD流水线状态
3. 验证Docker镜像构建
4. 确认自动部署成功
5. 运行健康检查

### 2️⃣ 功能更新
1. 创建功能分支
2. 提交代码并创建PR
3. 等待CI检查通过
4. 合并到develop分支
5. 验证开发环境部署
6. 合并到main分支部署生产

### 3️⃣ 紧急修复
1. 创建hotfix分支
2. 快速修复并测试
3. 直接合并到main分支
4. 监控生产部署状态
5. 验证修复效果

## 🔍 验证检查

### ✅ 部署验证
- [ ] 前端页面可访问
- [ ] 后端API正常响应
- [ ] 数据库连接正常
- [ ] AI功能正常工作
- [ ] 用户注册登录正常

### ✅ 性能验证
- [ ] 页面加载时间 < 3秒
- [ ] API响应时间 < 500ms
- [ ] 并发用户支持 > 100
- [ ] 资源使用率 < 80%

### ✅ 安全验证
- [ ] HTTPS配置正确
- [ ] API认证正常
- [ ] 敏感信息已加密
- [ ] 安全扫描通过

## 🚨 故障排查

### 常见问题
1. **镜像构建失败**
   - 检查Dockerfile语法
   - 验证依赖安装
   - 查看构建日志

2. **部署超时**
   - 检查资源配额
   - 验证镜像拉取速度
   - 查看Pod事件

3. **健康检查失败**
   - 验证应用启动时间
   - 检查健康检查端点
   - 查看应用日志

4. **服务不可访问**
   - 检查Service配置
   - 验证Ingress规则
   - 确认网络策略

### 紧急联系
- 运维团队: ops@company.com
- 开发团队: dev@company.com
- 项目负责人: pm@company.com

---
📅 最后更新: $(date)
👤 负责人: DevOps Team
EOF

    print_status "部署检查清单已生成到 DEPLOYMENT_CHECKLIST.md"
}

# 设置Git Hooks
setup_git_hooks() {
    print_info "设置Git Hooks..."
    
    mkdir -p .git/hooks
    
    # Pre-commit hook
    cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
# Pre-commit hook for AI Novel Editor

echo "🔍 运行pre-commit检查..."

# 检查前端代码
if [ -d "frontend" ]; then
    cd frontend
    if [ -f "package.json" ]; then
        echo "检查前端代码格式..."
        yarn lint --fix || exit 1
        yarn type-check || exit 1
    fi
    cd ..
fi

# 检查后端代码
if [ -d "backend" ]; then
    cd backend
    if [ -f "requirements.txt" ] && [ -d "venv" ]; then
        echo "检查后端代码格式..."
        source venv/bin/activate
        black . || exit 1
        flake8 . || exit 1
    fi
    cd ..
fi

echo "✅ Pre-commit检查通过"
EOF

    chmod +x .git/hooks/pre-commit
    print_status "Git Hooks已设置"
}

# 主函数
main() {
    check_requirements
    echo ""
    
    generate_secrets
    echo ""
    
    generate_k8s_config
    echo ""
    
    validate_workflows
    echo ""
    
    generate_checklist
    echo ""
    
    setup_git_hooks
    echo ""
    
    echo "=========================================="
    echo -e "${GREEN}🎉 GitHub Actions 部署设置完成！${NC}"
    echo "=========================================="
    echo ""
    echo -e "${YELLOW}下一步操作：${NC}"
    echo "1. 编辑 github-secrets.txt 并添加到GitHub Secrets"
    echo "2. 配置Kubernetes集群和kubeconfig"
    echo "3. 根据 DEPLOYMENT_CHECKLIST.md 完成部署检查"
    echo "4. 推送代码到GitHub触发第一次部署"
    echo ""
    echo -e "${BLUE}📖 详细文档：docs/GITHUB_ACTIONS_DEPLOY.md${NC}"
    echo ""
    echo -e "${GREEN}🚀 准备就绪，开始您的CI/CD之旅！${NC}"
}

# 运行主函数
main "$@"
