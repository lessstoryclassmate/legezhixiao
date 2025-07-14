#!/bin/bash
# CI/CD环境DNS修复脚本
# 专门解决GitHub Actions、Docker容器等CI环境中的DNS问题

set -e

echo "⚙️ CI/CD环境DNS修复开始..."

# 颜色输出函数
red() { echo -e "\033[31m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
blue() { echo -e "\033[34m$1\033[0m"; }

# 检测CI/CD环境
detect_ci_environment() {
    echo "🔍 检测CI/CD环境..."
    
    if [ -n "$GITHUB_ACTIONS" ]; then
        echo "检测到GitHub Actions环境"
        CI_ENV="github_actions"
    elif [ -n "$GITLAB_CI" ]; then
        echo "检测到GitLab CI环境"
        CI_ENV="gitlab_ci"
    elif [ -f /.dockerenv ]; then
        echo "检测到Docker容器环境"
        CI_ENV="docker"
    elif [ -n "$CI" ]; then
        echo "检测到通用CI环境"
        CI_ENV="generic_ci"
    else
        echo "检测到本地/服务器环境"
        CI_ENV="local"
    fi
    
    export CI_ENV
}

# GitHub Actions 特定修复
fix_github_actions_dns() {
    echo "🔧 GitHub Actions DNS修复..."
    
    # GitHub Actions runners通常有特定的DNS配置
    cat > /tmp/resolv.conf.github << EOF
# GitHub Actions 优化DNS配置
nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 1.1.1.1
nameserver 223.5.5.5

options timeout:1 attempts:2 rotate single-request-reopen
EOF
    
    if [ -w /etc/resolv.conf ]; then
        sudo cp /tmp/resolv.conf.github /etc/resolv.conf
        green "✅ GitHub Actions DNS配置已应用"
    else
        # 在受限环境中，尝试设置环境变量
        export DOCKER_BUILDKIT_CACHE_MOUNT_NS=1
        green "✅ 已设置DNS相关环境变量"
    fi
}

# Docker容器DNS修复
fix_docker_container_dns() {
    echo "🐳 Docker容器DNS修复..."
    
    # 检查是否在容器中
    if [ -f /.dockerenv ]; then
        echo "在Docker容器内，配置DNS..."
        
        # 容器内DNS配置
        cat > /tmp/resolv.conf.docker << EOF
nameserver 223.5.5.5
nameserver 8.8.8.8
nameserver 1.1.1.1

options ndots:0 timeout:1 attempts:2
EOF
        
        if [ -w /etc/resolv.conf ]; then
            cp /tmp/resolv.conf.docker /etc/resolv.conf
            green "✅ 容器DNS配置已更新"
        fi
        
        # 设置Docker build环境变量
        export DOCKER_BUILDKIT=1
        export BUILDKIT_PROGRESS=plain
    fi
}

# 网络诊断 (适用于CI环境)
diagnose_ci_network() {
    echo "🔍 CI环境网络诊断..."
    
    echo "当前网络配置:"
    cat /etc/resolv.conf 2>/dev/null || echo "无法读取resolv.conf"
    
    echo ""
    echo "网络接口:"
    if command -v ip &> /dev/null; then
        ip addr show | head -20
    else
        ifconfig 2>/dev/null | head -20 || echo "无法获取网络接口信息"
    fi
    
    echo ""
    echo "路由表:"
    if command -v ip &> /dev/null; then
        ip route show | head -10
    else
        route -n 2>/dev/null | head -10 || echo "无法获取路由信息"
    fi
    
    # 测试关键域名解析
    echo ""
    echo "关键域名解析测试:"
    domains=("github.com" "registry-1.docker.io")
    
    for domain in "${domains[@]}"; do
        if timeout 5 nslookup "$domain" > /dev/null 2>&1; then
            green "✅ $domain"
        else
            red "❌ $domain"
        fi
    done
}

# 优化Docker镜像拉取
optimize_docker_pull() {
    echo "🚀 优化Docker镜像拉取..."
    
    # 如果可以修改Docker配置
    if [ -w /etc/docker/ ] || [ "$CI_ENV" = "local" ]; then
        sudo mkdir -p /etc/docker
        
        cat > /tmp/docker-daemon-ci.json << EOF
{
  "registry-mirrors": ["https://ccr.ccs.tencentyun.com"],
  "dns": ["223.5.5.5", "8.8.8.8"],
  "max-concurrent-downloads": 3,
  "max-concurrent-uploads": 3
}
EOF
        
        sudo cp /tmp/docker-daemon-ci.json /etc/docker/daemon.json
        
        # 在非容器环境重启Docker
        if [ "$CI_ENV" = "local" ] && systemctl is-active docker &>/dev/null; then
            sudo systemctl restart docker
            sleep 5
        fi
        
        green "✅ Docker腾讯云镜像加速器已配置"
    fi
}

# 测试镜像拉取
test_image_pull() {
    echo "🧪 测试镜像拉取..."
    
    if ! command -v docker &> /dev/null; then
        yellow "⚠️ Docker未安装，跳过测试"
        return 0
    fi
    
    # 尝试拉取测试镜像
    test_images=("hello-world:latest" "alpine:latest")
    
    for image in "${test_images[@]}"; do
        echo "测试拉取: $image"
        
        if timeout 30 docker pull "$image" > /dev/null 2>&1; then
            green "✅ $image 拉取成功"
            docker rmi "$image" > /dev/null 2>&1 || true
        else
            red "❌ $image 拉取失败"
        fi
    done
}

# 设置CI优化环境变量
set_ci_env_vars() {
    echo "⚙️ 设置CI优化环境变量..."
    
    # Docker相关
    export DOCKER_BUILDKIT=1
    export BUILDKIT_PROGRESS=plain
    export COMPOSE_DOCKER_CLI_BUILD=1
    
    # 网络超时优化
    export COMPOSE_HTTP_TIMEOUT=120
    export DOCKER_CLIENT_TIMEOUT=120
    
    # 并发限制
    export DOCKER_MAX_CONCURRENT_DOWNLOADS=3
    
    # DNS超时设置
    export RESOLVE_TIMEOUT=5
    
    green "✅ CI环境变量已设置"
}

# 生成CI修复报告
generate_ci_report() {
    echo ""
    echo "================== CI/CD DNS修复报告 =================="
    echo "环境: $CI_ENV"
    echo "时间: $(date)"
    echo ""
    
    echo "📋 DNS配置检查:"
    if [ -r /etc/resolv.conf ]; then
        nameserver_count=$(grep -c "^nameserver" /etc/resolv.conf 2>/dev/null || echo "0")
        green "✅ 配置了 $nameserver_count 个DNS服务器"
    else
        yellow "⚠️ 无法读取DNS配置"
    fi
    
    echo ""
    echo "📋 网络连通性:"
    if ping -c 1 -W 5 8.8.8.8 > /dev/null 2>&1; then
        green "✅ 基本网络连通"
    else
        red "❌ 基本网络不通"
    fi
    
    echo ""
    echo "📋 关键服务解析:"
    critical_services=("github.com" "registry-1.docker.io")
    for service in "${critical_services[@]}"; do
        if timeout 5 nslookup "$service" > /dev/null 2>&1; then
            green "✅ $service"
        else
            red "❌ $service"
        fi
    done
    
    echo ""
    echo "🔧 故障排除建议:"
    echo "• 如果GitHub Actions失败，检查runner网络配置"
    echo "• 如果Docker拉取失败，检查网络连接"
    echo "• 检查组织/仓库的网络策略设置"
    echo "• 考虑在workflow中添加网络重试机制"
}

# 主函数
main() {
    echo "🚀 开始CI/CD环境DNS修复..."
    echo ""
    
    # 检测环境
    detect_ci_environment
    
    # 根据环境执行特定修复
    case "$CI_ENV" in
        "github_actions")
            fix_github_actions_dns
            ;;
        "docker")
            fix_docker_container_dns
            ;;
        "local"|"generic_ci")
            # 通用修复
            if [ -w /etc/resolv.conf ]; then
                cat > /tmp/resolv.conf.ci << EOF
nameserver 223.5.5.5
nameserver 8.8.8.8
nameserver 1.1.1.1
options timeout:2 attempts:2 rotate
EOF
                sudo cp /tmp/resolv.conf.ci /etc/resolv.conf 2>/dev/null || true
            fi
            ;;
    esac
    
    # 通用优化
    set_ci_env_vars
    optimize_docker_pull
    
    echo ""
    echo "⏳ 等待配置生效..."
    sleep 2
    
    # 诊断和测试
    diagnose_ci_network
    test_image_pull
    
    # 生成报告
    generate_ci_report
    
    echo ""
    green "🎉 CI/CD环境DNS修复完成！"
}

# 运行主函数
main "$@"
