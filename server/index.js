const express = require('express');
const cors = require('cors');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 5000;

// 中間件
app.use(cors());
app.use(express.json());

// 資料庫初始化
const db = new sqlite3.Database('./tutoring.db');

// 建立資料表
db.serialize(() => {
  // 檢查並更新學生資料表結構
  db.get("SELECT name FROM sqlite_master WHERE type='table' AND name='students'", (err, row) => {
    if (row) {
      // 檢查是否有新欄位
      db.all("PRAGMA table_info(students)", (err, columns) => {
        const hasEnglishName = columns && columns.some(col => col.name === 'english_name');
        const hasBirthDate = columns && columns.some(col => col.name === 'birth_date');
        const hasSchoolClass = columns && columns.some(col => col.name === 'school_class');
        
        if (!hasEnglishName || !hasBirthDate || !hasSchoolClass) {
          console.log('學生表需要更新欄位...');
          // 添加新欄位
          if (!hasEnglishName) {
            db.run("ALTER TABLE students ADD COLUMN english_name TEXT", (err) => {
              if (err) console.log('添加 english_name 欄位失敗:', err.message);
              else console.log('已添加 english_name 欄位');
            });
          }
          if (!hasBirthDate) {
            db.run("ALTER TABLE students ADD COLUMN birth_date DATE", (err) => {
              if (err) console.log('添加 birth_date 欄位失敗:', err.message);
              else console.log('已添加 birth_date 欄位');
            });
          }
          if (!hasSchoolClass) {
            db.run("ALTER TABLE students ADD COLUMN school_class TEXT", (err) => {
              if (err) console.log('添加 school_class 欄位失敗:', err.message);
              else console.log('已添加 school_class 欄位');
            });
          }
        } else {
          console.log('學生表結構已是最新版本');
        }
      });
    } else {
      // 建立新的學生資料表
      createStudentsTable();
    }
  });

  function createStudentsTable() {
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
        console.error('建立 students 表失敗:', err);
      } else {
        console.log('students 表建立成功');
      }
    });
  }

  // 課程資料表
  db.run(`CREATE TABLE IF NOT EXISTS courses (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    description TEXT,
    price_monthly DECIMAL(10,2),
    price_quarterly DECIMAL(10,2),
    price_semi_annual DECIMAL(10,2),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  )`);

  // 學生課程關聯表
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
  )`);

  // 檢查舊的 payments 表是否存在，如果存在則刪除重建
  db.get("SELECT name FROM sqlite_master WHERE type='table' AND name='payments'", (err, row) => {
    if (row) {
      console.log('發現舊的 payments 表，正在重建...');
      // 檢查是否有 fee_item 欄位
      db.get("PRAGMA table_info(payments)", (err, info) => {
        db.all("PRAGMA table_info(payments)", (err, columns) => {
          const hasFeeItem = columns && columns.some(col => col.name === 'fee_item');
          if (!hasFeeItem) {
            console.log('舊表結構不相容，正在重建...');
            db.run("DROP TABLE IF EXISTS payments", (err) => {
              if (err) {
                console.error('刪除舊表失敗:', err);
              } else {
                console.log('舊表已刪除');
              }
              createNewPaymentsTables();
            });
          } else {
            console.log('表結構已是最新版本');
            createNewPaymentsTables();
          }
        });
      });
    } else {
      createNewPaymentsTables();
    }
  });

  function createNewPaymentsTables() {
    // 繳費記錄表（新結構）
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
        console.error('建立 payments 表失敗:', err);
      } else {
        console.log('payments 表建立成功');
      }
    });

    // 繳費明細表（記錄每次實際繳費）
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
        console.error('建立 payment_details 表失敗:', err);
      } else {
        console.log('payment_details 表建立成功');
      }
    });
  }
});

// API 路由
app.get('/api/students', (req, res) => {
  db.all('SELECT * FROM students ORDER BY name', (err, rows) => {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }
    res.json(rows);
  });
});

app.post('/api/students', (req, res) => {
  const { name, english_name, birth_date, school_class, phone, email, address, parent_name, parent_phone } = req.body;
  
  db.run(
    'INSERT INTO students (name, english_name, birth_date, school_class, phone, email, address, parent_name, parent_phone) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
    [name, english_name, birth_date, school_class, phone, email, address, parent_name, parent_phone],
    function(err) {
      if (err) {
        res.status(500).json({ error: err.message });
        return;
      }
      res.json({ id: this.lastID, message: '學生新增成功' });
    }
  );
});

app.get('/api/students/:id', (req, res) => {
  const { id } = req.params;
  
  db.get('SELECT * FROM students WHERE id = ?', [id], (err, row) => {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }
    if (!row) {
      res.status(404).json({ error: '找不到該學生' });
      return;
    }
    res.json(row);
  });
});

app.put('/api/students/:id', (req, res) => {
  const { id } = req.params;
  const { name, english_name, birth_date, school_class, phone, email, address, parent_name, parent_phone, status } = req.body;
  
  db.run(
    'UPDATE students SET name = ?, english_name = ?, birth_date = ?, school_class = ?, phone = ?, email = ?, address = ?, parent_name = ?, parent_phone = ?, status = ? WHERE id = ?',
    [name, english_name, birth_date, school_class, phone, email, address, parent_name, parent_phone, status, id],
    function(err) {
      if (err) {
        res.status(500).json({ error: err.message });
        return;
      }
      if (this.changes === 0) {
        res.status(404).json({ error: '找不到該學生' });
        return;
      }
      res.json({ message: '學生資料更新成功' });
    }
  );
});

app.delete('/api/students/:id', (req, res) => {
  const { id } = req.params;
  
  // 先檢查是否有相關的繳費記錄
  db.get('SELECT COUNT(*) as count FROM payments WHERE student_id = ?', [id], (err, row) => {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }
    
    if (row.count > 0) {
      res.status(400).json({ error: '該學生有繳費記錄，無法刪除。請先將狀態設為停學。' });
      return;
    }
    
    db.run('DELETE FROM students WHERE id = ?', [id], function(err) {
      if (err) {
        res.status(500).json({ error: err.message });
        return;
      }
      if (this.changes === 0) {
        res.status(404).json({ error: '找不到該學生' });
        return;
      }
      res.json({ message: '學生刪除成功' });
    });
  });
});

app.get('/api/courses', (req, res) => {
  db.all('SELECT * FROM courses ORDER BY name', (err, rows) => {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }
    res.json(rows);
  });
});

app.post('/api/courses', (req, res) => {
  const { name, description, price_monthly, price_quarterly, price_semi_annual } = req.body;
  
  db.run(
    'INSERT INTO courses (name, description, price_monthly, price_quarterly, price_semi_annual) VALUES (?, ?, ?, ?, ?)',
    [name, description, price_monthly, price_quarterly, price_semi_annual],
    function(err) {
      if (err) {
        res.status(500).json({ error: err.message });
        return;
      }
      res.json({ id: this.lastID, message: '課程新增成功' });
    }
  );
});

app.put('/api/courses/:id', (req, res) => {
  const { id } = req.params;
  const { name, description, price_monthly, price_quarterly, price_semi_annual } = req.body;
  
  db.run(
    'UPDATE courses SET name = ?, description = ?, price_monthly = ?, price_quarterly = ?, price_semi_annual = ? WHERE id = ?',
    [name, description, price_monthly, price_quarterly, price_semi_annual, id],
    function(err) {
      if (err) {
        res.status(500).json({ error: err.message });
        return;
      }
      if (this.changes === 0) {
        res.status(404).json({ error: '找不到該課程' });
        return;
      }
      res.json({ message: '課程更新成功' });
    }
  );
});

app.delete('/api/courses/:id', (req, res) => {
  const { id } = req.params;
  
  // 先檢查是否有相關的繳費記錄
  db.get('SELECT COUNT(*) as count FROM payments WHERE course_id = ?', [id], (err, row) => {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }
    
    if (row.count > 0) {
      res.status(400).json({ error: '該課程有繳費記錄，無法刪除' });
      return;
    }
    
    db.run('DELETE FROM courses WHERE id = ?', [id], function(err) {
      if (err) {
        res.status(500).json({ error: err.message });
        return;
      }
      if (this.changes === 0) {
        res.status(404).json({ error: '找不到該課程' });
        return;
      }
      res.json({ message: '課程刪除成功' });
    });
  });
});

app.get('/api/payments', (req, res) => {
  const query = `
    SELECT p.*, s.name as student_name, c.name as course_name 
    FROM payments p
    JOIN students s ON p.student_id = s.id
    JOIN courses c ON p.course_id = c.id
    ORDER BY p.payment_date DESC
  `;
  
  db.all(query, (err, rows) => {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }
    res.json(rows);
  });
});

app.get('/api/payments/:id/details', (req, res) => {
  const { id } = req.params;
  
  db.all('SELECT * FROM payment_details WHERE payment_id = ? ORDER BY payment_date DESC', [id], (err, rows) => {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }
    res.json(rows);
  });
});

app.post('/api/payments', (req, res) => {
  console.log('收到繳費記錄請求:', req.body);
  
  const { student_id, course_id, fee_item, fee_date, total_amount, deposit_amount, payment_type, due_date, notes } = req.body;
  
  // 驗證必要欄位
  if (!student_id || !course_id || !fee_item || !fee_date || !total_amount || !payment_type) {
    console.log('缺少必要欄位');
    res.status(400).json({ error: '缺少必要欄位：學生、課程、費用項目、日期、金額和繳費方式都是必填的' });
    return;
  }
  
  const remaining_amount = total_amount - (deposit_amount || 0);
  const payment_stage = (deposit_amount || 0) >= total_amount ? 'full' : 'deposit';
  const status = (deposit_amount || 0) > 0 ? ((deposit_amount || 0) >= total_amount ? 'paid' : 'partial') : 'pending';
  
  console.log('計算結果:', { total_amount, deposit_amount, remaining_amount, payment_stage, status });
  
  db.run(
    'INSERT INTO payments (student_id, course_id, fee_item, fee_date, total_amount, deposit_amount, remaining_amount, paid_amount, payment_type, payment_stage, due_date, status, notes) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
    [student_id, course_id, fee_item, fee_date, total_amount, deposit_amount || 0, remaining_amount, deposit_amount || 0, payment_type, payment_stage, due_date, status, notes],
    function(err) {
      if (err) {
        console.error('資料庫錯誤:', err);
        res.status(500).json({ error: err.message });
        return;
      }
      
      console.log('繳費記錄新增成功，ID:', this.lastID);
      const paymentId = this.lastID;
      
      // 如果有訂金，記錄到繳費明細
      if (deposit_amount && deposit_amount > 0) {
        db.run(
          'INSERT INTO payment_details (payment_id, amount, payment_stage, notes) VALUES (?, ?, ?, ?)',
          [paymentId, deposit_amount, deposit_amount >= total_amount ? 'full' : 'deposit', '初次繳費'],
          (err) => {
            if (err) {
              console.error('記錄繳費明細失敗:', err);
            } else {
              console.log('繳費明細記錄成功');
            }
          }
        );
      }
      
      res.json({ id: paymentId, message: '繳費記錄新增成功' });
    }
  );
});

// 新增尾款繳費 API
app.post('/api/payments/:id/pay-remaining', (req, res) => {
  const { id } = req.params;
  const { amount, payment_method, notes } = req.body;
  
  // 先獲取當前繳費記錄
  db.get('SELECT * FROM payments WHERE id = ?', [id], (err, payment) => {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }
    
    if (!payment) {
      res.status(404).json({ error: '找不到繳費記錄' });
      return;
    }
    
    const newPaidAmount = payment.paid_amount + amount;
    const newRemainingAmount = payment.total_amount - newPaidAmount;
    const newStatus = newPaidAmount >= payment.total_amount ? 'paid' : 'partial';
    const newStage = newPaidAmount >= payment.total_amount ? 'completed' : 'remaining';
    
    // 更新繳費記錄
    db.run(
      'UPDATE payments SET paid_amount = ?, remaining_amount = ?, status = ?, payment_stage = ? WHERE id = ?',
      [newPaidAmount, newRemainingAmount, newStatus, newStage, id],
      function(err) {
        if (err) {
          res.status(500).json({ error: err.message });
          return;
        }
        
        // 記錄繳費明細
        db.run(
          'INSERT INTO payment_details (payment_id, amount, payment_stage, payment_method, notes) VALUES (?, ?, ?, ?, ?)',
          [id, amount, newPaidAmount >= payment.total_amount ? 'remaining' : 'remaining', payment_method || 'cash', notes || '尾款繳費'],
          (err) => {
            if (err) {
              res.status(500).json({ error: err.message });
              return;
            }
            res.json({ message: '尾款繳費成功' });
          }
        );
      }
    );
  });
});

app.delete('/api/payments/:id', (req, res) => {
  const { id } = req.params;
  
  db.run('DELETE FROM payments WHERE id = ?', [id], function(err) {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }
    if (this.changes === 0) {
      res.status(404).json({ error: '找不到該繳費記錄' });
      return;
    }
    res.json({ message: '繳費記錄刪除成功' });
  });
});

app.listen(PORT, () => {
  console.log(`伺服器運行在 http://localhost:${PORT}`);
});