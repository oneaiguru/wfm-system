import React, { useState } from 'react';
import { ScheduleException } from '../types/schedule';

const ExceptionManager: React.FC = () => {
  const [exceptions, setExceptions] = useState<ScheduleException[]>([
    {
      id: '1',
      date: '2024-01-01',
      type: 'holiday',
      description: 'New Year\'s Day',
      affectedEmployees: [],
      isActive: true,
    },
    {
      id: '2',
      date: '2024-03-08',
      type: 'holiday',
      description: 'International Women\'s Day',
      affectedEmployees: [],
      isActive: true,
    },
    {
      id: '3',
      date: '2024-07-20',
      type: 'special',
      description: 'System Maintenance',
      affectedEmployees: ['1', '2', '3'],
      isActive: false,
    },
    {
      id: '4',
      date: '2024-12-31',
      type: 'holiday',
      description: 'New Year\'s Eve',
      affectedEmployees: [],
      isActive: true,
    },
  ]);

  const [isCreating, setIsCreating] = useState(false);
  const [formData, setFormData] = useState({
    date: '',
    type: 'holiday' as ScheduleException['type'],
    description: '',
    affectedEmployees: [] as string[],
    isActive: true,
  });

  const employees = [
    { id: '1', name: 'Abdullaeva D.' },
    { id: '2', name: 'Azikova M.' },
    { id: '3', name: 'Akasheva D.' },
    { id: '4', name: 'Akasheva O.' },
    { id: '5', name: 'Akunova L.' },
  ];

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    
    const exception: ScheduleException = {
      id: Date.now().toString(),
      date: formData.date,
      type: formData.type,
      description: formData.description,
      affectedEmployees: formData.affectedEmployees,
      isActive: formData.isActive,
    };

    setExceptions(prev => [...prev, exception]);
    setFormData({
      date: '',
      type: 'holiday',
      description: '',
      affectedEmployees: [],
      isActive: true,
    });
    setIsCreating(false);
    console.log('✅ Created exception:', exception.description);
  };

  const toggleStatus = (id: string) => {
    setExceptions(prev => prev.map(exception => 
      exception.id === id ? { ...exception, isActive: !exception.isActive } : exception
    ));
  };

  const deleteException = (id: string) => {
    const exception = exceptions.find(e => e.id === id);
    setExceptions(prev => prev.filter(e => e.id !== id));
    console.log('🗑️ Deleted exception:', exception?.description);
  };

  const getTypeIcon = (type: ScheduleException['type']) => {
    switch (type) {
      case 'holiday': return '🎉';
      case 'special': return '⚠️';
      case 'maintenance': return '🔧';
      default: return '📅';
    }
  };

  const getTypeLabel = (type: ScheduleException['type']) => {
    switch (type) {
      case 'holiday': return 'Holiday';
      case 'special': return 'Special Day';
      case 'maintenance': return 'Maintenance';
      default: return 'Exception';
    }
  };

  const getTypeColor = (type: ScheduleException['type']) => {
    switch (type) {
      case 'holiday': return { bg: '#fef3c7', text: '#92400e' };
      case 'special': return { bg: '#fef2f2', text: '#dc2626' };
      case 'maintenance': return { bg: '#e0e7ff', text: '#3730a3' };
      default: return { bg: '#f3f4f6', text: '#374151' };
    }
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    });
  };

  const isUpcoming = (dateString: string) => {
    const date = new Date(dateString);
    const today = new Date();
    return date >= today;
  };

  const sortedExceptions = [...exceptions].sort((a, b) => 
    new Date(a.date).getTime() - new Date(b.date).getTime()
  );

  const upcomingExceptions = sortedExceptions.filter(e => isUpcoming(e.date) && e.isActive);
  const pastExceptions = sortedExceptions.filter(e => !isUpcoming(e.date));

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
            Exception Management
          </h1>
          <p style={{ 
            fontSize: '14px', 
            color: '#6b7280', 
            margin: '4px 0 0 0' 
          }}>
            Configure holidays, special days and schedule exceptions
          </p>
        </div>

        <button
          onClick={() => setIsCreating(true)}
          style={{
            padding: '12px 24px',
            backgroundColor: '#ea580c',
            color: 'white',
            border: 'none',
            borderRadius: '8px',
            fontSize: '14px',
            fontWeight: '500',
            cursor: 'pointer',
          }}
        >
          ➕ Add Exception
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
          backgroundColor: '#fef3c7',
          borderRadius: '8px',
          border: '1px solid #fde68a'
        }}>
          <div style={{ fontSize: '24px', fontWeight: 'bold', color: '#92400e' }}>
            {upcomingExceptions.length}
          </div>
          <div style={{ fontSize: '14px', color: '#92400e' }}>
            Upcoming Exceptions
          </div>
        </div>
        
        <div style={{
          padding: '16px',
          backgroundColor: '#dcfce7',
          borderRadius: '8px',
          border: '1px solid #bbf7d0'
        }}>
          <div style={{ fontSize: '24px', fontWeight: 'bold', color: '#166534' }}>
            {exceptions.filter(e => e.isActive).length}
          </div>
          <div style={{ fontSize: '14px', color: '#166534' }}>
            Active Exceptions
          </div>
        </div>
        
        <div style={{
          padding: '16px',
          backgroundColor: '#e0e7ff',
          borderRadius: '8px',
          border: '1px solid #c7d2fe'
        }}>
          <div style={{ fontSize: '24px', fontWeight: 'bold', color: '#3730a3' }}>
            {exceptions.filter(e => e.type === 'holiday').length}
          </div>
          <div style={{ fontSize: '14px', color: '#3730a3' }}>
            Holidays
          </div>
        </div>
      </div>

      {/* Exceptions List */}
      <div style={{ flex: 1, overflow: 'auto' }}>
        {/* Upcoming Exceptions */}
        {upcomingExceptions.length > 0 && (
          <div style={{ marginBottom: '32px' }}>
            <h3 style={{ 
              fontSize: '18px', 
              fontWeight: '600', 
              color: '#111827',
              marginBottom: '16px',
              display: 'flex',
              alignItems: 'center',
              gap: '8px'
            }}>
              📅 Upcoming Exceptions
            </h3>
            
            <div style={{ display: 'grid', gap: '12px' }}>
              {upcomingExceptions.map(exception => {
                const typeColor = getTypeColor(exception.type);
                
                return (
                  <div
                    key={exception.id}
                    style={{
                      border: '1px solid #e5e7eb',
                      borderRadius: '8px',
                      padding: '16px',
                      backgroundColor: 'white',
                      boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)',
                    }}
                  >
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start' }}>
                      <div style={{ flex: 1 }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '8px' }}>
                          <span style={{ fontSize: '20px' }}>{getTypeIcon(exception.type)}</span>
                          <h4 style={{ 
                            fontSize: '16px', 
                            fontWeight: '600', 
                            color: '#111827',
                            margin: 0
                          }}>
                            {exception.description}
                          </h4>
                          <span style={{
                            padding: '4px 8px',
                            borderRadius: '12px',
                            fontSize: '12px',
                            fontWeight: '500',
                            backgroundColor: typeColor.bg,
                            color: typeColor.text
                          }}>
                            {getTypeLabel(exception.type)}
                          </span>
                        </div>
                        
                        <div style={{ fontSize: '14px', color: '#6b7280', marginBottom: '8px' }}>
                          📅 {formatDate(exception.date)}
                        </div>
                        
                        {exception.affectedEmployees.length > 0 && (
                          <div style={{ fontSize: '12px', color: '#6b7280' }}>
                            👥 Affected Employees: {exception.affectedEmployees.length}
                          </div>
                        )}
                      </div>

                      <div style={{ display: 'flex', gap: '8px' }}>
                        <button
                          onClick={() => toggleStatus(exception.id)}
                          style={{
                            padding: '6px 12px',
                            backgroundColor: exception.isActive ? '#fef3c7' : '#dcfce7',
                            color: exception.isActive ? '#92400e' : '#166534',
                            border: 'none',
                            borderRadius: '6px',
                            fontSize: '12px',
                            cursor: 'pointer'
                          }}
                        >
                          {exception.isActive ? '⏸️' : '▶️'}
                        </button>
                        
                        <button
                          onClick={() => deleteException(exception.id)}
                          style={{
                            padding: '6px 12px',
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
                  </div>
                );
              })}
            </div>
          </div>
        )}

        {/* All Exceptions */}
        <div>
          <h3 style={{ 
            fontSize: '18px', 
            fontWeight: '600', 
            color: '#111827',
            marginBottom: '16px',
            display: 'flex',
            alignItems: 'center',
            gap: '8px'
          }}>
            📋 All Exceptions
          </h3>
          
          <div style={{ display: 'grid', gap: '12px' }}>
            {sortedExceptions.map(exception => {
              const typeColor = getTypeColor(exception.type);
              const isPast = !isUpcoming(exception.date);
              
              return (
                <div
                  key={exception.id}
                  style={{
                    border: '1px solid #e5e7eb',
                    borderRadius: '8px',
                    padding: '16px',
                    backgroundColor: isPast ? '#f9fafb' : 'white',
                    opacity: exception.isActive ? 1 : 0.6,
                    boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)',
                  }}
                >
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start' }}>
                    <div style={{ flex: 1 }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '8px' }}>
                        <span style={{ fontSize: '20px' }}>{getTypeIcon(exception.type)}</span>
                        <h4 style={{ 
                          fontSize: '16px', 
                          fontWeight: '600', 
                          color: isPast ? '#6b7280' : '#111827',
                          margin: 0
                        }}>
                          {exception.description}
                        </h4>
                        <span style={{
                          padding: '4px 8px',
                          borderRadius: '12px',
                          fontSize: '12px',
                          fontWeight: '500',
                          backgroundColor: typeColor.bg,
                          color: typeColor.text
                        }}>
                          {getTypeLabel(exception.type)}
                        </span>
                        {isPast && (
                          <span style={{
                            padding: '2px 6px',
                            borderRadius: '8px',
                            fontSize: '10px',
                            fontWeight: '500',
                            backgroundColor: '#f3f4f6',
                            color: '#6b7280'
                          }}>
                            PAST
                          </span>
                        )}
                        {!exception.isActive && (
                          <span style={{
                            padding: '2px 6px',
                            borderRadius: '8px',
                            fontSize: '10px',
                            fontWeight: '500',
                            backgroundColor: '#fef2f2',
                            color: '#dc2626'
                          }}>
                            INACTIVE
                          </span>
                        )}
                      </div>
                      
                      <div style={{ fontSize: '14px', color: '#6b7280', marginBottom: '8px' }}>
                        📅 {formatDate(exception.date)}
                      </div>
                      
                      {exception.affectedEmployees.length > 0 && (
                        <div style={{ fontSize: '12px', color: '#6b7280' }}>
                          👥 Affected Employees: {exception.affectedEmployees.map(id => 
                            employees.find(emp => emp.id === id)?.name
                          ).filter(Boolean).join(', ')}
                        </div>
                      )}
                    </div>

                    <div style={{ display: 'flex', gap: '8px' }}>
                      <button
                        onClick={() => toggleStatus(exception.id)}
                        style={{
                          padding: '6px 12px',
                          backgroundColor: exception.isActive ? '#fef3c7' : '#dcfce7',
                          color: exception.isActive ? '#92400e' : '#166534',
                          border: 'none',
                          borderRadius: '6px',
                          fontSize: '12px',
                          cursor: 'pointer'
                        }}
                      >
                        {exception.isActive ? '⏸️' : '▶️'}
                      </button>
                      
                      <button
                        onClick={() => deleteException(exception.id)}
                        style={{
                          padding: '6px 12px',
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
                </div>
              );
            })}
          </div>
        </div>
      </div>

      {/* Create Exception Modal */}
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
              Add Exception
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
                  Date
                </label>
                <input
                  type="date"
                  value={formData.date}
                  onChange={(e) => setFormData(prev => ({ ...prev, date: e.target.value }))}
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

              <div style={{ marginBottom: '16px' }}>
                <label style={{ 
                  display: 'block', 
                  fontSize: '14px', 
                  fontWeight: '500', 
                  marginBottom: '4px',
                  color: '#374151'
                }}>
                  Exception Type
                </label>
                <select
                  value={formData.type}
                  onChange={(e) => setFormData(prev => ({ 
                    ...prev, 
                    type: e.target.value as ScheduleException['type']
                  }))}
                  style={{
                    width: '100%',
                    padding: '10px 12px',
                    border: '1px solid #d1d5db',
                    borderRadius: '6px',
                    fontSize: '14px'
                  }}
                >
                  <option value="holiday">🎉 Holiday</option>
                  <option value="special">⚠️ Special Day</option>
                  <option value="maintenance">🔧 Maintenance</option>
                </select>
              </div>

              <div style={{ marginBottom: '16px' }}>
                <label style={{ 
                  display: 'block', 
                  fontSize: '14px', 
                  fontWeight: '500', 
                  marginBottom: '4px',
                  color: '#374151'
                }}>
                  Description
                </label>
                <input
                  type="text"
                  value={formData.description}
                  onChange={(e) => setFormData(prev => ({ ...prev, description: e.target.value }))}
                  placeholder="Describe the exception"
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

              <div style={{ marginBottom: '16px' }}>
                <label style={{ 
                  display: 'block', 
                  fontSize: '14px', 
                  fontWeight: '500', 
                  marginBottom: '8px',
                  color: '#374151'
                }}>
                  Affected Employees (optional)
                </label>
                <div style={{ 
                  border: '1px solid #d1d5db',
                  borderRadius: '6px',
                  padding: '8px',
                  maxHeight: '120px',
                  overflow: 'auto'
                }}>
                  {employees.map(employee => (
                    <label 
                      key={employee.id}
                      style={{ 
                        display: 'flex',
                        alignItems: 'center',
                        gap: '8px',
                        padding: '4px',
                        fontSize: '14px',
                        cursor: 'pointer'
                      }}
                    >
                      <input
                        type="checkbox"
                        checked={formData.affectedEmployees.includes(employee.id)}
                        onChange={(e) => {
                          const employeeId = employee.id;
                          setFormData(prev => ({
                            ...prev,
                            affectedEmployees: e.target.checked
                              ? [...prev.affectedEmployees, employeeId]
                              : prev.affectedEmployees.filter(id => id !== employeeId)
                          }));
                        }}
                        style={{ width: '16px', height: '16px' }}
                      />
                      {employee.name}
                    </label>
                  ))}
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
                    checked={formData.isActive}
                    onChange={(e) => setFormData(prev => ({ ...prev, isActive: e.target.checked }))}
                    style={{ width: '16px', height: '16px' }}
                  />
                  Activate Exception
                </label>
              </div>

              <div style={{ display: 'flex', gap: '12px', justifyContent: 'flex-end' }}>
                <button
                  type="button"
                  onClick={() => setIsCreating(false)}
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
                    backgroundColor: '#ea580c',
                    color: 'white',
                    border: 'none',
                    borderRadius: '6px',
                    fontSize: '14px',
                    cursor: 'pointer'
                  }}
                >
                  Add Exception
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
          Total Exceptions: <strong>{exceptions.length}</strong>
        </span>
        <span>
          Upcoming: <strong>{upcomingExceptions.length}</strong>
        </span>
      </div>
    </div>
  );
};

export default ExceptionManager;