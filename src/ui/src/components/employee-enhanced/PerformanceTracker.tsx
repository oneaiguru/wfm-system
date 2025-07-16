import React, { useState, useEffect } from 'react';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000/api/v1';

const PerformanceTracker: React.FC = () => {
  const [performanceData, setPerformanceData] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchPerformance = async () => {
      try {
        const response = await fetch(`${API_BASE_URL}/employees/performance/tracker`);
        const data = await response.json();
        setPerformanceData(data.performance || []);
      } catch (err) {
        console.error('Ошибка загрузки данных производительности');
      } finally {
        setLoading(false);
      }
    };
    fetchPerformance();
  }, []);

  if (loading) return <div>Загрузка трекера производительности...</div>;

  return (
    <div className="performance-tracker">
      <h1>Трекер производительности сотрудников</h1>
      <div className="performance-grid">
        {performanceData.map((employee: any) => (
          <div key={employee.id} className="performance-card">
            <h3>{employee.name}</h3>
            <div className="kpi-list">
              <div className="kpi-item">
                <span>Эффективность: {employee.efficiency}%</span>
                <div className="progress-bar">
                  <div style={{ width: `${employee.efficiency}%` }}></div>
                </div>
              </div>
              <div className="kpi-item">
                <span>Качество: {employee.quality}%</span>
                <div className="progress-bar">
                  <div style={{ width: `${employee.quality}%` }}></div>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default PerformanceTracker;