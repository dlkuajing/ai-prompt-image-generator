#!/bin/bash
# 快速配置向导

set -e

# 颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

clear
echo "=========================================="
echo "   跨海帆-闪图 frp 快速配置向导"
echo "=========================================="
echo ""

# 步骤 1：获取服务器 IP
echo -e "${BLUE}步骤 1: 配置服务器信息${NC}"
read -p "请输入你的 Linode 服务器 IP 地址: " SERVER_IP

# 验证 IP 格式
if [[ ! $SERVER_IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    echo -e "${YELLOW}警告: IP 地址格式可能不正确${NC}"
fi

# 步骤 2：设置安全令牌
echo ""
echo -e "${BLUE}步骤 2: 设置安全令牌${NC}"
echo "建议使用强密码作为令牌（至少 20 个字符）"
read -p "请输入安全令牌 [默认: KuaHaiFan_ShanTu_2024_Secure_Token]: " TOKEN
TOKEN=${TOKEN:-KuaHaiFan_ShanTu_2024_Secure_Token}

# 步骤 3：设置 Dashboard 密码
echo ""
echo -e "${BLUE}步骤 3: 设置 Dashboard 密码${NC}"
read -sp "请输入 Dashboard 密码 [默认: KuaHaiFan2024!]: " DASHBOARD_PWD
echo ""
DASHBOARD_PWD=${DASHBOARD_PWD:-KuaHaiFan2024!}

# 更新配置文件
echo ""
echo -e "${GREEN}正在更新配置文件...${NC}"

# 更新 frpc.ini
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s/YOUR_LINODE_IP/${SERVER_IP}/g" frpc.ini
    sed -i '' "s/KuaHaiFan_ShanTu_2024_Secure_Token/${TOKEN}/g" frpc.ini
else
    # Linux
    sed -i "s/YOUR_LINODE_IP/${SERVER_IP}/g" frpc.ini
    sed -i "s/KuaHaiFan_ShanTu_2024_Secure_Token/${TOKEN}/g" frpc.ini
fi

# 更新 frps.ini
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/KuaHaiFan_ShanTu_2024_Secure_Token/${TOKEN}/g" frps.ini
    sed -i '' "s/KuaHaiFan2024!/${DASHBOARD_PWD}/g" frps.ini
else
    sed -i "s/KuaHaiFan_ShanTu_2024_Secure_Token/${TOKEN}/g" frps.ini
    sed -i "s/KuaHaiFan2024!/${DASHBOARD_PWD}/g" frps.ini
fi

echo -e "${GREEN}✓ 配置文件更新完成${NC}"

# 生成服务器安装命令
echo ""
echo "=========================================="
echo -e "${GREEN}配置完成！${NC}"
echo "=========================================="
echo ""
echo -e "${BLUE}下一步操作：${NC}"
echo ""
echo "1. 将配置文件上传到服务器:"
echo -e "${YELLOW}   scp frps.ini install-server.sh root@${SERVER_IP}:/root/${NC}"
echo ""
echo "2. 登录服务器并安装:"
echo -e "${YELLOW}   ssh root@${SERVER_IP}${NC}"
echo -e "${YELLOW}   chmod +x install-server.sh${NC}"
echo -e "${YELLOW}   ./install-server.sh${NC}"
echo ""
echo "3. 在本地启动客户端:"
echo -e "${YELLOW}   ./start-client.sh${NC}"
echo ""
echo "=========================================="
echo ""
echo "访问地址:"
echo "  - API 服务: http://${SERVER_IP}:8000"
echo "  - Web 界面: http://${SERVER_IP}:8888"
echo "  - Dashboard: http://${SERVER_IP}:7500"
echo "    用户名: admin"
echo "    密码: ${DASHBOARD_PWD}"
echo ""
echo "配置信息已保存到: frp-config.txt"

# 保存配置信息
cat > frp-config.txt << EOF
跨海帆-闪图 frp 配置信息
==========================
生成时间: $(date)

服务器 IP: ${SERVER_IP}
安全令牌: ${TOKEN}
Dashboard 密码: ${DASHBOARD_PWD}

访问地址:
- API 服务: http://${SERVER_IP}:8000
- Web 界面: http://${SERVER_IP}:8888  
- Dashboard: http://${SERVER_IP}:7500
  用户名: admin
  密码: ${DASHBOARD_PWD}

注意：请妥善保管此配置信息！
EOF

echo -e "${GREEN}配置信息已保存到 frp-config.txt${NC}"