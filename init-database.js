#!/usr/bin/env node

/**
 * 資料庫初始化腳本
 * 用於確保在部署時資料庫和所有資料表都正確建立
 */

const sqlite3 = require('sqlite3').verbose();
const path = require('path');

console.log('🗄️  開始初始化資料庫...');

// 建立資料庫連接
const dbPath = path.join(__dirname, 'tutoring.db');
const db = new sqlite3.Database(dbPath, (err) => {
  if (err) {
    console.error('❌ 資料庫連接失敗:', err.message);
    process.exit(1);
  }
  console.log('✅ 資料庫連接成功:', dbPath);
});

// 初始化所有資料表
db.serialize(() => {
  console.log('📋 開始建立資料表...');

  // 1. 學生資料表
  db.run(`CREATE TABLE IF NOT EXISTS students (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    english_name TEXT,
    birth_date DATE,
    school_class TEXT,
    phone TEXT,
    email TEXT,
    address TEXT,
    parent_name TEXT,
    parent_phone TEXT,
    enrollment_date DATE DEFAULT CURRENT_DATE,
    status TEXT DEFAULT 'active',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  )`, (err) => {
    if (err) {
      console.error('❌ 建立 students 表失敗:', err.message);
    } else {
      console.log('✅ students 表建立成功');
    }
  });

  // 2. 課程資料表
  db.run(`CREATE TABLE IF NOT EXISTS courses (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    description TEXT,
    price_monthly DECIMAL(10,2),
    price_quarterly DECIMAL(10,2),
    price_semi_annual DECIMAL(10,2),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  )`, (err) => {
    if (err) {
      console.error('❌ 建立 courses 表失敗:', err.message);
    } else {
      console.log('✅ courses 表建立成功');
    }
  });

  // 3. 學生課程關聯表
  db.run(`CREATE TABLE IF NOT EXISTS student_courses (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    student_id INTEGER,
    course_id INTEGER,
    payment_type TEXT CHECK(payment_type IN ('monthly', 'quarterly', 'semi_annual')),
    start_date DATE,
    end_date DATE,
    status TEXT DEFAULT 'active',
    FOREIGN KEY (student_id) REFERENCES students (id),
    FOREIGN KEY (course_id) REFERENCES courses (id)
  )`, (err) => {
    if (err) {
      console.error('❌ 建立 student_courses 表失敗:', err.message);
    } else {
      console.log('✅ student_courses 表建立成功');
    }
  });

  // 4. 繳費記錄表
  db.run(`CREATE TABLE IF NOT EXISTS payments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    student_id INTEGER,
    course_id INTEGER,
    fee_item TEXT NOT NULL,
    fee_date DATE NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    deposit_amount DECIMAL(10,2) DEFAULT 0,
    remaining_amount DECIMAL(10,2) DEFAULT 0,
    paid_amount DECIMAL(10,2) DEFAULT 0,
    payment_type TEXT CHECK(payment_type IN ('monthly', 'quarterly', 'semi_annual')),
    payment_stage TEXT DEFAULT 'deposit' CHECK(payment_stage IN ('deposit', 'remaining', 'full', 'completed')),
    payment_date DATE DEFAULT CURRENT_DATE,
    due_date DATE,
    status TEXT DEFAULT 'pending' CHECK(status IN ('paid', 'pending', 'overdue', 'partial')),
    notes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students (id),
    FOREIGN KEY (course_id) REFERENCES courses (id)
  )`, (err) => {
    if (err) {
      console.error('❌ 建立 payments 表失敗:', err.message);
    } else {
      console.log('✅ payments 表建立成功');
    }
  });

  // 5. 繳費明細表
  db.run(`CREATE TABLE IF NOT EXISTS payment_details (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    payment_id INTEGER,
    amount DECIMAL(10,2) NOT NULL,
    payment_stage TEXT CHECK(payment_stage IN ('deposit', 'remaining', 'full')),
    payment_date DATE DEFAULT CURRENT_DATE,
    payment_method TEXT DEFAULT 'cash',
    notes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (payment_id) REFERENCES payments (id)
  )`, (err) => {
    if (err) {
      console.error('❌ 建立 payment_details 表失敗:', err.message);
    } else {
      console.log('✅ payment_details 表建立成功');
    }
  });

  // 6. 插入一些測試資料（如果表是空的）
  db.get("SELECT COUNT(*) as count FROM students", (err, row) => {
    if (err) {
      console.error('❌ 檢查學生資料失敗:', err.message);
      return;
    }

    if (row.count === 0) {
      console.log('📝 插入測試資料...');
      
      // 插入測試學生
      db.run(`INSERT INTO students (name, english_name, phone, email, school_class, parent_name, parent_phone) 
              VALUES (?, ?, ?, ?, ?, ?, ?)`,
        ['測試學生', 'Test Student', '0912345678', 'test@example.com', '國中一年級', '測試家長', '0987654321'],
        (err) => {
          if (err) {
            console.error('❌ 插入測試學生失敗:', err.message);
          } else {
            console.log('✅ 測試學生資料插入成功');
          }
        }
      );

      // 插入測試課程
      db.run(`INSERT INTO courses (name, description, price_monthly, price_quarterly, price_semi_annual) 
              VALUES (?, ?, ?, ?, ?)`,
        ['數學課程', '國中數學基礎課程', 3000, 8500, 16000],
        (err) => {
          if (err) {
            console.error('❌ 插入測試課程失敗:', err.message);
          } else {
            console.log('✅ 測試課程資料插入成功');
          }
        }
      );
    } else {
      console.log(`ℹ️  資料庫已有 ${row.count} 筆學生資料，跳過測試資料插入`);
    }
  });

  // 7. 驗證資料表結構
  setTimeout(() => {
    console.log('🔍 驗證資料表結構...');
    
    const tables = ['students', 'courses', 'student_courses', 'payments', 'payment_details'];
    let completed = 0;
    
    tables.forEach(tableName => {
      db.all(`PRAGMA table_info(${tableName})`, (err, columns) => {
        if (err) {
          console.error(`❌ 檢查 ${tableName} 表結構失敗:`, err.message);
        } else {
          console.log(`✅ ${tableName} 表結構正確 (${columns.length} 個欄位)`);
        }
        
        completed++;
        if (completed === tables.length) {
          console.log('🎉 資料庫初始化完成！');
          console.log('');
          console.log('📋 使用說明:');
          console.log('  - 資料庫檔案: tutoring.db');
          console.log('  - 可以開始使用 API 進行學生、課程、繳費管理');
          console.log('  - 如需重新初始化，請刪除 tutoring.db 後重新執行此腳本');
          console.log('');
          
          db.close((err) => {
            if (err) {
              console.error('❌ 關閉資料庫連接失敗:', err.message);
            } else {
              console.log('✅ 資料庫連接已關閉');
            }
            process.exit(0);
          });
        }
      });
    });
  }, 1000);
});