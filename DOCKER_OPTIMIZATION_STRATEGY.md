# Docker 镜像拉取优化策略

## 📋 问题分析

### 原问题
- 之前直接使用 `ccr.ccs.tencentyun.com/library/xxx` 作为基础镜像
- 腾讯云公共仓库不包含所有 Docker Hub 镜像标签
- 导致镜像拉取失败：`repo not found`、`unauthorized`、`manifest unknown`

### 根本原因
腾讯云公共注册表 (`ccr.ccs.tencentyun.com/library/`) 是一个**有限同步**的镜像仓库，并不包含 Docker Hub 的所有镜像变体。

## 🎯 优化策略

### 新策略：官方镜像 + 多个国内加速器
1. **镜像名称**: 使用官方 Docker Hub 镜像名
2. **加速器**: 配置多个国内镜像加速器（优先百度云）
3. **DNS**: 使用腾讯云 DNS 优化解析
4. **智能切换**: 自动检测可用加速器并配置

### 配置对比

#### ❌ 错误配置 (旧)
```dockerfile
FROM ccr.ccs.tencentyun.com/library/node:18-alpine
FROM ccr.ccs.tencentyun.com/library/python:3.11-slim
FROM ccr.ccs.tencentyun.com/library/nginx:alpine
```

```json
{
  "registry-mirrors": ["https://ccr.ccs.tencentyun.com"]
}
```

#### ⚠️ 有问题的配置 (旧)
```json
{
  "registry-mirrors": ["https://mirror.ccs.tencentyun.com"]
}
```

#### ✅ 正确配置 (新)
```dockerfile
FROM node:18-alpine
FROM python:3.11-slim
FROM nginx:alpine
```

```json
{
  "registry-mirrors": [
    "https://mirror.baidubce.com",
    "https://docker.mirrors.ustc.edu.cn",
    "https://registry.docker-cn.com",
    "https://mirror.ccs.tencentyun.com"
  ],
  "dns": ["119.29.29.29", "223.5.5.5", "8.8.8.8"]
}
```

## 🔧 实施步骤

### 1. 更新所有 Dockerfile
- ✅ `frontend/Dockerfile`: 使用 `node:18-alpine` 和 `nginx:alpine`
- ✅ `backend/Dockerfile`: 使用 `python:3.11-slim`
- ✅ `mongodb/Dockerfile`: 使用 `mongo:5.0`
- ✅ `redis/Dockerfile`: 使用 `redis:7-alpine`

### 2. 更新部署脚本
- ✅ `quick-deploy.sh`: 修复镜像加速器配置
- ✅ `quick-deploy-fixed.sh`: 已正确配置
- ✅ `dns-fix.sh`: 修复镜像加速器地址
- ✅ `ci-dns-fix.sh`: 修复镜像加速器地址
- ✅ `setup-tencent-docker.sh`: 修复镜像加速器地址
- ✅ `unified-deploy.sh`: 修复镜像加速器地址

### 3. 优化 Docker daemon.json
```json
{
  "registry-mirrors": [
    "https://mirror.baidubce.com",
    "https://docker.mirrors.ustc.edu.cn",
    "https://registry.docker-cn.com",
    "https://mirror.ccs.tencentyun.com"
  ],
  "dns": ["119.29.29.29", "223.5.5.5", "8.8.8.8"],
  "max-concurrent-downloads": 10,
  "max-concurrent-uploads": 5,
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
```

### 4. 镜像加速器选择策略
- **百度云加速器**: `https://mirror.baidubce.com` (首选)
- **中科大加速器**: `https://docker.mirrors.ustc.edu.cn` (备选)
- **Docker 中国**: `https://registry.docker-cn.com` (备选)
- **腾讯云加速器**: `https://mirror.ccs.tencentyun.com` (备选)

### 5. 智能检测和配置
- 部署前自动测试所有镜像加速器连通性
- 只配置可用的镜像源
- 按照速度和可靠性排序

## 📊 性能对比

### 旧方案问题
- ❌ 单一镜像源可能会因网络问题无法访问
- ❌ 腾讯云加速器可能被 DNS 污染
- ❌ 缺乏备选方案导致部署失败

### 新方案优势
- ✅ 多个镜像源确保高可用性
- ✅ 智能检测选择最佳可用源
- ✅ 百度云加速器稳定性更好
- ✅ 自动降级和容错机制

## 🚀 部署验证

### 镜像拉取测试
```bash
# 测试基础镜像拉取（通过腾讯云加速器）
docker pull node:18-alpine
docker pull python:3.11-slim
docker pull nginx:alpine
docker pull mongo:5.0
docker pull redis:7-alpine
```

### 加速器连通性测试
```bash
# 测试所有镜像加速器
./scripts/test-docker-mirrors.sh

# 测试特定加速器
curl -s --connect-timeout 5 https://mirror.baidubce.com/v2/
curl -s --connect-timeout 5 https://docker.mirrors.ustc.edu.cn/v2/
```

### DNS 解析测试
```bash
# 测试腾讯云 DNS
nslookup mirror.baidubce.com
nslookup docker.mirrors.ustc.edu.cn
```

## 💡 最佳实践

1. **镜像选择**: 始终使用官方镜像名，避免使用特定注册表前缀
2. **加速器配置**: 优先使用百度云，配置多个备选源
3. **DNS 配置**: 优先使用腾讯云 DNS (119.29.29.29) 提升解析速度
4. **智能检测**: 部署前自动测试镜像加速器可用性
5. **并发优化**: 配置适当的并发下载数量提升构建速度
6. **日志管理**: 配置日志轮转避免磁盘空间问题

## 🔍 故障排查

### 常见问题
1. **镜像拉取失败**: 运行 `./scripts/test-docker-mirrors.sh` 检查可用源
2. **构建速度慢**: 确认使用了多个镜像加速器
3. **网络连接问题**: 检查 DNS 配置和防火墙设置
4. **磁盘空间不足**: 检查 Docker 日志配置

### 诊断命令
```bash
# 检查 Docker 配置
docker info | grep -A 10 "Registry Mirrors"

# 测试镜像加速器
./scripts/test-docker-mirrors.sh

# 检查 DNS 解析
nslookup mirror.baidubce.com

# 测试镜像拉取
docker pull hello-world:latest
```

## 📝 结论

通过使用**官方镜像名 + 多个国内镜像加速器**的策略，我们既保证了镜像的完整可用性，又获得了国内访问的速度优势。特别是百度云加速器的稳定性表现优异，这是一个既稳定又高效的解决方案。

### 关键改进
- 🚀 **多源备份**: 4个镜像加速器确保高可用
- 🎯 **智能选择**: 自动检测最佳可用源
- 🔄 **容错机制**: 单个源失败时自动切换
- 📊 **性能优化**: 百度云加速器响应速度更快
