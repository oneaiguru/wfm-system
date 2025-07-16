import React, { useState, useEffect } from 'react';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000/api/v1';

const PredictiveAnalyticsEngine: React.FC = () => {
  const [predictions, setPredictions] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchPredictions = async () => {
      try {
        const response = await fetch(`${API_BASE_URL}/analytics/predictive/engine`);
        const data = await response.json();
        setPredictions(data.predictions || []);
      } catch (err) {
        console.error('Ошибка загрузки прогнозной аналитики');
      } finally {
        setLoading(false);
      }
    };
    fetchPredictions();
  }, []);

  if (loading) return <div>Загрузка движка прогнозной аналитики...</div>;

  return (
    <div className="predictive-analytics-engine">
      <h1>Движок прогнозной аналитики</h1>
      <div className="predictions-grid">
        {predictions.map((prediction: any, index) => (
          <div key={index} className="prediction-card">
            <h3>{prediction.model}</h3>
            <div className="prediction-value">
              Прогноз: {prediction.value}
            </div>
            <div className="confidence-level">
              Уверенность: {prediction.confidence}%
            </div>
            <div className="prediction-horizon">
              Горизонт: {prediction.horizon}
            </div>
            <button className="run-prediction-btn">Запустить прогноз</button>
          </div>
        ))}
      </div>
    </div>
  );
};

export default PredictiveAnalyticsEngine;