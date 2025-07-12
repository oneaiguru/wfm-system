import React, { useState } from 'react';
import { User, Settings, Shield, Moon, Sun, Globe, Clock, Bell } from 'lucide-react';
import { MobileSettings } from '../../types/mobile';
import { useMobileAuth } from '../../hooks/useMobileAuth';

// BDD: Personal information and subscription settings, Theme selection, Language preference, Time format
const MobileProfile: React.FC = () => {
  const { user, biometricAvailable, enableBiometric, disableBiometric } = useMobileAuth();
  const [settings, setSettings] = useState<MobileSettings>({
    theme: 'auto',
    language: 'ru',
    timeFormat: '24h',
    notifications: {
      scheduleChanges: true,
      requestUpdates: true,
      reminders: true,
      announcements: false
    },
    calendarView: 'month'
  });

  const handleSettingChange = <K extends keyof MobileSettings>(
    key: K, 
    value: MobileSettings[K]
  ) => {
    setSettings(prev => ({ ...prev, [key]: value }));
    // Save to localStorage
    localStorage.setItem('mobileSettings', JSON.stringify({ ...settings, [key]: value }));
  };

  const handleNotificationChange = (key: keyof MobileSettings['notifications'], value: boolean) => {
    const newNotifications = { ...settings.notifications, [key]: value };
    handleSettingChange('notifications', newNotifications);
  };

  const handleBiometricToggle = async () => {
    if (user?.biometricEnabled) {
      await disableBiometric();
    } else {
      await enableBiometric();
    }
  };

  return (
    <div className="space-y-6">
      {/* User Profile Section */}
      <div className="bg-white rounded-lg shadow-sm p-6">
        <div className="flex items-center space-x-4 mb-4">
          <div className="w-16 h-16 bg-blue-600 rounded-full flex items-center justify-center text-white text-xl font-semibold">
            {user?.name?.split(' ').map(n => n[0]).join('') || 'U'}
          </div>
          <div>
            <h2 className="text-lg font-semibold text-gray-900">{user?.name || 'Пользователь'}</h2>
            <p className="text-gray-600">{user?.role || 'Сотрудник'}</p>
            <p className="text-sm text-gray-500">{user?.department || 'Отдел'}</p>
          </div>
        </div>
        
        <div className="space-y-3 text-sm">
          <div className="flex justify-between">
            <span className="text-gray-600">Email:</span>
            <span className="text-gray-900">{user?.email || 'email@example.com'}</span>
          </div>
          <div className="flex justify-between">
            <span className="text-gray-600">ID сотрудника:</span>
            <span className="text-gray-900">{user?.id || '001'}</span>
          </div>
        </div>
      </div>

      {/* Security Settings */}
      <div className="bg-white rounded-lg shadow-sm p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center">
          <Shield className="h-5 w-5 mr-2" />
          Безопасность
        </h3>
        
        {biometricAvailable && (
          <div className="flex items-center justify-between py-3 border-b border-gray-200">
            <div>
              <p className="font-medium text-gray-900">Биометрическая аутентификация</p>
              <p className="text-sm text-gray-600">Вход по отпечатку пальца или Face ID</p>
            </div>
            <button
              onClick={handleBiometricToggle}
              className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
                user?.biometricEnabled ? 'bg-blue-600' : 'bg-gray-200'
              }`}
            >
              <span
                className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${
                  user?.biometricEnabled ? 'translate-x-6' : 'translate-x-1'
                }`}
              />
            </button>
          </div>
        )}
        
        <button className="w-full py-3 text-left text-gray-900 hover:bg-gray-50 rounded-lg">
          Изменить пароль
        </button>
      </div>

      {/* Appearance Settings */}
      <div className="bg-white rounded-lg shadow-sm p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center">
          <Settings className="h-5 w-5 mr-2" />
          Внешний вид
        </h3>
        
        <div className="space-y-4">
          {/* Theme Selection */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Тема
            </label>
            <div className="grid grid-cols-3 gap-2">
              {[
                { value: 'light', label: 'Светлая', icon: Sun },
                { value: 'dark', label: 'Темная', icon: Moon },
                { value: 'auto', label: 'Авто', icon: Settings }
              ].map(({ value, label, icon: Icon }) => (
                <button
                  key={value}
                  onClick={() => handleSettingChange('theme', value as any)}
                  className={`flex flex-col items-center p-3 rounded-lg border-2 transition-colors ${
                    settings.theme === value 
                      ? 'border-blue-600 bg-blue-50' 
                      : 'border-gray-200 hover:border-gray-300'
                  }`}
                >
                  <Icon className="h-5 w-5 mb-1" />
                  <span className="text-xs">{label}</span>
                </button>
              ))}
            </div>
          </div>

          {/* Language Selection */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Язык
            </label>
            <select
              value={settings.language}
              onChange={(e) => handleSettingChange('language', e.target.value as any)}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="ru">Русский</option>
              <option value="en">English</option>
            </select>
          </div>

          {/* Time Format */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Формат времени
            </label>
            <select
              value={settings.timeFormat}
              onChange={(e) => handleSettingChange('timeFormat', e.target.value as any)}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="24h">24 часа</option>
              <option value="12h">12 часов</option>
            </select>
          </div>

          {/* Default Calendar View */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Вид календаря по умолчанию
            </label>
            <select
              value={settings.calendarView}
              onChange={(e) => handleSettingChange('calendarView', e.target.value as any)}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="month">Месяц</option>
              <option value="week">Неделя</option>
              <option value="4day">4 дня</option>
              <option value="day">День</option>
            </select>
          </div>
        </div>
      </div>

      {/* Notification Settings */}
      <div className="bg-white rounded-lg shadow-sm p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center">
          <Bell className="h-5 w-5 mr-2" />
          Уведомления
        </h3>
        
        <div className="space-y-4">
          {[
            { key: 'scheduleChanges', label: 'Изменения расписания', description: 'Уведомления об изменениях в расписании' },
            { key: 'requestUpdates', label: 'Статус заявок', description: 'Уведомления о статусе ваших заявок' },
            { key: 'reminders', label: 'Напоминания', description: 'Напоминания о начале смены' },
            { key: 'announcements', label: 'Объявления', description: 'Новости и объявления компании' }
          ].map(({ key, label, description }) => (
            <div key={key} className="flex items-center justify-between py-3 border-b border-gray-200 last:border-b-0">
              <div>
                <p className="font-medium text-gray-900">{label}</p>
                <p className="text-sm text-gray-600">{description}</p>
              </div>
              <button
                onClick={() => handleNotificationChange(key as any, !settings.notifications[key as keyof typeof settings.notifications])}
                className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
                  settings.notifications[key as keyof typeof settings.notifications] ? 'bg-blue-600' : 'bg-gray-200'
                }`}
              >
                <span
                  className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${
                    settings.notifications[key as keyof typeof settings.notifications] ? 'translate-x-6' : 'translate-x-1'
                  }`}
                />
              </button>
            </div>
          ))}
        </div>
      </div>

      {/* App Info */}
      <div className="bg-white rounded-lg shadow-sm p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">
          О приложении
        </h3>
        <div className="space-y-2 text-sm">
          <div className="flex justify-between">
            <span className="text-gray-600">Версия:</span>
            <span className="text-gray-900">1.0.0</span>
          </div>
          <div className="flex justify-between">
            <span className="text-gray-600">Последнее обновление:</span>
            <span className="text-gray-900">15.07.2024</span>
          </div>
        </div>
        
        <div className="mt-4 pt-4 border-t border-gray-200">
          <button className="w-full py-2 text-blue-600 hover:text-blue-700 text-sm">
            Политика конфиденциальности
          </button>
          <button className="w-full py-2 text-blue-600 hover:text-blue-700 text-sm">
            Условия использования
          </button>
        </div>
      </div>
    </div>
  );
};

export default MobileProfile;