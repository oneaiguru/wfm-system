import React, { useState, useEffect } from 'react';

interface TrainingProgram {
  id: string;
  title: string;
  description: string;
  category: string;
  duration: number; // hours
  requiredSkills: string[];
  targetSkills: string[];
  instructorId: string;
  instructorName: string;
  maxParticipants: number;
  currentParticipants: number;
  status: 'draft' | 'active' | 'completed' | 'cancelled';
  startDate: string;
  endDate: string;
  sessions: TrainingSession[];
}

interface TrainingSession {
  id: string;
  programId: string;
  sessionNumber: number;
  date: string;
  startTime: string;
  endTime: string;
  location: string;
  attendees: string[];
  completedAttendees: string[];
  materials: string[];
}

interface Employee {
  id: string;
  name: string;
  department: string;
  currentSkills: string[];
  trainingHistory: string[];
}

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000/api/v1';

const TrainingProgramManager: React.FC = () => {
  const [programs, setPrograms] = useState<TrainingProgram[]>([]);
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [selectedProgram, setSelectedProgram] = useState<TrainingProgram | null>(null);
  const [loading, setLoading] = useState(true);
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [showEnrollModal, setShowEnrollModal] = useState(false);
  const [viewMode, setViewMode] = useState<'grid' | 'calendar'>('grid');

  useEffect(() => {
    fetchTrainingData();
  }, []);

  const fetchTrainingData = async () => {
    try {
      setLoading(true);
      const [programsRes, employeesRes] = await Promise.all([
        fetch(`${API_BASE_URL}/training/programs`),
        fetch(`${API_BASE_URL}/employees/training/eligibility`)
      ]);
      
      const programsData = await programsRes.json();
      const employeesData = await employeesRes.json();
      
      setPrograms(programsData.programs || []);
      setEmployees(employeesData.employees || []);
    } catch (err) {
      console.error('Ошибка загрузки данных обучения');
    } finally {
      setLoading(false);
    }
  };

  const createTrainingProgram = async (programData: Partial<TrainingProgram>) => {
    try {
      const response = await fetch(`${API_BASE_URL}/training/programs`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(programData),
      });
      
      if (!response.ok) throw new Error('Ошибка создания программы обучения');
      
      await fetchTrainingData();
      setShowCreateModal(false);
    } catch (err) {
      console.error('Ошибка создания программы обучения');
    }
  };

  const enrollEmployeeInProgram = async (programId: string, employeeId: string) => {
    try {
      const response = await fetch(`${API_BASE_URL}/training/programs/${programId}/enroll`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ employeeId }),
      });
      
      if (!response.ok) throw new Error('Ошибка записи на обучение');
      
      await fetchTrainingData();
    } catch (err) {
      console.error('Ошибка записи на обучение');
    }
  };

  const markSessionCompleted = async (sessionId: string, employeeId: string) => {
    try {
      const response = await fetch(`${API_BASE_URL}/training/sessions/${sessionId}/complete`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ employeeId }),
      });
      
      if (!response.ok) throw new Error('Ошибка отметки о завершении');
      
      await fetchTrainingData();
    } catch (err) {
      console.error('Ошибка отметки о завершении');
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'draft': return '#95a5a6';
      case 'active': return '#2ecc71';
      case 'completed': return '#3498db';
      case 'cancelled': return '#e74c3c';
      default: return '#95a5a6';
    }
  };

  const getStatusText = (status: string) => {
    switch (status) {
      case 'draft': return 'Черновик';
      case 'active': return 'Активная';
      case 'completed': return 'Завершена';
      case 'cancelled': return 'Отменена';
      default: return 'Неизвестно';
    }
  };

  if (loading) {
    return (
      <div className="training-program-manager">
        <div className="loading-spinner">
          <div className="spinner"></div>
          <p>Загрузка программ обучения...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="training-program-manager">
      <div className="manager-header">
        <h1>Управление программами обучения</h1>
        <div className="header-controls">
          <div className="view-toggle">
            <button 
              className={viewMode === 'grid' ? 'active' : ''}
              onClick={() => setViewMode('grid')}
            >
              🏠 Сетка
            </button>
            <button 
              className={viewMode === 'calendar' ? 'active' : ''}
              onClick={() => setViewMode('calendar')}
            >
              📅 Календарь
            </button>
          </div>
          <button 
            className="create-program-btn"
            onClick={() => setShowCreateModal(true)}
          >
            + Создать программу
          </button>
        </div>
      </div>

      <div className="training-stats">
        <div className="stat-card">
          <div className="stat-value">{programs.length}</div>
          <div className="stat-label">Всего программ</div>
        </div>
        <div className="stat-card">
          <div className="stat-value">{programs.filter(p => p.status === 'active').length}</div>
          <div className="stat-label">Активных программ</div>
        </div>
        <div className="stat-card">
          <div className="stat-value">
            {programs.reduce((acc, p) => acc + p.currentParticipants, 0)}
          </div>
          <div className="stat-label">Участников</div>
        </div>
        <div className="stat-card">
          <div className="stat-value">
            {programs.filter(p => p.status === 'completed').length}
          </div>
          <div className="stat-label">Завершенных программ</div>
        </div>
      </div>

      {viewMode === 'grid' ? (
        <div className="programs-grid">
          {programs.map(program => (
            <div key={program.id} className="program-card">
              <div className="program-header">
                <h3>{program.title}</h3>
                <div 
                  className="program-status"
                  style={{ backgroundColor: getStatusColor(program.status) }}
                >
                  {getStatusText(program.status)}
                </div>
              </div>

              <div className="program-details">
                <p className="program-description">{program.description}</p>
                <div className="program-meta">
                  <div className="meta-item">
                    <strong>Категория:</strong> {program.category}
                  </div>
                  <div className="meta-item">
                    <strong>Длительность:</strong> {program.duration} часов
                  </div>
                  <div className="meta-item">
                    <strong>Инструктор:</strong> {program.instructorName}
                  </div>
                  <div className="meta-item">
                    <strong>Участники:</strong> {program.currentParticipants}/{program.maxParticipants}
                  </div>
                </div>

                <div className="program-dates">
                  <div className="date-range">
                    {new Date(program.startDate).toLocaleDateString('ru-RU')} - 
                    {new Date(program.endDate).toLocaleDateString('ru-RU')}
                  </div>
                </div>

                <div className="required-skills">
                  <h5>Требуемые навыки:</h5>
                  <div className="skills-list">
                    {program.requiredSkills.map(skill => (
                      <span key={skill} className="skill-tag required">{skill}</span>
                    ))}
                  </div>
                </div>

                <div className="target-skills">
                  <h5>Изучаемые навыки:</h5>
                  <div className="skills-list">
                    {program.targetSkills.map(skill => (
                      <span key={skill} className="skill-tag target">{skill}</span>
                    ))}
                  </div>
                </div>
              </div>

              <div className="program-actions">
                <button 
                  className="details-btn"
                  onClick={() => setSelectedProgram(program)}
                >
                  Подробности
                </button>
                {program.status === 'active' && program.currentParticipants < program.maxParticipants && (
                  <button 
                    className="enroll-btn"
                    onClick={() => {
                      setSelectedProgram(program);
                      setShowEnrollModal(true);
                    }}
                  >
                    Записать сотрудника
                  </button>
                )}
              </div>

              <div className="program-progress">
                <div className="progress-bar">
                  <div 
                    className="progress-fill"
                    style={{ width: `${(program.currentParticipants / program.maxParticipants) * 100}%` }}
                  ></div>
                </div>
                <div className="progress-text">
                  Заполнено: {Math.round((program.currentParticipants / program.maxParticipants) * 100)}%
                </div>
              </div>
            </div>
          ))}
        </div>
      ) : (
        <div className="training-calendar">
          <div className="calendar-view">
            <h3>Календарь обучения</h3>
            <div className="calendar-grid">
              {programs
                .filter(p => p.status === 'active')
                .map(program => (
                  <div key={program.id} className="calendar-program">
                    <div className="program-timeline">
                      <h4>{program.title}</h4>
                      <div className="timeline-dates">
                        {new Date(program.startDate).toLocaleDateString('ru-RU')} - 
                        {new Date(program.endDate).toLocaleDateString('ru-RU')}
                      </div>
                      <div className="sessions-list">
                        {program.sessions.map((session, index) => (
                          <div key={session.id} className="session-item">
                            <div className="session-info">
                              <strong>Сессия {session.sessionNumber}</strong>
                              <div>{new Date(session.date).toLocaleDateString('ru-RU')}</div>
                              <div>{session.startTime} - {session.endTime}</div>
                              <div>{session.location}</div>
                            </div>
                            <div className="session-completion">
                              {session.completedAttendees.length}/{session.attendees.length} завершили
                            </div>
                          </div>
                        ))}
                      </div>
                    </div>
                  </div>
                ))}
            </div>
          </div>
        </div>
      )}

      {showCreateModal && (
        <div className="modal-overlay">
          <div className="create-program-modal">
            <div className="modal-header">
              <h2>Создание новой программы обучения</h2>
              <button 
                className="close-btn"
                onClick={() => setShowCreateModal(false)}
              >
                ✕
              </button>
            </div>
            <div className="modal-body">
              <p>Форма создания программы обучения будет реализована в следующей версии</p>
            </div>
          </div>
        </div>
      )}

      {showEnrollModal && selectedProgram && (
        <div className="modal-overlay">
          <div className="enroll-modal">
            <div className="modal-header">
              <h2>Запись в программу: {selectedProgram.title}</h2>
              <button 
                className="close-btn"
                onClick={() => {
                  setShowEnrollModal(false);
                  setSelectedProgram(null);
                }}
              >
                ✕
              </button>
            </div>
            <div className="modal-body">
              <div className="eligible-employees">
                <h3>Подходящие сотрудники</h3>
                {employees
                  .filter(emp => 
                    selectedProgram.requiredSkills.every(skill => 
                      emp.currentSkills.includes(skill)
                    )
                  )
                  .map(employee => (
                    <div key={employee.id} className="employee-option">
                      <div className="employee-info">
                        <h4>{employee.name}</h4>
                        <p>{employee.department}</p>
                        <div className="employee-skills">
                          {employee.currentSkills.map(skill => (
                            <span key={skill} className="skill-tag">{skill}</span>
                          ))}
                        </div>
                      </div>
                      <button 
                        className="enroll-employee-btn"
                        onClick={() => enrollEmployeeInProgram(selectedProgram.id, employee.id)}
                      >
                        Записать
                      </button>
                    </div>
                  ))}
              </div>
            </div>
          </div>
        </div>
      )}

      {selectedProgram && !showEnrollModal && (
        <div className="modal-overlay">
          <div className="program-details-modal">
            <div className="modal-header">
              <h2>{selectedProgram.title}</h2>
              <button 
                className="close-btn"
                onClick={() => setSelectedProgram(null)}
              >
                ✕
              </button>
            </div>
            <div className="modal-body">
              <div className="detailed-program-info">
                <div className="info-section">
                  <h3>Описание программы</h3>
                  <p>{selectedProgram.description}</p>
                </div>

                <div className="info-section">
                  <h3>Сессии обучения</h3>
                  <div className="sessions-detailed">
                    {selectedProgram.sessions.map(session => (
                      <div key={session.id} className="session-detailed">
                        <div className="session-header">
                          <h4>Сессия {session.sessionNumber}</h4>
                          <div className="session-date">
                            {new Date(session.date).toLocaleDateString('ru-RU')} 
                            {session.startTime} - {session.endTime}
                          </div>
                        </div>
                        <div className="session-details">
                          <p><strong>Место:</strong> {session.location}</p>
                          <p><strong>Участников:</strong> {session.attendees.length}</p>
                          <p><strong>Завершили:</strong> {session.completedAttendees.length}</p>
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
    </div>
  );
};

export default TrainingProgramManager;