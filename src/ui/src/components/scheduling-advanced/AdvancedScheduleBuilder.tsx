import React, { useState, useEffect } from 'react';

interface ScheduleConfig {
  id: string;
  name: string;
  period: { start: string; end: string };
  constraints: Constraint[];
  patterns: ShiftPattern[];
  employees: Employee[];
}

interface Constraint {
  id: string;
  type: 'skill_requirement' | 'max_hours' | 'rest_period' | 'availability';
  rule: string;
  value: any;
}

interface ShiftPattern {
  id: string;
  name: string;
  startTime: string;
  endTime: string;
  duration: number;
  skillRequirements: string[];
}

interface Employee {
  id: string;
  name: string;
  skills: string[];
  availability: any;
  maxHours: number;
}

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8001/api/v1';

const AdvancedScheduleBuilder: React.FC = () => {
  const [scheduleConfig, setScheduleConfig] = useState<ScheduleConfig>({
    id: '',
    name: '',
    period: { start: '', end: '' },
    constraints: [],
    patterns: [],
    employees: []
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [buildStatus, setBuildStatus] = useState<'idle' | 'building' | 'completed' | 'error'>('idle');

  const buildSchedule = async () => {
    try {
      setLoading(true);
      setBuildStatus('building');
      const response = await fetch(`${API_BASE_URL}/scheduling/advanced/build`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(scheduleConfig),
      });
      
      if (!response.ok) throw new Error('Ошибка создания расписания');
      
      const result = await response.json();
      setBuildStatus('completed');
      setError(null);
      
      // Show success message with schedule details
      alert(`Расписание успешно создано! 
      Смен запланировано: ${result.totalShifts}
      Покрытие: ${result.coverage}%
      Оптимизация: ${result.optimizationScore}%`);
      
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Ошибка создания расписания');
      setBuildStatus('error');
    } finally {
      setLoading(false);
    }
  };

  const addConstraint = () => {
    const newConstraint: Constraint = {
      id: Date.now().toString(),
      type: 'skill_requirement',
      rule: 'Требование навыка',
      value: ''
    };
    setScheduleConfig(prev => ({
      ...prev,
      constraints: [...prev.constraints, newConstraint]
    }));
  };

  const updateConstraint = (constraintId: string, field: string, value: any) => {
    setScheduleConfig(prev => ({
      ...prev,
      constraints: prev.constraints.map(constraint =>
        constraint.id === constraintId ? { ...constraint, [field]: value } : constraint
      )
    }));
  };

  const removeConstraint = (constraintId: string) => {
    setScheduleConfig(prev => ({
      ...prev,
      constraints: prev.constraints.filter(c => c.id !== constraintId)
    }));
  };

  const addShiftPattern = () => {
    const newPattern: ShiftPattern = {
      id: Date.now().toString(),
      name: 'Новая смена',
      startTime: '09:00',
      endTime: '17:00',
      duration: 8,
      skillRequirements: []
    };
    setScheduleConfig(prev => ({
      ...prev,
      patterns: [...prev.patterns, newPattern]
    }));
  };

  return (
    <div className="advanced-schedule-builder">
      <div className="builder-header">
        <h1>Расширенный конструктор расписаний</h1>
        <div className="header-actions">
          <button 
            className="build-btn"
            onClick={buildSchedule}
            disabled={loading || !scheduleConfig.name}
          >
            {loading ? 'Создание...' : 'Создать расписание'}
          </button>
        </div>
      </div>

      {error && (
        <div className="error-message">
          <span className="error-icon">⚠️</span>
          {error}
          <button onClick={() => setError(null)}>✕</button>
        </div>
      )}

      <div className="builder-status">
        <div className={`status-indicator ${buildStatus}`}>
          {buildStatus === 'idle' && '⏳ Готов к созданию'}
          {buildStatus === 'building' && '🔄 Создание расписания...'}
          {buildStatus === 'completed' && '✅ Расписание создано'}
          {buildStatus === 'error' && '❌ Ошибка создания'}
        </div>
      </div>

      <div className="builder-content">
        <div className="config-section">
          <h2>Основные параметры</h2>
          <div className="form-grid">
            <div className="form-group">
              <label>Название расписания</label>
              <input
                type="text"
                value={scheduleConfig.name}
                onChange={(e) => setScheduleConfig(prev => ({ ...prev, name: e.target.value }))}
                placeholder="Введите название расписания"
              />
            </div>
            <div className="form-group">
              <label>Начало периода</label>
              <input
                type="date"
                value={scheduleConfig.period.start}
                onChange={(e) => setScheduleConfig(prev => ({
                  ...prev,
                  period: { ...prev.period, start: e.target.value }
                }))}
              />
            </div>
            <div className="form-group">
              <label>Конец периода</label>
              <input
                type="date"
                value={scheduleConfig.period.end}
                onChange={(e) => setScheduleConfig(prev => ({
                  ...prev,
                  period: { ...prev.period, end: e.target.value }
                }))}
              />
            </div>
          </div>
        </div>

        <div className="constraints-section">
          <div className="section-header">
            <h2>Ограничения и правила</h2>
            <button className="add-constraint-btn" onClick={addConstraint}>
              + Добавить ограничение
            </button>
          </div>
          <div className="constraints-list">
            {scheduleConfig.constraints.map(constraint => (
              <div key={constraint.id} className="constraint-card">
                <div className="constraint-header">
                  <select
                    value={constraint.type}
                    onChange={(e) => updateConstraint(constraint.id, 'type', e.target.value)}
                  >
                    <option value="skill_requirement">Требование навыка</option>
                    <option value="max_hours">Максимум часов</option>
                    <option value="rest_period">Время отдыха</option>
                    <option value="availability">Доступность</option>
                  </select>
                  <button 
                    className="remove-constraint"
                    onClick={() => removeConstraint(constraint.id)}
                  >
                    Удалить
                  </button>
                </div>
                <div className="constraint-details">
                  <input
                    type="text"
                    value={constraint.rule}
                    onChange={(e) => updateConstraint(constraint.id, 'rule', e.target.value)}
                    placeholder="Описание правила"
                  />
                  <input
                    type="text"
                    value={constraint.value}
                    onChange={(e) => updateConstraint(constraint.id, 'value', e.target.value)}
                    placeholder="Значение"
                  />
                </div>
              </div>
            ))}
          </div>
        </div>

        <div className="patterns-section">
          <div className="section-header">
            <h2>Шаблоны смен</h2>
            <button className="add-pattern-btn" onClick={addShiftPattern}>
              + Добавить шаблон смены
            </button>
          </div>
          <div className="patterns-grid">
            {scheduleConfig.patterns.map(pattern => (
              <div key={pattern.id} className="pattern-card">
                <h3>{pattern.name}</h3>
                <div className="pattern-time">
                  {pattern.startTime} - {pattern.endTime} ({pattern.duration}ч)
                </div>
                <div className="pattern-skills">
                  Навыки: {pattern.skillRequirements.join(', ') || 'Любые'}
                </div>
              </div>
            ))}
          </div>
        </div>

        <div className="optimization-section">
          <h2>Параметры оптимизации</h2>
          <div className="optimization-grid">
            <div className="optimization-option">
              <label className="checkbox-label">
                <input type="checkbox" />
                Минимизировать сверхурочные
              </label>
            </div>
            <div className="optimization-option">
              <label className="checkbox-label">
                <input type="checkbox" />
                Максимизировать покрытие
              </label>
            </div>
            <div className="optimization-option">
              <label className="checkbox-label">
                <input type="checkbox" />
                Учитывать предпочтения сотрудников
              </label>
            </div>
            <div className="optimization-option">
              <label className="checkbox-label">
                <input type="checkbox" />
                Балансировать нагрузку
              </label>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default AdvancedScheduleBuilder;