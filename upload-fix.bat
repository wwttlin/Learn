@echo off
chcp 65001 >nul
echo ========================================
echo 上傳修復後的代碼到 Ubuntu 伺服器
echo ========================================
echo.

REM 設定你的伺服器資訊
set /p SERVER_IP="請輸入伺服器 IP: "
set /p SERVER_USER="請輸入 SSH 使用者名稱 (預設: your-username): " || set SERVER_USER=your-username
set /p PROJECT_PATH="請輸入專案路徑 (預設: ~/tutoring-system): " || set PROJECT_PATH=~/tutoring-system

echo.
echo 伺服器: %SERVER_USER%@%SERVER_IP%
echo 路徑: %PROJECT_PATH%
echo.
set /p CONFIRM="確認上傳? (Y/N): "
if /i not "%CONFIRM%"=="Y" goto :end

echo.
echo 📦 準備上傳檔案...
echo.

REM 檢查是否安裝 scp
where scp >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ 找不到 scp 命令
    echo 請安裝 OpenSSH 或使用 Git Bash
    echo.
    echo 或者使用 Git 方式上傳:
    echo   1. git add .
    echo   2. git commit -m "修復新增學生問題"
    echo   3. git push
    echo   4. 在伺服器上執行: git pull
    goto :end
)

echo 上傳前端組件...
scp client/src/components/StudentManagement.tsx %SERVER_USER%@%SERVER_IP%:%PROJECT_PATH%/client/src/components/
scp client/src/components/CourseManagement.tsx %SERVER_USER%@%SERVER_IP%:%PROJECT_PATH%/client/src/components/
scp client/src/components/PaymentManagement.tsx %SERVER_USER%@%SERVER_IP%:%PROJECT_PATH%/client/src/components/

echo 上傳前端配置...
scp client/package.json %SERVER_USER%@%SERVER_IP%:%PROJECT_PATH%/client/

echo 上傳部署腳本...
scp 簡易部署.sh %SERVER_USER%@%SERVER_IP%:%PROJECT_PATH%/
scp update-frontend.sh %SERVER_USER%@%SERVER_IP%:%PROJECT_PATH%/
scp diagnose-api.sh %SERVER_USER%@%SERVER_IP%:%PROJECT_PATH%/
scp setup-nginx.sh %SERVER_USER%@%SERVER_IP%:%PROJECT_PATH%/
scp fix-nginx.sh %SERVER_USER%@%SERVER_IP%:%PROJECT_PATH%/
scp 一鍵修復.sh %SERVER_USER%@%SERVER_IP%:%PROJECT_PATH%/

echo 上傳說明文件...
scp 修復新增學生問題.md %SERVER_USER%@%SERVER_IP%:%PROJECT_PATH%/
scp Nginx設定指南.md %SERVER_USER%@%SERVER_IP%:%PROJECT_PATH%/
scp 修復工具說明.md %SERVER_USER%@%SERVER_IP%:%PROJECT_PATH%/

echo.
echo ✅ 檔案上傳完成！
echo.
echo 📋 接下來在伺服器上執行:
echo.
echo   ssh %SERVER_USER%@%SERVER_IP%
echo   cd %PROJECT_PATH%
echo.
echo 🚀 推薦：一鍵修復所有問題
echo   chmod +x 一鍵修復.sh
echo   ./一鍵修復.sh
echo.
echo 或分別執行:
echo   chmod +x update-frontend.sh setup-nginx.sh fix-nginx.sh diagnose-api.sh
echo   ./update-frontend.sh      # 只更新前端
echo   ./setup-nginx.sh          # 配置 Nginx
echo   ./fix-nginx.sh            # 修復 Nginx
echo   ./diagnose-api.sh         # 診斷問題
echo.

:end
pause
