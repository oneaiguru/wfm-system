import React, { useState, useEffect, useRef } from 'react';
import './MobileProfile.css';
import LoadingSpinner from '../LoadingSpinner';
import { Input } from '../common/Input';
import { Button, PrimaryButton, SecondaryButton } from '../common/Button';
import ErrorBoundary from '../ErrorBoundary';
import { useToastHelpers } from '../common/Toast';

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
  const { success, error, warning } = useToastHelpers();

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
      error('Не удалось загрузить данные профиля', {
        title: 'Ошибка загрузки',
        duration: 5000
      });
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
        
        success('Профиль успешно обновлен', {
          title: 'Сохранено',
          duration: 3000
        });
      } else {
        const error = await response.json();
        throw new Error(error.message || 'Ошибка сохранения профиля');
      }
    } catch (error) {
      console.error('Ошибка сохранения профиля:', error);
      error('Не удалось сохранить изменения профиля', {
        title: 'Ошибка сохранения',
        duration: 5000
      });
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
      error('Не удалось сохранить настройки', {
        title: 'Ошибка',
        duration: 5000
      });
    }
  };

  const handlePhotoSelect = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      if (file.size > 5 * 1024 * 1024) { // 5MB limit
        warning('Файл слишком большой. Максимальный размер: 5MB', {
          title: 'Размер файла',
          duration: 4000
        });
        return;
      }
      
      if (!file.type.startsWith('image/')) {
        warning('Пожалуйста, выберите изображение', {
          title: 'Неверный тип файла',
          duration: 4000
        });
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
            <SecondaryButton
              onClick={() => setEditMode(true)}
              leftIcon={
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                </svg>
              }
            >
              Редактировать
            </SecondaryButton>
          ) : (
            <div className="mobile-profile__edit-actions">
              <PrimaryButton
                onClick={saveProfile}
                loading={saving}
                loadingText="Сохранение..."
                leftIcon={
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-3m-1 4l-3-3m0 0l-3 3m3-3v12" />
                  </svg>
                }
              >
                Сохранить
              </PrimaryButton>
              <Button
                variant="ghost"
                onClick={() => {
                  setEditMode(false);
                  setPhotoUpload(null);
                  setErrors({});
                }}
                leftIcon={
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                }
              >
                Отмена
              </Button>
            </div>
          )}
        </div>
      </div>
      
      <form ref={formRef} className="mobile-profile__form">
        <div className="mobile-profile__section">
          <h3>Личная информация</h3>
          
          <div className="mobile-profile__field">
            <Input
              label="Фамилия"
              type="text"
              value={profile?.last_name || ''}
              onChange={(e) => setProfile(prev => prev ? { ...prev, last_name: e.target.value } : null)}
              disabled={!editMode}
              error={errors.last_name}
              required
              size="md"
            />
          </div>
          
          <div className="mobile-profile__field">
            <Input
              label="Имя"
              type="text"
              value={profile?.first_name || ''}
              onChange={(e) => setProfile(prev => prev ? { ...prev, first_name: e.target.value } : null)}
              disabled={!editMode}
              error={errors.first_name}
              required
              size="md"
            />
          </div>
          
          <div className="mobile-profile__field">
            <Input
              label="Отчество"
              type="text"
              value={profile?.middle_name || ''}
              onChange={(e) => setProfile(prev => prev ? { ...prev, middle_name: e.target.value } : null)}
              disabled={!editMode}
              size="md"
            />
          </div>
          
          <div className="mobile-profile__field">
            <Input
              label="Email"
              type="email"
              value={profile?.email || ''}
              onChange={(e) => setProfile(prev => prev ? { ...prev, email: e.target.value } : null)}
              disabled={!editMode}
              error={errors.email}
              required
              size="md"
            />
          </div>
          
          <div className="mobile-profile__field">
            <Input
              label="Телефон"
              type="tel"
              value={profile?.phone || ''}
              onChange={(e) => setProfile(prev => prev ? { ...prev, phone: e.target.value } : null)}
              disabled={!editMode}
              error={errors.phone}
              required
              size="md"
            />
          </div>
        </div>
        
        <div className="mobile-profile__section">
          <h3>Рабочая информация</h3>
          
          <div className="mobile-profile__field">
            <Input
              label="Должность"
              type="text"
              value={profile?.position || ''}
              disabled
              size="md"
            />
          </div>
          
          <div className="mobile-profile__field">
            <Input
              label="Отдел"
              type="text"
              value={profile?.department || ''}
              disabled
              size="md"
            />
          </div>
          
          <div className="mobile-profile__field">
            <Input
              label="Дата трудоустройства"
              type="text"
              value={profile?.hire_date ? formatDate(profile.hire_date) : ''}
              disabled
              size="md"
            />
          </div>
          
          <div className="mobile-profile__field">
            <Input
              label="Стаж работы"
              type="text"
              value={profile?.hire_date ? `${calculateWorkingYears(profile.hire_date)} лет` : ''}
              disabled
              size="md"
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
            <Input
              label="Имя"
              type="text"
              value={profile?.emergency_contact.name || ''}
              onChange={(e) => setProfile(prev => prev ? {
                ...prev,
                emergency_contact: { ...prev.emergency_contact, name: e.target.value }
              } : null)}
              disabled={!editMode}
              size="md"
            />
          </div>
          
          <div className="mobile-profile__field">
            <Input
              label="Телефон"
              type="tel"
              value={profile?.emergency_contact.phone || ''}
              onChange={(e) => setProfile(prev => prev ? {
                ...prev,
                emergency_contact: { ...prev.emergency_contact, phone: e.target.value }
              } : null)}
              disabled={!editMode}
              size="md"
            />
          </div>
          
          <div className="mobile-profile__field">
            <Input
              label="Степень родства"
              type="text"
              value={profile?.emergency_contact.relationship || ''}
              onChange={(e) => setProfile(prev => prev ? {
                ...prev,
                emergency_contact: { ...prev.emergency_contact, relationship: e.target.value }
              } : null)}
              disabled={!editMode}
              size="md"
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
        <LoadingSpinner 
          message="Загрузка профиля..."
          size="lg"
          variant="spinner"
        />
      </div>
    );
  }

  if (!profile) {
    return (
      <ErrorBoundary level="section">
        <div className="mobile-profile__error">
          <h3>Ошибка загрузки профиля</h3>
          <PrimaryButton onClick={loadProfileData}>
            Попробовать снова
          </PrimaryButton>
        </div>
      </ErrorBoundary>
    );
  }

  return (
    <ErrorBoundary level="section">
      <div className="mobile-profile">
        <div className="mobile-profile__tabs">
          <button
            className={`mobile-profile__tab ${activeTab === 'profile' ? 'active' : ''}`}
            onClick={() => setActiveTab('profile')}
            aria-selected={activeTab === 'profile'}
            role="tab"
          >
            <svg className="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
            </svg>
            Профиль
          </button>
          <button
            className={`mobile-profile__tab ${activeTab === 'preferences' ? 'active' : ''}`}
            onClick={() => setActiveTab('preferences')}
            aria-selected={activeTab === 'preferences'}
            role="tab"
          >
            <svg className="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
            </svg>
            Настройки
          </button>
          <button
            className={`mobile-profile__tab ${activeTab === 'stats' ? 'active' : ''}`}
            onClick={() => setActiveTab('stats')}
            aria-selected={activeTab === 'stats'}
            role="tab"
          >
            <svg className="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
            </svg>
            Статистика
          </button>
        </div>

        <div role="tabpanel">
          {activeTab === 'profile' && renderProfileTab()}
          {activeTab === 'preferences' && renderPreferencesTab()}
          {activeTab === 'stats' && renderStatsTab()}
        </div>
      </div>
    </ErrorBoundary>
  );
};

export default MobileProfile;