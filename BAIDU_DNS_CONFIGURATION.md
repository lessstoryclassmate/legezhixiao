# 百度云DNS和镜像配置指南

## 🎯 配置概述

使用百度云DNS服务和百度云Docker镜像加速器，提供稳定可靠的网络服务。

## 🌐 DNS配置

### 百度云DNS
- **主DNS**: 180.76.76.76
- **备用DNS**: 8.8.8.8 (Google DNS)

### 配置方法
```bash
# 手动配置
sudo bash -c 'cat > /etc/resolv.conf <<EOF
nameserver 180.76.76.76
nameserver 8.8.8.8
EOF'

# 或使用验证脚本
./scripts/verify-baidu-dns.sh
```

## 🐳 Docker配置

### 镜像加速器
- **百度云镜像**: https://registry.baidubce.com
- **拉取格式**: `docker pull registry.baidubce.com/library/镜像名:标签`

### daemon.json配置
```json
{
  "registry-mirrors": ["https://registry.baidubce.com"],
  "dns": ["180.76.76.76", "8.8.8.8"],
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
```

## 📦 镜像拉取

### 基础镜像列表
```bash
# 使用简单格式，下载最新版本
BASE_IMAGES=(
    "node:18-alpine"
    "python:3.11-slim"
    "nginx:latest"
    "mongo:latest"
    "redis:latest"
)
```

### 拉取命令
```bash
# 直接通过百度云镜像拉取
docker pull registry.baidubce.com/library/nginx:latest

# 添加常规标签
docker tag registry.baidubce.com/library/nginx:latest nginx:latest
```

## 🔧 验证工具

### 1. DNS验证脚本
```bash
./scripts/verify-baidu-dns.sh
```

**功能:**
- 配置百度云DNS
- 测试DNS解析性能
- 验证网络连接
- 测试镜像加速器连通性

### 2. 完整部署脚本
```bash
./scripts/quick-deploy-fixed.sh
```

**功能:**
- 自动配置百度云DNS
- 配置Docker使用百度云镜像加速器
- 预拉取所需镜像
- 完成应用部署

## 🚀 优势

### DNS优势
- **稳定性**: 百度云DNS提供高可用性
- **速度**: 针对中国大陆网络优化
- **可靠性**: 备用DNS确保服务连续性

### 镜像加速器优势
- **速度**: 百度云镜像加速器提供快速下载
- **稳定性**: 减少网络波动影响
- **简化**: 统一使用单一镜像源

## 📋 使用检查清单

### 部署前检查
- [ ] 确认网络连接正常
- [ ] 验证DNS解析功能
- [ ] 测试镜像加速器连通性
- [ ] 检查Docker服务状态

### 部署后验证
- [ ] 确认DNS配置生效
- [ ] 验证镜像拉取成功
- [ ] 检查应用服务状态
- [ ] 测试网络连接稳定性

## 🛠️ 故障排查

### DNS解析失败
1. 检查网络连接
2. 验证DNS服务器可达性
3. 尝试使用备用DNS
4. 检查防火墙配置

### 镜像拉取失败
1. 验证镜像加速器连通性
2. 检查Docker daemon配置
3. 确认镜像名称和标签正确
4. 检查磁盘空间

### 网络连接问题
1. 测试基础网络连接
2. 检查路由配置
3. 验证防火墙设置
4. 确认DNS解析正常

## 🔄 维护建议

### 定期检查
- 每周验证DNS配置
- 定期测试镜像加速器
- 监控网络连接质量
- 检查Docker配置有效性

### 优化建议
- 根据网络环境调整DNS配置
- 监控镜像拉取性能
- 定期清理无用镜像
- 保持配置文件更新

## 📞 支持

如果遇到问题，请按以下顺序排查：
1. 运行DNS验证脚本
2. 检查网络连接
3. 验证Docker配置
4. 查看系统日志

---

**配置文件位置:**
- DNS配置: `/etc/resolv.conf`
- Docker配置: `/etc/docker/daemon.json`
- 验证脚本: `./scripts/verify-baidu-dns.sh`
