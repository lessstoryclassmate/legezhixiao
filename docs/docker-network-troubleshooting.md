# Docker 网络故障排除指南

## 常见问题和解决方案

### 1. app-network 网络不存在

**症状**: 
```
❌ app-network 网络不存在
容器路由检查失败
```

**解决方法**:
- 确保 `docker-compose.yml` 包含网络定义
- 检查 `docker-compose up` 命令是否成功执行
- 验证没有使用 `--no-deps` 或其他跳过网络的选项

### 2. 容器内缺少网络工具

**症状**:
```
ip: executable file not found in $PATH
ifconfig: command not found
```

**解决方法**:
在 Dockerfile 中添加网络工具:
```dockerfile
RUN apt-get update && apt-get install -y \
    iproute2 \
    iputils-ping \
    net-tools \
    && rm -rf /var/lib/apt/lists/*
```

### 3. 容器间网络不通

**症状**:
```
❌ backend -> mongodb 网络不通
ping: mongodb: Name or service not known
```

**解决方法**:
- 确保所有服务都连接到同一网络
- 检查服务名称是否正确
- 验证容器是否都在运行状态

### 4. 健康检查失败

**症状**:
```
❌ 后端健康检查失败
curl: (7) Failed to connect to localhost port 8000
```

**解决方法**:
- 检查服务是否实际启动
- 验证端口映射配置
- 查看应用日志排查启动错误

## 调试命令

### 网络检查
```bash
# 检查网络列表
docker network ls

# 检查特定网络
docker network inspect app-network

# 检查容器网络连接
docker-compose exec backend ping mongodb
```

### 容器状态
```bash
# 检查所有服务状态
docker-compose ps

# 查看服务日志
docker-compose logs backend
docker-compose logs mongodb
docker-compose logs redis
```

### 网络连通性
```bash
# 在容器内检查网络
docker-compose exec backend ip addr
docker-compose exec backend ip route
docker-compose exec backend netstat -tlnp
```

## 预防措施

1. **使用健康检查**: 确保服务真正可用后再开始下一步
2. **等待时间**: 给服务足够的启动时间
3. **错误处理**: 脚本中添加适当的错误检查和日志
4. **工具安装**: 在容器中安装必要的调试工具
5. **网络隔离**: 使用专用网络避免端口冲突
