#!/bin/bash
# 腾讯云 Docker 仓库连通性测试脚本

echo "🔍 腾讯云 Docker 仓库连通性测试"
echo "=================================="

# 测试 DNS 解析
echo "1. 测试 DNS 解析..."
if nslookup ccr.ccs.tencentyun.com > /dev/null 2>&1; then
    echo "✅ ccr.ccs.tencentyun.com DNS 解析正常"
    nslookup ccr.ccs.tencentyun.com | grep "Address:" | tail -n +2
else
    echo "❌ ccr.ccs.tencentyun.com DNS 解析失败"
fi

echo ""

# 测试网络连通性
echo "2. 测试网络连通性..."
if curl -s --connect-timeout 10 "https://ccr.ccs.tencentyun.com/v2/" > /dev/null; then
    echo "✅ 腾讯云 Docker 仓库网络连通正常"
else
    echo "❌ 腾讯云 Docker 仓库网络连通失败"
fi

echo ""

# 测试镜像拉取
echo "3. 测试镜像拉取..."
test_images=(
    "ccr.ccs.tencentyun.com/library/hello-world:latest"
    "ccr.ccs.tencentyun.com/library/alpine:latest"
)

for image in "${test_images[@]}"; do
    echo "🔄 测试拉取: $image"
    if timeout 60 docker pull "$image" > /dev/null 2>&1; then
        echo "✅ $image 拉取成功"
        # 清理测试镜像
        docker rmi "$image" > /dev/null 2>&1 || true
    else
        echo "❌ $image 拉取失败"
    fi
done

echo ""
echo "=================================="
echo "测试完成"
