#!/bin/bash
# 跨海帆-闪图 停止所有服务脚本

PROJECT_DIR="/Users/c.joelin/Desktop/跨海帆-闪图"
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${RED}正在停止跨海帆-闪图所有服务...${NC}"

# 停止后端服务
if [ -f "$PROJECT_DIR/.backend.pid" ]; then
    PID=$(cat "$PROJECT_DIR/.backend.pid")
    if ps -p $PID > /dev/null; then
        kill $PID 2>/dev/null
        echo "✓ 后端服务已停止 (PID: $PID)"
    fi
    rm "$PROJECT_DIR/.backend.pid"
fi

# 停止前端服务
if [ -f "$PROJECT_DIR/.frontend.pid" ]; then
    PID=$(cat "$PROJECT_DIR/.frontend.pid")
    if ps -p $PID > /dev/null; then
        kill $PID 2>/dev/null
        echo "✓ 前端服务已停止 (PID: $PID)"
    fi
    rm "$PROJECT_DIR/.frontend.pid"
fi

# 停止可能运行的Python服务
pkill -f "python main.py" 2>/dev/null
pkill -f "python3 -m http.server 8080" 2>/dev/null

# 停止FRP客户端
pkill frpc 2>/dev/null && echo "✓ FRP客户端已停止"

echo -e "${GREEN}所有服务已停止${NC}"