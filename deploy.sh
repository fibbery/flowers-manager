#!/bin/bash

# 花朵管理系统 - 生产环境部署脚本

set -e  # 遇到错误立即退出

echo "======================================"
echo "   花朵管理系统 - 生产环境部署"
echo "======================================"
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查 Node.js
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ 错误: 未检测到 Node.js${NC}"
    echo "请先安装 Node.js: https://nodejs.org/"
    exit 1
fi

echo -e "${GREEN}✅ Node.js 版本: $(node --version)${NC}"
echo ""

# 获取脚本所在目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# 1. 安装后端依赖
echo -e "${YELLOW}📦 步骤 1/4: 安装后端依赖...${NC}"
cd backend
if [ ! -d "node_modules" ]; then
    npm install --production
    echo -e "${GREEN}✅ 后端依赖安装完成${NC}"
else
    echo -e "${GREEN}✅ 后端依赖已存在${NC}"
fi
cd ..
echo ""

# 2. 安装前端依赖并构建
echo -e "${YELLOW}📦 步骤 2/4: 构建前端应用...${NC}"
cd frontend

# 安装依赖
if [ ! -d "node_modules" ]; then
    npm install
fi

# 构建生产版本
echo "正在构建前端..."
npm run build

if [ -d "dist" ]; then
    echo -e "${GREEN}✅ 前端构建完成${NC}"
    
    # 将构建文件移动到后端目录
    rm -rf ../backend/public
    mv dist ../backend/public
    echo -e "${GREEN}✅ 前端文件已部署到后端${NC}"
else
    echo -e "${RED}❌ 前端构建失败${NC}"
    exit 1
fi

cd ..
echo ""

# 3. 创建环境配置
echo -e "${YELLOW}⚙️  步骤 3/4: 配置环境变量...${NC}"
if [ ! -f "backend/.env" ]; then
    cat > backend/.env << EOF
NODE_ENV=production
PORT=3000
HOST=0.0.0.0
EOF
    echo -e "${GREEN}✅ 环境配置已创建${NC}"
else
    echo -e "${GREEN}✅ 环境配置已存在${NC}"
fi
echo ""

# 4. 启动服务
echo -e "${YELLOW}🚀 步骤 4/4: 启动服务...${NC}"
echo ""
echo "请选择启动方式："
echo "  1) 使用 PM2 启动（推荐，支持进程管理和自动重启）"
echo "  2) 使用 nohup 后台运行（简单后台运行）"
echo "  3) 直接运行（前台运行，关闭终端会停止）"
echo ""
read -p "请输入选项 (1-3): " choice

case $choice in
    1)
        # 检查 PM2
        if ! command -v pm2 &> /dev/null; then
            echo -e "${YELLOW}⚠️  未检测到 PM2，正在安装...${NC}"
            npm install -g pm2
        fi
        
        cd backend
        pm2 stop flowers-manager 2>/dev/null || true
        pm2 delete flowers-manager 2>/dev/null || true
        pm2 start server.js --name flowers-manager
        pm2 save
        
        echo ""
        echo -e "${GREEN}======================================"
        echo "✨ 部署完成！服务已启动"
        echo "======================================${NC}"
        echo ""
        echo -e "${GREEN}📍 访问地址:${NC}"
        echo "   http://localhost:3000"
        echo "   http://$(hostname -I | awk '{print $1}'):3000"
        echo ""
        echo -e "${GREEN}📊 PM2 管理命令:${NC}"
        echo "   查看状态: pm2 status"
        echo "   查看日志: pm2 logs flowers-manager"
        echo "   重启服务: pm2 restart flowers-manager"
        echo "   停止服务: pm2 stop flowers-manager"
        echo ""
        ;;
    
    2)
        cd backend
        
        # 停止已存在的进程
        if [ -f "flowers-manager.pid" ]; then
            OLD_PID=$(cat flowers-manager.pid)
            kill $OLD_PID 2>/dev/null || true
            rm flowers-manager.pid
        fi
        
        # 使用 nohup 启动
        nohup node server.js > flowers-manager.log 2>&1 &
        echo $! > flowers-manager.pid
        
        echo ""
        echo -e "${GREEN}======================================"
        echo "✨ 部署完成！服务已启动"
        echo "======================================${NC}"
        echo ""
        echo -e "${GREEN}📍 访问地址:${NC}"
        echo "   http://localhost:3000"
        echo "   http://$(hostname -I | awk '{print $1}' 2>/dev/null || echo '服务器IP'):3000"
        echo ""
        echo -e "${GREEN}📊 管理命令:${NC}"
        echo "   查看日志: tail -f backend/flowers-manager.log"
        echo "   停止服务: kill \$(cat backend/flowers-manager.pid)"
        echo ""
        ;;
    
    3)
        cd backend
        echo ""
        echo -e "${GREEN}======================================"
        echo "✨ 启动服务中..."
        echo "======================================${NC}"
        echo ""
        echo -e "${YELLOW}⚠️  按 Ctrl+C 可以停止服务${NC}"
        echo ""
        node server.js
        ;;
    
    *)
        echo -e "${RED}❌ 无效选项${NC}"
        exit 1
        ;;
esac

