import React, { useState, useEffect } from 'react';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000/api/v1';

const UserActivityMonitor: React.FC = () => {
  const [activities, setActivities] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchActivities = async () => {
      try {
        const response = await fetch(`${API_BASE_URL}/admin/users/activity/monitor`);
        const data = await response.json();
        setActivities(data.activities || []);
      } catch (err) {
        console.error('Ошибка загрузки активности');
      } finally {
        setLoading(false);
      }
    };
    fetchActivities();
  }, []);

  if (loading) return <div>Загрузка мониторинга активности...</div>;

  return (
    <div className="user-activity-monitor">
      <h1>Мониторинг активности пользователей</h1>
      <div className="activity-grid">
        {activities.map((activity: any, index) => (
          <div key={index} className="activity-card">
            <h3>Пользователь: {activity.user}</h3>
            <p>Действие: {activity.action}</p>
            <p>Время: {activity.timestamp}</p>
          </div>
        ))}
      </div>
    </div>
  );
};

export default UserActivityMonitor;