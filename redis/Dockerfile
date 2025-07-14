# Redis with network diagnostic tools - 使用 Docker Hub 官方镜像
FROM redis:7-alpine

# 安装网络诊断工具 (Alpine 包管理器)
RUN apk add --no-cache \
    iproute2 \
    net-tools \
    bind-tools \
    iputils

# 保持原有的 Redis 配置和启动方式
