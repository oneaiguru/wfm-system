import React, { useState } from 'react';
import { ShiftTemplate } from '../types/schedule';

const ShiftTemplateManager: React.FC = () => {
  const [templates, setTemplates] = useState<ShiftTemplate[]>([
    {
      id: '1',
      name: 'Day Shift',
      startTime: '08:00',
      endTime: '17:00',
      duration: 480,
      breakDuration: 60,
      color: '#74a689',
      type: 'day',
      workPattern: '5/2',
      isActive: true,
    },
    {
      id: '2',
      name: 'Night Shift',
      startTime: '20:00',
      endTime: '09:00',
      duration: 660,
      breakDuration: 60,
      color: '#4f46e5',
      type: 'night',
      workPattern: '2/2',
      isActive: true,
    },
    {
      id: '3',
      name: 'Short Shift',
      startTime: '10:00',
      endTime: '15:00',
      duration: 240,
      breakDuration: 30,
      color: '#f59e0b',
      type: 'day',
      workPattern: '6/1',
      isActive: false,
    },
  ]);

  const [isCreating, setIsCreating] = useState(false);
  const [editingTemplate, setEditingTemplate] = useState<ShiftTemplate | null>(null);
  const [formData, setFormData] = useState<Partial<ShiftTemplate>>({
    name: '',
    startTime: '08:00',
    endTime: '17:00',
    breakDuration: 60,
    color: '#74a689',
    type: 'day',
    workPattern: '5/2',
    isActive: true,
  });

  const calculateDuration = (start: string, end: string): number => {
    const [startHour, startMin] = start.split(':').map(Number);
    const [endHour, endMin] = end.split(':').map(Number);
    
    let startMinutes = startHour * 60 + startMin;
    let endMinutes = endHour * 60 + endMin;
    
    // Handle overnight shifts
    if (endMinutes <= startMinutes) {
      endMinutes += 24 * 60;
    }
    
    return endMinutes - startMinutes;
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    
    const duration = calculateDuration(formData.startTime!, formData.endTime!);
    
    const template: ShiftTemplate = {
      id: editingTemplate?.id || Date.now().toString(),
      name: formData.name!,
      startTime: formData.startTime!,
      endTime: formData.endTime!,
      duration,
      breakDuration: formData.breakDuration!,
      color: formData.color!,
      type: formData.type!,
      workPattern: formData.workPattern!,
      isActive: formData.isActive!,
    };

    if (editingTemplate) {
      setTemplates(prev => prev.map(t => t.id === editingTemplate.id ? template : t));
      console.log('✏️ Updated template:', template.name);
    } else {
      setTemplates(prev => [...prev, template]);
      console.log('➕ Created new template:', template.name);
    }

    handleCancel();
  };

  const handleEdit = (template: ShiftTemplate) => {
    setEditingTemplate(template);
    setFormData(template);
    setIsCreating(true);
    console.log('✏️ Editing template:', template.name);
  };

  const handleDelete = (id: string) => {
    const template = templates.find(t => t.id === id);
    setTemplates(prev => prev.filter(t => t.id !== id));
    console.log('🗑️ Deleted template:', template?.name);
  };

  const handleCancel = () => {
    setIsCreating(false);
    setEditingTemplate(null);
    setFormData({
      name: '',
      startTime: '08:00',
      endTime: '17:00',
      breakDuration: 60,
      color: '#74a689',
      type: 'day',
      workPattern: '5/2',
      isActive: true,
    });
  };

  const toggleStatus = (id: string) => {
    setTemplates(prev => prev.map(t => 
      t.id === id ? { ...t, isActive: !t.isActive } : t
    ));
  };

  const formatDuration = (minutes: number): string => {
    const hours = Math.floor(minutes / 60);
    const mins = minutes % 60;
    return `${hours}h ${mins > 0 ? `${mins}m` : ''}`.trim();
  };

  const getTypeIcon = (type: ShiftTemplate['type']) => {
    switch (type) {
      case 'day': return '☀️';
      case 'night': return '🌙';
      case 'overtime': return '⏰';
      default: return '🕒';
    }
  };

  const getTypeLabel = (type: ShiftTemplate['type']) => {
    switch (type) {
      case 'day': return 'Day Shift';
      case 'night': return 'Night Shift';
      case 'overtime': return 'Overtime';
      default: return 'Shift';
    }
  };

  return (
    <div style={{ 
      height: 'calc(100vh - 180px)', 
      display: 'flex', 
      flexDirection: 'column', 
      backgroundColor: 'white',
      padding: '24px'
    }}>
      {/* Header */}
      <div style={{ 
        display: 'flex', 
        justifyContent: 'space-between', 
        alignItems: 'center', 
        marginBottom: '24px',
        borderBottom: '1px solid #e5e7eb',
        paddingBottom: '16px'
      }}>
        <div>
          <h1 style={{ 
            fontSize: '24px', 
            fontWeight: 'bold', 
            color: '#111827', 
            margin: 0 
          }}>
            Shift Template Manager
          </h1>
          <p style={{ 
            fontSize: '14px', 
            color: '#6b7280', 
            margin: '4px 0 0 0' 
          }}>
            Create and manage shift templates
          </p>
        </div>

        <button
          onClick={() => setIsCreating(true)}
          style={{
            padding: '12px 24px',
            backgroundColor: '#059669',
            color: 'white',
            border: 'none',
            borderRadius: '8px',
            fontSize: '14px',
            fontWeight: '500',
            cursor: 'pointer',
          }}
        >
          ➕ Create Shift
        </button>
      </div>

      {/* Quick Stats */}
      <div style={{ 
        display: 'grid', 
        gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', 
        gap: '16px',
        marginBottom: '24px'
      }}>
        <div style={{
          padding: '16px',
          backgroundColor: '#dcfce7',
          borderRadius: '8px',
          border: '1px solid #bbf7d0'
        }}>
          <div style={{ fontSize: '24px', fontWeight: 'bold', color: '#166534' }}>
            {templates.filter(t => t.isActive).length}
          </div>
          <div style={{ fontSize: '14px', color: '#166534' }}>
            Active Templates
          </div>
        </div>
        
        <div style={{
          padding: '16px',
          backgroundColor: '#fef3c7',
          borderRadius: '8px',
          border: '1px solid #fde68a'
        }}>
          <div style={{ fontSize: '24px', fontWeight: 'bold', color: '#92400e' }}>
            {templates.filter(t => t.type === 'day').length}
          </div>
          <div style={{ fontSize: '14px', color: '#92400e' }}>
            Day Shifts
          </div>
        </div>
        
        <div style={{
          padding: '16px',
          backgroundColor: '#e0e7ff',
          borderRadius: '8px',
          border: '1px solid #c7d2fe'
        }}>
          <div style={{ fontSize: '24px', fontWeight: 'bold', color: '#3730a3' }}>
            {templates.filter(t => t.type === 'night').length}
          </div>
          <div style={{ fontSize: '14px', color: '#3730a3' }}>
            Night Shifts
          </div>
        </div>
      </div>

      {/* Templates Grid */}
      <div style={{ flex: 1, overflow: 'auto' }}>
        <div style={{ 
          display: 'grid', 
          gridTemplateColumns: 'repeat(auto-fill, minmax(350px, 1fr))', 
          gap: '20px' 
        }}>
          {templates.map(template => (
            <div
              key={template.id}
              style={{
                border: '1px solid #e5e7eb',
                borderRadius: '12px',
                padding: '20px',
                backgroundColor: 'white',
                boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)',
                opacity: template.isActive ? 1 : 0.6,
                borderLeft: `4px solid ${template.color}`
              }}
            >
              {/* Template Header */}
              <div style={{ 
                display: 'flex', 
                justifyContent: 'space-between', 
                alignItems: 'start',
                marginBottom: '16px'
              }}>
                <div style={{ flex: 1 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '4px' }}>
                    <span style={{ fontSize: '20px' }}>{getTypeIcon(template.type)}</span>
                    <h3 style={{ 
                      fontSize: '18px', 
                      fontWeight: '600', 
                      color: '#111827', 
                      margin: 0 
                    }}>
                      {template.name}
                    </h3>
                  </div>
                  
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <span style={{
                      padding: '2px 8px',
                      borderRadius: '12px',
                      fontSize: '12px',
                      fontWeight: '500',
                      backgroundColor: template.isActive ? '#dcfce7' : '#fef2f2',
                      color: template.isActive ? '#166534' : '#dc2626'
                    }}>
                      {template.isActive ? 'Active' : 'Inactive'}
                    </span>
                    <span style={{
                      padding: '2px 8px',
                      borderRadius: '12px',
                      fontSize: '12px',
                      fontWeight: '500',
                      backgroundColor: '#f3f4f6',
                      color: '#6b7280'
                    }}>
                      {getTypeLabel(template.type)}
                    </span>
                  </div>
                </div>

                <div style={{ display: 'flex', gap: '6px' }}>
                  <button
                    onClick={() => handleEdit(template)}
                    style={{
                      padding: '6px 10px',
                      backgroundColor: '#f3f4f6',
                      color: '#374151',
                      border: 'none',
                      borderRadius: '6px',
                      fontSize: '12px',
                      cursor: 'pointer'
                    }}
                  >
                    ✏️
                  </button>
                  
                  <button
                    onClick={() => toggleStatus(template.id)}
                    style={{
                      padding: '6px 10px',
                      backgroundColor: template.isActive ? '#fef3c7' : '#dcfce7',
                      color: template.isActive ? '#92400e' : '#166534',
                      border: 'none',
                      borderRadius: '6px',
                      fontSize: '12px',
                      cursor: 'pointer'
                    }}
                  >
                    {template.isActive ? '⏸️' : '▶️'}
                  </button>
                  
                  <button
                    onClick={() => handleDelete(template.id)}
                    style={{
                      padding: '6px 10px',
                      backgroundColor: '#fef2f2',
                      color: '#dc2626',
                      border: 'none',
                      borderRadius: '6px',
                      fontSize: '12px',
                      cursor: 'pointer'
                    }}
                  >
                    🗑️
                  </button>
                </div>
              </div>

              {/* Shift Details */}
              <div style={{ marginBottom: '16px' }}>
                <div style={{ 
                  display: 'grid', 
                  gridTemplateColumns: '1fr 1fr', 
                  gap: '16px',
                  marginBottom: '12px'
                }}>
                  <div>
                    <div style={{ 
                      fontSize: '12px', 
                      color: '#6b7280', 
                      marginBottom: '4px',
                      fontWeight: '500'
                    }}>
                      Start Time
                    </div>
                    <div style={{ 
                      fontSize: '16px', 
                      fontWeight: '600', 
                      color: '#111827'
                    }}>
                      {template.startTime}
                    </div>
                  </div>
                  
                  <div>
                    <div style={{ 
                      fontSize: '12px', 
                      color: '#6b7280', 
                      marginBottom: '4px',
                      fontWeight: '500'
                    }}>
                      End Time
                    </div>
                    <div style={{ 
                      fontSize: '16px', 
                      fontWeight: '600', 
                      color: '#111827'
                    }}>
                      {template.endTime}
                    </div>
                  </div>
                </div>

                <div style={{ 
                  display: 'grid', 
                  gridTemplateColumns: '1fr 1fr', 
                  gap: '16px'
                }}>
                  <div>
                    <div style={{ 
                      fontSize: '12px', 
                      color: '#6b7280', 
                      marginBottom: '4px',
                      fontWeight: '500'
                    }}>
                      Duration
                    </div>
                    <div style={{ 
                      fontSize: '14px', 
                      color: '#111827'
                    }}>
                      {formatDuration(template.duration)}
                    </div>
                  </div>
                  
                  <div>
                    <div style={{ 
                      fontSize: '12px', 
                      color: '#6b7280', 
                      marginBottom: '4px',
                      fontWeight: '500'
                    }}>
                      Break Duration
                    </div>
                    <div style={{ 
                      fontSize: '14px', 
                      color: '#111827'
                    }}>
                      {formatDuration(template.breakDuration)}
                    </div>
                  </div>
                </div>
              </div>

              {/* Work Pattern */}
              <div style={{ 
                padding: '12px',
                backgroundColor: '#f9fafb',
                borderRadius: '6px',
                border: '1px solid #e5e7eb'
              }}>
                <div style={{ 
                  fontSize: '12px', 
                  color: '#6b7280', 
                  marginBottom: '4px',
                  fontWeight: '500'
                }}>
                  Work Pattern
                </div>
                <div style={{ 
                  fontSize: '14px', 
                  fontWeight: '600', 
                  color: '#111827'
                }}>
                  {template.workPattern} schedule
                </div>
              </div>

              {/* Color Preview */}
              <div style={{ 
                marginTop: '12px',
                display: 'flex',
                alignItems: 'center',
                gap: '8px'
              }}>
                <div style={{ 
                  fontSize: '12px', 
                  color: '#6b7280',
                  fontWeight: '500'
                }}>
                  Color:
                </div>
                <div style={{
                  width: '20px',
                  height: '20px',
                  backgroundColor: template.color,
                  borderRadius: '4px',
                  border: '1px solid #e5e7eb'
                }} />
                <span style={{ fontSize: '12px', color: '#6b7280' }}>
                  {template.color}
                </span>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Create/Edit Modal */}
      {isCreating && (
        <div style={{
          position: 'fixed',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          backgroundColor: 'rgba(0, 0, 0, 0.5)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 1000
        }}>
          <div style={{
            backgroundColor: 'white',
            borderRadius: '12px',
            padding: '24px',
            width: '500px',
            maxHeight: '80vh',
            overflow: 'auto'
          }}>
            <h2 style={{ 
              fontSize: '20px', 
              fontWeight: 'bold', 
              marginBottom: '20px',
              color: '#111827'
            }}>
              {editingTemplate ? 'Edit Shift Template' : 'Create Shift Template'}
            </h2>

            <form onSubmit={handleSubmit}>
              <div style={{ marginBottom: '16px' }}>
                <label style={{ 
                  display: 'block', 
                  fontSize: '14px', 
                  fontWeight: '500', 
                  marginBottom: '4px',
                  color: '#374151'
                }}>
                  Template Name
                </label>
                <input
                  type="text"
                  value={formData.name || ''}
                  onChange={(e) => setFormData(prev => ({ ...prev, name: e.target.value }))}
                  placeholder="Enter template name"
                  required
                  style={{
                    width: '100%',
                    padding: '10px 12px',
                    border: '1px solid #d1d5db',
                    borderRadius: '6px',
                    fontSize: '14px'
                  }}
                />
              </div>

              <div style={{ 
                display: 'grid', 
                gridTemplateColumns: '1fr 1fr', 
                gap: '16px',
                marginBottom: '16px'
              }}>
                <div>
                  <label style={{ 
                    display: 'block', 
                    fontSize: '14px', 
                    fontWeight: '500', 
                    marginBottom: '4px',
                    color: '#374151'
                  }}>
                    Start Time
                  </label>
                  <input
                    type="time"
                    value={formData.startTime || ''}
                    onChange={(e) => setFormData(prev => ({ ...prev, startTime: e.target.value }))}
                    required
                    style={{
                      width: '100%',
                      padding: '10px 12px',
                      border: '1px solid #d1d5db',
                      borderRadius: '6px',
                      fontSize: '14px'
                    }}
                  />
                </div>

                <div>
                  <label style={{ 
                    display: 'block', 
                    fontSize: '14px', 
                    fontWeight: '500', 
                    marginBottom: '4px',
                    color: '#374151'
                  }}>
                    End Time
                  </label>
                  <input
                    type="time"
                    value={formData.endTime || ''}
                    onChange={(e) => setFormData(prev => ({ ...prev, endTime: e.target.value }))}
                    required
                    style={{
                      width: '100%',
                      padding: '10px 12px',
                      border: '1px solid #d1d5db',
                      borderRadius: '6px',
                      fontSize: '14px'
                    }}
                  />
                </div>
              </div>

              <div style={{ marginBottom: '16px' }}>
                <label style={{ 
                  display: 'block', 
                  fontSize: '14px', 
                  fontWeight: '500', 
                  marginBottom: '4px',
                  color: '#374151'
                }}>
                  Break Duration (minutes)
                </label>
                <input
                  type="number"
                  min="0"
                  max="480"
                  step="15"
                  value={formData.breakDuration || ''}
                  onChange={(e) => setFormData(prev => ({ ...prev, breakDuration: parseInt(e.target.value) }))}
                  style={{
                    width: '100%',
                    padding: '10px 12px',
                    border: '1px solid #d1d5db',
                    borderRadius: '6px',
                    fontSize: '14px'
                  }}
                />
              </div>

              <div style={{ 
                display: 'grid', 
                gridTemplateColumns: '1fr 1fr', 
                gap: '16px',
                marginBottom: '16px'
              }}>
                <div>
                  <label style={{ 
                    display: 'block', 
                    fontSize: '14px', 
                    fontWeight: '500', 
                    marginBottom: '4px',
                    color: '#374151'
                  }}>
                    Shift Type
                  </label>
                  <select
                    value={formData.type || 'day'}
                    onChange={(e) => setFormData(prev => ({ 
                      ...prev, 
                      type: e.target.value as ShiftTemplate['type']
                    }))}
                    style={{
                      width: '100%',
                      padding: '10px 12px',
                      border: '1px solid #d1d5db',
                      borderRadius: '6px',
                      fontSize: '14px'
                    }}
                  >
                    <option value="day">☀️ Day Shift</option>
                    <option value="night">🌙 Night Shift</option>
                    <option value="overtime">⏰ Overtime</option>
                  </select>
                </div>

                <div>
                  <label style={{ 
                    display: 'block', 
                    fontSize: '14px', 
                    fontWeight: '500', 
                    marginBottom: '4px',
                    color: '#374151'
                  }}>
                    Work Pattern
                  </label>
                  <select
                    value={formData.workPattern || '5/2'}
                    onChange={(e) => setFormData(prev => ({ ...prev, workPattern: e.target.value }))}
                    style={{
                      width: '100%',
                      padding: '10px 12px',
                      border: '1px solid #d1d5db',
                      borderRadius: '6px',
                      fontSize: '14px'
                    }}
                  >
                    <option value="5/2">5/2 (5 days work, 2 days off)</option>
                    <option value="2/2">2/2 (2 days work, 2 days off)</option>
                    <option value="6/1">6/1 (6 days work, 1 day off)</option>
                    <option value="4/3">4/3 (4 days work, 3 days off)</option>
                  </select>
                </div>
              </div>

              <div style={{ marginBottom: '16px' }}>
                <label style={{ 
                  display: 'block', 
                  fontSize: '14px', 
                  fontWeight: '500', 
                  marginBottom: '4px',
                  color: '#374151'
                }}>
                  Color
                </label>
                <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
                  <input
                    type="color"
                    value={formData.color || '#74a689'}
                    onChange={(e) => setFormData(prev => ({ ...prev, color: e.target.value }))}
                    style={{
                      width: '50px',
                      height: '40px',
                      border: '1px solid #d1d5db',
                      borderRadius: '6px',
                      cursor: 'pointer'
                    }}
                  />
                  <input
                    type="text"
                    value={formData.color || '#74a689'}
                    onChange={(e) => setFormData(prev => ({ ...prev, color: e.target.value }))}
                    placeholder="#74a689"
                    style={{
                      flex: 1,
                      padding: '10px 12px',
                      border: '1px solid #d1d5db',
                      borderRadius: '6px',
                      fontSize: '14px'
                    }}
                  />
                </div>
              </div>

              <div style={{ marginBottom: '24px' }}>
                <label style={{ 
                  display: 'flex',
                  alignItems: 'center',
                  gap: '8px',
                  fontSize: '14px',
                  cursor: 'pointer'
                }}>
                  <input
                    type="checkbox"
                    checked={formData.isActive ?? true}
                    onChange={(e) => setFormData(prev => ({ ...prev, isActive: e.target.checked }))}
                    style={{ width: '16px', height: '16px' }}
                  />
                  Active Template
                </label>
              </div>

              <div style={{ display: 'flex', gap: '12px', justifyContent: 'flex-end' }}>
                <button
                  type="button"
                  onClick={handleCancel}
                  style={{
                    padding: '10px 20px',
                    backgroundColor: '#f3f4f6',
                    color: '#374151',
                    border: 'none',
                    borderRadius: '6px',
                    fontSize: '14px',
                    cursor: 'pointer'
                  }}
                >
                  Cancel
                </button>
                
                <button
                  type="submit"
                  style={{
                    padding: '10px 20px',
                    backgroundColor: '#059669',
                    color: 'white',
                    border: 'none',
                    borderRadius: '6px',
                    fontSize: '14px',
                    cursor: 'pointer'
                  }}
                >
                  {editingTemplate ? 'Update Template' : 'Create Template'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Statistics Footer */}
      <div style={{ 
        borderTop: '1px solid #e5e7eb', 
        paddingTop: '16px',
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        fontSize: '14px',
        color: '#6b7280'
      }}>
        <span>
          Total Templates: <strong>{templates.length}</strong>
        </span>
        <span>
          Active: <strong>{templates.filter(t => t.isActive).length}</strong>
        </span>
      </div>
    </div>
  );
};

export default ShiftTemplateManager;