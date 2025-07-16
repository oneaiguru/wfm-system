import React, { useState, useEffect } from 'react';

interface CareerPath {
  id: string;
  currentRole: string;
  targetRole: string;
  requiredSkills: string[];
  estimatedTimeMonths: number;
  milestones: Milestone[];
}

interface Milestone {
  id: string;
  title: string;
  description: string;
  targetDate: string;
  completed: boolean;
  skills: string[];
}

interface Employee {
  id: string;
  name: string;
  currentRole: string;
  department: string;
  careerPath?: CareerPath;
  currentSkills: string[];
}

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000/api/v1';

const CareerDevelopmentPlanner: React.FC = () => {
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [selectedEmployee, setSelectedEmployee] = useState<Employee | null>(null);
  const [availablePaths, setAvailablePaths] = useState<CareerPath[]>([]);
  const [loading, setLoading] = useState(true);
  const [showPathModal, setShowPathModal] = useState(false);

  useEffect(() => {
    fetchCareerData();
  }, []);

  const fetchCareerData = async () => {
    try {
      setLoading(true);
      const [employeesRes, pathsRes] = await Promise.all([
        fetch(`${API_BASE_URL}/employees/career/development`),
        fetch(`${API_BASE_URL}/employees/career/paths`)
      ]);
      
      const employeesData = await employeesRes.json();
      const pathsData = await pathsRes.json();
      
      setEmployees(employeesData.employees || []);
      setAvailablePaths(pathsData.paths || []);
    } catch (err) {
      console.error('Ошибка загрузки данных карьерного развития');
    } finally {
      setLoading(false);
    }
  };

  const assignCareerPath = async (employeeId: string, pathId: string) => {
    try {
      const response = await fetch(`${API_BASE_URL}/employees/${employeeId}/career/assign`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ pathId }),
      });
      
      if (!response.ok) throw new Error('Ошибка назначения карьерного пути');
      
      await fetchCareerData();
      setShowPathModal(false);
    } catch (err) {
      console.error('Ошибка назначения карьерного пути');
    }
  };

  const updateMilestone = async (employeeId: string, milestoneId: string, completed: boolean) => {
    try {
      const response = await fetch(`${API_BASE_URL}/employees/${employeeId}/milestones/${milestoneId}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ completed }),
      });
      
      if (!response.ok) throw new Error('Ошибка обновления milestone');
      
      setEmployees(prev => prev.map(emp => 
        emp.id === employeeId && emp.careerPath
          ? {
              ...emp,
              careerPath: {
                ...emp.careerPath,
                milestones: emp.careerPath.milestones.map(milestone =>
                  milestone.id === milestoneId ? { ...milestone, completed } : milestone
                )
              }
            }
          : emp
      ));
    } catch (err) {
      console.error('Ошибка обновления milestone');
    }
  };

  const getProgressPercentage = (path: CareerPath) => {
    if (!path.milestones.length) return 0;
    const completedMilestones = path.milestones.filter(m => m.completed).length;
    return Math.round((completedMilestones / path.milestones.length) * 100);
  };

  if (loading) {
    return (
      <div className="career-development-planner">
        <div className="loading-spinner">
          <div className="spinner"></div>
          <p>Загрузка планов карьерного развития...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="career-development-planner">
      <div className="planner-header">
        <h1>Планировщик карьерного развития</h1>
        <div className="header-controls">
          <button className="create-path-btn">
            + Создать карьерный путь
          </button>
          <button className="analytics-btn">
            📊 Аналитика развития
          </button>
        </div>
      </div>

      <div className="development-overview">
        <div className="overview-stats">
          <div className="stat-card">
            <div className="stat-value">{employees.filter(e => e.careerPath).length}</div>
            <div className="stat-label">Сотрудников с планом развития</div>
          </div>
          <div className="stat-card">
            <div className="stat-value">{availablePaths.length}</div>
            <div className="stat-label">Доступных карьерных путей</div>
          </div>
          <div className="stat-card">
            <div className="stat-value">
              {employees
                .filter(e => e.careerPath)
                .reduce((acc, emp) => acc + getProgressPercentage(emp.careerPath!), 0) /
                Math.max(employees.filter(e => e.careerPath).length, 1)
              }%
            </div>
            <div className="stat-label">Средний прогресс</div>
          </div>
        </div>
      </div>

      <div className="employees-career-grid">
        {employees.map(employee => (
          <div key={employee.id} className="employee-career-card">
            <div className="employee-header">
              <div className="employee-info">
                <h3>{employee.name}</h3>
                <p>{employee.currentRole} • {employee.department}</p>
              </div>
              <div className="employee-actions">
                {!employee.careerPath ? (
                  <button 
                    className="assign-path-btn"
                    onClick={() => {
                      setSelectedEmployee(employee);
                      setShowPathModal(true);
                    }}
                  >
                    Назначить план
                  </button>
                ) : (
                  <div className="progress-indicator">
                    <div className="progress-circle">
                      <span>{getProgressPercentage(employee.careerPath)}%</span>
                    </div>
                  </div>
                )}
              </div>
            </div>

            {employee.careerPath && (
              <div className="career-path-details">
                <div className="path-info">
                  <h4>Путь развития</h4>
                  <p>{employee.careerPath.currentRole} → {employee.careerPath.targetRole}</p>
                  <p className="timeline">Срок: {employee.careerPath.estimatedTimeMonths} месяцев</p>
                </div>

                <div className="milestones-section">
                  <h5>Ключевые вехи</h5>
                  <div className="milestones-list">
                    {employee.careerPath.milestones.map(milestone => (
                      <div 
                        key={milestone.id} 
                        className={`milestone-item ${milestone.completed ? 'completed' : ''}`}
                      >
                        <div className="milestone-checkbox">
                          <input 
                            type="checkbox"
                            checked={milestone.completed}
                            onChange={(e) => updateMilestone(employee.id, milestone.id, e.target.checked)}
                          />
                        </div>
                        <div className="milestone-content">
                          <div className="milestone-title">{milestone.title}</div>
                          <div className="milestone-date">
                            Целевая дата: {new Date(milestone.targetDate).toLocaleDateString('ru-RU')}
                          </div>
                          <div className="milestone-skills">
                            {milestone.skills.map(skill => (
                              <span key={skill} className="skill-tag">{skill}</span>
                            ))}
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>

                <div className="required-skills">
                  <h5>Требуемые навыки</h5>
                  <div className="skills-comparison">
                    {employee.careerPath.requiredSkills.map(skill => (
                      <div key={skill} className="skill-comparison-item">
                        <span className="skill-name">{skill}</span>
                        <span className={`skill-status ${employee.currentSkills.includes(skill) ? 'acquired' : 'needed'}`}>
                          {employee.currentSkills.includes(skill) ? '✅' : '⏳'}
                        </span>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            )}
          </div>
        ))}
      </div>

      {showPathModal && selectedEmployee && (
        <div className="modal-overlay">
          <div className="career-path-modal">
            <div className="modal-header">
              <h2>Выбор карьерного пути для {selectedEmployee.name}</h2>
              <button 
                className="close-btn"
                onClick={() => {
                  setShowPathModal(false);
                  setSelectedEmployee(null);
                }}
              >
                ✕
              </button>
            </div>
            <div className="modal-body">
              <div className="available-paths">
                {availablePaths
                  .filter(path => path.currentRole === selectedEmployee.currentRole)
                  .map(path => (
                    <div key={path.id} className="path-option">
                      <div className="path-details">
                        <h4>{path.currentRole} → {path.targetRole}</h4>
                        <p>Срок: {path.estimatedTimeMonths} месяцев</p>
                        <div className="path-requirements">
                          <strong>Требуемые навыки:</strong>
                          <div className="skills-list">
                            {path.requiredSkills.map(skill => (
                              <span key={skill} className="skill-tag">{skill}</span>
                            ))}
                          </div>
                        </div>
                      </div>
                      <button 
                        className="select-path-btn"
                        onClick={() => assignCareerPath(selectedEmployee.id, path.id)}
                      >
                        Выбрать этот путь
                      </button>
                    </div>
                  ))}
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default CareerDevelopmentPlanner;