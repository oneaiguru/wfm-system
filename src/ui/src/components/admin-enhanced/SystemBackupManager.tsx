import React, { useState, useEffect } from 'react';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8001/api/v1';

const SystemBackupManager: React.FC = () => {
  const [backups, setBackups] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchBackups = async () => {
      try {
        const response = await fetch(`${API_BASE_URL}/admin/system/backup/manage`);
        const data = await response.json();
        setBackups(data.backups || []);
      } catch (err) {
        console.error('Ошибка загрузки резервных копий');
      } finally {
        setLoading(false);
      }
    };
    fetchBackups();
  }, []);

  const createBackup = async () => {
    try {
      await fetch(`${API_BASE_URL}/admin/system/backup/manage`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: 'create' }),
      });
      alert('Резервная копия создана');
    } catch (err) {
      alert('Ошибка создания резервной копии');
    }
  };

  if (loading) return <div>Загрузка менеджера резервных копий...</div>;

  return (
    <div className="system-backup-manager">
      <h1>Управление резервными копиями</h1>
      <button onClick={createBackup} className="create-backup-btn">
        Создать резервную копию
      </button>
      <div className="backups-list">
        {backups.map((backup: any, index) => (
          <div key={index} className="backup-card">
            <h3>Резервная копия {backup.id}</h3>
            <p>Дата: {backup.date}</p>
            <p>Размер: {backup.size}</p>
            <p>Статус: {backup.status}</p>
          </div>
        ))}
      </div>
    </div>
  );
};

export default SystemBackupManager;