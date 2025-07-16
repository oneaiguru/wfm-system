import React, { useState, useEffect } from 'react';

interface AssessmentTemplate {
  id: string;
  name: string;
  description: string;
  category: 'technical' | 'soft_skills' | 'leadership' | 'compliance' | 'performance';
  duration: number; // minutes
  questions: AssessmentQuestion[];
  passingScore: number;
  retakePolicy: 'unlimited' | 'limited' | 'once';
  validityPeriod: number; // months
}

interface AssessmentQuestion {
  id: string;
  type: 'multiple_choice' | 'single_choice' | 'text' | 'rating' | 'practical';
  question: string;
  options?: string[];
  correctAnswer?: string | number;
  weight: number;
  competency: string;
}

interface Assessment {
  id: string;
  templateId: string;
  templateName: string;
  employeeId: string;
  employeeName: string;
  assessorId: string;
  assessorName: string;
  scheduledDate: string;
  completedDate?: string;
  status: 'scheduled' | 'in_progress' | 'completed' | 'cancelled';
  score?: number;
  passed?: boolean;
  answers: AssessmentAnswer[];
  feedback: string;
  recommendations: string[];
}

interface AssessmentAnswer {
  questionId: string;
  answer: string | number;
  isCorrect?: boolean;
  score: number;
}

interface CompetencyProfile {
  employeeId: string;
  employeeName: string;
  department: string;
  position: string;
  competencies: CompetencyScore[];
  lastAssessmentDate: string;
  nextAssessmentDue: string;
}

interface CompetencyScore {
  competency: string;
  currentLevel: number;
  targetLevel: number;
  assessmentDate: string;
  trend: 'improving' | 'stable' | 'declining';
  gapAnalysis: string;
}

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000/api/v1';

const CompetencyAssessmentCenter: React.FC = () => {
  const [assessments, setAssessments] = useState<Assessment[]>([]);
  const [templates, setTemplates] = useState<AssessmentTemplate[]>([]);
  const [competencyProfiles, setCompetencyProfiles] = useState<CompetencyProfile[]>([]);
  const [selectedAssessment, setSelectedAssessment] = useState<Assessment | null>(null);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<'assessments' | 'templates' | 'profiles' | 'analytics'>('assessments');
  const [showScheduleModal, setShowScheduleModal] = useState(false);

  useEffect(() => {
    fetchAssessmentData();
  }, []);

  const fetchAssessmentData = async () => {
    try {
      setLoading(true);
      const [assessmentsRes, templatesRes, profilesRes] = await Promise.all([
        fetch(`${API_BASE_URL}/competency/assessments`),
        fetch(`${API_BASE_URL}/competency/templates`),
        fetch(`${API_BASE_URL}/competency/profiles`)
      ]);
      
      const assessmentsData = await assessmentsRes.json();
      const templatesData = await templatesRes.json();
      const profilesData = await profilesRes.json();
      
      setAssessments(assessmentsData.assessments || []);
      setTemplates(templatesData.templates || []);
      setCompetencyProfiles(profilesData.profiles || []);
    } catch (err) {
      console.error('Ошибка загрузки данных центра компетенций');
    } finally {
      setLoading(false);
    }
  };

  const scheduleAssessment = async (assessmentData: any) => {
    try {
      const response = await fetch(`${API_BASE_URL}/competency/assessments/schedule`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(assessmentData),
      });
      
      if (!response.ok) throw new Error('Ошибка планирования оценки');
      
      await fetchAssessmentData();
      setShowScheduleModal(false);
    } catch (err) {
      console.error('Ошибка планирования оценки');
    }
  };

  const startAssessment = async (assessmentId: string) => {
    try {
      const response = await fetch(`${API_BASE_URL}/competency/assessments/${assessmentId}/start`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
      });
      
      if (!response.ok) throw new Error('Ошибка начала оценки');
      
      await fetchAssessmentData();
    } catch (err) {
      console.error('Ошибка начала оценки');
    }
  };

  const completeAssessment = async (assessmentId: string, answers: AssessmentAnswer[], feedback: string) => {
    try {
      const response = await fetch(`${API_BASE_URL}/competency/assessments/${assessmentId}/complete`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ answers, feedback }),
      });
      
      if (!response.ok) throw new Error('Ошибка завершения оценки');
      
      await fetchAssessmentData();
    } catch (err) {
      console.error('Ошибка завершения оценки');
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'scheduled': return '#f39c12';
      case 'in_progress': return '#3498db';
      case 'completed': return '#2ecc71';
      case 'cancelled': return '#e74c3c';
      default: return '#95a5a6';
    }
  };

  const getStatusText = (status: string) => {
    switch (status) {
      case 'scheduled': return 'Запланирована';
      case 'in_progress': return 'В процессе';
      case 'completed': return 'Завершена';
      case 'cancelled': return 'Отменена';
      default: return 'Неизвестно';
    }
  };

  const getCategoryIcon = (category: string) => {
    switch (category) {
      case 'technical': return '🔧';
      case 'soft_skills': return '🤝';
      case 'leadership': return '👑';
      case 'compliance': return '✅';
      case 'performance': return '📊';
      default: return '📋';
    }
  };

  const getCategoryName = (category: string) => {
    switch (category) {
      case 'technical': return 'Технические навыки';
      case 'soft_skills': return 'Гибкие навыки';
      case 'leadership': return 'Лидерство';
      case 'compliance': return 'Соответствие требованиям';
      case 'performance': return 'Производительность';
      default: return 'Прочее';
    }
  };

  const getTrendIcon = (trend: string) => {
    switch (trend) {
      case 'improving': return '📈';
      case 'stable': return '➡️';
      case 'declining': return '📉';
      default: return '❓';
    }
  };

  if (loading) {
    return (
      <div className="competency-assessment-center">
        <div className="loading-spinner">
          <div className="spinner"></div>
          <p>Загрузка центра оценки компетенций...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="competency-assessment-center">
      <div className="center-header">
        <h1>Центр оценки компетенций</h1>
        <div className="header-controls">
          <button 
            className="schedule-assessment-btn"
            onClick={() => setShowScheduleModal(true)}
          >
            + Запланировать оценку
          </button>
          <button className="export-btn">
            📊 Экспорт отчетов
          </button>
        </div>
      </div>

      <div className="assessment-stats">
        <div className="stat-card">
          <div className="stat-value">{assessments.length}</div>
          <div className="stat-label">Всего оценок</div>
        </div>
        <div className="stat-card">
          <div className="stat-value">{assessments.filter(a => a.status === 'scheduled').length}</div>
          <div className="stat-label">Запланированных</div>
        </div>
        <div className="stat-card">
          <div className="stat-value">{assessments.filter(a => a.status === 'completed').length}</div>
          <div className="stat-label">Завершенных</div>
        </div>
        <div className="stat-card">
          <div className="stat-value">
            {assessments.filter(a => a.completed && a.passed).length > 0
              ? Math.round((assessments.filter(a => a.completed && a.passed).length / assessments.filter(a => a.completed).length) * 100)
              : 0
            }%
          </div>
          <div className="stat-label">Успешность</div>
        </div>
      </div>

      <div className="tab-navigation">
        <button 
          className={activeTab === 'assessments' ? 'active' : ''}
          onClick={() => setActiveTab('assessments')}
        >
          📋 Оценки
        </button>
        <button 
          className={activeTab === 'templates' ? 'active' : ''}
          onClick={() => setActiveTab('templates')}
        >
          📝 Шаблоны
        </button>
        <button 
          className={activeTab === 'profiles' ? 'active' : ''}
          onClick={() => setActiveTab('profiles')}
        >
          👤 Профили компетенций
        </button>
        <button 
          className={activeTab === 'analytics' ? 'active' : ''}
          onClick={() => setActiveTab('analytics')}
        >
          📊 Аналитика
        </button>
      </div>

      {activeTab === 'assessments' && (
        <div className="assessments-view">
          <div className="assessments-grid">
            {assessments.map(assessment => (
              <div key={assessment.id} className="assessment-card">
                <div className="assessment-header">
                  <h3>{assessment.templateName}</h3>
                  <div 
                    className="assessment-status"
                    style={{ backgroundColor: getStatusColor(assessment.status) }}
                  >
                    {getStatusText(assessment.status)}
                  </div>
                </div>

                <div className="assessment-details">
                  <div className="detail-item">
                    <strong>Сотрудник:</strong> {assessment.employeeName}
                  </div>
                  <div className="detail-item">
                    <strong>Оценщик:</strong> {assessment.assessorName}
                  </div>
                  <div className="detail-item">
                    <strong>Дата:</strong> {new Date(assessment.scheduledDate).toLocaleDateString('ru-RU')}
                  </div>
                  {assessment.completedDate && (
                    <div className="detail-item">
                      <strong>Завершена:</strong> {new Date(assessment.completedDate).toLocaleDateString('ru-RU')}
                    </div>
                  )}
                  {assessment.score !== undefined && (
                    <div className="detail-item">
                      <strong>Результат:</strong> 
                      <span className={assessment.passed ? 'passed' : 'failed'}>
                        {assessment.score}% ({assessment.passed ? 'Сдано' : 'Не сдано'})
                      </span>
                    </div>
                  )}
                </div>

                <div className="assessment-actions">
                  {assessment.status === 'scheduled' && (
                    <button 
                      className="start-btn"
                      onClick={() => startAssessment(assessment.id)}
                    >
                      Начать оценку
                    </button>
                  )}
                  {assessment.status === 'completed' && (
                    <button 
                      className="view-results-btn"
                      onClick={() => setSelectedAssessment(assessment)}
                    >
                      Результаты
                    </button>
                  )}
                  <button className="details-btn">
                    Подробности
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {activeTab === 'templates' && (
        <div className="templates-view">
          <div className="templates-grid">
            {templates.map(template => (
              <div key={template.id} className="template-card">
                <div className="template-header">
                  <div className="template-icon">
                    {getCategoryIcon(template.category)}
                  </div>
                  <div className="template-info">
                    <h3>{template.name}</h3>
                    <p className="template-category">{getCategoryName(template.category)}</p>
                  </div>
                </div>

                <div className="template-details">
                  <p>{template.description}</p>
                  <div className="template-meta">
                    <div className="meta-item">
                      <strong>Вопросов:</strong> {template.questions.length}
                    </div>
                    <div className="meta-item">
                      <strong>Длительность:</strong> {template.duration} мин
                    </div>
                    <div className="meta-item">
                      <strong>Проходной балл:</strong> {template.passingScore}%
                    </div>
                    <div className="meta-item">
                      <strong>Срок действия:</strong> {template.validityPeriod} мес
                    </div>
                  </div>
                </div>

                <div className="template-actions">
                  <button className="use-template-btn">
                    Использовать шаблон
                  </button>
                  <button className="edit-template-btn">
                    Редактировать
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {activeTab === 'profiles' && (
        <div className="profiles-view">
          <div className="profiles-grid">
            {competencyProfiles.map(profile => (
              <div key={profile.employeeId} className="profile-card">
                <div className="profile-header">
                  <h3>{profile.employeeName}</h3>
                  <p>{profile.position} • {profile.department}</p>
                </div>

                <div className="competency-scores">
                  <h4>Текущие компетенции</h4>
                  <div className="competencies-list">
                    {profile.competencies.map((comp, index) => (
                      <div key={index} className="competency-item">
                        <div className="competency-name">
                          {comp.competency}
                          <span className="trend-indicator">{getTrendIcon(comp.trend)}</span>
                        </div>
                        <div className="competency-levels">
                          <div className="current-level">
                            Текущий: {comp.currentLevel}/5
                          </div>
                          <div className="target-level">
                            Целевой: {comp.targetLevel}/5
                          </div>
                        </div>
                        <div className="competency-progress">
                          <div className="progress-bar">
                            <div 
                              className="progress-fill"
                              style={{ width: `${(comp.currentLevel / 5) * 100}%` }}
                            ></div>
                            <div 
                              className="target-marker"
                              style={{ left: `${(comp.targetLevel / 5) * 100}%` }}
                            ></div>
                          </div>
                        </div>
                        {comp.gapAnalysis && (
                          <div className="gap-analysis">
                            <small>{comp.gapAnalysis}</small>
                          </div>
                        )}
                      </div>
                    ))}
                  </div>
                </div>

                <div className="profile-dates">
                  <div className="date-item">
                    <strong>Последняя оценка:</strong>
                    {new Date(profile.lastAssessmentDate).toLocaleDateString('ru-RU')}
                  </div>
                  <div className="date-item">
                    <strong>Следующая оценка:</strong>
                    {new Date(profile.nextAssessmentDue).toLocaleDateString('ru-RU')}
                  </div>
                </div>

                <div className="profile-actions">
                  <button className="schedule-reassessment-btn">
                    Переоценка
                  </button>
                  <button className="development-plan-btn">
                    План развития
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {activeTab === 'analytics' && (
        <div className="analytics-view">
          <div className="analytics-cards">
            <div className="analytics-card">
              <h3>Общая статистика</h3>
              <div className="analytics-content">
                <div className="chart-placeholder">
                  📊 График успешности оценок по времени
                </div>
              </div>
            </div>

            <div className="analytics-card">
              <h3>Топ компетенций</h3>
              <div className="analytics-content">
                <div className="top-competencies">
                  {competencyProfiles
                    .flatMap(p => p.competencies)
                    .reduce((acc: any[], comp) => {
                      const existing = acc.find(c => c.competency === comp.competency);
                      if (existing) {
                        existing.avgLevel = (existing.avgLevel + comp.currentLevel) / 2;
                        existing.count += 1;
                      } else {
                        acc.push({ competency: comp.competency, avgLevel: comp.currentLevel, count: 1 });
                      }
                      return acc;
                    }, [])
                    .sort((a, b) => b.avgLevel - a.avgLevel)
                    .slice(0, 5)
                    .map((comp, index) => (
                      <div key={index} className="top-competency">
                        <div className="competency-rank">#{index + 1}</div>
                        <div className="competency-info">
                          <div className="competency-name">{comp.competency}</div>
                          <div className="competency-stats">
                            Средний уровень: {comp.avgLevel.toFixed(1)}/5
                          </div>
                        </div>
                      </div>
                    ))}
                </div>
              </div>
            </div>

            <div className="analytics-card">
              <h3>Области для развития</h3>
              <div className="analytics-content">
                <div className="development-areas">
                  {competencyProfiles
                    .flatMap(p => p.competencies)
                    .filter(comp => comp.currentLevel < comp.targetLevel)
                    .sort((a, b) => (b.targetLevel - b.currentLevel) - (a.targetLevel - a.currentLevel))
                    .slice(0, 5)
                    .map((comp, index) => (
                      <div key={index} className="development-area">
                        <div className="area-name">{comp.competency}</div>
                        <div className="area-gap">
                          Разрыв: {comp.targetLevel - comp.currentLevel} уровней
                        </div>
                      </div>
                    ))}
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {showScheduleModal && (
        <div className="modal-overlay">
          <div className="schedule-modal">
            <div className="modal-header">
              <h2>Планирование оценки компетенций</h2>
              <button 
                className="close-btn"
                onClick={() => setShowScheduleModal(false)}
              >
                ✕
              </button>
            </div>
            <div className="modal-body">
              <p>Форма планирования оценки будет реализована в следующей версии</p>
            </div>
          </div>
        </div>
      )}

      {selectedAssessment && (
        <div className="modal-overlay">
          <div className="assessment-results-modal">
            <div className="modal-header">
              <h2>Результаты оценки: {selectedAssessment.templateName}</h2>
              <button 
                className="close-btn"
                onClick={() => setSelectedAssessment(null)}
              >
                ✕
              </button>
            </div>
            <div className="modal-body">
              <div className="results-overview">
                <div className="score-summary">
                  <div className="final-score">
                    <span className="score-value">{selectedAssessment.score}%</span>
                    <span className={`score-status ${selectedAssessment.passed ? 'passed' : 'failed'}`}>
                      {selectedAssessment.passed ? 'СДАНО' : 'НЕ СДАНО'}
                    </span>
                  </div>
                </div>

                <div className="detailed-results">
                  <h3>Детальные результаты</h3>
                  {selectedAssessment.answers.map((answer, index) => (
                    <div key={index} className="answer-review">
                      <div className="question-number">Вопрос {index + 1}</div>
                      <div className="answer-content">
                        <div className="answer-text">Ответ: {answer.answer}</div>
                        <div className={`answer-result ${answer.isCorrect ? 'correct' : 'incorrect'}`}>
                          {answer.isCorrect ? '✅ Правильно' : '❌ Неправильно'}
                        </div>
                        <div className="answer-score">Баллы: {answer.score}</div>
                      </div>
                    </div>
                  ))}
                </div>

                {selectedAssessment.feedback && (
                  <div className="assessment-feedback">
                    <h3>Обратная связь</h3>
                    <p>{selectedAssessment.feedback}</p>
                  </div>
                )}

                {selectedAssessment.recommendations && selectedAssessment.recommendations.length > 0 && (
                  <div className="recommendations">
                    <h3>Рекомендации по развитию</h3>
                    <ul>
                      {selectedAssessment.recommendations.map((rec, index) => (
                        <li key={index}>{rec}</li>
                      ))}
                    </ul>
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default CompetencyAssessmentCenter;