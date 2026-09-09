#!/bin/bash
# ============================================
# DevOps实战 Lab 08: Docker 容器
# 运行: bash 08-docker.sh
# ============================================

CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Lab 08: Docker 容器实战${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# 检查Docker
if ! docker info &>/dev/null; then
    echo "Docker未运行,尝试启动..."
    service docker start 2>/dev/null || dockerd &>/dev/null &
    sleep 3
fi

# ---------- 基本概念 ----------
echo -e "${YELLOW}[1] 核心概念${NC}"
echo "----------------------------------------"
cat << 'EOF'
镜像(Image)      → 只读模板(类比: 类/安装包)
容器(Container)   → 镜像的运行实例(类比: 对象/进程)
仓库(Registry)    → 存放镜像的地方(Docker Hub/阿里云/Harbor)

镜像操作:
  docker pull nginx           拉取镜像
  docker images               列出本地镜像
  docker rmi nginx            删除镜像
  docker tag nginx mynginx:v1 打标签
  docker push mynginx:v1      推送到仓库
  docker save nginx > nginx.tar   导出为tar
  docker load < nginx.tar         从tar导入

容器操作:
  docker run -d --name web nginx   后台运行
  docker run -it ubuntu bash       交互式进入
  docker ps                        查看运行中容器
  docker ps -a                     查看所有容器(含停止的)
  docker stop web                  停止
  docker start web                 启动
  docker restart web               重启
  docker rm web                    删除容器
  docker exec -it web bash         进入运行中的容器
  docker logs web                  查看日志
  docker logs -f web               实时跟踪日志
  docker inspect web               查看详细信息
  docker stats                     实时资源监控
EOF
echo ""

# ---------- 常用run参数 ----------
echo -e "${YELLOW}[2] docker run 常用参数${NC}"
echo "----------------------------------------"
cat << 'EOF'
docker run [选项] 镜像名 [命令]

-d                后台运行
-it               交互式+伪终端
--name 容器名     给容器起名字
-p 8080:80        端口映射(宿主:容器)
-p 127.0.0.1:8080:80  只绑定本地
-v /host:/container   挂载目录
-v volname:/container 命名卷
-e KEY=VALUE      设置环境变量
--restart=always  开机自启
--network mynet   加入自定义网络
--memory 512m     内存限制
--cpus 1.5        CPU限制
--rm              容器停止后自动删除
-w /app           设置工作目录
-u 1000:1000      指定用户
EOF
echo ""

# ---------- 实战: 跑一个nginx ----------
echo -e "${YELLOW}[3] 实战: 运行Nginx${NC}"
echo "----------------------------------------"

echo '$ docker run -d --name lab-nginx -p 8080:80 nginx:alpine'
docker rm -f lab-nginx &>/dev/null
docker run -d --name lab-nginx -p 8080:80 nginx:alpine 2>/dev/null
sleep 2

echo '$ docker ps --filter name=lab-nginx'
docker ps --filter name=lab-nginx
echo ""

echo '$ curl -s http://localhost:8080 | head -5'
curl -s http://localhost:8080 | head -5
echo ""

echo '$ docker logs lab-nginx'
docker logs lab-nginx 2>/dev/null | tail -3
echo ""

# ---------- 实战: 自定义页面 ----------
echo -e "${YELLOW}[4] 实战: 自定义页面(挂载卷)${NC}"
echo "----------------------------------------"

mkdir -p /tmp/docker-lab/web
cat > /tmp/docker-lab/web/index.html << 'HTML'
<!DOCTYPE html>
<html><head><title>DevOps Lab</title></head>
<body><h1>Docker 实战成功!</h1><p>by 凯楠</p></body></html>
HTML

echo '$ docker run -d --name lab-web -p 8081:80 -v /tmp/docker-lab/web:/usr/share/nginx/html nginx:alpine'
docker rm -f lab-web &>/dev/null
docker run -d --name lab-web -p 8081:80 -v /tmp/docker-lab/web:/usr/share/nginx/html nginx:alpine 2>/dev/null
sleep 2

echo '$ curl http://localhost:8081'
curl -s http://localhost:8081
echo ""

# ---------- 实战: 写Dockerfile ----------
echo -e "${YELLOW}[5] 实战: 写Dockerfile${NC}"
echo "----------------------------------------"

mkdir -p /tmp/docker-lab/app
cat > /tmp/docker-lab/app/app.py << 'PYEOF'
from http.server import HTTPServer, BaseHTTPRequestHandler
import json, datetime, os

class H(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        data = {
            "message": "Hello from Docker!",
            "hostname": os.uname().nodename,
            "time": str(datetime.datetime.now()),
            "env": os.environ.get("APP_ENV", "dev")
        }
        self.wfile.write(json.dumps(data, indent=2).encode())
    def log_message(self, *a): pass

HTTPServer(('0.0.0.0', 5000), H).serve_forever()
PYEOF

cat > /tmp/docker-lab/app/Dockerfile << 'DOCKERFILE'
# 基础镜像
FROM python:3.11-slim

# 元数据(OCI 标准标签)
LABEL org.opencontainers.image.authors="RM3836 <steam3836@foxmail.com>"
LABEL org.opencontainers.image.description="DevOps Lab Demo App"

# 工作目录
WORKDIR /app

# 复制文件
COPY app.py .

# 环境变量
ENV APP_ENV=production
ENV PORT=5000

# 暴露端口
EXPOSE 5000

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s \
    CMD curl -f http://localhost:5000/ || exit 1

# 启动命令
CMD ["python3", "app.py"]
DOCKERFILE

echo "Dockerfile内容:"
cat /tmp/docker-lab/app/Dockerfile
echo ""

echo '$ docker build -t myapp:v1 /tmp/docker-lab/app/'
docker build -t myapp:v1 /tmp/docker-lab/app/ 2>&1 | tail -5
echo ""

echo '$ docker run -d --name lab-app -p 5000:5000 -e APP_ENV=staging myapp:v1'
docker rm -f lab-app &>/dev/null
docker run -d --name lab-app -p 5000:5000 -e APP_ENV=staging myapp:v1 2>/dev/null
sleep 2

echo '$ curl http://localhost:5000'
curl -s http://localhost:5000
echo ""

# ---------- docker-compose ----------
echo -e "${YELLOW}[6] docker-compose 多容器编排${NC}"
echo "----------------------------------------"

cat > /tmp/docker-lab/docker-compose.yml << 'YAMLEOF'
# 注: Compose v2 已废弃顶层 version 字段, 无需再声明
services:
  web:
    image: nginx:alpine
    ports:
      - "8082:80"
    volumes:
      - ./web:/usr/share/nginx/html
    depends_on:
      - app
    restart: always

  app:
    build: ./app
    ports:
      - "5001:5000"
    environment:
      - APP_ENV=production
    restart: always

  redis:
    image: redis:alpine
    ports:
      - "6379:6379"
    volumes:
      - redis-data:/data
    restart: always

volumes:
  redis-data:
YAMLEOF

echo "docker-compose.yml:"
cat /tmp/docker-lab/docker-compose.yml
echo ""
cat << 'EOF'
# 操作命令:
cd /tmp/docker-lab
docker-compose up -d        # 启动所有服务
docker-compose ps           # 查看状态
docker-compose logs -f      # 查看日志
docker-compose down         # 停止并删除
docker-compose up -d --build  # 重新构建并启动
EOF
echo ""

# ---------- 清理 ----------
echo -e "${YELLOW}[7] 清理资源${NC}"
echo "----------------------------------------"
echo "停止演示容器..."
docker rm -f lab-nginx lab-web lab-app &>/dev/null
echo "清理完成(保留镜像供后续使用)"
echo ""

# ---------- 速查表 ----------
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Docker 速查表${NC}"
echo -e "${CYAN}========================================${NC}"
cat << 'EOF'
日常操作:
  docker ps -a                     查看所有容器
  docker images                    查看所有镜像
  docker system df                 查看磁盘占用
  docker system prune -a           清理所有未使用资源
  docker exec -it 容器名 bash      进入容器调试
  docker cp 容器名:/path ./path    从容器拷贝文件

网络排查:
  docker network ls                查看网络
  docker network inspect bridge    查看网络详情
  docker port 容器名               查看端口映射

数据持久化:
  docker volume ls                 查看卷
  docker volume create myvol       创建卷
  docker volume inspect myvol      查看卷详情

Dockerfile最佳实践:
  - 用alpine基础镜像(小)
  - 合并RUN命令减少层数
  - .dockerignore排除无关文件
  - 多阶段构建减少最终镜像体积
  - 不要在镜像里存密码(用环境变量/secret)

EOF

echo -e "${GREEN}[完成] Lab 08 Docker 实战结束${NC}"
