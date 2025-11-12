#!/bin/bash

# 花朵管理系统 - 生产环境部署脚本
# 支持多实例部署，每个实例使用不同的端口

set -e  # 遇到错误立即退出

# ==================== 颜色定义 ====================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ==================== 全局变量 ====================
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PORT=""
INSTANCE_NAME=""
ENV_FILE=""
PID_FILE=""
LOG_FILE=""

# ==================== 工具函数 ====================

# 打印成功消息
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# 打印警告消息
print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# 打印错误消息
print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 打印信息消息
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# 打印步骤标题
print_step() {
    echo -e "${YELLOW}$1${NC}"
}

# 验证端口号
validate_port() {
    local port=$1
    if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        print_error "无效的端口号，请输入 1-65535 之间的数字"
        exit 1
    fi
}

# 加载环境变量文件
load_env_file() {
    local env_file=$1
    if [ -f "$env_file" ]; then
        set -a
        # shellcheck disable=SC1090
        source "$env_file"
        set +a
        return 0
    fi
    return 1
}

# 创建或更新环境配置文件
setup_env_file() {
    local port=$1
    local env_file="backend/.env.${port}"
    
    # 如果存在共享的 .env 文件，复制一份作为模板
    if [ -f "backend/.env" ] && [ ! -f "$env_file" ]; then
        cp backend/.env "$env_file"
    fi
    
    # 更新或创建实例专用的 .env 文件
    if [ -f "$env_file" ]; then
        # 更新现有文件中的 PORT
        if grep -q "^PORT=" "$env_file"; then
            # 使用 sed 更新 PORT 值（兼容 macOS 和 Linux）
            if [[ "$OSTYPE" == "darwin"* ]]; then
                sed -i '' "s/^PORT=.*/PORT=${port}/" "$env_file"
            else
                sed -i "s/^PORT=.*/PORT=${port}/" "$env_file"
            fi
        else
            # 如果不存在 PORT，添加它
            echo "PORT=${port}" >> "$env_file"
        fi
    else
        # 创建新的 .env 文件
        cat > "$env_file" << EOF
NODE_ENV=production
PORT=${port}
HOST=0.0.0.0
EOF
    fi
    
    echo "$env_file"
}

# 获取服务器 IP 地址
get_server_ip() {
    local ip
    if command -v hostname &> /dev/null; then
        ip=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "")
    fi
    if [ -z "$ip" ]; then
        ip="服务器IP"
    fi
    echo "$ip"
}

# 显示部署成功信息
show_deployment_success() {
    local port=$1
    local instance_name=$2
    local server_ip
    server_ip=$(get_server_ip)
    
    echo ""
    echo -e "${GREEN}======================================"
    echo "✨ 部署完成！服务已启动"
    echo "======================================${NC}"
    echo ""
    echo -e "${GREEN}📍 访问地址:${NC}"
    echo "   http://localhost:${port}"
    echo "   http://${server_ip}:${port}"
    echo ""
}

# 显示 PM2 管理命令
show_pm2_commands() {
    local instance_name=$1
    echo -e "${GREEN}📊 PM2 管理命令:${NC}"
    echo "   查看状态: pm2 status"
    echo "   查看日志: pm2 logs ${instance_name}"
    echo "   重启服务: pm2 restart ${instance_name}"
    echo "   停止服务: pm2 stop ${instance_name}"
    echo "   删除实例: pm2 delete ${instance_name}"
    echo ""
    print_info "可以同时运行多个实例，只需使用不同的端口号"
    echo ""
}

# 显示 nohup 管理命令
show_nohup_commands() {
    local pid_file=$1
    local log_file=$2
    echo -e "${GREEN}📊 管理命令:${NC}"
    echo "   查看日志: tail -f backend/${log_file}"
    echo "   停止服务: kill \$(cat backend/${pid_file})"
    echo "   进程 PID: \$(cat backend/${pid_file})"
    echo ""
    print_info "可以同时运行多个实例，只需使用不同的端口号"
    echo ""
}

# ==================== 部署步骤函数 ====================

# 检查 Node.js
check_nodejs() {
    if ! command -v node &> /dev/null; then
        print_error "未检测到 Node.js"
        echo "请先安装 Node.js: https://nodejs.org/"
        exit 1
    fi
    print_success "Node.js 版本: $(node --version)"
    echo ""
}

# 安装后端依赖
install_backend_deps() {
    print_step "📦 步骤 1/4: 安装后端依赖..."
    cd "$SCRIPT_DIR/backend"
    
    if [ ! -d "node_modules" ]; then
        npm install --production
        print_success "后端依赖安装完成"
    else
        print_success "后端依赖已存在"
    fi
    
    cd "$SCRIPT_DIR"
    echo ""
}

# 构建前端应用
build_frontend() {
    print_step "📦 步骤 2/4: 构建前端应用..."
    cd "$SCRIPT_DIR/frontend"
    
    # 安装依赖
    if [ ! -d "node_modules" ]; then
        npm install
    fi
    
    # 构建生产版本
    echo "正在构建前端..."
    npm run build
    
    if [ -d "dist" ]; then
        print_success "前端构建完成"
        
        # 将构建文件移动到后端目录
        rm -rf ../backend/public
        mv dist ../backend/public
        print_success "前端文件已部署到后端"
    else
        print_error "前端构建失败"
        exit 1
    fi
    
    cd "$SCRIPT_DIR"
    echo ""
}

# 创建基础环境配置
create_base_env() {
    print_step "⚙️  步骤 3/4: 配置环境变量..."
    
    if [ ! -f "backend/.env" ]; then
        cat > backend/.env << EOF
NODE_ENV=production
PORT=3000
HOST=0.0.0.0
EOF
        print_success "环境配置已创建"
    else
        print_success "环境配置已存在"
    fi
    
    echo ""
}

# 获取用户输入的端口号
get_port_from_user() {
    print_step "🚀 步骤 4/4: 启动服务..."
    echo ""
    echo "请输入服务端口号（例如: 3000, 3001, 4000 等）:"
    read -p "端口号: " PORT
    
    validate_port "$PORT"
}

# 初始化实例配置
init_instance_config() {
    # 设置环境配置文件
    ENV_FILE=$(setup_env_file "$PORT")
    print_success "已更新环境配置: $ENV_FILE (PORT=${PORT})"
    echo ""
    
    # 生成实例标识（基于端口号）
    INSTANCE_NAME="flowers-manager-${PORT}"
    PID_FILE="flowers-manager-${PORT}.pid"
    LOG_FILE="flowers-manager-${PORT}.log"
}

# ==================== 启动方式函数 ====================

# PM2 启动方式
start_with_pm2() {
    # 检查 PM2
    if ! command -v pm2 &> /dev/null; then
        print_warning "未检测到 PM2，正在安装..."
        npm install -g pm2
    fi
    
    cd "$SCRIPT_DIR/backend"
    
    # 停止并删除同名实例（如果存在）
    pm2 stop "$INSTANCE_NAME" 2>/dev/null || true
    pm2 delete "$INSTANCE_NAME" 2>/dev/null || true
    
    # 创建临时启动脚本，加载对应的 .env 文件并启动服务
    local temp_script="start-${PORT}.sh"
    cat > "$temp_script" << EOF
#!/bin/bash
# 加载对应的 .env 文件
if [ -f ".env.${PORT}" ]; then
    set -a
    # shellcheck disable=SC1090
    source ".env.${PORT}"
    set +a
fi
# 确保 PORT 环境变量已设置
export PORT=${PORT}
exec node server-prod.js
EOF
    chmod +x "$temp_script"
    
    # 使用 PM2 启动
    pm2 start "$temp_script" --name "$INSTANCE_NAME" --update-env
    pm2 save
    
    show_deployment_success "$PORT" "$INSTANCE_NAME"
    show_pm2_commands "$INSTANCE_NAME"
}

# nohup 启动方式
start_with_nohup() {
    cd "$SCRIPT_DIR/backend"
    
    # 停止已存在的进程（如果存在）
    if [ -f "$PID_FILE" ]; then
        local old_pid
        old_pid=$(cat "$PID_FILE")
        if ps -p "$old_pid" > /dev/null 2>&1; then
            kill "$old_pid" 2>/dev/null || true
            print_warning "已停止旧进程 (PID: $old_pid)"
        fi
        rm -f "$PID_FILE"
    fi
    
    # 加载对应的 .env 文件
    load_env_file ".env.${PORT}"
    export PORT=$PORT
    
    # 使用 nohup 启动
    nohup node server-prod.js > "$LOG_FILE" 2>&1 &
    echo $! > "$PID_FILE"
    
    show_deployment_success "$PORT" "$INSTANCE_NAME"
    show_nohup_commands "$PID_FILE" "$LOG_FILE"
}

# 直接运行方式
start_directly() {
    cd "$SCRIPT_DIR/backend"
    
    # 加载对应的 .env 文件
    load_env_file ".env.${PORT}"
    export PORT=$PORT
    
    echo ""
    echo -e "${GREEN}======================================"
    echo "✨ 启动服务中..."
    echo "======================================${NC}"
    echo ""
    print_info "服务将在端口 ${PORT} 上运行"
    print_warning "按 Ctrl+C 可以停止服务"
    echo ""
    
    node server-prod.js
}

# ==================== 主程序 ====================

main() {
    # 显示标题
    echo "======================================"
    echo "   花朵管理系统 - 生产环境部署"
    echo "======================================"
    echo ""
    
    # 切换到脚本目录
    cd "$SCRIPT_DIR"
    
    # 执行部署步骤
    check_nodejs
    install_backend_deps
    build_frontend
    create_base_env
    get_port_from_user
    init_instance_config
    
    # 选择启动方式
    echo ""
    echo "请选择启动方式："
    echo "  1) 使用 PM2 启动（推荐，支持进程管理和自动重启）"
    echo "  2) 使用 nohup 后台运行（简单后台运行）"
    echo "  3) 直接运行（前台运行，关闭终端会停止）"
    echo ""
    read -p "请输入选项 (1-3): " choice
    
    case $choice in
        1)
            start_with_pm2
            ;;
        2)
            start_with_nohup
            ;;
        3)
            start_directly
            ;;
        *)
            print_error "无效选项"
            exit 1
            ;;
    esac
}

# 运行主程序
main
