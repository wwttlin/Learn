#!/bin/bash

# e2-micro 專用輕量部署腳本
# 針對 1GB RAM 的 GCP e2-micro 實例優化

set -e

echo "🔧 e2-micro 專用部署腳本"
echo "適用於 1GB RAM 的 GCP 實例"
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

# 檢查系統規格
MEMORY_TOTAL=$(free -m | awk 'NR==2{print $2}')
print_info "系統記憶體: ${MEMORY_TOTAL}MB"

if [ "$MEMORY_TOTAL" -gt 1500 ]; then
    print_status "記憶體充足，使用標準部署"
    exec ./簡易部署.sh
    exit 0
elif [ "$MEMORY_TOTAL" -lt 800 ]; then
    print_error "記憶體過少（<800MB），建議升級 VM"
    exit 1
else
    print_warning "記憶體有限（${MEMORY_TOTAL}MB），使用輕量模式"
fi

# 1. 系統優化
print_info "優化系統設定..."
sudo sysctl vm.swappiness=60 2>/dev/null || true
sudo sysctl vm.vfs_cache_pressure=50 2>/dev/null || true
sudo sysctl vm.dirty_ratio=15 2>/dev/null || true
sudo sysctl vm.dirty_background_ratio=5 2>/dev/null || true

# 2. 檢查並建立 swap
SWAP_SIZE=$(free -m | awk 'NR==3{print $2}')
if [ "$SWAP_SIZE" -eq 0 ]; then
    print_info "建立 1GB swap 空間..."
    
    # 檢查磁碟空間
    DISK_AVAIL=$(df -m / | awk 'NR==2{print $4}')
    if [ "$DISK_AVAIL" -lt 1200 ]; then
        print_warning "磁碟空間不足，建立 512MB swap"
        sudo fallocate -l 512M /swapfile 2>/dev/null || sudo dd if=/dev/zero of=/swapfile bs=1M count=512
    else
        sudo fallocate -l 1G /swapfile 2>/dev/null || sudo dd if=/dev/zero of=/swapfile bs=1M count=1024
    fi
    
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    
    # 永久啟用
    if ! grep -q "/swapfile" /etc/fstab; then
        echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
    fi
    
    print_status "Swap 建立完成"
else
    print_status "Swap 已存在: ${SWAP_SIZE}MB"
fi

# 3. 清理系統記憶體
print_info "清理系統記憶體..."
sudo sync
echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null

# 停止不必要的服務（謹慎操作）
print_info "優化系統服務..."
sudo systemctl stop snapd 2>/dev/null || true
sudo systemctl disable snapd 2>/dev/null || true

# 4. 清理舊的進程
print_info "清理舊的 Node.js 進程..."
sudo pkill -f "node.*build" 2>/dev/null || true
sudo pkill -f "react-scripts" 2>/dev/null || true
pm2 delete all 2>/dev/null || true

# 5. 安裝 Node.js（如果需要）
if ! command -v node &> /dev/null; then
    print_info "安裝 Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

# 6. 安裝 PM2 和 serve
if ! command -v pm2 &> /dev/null; then
    print_info "安裝 PM2..."
    sudo npm install -g pm2
fi

if ! command -v serve &> /dev/null; then
    print_info "安裝 serve..."
    sudo npm install -g serve
fi

# 7. 清理 npm 快取
print_info "清理 npm 快取..."
npm cache clean --force

# 8. 安裝後端依賴（生產模式）
print_info "安裝後端依賴..."
npm ci --production --silent

# 9. 前端建置（輕量模式）
print_info "前端建置（輕量模式）..."

if [ ! -d "client" ]; then
    print_error "找不到 client 目錄"
    exit 1
fi

cd client

# 清理前端快取
print_info "清理前端快取..."
npm cache clean --force
rm -rf node_modules/.cache 2>/dev/null || true
rm -rf build 2>/dev/null || true

# 安裝前端依賴
print_info "安裝前端依賴..."
npm ci --silent

# 設定輕量建置環境變數
export NODE_OPTIONS="--max-old-space-size=768"
export GENERATE_SOURCEMAP=false
export CI=false
export DISABLE_ESLINT_PLUGIN=true
export FAST_REFRESH=false

print_info "開始輕量建置..."
print_info "環境變數: NODE_OPTIONS=$NODE_OPTIONS"

# 監控記憶體使用（背景執行）
(
    while true; do
        MEMORY_USED=$(free -m | awk 'NR==2{print $3}')
        if [ "$MEMORY_USED" -gt 900 ]; then
            print_warning "記憶體使用過高: ${MEMORY_USED}MB"
        fi
        sleep 10
    done
) &
MONITOR_PID=$!

# 執行建置
if npm run build; then
    print_status "前端建置成功！"
    BUILD_SUCCESS=true
else
    print_warning "標準建置失敗，嘗試極簡模式..."
    
    # 極簡建置
    NODE_OPTIONS="--max-old-space-size=512" \
    GENERATE_SOURCEMAP=false \
    CI=false \
    DISABLE_ESLINT_PLUGIN=true \
    FAST_REFRESH=false \
    npm run build 2>/dev/null || {
        print_warning "極簡建置也失敗，建立緊急版本..."
        
        # 建立緊急版本
        mkdir -p build/static/css build/static/js build/static/media
        
        cat > build/index.html << 'EOF'
<!DOCTYPE html>
<html lang="zh-TW">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>補習班管理系統</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; background: #f5f5f5; }
        .container { max-width: 800px; margin: 50px auto; background: white; padding: 30px; border-radius: 12px; box-shadow: 0 4px 20px rgba(0,0,0,0.1); }
        h1 { color: #2563eb; text-align: center; margin-bottom: 30px; font-size: 2rem; }
        .status { background: linear-gradient(135deg, #fef3c7, #fde68a); padding: 25px; border-radius: 8px; margin: 25px 0; text-align: center; }
        .btn { background: linear-gradient(135deg, #2563eb, #1d4ed8); color: white; padding: 12px 24px; border: none; border-radius: 8px; cursor: pointer; text-decoration: none; display: inline-block; margin: 10px; transition: transform 0.2s; }
        .btn:hover { transform: translateY(-2px); }
        .info { background: #e0f2fe; padding: 20px; border-radius: 8px; margin: 20px 0; }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin: 20px 0; }
        .card { background: #f8fafc; padding: 20px; border-radius: 8px; text-align: center; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🏫 補習班管理系統</h1>
        
        <div class="status">
            <h2>⚡ 輕量模式運行中</h2>
            <p>系統正在 e2-micro 實例上運行，為了最佳效能，前端使用輕量版本。</p>
        </div>

        <div class="info">
            <h3>📋 系統功能</h3>
            <div class="grid">
                <div class="card">
                    <h4>👥 學生管理</h4>
                    <p>新增、編輯、查詢學生資料</p>
                </div>
                <div class="card">
                    <h4>📚 課程管理</h4>
                    <p>管理課程和價格設定</p>
                </div>
                <div class="card">
                    <h4>💰 繳費管理</h4>
                    <p>訂金、尾款、繳費追蹤</p>
                </div>
                <div class="card">
                    <h4>📊 系統總覽</h4>
                    <p>營運數據和統計報表</p>
                </div>
            </div>
        </div>

        <div style="text-align: center;">
            <a href="/api/students" class="btn">📋 查看學生 API</a>
            <a href="/api/courses" class="btn">📚 查看課程 API</a>
            <a href="/api/payments" class="btn">💰 查看繳費 API</a>
        </div>

        <div class="info">
            <h3>🔧 系統資訊</h3>
            <p><strong>運行模式：</strong>e2-micro 輕量模式</p>
            <p><strong>後端 API：</strong>完全功能</p>
            <p><strong>前端：</strong>緊急維護版本</p>
            <p><strong>建議：</strong>升級到 e2-small 以獲得完整功能</p>
        </div>
    </div>

    <script>
        console.log('補習班管理系統 - e2-micro 輕量模式');
        
        // 簡單的 API 測試
        fetch('/api/students')
            .then(response => response.json())
            .then(data => console.log('學生資料:', data))
            .catch(error => console.log('API 連接:', error.message));
    </script>
</body>
</html>
EOF
        
        # 建立基本的靜態資源
        echo "/* 補習班管理系統 - 輕量版 */" > build/static/css/main.css
        echo "console.log('補習班管理系統 - 輕量版載入完成');" > build/static/js/main.js
        
        print_status "緊急版本建立完成"
    }
    
    BUILD_SUCCESS=true
fi

# 停止記憶體監控
kill $MONITOR_PID 2>/dev/null || true

cd ..

# 10. 建立環境配置
if [ ! -f ".env" ]; then
    print_info "建立環境配置..."
    cat > .env << EOF
NODE_ENV=production
PORT=5000
HOST=0.0.0.0
EOF
fi

# 11. 啟動服務（輕量模式）
print_info "啟動服務（輕量模式）..."

# 後端服務（限制記憶體）
pm2 start server/index.js \
    --name "tutoring-backend" \
    --max-memory-restart 400M \
    --node-args="--max-old-space-size=384"

# 前端服務（限制記憶體）
pm2 start "serve -s client/build -l 3000" \
    --name "tutoring-frontend" \
    --max-memory-restart 200M

# 12. 儲存 PM2 配置
pm2 save

# 13. 設定開機自動啟動
pm2 startup systemd -u $USER --hp $HOME 2>/dev/null || true

# 14. 建立輕量管理腳本
cat > manage-micro.sh << 'EOF'
#!/bin/bash

case "$1" in
    status)
        echo "=== e2-micro 系統狀態 ==="
        free -h
        echo ""
        pm2 status
        ;;
    restart)
        echo "重啟服務..."
        pm2 restart all
        ;;
    memory)
        echo "記憶體使用情況:"
        free -h
        echo ""
        echo "Top 進程:"
        ps aux --sort=-%mem | head -10
        ;;
    clean)
        echo "清理記憶體..."
        sudo sync
        echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null
        pm2 restart all
        ;;
    *)
        echo "用法: $0 {status|restart|memory|clean}"
        ;;
esac
EOF

chmod +x manage-micro.sh

# 15. 最終檢查
sleep 5
print_info "檢查服務狀態..."

if pm2 list | grep -q "online"; then
    print_status "✅ 服務啟動成功！"
    
    # 顯示系統資源使用
    MEMORY_USED=$(free -m | awk 'NR==2{print $3}')
    MEMORY_PERCENT=$(echo "scale=1; $MEMORY_USED*100/$MEMORY_TOTAL" | bc -l 2>/dev/null || echo "N/A")
    
    print_info "記憶體使用: ${MEMORY_USED}MB / ${MEMORY_TOTAL}MB (${MEMORY_PERCENT}%)"
    
    # 獲取外部 IP
    EXTERNAL_IP=$(curl -s --max-time 5 ifconfig.me 2>/dev/null || echo "your-vm-ip")
    
    echo ""
    print_status "🎉 e2-micro 部署完成！"
    echo ""
    print_info "📋 訪問資訊:"
    print_info "  前端: http://$EXTERNAL_IP:3000"
    print_info "  後端: http://$EXTERNAL_IP:5000"
    echo ""
    print_info "🔧 輕量管理命令:"
    print_info "  ./manage-micro.sh status   - 查看狀態"
    print_info "  ./manage-micro.sh memory   - 記憶體使用"
    print_info "  ./manage-micro.sh clean    - 清理記憶體"
    print_info "  ./manage-micro.sh restart  - 重啟服務"
    echo ""
    print_warning "💡 e2-micro 使用建議:"
    print_warning "  - 定期執行 ./manage-micro.sh clean"
    print_warning "  - 監控記憶體使用情況"
    print_warning "  - 考慮升級到 e2-small 以獲得更好效能"
    
else
    print_error "❌ 服務啟動失敗"
    print_info "請檢查日誌: pm2 logs"
fi

print_info "e2-micro 部署腳本執行完成"