#!/bin/bash
# ============================================
# DevOps实战教程 - 总目录
# 运行: bash index.sh
# ============================================

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║     DevOps 全栈实战教程 (20个Lab)        ║${NC}"
echo -e "${CYAN}╠══════════════════════════════════════════╣${NC}"
echo -e "${CYAN}║                                          ║${NC}"
echo -e "${CYAN}║  阶段一: 基础必会                        ║${NC}"
echo -e "${GREEN}║    01  Git 版本控制                       ║${NC}"
echo -e "${GREEN}║    02  SCP & rsync 文件传输               ║${NC}"
echo -e "${GREEN}║    03  tcpdump 网络抓包                   ║${NC}"
echo -e "${GREEN}║    04  iptables 防火墙                    ║${NC}"
echo -e "${GREEN}║    05  OpenSSL 证书加密                   ║${NC}"
echo -e "${GREEN}║    06  Shell grep+awk+sed 三剑客          ║${NC}"
echo -e "${GREEN}║    07  systemd 服务管理                   ║${NC}"
echo -e "${CYAN}║                                          ║${NC}"
echo -e "${CYAN}║  阶段二: 运维核心                        ║${NC}"
echo -e "${YELLOW}║    08  Docker 容器                        ║${NC}"
echo -e "${YELLOW}║    09  Nginx 反向代理+负载均衡            ║${NC}"
echo -e "${YELLOW}║    10  Redis 缓存                         ║${NC}"
echo -e "${YELLOW}║    11  MySQL 数据库                       ║${NC}"
echo -e "${YELLOW}║    12  Ansible 批量管理                   ║${NC}"
echo -e "${YELLOW}║    13  Prometheus + Grafana 监控          ║${NC}"
echo -e "${YELLOW}║    14  ELK 日志系统                       ║${NC}"
echo -e "${YELLOW}║    15  Jenkins + Harbor CI/CD             ║${NC}"
echo -e "${CYAN}║                                          ║${NC}"
echo -e "${CYAN}║  阶段三: 高级编排                        ║${NC}"
echo -e "${YELLOW}║    16  Kubernetes (K8s)                   ║${NC}"
echo -e "${YELLOW}║    17  Helm 包管理                        ║${NC}"
echo -e "${YELLOW}║    18  LVS + HAProxy 负载均衡             ║${NC}"
echo -e "${YELLOW}║    19  Consul + Nacos 服务发现            ║${NC}"
echo -e "${YELLOW}║    20  Supervisor 进程管理                ║${NC}"
echo -e "${CYAN}║                                          ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
echo ""
echo "运行方式:"
echo "  cd ~/devops-labs"
echo "  bash 01-git-basics.sh"
echo "  bash 02-scp-rsync.sh"
echo "  ..."
echo ""
echo "可直接运行的脚本(含实操输出):"
ls -1 ~/devops-labs/*.sh | while read f; do
    printf "  %-35s %s\n" "$(basename $f)" "$(head -5 $f | grep '# DevOps' | sed 's/# DevOps实战 //')"
done
echo ""
echo "Tips:"
echo "  - 阶段一的脚本可以直接在WSL上跑,有实际输出"
echo "  - 阶段二/三需要先装对应软件(脚本里有安装命令)"
echo "  - 每个脚本末尾都有速查表,方便复习"
