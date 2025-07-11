# MongoDB 连接故障排除指南

## 问题描述

CI/CD 部署过程中出现 MongoDB 连接超时错误：`MongoDB 连接失败: timed out`，错误发生在后端容器尝试连接 `172.16.32.2:27017` 时。

## 故障诊断清单

### 1. 服务器端 MongoDB 状态检查

#### 检查 MongoDB 服务状态
```bash
# 检查 MongoDB 服务是否运行
sudo systemctl status mongod

# 如果服务未运行，启动服务
sudo systemctl start mongod

# 设置开机自启
sudo systemctl enable mongod
```

#### 检查端口监听状态
```bash
# 检查 MongoDB 是否监听正确的端口和 IP
netstat -tlnp | grep 27017

# 期望输出应该包含：
# tcp  0.0.0.0:27017  或  tcp  172.16.32.2:27017
# 如果只有 127.0.0.1:27017，说明只监听本地环回接口
```

#### 检查 MongoDB 配置文件
```bash
# 查看 MongoDB 配置文件
sudo cat /etc/mongod.conf

# 检查网络绑定配置
grep -A 5 "net:" /etc/mongod.conf
```

**正确的网络配置应该是**：
```yaml
net:
  port: 27017
  bindIp: 0.0.0.0  # 或者 127.0.0.1,172.16.32.2
```

**如果配置错误，修改为**：
```yaml
net:
  port: 27017
  bindIp: 0.0.0.0  # 允许所有 IP 访问，或指定内网 IP
```

修改后重启服务：
```bash
sudo systemctl restart mongod
```

### 2. 防火墙和安全组检查

#### 本地防火墙检查
```bash
# 检查 UFW 防火墙状态
sudo ufw status

# 如果 27017 端口未开放，添加规则
sudo ufw allow 27017

# 或者允许特定 IP 段访问
sudo ufw allow from 172.16.0.0/16 to any port 27017
```

#### iptables 检查
```bash
# 检查 iptables 规则
sudo iptables -L -n | grep 27017

# 如果需要添加规则
sudo iptables -A INPUT -p tcp --dport 27017 -j ACCEPT
```

#### 云平台安全组检查
确保云平台安全组已开放：
- **端口**: 27017
- **协议**: TCP
- **源地址**: 允许内网访问（如 172.16.0.0/16）

### 3. 网络连通性测试

#### 从服务器本地测试
```bash
# 测试本地连接
mongo --host 172.16.32.2 --port 27017

# 或使用 mongosh (新版本)
mongosh mongodb://172.16.32.2:27017

# 测试端口连通性
telnet 172.16.32.2 27017
```

#### 从容器内测试
```bash
# 进入后端容器
docker-compose exec backend bash

# 测试网络连通性
ping 172.16.32.2

# 测试端口连通性
telnet 172.16.32.2 27017
# 或
timeout 10 bash -c "echo > /dev/tcp/172.16.32.2/27017"
```

### 4. MongoDB 日志检查

```bash
# 查看 MongoDB 日志
sudo tail -f /var/log/mongodb/mongod.log

# 查看系统日志中的 MongoDB 相关信息
sudo journalctl -u mongod -f
```

**常见错误模式**：
- `bind failed`：绑定地址失败，检查 bindIp 配置
- `permission denied`：权限问题，检查文件权限
- `connection refused`：连接被拒绝，检查防火墙

### 5. Docker 网络配置检查

#### 检查 Docker 网络
```bash
# 列出 Docker 网络
docker network ls

# 检查应用网络详情
docker network inspect $(docker-compose ps -q | head -1 | xargs docker inspect --format='{{.NetworkSettings.Networks}}' | grep -o '[a-zA-Z0-9_-]*app[a-zA-Z0-9_-]*')
```

#### 网络模式备选方案
如果桥接网络有问题，可以临时使用 host 网络模式：

**docker-compose.yml** 修改：
```yaml
backend:
  build: ./backend
  network_mode: "host"  # 临时解决方案，仅用于测试
  environment:
    - MONGODB_URL=mongodb://127.0.0.1:27017/ai_novel_db
```

⚠️ **注意**: host 网络模式会降低安全性，仅建议用于问题诊断。

### 6. MongoDB 认证配置

当前使用匿名连接，确保 MongoDB 配置正确：

#### 检查认证设置
```bash
# 连接 MongoDB 并检查用户
mongo --host 172.16.32.2 --port 27017
> use admin
> db.runCommand({connectionStatus: 1})
```

#### 如果启用了认证但想使用匿名连接
编辑 `/etc/mongod.conf`：
```yaml
# 注释掉或移除 security 部分
# security:
#   authorization: enabled
```

重启服务：
```bash
sudo systemctl restart mongod
```

### 7. 应用层连接测试

#### Python 连接测试脚本
```python
import motor.motor_asyncio
import asyncio

async def test_mongodb_connection():
    try:
        client = motor.motor_asyncio.AsyncIOMotorClient('mongodb://172.16.32.2:27017')
        # 测试连接
        await client.admin.command('ping')
        print("✅ MongoDB 连接成功")
        
        # 测试数据库操作
        db = client.ai_novel_db
        collection = db.test
        result = await collection.insert_one({"test": "connection"})
        print(f"✅ 数据插入成功，ID: {result.inserted_id}")
        
        # 清理测试数据
        await collection.delete_one({"_id": result.inserted_id})
        print("✅ 测试数据清理完成")
        
    except Exception as e:
        print(f"❌ MongoDB 连接失败: {e}")
    finally:
        client.close()

# 运行测试
asyncio.run(test_mongodb_connection())
```

### 8. 常见解决方案

#### 方案 1: 修复 MongoDB 网络绑定
```bash
# 1. 编辑配置文件
sudo nano /etc/mongod.conf

# 2. 修改网络配置
net:
  port: 27017
  bindIp: 0.0.0.0

# 3. 重启服务
sudo systemctl restart mongod
```

#### 方案 2: 配置防火墙规则
```bash
# Ubuntu/Debian
sudo ufw allow from 172.16.0.0/16 to any port 27017

# CentOS/RHEL
sudo firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='172.16.0.0/16' port protocol='tcp' port='27017' accept"
sudo firewall-cmd --reload
```

#### 方案 3: 使用 Docker 容器运行 MongoDB
如果系统安装的 MongoDB 有问题，可以考虑使用 Docker 运行：

```yaml
# docker-compose.yml 添加 MongoDB 服务
mongodb:
  image: mongo:7.0
  ports:
    - "27017:27017"
  environment:
    - MONGO_INITDB_DATABASE=ai_novel_db
  command: mongod --bind_ip_all
  networks:
    - app-network
```

### 9. 监控和预防措施

#### 设置监控脚本
```bash
#!/bin/bash
# mongodb_health_check.sh

echo "MongoDB 健康检查 - $(date)"

# 检查服务状态
if systemctl is-active --quiet mongod; then
    echo "✅ MongoDB 服务运行中"
else
    echo "❌ MongoDB 服务未运行"
    exit 1
fi

# 检查端口监听
if netstat -tlnp | grep -q ":27017 "; then
    echo "✅ MongoDB 端口监听正常"
else
    echo "❌ MongoDB 端口未监听"
    exit 1
fi

# 检查连接
if timeout 5 bash -c "echo > /dev/tcp/172.16.32.2/27017" 2>/dev/null; then
    echo "✅ MongoDB 连接测试成功"
else
    echo "❌ MongoDB 连接测试失败"
    exit 1
fi

echo "✅ MongoDB 健康检查通过"
```

#### 定期检查任务
```bash
# 添加到 crontab
crontab -e

# 每 5 分钟检查一次
*/5 * * * * /path/to/mongodb_health_check.sh >> /var/log/mongodb_health.log 2>&1
```

### 10. 紧急恢复步骤

如果 MongoDB 完全无法连接：

1. **重启 MongoDB 服务**：
   ```bash
   sudo systemctl restart mongod
   ```

2. **重置配置文件**：
   ```bash
   sudo cp /etc/mongod.conf /etc/mongod.conf.backup
   sudo nano /etc/mongod.conf
   # 使用最简配置
   ```

3. **检查磁盘空间**：
   ```bash
   df -h
   # 确保 MongoDB 数据目录有足够空间
   ```

4. **临时使用本地 MongoDB 容器**：
   ```bash
   docker run -d --name temp-mongo -p 27017:27017 mongo:7.0
   ```

## 总结

MongoDB 连接问题通常由以下原因引起：
1. **网络绑定配置错误** (bindIp 设置)
2. **防火墙阻止连接**
3. **MongoDB 服务未启动**
4. **端口冲突或占用**
5. **Docker 网络配置问题**

按照上述步骤逐一排查，通常能够快速定位和解决问题。

---

**创建日期**: 2025-07-11  
**适用版本**: MongoDB 4.4+  
**环境**: Ubuntu/CentOS + Docker
