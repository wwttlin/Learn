#!/bin/bash

# 快速部署腳本 - 補習班管理系統
# 簡化版本，專注於核心功能

echo "⚡ 快速部署腳本 - 補習班管理系統"
echo "================================"

# 基本檢查
if ! command -v node >/dev/null 2>&1; then
    echo "❌ 找不到 Node.js，請先安裝"
    exit 1
fi

if ! command -v npm >/dev/null 2>&1; then
    echo "❌ 找不到 npm"
    exit 1
fi

echo "✅ Node.js $(node --version) 已安裝"
echo "✅ npm $(npm --version) 已安裝"

# 停止現有服務
echo "🛑 停止現有服務..."
pkill -f "node.*server/index.js" 2>/dev/null || true
pm2 delete all 2>/dev/null || true

# 安裝依賴
echo "📦 安裝依賴..."
npm install

# 初始化資料庫
echo "🗄️ 初始化資料庫..."
node init-database.js

# 檢查資料庫
if [ ! -f "tutoring.db" ]; then
    echo "❌ 資料庫建立失敗"
    exit 1
fi

echo "✅ 資料庫建立成功"

# 建立環境變數
echo "⚙️ 設定環境變數..."
cat > .env << 'EOF'
NODE_ENV=production
PORT=5000
HOST=0.0.0.0
EOF

# 測試服務
echo "🧪 測試服務..."
timeout 10s node server/index.js &
TEST_PID=$!
sleep 5

if kill -0 $TEST_PID 2>/dev/null; then
    echo "✅ 服務測試成功"
    kill $TEST_PID 2>/dev/null || true
else
    echo "❌ 服務測試失敗"
    exit 1
fi

# 啟動服務
echo "🚀 啟動服務..."
if command -v pm2 >/dev/null 2>&1; then
    pm2 start server/index.js --name "tutoring-backend"
    echo "✅ 使用 PM2 啟動完成"
    echo "📋 管理命令: pm2 status, pm2 logs, pm2 restart all"
else
    nohup node server/index.js > server.log 2>&1 &
    echo $! > server.pid
    echo "✅ 使用 nohup 啟動完成"
    echo "📋 管理命令: cat server.log, kill \$(cat server.pid)"
fi

# 最終檢查
sleep 3
if curl -s --connect-timeout 5 "http://localhost:5000/api/students" >/dev/null 2>&1; then
    echo "🎉 部署成功！API 正常運行"
else
    echo "⚠️ 部署完成，但 API 測試失敗，請檢查日誌"
fi

echo ""
echo "📋 服務資訊:"
echo "  API 地址: http://localhost:5000"
echo "  測試命令: curl http://localhost:5000/api/students"
echo "  診斷工具: node diagnose-db.js"
echo ""