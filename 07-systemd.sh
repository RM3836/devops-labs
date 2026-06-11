#!/bin/bash
# ============================================
# DevOps实战 Lab 07: systemd 服务管理
# 运行: bash 07-systemd.sh
# ============================================

CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Lab 07: systemd 服务管理${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# ---------- 基本操作 ----------
echo -e "${YELLOW}[1] 基本操作${NC}"
echo "----------------------------------------"
cat << 'EOF'
# 服务管理四大动作
systemctl start   服务名      # 启动
systemctl stop    服务名      # 停止
systemctl restart 服务名      # 重启
systemctl reload  服务名      # 重载配置(不中断服务)

# 状态查看
systemctl status  服务名      # 查看状态(含最近日志)
systemctl is-active 服务名    # 是否运行
systemctl is-enabled 服务名   # 是否开机自启

# 开机自启
systemctl enable  服务名      # 设为开机自启
systemctl disable 服务名      # 取消开机自启

# 全局查看
systemctl list-units --type=service            # 所有服务
systemctl list-units --type=service --state=running  # 运行中的
systemctl list-unit-files --type=service       # 所有服务文件
EOF
echo ""

# ---------- 查看本机服务状态 ----------
echo -e "${YELLOW}[2] 本机服务状态${NC}"
echo "----------------------------------------"

echo '$ systemctl list-units --type=service --state=running | head -15'
systemctl list-units --type=service --state=running 2>/dev/null | head -15 || echo "(WSL可能不完全支持systemd)"
echo ""

# ---------- 日志查看 journalctl ----------
echo -e "${YELLOW}[3] journalctl 日志查看${NC}"
echo "----------------------------------------"
cat << 'EOF'
journalctl                          # 查看所有日志
journalctl -u nginx                 # 某服务的日志
journalctl -u nginx --since today   # 今天的日志
journalctl -u nginx --since "2025-06-01" --until "2025-06-02"
journalctl -u nginx -f              # 实时跟踪(类似tail -f)
journalctl -u nginx -n 50           # 最近50行
journalctl -p err                   # 只看错误级别
journalctl --disk-usage             # 日志占用空间
journalctl --vacuum-size=500M       # 清理日志到500M以内
journalctl -u nginx -o json-pretty  # JSON格式输出
EOF
echo ""

# ---------- 写一个自定义服务 ----------
echo -e "${YELLOW}[4] 实战: 写一个自定义服务${NC}"
echo "----------------------------------------"

cat > /tmp/demo-app.py << 'PYEOF'
#!/usr/bin/env python3
"""演示用的简单HTTP服务"""
import http.server
import json
import datetime

class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        data = {
            "status": "ok",
            "service": "demo-app",
            "time": str(datetime.datetime.now()),
            "path": self.path
        }
        self.wfile.write(json.dumps(data, indent=2).encode())
    def log_message(self, format, *args):
        print(f"[{datetime.datetime.now()}] {args[0]}")

if __name__ == '__main__':
    server = http.server.HTTPServer(('0.0.0.0', 8888), Handler)
    print("Demo app listening on :8888")
    server.serve_forever()
PYEOF
chmod +x /tmp/demo-app.py

echo "应用脚本: /tmp/demo-app.py"
echo ""

cat > /tmp/demo-app.service << 'SVCEOF'
[Unit]
Description=Demo Python HTTP App
Documentation=https://example.com/docs
After=network.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/tmp
ExecStart=/usr/bin/python3 /tmp/demo-app.py
ExecStop=/bin/kill -TERM $MAINPID
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=demo-app

# 安全加固(可选)
NoNewPrivileges=true
ProtectSystem=strict
ReadWritePaths=/tmp

[Install]
WantedBy=multi-user.target
SVCEOF

echo "service文件内容:"
cat /tmp/demo-app.service
echo ""

echo "部署步骤:"
cat << 'EOF'
# 1. 复制service文件
sudo cp /tmp/demo-app.service /etc/systemd/system/

# 2. 重载systemd配置
sudo systemctl daemon-reload

# 3. 启动服务
sudo systemctl start demo-app

# 4. 查看状态
sudo systemctl status demo-app

# 5. 设为开机自启
sudo systemctl enable demo-app

# 6. 查看日志
journalctl -u demo-app -f

# 7. 重启/停止
sudo systemctl restart demo-app
sudo systemctl stop demo-app
EOF
echo ""

# ---------- service文件字段详解 ----------
echo -e "${YELLOW}[5] service文件字段详解${NC}"
echo "----------------------------------------"
cat << 'EOF'
[Unit] 部分:
  Description     服务描述
  Documentation   文档URL
  After           在哪个服务之后启动(network.target=网络就绪后)
  Before          在哪个服务之前启动
  Wants           依赖(弱依赖,失败不影响)
  Requires        依赖(强依赖,失败则自己也失败)

[Service] 部分:
  Type=simple     主进程就是服务进程(最常用)
  Type=forking    主进程fork子进程后退出(传统守护进程)
  Type=oneshot    执行一次就退出(脚本任务)
  ExecStart       启动命令
  ExecStop        停止命令
  ExecReload      重载命令
  Restart=always  崩溃后自动重启
  RestartSec=5    重启间隔5秒
  User=root       运行用户
  WorkingDirectory 工作目录
  Environment     环境变量(key=value)
  EnvironmentFile 环境变量文件
  LimitNOFILE     最大文件描述符数

[Install] 部分:
  WantedBy=multi-user.target  # 多用户模式启动(等同于开机自启)
EOF
echo ""

# ---------- 运维排障流程 ----------
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  systemd 服务排障流程${NC}"
echo -e "${CYAN}========================================${NC}"
cat << 'EOF'
服务起不来? 按这个顺序排查:

1. systemctl status 服务名
   → 看Active状态和最近几行日志

2. journalctl -u 服务名 -n 50 --no-pager
   → 看完整错误日志

3. 手动执行ExecStart的命令
   → 直接跑看报不报错

4. 检查配置文件语法
   → nginx -t / httpd -t / named-checkconf

5. 检查端口占用
   → ss -tlnp | grep 端口号

6. 检查权限
   → ls -la 文件路径 / namei -l 路径

7. 检查SELinux
   → getenforce / ausearch -m avc
EOF

echo -e "${GREEN}[完成] Lab 07 systemd 实战结束${NC}"
