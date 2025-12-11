#!/bin/bash

# 補習班管理系統監控腳本
# 用於監控系統狀態和自動重啟異常服務

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日誌檔案
LOG_FILE="./logs/monitor.log"
mkdir -p logs

# 記錄日誌函數
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"
}

log_error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: $1" >> $LOG_FILE
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - WARNING: $1" >> $LOG_FILE
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_success() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - SUCCESS: $1" >> $LOG_FILE
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# 檢查服務狀態
check_service() {
    local service_name=$1
    local port=$2
    
    # 檢查 PM2 進程
    if pm2 list | grep -q "$service_name.*online"; then
        log_success "$service_name 進程正常運行"
        
        # 檢查端口是否可訪問
        if curl -s --max-time 5 "http://localhost:$port" > /dev/null; then
            log_success "$service_name 端口 $port 可正常訪問"
            return 0
        else
            log_error "$service_name 端口 $port 無法訪問"
            return 1
        fi
    else
        log_error "$service_name 進程未運行"
        return 1
    fi
}

# 重啟服務
restart_service() {
    local service_name=$1
    log_warning "正在重啟 $service_name..."
    
    if pm2 restart $service_name; then
        sleep 10  # 等待服務啟動
        log_success "$service_name 重啟成功"
        return 0
    else
        log_error "$service_name 重啟失敗"
        return 1
    fi
}

# 檢查系統資源
check_system_resources() {
    # 檢查記憶體使用率
    local memory_usage=$(free | grep Mem | awk '{printf("%.1f", $3/$2 * 100.0)}')
    log_message "記憶體使用率: ${memory_usage}%"
    
    if (( $(echo "$memory_usage > 90" | bc -l) )); then
        log_warning "記憶體使用率過高: ${memory_usage}%"
    fi
    
    # 檢查磁碟使用率
    local disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    log_message "磁碟使用率: ${disk_usage}%"
    
    if [ "$disk_usage" -gt 85 ]; then
        log_warning "磁碟使用率過高: ${disk_usage}%"
    fi
    
    # 檢查 CPU 負載
    local cpu_load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    log_message "CPU 負載: $cpu_load"
}

# 檢查資料庫檔案
check_database() {
    if [ -f "tutoring.db" ]; then
        local db_size=$(du -h tutoring.db | cut -f1)
        log_message "資料庫檔案大小: $db_size"
        
        # 檢查資料庫是否可讀寫
        if sqlite3 tutoring.db "SELECT 1;" > /dev/null 2>&1; then
            log_success "資料庫檔案正常"
        else
            log_error "資料庫檔案可能損壞"
        fi
    else
        log_error "找不到資料庫檔案"
    fi
}

# 清理舊日誌
cleanup_logs() {
    # 清理超過 7 天的日誌
    find logs -name "*.log" -mtime +7 -delete 2>/dev/null
    
    # 清理 PM2 日誌（保留最新 100MB）
    pm2 flush
}

# 發送通知（可選）
send_notification() {
    local message=$1
    local level=$2
    
    # 這裡可以整合 Slack、Discord、Email 等通知服務
    # 例如：
    # curl -X POST -H 'Content-type: application/json' \
    #   --data "{\"text\":\"$message\"}" \
    #   YOUR_SLACK_WEBHOOK_URL
    
    log_message "通知: $message"
}

# 主監控函數
main_monitor() {
    log_message "開始系統監控檢查..."
    
    local issues=0
    
    # 檢查後端服務
    if ! check_service "tutoring-backend" "5000"; then
        if restart_service "tutoring-backend"; then
            send_notification "後端服務已自動重啟" "warning"
        else
            send_notification "後端服務重啟失敗，需要人工介入" "error"
            ((issues++))
        fi
    fi
    
    # 檢查前端服務
    if ! check_service "tutoring-frontend" "3000"; then
        if restart_service "tutoring-frontend"; then
            send_notification "前端服務已自動重啟" "warning"
        else
            send_notification "前端服務重啟失敗，需要人工介入" "error"
            ((issues++))
        fi
    fi
    
    # 檢查系統資源
    check_system_resources
    
    # 檢查資料庫
    check_database
    
    # 清理日誌（每天執行一次）
    if [ "$(date +%H:%M)" = "02:00" ]; then
        cleanup_logs
        log_message "日誌清理完成"
    fi
    
    if [ $issues -eq 0 ]; then
        log_success "所有服務運行正常"
    else
        log_error "發現 $issues 個問題需要處理"
    fi
    
    log_message "監控檢查完成"
    echo "----------------------------------------"
}

# 顯示幫助資訊
show_help() {
    echo "補習班管理系統監控腳本"
    echo ""
    echo "用法: $0 [選項]"
    echo ""
    echo "選項:"
    echo "  -h, --help     顯示此幫助資訊"
    echo "  -s, --status   顯示服務狀態"
    echo "  -r, --restart  重啟所有服務"
    echo "  -m, --monitor  執行一次監控檢查"
    echo "  -w, --watch    持續監控模式"
    echo ""
}

# 顯示服務狀態
show_status() {
    echo "=== 補習班管理系統狀態 ==="
    echo ""
    
    echo "PM2 進程狀態:"
    pm2 status
    echo ""
    
    echo "系統資源:"
    echo "記憶體使用: $(free -h | grep Mem | awk '{print $3 "/" $2}')"
    echo "磁碟使用: $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')"
    echo "CPU 負載: $(uptime | awk -F'load average:' '{print $2}')"
    echo ""
    
    echo "網路連接:"
    echo "端口 3000: $(netstat -tlnp 2>/dev/null | grep :3000 | wc -l) 個連接"
    echo "端口 5000: $(netstat -tlnp 2>/dev/null | grep :5000 | wc -l) 個連接"
    echo ""
    
    if [ -f "tutoring.db" ]; then
        echo "資料庫: $(du -h tutoring.db | cut -f1)"
    else
        echo "資料庫: 未找到"
    fi
}

# 重啟所有服務
restart_all() {
    log_message "重啟所有服務..."
    pm2 restart all
    sleep 10
    pm2 status
}

# 持續監控模式
watch_mode() {
    log_message "進入持續監控模式（每 5 分鐘檢查一次）"
    log_message "按 Ctrl+C 退出"
    
    while true; do
        main_monitor
        sleep 300  # 5 分鐘
    done
}

# 主程式
case "$1" in
    -h|--help)
        show_help
        ;;
    -s|--status)
        show_status
        ;;
    -r|--restart)
        restart_all
        ;;
    -m|--monitor)
        main_monitor
        ;;
    -w|--watch)
        watch_mode
        ;;
    *)
        main_monitor
        ;;
esac