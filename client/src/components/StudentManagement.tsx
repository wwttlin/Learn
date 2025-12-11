import React, { useState, useEffect } from 'react';

interface Student {
  id: number;
  name: string;
  english_name: string;
  birth_date: string;
  school_class: string;
  phone: string;
  email: string;
  address: string;
  parent_name: string;
  parent_phone: string;
  enrollment_date: string;
  status: string;
}

const StudentManagement: React.FC = () => {
  const [students, setStudents] = useState<Student[]>([]);
  const [showForm, setShowForm] = useState(false);
  const [editingStudent, setEditingStudent] = useState<Student | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [formData, setFormData] = useState({
    name: '',
    english_name: '',
    birth_date: '',
    school_class: '',
    phone: '',
    email: '',
    address: '',
    parent_name: '',
    parent_phone: '',
    status: 'active'
  });

  useEffect(() => {
    fetchStudents();
  }, []);

  const fetchStudents = async () => {
    try {
      const response = await fetch('http://localhost:5000/api/students');
      const data = await response.json();
      setStudents(data);
    } catch (error) {
      console.error('獲取學生資料失敗:', error);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const url = editingStudent 
        ? `http://localhost:5000/api/students/${editingStudent.id}`
        : 'http://localhost:5000/api/students';
      const method = editingStudent ? 'PUT' : 'POST';
      
      const response = await fetch(url, {
        method,
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(formData),
      });
      
      if (response.ok) {
        resetForm();
        fetchStudents();
        alert(editingStudent ? '學生資料更新成功！' : '學生新增成功！');
      }
    } catch (error) {
      console.error('操作失敗:', error);
      alert('操作失敗！');
    }
  };

  const resetForm = () => {
    setFormData({
      name: '',
      english_name: '',
      birth_date: '',
      school_class: '',
      phone: '',
      email: '',
      address: '',
      parent_name: '',
      parent_phone: '',
      status: 'active'
    });
    setShowForm(false);
    setEditingStudent(null);
  };

  const handleEdit = (student: Student) => {
    setFormData({
      name: student.name,
      english_name: student.english_name || '',
      birth_date: student.birth_date || '',
      school_class: student.school_class || '',
      phone: student.phone || '',
      email: student.email || '',
      address: student.address || '',
      parent_name: student.parent_name || '',
      parent_phone: student.parent_phone || '',
      status: student.status
    });
    setEditingStudent(student);
    setShowForm(true);
  };

  const handleDelete = async (id: number, name: string) => {
    if (!window.confirm(`確定要刪除學生「${name}」嗎？`)) {
      return;
    }
    
    try {
      const response = await fetch(`http://localhost:5000/api/students/${id}`, {
        method: 'DELETE',
      });
      
      const data = await response.json();
      
      if (response.ok) {
        fetchStudents();
        alert('學生刪除成功！');
      } else {
        alert(data.error || '刪除失敗！');
      }
    } catch (error) {
      console.error('刪除學生失敗:', error);
      alert('刪除學生失敗！');
    }
  };

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value
    });
  };

  const filteredStudents = students.filter(student =>
    student.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    student.english_name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    student.school_class?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    student.phone?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    student.parent_name?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
        <h2 style={{ fontSize: '2rem', fontWeight: 'bold' }}>學生管理</h2>
        <button
          onClick={() => {
            if (showForm) {
              resetForm();
            } else {
              setShowForm(true);
            }
          }}
          className="btn btn-primary"
        >
          {showForm ? '取消' : '新增學生'}
        </button>
      </div>

      {/* 搜尋功能 */}
      <div className="card" style={{ marginBottom: '1.5rem' }}>
        <div className="form-group">
          <label className="form-label">搜尋學生</label>
          <input
            type="text"
            placeholder="輸入學生姓名、英文名字、學校班級、電話或家長姓名進行搜尋..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="form-input"
          />
        </div>
      </div>

      {showForm && (
        <div className="card">
          <h3 style={{ fontSize: '1.25rem', fontWeight: '600', marginBottom: '1rem' }}>
            {editingStudent ? '編輯學生資料' : '新增學生'}
          </h3>
          <form onSubmit={handleSubmit} className="grid grid-2">
            <div className="form-group">
              <label className="form-label">學生姓名</label>
              <input
                type="text"
                name="name"
                value={formData.name}
                onChange={handleInputChange}
                required
                className="form-input"
              />
            </div>
            <div className="form-group">
              <label className="form-label">英文名字</label>
              <input
                type="text"
                name="english_name"
                value={formData.english_name}
                onChange={handleInputChange}
                placeholder="例如：John Smith"
                className="form-input"
              />
            </div>
            <div className="form-group">
              <label className="form-label">出生年月日</label>
              <input
                type="date"
                name="birth_date"
                value={formData.birth_date}
                onChange={handleInputChange}
                className="form-input"
              />
            </div>
            <div className="form-group">
              <label className="form-label">就讀學校班級</label>
              <input
                type="text"
                name="school_class"
                value={formData.school_class}
                onChange={handleInputChange}
                placeholder="例如：台北市立中山國小五年三班"
                className="form-input"
              />
            </div>
            <div className="form-group">
              <label className="form-label">聯絡電話</label>
              <input
                type="tel"
                name="phone"
                value={formData.phone}
                onChange={handleInputChange}
                className="form-input"
              />
            </div>
            <div className="form-group">
              <label className="form-label">電子郵件</label>
              <input
                type="email"
                name="email"
                value={formData.email}
                onChange={handleInputChange}
                className="form-input"
              />
            </div>
            <div className="form-group">
              <label className="form-label">地址</label>
              <input
                type="text"
                name="address"
                value={formData.address}
                onChange={handleInputChange}
                className="form-input"
              />
            </div>
            <div className="form-group">
              <label className="form-label">家長姓名</label>
              <input
                type="text"
                name="parent_name"
                value={formData.parent_name}
                onChange={handleInputChange}
                className="form-input"
              />
            </div>
            <div className="form-group">
              <label className="form-label">家長電話</label>
              <input
                type="tel"
                name="parent_phone"
                value={formData.parent_phone}
                onChange={handleInputChange}
                className="form-input"
              />
            </div>
            {editingStudent && (
              <div className="form-group">
                <label className="form-label">學生狀態</label>
                <select
                  name="status"
                  value={formData.status}
                  onChange={handleInputChange}
                  className="form-input"
                >
                  <option value="active">在學</option>
                  <option value="inactive">停學</option>
                </select>
              </div>
            )}
            <div style={{ gridColumn: '1 / -1' }}>
              <button type="submit" className="btn btn-success" style={{ marginRight: '0.5rem' }}>
                {editingStudent ? '更新學生資料' : '新增學生'}
              </button>
              <button type="button" onClick={resetForm} className="btn" style={{ backgroundColor: '#6b7280', color: 'white' }}>
                取消
              </button>
            </div>
          </form>
        </div>
      )}

      <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
        <div style={{ overflowX: 'auto' }}>
          <table className="table">
            <thead>
              <tr>
                <th>學生姓名</th>
                <th>英文名字</th>
                <th>出生年月日</th>
                <th>就讀學校班級</th>
                <th>聯絡電話</th>
                <th>家長姓名</th>
                <th>入學日期</th>
                <th>狀態</th>
                <th>操作</th>
              </tr>
            </thead>
            <tbody>
              {filteredStudents.map((student) => (
                <tr key={student.id}>
                  <td style={{ fontWeight: '600' }}>{student.name}</td>
                  <td style={{ fontStyle: student.english_name ? 'normal' : 'italic', color: student.english_name ? '#374151' : '#9ca3af' }}>
                    {student.english_name || '未填寫'}
                  </td>
                  <td>
                    {student.birth_date ? new Date(student.birth_date).toLocaleDateString('zh-TW') : 
                     <span style={{ fontStyle: 'italic', color: '#9ca3af' }}>未填寫</span>}
                  </td>
                  <td style={{ fontSize: '0.875rem', color: student.school_class ? '#374151' : '#9ca3af' }}>
                    {student.school_class || '未填寫'}
                  </td>
                  <td>{student.phone}</td>
                  <td>{student.parent_name}</td>
                  <td>{new Date(student.enrollment_date).toLocaleDateString('zh-TW')}</td>
                  <td>
                    <span style={{
                      display: 'inline-flex',
                      padding: '0.25rem 0.5rem',
                      fontSize: '0.75rem',
                      fontWeight: '600',
                      borderRadius: '9999px',
                      backgroundColor: student.status === 'active' ? '#dcfce7' : '#fee2e2',
                      color: student.status === 'active' ? '#166534' : '#991b1b'
                    }}>
                      {student.status === 'active' ? '在學' : '停學'}
                    </span>
                  </td>
                  <td>
                    <button
                      onClick={() => handleEdit(student)}
                      style={{
                        padding: '0.25rem 0.5rem',
                        marginRight: '0.25rem',
                        fontSize: '0.75rem',
                        backgroundColor: '#3b82f6',
                        color: 'white',
                        border: 'none',
                        borderRadius: '4px',
                        cursor: 'pointer'
                      }}
                    >
                      編輯
                    </button>
                    <button
                      onClick={() => handleDelete(student.id, student.name)}
                      style={{
                        padding: '0.25rem 0.5rem',
                        fontSize: '0.75rem',
                        backgroundColor: '#ef4444',
                        color: 'white',
                        border: 'none',
                        borderRadius: '4px',
                        cursor: 'pointer'
                      }}
                    >
                      刪除
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {filteredStudents.length === 0 && searchTerm && (
        <div style={{ textAlign: 'center', padding: '3rem' }}>
          <p style={{ color: '#6b7280', fontSize: '1.125rem' }}>找不到符合「{searchTerm}」的學生</p>
        </div>
      )}

      {students.length === 0 && (
        <div style={{ textAlign: 'center', padding: '3rem' }}>
          <p style={{ color: '#6b7280', fontSize: '1.125rem' }}>尚未新增任何學生</p>
          <button
            onClick={() => setShowForm(true)}
            className="btn btn-primary"
            style={{ marginTop: '1rem' }}
          >
            新增第一個學生
          </button>
        </div>
      )}
    </div>
  );
};

export default StudentManagement;