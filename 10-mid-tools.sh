#!/bin/bash
# ============================================
# DevOps实战 Lab 10-15: 中级工具合集(实操版)
# 运行: bash 10-mid-tools.sh
# ============================================

set -e

CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# ---------- 工具函数 ----------
info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
fail()  { echo -e "${RED}[ERROR]${NC} $1"; }
cmd()   { echo -e "${YELLOW}\$ $1${NC}"; }

section() {
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}========================================${NC}"
}

# 通用: 检查命令是否存在
has() { command -v "$1" >/dev/null 2>&1; }

# ============================================================
# Lab 10: Redis 缓存(实操)
# ============================================================
lab10_redis() {
    section "Lab 10: Redis 缓存(实操)"

    if has redis-cli; then
        info "检测到本机 Redis,使用本地实例"
        redis-cli ping >/dev/null 2>&1 || {
            warn "Redis 未运行,尝试启动..."
            service redis-server start >/dev/null 2>&1 || sudo service redis-server start >/dev/null 2>&1 || true
            sleep 1
        }
        RCLI="redis-cli"
    elif has docker && docker info >/dev/null 2>&1; then
        info "用 Docker 启动 Redis 容器"
        docker rm -f lab-redis >/dev/null 2>&1 || true
        docker run -d --name lab-redis -p 6379:6379 redis:alpine >/dev/null 2>&1
        sleep 2
        RCLI="docker exec lab-redis redis-cli"
        warn "演示结束后请执行: docker rm -f lab-redis 清理容器"
    else
        fail "未找到 redis-cli 或 Docker,请先安装: apt install redis-server 或 docker"
        info "以下为纯命令演示(不执行):"
        cat << 'EOF'
SET name "kainan"          # 设置键
GET name                   # 读取键
SET token "abc" EX 3600    # 设置+10分钟过期
INCR counter               # 自增
EOF
        return 0
    fi

    info "验证连接:"
    cmd "$RCLI ping"
    $RCLI ping

    echo ""
    info "String 类型:"
    cmd "$RCLI SET name kainan"
    $RCLI SET name kainan
    cmd "$RCLI GET name"
    $RCLI GET name
    cmd "$RCLI SET token abc EX 60"
    $RCLI SET token abc EX 60
    cmd "$RCLI TTL token  # 剩余过期时间(秒)"
    $RCLI TTL token

    echo ""
    info "自增(计数器场景):"
    $RCLI DEL counter >/dev/null
    cmd "$RCLI INCR counter"
    $RCLI INCR counter
    cmd "$RCLI INCR counter"
    $RCLI INCR counter

    echo ""
    info "Hash 类型(对象):"
    cmd "$RCLI HSET user:1 name kainan age 22"
    $RCLI HSET user:1 name kainan age 22
    cmd "$RCLI HGETALL user:1"
    $RCLI HGETALL user:1

    echo ""
    info "List 类型(队列):"
    $RCLI DEL queue >/dev/null
    cmd "$RCLI LPUSH queue task1 task2"
    $RCLI LPUSH queue task1 task2
    cmd "$RCLI RPOP queue  # 右弹出(先进先出)"
    $RCLI RPOP queue

    echo ""
    info "运维命令:"
    cmd "$RCLI DBSIZE  # key 总数"
    $RCLI DBSIZE
    cmd "$RCLI INFO memory | head -3  # 内存占用"
    $RCLI INFO memory 2>/dev/null | grep -E "used_memory_human|maxmemory_human" || true

    echo ""
    info "[完成] Lab 10 Redis 实操结束"
}

# ============================================================
# Lab 11: MySQL 数据库(实操)
# ============================================================
lab11_mysql() {
    section "Lab 11: MySQL 数据库(实操)"

    if ! has docker; then
        fail "未找到 Docker,请先安装。或用: apt install mysql-server"
        info "以下为 SQL 演示(不执行):"
        cat << 'EOF'
CREATE DATABASE mydb CHARACTER SET utf8mb4;
USE mydb;
CREATE TABLE users (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(50), age INT);
INSERT INTO users (name, age) VALUES ('kainan', 22);
SELECT * FROM users WHERE age > 20;
EOF
        return 0
    fi

    if ! docker info >/dev/null 2>&1; then
        fail "Docker daemon 未运行,请先启动 Docker Desktop 或 systemctl start docker"
        return 0
    fi

    info "用 Docker 启动 MySQL 8"
    docker rm -f lab-mysql >/dev/null 2>&1 || true
    docker run -d --name lab-mysql \
        -e MYSQL_ROOT_PASSWORD=root123456 \
        -e MYSQL_DATABASE=mydb \
        -p 3306:3306 mysql:8 >/dev/null 2>&1

    info "等待 MySQL 就绪(最多30秒)..."
    for i in $(seq 1 30); do
        if docker exec lab-mysql mysqladmin ping -uroot -proot123456 >/dev/null 2>&1; then
            info "MySQL 就绪"
            break
        fi
        sleep 1
    done

    MYSQL="docker exec lab-mysql mysql -uroot -proot123456 mydb"

    info "建表:"
    cmd "$MYSQL -e 'CREATE TABLE users (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(50), age INT);'"
    $MYSQL -e "CREATE TABLE users (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(50), age INT);"

    info "插入数据:"
    cmd "$MYSQL -e \"INSERT INTO users (name, age) VALUES ('kainan', 22), ('zhangsan', 25);\""
    $MYSQL -e "INSERT INTO users (name, age) VALUES ('kainan', 22), ('zhangsan', 25);"

    info "查询:"
    cmd "$MYSQL -e 'SELECT * FROM users;'"
    $MYSQL -e "SELECT * FROM users;"

    info "条件查询:"
    cmd "$MYSQL -e 'SELECT * FROM users WHERE age > 22;'"
    $MYSQL -e "SELECT * FROM users WHERE age > 22;"

    info "更新:"
    cmd "$MYSQL -e \"UPDATE users SET age = 23 WHERE name = 'kainan';\""
    $MYSQL -e "UPDATE users SET age = 23 WHERE name = 'kainan';"
    $MYSQL -e "SELECT * FROM users WHERE name = 'kainan';"

    info "备份演示(mysqldump):"
    cmd "docker exec lab-mysql mysqldump -uroot -proot123456 mydb > /tmp/mydb-backup.sql"
    docker exec lab-mysql mysqldump -uroot -proot123456 mydb > /tmp/mydb-backup.sql 2>/dev/null
    info "备份文件: /tmp/mydb-backup.sql ($(wc -l < /tmp/mydb-backup.sql) 行)"

    echo ""
    warn "演示结束,清理容器: docker rm -f lab-mysql"
    info "[完成] Lab 11 MySQL 实操结束"
}

# ============================================================
# Lab 12: Ansible 批量管理(实操)
# ============================================================
lab12_ansible() {
    section "Lab 12: Ansible 批量管理(实操)"

    if ! has ansible; then
        fail "未找到 ansible,请先安装: pip install ansible (或 apt install ansible)"
        info "以下为命令演示(不执行):"
        cat << 'EOF'
ansible localhost -m ping                          # 测试本机连通
ansible localhost -m shell -a "uptime"             # 执行命令
ansible localhost -m file -a "path=/tmp/t state=directory"  # 创建目录
EOF
        return 0
    fi

    info "Ad-hoc: 测试本机连通(ping 模块)"
    cmd "ansible localhost -m ping"
    ansible localhost -m ping 2>&1 | tail -6

    echo ""
    info "Ad-hoc: 执行 shell 命令"
    cmd "ansible localhost -m shell -a 'uptime'"
    ansible localhost -m shell -a "uptime" 2>&1 | tail -4

    echo ""
    info "Ad-hoc: 用 file 模块创建目录"
    cmd "ansible localhost -m file -a 'path=/tmp/ansible-lab state=directory'"
    ansible localhost -m file -a "path=/tmp/ansible-lab state=directory" 2>&1 | tail -4
    info "验证: $(ls -ld /tmp/ansible-lab 2>/dev/null || echo '已创建 /tmp/ansible-lab')"

    echo ""
    info "[完成] Lab 12 Ansible 实操结束"
}

# ============================================================
# Lab 13: 监控(实操, psutil)
# ============================================================
lab13_monitor() {
    section "Lab 13: 系统监控(实操, psutil)"

    PY="python3"
    has python3 || PY="python"

    if ! $PY -c "import psutil" >/dev/null 2>&1; then
        warn "未安装 psutil,尝试安装..."
        $PY -m pip install psutil -q 2>&1 | tail -1 || {
            fail "安装失败,请手动执行: pip install psutil"
            return 0
        }
    fi

    info "采集 CPU / 内存 / 磁盘实时指标:"
    $PY - << 'PYEOF'
import psutil
import time

print("采集系统指标(2次采样):\n")
for i in range(2):
    cpu = psutil.cpu_percent(interval=1)
    mem = psutil.virtual_memory()
    disk = psutil.disk_usage('/')
    net = psutil.net_io_counters()

    print(f"--- 第{i+1}次采样 ---")
    print(f"CPU 使用率 : {cpu}%")
    print(f"内存       : {mem.used/1024**3:.1f}G / {mem.total/1024**3:.1f}G ({mem.percent}%)")
    print(f"磁盘       : {disk.used/1024**3:.1f}G / {disk.total/1024**3:.1f}G ({disk.percent}%)")
    print(f"网络       : 发送 {net.bytes_sent/1024**2:.1f}M / 接收 {net.bytes_recv/1024**2:.1f}M")
    print(f"进程总数   : {len(psutil.pids())}")
    print()
    if i == 0:
        time.sleep(0.5)

# Top 3 内存占用进程
print("Top 3 内存占用进程:")
procs = []
for p in psutil.process_iter(['name', 'memory_info']):
    try:
        procs.append((p.info['name'], p.info['memory_info'].rss))
    except (psutil.NoSuchProcess, psutil.AccessDenied):
        pass
procs.sort(key=lambda x: x[1], reverse=True)
for name, rss in procs[:3]:
    print(f"  {name:20s} {rss/1024**2:.0f} MB")
PYEOF

    echo ""
    info "对应 Prometheus 指标(node_exporter):"
    cat << 'EOF'
  node_cpu_seconds_total       CPU 累计秒数
  node_memory_MemAvailable_bytes  可用内存
  node_filesystem_avail_bytes     可用磁盘
  # 生产环境用 node_exporter 暴露, Prometheus 拉取, Grafana 展示
EOF

    info "[完成] Lab 13 监控实操结束"
}

# ============================================================
# Lab 14: 日志分析(实操)
# ============================================================
lab14_log() {
    section "Lab 14: 日志分析(实操)"

    info "生成一份真实风格的 Nginx 访问日志样例:"
    LOG=/tmp/lab-access.log
    cat > "$LOG" << 'EOF'
192.168.1.10 - - [09/Sep/2026:17:00:01 +0800] "GET /index.html HTTP/1.1" 200 1024 "-" "Mozilla/5.0"
192.168.1.11 - - [09/Sep/2026:17:00:02 +0800] "POST /api/login HTTP/1.1" 500 512 "-" "curl/7.68"
192.168.1.12 - - [09/Sep/2026:17:00:03 +0800] "GET /api/users HTTP/1.1" 200 2048 "-" "Mozilla/5.0"
192.168.1.10 - - [09/Sep/2026:17:00:04 +0800] "GET /static/app.js HTTP/1.1" 200 4096 "-" "Mozilla/5.0"
192.168.1.13 - - [09/Sep/2026:17:00:05 +0800] "GET /api/data HTTP/1.1" 502 0 "-" "curl/7.68"
192.168.1.14 - - [09/Sep/2026:17:00:06 +0800] "GET /health HTTP/1.1" 200 128 "-" "curl/7.68"
192.168.1.11 - - [09/Sep/2026:17:00:07 +0800] "POST /api/login HTTP/1.1" 401 256 "-" "curl/7.68"
192.168.1.15 - - [09/Sep/2026:17:00:08 +0800] "GET /index.html HTTP/1.1" 200 1024 "-" "Mozilla/5.0"
EOF
    info "样例文件: $LOG ($(wc -l < "$LOG") 行)"

    echo ""
    info "1. 统计状态码分布(grep + awk + sort):"
    cmd "awk '{print \$9}' $LOG | sort | uniq -c | sort -rn"
    awk '{print $9}' "$LOG" | sort | uniq -c | sort -rn

    echo ""
    info "2. 找出错误请求(5xx):"
    cmd "awk '\$9 >= 500' $LOG"
    awk '$9 >= 500' "$LOG"

    echo ""
    info "3. 统计每个 IP 的请求数:"
    cmd "awk '{print \$1}' $LOG | sort | uniq -c | sort -rn"
    awk '{print $1}' "$LOG" | sort | uniq -c | sort -rn

    echo ""
    info "4. 提取访问最多的 URL:"
    cmd "awk '{print \$7}' $LOG | sort | uniq -c | sort -rn | head -3"
    awk '{print $7}' "$LOG" | sort | uniq -c | sort -rn | head -3

    echo ""
    info "5. 按小时统计请求量:"
    cmd "grep -oE '[0-9]{2}/Sep/2026:[0-9]{2}' $LOG | cut -d: -f2 | sort | uniq -c"
    grep -oE '[0-9]{2}/Sep/2026:[0-9]{2}' "$LOG" | cut -d: -f2 | sort | uniq -c

    info "[完成] Lab 14 日志分析实操结束"
}

# ============================================================
# Lab 15: CI/CD(实操)
# ============================================================
lab15_cicd() {
    section "Lab 15: CI/CD(实操)"

    info "本 Lab 演示 GitHub Actions 流水线,实际运行在 GitHub 云端"
    echo ""
    info "生成一个最小 CI 工作流文件(与仓库 .github/workflows/ci.yml 同类):"

    cat > /tmp/lab-ci-demo.yml << 'EOF'
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]

jobs:
  build-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: 运行测试脚本
        run: |
          echo "开始构建..."
          bash build.sh
          echo "构建完成"

      - name: 语法检查
        run: |
          for f in *.sh; do bash -n "$f" || exit 1; done
          echo "语法检查通过"
EOF

    info "工作流文件内容:"
    cat /tmp/lab-ci-demo.yml

    echo ""
    info "CI/CD 流水线概念(面试重点):"
    cat << 'EOF'
  CI(持续集成)  代码提交后自动构建+测试, 快速发现问题
  CD(持续交付)  测试通过后自动部署到测试/生产环境

  典型流水线阶段:
    拉代码 → 构建 → 测试 → 推送镜像 → 部署

  主流工具:
    GitHub Actions   GitHub 原生, 免费额度, 上手快
    Jenkins          传统自建, 可定制性强
    GitLab CI        GitLab 集成
EOF

    info "[完成] Lab 15 CI/CD 实操结束"
}

# ============================================================
# 主流程
# ============================================================
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Lab 10-15: 中级工具实操合集${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

lab10_redis
lab11_mysql
lab12_ansible
lab13_monitor
lab14_log
lab15_cicd

echo ""
echo -e "${GREEN}[全部完成] Lab 10-15 中级工具实操合集结束${NC}"
