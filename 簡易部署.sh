#!/bin/bash

# 簡易部署腳本 - 適用於透過 SSH/SCP 上傳的專案
# 無需 gcloud CLI

set -e

echo "🚀 補習班管理系統 - 簡易部署腳本"
echo "適用於透過 SSH/SCP/Git 上傳的專案"
echo ""

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

# 檢查是否在正確的目錄
if [ ! -f "package.json" ] || [ ! -d "server" ] || [ ! -d "client" ]; then
    print_error "請在專案根目錄執行此腳本"
    print_info "確保目錄包含: package.json, server/, client/"
    exit 1
fi

print_info "在目錄 $(pwd) 中找到專案檔案"

# 檢查系統
print_info "檢查系統環境..."
if command -v lsb_release &> /dev/null; then
    OS_INFO=$(lsb_release -d | cut -f2)
    print_info "作業系統: $OS_INFO"
fi

# 更新系統
print_status "更新系統套件..."
sudo apt update -y

# 安裝 Node.js
if ! command -v node &> /dev/null; then
    print_status "安裝 Node.js 18.x..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
    print_status "Node.js 安裝完成: $(node --version)"
else
    print_status "Node.js 已安裝: $(node --version)"
fi

# 安裝 PM2
if ! command -v pm2 &> /dev/null; then
    print_status "安裝 PM2 進程管理器..."
    sudo npm install -g pm2
    print_status "PM2 安裝完成: $(pm2 --version)"
else
    print_status "PM2 已安裝: $(pm2 --version)"
fi

# 安裝 serve
if ! command -v serve &> /dev/null; then
    print_status "安裝 serve 靜態檔案服務器..."
    sudo npm install -g serve
    print_status "serve 安裝完成"
else
    print_status "serve 已安裝"
fi

# 建立必要目錄
print_status "建立目錄結構..."
mkdir -p logs backups

# 安裝後端依賴
print_status "安裝後端依賴..."
npm install

# 檢查前端目錄
if [ -d "client" ]; then
    print_status "安裝前端依賴..."
    cd client
    npm install
    
    print_status "建置前端應用..."
    npm run build
    cd ..
    
    if [ -d "client/build" ]; then
        print_status "前端建置成功"
    else
        print_error "前端建置失敗"
        exit 1
    fi
else
    print_error "找不到 client 目錄"
    exit 1
fi

# 建立環境配置
if [ ! -f ".env" ]; then
    print_status "建立環境配置檔案..."
    cat > .env << EOF
NODE_ENV=production
PORT=5000
HOST=0.0.0.0
EOF
    print_status "環境配置檔案已建立"
else
    print_status "環境配置檔案已存在"
fi

# 停止現有服務
print_status "停止現有服務..."
pm2 delete all 2>/dev/null || true

# 啟動後端服務
print_status "啟動後端服務..."
pm2 start server/index.js --name "tutoring-backend" --env production

# 啟動前端服務
print_status "啟動前端服務..."
pm2 start "serve -s client/build -l 3000" --name "tutoring-frontend"

# 儲存 PM2 配置
print_status "儲存 PM2 配置..."
pm2 save

# 設定開機自動啟動
print_status "設定開機自動啟動..."
pm2 startup systemd -u $USER --hp $HOME 2>/dev/null || {
    print_warning "自動啟動設定可能需要手動執行以下命令:"
    pm2 startup systemd -u $USER --hp $HOME
}

# 建立備份腳本
print_status "建立資料庫備份腳本..."
cat > backup-db.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
if [ -f "tutoring.db" ]; then
    cp tutoring.db backups/tutoring_$DATE.db
    echo "資料庫備份完成: tutoring_$DATE.db"
    # 清理 7 天前的備份
    find backups -name "tutoring_*.db" -mtime +7 -delete 2>/dev/null
else
    echo "找不到資料庫檔案"
fi
EOF

chmod +x backup-db.sh

# 建立管理腳本
print_status "建立管理腳本..."
cat > manage.sh << 'EOF'
#!/bin/bash

case "$1" in
    status)
        echo "=== 服務狀態 ==="
        pm2 status
        echo ""
        echo "=== 系統資源 ==="
        echo "記憶體: $(free -h | grep Mem | awk '{print $3 "/" $2}')"
        echo "磁碟: $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')"
        ;;
    logs)
        pm2 logs
        ;;
    restart)
        echo "重啟所有服務..."
        pm2 restart all
        ;;
    stop)
        echo "停止所有服務..."
        pm2 stop all
        ;;
    backup)
        ./backup-db.sh
        ;;
    update)
        echo "更新專案..."
        if [ -d ".git" ]; then
            git pull
            npm install
            cd client && npm install && npm run build && cd ..
            pm2 restart all
            echo "更新完成"
        else
            echo "這不是 Git 倉庫，請手動更新檔案"
        fi
        ;;
    *)
        echo "用法: $0 {status|logs|restart|stop|backup|update}"
        echo ""
        echo "  status  - 顯示服務狀態"
        echo "  logs    - 顯示服務日誌"
        echo "  restart - 重啟所有服務"
        echo "  stop    - 停止所有服務"
        echo "  backup  - 備份資料庫"
        echo "  update  - 更新專案（需要 Git）"
        ;;
esac
EOF

chmod +x manage.sh

# 等待服務啟動
print_status "等待服務啟動..."
sleep 5

# 檢查服務狀態
print_status "檢查服務狀態..."
pm2 status

# 獲取外部 IP
EXTERNAL_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "無法獲取")

# 顯示完成資訊
echo ""
echo "🎉 部署完成！"
echo ""
echo "📋 訪問資訊:"
if [ "$EXTERNAL_IP" != "無法獲取" ]; then
    echo "  前端應用: http://$EXTERNAL_IP:3000"
    echo "  後端 API: http://$EXTERNAL_IP:5000"
else
    echo "  前端應用: http://your-vm-ip:3000"
    echo "  後端 API: http://your-vm-ip:5000"
fi
echo ""
echo "🔧 管理命令:"
echo "  ./manage.sh status   - 查看服務狀態"
echo "  ./manage.sh logs     - 查看服務日誌"
echo "  ./manage.sh restart  - 重啟服務"
echo "  ./manage.sh backup   - 備份資料庫"
echo ""
echo "📁 重要檔案:"
echo "  資料庫: $(pwd)/tutoring.db"
echo "  日誌: $(pwd)/logs/"
echo "  備份: $(pwd)/backups/"
echo ""

# 最終檢查
sleep 3
if pm2 list | grep -q "online"; then
    print_status "✅ 所有服務運行正常"
    
    # 測試服務連接
    if curl -s --max-time 5 "http://localhost:5000/api/students" > /dev/null 2>&1; then
        print_status "✅ 後端 API 正常回應"
    else
        print_warning "⚠️  後端 API 可能需要幾秒鐘才能完全啟動"
    fi
    
    if curl -s --max-time 5 "http://localhost:3000" > /dev/null 2>&1; then
        print_status "✅ 前端服務正常回應"
    else
        print_warning "⚠️  前端服務可能需要幾秒鐘才能完全啟動"
    fi
else
    print_error "❌ 部分服務可能有問題"
    print_info "請執行 './manage.sh logs' 查看詳細日誌"
fi

echo ""
print_info "部署腳本執行完成！"
print_info "如有問題，請查看日誌: ./manage.sh logs"