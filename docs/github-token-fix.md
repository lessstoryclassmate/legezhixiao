# 🔧 GitHub Token 认证修复报告

## 问题描述
部署脚本在尝试克隆私有仓库时出现错误：
```
fatal: could not read Username for 'https://github.com': No such device or address
```

## 根本原因
- 使用普通 HTTPS URL 克隆私有仓库，没有提供身份认证
- GitHub Actions 的 secrets 没有正确传递到部署脚本
- 服务器环境无法交互式输入用户名密码

## 修复方案

### 1. ✅ 添加 GITHUB_TOKEN 环境变量
在 GitHub Actions 工作流中添加 `GITHUB_TOKEN`：
```yaml
env:
  GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### 2. ✅ 修改 Git 克隆 URL
将原来的：
```bash
git clone https://github.com/lessstoryclassmate/legezhixiao .
```

修改为：
```bash
git clone "https://${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git" .
```

### 3. ✅ 增强错误处理
- 添加环境变量检查
- 提供详细的调试信息
- 实现重试机制

### 4. ✅ 安全考虑
- 使用 GitHub 内置的 `GITHUB_TOKEN`，无需额外配置
- 自动具有仓库访问权限
- 会在 workflow 结束后自动失效

## 修改的文件

### 1. `.github/workflows/deploy-advanced.yml`
- 添加 `GITHUB_TOKEN` 环境变量
- 修改部署脚本中的 git clone 命令
- 增强错误处理和调试信息

### 2. `scripts/deploy-with-token.sh`
- 新建专用的Token认证部署脚本
- 包含完整的环境变量检查
- 提供详细的调试信息

### 3. `scripts/test-github-token.sh`
- 创建Token权限测试脚本
- 用于诊断Token相关问题

## 使用说明

### GitHub Actions 自动部署
部署会在推送到 main 分支时自动触发，现在使用 Token 认证：
```bash
git add .
git commit -m "fix: 修复GitHub Token认证问题"
git push origin main
```

### 手动测试 Token 权限
```bash
export GITHUB_TOKEN="your_token_here"
export GITHUB_REPOSITORY="lessstoryclassmate/legezhixiao"
./scripts/test-github-token.sh
```

### 手动部署到服务器
```bash
# 在服务器上设置环境变量
export GITHUB_TOKEN="your_token_here"
export GITHUB_REPOSITORY="lessstoryclassmate/legezhixiao"
export SERVER_IP="106.13.216.179"
export MONGO_PASSWORD="your_mongo_password"
export REDIS_PASSWORD="your_redis_password"
export JWT_SECRET_KEY="your_jwt_secret"
export SILICONFLOW_API_KEY="your_api_key"

# 运行部署脚本
./scripts/deploy-with-token.sh
```

## 优势

1. **无需额外配置**：使用 GitHub 内置的 `GITHUB_TOKEN`
2. **自动权限管理**：Token 自动具有仓库访问权限
3. **安全性**：Token 在 workflow 结束后自动失效
4. **兼容性**：支持私有和公开仓库
5. **错误诊断**：提供详细的调试信息

## 故障排除

### 如果仍然出现认证错误：
1. 检查 `GITHUB_TOKEN` 是否正确传递
2. 确认仓库是私有还是公开
3. 运行测试脚本诊断问题
4. 检查网络连接和防火墙设置

### 常见问题：
- **Token 长度为 0**：环境变量未正确设置
- **API 访问失败**：网络问题或 Token 无效
- **克隆失败但 API 成功**：Git 配置问题

## 下一步
1. 提交修复并测试部署
2. 监控 GitHub Actions 日志
3. 验证服务器上的服务状态
4. 确认所有功能正常工作

---

**修复完成时间**: $(date)
**修复版本**: 增强的 Token 认证版本
**测试状态**: 待验证
