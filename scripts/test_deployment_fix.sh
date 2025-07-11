#!/bin/bash

# 测试部署脚本的Git克隆逻辑
# 模拟GitHub Actions部署环境

set -e

echo "🧪 测试部署脚本的Git克隆逻辑"
echo "=================================="

# 创建测试目录
TEST_DIR="/tmp/deployment-test-$(date +%s)"
GITHUB_REPOSITORY="lessstoryclassmate/legezhixiao"

echo "📁 创建测试目录: $TEST_DIR"
mkdir -p "$TEST_DIR"

# 测试场景1: 空目录
echo ""
echo "🔬 测试场景1: 空目录克隆"
cd "$TEST_DIR"
mkdir -p empty-dir
cd empty-dir

if [ -d ".git" ]; then
  echo "📦 更新现有Git仓库..."
  git fetch origin
  git reset --hard origin/main
  git clean -fd
else
  echo "📦 初始化Git仓库..."
  if [ "$(ls -A . 2>/dev/null)" ]; then
    echo "⚠️  目录不为空，清理现有文件..."
    find . -maxdepth 1 -not -name '.' -not -name '..' -exec rm -rf {} + 2>/dev/null || true
  fi
  echo "🔄 克隆代码仓库..."
  for i in {1..3}; do
    if git clone https://github.com/$GITHUB_REPOSITORY .; then
      echo "✅ 代码克隆成功"
      break
    else
      echo "❌ 克隆失败，尝试第 $i 次重试..."
      sleep 2
      if [ $i -eq 3 ]; then
        echo "❌ 代码克隆最终失败"
        exit 1
      fi
    fi
  done
fi

# 验证克隆结果
if [ ! -f "docker-compose.yml" ]; then
  echo "❌ 关键文件缺失，代码克隆可能失败"
  ls -la
  exit 1
fi
echo "✅ 代码验证通过"

# 测试场景2: 非空目录
echo ""
echo "🔬 测试场景2: 非空目录清理后克隆"
cd "$TEST_DIR"
mkdir -p non-empty-dir
cd non-empty-dir

# 创建一些文件模拟非空目录
echo "dummy content" > dummy.txt
mkdir dummy-folder
echo "more content" > dummy-folder/file.txt

echo "📋 目录内容 (清理前):"
ls -la

if [ -d ".git" ]; then
  echo "📦 更新现有Git仓库..."
  git fetch origin
  git reset --hard origin/main
  git clean -fd
else
  echo "📦 初始化Git仓库..."
  if [ "$(ls -A . 2>/dev/null)" ]; then
    echo "⚠️  目录不为空，清理现有文件..."
    find . -maxdepth 1 -not -name '.' -not -name '..' -exec rm -rf {} + 2>/dev/null || true
  fi
  echo "🔄 克隆代码仓库..."
  for i in {1..3}; do
    if git clone https://github.com/$GITHUB_REPOSITORY .; then
      echo "✅ 代码克隆成功"
      break
    else
      echo "❌ 克隆失败，尝试第 $i 次重试..."
      sleep 2
      if [ $i -eq 3 ]; then
        echo "❌ 代码克隆最终失败"
        exit 1
      fi
    fi
  done
fi

# 验证克隆结果
if [ ! -f "docker-compose.yml" ]; then
  echo "❌ 关键文件缺失，代码克隆可能失败"
  ls -la
  exit 1
fi
echo "✅ 代码验证通过"

# 测试场景3: 已存在Git仓库
echo ""
echo "🔬 测试场景3: 已存在Git仓库更新"
cd "$TEST_DIR"
mkdir -p existing-git-dir
cd existing-git-dir

# 先克隆一次
git clone https://github.com/$GITHUB_REPOSITORY .

# 然后测试更新逻辑
if [ -d ".git" ]; then
  echo "📦 更新现有Git仓库..."
  if git fetch origin && git reset --hard origin/main && git clean -fd; then
    echo "✅ 代码更新成功"
  else
    echo "❌ Git更新失败，尝试重新克隆..."
    cd ..
    rm -rf existing-git-dir
    mkdir -p existing-git-dir
    cd existing-git-dir
    git clone https://github.com/$GITHUB_REPOSITORY .
  fi
else
  echo "📦 初始化Git仓库..."
  if [ "$(ls -A . 2>/dev/null)" ]; then
    echo "⚠️  目录不为空，清理现有文件..."
    find . -maxdepth 1 -not -name '.' -not -name '..' -exec rm -rf {} + 2>/dev/null || true
  fi
  echo "🔄 克隆代码仓库..."
  git clone https://github.com/$GITHUB_REPOSITORY .
fi

# 验证更新结果
if [ ! -f "docker-compose.yml" ]; then
  echo "❌ 关键文件缺失，代码更新可能失败"
  ls -la
  exit 1
fi
echo "✅ 代码验证通过"

# 清理测试目录
echo ""
echo "🧹 清理测试环境"
cd /tmp
rm -rf "$TEST_DIR"

echo ""
echo "🎉 所有测试场景通过！部署脚本的Git克隆逻辑已修复。"
echo "✅ 现在可以处理："
echo "   - 空目录克隆"
echo "   - 非空目录清理后克隆"  
echo "   - 现有Git仓库更新"
echo "   - 失败重试机制"
