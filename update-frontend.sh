#!/bin/bash

# 快速更新前端腳本
# 用於修復 API 路徑問題後重新部署前端

set -e

echo "🔄 更新前端應用..."

# 顏色定義
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[ℹ]${NC} $1"
}

# 檢查是否在專案目錄
if [ ! -d "client" ]; then
    echo "錯誤：找不到 client 目錄"
    exit 1
fi

# 進入前端目錄
cd client

print_info "清理舊的建置檔案..."
rm -rf build node_modules/.cache 2>/dev/null || true

print_info "安裝依賴..."
npm install

print_info "建置前端應用..."
export NODE_OPTIONS="--max-old-space-size=2048"
export CI=false
export GENERATE_SOURCEMAP=false

if npm run build; then
    print_status "前端建置成功"
else
    echo "建置失敗，請檢查錯誤訊息"
    exit 1
fi

cd ..

print_info "重啟前端服務..."
pm2 restart tutoring-frontend

print_status "前端更新完成！"
print_info "請稍等幾秒鐘讓服務完全啟動"

sleep 3

# 測試服務
if curl -s --max-time 5 "http://localhost:3000" > /dev/null 2>&1; then
    print_status "✅ 前端服務正常運行"
else
    echo "⚠️  前端服務可能需要更多時間啟動"
fi

echo ""
echo "完成！請重新整理瀏覽器測試新增學生功能"
