#!/bin/bash

echo "🚀 使用您的密钥安装Docker - 快速启动脚本"
echo "============================================"

# 请在这里设置您的服务器信息
SERVER_IP="your_server_ip_here"  # 请替换为您的服务器IP
SERVER_USER="root"               # 服务器用户名

# 创建临时密钥文件
TEMP_KEY_FILE="/tmp/ai_server_key.pem"

# 将您的私钥写入临时文件
cat > "$TEMP_KEY_FILE" << 'EOF'
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAyfc/5qK33gCaKWF/CTrXcb+LBgAQE9MkgnDYqMd2dELElaT3
lBa6OeWsC6b4BGLukL50a1MGGSdi6s58HJu7KrCIwljIzZM1Knuj7aF9co6aeQzE
Vnt2rDEYLBDpbOn2WWRqg+GKdw0x6wHrtB0fd8f1VWgFJOsx/TvhzzQ+xngz6V8r
iJoi6CsLsqaTGs7Txi6Ox9Dr4ACQvaWNhf+JAfee+2s9n64/rSky5rq4+uxPd8jA
q3oFRmlQ3JzwmCLMtVcNgLuuPeEHGIZlTOvpjj4m/MjqfEZaCmC3aZpy6X1uRMy3
7cO2sl3S640iCwy5PXBexg5gVAUCq2Um6NTs+QIDAQABAoIBAA1ZlpO8NcMq7wXF
OAx4Iz2Vl67x2h41Wrh0lR2y8ZWFxFDP8r2LMwwYrmKmysYfc/2FWVSuzDxlahhz
RajuclTEDoYqMDvGe0EvowpWHmCwJG3T9jZxOsrvA9YF2Cgm3u3RwWiuQ+TSrnYG
Tno9YpMcWI8orQ5frZI7nxV/MpcTxMybxxIZqfBlSbjgumNAReBHIliNj2vnh08Y
2EwesHI+5Nn/TqWwMDpIyYEe/+WYyFSrmF1PrpLHsHiH3PGtK29goaKwNaW2NFxO
rqXg2vXZgFDDdtZ7nxblE2IBTFThz45l6Gn+rVVfsM8Z14lf0sfsAKqOoiDuXq+a
XzPxNvECgYEA+JGmOfcokOBrLa8XJcQsB7+eE7b+kstvuMt8af8R900+KORngqV1
59Ox8BRc3cub1G9B5IL25ZnFrDBLsAULCnjpa3fNo223IVhtxm1uvK5ZDtdHQnwF
z/0hCUYaLcAxggK4wEUAijwYNLn0Z1Qs9WwVTIGR3m5KlJ36qnQiMC8CgYEA0ADv
zYb/3n7uTxy1Spd7ukO6Kj350zPUfqzkY0ryf+wTk1kxE8wx2QDhpQsRcfXVcukX
szX7rz+IvXrk5yG93lU+iIvGi//r1+RRpmdv42/Sw9x6Wh3kBYevHgA9eQlCNJQD
9rguSzA+KUHADIxdCZCozkZrNguFB9HJG+A6A1cCgYBVzvHzUL9QRCi7vJXhE7ef
dSa85486XcBTqutoLAWnuaKbuz2AfF4XiZ0DpAPrDT7eNwooOI3C9TKoHoQCX7tQ
Ai2SS+lRYa62dDBxL5XqzMUxul9/NBFNm7Sr3udqo85zcz0UIr3s+pHgodEdWpGq
p4UyxAf3IVvdsiu2bCDhQQKBgQChClifU4n+hV+UOLHT0nyktZMI6XrmnhZDDTC1
/2zIxcpSJpfssAdX72rEEVGsXZyonvcOdRkrkZEYwnE+0cziujT0GuPZuIasW8Ur
hKIIAKe5pJXF96Z28ZoPLDhr4VM0yfRXrDmLVQqLfrBmBrZxlWJccgDHkxun9jAy
OOQxeQKBgAzl1CTHjbhRxKw4KQYdSGDGSHr5RQrbeKrNMjVIxvJMdzywDCcGRCX+
APznzfTOjkQbbdUu9c2Q8PvaB9eOSoNxkCfnToydx+ImFpwZu99Syb+WLVQeiVk6
YK83VO9P9C+zJeGs128IfRlS11OhKKJ90750dYbLtVj/j6Lsa80d
-----END RSA PRIVATE KEY-----
EOF

# 设置密钥文件权限
chmod 600 "$TEMP_KEY_FILE"

echo "📋 配置信息:"
echo "服务器IP: $SERVER_IP"
echo "用户名: $SERVER_USER"
echo "密钥文件: $TEMP_KEY_FILE"

# 检查是否设置了服务器IP
if [ "$SERVER_IP" = "your_server_ip_here" ]; then
    echo ""
    echo "❌ 请先编辑此脚本，设置正确的服务器IP地址！"
    echo "编辑文件: $0"
    echo "修改第6行: SERVER_IP=\"your_server_ip_here\""
    echo "改为: SERVER_IP=\"您的实际服务器IP\""
    echo ""
    rm -f "$TEMP_KEY_FILE"
    exit 1
fi

echo ""
echo "🔍 检查脚本依赖..."
if [ ! -f "scripts/ssh-install-docker.sh" ]; then
    echo "❌ 找不到安装脚本: scripts/ssh-install-docker.sh"
    echo "请确保在项目根目录下运行此脚本"
    rm -f "$TEMP_KEY_FILE"
    exit 1
fi

echo "✅ 依赖检查通过"

echo ""
echo "🚀 开始执行安装..."
bash scripts/ssh-install-docker.sh "$SERVER_IP" "$SERVER_USER" "$TEMP_KEY_FILE"

# 清理临时密钥文件
echo ""
echo "🧹 清理临时文件..."
rm -f "$TEMP_KEY_FILE"

echo ""
echo "✅ 安装完成！"
