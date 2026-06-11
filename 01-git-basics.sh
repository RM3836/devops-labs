#!/bin/bash
# ============================================
# DevOps实战 Lab 01: Git 从零到实战
# 运行: bash 01-git-basics.sh
# ============================================

set -e
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Lab 01: Git 基础到实战${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# ---------- 场景1: 初始化和基本操作 ----------
echo -e "${YELLOW}[场景1] 创建仓库 + 基本操作${NC}"
echo "----------------------------------------"

# 清理旧环境
rm -rf /tmp/git-lab && mkdir -p /tmp/git-lab && cd /tmp/git-lab

echo '$ git init my-project'
git init my-project
cd my-project
git branch -m main 2>/dev/null || true

echo ""
echo '$ echo "# 我的运维项目" > README.md'
echo "# 我的运维项目" > README.md

echo '$ git add README.md'
git add README.md

echo '$ git commit -m "初始化: 创建README"'
git commit -m "初始化: 创建README"

echo ""
echo '$ git log --oneline'
git log --oneline
echo ""

# ---------- 场景2: 分支操作（面试必问）----------
echo -e "${YELLOW}[场景2] 分支操作（面试高频）${NC}"
echo "----------------------------------------"

echo '$ git checkout -b feature/nginx-config'
git checkout -b feature/nginx-config

echo '$ echo "server { listen 80; }" > nginx.conf'
echo "server { listen 80; }" > nginx.conf
echo '$ git add . && git commit -m "添加nginx配置"'
git add . && git commit -m "添加nginx配置"

echo '$ git checkout main'
git checkout main

echo '$ git merge feature/nginx-config'
git merge feature/nginx-config

echo ""
echo '$ git branch -a'
git branch -a
echo '$ git log --oneline --graph --all'
git log --oneline --graph --all
echo ""

# ---------- 场景3: 版本回滚（运维救命技能）----------
echo -e "${YELLOW}[场景3] 版本回滚（运维救命技能）${NC}"
echo "----------------------------------------"

echo '$ echo "bad config" >> nginx.conf'
echo "bad config" >> nginx.conf
echo '$ git add . && git commit -m "错误的修改"'
git add . && git commit -m "错误的修改"

echo '$ git log --oneline'
git log --oneline

echo ""
echo '$ git revert HEAD --no-edit'
git revert HEAD --no-edit

echo '$ echo "--- 回滚后内容 ---"'
echo "--- 回滚后内容 ---"
echo '$ cat nginx.conf'
cat nginx.conf
echo ""

echo '$ git log --oneline'
git log --oneline
echo ""

# ---------- 场景4: .gitignore（项目必备）----------
echo -e "${YELLOW}[场景4] .gitignore 排除规则${NC}"
echo "----------------------------------------"

cat > .gitignore << 'EOF'
# 运维项目常见的忽略项
*.log
*.pyc
__pycache__/
.env
node_modules/
*.tmp
EOF

echo '$ cat .gitignore'
cat .gitignore
echo ""

echo '$ echo "secret_key=abc123" > .env'
echo "secret_key=abc123" > .env
echo '$ echo "2025-01-01 error happened" > app.log'
echo "2025-01-01 error happened" > app.log

echo '$ git status'
git status
echo "(注意 .env 和 app.log 被忽略了)"
echo ""

# ---------- 场景5: 远程仓库操作 ----------
echo -e "${YELLOW}[场景5] 远程仓库操作（实际工作流）${NC}"
echo "----------------------------------------"
echo "以下命令需要远程仓库,此处只展示命令:"
echo ""
echo "  git remote add origin git@github.com:RM3836/my-project.git"
echo "  git push -u origin main          # 推送并关联远程"
echo "  git pull origin main              # 拉取最新代码"
echo "  git clone git@github.com:RM3836/xxx.git  # 克隆仓库"
echo "  git fetch --all                   # 获取所有远程更新"
echo ""

# ---------- 常用命令速查 ----------
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Git 运维常用命令速查${NC}"
echo -e "${CYAN}========================================${NC}"
cat << 'EOF'

查看类:
  git status              查看工作区状态
  git log --oneline       简洁日志
  git diff                查看修改内容
  git blame 文件名        查看谁改了每一行

操作类:
  git add .               暂存所有修改
  git commit -m "说明"    提交
  git push                推送远程
  git pull                拉取并合并

分支类:
  git branch              查看分支
  git checkout -b 新分支  创建并切换分支
  git merge 目标分支      合并分支

回滚类:
  git revert HEAD         撤销最近一次提交(安全)
  git reset --hard HEAD~1 回退到上一个版本(危险!)
  git stash               暂存当前修改
  git stash pop           恢复暂存的修改

标签类:
  git tag v1.0            打标签(标记版本)
  git tag -a v1.0 -m "说明"  带说明的标签

EOF

echo -e "${GREEN}[完成] Lab 01 Git 实战结束${NC}"
echo "临时目录: /tmp/git-lab/my-project"
