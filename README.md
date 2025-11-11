# 🌸 花朵管理系统

一个简单易用的花朵管理 Web 应用，用于记录和管理每个人拥有的花朵。

## ✨ 功能特性

- ✅ **添加人员**：添加新人员及其拥有的花朵列表
- ✅ **查看列表**：以卡片形式展示所有人员和花朵信息
- ✅ **编辑信息**：修改人员名称和花朵列表
- ✅ **删除数据**：删除不需要的人员和花朵数据
- ✅ **智能查询**：
  - 根据人名查询该人拥有的花朵（支持模糊查询）
  - 根据花名查询拥有该花的人（支持模糊查询）
- ✅ **现代化 UI**：美观的渐变色设计和流畅的动画效果
- ✅ **响应式设计**：支持各种屏幕尺寸

## 🛠 技术栈

### 后端
- **Node.js** + **Express**: 后端服务器框架
- **SQLite** + **sqlite3**: 轻量级数据库（兼容 Node.js 23+）
- **CORS**: 跨域资源共享支持

### 前端
- **Vue.js 3**: 现代化的前端框架
- **Vite**: 快速的构建工具
- **Axios**: HTTP 客户端

## 📋 系统要求

- Node.js 14.0 或更高版本
- npm 或 yarn 包管理器

## 🚀 快速开始

### 方法一：使用启动脚本（推荐）

```bash
# 进入项目目录
cd flowers-manager

# 给启动脚本添加执行权限
chmod +x start.sh

# 运行启动脚本
./start.sh
```

启动脚本会自动：
1. 检查 Node.js 环境
2. 安装后端和前端依赖
3. 启动后端服务器（端口 3000）
4. 启动前端开发服务器（端口 5173）

### 方法二：手动启动

#### 1. 启动后端服务

```bash
cd backend
npm install
npm start
```

后端服务将运行在 `http://localhost:3000`

#### 2. 启动前端服务（新终端窗口）

```bash
cd frontend
npm install
npm run dev
```

前端应用将运行在 `http://localhost:5173`

## 🌐 访问应用

在浏览器中打开 [http://localhost:5173](http://localhost:5173)

## 📚 API 接口文档

### 数据管理接口

#### 获取所有人员
```
GET /api/persons
```

#### 获取单个人员
```
GET /api/persons/:id
```

#### 添加人员
```
POST /api/persons
Content-Type: application/json

{
  "name": "张三",
  "flowers": [
    { "name": "玫瑰" },
    { "name": "百合" }
  ]
}
```

#### 更新人员
```
PUT /api/persons/:id
Content-Type: application/json

{
  "name": "张三",
  "flowers": [
    { "name": "玫瑰" },
    { "name": "郁金香" }
  ]
}
```

#### 删除人员
```
DELETE /api/persons/:id
```

### 查询接口

#### 根据人名查询花朵
```
GET /api/search/person?name=<人名>
```

支持模糊查询，返回所有匹配的人员及其花朵列表。

#### 根据花名查询拥有者
```
GET /api/search/flower?name=<花名>
```

支持模糊查询，返回所有拥有该花朵的人员列表。

## 📁 项目结构

```
flowers-manager/
├── backend/              # 后端目录
│   ├── server.js        # Express 服务器
│   ├── package.json     # 后端依赖配置
│   └── flowers.db       # SQLite 数据库（运行后自动生成）
├── frontend/            # 前端目录
│   ├── src/
│   │   ├── App.vue      # 主应用组件
│   │   ├── main.js      # 应用入口
│   │   └── style.css    # 全局样式
│   ├── index.html       # HTML 模板
│   ├── vite.config.js   # Vite 配置
│   └── package.json     # 前端依赖配置
├── start.sh             # 快速启动脚本
└── README.md            # 项目文档
```

## 🗄 数据库结构

### persons 表
| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER | 主键，自增 |
| name | TEXT | 人员姓名（唯一） |
| created_at | DATETIME | 创建时间 |

### flowers 表
| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER | 主键，自增 |
| name | TEXT | 花朵名称 |
| person_id | INTEGER | 外键，关联 persons.id |
| created_at | DATETIME | 创建时间 |

## 🎯 使用说明

1. **查询功能**：
   - 根据人名查花朵：输入人名（支持模糊查询），查看该人拥有的所有花朵
   - 根据花名查拥有者：输入花名（支持模糊查询），查看哪些人拥有该花朵
2. **添加人员**：在表单输入人员姓名，可以添加多个花朵，点击"添加"按钮
3. **查看列表**：所有人员以卡片形式展示在下方
4. **编辑人员**：点击卡片右上角的"编辑"按钮，修改后点击"更新"
5. **删除人员**：点击卡片右上角的"删除"按钮，确认后删除

## ⚠️ 注意事项

- 人员姓名必须唯一
- 删除人员时会同时删除其所有花朵数据
- 数据库文件 `flowers.db` 存储在 backend 目录中
- 首次运行会自动创建数据库和表结构

## 🛑 停止服务

如果使用启动脚本：
- 在终端按 `Ctrl+C` 即可停止所有服务

如果手动启动：
- 分别在两个终端窗口按 `Ctrl+C` 停止服务

## 🔧 开发模式

### 后端开发
```bash
cd backend
npm run dev  # 使用 nodemon 自动重启
```

### 前端开发
```bash
cd frontend
npm run dev  # Vite 热更新
```

## 📦 生产构建

```bash
cd frontend
npm run build
```

构建后的文件在 `frontend/dist` 目录中。

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

ISC License

---

Made with ❤️ and Vue.js

