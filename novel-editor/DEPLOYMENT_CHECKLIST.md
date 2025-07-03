# 🚀 GitHub Actions 部署检查清单

## 📋 部署前检查

### ✅ GitHub仓库配置
- [ ] 仓库已创建并推送代码
- [ ] 启用GitHub Actions
- [ ] 配置Branch Protection Rules (main分支)
- [ ] 设置Environment (development, production)

### ✅ Secrets配置
- [ ] SECRET_KEY
- [ ] SILICONFLOW_API_KEY  
- [ ] MYSQL_ROOT_PASSWORD
- [ ] KUBE_CONFIG_DEV (base64编码)
- [ ] KUBE_CONFIG_PROD (base64编码)
- [ ] SLACK_WEBHOOK (可选)
- [ ] SONAR_TOKEN (可选)

### ✅ Kubernetes集群准备
- [ ] 开发环境集群已准备就绪
- [ ] 生产环境集群已准备就绪
- [ ] kubectl访问权限已配置
- [ ] 命名空间已创建 (development, production)
- [ ] RBAC权限已配置
- [ ] Ingress Controller已安装

### ✅ Docker Registry
- [ ] GitHub Container Registry已启用
- [ ] 镜像推送权限已配置
- [ ] 多架构构建支持已启用

### ✅ 应用配置
- [ ] 数据库连接配置正确
- [ ] API密钥配置正确
- [ ] 健康检查端点已实现
- [ ] 日志配置已优化

## 🔄 部署流程

### 1️⃣ 初始部署
1. 推送代码到GitHub
2. 检查CI/CD流水线状态
3. 验证Docker镜像构建
4. 确认自动部署成功
5. 运行健康检查

### 2️⃣ 功能更新
1. 创建功能分支
2. 提交代码并创建PR
3. 等待CI检查通过
4. 合并到develop分支
5. 验证开发环境部署
6. 合并到main分支部署生产

### 3️⃣ 紧急修复
1. 创建hotfix分支
2. 快速修复并测试
3. 直接合并到main分支
4. 监控生产部署状态
5. 验证修复效果

## 🔍 验证检查

### ✅ 部署验证
- [ ] 前端页面可访问
- [ ] 后端API正常响应
- [ ] 数据库连接正常
- [ ] AI功能正常工作
- [ ] 用户注册登录正常

### ✅ 性能验证
- [ ] 页面加载时间 < 3秒
- [ ] API响应时间 < 500ms
- [ ] 并发用户支持 > 100
- [ ] 资源使用率 < 80%

### ✅ 安全验证
- [ ] HTTPS配置正确
- [ ] API认证正常
- [ ] 敏感信息已加密
- [ ] 安全扫描通过

## 🚨 故障排查

### 常见问题
1. **镜像构建失败**
   - 检查Dockerfile语法
   - 验证依赖安装
   - 查看构建日志

2. **部署超时**
   - 检查资源配额
   - 验证镜像拉取速度
   - 查看Pod事件

3. **健康检查失败**
   - 验证应用启动时间
   - 检查健康检查端点
   - 查看应用日志

4. **服务不可访问**
   - 检查Service配置
   - 验证Ingress规则
   - 确认网络策略

### 紧急联系
- 运维团队: ops@company.com
- 开发团队: dev@company.com
- 项目负责人: pm@company.com

---
📅 最后更新: Thu Jul  3 01:41:50 UTC 2025
👤 负责人: DevOps Team
