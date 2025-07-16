import React, { useState, useEffect } from 'react';

interface OptimizationSuggestion {
  id: string;
  title: string;
  description: string;
  impact: 'high' | 'medium' | 'low';
  effort: 'high' | 'medium' | 'low';
  category: 'performance' | 'efficiency' | 'automation';
  estimatedSavings: {
    timeHours: number;
    costRubles: number;
  };
  status: 'pending' | 'implementing' | 'completed' | 'rejected';
}

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000/api/v1';

const WorkflowOptimization: React.FC = () => {
  const [suggestions, setSuggestions] = useState<OptimizationSuggestion[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchSuggestions();
  }, []);

  const fetchSuggestions = async () => {
    try {
      setLoading(true);
      const response = await fetch(`${API_BASE_URL}/workflow/optimization/suggestions`);
      if (!response.ok) throw new Error('Ошибка загрузки рекомендаций');
      const data = await response.json();
      setSuggestions(data.suggestions || []);
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Неизвестная ошибка');
    } finally {
      setLoading(false);
    }
  };

  const updateSuggestionStatus = async (suggestionId: string, status: string) => {
    try {
      const response = await fetch(`${API_BASE_URL}/workflow/optimization/suggestions/${suggestionId}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status }),
      });
      if (!response.ok) throw new Error('Ошибка обновления статуса');
      setSuggestions(prev => prev.map(s => 
        s.id === suggestionId ? { ...s, status: status as any } : s
      ));
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Ошибка обновления статуса');
    }
  };

  const getImpactColor = (impact: string) => {
    switch (impact) {
      case 'high': return '#e74c3c';
      case 'medium': return '#f39c12';
      case 'low': return '#27ae60';
      default: return '#95a5a6';
    }
  };

  if (loading) {
    return (
      <div className="workflow-optimization">
        <div className="loading-spinner">
          <div className="spinner"></div>
          <p>Загрузка рекомендаций по оптимизации...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="workflow-optimization">
      <div className="optimization-header">
        <h1>Оптимизация рабочих процессов</h1>
        <button className="refresh-btn" onClick={fetchSuggestions}>
          🔄 Обновить рекомендации
        </button>
      </div>

      {error && (
        <div className="error-message">
          <span className="error-icon">⚠️</span>
          {error}
          <button onClick={() => setError(null)}>✕</button>
        </div>
      )}

      <div className="optimization-stats">
        <div className="stat-card">
          <h3>Всего рекомендаций</h3>
          <div className="stat-value">{suggestions.length}</div>
        </div>
        <div className="stat-card">
          <h3>Потенциальная экономия</h3>
          <div className="stat-value">
            {suggestions.reduce((acc, s) => acc + s.estimatedSavings.timeHours, 0)} часов
          </div>
        </div>
        <div className="stat-card">
          <h3>Экономия средств</h3>
          <div className="stat-value">
            {suggestions.reduce((acc, s) => acc + s.estimatedSavings.costRubles, 0).toLocaleString()} ₽
          </div>
        </div>
      </div>

      <div className="suggestions-grid">
        {suggestions.map(suggestion => (
          <div key={suggestion.id} className="suggestion-card">
            <div className="suggestion-header">
              <h3>{suggestion.title}</h3>
              <div className="badges">
                <span 
                  className="impact-badge" 
                  style={{ backgroundColor: getImpactColor(suggestion.impact) }}
                >
                  {suggestion.impact === 'high' ? 'Высокий эффект' : 
                   suggestion.impact === 'medium' ? 'Средний эффект' : 'Низкий эффект'}
                </span>
                <span className={`status-badge ${suggestion.status}`}>
                  {suggestion.status === 'pending' ? 'Ожидает' :
                   suggestion.status === 'implementing' ? 'Внедряется' :
                   suggestion.status === 'completed' ? 'Завершено' : 'Отклонено'}
                </span>
              </div>
            </div>

            <p className="suggestion-description">{suggestion.description}</p>

            <div className="suggestion-metrics">
              <div className="metric">
                <span className="metric-label">Категория:</span>
                <span className="metric-value">
                  {suggestion.category === 'performance' ? 'Производительность' :
                   suggestion.category === 'efficiency' ? 'Эффективность' : 'Автоматизация'}
                </span>
              </div>
              <div className="metric">
                <span className="metric-label">Усилия:</span>
                <span className="metric-value">
                  {suggestion.effort === 'high' ? 'Высокие' :
                   suggestion.effort === 'medium' ? 'Средние' : 'Низкие'}
                </span>
              </div>
            </div>

            <div className="savings-info">
              <div className="savings-item">
                <span>💰 Экономия времени: {suggestion.estimatedSavings.timeHours} часов</span>
              </div>
              <div className="savings-item">
                <span>💵 Экономия средств: {suggestion.estimatedSavings.costRubles.toLocaleString()} ₽</span>
              </div>
            </div>

            <div className="suggestion-actions">
              <button 
                className="implement-btn"
                onClick={() => updateSuggestionStatus(suggestion.id, 'implementing')}
                disabled={suggestion.status !== 'pending'}
              >
                Внедрить
              </button>
              <button 
                className="reject-btn"
                onClick={() => updateSuggestionStatus(suggestion.id, 'rejected')}
                disabled={suggestion.status !== 'pending'}
              >
                Отклонить
              </button>
            </div>
          </div>
        ))}

        {suggestions.length === 0 && (
          <div className="empty-state">
            <div className="empty-icon">🎯</div>
            <h3>Нет рекомендаций по оптимизации</h3>
            <p>Ваши рабочие процессы уже оптимизированы или анализ еще не завершен</p>
          </div>
        )}
      </div>
    </div>
  );
};

export default WorkflowOptimization;