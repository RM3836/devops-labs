#!/bin/bash
# ============================================
# DevOps实战 Lab 09: Nginx 反向代理+负载均衡
# 运行: bash 09-nginx.sh
# ============================================

CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Lab 09: Nginx 反向代理+负载均衡${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# 安装检查
if ! command -v nginx &>/dev/null; then
    echo "nginx未安装,请运行: apt install -y nginx"
    exit 1
fi

# ---------- 核心配置结构 ----------
echo -e "${YELLOW}[1] Nginx 配置结构${NC}"
echo "----------------------------------------"
cat << 'EOF'
配置文件: /etc/nginx/nginx.conf (主配置)
配置目录: /etc/nginx/conf.d/*.conf (站点配置)

配置结构:
  main        全局配置(worker进程数/日志/用户)
  ├── events  连接处理(最大连接数/epoll)
  └── http    HTTP相关
      ├── upstream      负载均衡后端组
      ├── server        虚拟主机(一个站点)
      │   ├── listen 80          监听端口
      │   ├── server_name        域名
      │   ├── location /         URL匹配规则
      │   │   ├── proxy_pass     反向代理
      │   │   ├── root           静态文件根目录
      │   │   └── try_files      尝试文件顺序
      │   └── error_page         错误页
      └── server        另一个站点...
EOF
echo ""

# ---------- 静态网站 ----------
echo -e "${YELLOW}[2] 实战: 静态网站${NC}"
echo "----------------------------------------"

mkdir -p /tmp/nginx-lab/site1
cat > /tmp/nginx-lab/site1/index.html << 'HTML'
<h1>站点1 - 静态网站</h1>
HTML

cat > /tmp/nginx-lab/site1.conf << 'CONF'
server {
    listen 8001;
    server_name localhost;
    root /tmp/nginx-lab/site1;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }

    # 静态资源缓存
    location ~* \.(jpg|png|css|js)$ {
        expires 7d;
        add_header Cache-Control "public, immutable";
    }
}
CONF

echo "静态站点配置:"
cat /tmp/nginx-lab/site1.conf
echo ""

# ---------- 反向代理 ----------
echo -e "${YELLOW}[3] 实战: 反向代理${NC}"
echo "----------------------------------------"

cat > /tmp/nginx-lab/proxy.conf << 'CONF'
# 反向代理到后端应用
server {
    listen 8002;
    server_name localhost;

    location / {
        proxy_pass http://127.0.0.1:5000;   # 转发到后端

        # 必须的代理头
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # 超时设置
        proxy_connect_timeout 10s;
        proxy_read_timeout 60s;
        proxy_send_timeout 60s;
    }
}
CONF

echo "反向代理配置:"
cat /tmp/nginx-lab/proxy.conf
echo ""

# ---------- 负载均衡 ----------
echo -e "${YELLOW}[4] 实战: 负载均衡${NC}"
echo "----------------------------------------"

cat > /tmp/nginx-lab/lb.conf << 'CONF'
# 负载均衡配置
upstream backend {
    # 调度算法:
    # 轮询(默认)     不写就是轮询
    # weight         加权轮询
    # ip_hash        按IP哈希(会话保持)
    # least_conn     最少连接
    # fair           按响应时间(需第三方模块)

    server 192.168.1.101:8080 weight=3;   # 权重3
    server 192.168.1.102:8080 weight=2;   # 权重2
    server 192.168.1.103:8080 weight=1;   # 权重1
    server 192.168.1.104:8080 backup;     # 备用(其他全挂才用)
}

server {
    listen 8003;
    server_name localhost;

    location / {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;

        # 健康检查(被动)
        proxy_next_upstream error timeout http_502 http_503;
        proxy_next_upstream_tries 3;
    }
}
CONF

echo "负载均衡配置:"
cat /tmp/nginx-lab/lb.conf
echo ""

# ---------- HTTPS配置 ----------
echo -e "${YELLOW}[5] HTTPS配置${NC}"
echo "----------------------------------------"
cat << 'CONF'
server {
    listen 443 ssl http2;
    server_name example.com;

    # 证书路径
    ssl_certificate     /etc/nginx/ssl/server.crt;
    ssl_certificate_key /etc/nginx/ssl/server.key;

    # SSL优化
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # HSTS(强制HTTPS)
    add_header Strict-Transport-Security "max-age=31536000" always;
}

# HTTP强制跳HTTPS
server {
    listen 80;
    server_name example.com;
    return 301 https://$server_name$request_uri;
}
CONF
echo ""

# ---------- location匹配规则 ----------
echo -e "${YELLOW}[6] location 匹配规则（面试重点）${NC}"
echo "----------------------------------------"
cat << 'EOF'
location = /exact       精确匹配(优先级最高)
location ^~ /prefix     前缀匹配(不再检查正则)
location ~ \.php$       正则匹配(区分大小写)
location ~* \.(jpg|png)$ 正则匹配(不区分大小写)
location /general       普通前缀匹配(优先级最低)

匹配顺序:
  1. 精确匹配 =
  2. 前缀匹配 ^~
  3. 正则 ~ (按配置文件顺序)
  4. 正则 ~*
  5. 普通前缀 /

常见location配置:
  # 禁止访问隐藏文件
  location ~ /\. { deny all; }

  # PHP-FPM
  location ~ \.php$ {
      fastcgi_pass 127.0.0.1:9000;
      fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
      include fastcgi_params;
  }

  # 跨域
  location /api/ {
      add_header Access-Control-Allow-Origin *;
      proxy_pass http://backend;
  }

  # 限流
  location /login {
      limit_req zone=login burst=5 nodelay;
      proxy_pass http://backend;
  }
EOF
echo ""

# ---------- Nginx排障 ----------
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Nginx 排障命令${NC}"
echo -e "${CYAN}========================================${NC}"
cat << 'EOF'
nginx -t                    检查配置语法
nginx -T                    检查并打印完整配置
nginx -s reload             平滑重载(不断开连接)
nginx -s stop               快速停止
tail -f /var/log/nginx/error.log   实时看错误日志
tail -f /var/log/nginx/access.log  实时看访问日志

常见错误:
  502 Bad Gateway     → 后端挂了/连不上
  504 Gateway Timeout → 后端响应太慢
  403 Forbidden       → 权限问题/SELinux/index缺失
  404 Not Found       → 路径错误/alias和root搞混
EOF

echo -e "${GREEN}[完成] Lab 09 Nginx 实战结束${NC}"
