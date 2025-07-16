import React, { useState, useEffect } from 'react';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000/api/v1';

const ShiftPatternDesigner: React.FC = () => {
  const [patterns, setPatterns] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchPatterns = async () => {
      try {
        const response = await fetch(`${API_BASE_URL}/scheduling/patterns/library`);
        const data = await response.json();
        setPatterns(data.patterns || []);
      } catch (err) {
        console.error('Ошибка загрузки шаблонов смен');
      } finally {
        setLoading(false);
      }
    };
    fetchPatterns();
  }, []);

  if (loading) return <div>Загрузка дизайнера шаблонов смен...</div>;

  return (
    <div className="shift-pattern-designer">
      <h1>Дизайнер шаблонов смен</h1>
      <div className="pattern-designer">
        <div className="design-canvas">
          <h2>Создание нового шаблона</h2>
          <div className="pattern-grid">
            {Array.from({ length: 7 }, (_, day) => (
              <div key={day} className="day-column">
                <h3>День {day + 1}</h3>
                <div className="shift-slots">
                  <div className="shift-slot">09:00-17:00</div>
                  <div className="shift-slot">17:00-01:00</div>
                  <div className="shift-slot">01:00-09:00</div>
                </div>
              </div>
            ))}
          </div>
        </div>
        <div className="pattern-library">
          <h3>Библиотека шаблонов</h3>
          {patterns.map((pattern: any, index) => (
            <div key={index} className="pattern-item">
              <h4>{pattern.name}</h4>
              <p>Ротация: {pattern.rotation} дней</p>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default ShiftPatternDesigner;