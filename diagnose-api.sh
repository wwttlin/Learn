#!/bin/bash

# API 診斷腳本
# 用於檢查前後端連接和 API 狀態

echo "🔍 補習班管理系統 - API 診斷"
echo "================================"
echo ""

# 顏色定義
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_ok() {
    echo -e "${GREEN}✓${NC} $1"
}

print_fail() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# 1. 檢查服務狀態
echo "1️⃣  檢查服務狀態"
echo "-------------------"
if command -v pm2 &> /dev/null; then
    pm2 list
    echo ""
else
    print_fail "PM2 未安裝"
fi

# 2. 檢查端口
echo "2️⃣  檢查端口佔用"
echo "-------------------"
for port in 80 3000 5000; do
    if sudo lsof -i :$port > /dev/null 2>&1; then
        print_ok "端口 $port 正在使用"
        sudo lsof -i :$port | grep LISTEN
    else
        print_fail "端口 $port 未被使用"
    fi
done
echo ""

# 3. 測試後端 API
echo "3️⃣  測試後端 API"
echo "-------------------"
print_info "測試 http://localhost:5000/api/students"
if curl -s --max-time 5 "http://localhost:5000/api/students" > /dev/null 2>&1; then
    print_ok "後端 API 正常回應"
    STUDENT_COUNT=$(curl -s "http://localhost:5000/api/students" | grep -o '\[' | wc -l)
    echo "   學生數量: $STUDENT_COUNT"
else
    print_fail "後端 API 無法訪問"
fi
echo ""

# 4. 測試前端服務
echo "4️⃣  測試前端服務"
echo "-------------------"
print_info "測試 http://localhost:3000"
if curl -s --max-time 5 "http://localhost:3000" > /dev/null 2>&1; then
    print_ok "前端服務正常回應"
else
    print_fail "前端服務無法訪問"
fi
echo ""

# 5. 測試 Nginx
echo "5️⃣  測試 Nginx"
echo "-------------------"
if command -v nginx &> /dev/null; then
    if sudo systemctl is-active --quiet nginx; then
        print_ok "Nginx 正在運行"
        
        # 測試 Nginx 配置
        if sudo nginx -t 2>&1 | grep -q "successful"; then
            print_ok "Nginx 配置正確"
        else
            print_fail "Nginx 配置有誤"
            sudo nginx -t
        fi
        
        # 測試通過 Nginx 訪問
        print_info "測試 http://localhost/api/students"
        if curl -s --max-time 5 "http://localhost/api/students" > /dev/null 2>&1; then
            print_ok "通過 Nginx 訪問 API 成功"
        else
            print_fail "通過 Nginx 訪問 API 失敗"
        fi
    else
        print_fail "Nginx 未運行"
    fi
else
    print_warning "Nginx 未安裝"
fi
echo ""

# 6. 檢查資料庫
echo "6️⃣  檢查資料庫"
echo "-------------------"
if [ -f "tutoring.db" ]; then
    print_ok "資料庫檔案存在"
    DB_SIZE=$(du -h tutoring.db | cut -f1)
    echo "   大小: $DB_SIZE"
    
    # 檢查資料表
    if command -v sqlite3 &> /dev/null; then
        TABLES=$(sqlite3 tutoring.db ".tables")
        print_ok "資料表: $TABLES"
    fi
else
    print_fail "找不到資料庫檔案"
fi
echo ""

# 7. 檢查日誌
echo "7️⃣  最近的錯誤日誌"
echo "-------------------"
if [ -d "$HOME/.pm2/logs" ]; then
    print_info "後端錯誤日誌 (最後 10 行):"
    tail -n 10 $HOME/.pm2/logs/tutoring-backend-error.log 2>/dev/null || echo "   無錯誤日誌"
    echo ""
    print_info "前端錯誤日誌 (最後 10 行):"
    tail -n 10 $HOME/.pm2/logs/tutoring-frontend-error.log 2>/dev/null || echo "   無錯誤日誌"
fi
echo ""

# 8. 系統資源
echo "8️⃣  系統資源"
echo "-------------------"
echo "記憶體使用:"
free -h | grep Mem
echo ""
echo "磁碟使用:"
df -h / | tail -n 1
echo ""

# 9. 測試新增學生 API
echo "9️⃣  測試新增學生 API"
echo "-------------------"
print_info "發送測試請求..."
RESPONSE=$(curl -s -X POST http://localhost:5000/api/students \
  -H "Content-Type: application/json" \
  -d '{
    "name": "測試學生",
    "english_name": "Test Student",
    "birth_date": "2010-01-01",
    "school_class": "測試班級",
    "phone": "0912345678",
    "email": "test@example.com",
    "address": "測試地址",
    "parent_name": "測試家長",
    "parent_phone": "0987654321"
  }' 2>&1)

if echo "$RESPONSE" | grep -q "學生新增成功"; then
    print_ok "新增學生 API 測試成功"
    echo "   回應: $RESPONSE"
    
    # 刪除測試學生
    STUDENT_ID=$(echo "$RESPONSE" | grep -o '"id":[0-9]*' | grep -o '[0-9]*')
    if [ ! -z "$STUDENT_ID" ]; then
        curl -s -X DELETE "http://localhost:5000/api/students/$STUDENT_ID" > /dev/null 2>&1
        print_info "已清理測試資料"
    fi
else
    print_fail "新增學生 API 測試失敗"
    echo "   回應: $RESPONSE"
fi
echo ""

echo "================================"
echo "診斷完成！"
echo ""
echo "💡 建議："
echo "  - 如果後端 API 失敗，執行: pm2 restart tutoring-backend"
echo "  - 如果前端服務失敗，執行: pm2 restart tutoring-frontend"
echo "  - 如果 Nginx 有問題，執行: sudo systemctl restart nginx"
echo "  - 查看詳細日誌: pm2 logs"
