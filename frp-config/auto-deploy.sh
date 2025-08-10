#!/bin/bash
# 自动部署脚本 - 需要手动输入服务器密码

set -e

SERVER_IP="172.104.59.98"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

clear
echo "========================================"
echo "   FRP 服务器自动部署脚本"
echo "   服务器: ${SERVER_IP}"
echo "========================================"
echo ""
echo -e "${YELLOW}注意：执行过程中需要输入服务器密码${NC}"
echo ""
read -p "按回车键开始部署..." 

# 步骤1：上传配置文件
echo ""
echo -e "${BLUE}步骤 1: 上传配置文件到服务器${NC}"
echo "请输入服务器密码："
scp frps.ini root@${SERVER_IP}:/root/

echo -e "${GREEN}✓ 配置文件上传成功${NC}"

# 步骤2：创建安装脚本
echo ""
echo -e "${BLUE}步骤 2: 创建服务器安装脚本${NC}"

cat > /tmp/install_frp.sh << 'EOF'
#!/bin/bash
cd /root
echo "正在下载 FRP..."
wget -q https://github.com/fatedier/frp/releases/download/v0.52.3/frp_0.52.3_linux_amd64.tar.gz
echo "解压文件..."
tar -xzf frp_0.52.3_linux_amd64.tar.gz
cd frp_0.52.3_linux_amd64
cp /root/frps.ini .

echo "创建系统服务..."
cat > /etc/systemd/system/frps.service << 'EOFSVC'
[Unit]
Description=frp server
After=network.target

[Service]
Type=simple
User=root
Restart=on-failure
RestartSec=5s
WorkingDirectory=/root/frp_0.52.3_linux_amd64
ExecStart=/root/frp_0.52.3_linux_amd64/frps -c /root/frp_0.52.3_linux_amd64/frps.ini

[Install]
WantedBy=multi-user.target
EOFSVC

systemctl daemon-reload
systemctl enable frps
systemctl start frps

# 配置防火墙
if command -v ufw &> /dev/null; then
    ufw allow 7000/tcp
    ufw allow 7500/tcp
    ufw allow 8000/tcp
    ufw allow 8888/tcp
    ufw allow 8080/tcp
    echo "防火墙规则已添加"
fi

echo "FRP 服务安装完成！"
systemctl status frps --no-pager
EOF

# 步骤3：上传并执行安装脚本
echo "上传安装脚本（需要再次输入密码）："
scp /tmp/install_frp.sh root@${SERVER_IP}:/root/

echo ""
echo -e "${BLUE}步骤 3: 在服务器上执行安装${NC}"
echo "连接到服务器执行安装（需要再次输入密码）："
ssh root@${SERVER_IP} "chmod +x /root/install_frp.sh && /root/install_frp.sh"

echo ""
echo "========================================"
echo -e "${GREEN}部署完成！${NC}"
echo "========================================"
echo ""
echo "访问地址："
echo "  - Web 界面: http://${SERVER_IP}:8888"
echo "  - API 服务: http://${SERVER_IP}:8000"
echo "  - Dashboard: http://${SERVER_IP}:7500"
echo "    用户名: admin"
echo "    密码: KuaHaiFan2024!"
echo ""
echo "现在启动本地客户端："
echo "  cd frp-config && ./start-client.sh"
echo ""