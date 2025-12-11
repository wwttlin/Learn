#!/bin/bash

# e2-micro 記憶體監控腳本

echo "📊 e2-micro 記憶體監控"
echo "======================"

# 顏色定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[ℹ]${NC} $1"
}

# 獲取記憶體資訊
get_memory_info() {
    MEMORY_TOTAL=$(free -m | awk 'NR==2{print $2}')
    MEMORY_USED=$(free -m | awk 'NR==2{print $3}')
    MEMORY_FREE=$(free -m | awk 'NR==2{print $4}')
    MEMORY_AVAILABLE=$(free -m | awk 'NR==2{print $7}')
    MEMORY_PERCENT=$(echo "scale=1; $MEMORY_USED*100/$MEMORY_TOTAL" | bc -l 2>/dev/null || echo "0")
    
    SWAP_TOTAL=$(free -m | awk 'NR==3{print $2}')
    SWAP_USED=$(free -m | awk 'NR==3{print $3}')
    SWAP_FREE=$(free -m | awk 'NR==3{print $4}')
}

# 顯示記憶體狀態
show_memory_status() {
    get_memory_info
    
    echo "💾 記憶體狀態"
    echo "  總計: ${MEMORY_TOTAL}MB"
    echo "  已用: ${MEMORY_USED}MB (${MEMORY_PERCENT}%)"
    echo "  可用: ${MEMORY_AVAILABLE}MB"
    
    # 記憶體警告
    if (( $(echo "$MEMORY_PERCENT > 85" | bc -l) )); then
        print_error "記憶體使用率過高！"
    elif (( $(echo "$MEMORY_PERCENT > 70" | bc -l) )); then
        print_warning "記憶體使用率偏高"
    else
        print_status "記憶體使用正常"
    fi
    
    echo ""
    echo "🔄 Swap 狀態"
    if [ "$SWAP_TOTAL" -gt 0 ]; then
        SWAP_PERCENT=$(echo "scale=1; $SWAP_USED*100/$SWAP_TOTAL" | bc -l 2>/dev/null || echo "0")
        echo "  總計: ${SWAP_TOTAL}MB"
        echo "  已用: ${SWAP_USED}MB (${SWAP_PERCENT}%)"
        echo "  可用: ${SWAP_FREE}MB"
        
        if (( $(echo "$SWAP_PERCENT > 50" | bc -l) )); then
            print_warning "Swap 使用率較高，系統可能變慢"
        fi
    else
        print_warning "沒有 Swap 空間"
    fi
}

# 顯示進程記憶體使用
show_process_memory() {
    echo ""
    echo "🔍 Top 10 記憶體使用進程"
    echo "PID    %MEM  RSS(MB)  COMMAND"
    echo "--------------------------------"
    ps aux --sort=-%mem | head -11 | tail -10 | while read line; do
        PID=$(echo $line | awk '{print $2}')
        MEM_PERCENT=$(echo $line | awk '{print $4}')
        RSS_KB=$(echo $line | awk '{print $6}')
        RSS_MB=$(echo "scale=1; $RSS_KB/1024" | bc -l 2>/dev/null || echo "0")
        COMMAND=$(echo $line | awk '{for(i=11;i<=NF;i++) printf "%s ", $i; print ""}' | cut -c1-30)
        
        printf "%-6s %-5s %-8s %s\n" "$PID" "$MEM_PERCENT%" "${RSS_MB}MB" "$COMMAND"
    done
}

# 顯示 PM2 進程狀態
show_pm2_status() {
    echo ""
    echo "🚀 PM2 進程狀態"
    if command -v pm2 &> /dev/null; then
        pm2 jlist 2>/dev/null | jq -r '.[] | "\(.name): \(.monit.memory/1024/1024 | floor)MB RAM, \(.monit.cpu)% CPU"' 2>/dev/null || {
            echo "PM2 進程列表:"
            pm2 list --no-colors 2>/dev/null || echo "沒有 PM2 進程運行"
        }
    else
        echo "PM2 未安裝"
    fi
}

# 記憶體清理
clean_memory() {
    echo ""
    print_info "執行記憶體清理..."
    
    # 清理系統快取
    sudo sync
    echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null 2>&1
    
    # 清理 npm 快取
    npm cache clean --force >/dev/null 2>&1
    
    # 重啟 PM2 進程（如果存在）
    if command -v pm2 &> /dev/null && pm2 list 2>/dev/null | grep -q "online"; then
        print_info "重啟 PM2 進程..."
        pm2 restart all >/dev/null 2>&1
    fi
    
    print_status "記憶體清理完成"
    
    # 顯示清理後的狀態
    sleep 2
    get_memory_info
    echo "清理後記憶體使用: ${MEMORY_USED}MB (${MEMORY_PERCENT}%)"
}

# 記憶體優化建議
show_optimization_tips() {
    get_memory_info
    
    echo ""
    echo "💡 優化建議"
    
    if [ "$SWAP_TOTAL" -eq 0 ]; then
        print_warning "建議建立 Swap 空間:"
        echo "  sudo fallocate -l 1G /swapfile"
        echo "  sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile"
    fi
    
    if (( $(echo "$MEMORY_PERCENT > 80" | bc -l) )); then
        print_warning "記憶體使用過高，建議:"
        echo "  1. 執行記憶體清理: $0 --clean"
        echo "  2. 重啟不必要的服務"
        echo "  3. 考慮升級到 e2-small"
    fi
    
    if [ "$MEMORY_TOTAL" -lt 1200 ]; then
        print_warning "記憶體容量較小，建議:"
        echo "  1. 使用 deploy-micro.sh 部署"
        echo "  2. 定期清理記憶體"
        echo "  3. 監控系統效能"
    fi
}

# 持續監控模式
continuous_monitor() {
    echo "🔄 持續監控模式（每 30 秒更新，按 Ctrl+C 退出）"
    echo ""
    
    while true; do
        clear
        echo "📊 e2-micro 即時監控 - $(date '+%Y-%m-%d %H:%M:%S')"
        echo "================================================"
        
        show_memory_status
        show_process_memory
        
        # 檢查是否需要警告
        get_memory_info
        if (( $(echo "$MEMORY_PERCENT > 90" | bc -l) )); then
            echo ""
            print_error "⚠️  記憶體使用率過高！建議立即清理"
        fi
        
        echo ""
        echo "按 Ctrl+C 退出監控..."
        sleep 30
    done
}

# 主程式
case "$1" in
    --clean|-c)
        clean_memory
        ;;
    --monitor|-m)
        continuous_monitor
        ;;
    --tips|-t)
        show_optimization_tips
        ;;
    --help|-h)
        echo "e2-micro 記憶體監控工具"
        echo ""
        echo "用法: $0 [選項]"
        echo ""
        echo "選項:"
        echo "  (無參數)     顯示當前記憶體狀態"
        echo "  -c, --clean  執行記憶體清理"
        echo "  -m, --monitor 持續監控模式"
        echo "  -t, --tips   顯示優化建議"
        echo "  -h, --help   顯示此幫助"
        ;;
    *)
        show_memory_status
        show_process_memory
        show_pm2_status
        show_optimization_tips
        ;;
esac