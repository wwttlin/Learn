#!/bin/bash

# Git 狀態檢查腳本

echo "📊 Git 倉庫狀態檢查"
echo "===================="

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
    exit 1
fi

# 基本資訊
print_info "當前分支: $(git branch --show-current)"

if git remote get-url origin >/dev/null 2>&1; then
    print_info "遠端倉庫: $(git remote get-url origin)"
else
    print_warning "沒有設定遠端倉庫"
fi

echo ""

# 檢查工作區狀態
if git diff --quiet && git diff --cached --quiet; then
    if [ -n "$(git ls-files --others --exclude-standard)" ]; then
        print_warning "有未追蹤的檔案"
        echo "未追蹤的檔案:"
        git ls-files --others --exclude-standard | sed 's/^/  /'
    else
        print_status "工作區乾淨，沒有變更"
    fi
else
    print_info "有檔案變更需要提交"
    echo ""
    echo "變更狀態:"
    git status --porcelain | while read line; do
        status="${line:0:2}"
        file="${line:3}"
        case "$status" in
            "M ") echo "  📝 已修改: $file" ;;
            " M") echo "  ✏️  已變更: $file" ;;
            "A ") echo "  ➕ 已添加: $file" ;;
            "D ") echo "  ➖ 已刪除: $file" ;;
            "??") echo "  ❓ 未追蹤: $file" ;;
            *) echo "  📄 $status $file" ;;
        esac
    done
fi

echo ""

# 檢查與遠端的差異
if git remote get-url origin >/dev/null 2>&1; then
    print_info "檢查與遠端的差異..."
    
    # 獲取遠端資訊（靜默模式）
    git fetch origin 2>/dev/null || true
    
    # 檢查本地是否領先遠端
    ahead=$(git rev-list --count origin/main..HEAD 2>/dev/null || echo "0")
    behind=$(git rev-list --count HEAD..origin/main 2>/dev/null || echo "0")
    
    if [ "$ahead" -gt 0 ]; then
        print_warning "本地領先遠端 $ahead 個提交"
        echo "  💡 執行 ./update-github.sh 來推送變更"
    fi
    
    if [ "$behind" -gt 0 ]; then
        print_warning "本地落後遠端 $behind 個提交"
        echo "  💡 執行 git pull origin main 來更新"
    fi
    
    if [ "$ahead" -eq 0 ] && [ "$behind" -eq 0 ]; then
        print_status "與遠端同步"
    fi
fi

echo ""

# 最近的提交
print_info "最近的提交:"
git log --oneline -5 | sed 's/^/  /'

echo ""

# 提供操作建議
print_info "可用操作:"
echo "  📤 同步到 GitHub: ./update-github.sh"
echo "  📥 從 GitHub 更新: git pull origin main"
echo "  📋 查看詳細狀態: git status"
echo "  📜 查看提交歷史: git log --oneline"