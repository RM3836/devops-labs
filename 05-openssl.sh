#!/bin/bash
# ============================================
# DevOps实战 Lab 05: OpenSSL 证书操作
# 运行: bash 05-openssl.sh
# ============================================

CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Lab 05: OpenSSL 证书与加密${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

rm -rf /tmp/ssl-lab && mkdir -p /tmp/ssl-lab && cd /tmp/ssl-lab

# ---------- 基础加密 ----------
echo -e "${YELLOW}[1] 基础加解密${NC}"
echo "----------------------------------------"

echo '$ echo "Hello DevOps" | openssl enc -aes-256-cbc -base64 -pass pass:mypassword'
ENCRYPTED=$(echo "Hello DevOps" | openssl enc -aes-256-cbc -base64 -pass pass:mypassword 2>/dev/null)
echo "加密结果: $ENCRYPTED"

echo '$ echo "$ENCRYPTED" | openssl enc -d -aes-256-cbc -base64 -pass pass:mypassword'
echo "$ENCRYPTED" | openssl enc -d -aes-256-cbc -base64 -pass pass:mypassword 2>/dev/null
echo ""

# MD5/SHA 哈希
echo '$ echo -n "password123" | openssl dgst -md5'
echo -n "password123" | openssl dgst -md5
echo '$ echo -n "password123" | openssl dgst -sha256'
echo -n "password123" | openssl dgst -sha256
echo ""

# ---------- 生成RSA密钥对 ----------
echo -e "${YELLOW}[2] 生成RSA密钥对${NC}"
echo "----------------------------------------"

echo '$ openssl genrsa -out private.key 2048'
openssl genrsa -out private.key 2048 2>/dev/null
echo "私钥生成完成: $(ls -lh private.key)"

echo '$ openssl rsa -in private.key -pubout -out public.key'
openssl rsa -in private.key -pubout -out public.key 2>/dev/null
echo "公钥生成完成: $(ls -lh public.key)"

echo ""
echo '$ openssl rsa -in private.key -text -noout | head -5'
openssl rsa -in private.key -text -noout 2>/dev/null | head -5
echo ""

# ---------- 生成自签名证书 ----------
echo -e "${YELLOW}[3] 生成自签名证书（HTTPS开发测试用）${NC}"
echo "----------------------------------------"

echo '$ openssl req -x509 -newkey rsa:2048 -keyout server.key -out server.crt -days 365 -nodes -subj "/CN=localhost/O=DevOps Lab"'
openssl req -x509 -newkey rsa:2048 -keyout server.key -out server.crt -days 365 -nodes -subj "/CN=localhost/O=DevOps Lab" 2>/dev/null
echo "证书生成完成:"
ls -lh server.key server.crt

echo ""
echo '$ openssl x509 -in server.crt -text -noout | grep -E "Subject:|Issuer:|Not Before|Not After"'
openssl x509 -in server.crt -text -noout 2>/dev/null | grep -E "Subject:|Issuer:|Not Before|Not After"
echo ""

# ---------- 查看远程证书 ----------
echo -e "${YELLOW}[4] 检查远程网站证书${NC}"
echo "----------------------------------------"

echo '$ openssl s_client -connect baidu.com:443 -servername baidu.com </dev/null 2>/dev/null | openssl x509 -noout -dates'
openssl s_client -connect baidu.com:443 -servername baidu.com </dev/null 2>/dev/null | openssl x509 -noout -dates
echo ""

echo '$ openssl s_client -connect baidu.com:443 -servername baidu.com </dev/null 2>/dev/null | openssl x509 -noout -subject -issuer'
openssl s_client -connect baidu.com:443 -servername baidu.com </dev/null 2>/dev/null | openssl x509 -noout -subject -issuer
echo ""

# ---------- 生成CSR(证书签名请求) ----------
echo -e "${YELLOW}[5] 生成CSR（向CA申请正式证书用）${NC}"
echo "----------------------------------------"
cat << 'EOF'
# 完整流程:
# 1. 生成私钥
openssl genrsa -out mysite.key 2048

# 2. 生成CSR(填写域名等信息)
openssl req -new -key mysite.key -out mysite.csr

# 3. 提交CSR给CA(如Let's Encrypt/DigiCert)
# 4. CA验证后返回签名证书 mysite.crt

# 5. 配置Nginx使用:
#    ssl_certificate     /etc/nginx/ssl/mysite.crt;
#    ssl_certificate_key /etc/nginx/ssl/mysite.key;
EOF
echo ""

# ---------- 证书格式转换 ----------
echo -e "${YELLOW}[6] 证书格式转换${NC}"
echo "----------------------------------------"
cat << 'EOF'
# PEM → DER (Base64转二进制)
openssl x509 -in cert.pem -out cert.der -outform DER

# DER → PEM
openssl x509 -in cert.der -inform DER -out cert.pem -outform PEM

# PEM+KEY → PKCS12 (Java/Windows常用)
openssl pkcs12 -export -in cert.pem -inkey key.pem -out cert.p12

# PKCS12 → PEM
openssl pkcs12 -in cert.p12 -out cert.pem -nodes

# 验证证书和私钥是否匹配
openssl x509 -noout -modulus -in cert.pem | md5sum
openssl rsa  -noout -modulus -in key.pem  | md5sum
# 两个md5一样 = 匹配
EOF
echo ""

echo -e "${GREEN}[完成] Lab 05 OpenSSL 实战结束${NC}"
echo "临时目录: /tmp/ssl-lab/"
