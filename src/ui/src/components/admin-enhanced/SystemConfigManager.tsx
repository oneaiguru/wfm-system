import React, { useState, useEffect } from 'react';

interface SystemConfig {
  id: string;
  category: string;
  name: string;
  value: any;
  type: 'string' | 'number' | 'boolean' | 'json';
  description: string;
  isAdvanced: boolean;
  requiresRestart: boolean;
}

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000/api/v1';

const SystemConfigManager: React.FC = () => {
  const [configs, setConfigs] = useState<SystemConfig[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedCategory, setSelectedCategory] = useState('all');
  const [showAdvanced, setShowAdvanced] = useState(false);

  const categories = ['all', 'system', 'database', 'security', 'performance', 'integration'];

  useEffect(() => {
    fetchConfigs();
  }, []);

  const fetchConfigs = async () => {
    try {
      setLoading(true);
      const response = await fetch(`${API_BASE_URL}/admin/config/advanced`);
      if (!response.ok) throw new Error('Ошибка загрузки конфигурации');
      const data = await response.json();
      setConfigs(data.configs || []);
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Неизвестная ошибка');
    } finally {
      setLoading(false);
    }
  };

  const updateConfig = async (configId: string, newValue: any) => {
    try {
      const response = await fetch(`${API_BASE_URL}/admin/config/advanced/${configId}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ value: newValue }),
      });
      if (!response.ok) throw new Error('Ошибка обновления конфигурации');
      setConfigs(prev => prev.map(config =>
        config.id === configId ? { ...config, value: newValue } : config
      ));
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Ошибка обновления');
    }
  };

  const filteredConfigs = configs.filter(config => {
    const categoryMatch = selectedCategory === 'all' || config.category === selectedCategory;
    const advancedMatch = showAdvanced || !config.isAdvanced;
    return categoryMatch && advancedMatch;
  });

  if (loading) {
    return (
      <div className="system-config-manager">
        <div className="loading-spinner">
          <div className="spinner"></div>
          <p>Загрузка конфигурации системы...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="system-config-manager">
      <div className="config-header">
        <h1>Управление конфигурацией системы</h1>
        <div className="header-controls">
          <select value={selectedCategory} onChange={(e) => setSelectedCategory(e.target.value)}>
            {categories.map(cat => (
              <option key={cat} value={cat}>
                {cat === 'all' ? 'Все категории' : cat}
              </option>
            ))}
          </select>
          <label className="advanced-toggle">
            <input
              type="checkbox"
              checked={showAdvanced}
              onChange={(e) => setShowAdvanced(e.target.checked)}
            />
            Показать расширенные настройки
          </label>
        </div>
      </div>

      {error && (
        <div className="error-message">
          <span className="error-icon">⚠️</span>
          {error}
          <button onClick={() => setError(null)}>✕</button>
        </div>
      )}

      <div className="config-grid">
        {filteredConfigs.map(config => (
          <div key={config.id} className={`config-card ${config.isAdvanced ? 'advanced' : ''}`}>
            <div className="config-header">
              <h3>{config.name}</h3>
              <div className="config-badges">
                <span className="category-badge">{config.category}</span>
                {config.isAdvanced && <span className="advanced-badge">Расширенная</span>}
                {config.requiresRestart && <span className="restart-badge">Требует перезапуск</span>}
              </div>
            </div>
            
            <p className="config-description">{config.description}</p>
            
            <div className="config-control">
              {config.type === 'boolean' ? (
                <label className="switch">
                  <input
                    type="checkbox"
                    checked={config.value}
                    onChange={(e) => updateConfig(config.id, e.target.checked)}
                  />
                  <span className="slider"></span>
                </label>
              ) : config.type === 'number' ? (
                <input
                  type="number"
                  value={config.value}
                  onChange={(e) => updateConfig(config.id, parseFloat(e.target.value) || 0)}
                />
              ) : config.type === 'json' ? (
                <textarea
                  value={JSON.stringify(config.value, null, 2)}
                  onChange={(e) => {
                    try {
                      const parsed = JSON.parse(e.target.value);
                      updateConfig(config.id, parsed);
                    } catch (err) {
                      // Invalid JSON, don't update
                    }
                  }}
                  rows={4}
                />
              ) : (
                <input
                  type="text"
                  value={config.value}
                  onChange={(e) => updateConfig(config.id, e.target.value)}
                />
              )}
            </div>
          </div>
        ))}
      </div>

      {filteredConfigs.length === 0 && (
        <div className="empty-state">
          <div className="empty-icon">⚙️</div>
          <h3>Конфигурации не найдены</h3>
          <p>Попробуйте изменить фильтры поиска</p>
        </div>
      )}
    </div>
  );
};

export default SystemConfigManager;