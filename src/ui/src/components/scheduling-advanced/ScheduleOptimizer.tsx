import React, { useState } from 'react';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000/api/v1';

const ScheduleOptimizer: React.FC = () => {
  const [optimizing, setOptimizing] = useState(false);
  const [results, setResults] = useState<any>(null);

  const runOptimization = async () => {
    setOptimizing(true);
    try {
      const response = await fetch(`${API_BASE_URL}/scheduling/optimize/engine`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ algorithm: 'genetic', iterations: 1000 }),
      });
      const data = await response.json();
      setResults(data);
    } catch (err) {
      console.error('Ошибка оптимизации');
    } finally {
      setOptimizing(false);
    }
  };

  return (
    <div className="schedule-optimizer">
      <h1>Оптимизатор расписаний</h1>
      <div className="optimizer-controls">
        <button onClick={runOptimization} disabled={optimizing} className="optimize-btn">
          {optimizing ? 'Оптимизация...' : 'Запустить оптимизацию'}
        </button>
      </div>
      {results && (
        <div className="optimization-results">
          <h2>Результаты оптимизации</h2>
          <div className="results-grid">
            <div className="result-card">
              <h3>Улучшение покрытия</h3>
              <div className="result-value">{results.coverageImprovement}%</div>
            </div>
            <div className="result-card">
              <h3>Сокращение сверхурочных</h3>
              <div className="result-value">{results.overtimeReduction}%</div>
            </div>
            <div className="result-card">
              <h3>Балансировка нагрузки</h3>
              <div className="result-value">{results.loadBalance}%</div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default ScheduleOptimizer;