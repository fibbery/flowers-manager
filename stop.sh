#!/bin/bash

# 停止花朵管理系统服务

echo "======================================"
echo "   停止花朵管理系统服务"
echo "======================================"
echo ""

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. 尝试停止 PM2 服务
if command -v pm2 &> /dev/null; then
    echo -e "${YELLOW}检查 PM2 服务...${NC}"
    if pm2 list | grep -q "flowers-manager"; then
        pm2 stop flowers-manager
        pm2 delete flowers-manager
        echo -e "${GREEN}✅ PM2 服务已停止${NC}"
    else
        echo "未找到 PM2 服务"
    fi
fi

# 2. 停止 nohup 进程
if [ -f "backend/flowers-manager.pid" ]; then
    echo -e "${YELLOW}停止后台进程...${NC}"
    PID=$(cat backend/flowers-manager.pid)
    kill $PID 2>/dev/null && echo -e "${GREEN}✅ 后台进程已停止 (PID: $PID)${NC}" || echo "进程已不存在"
    rm backend/flowers-manager.pid
fi

# 3. 查找并停止所有相关进程
echo -e "${YELLOW}检查其他 Node 进程...${NC}"
PIDS=$(ps aux | grep "[n]ode.*server" | grep -v grep | awk '{print $2}')
if [ ! -z "$PIDS" ]; then
    echo "找到以下进程："
    ps aux | grep "[n]ode.*server" | grep -v grep
    echo ""
    read -p "是否停止这些进程？(y/n): " confirm
    if [ "$confirm" = "y" ]; then
        echo $PIDS | xargs kill
        echo -e "${GREEN}✅ 进程已停止${NC}"
    fi
else
    echo "未找到其他相关进程"
fi

echo ""
echo -e "${GREEN}======================================"
echo "✅ 停止完成"
echo "======================================${NC}"

