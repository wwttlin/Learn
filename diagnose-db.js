#!/usr/bin/env node

/**
 * 資料庫診斷腳本
 * 用於檢查資料庫狀態和排除問題
 */

const sqlite3 = require('sqlite3').verbose();
const fs = require('fs');
const path = require('path');

console.log('🔍 資料庫診斷工具');
console.log('================');

const dbPath = path.join(__dirname, 'tutoring.db');

// 1. 檢查資料庫檔案是否存在
console.log('1. 檢查資料庫檔案...');
if (fs.existsSync(dbPath)) {
    const stats = fs.statSync(dbPath);
    console.log(`✅ 資料庫檔案存在: ${dbPath}`);
    console.log(`   檔案大小: ${stats.size} bytes`);
    console.log(`   建立時間: ${stats.birthtime}`);
    console.log(`   修改時間: ${stats.mtime}`);
    
    // 檢查檔案權限
    try {
        fs.accessSync(dbPath, fs.constants.R_OK | fs.constants.W_OK);
        console.log('✅ 檔案權限正常 (可讀寫)');
    } catch (err) {
        console.log('❌ 檔案權限問題:', err.message);
    }
} else {
    console.log('❌ 資料庫檔案不存在');
    console.log('💡 請執行: node init-database.js');
    process.exit(1);
}

// 2. 嘗試連接資料庫
console.log('\n2. 測試資料庫連接...');
const db = new sqlite3.Database(dbPath, (err) => {
    if (err) {
        console.log('❌ 資料庫連接失敗:', err.message);
        process.exit(1);
    }
    console.log('✅ 資料庫連接成功');
});

// 3. 檢查資料表結構
console.log('\n3. 檢查資料表結構...');
const expectedTables = ['students', 'courses', 'student_courses', 'payments', 'payment_details'];

db.serialize(() => {
    // 獲取所有資料表
    db.all("SELECT name FROM sqlite_master WHERE type='table'", (err, tables) => {
        if (err) {
            console.log('❌ 獲取資料表列表失敗:', err.message);
            return;
        }
        
        const existingTables = tables.map(t => t.name);
        console.log('📋 現有資料表:', existingTables.join(', '));
        
        // 檢查每個預期的資料表
        expectedTables.forEach(tableName => {
            if (existingTables.includes(tableName)) {
                console.log(`✅ ${tableName} 表存在`);
            } else {
                console.log(`❌ ${tableName} 表不存在`);
            }
        });
        
        // 4. 檢查資料表欄位
        console.log('\n4. 檢查資料表欄位...');
        let tableChecked = 0;
        
        expectedTables.forEach(tableName => {
            if (existingTables.includes(tableName)) {
                db.all(`PRAGMA table_info(${tableName})`, (err, columns) => {
                    if (err) {
                        console.log(`❌ 檢查 ${tableName} 表結構失敗:`, err.message);
                    } else {
                        console.log(`📊 ${tableName} 表 (${columns.length} 個欄位):`);
                        columns.forEach(col => {
                            console.log(`   - ${col.name} (${col.type}${col.notnull ? ', NOT NULL' : ''}${col.dflt_value ? ', DEFAULT: ' + col.dflt_value : ''})`);
                        });
                    }
                    
                    tableChecked++;
                    if (tableChecked === expectedTables.length) {
                        checkData();
                    }
                });
            } else {
                tableChecked++;
                if (tableChecked === expectedTables.length) {
                    checkData();
                }
            }
        });
    });
});

// 5. 檢查資料內容
function checkData() {
    console.log('\n5. 檢查資料內容...');
    
    // 檢查學生資料
    db.get("SELECT COUNT(*) as count FROM students", (err, row) => {
        if (err) {
            console.log('❌ 檢查學生資料失敗:', err.message);
        } else {
            console.log(`📊 學生資料: ${row.count} 筆`);
        }
        
        // 檢查課程資料
        db.get("SELECT COUNT(*) as count FROM courses", (err, row) => {
            if (err) {
                console.log('❌ 檢查課程資料失敗:', err.message);
            } else {
                console.log(`📊 課程資料: ${row.count} 筆`);
            }
            
            // 檢查繳費資料
            db.get("SELECT COUNT(*) as count FROM payments", (err, row) => {
                if (err) {
                    console.log('❌ 檢查繳費資料失敗:', err.message);
                } else {
                    console.log(`📊 繳費資料: ${row.count} 筆`);
                }
                
                testOperations();
            });
        });
    });
}

// 6. 測試基本操作
function testOperations() {
    console.log('\n6. 測試基本操作...');
    
    // 測試插入學生
    const testStudent = {
        name: '測試學生_' + Date.now(),
        phone: '0912345678',
        email: 'test@example.com'
    };
    
    db.run(
        'INSERT INTO students (name, phone, email) VALUES (?, ?, ?)',
        [testStudent.name, testStudent.phone, testStudent.email],
        function(err) {
            if (err) {
                console.log('❌ 測試插入學生失敗:', err.message);
                console.log('💡 這可能是導致「新增學生資料會說操作失敗」的原因');
            } else {
                console.log('✅ 測試插入學生成功 (ID:', this.lastID, ')');
                
                // 清理測試資料
                db.run('DELETE FROM students WHERE id = ?', [this.lastID], (err) => {
                    if (err) {
                        console.log('⚠️  清理測試資料失敗:', err.message);
                    } else {
                        console.log('✅ 測試資料已清理');
                    }
                    
                    finishDiagnosis();
                });
            }
        }
    );
}

// 7. 完成診斷
function finishDiagnosis() {
    console.log('\n📋 診斷總結:');
    console.log('===========');
    
    db.close((err) => {
        if (err) {
            console.log('❌ 關閉資料庫連接失敗:', err.message);
        } else {
            console.log('✅ 資料庫連接已關閉');
        }
        
        console.log('\n💡 如果發現問題:');
        console.log('  1. 重新初始化資料庫: node init-database.js');
        console.log('  2. 檢查檔案權限: ls -la tutoring.db');
        console.log('  3. 檢查後端日誌: 查看服務啟動時的錯誤訊息');
        console.log('  4. 確保 SQLite3 模組正確安裝: npm install sqlite3');
        
        process.exit(0);
    });
}