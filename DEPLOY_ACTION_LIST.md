# 🚀 部署行动清单

## 立即执行步骤

### 1. 在GitHub中设置Secrets
**路径**: 仓库 → Settings → Secrets and variables → Actions → New repository secret

**必须设置的Secrets**:
- [ ] `GITHUB_TOKEN_CUSTOM` = `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`
- [ ] `SERVER_SSH_KEY` = 您的SSH私钥内容
- [ ] `SERVER_IP` = `106.13.216.179`
- [ ] `SERVER_USER` = `root`
- [ ] `SILICONFLOW_API_KEY` = `sk-mjithqmjwccqgffouexthbavtnvftwkqjludpcxhrmeztcib`
- [ ] `JWT_SECRET_KEY` = 随机32+字符字符串
- [ ] `MONGO_PASSWORD` = `Lekairong350702`
- [ ] `REDIS_PASSWORD` = `Lekairong350702`

### 2. 验证GitHub Token（可选）
```bash
# 在本地测试Token有效性
./scripts/test_github_token.sh
```

### 3. 触发部署
- [ ] 推送代码到main分支（已完成）
- [ ] 或手动触发GitHub Actions工作流
- [ ] 监控Actions日志确认部署成功

### 4. 验证部署结果
- [ ] 访问 `http://106.13.216.179:80` (前端)
- [ ] 访问 `http://106.13.216.179:8000/health` (后端健康检查)
- [ ] 访问 `http://106.13.216.179:8000/docs` (API文档)

## 🎯 关键修复内容

✅ **问题**: `fatal: could not read Username for 'https://github.com'`  
✅ **解决**: 使用Token认证的HTTPS URL  
✅ **方法**: `https://$GITHUB_TOKEN@github.com/repo.git`

## ⚡ 快速验证

如果部署成功，您应该看到：
1. GitHub Actions工作流显示绿色✅
2. 前端页面正常加载
3. 后端API返回健康状态
4. 所有Docker容器正常运行

## 🚨 如果仍有问题

1. **检查Secrets设置**: 确保所有8个Secrets都已正确设置
2. **查看Actions日志**: 定位具体的错误信息
3. **SSH连接测试**: 确认服务器可以SSH连接
4. **Token权限验证**: 确认Token有repo权限

---
**状态**: ✅ 修复完成，等待部署测试  
**下一步**: 设置GitHub Secrets并触发部署
