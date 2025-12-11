# 🪟 Windows 用戶部署指南

## 🎯 適用對象
- Windows 10/11 用戶
- 沒有安裝 gcloud CLI
- 想要將專案部署到 GCP Ubuntu VM

## 📋 準備工作

### 1. 獲取 VM 資訊
1. 登入 [GCP Console](https://console.cloud.google.com/)
2. 進入 **Compute Engine > VM 執行個體**
3. 記錄你的 VM 資訊：
   - **外部 IP**：例如 `34.80.123.456`
   - **用戶名**：通常是你的 Google 帳號名稱前綴
   - **SSH 連接方式**

### 2. 設定 SSH 連接（選擇一種方式）

#### 方式A：使用 GCP 網頁 SSH
1. 在 VM 列表中點擊 **SSH** 按鈕
2. 會開啟瀏覽器 SSH 終端
3. 這是最簡單的方式，無需額外設定

#### 方式B：使用 Windows SSH 客戶端
1. 開啟 **PowerShell** 或 **命令提示字元**
2. 測試連接：
   ```cmd
   ssh username@your-vm-ip
   ```
3. 首次連接會要求確認，輸入 `yes`

---

## 🚀 方案1：使用 Git（最推薦）

### 步驟1：建立 GitHub 倉庫
1. 登入 [GitHub](https://github.com/)
2. 點擊 **New repository**
3. 倉庫名稱：`tutoring-system`
4. 設為 **Public**（或 Private）
5. 點擊 **Create repository**

### 步驟2：上傳專案到 GitHub
```cmd
# 在專案目錄開啟 PowerShell
cd C:\path\to\your\tutoring-system

# 初始化 Git（如果還沒有）
git init

# 添加所有檔案
git add .

# 提交
git commit -m "補習班管理系統初始版本"

# 連接到 GitHub（替換為你的倉庫 URL）
git remote add origin https://github.com/your-username/tutoring-system.git

# 推送到 GitHub
git push -u origin main
```

### 步驟3：在 VM 上部署
1. **SSH 連接到 VM**（使用 GCP 網頁 SSH 或 PowerShell）
2. **下載專案**：
   ```bash
   git clone https://github.com/your-username/tutoring-system.git
   cd tutoring-system
   ```
3. **執行部署**：
   ```bash
   chmod +x 簡易部署.sh
   ./簡易部署.sh
   ```

---

## 📁 方案2：使用 WinSCP（圖形界面）

### 步驟1：下載安裝 WinSCP
1. 前往 [WinSCP 官網](https://winscp.net/eng/download.php)
2. 下載並安裝 WinSCP

### 步驟2：連接到 VM
1. 開啟 WinSCP
2. 新增連接：
   - **檔案協定**：SFTP
   - **主機名稱**：你的 VM 外部 IP
   - **端口**：22
   - **用戶名**：你的 VM 用戶名
   - **密碼**：（如果有設定密碼）

### 步驟3：上傳專案
1. 左側視窗：導航到你的專案資料夾
2. 右側視窗：導航到 `/home/username/`
3. 將整個 `tutoring-system` 資料夾拖拽到右側
4. 等待上傳完成

### 步驟4：部署
1. 使用 SSH 連接到 VM
2. 執行部署：
   ```bash
   cd tutoring-system
   chmod +x 簡易部署.sh
   ./簡易部署.sh
   ```

---

## 💾 方案3：壓縮包上傳

### 步驟1：壓縮專案
1. 右鍵點擊 `tutoring-system` 資料夾
2. 選擇 **傳送到 > 壓縮的資料夾**
3. 或使用 PowerShell：
   ```powershell
   Compress-Archive -Path .\tutoring-system\ -DestinationPath tutoring-system.zip
   ```

### 步驟2：上傳壓縮檔
使用 WinSCP 或 PowerShell SCP：
```powershell
scp tutoring-system.zip username@your-vm-ip:~/
```

### 步驟3：解壓並部署
```bash
# SSH 連接到 VM
ssh username@your-vm-ip

# 解壓檔案
unzip tutoring-system.zip
cd tutoring-system

# 部署
chmod +x 簡易部署.sh
./簡易部署.sh
```

---

## 🔧 詳細操作步驟

### 使用 PowerShell SSH（推薦）

#### 1. 測試 SSH 連接
```powershell
# 開啟 PowerShell（以系統管理員身分執行）
ssh username@your-vm-ip

# 如果出現錯誤，可能需要啟用 SSH 客戶端
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
```

#### 2. 上傳檔案
```powershell
# 上傳整個資料夾
scp -r .\tutoring-system\ username@your-vm-ip:~/

# 或上傳壓縮檔
scp tutoring-system.zip username@your-vm-ip:~/
```

#### 3. 連接並部署
```powershell
# SSH 連接
ssh username@your-vm-ip

# 在 VM 上執行
cd tutoring-system  # 或先解壓 unzip tutoring-system.zip
chmod +x 簡易部署.sh
./簡易部署.sh
```

---

## 🎯 完整範例：Git 方式

### 1. 本地準備（Windows PowerShell）
```powershell
# 進入專案目錄
cd C:\Users\YourName\Desktop\tutoring-system

# 檢查 Git 是否安裝
git --version

# 如果沒有 Git，請下載安裝：https://git-scm.com/

# 初始化並上傳到 GitHub
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/your-username/tutoring-system.git
git push -u origin main
```

### 2. VM 部署（SSH 終端）
```bash
# 下載專案
git clone https://github.com/your-username/tutoring-system.git
cd tutoring-system

# 執行部署腳本
chmod +x 簡易部署.sh
./簡易部署.sh
```

### 3. 訪問系統
- 前端：`http://your-vm-ip:3000`
- 後端：`http://your-vm-ip:5000`

---

## 🔍 故障排除

### 常見問題

#### 1. SSH 連接被拒絕
```powershell
# 檢查 VM 是否正在運行
# 在 GCP Console 確認 VM 狀態

# 檢查防火牆規則
# GCP Console > VPC 網路 > 防火牆
```

#### 2. 權限被拒絕
```bash
# 在 VM 上檢查檔案權限
ls -la
chmod +x 簡易部署.sh
```

#### 3. 上傳失敗
```powershell
# 檢查檔案大小，可能需要排除 node_modules
scp -r --exclude='node_modules' .\tutoring-system\ username@your-vm-ip:~/
```

#### 4. 部署失敗
```bash
# 查看詳細錯誤
./manage.sh logs

# 手動安裝 Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```

---

## 💡 小技巧

### 1. 加速上傳
```powershell
# 排除不必要的檔案
$exclude = @('node_modules', '.git', '*.db', 'logs')
# 使用 robocopy 或其他工具
```

### 2. 自動化腳本
建立 `deploy.bat` 檔案：
```batch
@echo off
echo 正在上傳專案...
scp -r .\tutoring-system\ username@your-vm-ip:~/
echo 正在部署...
ssh username@your-vm-ip "cd tutoring-system && chmod +x 簡易部署.sh && ./簡易部署.sh"
echo 部署完成！
pause
```

### 3. 設定 SSH 金鑰（可選）
```powershell
# 生成 SSH 金鑰
ssh-keygen -t rsa -b 4096

# 複製公鑰到 VM
type $env:USERPROFILE\.ssh\id_rsa.pub | ssh username@your-vm-ip "cat >> ~/.ssh/authorized_keys"
```

選擇最適合你的方式開始部署吧！🚀