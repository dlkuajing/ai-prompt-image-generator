#!/bin/bash
# Linode 服务器部署脚本
# 服务器 IP: 172.104.59.98

set -e

SERVER_IP="172.104.59.98"
SERVER_KEY="ce755101ccd9452c"

echo "======================================"
echo "   部署 frp 到 Linode 服务器"
echo "   服务器: ${SERVER_IP}"
echo "======================================"
echo ""

# 步骤 1: 上传文件
echo "步骤 1: 上传配置文件到服务器..."
echo "执行命令："
echo "scp frps.ini install-server.sh root@${SERVER_IP}:/root/"
echo ""
read -p "按回车键继续上传文件..." 

scp frps.ini install-server.sh root@${SERVER_IP}:/root/

echo "✅ 文件上传完成"
echo ""

# 步骤 2: SSH 连接命令
echo "步骤 2: 连接到服务器并安装"
echo ""
echo "即将执行以下命令："
echo "1. chmod +x /root/install-server.sh"
echo "2. /root/install-server.sh"
echo ""
echo "请在服务器上执行安装脚本..."
echo ""

# SSH 连接并执行命令
ssh root@${SERVER_IP} << 'ENDSSH'
echo "已连接到服务器"
cd /root
chmod +x install-server.sh
./install-server.sh
ENDSSH

echo ""
echo "======================================"
echo "✅ 服务器部署完成！"
echo "======================================"
echo ""
echo "访问地址："
echo "  - API 服务: http://${SERVER_IP}:8000"
echo "  - Web 界面: http://${SERVER_IP}:8888"
echo "  - Dashboard: http://${SERVER_IP}:7500"
echo "    用户名: admin"
echo "    密码: KuaHaiFan2024!"
echo ""