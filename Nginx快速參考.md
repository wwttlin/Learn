# 🌐 Nginx 快速參考

## ⚡ 最快速的方法

```bash
# 在 Ubuntu 伺服器上執行
chmod +x setup-nginx.sh
./setup-nginx.sh
```

腳本會自動：
- ✅ 檢測你的 SSL 證書
- ✅ 保留 Let's Encrypt 設定
- ✅ 配置 API 轉發
- ✅ 測試並重啟

---

## 🔍 診斷問題

```bash
./fix-nginx.sh
```

---

## 📝 手動配置（如果自動腳本失敗）

### 1. 編輯配置

```bash
sudo nano /etc/nginx/sites-available/tutoring-system
```

### 2. 關鍵配置（複製貼上）

在你現有的 `server` 區塊中，確保有這兩個 `location`：

```nginx
# 後端 API 轉發
location /api {
    proxy_pass http://localhost:5000;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    client_max_body_size 10M;
}

# 前端轉發
location / {
    proxy_pass http://localhost:3000;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

### 3. 測試並重啟

```bash
sudo nginx -t
sudo systemctl restart nginx
```

---

## 🔧 常用命令

```bash
# 測試配置
sudo nginx -t

# 重啟 Nginx
sudo systemctl restart nginx

# 查看狀態
sudo systemctl status nginx

# 查看錯誤日誌
sudo tail -f /var/log/nginx/error.log

# 查看應用日誌
sudo tail -f /var/log/nginx/tutoring-system.error.log
```

---

## ⚠️ 常見錯誤

### 錯誤 1: `nginx: [emerg] bind() to 0.0.0.0:80 failed`

**原因**: 端口被佔用

**解決**:
```bash
# 查看誰在使用 80 端口
sudo lsof -i :80

# 停止衝突的服務
sudo systemctl stop apache2  # 如果是 Apache
```

### 錯誤 2: `502 Bad Gateway`

**原因**: 後端服務未運行

**解決**:
```bash
pm2 list
pm2 restart tutoring-backend
```

### 錯誤 3: SSL 證書錯誤

**原因**: 證書路徑不正確

**解決**:
```bash
# 查看證書
sudo certbot certificates

# 重新配置
./setup-nginx.sh
```

---

## 📋 完整配置範例

### 有 HTTPS 的配置

```nginx
# HTTP -> HTTPS 重定向
server {
    listen 80;
    server_name your-domain.com;
    
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }
    
    location / {
        return 301 https://$server_name$request_uri;
    }
}

# HTTPS 主配置
server {
    listen 443 ssl http2;
    server_name your-domain.com;
    
    # SSL 證書
    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
    
    # 後端 API
    location /api {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        client_max_body_size 10M;
    }
    
    # 前端
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### 只有 HTTP 的配置

```nginx
server {
    listen 80;
    server_name _;
    
    # 後端 API
    location /api {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        client_max_body_size 10M;
    }
    
    # 前端
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

---

## 🎯 測試步驟

```bash
# 1. 測試後端
curl http://localhost:5000/api/students

# 2. 測試前端
curl http://localhost:3000

# 3. 測試 Nginx 轉發
curl http://localhost/api/students

# 4. 從外部測試
curl http://your-server-ip/api/students
```

---

## 💡 提示

1. **保留 Let's Encrypt 設定**: 使用 `./setup-nginx.sh` 會自動保留
2. **備份配置**: 腳本會自動備份到 `.backup` 檔案
3. **測試後再重啟**: 總是先執行 `sudo nginx -t`
4. **查看日誌**: 出問題時先看 `/var/log/nginx/error.log`

---

## 🆘 緊急恢復

如果完全無法啟動：

```bash
# 1. 停止 Nginx
sudo systemctl stop nginx

# 2. 恢復備份
sudo cp /etc/nginx/sites-available/tutoring-system.backup.* /etc/nginx/sites-available/tutoring-system

# 3. 測試
sudo nginx -t

# 4. 啟動
sudo systemctl start nginx

# 5. 重新配置
./setup-nginx.sh
```

---

記住：**使用 `./setup-nginx.sh` 是最簡單的方法！**
