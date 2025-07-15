# 百度云 Docker 镜像拉取指南

## 🎯 配置说明

已将部署脚本优化为使用百度云镜像加速器，删除了所有其他镜像源和 DNS 配置。

### 配置要点
- **唯一镜像源**: 仅使用百度云镜像 `https://mirror.baidubce.com`
- **镜像格式**: 使用简单格式如 `nginx:latest`
- **拉取方式**: 通过 `docker pull mirror.baidubce.com/library/` 前缀拉取
- **自动标签**: 拉取后自动添加常规标签方便使用

## 🔧 Docker 配置

### daemon.json 配置
```json
{
  "registry-mirrors": ["https://mirror.baidubce.com"],
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

### 重启 Docker 服务
```bash
sudo systemctl restart docker
```

## 📦 镜像拉取方法

### 1. 直接拉取方式
```bash
# 拉取镜像
docker pull mirror.baidubce.com/library/nginx:latest

# 添加标签
docker tag mirror.baidubce.com/library/nginx:latest nginx:latest

# 使用镜像
docker run nginx:latest
```

### 2. 使用助手脚本
```bash
# 拉取并自动添加标签
./scripts/baidu-pull.sh nginx:latest

# 查看常用镜像列表
./scripts/baidu-pull.sh --list

# 测试连通性
./scripts/baidu-pull.sh --test

# 配置镜像加速器
./scripts/baidu-pull.sh --config
```

## 🚀 当前项目镜像

### 基础镜像列表
```bash
# Node.js 环境
node:18-alpine

# Python 环境
python:3.11-slim

# Web 服务器
nginx:latest

# 数据库
mongo:latest
redis:latest
```

### 部署脚本中的拉取
```bash
# 自动拉取并添加标签
for image in "${BASE_IMAGES[@]}"; do
    docker pull "mirror.baidubce.com/library/$image"
    docker tag "mirror.baidubce.com/library/$image" "$image"
done
```

## 🔍 验证工具

### 1. 百度云镜像验证
```bash
./scripts/verify-baidu-mirror.sh
```

### 2. 部署脚本验证
```bash
./scripts/quick-deploy-fixed.sh
```

## 📋 最佳实践

### ✅ 推荐做法
1. **使用简单镜像格式**: `nginx:latest` 而不是 `docker.io/library/nginx:latest`
2. **自动添加标签**: 拉取后立即添加常规标签
3. **定期测试连通性**: 确保百度云镜像服务可用
4. **版本固定**: 生产环境使用具体版本标签

### ⚠️ 注意事项
1. **网络依赖**: 依赖百度云镜像服务可用性
2. **版本同步**: 确保百度云镜像与官方同步
3. **存储清理**: 定期清理不用的镜像标签
4. **备用方案**: 准备直接拉取的备用方案

## 🛠️ 故障排查

### 常见问题

#### 1. 镜像拉取失败
```bash
# 检查连通性
curl -s https://mirror.baidubce.com/v2/

# 检查配置
cat /etc/docker/daemon.json

# 重启 Docker
sudo systemctl restart docker
```

#### 2. 镜像不存在
```bash
# 确认镜像名称正确
docker search nginx

# 尝试直接拉取对比
docker pull nginx:latest
```

#### 3. 标签管理混乱
```bash
# 查看所有标签
docker images

# 清理不用的标签
docker rmi mirror.baidubce.com/library/nginx:latest
```

## 🔧 管理命令

### 镜像管理
```bash
# 查看所有镜像
docker images

# 清理悬空镜像
docker image prune

# 查看镜像详情
docker inspect nginx:latest

# 删除镜像
docker rmi nginx:latest
```

### 配置管理
```bash
# 查看 Docker 配置
docker info

# 重新加载配置
sudo systemctl reload docker

# 查看日志
sudo journalctl -u docker
```

## 📊 性能优化

### 拉取优化
- 并发下载数量: 3（适合大多数网络环境）
- 超时设置: 合理设置连接超时
- 重试机制: 失败时自动重试

### 存储优化
- 使用 overlay2 存储驱动
- 定期清理无用镜像
- 监控磁盘空间使用

## 🔄 升级和维护

### 定期维护
1. 测试百度云镜像连通性
2. 更新基础镜像版本
3. 清理旧版本镜像
4. 检查配置文件有效性

### 升级策略
1. 测试新版本镜像
2. 逐步替换基础镜像
3. 验证应用兼容性
4. 回滚机制准备

## 📚 参考资料

- [百度云镜像服务文档](https://cloud.baidu.com/doc/CCE/s/hjxpugvj0)
- [Docker 官方文档](https://docs.docker.com/)
- [部署脚本位置](./scripts/quick-deploy-fixed.sh)
- [验证脚本位置](./scripts/verify-baidu-mirror.sh)
- [助手脚本位置](./scripts/baidu-pull.sh)
