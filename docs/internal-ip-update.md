# 内网 IP 地址配置更新

## 更新概述

根据最新的服务器配置要求，更新云数据库的内网 IP 地址配置，将 MongoDB 和 Redis 服务迁移到新的内网地址 `172.16.32.2`。

## 配置变更详情

### 服务器基础信息
- **服务器 IP**: `106.13.216.179`
- **服务器用户**: `root`
- **SSH 端口**: `22`
- **认证方式**: SSH 密钥

### 数据库配置更新

#### MongoDB 配置 ✅ 已更新
- **之前**: `172.16.16.2:27017`
- **现在**: `172.16.32.2:27017`
- **数据库名**: `ai_novel_db`
- **连接方式**: 匿名访问

#### Redis 配置 ✅ 已更新
- **之前**: `172.16.16.4:6379`
- **现在**: `172.16.32.2:6379`
- **认证**: 密码认证 (`REDIS_PASSWORD`)

#### MySQL 配置 🔄 保持不变
**系统数据库**:
- **地址**: `172.16.16.3:3306` (保持不变)
- **数据库**: `novel_data`
- **用户**: `lkr`
- **密码**: `Lekairong350702`

**用户数据库**:
- **地址**: `172.16.32.2:3306` (已更新)
- **数据库**: `novel_user_data`
- **用户**: `novel_data_user`
- **密码**: `Lekairong350702`

### AI 服务配置
- **SiliconFlow API Key**: `sk-mjithqmjwccqgffouexthbavtnvftwkqjludpcxhrmeztcib`
- **默认模型**: `deepseek-ai/DeepSeek-V3`
- **API 地址**: `https://api.siliconflow.cn/v1/chat/completions`

### MCP 服务配置
- **服务名**: `novel-ai-server`
- **端口**: `8000`
- **主机**: `106.13.216.179` (外网 IP)
- **工具**: `novel_generation,character_creation,plot_analysis,content_review,style_transfer`

## 修改的文件列表

### 1. `.github/workflows/deploy-advanced.yml`
**修改内容**:
- 测试环境变量中的 MongoDB 和 Redis 地址
- 部署脚本中的环境变量配置
- 验证信息显示

**关键变更**:
```yaml
# 测试环境
MONGODB_HOST=172.16.32.2
REDIS_HOST=172.16.32.2
DATABASE_NOVELHOST=172.16.32.2

# 部署环境
MongoDB: 172.16.32.2:27017/ai_novel_db
Redis: 172.16.32.2:6379
```

### 2. `docker-compose.yml`
**修改内容**:
- 更新环境变量默认值
- MongoDB 和 Redis 连接字符串

**关键变更**:
```yaml
environment:
  - MONGODB_URL=mongodb://172.16.32.2:27017/ai_novel_db
  - REDIS_URL=redis://:password@172.16.32.2:6379
```

## 网络架构图

```
外网访问 (106.13.216.179)
    ↓
服务器 (106.13.216.179)
    ├── Frontend Container (端口 80)
    └── Backend Container (端口 8000)
        ├── → MongoDB (172.16.32.2:27017) ✅ 已更新
        ├── → Redis (172.16.32.2:6379) ✅ 已更新
        ├── → MySQL 系统库 (172.16.16.3:3306) 🔄 保持不变
        └── → MySQL 用户库 (172.16.32.2:3306) ✅ 已更新
```

## 环境变量配置

### 完整的环境变量列表
```bash
# 服务器配置
SERVER_IP=106.13.216.179
SERVER_USER=root
SERVER_SSH_PORT=22
SERVER_PORT=22

# AI 服务配置
SILICONFLOW_API_KEY=sk-mjithqmjwccqgffouexthbavtnvftwkqjludpcxhrmeztcib
SILICONFLOW_DEFAULT_MODEL=deepseek-ai/DeepSeek-V3
SILICONFLOW_API_URL=https://api.siliconflow.cn/v1/chat/completions
JWT_SECRET_KEY=${JWT_SECRET_KEY}

# MCP 服务配置
MCP_SERVER_NAME=novel-ai-server
MCP_SERVER_PORT=8000
MCP_SERVER_HOST=106.13.216.179
MCP_TOOLS_ENABLED=true
MCP_TOOLS_LIST=novel_generation,character_creation,plot_analysis,content_review,style_transfer
NOVEL_GENERATION_MAX_TOKENS=4096
NOVEL_GENERATION_TEMPERATURE=0.8
NOVEL_GENERATION_TOP_P=0.9

# 云数据库配置 (已更新)
MONGODB_HOST=172.16.32.2
MONGODB_PORT=27017
MONGODB_DATABASE=ai_novel_db
REDIS_HOST=172.16.32.2
REDIS_PORT=6379
REDIS_PASSWORD=${REDIS_PASSWORD}

# MySQL 数据库配置
DATABASE_PORT=3306
DATABASE_SYSTEMHOST=172.16.16.3  # 保持不变
DATABASE_SYSTEM=novel_data
DATABASE_USER=lkr
DATABASE_PASSWORD=Lekairong350702
DATABASE_NOVELHOST=172.16.32.2  # 已更新
DATABASE_NOVELDATA=novel_user_data
DATABASE_NOVELUSER=novel_data_user
DATABASE_NOVELUSER_PASSWORD=Lekairong350702
```

## 网络连接验证

### 连接测试命令
```bash
# 测试新的 MongoDB 地址
ping -c 3 172.16.32.2
telnet 172.16.32.2 27017

# 测试新的 Redis 地址
telnet 172.16.32.2 6379

# 测试 MySQL 系统库 (保持不变)
ping -c 3 172.16.16.3
telnet 172.16.16.3 3306

# 测试 MySQL 用户库 (已更新)
telnet 172.16.32.2 3306
```

### CI/CD 工作流验证
工作流会自动测试以下连接：
- `172.16.32.2` - MongoDB/Redis 服务器
- `172.16.16.3` - MySQL 系统库服务器

## 部署注意事项

### 1. 网络配置
- 确保服务器能够访问 `172.16.32.2` 地址
- 验证防火墙和安全组设置
- 确认端口 27017、6379、3306 开放

### 2. 服务依赖
- MongoDB 和 Redis 现在在同一台服务器上
- 可能需要协调资源使用
- 确保服务器有足够的内存和存储

### 3. 数据迁移
- 如果需要从旧地址迁移数据，需要制定迁移计划
- 备份现有数据
- 验证数据完整性

## 后续验证步骤

1. **推送代码**: 触发 GitHub Actions 工作流
2. **观察构建**: 检查网络连接测试结果
3. **验证部署**: 确认服务正常启动
4. **功能测试**: 验证应用各项功能正常
5. **性能监控**: 观察新配置下的性能表现

---

**更新日期**: 2025-07-11  
**版本**: v4.0  
**状态**: 已配置  
**影响范围**: MongoDB, Redis, MySQL 用户库
