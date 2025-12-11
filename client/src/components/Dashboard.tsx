import React, { useState, useEffect } from 'react';

interface DashboardStats {
  totalStudents: number;
  totalCourses: number;
  monthlyRevenue: number;
  pendingPayments: number;
}

const Dashboard: React.FC = () => {
  const [stats, setStats] = useState<DashboardStats>({
    totalStudents: 0,
    totalCourses: 0,
    monthlyRevenue: 0,
    pendingPayments: 0
  });

  useEffect(() => {
    // 這裡會從 API 獲取統計數據
    // 暫時使用模擬數據
    setStats({
      totalStudents: 45,
      totalCourses: 8,
      monthlyRevenue: 125000,
      pendingPayments: 3
    });
  }, []);

  const statCards = [
    {
      title: '總學生數',
      value: stats.totalStudents,
      icon: '👥',
      color: 'bg-blue-500'
    },
    {
      title: '開設課程',
      value: stats.totalCourses,
      icon: '📚',
      color: 'bg-green-500'
    },
    {
      title: '本月收入',
      value: `NT$ ${stats.monthlyRevenue.toLocaleString()}`,
      icon: '💰',
      color: 'bg-yellow-500'
    },
    {
      title: '待繳費用',
      value: stats.pendingPayments,
      icon: '⏰',
      color: 'bg-red-500'
    }
  ];

  return (
    <div>
      <h2 style={{ fontSize: '2rem', fontWeight: 'bold', marginBottom: '2rem' }}>系統總覽</h2>
      
      <div className="grid grid-4" style={{ marginBottom: '2rem' }}>
        {statCards.map((card, index) => (
          <div key={index} className="card">
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div>
                <p style={{ color: '#6b7280', fontSize: '0.875rem' }}>{card.title}</p>
                <p style={{ fontSize: '1.5rem', fontWeight: 'bold' }}>{card.value}</p>
              </div>
              <div style={{ fontSize: '2rem' }}>
                {card.icon}
              </div>
            </div>
          </div>
        ))}
      </div>

      <div className="grid grid-2">
        <div className="card">
          <h3 style={{ fontSize: '1.25rem', fontWeight: '600', marginBottom: '1rem' }}>最近繳費記錄</h3>
          <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', padding: '0.75rem', backgroundColor: '#f9fafb', borderRadius: '6px', marginBottom: '0.5rem' }}>
              <span>張小明 - 數學課程</span>
              <span style={{ color: '#16a34a', fontWeight: '600' }}>NT$ 3,000</span>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', padding: '0.75rem', backgroundColor: '#f9fafb', borderRadius: '6px', marginBottom: '0.5rem' }}>
              <span>李小華 - 英文課程</span>
              <span style={{ color: '#16a34a', fontWeight: '600' }}>NT$ 2,500</span>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', padding: '0.75rem', backgroundColor: '#f9fafb', borderRadius: '6px' }}>
              <span>王小美 - 物理課程</span>
              <span style={{ color: '#16a34a', fontWeight: '600' }}>NT$ 3,500</span>
            </div>
          </div>
        </div>

        <div className="card">
          <h3 style={{ fontSize: '1.25rem', fontWeight: '600', marginBottom: '1rem' }}>待處理事項</h3>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', padding: '0.75rem', backgroundColor: '#fef3c7', borderLeft: '4px solid #f59e0b', borderRadius: '6px', marginBottom: '0.5rem' }}>
              <span>⚠️</span>
              <span style={{ marginLeft: '0.5rem' }}>3 位學生繳費逾期</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', padding: '0.75rem', backgroundColor: '#dbeafe', borderLeft: '4px solid #3b82f6', borderRadius: '6px', marginBottom: '0.5rem' }}>
              <span>ℹ️</span>
              <span style={{ marginLeft: '0.5rem' }}>新學期課程安排</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', padding: '0.75rem', backgroundColor: '#dcfce7', borderLeft: '4px solid #16a34a', borderRadius: '6px' }}>
              <span>✅</span>
              <span style={{ marginLeft: '0.5rem' }}>本月收支報表已完成</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;