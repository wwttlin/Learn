# Nginx 設定指南

## 🎯 適用情況

如果你的 Nginx 已經有 Let's Encrypt SSL 證書，部署後出現問題，使用這個指南。

## 🚀 快速修復（推薦）

### 方法 1: 使用自動配置腳本

在 Ubuntu 伺服器上執行：

```bash
chmod +x setup-nginx.sh
./setup-nginx.sh
```

腳本會：
- ✅ 自動檢測你的 SSL 證書
- ✅ 保留現有的 Let's Encrypt 設定
- ✅ 建立正確的 API 轉發配置
- ✅ 備份舊配置
- ✅ 測試並重啟 Nginx

### 方法 2: 使用快速診斷腳本

```bash
chmod +x fix-nginx.sh
./fix-nginx.sh
```

這會檢查所有問題並給出修復建議。

## 📝 手動配置（進階）

如果你想手動配置，按照以下步驟：

### 1. 備份現有配置

```bash
sudo cp /etc/nginx/sites-available/tutoring-system /etc/nginx/sites-available/tutoring-system.backup
```

### 2. 編輯配置檔案

```bash
sudo nano /etc/nginx/sites-available/tutoring-system
```

### 3. 配置範例

#### 如果你有 HTTPS (Let's Encrypt)

```nginx
# HTTP - 重定向到 HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name your-domain.com www.your-domain.com;
    
    # Let's Encrypt 驗證
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }
    
    # 重定向到 HTTPS
    location / {
        return 301 https://$server_name$request_uri;
    }
}

# HTTPS - 主要配置
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name your-domain.com www.your-domain.com;
    
    # SSL 證書（Let's Encrypt 自動管理）
    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
    
    # SSL 設定
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    
    # 安全標頭
    add_header Strict-Transport-Security "max-age=31536000" always;
    
    # 日誌
    access_log /var/log/nginx/tutoring-system.access.log;
    error_log /var/log/nginx/tutoring-system.error.log;
    
    # Gzip 壓縮
    gzip on;
    gzip_types text/plain text/css application/javascript application/json;
    
    # 🔑 重點：後端 API 轉發
    location /api {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        client_max_body_size 10M;
    }
    
    # 🔑 重點：前端轉發
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

#### 如果只有 HTTP

```nginx
server {
    listen 80;
    server_name your-domain.com;
    
    # 日誌
    access_log /var/log/nginx/tutoring-system.access.log;
    error_log /var/log/nginx/tutoring-system.error.log;
    
    # Gzip 壓縮
    gzip on;
    gzip_types text/plain text/css application/javascript application/json;
    
    # 後端 API 轉發
    location /api {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        client_max_body_size 10M;
    }
    
    # 前端轉發
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### 4. 測試配置

```bash
sudo nginx -t
```

### 5. 重啟 Nginx

```bash
sudo systemctl restart nginx
```

## 🔍 診斷問題

### 檢查 Nginx 狀態

```bash
sudo systemctl status nginx
```

### 查看錯誤日誌

```bash
sudo tail -f /var/log/nginx/error.log
```

### 查看應用日誌

```bash
sudo tail -f /var/log/nginx/tutoring-system.error.log
```

### 測試 API 轉發

```bash
# 直接訪問後端
curl http://localhost:5000/api/students

# 通過 Nginx 訪問
curl http://localhost/api/students
```

## ⚠️ 常見問題

### 問題 1: 502 Bad Gateway

**原因**: 後端服務未運行

**解決**:
```bash
pm2 list
pm2 restart tutoring-backend
```

### 問題 2: 404 Not Found (訪問 /api)

**原因**: Nginx 配置缺少 API 轉發

**解決**:
```bash
./setup-nginx.sh
```

### 問題 3: SSL 證書錯誤

**原因**: 證書路徑不正確或已過期

**解決**:
```bash
# 檢查證書
sudo certbot certificates

# 更新證書
sudo certbot renew

# 重新配置
./setup-nginx.sh
```

### 問題 4: 配置測試失敗

**原因**: 語法錯誤或路徑錯誤

**解決**:
```bash
# 查看詳細錯誤
sudo nginx -t

# 恢復備份
sudo cp /etc/nginx/sites-available/tutoring-system.backup /etc/nginx/sites-available/tutoring-system
sudo systemctl restart nginx
```

## 🔧 維護命令

```bash
# 重啟 Nginx
sudo systemctl restart nginx

# 重新載入配置（不中斷服務）
sudo systemctl reload nginx

# 查看狀態
sudo systemctl status nginx

# 測試配置
sudo nginx -t

# 查看訪問日誌
sudo tail -f /var/log/nginx/tutoring-system.access.log

# 查看錯誤日誌
sudo tail -f /var/log/nginx/tutoring-system.error.log
```

## 📋 配置檔案位置

- **主配置**: `/etc/nginx/nginx.conf`
- **站點配置**: `/etc/nginx/sites-available/tutoring-system`
- **啟用的站點**: `/etc/nginx/sites-enabled/tutoring-system`
- **訪問日誌**: `/var/log/nginx/tutoring-system.access.log`
- **錯誤日誌**: `/var/log/nginx/tutoring-system.error.log`
- **SSL 證書**: `/etc/letsencrypt/live/your-domain.com/`

## 🎓 Let's Encrypt 證書管理

### 查看證書狀態

```bash
sudo certbot certificates
```

### 更新證書

```bash
sudo certbot renew
```

### 測試自動更新

```bash
sudo certbot renew --dry-run
```

### 重新申請證書

```bash
sudo certbot --nginx -d your-domain.com -d www.your-domain.com
```

## 💡 最佳實踐

1. **定期備份配置**
   ```bash
   sudo cp /etc/nginx/sites-available/tutoring-system ~/nginx-backup-$(date +%Y%m%d).conf
   ```

2. **監控日誌**
   ```bash
   # 設定日誌輪替
   sudo nano /etc/logrotate.d/nginx
   ```

3. **測試後再重啟**
   ```bash
   sudo nginx -t && sudo systemctl reload nginx
   ```

4. **使用 reload 而非 restart**
   ```bash
   # reload 不會中斷現有連接
   sudo systemctl reload nginx
   ```

## 🆘 緊急恢復

如果 Nginx 完全無法啟動：

```bash
# 1. 停止 Nginx
sudo systemctl stop nginx

# 2. 移除問題配置
sudo rm /etc/nginx/sites-enabled/tutoring-system

# 3. 使用預設配置
sudo ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/

# 4. 啟動 Nginx
sudo systemctl start nginx

# 5. 重新配置
./setup-nginx.sh
```

## 📞 需要幫助？

執行完整診斷：
```bash
./diagnose-api.sh
```

這會檢查所有服務並給出詳細報告。
