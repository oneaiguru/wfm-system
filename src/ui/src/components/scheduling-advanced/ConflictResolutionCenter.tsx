import React, { useState, useEffect } from 'react';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000/api/v1';

const ConflictResolutionCenter: React.FC = () => {
  const [conflicts, setConflicts] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchConflicts = async () => {
      try {
        const response = await fetch(`${API_BASE_URL}/scheduling/conflicts/resolve`);
        const data = await response.json();
        setConflicts(data.conflicts || []);
      } catch (err) {
        console.error('Ошибка загрузки конфликтов');
      } finally {
        setLoading(false);
      }
    };
    fetchConflicts();
  }, []);

  const resolveConflict = async (conflictId: string, resolution: string) => {
    try {
      await fetch(`${API_BASE_URL}/scheduling/conflicts/resolve/${conflictId}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ resolution }),
      });
      setConflicts(prev => prev.filter((c: any) => c.id !== conflictId));
    } catch (err) {
      console.error('Ошибка разрешения конфликта');
    }
  };

  if (loading) return <div>Загрузка центра разрешения конфликтов...</div>;

  return (
    <div className="conflict-resolution-center">
      <h1>Центр разрешения конфликтов</h1>
      <div className="conflicts-list">
        {conflicts.map((conflict: any) => (
          <div key={conflict.id} className="conflict-card">
            <div className="conflict-header">
              <h3>{conflict.title}</h3>
              <span className={`severity ${conflict.severity}`}>{conflict.severity}</span>
            </div>
            <p>{conflict.description}</p>
            <div className="conflict-actions">
              <button onClick={() => resolveConflict(conflict.id, 'auto')}>
                Автоматическое разрешение
              </button>
              <button onClick={() => resolveConflict(conflict.id, 'manual')}>
                Ручное разрешение
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default ConflictResolutionCenter;