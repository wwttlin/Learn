@echo off
chcp 65001 >nul
echo ========================================
echo    GitHub 同步更新腳本
echo ========================================
echo.

REM 檢查是否在 Git 倉庫中
if not exist ".git" (
    echo ❌ 這不是一個 Git 倉庫
    echo    請先執行: git init
    pause
    exit /b 1
)

REM 檢查是否有遠端倉庫
git remote get-url origin >nul 2>&1
if errorlevel 1 (
    echo ❌ 沒有設定遠端倉庫
    echo    請先執行 git-setup.bat 或手動設定遠端倉庫
    pause
    exit /b 1
)

echo ✅ Git 倉庫檢查通過

REM 顯示遠端倉庫
for /f "tokens=*" %%i in ('git remote get-url origin') do set remote_url=%%i
echo 📡 遠端倉庫: %remote_url%
echo.

REM 檢查檔案變更
echo 🔍 檢查檔案變更...
git diff --quiet && git diff --cached --quiet
if not errorlevel 1 (
    echo ⚠️  沒有檔案變更需要提交
    
    REM 檢查未追蹤的檔案
    for /f %%i in ('git ls-files --others --exclude-standard ^| find /c /v ""') do set untracked_count=%%i
    if %untracked_count% gtr 0 (
        echo.
        echo 📁 發現未追蹤的檔案:
        git ls-files --others --exclude-standard
        echo.
        set /p add_files="是否要添加這些檔案？(Y/n): "
        if /i not "%add_files%"=="n" (
            git add .
        ) else (
            echo 跳過未追蹤的檔案
            pause
            exit /b 0
        )
    ) else (
        echo ✅ 所有檔案都是最新的
        pause
        exit /b 0
    )
)

REM 顯示變更的檔案
echo.
echo 📝 變更的檔案:
git status --porcelain
echo.

REM 添加所有變更
echo 📦 添加所有變更...
git add .

REM 顯示將要提交的變更
echo.
echo 📋 將要提交的變更:
git diff --cached --name-only
echo.

REM 輸入提交訊息
echo 💬 請輸入提交訊息 (或按 Enter 使用預設訊息):
set /p commit_message="提交訊息: "

if "%commit_message%"=="" (
    REM 生成自動提交訊息
    for /f "tokens=1-3 delims=/ " %%a in ('date /t') do set current_date=%%c-%%a-%%b
    for /f "tokens=1-2 delims=: " %%a in ('time /t') do set current_time=%%a:%%b
    set commit_message=更新系統檔案 - %current_date% %current_time%

- 修復前端建置問題
- 更新部署腳本  
- 添加問題解決指南
- 優化系統配置
)

REM 提交變更
echo.
echo 💾 提交變更...
git commit -m "%commit_message%"
if errorlevel 1 (
    echo ❌ 提交失敗
    pause
    exit /b 1
)

echo ✅ 提交成功

REM 推送到 GitHub
echo.
echo 🚀 推送到 GitHub...
git push origin main
if not errorlevel 1 (
    echo.
    echo ✅ 推送成功！
    echo.
    echo 🎉 所有變更已同步到 GitHub
    echo 🔗 倉庫地址: %remote_url%
) else (
    echo.
    echo ❌ 推送失敗
    echo.
    echo ⚠️  可能的原因:
    echo    1. 網路連接問題
    echo    2. 認證失敗
    echo    3. 遠端倉庫有新的變更
    echo.
    echo 💡 嘗試解決方案:
    echo    1. 檢查網路連接
    echo    2. 重新設定認證: git-setup.bat
    echo    3. 拉取遠端變更: git pull origin main
    echo.
    
    REM 提供自動修復選項
    set /p auto_fix="是否要嘗試拉取遠端變更並重新推送？(y/N): "
    if /i "%auto_fix%"=="y" (
        echo 📥 拉取遠端變更...
        git pull origin main --no-edit
        if not errorlevel 1 (
            echo 🚀 重新推送...
            git push origin main
            if not errorlevel 1 (
                echo ✅ 推送成功！
            ) else (
                echo ❌ 推送仍然失敗，請手動解決
            )
        ) else (
            echo ❌ 拉取失敗，可能有衝突需要手動解決
        )
    )
)

echo.
echo 🏁 同步腳本執行完成
pause