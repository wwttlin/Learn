# 🔧 Git Push 問題解決指南

## 🚨 常見 Git Push 失敗原因

### 1. 認證問題（最常見）
### 2. 網路/代理問題
### 3. 倉庫設定問題
### 4. 分支問題

---

## 🔍 診斷步驟

### 步驟1：查看具體錯誤訊息
```bash
git push -u origin main
# 請複製完整的錯誤訊息
```

### 步驟2：檢查 Git 配置
```bash
# 檢查用戶設定
git config --global user.name
git config --global user.email

# 檢查遠端倉庫
git remote -v
```

---

## 🔐 解決方案1：認證問題

### GitHub 已停用密碼認證（2021年8月後）

#### 方案A：使用 Personal Access Token（推薦）

1. **建立 Personal Access Token**：
   - 登入 GitHub
   - 右上角頭像 → Settings
   - 左側選單 → Developer settings
   - Personal access tokens → Tokens (classic)
   - Generate new token (classic)
   - 勾選 `repo` 權限
   - 複製生成的 token（只會顯示一次！）

2. **使用 Token 推送**：
   ```bash
   # 方法1：在 URL 中包含 token
   git remote set-url origin https://your-token@github.com/username/tutoring-system.git
   git push -u origin main
   
   # 方法2：推送時輸入認證
   git push -u origin main
   # Username: your-github-username
   # Password: your-personal-access-token
   ```

#### 方案B：使用 SSH 金鑰

1. **生成 SSH 金鑰**：
   ```bash
   ssh-keygen -t ed25519 -C "your-email@example.com"
   # 按 Enter 使用預設路徑
   # 可以設定密碼或直接按 Enter
   ```

2. **添加到 GitHub**：
   ```bash
   # 複製公鑰
   cat ~/.ssh/id_ed25519.pub
   # 或在 Windows：
   type %USERPROFILE%\.ssh\id_ed25519.pub
   ```
   - 登入 GitHub → Settings → SSH and GPG keys
   - New SSH key → 貼上公鑰內容

3. **更改遠端 URL 為 SSH**：
   ```bash
   git remote set-url origin git@github.com:username/tutoring-system.git
   git push -u origin main
   ```

---

## 🌐 解決方案2：網路/代理問題

### 檢查網路連接
```bash
# 測試 GitHub 連接
ping github.com
curl -I https://github.com
```

### 如果需要設定代理

#### HTTP/HTTPS 代理
```bash
# 設定全域代理
git config --global http.proxy http://proxy-server:port
git config --global https.proxy https://proxy-server:port

# 或只為 GitHub 設定代理
git config --global http.https://github.com.proxy http://proxy-server:port
```

#### SOCKS 代理
```bash
git config --global http.proxy socks5://proxy-server:port
```

#### 取消代理設定
```bash
git config --global --unset http.proxy
git config --global --unset https.proxy
```

### 公司網路/防火牆問題
```bash
# 嘗試使用 SSH 端口 443（繞過防火牆）
# 編輯 ~/.ssh/config 檔案
Host github.com
    Hostname ssh.github.com
    Port 443
    User git
```

---

## 📁 解決方案3：倉庫設定問題

### 檢查倉庫是否存在
1. 確認 GitHub 上已建立倉庫
2. 檢查倉庫名稱是否正確
3. 確認你有推送權限

### 重新設定遠端倉庫
```bash
# 移除現有遠端
git remote remove origin

# 重新添加（使用正確的 URL）
git remote add origin https://github.com/username/tutoring-system.git

# 或使用 SSH
git remote add origin git@github.com:username/tutoring-system.git
```

---

## 🌿 解決方案4：分支問題

### 檢查分支狀態
```bash
# 查看當前分支
git branch

# 查看所有分支
git branch -a

# 如果在 master 分支，改為 main
git branch -M main
```

### 首次推送到空倉庫
```bash
# 如果是全新倉庫
git push -u origin main

# 如果倉庫已有內容，需要先拉取
git pull origin main --allow-unrelated-histories
git push -u origin main
```

---

## 🔧 完整解決流程

### 流程1：使用 Personal Access Token（推薦）

```bash
# 1. 設定用戶資訊（如果還沒設定）
git config --global user.name "Your Name"
git config --global user.email "your-email@example.com"

# 2. 檢查遠端設定
git remote -v

# 3. 使用 token 設定遠端 URL
git remote set-url origin https://your-token@github.com/username/tutoring-system.git

# 4. 推送
git push -u origin main
```

### 流程2：使用 SSH 金鑰

```bash
# 1. 生成 SSH 金鑰（如果還沒有）
ssh-keygen -t ed25519 -C "your-email@example.com"

# 2. 啟動 SSH agent 並添加金鑰
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# 3. 測試 SSH 連接
ssh -T git@github.com

# 4. 設定 SSH 遠端 URL
git remote set-url origin git@github.com:username/tutoring-system.git

# 5. 推送
git push -u origin main
```

---

## 🚨 緊急替代方案

### 如果 Git 推送仍然失敗，使用其他上傳方式：

#### 方案A：手動上傳到 GitHub
1. 在 GitHub 建立新倉庫
2. 點擊 "uploading an existing file"
3. 將所有檔案拖拽上傳
4. 在 VM 上使用 `git clone` 下載

#### 方案B：使用 SCP 直接上傳
```bash
# 壓縮專案
tar -czf tutoring-system.tar.gz tutoring-system/

# 上傳到 VM
scp tutoring-system.tar.gz username@vm-ip:~/

# 在 VM 上解壓
ssh username@vm-ip
tar -xzf tutoring-system.tar.gz
cd tutoring-system
./簡易部署.sh
```

#### 方案C：使用 WinSCP（Windows）
1. 下載 [WinSCP](https://winscp.net/)
2. 連接到 VM
3. 直接拖拽上傳整個資料夾

---

## 🔍 除錯命令

### 查看詳細錯誤
```bash
# 啟用詳細輸出
GIT_CURL_VERBOSE=1 git push -u origin main

# 或
git push -u origin main --verbose
```

### 檢查 Git 配置
```bash
# 查看所有配置
git config --list

# 查看特定配置
git config --get remote.origin.url
git config --get user.name
git config --get user.email
```

### 重置 Git 狀態
```bash
# 如果需要重新開始
rm -rf .git
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/username/tutoring-system.git
git push -u origin main
```

---

## 💡 小技巧

### 1. 儲存認證資訊
```bash
# 儲存認證（避免重複輸入）
git config --global credential.helper store
```

### 2. 設定預設分支
```bash
# 設定預設分支為 main
git config --global init.defaultBranch main
```

### 3. 檢查網路問題
```bash
# 測試 HTTPS 連接
curl -v https://github.com

# 測試 SSH 連接
ssh -vT git@github.com
```

請告訴我具體的錯誤訊息，我可以提供更精確的解決方案！🔧