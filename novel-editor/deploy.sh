#!/bin/bash

# AI小说编辑器部署脚本

set -e

echo "开始部署AI小说编辑器..."

# 检查环境
check_requirements() {
    echo "检查部署环境..."
    
    if ! command -v docker &> /dev/null; then
        echo "错误: Docker未安装"
        exit 1
    fi
    
    if ! command -v kubectl &> /dev/null; then
        echo "错误: kubectl未安装"
        exit 1
    fi
    
    echo "环境检查通过"
}

# 构建镜像
build_images() {
    echo "构建Docker镜像..."
    
    # 构建后端镜像
    docker build -t novel-editor-backend:latest ./backend
    echo "后端镜像构建完成"
    
    # 构建前端镜像
    docker build -t novel-editor-frontend:latest ./frontend
    echo "前端镜像构建完成"
}

# 部署到K8S
deploy_to_k8s() {
    echo "部署到Kubernetes..."
    
    # 应用K8S配置
    kubectl apply -f deployment/k8s-manifest.yaml
    
    # 等待部署完成
    echo "等待部署完成..."
    kubectl wait --for=condition=available --timeout=300s deployment/novel-editor-backend
    kubectl wait --for=condition=available --timeout=300s deployment/novel-editor-frontend
    
    echo "部署完成"
}

# 显示访问信息
show_access_info() {
    echo "=========================="
    echo "部署完成！"
    echo "=========================="
    
    # 获取Ingress信息
    INGRESS_IP=$(kubectl get ingress novel-editor-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    
    if [ -z "$INGRESS_IP" ]; then
        echo "请配置域名解析到Ingress IP"
        echo "使用以下命令查看Ingress状态:"
        echo "kubectl get ingress novel-editor-ingress"
    else
        echo "访问地址: http://$INGRESS_IP"
    fi
    
    echo ""
    echo "查看部署状态:"
    echo "kubectl get pods"
    echo "kubectl get services"
    echo "kubectl get ingress"
}

# 主函数
main() {
    check_requirements
    build_images
    deploy_to_k8s
    show_access_info
}

# 错误处理
trap 'echo "部署失败，请检查错误信息"; exit 1' ERR

# 运行部署
main

echo "部署脚本执行完成"
