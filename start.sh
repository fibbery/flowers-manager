#!/bin/bash

echo "==================================="
echo "    花朵管理系统 - 快速启动脚本"
echo "==================================="
echo ""

# 检查是否已安装 Node.js
if ! command -v node &> /dev/null; then
    echo "❌ 错误: 未检测到 Node.js"
    echo "请先安装 Node.js: https://nodejs.org/"
    exit 1
fi

echo "✅ Node.js 版本: $(node --version)"
echo ""

# 后端安装和启动
echo "📦 安装后端依赖..."
cd backend
if [ ! -d "node_modules" ]; then
    npm install
else
    echo "后端依赖已安装，跳过..."
fi
echo ""

echo "🚀 启动后端服务器..."
node server.js &
BACKEND_PID=$!
echo "后端进程 PID: $BACKEND_PID"
echo ""

# 等待后端启动
sleep 3

# 前端安装和启动
echo "📦 安装前端依赖..."
cd ../frontend
if [ ! -d "node_modules" ]; then
    npm install
else
    echo "前端依赖已安装，跳过..."
fi
echo ""

echo "🚀 启动前端开发服务器..."
npm run dev &
FRONTEND_PID=$!
echo "前端进程 PID: $FRONTEND_PID"
echo ""

echo "==================================="
echo "✨ 启动完成！"
echo "==================================="
echo ""
echo "📍 访问地址:"
echo "   前端: http://localhost:5173"
echo "   后端: http://localhost:3000"
echo ""
echo "💡 按 Ctrl+C 停止服务"
echo ""

# 保存进程 ID
cd ..
echo $BACKEND_PID > .backend.pid
echo $FRONTEND_PID > .frontend.pid

# 等待中断信号
trap "echo ''; echo '⏹️  正在停止服务...'; kill $BACKEND_PID $FRONTEND_PID 2>/dev/null; rm -f .backend.pid .frontend.pid; echo '✅ 服务已停止'; exit 0" INT TERM

# 保持脚本运行
wait

