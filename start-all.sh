#!/bin/bash
# 跨海帆-闪图 一键启动脚本

set -e

PROJECT_DIR="/Users/c.joelin/Desktop/跨海帆-闪图"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

clear
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}     跨海帆-闪图 项目启动器${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 检查并停止已运行的服务
echo -e "${YELLOW}检查现有服务...${NC}"
if lsof -Pi :8000 -sTCP:LISTEN -t >/dev/null ; then
    echo "发现8000端口被占用，正在停止..."
    kill $(lsof -Pi :8000 -sTCP:LISTEN -t) 2>/dev/null || true
    sleep 1
fi

if lsof -Pi :8080 -sTCP:LISTEN -t >/dev/null ; then
    echo "发现8080端口被占用，正在停止..."
    kill $(lsof -Pi :8080 -sTCP:LISTEN -t) 2>/dev/null || true
    sleep 1
fi

# 启动后端服务
echo -e "${BLUE}[1/3] 启动后端API服务...${NC}"
cd "$PROJECT_DIR/backend"
if [ -d "venv" ]; then
    source venv/bin/activate
else
    echo "创建Python虚拟环境..."
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
fi

python main.py > backend.log 2>&1 &
BACKEND_PID=$!
echo -e "${GREEN}✓ 后端服务已启动 (PID: $BACKEND_PID)${NC}"
sleep 2

# 启动前端静态服务器
echo -e "${BLUE}[2/3] 启动前端服务...${NC}"
cd "$PROJECT_DIR"
python3 -m http.server 8080 > frontend.log 2>&1 &
FRONTEND_PID=$!
echo -e "${GREEN}✓ 前端服务已启动 (PID: $FRONTEND_PID)${NC}"
sleep 1

# 可选：启动FRP
echo ""
read -p "是否启动FRP全球访问功能？(y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}[3/3] 启动FRP客户端...${NC}"
    cd "$PROJECT_DIR/frp-config"
    if [ -f "start-client.sh" ]; then
        ./start-client.sh
        echo -e "${GREEN}✓ FRP客户端已启动${NC}"
    else
        echo -e "${YELLOW}警告: FRP启动脚本不存在${NC}"
    fi
fi

# 显示访问信息
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}     所有服务已成功启动！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}访问地址：${NC}"
echo -e "  本地Web界面: ${GREEN}http://localhost:8080${NC}"
echo -e "  本地API文档: ${GREEN}http://localhost:8000/docs${NC}"
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "  全球Web访问: ${GREEN}http://172.104.59.98:8888${NC}"
    echo -e "  全球API访问: ${GREEN}http://172.104.59.98:8000${NC}"
    echo ""
fi
echo -e "${YELLOW}提示: 按 Ctrl+C 停止所有服务${NC}"
echo ""

# 保存PID到文件
echo "$BACKEND_PID" > "$PROJECT_DIR/.backend.pid"
echo "$FRONTEND_PID" > "$PROJECT_DIR/.frontend.pid"

# 等待用户中断
trap 'echo -e "\n${YELLOW}正在停止所有服务...${NC}"; kill $BACKEND_PID $FRONTEND_PID 2>/dev/null; pkill frpc 2>/dev/null; echo -e "${GREEN}服务已停止${NC}"; exit' INT

# 保持脚本运行
while true; do
    sleep 1
done