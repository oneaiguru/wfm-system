import React, { useState, useEffect } from 'react';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8001/api/v1';

const RealTimeDataVisualization: React.FC = () => {
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchRealTimeData = async () => {
      try {
        const response = await fetch(`${API_BASE_URL}/analytics/data/realtime/visualization`);
        const data = await response.json();
        setData(data.visualizations || []);
      } catch (err) {
        console.error('Ошибка загрузки данных');
      } finally {
        setLoading(false);
      }
    };
    fetchRealTimeData();
    const interval = setInterval(fetchRealTimeData, 5000); // Update every 5 seconds
    return () => clearInterval(interval);
  }, []);

  if (loading) return <div>Загрузка визуализации данных в реальном времени...</div>;

  return (
    <div className="realtime-data-visualization">
      <h1>Визуализация данных в реальном времени</h1>
      <div className="visualization-grid">
        {data.map((viz: any, index) => (
          <div key={index} className="visualization-card">
            <h3>{viz.title}</h3>
            <div className="chart-container">📈 График в реальном времени</div>
            <div className="last-update">Обновлено: {new Date().toLocaleTimeString('ru-RU')}</div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default RealTimeDataVisualization;