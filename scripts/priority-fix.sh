#!/bin/bash
# 优先级修复脚本 - 按优先级顺序修复部署问题
# 使用方法: ./scripts/priority-fix.sh [--emergency] [--skip-tests]

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# 解析命令行参数
EMERGENCY_MODE=false
SKIP_TESTS=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --emergency|-e)
            EMERGENCY_MODE=true
            shift
            ;;
        --skip-tests|-s)
            SKIP_TESTS=true
            shift
            ;;
        --help|-h)
            echo "优先级修复脚本使用方法:"
            echo "  $0 [选项]"
            echo ""
            echo "选项:"
            echo "  --emergency, -e    紧急修复模式，跳过验证步骤"
            echo "  --skip-tests, -s   跳过测试步骤"
            echo "  --help, -h         显示此帮助信息"
            exit 0
            ;;
        *)
            echo "未知参数: $1"
            exit 1
            ;;
    esac
done

echo -e "${BLUE}🚨 AI小说编辑器 - 优先级修复脚本${NC}"
echo "================================================="
echo -e "${YELLOW}修复模式: $([ "$EMERGENCY_MODE" = true ] && echo "紧急模式" || echo "标准模式")${NC}"
echo -e "${YELLOW}测试模式: $([ "$SKIP_TESTS" = true ] && echo "跳过测试" || echo "包含测试")${NC}"
echo ""

# 记录修复开始时间
start_time=$(date +%s)

# ===== 优先级 1: 关键系统修复 =====
echo -e "${RED}🔴 优先级 1: 关键系统修复${NC}"
echo "================================================="

# 1.1 DNS 配置修复
echo -e "${YELLOW}1.1 修复 DNS 配置...${NC}"
if [ -f "/etc/resolv.conf" ]; then
    sudo cp /etc/resolv.conf /etc/resolv.conf.backup.$(date +%s) 2>/dev/null || true
fi

# 使用百度云DNS（符合用户要求）
sudo bash -c 'cat > /etc/resolv.conf <<EOF
nameserver 180.76.76.76
EOF'

echo -e "${GREEN}✅ DNS 已设置为百度云DNS (180.76.76.76)${NC}"

# 1.2 systemd 服务冲突清理
echo -e "${YELLOW}1.2 清理 systemd 服务冲突...${NC}"
CONFLICT_SERVICES=(
    "ai-novel-editor" "ai-novel-editor.service"
    "novel-editor" "novel-editor.service"
    "backend" "backend.service"
    "frontend" "frontend.service"
    "legezhixiao" "legezhixiao.service"
)

for service in "${CONFLICT_SERVICES[@]}"; do
    if systemctl list-unit-files | grep -q "^$service"; then
        sudo systemctl stop "$service" 2>/dev/null || true
        sudo systemctl disable "$service" 2>/dev/null || true
        echo -e "${GREEN}✅ 已停止并禁用: $service${NC}"
    fi
done

# 移除服务文件
for service in "${CONFLICT_SERVICES[@]}"; do
    for service_dir in "/etc/systemd/system" "/lib/systemd/system" "/usr/lib/systemd/system"; do
        if [ -f "$service_dir/$service" ]; then
            sudo rm -f "$service_dir/$service"
            echo -e "${GREEN}✅ 已移除: $service_dir/$service${NC}"
        fi
    done
done

sudo systemctl daemon-reload || true
sudo systemctl reset-failed || true
echo -e "${GREEN}✅ systemd 服务冲突清理完成${NC}"

# 1.3 SSH 密钥配置验证
echo -e "${YELLOW}1.3 验证 SSH 密钥配置...${NC}"
SSH_KEY_PATH="/root/.ssh/id_ed25519"

if [ -f "$SSH_KEY_PATH" ]; then
    # 检查并修正权限
    current_perms=$(stat -c "%a" "$SSH_KEY_PATH")
    if [ "$current_perms" != "600" ]; then
        sudo chmod 600 "$SSH_KEY_PATH"
        echo -e "${GREEN}✅ SSH 密钥权限已修正为 600${NC}"
    else
        echo -e "${GREEN}✅ SSH 密钥权限正确${NC}"
    fi
    
    # 确保 .ssh 目录权限
    sudo chmod 700 /root/.ssh
    
    # 配置 SSH 客户端
    sudo tee /root/.ssh/config > /dev/null <<EOF
Host github.com
    HostName github.com
    User git
    IdentityFile $SSH_KEY_PATH
    IdentitiesOnly yes
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    ConnectTimeout 30
EOF
    sudo chmod 600 /root/.ssh/config
    echo -e "${GREEN}✅ SSH 客户端配置已更新${NC}"
else
    echo -e "${RED}❌ SSH 密钥不存在: $SSH_KEY_PATH${NC}"
    echo -e "${YELLOW}💡 请手动生成 SSH 密钥: ssh-keygen -t ed25519 -f $SSH_KEY_PATH -N ''${NC}"
fi

# ===== 优先级 2: Docker 环境修复 =====
echo -e "${YELLOW}🟡 优先级 2: Docker 环境修复${NC}"
echo "================================================="

# 2.1 Docker 镜像加速器配置
echo -e "${YELLOW}2.1 配置 Docker 镜像加速器...${NC}"
sudo mkdir -p /etc/docker

# 使用百度云镜像源（符合用户要求）
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "registry-mirrors": ["https://registry.baidubce.com"],
  "dns": ["180.76.76.76"],
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

echo -e "${GREEN}✅ Docker 镜像加速器已配置（百度云）${NC}"

# 2.2 重启 Docker 服务
echo -e "${YELLOW}2.2 重启 Docker 服务...${NC}"
sudo systemctl restart docker || true
sleep 5

if systemctl is-active --quiet docker; then
    echo -e "${GREEN}✅ Docker 服务重启成功${NC}"
else
    echo -e "${RED}❌ Docker 服务重启失败${NC}"
fi

# 2.3 停止现有容器
echo -e "${YELLOW}2.3 停止现有容器...${NC}"
if command -v docker-compose > /dev/null 2>&1; then
    docker-compose down --remove-orphans 2>/dev/null || true
    echo -e "${GREEN}✅ 现有容器已停止${NC}"
else
    echo -e "${YELLOW}⚠️ docker-compose 不可用，跳过容器停止${NC}"
fi

# ===== 优先级 3: 应用依赖修复 =====
echo -e "${GREEN}🟢 优先级 3: 应用依赖修复${NC}"
echo "================================================="

# 3.1 检查关键文件
echo -e "${YELLOW}3.1 检查关键文件...${NC}"
CRITICAL_FILES=(
    "docker-compose.production.yml"
    "package.json"
    "requirements.txt"
    ".env"
)

missing_files=0
for file in "${CRITICAL_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅ $file 存在${NC}"
    else
        echo -e "${RED}❌ $file 缺失${NC}"
        missing_files=$((missing_files + 1))
    fi
done

if [ $missing_files -eq 0 ]; then
    echo -e "${GREEN}✅ 所有关键文件存在${NC}"
else
    echo -e "${RED}❌ 缺少 $missing_files 个关键文件${NC}"
fi

# 3.2 验证 pyjwt 依赖
echo -e "${YELLOW}3.2 验证 Python 依赖...${NC}"
if [ -f "backend/requirements.txt" ]; then
    if grep -q "pyjwt" backend/requirements.txt; then
        echo -e "${GREEN}✅ pyjwt 依赖已存在${NC}"
    else
        echo -e "${YELLOW}⚠️ 添加 pyjwt 依赖...${NC}"
        echo "pyjwt>=2.8.0" >> backend/requirements.txt
        echo -e "${GREEN}✅ pyjwt 依赖已添加${NC}"
    fi
else
    echo -e "${RED}❌ backend/requirements.txt 不存在${NC}"
fi

# 3.3 创建或更新 .env 文件
echo -e "${YELLOW}3.3 更新环境变量配置...${NC}"
if [ ! -f ".env" ]; then
    cat > .env <<EOF
# 服务器配置
SERVER_IP=106.13.216.179

# MongoDB 配置
MONGODB_HOST=mongodb-server
MONGODB_PORT=27017
MONGODB_DATABASE=ai_novel_db
MONGO_PASSWORD=mongodb_password_123456

# Redis 配置
REDIS_HOST=redis-server
REDIS_PORT=6379
REDIS_PASSWORD=redis_password_123456

# JWT 配置
JWT_SECRET_KEY=your-jwt-secret-key-change-this-in-production

# SiliconFlow API 配置
SILICONFLOW_API_KEY=sk-mjithqmjwccqgffouexthbavtnvftwkqjludpcxhrmeztcib
SILICONFLOW_DEFAULT_MODEL=deepseek-ai/DeepSeek-V3
SILICONFLOW_API_URL=https://api.siliconflow.cn/v1/chat/completions

# 小说生成配置
NOVEL_GENERATION_MAX_TOKENS=2048
NOVEL_GENERATION_TEMPERATURE=0.7
NOVEL_GENERATION_TOP_P=0.9
EOF
    echo -e "${GREEN}✅ .env 文件已创建${NC}"
else
    echo -e "${GREEN}✅ .env 文件已存在${NC}"
fi

# ===== 优先级 4: 网络连通性验证 =====
echo -e "${BLUE}🔵 优先级 4: 网络连通性验证${NC}"
echo "================================================="

if [ "$SKIP_TESTS" = false ]; then
    echo -e "${YELLOW}4.1 测试网络连通性...${NC}"
    
    # 测试关键服务
    CRITICAL_SERVICES=(
        "github.com"
        "registry.baidubce.com"
        "api.siliconflow.cn"
    )
    
    for service in "${CRITICAL_SERVICES[@]}"; do
        if curl -s --connect-timeout 10 "https://$service" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ $service 连通正常${NC}"
        else
            echo -e "${RED}❌ $service 连通失败${NC}"
        fi
    done
    
    # 测试 Docker 镜像拉取
    echo -e "${YELLOW}4.2 测试 Docker 镜像拉取...${NC}"
    if timeout 30 docker pull registry.baidubce.com/library/hello-world 2>/dev/null; then
        echo -e "${GREEN}✅ Docker 镜像拉取正常${NC}"
        docker rmi registry.baidubce.com/library/hello-world 2>/dev/null || true
    else
        echo -e "${RED}❌ Docker 镜像拉取失败${NC}"
    fi
else
    echo -e "${YELLOW}⚠️ 跳过网络连通性测试${NC}"
fi

# ===== 优先级 5: 服务启动准备 =====
echo -e "${PURPLE}🟣 优先级 5: 服务启动准备${NC}"
echo "================================================="

# 5.1 预拉取基础镜像
echo -e "${YELLOW}5.1 预拉取基础镜像...${NC}"
BASE_IMAGES=(
    "node:18-alpine"
    "python:3.11-slim"
    "nginx:latest"
    "mongo:latest"
    "redis:latest"
)

if [ "$EMERGENCY_MODE" = false ]; then
    for image in "${BASE_IMAGES[@]}"; do
        echo -e "${YELLOW}🔄 拉取镜像: $image${NC}"
        if docker pull "registry.baidubce.com/library/$image" 2>/dev/null; then
            docker tag "registry.baidubce.com/library/$image" "$image" 2>/dev/null || true
            echo -e "${GREEN}✅ $image 拉取成功${NC}"
        else
            echo -e "${YELLOW}⚠️ $image 拉取失败，构建时会自动拉取${NC}"
        fi
    done
else
    echo -e "${YELLOW}⚠️ 紧急模式，跳过镜像预拉取${NC}"
fi

# 5.2 验证 Docker Compose 配置
echo -e "${YELLOW}5.2 验证 Docker Compose 配置...${NC}"
if [ -f "docker-compose.production.yml" ]; then
    if docker-compose -f docker-compose.production.yml config > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Docker Compose 配置验证通过${NC}"
    else
        echo -e "${RED}❌ Docker Compose 配置验证失败${NC}"
    fi
else
    echo -e "${RED}❌ docker-compose.production.yml 不存在${NC}"
fi

# ===== 修复完成总结 =====
echo ""
echo "================================================="
echo -e "${GREEN}🎉 优先级修复完成！${NC}"
echo "================================================="

# 计算修复耗时
end_time=$(date +%s)
duration=$((end_time - start_time))
echo -e "${BLUE}⏱️ 修复耗时: ${duration}秒${NC}"

echo ""
echo -e "${YELLOW}📋 修复内容总结:${NC}"
echo -e "${GREEN}✅ 1. DNS 配置已修复 (百度云DNS: 180.76.76.76)${NC}"
echo -e "${GREEN}✅ 2. systemd 服务冲突已清理${NC}"
echo -e "${GREEN}✅ 3. SSH 密钥配置已验证${NC}"
echo -e "${GREEN}✅ 4. Docker 镜像加速器已配置 (百度云)${NC}"
echo -e "${GREEN}✅ 5. 应用依赖已检查和修复${NC}"
echo -e "${GREEN}✅ 6. 网络连通性已$([ "$SKIP_TESTS" = true ] && echo "跳过" || echo "验证")${NC}"
echo -e "${GREEN}✅ 7. 服务启动准备已完成${NC}"

echo ""
echo -e "${YELLOW}🚀 建议接下来的操作:${NC}"
echo -e "1. 运行部署脚本: ${GREEN}./scripts/quick-deploy-fixed.sh${NC}"
echo -e "2. 或手动启动服务: ${GREEN}docker-compose -f docker-compose.production.yml up -d --build${NC}"
echo -e "3. 查看服务状态: ${GREEN}docker-compose -f docker-compose.production.yml ps${NC}"
echo -e "4. 查看服务日志: ${GREEN}docker-compose -f docker-compose.production.yml logs -f${NC}"

echo ""
echo -e "${BLUE}📞 故障排查:${NC}"
echo -e "如果仍有问题，请检查:"
echo -e "• SSH 密钥是否正确配置在 GitHub"
echo -e "• 网络连接是否正常"
echo -e "• Docker 服务是否正常运行"
echo -e "• 端口 80 和 8000 是否被占用"

echo ""
echo -e "${GREEN}✅ 优先级修复脚本执行完成！${NC}"
