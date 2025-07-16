import React, { useState, useEffect } from 'react';

interface Integration {
  id: string;
  name: string;
  type: 'webhook' | 'api' | 'email' | 'database';
  status: 'active' | 'inactive' | 'error';
  lastSync: string;
  config: any;
}

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000/api/v1';

const WorkflowIntegrations: React.FC = () => {
  const [integrations, setIntegrations] = useState<Integration[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchIntegrations();
  }, []);

  const fetchIntegrations = async () => {
    try {
      setLoading(true);
      const response = await fetch(`${API_BASE_URL}/workflow/integrations/configure`);
      if (!response.ok) throw new Error('Ошибка загрузки интеграций');
      const data = await response.json();
      setIntegrations(data.integrations || []);
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Неизвестная ошибка');
    } finally {
      setLoading(false);
    }
  };

  const configureIntegration = async (integration: Partial<Integration>) => {
    try {
      const response = await fetch(`${API_BASE_URL}/workflow/integrations/configure`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(integration),
      });
      if (!response.ok) throw new Error('Ошибка настройки интеграции');
      const newIntegration = await response.json();
      setIntegrations(prev => [...prev, newIntegration]);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Ошибка настройки интеграции');
    }
  };

  if (loading) {
    return (
      <div className="workflow-integrations">
        <div className="loading-spinner">
          <div className="spinner"></div>
          <p>Загрузка интеграций...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="workflow-integrations">
      <div className="integrations-header">
        <h1>Интеграции рабочих процессов</h1>
        <button className="add-integration-btn">+ Добавить интеграцию</button>
      </div>

      {error && (
        <div className="error-message">
          <span className="error-icon">⚠️</span>
          {error}
          <button onClick={() => setError(null)}>✕</button>
        </div>
      )}

      <div className="integrations-grid">
        {integrations.map(integration => (
          <div key={integration.id} className="integration-card">
            <div className="integration-header">
              <h3>{integration.name}</h3>
              <span className={`status-badge ${integration.status}`}>
                {integration.status === 'active' ? 'Активна' : 
                 integration.status === 'inactive' ? 'Неактивна' : 'Ошибка'}
              </span>
            </div>
            <div className="integration-type">Тип: {integration.type}</div>
            <div className="last-sync">
              Последняя синхронизация: {new Date(integration.lastSync).toLocaleString('ru-RU')}
            </div>
            <div className="integration-actions">
              <button className="configure-btn">Настроить</button>
              <button className="test-btn">Тестировать</button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default WorkflowIntegrations;