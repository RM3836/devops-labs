#!/bin/bash
# ============================================
# DevOps实战 Lab 06: Shell 脚本（运维三剑客）
# 运行: bash 06-shell-awk-sed-grep.sh
# ============================================

CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Lab 06: Shell 运维三剑客${NC}"
echo -e "${CYAN}  grep + awk + sed${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# 准备测试数据
cat > /tmp/test.log << 'EOF'
2025-06-01 10:00:01 INFO  [nginx] 192.168.1.10 GET /index.html 200 0.023
2025-06-01 10:00:02 ERROR [nginx] 192.168.1.11 POST /api/login 500 0.156
2025-06-01 10:00:03 INFO  [nginx] 192.168.1.12 GET /api/users 200 0.045
2025-06-01 10:00:04 WARN  [mysql]  192.168.1.20 Slow query: SELECT * FROM orders 2.340
2025-06-01 10:00:05 ERROR [nginx] 192.168.1.13 GET /api/data 502 0.001
2025-06-01 10:00:06 INFO  [nginx] 192.168.1.10 GET /static/app.js 200 0.008
2025-06-01 10:00:07 ERROR [redis]  192.168.1.30 Connection refused 0.000
2025-06-01 10:00:08 INFO  [nginx] 192.168.1.14 GET /health 200 0.001
2025-06-01 10:00:09 ERROR [nginx] 192.168.1.11 POST /api/login 401 0.034
2025-06-01 10:00:10 INFO  [nginx] 192.168.1.15 GET /index.html 200 0.019
EOF

echo "测试日志文件: /tmp/test.log"
echo "----------------------------------------"
cat /tmp/test.log
echo ""

# ---------- grep ----------
echo -e "${YELLOW}[grep] 文本搜索（过滤之王）${NC}"
echo "----------------------------------------"

echo '$ grep "ERROR" /tmp/test.log'
grep "ERROR" /tmp/test.log
echo ""

echo '$ grep -c "ERROR" /tmp/test.log  # 统计行数'
grep -c "ERROR" /tmp/test.log
echo ""

echo '$ grep -v "INFO" /tmp/test.log  # 排除INFO'
grep -v "INFO" /tmp/test.log
echo ""

echo '$ grep -E "ERROR|WARN" /tmp/test.log  # 正则: ERROR或WARN'
grep -E "ERROR|WARN" /tmp/test.log
echo ""

echo '$ grep -o "192\.168\.[0-9.]*" /tmp/test.log | sort | uniq -c | sort -rn  # 统计IP出现次数'
grep -o "192\.168\.[0-9.]*" /tmp/test.log | sort | uniq -c | sort -rn
echo ""

# ---------- awk ----------
echo -e "${YELLOW}[awk] 列处理（按字段切割）${NC}"
echo "----------------------------------------"

echo '$ awk \'{print $1, $2, $5}\' /tmp/test.log  # 打印第1,2,5列'
awk '{print $1, $2, $5}' /tmp/test.log
echo ""

echo '$ awk \'/ERROR/ {print $4, $6, $7}\' /tmp/test.log  # 筛选ERROR并打印关键列'
awk '/ERROR/ {print $4, $6, $7}' /tmp/test.log
echo ""

echo '$ awk \'{sum+=$NF} END {print "平均响应时间:", sum/NR"s"}\' /tmp/test.log'
awk '{sum+=$NF} END {print "平均响应时间:", sum/NR"s"}' /tmp/test.log
echo ""

echo '$ awk -F"[ :]" \'{print $3}\' /tmp/test.log | sort | uniq -c  # 按小时统计'
awk -F"[ :]" '{print $3}' /tmp/test.log | sort | uniq -c
echo ""

echo '$ awk \'$NF > 0.1 {print "慢请求:", $0}\' /tmp/test.log  # 响应>0.1s的请求'
awk '$NF > 0.1 {print "慢请求:", $0}' /tmp/test.log
echo ""

# ---------- sed ----------
echo -e "${YELLOW}[sed] 流编辑器（替换/删除/插入）${NC}"
echo "----------------------------------------"

echo '$ sed -n \'1,3p\' /tmp/test.log  # 打印前3行'
sed -n '1,3p' /tmp/test.log
echo ""

echo '$ sed -i \'s/ERROR/CRITICAL/g\' /tmp/test.log.bak  # 替换(常用-i原地修改)'
cp /tmp/test.log /tmp/test.log.bak
sed -i 's/ERROR/CRITICAL/g' /tmp/test.log.bak
head -3 /tmp/test.log.bak
echo ""

echo '$ sed \'/INFO/d\' /tmp/test.log  # 删除包含INFO的行'
sed '/INFO/d' /tmp/test.log
echo ""

echo '$ sed -n \'/ERROR/p\' /tmp/test.log  # 只打印ERROR行(类似grep)'
sed -n '/ERROR/p' /tmp/test.log
echo ""

# ---------- 组合技（管道） ----------
echo -e "${YELLOW}[组合技] 管道串联（运维日常）${NC}"
echo "----------------------------------------"

echo "统计每个服务的ERROR数:"
echo '$ grep ERROR /tmp/test.log | awk \'{print $4}\' | sort | uniq -c | sort -rn'
grep ERROR /tmp/test.log | awk '{print $4}' | sort | uniq -c | sort -rn
echo ""

echo "找出访问最频繁的IP:"
echo '$ awk \'{print $6}\' /tmp/test.log | sort | uniq -c | sort -rn | head -3'
awk '{print $6}' /tmp/test.log | sort | uniq -c | sort -rn | head -3
echo ""

echo "提取状态码分布:"
echo '$ awk \'{print $(NF-1)}\' /tmp/test.log | sort | uniq -c | sort -rn'
awk '{print $(NF-1)}' /tmp/test.log | sort | uniq -c | sort -rn
echo ""

# ---------- 速查表 ----------
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  运维三剑客速查表${NC}"
echo -e "${CYAN}========================================${NC}"
cat << 'EOF'

grep  "搜什么"  文件         # 搜索
grep -i          不区分大小写
grep -r          递归搜索目录
grep -l          只显示文件名
grep -c          统计匹配行数
grep -n          显示行号
grep -A3         匹配行+后3行
grep -B3         匹配行+前3行

awk  '{print $1}' 文件      # 按列处理
awk -F":"                     # 指定分隔符
awk '/pattern/ {action}'     # 条件+动作
awk '{sum+=$1} END{print sum}' # 求和
awk 'NR==5'                   # 第5行

sed  's/old/new/g' 文件     # 替换
sed -i                        # 原地修改
sed -n '5,10p'               # 打印5-10行
sed '/pattern/d'              # 删除匹配行
sed -i '3a\新行内容'          # 第3行后插入

组合:
  cat file | grep X | awk '{print $2}' | sort | uniq -c  # 万能统计
  tail -f log | grep --line-buffered ERROR  # 实时监控错误
  find . -name "*.log" | xargs grep "OOM"  # 批量搜索

EOF

echo -e "${GREEN}[完成] Lab 06 Shell 运维三剑客 实战结束${NC}"
