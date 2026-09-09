# DevOps 全栈实战教程（20 个运维 Lab）

> 面向运维 / 网络安全 / DevOps 岗位的**可运行**实战脚本合集。每个 Lab 都是一个独立的 Bash 脚本，`bash xxx.sh` 直接跑，边跑边看真实输出，末尾附速查表与面试常问。

---

## 目录

- [项目简介](#项目简介)
- [环境要求](#环境要求)
- [快速开始](#快速开始)
- [Lab 清单与进度](#lab-清单与进度)
- [学习路线建议](#学习路线建议)
- [脚本使用约定](#脚本使用约定)
- [常见问题 FAQ](#常见问题-faq)
- [贡献与规范](#贡献与规范)

---

## 项目简介

本仓库将运维核心技能拆分为 **20 个 Lab**，分为三个阶段：

| 阶段 | 定位 | 内容 |
|------|------|------|
| 阶段一：基础必会 | 直接可跑，有真实输出 | Git、SCP/rsync、tcpdump、iptables、OpenSSL、Shell 三剑客、systemd |
| 阶段二：运维核心 | 需先装对应软件 | Docker、Nginx、Redis、MySQL、Ansible、Prometheus、ELK、CI/CD |
| 阶段三：高级编排 | 需要集群环境 | K8s、Helm、LVS/HAProxy、服务发现、Supervisor |

**核心原则**：先跑起来看结果，再理解原理。每个脚本都遵循「演示命令 → 真实执行 → 输出 → 速查表」的结构。

---

## 环境要求

| 依赖 | 版本 | 说明 |
|------|------|------|
| Linux / WSL2 | 任意 | 推荐 Ubuntu 20.04+ |
| Bash | 4.0+ | 脚本解释器 |
| Git | 2.x | 仅 Lab 01 需要 |
| Docker | 20.10+ | Lab 08、13-19 需要 |

> 部分脚本需要 root 权限（tcpdump、iptables），已单独标注。

---

## 快速开始

```bash
# 1. 克隆仓库
git clone https://github.com/RM3836/devops-labs.git
cd devops-labs

# 2. 查看总目录
bash index.sh

# 3. 按顺序运行单个 Lab
bash 01-git-basics.sh
bash 02-scp-rsync.sh
```

> 提示：阶段一的脚本（01~07）可以直接在 WSL 上跑，有实际输出；阶段二/三的脚本里已包含安装命令，按提示先装软件再运行。

---

## Lab 清单与进度

| # | Lab | 主题 | 脚本文件 | 需要 root | 状态 |
|---|-----|------|----------|:---:|:---:|
| 01 | Git | 版本控制从零到实战 | `01-git-basics.sh` | 否 | ✅ |
| 02 | SCP & rsync | 文件传输 / 增量同步 / 定时备份 | `02-scp-rsync.sh` | 否 | ✅ |
| 03 | tcpdump | 网络抓包 / 过滤表达式 | `03-tcpdump.sh` | 是 | ✅ |
| 04 | iptables | 四表五链 / 防火墙规则 | `04-iptables.sh` | 是 | ✅ |
| 05 | OpenSSL | 证书 / 加解密 / CSR | `05-openssl.sh` | 否 | ✅ |
| 06 | Shell 三剑客 | grep + awk + sed | `06-shell-awk-sed-grep.sh` | 否 | ✅ |
| 07 | systemd | 服务管理 / 自定义服务 | `07-systemd.sh` | 否 | ✅ |
| 08 | Docker | 容器 / Dockerfile / compose | `08-docker.sh` | 否 | ✅ |
| 09 | Nginx | 反向代理 / 负载均衡 / HTTPS | `09-nginx.sh` | 否 | ✅ |
| 10 | Redis | 缓存 / 持久化 / 高可用 | `10-mid-tools.sh` | 否 | ✅ |
| 11 | MySQL | 数据库 / 备份 / 主从 | `10-mid-tools.sh` | 否 | ✅ |
| 12 | Ansible | 批量管理 / Playbook / Role | `10-mid-tools.sh` | 否 | ✅ |
| 13 | Prometheus | 监控 / PromQL / 告警 | `10-mid-tools.sh` | 否 | ✅ |
| 14 | ELK | 日志采集 / 检索 | `10-mid-tools.sh` | 否 | ✅ |
| 15 | Jenkins+Harbor | CI/CD / 镜像仓库 | `10-mid-tools.sh` | 否 | ✅ |
| 16 | Kubernetes | 集群 / Pod / Deployment | `16-advanced.sh` | 否 | ✅ |
| 17 | Helm | K8s 包管理 | `16-advanced.sh` | 否 | ✅ |
| 18 | LVS+HAProxy | 四/七层负载均衡 | `16-advanced.sh` | 否 | ✅ |
| 19 | Consul+Nacos | 服务发现 / 配置中心 | `16-advanced.sh` | 否 | ✅ |
| 20 | Supervisor | 进程管理 | `16-advanced.sh` | 否 | ✅ |

> 说明：Lab 10-15 合并为 `10-mid-tools.sh`，Lab 16-20 合并为 `16-advanced.sh`，与 `index.sh` 中展示的 20 个 Lab 一一对应。

---

## 学习路线建议

### 求职向（网络安全测试 / DevOps 实习生）

1. **必做**（01~07）：Git → Shell 三剑客 → systemd → tcpdump → iptables → OpenSSL。这些是面试和日常工作的高频基础。
2. **重点**（08~09）：Docker、Nginx 是简历上最常被问到的两项，务必跑通并理解。
3. **进阶**（12~15）：Ansible、监控、CI/CD 是 DevOps 岗位的核心加分项。

### 学习节奏

```
第 1 周：01~04（版本控制 + 文件传输 + 抓包 + 防火墙）
第 2 周：05~07（证书 + 三剑客 + 服务管理）
第 3 周：08~09（容器 + Web 服务器）
第 4 周：10~15（缓存/数据库/自动化/监控/日志/CI-CD）
第 5 周起：16~20（K8s 生态与高级编排）
```

---

## 脚本使用约定

- 所有脚本均以 `#!/bin/bash` 开头，用 `set -e` 保证出错即停。
- 演示脚本会在 `/tmp/` 下创建临时目录（如 `/tmp/git-lab`、`/tmp/transfer-lab`），运行前会自动清理旧环境。
- 颜色输出使用 ANSI 转义码：`CYAN`（标题）、`YELLOW`（场景）、`GREEN`（完成）。
- 每个脚本末尾的「速查表」和「面试常问」是复习重点，建议整理成自己的笔记。

---

## 常见问题 FAQ

**Q1：WSL 下运行 tcpdump / iptables 报错？**
需要 root 权限，`sudo bash 03-tcpdump.sh`。WSL2 默认支持，若报 `Operation not permitted` 说明内核未加载对应模块。

**Q2：Docker 命令提示找不到？**
Docker Desktop 的 CLI 默认不进 PATH。参考 `~/.docker/daemon.json` 配置镜像加速后重启 Docker Desktop。

**Q3：阶段二脚本为什么没有真实输出？**
Redis / MySQL / Ansible 等需要先安装对应软件，脚本里已给出安装命令（`apt install` 或 `docker run`），装好后再跑。

**Q4：`set -e` 导致脚本中途退出？**
某些演示命令（如 `tcpdump` 抓包）在无包时会返回非零退出码，脚本已用 `|| true` 兜底。若仍中途退出，可临时注释 `set -e` 排查。

---

## 贡献与规范

- 保持脚本风格统一：头部注释块 + 阶段分隔线 + 速查表结尾。
- 新增 Lab 遵循现有编号规则，并同步更新 `index.sh` 和本 README。
- 提交信息规范：`Lab XX: 主题描述`。

---

## 许可

MIT License

---

> 维护者：[RM3836](https://github.com/RM3836)
