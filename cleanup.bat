@echo off
chcp 65001 >nul
echo ========================================
echo 清理不需要的檔案
echo ========================================
echo.
echo 將刪除以下檔案:
echo.
echo 🗑️ 重複的部署腳本:
echo   - deploy.sh (保留 簡易部署.sh)
echo   - deploy-ubuntu.sh (保留 簡易部署.sh)
echo   - deploy-micro.sh (保留 簡易部署.sh)
echo   - quick-deploy.sh (保留 簡易部署.sh)
echo   - quick-fix.sh (保留 一鍵修復.sh)
echo   - instant-fix.sh (保留 一鍵修復.sh)
echo   - emergency-fix.sh (保留 一鍵修復.sh)
echo   - fix-build.sh (功能已整合)
echo   - fix-database.sh (功能已整合)
echo   - memory-monitor.sh (功能已整合)
echo   - 監控腳本.sh (功能已整合)
echo.
echo 🗑️ 重複的文檔:
echo   - 快速參考.md (保留 README-修復指南.md)
echo   - 快速開始.md (保留 README-修復指南.md)
echo   - 快速部署.md (保留 README-修復指南.md)
echo   - 部署指南.md (保留 README-修復指南.md)
echo   - 故障排除.md (保留 修復工具說明.md)
echo   - 建置問題解決.md (保留 修復新增學生問題.md)
echo   - Ubuntu問題排除.md (保留 Nginx設定指南.md)
echo   - 本地建置方案.md (不需要)
echo   - 上傳方案.md (保留 upload-fix.bat)
echo   - 學生管理新功能測試.md (不需要)
echo   - 新功能測試指南.md (不需要)
echo   - 測試新功能.md (不需要)
echo   - e2-micro優化指南.md (不需要)
echo   - Git問題解決.md (不需要)
echo   - Windows用戶指南.md (不需要)
echo.
echo 🗑️ 重複的 Git 工具:
echo   - git-setup.sh (不需要)
echo   - git-setup.bat (不需要)
echo   - git-status.sh (不需要)
echo   - update-github.sh (不需要)
echo   - update-github.bat (不需要)
echo.
echo 🗑️ 其他不需要的檔案:
echo   - diagnose-db.js (功能已整合到 diagnose-api.sh)
echo   - init-database.js (後端自動初始化)
echo.
echo ✅ 保留的重要檔案:
echo   - 簡易部署.sh (主要部署腳本)
echo   - 一鍵修復.sh (一鍵修復工具)
echo   - setup-nginx.sh (Nginx 配置)
echo   - fix-nginx.sh (Nginx 診斷)
echo   - update-frontend.sh (前端更新)
echo   - diagnose-api.sh (系統診斷)
echo   - upload-fix.bat (Windows 上傳)
echo   - README-修復指南.md (主要文檔)
echo   - Nginx設定指南.md (Nginx 文檔)
echo   - Nginx快速參考.md (快速參考)
echo   - 修復工具說明.md (工具說明)
echo   - 修復新增學生問題.md (問題說明)
echo   - 快速修復指南.md (快速指南)
echo.
set /p CONFIRM="確認刪除? (Y/N): "
if /i not "%CONFIRM%"=="Y" goto :end

echo.
echo 開始清理...
echo.

REM 刪除重複的部署腳本
del /f deploy.sh 2>nul && echo ✓ 已刪除 deploy.sh
del /f deploy-ubuntu.sh 2>nul && echo ✓ 已刪除 deploy-ubuntu.sh
del /f deploy-micro.sh 2>nul && echo ✓ 已刪除 deploy-micro.sh
del /f quick-deploy.sh 2>nul && echo ✓ 已刪除 quick-deploy.sh
del /f quick-fix.sh 2>nul && echo ✓ 已刪除 quick-fix.sh
del /f instant-fix.sh 2>nul && echo ✓ 已刪除 instant-fix.sh
del /f emergency-fix.sh 2>nul && echo ✓ 已刪除 emergency-fix.sh
del /f fix-build.sh 2>nul && echo ✓ 已刪除 fix-build.sh
del /f fix-database.sh 2>nul && echo ✓ 已刪除 fix-database.sh
del /f memory-monitor.sh 2>nul && echo ✓ 已刪除 memory-monitor.sh
del /f 監控腳本.sh 2>nul && echo ✓ 已刪除 監控腳本.sh

REM 刪除重複的文檔
del /f 快速參考.md 2>nul && echo ✓ 已刪除 快速參考.md
del /f 快速開始.md 2>nul && echo ✓ 已刪除 快速開始.md
del /f 快速部署.md 2>nul && echo ✓ 已刪除 快速部署.md
del /f 部署指南.md 2>nul && echo ✓ 已刪除 部署指南.md
del /f 故障排除.md 2>nul && echo ✓ 已刪除 故障排除.md
del /f 建置問題解決.md 2>nul && echo ✓ 已刪除 建置問題解決.md
del /f Ubuntu問題排除.md 2>nul && echo ✓ 已刪除 Ubuntu問題排除.md
del /f 本地建置方案.md 2>nul && echo ✓ 已刪除 本地建置方案.md
del /f 上傳方案.md 2>nul && echo ✓ 已刪除 上傳方案.md
del /f 學生管理新功能測試.md 2>nul && echo ✓ 已刪除 學生管理新功能測試.md
del /f 新功能測試指南.md 2>nul && echo ✓ 已刪除 新功能測試指南.md
del /f 測試新功能.md 2>nul && echo ✓ 已刪除 測試新功能.md
del /f e2-micro優化指南.md 2>nul && echo ✓ 已刪除 e2-micro優化指南.md
del /f Git問題解決.md 2>nul && echo ✓ 已刪除 Git問題解決.md
del /f Windows用戶指南.md 2>nul && echo ✓ 已刪除 Windows用戶指南.md

REM 刪除 Git 工具
del /f git-setup.sh 2>nul && echo ✓ 已刪除 git-setup.sh
del /f git-setup.bat 2>nul && echo ✓ 已刪除 git-setup.bat
del /f git-status.sh 2>nul && echo ✓ 已刪除 git-status.sh
del /f update-github.sh 2>nul && echo ✓ 已刪除 update-github.sh
del /f update-github.bat 2>nul && echo ✓ 已刪除 update-github.bat

REM 刪除其他不需要的檔案
del /f diagnose-db.js 2>nul && echo ✓ 已刪除 diagnose-db.js
del /f init-database.js 2>nul && echo ✓ 已刪除 init-database.js

echo.
echo ========================================
echo ✅ 清理完成！
echo ========================================
echo.
echo 📁 保留的檔案結構:
echo.
echo 📂 部署和修復工具 (7 個)
echo   ├─ 簡易部署.sh          - 主要部署腳本
echo   ├─ 一鍵修復.sh          - 一鍵修復所有問題
echo   ├─ setup-nginx.sh       - Nginx 配置工具
echo   ├─ fix-nginx.sh         - Nginx 診斷工具
echo   ├─ update-frontend.sh   - 前端更新工具
echo   ├─ diagnose-api.sh      - 系統診斷工具
echo   └─ upload-fix.bat       - Windows 上傳工具
echo.
echo 📂 文檔 (6 個)
echo   ├─ README.md                  - 專案說明
echo   ├─ README-修復指南.md         - 完整修復指南 ⭐
echo   ├─ 快速修復指南.md            - 快速參考卡片
echo   ├─ Nginx設定指南.md           - Nginx 詳細說明
echo   ├─ Nginx快速參考.md           - Nginx 快速參考
echo   ├─ 修復工具說明.md            - 工具使用說明
echo   └─ 修復新增學生問題.md        - 問題詳解
echo.
echo 📂 配置檔案
echo   ├─ package.json
echo   ├─ .env
echo   ├─ nginx.conf
echo   ├─ ecosystem.config.js
echo   ├─ docker-compose.yml
echo   ├─ Dockerfile.backend
echo   └─ Dockerfile.frontend
echo.
echo 💡 建議: 執行 'git status' 查看變更
echo.

:end
pause
