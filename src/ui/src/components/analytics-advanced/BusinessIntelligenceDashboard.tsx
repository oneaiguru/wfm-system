import React, { useState, useEffect } from 'react';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000/api/v1';

const BusinessIntelligenceDashboard: React.FC = () => {
  const [kpis, setKpis] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchBI = async () => {
      try {
        const response = await fetch(`${API_BASE_URL}/analytics/business-intelligence/dashboard`);
        const data = await response.json();
        setKpis(data.kpis || []);
      } catch (err) {
        console.error('Ошибка загрузки BI');
      } finally {
        setLoading(false);
      }
    };
    fetchBI();
  }, []);

  if (loading) return <div>Загрузка бизнес-аналитики...</div>;

  return (
    <div className="business-intelligence-dashboard">
      <h1>Панель бизнес-аналитики</h1>
      <div className="kpi-grid">
        {kpis.map((kpi: any, index) => (
          <div key={index} className="kpi-card">
            <h3>{kpi.name}</h3>
            <div className="kpi-value">{kpi.value}</div>
            <div className="kpi-target">Цель: {kpi.target}</div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default BusinessIntelligenceDashboard;