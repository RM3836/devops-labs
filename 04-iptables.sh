#!/bin/bash
# ============================================
# DevOps实战 Lab 04: iptables 防火墙
# 运行: bash 04-iptables.sh (需要root)
# ============================================

CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Lab 04: iptables 防火墙${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# ---------- 核心概念 ----------
echo -e "${YELLOW}[1] 四表五链（面试必问）${NC}"
echo "----------------------------------------"
cat << 'EOF'
四个表(优先级从高到低):
  raw       → 连接跟踪(conntrack)之前生效
  mangle    → 修改IP头(TTL/TOS等)
  nat       → 网络地址转换(SNAT/DNAT/MASQUERADE)
  filter    → 过滤(默认表) ← 最常用

五个链(数据包经过的关卡):
  PREROUTING   → 路由前(刚进来的包)
  INPUT        → 目标是本机的包
  FORWARD      → 经过本机转发的包
  OUTPUT       → 本机发出的包
  POSTROUTING  → 路由后(即将出去的包)

表和链的关系:
                raw    mangle   nat      filter
PREROUTING       ✓       ✓       ✓
INPUT                    ✓               ✓
FORWARD                  ✓               ✓
OUTPUT                   ✓       ✓       ✓
POSTROUTING              ✓       ✓

数据包流向:
  入站:   网卡 → PREROUTING → 路由判断 → INPUT → 应用
  出站:   应用 → OUTPUT → 路由判断 → POSTROUTING → 网卡
  转发:   网卡 → PREROUTING → FORWARD → POSTROUTING → 网卡
EOF
echo ""

# ---------- 基本操作 ----------
echo -e "${YELLOW}[2] 基本操作${NC}"
echo "----------------------------------------"

echo '$ iptables -L -n -v  # 查看当前规则'
iptables -L -n -v 2>/dev/null || echo "(需要root权限)"
echo ""

echo '$ iptables -L -n -v --line-numbers  # 带行号查看'
iptables -L -n -v --line-numbers 2>/dev/null || echo "(需要root权限)"
echo ""

cat << 'EOF'
# 常用参数
iptables -A INPUT ...     # 追加规则(末尾)
iptables -I INPUT 1 ...   # 插入规则(指定位置)
iptables -D INPUT 3       # 删除第3条规则
iptables -F               # 清空所有规则
iptables -P INPUT DROP    # 设置默认策略

# 匹配条件
-p tcp/udp/icmp           # 协议
--dport 80                # 目标端口
--sport 1024:65535        # 源端口范围
-s 192.168.1.0/24         # 源地址
-d 10.0.0.1               # 目标地址
-i eth0                   # 入接口
-o eth0                   # 出接口
-m state --state ESTABLISHED,RELATED  # 已建立的连接
-m multiport --dports 80,443          # 多端口
-m iprange --src-range 192.168.1.1-192.168.1.100  # IP范围

# 动作
-j ACCEPT                 # 允许
-j DROP                   # 丢弃(不回复)
-j REJECT                 # 拒绝(回复ICMP不可达)
-j LOG --log-prefix "FW: "# 记录日志
-j SNAT --to-source 1.2.3.4    # 源地址转换
-j DNAT --to-destination 10.0.0.1:8080  # 目标地址转换
-j MASQUERADE             # 伪装(动态SNAT,适合拨号上网)
EOF
echo ""

# ---------- 实战场景 ----------
echo -e "${YELLOW}[3] 实战场景（直接可复用的规则）${NC}"
echo "----------------------------------------"
cat << 'EOF'
# 场景1: Web服务器防火墙
iptables -A INPUT -i lo -j ACCEPT                              # 允许回环
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT # 已建立连接放行
iptables -A INPUT -p tcp --dport 80 -j ACCEPT                  # HTTP
iptables -A INPUT -p tcp --dport 443 -j ACCEPT                 # HTTPS
iptables -A INPUT -p tcp --dport 22 -s 192.168.1.0/24 -j ACCEPT # SSH只允许内网
iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT   # 允许ping
iptables -P INPUT DROP                                          # 其他全部拒绝

# 场景2: 防暴力破解(限速)
iptables -A INPUT -p tcp --dport 22 -m recent --set --name SSH
iptables -A INPUT -p tcp --dport 22 -m recent --update --seconds 60 --hitcount 5 --name SSH -j DROP
# 60秒内超过5次SSH连接就丢弃

# 场景3: 端口转发(把8080转到内网80)
iptables -t nat -A PREROUTING -p tcp --dport 8080 -j DNAT --to-destination 192.168.1.100:80
iptables -t nat -A POSTROUTING -d 192.168.1.100 -j MASQUERADE

# 场景4: NAT上网(内网通过服务器上网)
echo 1 > /proc/sys/net/ipv4/ip_forward                        # 开启转发
iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -o eth0 -j MASQUERADE

# 场景5: 禁止某IP访问
iptables -A INPUT -s 10.0.0.100 -j DROP

# 场景6: 限速(防DDoS)
iptables -A INPUT -p tcp --dport 80 -m limit --limit 100/min --limit-burst 200 -j ACCEPT
EOF
echo ""

# ---------- 保存和恢复 ----------
echo -e "${YELLOW}[4] 规则持久化${NC}"
echo "----------------------------------------"
cat << 'EOF'
# iptables规则重启后丢失!必须持久化:

# CentOS/RHEL:
service iptables save         # 保存到 /etc/sysconfig/iptables
iptables-save > /etc/iptables.rules   # 手动导出
iptables-restore < /etc/iptables.rules # 恢复

# Ubuntu:
iptables-save > /etc/iptables/rules.v4
# 开机自动加载:
# 在 /etc/network/interfaces 的 iface eth0 inet dhcp 后加:
#   pre-up iptables-restore < /etc/iptables/rules.v4
EOF
echo ""

# ---------- iptables vs firewall-cmd ----------
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  iptables vs firewall-cmd${NC}"
echo -e "${CYAN}========================================${NC}"
cat << 'EOF'

特性              iptables           firewall-cmd
──────────────────────────────────────────────────
定位              底层工具           iptables的前端
配置方式          命令行逐条         zone概念+富规则
复杂度            高(要理解链)       低(更友好)
适用场景          精细控制/脚本      日常管理
持久化            手动               自动
CentOS默认        6及以前            7+

firewall-cmd 常用命令(对比):
  firewall-cmd --state                    # 查看状态
  firewall-cmd --list-all                 # 查看所有规则
  firewall-cmd --add-port=80/tcp --permanent   # 开端口
  firewall-cmd --add-service=http --permanent  # 开服务
  firewall-cmd --reload                   # 重载配置

面试答法: firewall-cmd是iptables的封装,底层还是调iptables,
          但提供了zone/service等更友好的概念,适合日常运维。
EOF

echo -e "${GREEN}[完成] Lab 04 iptables 实战结束${NC}"
