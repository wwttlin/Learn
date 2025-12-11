#!/bin/bash

# GitHub 同步更新腳本

echo "🔄 同步更新到 GitHub..."

# 顏色定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[ℹ]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# 檢查是否在 Git 倉庫中
if [ ! -d ".git" ]; then
    print_error "這不是一個 Git 倉庫"
    print_info "請先執行: git init"
    exit 1
fi

# 檢查是否有遠端倉庫
if ! git remote get-url origin >/dev/null 2>&1; then
    print_error "沒有設定遠端倉庫"
    print_info "請先執行 git-setup.sh 或手動設定遠端倉庫"
    exit 1
fi

print_info "遠端倉庫: $(git remote get-url origin)"

# 檢查當前狀態
print_info "檢查檔案變更..."
if git diff --quiet && git diff --cached --quiet; then
    print_warning "沒有檔案變更需要提交"
    
    # 檢查是否有未追蹤的檔案
    if [ -n "$(git ls-files --others --exclude-standard)" ]; then
        print_info "發現未追蹤的檔案:"
        git ls-files --others --exclude-standard
        echo ""
        read -p "是否要添加這些檔案？(Y/n): " add_files
        if [[ ! $add_files =~ ^[Nn]$ ]]; then
            git add .
        else
            print_info "跳過未追蹤的檔案"
            exit 0
        fi
    else
        print_info "所有檔案都是最新的"
        exit 0
    fi
fi

# 顯示變更的檔案
print_info "變更的檔案:"
git status --porcelain

echo ""

# 添加所有變更
print_info "添加所有變更..."
git add .

# 顯示將要提交的變更
print_info "將要提交的變更:"
git diff --cached --name-only

echo ""

# 輸入提交訊息
echo "請輸入提交訊息 (或按 Enter 使用預設訊息):"
read -p "提交訊息: " commit_message

if [ -z "$commit_message" ]; then
    # 生成自動提交訊息
    current_date=$(date '+%Y-%m-%d %H:%M')
    commit_message="更新系統檔案 - $current_date

- 修復前端建置問題
- 更新部署腳本
- 添加問題解決指南
- 優化系統配置"
fi

# 提交變更
print_info "提交變更..."
if git commit -m "$commit_message"; then
    print_status "提交成功"
else
    print_error "提交失敗"
    exit 1
fi

# 推送到 GitHub
print_info "推送到 GitHub..."
if git push origin main; then
    print_status "推送成功！"
    echo ""
    print_status "所有變更已同步到 GitHub"
    print_info "倉庫地址: $(git remote get-url origin | sed 's/.*@github.com:/https:\/\/github.com\//' | sed 's/\.git$//')"
else
    print_error "推送失敗"
    echo ""
    print_warning "可能的原因:"
    echo "1. 網路連接問題"
    echo "2. 認證失敗"
    echo "3. 遠端倉庫有新的變更"
    echo ""
    print_info "嘗試解決方案:"
    echo "1. 檢查網路連接"
    echo "2. 重新設定認證: ./git-setup.sh"
    echo "3. 拉取遠端變更: git pull origin main"
    
    # 提供自動修復選項
    echo ""
    read -p "是否要嘗試拉取遠端變更並重新推送？(y/N): " auto_fix
    if [[ $auto_fix =~ ^[Yy]$ ]]; then
        print_info "拉取遠端變更..."
        if git pull origin main --no-edit; then
            print_info "重新推送..."
            if git push origin main; then
                print_status "推送成功！"
            else
                print_error "推送仍然失敗，請手動解決"
            fi
        else
            print_error "拉取失敗，可能有衝突需要手動解決"
        fi
    fi
fi

echo ""
print_info "同步腳本執行完成"