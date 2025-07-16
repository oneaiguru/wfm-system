import React, { useState, useEffect, useRef } from 'react';
import './MobileProfile.css';

interface EmployeeProfile {
  id: string;
  employee_id: string;
  first_name: string;
  last_name: string;
  middle_name?: string;
  email: string;
  phone: string;
  position: string;
  department: string;
  hire_date: string;
  avatar_url?: string;
  skills: string[];
  certifications: string[];
  languages: string[];
  emergency_contact: {
    name: string;
    phone: string;
    relationship: string;
  };
}

interface UserPreferences {
  theme: 'light' | 'dark' | 'auto';
  language: 'ru' | 'en';
  notifications_enabled: boolean;
  push_notifications: boolean;
  email_notifications: boolean;
  sms_notifications: boolean;
  calendar_sync: boolean;
  biometric_login: boolean;
  auto_clock_in: boolean;
  shift_reminders: boolean;
  overtime_alerts: boolean;
  timezone: string;
  working_hours_start: string;
  working_hours_end: string;
}

interface WorkStats {
  current_month_hours: number;
  overtime_hours: number;
  vacation_days_left: number;
  sick_days_used: number;
  attendance_rate: number;
  shifts_completed: number;
  shifts_upcoming: number;
}

interface MobileProfileProps {
  employeeId: string;
  onProfileUpdate?: (profile: EmployeeProfile) => void;
  onPreferencesUpdate?: (preferences: UserPreferences) => void;
}

const MobileProfile: React.FC<MobileProfileProps> = ({
  employeeId,
  onProfileUpdate,
  onPreferencesUpdate
}) => {
  const [profile, setProfile] = useState<EmployeeProfile | null>(null);
  const [preferences, setPreferences] = useState<UserPreferences | null>(null);
  const [workStats, setWorkStats] = useState<WorkStats | null>(null);
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [activeTab, setActiveTab] = useState<'profile' | 'preferences' | 'stats'>('profile');
  const [editMode, setEditMode] = useState(false);
  const [photoUpload, setPhotoUpload] = useState<File | null>(null);
  const [errors, setErrors] = useState<Record<string, string>>({});
  
  const fileInputRef = useRef<HTMLInputElement>(null);
  const formRef = useRef<HTMLFormElement>(null);

  useEffect(() => {
    loadProfileData();
  }, [employeeId]);

  const loadProfileData = async () => {
    setLoading(true);
    try {
      const [profileResponse, preferencesResponse, statsResponse] = await Promise.all([
        fetch(`/api/v1/mobile/profile/${employeeId}`, {
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('mobile_auth_token')}`,
            'Content-Type': 'application/json'
          }
        }),
        fetch(`/api/v1/mobile/profile/${employeeId}/preferences`, {
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('mobile_auth_token')}`,
            'Content-Type': 'application/json'
          }
        }),
        fetch(`/api/v1/mobile/profile/${employeeId}/stats`, {
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('mobile_auth_token')}`,
            'Content-Type': 'application/json'
          }
        })
      ]);

      if (profileResponse.ok) {
        const profileData = await profileResponse.json();
        setProfile(profileData);
      }

      if (preferencesResponse.ok) {
        const preferencesData = await preferencesResponse.json();
        setPreferences(preferencesData);
      }

      if (statsResponse.ok) {
        const statsData = await statsResponse.json();
        setWorkStats(statsData);
      }
    } catch (error) {
      console.error('Ошибка загрузки профиля:', error);
    } finally {
      setLoading(false);
    }
  };

  const validateProfile = (): boolean => {
    if (!profile) return false;
    
    const newErrors: Record<string, string> = {};
    
    if (!profile.first_name.trim()) {
      newErrors.first_name = 'Имя обязательно';
    }
    
    if (!profile.last_name.trim()) {
      newErrors.last_name = 'Фамилия обязательна';
    }
    
    if (!profile.email.trim()) {
      newErrors.email = 'Email обязателен';
    } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(profile.email)) {
      newErrors.email = 'Неверный формат email';
    }
    
    if (!profile.phone.trim()) {
      newErrors.phone = 'Телефон обязателен';
    } else if (!/^\+?[\d\s\-\(\)]+$/.test(profile.phone)) {
      newErrors.phone = 'Неверный формат телефона';
    }
    
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const saveProfile = async () => {
    if (!validateProfile() || !profile) return;
    
    setSaving(true);
    try {
      const formData = new FormData();
      
      // Add profile data
      formData.append('profile', JSON.stringify(profile));
      
      // Add photo if uploaded
      if (photoUpload) {
        formData.append('avatar', photoUpload);
      }
      
      const response = await fetch(`/api/v1/mobile/profile/${employeeId}`, {
        method: 'PUT',
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('mobile_auth_token')}`
        },
        body: formData
      });
      
      if (response.ok) {
        const updatedProfile = await response.json();
        setProfile(updatedProfile);
        setEditMode(false);
        setPhotoUpload(null);
        
        if (onProfileUpdate) {
          onProfileUpdate(updatedProfile);
        }
        
        alert('Профиль успешно обновлен');
      } else {
        const error = await response.json();
        throw new Error(error.message || 'Ошибка сохранения профиля');
      }
    } catch (error) {
      console.error('Ошибка сохранения профиля:', error);
      alert('Ошибка сохранения профиля');
    } finally {
      setSaving(false);
    }
  };

  const savePreferences = async (newPreferences: UserPreferences) => {
    try {
      const response = await fetch(`/api/v1/mobile/profile/${employeeId}/preferences`, {
        method: 'PUT',
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('mobile_auth_token')}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(newPreferences)
      });
      
      if (response.ok) {
        setPreferences(newPreferences);
        
        if (onPreferencesUpdate) {
          onPreferencesUpdate(newPreferences);
        }
        
        // Apply theme immediately
        if (newPreferences.theme !== 'auto') {
          document.documentElement.setAttribute('data-theme', newPreferences.theme);
        }
      }
    } catch (error) {
      console.error('Ошибка сохранения настроек:', error);
    }
  };

  const handlePhotoSelect = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      if (file.size > 5 * 1024 * 1024) { // 5MB limit
        alert('Файл слишком большой. Максимальный размер: 5MB');
        return;
      }
      
      if (!file.type.startsWith('image/')) {
        alert('Пожалуйста, выберите изображение');
        return;
      }
      
      setPhotoUpload(file);
    }
  };

  const removePhoto = () => {
    setPhotoUpload(null);
    if (fileInputRef.current) {
      fileInputRef.current.value = '';
    }
  };

  const getPhotoUrl = (): string => {
    if (photoUpload) {
      return URL.createObjectURL(photoUpload);
    }
    return profile?.avatar_url || '/default-avatar.png';
  };

  const formatDate = (dateString: string): string => {
    return new Date(dateString).toLocaleDateString('ru-RU', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric'
    });
  };

  const calculateWorkingYears = (hireDate: string): number => {
    const hire = new Date(hireDate);
    const now = new Date();
    return Math.floor((now.getTime() - hire.getTime()) / (365.25 * 24 * 60 * 60 * 1000));
  };

  const renderProfileTab = () => (
    <div className="mobile-profile__content">
      <div className="mobile-profile__header">
        <div className="mobile-profile__photo-container">
          <img
            src={getPhotoUrl()}
            alt="Фото профиля"
            className="mobile-profile__photo"
            onError={(e) => {
              (e.target as HTMLImageElement).src = '/default-avatar.png';
            }}
          />
          
          {editMode && (
            <div className="mobile-profile__photo-edit">
              <button
                className="mobile-profile__photo-button"
                onClick={() => fileInputRef.current?.click()}
              >
                📷
              </button>
              {(photoUpload || profile?.avatar_url) && (
                <button
                  className="mobile-profile__photo-button mobile-profile__photo-remove"
                  onClick={removePhoto}
                >
                  🗑️
                </button>
              )}
            </div>
          )}
          
          <input
            ref={fileInputRef}
            type="file"
            accept="image/*"
            onChange={handlePhotoSelect}
            style={{ display: 'none' }}
          />
        </div>
        
        <div className="mobile-profile__basic-info">
          <h2>
            {profile?.last_name} {profile?.first_name} {profile?.middle_name}
          </h2>
          <p>{profile?.position}</p>
          <p>{profile?.department}</p>
        </div>
        
        <div className="mobile-profile__actions">
          {!editMode ? (
            <button
              className="mobile-profile__edit-button"
              onClick={() => setEditMode(true)}
            >
              ✏️ Редактировать
            </button>
          ) : (
            <div className="mobile-profile__edit-actions">
              <button
                className="mobile-profile__save-button"
                onClick={saveProfile}
                disabled={saving}
              >
                {saving ? 'Сохранение...' : '💾 Сохранить'}
              </button>
              <button
                className="mobile-profile__cancel-button"
                onClick={() => {
                  setEditMode(false);
                  setPhotoUpload(null);
                  setErrors({});
                }}
              >
                ❌ Отмена
              </button>
            </div>
          )}
        </div>
      </div>
      
      <form ref={formRef} className="mobile-profile__form">
        <div className="mobile-profile__section">
          <h3>Личная информация</h3>
          
          <div className="mobile-profile__field">
            <label>Фамилия *</label>
            <input
              type="text"
              value={profile?.last_name || ''}
              onChange={(e) => setProfile(prev => prev ? { ...prev, last_name: e.target.value } : null)}
              disabled={!editMode}
              className={errors.last_name ? 'error' : ''}
            />
            {errors.last_name && <span className="mobile-profile__error">{errors.last_name}</span>}
          </div>
          
          <div className="mobile-profile__field">
            <label>Имя *</label>
            <input
              type="text"
              value={profile?.first_name || ''}
              onChange={(e) => setProfile(prev => prev ? { ...prev, first_name: e.target.value } : null)}
              disabled={!editMode}
              className={errors.first_name ? 'error' : ''}
            />
            {errors.first_name && <span className="mobile-profile__error">{errors.first_name}</span>}
          </div>
          
          <div className="mobile-profile__field">
            <label>Отчество</label>
            <input
              type="text"
              value={profile?.middle_name || ''}
              onChange={(e) => setProfile(prev => prev ? { ...prev, middle_name: e.target.value } : null)}
              disabled={!editMode}
            />
          </div>
          
          <div className="mobile-profile__field">
            <label>Email *</label>
            <input
              type="email"
              value={profile?.email || ''}
              onChange={(e) => setProfile(prev => prev ? { ...prev, email: e.target.value } : null)}
              disabled={!editMode}
              className={errors.email ? 'error' : ''}
            />
            {errors.email && <span className="mobile-profile__error">{errors.email}</span>}
          </div>
          
          <div className="mobile-profile__field">
            <label>Телефон *</label>
            <input
              type="tel"
              value={profile?.phone || ''}
              onChange={(e) => setProfile(prev => prev ? { ...prev, phone: e.target.value } : null)}
              disabled={!editMode}
              className={errors.phone ? 'error' : ''}
            />
            {errors.phone && <span className="mobile-profile__error">{errors.phone}</span>}
          </div>
        </div>
        
        <div className="mobile-profile__section">
          <h3>Рабочая информация</h3>
          
          <div className="mobile-profile__field">
            <label>Должность</label>
            <input
              type="text"
              value={profile?.position || ''}
              disabled
            />
          </div>
          
          <div className="mobile-profile__field">
            <label>Отдел</label>
            <input
              type="text"
              value={profile?.department || ''}
              disabled
            />
          </div>
          
          <div className="mobile-profile__field">
            <label>Дата трудоустройства</label>
            <input
              type="text"
              value={profile?.hire_date ? formatDate(profile.hire_date) : ''}
              disabled
            />
          </div>
          
          <div className="mobile-profile__field">
            <label>Стаж работы</label>
            <input
              type="text"
              value={profile?.hire_date ? `${calculateWorkingYears(profile.hire_date)} лет` : ''}
              disabled
            />
          </div>
        </div>
        
        <div className="mobile-profile__section">
          <h3>Навыки и сертификаты</h3>
          
          <div className="mobile-profile__field">
            <label>Навыки</label>
            <div className="mobile-profile__tags">
              {profile?.skills.map((skill, index) => (
                <span key={index} className="mobile-profile__tag">{skill}</span>
              ))}
            </div>
          </div>
          
          <div className="mobile-profile__field">
            <label>Сертификаты</label>
            <div className="mobile-profile__tags">
              {profile?.certifications.map((cert, index) => (
                <span key={index} className="mobile-profile__tag mobile-profile__tag--cert">{cert}</span>
              ))}
            </div>
          </div>
          
          <div className="mobile-profile__field">
            <label>Языки</label>
            <div className="mobile-profile__tags">
              {profile?.languages.map((lang, index) => (
                <span key={index} className="mobile-profile__tag mobile-profile__tag--lang">{lang}</span>
              ))}
            </div>
          </div>
        </div>
        
        <div className="mobile-profile__section">
          <h3>Экстренный контакт</h3>
          
          <div className="mobile-profile__field">
            <label>Имя</label>
            <input
              type="text"
              value={profile?.emergency_contact.name || ''}
              onChange={(e) => setProfile(prev => prev ? {
                ...prev,
                emergency_contact: { ...prev.emergency_contact, name: e.target.value }
              } : null)}
              disabled={!editMode}
            />
          </div>
          
          <div className="mobile-profile__field">
            <label>Телефон</label>
            <input
              type="tel"
              value={profile?.emergency_contact.phone || ''}
              onChange={(e) => setProfile(prev => prev ? {
                ...prev,
                emergency_contact: { ...prev.emergency_contact, phone: e.target.value }
              } : null)}
              disabled={!editMode}
            />
          </div>
          
          <div className="mobile-profile__field">
            <label>Степень родства</label>
            <input
              type="text"
              value={profile?.emergency_contact.relationship || ''}
              onChange={(e) => setProfile(prev => prev ? {
                ...prev,
                emergency_contact: { ...prev.emergency_contact, relationship: e.target.value }
              } : null)}
              disabled={!editMode}
            />
          </div>
        </div>
      </form>
    </div>
  );

  const renderPreferencesTab = () => (
    <div className="mobile-profile__content">
      <div className="mobile-profile__section">
        <h3>Внешний вид</h3>
        
        <div className="mobile-profile__field">
          <label>Тема</label>
          <select
            value={preferences?.theme || 'auto'}
            onChange={(e) => {
              const newPrefs = { ...preferences!, theme: e.target.value as 'light' | 'dark' | 'auto' };
              savePreferences(newPrefs);
            }}
          >
            <option value="auto">Автоматически</option>
            <option value="light">Светлая</option>
            <option value="dark">Темная</option>
          </select>
        </div>
        
        <div className="mobile-profile__field">
          <label>Язык</label>
          <select
            value={preferences?.language || 'ru'}
            onChange={(e) => {
              const newPrefs = { ...preferences!, language: e.target.value as 'ru' | 'en' };
              savePreferences(newPrefs);
            }}
          >
            <option value="ru">Русский</option>
            <option value="en">English</option>
          </select>
        </div>
      </div>
      
      <div className="mobile-profile__section">
        <h3>Уведомления</h3>
        
        <div className="mobile-profile__toggle">
          <label>
            <input
              type="checkbox"
              checked={preferences?.notifications_enabled || false}
              onChange={(e) => {
                const newPrefs = { ...preferences!, notifications_enabled: e.target.checked };
                savePreferences(newPrefs);
              }}
            />
            <span>Включить уведомления</span>
          </label>
        </div>
        
        <div className="mobile-profile__toggle">
          <label>
            <input
              type="checkbox"
              checked={preferences?.push_notifications || false}
              onChange={(e) => {
                const newPrefs = { ...preferences!, push_notifications: e.target.checked };
                savePreferences(newPrefs);
              }}
            />
            <span>Push-уведомления</span>
          </label>
        </div>
        
        <div className="mobile-profile__toggle">
          <label>
            <input
              type="checkbox"
              checked={preferences?.email_notifications || false}
              onChange={(e) => {
                const newPrefs = { ...preferences!, email_notifications: e.target.checked };
                savePreferences(newPrefs);
              }}
            />
            <span>Email уведомления</span>
          </label>
        </div>
        
        <div className="mobile-profile__toggle">
          <label>
            <input
              type="checkbox"
              checked={preferences?.sms_notifications || false}
              onChange={(e) => {
                const newPrefs = { ...preferences!, sms_notifications: e.target.checked };
                savePreferences(newPrefs);
              }}
            />
            <span>SMS уведомления</span>
          </label>
        </div>
      </div>
      
      <div className="mobile-profile__section">
        <h3>Рабочие настройки</h3>
        
        <div className="mobile-profile__toggle">
          <label>
            <input
              type="checkbox"
              checked={preferences?.calendar_sync || false}
              onChange={(e) => {
                const newPrefs = { ...preferences!, calendar_sync: e.target.checked };
                savePreferences(newPrefs);
              }}
            />
            <span>Синхронизация с календарем</span>
          </label>
        </div>
        
        <div className="mobile-profile__toggle">
          <label>
            <input
              type="checkbox"
              checked={preferences?.biometric_login || false}
              onChange={(e) => {
                const newPrefs = { ...preferences!, biometric_login: e.target.checked };
                savePreferences(newPrefs);
              }}
            />
            <span>Биометрический вход</span>
          </label>
        </div>
        
        <div className="mobile-profile__toggle">
          <label>
            <input
              type="checkbox"
              checked={preferences?.auto_clock_in || false}
              onChange={(e) => {
                const newPrefs = { ...preferences!, auto_clock_in: e.target.checked };
                savePreferences(newPrefs);
              }}
            />
            <span>Автоматическая отметка начала смены</span>
          </label>
        </div>
        
        <div className="mobile-profile__toggle">
          <label>
            <input
              type="checkbox"
              checked={preferences?.shift_reminders || false}
              onChange={(e) => {
                const newPrefs = { ...preferences!, shift_reminders: e.target.checked };
                savePreferences(newPrefs);
              }}
            />
            <span>Напоминания о сменах</span>
          </label>
        </div>
        
        <div className="mobile-profile__toggle">
          <label>
            <input
              type="checkbox"
              checked={preferences?.overtime_alerts || false}
              onChange={(e) => {
                const newPrefs = { ...preferences!, overtime_alerts: e.target.checked };
                savePreferences(newPrefs);
              }}
            />
            <span>Предупреждения о сверхурочных</span>
          </label>
        </div>
      </div>
    </div>
  );

  const renderStatsTab = () => (
    <div className="mobile-profile__content">
      <div className="mobile-profile__stats-grid">
        <div className="mobile-profile__stat-card">
          <div className="mobile-profile__stat-icon">📊</div>
          <div className="mobile-profile__stat-content">
            <div className="mobile-profile__stat-value">
              {workStats?.current_month_hours || 0}ч
            </div>
            <div className="mobile-profile__stat-label">Часы в этом месяце</div>
          </div>
        </div>
        
        <div className="mobile-profile__stat-card">
          <div className="mobile-profile__stat-icon">⏰</div>
          <div className="mobile-profile__stat-content">
            <div className="mobile-profile__stat-value">
              {workStats?.overtime_hours || 0}ч
            </div>
            <div className="mobile-profile__stat-label">Сверхурочные</div>
          </div>
        </div>
        
        <div className="mobile-profile__stat-card">
          <div className="mobile-profile__stat-icon">🏖️</div>
          <div className="mobile-profile__stat-content">
            <div className="mobile-profile__stat-value">
              {workStats?.vacation_days_left || 0}
            </div>
            <div className="mobile-profile__stat-label">Дней отпуска осталось</div>
          </div>
        </div>
        
        <div className="mobile-profile__stat-card">
          <div className="mobile-profile__stat-icon">🤒</div>
          <div className="mobile-profile__stat-content">
            <div className="mobile-profile__stat-value">
              {workStats?.sick_days_used || 0}
            </div>
            <div className="mobile-profile__stat-label">Больничных использовано</div>
          </div>
        </div>
        
        <div className="mobile-profile__stat-card">
          <div className="mobile-profile__stat-icon">📈</div>
          <div className="mobile-profile__stat-content">
            <div className="mobile-profile__stat-value">
              {workStats?.attendance_rate || 0}%
            </div>
            <div className="mobile-profile__stat-label">Посещаемость</div>
          </div>
        </div>
        
        <div className="mobile-profile__stat-card">
          <div className="mobile-profile__stat-icon">✅</div>
          <div className="mobile-profile__stat-content">
            <div className="mobile-profile__stat-value">
              {workStats?.shifts_completed || 0}
            </div>
            <div className="mobile-profile__stat-label">Смен выполнено</div>
          </div>
        </div>
      </div>
    </div>
  );

  if (loading) {
    return (
      <div className="mobile-profile__loading">
        <div className="mobile-profile__spinner"></div>
        <p>Загрузка профиля...</p>
      </div>
    );
  }

  if (!profile) {
    return (
      <div className="mobile-profile__error">
        <h3>Ошибка загрузки профиля</h3>
        <button onClick={loadProfileData}>Попробовать снова</button>
      </div>
    );
  }

  return (
    <div className="mobile-profile">
      <div className="mobile-profile__tabs">
        <button
          className={`mobile-profile__tab ${activeTab === 'profile' ? 'active' : ''}`}
          onClick={() => setActiveTab('profile')}
        >
          👤 Профиль
        </button>
        <button
          className={`mobile-profile__tab ${activeTab === 'preferences' ? 'active' : ''}`}
          onClick={() => setActiveTab('preferences')}
        >
          ⚙️ Настройки
        </button>
        <button
          className={`mobile-profile__tab ${activeTab === 'stats' ? 'active' : ''}`}
          onClick={() => setActiveTab('stats')}
        >
          📊 Статистика
        </button>
      </div>

      {activeTab === 'profile' && renderProfileTab()}
      {activeTab === 'preferences' && renderPreferencesTab()}
      {activeTab === 'stats' && renderStatsTab()}
    </div>
  );
};

export default MobileProfile;