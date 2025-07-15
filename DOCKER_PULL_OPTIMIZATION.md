# Docker 镜像拉取优化指南

基于官方文档: https://docs.docker.com/reference/cli/docker/image/pull/

## 🎯 关键优化要点

### 1. 镜像命名规范
```bash
# ✅ 推荐: 使用完整的镜像名格式
docker.io/library/node:18-alpine
docker.io/library/python:3.11-slim

# ❌ 避免: 简写格式（虽然可用，但不明确）
node:18-alpine
python:3.11-slim
```

### 2. 并发下载配置
```json
{
  "max-concurrent-downloads": 3,  // 官方推荐值
  "max-concurrent-uploads": 5
}
```

**说明:**
- Docker 默认并发下载 3 个层
- 低带宽环境建议设置为 1-2
- 高带宽环境可适当增加到 5-10

### 3. 镜像加速器配置
```json
{
  "registry-mirrors": [
    "https://mirror.baidubce.com",
    "https://docker.mirrors.ustc.edu.cn",
    "https://registry.docker-cn.com",
    "https://mirror.ccs.tencentyun.com"
  ]
}
```

**优化策略:**
- 按地理位置和网络质量排序
- 定期测试连通性
- 设置多个备用镜像源

### 4. 高级拉取选项

#### 4.1 平台指定
```bash
# 确保镜像兼容性
docker pull --platform linux/amd64 nginx:alpine
```

#### 4.2 静默模式
```bash
# 减少输出干扰
docker pull --quiet alpine:latest
```

#### 4.3 摘要拉取
```bash
# 固定镜像版本
docker pull ubuntu@sha256:2e863c44b718727c860746568e1d54afd13b2fa71b160f5cd9058fc436217b30
```

#### 4.4 批量拉取
```bash
# 拉取所有标签
docker pull --all-tags alpine
```

### 5. 完整的 daemon.json 配置

```json
{
  "registry-mirrors": [
    "https://mirror.baidubce.com",
    "https://docker.mirrors.ustc.edu.cn",
    "https://registry.docker-cn.com",
    "https://mirror.ccs.tencentyun.com"
  ],
  "dns": ["119.29.29.29", "223.5.5.5", "8.8.8.8"],
  "max-concurrent-downloads": 3,
  "max-concurrent-uploads": 5,
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "insecure-registries": [],
  "live-restore": true
}
```

### 6. 镜像层优化

#### 6.1 层复用机制
- Docker 会自动复用相同的层
- 减少磁盘空间占用
- 加速后续拉取

#### 6.2 内容寻址存储
- 使用 SHA256 摘要确保完整性
- 支持镜像去重
- 提高缓存效率

### 7. 网络优化

#### 7.1 代理配置
```json
{
  "proxies": {
    "default": {
      "httpProxy": "http://proxy.example.com:3128",
      "httpsProxy": "http://proxy.example.com:3128",
      "noProxy": "*.test.example.com,.example2.com"
    }
  }
}
```

#### 7.2 DNS 优化
```json
{
  "dns": ["119.29.29.29", "223.5.5.5", "8.8.8.8"]
}
```

### 8. 错误处理策略

#### 8.1 超时处理
```bash
# 设置连接超时
docker pull --timeout 300 large-image:latest
```

#### 8.2 重试机制
```bash
# 脚本中的重试逻辑
for i in {1..3}; do
    if docker pull "$image"; then
        break
    else
        echo "重试 $i/3..."
        sleep 5
    fi
done
```

### 9. 监控和诊断

#### 9.1 拉取进度监控
```bash
# 详细输出模式
docker pull --progress=plain nginx:alpine
```

#### 9.2 镜像信息查看
```bash
# 查看镜像详细信息
docker inspect nginx:alpine
docker image ls --digests
```

### 10. 最佳实践清单

**✅ 应该做的:**
1. 使用完整的镜像名格式
2. 配置多个镜像加速器
3. 设置合理的并发下载数量
4. 定期清理无用镜像
5. 使用 digest 固定重要镜像版本

**❌ 避免的:**
1. 过高的并发下载数量
2. 单一镜像源依赖
3. 忽略镜像大小和层数
4. 不验证镜像完整性
5. 在生产环境使用 latest 标签

### 11. 故障排查

#### 11.1 常见错误
- `connection timeout`: 网络连接问题
- `manifest unknown`: 镜像不存在或标签错误
- `denied`: 权限问题

#### 11.2 诊断命令
```bash
# 测试镜像源连通性
curl -s https://mirror.baidubce.com/v2/

# 检查 Docker 配置
docker info

# 查看拉取日志
docker events --filter type=image
```

### 12. 性能优化建议

#### 12.1 网络环境优化
- 使用就近的镜像加速器
- 配置 DNS 缓存
- 启用 HTTP/2 支持

#### 12.2 存储优化
- 使用 overlay2 存储驱动
- 定期清理镜像缓存
- 监控磁盘空间使用

## 🔧 验证工具

使用提供的验证脚本测试配置：
```bash
./scripts/verify-docker-pull.sh
```

## 📚 参考资料

1. [Docker 官方文档 - docker pull](https://docs.docker.com/reference/cli/docker/image/pull/)
2. [Docker 官方文档 - daemon.json](https://docs.docker.com/reference/cli/dockerd/)
3. [Docker 官方文档 - 存储驱动](https://docs.docker.com/engine/storage/drivers/)
4. [Docker 官方文档 - 代理配置](https://docs.docker.com/reference/cli/dockerd/#proxy-configuration)
