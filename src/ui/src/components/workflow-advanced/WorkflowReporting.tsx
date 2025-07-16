import React, { useState, useEffect } from 'react';
import './WorkflowReporting.css';

interface WorkflowReport {
  id: string;
  title: string;
  type: 'summary' | 'detailed' | 'performance' | 'audit';
  dateRange: { start: string; end: string };
  metrics: {
    totalWorkflows: number;
    completedWorkflows: number;
    averageCompletionTime: number;
    bottlenecks: string[];
  };
  status: 'generating' | 'ready' | 'error';
  generatedAt: string;
}

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000/api/v1';

const WorkflowReporting: React.FC = () => {
  const [reports, setReports] = useState<WorkflowReport[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedReport, setSelectedReport] = useState<WorkflowReport | null>(null);
  const [showCreateModal, setShowCreateModal] = useState(false);

  useEffect(() => {
    fetchReports();
  }, []);

  const fetchReports = async () => {
    try {
      setLoading(true);
      const response = await fetch(`${API_BASE_URL}/workflow/analytics/reports`);
      if (!response.ok) throw new Error('Ошибка загрузки отчетов');
      const data = await response.json();
      setReports(data.reports || []);
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Неизвестная ошибка');
    } finally {
      setLoading(false);
    }
  };

  const generateReport = async (reportConfig: any) => {
    try {
      const response = await fetch(`${API_BASE_URL}/workflow/analytics/reports`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(reportConfig),
      });
      if (!response.ok) throw new Error('Ошибка создания отчета');
      const newReport = await response.json();
      setReports(prev => [...prev, newReport]);
      setShowCreateModal(false);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Ошибка создания отчета');
    }
  };

  if (loading) {
    return (
      <div className="workflow-reporting">
        <div className="loading-spinner">
          <div className="spinner"></div>
          <p>Загрузка отчетов...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="workflow-reporting">
      <div className="reporting-header">
        <h1>Отчеты по рабочим процессам</h1>
        <button className="create-report-btn" onClick={() => setShowCreateModal(true)}>
          + Создать отчет
        </button>
      </div>

      {error && (
        <div className="error-message">
          <span className="error-icon">⚠️</span>
          {error}
          <button onClick={() => setError(null)}>✕</button>
        </div>
      )}

      <div className="reports-grid">
        {reports.map(report => (
          <div key={report.id} className="report-card">
            <div className="report-header">
              <h3>{report.title}</h3>
              <span className={`status-badge ${report.status}`}>
                {report.status === 'ready' ? 'Готов' : 
                 report.status === 'generating' ? 'Генерируется' : 'Ошибка'}
              </span>
            </div>
            
            <div className="report-metrics">
              <div className="metric">
                <span className="metric-label">Всего процессов:</span>
                <span className="metric-value">{report.metrics.totalWorkflows}</span>
              </div>
              <div className="metric">
                <span className="metric-label">Завершено:</span>
                <span className="metric-value">{report.metrics.completedWorkflows}</span>
              </div>
              <div className="metric">
                <span className="metric-label">Среднее время:</span>
                <span className="metric-value">{report.metrics.averageCompletionTime}ч</span>
              </div>
            </div>

            <div className="report-actions">
              <button 
                className="view-btn"
                onClick={() => setSelectedReport(report)}
                disabled={report.status !== 'ready'}
              >
                Просмотр
              </button>
              <button className="download-btn" disabled={report.status !== 'ready'}>
                Скачать
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default WorkflowReporting;