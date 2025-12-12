#!/bin/bash

# 一鍵修復腳本 - 修復所有常見問題
# 包含：前端更新、Nginx 配置、服務重啟

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[✓]${NC} $1"; }
print_info() { echo -e "${BLUE}[ℹ]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[⚠]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }

echo "🚀 補習班管理系統 - 一鍵修復"
echo "=============================="
echo ""
echo "此腳本會："
echo "  1. 檢查並修復 Nginx 配置"
echo "  2. 更新前端應用"
echo "  3. 重啟所有服務"
echo "  4. 執行完整診斷"
echo ""
read -p "按 Enter 繼續，或 Ctrl+C 取消..."
echo ""

# 步驟 1: 檢查 Nginx
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 步驟 1/4: 檢查 Nginx"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if command -v nginx &> /dev/null; then
    if sudo nginx -t 2>&1 | grep -q "successful"; then
        print_status "Nginx 配置正確"
    else
        print_warning "Nginx 配置有問題，正在修復..."
        if [ -f "setup-nginx.sh" ]; then
            chmod +x setup-nginx.sh
            ./setup-nginx.sh
        else
            print_error "找不到 setup-nginx.sh"
        fi
    fi
else
    print_warning "Nginx 未安裝"
    echo "是否要安裝並配置 Nginx? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        sudo apt-get update
        sudo apt-get install -y nginx
        if [ -f "setup-nginx.sh" ]; then
            chmod +x setup-nginx.sh
            ./setup-nginx.sh
        fi
    fi
fi
echo ""

# 步驟 2: 更新前端
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 步驟 2/4: 更新前端"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ -d "client" ]; then
    print_info "進入前端目錄..."
    cd client
    
    print_info "清理快取..."
    rm -rf node_modules/.cache build 2>/dev/null || true
    
    print_info "安裝依賴..."
    npm install
    
    print_info "建置前端..."
    export NODE_OPTIONS="--max-old-space-size=2048"
    export CI=false
    export GENERATE_SOURCEMAP=false
    
    if npm run build; then
        print_status "前端建置成功"
    else
        print_error "前端建置失敗"
        cd ..
        exit 1
    fi
    
    cd ..
else
    print_error "找不到 client 目錄"
    exit 1
fi
echo ""

# 步驟 3: 重啟服務
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 步驟 3/4: 重啟服務"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if command -v pm2 &> /dev/null; then
    print_info "重啟後端服務..."
    pm2 restart tutoring-backend 2>/dev/null || pm2 start server/index.js --name "tutoring-backend"
    
    print_info "重啟前端服務..."
    pm2 restart tutoring-frontend 2>/dev/null || pm2 start "serve -s client/build -l 3000" --name "tutoring-frontend"
    
    print_info "儲存 PM2 配置..."
    pm2 save
    
    print_status "服務已重啟"
else
    print_warning "PM2 未安裝"
    echo "是否要安裝 PM2? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        sudo npm install -g pm2
        pm2 start server/index.js --name "tutoring-backend"
        pm2 start "serve -s client/build -l 3000" --name "tutoring-frontend"
        pm2 save
        pm2 startup
    fi
fi

if command -v nginx &> /dev/null; then
    print_info "重啟 Nginx..."
    sudo systemctl restart nginx
    print_status "Nginx 已重啟"
fi
echo ""

# 步驟 4: 診斷
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 步驟 4/4: 執行診斷"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

print_info "等待服務啟動..."
sleep 5

# 檢查服務
print_info "檢查服務狀態..."

# 後端
if curl -s --max-time 5 "http://localhost:5000/api/students" > /dev/null 2>&1; then
    print_status "✅ 後端 API 正常"
else
    print_error "❌ 後端 API 異常"
fi

# 前端
if curl -s --max-time 5 "http://localhost:3000" > /dev/null 2>&1; then
    print_status "✅ 前端服務正常"
else
    print_error "❌ 前端服務異常"
fi

# Nginx
if command -v nginx &> /dev/null && sudo systemctl is-active --quiet nginx; then
    if curl -s --max-time 5 "http://localhost/api/students" > /dev/null 2>&1; then
        print_status "✅ Nginx 轉發正常"
    else
        print_warning "⚠️  Nginx 轉發可能有問題"
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 修復完成！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 獲取訪問資訊
EXTERNAL_IP=$(curl -s ifconfig.me 2>/dev/null || echo "無法獲取")

if [ "$EXTERNAL_IP" != "無法獲取" ]; then
    echo "🌐 訪問網址:"
    if command -v nginx &> /dev/null && sudo systemctl is-active --quiet nginx; then
        echo "  主要網址: http://$EXTERNAL_IP"
        echo ""
        echo "  直接訪問:"
        echo "  - 前端: http://$EXTERNAL_IP:3000"
        echo "  - 後端: http://$EXTERNAL_IP:5000"
    else
        echo "  前端: http://$EXTERNAL_IP:3000"
        echo "  後端: http://$EXTERNAL_IP:5000"
    fi
else
    echo "🌐 訪問網址:"
    echo "  前端: http://your-server-ip:3000"
    echo "  後端: http://your-server-ip:5000"
fi

echo ""
echo "📋 管理命令:"
echo "  pm2 list                - 查看服務狀態"
echo "  pm2 logs                - 查看日誌"
echo "  ./manage.sh status      - 查看系統狀態"
echo "  ./diagnose-api.sh       - 完整診斷"
echo "  ./fix-nginx.sh          - 修復 Nginx"
echo ""

# 詳細診斷
if [ -f "diagnose-api.sh" ]; then
    echo "💡 執行完整診斷? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        chmod +x diagnose-api.sh
        ./diagnose-api.sh
    fi
fi

echo ""
print_status "所有修復步驟已完成！"
echo ""
