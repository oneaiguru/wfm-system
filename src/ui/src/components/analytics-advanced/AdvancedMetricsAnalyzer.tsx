import React, { useState, useEffect } from 'react';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8001/api/v1';

const AdvancedMetricsAnalyzer: React.FC = () => {
  const [metrics, setMetrics] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchMetrics = async () => {
      try {
        const response = await fetch(`${API_BASE_URL}/analytics/metrics/advanced`);
        const data = await response.json();
        setMetrics(data.metrics || []);
      } catch (err) {
        console.error('Ошибка загрузки метрик');
      } finally {
        setLoading(false);
      }
    };
    fetchMetrics();
  }, []);

  if (loading) return <div>Загрузка расширенного анализа метрик...</div>;

  return (
    <div className="advanced-metrics-analyzer">
      <h1>Расширенный анализ метрик</h1>
      <div className="metrics-dashboard">
        {metrics.map((metric: any, index) => (
          <div key={index} className="metric-card advanced">
            <h3>{metric.name}</h3>
            <div className="metric-value">{metric.value}</div>
            <div className="metric-trend">Тренд: {metric.trend}</div>
            <div className="metric-prediction">Прогноз: {metric.prediction}</div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default AdvancedMetricsAnalyzer;