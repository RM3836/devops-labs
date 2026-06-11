#!/bin/bash
# ============================================
# DevOps实战 Lab 03: tcpdump 抓包分析
# 运行: bash 03-tcpdump.sh (需要root)
# ============================================

set -e
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Lab 03: tcpdump 网络抓包${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# 安装tcpdump
if ! command -v tcpdump &>/dev/null; then
    echo "安装 tcpdump..."
    apt-get update -qq && apt-get install -y -qq tcpdump
fi

# ---------- 基础命令 ----------
echo -e "${YELLOW}[1] 基础抓包命令${NC}"
echo "----------------------------------------"
cat << 'EOF'
# 基本语法
tcpdump [选项] [过滤条件]

# 常用选项
tcpdump -i eth0           # 指定网卡
tcpdump -n                # 不解析域名(快)
tcpdump -nn               # 不解析域名+端口(更快)
tcpdump -c 10             # 只抓10个包
tcpdump -w file.pcap      # 保存到文件(可用wireshark打开)
tcpdump -r file.pcap      # 读取pcap文件
tcpdump -v/-vv/-vvv       # 详细程度递增
tcpdump -A                # 以ASCII显示内容
tcpdump -X                # 以十六进制+ASCII显示
tcpdump -s 0              # 抓完整包(不截断)
EOF
echo ""

# ---------- 过滤表达式（核心技能）----------
echo -e "${YELLOW}[2] 过滤表达式（核心技能）${NC}"
echo "----------------------------------------"
cat << 'EOF'
# 按主机
tcpdump host 192.168.1.100         # 抓某主机的包
tcpdump src host 192.168.1.100     # 只抓源地址
tcpdump dst host 192.168.1.100     # 只抓目标地址

# 按端口
tcpdump port 80                    # 抓HTTP流量
tcpdump port 443                   # 抓HTTPS流量
tcpdump port 22                    # 抓SSH流量
tcpdump src port 3306              # 抓MySQL发出的包

# 按协议
tcpdump tcp                        # 只抓TCP
tcpdump udp                        # 只抓UDP
tcpdump icmp                       # 只抓ICMP(ping)

# 组合条件
tcpdump host 10.0.0.1 and port 80           # AND
tcpdump port 80 or port 443                 # OR
tcpdump not port 22                          # 排除SSH
tcpdump "tcp[tcpflags] & (tcp-syn) != 0"    # 只抓SYN包

# HTTP专项
tcpdump -A -s 0 'tcp port 80' | grep "GET\|POST\|Host:"  # 抓HTTP请求
EOF
echo ""

# ---------- 实战: 抓取DNS查询 ----------
echo -e "${YELLOW}[3] 实战: 抓取DNS查询${NC}"
echo "----------------------------------------"

echo "后台发起DNS查询..."
(nslookup baidu.com > /dev/null 2>&1) &
sleep 1

echo '$ tcpdump -i any -nn -c 5 port 53'
timeout 5 tcpdump -i any -nn -c 5 port 53 2>/dev/null || echo "(抓包完成或超时)"
echo ""

# ---------- 实战: 分析TCP握手 ----------
echo -e "${YELLOW}[4] 实战: 保存抓包到文件${NC}"
echo "----------------------------------------"

echo '$ tcpdump -i any -nn -c 20 -w /tmp/dns-capture.pcap port 53'
(nslookup qq.com > /dev/null 2>&1) &
timeout 5 tcpdump -i any -nn -c 20 -w /tmp/dns-capture.pcap port 53 2>/dev/null || true

echo ""
echo '$ tcpdump -nn -r /tmp/dns-capture.pcap | head -5'
tcpdump -nn -r /tmp/dns-capture.pcap 2>/dev/null | head -5
echo ""

# ---------- 面试常问 ----------
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  tcpdump 面试常问${NC}"
echo -e "${CYAN}========================================${NC}"
cat << 'EOF'
Q: 如何抓取HTTP请求内容?
A: tcpdump -A -s 0 'tcp port 80 and (((ip[2:2] - ((ip[0]&0xf)<<2)) - ((tcp[12]&0xf0)>>2)) != 0)'

Q: 如何抓TCP三次握手?
A: tcpdump -nn -c 3 'tcp[tcpflags] == tcp-syn' or 'tcp[tcpflags] == tcp-syn-ack'

Q: 如何统计某端口连接数?
A: tcpdump -nn port 80 2>/dev/null | wc -l

Q: tcpdump和Wireshark区别?
A: tcpdump是命令行抓包(服务器上用), Wireshark是GUI分析(本地分析pcap文件)
   工作流: tcpdump -w xxx.pcap → 下载 → Wireshark打开分析

EOF

echo -e "${GREEN}[完成] Lab 03 tcpdump 实战结束${NC}"
