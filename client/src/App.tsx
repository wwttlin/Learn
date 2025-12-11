import React, { useState } from 'react';
import StudentManagement from './components/StudentManagement';
import CourseManagement from './components/CourseManagement';
import PaymentManagement from './components/PaymentManagement';
import Dashboard from './components/Dashboard';

function App() {
  const [activeTab, setActiveTab] = useState('dashboard');

  const tabs = [
    { id: 'dashboard', name: '總覽', component: Dashboard },
    { id: 'students', name: '學生管理', component: StudentManagement },
    { id: 'courses', name: '課程管理', component: CourseManagement },
    { id: 'payments', name: '繳費管理', component: PaymentManagement },
  ];

  const ActiveComponent = tabs.find(tab => tab.id === activeTab)?.component || Dashboard;

  return (
    <div style={{ minHeight: '100vh' }}>
      <nav className="nav">
        <div className="nav-content">
          <h1>補習班管理系統</h1>
          <div className="nav-tabs">
            {tabs.map(tab => (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`nav-tab ${activeTab === tab.id ? 'active' : ''}`}
              >
                {tab.name}
              </button>
            ))}
          </div>
        </div>
      </nav>

      <main className="container">
        <ActiveComponent />
      </main>
    </div>
  );
}

export default App;
