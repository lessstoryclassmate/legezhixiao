#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 AI小说编辑器 - 关键问题修复验证${NC}"
echo "================================================="

# 1. 检查 pyjwt 是否已添加到 requirements.txt
echo -e "\n${YELLOW}1. 检查 pyjwt 依赖...${NC}"
if grep -q "pyjwt" backend/requirements.txt; then
    echo -e "${GREEN}✅ pyjwt 已添加到 requirements.txt${NC}"
    grep pyjwt backend/requirements.txt
else
    echo -e "${RED}❌ pyjwt 未找到在 requirements.txt${NC}"
fi

# 2. 检查环境变量是否有默认值
echo -e "\n${YELLOW}2. 检查环境变量配置...${NC}"
if [ -f ".env" ]; then
    echo -e "${GREEN}✅ .env 文件存在${NC}"
    
    # 检查关键环境变量
    echo -e "\n${BLUE}MongoDB 密码配置:${NC}"
    grep "MONGO_PASSWORD" .env
    
    echo -e "\n${BLUE}Redis 密码配置:${NC}"
    grep "REDIS_PASSWORD" .env
    
    echo -e "\n${BLUE}JWT 密钥配置:${NC}"
    grep "JWT_SECRET_KEY" .env
else
    echo -e "${RED}❌ .env 文件不存在${NC}"
fi

# 3. 检查 docker-compose.yml 中的 Redis 配置
echo -e "\n${YELLOW}3. 检查 Redis Docker 配置...${NC}"
if grep -A 10 "redis:" docker-compose.yml | grep -q "requirepass"; then
    echo -e "${GREEN}✅ Redis 配置已优化，支持密码检测${NC}"
else
    echo -e "${RED}❌ Redis 配置可能有问题${NC}"
fi

# 4. 检查 MongoDB 配置
echo -e "\n${YELLOW}4. 检查 MongoDB Docker 配置...${NC}"
if grep -A 10 "mongodb:" docker-compose.yml | grep -q "MONGO_INITDB_ROOT_PASSWORD"; then
    echo -e "${GREEN}✅ MongoDB 配置正确${NC}"
else
    echo -e "${RED}❌ MongoDB 配置可能有问题${NC}"
fi

# 5. 建议下一步操作
echo -e "\n${BLUE}========================================${NC}"
echo -e "${YELLOW}📝 建议的测试步骤:${NC}"
echo -e "1. 运行: ${GREEN}docker-compose down --volumes${NC}"
echo -e "2. 运行: ${GREEN}docker-compose build --no-cache${NC}"
echo -e "3. 运行: ${GREEN}docker-compose up -d${NC}"
echo -e "4. 检查: ${GREEN}docker-compose logs -f backend${NC}"
echo -e "5. 测试: ${GREEN}curl -f http://localhost:8000/health${NC}"

echo -e "\n${GREEN}🔥 修复完成！准备进行测试...${NC}"
