# Docker 镜像拉取加速器配置说明

## 概述

本文档介绍了为解决 Docker 镜像拉取超时问题而实施的优化方案。主要包括镜像加速器配置、网络优化和重试机制。

## 问题背景

在 CI/CD 部署过程中经常遇到以下错误：
```
Error getting v2 registry: Get "https://registry-1.docker.io/v2/": net/http: request canceled while waiting for connection (Client.Timeout exceeded while awaiting headers)
Handler for POST /v1.51/images/create returned error
```

这些错误主要由以下原因造成：
1. 网络连接不稳定
2. Docker Hub 访问速度慢
3. 防火墙或网络策略限制
4. Docker 配置不当

## 解决方案

### 1. 镜像加速器配置

#### 配置文件位置
- `/etc/docker/daemon.json`

#### 配置内容
```json
{
  "registry-mirrors": [
    "https://registry-1.docker.io",
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com",
    "https://mirror.ccs.tencentyun.com",
    "https://registry.docker-cn.com",
    "https://dockerhub.azk8s.cn"
  ],
  "max-concurrent-downloads": 10,
  "max-concurrent-uploads": 5,
  "log-driver": "json-file",
  "log-level": "warn",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ],
  "dns": ["8.8.8.8", "114.114.114.114"],
  "insecure-registries": [],
  "live-restore": true
}
```

#### 特点说明
- **多镜像源**：配置了多个镜像源，确保高可用性
- **官方源优先**：优先使用官方源，保证镜像完整性
- **DNS优化**：配置了可靠的DNS服务器
- **并发控制**：合理设置并发数，避免网络过载

### 2. 自动化脚本

#### 2.1 Docker 镜像加速器配置脚本
- **文件**: `scripts/setup-docker-mirrors.sh`
- **功能**: 自动配置 Docker 镜像加速器并预下载常用镜像
- **使用方法**: `bash scripts/setup-docker-mirrors.sh`

#### 2.2 网络修复脚本
- **文件**: `scripts/fix-docker-network.sh`
- **功能**: 修复 Docker 网络问题，优化网络参数
- **使用方法**: `bash scripts/fix-docker-network.sh`

#### 2.3 便捷修复命令
安装后可使用 `fix-docker-network` 命令快速修复网络问题。

### 3. CI/CD 流程优化

#### 3.1 预配置阶段
在部署开始时自动运行镜像加速器配置：
```bash
if [ -f "scripts/setup-docker-mirrors.sh" ]; then
  chmod +x scripts/setup-docker-mirrors.sh
  bash scripts/setup-docker-mirrors.sh
fi
```

#### 3.2 构建阶段重试机制
- **重试次数**: 最多5次
- **超时设置**: 2400秒 (40分钟)
- **渐进式修复**: 随着重试次数增加，采取更强的修复措施

#### 3.3 网络状态监控
- 构建前检查网络连通性
- 失败时自动诊断问题类型
- 提供详细的错误日志

### 4. 预下载策略

#### 常用镜像预下载
系统会自动预下载以下常用镜像：
- `hello-world:latest`
- `alpine:latest`
- `ubuntu:20.04`
- `node:18-alpine`
- `python:3.11-slim`
- `nginx:alpine`
- `redis:alpine`

#### 好处
1. 减少构建时的下载时间
2. 提高构建成功率
3. 缓存热门镜像，避免重复下载

## 使用指南

### 1. 手动执行配置

#### 在服务器上执行：
```bash
# 配置镜像加速器
cd /opt/ai-novel-editor
bash scripts/setup-docker-mirrors.sh

# 如果遇到网络问题
bash scripts/fix-docker-network.sh
```

### 2. 验证配置

#### 检查配置是否生效：
```bash
# 查看镜像源配置
docker info | grep -A 20 "Registry Mirrors"

# 测试镜像拉取
docker pull hello-world

# 查看已下载镜像
docker images
```

### 3. 故障排除

#### 常用诊断命令：
```bash
# 检查 Docker 服务状态
sudo systemctl status docker

# 查看 Docker 配置
sudo cat /etc/docker/daemon.json

# 测试网络连通性
curl -I https://registry-1.docker.io/v2/

# 查看 Docker 系统信息
docker system info

# 清理 Docker 缓存
docker system prune -f
```

#### 如果问题持续存在：
1. 检查防火墙设置
2. 验证网络策略
3. 联系网络管理员
4. 考虑使用 VPN 或代理

### 4. 监控和维护

#### 定期检查：
1. 镜像源的可用性
2. Docker 服务的健康状态
3. 磁盘空间使用情况
4. 网络连接质量

#### 优化建议：
1. 根据实际情况调整并发数
2. 定期清理无用镜像
3. 监控构建时间和成功率
4. 根据地理位置选择最佳镜像源

## 技术细节

### 1. 网络优化参数
```bash
net.core.rmem_max=26214400
net.core.wmem_max=26214400
net.ipv4.tcp_congestion_control=bbr
net.ipv4.tcp_window_scaling=1
```

### 2. Docker 构建优化
```bash
export DOCKER_BUILDKIT=1
export BUILDKIT_PROGRESS=plain
export COMPOSE_HTTP_TIMEOUT=300
export DOCKER_CLIENT_TIMEOUT=300
```

### 3. 重试策略
- 第1-2次：基本重试
- 第3次：重启 Docker 服务
- 第4-5次：执行完整网络修复

## 总结

通过以上配置和优化，可以显著提高 Docker 镜像拉取的成功率和速度：

1. **提高成功率**: 多镜像源 + 重试机制
2. **提升速度**: 预下载 + 网络优化
3. **增强稳定性**: 自动修复 + 健康检查
4. **简化维护**: 自动化脚本 + 便捷命令

这些改进使部署过程更加稳定可靠，减少了因网络问题导致的部署失败。
