import React, { useState, useEffect } from 'react';

interface Course {
  id: number;
  name: string;
  description: string;
  price_monthly: number;
  price_quarterly: number;
  price_semi_annual: number;
  created_at: string;
}

const CourseManagement: React.FC = () => {
  const [courses, setCourses] = useState<Course[]>([]);
  const [showForm, setShowForm] = useState(false);
  const [editingCourse, setEditingCourse] = useState<Course | null>(null);
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    price_monthly: '',
    price_quarterly: '',
    price_semi_annual: ''
  });

  useEffect(() => {
    fetchCourses();
  }, []);

  const fetchCourses = async () => {
    try {
      const response = await fetch('/api/courses');
      const data = await response.json();
      setCourses(data);
    } catch (error) {
      console.error('獲取課程資料失敗:', error);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const url = editingCourse 
        ? `/api/courses/${editingCourse.id}`
        : '/api/courses';
      const method = editingCourse ? 'PUT' : 'POST';
      
      const response = await fetch(url, {
        method,
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          ...formData,
          price_monthly: parseFloat(formData.price_monthly),
          price_quarterly: parseFloat(formData.price_quarterly),
          price_semi_annual: parseFloat(formData.price_semi_annual)
        }),
      });
      
      const data = await response.json();
      
      if (response.ok) {
        resetForm();
        fetchCourses();
        alert(editingCourse ? '課程更新成功！' : '課程新增成功！');
      } else {
        console.error('操作失敗:', data);
        alert(`操作失敗：${data.error || '未知錯誤'}`);
      }
    } catch (error) {
      console.error('操作失敗:', error);
      alert('操作失敗：無法連接到伺服器');
    }
  };

  const resetForm = () => {
    setFormData({
      name: '',
      description: '',
      price_monthly: '',
      price_quarterly: '',
      price_semi_annual: ''
    });
    setShowForm(false);
    setEditingCourse(null);
  };

  const handleEdit = (course: Course) => {
    setFormData({
      name: course.name,
      description: course.description || '',
      price_monthly: course.price_monthly?.toString() || '',
      price_quarterly: course.price_quarterly?.toString() || '',
      price_semi_annual: course.price_semi_annual?.toString() || ''
    });
    setEditingCourse(course);
    setShowForm(true);
  };

  const handleDelete = async (id: number, name: string) => {
    if (!window.confirm(`確定要刪除課程「${name}」嗎？`)) {
      return;
    }
    
    try {
      const response = await fetch(`/api/courses/${id}`, {
        method: 'DELETE',
      });
      
      const data = await response.json();
      
      if (response.ok) {
        fetchCourses();
        alert('課程刪除成功！');
      } else {
        alert(data.error || '刪除失敗！');
      }
    } catch (error) {
      console.error('刪除課程失敗:', error);
      alert('刪除課程失敗：無法連接到伺服器');
    }
  };

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value
    });
  };

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
        <h2 style={{ fontSize: '2rem', fontWeight: 'bold' }}>課程管理</h2>
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
          {showForm ? '取消' : '新增課程'}
        </button>
      </div>

      {showForm && (
        <div className="card">
          <h3 style={{ fontSize: '1.25rem', fontWeight: '600', marginBottom: '1rem' }}>
            {editingCourse ? '編輯課程' : '新增課程'}
          </h3>
          <form onSubmit={handleSubmit}>
            <div className="grid grid-2" style={{ marginBottom: '1rem' }}>
              <div className="form-group">
                <label className="form-label">課程名稱</label>
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
                <label className="form-label">月繳費用</label>
                <input
                  type="number"
                  name="price_monthly"
                  value={formData.price_monthly}
                  onChange={handleInputChange}
                  required
                  className="form-input"
                />
              </div>
            </div>
            
            <div className="form-group">
              <label className="form-label">課程描述</label>
              <textarea
                name="description"
                value={formData.description}
                onChange={handleInputChange}
                rows={3}
                className="form-input"
              />
            </div>

            <div className="grid grid-2" style={{ marginBottom: '1rem' }}>
              <div className="form-group">
                <label className="form-label">季繳費用</label>
                <input
                  type="number"
                  name="price_quarterly"
                  value={formData.price_quarterly}
                  onChange={handleInputChange}
                  required
                  className="form-input"
                />
              </div>
              <div className="form-group">
                <label className="form-label">半年繳費用</label>
                <input
                  type="number"
                  name="price_semi_annual"
                  value={formData.price_semi_annual}
                  onChange={handleInputChange}
                  required
                  className="form-input"
                />
              </div>
            </div>

            <div>
              <button type="submit" className="btn btn-success" style={{ marginRight: '0.5rem' }}>
                {editingCourse ? '更新課程' : '新增課程'}
              </button>
              <button type="button" onClick={resetForm} className="btn" style={{ backgroundColor: '#6b7280', color: 'white' }}>
                取消
              </button>
            </div>
          </form>
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {courses.map((course) => (
          <div key={course.id} className="bg-white rounded-lg shadow-md p-6">
            <h3 className="text-xl font-semibold text-gray-800 mb-2">{course.name}</h3>
            <p className="text-gray-600 mb-4">{course.description}</p>
            
            <div className="space-y-2">
              <div className="flex justify-between items-center">
                <span className="text-sm text-gray-500">月繳:</span>
                <span className="font-semibold text-blue-600">NT$ {course.price_monthly?.toLocaleString()}</span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-sm text-gray-500">季繳:</span>
                <span className="font-semibold text-green-600">NT$ {course.price_quarterly?.toLocaleString()}</span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-sm text-gray-500">半年繳:</span>
                <span className="font-semibold text-purple-600">NT$ {course.price_semi_annual?.toLocaleString()}</span>
              </div>
            </div>

            <div style={{ marginTop: '1rem', paddingTop: '1rem', borderTop: '1px solid #e5e7eb' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <span style={{ fontSize: '0.75rem', color: '#9ca3af' }}>
                  建立日期: {new Date(course.created_at).toLocaleDateString('zh-TW')}
                </span>
                <div style={{ display: 'flex', gap: '0.5rem' }}>
                  <button 
                    onClick={() => handleEdit(course)}
                    style={{ 
                      color: '#2563eb', 
                      fontSize: '0.875rem',
                      background: 'none',
                      border: 'none',
                      cursor: 'pointer'
                    }}
                  >
                    編輯
                  </button>
                  <button 
                    onClick={() => handleDelete(course.id, course.name)}
                    style={{ 
                      color: '#dc2626', 
                      fontSize: '0.875rem',
                      background: 'none',
                      border: 'none',
                      cursor: 'pointer'
                    }}
                  >
                    刪除
                  </button>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>

      {courses.length === 0 && (
        <div className="text-center py-12">
          <p className="text-gray-500 text-lg">尚未新增任何課程</p>
          <button
            onClick={() => setShowForm(true)}
            className="mt-4 bg-blue-600 text-white px-6 py-2 rounded-md hover:bg-blue-700 transition-colors"
          >
            新增第一個課程
          </button>
        </div>
      )}
    </div>
  );
};

export default CourseManagement;