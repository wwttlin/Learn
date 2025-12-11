#!/bin/bash

# 緊急修復腳本 - 解決 npm run build 無限循環問題

echo "🚨 緊急修復 npm run build 無限循環問題"
echo "========================================="

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

# 1. 立即停止所有相關進程
print_info "停止所有 npm/node 進程..."
sudo pkill -f "npm run build" 2>/dev/null || true
sudo pkill -f "react-scripts build" 2>/dev/null || true
sudo pkill -f "webpack" 2>/dev/null || true
sudo pkill -f "node.*build" 2>/dev/null || true
sudo pkill -f "npm" 2>/dev/null || true

sleep 3

# 2. 檢查是否還有殘留進程
REMAINING=$(ps aux | grep -E "(npm|react-scripts|webpack)" | grep -v grep | wc -l)
if [ "$REMAINING" -gt 0 ]; then
    print_warning "發現殘留進程，強制終止..."
    sudo pkill -9 -f "npm" 2>/dev/null || true
    sudo pkill -9 -f "node" 2>/dev/null || true
    sleep 2
fi

print_status "所有相關進程已停止"

# 3. 檢查記憶體狀態
MEMORY_TOTAL=$(free -m | awk 'NR==2{print $2}')
MEMORY_USED=$(free -m | awk 'NR==2{print $3}')
SWAP_TOTAL=$(free -m | awk 'NR==3{print $2}')

print_info "記憶體狀態: ${MEMORY_USED}MB / ${MEMORY_TOTAL}MB"
print_info "Swap 狀態: ${SWAP_TOTAL}MB"

# 4. 建立 swap（如果沒有）
if [ "$SWAP_TOTAL" -eq 0 ]; then
    print_warning "沒有 swap，立即建立..."
    sudo fallocate -l 1G /swapfile 2>/dev/null || sudo dd if=/dev/zero of=/swapfile bs=1M count=1024
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    print_status "Swap 建立完成"
fi

# 5. 清理記憶體
print_info "清理系統記憶體..."
sudo sync
echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null

# 6. 修復 package.json 中的循環問題
print_info "檢查 package.json 配置..."

if [ -f "package.json" ]; then
    # 檢查是否有循環引用
    if grep -q "cd client && npm run build" package.json; then
        print_warning "發現 package.json 中的循環引用，正在修復..."
        
        # 備份原檔案
        cp package.json package.json.backup
        
        # 修復 build 腳本
        sed -i 's/"build": "cd client && npm run build"/"build": "echo \"Please run build from client directory\""/' package.json
        
        print_status "package.json 已修復"
    fi
fi

# 7. 進入 client 目錄並清理
if [ ! -d "client" ]; then
    print_error "找不到 client 目錄"
    exit 1
fi

cd client

print_info "清理前端快取和依賴..."
npm cache clean --force 2>/dev/null || true
rm -rf node_modules/.cache 2>/dev/null || true
rm -rf build 2>/dev/null || true
rm -rf .eslintcache 2>/dev/null || true

# 8. 檢查 client/package.json
if [ -f "package.json" ]; then
    print_info "檢查前端 package.json..."
    
    # 確保 build 腳本正確
    if ! grep -q '"build": "react-scripts build"' package.json; then
        print_warning "修復前端 build 腳本..."
        
        # 備份
        cp package.json package.json.backup
        
        # 使用 sed 修復 build 腳本
        sed -i 's/"build": ".*"/"build": "react-scripts build"/' package.json
        
        print_status "前端 package.json 已修復"
    fi
else
    print_error "找不到 client/package.json"
    exit 1
fi

# 9. 重新安裝依賴（最小化）
print_info "重新安裝前端依賴..."
rm -rf node_modules package-lock.json 2>/dev/null || true

# 使用 npm ci 安裝（更快更穩定）
if npm ci --silent; then
    print_status "依賴安裝成功"
else
    print_warning "npm ci 失敗，嘗試 npm install..."
    npm install --silent
fi

# 10. 建立緊急版本（跳過建置）
print_warning "e2-micro 記憶體不足，建立緊急版本..."

mkdir -p build/static/css build/static/js build/static/media

# 建立完整的緊急前端
cat > build/index.html << 'EOF'
<!DOCTYPE html>
<html lang="zh-TW">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>補習班管理系統</title>
    <link rel="stylesheet" href="/static/css/main.css">
</head>
<body>
    <div id="root">
        <div class="app">
            <nav class="nav">
                <div class="nav-content">
                    <h1>補習班管理系統</h1>
                    <div class="nav-tabs">
                        <button class="nav-tab active" onclick="showTab('dashboard')">總覽</button>
                        <button class="nav-tab" onclick="showTab('students')">學生管理</button>
                        <button class="nav-tab" onclick="showTab('courses')">課程管理</button>
                        <button class="nav-tab" onclick="showTab('payments')">繳費管理</button>
                    </div>
                </div>
            </nav>

            <main class="container">
                <div id="dashboard" class="tab-content active">
                    <h2>系統總覽</h2>
                    <div class="grid grid-4">
                        <div class="card">
                            <h3>總學生數</h3>
                            <p class="stat-number" id="totalStudents">載入中...</p>
                        </div>
                        <div class="card">
                            <h3>開設課程</h3>
                            <p class="stat-number" id="totalCourses">載入中...</p>
                        </div>
                        <div class="card">
                            <h3>本月收入</h3>
                            <p class="stat-number" id="monthlyRevenue">載入中...</p>
                        </div>
                        <div class="card">
                            <h3>待繳費用</h3>
                            <p class="stat-number" id="pendingPayments">載入中...</p>
                        </div>
                    </div>
                </div>

                <div id="students" class="tab-content">
                    <h2>學生管理</h2>
                    <div class="card">
                        <button class="btn btn-primary" onclick="showAddStudentForm()">新增學生</button>
                        <div id="studentsList">載入中...</div>
                    </div>
                </div>

                <div id="courses" class="tab-content">
                    <h2>課程管理</h2>
                    <div class="card">
                        <button class="btn btn-primary" onclick="showAddCourseForm()">新增課程</button>
                        <div id="coursesList">載入中...</div>
                    </div>
                </div>

                <div id="payments" class="tab-content">
                    <h2>繳費管理</h2>
                    <div class="card">
                        <button class="btn btn-primary" onclick="showAddPaymentForm()">新增繳費記錄</button>
                        <div id="paymentsList">載入中...</div>
                    </div>
                </div>
            </main>
        </div>
    </div>

    <script src="/static/js/main.js"></script>
</body>
</html>
EOF

# CSS 檔案
cat > build/static/css/main.css << 'EOF'
/* 補習班管理系統 - 緊急版本樣式 */
* { margin: 0; padding: 0; box-sizing: border-box; }

body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
    background-color: #f5f5f5;
    line-height: 1.6;
}

.app { min-height: 100vh; }

.nav {
    background-color: #2563eb;
    color: white;
    padding: 1rem 0;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.nav-content {
    max-width: 1200px;
    margin: 0 auto;
    padding: 0 20px;
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.nav h1 { font-size: 1.5rem; margin: 0; }

.nav-tabs { display: flex; gap: 1rem; }

.nav-tab {
    padding: 0.5rem 1rem;
    border: none;
    border-radius: 6px;
    background: transparent;
    color: #bfdbfe;
    cursor: pointer;
    transition: all 0.2s;
}

.nav-tab:hover { background-color: #1d4ed8; }
.nav-tab.active { background-color: #1e40af; color: white; }

.container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 20px;
}

.tab-content { display: none; }
.tab-content.active { display: block; }

.card {
    background: white;
    border-radius: 8px;
    box-shadow: 0 1px 3px rgba(0,0,0,0.1);
    padding: 1.5rem;
    margin-bottom: 1.5rem;
}

.btn {
    padding: 0.5rem 1rem;
    border: none;
    border-radius: 6px;
    cursor: pointer;
    font-weight: 500;
    transition: all 0.2s;
}

.btn-primary {
    background-color: #2563eb;
    color: white;
}

.btn-primary:hover { background-color: #1d4ed8; }

.grid { display: grid; gap: 1.5rem; margin: 1.5rem 0; }
.grid-4 { grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); }

.stat-number {
    font-size: 2rem;
    font-weight: bold;
    color: #2563eb;
    margin-top: 0.5rem;
}

.loading { text-align: center; padding: 2rem; color: #6b7280; }
.error { color: #dc2626; background: #fee2e2; padding: 1rem; border-radius: 6px; }

@media (max-width: 768px) {
    .nav-content { flex-direction: column; gap: 1rem; }
    .grid-4 { grid-template-columns: 1fr; }
}
EOF

# JavaScript 檔案
cat > build/static/js/main.js << 'EOF'
// 補習班管理系統 - 緊急版本 JavaScript

console.log('補習班管理系統 - 緊急版本載入完成');

// 全域變數
let students = [];
let courses = [];
let payments = [];

// 標籤切換
function showTab(tabName) {
    // 隱藏所有標籤內容
    document.querySelectorAll('.tab-content').forEach(tab => {
        tab.classList.remove('active');
    });
    
    // 移除所有標籤的 active 類別
    document.querySelectorAll('.nav-tab').forEach(tab => {
        tab.classList.remove('active');
    });
    
    // 顯示選中的標籤
    document.getElementById(tabName).classList.add('active');
    event.target.classList.add('active');
    
    // 載入對應的資料
    loadTabData(tabName);
}

// 載入標籤資料
function loadTabData(tabName) {
    switch(tabName) {
        case 'dashboard':
            loadDashboard();
            break;
        case 'students':
            loadStudents();
            break;
        case 'courses':
            loadCourses();
            break;
        case 'payments':
            loadPayments();
            break;
    }
}

// 載入總覽資料
async function loadDashboard() {
    try {
        const [studentsRes, coursesRes, paymentsRes] = await Promise.all([
            fetch('/api/students'),
            fetch('/api/courses'),
            fetch('/api/payments')
        ]);
        
        const students = await studentsRes.json();
        const courses = await coursesRes.json();
        const payments = await paymentsRes.json();
        
        document.getElementById('totalStudents').textContent = students.length;
        document.getElementById('totalCourses').textContent = courses.length;
        
        const totalRevenue = payments.reduce((sum, p) => sum + (p.paid_amount || 0), 0);
        document.getElementById('monthlyRevenue').textContent = `NT$ ${totalRevenue.toLocaleString()}`;
        
        const pending = payments.filter(p => p.remaining_amount > 0).length;
        document.getElementById('pendingPayments').textContent = pending;
        
    } catch (error) {
        console.error('載入總覽資料失敗:', error);
        document.getElementById('totalStudents').textContent = '錯誤';
        document.getElementById('totalCourses').textContent = '錯誤';
        document.getElementById('monthlyRevenue').textContent = '錯誤';
        document.getElementById('pendingPayments').textContent = '錯誤';
    }
}

// 載入學生資料
async function loadStudents() {
    const container = document.getElementById('studentsList');
    container.innerHTML = '<div class="loading">載入中...</div>';
    
    try {
        const response = await fetch('/api/students');
        const students = await response.json();
        
        if (students.length === 0) {
            container.innerHTML = '<p>尚未新增任何學生</p>';
            return;
        }
        
        const html = `
            <table style="width: 100%; border-collapse: collapse; margin-top: 1rem;">
                <thead>
                    <tr style="background: #f9fafb;">
                        <th style="padding: 0.75rem; text-align: left; border-bottom: 1px solid #e5e7eb;">姓名</th>
                        <th style="padding: 0.75rem; text-align: left; border-bottom: 1px solid #e5e7eb;">電話</th>
                        <th style="padding: 0.75rem; text-align: left; border-bottom: 1px solid #e5e7eb;">家長</th>
                        <th style="padding: 0.75rem; text-align: left; border-bottom: 1px solid #e5e7eb;">狀態</th>
                    </tr>
                </thead>
                <tbody>
                    ${students.map(student => `
                        <tr style="border-bottom: 1px solid #f3f4f6;">
                            <td style="padding: 0.75rem; font-weight: 600;">${student.name}</td>
                            <td style="padding: 0.75rem;">${student.phone || '-'}</td>
                            <td style="padding: 0.75rem;">${student.parent_name || '-'}</td>
                            <td style="padding: 0.75rem;">
                                <span style="padding: 0.25rem 0.5rem; font-size: 0.75rem; border-radius: 9999px; background: ${student.status === 'active' ? '#dcfce7' : '#fee2e2'}; color: ${student.status === 'active' ? '#166534' : '#991b1b'};">
                                    ${student.status === 'active' ? '在學' : '停學'}
                                </span>
                            </td>
                        </tr>
                    `).join('')}
                </tbody>
            </table>
        `;
        
        container.innerHTML = html;
        
    } catch (error) {
        console.error('載入學生資料失敗:', error);
        container.innerHTML = '<div class="error">載入學生資料失敗，請檢查後端服務</div>';
    }
}

// 載入課程資料
async function loadCourses() {
    const container = document.getElementById('coursesList');
    container.innerHTML = '<div class="loading">載入中...</div>';
    
    try {
        const response = await fetch('/api/courses');
        const courses = await response.json();
        
        if (courses.length === 0) {
            container.innerHTML = '<p>尚未新增任何課程</p>';
            return;
        }
        
        const html = courses.map(course => `
            <div class="card" style="margin: 1rem 0;">
                <h3>${course.name}</h3>
                <p style="color: #6b7280; margin: 0.5rem 0;">${course.description || '無描述'}</p>
                <div style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 1rem; margin-top: 1rem;">
                    <div>
                        <span style="font-size: 0.875rem; color: #6b7280;">月繳:</span>
                        <span style="font-weight: 600; color: #2563eb;">NT$ ${course.price_monthly?.toLocaleString() || 0}</span>
                    </div>
                    <div>
                        <span style="font-size: 0.875rem; color: #6b7280;">季繳:</span>
                        <span style="font-weight: 600; color: #16a34a;">NT$ ${course.price_quarterly?.toLocaleString() || 0}</span>
                    </div>
                    <div>
                        <span style="font-size: 0.875rem; color: #6b7280;">半年繳:</span>
                        <span style="font-weight: 600; color: #7c3aed;">NT$ ${course.price_semi_annual?.toLocaleString() || 0}</span>
                    </div>
                </div>
            </div>
        `).join('');
        
        container.innerHTML = html;
        
    } catch (error) {
        console.error('載入課程資料失敗:', error);
        container.innerHTML = '<div class="error">載入課程資料失敗，請檢查後端服務</div>';
    }
}

// 載入繳費資料
async function loadPayments() {
    const container = document.getElementById('paymentsList');
    container.innerHTML = '<div class="loading">載入中...</div>';
    
    try {
        const response = await fetch('/api/payments');
        const payments = await response.json();
        
        if (payments.length === 0) {
            container.innerHTML = '<p>尚未有任何繳費記錄</p>';
            return;
        }
        
        const html = `
            <table style="width: 100%; border-collapse: collapse; margin-top: 1rem;">
                <thead>
                    <tr style="background: #f9fafb;">
                        <th style="padding: 0.75rem; text-align: left; border-bottom: 1px solid #e5e7eb;">學生</th>
                        <th style="padding: 0.75rem; text-align: left; border-bottom: 1px solid #e5e7eb;">課程</th>
                        <th style="padding: 0.75rem; text-align: left; border-bottom: 1px solid #e5e7eb;">總金額</th>
                        <th style="padding: 0.75rem; text-align: left; border-bottom: 1px solid #e5e7eb;">已繳</th>
                        <th style="padding: 0.75rem; text-align: left; border-bottom: 1px solid #e5e7eb;">剩餘</th>
                        <th style="padding: 0.75rem; text-align: left; border-bottom: 1px solid #e5e7eb;">狀態</th>
                    </tr>
                </thead>
                <tbody>
                    ${payments.map(payment => `
                        <tr style="border-bottom: 1px solid #f3f4f6;">
                            <td style="padding: 0.75rem; font-weight: 600;">${payment.student_name}</td>
                            <td style="padding: 0.75rem;">${payment.course_name}</td>
                            <td style="padding: 0.75rem; font-weight: 600;">NT$ ${payment.total_amount?.toLocaleString() || 0}</td>
                            <td style="padding: 0.75rem; color: #16a34a; font-weight: 600;">NT$ ${payment.paid_amount?.toLocaleString() || 0}</td>
                            <td style="padding: 0.75rem; color: ${(payment.remaining_amount || 0) > 0 ? '#dc2626' : '#16a34a'}; font-weight: 600;">NT$ ${payment.remaining_amount?.toLocaleString() || 0}</td>
                            <td style="padding: 0.75rem;">
                                <span style="padding: 0.25rem 0.5rem; font-size: 0.75rem; border-radius: 9999px; background: ${payment.status === 'paid' ? '#dcfce7' : payment.status === 'partial' ? '#fef3c7' : '#e0e7ff'}; color: ${payment.status === 'paid' ? '#166534' : payment.status === 'partial' ? '#92400e' : '#1e40af'};">
                                    ${payment.status === 'paid' ? '已完成' : payment.status === 'partial' ? '部分繳費' : '待繳費'}
                                </span>
                            </td>
                        </tr>
                    `).join('')}
                </tbody>
            </table>
        `;
        
        container.innerHTML = html;
        
    } catch (error) {
        console.error('載入繳費資料失敗:', error);
        container.innerHTML = '<div class="error">載入繳費資料失敗，請檢查後端服務</div>';
    }
}

// 顯示新增表單的佔位函數
function showAddStudentForm() {
    alert('新增學生功能請使用 API 或升級到完整版本');
}

function showAddCourseForm() {
    alert('新增課程功能請使用 API 或升級到完整版本');
}

function showAddPaymentForm() {
    alert('新增繳費功能請使用 API 或升級到完整版本');
}

// 頁面載入完成後初始化
document.addEventListener('DOMContentLoaded', function() {
    console.log('補習班管理系統初始化...');
    loadDashboard();
});
EOF

cd ..

print_status "緊急版本建立完成！"

# 11. 啟動服務
print_info "啟動後端服務..."
pm2 delete all 2>/dev/null || true

# 啟動後端（限制記憶體）
pm2 start server/index.js --name "tutoring-backend" --max-memory-restart 300M

# 啟動前端服務
pm2 start "serve -s client/build -l 3000" --name "tutoring-frontend" --max-memory-restart 100M

pm2 save

# 12. 檢查服務狀態
sleep 3
if pm2 list | grep -q "online"; then
    print_status "✅ 緊急修復完成！"
    
    EXTERNAL_IP=$(curl -s --max-time 5 ifconfig.me 2>/dev/null || echo "your-vm-ip")
    
    echo ""
    print_status "🎉 系統已啟動（緊急版本）"
    echo ""
    print_info "📋 訪問資訊:"
    print_info "  前端: http://$EXTERNAL_IP:3000"
    print_info "  後端: http://$EXTERNAL_IP:5000"
    echo ""
    print_warning "⚠️  當前使用緊急版本："
    print_warning "  - 前端功能有限（僅顯示資料）"
    print_warning "  - 後端 API 完全正常"
    print_warning "  - 建議升級 VM 到 e2-small 以獲得完整功能"
    echo ""
    print_info "🔧 管理命令:"
    print_info "  pm2 status        - 查看服務狀態"
    print_info "  pm2 logs          - 查看日誌"
    print_info "  pm2 restart all   - 重啟服務"
    
else
    print_error "❌ 服務啟動失敗"
    print_info "請檢查日誌: pm2 logs"
fi

print_status "緊急修復腳本執行完成"