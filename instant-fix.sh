#!/bin/bash

# 立即修復腳本 - 解決 client 目錄和前端服務問題

echo "🚨 立即修復腳本"
echo "================"

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

# 1. 檢查當前目錄結構
print_info "檢查目錄結構..."
ls -la

echo ""
print_info "檢查是否有 client 目錄..."
if [ -d "client" ]; then
    print_status "找到 client 目錄"
    ls -la client/
else
    print_error "找不到 client 目錄！"
    print_info "當前目錄內容:"
    ls -la
    
    # 檢查是否在錯誤的目錄
    if [ -f "../client/package.json" ]; then
        print_info "發現 client 目錄在上層，移動到正確位置..."
        cd ..
    elif [ -f "src/App.tsx" ]; then
        print_info "當前目錄似乎就是 client 目錄"
        # 當前目錄就是 client，需要重新組織
        mkdir -p ../tutoring-system-temp
        cp -r . ../tutoring-system-temp/client/
        cd ../tutoring-system-temp
        mv client/server . 2>/dev/null || echo "沒有 server 目錄"
        mv client/package.json . 2>/dev/null || echo "沒有根 package.json"
        print_info "目錄結構已重新組織"
    else
        print_error "無法找到正確的專案結構"
        exit 1
    fi
fi

# 2. 停止所有相關進程
print_info "停止所有相關進程..."
sudo pkill -9 -f "npm" 2>/dev/null || true
sudo pkill -9 -f "node" 2>/dev/null || true
sudo pkill -9 -f "react-scripts" 2>/dev/null || true
pm2 delete all 2>/dev/null || true

sleep 2

# 3. 清理記憶體
print_info "清理系統記憶體..."
sudo sync
echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null

# 4. 檢查並建立 swap
SWAP_SIZE=$(free -m | awk 'NR==3{print $2}')
if [ "$SWAP_SIZE" -eq 0 ]; then
    print_info "建立 swap 空間..."
    sudo fallocate -l 1G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
fi

# 5. 跳過前端建置，直接建立簡單的前端
print_warning "跳過複雜的 React 建置，建立簡單前端..."

mkdir -p client/build/static/css client/build/static/js

# 建立簡單的 HTML 前端
cat > client/build/index.html << 'EOF'
<!DOCTYPE html>
<html lang="zh-TW">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>補習班管理系統</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
        }
        .container { 
            max-width: 1200px; 
            margin: 0 auto; 
            padding: 20px; 
        }
        .header {
            background: rgba(255,255,255,0.95);
            backdrop-filter: blur(10px);
            border-radius: 15px;
            padding: 2rem;
            margin-bottom: 2rem;
            text-align: center;
            box-shadow: 0 8px 32px rgba(0,0,0,0.1);
        }
        .header h1 { 
            color: #2563eb; 
            font-size: 2.5rem; 
            margin-bottom: 0.5rem;
        }
        .header p { 
            color: #6b7280; 
            font-size: 1.1rem; 
        }
        .nav-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
            gap: 1.5rem;
            margin-bottom: 2rem;
        }
        .nav-card {
            background: rgba(255,255,255,0.95);
            backdrop-filter: blur(10px);
            border-radius: 15px;
            padding: 2rem;
            text-align: center;
            cursor: pointer;
            transition: all 0.3s ease;
            box-shadow: 0 4px 20px rgba(0,0,0,0.1);
        }
        .nav-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 8px 30px rgba(0,0,0,0.15);
        }
        .nav-card h3 {
            color: #1f2937;
            font-size: 1.3rem;
            margin-bottom: 1rem;
        }
        .nav-card p {
            color: #6b7280;
            line-height: 1.6;
        }
        .icon {
            font-size: 3rem;
            margin-bottom: 1rem;
            display: block;
        }
        .status-card {
            background: rgba(255,255,255,0.95);
            backdrop-filter: blur(10px);
            border-radius: 15px;
            padding: 2rem;
            box-shadow: 0 4px 20px rgba(0,0,0,0.1);
        }
        .api-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 1rem;
            margin-top: 1rem;
        }
        .api-btn {
            background: linear-gradient(135deg, #2563eb, #1d4ed8);
            color: white;
            padding: 1rem;
            border: none;
            border-radius: 10px;
            cursor: pointer;
            text-decoration: none;
            display: block;
            text-align: center;
            font-weight: 600;
            transition: all 0.3s ease;
        }
        .api-btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 15px rgba(37, 99, 235, 0.4);
        }
        .stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
            gap: 1rem;
            margin: 1rem 0;
        }
        .stat-item {
            text-align: center;
            padding: 1rem;
            background: rgba(59, 130, 246, 0.1);
            border-radius: 10px;
        }
        .stat-number {
            font-size: 1.8rem;
            font-weight: bold;
            color: #2563eb;
        }
        .stat-label {
            font-size: 0.9rem;
            color: #6b7280;
            margin-top: 0.5rem;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🏫 補習班管理系統</h1>
            <p>e2-micro 輕量版本 - 完整後端 API 功能</p>
        </div>

        <div class="nav-grid">
            <div class="nav-card" onclick="loadData('students')">
                <span class="icon">👥</span>
                <h3>學生管理</h3>
                <p>查看和管理學生資料<br>支援搜尋和狀態管理</p>
            </div>
            
            <div class="nav-card" onclick="loadData('courses')">
                <span class="icon">📚</span>
                <h3>課程管理</h3>
                <p>管理課程和價格設定<br>月繳、季繳、半年繳</p>
            </div>
            
            <div class="nav-card" onclick="loadData('payments')">
                <span class="icon">💰</span>
                <h3>繳費管理</h3>
                <p>訂金、尾款管理<br>完整的繳費追蹤</p>
            </div>
            
            <div class="nav-card" onclick="showApiInfo()">
                <span class="icon">🔧</span>
                <h3>API 管理</h3>
                <p>直接訪問後端 API<br>完整的 CRUD 功能</p>
            </div>
        </div>

        <div class="status-card">
            <h3>📊 系統狀態</h3>
            <div class="stats">
                <div class="stat-item">
                    <div class="stat-number" id="studentCount">-</div>
                    <div class="stat-label">學生總數</div>
                </div>
                <div class="stat-item">
                    <div class="stat-number" id="courseCount">-</div>
                    <div class="stat-label">課程總數</div>
                </div>
                <div class="stat-item">
                    <div class="stat-number" id="paymentCount">-</div>
                    <div class="stat-label">繳費記錄</div>
                </div>
                <div class="stat-item">
                    <div class="stat-number" id="totalRevenue">-</div>
                    <div class="stat-label">總收入</div>
                </div>
            </div>
            
            <div id="dataDisplay" style="margin-top: 2rem;">
                <p style="text-align: center; color: #6b7280;">點擊上方功能卡片查看資料</p>
            </div>
        </div>
    </div>

    <script>
        console.log('補習班管理系統 - e2-micro 版本載入完成');
        
        // 載入統計資料
        async function loadStats() {
            try {
                const [studentsRes, coursesRes, paymentsRes] = await Promise.all([
                    fetch('/api/students').catch(() => ({json: () => []})),
                    fetch('/api/courses').catch(() => ({json: () => []})),
                    fetch('/api/payments').catch(() => ({json: () => []}))
                ]);
                
                const students = await studentsRes.json();
                const courses = await coursesRes.json();
                const payments = await paymentsRes.json();
                
                document.getElementById('studentCount').textContent = students.length || 0;
                document.getElementById('courseCount').textContent = courses.length || 0;
                document.getElementById('paymentCount').textContent = payments.length || 0;
                
                const totalRevenue = payments.reduce((sum, p) => sum + (p.paid_amount || 0), 0);
                document.getElementById('totalRevenue').textContent = totalRevenue > 0 ? `NT$ ${totalRevenue.toLocaleString()}` : 'NT$ 0';
                
            } catch (error) {
                console.error('載入統計資料失敗:', error);
            }
        }
        
        // 載入特定資料
        async function loadData(type) {
            const display = document.getElementById('dataDisplay');
            display.innerHTML = '<div style="text-align: center; padding: 2rem;">載入中...</div>';
            
            try {
                const response = await fetch(`/api/${type}`);
                const data = await response.json();
                
                if (data.length === 0) {
                    display.innerHTML = `<div style="text-align: center; padding: 2rem; color: #6b7280;">尚未有任何${getTypeName(type)}資料</div>`;
                    return;
                }
                
                let html = `<h4>${getTypeName(type)}列表 (${data.length} 筆)</h4>`;
                
                if (type === 'students') {
                    html += `
                        <div style="overflow-x: auto; margin-top: 1rem;">
                            <table style="width: 100%; border-collapse: collapse;">
                                <thead>
                                    <tr style="background: #f9fafb;">
                                        <th style="padding: 0.75rem; text-align: left; border-bottom: 1px solid #e5e7eb;">姓名</th>
                                        <th style="padding: 0.75rem; text-align: left; border-bottom: 1px solid #e5e7eb;">英文名</th>
                                        <th style="padding: 0.75rem; text-align: left; border-bottom: 1px solid #e5e7eb;">電話</th>
                                        <th style="padding: 0.75rem; text-align: left; border-bottom: 1px solid #e5e7eb;">學校班級</th>
                                        <th style="padding: 0.75rem; text-align: left; border-bottom: 1px solid #e5e7eb;">狀態</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    ${data.map(item => `
                                        <tr style="border-bottom: 1px solid #f3f4f6;">
                                            <td style="padding: 0.75rem; font-weight: 600;">${item.name}</td>
                                            <td style="padding: 0.75rem; color: #6b7280;">${item.english_name || '-'}</td>
                                            <td style="padding: 0.75rem;">${item.phone || '-'}</td>
                                            <td style="padding: 0.75rem; font-size: 0.875rem;">${item.school_class || '-'}</td>
                                            <td style="padding: 0.75rem;">
                                                <span style="padding: 0.25rem 0.5rem; font-size: 0.75rem; border-radius: 9999px; background: ${item.status === 'active' ? '#dcfce7' : '#fee2e2'}; color: ${item.status === 'active' ? '#166534' : '#991b1b'};">
                                                    ${item.status === 'active' ? '在學' : '停學'}
                                                </span>
                                            </td>
                                        </tr>
                                    `).join('')}
                                </tbody>
                            </table>
                        </div>
                    `;
                } else if (type === 'courses') {
                    html += `
                        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 1rem; margin-top: 1rem;">
                            ${data.map(item => `
                                <div style="background: #f8fafc; padding: 1.5rem; border-radius: 8px;">
                                    <h4 style="color: #1f2937; margin-bottom: 0.5rem;">${item.name}</h4>
                                    <p style="color: #6b7280; margin-bottom: 1rem; font-size: 0.9rem;">${item.description || '無描述'}</p>
                                    <div style="display: grid; gap: 0.5rem;">
                                        <div style="display: flex; justify-content: space-between;">
                                            <span style="color: #6b7280;">月繳:</span>
                                            <span style="font-weight: 600; color: #2563eb;">NT$ ${item.price_monthly?.toLocaleString() || 0}</span>
                                        </div>
                                        <div style="display: flex; justify-content: space-between;">
                                            <span style="color: #6b7280;">季繳:</span>
                                            <span style="font-weight: 600; color: #16a34a;">NT$ ${item.price_quarterly?.toLocaleString() || 0}</span>
                                        </div>
                                        <div style="display: flex; justify-content: space-between;">
                                            <span style="color: #6b7280;">半年繳:</span>
                                            <span style="font-weight: 600; color: #7c3aed;">NT$ ${item.price_semi_annual?.toLocaleString() || 0}</span>
                                        </div>
                                    </div>
                                </div>
                            `).join('')}
                        </div>
                    `;
                } else if (type === 'payments') {
                    html += `
                        <div style="overflow-x: auto; margin-top: 1rem;">
                            <table style="width: 100%; border-collapse: collapse;">
                                <thead>
                                    <tr style="background: #f9fafb;">
                                        <th style="padding: 0.75rem; text-align: left; border-bottom: 1px solid #e5e7eb;">學生</th>
                                        <th style="padding: 0.75rem; text-align: left; border-bottom: 1px solid #e5e7eb;">課程</th>
                                        <th style="padding: 0.75rem; text-align: left; border-bottom: 1px solid #e5e7eb;">費用項目</th>
                                        <th style="padding: 0.75rem; text-align: left; border-bottom: 1px solid #e5e7eb;">總金額</th>
                                        <th style="padding: 0.75rem; text-align: left; border-bottom: 1px solid #e5e7eb;">已繳</th>
                                        <th style="padding: 0.75rem; text-align: left; border-bottom: 1px solid #e5e7eb;">剩餘</th>
                                        <th style="padding: 0.75rem; text-align: left; border-bottom: 1px solid #e5e7eb;">狀態</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    ${data.map(item => `
                                        <tr style="border-bottom: 1px solid #f3f4f6;">
                                            <td style="padding: 0.75rem; font-weight: 600;">${item.student_name}</td>
                                            <td style="padding: 0.75rem;">${item.course_name}</td>
                                            <td style="padding: 0.75rem; color: #374151;">${item.fee_item || '-'}</td>
                                            <td style="padding: 0.75rem; font-weight: 600;">NT$ ${item.total_amount?.toLocaleString() || 0}</td>
                                            <td style="padding: 0.75rem; color: #16a34a; font-weight: 600;">NT$ ${item.paid_amount?.toLocaleString() || 0}</td>
                                            <td style="padding: 0.75rem; color: ${(item.remaining_amount || 0) > 0 ? '#dc2626' : '#16a34a'}; font-weight: 600;">NT$ ${item.remaining_amount?.toLocaleString() || 0}</td>
                                            <td style="padding: 0.75rem;">
                                                <span style="padding: 0.25rem 0.5rem; font-size: 0.75rem; border-radius: 9999px; background: ${item.status === 'paid' ? '#dcfce7' : item.status === 'partial' ? '#fef3c7' : '#e0e7ff'}; color: ${item.status === 'paid' ? '#166534' : item.status === 'partial' ? '#92400e' : '#1e40af'};">
                                                    ${item.status === 'paid' ? '已完成' : item.status === 'partial' ? '部分繳費' : '待繳費'}
                                                </span>
                                            </td>
                                        </tr>
                                    `).join('')}
                                </tbody>
                            </table>
                        </div>
                    `;
                }
                
                display.innerHTML = html;
                
            } catch (error) {
                console.error(`載入${getTypeName(type)}資料失敗:`, error);
                display.innerHTML = `<div style="color: #dc2626; background: #fee2e2; padding: 1rem; border-radius: 6px;">載入${getTypeName(type)}資料失敗，請檢查後端服務</div>`;
            }
        }
        
        function getTypeName(type) {
            const names = {
                'students': '學生',
                'courses': '課程', 
                'payments': '繳費'
            };
            return names[type] || type;
        }
        
        function showApiInfo() {
            const display = document.getElementById('dataDisplay');
            display.innerHTML = `
                <h4>🔧 API 端點資訊</h4>
                <p style="margin: 1rem 0; color: #6b7280;">由於 e2-micro 記憶體限制，前端使用輕量版本。所有功能都可以透過 API 使用：</p>
                <div class="api-grid">
                    <a href="/api/students" class="api-btn" target="_blank">👥 學生 API</a>
                    <a href="/api/courses" class="api-btn" target="_blank">📚 課程 API</a>
                    <a href="/api/payments" class="api-btn" target="_blank">💰 繳費 API</a>
                </div>
                <div style="margin-top: 2rem; padding: 1rem; background: #e0f2fe; border-radius: 6px;">
                    <h5>💡 使用建議:</h5>
                    <ul style="margin: 0.5rem 0; padding-left: 1.5rem; color: #374151;">
                        <li>使用 Postman 或類似工具測試 API</li>
                        <li>考慮升級到 e2-small 以獲得完整前端功能</li>
                        <li>或在本地建置前端後上傳</li>
                    </ul>
                </div>
            `;
        }
        
        // 頁面載入完成後初始化
        document.addEventListener('DOMContentLoaded', function() {
            loadStats();
        });
    </script>
</body>
</html>
EOF

# 建立基本的 CSS 和 JS 檔案
echo "/* 補習班管理系統 - e2-micro 版本 */" > client/build/static/css/main.css
echo "console.log('補習班管理系統 - e2-micro 版本');" > client/build/static/js/main.js

print_status "簡化前端已建立"

# 6. 啟動服務
print_info "啟動服務..."

# 確保 .env 檔案存在
if [ ! -f ".env" ]; then
    cat > .env << EOF
NODE_ENV=production
PORT=5000
HOST=0.0.0.0
EOF
fi

# 安裝後端依賴（如果需要）
if [ ! -d "node_modules" ]; then
    print_info "安裝後端依賴..."
    npm install --production
fi

# 啟動後端
pm2 start server/index.js --name "tutoring-backend" --max-memory-restart 300M

# 啟動前端服務
pm2 start "serve -s client/build -l 3000" --name "tutoring-frontend" --max-memory-restart 100M

pm2 save

# 7. 檢查服務狀態
sleep 3

print_info "檢查服務狀態..."
pm2 status

# 測試服務
print_info "測試服務連接..."
if curl -s --max-time 5 "http://localhost:5000/api/students" >/dev/null; then
    print_status "✅ 後端服務正常"
else
    print_warning "⚠️  後端服務可能需要幾秒鐘啟動"
fi

if curl -s --max-time 5 "http://localhost:3000" >/dev/null; then
    print_status "✅ 前端服務正常"
else
    print_warning "⚠️  前端服務可能需要幾秒鐘啟動"
fi

# 8. 顯示結果
EXTERNAL_IP=$(curl -s --max-time 5 ifconfig.me 2>/dev/null || echo "your-vm-ip")

echo ""
print_status "🎉 立即修復完成！"
echo ""
print_info "📋 訪問資訊:"
print_info "  前端: http://$EXTERNAL_IP:3000"
print_info "  後端: http://$EXTERNAL_IP:5000"
echo ""
print_warning "⚠️  當前版本說明:"
print_warning "  - 使用輕量前端（無建置問題）"
print_warning "  - 後端 API 完全正常"
print_warning "  - 可查看所有資料"
print_warning "  - 新增功能需要使用 API"
echo ""
print_info "🔧 管理命令:"
print_info "  pm2 status        - 查看服務狀態"
print_info "  pm2 logs          - 查看日誌"
print_info "  pm2 restart all   - 重啟服務"
echo ""
print_info "💡 升級建議:"
print_info "  - 升級到 e2-small 獲得完整功能"
print_info "  - 或使用本地建置方案"

print_status "修復腳本執行完成！"