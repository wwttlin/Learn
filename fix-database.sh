#!/bin/bash

# 資料庫修復腳本
# 專門解決「新增學生資料操作失敗」問題

echo "🔧 資料庫修復腳本"
echo "================"

# 1. 備份現有資料庫
if [ -f "tutoring.db" ]; then
    echo "📋 備份現有資料庫..."
    cp tutoring.db "tutoring.db.backup.$(date +%Y%m%d_%H%M%S)"
    echo "✅ 資料庫已備份"
fi

# 2. 停止服務
echo "🛑 停止服務..."
pkill -f "node.*server/index.js" 2>/dev/null || true
pm2 stop all 2>/dev/null || true

# 3. 重新初始化資料庫
echo "🗄️ 重新初始化資料庫..."
rm -f tutoring.db
node init-database.js

# 4. 檢查資料庫
if [ -f "tutoring.db" ]; then
    echo "✅ 資料庫重建成功"
    chmod 664 tutoring.db 2>/dev/null || chmod 644 tutoring.db
    echo "✅ 權限設定完成"
else
    echo "❌ 資料庫重建失敗"
    exit 1
fi

# 5. 診斷資料庫
echo "🔍 診斷資料庫..."
node diagnose-db.js

# 6. 測試資料庫操作
echo "🧪 測試資料庫操作..."
node -e "
const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('./tutoring.db');

db.run('INSERT INTO students (name, phone, email) VALUES (?, ?, ?)', 
  ['測試學生', '0912345678', 'test@example.com'], 
  function(err) {
    if (err) {
      console.log('❌ 測試插入失敗:', err.message);
      process.exit(1);
    } else {
      console.log('✅ 測試插入成功，ID:', this.lastID);
      
      // 清理測試資料
      db.run('DELETE FROM students WHERE id = ?', [this.lastID], (err) => {
        if (err) {
          console.log('⚠️ 清理測試資料失敗');
        } else {
          console.log('✅ 測試資料已清理');
        }
        db.close();
      });
    }
  }
);
"

# 7. 重啟服務
echo "🚀 重啟服務..."
if command -v pm2 >/dev/null 2>&1; then
    pm2 restart all 2>/dev/null || pm2 start server/index.js --name "tutoring-backend"
    echo "✅ PM2 服務已重啟"
else
    nohup node server/index.js > server.log 2>&1 &
    echo $! > server.pid
    echo "✅ 服務已重啟"
fi

# 8. 最終測試
sleep 3
echo "🧪 最終 API 測試..."
if curl -s --connect-timeout 5 "http://localhost:5000/api/students" >/dev/null 2>&1; then
    echo "🎉 修復成功！API 正常運行"
    echo ""
    echo "📋 現在可以嘗試新增學生資料了"
else
    echo "❌ API 仍然無法訪問，請檢查服務日誌"
    if [ -f "server.log" ]; then
        echo "📋 最近的日誌:"
        tail -10 server.log
    fi
fi

echo ""
echo "💡 如果問題仍然存在:"
echo "  1. 檢查日誌: pm2 logs 或 cat server.log"
echo "  2. 重新部署: ./quick-deploy.sh"
echo "  3. 診斷資料庫: node diagnose-db.js"