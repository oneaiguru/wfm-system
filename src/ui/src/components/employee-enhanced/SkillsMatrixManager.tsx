import React, { useState, useEffect } from 'react';

interface Skill {
  id: string;
  name: string;
  category: string;
  level: 1 | 2 | 3 | 4 | 5;
  certification?: string;
  expiryDate?: string;
}

interface Employee {
  id: string;
  name: string;
  department: string;
  skills: Skill[];
}

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000/api/v1';

const SkillsMatrixManager: React.FC = () => {
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [skillCategories, setSkillCategories] = useState<string[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedEmployee, setSelectedEmployee] = useState<Employee | null>(null);
  const [showSkillModal, setShowSkillModal] = useState(false);

  useEffect(() => {
    fetchEmployeesAndSkills();
  }, []);

  const fetchEmployeesAndSkills = async () => {
    try {
      setLoading(true);
      const response = await fetch(`${API_BASE_URL}/skills/matrix`);
      if (!response.ok) throw new Error('Ошибка загрузки матрицы навыков');
      const data = await response.json();
      setEmployees(data.employees || []);
      setSkillCategories(data.categories || []);
    } catch (err) {
      console.error('Ошибка загрузки данных');
    } finally {
      setLoading(false);
    }
  };

  const getSkillLevelColor = (level: number) => {
    switch (level) {
      case 1: return '#e74c3c'; // Новичок
      case 2: return '#f39c12'; // Базовый
      case 3: return '#f1c40f'; // Средний
      case 4: return '#2ecc71'; // Продвинутый
      case 5: return '#27ae60'; // Эксперт
      default: return '#95a5a6';
    }
  };

  const getSkillLevelText = (level: number) => {
    switch (level) {
      case 1: return 'Новичок';
      case 2: return 'Базовый';
      case 3: return 'Средний';
      case 4: return 'Продвинутый';
      case 5: return 'Эксперт';
      default: return 'Не указан';
    }
  };

  const updateEmployeeSkill = async (employeeId: string, skillId: string, newLevel: number) => {
    try {
      const response = await fetch(`${API_BASE_URL}/skills/matrix/${employeeId}/skills/${skillId}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ level: newLevel }),
      });
      
      if (!response.ok) throw new Error('Ошибка обновления навыка');
      
      // Update local state
      setEmployees(prev => prev.map(emp => 
        emp.id === employeeId 
          ? {
              ...emp,
              skills: emp.skills.map(skill => 
                skill.id === skillId ? { ...skill, level: newLevel as any } : skill
              )
            }
          : emp
      ));
    } catch (err) {
      console.error('Ошибка обновления навыка');
    }
  };

  if (loading) {
    return (
      <div className="skills-matrix-manager">
        <div className="loading-spinner">
          <div className="spinner"></div>
          <p>Загрузка матрицы навыков...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="skills-matrix-manager">
      <div className="matrix-header">
        <h1>Матрица навыков сотрудников</h1>
        <div className="header-controls">
          <button className="add-skill-btn" onClick={() => setShowSkillModal(true)}>
            + Добавить навык
          </button>
          <button className="export-btn">
            📊 Экспорт матрицы
          </button>
        </div>
      </div>

      <div className="skills-legend">
        <h3>Уровни навыков:</h3>
        <div className="legend-items">
          {[1, 2, 3, 4, 5].map(level => (
            <div key={level} className="legend-item">
              <div 
                className="legend-color" 
                style={{ backgroundColor: getSkillLevelColor(level) }}
              ></div>
              <span>{getSkillLevelText(level)}</span>
            </div>
          ))}
        </div>
      </div>

      <div className="matrix-grid">
        <div className="matrix-table">
          <div className="table-header">
            <div className="employee-column">Сотрудник</div>
            {skillCategories.map(category => (
              <div key={category} className="skill-category-column">
                {category}
              </div>
            ))}
          </div>

          <div className="table-body">
            {employees.map(employee => (
              <div key={employee.id} className="employee-row">
                <div className="employee-info">
                  <h4>{employee.name}</h4>
                  <p>{employee.department}</p>
                </div>
                
                {skillCategories.map(category => (
                  <div key={category} className="skills-cell">
                    {employee.skills
                      .filter(skill => skill.category === category)
                      .map(skill => (
                        <div 
                          key={skill.id} 
                          className="skill-badge"
                          style={{ backgroundColor: getSkillLevelColor(skill.level) }}
                          onClick={() => {
                            setSelectedEmployee(employee);
                            setShowSkillModal(true);
                          }}
                          title={`${skill.name} - ${getSkillLevelText(skill.level)}`}
                        >
                          {skill.level}
                        </div>
                      ))}
                  </div>
                ))}
              </div>
            ))}
          </div>
        </div>
      </div>

      <div className="matrix-analytics">
        <div className="analytics-card">
          <h3>Статистика навыков</h3>
          <div className="stats-grid">
            <div className="stat-item">
              <div className="stat-value">{employees.length}</div>
              <div className="stat-label">Сотрудников</div>
            </div>
            <div className="stat-item">
              <div className="stat-value">
                {skillCategories.length}
              </div>
              <div className="stat-label">Категорий навыков</div>
            </div>
            <div className="stat-item">
              <div className="stat-value">
                {employees.reduce((acc, emp) => acc + emp.skills.length, 0)}
              </div>
              <div className="stat-label">Всего навыков</div>
            </div>
          </div>
        </div>

        <div className="analytics-card">
          <h3>Уровень покрытия навыков</h3>
          <div className="coverage-chart">
            {skillCategories.map(category => {
              const categorySkills = employees.flatMap(emp => 
                emp.skills.filter(skill => skill.category === category)
              );
              const avgLevel = categorySkills.length > 0 
                ? categorySkills.reduce((sum, skill) => sum + skill.level, 0) / categorySkills.length 
                : 0;
              
              return (
                <div key={category} className="coverage-item">
                  <div className="category-name">{category}</div>
                  <div className="coverage-bar">
                    <div 
                      className="coverage-fill"
                      style={{ 
                        width: `${(avgLevel / 5) * 100}%`,
                        backgroundColor: getSkillLevelColor(Math.round(avgLevel))
                      }}
                    ></div>
                  </div>
                  <div className="coverage-value">{avgLevel.toFixed(1)}</div>
                </div>
              );
            })}
          </div>
        </div>
      </div>

      {showSkillModal && (
        <div className="modal-overlay">
          <div className="skill-modal">
            <div className="modal-header">
              <h2>
                {selectedEmployee 
                  ? `Редактирование навыков: ${selectedEmployee.name}`
                  : 'Добавление нового навыка'
                }
              </h2>
              <button 
                className="close-btn"
                onClick={() => {
                  setShowSkillModal(false);
                  setSelectedEmployee(null);
                }}
              >
                ✕
              </button>
            </div>
            <div className="modal-body">
              <p>Функционал редактирования навыков будет реализован в следующей версии</p>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default SkillsMatrixManager;