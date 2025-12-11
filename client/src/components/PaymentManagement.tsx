import React, { useState, useEffect } from 'react';

interface Payment {
  id: number;
  student_id: number;
  course_id: number;
  fee_item: string;
  fee_date: string;
  total_amount: number;
  deposit_amount: number;
  remaining_amount: number;
  paid_amount: number;
  payment_type: string;
  payment_stage: string;
  payment_date: string;
  due_date: string;
  status: string;
  notes: string;
  student_name: string;
  course_name: string;
}



interface Student {
  id: number;
  name: string;
}

interface Course {
  id: number;
  name: string;
  price_monthly: number;
  price_quarterly: number;
  price_semi_annual: number;
}

const PaymentManagement: React.FC = () => {
  const [payments, setPayments] = useState<Payment[]>([]);
  const [students, setStudents] = useState<Student[]>([]);
  const [courses, setCourses] = useState<Course[]>([]);
  const [showForm, setShowForm] = useState(false);
  const [showPaymentModal, setShowPaymentModal] = useState(false);
  const [selectedPayment, setSelectedPayment] = useState<Payment | null>(null);
  const [formData, setFormData] = useState({
    student_id: '',
    course_id: '',
    fee_item: '',
    fee_date: '',
    payment_type: 'monthly',
    deposit_amount: '',
    due_date: '',
    notes: ''
  });
  const [paymentData, setPaymentData] = useState({
    amount: '',
    payment_method: 'cash',
    notes: ''
  });

  useEffect(() => {
    fetchPayments();
    fetchStudents();
    fetchCourses();
  }, []);

  const fetchPayments = async () => {
    try {
      const response = await fetch('http://localhost:5000/api/payments');
      const data = await response.json();
      setPayments(data);
    } catch (error) {
      console.error('獲取繳費記錄失敗:', error);
    }
  };

  const fetchStudents = async () => {
    try {
      const response = await fetch('http://localhost:5000/api/students');
      const data = await response.json();
      setStudents(data);
    } catch (error) {
      console.error('獲取學生資料失敗:', error);
    }
  };

  const fetchCourses = async () => {
    try {
      const response = await fetch('http://localhost:5000/api/courses');
      const data = await response.json();
      setCourses(data);
    } catch (error) {
      console.error('獲取課程資料失敗:', error);
    }
  };

  const getTotalAmount = () => {
    const course = courses.find(c => c.id === parseInt(formData.course_id));
    if (!course) return 0;
    
    switch (formData.payment_type) {
      case 'monthly':
        return course.price_monthly;
      case 'quarterly':
        return course.price_quarterly;
      case 'semi_annual':
        return course.price_semi_annual;
      default:
        return 0;
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    console.log('表單提交開始');
    
    const total_amount = getTotalAmount();
    const deposit_amount = parseFloat(formData.deposit_amount) || 0;
    
    console.log('表單資料:', {
      formData,
      total_amount,
      deposit_amount
    });
    
    if (!formData.student_id || !formData.course_id || !formData.fee_item || !formData.fee_date) {
      alert('請填寫所有必要欄位：學生、課程、費用項目和日期！');
      return;
    }
    
    if (total_amount <= 0) {
      alert('課程金額錯誤！');
      return;
    }
    
    if (deposit_amount > total_amount) {
      alert('訂金不能超過總金額！');
      return;
    }
    
    const requestData = {
      student_id: parseInt(formData.student_id),
      course_id: parseInt(formData.course_id),
      fee_item: formData.fee_item,
      fee_date: formData.fee_date,
      total_amount,
      deposit_amount,
      payment_type: formData.payment_type,
      due_date: formData.due_date,
      notes: formData.notes
    };
    
    console.log('發送請求資料:', requestData);
    
    try {
      const response = await fetch('http://localhost:5000/api/payments', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(requestData),
      });
      
      console.log('回應狀態:', response.status);
      
      const responseData = await response.json();
      console.log('回應資料:', responseData);
      
      if (response.ok) {
        setFormData({
          student_id: '',
          course_id: '',
          fee_item: '',
          fee_date: '',
          payment_type: 'monthly',
          deposit_amount: '',
          due_date: '',
          notes: ''
        });
        setShowForm(false);
        fetchPayments();
        alert('繳費記錄新增成功！');
      } else {
        alert(`新增失敗：${responseData.error || '未知錯誤'}`);
      }
    } catch (error) {
      console.error('新增繳費記錄失敗:', error);
      alert('新增繳費記錄失敗！請檢查網路連線。');
    }
  };

  const handlePayRemaining = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedPayment) return;
    
    const amount = parseFloat(paymentData.amount);
    if (amount <= 0 || amount > selectedPayment.remaining_amount) {
      alert('繳費金額不正確！');
      return;
    }
    
    try {
      const response = await fetch(`http://localhost:5000/api/payments/${selectedPayment.id}/pay-remaining`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          amount,
          payment_method: paymentData.payment_method,
          notes: paymentData.notes
        }),
      });
      
      if (response.ok) {
        setPaymentData({
          amount: '',
          payment_method: 'cash',
          notes: ''
        });
        setShowPaymentModal(false);
        setSelectedPayment(null);
        fetchPayments();
        alert('尾款繳費成功！');
      }
    } catch (error) {
      console.error('尾款繳費失敗:', error);
      alert('尾款繳費失敗！');
    }
  };

  const openPaymentModal = (payment: Payment) => {
    setSelectedPayment(payment);
    setPaymentData({
      amount: payment.remaining_amount.toString(),
      payment_method: 'cash',
      notes: ''
    });
    setShowPaymentModal(true);
  };

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value
    });
  };

  const handlePaymentInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    setPaymentData({
      ...paymentData,
      [e.target.name]: e.target.value
    });
  };

  const handleDelete = async (id: number, studentName: string, courseName: string) => {
    if (!window.confirm(`確定要刪除「${studentName} - ${courseName}」的繳費記錄嗎？`)) {
      return;
    }
    
    try {
      const response = await fetch(`http://localhost:5000/api/payments/${id}`, {
        method: 'DELETE',
      });
      
      if (response.ok) {
        fetchPayments();
        alert('繳費記錄刪除成功！');
      } else {
        const data = await response.json();
        alert(data.error || '刪除失敗！');
      }
    } catch (error) {
      console.error('刪除繳費記錄失敗:', error);
      alert('刪除繳費記錄失敗！');
    }
  };

  const getPaymentTypeText = (type: string) => {
    switch (type) {
      case 'monthly': return '月繳';
      case 'quarterly': return '季繳';
      case 'semi_annual': return '半年繳';
      default: return type;
    }
  };



  const getStatusText = (status: string) => {
    switch (status) {
      case 'paid': return '已完成';
      case 'partial': return '部分繳費';
      case 'pending': return '待繳費';
      case 'overdue': return '逾期';
      default: return status;
    }
  };

  const getStageText = (stage: string) => {
    switch (stage) {
      case 'deposit': return '訂金階段';
      case 'remaining': return '尾款階段';
      case 'full': return '全額繳費';
      case 'completed': return '已完成';
      default: return stage;
    }
  };

  const getStageColor = (stage: string) => {
    switch (stage) {
      case 'deposit': return '#f59e0b';
      case 'remaining': return '#3b82f6';
      case 'full': return '#10b981';
      case 'completed': return '#16a34a';
      default: return '#6b7280';
    }
  };

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
        <h2 style={{ fontSize: '2rem', fontWeight: 'bold' }}>繳費管理</h2>
        <button
          onClick={() => setShowForm(!showForm)}
          className="btn btn-primary"
        >
          {showForm ? '取消' : '新增繳費記錄'}
        </button>
      </div>

      {showForm && (
        <div className="card">
          <h3 style={{ fontSize: '1.25rem', fontWeight: '600', marginBottom: '1rem' }}>新增繳費記錄</h3>
          <form onSubmit={handleSubmit} className="grid grid-2">
            <div className="form-group">
              <label className="form-label">學生</label>
              <select
                name="student_id"
                value={formData.student_id}
                onChange={handleInputChange}
                required
                className="form-input"
              >
                <option value="">請選擇學生</option>
                {students.map(student => (
                  <option key={student.id} value={student.id}>{student.name}</option>
                ))}
              </select>
            </div>
            
            <div className="form-group">
              <label className="form-label">課程</label>
              <select
                name="course_id"
                value={formData.course_id}
                onChange={handleInputChange}
                required
                className="form-input"
              >
                <option value="">請選擇課程</option>
                {courses.map(course => (
                  <option key={course.id} value={course.id}>{course.name}</option>
                ))}
              </select>
            </div>

            <div className="form-group">
              <label className="form-label">費用項目</label>
              <input
                type="text"
                name="fee_item"
                value={formData.fee_item}
                onChange={handleInputChange}
                required
                placeholder="例如：2025年1月學費、教材費、註冊費等"
                className="form-input"
              />
            </div>

            <div className="form-group">
              <label className="form-label">費用日期</label>
              <input
                type="date"
                name="fee_date"
                value={formData.fee_date}
                onChange={handleInputChange}
                required
                className="form-input"
              />
            </div>

            <div className="form-group">
              <label className="form-label">繳費方式</label>
              <select
                name="payment_type"
                value={formData.payment_type}
                onChange={handleInputChange}
                className="form-input"
              >
                <option value="monthly">月繳</option>
                <option value="quarterly">季繳</option>
                <option value="semi_annual">半年繳</option>
              </select>
            </div>

            <div className="form-group">
              <label className="form-label">總金額</label>
              <input
                type="text"
                value={`NT$ ${getTotalAmount().toLocaleString()}`}
                disabled
                className="form-input"
                style={{ backgroundColor: '#f3f4f6' }}
              />
            </div>

            <div className="form-group">
              <label className="form-label">訂金金額</label>
              <input
                type="number"
                name="deposit_amount"
                value={formData.deposit_amount}
                onChange={handleInputChange}
                placeholder="輸入訂金金額（可為0）"
                min="0"
                max={getTotalAmount()}
                className="form-input"
              />
            </div>

            <div className="form-group">
              <label className="form-label">到期日</label>
              <input
                type="date"
                name="due_date"
                value={formData.due_date}
                onChange={handleInputChange}
                className="form-input"
              />
            </div>

            <div className="form-group">
              <label className="form-label">備註</label>
              <textarea
                name="notes"
                value={formData.notes}
                onChange={handleInputChange}
                className="form-input"
              />
            </div>

            <div style={{ gridColumn: '1 / -1' }}>
              <button type="submit" className="btn btn-success">
                新增繳費記錄
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
                <th>課程名稱</th>
                <th>費用項目</th>
                <th>費用日期</th>
                <th>繳費方式</th>
                <th>總金額</th>
                <th>已繳金額</th>
                <th>剩餘金額</th>
                <th>繳費階段</th>
                <th>狀態</th>
                <th>操作</th>
              </tr>
            </thead>
            <tbody>
              {payments.map((payment) => (
                <tr key={payment.id}>
                  <td style={{ fontWeight: '600' }}>{payment.student_name}</td>
                  <td>{payment.course_name}</td>
                  <td style={{ fontWeight: '500', color: '#374151' }}>{payment.fee_item}</td>
                  <td>{new Date(payment.fee_date).toLocaleDateString('zh-TW')}</td>
                  <td>{getPaymentTypeText(payment.payment_type)}</td>
                  <td style={{ fontWeight: '600' }}>
                    NT$ {payment.total_amount?.toLocaleString()}
                  </td>
                  <td style={{ fontWeight: '600', color: '#16a34a' }}>
                    NT$ {payment.paid_amount?.toLocaleString()}
                  </td>
                  <td style={{ fontWeight: '600', color: payment.remaining_amount > 0 ? '#dc2626' : '#16a34a' }}>
                    NT$ {payment.remaining_amount?.toLocaleString()}
                  </td>
                  <td>
                    <span style={{
                      display: 'inline-flex',
                      padding: '0.25rem 0.5rem',
                      fontSize: '0.75rem',
                      fontWeight: '600',
                      borderRadius: '4px',
                      backgroundColor: getStageColor(payment.payment_stage),
                      color: 'white'
                    }}>
                      {getStageText(payment.payment_stage)}
                    </span>
                  </td>
                  <td>
                    <span style={{
                      display: 'inline-flex',
                      padding: '0.25rem 0.5rem',
                      fontSize: '0.75rem',
                      fontWeight: '600',
                      borderRadius: '9999px',
                      backgroundColor: payment.status === 'paid' ? '#dcfce7' : payment.status === 'partial' ? '#fef3c7' : payment.status === 'pending' ? '#e0e7ff' : '#fee2e2',
                      color: payment.status === 'paid' ? '#166534' : payment.status === 'partial' ? '#92400e' : payment.status === 'pending' ? '#1e40af' : '#991b1b'
                    }}>
                      {getStatusText(payment.status)}
                    </span>
                  </td>
                  <td>
                    <div style={{ display: 'flex', gap: '0.25rem', flexWrap: 'wrap' }}>
                      {payment.remaining_amount > 0 && (
                        <button
                          onClick={() => openPaymentModal(payment)}
                          style={{
                            padding: '0.25rem 0.5rem',
                            fontSize: '0.75rem',
                            backgroundColor: '#16a34a',
                            color: 'white',
                            border: 'none',
                            borderRadius: '4px',
                            cursor: 'pointer'
                          }}
                        >
                          繳尾款
                        </button>
                      )}
                      <button
                        onClick={() => handleDelete(payment.id, payment.student_name, payment.course_name)}
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
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {payments.length === 0 && (
        <div style={{ textAlign: 'center', padding: '3rem' }}>
          <p style={{ color: '#6b7280', fontSize: '1.125rem' }}>尚未有任何繳費記錄</p>
        </div>
      )}

      {/* 繳費模態框 */}
      {showPaymentModal && selectedPayment && (
        <div style={{
          position: 'fixed',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          backgroundColor: 'rgba(0, 0, 0, 0.5)',
          display: 'flex',
          justifyContent: 'center',
          alignItems: 'center',
          zIndex: 1000
        }}>
          <div className="card" style={{ width: '500px', maxWidth: '90vw' }}>
            <h3 style={{ fontSize: '1.25rem', fontWeight: '600', marginBottom: '1rem' }}>
              繳費 - {selectedPayment.student_name}
            </h3>
            
            <div style={{ marginBottom: '1rem', padding: '1rem', backgroundColor: '#f3f4f6', borderRadius: '6px' }}>
              <p><strong>課程：</strong>{selectedPayment.course_name}</p>
              <p><strong>費用項目：</strong>{selectedPayment.fee_item}</p>
              <p><strong>費用日期：</strong>{new Date(selectedPayment.fee_date).toLocaleDateString('zh-TW')}</p>
              <hr style={{ margin: '0.5rem 0', border: 'none', borderTop: '1px solid #d1d5db' }} />
              <p><strong>總金額：</strong>NT$ {selectedPayment.total_amount.toLocaleString()}</p>
              <p><strong>已繳金額：</strong>NT$ {selectedPayment.paid_amount.toLocaleString()}</p>
              <p><strong>剩餘金額：</strong>NT$ {selectedPayment.remaining_amount.toLocaleString()}</p>
            </div>

            <form onSubmit={handlePayRemaining}>
              <div className="form-group">
                <label className="form-label">繳費金額</label>
                <input
                  type="number"
                  name="amount"
                  value={paymentData.amount}
                  onChange={handlePaymentInputChange}
                  required
                  min="1"
                  max={selectedPayment.remaining_amount}
                  className="form-input"
                />
              </div>

              <div className="form-group">
                <label className="form-label">付款方式</label>
                <select
                  name="payment_method"
                  value={paymentData.payment_method}
                  onChange={handlePaymentInputChange}
                  className="form-input"
                >
                  <option value="cash">現金</option>
                  <option value="transfer">轉帳</option>
                  <option value="credit_card">信用卡</option>
                  <option value="check">支票</option>
                </select>
              </div>

              <div className="form-group">
                <label className="form-label">備註</label>
                <textarea
                  name="notes"
                  value={paymentData.notes}
                  onChange={handlePaymentInputChange}
                  className="form-input"
                  rows={3}
                />
              </div>

              <div style={{ display: 'flex', gap: '0.5rem', justifyContent: 'flex-end' }}>
                <button
                  type="button"
                  onClick={() => {
                    setShowPaymentModal(false);
                    setSelectedPayment(null);
                  }}
                  className="btn"
                  style={{ backgroundColor: '#6b7280', color: 'white' }}
                >
                  取消
                </button>
                <button type="submit" className="btn btn-success">
                  確認繳費
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default PaymentManagement;