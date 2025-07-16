import React, { useState, useEffect } from 'react';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000/api/v1';

const ComplianceReportingCenter: React.FC = () => {
  const [reports, setReports] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchReports = async () => {
      try {
        const response = await fetch(`${API_BASE_URL}/analytics/compliance/reporting`);
        const data = await response.json();
        setReports(data.reports || []);
      } catch (err) {
        console.error('Ошибка загрузки отчетов соответствия');
      } finally {
        setLoading(false);
      }
    };
    fetchReports();
  }, []);

  if (loading) return <div>Загрузка центра отчетности соответствия...</div>;

  return (
    <div className="compliance-reporting-center">
      <h1>Центр отчетности соответствия</h1>
      <div className="compliance-grid">
        {reports.map((report: any, index) => (
          <div key={index} className="compliance-card">
            <h3>{report.title}</h3>
            <div className="compliance-status">
              Статус: <span className={`status ${report.status}`}>{report.status}</span>
            </div>
            <div className="compliance-score">Оценка: {report.score}%</div>
            <button className="download-btn">Скачать отчет</button>
          </div>
        ))}
      </div>
    </div>
  );
};

export default ComplianceReportingCenter;