import React, { useState } from 'react';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000/api/v1';

const AutoSchedulingEngine: React.FC = () => {
  const [generating, setGenerating] = useState(false);
  const [progress, setProgress] = useState(0);

  const generateSchedule = async () => {
    setGenerating(true);
    setProgress(0);
    
    try {
      const response = await fetch(`${API_BASE_URL}/scheduling/auto/generate`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ 
          period: '2024-01-01_2024-01-31',
          algorithm: 'advanced_ai'
        }),
      });
      
      // Simulate progress updates
      const interval = setInterval(() => {
        setProgress(prev => {
          if (prev >= 90) {
            clearInterval(interval);
            return 100;
          }
          return prev + 10;
        });
      }, 500);
      
      const data = await response.json();
      alert('Автоматическое расписание создано успешно!');
    } catch (err) {
      console.error('Ошибка автоматического создания расписания');
    } finally {
      setGenerating(false);
    }
  };

  return (
    <div className="auto-scheduling-engine">
      <h1>Движок автоматического планирования</h1>
      <div className="engine-controls">
        <div className="settings-panel">
          <h3>Параметры автопланирования</h3>
          <div className="setting-group">
            <label>Алгоритм планирования</label>
            <select>
              <option value="advanced_ai">Продвинутый ИИ</option>
              <option value="genetic">Генетический алгоритм</option>
              <option value="constraint_based">На основе ограничений</option>
            </select>
          </div>
          <div className="setting-group">
            <label>Приоритет оптимизации</label>
            <select>
              <option value="coverage">Максимальное покрытие</option>
              <option value="cost">Минимальные затраты</option>
              <option value="satisfaction">Удовлетворенность сотрудников</option>
            </select>
          </div>
        </div>
        
        <div className="generation-panel">
          <button 
            onClick={generateSchedule} 
            disabled={generating}
            className="generate-btn"
          >
            {generating ? 'Создание расписания...' : 'Создать автоматически'}
          </button>
          
          {generating && (
            <div className="progress-indicator">
              <div className="progress-bar">
                <div 
                  className="progress-fill" 
                  style={{ width: `${progress}%` }}
                ></div>
              </div>
              <div className="progress-text">{progress}% завершено</div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default AutoSchedulingEngine;