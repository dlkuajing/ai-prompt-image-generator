# 🌐 frp 内网穿透配置指南

通过 frp 让外网用户访问你的"跨海帆-闪图"项目

## 📋 前置要求

- ✅ 一台有公网 IP 的服务器（如 Linode）
- ✅ 本地运行的"跨海帆-闪图"项目
- ✅ 基本的 Linux 命令行知识

## 🚀 快速开始

### 步骤 1：服务器端配置（Linode）

1. **上传配置文件到服务器**
```bash
# 将 frps.ini 和 install-server.sh 上传到服务器
scp frps.ini install-server.sh root@YOUR_LINODE_IP:/root/
```

2. **登录服务器并安装**
```bash
ssh root@YOUR_LINODE_IP
chmod +x install-server.sh
sudo ./install-server.sh
```

3. **修改配置文件**
```bash
# 编辑配置文件，修改密码和 token
nano /opt/frp/frps.ini

# 修改以下内容：
# dashboard_pwd = 你的新密码
# token = 你的新token
```

4. **重启服务**
```bash
systemctl restart frps
systemctl status frps  # 检查状态
```

### 步骤 2：本地客户端配置（Mac）

1. **修改客户端配置**
```bash
# 编辑 frpc.ini
nano frpc.ini

# 修改服务器地址
server_addr = YOUR_LINODE_IP  # 替换为你的实际 IP

# 修改 token（与服务器一致）
token = 你的新token
```

2. **启动本地服务**
```bash
# 终端 1：启动 API 服务
cd backend
source venv/bin/activate
python main.py

# 终端 2：启动静态文件服务
python3 -m http.server 8080
```

3. **启动 frp 客户端**
```bash
# 终端 3：启动 frp
chmod +x start-client.sh
./start-client.sh
```

## 🔗 访问地址

配置成功后，可以通过以下地址访问：

- **API 服务**: `http://YOUR_LINODE_IP:8000`
- **Web 界面**: `http://YOUR_LINODE_IP:8888`
- **Dashboard**: `http://YOUR_LINODE_IP:7500`
  - 用户名: admin
  - 密码: 你设置的密码

## 📁 文件说明

```
frp-config/
├── frps.ini          # 服务端配置文件
├── frpc.ini          # 客户端配置文件
├── install-server.sh # 服务端安装脚本
├── start-client.sh   # 客户端启动脚本
└── README.md         # 本文档
```

## ⚙️ 配置详解

### 服务端配置 (frps.ini)

| 参数 | 说明 | 默认值 |
|------|------|--------|
| bind_port | frp 服务监听端口 | 7000 |
| dashboard_port | 管理面板端口 | 7500 |
| dashboard_user | 管理面板用户名 | admin |
| dashboard_pwd | 管理面板密码 | 需修改 |
| token | 认证令牌 | 需修改 |
| allow_ports | 允许的端口范围 | 8000-9000 |

### 客户端配置 (frpc.ini)

| 服务名 | 类型 | 本地端口 | 远程端口 | 说明 |
|--------|------|----------|----------|------|
| kuahaifan_api | tcp | 8000 | 8000 | API 服务 |
| kuahaifan_web | tcp | 8080 | 8888 | 静态文件 |

## 🔒 安全建议

1. **修改默认密码和 token**
   - 使用强密码
   - token 至少 20 个字符

2. **限制访问**
   ```ini
   # 在 frps.ini 中添加
   allow_ports = 8000,8888  # 只允许特定端口
   ```

3. **使用 HTTPS**（可选）
   - 配置 SSL 证书
   - 使用 https 类型代理

4. **监控日志**
   ```bash
   # 查看服务端日志
   journalctl -u frps -f
   
   # 查看客户端日志
   tail -f frpc.log
   ```

## 🐛 故障排查

### 问题 1：无法连接到服务器

**检查防火墙**
```bash
# Ubuntu/Debian
sudo ufw status

# CentOS
sudo firewall-cmd --list-all
```

**检查端口**
```bash
# 服务端
netstat -tlnp | grep frps

# 客户端
lsof -i :8000
lsof -i :8080
```

### 问题 2：Dashboard 无法访问

1. 确认端口 7500 已开放
2. 检查配置文件中的 dashboard_port
3. 查看日志：`journalctl -u frps -n 50`

### 问题 3：图片生成失败

1. 确认本地 API 服务正常运行
2. 检查 frpc 连接状态
3. 查看 Dashboard 中的连接信息

## 📊 性能优化

1. **启用 TCP 多路复用**
   ```ini
   # 已在配置中启用
   tcp_mux = true
   ```

2. **调整连接池**
   ```ini
   # frpc.ini
   pool_count = 10  # 增加连接池大小
   ```

3. **使用压缩**（适用于文本数据）
   ```ini
   # frpc.ini
   use_compression = true
   ```

## 🔄 常用命令

### 服务端命令
```bash
# 查看服务状态
systemctl status frps

# 启动/停止/重启
systemctl start frps
systemctl stop frps
systemctl restart frps

# 查看日志
journalctl -u frps -f

# 编辑配置
nano /opt/frp/frps.ini
```

### 客户端命令
```bash
# 启动客户端
./start-client.sh

# 后台运行
nohup ./frp-client/frpc -c frpc.ini > frpc.log 2>&1 &

# 查看进程
ps aux | grep frpc

# 停止客户端
pkill frpc
```

## 📈 监控和统计

访问 Dashboard 查看：
- 当前连接数
- 流量统计
- 代理状态
- 客户端信息

URL: `http://YOUR_LINODE_IP:7500`

## 🤝 获取帮助

- [frp 官方文档](https://gofrp.org/docs/)
- [GitHub Issues](https://github.com/fatedier/frp/issues)
- 查看日志文件定位问题

## 📝 注意事项

1. **API 密钥安全**
   - 项目包含 Gemini/Imagen API 密钥
   - 建议添加访问控制

2. **使用限制**
   - 注意 API 调用配额
   - 监控带宽使用

3. **备份配置**
   - 定期备份 frp 配置文件
   - 记录服务器设置

---

💡 **提示**: 首次配置可能需要 10-15 分钟，配置成功后即可稳定使用。