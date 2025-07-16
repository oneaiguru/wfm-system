import React, { useState, useEffect } from 'react';

interface Role {
  id: string;
  name: string;
  description: string;
  permissions: Permission[];
  inheritedFrom?: string;
  userCount: number;
  isSystemRole: boolean;
}

interface Permission {
  id: string;
  name: string;
  module: string;
  actions: string[];
  granted: boolean;
}

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000/api/v1';

const AdvancedRoleEditor: React.FC = () => {
  const [roles, setRoles] = useState<Role[]>([]);
  const [selectedRole, setSelectedRole] = useState<Role | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchRoles();
  }, []);

  const fetchRoles = async () => {
    try {
      setLoading(true);
      const response = await fetch(`${API_BASE_URL}/admin/roles/advanced/create`);
      if (!response.ok) throw new Error('Ошибка загрузки ролей');
      const data = await response.json();
      setRoles(data.roles || []);
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Неизвестная ошибка');
    } finally {
      setLoading(false);
    }
  };

  const createRole = async (roleData: Partial<Role>) => {
    try {
      const response = await fetch(`${API_BASE_URL}/admin/roles/advanced/create`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(roleData),
      });
      if (!response.ok) throw new Error('Ошибка создания роли');
      const newRole = await response.json();
      setRoles(prev => [...prev, newRole]);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Ошибка создания роли');
    }
  };

  if (loading) {
    return (
      <div className="advanced-role-editor">
        <div className="loading-spinner">
          <div className="spinner"></div>
          <p>Загрузка ролей...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="advanced-role-editor">
      <div className="role-editor-header">
        <h1>Расширенный редактор ролей</h1>
        <button className="create-role-btn">
          + Создать роль
        </button>
      </div>

      {error && (
        <div className="error-message">
          <span className="error-icon">⚠️</span>
          {error}
          <button onClick={() => setError(null)}>✕</button>
        </div>
      )}

      <div className="role-editor-layout">
        <div className="roles-list">
          <h3>Список ролей</h3>
          {roles.map(role => (
            <div
              key={role.id}
              className={`role-item ${selectedRole?.id === role.id ? 'selected' : ''}`}
              onClick={() => setSelectedRole(role)}
            >
              <div className="role-info">
                <h4>{role.name}</h4>
                <p>{role.description}</p>
                <div className="role-meta">
                  <span>Пользователей: {role.userCount}</span>
                  {role.isSystemRole && <span className="system-role">Системная</span>}
                </div>
              </div>
            </div>
          ))}
        </div>

        <div className="role-editor-panel">
          {selectedRole ? (
            <div className="role-details">
              <h3>Права роли: {selectedRole.name}</h3>
              <div className="permissions-grid">
                {selectedRole.permissions.map(permission => (
                  <div key={permission.id} className="permission-card">
                    <h4>{permission.name}</h4>
                    <div className="permission-module">Модуль: {permission.module}</div>
                    <div className="permission-actions">
                      {permission.actions.map(action => (
                        <span key={action} className="action-tag">{action}</span>
                      ))}
                    </div>
                    <label className="permission-toggle">
                      <input
                        type="checkbox"
                        checked={permission.granted}
                        onChange={() => {}}
                      />
                      Разрешить
                    </label>
                  </div>
                ))}
              </div>
            </div>
          ) : (
            <div className="no-selection">
              <h3>Выберите роль для редактирования</h3>
              <p>Нажмите на роль в списке слева</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default AdvancedRoleEditor;