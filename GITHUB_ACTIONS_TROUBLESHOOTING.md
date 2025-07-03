# 🔍 GitHub Actions 部署检查清单

## 📋 快速诊断步骤

### 1. 确认GitHub Actions页面访问
- 访问：https://github.com/lessstoryclassmate/legezhixiao
- 点击 `Actions` 选项卡
- 应该看到 `AI Novel Editor Deploy` 工作流

### 2. 检查工作流状态
- 如果看到工作流但是失败了，点击查看详细日志
- 如果完全看不到工作流，请继续下面的步骤

### 3. 手动触发测试
- 在Actions页面点击 `AI Novel Editor Deploy`
- 点击 `Run workflow` 按钮
- 选择 `main` 分支
- 点击绿色的 `Run workflow` 按钮

### 4. 验证GitHub Secrets配置
确保以下Secrets已在仓库设置中配置：

#### 必需的Secrets：
- `SERVER_IP` = 106.13.216.179
- `SERVER_USER` = root  
- `SERVER_SSH_KEY` = [您的SSH私钥]
- `DATABASE_SYSTEMIP` = 172.16.16.3
- `DATABASE_SYSTEM` = novel_data
- `DATABASE_USER` = lkr
- `DATABASE_PASSWORD` = Lekairong350702
- `DATABASE_NOVELIP` = 172.16.16.2
- `DATABASE_NOVELDATA` = novel_user_data
- `DATABASE_NOVELUSER` = novel_data_user
- `DATABASE_NOVELUSER_PASSWORD` = Lekairong350702
- `SILICONFLOW_API_KEY` = sk-mjithqmjwccqgffouexthbavtnvftwkqjludpcxhrmeztcib
- `JWT_SECRET_KEY` = [32位以上随机字符串]

### 5. 仓库权限检查
- 确认您是仓库的管理员或有Actions权限
- 检查仓库是否启用了GitHub Actions

### 6. 浏览器缓存清理
- 按 Ctrl+F5 强制刷新页面
- 或清除浏览器缓存后重新访问

## 🚨 常见问题解决

### 问题1: 完全看不到Actions选项卡
**原因**: 仓库可能禁用了Actions
**解决**: Settings → Actions → General → 启用Actions

### 问题2: 看到Actions但没有工作流
**原因**: 工作流文件可能有语法错误
**解决**: 检查 `.github/workflows/deploy.yml` 文件

### 问题3: 工作流运行失败
**原因**: Secrets配置缺失或错误
**解决**: 检查并重新配置所有必需的Secrets

### 问题4: SSH连接失败
**原因**: SSH密钥格式错误或服务器配置问题
**解决**: 
1. 确认SSH密钥包含完整的BEGIN/END标记
2. 测试SSH连接: `ssh root@106.13.216.179`

## 🎯 成功指标

### 部署成功后应该看到：
- ✅ 工作流运行完成（绿色✓）
- ✅ 所有步骤成功执行
- ✅ 服务健康检查通过

### 验证部署结果：
- 前端页面: http://106.13.216.179
- API文档: http://106.13.216.179:8000/docs  
- 健康检查: http://106.13.216.179:8000/health

## 📞 获取帮助

如果上述步骤都无法解决问题：
1. 提供GitHub Actions页面的截图
2. 描述具体看到的错误信息
3. 确认已按清单配置所有Secrets

---

**🔍 请按此清单逐步检查，找出GitHub Actions不显示的具体原因。**
