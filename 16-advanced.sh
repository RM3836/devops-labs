#!/bin/bash
# ============================================
# DevOps实战 Lab 16-20: 高级工具合集(实操版)
# 运行: bash 16-advanced.sh
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

has() { command -v "$1" >/dev/null 2>&1; }

# ============================================================
# Lab 16: Kubernetes(实操, kind)
# ============================================================
lab16_k8s() {
    section "Lab 16: Kubernetes(实操, kind)"

    cat << 'EOF'
核心概念:
  Pod         最小部署单元(1个或多个容器)
  Deployment  管理 Pod(副本数/滚动更新/回滚)
  Service     服务发现 + 负载均衡(给 Pod 稳定 IP)
  Namespace   资源隔离
  ConfigMap   非敏感配置 / Secret 敏感配置
  Ingress     HTTP(S) 入口路由
EOF

    if ! has kubectl; then
        fail "未找到 kubectl,请先安装: 见 https://kubernetes.io/zh-cn/docs/tasks/tools/"
        info "以下为 YAML 演示(不执行)"
        cat << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata: { name: myapp }
spec:
  replicas: 3
  selector: { matchLabels: { app: myapp } }
  template:
    metadata: { labels: { app: myapp } }
    spec:
      containers:
      - name: myapp
        image: nginx:alpine
        ports: [ { containerPort: 80 } ]
EOF
        return 0
    fi

    # 检测是否已有可用的 K8s 集群
    if kubectl cluster-info >/dev/null 2>&1; then
        info "检测到可用的 Kubernetes 集群"
    elif has docker && docker info >/dev/null 2>&1 && has kind; then
        info "用 kind 启动单节点集群(复用 Docker daemon, 无需虚拟机)"
        cmd "kind create cluster --name lab"
        kind create cluster --name lab --wait 120s
        warn "演示结束后清理: kind delete cluster --name lab"
    elif has docker && docker info >/dev/null 2>&1; then
        warn "检测到 Docker 但未装 kind。安装: curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64 && chmod +x kind"
        warn "kind 相比 minikube 无需虚拟机, 直接复用 Docker daemon, 资源占用更低"
        info "以下为命令演示(不执行)"
        cat << 'EOF'
kind create cluster --name lab
kubectl get nodes
EOF
        return 0
    else
        fail "无 kubectl 且无 Docker/kind 环境。minikube 需虚拟机, 推荐 kind(复用 Docker)"
        return 0
    fi

    info "部署一个 Nginx 应用(Deployment + Service):"
    cat > /tmp/lab-k8s.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: lab-nginx
spec:
  replicas: 2
  selector:
    matchLabels: { app: lab-nginx }
  template:
    metadata:
      labels: { app: lab-nginx }
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: lab-nginx-svc
spec:
  selector: { app: lab-nginx }
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
EOF

    cmd "kubectl apply -f /tmp/lab-k8s.yaml"
    kubectl apply -f /tmp/lab-k8s.yaml

    info "等待 Pod 就绪..."
    kubectl wait --for=condition=ready pod -l app=lab-nginx --timeout=90s 2>/dev/null || kubectl rollout status deploy/lab-nginx --timeout=90s

    echo ""
    info "查看资源:"
    cmd "kubectl get pods,deploy,svc"
    kubectl get pods,deploy,svc

    echo ""
    info "扩容到 4 副本:"
    cmd "kubectl scale deploy lab-nginx --replicas=4"
    kubectl scale deploy lab-nginx --replicas=4
    kubectl get pods -l app=lab-nginx

    echo ""
    info "查看 Pod 日志:"
    POD=$(kubectl get pod -l app=lab-nginx -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    [ -n "$POD" ] && kubectl logs "$POD" 2>/dev/null | head -3

    echo ""
    info "清理演示资源(保留集群):"
    kubectl delete -f /tmp/lab-k8s.yaml 2>/dev/null

    info "[完成] Lab 16 K8s 实操结束"
}

# ============================================================
# Lab 17: Helm(实操)
# ============================================================
lab17_helm() {
    section "Lab 17: Helm(实操)"

    if ! has helm; then
        fail "未找到 helm,安装: curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash"
        info "以下为命令演示(不执行)"
        cat << 'EOF'
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install my-nginx bitnami/nginx
helm list
helm upgrade my-nginx bitnami/nginx --set replicaCount=3
helm rollback my-nginx 1
helm uninstall my-nginx
EOF
        return 0
    fi

    if ! kubectl cluster-info >/dev/null 2>&1; then
        fail "需要先有 K8s 集群(见 Lab 16), 否则 Helm 无处安装"
        return 0
    fi

    info "添加 bitnami 仓库:"
    cmd "helm repo add bitnami https://charts.bitnami.com/bitnami"
    helm repo add bitnami https://charts.bitnami.com/bitnami 2>/dev/null || true
    helm repo update 2>/dev/null || true

    info "安装 nginx chart:"
    cmd "helm install lab-nginx bitnami/nginx"
    helm install lab-nginx bitnami/nginx 2>&1 | head -20 || {
        fail "安装失败(可能是镜像拉取问题, 检查镜像加速)"
        return 0
    }

    info "查看已安装的 release:"
    cmd "helm list"
    helm list

    info "卸载:"
    cmd "helm uninstall lab-nginx"
    helm uninstall lab-nginx 2>/dev/null

    info "[完成] Lab 17 Helm 实操结束"
}

# ============================================================
# Lab 18: LVS + HAProxy 负载均衡
# ============================================================
lab18_lvs() {
    section "Lab 18: LVS + HAProxy 负载均衡"

    if ! has ipvsadm; then
        fail "未找到 ipvsadm(需 root)。安装: apt install ipvsadm"
        info "以下为命令演示(不执行)"
        cat << 'EOF'
# LVS 四层负载均衡
ipvsadm -A -t 192.168.1.100:80 -s wlc          # 添加虚拟服务(加权最少连接)
ipvsadm -a -t 192.168.1.100:80 -r 192.168.1.101:80 -g -w 3  # 添加后端(DR模式)
ipvsadm -Ln                                     # 查看规则
ipvsadm --stats                                 # 查看统计

# HAProxy 四/七层
# 配置 /etc/haproxy/haproxy.cfg 的 backend 段
EOF
        return 0
    fi

    [ "$(id -u)" = "0" ] || {
        fail "ipvsadm 需要 root 权限, 请: sudo bash 16-advanced.sh"
        return 0
    }

    info "查看当前 LVS 规则:"
    cmd "ipvsadm -Ln"
    ipvsadm -Ln 2>/dev/null || echo "(暂无规则)"

    info "[完成] Lab 18 LVS 实操结束(完整部署需多台后端, 本 Lab 演示命令)"
}

# ============================================================
# Lab 19: Consul 服务发现(实操)
# ============================================================
lab19_consul() {
    section "Lab 19: Consul 服务发现(实操)"

    if ! has docker || ! docker info >/dev/null 2>&1; then
        fail "需要 Docker(且 daemon 运行中)来起 Consul 容器"
        info "以下为命令演示(不执行)"
        cat << 'EOF'
docker run -d --name consul -p 8500:8500 consul agent -server -bootstrap -ui -client=0.0.0.0
curl -X PUT http://localhost:8500/v1/agent/service/register -d '{...}'
curl http://localhost:8500/v1/catalog/service/web
EOF
        return 0
    fi

    info "用 Docker 启动 Consul(单节点 server):"
    docker rm -f lab-consul >/dev/null 2>&1 || true
    cmd "docker run -d --name lab-consul -p 8500:8500 consul agent -server -bootstrap -ui -client=0.0.0.0"
    docker run -d --name lab-consul -p 8500:8500 consul agent -server -bootstrap -ui -client=0.0.0.0 >/dev/null
    sleep 3

    info "注册一个服务:"
    cmd "curl -X PUT http://localhost:8500/v1/agent/service/register -d '{...web服务...}'"
    curl -s -X PUT http://localhost:8500/v1/agent/service/register \
        -d '{"ID":"web1","Name":"web","Address":"127.0.0.1","Port":8080}' >/dev/null
    info "服务注册成功"

    echo ""
    info "查询服务:"
    cmd "curl http://localhost:8500/v1/catalog/service/web"
    curl -s http://localhost:8500/v1/catalog/service/web | head -c 500
    echo ""

    echo ""
    info "KV 配置中心演示:"
    cmd "curl -X PUT http://localhost:8500/v1/kv/config/db_host -d '192.168.1.200'"
    curl -s -X PUT http://localhost:8500/v1/kv/config/db_host -d '192.168.1.200' >/dev/null
    cmd "curl http://localhost:8500/v1/kv/config/db_host?raw"
    curl -s "http://localhost:8500/v1/kv/config/db_host?raw"
    echo ""

    echo ""
    info "Web UI: http://localhost:8500/ui"
    warn "演示结束清理: docker rm -f lab-consul"
    info "[完成] Lab 19 Consul 服务发现实操结束"
}

# ============================================================
# Lab 20: Supervisor 进程管理(实操)
# ============================================================
lab20_supervisor() {
    section "Lab 20: Supervisor 进程管理(实操)"

    if ! has supervisord && ! has supervisorctl; then
        fail "未找到 supervisor,安装: pip install supervisor 或 apt install supervisor"
        info "以下为命令演示(不执行)"
        cat << 'EOF'
# 配置 /etc/supervisor/conf.d/myapp.conf
[program:myapp]
command=python3 /opt/app/main.py
autostart=true
autorestart=true
stdout_logfile=/var/log/myapp.log

# 管理
supervisorctl reread
supervisorctl update
supervisorctl status
supervisorctl restart myapp
EOF
        return 0
    fi

    info "Supervisor 三大组件: supervisord(守护进程) + supervisorctl(控制) + 配置文件"
    echo ""

    info "准备一个演示程序(一个会崩溃的脚本):"
    cat > /tmp/lab-crash.py << 'PYEOF'
import time, sys
print("进程启动, PID:", __import__("os").getpid(), flush=True)
time.sleep(5)
print("模拟崩溃退出", flush=True)
sys.exit(1)
PYEOF
    info "演示脚本: /tmp/lab-crash.py(运行5秒后自动退出)"

    echo ""
    info "Supervisor 的价值: 进程崩溃后 autorestart 自动拉起"
    cat << 'EOF'
[program:lab-crash]
command=python3 /tmp/lab-crash.py
autostart=true
autorestart=true          # 崩溃自动重启
startretries=3            # 最多重试3次
stdout_logfile=/tmp/lab-crash.log

supervisor vs systemd:
  supervisor  Python 项目常用, 配置简单, 适合用户态进程
  systemd     系统级服务管理, 功能更强大, 现代 Linux 默认
EOF

    echo ""
    info "常用命令速查:"
    cat << 'EOF'
supervisorctl reread          读取新配置
supervisorctl update          应用配置变更
supervisorctl status          查看所有进程状态
supervisorctl start/stop/restart 程序名
supervisorctl tail -f 程序名  实时看日志
EOF

    info "[完成] Lab 20 Supervisor 实操结束"
}

# ============================================================
# 主流程
# ============================================================
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Lab 16-20: 高级工具实操合集${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

lab16_k8s
lab17_helm
lab18_lvs
lab19_consul
lab20_supervisor

echo ""
echo -e "${GREEN}[全部完成] Lab 16-20 高级工具实操合集结束${NC}"
