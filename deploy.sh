#!/bin/bash

# 補習班管理系統部署腳本
# 適用於 Ubuntu Linux (GCP Cloud)

set -e  # 遇到錯誤立即退出

echo "🚀 開始部署補習班管理系統..."

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 函數：印出彩色訊息
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 檢查是否為 root 用戶
if [ "$EUID" -eq 0 ]; then
    print_error "請不要使用 root 用戶執行此腳本"
    exit 1
fi

# 檢查作業系統
if ! grep -q "Ubuntu" /etc/os-release; then
    print_warning "此腳本專為 Ubuntu 設計，其他系統可能需要調整"
fi

# 1. 更新系統
print_status "更新系統套件..."
sudo apt update && sudo apt upgrade -y

# 2. 安裝 Node.js
if ! command -v node &> /dev/null; then
    print_status "安裝 Node.js 18.x..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
else
    print_status "Node.js 已安裝: $(node --version)"
fi

# 3. 安裝 Git
if ! command -v git &> /dev/null; then
    print_status "安裝 Git..."
    sudo apt install git -y
else
    print_status "Git 已安裝: $(git --version)"
fi

# 4. 安裝 PM2
if ! command -v pm2 &> /dev/null; then
    print_status "安裝 PM2..."
    sudo npm install -g pm2
else
    print_status "PM2 已安裝: $(pm2 --version)"
fi

# 5. 安裝 serve
if ! command -v serve &> /dev/null; then
    print_status "安裝 serve..."
    sudo npm install -g serve
else
    print_status "serve 已安裝"
fi

# 6. 建立必要目錄
print_status "建立目錄結構..."
mkdir -p logs
mkdir -p backups

# 7. 安裝專案依賴
print_status "安裝後端依賴..."
npm install

print_status "安裝前端依賴..."
cd client
npm install

# 8. 建置前端
print_status "建置前端應用..."
npm run build
cd ..

# 9. 建立環境配置檔案
if [ ! -f .env ]; then
    print_status "建立環境配置檔案..."
    cat > .env << EOF
NODE_ENV=production
PORT=5000
HOST=0.0.0.0
EOF
else
    print_status "環境配置檔案已存在"
fi

# 10. 停止現有服務（如果存在）
print_status "停止現有服務..."
pm2 delete all 2>/dev/null || true

# 11. 啟動服務
print_status "啟動服務..."
pm2 start ecosystem.config.js --env production

# 12. 儲存 PM2 配置
print_status "儲存 PM2 配置..."
pm2 save

# 13. 設定開機自動啟動
print_status "設定開機自動啟動..."
pm2 startup systemd -u $USER --hp $HOME 2>/dev/null || true

# 14. 建立備份腳本
print_status "建立資料庫備份腳本..."
cat > backup-db.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
cp tutoring.db backups/tutoring_$DATE.db
find backups -name "tutoring_*.db" -mtime +7 -delete
echo "資料庫備份完成: tutoring_$DATE.db"
EOF

chmod +x backup-db.sh

# 15. 設定防火牆（如果 UFW 已安裝）
if command -v ufw &> /dev/null; then
    print_status "設定防火牆規則..."
    sudo ufw allow 3000 2>/dev/null || true
    sudo ufw allow 5000 2>/dev/null || true
fi

# 16. 顯示服務狀態
print_status "檢查服務狀態..."
sleep 3
pm2 status

# 17. 顯示完成訊息
echo ""
echo "🎉 部署完成！"
echo ""
echo "📋 服務資訊："
echo "  前端: http://$(curl -s ifconfig.me):3000"
echo "  後端: http://$(curl -s ifconfig.me):5000"
echo ""
echo "🔧 管理命令："
echo "  查看狀態: pm2 status"
echo "  查看日誌: pm2 logs"
echo "  重啟服務: pm2 restart all"
echo "  備份資料: ./backup-db.sh"
echo ""
echo "📁 重要檔案："
echo "  資料庫: $(pwd)/tutoring.db"
echo "  日誌: $(pwd)/logs/"
echo "  備份: $(pwd)/backups/"
echo ""

# 18. 檢查服務是否正常運行
sleep 5
if pm2 list | grep -q "online"; then
    print_status "✅ 所有服務運行正常"
else
    print_error "❌ 部分服務可能有問題，請檢查日誌: pm2 logs"
fi

echo "部署腳本執行完成！"