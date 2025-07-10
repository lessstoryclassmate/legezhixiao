# GitHub Actions 快速配置脚本

echo "🚀 配置GitHub Actions自动部署..."

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=====================================${NC}"
echo -e "${GREEN}  GitHub Actions 自动部署配置向导  ${NC}"
echo -e "${BLUE}=====================================${NC}"

# 1. 生成SSH密钥对
echo -e "${YELLOW}1. 生成SSH密钥对...${NC}"
if [ ! -f ~/.ssh/deploy_key ]; then
    ssh-keygen -t ed25519 -C "github-actions-deploy" -f ~/.ssh/deploy_key -N ""
    echo -e "${GREEN}✅ SSH密钥对生成完成${NC}"
else
    echo -e "${YELLOW}⚠️  SSH密钥对已存在${NC}"
fi

# 2. 显示需要配置的GitHub Secrets
echo -e "${YELLOW}2. 需要在GitHub仓库中配置以下Secrets：${NC}"
echo -e "${BLUE}-------------------------------------${NC}"
echo -e "${GREEN}SSH_PRIVATE_KEY${NC}     : SSH私钥"
echo -e "${GREEN}DEPLOY_HOST${NC}         : 服务器IP地址"
echo -e "${GREEN}DEPLOY_USER${NC}         : 服务器用户名 (如: ubuntu)"
echo -e "${GREEN}SILICONFLOW_API_KEY${NC} : SiliconFlow API密钥"
echo -e "${GREEN}JWT_SECRET_KEY${NC}      : JWT加密密钥"
echo -e "${GREEN}MONGO_PASSWORD${NC}      : MongoDB密码"
echo -e "${GREEN}REDIS_PASSWORD${NC}      : Redis密码"
echo -e "${GREEN}MYSQL_HOST${NC}          : MySQL主机地址"
echo -e "${GREEN}MYSQL_USER${NC}          : MySQL用户名"
echo -e "${GREEN}MYSQL_PASSWORD${NC}      : MySQL密码"
echo -e "${BLUE}-------------------------------------${NC}"

# 3. 显示SSH私钥内容
echo -e "${YELLOW}3. SSH私钥内容（复制到GitHub Secrets）：${NC}"
echo -e "${BLUE}-------------------------------------${NC}"
cat ~/.ssh/deploy_key
echo -e "${BLUE}-------------------------------------${NC}"

# 4. 显示SSH公钥内容
echo -e "${YELLOW}4. SSH公钥内容（添加到服务器）：${NC}"
echo -e "${BLUE}-------------------------------------${NC}"
cat ~/.ssh/deploy_key.pub
echo -e "${BLUE}-------------------------------------${NC}"

# 5. 生成配置服务器的命令
echo -e "${YELLOW}5. 在服务器上执行以下命令：${NC}"
echo -e "${BLUE}-------------------------------------${NC}"
echo "# 添加公钥到服务器"
echo "echo \"$(cat ~/.ssh/deploy_key.pub)\" >> ~/.ssh/authorized_keys"
echo "chmod 600 ~/.ssh/authorized_keys"
echo "chmod 700 ~/.ssh"
echo ""
echo "# 安装Docker（如果未安装）"
echo "curl -fsSL https://get.docker.com | sh"
echo "sudo usermod -aG docker \$USER"
echo ""
echo "# 安装Docker Compose"
echo "sudo curl -L \"https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose"
echo "sudo chmod +x /usr/local/bin/docker-compose"
echo -e "${BLUE}-------------------------------------${NC}"

# 6. 配置步骤说明
echo -e "${YELLOW}6. 配置步骤：${NC}"
echo -e "${GREEN}Step 1:${NC} 在GitHub仓库中配置Secrets"
echo -e "        Settings > Secrets and variables > Actions > New repository secret"
echo -e "${GREEN}Step 2:${NC} 在服务器上添加SSH公钥"
echo -e "${GREEN}Step 3:${NC} 推送代码到main分支触发自动部署"
echo -e "${GREEN}Step 4:${NC} 在Actions选项卡中查看部署状态"

# 7. 测试连接命令
echo -e "${YELLOW}7. 测试SSH连接：${NC}"
echo -e "${BLUE}-------------------------------------${NC}"
echo "# 替换your-server-ip为实际服务器IP"
echo "ssh -i ~/.ssh/deploy_key ubuntu@your-server-ip"
echo -e "${BLUE}-------------------------------------${NC}"

# 8. 快速部署验证
echo -e "${YELLOW}8. 快速验证部署（部署成功后）：${NC}"
echo -e "${BLUE}-------------------------------------${NC}"
echo "# 检查前端服务"
echo "curl -f http://your-server-ip:80"
echo ""
echo "# 检查后端API"
echo "curl -f http://your-server-ip:8000/health"
echo ""
echo "# 检查API文档"
echo "curl -f http://your-server-ip:8000/docs"
echo -e "${BLUE}-------------------------------------${NC}"

echo -e "${GREEN}✅ 配置向导完成！${NC}"
echo -e "${YELLOW}请按照上述步骤完成GitHub Actions配置${NC}"
