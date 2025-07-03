#!/bin/bash

# 🔍 GitHub Actions 部署日志分析和自动修复脚本
# 自动读取失败的部署记录，分析错误并提供修复方案

set -e

# 配置信息
REPO_OWNER="your-username"  # 替换为您的GitHub用户名
REPO_NAME="legezhixiao"     # 仓库名称
WORKFLOW_NAME="🚀 Deploy to Baidu Cloud"  # 工作流名称

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 GitHub Actions 部署日志分析器${NC}"
echo "=================================================="

# 检查是否安装了必要工具
check_dependencies() {
    echo -e "${YELLOW}📋 检查依赖工具...${NC}"
    
    if ! command -v gh &> /dev/null; then
        echo -e "${RED}❌ GitHub CLI (gh) 未安装${NC}"
        echo -e "${YELLOW}💡 安装命令: curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg${NC}"
        echo -e "${YELLOW}   sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg${NC}"
        echo -e "${YELLOW}   echo \"deb [arch=\$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main\" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null${NC}"
        echo -e "${YELLOW}   sudo apt update && sudo apt install gh${NC}"
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}❌ jq 未安装${NC}"
        echo -e "${YELLOW}💡 安装命令: sudo apt install jq${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ 依赖工具检查完成${NC}"
}

# 获取最新的失败运行
get_latest_failed_run() {
    echo -e "${YELLOW}🔍 获取最新的失败部署记录...${NC}"
    
    # 检查GitHub CLI认证状态
    if ! gh auth status &> /dev/null; then
        echo -e "${RED}❌ GitHub CLI 未认证${NC}"
        echo -e "${YELLOW}💡 请运行: gh auth login${NC}"
        exit 1
    fi
    
    # 获取工作流运行列表
    local runs=$(gh api repos/$REPO_OWNER/$REPO_NAME/actions/runs \
        --jq '.workflow_runs[] | select(.conclusion == "failure") | {id: .id, created_at: .created_at, head_commit: .head_commit.message}' \
        | head -1)
    
    if [ -z "$runs" ]; then
        echo -e "${GREEN}🎉 没有找到失败的部署记录！${NC}"
        exit 0
    fi
    
    echo "$runs"
}

# 分析错误日志
analyze_logs() {
    local run_id=$1
    echo -e "${YELLOW}📊 分析运行ID: $run_id 的日志...${NC}"
    
    # 获取job列表
    local jobs=$(gh api repos/$REPO_OWNER/$REPO_NAME/actions/runs/$run_id/jobs --jq '.jobs[].id')
    
    for job_id in $jobs; do
        echo -e "${BLUE}🔍 分析Job ID: $job_id${NC}"
        
        # 获取日志
        local logs=$(gh api repos/$REPO_OWNER/$REPO_NAME/actions/jobs/$job_id/logs)
        
        # 分析常见错误模式
        analyze_error_patterns "$logs"
    done
}

# 错误模式分析和修复建议
analyze_error_patterns() {
    local logs="$1"
    
    echo -e "${YELLOW}🔍 分析错误模式...${NC}"
    
    # Docker相关错误
    if echo "$logs" | grep -qi "docker.*error\|FROM.*error\|build.*failed"; then
        handle_docker_errors "$logs"
    fi
    
    # SSH连接错误
    if echo "$logs" | grep -qi "ssh.*error\|connection.*refused\|permission.*denied"; then
        handle_ssh_errors "$logs"
    fi
    
    # 依赖安装错误
    if echo "$logs" | grep -qi "npm.*error\|yarn.*error\|pip.*error\|timeout"; then
        handle_dependency_errors "$logs"
    fi
    
    # 环境变量错误
    if echo "$logs" | grep -qi "secret.*not.*found\|environment.*variable"; then
        handle_env_errors "$logs"
    fi
    
    # 端口占用错误
    if echo "$logs" | grep -qi "port.*already.*use\|address.*already.*use"; then
        handle_port_errors "$logs"
    fi
}

# Docker错误处理
handle_docker_errors() {
    local logs="$1"
    echo -e "${RED}🐳 检测到Docker相关错误${NC}"
    
    if echo "$logs" | grep -qi "FROM.*error\|as.*error"; then
        echo -e "${YELLOW}💡 修复建议: Docker语法错误${NC}"
        echo "1. 检查Dockerfile中的FROM语句大小写"
        echo "2. 确保使用正确的Docker版本"
        generate_docker_fix
    fi
    
    if echo "$logs" | grep -qi "timeout\|network"; then
        echo -e "${YELLOW}💡 修复建议: 网络超时问题${NC}"
        echo "1. 使用国内镜像源"
        echo "2. 增加超时时间"
        generate_network_fix
    fi
}

# SSH错误处理
handle_ssh_errors() {
    echo -e "${RED}🔐 检测到SSH连接错误${NC}"
    echo -e "${YELLOW}💡 修复建议:${NC}"
    echo "1. 检查SERVER_SSH_KEY密钥格式"
    echo "2. 验证SERVER_IP和SERVER_USER配置"
    echo "3. 确保服务器SSH服务运行正常"
    
    generate_ssh_fix
}

# 依赖安装错误处理
handle_dependency_errors() {
    echo -e "${RED}📦 检测到依赖安装错误${NC}"
    echo -e "${YELLOW}💡 修复建议:${NC}"
    echo "1. 使用国内镜像源加速下载"
    echo "2. 增加安装超时时间"
    echo "3. 清理缓存重新安装"
    
    generate_dependency_fix
}

# 环境变量错误处理
handle_env_errors() {
    echo -e "${RED}🌍 检测到环境变量错误${NC}"
    echo -e "${YELLOW}💡 修复建议:${NC}"
    echo "1. 检查GitHub Secrets配置"
    echo "2. 验证环境变量名称拼写"
    echo "3. 确保所有必需的密钥都已设置"
    
    generate_env_fix
}

# 端口占用错误处理
handle_port_errors() {
    echo -e "${RED}🔌 检测到端口占用错误${NC}"
    echo -e "${YELLOW}💡 修复建议:${NC}"
    echo "1. 停止现有服务"
    echo "2. 清理Docker容器"
    echo "3. 检查端口映射配置"
    
    generate_port_fix
}

# 生成Docker修复方案
generate_docker_fix() {
    cat > docker-fix.sh << 'EOF'
#!/bin/bash
# Docker错误自动修复脚本

echo "🔧 修复Docker相关问题..."

# 1. 检查并修复Dockerfile语法
echo "📝 检查Dockerfile语法..."
find . -name "Dockerfile*" -exec sed -i 's/FROM \(.*\) AS \(.*\)/FROM \1 as \2/g' {} \;
find . -name "Dockerfile*" -exec sed -i 's/--from=\([A-Z]\)/--from=\L\1/g' {} \;

# 2. 更新Docker到最新版本
if command -v docker &> /dev/null; then
    echo "🆙 更新Docker版本..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io
    fi
fi

# 3. 清理Docker缓存
echo "🧹 清理Docker缓存..."
docker system prune -f || true

echo "✅ Docker修复完成"
EOF
    chmod +x docker-fix.sh
    echo -e "${GREEN}📁 已生成修复脚本: docker-fix.sh${NC}"
}

# 生成网络修复方案
generate_network_fix() {
    cat > network-fix.sh << 'EOF'
#!/bin/bash
# 网络问题修复脚本

echo "🌐 修复网络相关问题..."

# 1. 配置Docker镜像加速
echo "🚀 配置Docker镜像加速..."
sudo mkdir -p /etc/docker
cat > /tmp/daemon.json << 'DOCKER_CONFIG'
{
  "registry-mirrors": [
    "https://mirror.ccs.tencentyun.com",
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com"
  ]
}
DOCKER_CONFIG
sudo mv /tmp/daemon.json /etc/docker/daemon.json
sudo systemctl restart docker

# 2. 预拉取常用镜像
echo "📦 预拉取基础镜像..."
docker pull python:3.11-slim || true
docker pull node:18-alpine || true
docker pull nginx:alpine || true

echo "✅ 网络修复完成"
EOF
    chmod +x network-fix.sh
    echo -e "${GREEN}📁 已生成修复脚本: network-fix.sh${NC}"
}

# 生成SSH修复方案
generate_ssh_fix() {
    cat > ssh-fix.sh << 'EOF'
#!/bin/bash
# SSH连接问题修复脚本

echo "🔐 修复SSH连接问题..."

echo "📋 SSH连接检查清单:"
echo "1. 验证SSH密钥格式 (应该以 '-----BEGIN' 开始)"
echo "2. 检查服务器IP地址是否正确"
echo "3. 确认用户名是否正确 (通常是 root 或 ubuntu)"
echo "4. 测试SSH连接:"
echo "   ssh -i ~/.ssh/your_key user@server_ip"

echo "🔧 GitHub Secrets检查:"
echo "- SERVER_SSH_KEY: SSH私钥内容"
echo "- SERVER_IP: 服务器IP地址"
echo "- SERVER_USER: SSH用户名"

echo "✅ SSH检查完成，请手动验证上述配置"
EOF
    chmod +x ssh-fix.sh
    echo -e "${GREEN}📁 已生成修复脚本: ssh-fix.sh${NC}"
}

# 生成依赖修复方案
generate_dependency_fix() {
    cat > dependency-fix.sh << 'EOF'
#!/bin/bash
# 依赖安装问题修复脚本

echo "📦 修复依赖安装问题..."

# 1. 配置npm镜像源
echo "🔧 配置npm镜像源..."
npm config set registry https://registry.npmmirror.com
npm config set timeout 300000

# 2. 配置yarn镜像源
if command -v yarn &> /dev/null; then
    echo "🔧 配置yarn镜像源..."
    yarn config set registry https://registry.npmmirror.com
    yarn config set network-timeout 300000
fi

# 3. 配置pip镜像源
echo "🔧 配置pip镜像源..."
pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
pip config set global.timeout 300

# 4. 清理缓存
echo "🧹 清理依赖缓存..."
npm cache clean --force || true
yarn cache clean || true
pip cache purge || true

echo "✅ 依赖修复完成"
EOF
    chmod +x dependency-fix.sh
    echo -e "${GREEN}📁 已生成修复脚本: dependency-fix.sh${NC}"
}

# 生成环境变量修复方案
generate_env_fix() {
    cat > env-fix.sh << 'EOF'
#!/bin/bash
# 环境变量问题修复脚本

echo "🌍 检查环境变量配置..."

echo "📋 必需的GitHub Secrets清单:"
echo "================================"
echo "🔐 SSH配置:"
echo "- SERVER_SSH_KEY"
echo "- SERVER_IP"  
echo "- SERVER_USER"
echo ""
echo "🗄️ 数据库配置:"
echo "- DATABASE_SYSTEMIP"
echo "- DATABASE_SYSTEM"
echo "- DATABASE_USER"
echo "- DATABASE_PASSWORD"
echo "- DATABASE_NOVELIP"
echo "- DATABASE_NOVELDATA"
echo "- DATABASE_NOVELUSER"
echo "- DATABASE_NOVELUSER_PASSWORD"
echo ""
echo "🤖 AI服务配置:"
echo "- SILICONFLOW_API_KEY"
echo ""
echo "🔒 安全配置:"
echo "- JWT_SECRET_KEY"
echo ""
echo "🔍 检查方法:"
echo "1. 访问 GitHub仓库 > Settings > Secrets and variables > Actions"
echo "2. 确保所有必需的密钥都已配置"
echo "3. 检查密钥名称拼写是否正确"

echo "✅ 环境变量检查完成"
EOF
    chmod +x env-fix.sh
    echo -e "${GREEN}📁 已生成修复脚本: env-fix.sh${NC}"
}

# 生成端口修复方案
generate_port_fix() {
    cat > port-fix.sh << 'EOF'
#!/bin/bash
# 端口占用问题修复脚本

echo "🔌 修复端口占用问题..."

# 1. 停止现有Docker服务
echo "🛑 停止现有Docker服务..."
docker-compose down || true
docker-compose -f docker-compose.prod.yml down || true
docker-compose -f docker-compose.simple.yml down || true

# 2. 清理所有容器
echo "🧹 清理Docker容器..."
docker container prune -f

# 3. 检查端口占用
echo "🔍 检查端口占用情况..."
netstat -tlnp | grep -E ":(80|8000|3306|6379) "

# 4. 强制释放端口（如果需要）
echo "🔧 释放端口..."
sudo fuser -k 80/tcp || true
sudo fuser -k 8000/tcp || true

echo "✅ 端口修复完成"
EOF
    chmod +x port-fix.sh
    echo -e "${GREEN}📁 已生成修复脚本: port-fix.sh${NC}"
}

# 生成自动修复摘要
generate_fix_summary() {
    cat > fix-summary.md << 'EOF'
# 🔧 GitHub Actions 部署错误修复摘要

## 📊 错误分析结果

基于最新的失败部署日志分析，系统已自动生成相应的修复方案。

## 🛠️ 修复脚本说明

| 脚本名称 | 用途 | 运行方式 |
|----------|------|----------|
| `docker-fix.sh` | 修复Docker相关问题 | `./docker-fix.sh` |
| `network-fix.sh` | 修复网络连接问题 | `./network-fix.sh` |
| `ssh-fix.sh` | 修复SSH连接问题 | `./ssh-fix.sh` |
| `dependency-fix.sh` | 修复依赖安装问题 | `./dependency-fix.sh` |
| `env-fix.sh` | 检查环境变量配置 | `./env-fix.sh` |
| `port-fix.sh` | 修复端口占用问题 | `./port-fix.sh` |

## 🚀 推荐修复流程

1. **本地修复**：
   ```bash
   # 运行相关修复脚本
   ./docker-fix.sh
   ./dependency-fix.sh
   ```

2. **服务器修复**：
   ```bash
   # 在服务器上运行
   ./network-fix.sh
   ./port-fix.sh
   ```

3. **配置检查**：
   ```bash
   # 检查GitHub Secrets配置
   ./env-fix.sh
   ./ssh-fix.sh
   ```

4. **重新部署**：
   ```bash
   git add .
   git commit -m "🔧 修复部署问题"
   git push
   ```

## ⚡ 快速修复命令

```bash
# 一键运行所有修复脚本
for script in *-fix.sh; do
    echo "🔧 运行 $script..."
    ./"$script"
done
```

## 📞 需要手动处理的问题

- GitHub Secrets配置
- 服务器SSH密钥配置
- 网络防火墙设置
- 域名DNS配置

EOF
    echo -e "${GREEN}📁 已生成修复摘要: fix-summary.md${NC}"
}

# 主函数
main() {
    echo -e "${BLUE}开始GitHub Actions错误诊断...${NC}"
    
    # 检查依赖
    check_dependencies
    
    # 获取最新失败记录
    local failed_run=$(get_latest_failed_run)
    
    if [ -z "$failed_run" ]; then
        echo -e "${GREEN}🎉 没有失败的部署记录${NC}"
        exit 0
    fi
    
    # 提取运行ID
    local run_id=$(echo "$failed_run" | jq -r '.id')
    local commit_message=$(echo "$failed_run" | jq -r '.head_commit')
    
    echo -e "${YELLOW}📋 失败的部署信息:${NC}"
    echo "   运行ID: $run_id"
    echo "   提交信息: $commit_message"
    
    # 分析日志
    analyze_logs "$run_id"
    
    # 生成修复摘要
    generate_fix_summary
    
    echo ""
    echo -e "${GREEN}🎉 错误分析完成！${NC}"
    echo -e "${YELLOW}📁 请查看生成的修复脚本和摘要文档${NC}"
    echo -e "${BLUE}💡 运行 './fix-summary.md' 查看详细修复指南${NC}"
}

# 运行主函数
main "$@"
