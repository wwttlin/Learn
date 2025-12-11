@echo off
chcp 65001 >nul
echo ========================================
echo    Git 設定和推送輔助腳本
echo ========================================
echo.

REM 檢查是否在正確的目錄
if not exist "package.json" (
    echo ❌ 錯誤：請在專案根目錄執行此腳本
    echo    確保目錄包含 package.json 檔案
    pause
    exit /b 1
)

echo ✅ 找到專案檔案

REM 檢查 Git 是否安裝
git --version >nul 2>&1
if errorlevel 1 (
    echo ❌ 錯誤：Git 未安裝
    echo    請前往 https://git-scm.com/ 下載安裝 Git
    pause
    exit /b 1
)

echo ✅ Git 已安裝

REM 檢查用戶設定
for /f "tokens=*" %%i in ('git config --global user.name 2^>nul') do set git_name=%%i
for /f "tokens=*" %%i in ('git config --global user.email 2^>nul') do set git_email=%%i

if "%git_name%"=="" (
    echo.
    echo 📝 設定 Git 用戶資訊
    set /p git_name="請輸入你的姓名: "
    git config --global user.name "%git_name%"
)

if "%git_email%"=="" (
    set /p git_email="請輸入你的 Email: "
    git config --global user.email "%git_email%"
)

echo ✅ Git 用戶設定完成
echo    姓名: %git_name%
echo    Email: %git_email%

REM 檢查是否已初始化 Git
if not exist ".git" (
    echo.
    echo 🔧 初始化 Git 倉庫...
    git init
    git add .
    git commit -m "補習班管理系統初始版本"
    echo ✅ Git 倉庫初始化完成
)

REM 獲取 GitHub 倉庫資訊
echo.
echo 📋 GitHub 倉庫設定
echo    請確保你已在 GitHub 建立倉庫: tutoring-system
echo.
set /p github_username="請輸入你的 GitHub 用戶名: "
set /p repo_name="請輸入倉庫名稱 (預設: tutoring-system): "
if "%repo_name%"=="" set repo_name=tutoring-system

REM 設定遠端倉庫
echo.
echo 🔗 設定遠端倉庫...
git remote remove origin 2>nul
git remote add origin https://github.com/%github_username%/%repo_name%.git
echo ✅ 遠端倉庫設定完成

REM 選擇認證方式
echo.
echo 🔐 選擇認證方式:
echo    1. Personal Access Token (推薦)
echo    2. SSH 金鑰
echo    3. 嘗試直接推送
echo.
set /p auth_choice="請選擇 (1-3): "

if "%auth_choice%"=="1" goto :token_auth
if "%auth_choice%"=="2" goto :ssh_auth
if "%auth_choice%"=="3" goto :direct_push

:token_auth
echo.
echo 📝 Personal Access Token 設定
echo.
echo 請按照以下步驟建立 Token:
echo 1. 前往 https://github.com/settings/tokens
echo 2. 點擊 "Generate new token (classic)"
echo 3. 勾選 "repo" 權限
echo 4. 複製生成的 token
echo.
set /p github_token="請貼上你的 Personal Access Token: "

REM 使用 token 設定 URL
git remote set-url origin https://%github_token%@github.com/%github_username%/%repo_name%.git
goto :push

:ssh_auth
echo.
echo 🔑 SSH 金鑰設定
echo.
echo 檢查 SSH 金鑰...
if exist "%USERPROFILE%\.ssh\id_rsa.pub" (
    echo ✅ 找到現有的 SSH 金鑰
    echo.
    echo 請將以下公鑰添加到 GitHub:
    echo https://github.com/settings/ssh/new
    echo.
    type "%USERPROFILE%\.ssh\id_rsa.pub"
) else if exist "%USERPROFILE%\.ssh\id_ed25519.pub" (
    echo ✅ 找到現有的 SSH 金鑰
    echo.
    echo 請將以下公鑰添加到 GitHub:
    echo https://github.com/settings/ssh/new
    echo.
    type "%USERPROFILE%\.ssh\id_ed25519.pub"
) else (
    echo ❌ 未找到 SSH 金鑰
    echo.
    echo 正在生成新的 SSH 金鑰...
    ssh-keygen -t ed25519 -C "%git_email%" -f "%USERPROFILE%\.ssh\id_ed25519" -N ""
    echo.
    echo ✅ SSH 金鑰已生成
    echo.
    echo 請將以下公鑰添加到 GitHub:
    echo https://github.com/settings/ssh/new
    echo.
    type "%USERPROFILE%\.ssh\id_ed25519.pub"
)

echo.
pause

REM 設定 SSH URL
git remote set-url origin git@github.com:%github_username%/%repo_name%.git
goto :push

:direct_push
echo.
echo 🚀 嘗試直接推送...

:push
echo.
echo 📤 推送到 GitHub...
git branch -M main
git push -u origin main

if errorlevel 1 (
    echo.
    echo ❌ 推送失敗！
    echo.
    echo 🔧 可能的解決方案:
    echo 1. 檢查網路連接
    echo 2. 確認 GitHub 倉庫已建立
    echo 3. 檢查認證資訊是否正確
    echo 4. 嘗試使用代理設定
    echo.
    echo 💡 替代方案:
    echo 1. 使用 WinSCP 直接上傳到 VM
    echo 2. 手動上傳檔案到 GitHub 網頁
    echo 3. 使用 SCP 命令上傳
    echo.
    echo 詳細解決方案請參考: Git問題解決.md
) else (
    echo.
    echo ✅ 推送成功！
    echo.
    echo 🎉 專案已上傳到 GitHub
    echo    倉庫地址: https://github.com/%github_username%/%repo_name%
    echo.
    echo 📋 下一步 - 在 VM 上部署:
    echo    1. SSH 連接到你的 VM
    echo    2. 執行: git clone https://github.com/%github_username%/%repo_name%.git
    echo    3. 執行: cd %repo_name% ^&^& ./簡易部署.sh
)

echo.
pause