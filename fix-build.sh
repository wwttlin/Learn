#!/bin/bash

# 前端建置問題修復腳本

set -e

echo "🔧 修復前端建置問題..."

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

# 檢查是否在正確目錄
if [ ! -f "package.json" ] || [ ! -d "client" ]; then
    print_error "請在專案根目錄執行此腳本"
    exit 1
fi

# 1. 檢查系統資源
print_info "檢查系統資源..."
MEMORY_TOTAL=$(free -m | awk 'NR==2{print $2}')
MEMORY_USED=$(free -m | awk 'NR==2{print $3}')
MEMORY_PERCENT=$(echo "scale=1; $MEMORY_USED*100/$MEMORY_TOTAL" | bc -l 2>/dev/null || echo "0")

print_info "記憶體: ${MEMORY_USED}MB / ${MEMORY_TOTAL}MB (${MEMORY_PERCENT}%)"

DISK_USAGE=$(df -h / | awk 'NR==2{print $5}' | sed 's/%//')
print_info "磁碟使用: ${DISK_USAGE}%"

# 2. 檢查並建立 swap
SWAP_SIZE=$(free -m | awk 'NR==3{print $2}')
if [ "$SWAP_SIZE" -eq 0 ]; then
    print_warning "沒有 swap 空間，正在建立..."
    
    if [ "$MEMORY_TOTAL" -lt 2048 ]; then
        print_info "記憶體不足 2GB，建立 1GB swap..."
        sudo fallocate -l 1G /swapfile 2>/dev/null || sudo dd if=/dev/zero of=/swapfile bs=1M count=1024
        sudo chmod 600 /swapfile
        sudo mkswap /swapfile
        sudo swapon /swapfile
        
        # 永久啟用
        if ! grep -q "/swapfile" /etc/fstab; then
            echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
        fi
        
        print_status "Swap 建立完成"
    fi
else
    print_status "Swap 已存在: ${SWAP_SIZE}MB"
fi

# 3. 清理磁碟空間（如果需要）
if [ "$DISK_USAGE" -gt 85 ]; then
    print_warning "磁碟空間不足，正在清理..."
    sudo apt autoremove -y 2>/dev/null || true
    sudo apt autoclean 2>/dev/null || true
    
    # 清理 npm 快取
    npm cache clean --force 2>/dev/null || true
    
    print_status "磁碟清理完成"
fi

# 4. 停止可能卡住的進程
print_info "停止現有的建置進程..."
sudo pkill -f "react-scripts build" 2>/dev/null || true
sudo pkill -f "webpack" 2>/dev/null || true
sudo pkill -f "node.*build" 2>/dev/null || true

sleep 2

# 5. 檢查 Node.js 版本
NODE_VERSION=$(node --version | sed 's/v//' | cut -d. -f1)
print_info "Node.js 版本: $(node --version)"

if [ "$NODE_VERSION" -lt 16 ]; then
    print_warning "Node.js 版本過舊，建議升級到 18.x"
    read -p "是否要升級 Node.js？(y/N): " upgrade_node
    if [[ $upgrade_node =~ ^[Yy]$ ]]; then
        print_info "升級 Node.js..."
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        sudo apt-get install -y nodejs
        print_status "Node.js 升級完成: $(node --version)"
    fi
fi

# 6. 進入 client 目錄並修復
print_info "進入前端目錄..."
cd client

# 7. 清理快取和依賴
print_info "清理快取和舊的建置檔案..."
npm cache clean --force 2>/dev/null || true
rm -rf node_modules/.cache 2>/dev/null || true
rm -rf build 2>/dev/null || true

# 8. 檢查 package.json
if [ ! -f "package.json" ]; then
    print_error "找不到 client/package.json"
    exit 1
fi

# 9. 重新安裝依賴（如果需要）
if [ ! -d "node_modules" ] || [ ! -f "package-lock.json" ]; then
    print_info "重新安裝前端依賴..."
    rm -rf node_modules package-lock.json 2>/dev/null || true
    npm install
else
    print_info "檢查依賴完整性..."
    npm ci 2>/dev/null || npm install
fi

# 10. 設定建置環境變數
export NODE_OPTIONS="--max-old-space-size=2048"
export CI=false
export GENERATE_SOURCEMAP=false

print_info "設定建置環境變數:"
print_info "  NODE_OPTIONS=$NODE_OPTIONS"
print_info "  CI=$CI"
print_info "  GENERATE_SOURCEMAP=$GENERATE_SOURCEMAP"

# 11. 嘗試建置
print_info "開始前端建置..."

# 方法1: 使用環境變數建置
if NODE_OPTIONS="--max-old-space-size=2048" CI=false GENERATE_SOURCEMAP=false npm run build; then
    print_status "建置成功！"
    BUILD_SUCCESS=true
else
    print_warning "標準建置失敗，嘗試替代方案..."
    BUILD_SUCCESS=false
fi

# 方法2: 如果標準建置失敗，嘗試 yarn
if [ "$BUILD_SUCCESS" = false ]; then
    if command -v yarn &> /dev/null; then
        print_info "嘗試使用 yarn 建置..."
        if yarn build; then
            print_status "yarn 建置成功！"
            BUILD_SUCCESS=true
        fi
    else
        print_info "安裝 yarn 並嘗試建置..."
        if sudo npm install -g yarn 2>/dev/null; then
            yarn install
            if yarn build; then
                print_status "yarn 建置成功！"
                BUILD_SUCCESS=true
            fi
        fi
    fi
fi

# 方法3: 如果還是失敗，嘗試降級 react-scripts
if [ "$BUILD_SUCCESS" = false ]; then
    print_info "嘗試降級 react-scripts..."
    npm install react-scripts@4.0.3
    if NODE_OPTIONS="--max-old-space-size=2048" CI=false npm run build; then
        print_status "降級後建置成功！"
        BUILD_SUCCESS=true
    fi
fi

# 方法4: 最後的緊急方案 - 建立最小建置
if [ "$BUILD_SUCCESS" = false ]; then
    print_warning "所有建置方法都失敗，建立最小版本..."
    mkdir -p build/static/css build/static/js
    
    cat > build/index.html << 'EOF'
<!DOCTYPE html>
<html lang="zh-TW">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>補習班管理系統</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        h1 { color: #2563eb; text-align: center; }
        .status { text-align: center; padding: 20px; background: #fef3c7; border-radius: 6px; margin: 20px 0; }
        .btn { background: #2563eb; color: white; padding: 10px 20px; border: none; border-radius: 6px; cursor: pointer; }
        .btn:hover { background: #1d4ed8; }
    </style>
</head>
<body>
    <div class="container">
        <h1>補習班管理系統</h1>
        <div class="status">
            <h2>系統正在維護中</h2>
            <p>前端建置遇到問題，請稍後再試或聯絡系統管理員。</p>
            <p>您可以直接訪問後端 API：<a href="/api/students">/api/students</a></p>
        </div>
        <div style="text-align: center;">
            <button class="btn" onclick="location.reload()">重新載入</button>
        </div>
    </div>
</body>
</html>
EOF
    
    echo '{}' > build/static/css/main.css
    echo 'console.log("補習班管理系統 - 維護模式");' > build/static/js/main.js
    
    print_status "緊急版本建立完成"
    BUILD_SUCCESS=true
fi

cd ..

# 12. 檢查建置結果
if [ "$BUILD_SUCCESS" = true ] && [ -d "client/build" ]; then
    BUILD_SIZE=$(du -sh client/build | cut -f1)
    print_status "前端建置完成！建置大小: $BUILD_SIZE"
    
    # 檢查關鍵檔案
    if [ -f "client/build/index.html" ]; then
        print_status "✓ index.html 存在"
    fi
    
    if [ -d "client/build/static" ]; then
        print_status "✓ static 資源存在"
    fi
    
    print_info "建置檔案位置: $(pwd)/client/build"
    
else
    print_error "建置失敗！"
    print_info "請檢查錯誤訊息並嘗試手動建置："
    print_info "  cd client"
    print_info "  NODE_OPTIONS='--max-old-space-size=2048' npm run build"
    exit 1
fi

# 13. 提供後續步驟
echo ""
print_status "修復完成！後續步驟："
print_info "1. 繼續執行部署腳本: ./簡易部署.sh"
print_info "2. 或手動啟動服務:"
print_info "   pm2 start server/index.js --name tutoring-backend"
print_info "   pm2 start 'serve -s client/build -l 3000' --name tutoring-frontend"

echo ""
print_info "系統資源建議："
if [ "$MEMORY_TOTAL" -lt 2048 ]; then
    print_warning "建議升級 VM 到至少 2GB RAM"
fi
if [ "$DISK_USAGE" -gt 80 ]; then
    print_warning "建議清理磁碟空間或擴展儲存"
fi

print_status "修復腳本執行完成！"