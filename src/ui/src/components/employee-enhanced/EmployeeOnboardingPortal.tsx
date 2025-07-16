import React, { useState, useEffect } from 'react';

interface OnboardingStep {
  id: string;
  title: string;
  description: string;
  category: 'documentation' | 'training' | 'system_access' | 'equipment' | 'meetings';
  required: boolean;
  estimatedDuration: number; // minutes
  dependencies: string[];
  assignedTo: string;
  assignedToName: string;
  status: 'pending' | 'in_progress' | 'completed' | 'skipped';
  completedAt?: string;
  completedBy?: string;
  notes?: string;
  attachments: string[];
}

interface NewEmployee {
  id: string;
  name: string;
  email: string;
  department: string;
  position: string;
  manager: string;
  startDate: string;
  onboardingSteps: OnboardingStep[];
  onboardingProgress: number;
  status: 'not_started' | 'in_progress' | 'completed' | 'delayed';
}

interface OnboardingTemplate {
  id: string;
  name: string;
  department: string;
  position: string;
  steps: Omit<OnboardingStep, 'id' | 'status' | 'completedAt' | 'completedBy'>[];
}

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000/api/v1';

const EmployeeOnboardingPortal: React.FC = () => {
  const [newEmployees, setNewEmployees] = useState<NewEmployee[]>([]);
  const [templates, setTemplates] = useState<OnboardingTemplate[]>([]);
  const [selectedEmployee, setSelectedEmployee] = useState<NewEmployee | null>(null);
  const [loading, setLoading] = useState(true);
  const [viewMode, setViewMode] = useState<'list' | 'kanban' | 'calendar'>('list');
  const [filterStatus, setFilterStatus] = useState<string>('all');
  const [showCreateModal, setShowCreateModal] = useState(false);

  useEffect(() => {
    fetchOnboardingData();
  }, []);

  const fetchOnboardingData = async () => {
    try {
      setLoading(true);
      const [employeesRes, templatesRes] = await Promise.all([
        fetch(`${API_BASE_URL}/employees/onboarding/active`),
        fetch(`${API_BASE_URL}/employees/onboarding/templates`)
      ]);
      
      const employeesData = await employeesRes.json();
      const templatesData = await templatesRes.json();
      
      setNewEmployees(employeesData.employees || []);
      setTemplates(templatesData.templates || []);
    } catch (err) {
      console.error('Ошибка загрузки данных адаптации');
    } finally {
      setLoading(false);
    }
  };

  const updateStepStatus = async (employeeId: string, stepId: string, status: string, notes?: string) => {
    try {
      const response = await fetch(`${API_BASE_URL}/employees/${employeeId}/onboarding/steps/${stepId}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status, notes }),
      });
      
      if (!response.ok) throw new Error('Ошибка обновления этапа адаптации');
      
      setNewEmployees(prev => prev.map(emp => 
        emp.id === employeeId
          ? {
              ...emp,
              onboardingSteps: emp.onboardingSteps.map(step => 
                step.id === stepId
                  ? { ...step, status: status as any, completedAt: status === 'completed' ? new Date().toISOString() : undefined, notes }
                  : step
              )
            }
          : emp
      ));
    } catch (err) {
      console.error('Ошибка обновления этапа адаптации');
    }
  };

  const createOnboardingPlan = async (employeeData: any) => {
    try {
      const response = await fetch(`${API_BASE_URL}/employees/onboarding/create`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(employeeData),
      });
      
      if (!response.ok) throw new Error('Ошибка создания плана адаптации');
      
      await fetchOnboardingData();
      setShowCreateModal(false);
    } catch (err) {
      console.error('Ошибка создания плана адаптации');
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'not_started': return '#95a5a6';
      case 'in_progress': return '#f39c12';
      case 'completed': return '#2ecc71';
      case 'delayed': return '#e74c3c';
      default: return '#95a5a6';
    }
  };

  const getStatusText = (status: string) => {
    switch (status) {
      case 'not_started': return 'Не начата';
      case 'in_progress': return 'В процессе';
      case 'completed': return 'Завершена';
      case 'delayed': return 'Задержка';
      default: return 'Неизвестно';
    }
  };

  const getCategoryIcon = (category: string) => {
    switch (category) {
      case 'documentation': return '📄';
      case 'training': return '🎓';
      case 'system_access': return '🔐';
      case 'equipment': return '💻';
      case 'meetings': return '👥';
      default: return '📋';
    }
  };

  const getCategoryName = (category: string) => {
    switch (category) {
      case 'documentation': return 'Документооборот';
      case 'training': return 'Обучение';
      case 'system_access': return 'Доступ к системам';
      case 'equipment': return 'Оборудование';
      case 'meetings': return 'Встречи';
      default: return 'Прочее';
    }
  };

  const calculateProgress = (employee: NewEmployee) => {
    const completedSteps = employee.onboardingSteps.filter(step => step.status === 'completed').length;
    return Math.round((completedSteps / employee.onboardingSteps.length) * 100);
  };

  const getDaysFromStart = (startDate: string) => {
    const start = new Date(startDate);
    const now = new Date();
    const diffTime = Math.abs(now.getTime() - start.getTime());
    return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
  };

  const filteredEmployees = filterStatus === 'all' 
    ? newEmployees 
    : newEmployees.filter(emp => emp.status === filterStatus);

  if (loading) {
    return (
      <div className="employee-onboarding-portal">
        <div className="loading-spinner">
          <div className="spinner"></div>
          <p>Загрузка портала адаптации сотрудников...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="employee-onboarding-portal">
      <div className="portal-header">
        <h1>Портал адаптации новых сотрудников</h1>
        <div className="header-controls">
          <div className="view-toggle">
            <button 
              className={viewMode === 'list' ? 'active' : ''}
              onClick={() => setViewMode('list')}
            >
              📋 Список
            </button>
            <button 
              className={viewMode === 'kanban' ? 'active' : ''}
              onClick={() => setViewMode('kanban')}
            >
              📊 Канбан
            </button>
            <button 
              className={viewMode === 'calendar' ? 'active' : ''}
              onClick={() => setViewMode('calendar')}
            >
              📅 Календарь
            </button>
          </div>
          <button 
            className="create-plan-btn"
            onClick={() => setShowCreateModal(true)}
          >
            + Создать план адаптации
          </button>
        </div>
      </div>

      <div className="onboarding-stats">
        <div className="stat-card">
          <div className="stat-value">{newEmployees.length}</div>
          <div className="stat-label">Новых сотрудников</div>
        </div>
        <div className="stat-card">
          <div className="stat-value">{newEmployees.filter(e => e.status === 'in_progress').length}</div>
          <div className="stat-label">В процессе адаптации</div>
        </div>
        <div className="stat-card">
          <div className="stat-value">{newEmployees.filter(e => e.status === 'completed').length}</div>
          <div className="stat-label">Завершили адаптацию</div>
        </div>
        <div className="stat-card">
          <div className="stat-value">
            {newEmployees.length > 0 
              ? Math.round(newEmployees.reduce((acc, emp) => acc + calculateProgress(emp), 0) / newEmployees.length)
              : 0
            }%
          </div>
          <div className="stat-label">Средний прогресс</div>
        </div>
      </div>

      <div className="filter-controls">
        <select 
          value={filterStatus} 
          onChange={(e) => setFilterStatus(e.target.value)}
          className="status-filter"
        >
          <option value="all">Все статусы</option>
          <option value="not_started">Не начата</option>
          <option value="in_progress">В процессе</option>
          <option value="completed">Завершена</option>
          <option value="delayed">Задержка</option>
        </select>
      </div>

      {viewMode === 'list' && (
        <div className="employees-list">
          {filteredEmployees.map(employee => (
            <div key={employee.id} className="employee-card">
              <div className="employee-header">
                <div className="employee-info">
                  <h3>{employee.name}</h3>
                  <p>{employee.position} • {employee.department}</p>
                  <p>Менеджер: {employee.manager}</p>
                  <p>Дней с начала работы: {getDaysFromStart(employee.startDate)}</p>
                </div>
                <div className="employee-status">
                  <div 
                    className="status-indicator"
                    style={{ backgroundColor: getStatusColor(employee.status) }}
                  >
                    {getStatusText(employee.status)}
                  </div>
                  <div className="progress-circle">
                    <span>{calculateProgress(employee)}%</span>
                  </div>
                </div>
              </div>

              <div className="progress-bar">
                <div 
                  className="progress-fill"
                  style={{ width: `${calculateProgress(employee)}%` }}
                ></div>
              </div>

              <div className="onboarding-summary">
                <div className="steps-by-category">
                  {['documentation', 'training', 'system_access', 'equipment', 'meetings'].map(category => {
                    const categorySteps = employee.onboardingSteps.filter(step => step.category === category);
                    if (categorySteps.length === 0) return null;
                    
                    const completedInCategory = categorySteps.filter(step => step.status === 'completed').length;
                    
                    return (
                      <div key={category} className="category-summary">
                        <div className="category-icon">{getCategoryIcon(category)}</div>
                        <div className="category-info">
                          <div className="category-name">{getCategoryName(category)}</div>
                          <div className="category-progress">
                            {completedInCategory}/{categorySteps.length}
                          </div>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>

              <div className="employee-actions">
                <button 
                  className="view-details-btn"
                  onClick={() => setSelectedEmployee(employee)}
                >
                  Подробный план
                </button>
                <button className="send-reminder-btn">
                  Отправить напоминание
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      {viewMode === 'kanban' && (
        <div className="kanban-view">
          {['not_started', 'in_progress', 'completed', 'delayed'].map(status => (
            <div key={status} className="kanban-column">
              <div className="column-header">
                <h3>{getStatusText(status)}</h3>
                <span className="column-count">
                  {filteredEmployees.filter(emp => emp.status === status).length}
                </span>
              </div>
              <div className="column-cards">
                {filteredEmployees
                  .filter(emp => emp.status === status)
                  .map(employee => (
                    <div key={employee.id} className="kanban-card">
                      <h4>{employee.name}</h4>
                      <p>{employee.position}</p>
                      <div className="card-progress">
                        <div className="progress-bar">
                          <div 
                            className="progress-fill"
                            style={{ width: `${calculateProgress(employee)}%` }}
                          ></div>
                        </div>
                        <span>{calculateProgress(employee)}%</span>
                      </div>
                      <div className="card-actions">
                        <button onClick={() => setSelectedEmployee(employee)}>
                          Детали
                        </button>
                      </div>
                    </div>
                  ))}
              </div>
            </div>
          ))}
        </div>
      )}

      {selectedEmployee && (
        <div className="modal-overlay">
          <div className="employee-details-modal">
            <div className="modal-header">
              <h2>План адаптации: {selectedEmployee.name}</h2>
              <button 
                className="close-btn"
                onClick={() => setSelectedEmployee(null)}
              >
                ✕
              </button>
            </div>
            <div className="modal-body">
              <div className="employee-details">
                <div className="employee-overview">
                  <h3>Информация о сотруднике</h3>
                  <div className="overview-grid">
                    <div><strong>Позиция:</strong> {selectedEmployee.position}</div>
                    <div><strong>Отдел:</strong> {selectedEmployee.department}</div>
                    <div><strong>Менеджер:</strong> {selectedEmployee.manager}</div>
                    <div><strong>Дата начала:</strong> {new Date(selectedEmployee.startDate).toLocaleDateString('ru-RU')}</div>
                  </div>
                </div>

                <div className="onboarding-steps">
                  <h3>Этапы адаптации</h3>
                  <div className="steps-list">
                    {selectedEmployee.onboardingSteps.map(step => (
                      <div key={step.id} className={`step-item ${step.status}`}>
                        <div className="step-header">
                          <div className="step-info">
                            <div className="step-category">
                              {getCategoryIcon(step.category)} {getCategoryName(step.category)}
                            </div>
                            <h4>{step.title}</h4>
                            <p>{step.description}</p>
                          </div>
                          <div className="step-status">
                            <select 
                              value={step.status}
                              onChange={(e) => updateStepStatus(selectedEmployee.id, step.id, e.target.value)}
                            >
                              <option value="pending">Ожидает</option>
                              <option value="in_progress">В процессе</option>
                              <option value="completed">Завершено</option>
                              <option value="skipped">Пропущено</option>
                            </select>
                          </div>
                        </div>
                        
                        <div className="step-details">
                          <div className="step-meta">
                            <span><strong>Ответственный:</strong> {step.assignedToName}</span>
                            <span><strong>Время:</strong> {step.estimatedDuration} мин</span>
                            <span><strong>Обязательно:</strong> {step.required ? 'Да' : 'Нет'}</span>
                          </div>
                          
                          {step.completedAt && (
                            <div className="completion-info">
                              <strong>Завершено:</strong> {new Date(step.completedAt).toLocaleDateString('ru-RU')}
                            </div>
                          )}
                          
                          {step.notes && (
                            <div className="step-notes">
                              <strong>Заметки:</strong> {step.notes}
                            </div>
                          )}
                          
                          {step.attachments.length > 0 && (
                            <div className="step-attachments">
                              <strong>Вложения:</strong>
                              {step.attachments.map((attachment, index) => (
                                <a key={index} href={attachment} target="_blank" rel="noopener noreferrer">
                                  {attachment}
                                </a>
                              ))}
                            </div>
                          )}
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {showCreateModal && (
        <div className="modal-overlay">
          <div className="create-plan-modal">
            <div className="modal-header">
              <h2>Создание плана адаптации</h2>
              <button 
                className="close-btn"
                onClick={() => setShowCreateModal(false)}
              >
                ✕
              </button>
            </div>
            <div className="modal-body">
              <p>Форма создания плана адаптации будет реализована в следующей версии</p>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default EmployeeOnboardingPortal;