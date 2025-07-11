# MongoDB 连接故障排除指南

## 问题描述

CI/CD 部署时后端容器无法连接 MongoDB (`172.16.32.2:27017`)，报错 "MongoDB 连接失败: timed out"。

## 诊断步骤

### 1. 检查 MongoDB 服务状态

```bash
# 检查 MongoDB 服务是否运行
sudo systemctl status mongod

# 如果未运行，启动服务
sudo systemctl start mongod
sudo systemctl enable mongod
```

### 2. 检查 MongoDB 网络绑定

```bash
# 检查 MongoDB 是否监听正确的地址和端口
netstat -tlnp | grep 27017

# 应该看到类似以下输出之一:
# tcp  0.0.0.0:27017  (允许所有地址连接)
# tcp  172.16.32.2:27017  (只允许内网地址连接)

# 如果只看到 127.0.0.1:27017，则需要修改配置
```

### 3. 修改 MongoDB 配置文件

编辑 MongoDB 配置文件（通常位于 `/etc/mongod.conf`）：

```yaml
# /etc/mongod.conf
net:
  bindIp: 0.0.0.0  # 允许所有地址连接
  port: 27017

# 或者指定具体的内网地址
net:
  bindIp: 127.0.0.1,172.16.32.2
  port: 27017
```

修改后重启 MongoDB：

```bash
sudo systemctl restart mongod
sudo systemctl status mongod
```

### 4. 检查防火墙设置

```bash
# Ubuntu/Debian 系统
sudo ufw status
sudo ufw allow 27017

# CentOS/RHEL 系统
sudo firewall-cmd --list-ports
sudo firewall-cmd --permanent --add-port=27017/tcp
sudo firewall-cmd --reload
```

### 5. 检查云平台安全组

确保云平台（阿里云、腾讯云等）的安全组规则允许：
- 来源：内网网段 (172.16.0.0/16)
- 端口：27017
- 协议：TCP

### 6. 测试连接

```bash
# 从应用服务器测试连接
telnet 172.16.32.2 27017

# 使用 MongoDB 客户端测试
mongosh --host 172.16.32.2 --port 27017

# 测试基本操作
mongosh "mongodb://172.16.32.2:27017/ai_novel_db" --eval "db.adminCommand('ping')"
```

## 常见解决方案

### 方案 1: 标准配置修正

1. **修改 mongod.conf**：
```yaml
net:
  bindIp: 0.0.0.0
  port: 27017

security:
  authorization: disabled  # 如果使用匿名访问
```

2. **重启服务**：
```bash
sudo systemctl restart mongod
```

### 方案 2: 使用 Host 网络模式 (临时解决)

在 `docker-compose.yml` 中临时使用 host 网络：

```yaml
backend:
  network_mode: host  # 临时测试用
  # 注释掉 networks 和 ports 配置
```

### 方案 3: 配置 Docker 网络路由

```bash
# 添加路由规则
sudo route add -net 172.16.32.0/24 gw $(docker network inspect bridge --format='{{(index .IPAM.Config 0).Gateway}}')
```

### 方案 4: 使用容器内 MongoDB (备用方案)

如果外部 MongoDB 连接持续有问题，可以临时启用本地 MongoDB 容器：

```yaml
# docker-compose.yml 中添加
mongodb:
  image: mongo:7.0
  ports:
    - "27017:27017"
  environment:
    - MONGO_INITDB_DATABASE=ai_novel_db
  command: mongod --bind_ip_all
```

## 故障排除检查清单

- [ ] MongoDB 服务已启动 (`systemctl status mongod`)
- [ ] MongoDB 监听正确地址 (`netstat -tlnp | grep 27017`)
- [ ] 防火墙允许 27017 端口
- [ ] 云安全组允许内网访问 27017 端口
- [ ] 可以从应用服务器 telnet 到 MongoDB
- [ ] MongoDB 配置文件正确设置 bindIp
- [ ] 容器网络配置正确

## 验证脚本

创建一个验证脚本来测试所有连接：

```bash
#!/bin/bash
echo "=== MongoDB 连接验证 ==="

# 检查服务状态
echo "1. 检查 MongoDB 服务状态..."
sudo systemctl is-active mongod || echo "MongoDB 服务未运行"

# 检查端口监听
echo "2. 检查端口监听..."
netstat -tlnp | grep 27017 || echo "27017 端口未监听"

# 检查网络连接
echo "3. 检查网络连接..."
timeout 5 bash -c "echo > /dev/tcp/172.16.32.2/27017" && echo "✅ MongoDB 连接成功" || echo "❌ MongoDB 连接失败"

# 检查 MongoDB 响应
echo "4. 检查 MongoDB 响应..."
mongosh --host 172.16.32.2 --port 27017 --eval "db.adminCommand('ping')" --quiet || echo "MongoDB ping 失败"

echo "=== 验证完成 ==="
```

## 最佳实践

1. **生产环境配置**：
   - 使用防火墙限制访问来源
   - 启用 MongoDB 认证
   - 定期备份数据

2. **网络安全**：
   - 只允许必要的内网访问
   - 使用 VPN 或跳板机访问
   - 监控异常连接

3. **监控告警**：
   - 设置 MongoDB 连接监控
   - 配置服务异常告警
   - 记录连接日志

## 应急恢复

如果 MongoDB 连接问题严重影响部署，可以：

1. **临时使用本地容器**：启用 docker-compose 中的 MongoDB 服务
2. **回滚到上一版本**：使用备份目录恢复
3. **热修复配置**：直接在服务器上修改 .env 文件

---

**创建日期**: 2025-07-11  
**更新版本**: v1.0  
**适用环境**: Ubuntu/CentOS + MongoDB 7.0  
**紧急联系**: 检查服务器 MongoDB 配置和网络设置
