# Ubuntu 部署問題排除指南

## 🚨 常見問題：新增學生資料操作失敗

### 問題症狀
- 前端顯示「操作失敗」
- 無法新增學生、課程或繳費資料
- API 回傳 500 錯誤

### 🔍 診斷步驟

#### 1. 快速診斷
```bash
# 執行資料庫診斷工具
node diagnose-db.js
```

#### 2. 檢查資料庫檔案
```bash
# 檢查資料庫檔案是否存在
ls -la tutoring.db

# 如果不存在，初始化資料庫
node init-database.js
```

#### 3. 檢查服務狀態
```bash
# 檢查後端服務是否運行
pm2 status
# 或
ps aux | grep node

# 查看服務日誌
pm2 logs
# 或
cat server.log
```

#### 4. 測試 API 連接
```bash
# 測試學生 API
curl -X GET http://localhost:5000/api/students

# 測試新增學生
curl -X POST http://localhost:5000/api/students \
  -H "Content-Type: application/json" \
  -d '{"name":"測試學生","phone":"0912345678","email":"test@example.com"}'
```

### 🛠️ 解決方案

#### 方案 1: 重新初始化資料庫
```bash
# 停止服務
pm2 stop all

# 備份現有資料庫（如果有重要資料）
cp tutoring.db tutoring.db.backup

# 重新初始化資料庫
node init-database.js

# 重啟服務
pm2 restart all
```

#### 方案 2: 完整重新部署
```bash
# 執行完整部署腳本
chmod +x deploy-ubuntu.sh
./deploy-ubuntu.sh
```

#### 方案 3: 手動修復權限
```bash
# 修復資料庫檔案權限
chmod 664 tutoring.db
chown $USER:$USER tutoring.db

# 確保目錄權限正確
chmod 755 .
```

### 🔧 常見錯誤及解決方法

#### 錯誤 1: `SQLITE_CANTOPEN: unable to open database file`
**原因**: 資料庫檔案不存在或權限不足
**解決**: 
```bash
node init-database.js
chmod 664 tutoring.db
```

#### 錯誤 2: `SQLITE_ERROR: no such table: students`
**原因**: 資料表未建立
**解決**: 
```bash
node init-database.js
```

#### 錯誤 3: `Cannot read property 'lastID' of undefined`
**原因**: 資料庫連接問題
**解決**: 
```bash
# 檢查 SQLite3 模組
npm install sqlite3
node diagnose-db.js
```

#### 錯誤 4: `EADDRINUSE: address already in use :::5000`
**原因**: 端口被占用
**解決**: 
```bash
# 找出占用端口的進程
sudo lsof -i :5000

# 終止進程
sudo kill -9 <PID>

# 或使用不同端口
export PORT=5001
```

### 📋 預防措施

#### 1. 定期備份
```bash
# 建立備份腳本
cat > backup-db.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
cp tutoring.db "backups/tutoring_${DATE}.db"
echo "資料庫已備份到: backups/tutoring_${DATE}.db"
EOF

chmod +x backup-db.sh
mkdir -p backups
```

#### 2. 監控腳本
```bash
# 建立監控腳本
cat > monitor.sh << 'EOF'
#!/bin/bash
while true; do
    if ! curl -s http://localhost:5000/api/students > /dev/null; then
        echo "$(date): API 無回應，重啟服務..."
        pm2 restart all
    fi
    sleep 60
done
EOF

chmod +x monitor.sh
```

#### 3. 系統服務設定
```bash
# 設定 PM2 開機自啟
pm2 startup
pm2 save
```

### 🚀 完整部署檢查清單

- [ ] Node.js 已安裝 (v14+)
- [ ] npm 依賴已安裝
- [ ] 資料庫已初始化
- [ ] 資料庫檔案權限正確
- [ ] 後端服務正常啟動
- [ ] API 端點可正常訪問
- [ ] 防火牆規則已設定
- [ ] PM2 已設定開機自啟
- [ ] 備份機制已建立

### 📞 緊急修復指令

如果系統完全無法運作，執行以下指令進行緊急修復：

```bash
# 緊急修復一鍵腳本
curl -sSL https://raw.githubusercontent.com/wwttlin/Learn/main/deploy-ubuntu.sh | bash
```

或手動執行：

```bash
# 1. 停止所有服務
pm2 delete all
sudo pkill -9 -f node

# 2. 重新安裝依賴
npm install

# 3. 重新初始化資料庫
rm -f tutoring.db
node init-database.js

# 4. 重新啟動服務
pm2 start server/index.js --name "tutoring-backend"
pm2 save

# 5. 測試服務
sleep 5
curl http://localhost:5000/api/students
```

### 📧 技術支援

如果問題仍然存在，請提供以下資訊：

1. 系統資訊: `uname -a`
2. Node.js 版本: `node --version`
3. 錯誤日誌: `pm2 logs` 或 `cat server.log`
4. 診斷結果: `node diagnose-db.js`
5. 資料庫狀態: `ls -la tutoring.db`