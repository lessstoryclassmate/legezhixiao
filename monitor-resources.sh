#!/bin/bash
echo "📊 系统资源监控"
echo "================"
echo "内存使用："
free -h
echo
echo "磁盘使用："
df -h
echo
echo "Docker 容器状态："
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo
echo "Docker 系统信息："
docker system df
