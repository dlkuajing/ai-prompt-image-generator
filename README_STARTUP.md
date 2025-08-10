# 🚀 跨海帆-闪图 项目启动指南

## 项目概述
AI提示词变体与图片批量生成工具，使用 Gemini 2.0 Flash Exp 生成提示词变体，Imagen 4 API 生成高质量图片。

## 启动步骤

### 1. 环境准备

```bash
# 进入项目目录
cd /Users/c.joelin/Desktop/跨海帆-闪图

# 进入后端目录
cd backend

# 创建并激活Python虚拟环境
python3 -m venv venv
source venv/bin/activate  # macOS/Linux

# 安装依赖
pip install -r requirements.txt
```

### 2. 启动后端服务

```bash
# 在backend目录下
python main.py
# 服务将在 http://localhost:8000 启动
```

### 3. 启动前端静态文件服务

```bash
# 新开一个终端，在项目根目录
cd /Users/c.joelin/Desktop/跨海帆-闪图

# 启动HTTP服务器（端口8080）
python3 -m http.server 8080
```

### 4. 访问方式

#### 本地访问
- **Web界面**: http://localhost:8080
- **API文档**: http://localhost:8000/docs

#### 全球访问（通过FRP）

如需开启全球访问，启动FRP客户端：

```bash
# 新开终端，进入FRP配置目录
cd /Users/c.joelin/Desktop/跨海帆-闪图/frp-config

# 启动FRP客户端
./start-client.sh
```

全球访问地址：
- **Web界面**: http://172.104.59.98:8888
- **API服务**: http://172.104.59.98:8000
- **FRP Dashboard**: http://172.104.59.98:7500
  - 用户名: admin
  - 密码: KuaHaiFan2024!

## 核心功能

1. **提示词变体生成**
   - 输入基础提示词
   - 选择变化维度（场景、光影、色调等18个维度）
   - 自动生成多个变体

2. **批量图片生成**
   - 支持5种比例（1:1、9:16、16:9、3:4、4:3）
   - 异步并发生成
   - 实时进度显示

3. **批量下载**
   - 一键打包下载所有生成的图片

## API密钥
项目使用的Gemini API密钥已内置：
```
GEMINI_API_KEY=AIzaSyB-ZYo5kMjtpqnOyjEELzy8PD8VnMTuvkw
```

## 进程管理

### 查看运行状态
```bash
# 查看后端服务
ps aux | grep "python main.py"

# 查看静态文件服务
ps aux | grep "http.server"

# 查看FRP客户端
ps aux | grep frpc
```

### 停止服务
```bash
# 停止后端：在运行终端按 Ctrl+C

# 停止FRP客户端
pkill frpc

# 或查找进程ID后终止
ps aux | grep frpc
kill -9 [PID]
```

## 故障排查

### 后端无法启动
1. 检查8000端口是否被占用：`lsof -i :8000`
2. 检查Python版本：需要Python 3.8+
3. 重新安装依赖：`pip install -r requirements.txt`

### FRP连接失败
1. 检查网络连接：`ping 172.104.59.98`
2. 查看FRP日志：`tail -f frp-config/frpc.log`
3. 确认服务器FRP服务运行中

### 图片生成失败
1. 检查API密钥是否有效
2. 查看后端日志输出
3. 确认网络可访问Google API

## 项目结构
```
跨海帆-闪图/
├── backend/
│   ├── main.py              # FastAPI主应用
│   ├── imagen_api.py        # Imagen API集成
│   ├── requirements.txt     # Python依赖
│   └── venv/                # 虚拟环境
├── frp-config/
│   ├── frpc.ini            # FRP客户端配置
│   ├── start-client.sh     # 启动脚本
│   └── frpc.log            # 运行日志
├── index.html              # 主界面
└── README_STARTUP.md       # 本文档
```

## 快速重启命令

一键启动所有服务（创建启动脚本）：

```bash
#!/bin/bash
# 保存为 start-all.sh

echo "启动跨海帆-闪图项目..."

# 启动后端
cd backend
source venv/bin/activate
python main.py &
cd ..

# 启动静态服务器
python3 -m http.server 8080 &

# 启动FRP（可选）
cd frp-config
./start-client.sh &
cd ..

echo "所有服务已启动！"
echo "本地访问: http://localhost:8080"
echo "全球访问: http://172.104.59.98:8888"
```

---
最后更新：2025年8月10日