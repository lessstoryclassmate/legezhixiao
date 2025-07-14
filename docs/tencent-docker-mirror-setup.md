# 腾讯云Docker镜像加速器配置说明

## 更改概述

已成功删除所有其他镜像加速器配置，统一使用腾讯云容器镜像服务 (CCR)。

## 主要更改

### 1. 删除的镜像源
- ❌ 百度云镜像: `mirror.baidubce.com`
- ❌ Docker代理: `dockerproxy.com`
- ❌ 中科大镜像: `docker.mirrors.ustc.edu.cn`
- ❌ 清华大学镜像: `mirrors.tuna.tsinghua.edu.cn`

### 2. 新增的腾讯云配置
- ✅ 腾讯云镜像: `ccr.ccs.tencentyun.com`

## 配置方式

### 自动配置脚本
- 新增: `scripts/setup-tencent-docker.sh`
- 功能: 自动配置腾讯云Docker镜像加速器

### Docker Daemon 配置
```json
{
  "registry-mirrors": ["https://ccr.ccs.tencentyun.com"],
  "dns": ["223.5.5.5", "8.8.8.8"],
  "max-concurrent-downloads": 5,
  "max-concurrent-uploads": 3,
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
```

## 更新的脚本

### 1. 部署脚本
- `scripts/quick-deploy.sh` - 主部署脚本
- `scripts/network-fix-all.sh` - 网络修复脚本
- `scripts/ci-dns-fix.sh` - CI环境DNS修复

### 2. 诊断脚本
- `scripts/network-deep-diagnosis.sh` - 深度网络诊断
- `scripts/network-connection-fix.sh` - 网络连接修复
- `scripts/dns-fix.sh` - DNS修复脚本

### 3. GitHub Actions
- `.github/workflows/deploy.yml` - 部署工作流

## 使用方法

### 自动配置
```bash
# 运行腾讯云镜像配置脚本
sudo ./scripts/setup-tencent-docker.sh
```

### 手动拉取示例
```bash
# 标准拉取（使用配置的镜像加速器）
docker pull nginx:latest

# 直接从腾讯云拉取
docker pull ccr.ccs.tencentyun.com/library/nginx:latest

# 拉取官方镜像
docker pull ccr.ccs.tencentyun.com/library/node:18-alpine
docker pull ccr.ccs.tencentyun.com/library/python:3.11-slim
```

### 验证配置
```bash
# 查看Docker镜像配置
docker info | grep -A 5 "Registry Mirrors"

# 测试拉取
docker pull ccr.ccs.tencentyun.com/library/hello-world:latest
```

## CI/CD 流程

### GitHub Actions 更新
1. 自动上传腾讯云配置脚本
2. 在部署前配置腾讯云镜像加速器
3. 验证镜像拉取功能

### 部署流程
1. 🔄 上传所有脚本到服务器
2. 🐳 配置腾讯云Docker镜像加速器
3. 🚪 检查和修复端口冲突
4. 🔧 修复网络和DNS问题
5. 🚀 执行部署

## 优势

### 腾讯云优势
- ✅ 国内访问速度快
- ✅ 稳定性高
- ✅ 支持官方镜像库
- ✅ 减少拉取失败

### 配置优势
- ✅ 统一镜像源，减少复杂性
- ✅ 自动化配置脚本
- ✅ 完整的测试和验证
- ✅ 兼容现有部署流程

## 故障排除

### 如果镜像拉取失败
```bash
# 检查Docker配置
docker info | grep -A 10 "Registry Mirrors"

# 重新配置
sudo ./scripts/setup-tencent-docker.sh

# 手动重启Docker
sudo systemctl restart docker
```

### 回退到官方源
```bash
# 备份并删除配置
sudo mv /etc/docker/daemon.json /etc/docker/daemon.json.backup
sudo systemctl restart docker
```

## 监控和维护

### 定期检查
- 验证腾讯云镜像服务可用性
- 监控Docker拉取性能
- 检查配置文件完整性

### 日志查看
```bash
# Docker服务日志
sudo journalctl -u docker.service

# 镜像拉取日志
docker pull --quiet=false <image_name>
```

## 注意事项

1. **网络环境**: 确保服务器可以访问腾讯云服务
2. **权限要求**: 配置脚本需要sudo权限
3. **服务重启**: 配置更改需要重启Docker服务
4. **兼容性**: 适用于所有Docker版本

---

配置完成后，所有Docker镜像拉取将优先使用腾讯云加速器，提高部署效率和成功率。
