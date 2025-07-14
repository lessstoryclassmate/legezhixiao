# MongoDB with network diagnostic tools - 使用 Docker Hub 官方镜像
FROM mongo:5.0

# 安装网络诊断工具
RUN apt-get update && apt-get install -y \
    iproute2 \
    net-tools \
    dnsutils \
    iputils-ping \
    && rm -rf /var/lib/apt/lists/*

# 保持原有的 MongoDB 配置和启动方式
