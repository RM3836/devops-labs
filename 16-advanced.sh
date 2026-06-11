#!/bin/bash
# ============================================
# DevOps实战 Lab 16-20: 高级工具合集
# 运行: bash 16-advanced.sh
# ============================================

CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Lab 16: Kubernetes (K8s)${NC}"
echo -e "${CYAN}========================================${NC}"
cat << 'EOF'

核心概念:
  Pod           最小部署单元(1个或多个容器)
  Deployment    管理Pod(副本数/滚动更新/回滚)
  Service       服务发现+负载均衡(给Pod一个稳定IP)
  Namespace     命名空间(隔离资源)
  ConfigMap     配置数据(非敏感)
  Secret        敏感数据(密码/证书,base64编码)
  Ingress       入口(HTTP/HTTPS路由)
  PV/PVC        持久化存储
  Node          工作节点
  Master        控制节点(API Server/etcd/Scheduler/Controller Manager)

本地学习环境:
  # minikube (单节点)
  minikube start --driver=docker

  # kind (Docker-in-Docker)
  kind create cluster --name lab

基本操作:
  kubectl get nodes                      查看节点
  kubectl get pods -A                    所有命名空间的Pod
  kubectl get pods -n default            指定命名空间
  kubectl get svc                        查看Service
  kubectl get deploy                     查看Deployment
  kubectl describe pod pod名             Pod详情
  kubectl logs pod名                     查看日志
  kubectl logs -f pod名                  实时日志
  kubectl exec -it pod名 -- bash         进入Pod
  kubectl apply -f deployment.yaml       创建/更新资源
  kubectl delete -f deployment.yaml      删除资源
  kubectl scale deploy app --replicas=5  扩容
  kubectl rollout history deploy app     查看版本历史
  kubectl rollout undo deploy app        回滚

Deployment 示例:
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: myapp
    namespace: default
  spec:
    replicas: 3
    selector:
      matchLabels:
        app: myapp
    template:
      metadata:
        labels:
          app: myapp
      spec:
        containers:
        - name: myapp
          image: myapp:v1
          ports:
          - containerPort: 8080
          resources:
            requests: { cpu: "100m", memory: "128Mi" }
            limits:   { cpu: "500m", memory: "256Mi" }
          readinessProbe:
            httpGet: { path: /health, port: 8080 }
          livenessProbe:
            httpGet: { path: /health, port: 8080 }
          env:
          - name: APP_ENV
            valueFrom:
              configMapKeyRef: { name: app-config, key: env }

Service 示例:
  apiVersion: v1
  kind: Service
  metadata:
    name: myapp-svc
  spec:
    selector:
      app: myapp
    ports:
    - port: 80
      targetPort: 8080
    type: ClusterIP    # ClusterIP(内部)/NodePort(节点端口)/LoadBalancer(云LB)

Ingress 示例:
  apiVersion: networking.k8s.io/v1
  kind: Ingress
  metadata:
    name: myapp-ingress
    annotations:
      nginx.ingress.kubernetes.io/rewrite-target: /
  spec:
    rules:
    - host: app.example.com
      http:
        paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: myapp-svc
              port: { number: 80 }

EOF

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Lab 17: Helm (K8s包管理器)${NC}"
echo -e "${CYAN}========================================${NC}"
cat << 'EOF'

安装:
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

基本操作:
  helm repo add bitnami https://charts.bitnami.com/bitnami   添加仓库
  helm repo update                                             更新仓库
  helm search repo nginx                                       搜索chart
  helm install my-nginx bitnami/nginx                          安装
  helm list                                                    列出已安装
  helm upgrade my-nginx bitnami/nginx --set replicaCount=3     升级
  helm rollback my-nginx 1                                     回滚到版本1
  helm uninstall my-nginx                                      卸载
  helm show chart bitnami/nginx                                查看chart信息
  helm template my-nginx bitnami/nginx                         渲染模板(不安装)

自定义Chart:
  helm create mychart                创建chart骨架
  mychart/
  ├── Chart.yaml         # chart元数据
  ├── values.yaml        # 默认值
  ├── templates/         # 模板文件
  │   ├── deployment.yaml
  │   ├── service.yaml
  │   └── _helpers.tpl
  └── charts/            # 依赖的子chart

  helm install myrelease ./mychart -f custom-values.yaml   用自定义值安装

EOF

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Lab 18: LVS + HAProxy 负载均衡${NC}"
echo -e "${CYAN}========================================${NC}"
cat << 'EOF'

LVS (Linux Virtual Server, 四层):
  # 工作模式
  DR(直接路由)   性能最高,Real Server直接回客户端
  NAT            最简单,所有流量经过LVS
  TUN(隧道)      跨网段,IP隧道封装

  # 调度算法
  rr   轮询        wrr  加权轮询
  lc   最少连接     wlc  加权最少连接(默认)
  sh   源哈希       dh   目标哈希

  # 管理工具: ipvsadm
  ipvsadm -A -t 192.168.1.100:80 -s wlc          添加虚拟服务
  ipvsadm -a -t 192.168.1.100:80 -r 192.168.1.101:80 -g -w 3  添加后端(DR模式,-g)
  ipvsadm -Ln                                     查看规则
  ipvsadm --stats                                 查看统计

HAProxy (四/七层):
  安装: apt install haproxy

  配置 /etc/haproxy/haproxy.cfg:
    global
        maxconn 50000
        log /dev/log local0

    defaults
        mode http
        timeout connect 5s
        timeout client 30s
        timeout server 30s
        option httplog

    frontend http-in
        bind *:80
        acl is_api path_beg /api
        use_backend api-servers if is_api
        default_backend web-servers

    backend web-servers
        balance roundrobin
        option httpchk GET /health
        server web1 192.168.1.101:8080 check inter 3s fall 3 rise 2 weight 3
        server web2 192.168.1.102:8080 check inter 3s fall 3 rise 2 weight 2
        server web3 192.168.1.103:8080 check inter 3s fall 3 rise 2 backup

    backend api-servers
        balance leastconn
        server api1 192.168.1.201:3000 check
        server api2 192.168.1.202:3000 check

    listen stats
        bind *:8404
        stats enable
        stats uri /stats
        stats auth admin:password

  管理:
    systemctl restart haproxy
    haproxy -c -f /etc/haproxy/haproxy.cfg   检查配置

负载均衡对比(面试):
  工具          层级    性能    功能             场景
  LVS           L4      最高    简单转发         大规模入口
  HAProxy       L4/L7   高      ACL/健康检查     API网关/微服务
  Nginx         L7      中      反向代理/静态    Web服务器

EOF

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Lab 19: Consul + Nacos 服务发现${NC}"
echo -e "${CYAN}========================================${NC}"
cat << 'EOF'

Consul (HashiCorp):
  功能: 服务注册发现 + KV配置中心 + 健康检查 + 多数据中心

  docker run -d --name consul -p 8500:8500 -p 8600:8600 consul agent -server -bootstrap -ui -client=0.0.0.0

  # 注册服务
  curl -X PUT http://localhost:8500/v1/agent/service/register -d '{
    "ID": "web1",
    "Name": "web",
    "Tags": ["v1"],
    "Address": "192.168.1.101",
    "Port": 8080,
    "Check": {
      "HTTP": "http://192.168.1.101:8080/health",
      "Interval": "10s"
    }
  }'

  # 查询服务
  curl http://localhost:8500/v1/catalog/service/web
  dig @127.0.0.1 -p 8600 web.service.consul SRV   # DNS查询

  # KV配置
  curl -X PUT http://localhost:8500/v1/kv/config/db_host -d '192.168.1.200'
  curl http://localhost:8500/v1/kv/config/db_host?raw

Nacos (阿里):
  功能: 服务注册发现 + 配置中心(支持动态推送)

  docker run -d --name nacos -p 8848:8848 -e MODE=standalone nacos/nacos-server

  # 控制台: http://localhost:8848/nacos  账号nacos/nacos

  # 注册服务(Java SDK)
  # NamingService naming = NamingFactory.createNamingService("127.0.0.1:8848");
  # naming.registerInstance("my-service", "192.168.1.101", 8080);

  # 配置管理(Java SDK)
  # ConfigService config = ConfigFactory.createConfigService("127.0.0.1:8848");
  # String content = config.getConfig("app.properties", "DEFAULT_GROUP", 3000);
  # config.addListener("app.properties", "DEFAULT_GROUP", listener);  # 动态监听

Consul vs Nacos:
  特性          Consul            Nacos
  语言生态      Go/多语言         Java/Spring Cloud
  配置中心      KV(简单)          Data ID+Group(灵活)
  健康检查      HTTP/TCP/gRPC/脚本 HTTP/TCP
  多数据中心    原生支持          需额外配置
  社区          国际主流          国内主流(阿里)

EOF

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Lab 20: Supervisor 进程管理${NC}"
echo -e "${CYAN}========================================${NC}"
cat << 'EOF'

安装: pip install supervisor  或  apt install supervisor

配置 /etc/supervisor/conf.d/myapp.conf:
  [program:myapp]
  command=python3 /opt/app/main.py
  directory=/opt/app
  user=www-data
  autostart=true
  autorestart=true
  startretries=3
  redirect_stderr=true
  stdout_logfile=/var/log/myapp.log
  stdout_logfile_maxbytes=10MB
  stdout_logfile_backups=5
  environment=APP_ENV="production",DB_HOST="127.0.0.1"

管理命令:
  supervisorctl reread              读取新配置
  supervisorctl update              更新(启停变化的)
  supervisorctl start myapp         启动
  supervisorctl stop myapp          停止
  supervisorctl restart myapp       重启
  supervisorctl status              查看所有状态
  supervisorctl tail -f myapp       实时看日志

批量管理:
  [group:webapps]
  programs=myapp,worker,scheduler

  supervisorctl start webapps:*     启动组内所有
  supervisorctl stop webapps:*      停止组内所有

supervisor vs systemd:
  supervisor    Python项目常用,配置简单,适合用户态进程
  systemd       系统级服务管理,功能更强大,现代Linux默认

EOF

echo -e "${GREEN}[完成] Lab 16-20 高级工具合集 实战结束${NC}"
