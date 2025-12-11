#!/bin/bash

# Git 設定和推送輔助腳本
# 適用於 Linux/Mac

set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

echo "========================================"
echo "    Git 設定和推送輔助腳本"
echo "========================================"
echo ""

# 檢查是否在正確的目錄
if [ ! -f "package.json" ]; then
    print_error "請在專案根目錄執行此腳本"
    print_info "確保目錄包含 package.json 檔案"
    exit 1
fi

print_status "找到專案檔案"

# 檢查 Git 是否安裝
if ! command -v git &> /dev/null; then
    print_error "Git 未安裝"
    print_info "請安裝 Git: https://git-scm.com/"
    
    # 嘗試自動安裝（Ubuntu/Debian）
    if command -v apt &> /dev/null; then
        print_info "嘗試自動安裝 Git..."
        sudo apt update && sudo apt install -y git
    elif command -v yum &> /dev/null; then
        print_info "嘗試自動安裝 Git..."
        sudo yum install -y git
    elif command -v brew &> /dev/null; then
        print_info "嘗試自動安裝 Git..."
        brew install git
    fi
    
    if ! command -v git &> /dev/null; then
        print_error "Git 安裝失敗，請手動安裝"
        exit 1
    fi
fi

print_status "Git 已安裝: $(git --version)"

# 檢查用戶設定
git_name=$(git config --global user.name 2>/dev/null || echo "")
git_email=$(git config --global user.email 2>/dev/null || echo "")

if [ -z "$git_name" ]; then
    echo ""
    print_info "設定 Git 用戶資訊"
    read -p "請輸入你的姓名: " git_name
    git config --global user.name "$git_name"
fi

if [ -z "$git_email" ]; then
    read -p "請輸入你的 Email: " git_email
    git config --global user.email "$git_email"
fi

print_status "Git 用戶設定完成"
print_info "姓名: $git_name"
print_info "Email: $git_email"

# 檢查是否已初始化 Git
if [ ! -d ".git" ]; then
    echo ""
    print_info "初始化 Git 倉庫..."
    git init
    git add .
    git commit -m "補習班管理系統初始版本"
    print_status "Git 倉庫初始化完成"
fi

# 獲取 GitHub 倉庫資訊
echo ""
print_info "GitHub 倉庫設定"
print_info "請確保你已在 GitHub 建立倉庫: tutoring-system"
echo ""
read -p "請輸入你的 GitHub 用戶名: " github_username
read -p "請輸入倉庫名稱 (預設: tutoring-system): " repo_name
repo_name=${repo_name:-tutoring-system}

# 設定遠端倉庫
echo ""
print_info "設定遠端倉庫..."
git remote remove origin 2>/dev/null || true
git remote add origin "https://github.com/$github_username/$repo_name.git"
print_status "遠端倉庫設定完成"

# 選擇認證方式
echo ""
print_info "選擇認證方式:"
echo "  1. Personal Access Token (推薦)"
echo "  2. SSH 金鑰"
echo "  3. 嘗試直接推送"
echo ""
read -p "請選擇 (1-3): " auth_choice

case $auth_choice in
    1)
        echo ""
        print_info "Personal Access Token 設定"
        echo ""
        echo "請按照以下步驟建立 Token:"
        echo "1. 前往 https://github.com/settings/tokens"
        echo "2. 點擊 'Generate new token (classic)'"
        echo "3. 勾選 'repo' 權限"
        echo "4. 複製生成的 token"
        echo ""
        read -p "請貼上你的 Personal Access Token: " github_token
        
        # 使用 token 設定 URL
        git remote set-url origin "https://$github_token@github.com/$github_username/$repo_name.git"
        ;;
    2)
        echo ""
        print_info "SSH 金鑰設定"
        echo ""
        
        # 檢查現有的 SSH 金鑰
        if [ -f "$HOME/.ssh/id_rsa.pub" ]; then
            print_status "找到現有的 SSH 金鑰"
            echo ""
            print_info "請將以下公鑰添加到 GitHub:"
            print_info "https://github.com/settings/ssh/new"
            echo ""
            cat "$HOME/.ssh/id_rsa.pub"
        elif [ -f "$HOME/.ssh/id_ed25519.pub" ]; then
            print_status "找到現有的 SSH 金鑰"
            echo ""
            print_info "請將以下公鑰添加到 GitHub:"
            print_info "https://github.com/settings/ssh/new"
            echo ""
            cat "$HOME/.ssh/id_ed25519.pub"
        else
            print_warning "未找到 SSH 金鑰"
            echo ""
            print_info "正在生成新的 SSH 金鑰..."
            ssh-keygen -t ed25519 -C "$git_email" -f "$HOME/.ssh/id_ed25519" -N ""
            
            # 啟動 SSH agent 並添加金鑰
            eval "$(ssh-agent -s)"
            ssh-add "$HOME/.ssh/id_ed25519"
            
            print_status "SSH 金鑰已生成"
            echo ""
            print_info "請將以下公鑰添加到 GitHub:"
            print_info "https://github.com/settings/ssh/new"
            echo ""
            cat "$HOME/.ssh/id_ed25519.pub"
        fi
        
        echo ""
        read -p "按 Enter 繼續（確保已添加公鑰到 GitHub）..."
        
        # 測試 SSH 連接
        print_info "測試 SSH 連接..."
        if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
            print_status "SSH 連接測試成功"
        else
            print_warning "SSH 連接測試失敗，但仍會嘗試推送"
        fi
        
        # 設定 SSH URL
        git remote set-url origin "git@github.com:$github_username/$repo_name.git"
        ;;
    3)
        print_info "嘗試直接推送..."
        ;;
esac

# 推送到 GitHub
echo ""
print_info "推送到 GitHub..."
git branch -M main

if git push -u origin main; then
    echo ""
    print_status "推送成功！"
    echo ""
    print_status "專案已上傳到 GitHub"
    print_info "倉庫地址: https://github.com/$github_username/$repo_name"
    echo ""
    print_info "下一步 - 在 VM 上部署:"
    print_info "1. SSH 連接到你的 VM"
    print_info "2. 執行: git clone https://github.com/$github_username/$repo_name.git"
    print_info "3. 執行: cd $repo_name && ./簡易部署.sh"
else
    echo ""
    print_error "推送失敗！"
    echo ""
    print_warning "可能的解決方案:"
    echo "1. 檢查網路連接"
    echo "2. 確認 GitHub 倉庫已建立"
    echo "3. 檢查認證資訊是否正確"
    echo "4. 嘗試使用代理設定"
    echo ""
    print_info "替代方案:"
    echo "1. 使用 SCP 直接上傳到 VM"
    echo "2. 手動上傳檔案到 GitHub 網頁"
    echo "3. 使用其他 Git 託管服務"
    echo ""
    print_info "詳細解決方案請參考: Git問題解決.md"
    
    # 提供代理設定選項
    echo ""
    read -p "是否需要設定代理？(y/N): " setup_proxy
    if [[ $setup_proxy =~ ^[Yy]$ ]]; then
        read -p "請輸入代理地址 (格式: http://proxy-server:port): " proxy_url
        git config --global http.proxy "$proxy_url"
        git config --global https.proxy "$proxy_url"
        print_status "代理設定完成，請重新執行推送"
        print_info "執行: git push -u origin main"
    fi
fi

echo ""
print_info "腳本執行完成"