#!/bin/bash
# 百度云镜像拉取助手脚本
# 简化百度云镜像拉取和标签管理

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 显示帮助信息
show_help() {
    echo "🔧 百度云镜像拉取助手"
    echo "====================="
    echo "用法: $0 [选项] <镜像名>"
    echo ""
    echo "选项:"
    echo "  -h, --help        显示帮助信息"
    echo "  -l, --list        列出常用镜像"
    echo "  -t, --test        测试百度云镜像连通性"
    echo "  -c, --config      配置百度云镜像加速器"
    echo ""
    echo "示例:"
    echo "  $0 nginx:latest              # 拉取 nginx:latest"
    echo "  $0 node:18-alpine            # 拉取 node:18-alpine"
    echo "  $0 -l                        # 列出常用镜像"
    echo "  $0 -t                        # 测试连通性"
    echo "  $0 -c                        # 配置镜像加速器"
}

# 配置百度云镜像加速器
configure_baidu_mirror() {
    echo -e "${BLUE}🔧 配置百度云镜像加速器...${NC}"
    
    sudo mkdir -p /etc/docker
    cat > /tmp/docker-daemon.json <<EOF
{
  "registry-mirrors": ["https://mirror.baidubce.com"],
  "max-concurrent-downloads": 3,
  "max-concurrent-uploads": 5,
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "live-restore": true
}
EOF
    
    sudo cp /tmp/docker-daemon.json /etc/docker/daemon.json
    echo -e "${GREEN}✅ 百度云镜像加速器配置完成${NC}"
    
    echo -e "${YELLOW}⚠️ 需要重启 Docker 服务使配置生效${NC}"
    echo "运行: sudo systemctl restart docker"
}

# 测试百度云镜像连通性
test_baidu_mirror() {
    echo -e "${BLUE}🔍 测试百度云镜像连通性...${NC}"
    
    if curl -s --connect-timeout 5 --max-time 10 "https://mirror.baidubce.com/v2/" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ 百度云镜像连通正常${NC}"
        return 0
    else
        echo -e "${RED}❌ 百度云镜像连通失败${NC}"
        return 1
    fi
}

# 列出常用镜像
list_common_images() {
    echo -e "${BLUE}📋 常用镜像列表:${NC}"
    echo ""
    echo "基础镜像:"
    echo "  • alpine:latest"
    echo "  • ubuntu:latest"
    echo "  • centos:latest"
    echo ""
    echo "开发环境:"
    echo "  • node:18-alpine"
    echo "  • python:3.11-slim"
    echo "  • openjdk:11-jre-slim"
    echo ""
    echo "Web 服务器:"
    echo "  • nginx:latest"
    echo "  • apache:latest"
    echo ""
    echo "数据库:"
    echo "  • mysql:latest"
    echo "  • postgres:latest"
    echo "  • mongo:latest"
    echo "  • redis:latest"
    echo ""
    echo "使用示例:"
    echo "  $0 nginx:latest"
    echo "  $0 node:18-alpine"
}

# 拉取镜像
pull_image() {
    local image=$1
    
    if [ -z "$image" ]; then
        echo -e "${RED}❌ 请指定镜像名称${NC}"
        show_help
        exit 1
    fi
    
    echo -e "${BLUE}🔄 拉取镜像: $image${NC}"
    echo "从百度云镜像源拉取..."
    
    # 记录开始时间
    start_time=$(date +%s)
    
    # 从百度云镜像拉取
    if docker pull "mirror.baidubce.com/library/$image"; then
        # 添加常规标签
        docker tag "mirror.baidubce.com/library/$image" "$image"
        
        # 计算耗时
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        
        echo -e "${GREEN}✅ 镜像拉取成功 (耗时: ${duration}s)${NC}"
        echo "📋 镜像信息:"
        docker images "$image" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
        
        # 清理百度云标签的镜像（可选）
        read -p "是否清理百度云标签的镜像? (y/N): " clean_baidu_tag
        if [[ "$clean_baidu_tag" =~ ^[Yy]$ ]]; then
            docker rmi "mirror.baidubce.com/library/$image" 2>/dev/null || true
            echo -e "${GREEN}✅ 百度云标签已清理${NC}"
        fi
        
    else
        echo -e "${RED}❌ 镜像拉取失败${NC}"
        echo "尝试直接拉取进行对比..."
        if docker pull "$image"; then
            echo -e "${YELLOW}⚠️ 直接拉取成功，但百度云镜像拉取失败${NC}"
        else
            echo -e "${RED}❌ 直接拉取也失败，请检查镜像名称${NC}"
        fi
        exit 1
    fi
}

# 主函数
main() {
    case "$1" in
        -h|--help)
            show_help
            ;;
        -l|--list)
            list_common_images
            ;;
        -t|--test)
            test_baidu_mirror
            ;;
        -c|--config)
            configure_baidu_mirror
            ;;
        "")
            echo -e "${RED}❌ 请指定选项或镜像名称${NC}"
            show_help
            exit 1
            ;;
        *)
            # 验证Docker是否运行
            if ! docker info > /dev/null 2>&1; then
                echo -e "${RED}❌ Docker 服务未运行或无权限访问${NC}"
                exit 1
            fi
            
            # 测试百度云镜像连通性
            if ! test_baidu_mirror; then
                echo -e "${YELLOW}⚠️ 百度云镜像连通性测试失败，但继续尝试拉取${NC}"
            fi
            
            # 拉取镜像
            pull_image "$1"
            ;;
    esac
}

# 运行主函数
main "$@"
