#!/bin/bash
# ============================================
# DevOps实战 Lab 02: SCP + rsync 文件传输
# 运行: bash 02-scp-rsync.sh
# ============================================

set -e
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Lab 02: SCP & rsync 文件传输${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# 准备测试数据
rm -rf /tmp/transfer-lab && mkdir -p /tmp/transfer-lab/{src,dst}
cd /tmp/transfer-lab

# 生成测试文件
echo "这是配置文件" > src/config.txt
echo "密码=secret123" > src/secret.env
dd if=/dev/urandom of=src/bigfile.bin bs=1M count=10 2>/dev/null
mkdir -p src/logs && echo "2025-01-01 INFO started" > src/logs/app.log

echo "测试数据准备完成:"
echo '$ tree src/'
tree src/ 2>/dev/null || find src/ -type f
echo ""

# ---------- SCP 基础 ----------
echo -e "${YELLOW}[SCP] 安全拷贝（基于SSH）${NC}"
echo "----------------------------------------"
cat << 'EOF'
# 基本语法
scp 本地文件 用户名@远程IP:远程路径     # 上传
scp 用户名@远程IP:远程路径 本地路径     # 下载

# 常用参数
scp -r  目录/           # 递归拷贝目录
scp -P 2222             # 指定SSH端口
scp -i ~/.ssh/key.pem   # 指定密钥文件
scp -C                  # 启用压缩

# 实战示例（模拟本地到本地演示）
EOF

# 模拟SCP操作(本地到本地)
echo '$ scp src/config.txt dst/config.txt'
scp src/config.txt dst/config.txt 2>/dev/null || cp src/config.txt dst/config.txt
echo "拷贝完成: $(ls -lh dst/config.txt)"

echo ""
echo '$ scp -r src/logs dst/ (递归拷贝目录)'
scp -r src/logs dst/ 2>/dev/null || cp -r src/logs dst/
echo "目录拷贝完成:"
find dst/logs/ -type f
echo ""

# ---------- rsync 基础 ----------
echo -e "${YELLOW}[rsync] 增量同步（只传差异）${NC}"
echo "----------------------------------------"
cat << 'EOF'
# 基本语法
rsync [选项] 源路径 目标路径

# 常用参数
rsync -a          # 归档模式(保留权限/时间/符号链接)
rsync -v          # 显示详情
rsync -z          # 传输时压缩
rsync -P          # 显示进度+支持断点续传
rsync --delete    # 目标删除源没有的文件(镜像同步)
rsync -e "ssh -p 2222"  # 指定SSH端口

# 实战示例
EOF

# 演示rsync增量同步
echo '$ rsync -av src/ dst/'
rsync -av src/ dst/
echo ""

# 修改一个文件，演示增量
echo "修改后的配置" >> src/config.txt
echo ""
echo '$ echo "修改后的配置" >> src/config.txt'
echo '$ rsync -av src/ dst/  (只传输变更的文件)'
rsync -av src/ dst/
echo ""

# ---------- SCP vs rsync 对比 ----------
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  SCP vs rsync 对比${NC}"
echo -e "${CYAN}========================================${NC}"
cat << 'EOF'

特性              SCP                 rsync
──────────────────────────────────────────────
增量传输          不支持(全量)        支持(只传差异)
断点续传          不支持              支持(-P参数)
压缩传输          支持(-C)            支持(-z)
删除目标多余文件  不支持              支持(--delete)
保留权限          部分                完全(-a)
速度(大文件)      慢                  快(增量)
典型场景          单次小文件传输      大目录同步/备份

实际工作选择:
  - 传一个配置文件 → scp 够用
  - 同步整个项目目录 → rsync
  - 定时备份 → rsync + cron
  - 跨机器部署 → ansible(比rsync更强大)

EOF

# ---------- 实战: rsync + cron 定时备份脚本 ----------
echo -e "${YELLOW}[实战] rsync 定时备份脚本${NC}"
echo "----------------------------------------"

cat > /tmp/transfer-lab/backup.sh << 'SCRIPT'
#!/bin/bash
# 用途: 每天凌晨2点增量备份 /opt/data 到远程备份服务器
# crontab: 0 2 * * * /opt/scripts/backup.sh >> /var/log/backup.log 2>&1

SRC="/opt/data/"
DST="backup@192.168.1.100:/backup/$(hostname)/"
DATE=$(date +%Y-%m-%d)

echo "[$DATE] 开始备份..."
rsync -avzP --delete \
    -e "ssh -i /root/.ssh/backup_key" \
    "$SRC" "$DST"

if [ $? -eq 0 ]; then
    echo "[$DATE] 备份成功"
else
    echo "[$DATE] 备份失败!" >&2
    exit 1
fi
SCRIPT

echo '$ cat backup.sh'
cat /tmp/transfer-lab/backup.sh
echo ""

echo -e "${GREEN}[完成] Lab 02 SCP & rsync 实战结束${NC}"
echo "临时目录: /tmp/transfer-lab/"
