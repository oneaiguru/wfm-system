import React, { useState, useEffect } from 'react';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000/api/v1';

const ScheduleTemplateLibrary: React.FC = () => {
  const [templates, setTemplates] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchTemplates = async () => {
      try {
        const response = await fetch(`${API_BASE_URL}/scheduling/templates/advanced`);
        const data = await response.json();
        setTemplates(data.templates || []);
      } catch (err) {
        console.error('Ошибка загрузки шаблонов');
      } finally {
        setLoading(false);
      }
    };
    fetchTemplates();
  }, []);

  if (loading) return <div>Загрузка библиотеки шаблонов расписаний...</div>;

  return (
    <div className="schedule-template-library">
      <h1>Библиотека шаблонов расписаний</h1>
      <div className="templates-grid">
        {templates.map((template: any) => (
          <div key={template.id} className="template-card">
            <h3>{template.name}</h3>
            <p>{template.description}</p>
            <div className="template-stats">
              <span>Смен: {template.shiftCount}</span>
              <span>Покрытие: {template.coverage}%</span>
            </div>
            <div className="template-actions">
              <button className="use-template-btn">Использовать</button>
              <button className="preview-btn">Предпросмотр</button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default ScheduleTemplateLibrary;