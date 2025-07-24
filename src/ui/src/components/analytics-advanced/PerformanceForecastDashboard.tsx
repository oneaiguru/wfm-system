import React, { useState, useEffect } from 'react';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8001/api/v1';

const PerformanceForecastDashboard: React.FC = () => {
  const [forecasts, setForecasts] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchForecasts = async () => {
      try {
        const response = await fetch(`${API_BASE_URL}/analytics/performance/forecast`);
        const data = await response.json();
        setForecasts(data.forecasts || []);
      } catch (err) {
        console.error('Ошибка загрузки прогнозов');
      } finally {
        setLoading(false);
      }
    };
    fetchForecasts();
  }, []);

  if (loading) return <div>Загрузка прогнозов производительности...</div>;

  return (
    <div className="performance-forecast-dashboard">
      <h1>Прогнозирование производительности</h1>
      <div className="forecasts-grid">
        {forecasts.map((forecast: any, index) => (
          <div key={index} className="forecast-card">
            <h3>Прогноз {forecast.type}</h3>
            <div className="forecast-chart">📊 График прогноза</div>
            <div className="forecast-accuracy">Точность: {forecast.accuracy}%</div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default PerformanceForecastDashboard;