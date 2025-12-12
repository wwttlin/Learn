#!/bin/bash

# Ubuntu 部署腳本 - 補習班管理系統 (修復版)
# 包含完整的資料庫初始化和錯誤處理

set -e  # 遇到錯誤立即退出

echo "🚀 Ubuntu 部署腳本 - 補習班管理系統 (修復版)"
echo "============================================="

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# 錯誤處理函數
handle_error() {
    print_error "腳本執行失敗，行號: $1"
    print_info "請檢查錯誤訊息並重新執行"
    exit 1
}

trap 'handle_error $LINENO' ERR

# 檢查是否為 root 用戶
if [ "$EUID" -eq 0 ]; then
    print_warning "建議不要使用 root 用戶執行此腳本"
fi

# 1. 檢查系統環境
print_info "檢查系統環境..."

# 檢查 Node.js
if ! command -v node >/dev/null 2>&1; then
    print_error "找不到 Node.js，請先安裝 Node.js"
    print_info "安裝指令: curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - && sudo apt-get install -y nodejs"
    exit 1
fi

NODE_VERSION=$(node --version)
print_status "Node.js 版本: $NODE_VERSION"

# 檢查 npm
if ! command -v npm >/dev/null 2>&1; then
    print_error "找不到 npm"
    exit 1
fi

NPM_VERSION=$(npm --version)
print_status "npm 版本: $NPM_VERSION"

# 2. 檢查專案檔案
print_info "檢查專案檔案..."

if [ ! -f "server/index.js" ]; then
    print_error "找不到後端檔案 server/index.js"
    exit 1
fi

if [ ! -f "package.json" ]; then
    print_error "找不到 package.json"
    exit 1
fi

if [ ! -f "init-database.js" ]; then
    print_error "找不到資料庫初始化腳本 init-database.js"
    exit 1
fi

print_status "專案檔案檢查完成"

# 3. 停止現有服務
print_info "停止現有服務..."
pkill -f "node.*server/index.js" 2>/dev/null || true
pkill -f "npm.*start" 2>/dev/null || true

# 如果有 PM2，停止相關服務
if command -v pm2 >/dev/null 2>&1; then
    pm2 delete all 2>/dev/null || true
fi

print_status "現有服務已停止"

# 4. 安裝依賴
print_info "安裝後端依賴..."
npm install --production

print_status "後端依賴安裝完成"

# 5. 初始化資料庫
print_info "初始化資料庫..."

# 刪除舊的資料庫檔案（如果存在且有問題）
if [ -f "tutoring.db" ]; then
    print_warning "發現現有資料庫檔案，將備份後重新建立"
    cp tutoring.db "tutoring.db.backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
fi

# 執行資料庫初始化
node init-database.js

print_status "資料庫初始化完成"

# 6. 檢查資料庫檔案
if [ -f "tutoring.db" ]; then
    print_status "資料庫檔案已建立: tutoring.db"
    
    # 檢查檔案權限
    chmod 664 tutoring.db 2>/dev/null || chmod 644 tutoring.db
    print_status "資料庫檔案權限已設定"
else
    print_error "資料庫檔案建立失敗"
    exit 1
fi

# 7. 建立環境變數檔案
print_info "建立環境變數檔案..."

cat > .env << 'EOF'
NODE_ENV=production
PORT=5000
HOST=0.0.0.0
DB_PATH=./tutoring.db
EOF

print_status "環境變數檔案已建立"

# 8. 測試後端服務
print_info "測試後端服務..."

# 啟動後端服務（背景執行）
node server/index.js > server.log 2>&1 &
SERVER_PID=$!

# 等待服務啟動
sleep 8

# 檢查服務是否正在運行
if kill -0 $SERVER_PID 2>/dev/null; then
    print_status "後端服務啟動成功 (PID: $SERVER_PID)"
    
    # 測試 API 連接
    sleep 3
    if curl -s --connect-timeout 10 --max-time 15 "http://localhost:5000/api/students" >/dev/null 2>&1; then
        print_status "API 連接測試成功"
    else
        print_warning "API 連接測試失敗，檢查服務日誌"
        tail -10 server.log
    fi
else
    print_error "後端服務啟動失敗"
    print_info "檢查日誌:"
    cat server.log
    exit 1
fi

# 停止測試服務
kill $SERVER_PID 2>/dev/null || true
wait $SERVER_PID 2>/dev/null || true

# 9. 安裝 PM2（如果沒有）
USE_PM2=false
if ! command -v pm2 >/dev/null 2>&1; then
    print_info "安裝 PM2..."
    if npm install -g pm2 2>/dev/null; then
        print_status "PM2 安裝完成"
        USE_PM2=true
    else
        print_warning "PM2 安裝失敗，將使用 nohup 啟動服務"
        USE_PM2=false
    fi
else
    print_status "PM2 已安裝"
    USE_PM2=true
fi

# 10. 啟動生產服務
print_info "啟動生產服務..."

if [ "$USE_PM2" = true ]; then
    # 使用 PM2 啟動
    pm2 start server/index.js --name "tutoring-backend" --max-memory-restart 400M
    pm2 save
    # 不強制執行 startup，因為可能需要 sudo
    pm2 startup 2>/dev/null || print_warning "PM2 startup 設定需要手動執行: pm2 startup"
    print_status "使用 PM2 啟動服務完成"
else
    # 使用 nohup 啟動
    nohup node server/index.js > server.log 2>&1 &
    echo $! > server.pid
    print_status "使用 nohup 啟動服務完成"
fi

# 11. 檢查防火牆設定
print_info "檢查防火牆設定..."

if command -v ufw >/dev/null 2>&1; then
    if sudo ufw allow 5000/tcp 2>/dev/null; then
        print_status "防火牆規則已添加 (Port 5000)"
    else
        print_warning "防火牆設定可能需要手動配置"
    fi
fi

# 12. 最終測試
print_info "執行最終測試..."
sleep 5

if curl -s --connect-timeout 5 --max-time 10 "http://localhost:5000/api/students" >/dev/null 2>&1; then
    print_status "最終 API 測試成功"
else
    print_warning "最終 API 測試失敗，請檢查服務狀態"
fi

# 13. 顯示部署結果
EXTERNAL_IP=$(curl -s --connect-timeout 5 --max-time 10 ifconfig.me 2>/dev/null || echo "your-server-ip")

echo ""
print_status "🎉 Ubuntu 部署完成！"
echo ""
print_info "📋 服務資訊:"
print_info "  後端 API: http://$EXTERNAL_IP:5000"
print_info "  本地測試: http://localhost:5000"
echo ""
print_info "🔧 管理命令:"
if [ "$USE_PM2" = true ]; then
    print_info "  pm2 status        - 查看服務狀態"
    print_info "  pm2 logs          - 查看日誌"
    print_info "  pm2 restart all   - 重啟服務"
    print_info "  pm2 stop all      - 停止服務"
else
    print_info "  cat server.log    - 查看日誌"
    print_info "  cat server.pid    - 查看進程 ID"
    print_info "  kill \$(cat server.pid) - 停止服務"
fi
echo ""
print_info "🗄️ 資料庫:"
print_info "  檔案位置: ./tutoring.db"
print_info "  診斷工具: node diagnose-db.js"
print_info "  重新初始化: node init-database.js"
echo ""
print_info "🧪 API 測試:"
print_info "  curl http://localhost:5000/api/students"
print_info "  curl http://localhost:5000/api/courses"
print_info "  curl http://localhost:5000/api/payments"
echo ""
print_warning "⚠️  注意事項:"
print_warning "  - 確保 GCP 防火牆允許 Port 5000"
print_warning "  - 定期備份 tutoring.db 檔案"
print_warning "  - 監控服務運行狀態"

print_status "部署腳本執行完成！"