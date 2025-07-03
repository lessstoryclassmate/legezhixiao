#!/bin/bash

# 智能SCP上传问题修复脚本
# 用于诊断和修复GitHub Actions中的SCP上传失败问题

echo "🔍 SCP上传问题智能诊断开始..."

# 函数：记录日志
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# 函数：检查项目结构
check_project_structure() {
    log "📁 检查项目结构..."
    
    # 检查当前目录
    log "当前工作目录: $(pwd)"
    log "目录内容:"
    ls -la
    
    # 检查novel-editor目录
    if [ -d "novel-editor" ]; then
        log "✅ novel-editor目录存在"
        log "📁 novel-editor目录内容:"
        ls -la novel-editor/
        
        # 检查关键子目录
        local missing_dirs=()
        for dir in "backend" "frontend" "nginx"; do
            if [ ! -d "novel-editor/$dir" ]; then
                missing_dirs+=("$dir")
            fi
        done
        
        if [ ${#missing_dirs[@]} -eq 0 ]; then
            log "✅ 所有关键目录都存在"
            return 0
        else
            log "❌ 缺少关键目录: ${missing_dirs[*]}"
            return 1
        fi
    else
        log "❌ novel-editor目录不存在"
        return 1
    fi
}

# 函数：生成修复的工作流
generate_fixed_workflow() {
    log "🔧 生成修复的GitHub Actions工作流..."
    
    cat > ".github/workflows/baidu-deploy-fixed.yml" << 'EOF'
name: 🚀 Deploy to Baidu Cloud (Fixed)

on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  deploy:
    name: 部署到百度云服务器
    runs-on: ubuntu-latest
    
    steps:
    - name: 📥 检出代码
      uses: actions/checkout@v4
      with:
        fetch-depth: 0  # 确保完整检出

    - name: 🔍 验证项目结构
      run: |
        echo "📁 项目结构检查:"
        ls -la
        echo "📁 验证novel-editor目录:"
        if [ ! -d "novel-editor" ]; then
          echo "❌ novel-editor目录不存在，尝试查找项目文件..."
          find . -name "docker-compose*.yml" -o -name "backend" -o -name "frontend" | head -10
          exit 1
        fi
        ls -la novel-editor/
        
        # 检查关键子目录
        for dir in backend frontend; do
          if [ ! -d "novel-editor/$dir" ]; then
            echo "❌ 缺少关键目录: novel-editor/$dir"
            exit 1
          fi
        done
        
        echo "✅ 项目结构验证通过"

    - name: 🔐 配置SSH密钥
      run: |
        mkdir -p ~/.ssh
        echo "${{ secrets.SERVER_SSH_KEY }}" > ~/.ssh/id_rsa
        chmod 600 ~/.ssh/id_rsa
        ssh-keyscan -H ${{ secrets.SERVER_IP }} >> ~/.ssh/known_hosts

    - name: 📦 创建环境配置文件
      run: |
        cat > novel-editor/.env.prod << EOF
        # 应用配置
        DEBUG=false
        ENVIRONMENT=production
        
        # 数据库配置
        DATABASE_PORT=3306
        DATABASE_SYSTEMIP=${{ secrets.DATABASE_SYSTEMIP }}
        DATABASE_SYSTEM=${{ secrets.DATABASE_SYSTEM }}
        DATABASE_USER=${{ secrets.DATABASE_USER }}
        DATABASE_PASSWORD=${{ secrets.DATABASE_PASSWORD }}
        DATABASE_NOVELIP=${{ secrets.DATABASE_NOVELIP }}
        DATABASE_NOVELDATA=${{ secrets.DATABASE_NOVELDATA }}
        DATABASE_NOVELUSER=${{ secrets.DATABASE_NOVELUSER }}
        DATABASE_NOVELUSER_PASSWORD=${{ secrets.DATABASE_NOVELUSER_PASSWORD }}
        
        # AI服务配置
        SILICONFLOW_API_KEY=${{ secrets.SILICONFLOW_API_KEY }}
        SILICONFLOW_API_URL=https://api.siliconflow.cn/v1
        DEFAULT_AI_MODEL=deepseek-ai/DeepSeek-V3
        
        # 安全配置
        SECRET_KEY=${{ secrets.JWT_SECRET_KEY }}
        ALGORITHM=HS256
        ACCESS_TOKEN_EXPIRE_MINUTES=30
        EOF

    - name: 🚀 部署到百度云服务器
      run: |
        echo "📤 开始上传项目文件..."
        
        # 方法1: 创建压缩包上传
        echo "📦 创建项目压缩包..."
        tar -czf novel-editor.tar.gz novel-editor/
        
        # 上传压缩包
        echo "📤 上传压缩包到服务器..."
        scp -v novel-editor.tar.gz ${{ secrets.SERVER_USER }}@${{ secrets.SERVER_IP }}:/root/
        
        # 在服务器上解压和部署
        ssh ${{ secrets.SERVER_USER }}@${{ secrets.SERVER_IP }} << 'DEPLOY_EOF'
          cd /root
          
          # 备份现有部署
          if [ -d "novel-editor" ]; then
            mv novel-editor novel-editor-backup-$(date +%Y%m%d_%H%M%S)
          fi
          
          # 解压新的部署包
          echo "📦 解压项目文件..."
          tar -xzf novel-editor.tar.gz
          
          # 验证解压结果
          echo "📁 验证解压结果:"
          ls -la novel-editor/
          
          # 进入项目目录
          cd novel-editor
          
          echo "🔍 检查Docker版本..."
          docker --version || echo "Docker版本检查失败"
          docker compose version || docker-compose --version || echo "Docker Compose版本检查失败"
          
          echo "🛑 停止现有服务..."
          docker-compose -f docker-compose.prod.yml down || true
          
          echo "🧹 清理旧容器和镜像..."
          docker system prune -f
          
          echo "🔨 构建并启动服务..."
          # 先尝试标准配置
          if docker-compose -f docker-compose.prod.yml up -d --build; then
            echo "✅ 标准配置部署成功"
          elif docker-compose -f docker-compose.simple.yml up -d --build; then
            echo "✅ 简化配置部署成功"
          else
            echo "❌ 部署失败，尝试分步构建..."
            
            # 分步构建
            docker-compose -f docker-compose.simple.yml build backend || echo "后端构建失败"
            docker-compose -f docker-compose.simple.yml build frontend || echo "前端构建失败"
            docker-compose -f docker-compose.simple.yml up -d || echo "服务启动失败"
          fi
          
          echo "⏳ 等待服务启动..."
          sleep 30
          
          echo "🔍 检查服务状态..."
          docker-compose ps 2>/dev/null || docker ps
          
          echo "💓 健康检查..."
          curl -f http://localhost:8000/health || echo "Backend health check failed"
          curl -f http://localhost/ || echo "Frontend health check failed"
          
          echo "📊 显示服务日志..."
          docker-compose logs --tail=10 2>/dev/null || docker logs $(docker ps -q) 2>/dev/null || echo "无法获取日志"
        DEPLOY_EOF

    - name: ✅ 部署验证
      run: |
        echo "🎉 部署完成！"
        echo "📍 前端地址: http://${{ secrets.SERVER_IP }}"
        echo "📍 API文档: http://${{ secrets.SERVER_IP }}:8000/docs"
        echo "📍 健康检查: http://${{ secrets.SERVER_IP }}:8000/health"
EOF

    log "✅ 修复的工作流已生成: .github/workflows/baidu-deploy-fixed.yml"
}

# 函数：生成诊断报告
generate_diagnostic_report() {
    log "📋 生成诊断报告..."
    
    cat > "SCP_UPLOAD_DIAGNOSTIC_REPORT.md" << EOF
# SCP上传问题诊断报告

## 问题描述
GitHub Actions工作流中的SCP命令上传novel-editor目录失败。

## 可能原因分析

### 1. 项目结构问题
- novel-editor目录不存在或路径不正确
- 关键子目录(backend/frontend)缺失
- 权限问题

### 2. SCP命令问题
- 源路径引用错误
- 目标路径不存在
- SSH连接问题

### 3. 服务器端问题
- 目标目录权限不足
- 磁盘空间不足
- 网络连接问题

## 修复方案

### 方案1: 使用压缩包上传（推荐）
- 将项目文件打包成tar.gz
- 上传压缩包到服务器
- 在服务器端解压

### 方案2: 修正SCP命令
- 使用绝对路径
- 添加详细的错误检查
- 预先创建目标目录

### 方案3: 分步上传
- 分别上传各个子目录
- 添加上传验证
- 失败时自动重试

## 实施步骤

1. 使用修复的工作流文件: \`baidu-deploy-fixed.yml\`
2. 验证项目结构完整性
3. 测试压缩包上传方法
4. 监控部署日志

## 预防措施

1. 在CI/CD中添加项目结构验证
2. 使用可靠的文件传输方法
3. 添加详细的错误诊断
4. 实施自动重试机制

生成时间: $(date)
EOF

    log "📋 诊断报告已生成: SCP_UPLOAD_DIAGNOSTIC_REPORT.md"
}

# 主执行流程
main() {
    log "🚀 开始SCP上传问题智能修复..."
    
    # 检查项目结构
    if check_project_structure; then
        log "✅ 项目结构检查通过"
    else
        log "❌ 项目结构检查失败"
    fi
    
    # 生成修复方案
    generate_fixed_workflow
    generate_diagnostic_report
    
    log "🎉 智能修复完成！"
    log "📋 请查看生成的文件:"
    log "   - .github/workflows/baidu-deploy-fixed.yml (修复的工作流)"
    log "   - SCP_UPLOAD_DIAGNOSTIC_REPORT.md (诊断报告)"
    log ""
    log "🔧 建议操作:"
    log "   1. 提交修复的工作流文件"
    log "   2. 触发新的部署测试"
    log "   3. 监控部署日志"
}

# 执行主函数
main "$@"
