#!/bin/bash

# Nginx 配置腳本 - 保留現有 SSL 設定
# 適用於已有 Let's Encrypt 證書的伺服器

set -e

# 顏色定義
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[ℹ]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

echo "🔧 Nginx 配置工具 - 補習班管理系統"
echo "===================================="
echo ""

# 檢查是否為 root 或有 sudo 權限
if [ "$EUID" -ne 0 ] && ! sudo -n true 2>/dev/null; then
    print_error "此腳本需要 sudo 權限"
    exit 1
fi

# 檢查 Nginx 是否安裝
if ! command -v nginx &> /dev/null; then
    print_warning "Nginx 未安裝，正在安裝..."
    sudo apt-get update
    sudo apt-get install -y nginx
    print_status "Nginx 安裝完成"
else
    print_status "Nginx 已安裝: $(nginx -v 2>&1 | cut -d'/' -f2)"
fi

# 詢問域名
echo ""
print_info "請輸入你的域名資訊"
read -p "域名 (例如: example.com，留空則使用 IP): " DOMAIN_NAME

# 檢查是否有 SSL 證書
HAS_SSL=false
SSL_CERT_PATH=""
SSL_KEY_PATH=""

if [ ! -z "$DOMAIN_NAME" ]; then
    # 檢查常見的 SSL 證書路徑
    if [ -f "/etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem" ]; then
        HAS_SSL=true
        SSL_CERT_PATH="/etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem"
        SSL_KEY_PATH="/etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem"
        print_status "找到 Let's Encrypt SSL 證書"
    else
        print_warning "未找到 SSL 證書，將只配置 HTTP"
    fi
fi

# 配置檔案路徑
NGINX_CONF="/etc/nginx/sites-available/tutoring-system"
NGINX_ENABLED="/etc/nginx/sites-enabled/tutoring-system"

# 備份現有配置
if [ -f "$NGINX_CONF" ]; then
    BACKUP_FILE="${NGINX_CONF}.backup.$(date +%Y%m%d_%H%M%S)"
    sudo cp "$NGINX_CONF" "$BACKUP_FILE"
    print_status "已備份現有配置到: $BACKUP_FILE"
fi

print_info "正在建立 Nginx 配置..."

# 建立配置檔案
if [ "$HAS_SSL" = true ]; then
    # HTTPS 配置
    sudo tee $NGINX_CONF > /dev/null << EOF
# HTTP - 重定向到 HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN_NAME www.$DOMAIN_NAME;
    
    # Let's Encrypt 驗證
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }
    
    # 重定向到 HTTPS
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}

# HTTPS - 主要配置
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $DOMAIN_NAME www.$DOMAIN_NAME;
    
    # SSL 證書
    ssl_certificate $SSL_CERT_PATH;
    ssl_certificate_key $SSL_KEY_PATH;
    
    # SSL 設定
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_stapling on;
    ssl_stapling_verify on;
    
    # 安全標頭
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    
    # 日誌
    access_log /var/log/nginx/tutoring-system.access.log;
    error_log /var/log/nginx/tutoring-system.error.log;
    
    # Gzip 壓縮
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/json;
    
    # 後端 API
    location /api {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # 超時設定
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # 請求大小限制
        client_max_body_size 10M;
    }
    
    # 前端靜態檔案
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # WebSocket 支援
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # 超時設定
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
EOF
    print_status "已建立 HTTPS 配置"
else
    # HTTP 配置
    SERVER_NAME="${DOMAIN_NAME:-_}"
    sudo tee $NGINX_CONF > /dev/null << EOF
server {
    listen 80;
    listen [::]:80;
    server_name $SERVER_NAME;
    
    # 日誌
    access_log /var/log/nginx/tutoring-system.access.log;
    error_log /var/log/nginx/tutoring-system.error.log;
    
    # Gzip 壓縮
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/json;
    
    # 後端 API
    location /api {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # 超時設定
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # 請求大小限制
        client_max_body_size 10M;
    }
    
    # 前端靜態檔案
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # 超時設定
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
EOF
    print_status "已建立 HTTP 配置"
fi

# 啟用配置
if [ ! -L "$NGINX_ENABLED" ]; then
    sudo ln -sf $NGINX_CONF $NGINX_ENABLED
    print_status "配置已啟用"
fi

# 測試配置
print_info "測試 Nginx 配置..."
if sudo nginx -t 2>&1 | tee /tmp/nginx-test.log; then
    print_status "Nginx 配置測試通過"
    
    # 重啟 Nginx
    print_info "重啟 Nginx..."
    sudo systemctl restart nginx
    
    if sudo systemctl is-active --quiet nginx; then
        print_status "Nginx 已成功重啟"
    else
        print_error "Nginx 啟動失敗"
        sudo systemctl status nginx
        exit 1
    fi
else
    print_error "Nginx 配置測試失敗"
    cat /tmp/nginx-test.log
    print_info "配置檔案位置: $NGINX_CONF"
    exit 1
fi

# 顯示結果
echo ""
echo "=================================="
echo "✅ Nginx 配置完成！"
echo "=================================="
echo ""

if [ "$HAS_SSL" = true ]; then
    echo "🌐 訪問網址:"
    echo "  https://$DOMAIN_NAME"
    echo "  https://www.$DOMAIN_NAME"
    echo ""
    echo "🔒 SSL 證書:"
    echo "  證書: $SSL_CERT_PATH"
    echo "  私鑰: $SSL_KEY_PATH"
else
    if [ ! -z "$DOMAIN_NAME" ]; then
        echo "🌐 訪問網址:"
        echo "  http://$DOMAIN_NAME"
    else
        EXTERNAL_IP=$(curl -s ifconfig.me 2>/dev/null || echo "your-server-ip")
        echo "🌐 訪問網址:"
        echo "  http://$EXTERNAL_IP"
    fi
fi

echo ""
echo "📋 配置檔案:"
echo "  $NGINX_CONF"
echo ""
echo "📝 日誌檔案:"
echo "  /var/log/nginx/tutoring-system.access.log"
echo "  /var/log/nginx/tutoring-system.error.log"
echo ""

if [ "$HAS_SSL" = false ] && [ ! -z "$DOMAIN_NAME" ]; then
    echo "💡 提示: 如需啟用 HTTPS，請執行:"
    echo "  sudo certbot --nginx -d $DOMAIN_NAME -d www.$DOMAIN_NAME"
    echo ""
fi

echo "🔧 管理命令:"
echo "  sudo systemctl status nginx   - 查看狀態"
echo "  sudo systemctl restart nginx  - 重啟服務"
echo "  sudo nginx -t                 - 測試配置"
echo "  sudo tail -f /var/log/nginx/tutoring-system.access.log  - 查看訪問日誌"
echo ""
