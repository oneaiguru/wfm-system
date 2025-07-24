import React, { useState, useEffect } from 'react';
import './WorkflowTemplates.css';

interface WorkflowTemplate {
  id: string;
  name: string;
  description: string;
  category: string;
  steps: WorkflowStep[];
  isPublic: boolean;
  createdBy: string;
  createdAt: string;
  usageCount: number;
  rating: number;
}

interface WorkflowStep {
  id: string;
  name: string;
  type: 'approval' | 'notification' | 'condition' | 'action';
  config: any;
  position: { x: number; y: number };
}

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8001/api/v1';

const WorkflowTemplates: React.FC = () => {
  const [templates, setTemplates] = useState<WorkflowTemplate[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedCategory, setSelectedCategory] = useState('all');
  const [searchQuery, setSearchQuery] = useState('');
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [newTemplate, setNewTemplate] = useState<Partial<WorkflowTemplate>>({
    name: '',
    description: '',
    category: 'general',
    steps: [],
    isPublic: false
  });

  const categories = [
    { value: 'all', label: 'Все категории' },
    { value: 'approval', label: 'Согласование' },
    { value: 'vacation', label: 'Отпуска' },
    { value: 'shift', label: 'Смены' },
    { value: 'notification', label: 'Уведомления' },
    { value: 'general', label: 'Общие' }
  ];

  useEffect(() => {
    fetchTemplates();
  }, []);

  const fetchTemplates = async () => {
    try {
      setLoading(true);
      const response = await fetch(`${API_BASE_URL}/workflow/templates/library`);
      if (!response.ok) {
        throw new Error('Ошибка загрузки шаблонов');
      }
      const data = await response.json();
      setTemplates(data.templates || []);
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Неизвестная ошибка');
    } finally {
      setLoading(false);
    }
  };

  const createTemplate = async (template: Partial<WorkflowTemplate>) => {
    try {
      const response = await fetch(`${API_BASE_URL}/workflow/templates/library`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(template),
      });

      if (!response.ok) {
        throw new Error('Ошибка создания шаблона');
      }

      const newTemplateData = await response.json();
      setTemplates(prev => [...prev, newTemplateData]);
      setShowCreateModal(false);
      setNewTemplate({
        name: '',
        description: '',
        category: 'general',
        steps: [],
        isPublic: false
      });
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Ошибка создания шаблона');
    }
  };

  const useTemplate = async (templateId: string) => {
    try {
      const response = await fetch(`${API_BASE_URL}/workflow/templates/library/${templateId}/use`, {
        method: 'POST',
      });

      if (!response.ok) {
        throw new Error('Ошибка использования шаблона');
      }

      // Update usage count
      setTemplates(prev => prev.map(template => 
        template.id === templateId 
          ? { ...template, usageCount: template.usageCount + 1 }
          : template
      ));

      alert('Шаблон успешно применен к новому рабочему процессу');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Ошибка использования шаблона');
    }
  };

  const deleteTemplate = async (templateId: string) => {
    if (!window.confirm('Вы уверены, что хотите удалить этот шаблон?')) {
      return;
    }

    try {
      const response = await fetch(`${API_BASE_URL}/workflow/templates/library/${templateId}`, {
        method: 'DELETE',
      });

      if (!response.ok) {
        throw new Error('Ошибка удаления шаблона');
      }

      setTemplates(prev => prev.filter(template => template.id !== templateId));
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Ошибка удаления шаблона');
    }
  };

  const filteredTemplates = templates.filter(template => {
    const categoryMatch = selectedCategory === 'all' || template.category === selectedCategory;
    const searchMatch = template.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
                       template.description.toLowerCase().includes(searchQuery.toLowerCase());
    return categoryMatch && searchMatch;
  });

  const addStep = () => {
    const newStep: WorkflowStep = {
      id: Date.now().toString(),
      name: 'Новый шаг',
      type: 'approval',
      config: {},
      position: { x: 100, y: 100 }
    };
    setNewTemplate(prev => ({
      ...prev,
      steps: [...(prev.steps || []), newStep]
    }));
  };

  const updateStep = (stepId: string, field: string, value: any) => {
    setNewTemplate(prev => ({
      ...prev,
      steps: prev.steps?.map(step => 
        step.id === stepId ? { ...step, [field]: value } : step
      ) || []
    }));
  };

  const removeStep = (stepId: string) => {
    setNewTemplate(prev => ({
      ...prev,
      steps: prev.steps?.filter(step => step.id !== stepId) || []
    }));
  };

  if (loading) {
    return (
      <div className="workflow-templates">
        <div className="loading-spinner">
          <div className="spinner"></div>
          <p>Загрузка шаблонов...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="workflow-templates">
      <div className="templates-header">
        <h1>Шаблоны рабочих процессов</h1>
        <button 
          className="create-template-btn"
          onClick={() => setShowCreateModal(true)}
        >
          + Создать шаблон
        </button>
      </div>

      {error && (
        <div className="error-message">
          <span className="error-icon">⚠️</span>
          {error}
          <button onClick={() => setError(null)}>✕</button>
        </div>
      )}

      <div className="templates-filters">
        <div className="search-bar">
          <input
            type="text"
            placeholder="Поиск шаблонов..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
        </div>
        <div className="category-filter">
          <select
            value={selectedCategory}
            onChange={(e) => setSelectedCategory(e.target.value)}
          >
            {categories.map(category => (
              <option key={category.value} value={category.value}>
                {category.label}
              </option>
            ))}
          </select>
        </div>
      </div>

      <div className="templates-stats">
        <div className="stat-card">
          <h3>Всего шаблонов</h3>
          <div className="stat-value">{templates.length}</div>
        </div>
        <div className="stat-card">
          <h3>Публичных</h3>
          <div className="stat-value">{templates.filter(t => t.isPublic).length}</div>
        </div>
        <div className="stat-card">
          <h3>Популярных</h3>
          <div className="stat-value">{templates.filter(t => t.usageCount > 10).length}</div>
        </div>
      </div>

      <div className="templates-grid">
        {filteredTemplates.map(template => (
          <div key={template.id} className="template-card">
            <div className="template-header">
              <h3>{template.name}</h3>
              <div className="template-badges">
                {template.isPublic && <span className="badge public">Публичный</span>}
                <span className="badge category">{template.category}</span>
              </div>
            </div>
            
            <p className="template-description">{template.description}</p>
            
            <div className="template-stats">
              <div className="stat">
                <span className="stat-label">Шагов:</span>
                <span className="stat-value">{template.steps.length}</span>
              </div>
              <div className="stat">
                <span className="stat-label">Использований:</span>
                <span className="stat-value">{template.usageCount}</span>
              </div>
              <div className="stat">
                <span className="stat-label">Рейтинг:</span>
                <span className="stat-value">⭐ {template.rating.toFixed(1)}</span>
              </div>
            </div>

            <div className="template-meta">
              <div className="created-by">Автор: {template.createdBy}</div>
              <div className="created-at">
                Создан: {new Date(template.createdAt).toLocaleDateString('ru-RU')}
              </div>
            </div>

            <div className="template-actions">
              <button 
                className="use-btn"
                onClick={() => useTemplate(template.id)}
              >
                Использовать
              </button>
              <button 
                className="edit-btn"
                title="Редактировать шаблон"
              >
                ✏️
              </button>
              <button 
                className="delete-btn"
                onClick={() => deleteTemplate(template.id)}
                title="Удалить шаблон"
              >
                🗑️
              </button>
            </div>
          </div>
        ))}

        {filteredTemplates.length === 0 && (
          <div className="empty-state">
            <div className="empty-icon">📋</div>
            <h3>Шаблоны не найдены</h3>
            <p>Создайте первый шаблон или измените критерии поиска</p>
            <button 
              className="create-first-template-btn"
              onClick={() => setShowCreateModal(true)}
            >
              Создать шаблон
            </button>
          </div>
        )}
      </div>

      {showCreateModal && (
        <div className="modal-overlay">
          <div className="create-template-modal">
            <div className="modal-header">
              <h2>Создание шаблона рабочего процесса</h2>
              <button 
                className="close-btn"
                onClick={() => setShowCreateModal(false)}
              >
                ✕
              </button>
            </div>

            <div className="modal-body">
              <div className="form-section">
                <div className="form-group">
                  <label>Название шаблона</label>
                  <input
                    type="text"
                    value={newTemplate.name || ''}
                    onChange={(e) => setNewTemplate(prev => ({ ...prev, name: e.target.value }))}
                    placeholder="Введите название шаблона"
                  />
                </div>

                <div className="form-group">
                  <label>Описание</label>
                  <textarea
                    value={newTemplate.description || ''}
                    onChange={(e) => setNewTemplate(prev => ({ ...prev, description: e.target.value }))}
                    placeholder="Описание шаблона"
                    rows={3}
                  />
                </div>

                <div className="form-row">
                  <div className="form-group">
                    <label>Категория</label>
                    <select
                      value={newTemplate.category || 'general'}
                      onChange={(e) => setNewTemplate(prev => ({ ...prev, category: e.target.value }))}
                    >
                      {categories.slice(1).map(category => (
                        <option key={category.value} value={category.value}>
                          {category.label}
                        </option>
                      ))}
                    </select>
                  </div>

                  <div className="form-group">
                    <label className="checkbox-label">
                      <input
                        type="checkbox"
                        checked={newTemplate.isPublic || false}
                        onChange={(e) => setNewTemplate(prev => ({ ...prev, isPublic: e.target.checked }))}
                      />
                      Публичный шаблон
                    </label>
                  </div>
                </div>
              </div>

              <div className="steps-section">
                <div className="steps-header">
                  <h3>Шаги процесса</h3>
                  <button 
                    className="add-step-btn"
                    onClick={addStep}
                    type="button"
                  >
                    + Добавить шаг
                  </button>
                </div>

                <div className="steps-list">
                  {newTemplate.steps?.map((step, index) => (
                    <div key={step.id} className="step-item">
                      <div className="step-number">{index + 1}</div>
                      <div className="step-content">
                        <input
                          type="text"
                          value={step.name}
                          onChange={(e) => updateStep(step.id, 'name', e.target.value)}
                          placeholder="Название шага"
                        />
                        <select
                          value={step.type}
                          onChange={(e) => updateStep(step.id, 'type', e.target.value)}
                        >
                          <option value="approval">Согласование</option>
                          <option value="notification">Уведомление</option>
                          <option value="condition">Условие</option>
                          <option value="action">Действие</option>
                        </select>
                      </div>
                      <button 
                        className="remove-step"
                        onClick={() => removeStep(step.id)}
                      >
                        Удалить
                      </button>
                    </div>
                  ))}
                </div>
              </div>
            </div>

            <div className="modal-footer">
              <button 
                className="cancel-btn"
                onClick={() => setShowCreateModal(false)}
              >
                Отмена
              </button>
              <button 
                className="save-btn"
                onClick={() => createTemplate(newTemplate)}
                disabled={!newTemplate.name || !newTemplate.description}
              >
                Создать шаблон
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default WorkflowTemplates;