#!/bin/bash
# frp 客户端启动脚本 (在本地 Mac 上运行)

set -e

# 配置变量
FRP_VERSION="0.52.3"
INSTALL_DIR="./frp-client"
CONFIG_FILE="./frpc.ini"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 检查 frpc 是否已安装
check_frpc() {
    if [[ ! -f "${INSTALL_DIR}/frpc" ]]; then
        print_warning "frpc 未安装，正在下载..."
        download_frpc
    else
        print_info "frpc 已安装"
    fi
}

# 下载 frpc
download_frpc() {
    print_step "下载 frp 客户端 v${FRP_VERSION}..."
    
    # 创建目录
    mkdir -p ${INSTALL_DIR}
    
    # 检测系统架构
    ARCH=$(uname -m)
    if [[ "$ARCH" == "x86_64" ]]; then
        ARCH="amd64"
    elif [[ "$ARCH" == "arm64" ]]; then
        ARCH="arm64"
    else
        print_error "不支持的系统架构: $ARCH"
        exit 1
    fi
    
    # 下载 frp
    DOWNLOAD_URL="https://github.com/fatedier/frp/releases/download/v${FRP_VERSION}/frp_${FRP_VERSION}_darwin_${ARCH}.tar.gz"
    
    print_info "下载地址: ${DOWNLOAD_URL}"
    curl -L ${DOWNLOAD_URL} -o /tmp/frp.tar.gz
    
    # 解压
    cd /tmp
    tar -xzf frp.tar.gz
    
    # 移动文件
    mv frp_${FRP_VERSION}_darwin_${ARCH}/frpc ${INSTALL_DIR}/
    
    # 清理
    rm -rf frp.tar.gz frp_${FRP_VERSION}_darwin_${ARCH}
    
    # 设置权限
    chmod +x ${INSTALL_DIR}/frpc
    
    cd - > /dev/null
    print_info "frpc 下载完成"
}

# 检查配置文件
check_config() {
    if [[ ! -f "${CONFIG_FILE}" ]]; then
        print_error "配置文件 ${CONFIG_FILE} 不存在"
        print_info "请先配置 frpc.ini 文件"
        exit 1
    fi
    
    # 检查是否已配置服务器地址
    if grep -q "YOUR_LINODE_IP" ${CONFIG_FILE}; then
        print_error "请先修改 ${CONFIG_FILE} 中的服务器地址"
        echo ""
        read -p "请输入你的 Linode 服务器 IP: " SERVER_IP
        
        # 替换配置文件中的 IP
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            sed -i '' "s/YOUR_LINODE_IP/${SERVER_IP}/g" ${CONFIG_FILE}
        else
            # Linux
            sed -i "s/YOUR_LINODE_IP/${SERVER_IP}/g" ${CONFIG_FILE}
        fi
        
        print_info "服务器地址已更新为: ${SERVER_IP}"
    fi
}

# 检查本地服务
check_local_services() {
    print_step "检查本地服务状态..."
    
    # 检查 FastAPI 服务 (端口 8000)
    if lsof -Pi :8000 -sTCP:LISTEN -t >/dev/null ; then
        print_info "✓ FastAPI 服务正在运行 (端口 8000)"
    else
        print_warning "✗ FastAPI 服务未运行，请先启动后端服务"
        echo "  运行: cd backend && source venv/bin/activate && python main.py"
    fi
    
    # 检查静态文件服务 (端口 8080)
    if lsof -Pi :8080 -sTCP:LISTEN -t >/dev/null ; then
        print_info "✓ 静态文件服务正在运行 (端口 8080)"
    else
        print_warning "✗ 静态文件服务未运行"
        echo "  运行: python3 -m http.server 8080"
    fi
    
    echo ""
}

# 启动 frpc
start_frpc() {
    print_step "启动 frp 客户端..."
    
    # 检查是否已在运行
    if pgrep -f "${INSTALL_DIR}/frpc" > /dev/null; then
        print_warning "frpc 已在运行，正在停止..."
        pkill -f "${INSTALL_DIR}/frpc"
        sleep 2
    fi
    
    # 启动 frpc (后台运行，避免阻塞)
    print_info "正在连接到服务器..."
    nohup ${INSTALL_DIR}/frpc -c ${CONFIG_FILE} >> frpc.log 2>&1 &
    FRP_PID=$!
    
    # 等待一下让服务启动
    sleep 2
    
    # 检查是否成功启动
    if ps -p $FRP_PID > /dev/null; then
        echo -e "${GREEN}✓ FRP客户端已启动${NC}"
    else
        print_error "FRP客户端启动失败，请检查日志: frpc.log"
        return 1
    fi
}

# 显示连接信息
show_info() {
    echo ""
    echo "=========================================="
    echo -e "${GREEN}frp 客户端配置完成！${NC}"
    echo "=========================================="
    echo ""
    echo "配置文件: ${CONFIG_FILE}"
    echo "日志文件: ./frpc.log"
    echo ""
    echo "如果连接成功，可以通过以下地址访问:"
    echo "  - API 服务: http://YOUR_SERVER_IP:8000"
    echo "  - Web 界面: http://YOUR_SERVER_IP:8888"
    echo "  - Dashboard: http://YOUR_SERVER_IP:7500"
    echo ""
    echo "按 Ctrl+C 停止客户端"
    echo ""
}

# 清理函数
cleanup() {
    echo ""
    print_info "正在停止 frp 客户端..."
    exit 0
}

# 设置信号处理
trap cleanup SIGINT SIGTERM

# 主函数
main() {
    clear
    echo "=========================================="
    echo "     跨海帆-闪图 frp 客户端启动脚本"
    echo "=========================================="
    echo ""
    
    check_frpc
    check_config
    check_local_services
    show_info
    start_frpc
}

# 运行主函数
main