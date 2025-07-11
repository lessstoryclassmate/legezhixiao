# MongoDB vm.max_map_count 系统参数修复

## 问题描述

在 CI/CD 流水线中，后端健康检查失败的主要原因是 MongoDB 的 `vm.max_map_count` 系统参数设置过低，导致 MongoDB 在容器中无法正常启动或分配足够内存。

### 错误日志

```
vm.max_map_count is too low
currentValue: 262144, recommendedMinimum: 1677720
```

## 解决方案

### 1. 系统参数调整

在 GitHub Actions workflow 中，在启动 Docker Compose 之前，增加系统参数调整步骤：

```yaml
- name: 提升 MongoDB vm.max_map_count 参数
  run: sudo sysctl -w vm.max_map_count=1677720
```

### 2. MongoDB 连接配置优化

在环境变量中添加完整的 MongoDB 连接字符串：

```bash
MONGODB_URL=mongodb://admin:密码@mongodb:27017/ai_novel_db
MONGO_INITDB_DATABASE=ai_novel_db
```

### 3. 增强的健康检查

改进了健康检查机制，在失败时输出详细的诊断信息：

- 系统参数状态
- 容器运行状态
- MongoDB 和后端容器日志

## 修改内容

### 构建阶段 (build job)

1. **系统参数调整**: 在构建 Docker 镜像前设置 `vm.max_map_count=1677720`
2. **MongoDB 连接配置**: 添加了 `MONGODB_URL` 和 `MONGO_INITDB_DATABASE` 环境变量
3. **增强日志**: 在健康检查失败时输出详细的诊断信息

### 部署阶段 (deploy job)

1. **生产环境参数**: 在部署脚本中同样设置 `vm.max_map_count=1677720`
2. **环境变量统一**: 确保生产环境的 MongoDB 连接配置与测试环境一致
3. **日志改进**: 增加了参数设置的确认信息

## 技术细节

### vm.max_map_count 参数说明

- **当前值**: 262144 (系统默认)
- **推荐值**: 1677720 (MongoDB 推荐)
- **作用**: 控制进程可以拥有的内存映射区域的最大数量

### MongoDB 启动依赖

后端服务在 `docker-compose.yml` 中使用 `condition: service_healthy` 依赖 MongoDB，只有 MongoDB 完全健康后，后端服务才会启动。

## 验证方法

### 本地验证

```bash
# 检查当前参数值
sysctl vm.max_map_count

# 设置参数
sudo sysctl -w vm.max_map_count=1677720

# 启动服务
docker-compose up -d
```

### CI/CD 验证

workflow 会在健康检查过程中输出详细日志，包括：
- 系统参数状态
- 容器运行状态
- MongoDB 和后端容器的详细日志

## 预期效果

1. **MongoDB 启动**: MongoDB 容器能够正常启动，没有内存映射警告
2. **后端健康**: 后端服务能够成功连接 MongoDB 并通过健康检查
3. **部署成功**: CI/CD 流水线能够顺利完成构建、测试和部署

## 后续监控

如果问题仍然存在，建议检查：
1. MongoDB 容器日志中的具体错误信息
2. 后端容器的连接日志
3. 网络连接状态
4. 磁盘空间和内存使用情况

---

**修改日期**: 2025-07-11  
**修改版本**: v1.0  
**状态**: 已应用
