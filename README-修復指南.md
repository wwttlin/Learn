# 📚 補習班管理系統 - 完整修復指南

## 🎯 你遇到什麼問題？

| 問題 | 解決方案 | 文檔 |
|------|---------|------|
| 🔴 新增學生失敗 | `./一鍵修復.sh` | [快速修復指南](./快速修復指南.md) |
| 🌐 Nginx 有問題 | `./setup-nginx.sh` | [Nginx快速參考](./Nginx快速參考.md) |
| 🔍 不知道問題在哪 | `./diagnose-api.sh` | [修復工具說明](./修復工具說明.md) |
| 📖 需要詳細說明 | 看下面的文檔列表 | - |

---

## ⚡ 最快的解決方法

### 在 Windows 上

1. 上傳修復檔案：
   ```cmd
   upload-fix.bat
   ```

### 在 Ubuntu 伺服器上

2. 一鍵修復所有問題：
   ```bash
   chmod +x 一鍵修復.sh
   ./一鍵修復.sh
   ```

**就這麼簡單！** 90% 的問題都能自動解決。

---

## 📁 所有工具和文檔

### 🛠️ 修復工具

| 工具 | 用途 | 執行時間 |
|------|------|---------|
| `一鍵修復.sh` ⭐ | 修復所有問題 | 5-10 分鐘 |
| `setup-nginx.sh` | 配置 Nginx（保留 SSL） | 1-2 分鐘 |
| `fix-nginx.sh` | 診斷 Nginx 問題 | 30 秒 |
| `update-frontend.sh` | 更新前端 | 3-5 分鐘 |
| `diagnose-api.sh` | 完整診斷 | 1 分鐘 |
| `manage.sh` | 日常管理 | 即時 |
| `upload-fix.bat` | Windows 上傳工具 | 1-2 分鐘 |

### 📖 文檔指南

| 文檔 | 內容 | 適合 |
|------|------|------|
| [快速修復指南](./快速修復指南.md) | 快速參考卡片 | ⭐ 所有人 |
| [Nginx快速參考](./Nginx快速參考.md) | Nginx 快速配置 | Nginx 問題 |
| [Nginx設定指南](./Nginx設定指南.md) | Nginx 詳細說明 | 深入了解 |
| [修復工具說明](./修復工具說明.md) | 所有工具說明 | 工具選擇 |
| [修復新增學生問題](./修復新增學生問題.md) | 新增學生問題詳解 | API 問題 |

---

## 🚀 快速開始

### 步驟 1: 上傳代碼（Windows）

```cmd
REM 雙擊執行
upload-fix.bat
```

### 步驟 2: 修復問題（Ubuntu）

```bash
# SSH 連接到伺服器
ssh user@your-server-ip

# 進入專案目錄
cd ~/tutoring-system

# 一鍵修復
chmod +x 一鍵修復.sh
./一鍵修復.sh
```

### 步驟 3: 測試

打開瀏覽器訪問 `http://你的伺服器IP`，測試新增學生功能。

---

## 🎓 常見問題 FAQ

### Q1: 新增學生時顯示「操作失敗」

**A**: 執行一鍵修復
```bash
./一鍵修復.sh
```

### Q2: Nginx 無法啟動

**A**: 重新配置 Nginx
```bash
./setup-nginx.sh
```

### Q3: 不確定問題在哪

**A**: 執行診斷
```bash
./diagnose-api.sh
```

### Q4: 已有 Let's Encrypt SSL，會被覆蓋嗎？

**A**: 不會！`setup-nginx.sh` 會自動檢測並保留你的 SSL 設定。

### Q5: 如何查看日誌？

**A**: 
```bash
pm2 logs                    # PM2 日誌
sudo tail -f /var/log/nginx/error.log  # Nginx 日誌
```

### Q6: 如何重啟服務？

**A**:
```bash
./manage.sh restart         # 重啟所有服務
pm2 restart all             # 只重啟 PM2 服務
sudo systemctl restart nginx # 只重啟 Nginx
```

---

## 🔧 日常維護命令

```bash
# 查看狀態
./manage.sh status
pm2 list
sudo systemctl status nginx

# 查看日誌
./manage.sh logs
pm2 logs
sudo tail -f /var/log/nginx/tutoring-system.error.log

# 重啟服務
./manage.sh restart
pm2 restart all
sudo systemctl restart nginx

# 備份資料庫
./manage.sh backup

# 診斷問題
./diagnose-api.sh
./fix-nginx.sh
```

---

## 📊 工具選擇流程圖

```
遇到問題
    │
    ├─ 不確定問題？ → ./diagnose-api.sh
    │
    ├─ 新增學生失敗？ → ./一鍵修復.sh
    │
    ├─ Nginx 問題？
    │   ├─ 快速診斷 → ./fix-nginx.sh
    │   └─ 重新配置 → ./setup-nginx.sh
    │
    ├─ 只需更新前端？ → ./update-frontend.sh
    │
    └─ 所有問題？ → ./一鍵修復.sh ⭐
```

---

## 🎯 推薦工作流程

### 首次部署

```bash
# 1. 部署應用
./簡易部署.sh

# 2. 配置 Nginx
./setup-nginx.sh

# 3. 診斷檢查
./diagnose-api.sh
```

### 日常更新

```bash
# 方案 A: 一鍵更新（推薦）
./一鍵修復.sh

# 方案 B: 只更新前端
./update-frontend.sh
pm2 restart all
```

### 問題排查

```bash
# 1. 診斷問題
./diagnose-api.sh

# 2. 根據診斷結果選擇工具
./fix-nginx.sh          # Nginx 問題
./update-frontend.sh    # 前端問題
pm2 restart all         # 服務問題

# 3. 如果還是不行
./一鍵修復.sh
```

---

## 💡 最佳實踐

1. **定期備份**
   ```bash
   ./manage.sh backup
   ```

2. **監控日誌**
   ```bash
   pm2 logs
   ```

3. **更新前先診斷**
   ```bash
   ./diagnose-api.sh
   ```

4. **保持工具可執行**
   ```bash
   chmod +x *.sh
   ```

5. **遇到問題先用一鍵修復**
   ```bash
   ./一鍵修復.sh
   ```

---

## 🆘 需要幫助？

### 收集診斷資訊

```bash
# 1. 執行診斷
./diagnose-api.sh > diagnosis.txt

# 2. 收集日誌
pm2 logs --lines 100 > pm2-logs.txt
sudo tail -100 /var/log/nginx/error.log > nginx-logs.txt

# 3. 檢查瀏覽器 Console (F12)
```

### 提供資訊

- `diagnosis.txt` - 系統診斷報告
- `pm2-logs.txt` - PM2 服務日誌
- `nginx-logs.txt` - Nginx 錯誤日誌
- 瀏覽器 Console 截圖

---

## 📞 聯絡資訊

如果所有方法都無法解決問題，請提供：

1. 診斷報告 (`./diagnose-api.sh`)
2. 錯誤日誌
3. 瀏覽器 Console 錯誤
4. 你執行的步驟

---

## 🎉 成功標誌

修復成功後，你應該能夠：

- ✅ 訪問 `http://你的伺服器IP`
- ✅ 成功新增學生
- ✅ 看到具體的錯誤訊息（如果有錯誤）
- ✅ 所有 API 請求正常工作

---

## 📝 版本資訊

- **最後更新**: 2024-12-12
- **適用版本**: 補習班管理系統 v1.0
- **支援系統**: Ubuntu 20.04+, Debian 10+

---

## 🌟 快速命令速查表

```bash
# 最常用的 5 個命令
./一鍵修復.sh              # 1. 修復所有問題 ⭐
./diagnose-api.sh         # 2. 診斷問題
./setup-nginx.sh          # 3. 配置 Nginx
./manage.sh status        # 4. 查看狀態
pm2 logs                  # 5. 查看日誌
```

---

**記住：遇到問題先執行 `./一鍵修復.sh`！**

這個腳本會自動：
- ✅ 檢查並修復 Nginx
- ✅ 更新前端應用
- ✅ 重啟所有服務
- ✅ 執行完整診斷

90% 的問題都能自動解決！🎉
