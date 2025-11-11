// PM2 配置文件
module.exports = {
  apps: [{
    name: 'flowers-manager',
    script: './backend/server-prod.js',
    
    // 实例数量
    instances: 1,
    
    // 执行模式
    exec_mode: 'fork',
    
    // 环境变量
    env: {
      NODE_ENV: 'production',
      PORT: 3000,
      HOST: '0.0.0.0'
    },
    
    // 监听文件变化（生产环境建议关闭）
    watch: false,
    
    // 忽略监听的文件
    ignore_watch: [
      'node_modules',
      'logs',
      '*.log',
      'flowers.db'
    ],
    
    // 最大内存限制（超过自动重启）
    max_memory_restart: '500M',
    
    // 日志配置
    error_file: './logs/error.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true,
    
    // 自动重启配置
    autorestart: true,
    max_restarts: 10,
    min_uptime: '10s',
    
    // 崩溃重启延迟
    restart_delay: 4000,
    
    // 优雅关闭超时时间
    kill_timeout: 5000,
    
    // 监听退出信号
    listen_timeout: 3000,
    
    // 集群模式下的端口
    // increment_var: 'PORT',
    
    // 合并日志
    merge_logs: true,
    
    // 日志时间格式
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z'
  }]
};

