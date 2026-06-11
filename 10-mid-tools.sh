#!/bin/bash
# ============================================
# DevOps实战 Lab 10-15: 中级工具合集
# 运行: bash 10-mid-tools.sh
# ============================================

CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Lab 10: Redis 缓存${NC}"
echo -e "${CYAN}========================================${NC}"
cat << 'EOF'

安装: apt install redis-server  或  docker run -d redis:alpine

基本操作:
  redis-cli                       连接
  redis-cli -h host -p 6379 -a password  远程连接

  # String
  SET name "kainan"               设置
  GET name                        获取
  SET token "abc" EX 3600         设置+过期时间(秒)
  INCR counter                    自增
  MSET k1 v1 k2 v2               批量设置

  # Hash(对象)
  HSET user:1 name "kainan" age 22
  HGET user:1 name
  HGETALL user:1

  # List(队列)
  LPUSH queue task1 task2         左插入
  RPOP queue                      右弹出(队列)
  LRANGE queue 0 -1               查看全部

  # Set(集合)
  SADD tags python linux docker
  SMEMBERS tags                   列出所有
  SISMEMBER tags python           判断是否存在

  # ZSet(有序集合/排行榜)
  ZADD scores 95 kainan 88 zhangsan
  ZREVRANGE scores 0 9 WITHSCORES  # Top10

运维命令:
  INFO                            服务器信息
  INFO memory                     内存使用
  DBSIZE                          key数量
  KEYS pattern                    查找key(生产慎用!)
  SCAN 0 MATCH pattern COUNT 100  安全的key扫描
  SLOWLOG GET 10                  慢查询日志
  MONITOR                         实时监控所有命令(调试用)
  CONFIG GET maxmemory            查看配置
  CONFIG SET maxmemory 256mb      动态改配置

持久化:
  RDB(快照)  → 配置 save 900 1 (900秒内1次修改就快照)
  AOF(日志)  → appendonly yes (每条命令都记录)
  混合模式   → aof-use-rdb-preamble yes (推荐)

哨兵(Sentinel)高可用:
  sentinel monitor mymaster 127.0.0.1 6379 2
  # 2个sentinel同意才故障转移

集群(Cluster):
  redis-cli --cluster create node1:6379 node2:6379 node3:6379
  # 16384个slot分片

EOF

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Lab 11: MySQL 数据库${NC}"
echo -e "${CYAN}========================================${NC}"
cat << 'EOF'

安装: apt install mysql-server  或  docker run -d -e MYSQL_ROOT_PASSWORD=123456 mysql:8

基本操作:
  mysql -u root -p                           连接
  mysql -h 192.168.1.100 -u root -p          远程连接

  # 库操作
  SHOW DATABASES;                            列出数据库
  CREATE DATABASE mydb CHARACTER SET utf8mb4;
  USE mydb;                                  切换数据库
  DROP DATABASE mydb;                        删除数据库

  # 表操作
  SHOW TABLES;                               列出表
  CREATE TABLE users (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(50), age INT);
  DESCRIBE users;                            查看表结构
  ALTER TABLE users ADD email VARCHAR(100);  加字段

  # CRUD
  INSERT INTO users (name, age) VALUES ('kainan', 22);
  SELECT * FROM users WHERE age > 20;
  UPDATE users SET age = 23 WHERE name = 'kainan';
  DELETE FROM users WHERE id = 1;

运维命令:
  SHOW PROCESSLIST;              查看当前连接
  SHOW STATUS LIKE 'Threads%';   连接数
  SHOW VARIABLES LIKE 'max_connections';  最大连接数
  SET GLOBAL max_connections = 500;       修改(临时)
  SHOW ENGINE INNODB STATUS;     InnoDB状态
  EXPLAIN SELECT ...;            执行计划(优化慢查询)

备份恢复:
  mysqldump -u root -p mydb > backup.sql     备份
  mysqldump -u root -p --all-databases > all.sql  全量备份
  mysql -u root -p mydb < backup.sql         恢复
  mysqldump -u root -p mydb users > users.sql # 单表备份

主从复制:
  # 主库 my.cnf
  server-id=1
  log-bin=mysql-bin
  binlog-do-db=mydb

  # 从库 my.cnf
  server-id=2
  relay-log=relay-bin

  # 从库执行
  CHANGE MASTER TO MASTER_HOST='192.168.1.100', MASTER_USER='repl', MASTER_PASSWORD='xxx';
  START SLAVE;
  SHOW SLAVE STATUS\G

EOF

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Lab 12: Ansible 批量管理${NC}"
echo -e "${CYAN}========================================${NC}"
cat << 'EOF'

安装: pip install ansible  或  apt install ansible

核心概念:
  控制节点   你操作的机器
  被管节点   被管理的服务器(只需SSH+Python)
  Inventory  主机清单(哪些机器)
  Playbook   YAML剧本(要做什么)
  Module     模块(具体操作单元)
  Role       角色(可复用的任务集合)

Inventory 文件 /etc/ansible/hosts:
  [webservers]
  web1 ansible_host=192.168.1.101 ansible_user=root
  web2 ansible_host=192.168.1.102 ansible_user=root

  [dbservers]
  db1 ansible_host=192.168.1.201

  [all:vars]
  ansible_python_interpreter=/usr/bin/python3

Ad-hoc 命令(一次性):
  ansible all -m ping                           测试连通性
  ansible webservers -m shell -a "uptime"       执行命令
  ansible webservers -m copy -a "src=./app.conf dest=/etc/"  拷贝文件
  ansible webservers -m service -a "name=nginx state=restarted"  重启服务
  ansible webservers -m yum -a "name=nginx state=present"  安装软件
  ansible webservers -m file -a "path=/opt/data state=directory mode=0755"

Playbook 示例:
  # deploy.yml
  ---
  - hosts: webservers
    become: yes
    vars:
      app_version: "1.2.3"
    tasks:
      - name: 安装nginx
        apt: name=nginx state=present

      - name: 拷贝配置
        template: src=nginx.conf.j2 dest=/etc/nginx/nginx.conf
        notify: 重启nginx

      - name: 启动nginx
        service: name=nginx state=started enabled=yes

    handlers:
      - name: 重启nginx
        service: name=nginx state=restarted

执行: ansible-playbook deploy.yml
检查: ansible-playbook deploy.yml --check   # dry run
调试: ansible-playbook deploy.yml -vvv      # 详细输出

Role 结构:
  roles/
  └── nginx/
      ├── tasks/main.yml
      ├── handlers/main.yml
      ├── templates/nginx.conf.j2
      ├── files/
      ├── vars/main.yml
      └── defaults/main.yml

EOF

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Lab 13: Prometheus + Grafana 监控${NC}"
echo -e "${CYAN}========================================${NC}"
cat << 'EOF'

架构:
  应用 → exporter暴露指标 → prometheus拉取 → grafana展示
                              ↓
                          alertmanager → 钉钉/企微/邮件

Docker一键部署:
  docker run -d --name prometheus -p 9090:9090 prom/prometheus
  docker run -d --name grafana -p 3000:3000 grafana/grafana
  docker run -d --name node-exporter -p 9100:9100 prom/node-exporter

Prometheus 配置 prometheus.yml:
  global:
    scrape_interval: 15s

  scrape_configs:
    - job_name: 'node'
      static_configs:
        - targets: ['192.168.1.101:9100', '192.168.1.102:9100']

    - job_name: 'nginx'
      static_configs:
        - targets: ['192.168.1.101:9113']

常用PromQL:
  up                                    目标是否存活
  rate(http_requests_total[5m])         5分钟请求速率
  node_memory_MemAvailable_bytes        可用内存
  100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)  CPU使用率
  node_filesystem_avail_bytes           可用磁盘

常用Exporter:
  node_exporter     系统指标(CPU/内存/磁盘/网络)
  mysqld_exporter   MySQL指标
  redis_exporter    Redis指标
  nginx_exporter    Nginx指标
  blackbox_exporter 黑盒探测(HTTP/TCP/ICMP)

Grafana:
  默认账号: admin / admin
  常用Dashboard ID:
    1860  Node Exporter Full
    763   Redis Dashboard
    7362  MySQL Overview

告警规则 alert_rules.yml:
  groups:
    - name: host
      rules:
        - alert: HighCPU
          expr: 100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
          for: 5m
          labels: { severity: warning }
          annotations:
            summary: "CPU使用率超过80%"

EOF

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Lab 14: ELK 日志系统${NC}"
echo -e "${CYAN}========================================${NC}"
cat << 'EOF'

架构:
  应用日志 → Filebeat采集 → Logstash处理 → Elasticsearch存储 → Kibana查询
  (简化版: Filebeat → Elasticsearch → Kibana = EFK)

Docker部署ELK:
  # Elasticsearch
  docker run -d --name es -p 9200:9200 -e "discovery.type=single-node" elasticsearch:8.x

  # Kibana
  docker run -d --name kibana -p 5601:5601 -e "ELASTICSEARCH_HOSTS=http://es:9200" kibana:8.x

  # Filebeat(每台被管机器装)
  docker run -d --name filebeat -v /var/log:/var/log filebeat:8.x

Filebeat 配置 filebeat.yml:
  filebeat.inputs:
    - type: log
      paths:
        - /var/log/nginx/access.log
        - /var/log/nginx/error.log

  output.elasticsearch:
    hosts: ["192.168.1.100:9200"]
    index: "nginx-%{+yyyy.MM.dd}"

  # 或输出到Logstash
  output.logstash:
    hosts: ["192.168.1.100:5044"]

Logstash 配置 logstash.conf:
  input {
    beats { port => 5044 }
  }
  filter {
    grok {
      match => { "message" => "%{COMBINEDAPACHELOG}" }
    }
    date {
      match => ["timestamp", "dd/MMM/yyyy:HH:mm:ss Z"]
    }
  }
  output {
    elasticsearch {
      hosts => ["localhost:9200"]
      index => "web-%{+YYYY.MM.dd}"
    }
  }

Elasticsearch 常用API:
  curl localhost:9200/_cat/health           集群健康
  curl localhost:9200/_cat/indices          列出索引
  curl localhost:9200/_cat/nodes            列出节点
  curl localhost:9200/nginx-*/_search?q=500 搜索

EOF

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Lab 15: Jenkins + Harbor CI/CD${NC}"
echo -e "${CYAN}========================================${NC}"
cat << 'EOF'

Jenkins (CI/CD流水线):
  docker run -d --name jenkins -p 8080:8080 -p 50000:50000 \
    -v jenkins_home:/var/jenkins_home jenkins/jenkins:lts

  初始密码: docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword

  Pipeline 示例(Jenkinsfile):
  pipeline {
      agent any
      stages {
          stage('拉代码') {
              steps { git 'https://github.com/RM3836/app.git' }
          }
          stage('构建') {
              steps { sh 'docker build -t myapp:${BUILD_NUMBER} .' }
          }
          stage('测试') {
              steps { sh 'docker run --rm myapp:${BUILD_NUMBER} pytest' }
          }
          stage('推送镜像') {
              steps {
                  sh 'docker tag myapp:${BUILD_NUMBER} harbor.local/myproject/myapp:${BUILD_NUMBER}'
                  sh 'docker push harbor.local/myproject/myapp:${BUILD_NUMBER}'
              }
          }
          stage('部署') {
              steps { sh 'kubectl apply -f k8s/deployment.yaml' }
          }
      }
  }

Harbor (企业级镜像仓库):
  # 安装(需要docker-compose)
  wget https://github.com/goharbor/harbor/releases/latest/download/harbor-offline-installer.tgz
  tar xzf harbor-offline-installer.tgz && cd harbor
  cp harbor.yml.tmpl harbor.yml  # 编辑hostname/https/password
  ./install.sh --with-trivy       # --with-trivy启用漏洞扫描

  使用:
  docker login harbor.local
  docker tag myapp:v1 harbor.local/myproject/myapp:v1
  docker push harbor.local/myproject/myapp:v1

  功能: 镜像仓库 + 漏洞扫描 + 镜像签名 + 复制策略 + RBAC权限

Nexus (制品仓库):
  docker run -d --name nexus -p 8081:8081 sonatype/nexus3
  # 支持: Maven/npm/Docker/PyPI/npm私有仓库

EOF

echo -e "${GREEN}[完成] Lab 10-15 中级工具合集 实战结束${NC}"
