#!/bin/bash

# 快速修復建置問題的腳本

echo "🚀 快速修復建置問題..."

# 1. 停止卡住的進程
echo "停止可能卡住的進程..."
sudo pkill -f "react-scripts build" 2>/dev/null || true
sudo pkill -f "webpack" 2>/dev/null || true
sudo pkill -f "node.*build" 2>/dev/null || true

# 2. 檢查記憶體並建立 swap（如果需要）
MEMORY=$(free -m | awk 'NR==2{print $2}')
SWAP=$(free -m | awk 'NR==3{print $2}')

echo "記憶體: ${MEMORY}MB, Swap: ${SWAP}MB"

if [ "$MEMORY" -lt 2048 ] && [ "$SWAP" -eq 0 ]; then
    echo "記憶體不足，建立 swap..."
    sudo fallocate -l 1G /swapfile 2>/dev/null || sudo dd if=/dev/zero of=/swapfile bs=1M count=1024
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo "Swap 建立完成"
fi

# 3. 設定環境變數並重新建置
cd client
echo "清理快取..."
npm cache clean --force
rm -rf node_modules/.cache 2>/dev/null || true

echo "重新建置..."
NODE_OPTIONS="--max-old-space-size=2048" CI=false GENERATE_SOURCEMAP=false npm run build

if [ $? -eq 0 ]; then
    echo "✅ 建置成功！"
else
    echo "❌ 建置失敗，請執行完整修復腳本: ./fix-build.sh"
fi

cd ..