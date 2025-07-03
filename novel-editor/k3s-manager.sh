#!/bin/bash

# K3S 管理脚本
# 在容器环境中管理K3S集群

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# 检查K3S是否安装
check_k3s_installed() {
    if ! command -v k3s &> /dev/null; then
        print_error "K3S未安装"
        echo "请运行以下命令安装K3S："
        echo "curl -sfL https://get.k3s.io | sudo sh -s - --write-kubeconfig-mode 644"
        exit 1
    fi
    print_status "K3S已安装 - 版本: $(sudo k3s --version | head -1)"
}

# 启动K3S
start_k3s() {
    print_status "启动K3S集群..."
    
    # 检查是否已经运行
    if pgrep -f "k3s server" > /dev/null; then
        print_warning "K3S已在运行"
        return 0
    fi
    
    # 启动K3S服务器
    sudo k3s server \
        --write-kubeconfig-mode 644 \
        --disable traefik \
        --disable servicelb \
        --log /tmp/k3s.log &
    
    K3S_PID=$!
    print_status "K3S服务器已启动 (PID: $K3S_PID)"
    
    # 等待K3S启动
    echo "等待K3S集群启动..."
    local retry_count=0
    local max_retries=30
    
    while [ $retry_count -lt $max_retries ]; do
        if sudo kubectl get nodes &> /dev/null; then
            print_status "K3S集群启动成功"
            return 0
        fi
        sleep 2
        retry_count=$((retry_count + 1))
        echo "等待中... ($retry_count/$max_retries)"
    done
    
    print_error "K3S集群启动超时"
    return 1
}

# 停止K3S
stop_k3s() {
    print_warning "停止K3S集群..."
    
    # 使用k3s-killall脚本停止
    if [ -f /usr/local/bin/k3s-killall.sh ]; then
        sudo /usr/local/bin/k3s-killall.sh
    else
        # 手动停止进程
        sudo pkill -f "k3s server" || true
        sudo pkill -f "containerd" || true
    fi
    
    print_status "K3S集群已停止"
}

# 检查K3S状态
status_k3s() {
    echo "=================================="
    echo "K3S集群状态检查"
    echo "=================================="
    
    # 检查进程
    if pgrep -f "k3s server" > /dev/null; then
        print_status "K3S服务器正在运行"
        K3S_PID=$(pgrep -f "k3s server")
        echo "  进程ID: $K3S_PID"
    else
        print_warning "K3S服务器未运行"
    fi
    
    # 检查节点
    echo ""
    echo "集群节点状态:"
    if sudo kubectl get nodes 2>/dev/null; then
        echo ""
        echo "Pod状态概览:"
        sudo kubectl get pods -A
    else
        print_warning "无法连接到K3S集群"
    fi
    
    echo ""
    echo "Kubeconfig位置: /etc/rancher/k3s/k3s.yaml"
}

# 部署应用到K3S
deploy_app() {
    print_status "部署应用到K3S集群..."
    
    if [ ! -f "deployment/k8s-manifest.yaml" ]; then
        print_error "K8S部署清单文件不存在: deployment/k8s-manifest.yaml"
        exit 1
    fi
    
    # 应用部署清单
    sudo kubectl apply -f deployment/k8s-manifest.yaml
    
    print_status "应用部署完成"
    
    # 显示部署状态
    echo ""
    echo "部署状态:"
    sudo kubectl get deployments
    echo ""
    echo "服务状态:"
    sudo kubectl get services
    echo ""
    echo "Pod状态:"
    sudo kubectl get pods
}

# 删除应用部署
undeploy_app() {
    print_warning "从K3S集群删除应用..."
    
    if [ -f "deployment/k8s-manifest.yaml" ]; then
        sudo kubectl delete -f deployment/k8s-manifest.yaml || true
        print_status "应用已从集群中移除"
    else
        print_warning "K8S部署清单文件不存在"
    fi
}

# 重置K3S集群
reset_k3s() {
    print_warning "重置K3S集群（这将删除所有数据）..."
    
    read -p "确定要重置K3S集群吗？这将删除所有Pod和数据 (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "操作已取消"
        return 0
    fi
    
    # 停止K3S
    stop_k3s
    
    # 清理数据
    sudo rm -rf /var/lib/rancher/k3s/
    sudo rm -rf /etc/rancher/k3s/
    
    print_status "K3S集群已重置"
}

# 显示帮助
show_help() {
    echo "K3S管理脚本使用方法:"
    echo ""
    echo "命令:"
    echo "  start      启动K3S集群"
    echo "  stop       停止K3S集群"  
    echo "  status     显示K3S集群状态"
    echo "  restart    重启K3S集群"
    echo "  deploy     部署应用到K3S"
    echo "  undeploy   从K3S删除应用"
    echo "  reset      重置K3S集群"
    echo "  help       显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  ./k3s-manager.sh start"
    echo "  ./k3s-manager.sh deploy"
    echo "  ./k3s-manager.sh status"
}

# 主函数
main() {
    case "${1:-help}" in
        "start")
            check_k3s_installed
            start_k3s
            ;;
        "stop")
            stop_k3s
            ;;
        "status")
            check_k3s_installed
            status_k3s
            ;;
        "restart")
            check_k3s_installed
            stop_k3s
            sleep 3
            start_k3s
            ;;
        "deploy")
            check_k3s_installed
            deploy_app
            ;;
        "undeploy")
            check_k3s_installed
            undeploy_app
            ;;
        "reset")
            check_k3s_installed
            reset_k3s
            ;;
        "help")
            show_help
            ;;
        *)
            echo "未知命令: $1"
            show_help
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"
