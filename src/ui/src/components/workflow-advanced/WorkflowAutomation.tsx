import React, { useState, useEffect } from 'react';
import './WorkflowAutomation.css';

interface AutomationRule {
  id: string;
  name: string;
  description: string;
  trigger: {
    type: 'schedule' | 'event' | 'condition';
    config: any;
  };
  actions: {
    type: string;
    config: any;
  }[];
  enabled: boolean;
  lastRun?: string;
  nextRun?: string;
}

interface TriggerCondition {
  field: string;
  operator: string;
  value: string;
}

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8001/api/v1';

const WorkflowAutomation: React.FC = () => {
  const [rules, setRules] = useState<AutomationRule[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [newRule, setNewRule] = useState<Partial<AutomationRule>>({
    name: '',
    description: '',
    trigger: { type: 'event', config: {} },
    actions: [],
    enabled: true
  });

  useEffect(() => {
    fetchAutomationRules();
  }, []);

  const fetchAutomationRules = async () => {
    try {
      setLoading(true);
      const response = await fetch(`${API_BASE_URL}/workflow/automation/rules`);
      if (!response.ok) {
        throw new Error('Ошибка загрузки правил автоматизации');
      }
      const data = await response.json();
      setRules(data.rules || []);
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Неизвестная ошибка');
    } finally {
      setLoading(false);
    }
  };

  const createAutomationRule = async (rule: Partial<AutomationRule>) => {
    try {
      const response = await fetch(`${API_BASE_URL}/workflow/automation/rules`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(rule),
      });

      if (!response.ok) {
        throw new Error('Ошибка создания правила');
      }

      const newRuleData = await response.json();
      setRules(prev => [...prev, newRuleData]);
      setShowCreateModal(false);
      setNewRule({
        name: '',
        description: '',
        trigger: { type: 'event', config: {} },
        actions: [],
        enabled: true
      });
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Ошибка создания правила');
    }
  };

  const toggleRule = async (ruleId: string, enabled: boolean) => {
    try {
      const response = await fetch(`${API_BASE_URL}/workflow/automation/rules/${ruleId}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ enabled }),
      });

      if (!response.ok) {
        throw new Error('Ошибка обновления правила');
      }

      setRules(prev => prev.map(rule => 
        rule.id === ruleId ? { ...rule, enabled } : rule
      ));
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Ошибка обновления правила');
    }
  };

  const deleteRule = async (ruleId: string) => {
    if (!window.confirm('Вы уверены, что хотите удалить это правило?')) {
      return;
    }

    try {
      const response = await fetch(`${API_BASE_URL}/workflow/automation/rules/${ruleId}`, {
        method: 'DELETE',
      });

      if (!response.ok) {
        throw new Error('Ошибка удаления правила');
      }

      setRules(prev => prev.filter(rule => rule.id !== ruleId));
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Ошибка удаления правила');
    }
  };

  const addAction = () => {
    setNewRule(prev => ({
      ...prev,
      actions: [...(prev.actions || []), { type: 'email', config: {} }]
    }));
  };

  const updateAction = (index: number, field: string, value: any) => {
    setNewRule(prev => ({
      ...prev,
      actions: prev.actions?.map((action, i) => 
        i === index ? { ...action, [field]: value } : action
      ) || []
    }));
  };

  const removeAction = (index: number) => {
    setNewRule(prev => ({
      ...prev,
      actions: prev.actions?.filter((_, i) => i !== index) || []
    }));
  };

  if (loading) {
    return (
      <div className="workflow-automation">
        <div className="loading-spinner">
          <div className="spinner"></div>
          <p>Загрузка правил автоматизации...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="workflow-automation">
      <div className="automation-header">
        <h1>Автоматизация рабочих процессов</h1>
        <button 
          className="create-rule-btn"
          onClick={() => setShowCreateModal(true)}
        >
          + Создать правило
        </button>
      </div>

      {error && (
        <div className="error-message">
          <span className="error-icon">⚠️</span>
          {error}
          <button onClick={() => setError(null)}>✕</button>
        </div>
      )}

      <div className="automation-stats">
        <div className="stat-card">
          <h3>Всего правил</h3>
          <div className="stat-value">{rules.length}</div>
        </div>
        <div className="stat-card">
          <h3>Активных</h3>
          <div className="stat-value">{rules.filter(r => r.enabled).length}</div>
        </div>
        <div className="stat-card">
          <h3>Выполнено сегодня</h3>
          <div className="stat-value">
            {rules.filter(r => r.lastRun && 
              new Date(r.lastRun).toDateString() === new Date().toDateString()
            ).length}
          </div>
        </div>
      </div>

      <div className="rules-grid">
        {rules.map(rule => (
          <div key={rule.id} className={`rule-card ${rule.enabled ? 'enabled' : 'disabled'}`}>
            <div className="rule-header">
              <h3>{rule.name}</h3>
              <div className="rule-controls">
                <label className="switch">
                  <input
                    type="checkbox"
                    checked={rule.enabled}
                    onChange={(e) => toggleRule(rule.id, e.target.checked)}
                  />
                  <span className="slider"></span>
                </label>
                <button 
                  className="delete-btn"
                  onClick={() => deleteRule(rule.id)}
                  title="Удалить правило"
                >
                  🗑️
                </button>
              </div>
            </div>
            
            <p className="rule-description">{rule.description}</p>
            
            <div className="rule-details">
              <div className="trigger-info">
                <strong>Триггер:</strong> {rule.trigger.type === 'schedule' ? 'По расписанию' : 
                  rule.trigger.type === 'event' ? 'По событию' : 'По условию'}
              </div>
              <div className="actions-info">
                <strong>Действий:</strong> {rule.actions.length}
              </div>
            </div>

            <div className="rule-status">
              {rule.lastRun && (
                <div className="last-run">
                  Последний запуск: {new Date(rule.lastRun).toLocaleString('ru-RU')}
                </div>
              )}
              {rule.nextRun && (
                <div className="next-run">
                  Следующий запуск: {new Date(rule.nextRun).toLocaleString('ru-RU')}
                </div>
              )}
            </div>
          </div>
        ))}

        {rules.length === 0 && (
          <div className="empty-state">
            <div className="empty-icon">🤖</div>
            <h3>Нет правил автоматизации</h3>
            <p>Создайте первое правило для автоматизации рабочих процессов</p>
            <button 
              className="create-first-rule-btn"
              onClick={() => setShowCreateModal(true)}
            >
              Создать правило
            </button>
          </div>
        )}
      </div>

      {showCreateModal && (
        <div className="modal-overlay">
          <div className="create-rule-modal">
            <div className="modal-header">
              <h2>Создание правила автоматизации</h2>
              <button 
                className="close-btn"
                onClick={() => setShowCreateModal(false)}
              >
                ✕
              </button>
            </div>

            <div className="modal-body">
              <div className="form-group">
                <label>Название правила</label>
                <input
                  type="text"
                  value={newRule.name || ''}
                  onChange={(e) => setNewRule(prev => ({ ...prev, name: e.target.value }))}
                  placeholder="Введите название правила"
                />
              </div>

              <div className="form-group">
                <label>Описание</label>
                <textarea
                  value={newRule.description || ''}
                  onChange={(e) => setNewRule(prev => ({ ...prev, description: e.target.value }))}
                  placeholder="Описание правила"
                  rows={3}
                />
              </div>

              <div className="form-group">
                <label>Тип триггера</label>
                <select
                  value={newRule.trigger?.type || 'event'}
                  onChange={(e) => setNewRule(prev => ({
                    ...prev,
                    trigger: { type: e.target.value as any, config: {} }
                  }))}
                >
                  <option value="event">По событию</option>
                  <option value="schedule">По расписанию</option>
                  <option value="condition">По условию</option>
                </select>
              </div>

              <div className="form-group">
                <label>Действия</label>
                <div className="actions-list">
                  {newRule.actions?.map((action, index) => (
                    <div key={index} className="action-item">
                      <select
                        value={action.type}
                        onChange={(e) => updateAction(index, 'type', e.target.value)}
                      >
                        <option value="email">Отправить email</option>
                        <option value="notification">Уведомление</option>
                        <option value="webhook">Webhook</option>
                        <option value="approve">Автоодобрение</option>
                      </select>
                      <button 
                        className="remove-action"
                        onClick={() => removeAction(index)}
                      >
                        Удалить
                      </button>
                    </div>
                  ))}
                  <button 
                    className="add-action-btn"
                    onClick={addAction}
                    type="button"
                  >
                    + Добавить действие
                  </button>
                </div>
              </div>
            </div>

            <div className="modal-footer">
              <button 
                className="cancel-btn"
                onClick={() => setShowCreateModal(false)}
              >
                Отмена
              </button>
              <button 
                className="save-btn"
                onClick={() => createAutomationRule(newRule)}
                disabled={!newRule.name || !newRule.description}
              >
                Создать правило
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default WorkflowAutomation;