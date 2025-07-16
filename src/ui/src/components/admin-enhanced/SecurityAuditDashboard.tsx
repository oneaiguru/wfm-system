import React, { useState, useEffect } from 'react';

interface SecurityEvent {
  id: string;
  timestamp: string;
  type: 'login' | 'logout' | 'failed_login' | 'permission_change' | 'data_access';
  user: string;
  severity: 'low' | 'medium' | 'high' | 'critical';
  description: string;
  ipAddress: string;
}

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000/api/v1';

const SecurityAuditDashboard: React.FC = () => {
  const [events, setEvents] = useState<SecurityEvent[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [filterSeverity, setFilterSeverity] = useState('all');

  useEffect(() => {
    fetchSecurityEvents();
  }, []);

  const fetchSecurityEvents = async () => {
    try {
      setLoading(true);
      const response = await fetch(`${API_BASE_URL}/admin/security/audit/dashboard`);
      if (!response.ok) throw new Error('Ошибка загрузки событий безопасности');
      const data = await response.json();
      setEvents(data.events || []);
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Неизвестная ошибка');
    } finally {
      setLoading(false);
    }
  };

  const getSeverityColor = (severity: string) => {
    switch (severity) {
      case 'critical': return '#e74c3c';
      case 'high': return '#f39c12';
      case 'medium': return '#f1c40f';
      case 'low': return '#27ae60';
      default: return '#95a5a6';
    }
  };

  const filteredEvents = events.filter(event => 
    filterSeverity === 'all' || event.severity === filterSeverity
  );

  if (loading) {
    return (
      <div className="security-audit-dashboard">
        <div className="loading-spinner">
          <div className="spinner"></div>
          <p>Загрузка аудита безопасности...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="security-audit-dashboard">
      <div className="audit-header">
        <h1>Панель аудита безопасности</h1>
        <select value={filterSeverity} onChange={(e) => setFilterSeverity(e.target.value)}>
          <option value="all">Все уровни</option>
          <option value="critical">Критический</option>
          <option value="high">Высокий</option>
          <option value="medium">Средний</option>
          <option value="low">Низкий</option>
        </select>
      </div>

      {error && (
        <div className="error-message">
          <span className="error-icon">⚠️</span>
          {error}
          <button onClick={() => setError(null)}>✕</button>
        </div>
      )}

      <div className="security-stats">
        <div className="stat-card critical">
          <h3>Критические</h3>
          <div className="stat-value">{events.filter(e => e.severity === 'critical').length}</div>
        </div>
        <div className="stat-card high">
          <h3>Высокие</h3>
          <div className="stat-value">{events.filter(e => e.severity === 'high').length}</div>
        </div>
        <div className="stat-card medium">
          <h3>Средние</h3>
          <div className="stat-value">{events.filter(e => e.severity === 'medium').length}</div>
        </div>
        <div className="stat-card low">
          <h3>Низкие</h3>
          <div className="stat-value">{events.filter(e => e.severity === 'low').length}</div>
        </div>
      </div>

      <div className="events-list">
        {filteredEvents.map(event => (
          <div key={event.id} className="event-card">
            <div className="event-header">
              <span 
                className="severity-indicator"
                style={{ backgroundColor: getSeverityColor(event.severity) }}
              ></span>
              <h3>{event.description}</h3>
              <span className="event-time">
                {new Date(event.timestamp).toLocaleString('ru-RU')}
              </span>
            </div>
            <div className="event-details">
              <div className="event-detail">
                <strong>Пользователь:</strong> {event.user}
              </div>
              <div className="event-detail">
                <strong>IP-адрес:</strong> {event.ipAddress}
              </div>
              <div className="event-detail">
                <strong>Тип события:</strong> {event.type}
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default SecurityAuditDashboard;