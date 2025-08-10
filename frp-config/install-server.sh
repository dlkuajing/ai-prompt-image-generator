#!/bin/bash
# frp 服务端安装脚本 (在 Linode 服务器上运行)
# 支持系统: Ubuntu/Debian/CentOS

set -e

# 配置变量
FRP_VERSION="0.52.3"
INSTALL_DIR="/opt/frp"
SERVICE_FILE="/etc/systemd/system/frps.service"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 打印带颜色的信息
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# 检查是否为 root 用户
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "此脚本需要 root 权限运行"
        echo "请使用: sudo bash $0"
        exit 1
    fi
}

# 检测系统架构
detect_arch() {
    ARCH=$(uname -m)
    if [[ "$ARCH" == "x86_64" ]]; then
        ARCH="amd64"
    elif [[ "$ARCH" == "aarch64" ]]; then
        ARCH="arm64"
    else
        print_error "不支持的系统架构: $ARCH"
        exit 1
    fi
    print_info "检测到系统架构: $ARCH"
}

# 下载 frp
download_frp() {
    print_info "正在下载 frp v${FRP_VERSION}..."
    
    # 创建安装目录
    mkdir -p ${INSTALL_DIR}
    cd /tmp
    
    # 下载 frp
    DOWNLOAD_URL="https://github.com/fatedier/frp/releases/download/v${FRP_VERSION}/frp_${FRP_VERSION}_linux_${ARCH}.tar.gz"
    wget -q --show-progress ${DOWNLOAD_URL} -O frp.tar.gz
    
    # 解压
    tar -xzf frp.tar.gz
    
    # 移动文件
    mv frp_${FRP_VERSION}_linux_${ARCH}/frps ${INSTALL_DIR}/
    mv frp_${FRP_VERSION}_linux_${ARCH}/frps.ini ${INSTALL_DIR}/frps.ini.example
    
    # 清理
    rm -rf frp.tar.gz frp_${FRP_VERSION}_linux_${ARCH}
    
    print_info "frp 下载完成"
}

# 配置 frps
configure_frps() {
    print_info "配置 frps..."
    
    # 备份示例配置
    if [[ -f "${INSTALL_DIR}/frps.ini" ]]; then
        cp ${INSTALL_DIR}/frps.ini ${INSTALL_DIR}/frps.ini.bak.$(date +%Y%m%d_%H%M%S)
    fi
    
    # 复制配置文件
    if [[ -f "./frps.ini" ]]; then
        cp ./frps.ini ${INSTALL_DIR}/frps.ini
        print_info "已复制配置文件"
    else
        print_warning "未找到 frps.ini，请手动配置 ${INSTALL_DIR}/frps.ini"
    fi
    
    # 设置权限
    chmod 755 ${INSTALL_DIR}/frps
    chmod 644 ${INSTALL_DIR}/frps.ini
}

# 创建 systemd 服务
create_service() {
    print_info "创建 systemd 服务..."
    
    cat > ${SERVICE_FILE} << EOF
[Unit]
Description=frp Server Service
After=network.target syslog.target
Wants=network.target

[Service]
Type=simple
User=root
Restart=on-failure
RestartSec=5s
ExecStart=${INSTALL_DIR}/frps -c ${INSTALL_DIR}/frps.ini
StandardOutput=journal
StandardError=journal
SyslogIdentifier=frps
KillMode=mixed
KillSignal=SIGTERM

[Install]
WantedBy=multi-user.target
EOF
    
    # 重载 systemd
    systemctl daemon-reload
    
    print_info "systemd 服务创建完成"
}

# 配置防火墙
configure_firewall() {
    print_info "配置防火墙规则..."
    
    # 检查防火墙类型
    if command -v ufw &> /dev/null; then
        # Ubuntu/Debian 使用 ufw
        ufw allow 7000/tcp comment 'frp bind port'
        ufw allow 7500/tcp comment 'frp dashboard'
        ufw allow 8000/tcp comment 'kuahaifan api'
        ufw allow 8888/tcp comment 'kuahaifan web'
        ufw allow 8080/tcp comment 'frp http'
        ufw allow 8443/tcp comment 'frp https'
        print_info "ufw 防火墙规则已添加"
        
    elif command -v firewall-cmd &> /dev/null; then
        # CentOS/RHEL 使用 firewalld
        firewall-cmd --permanent --add-port=7000/tcp
        firewall-cmd --permanent --add-port=7500/tcp
        firewall-cmd --permanent --add-port=8000/tcp
        firewall-cmd --permanent --add-port=8888/tcp
        firewall-cmd --permanent --add-port=8080/tcp
        firewall-cmd --permanent --add-port=8443/tcp
        firewall-cmd --reload
        print_info "firewalld 防火墙规则已添加"
        
    else
        print_warning "未检测到防火墙，请手动开放端口: 7000, 7500, 8000, 8888, 8080, 8443"
    fi
}

# 启动服务
start_service() {
    print_info "启动 frps 服务..."
    
    systemctl enable frps
    systemctl start frps
    
    # 检查服务状态
    sleep 2
    if systemctl is-active --quiet frps; then
        print_info "frps 服务启动成功"
    else
        print_error "frps 服务启动失败，请检查日志: journalctl -u frps -f"
        exit 1
    fi
}

# 显示信息
show_info() {
    echo ""
    echo "=========================================="
    echo -e "${GREEN}frp 服务端安装完成！${NC}"
    echo "=========================================="
    echo ""
    echo "配置文件: ${INSTALL_DIR}/frps.ini"
    echo "服务状态: systemctl status frps"
    echo "查看日志: journalctl -u frps -f"
    echo "重启服务: systemctl restart frps"
    echo ""
    echo "Dashboard 访问地址: http://YOUR_SERVER_IP:7500"
    echo "Dashboard 用户名: admin"
    echo "Dashboard 密码: KuaHaiFan2024!"
    echo ""
    echo "请确保已开放以下端口:"
    echo "  - 7000 (frp 通信端口)"
    echo "  - 7500 (Dashboard)"
    echo "  - 8000 (API 服务)"
    echo "  - 8888 (Web 服务)"
    echo "  - 8080 (HTTP 代理)"
    echo ""
    print_warning "请记得修改 frps.ini 中的密码和 token！"
}

# 主函数
main() {
    print_info "开始安装 frp 服务端..."
    
    check_root
    detect_arch
    download_frp
    configure_frps
    create_service
    configure_firewall
    start_service
    show_info
}

# 运行主函数
main