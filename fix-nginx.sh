#!/bin/bash

# Nginx 快速修復腳本
# 用於修復部署後的 Nginx 問題

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[✓]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[⚠]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }

echo "🔧 Nginx 快速修復"
echo "=================="
echo ""

# 1. 檢查 Nginx 狀態
echo "1️⃣  檢查 Nginx 狀態"
if sudo systemctl is-active --quiet nginx; then
    print_status "Nginx 正在運行"
else
    print_warning "Nginx 未運行，嘗試啟動..."
    sudo systemctl start nginx || print_error "啟動失敗"
fi
echo ""

# 2. 測試配置
echo "2️⃣  測試 Nginx 配置"
if sudo nginx -t 2>&1 | grep -q "successful"; then
    print_status "配置正確"
else
    print_error "配置有誤，顯示錯誤:"
    sudo nginx -t
    echo ""
    echo "❓ 要重新配置 Nginx 嗎? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        chmod +x setup-nginx.sh
        ./setup-nginx.sh
        exit 0
    fi
fi
echo ""

# 3. 檢查配置檔案
echo "3️⃣  檢查配置檔案"
CONF_FILE="/etc/nginx/sites-available/tutoring-system"
if [ -f "$CONF_FILE" ]; then
    print_status "找到配置檔案"
    
    # 檢查是否有 API 轉發配置
    if grep -q "location /api" "$CONF_FILE"; then
        print_status "API 轉發配置存在"
    else
        print_warning "缺少 API 轉發配置"
    fi
else
    print_warning "配置檔案不存在"
    echo ""
    echo "❓ 要建立新配置嗎? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        chmod +x setup-nginx.sh
        ./setup-nginx.sh
        exit 0
    fi
fi
echo ""

# 4. 檢查端口衝突
echo "4️⃣  檢查端口衝突"
for port in 80 443; do
    if sudo lsof -i :$port > /dev/null 2>&1; then
        PROCESS=$(sudo lsof -i :$port | grep LISTEN | awk '{print $1}' | head -1)
        if [ "$PROCESS" = "nginx" ]; then
            print_status "端口 $port 由 Nginx 使用"
        else
            print_warning "端口 $port 被 $PROCESS 佔用"
        fi
    else
        print_warning "端口 $port 未被使用"
    fi
done
echo ""

# 5. 檢查後端服務
echo "5️⃣  檢查後端服務"
if curl -s --max-time 3 "http://localhost:5000/api/students" > /dev/null 2>&1; then
    print_status "後端 API 正常"
else
    print_warning "後端 API 無法訪問"
    echo "   請確認: pm2 list"
fi
echo ""

# 6. 檢查前端服務
echo "6️⃣  檢查前端服務"
if curl -s --max-time 3 "http://localhost:3000" > /dev/null 2>&1; then
    print_status "前端服務正常"
else
    print_warning "前端服務無法訪問"
    echo "   請確認: pm2 list"
fi
echo ""

# 7. 測試通過 Nginx 訪問
echo "7️⃣  測試通過 Nginx 訪問"
if curl -s --max-time 3 "http://localhost/api/students" > /dev/null 2>&1; then
    print_status "通過 Nginx 訪問 API 成功"
else
    print_warning "通過 Nginx 訪問 API 失敗"
fi
echo ""

# 8. 顯示最近的錯誤
echo "8️⃣  最近的 Nginx 錯誤 (最後 5 行)"
if [ -f "/var/log/nginx/tutoring-system.error.log" ]; then
    sudo tail -n 5 /var/log/nginx/tutoring-system.error.log 2>/dev/null || echo "   無錯誤日誌"
elif [ -f "/var/log/nginx/error.log" ]; then
    sudo tail -n 5 /var/log/nginx/error.log 2>/dev/null || echo "   無錯誤日誌"
else
    echo "   找不到錯誤日誌"
fi
echo ""

# 總結和建議
echo "=================================="
echo "💡 修復建議"
echo "=================================="
echo ""

# 根據檢查結果給出建議
if ! sudo systemctl is-active --quiet nginx; then
    echo "❌ Nginx 未運行"
    echo "   執行: sudo systemctl start nginx"
    echo ""
fi

if ! sudo nginx -t 2>&1 | grep -q "successful"; then
    echo "❌ Nginx 配置有誤"
    echo "   執行: ./setup-nginx.sh"
    echo "   或手動編輯: sudo nano /etc/nginx/sites-available/tutoring-system"
    echo ""
fi

if ! curl -s --max-time 3 "http://localhost:5000/api/students" > /dev/null 2>&1; then
    echo "❌ 後端服務未運行"
    echo "   執行: pm2 restart tutoring-backend"
    echo "   或: node server/index.js"
    echo ""
fi

if ! curl -s --max-time 3 "http://localhost:3000" > /dev/null 2>&1; then
    echo "❌ 前端服務未運行"
    echo "   執行: pm2 restart tutoring-frontend"
    echo ""
fi

echo "🔧 常用命令:"
echo "  ./setup-nginx.sh              - 重新配置 Nginx"
echo "  sudo systemctl restart nginx  - 重啟 Nginx"
echo "  sudo nginx -t                 - 測試配置"
echo "  pm2 list                      - 查看服務狀態"
echo "  ./diagnose-api.sh             - 完整診斷"
echo ""
