import React, { useState, useEffect, useCallback } from 'react';
import { 
  User, 
  Bell, 
  Clock, 
  Globe, 
  Shield, 
  Save, 
  RefreshCw,
  AlertCircle,
  CheckCircle,
  RotateCcw,
  Download,
  Upload,
  TestTube,
  Eye,
  EyeOff,
  Settings,
  Moon,
  Sun,
  Monitor,
  Smartphone
} from 'lucide-react';
import realUserPreferencesService, { UserPreferences as UserPreferencesType } from '../../../services/realUserPreferencesService';

const UserPreferences: React.FC = () => {
  const [preferences, setPreferences] = useState<UserPreferencesType | null>(null);
  const [editingPreferences, setEditingPreferences] = useState<Partial<UserPreferencesType>>({});
  const [availableShiftTypes, setAvailableShiftTypes] = useState<Array<{ id: string; name: string; description: string; icon: string }>>([]);
  const [availableDepartments, setAvailableDepartments] = useState<Array<{ id: string; name: string; description: string }>>([]);
  const [activeTab, setActiveTab] = useState<string>('notifications');
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [apiError, setApiError] = useState<string>('');
  const [saveSuccess, setSaveSuccess] = useState(false);
  const [validationErrors, setValidationErrors] = useState<string[]>([]);
  const [validationWarnings, setValidationWarnings] = useState<string[]>([]);

  const tabs = [
    { id: 'notifications', name: 'Notifications', icon: Bell, color: 'blue' },
    { id: 'shifts', name: 'Shift Preferences', icon: Clock, color: 'green' },
    { id: 'personal', name: 'Personal Settings', icon: User, color: 'purple' },
    { id: 'privacy', name: 'Privacy', icon: Shield, color: 'red' },
  ];

  const languages = [
    { code: 'ru', name: 'Русский', flag: '🇷🇺' },
    { code: 'en', name: 'English', flag: '🇺🇸' },
    { code: 'ky', name: 'Кыргызча', flag: '🇰🇬' }
  ];

  const timezones = [
    { value: 'Asia/Bishkek', label: 'Бишкек (GMT+6)' },
    { value: 'Asia/Almaty', label: 'Алматы (GMT+6)' },
    { value: 'Asia/Tashkent', label: 'Ташкент (GMT+5)' },
    { value: 'Europe/Moscow', label: 'Москва (GMT+3)' }
  ];

  const themes = [
    { value: 'light', label: 'Light', icon: Sun },
    { value: 'dark', label: 'Dark', icon: Moon },
    { value: 'auto', label: 'Auto', icon: Monitor }
  ];

  useEffect(() => {
    loadUserPreferences();
    loadAvailableOptions();

    // Subscribe to real-time updates
    const unsubscribe = realUserPreferencesService.subscribeToPreferenceUpdates((updatedPreferences) => {
      console.log('[REAL COMPONENT] Received real-time preferences update:', updatedPreferences);
      setPreferences(updatedPreferences);
      setEditingPreferences(updatedPreferences);
    });

    return unsubscribe;
  }, []);

  const loadUserPreferences = async () => {
    setLoading(true);
    setApiError('');
    
    try {
      // Check API health first
      const isApiHealthy = await realUserPreferencesService.checkApiHealth();
      if (!isApiHealthy) {
        throw new Error('API server is not available. Please try again later.');
      }

      const result = await realUserPreferencesService.getUserPreferences();
      
      if (result.success && result.data) {
        console.log('[REAL COMPONENT] Loaded user preferences:', result.data);
        setPreferences(result.data);
        setEditingPreferences(result.data);
      } else {
        setApiError(result.error || 'Failed to load user preferences');
      }
      
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
      setApiError(errorMessage);
      console.error('[REAL COMPONENT] Failed to load user preferences:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadAvailableOptions = async () => {
    try {
      const [shiftTypesResult, departmentsResult] = await Promise.all([
        realUserPreferencesService.getAvailableShiftTypes(),
        realUserPreferencesService.getAvailableDepartments()
      ]);

      if (shiftTypesResult.success && shiftTypesResult.data) {
        setAvailableShiftTypes(shiftTypesResult.data);
      }

      if (departmentsResult.success && departmentsResult.data) {
        setAvailableDepartments(departmentsResult.data);
      }
    } catch (error) {
      console.error('[REAL COMPONENT] Failed to load available options:', error);
    }
  };

  const handleSavePreferences = async () => {
    setSaving(true);
    setApiError('');
    setSaveSuccess(false);
    setValidationErrors([]);
    setValidationWarnings([]);
    
    try {
      // Validate preferences first
      const validationResult = await realUserPreferencesService.validateUserPreferences(editingPreferences);
      
      if (!validationResult.success) {
        throw new Error(validationResult.error || 'Validation failed');
      }
      
      if (validationResult.data && !validationResult.data.valid) {
        const errors = validationResult.data.errors.map(e => `${e.field}: ${e.message}`);
        setValidationErrors(errors);
        return;
      }

      if (validationResult.data?.warnings.length) {
        const warnings = validationResult.data.warnings.map(w => `${w.field}: ${w.message}`);
        setValidationWarnings(warnings);
      }

      // Update preferences
      const result = await realUserPreferencesService.updateUserPreferences(editingPreferences);
      
      if (result.success && result.data) {
        console.log('[REAL COMPONENT] Preferences updated successfully:', result.data);
        setPreferences(result.data);
        setEditingPreferences(result.data);
        setSaveSuccess(true);
        
        // Hide success message after 3 seconds
        setTimeout(() => setSaveSuccess(false), 3000);
      } else {
        setApiError(result.error || 'Failed to update preferences');
      }
      
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Save failed';
      setApiError(errorMessage);
      console.error('[REAL COMPONENT] Failed to save preferences:', error);
    } finally {
      setSaving(false);
    }
  };

  const handleResetPreferences = async () => {
    setApiError('');
    
    try {
      const result = await realUserPreferencesService.resetUserPreferences();
      
      if (result.success && result.data) {
        console.log('[REAL COMPONENT] Preferences reset successfully:', result.data);
        setPreferences(result.data);
        setEditingPreferences(result.data);
        setSaveSuccess(true);
        setTimeout(() => setSaveSuccess(false), 3000);
      } else {
        setApiError(result.error || 'Failed to reset preferences');
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Reset failed';
      setApiError(errorMessage);
    }
  };

  const handleTestNotification = async (notificationType: string) => {
    try {
      const result = await realUserPreferencesService.testNotificationSettings(notificationType);
      
      if (result.success && result.data) {
        console.log('[REAL COMPONENT] Test notification sent:', result.data);
        setSaveSuccess(true);
        setTimeout(() => setSaveSuccess(false), 3000);
      } else {
        setApiError(result.error || 'Failed to send test notification');
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Test failed';
      setApiError(errorMessage);
    }
  };

  const updateEditingPreferences = (section: keyof UserPreferencesType, field: string, value: any) => {
    setEditingPreferences(prev => ({
      ...prev,
      [section]: {
        ...((prev[section] as any) || {}),
        [field]: value
      }
    }));
  };

  const handleShiftPreferenceToggle = (type: 'preferredShifts' | 'avoidShifts', shiftId: string) => {
    if (!editingPreferences.shiftPreferences) return;

    const currentPreferred = [...(editingPreferences.shiftPreferences.preferredShifts || [])];
    const currentAvoid = [...(editingPreferences.shiftPreferences.avoidShifts || [])];

    if (type === 'preferredShifts') {
      // Remove from avoid list if exists
      const avoidIndex = currentAvoid.indexOf(shiftId);
      if (avoidIndex > -1) {
        currentAvoid.splice(avoidIndex, 1);
      }

      // Toggle in preferred list
      const preferredIndex = currentPreferred.indexOf(shiftId);
      if (preferredIndex > -1) {
        currentPreferred.splice(preferredIndex, 1);
      } else {
        currentPreferred.push(shiftId);
      }
    } else {
      // Remove from preferred list if exists
      const preferredIndex = currentPreferred.indexOf(shiftId);
      if (preferredIndex > -1) {
        currentPreferred.splice(preferredIndex, 1);
      }

      // Toggle in avoid list
      const avoidIndex = currentAvoid.indexOf(shiftId);
      if (avoidIndex > -1) {
        currentAvoid.splice(avoidIndex, 1);
      } else {
        currentAvoid.push(shiftId);
      }
    }

    setEditingPreferences(prev => ({
      ...prev,
      shiftPreferences: {
        ...prev.shiftPreferences,
        preferredShifts: currentPreferred,
        avoidShifts: currentAvoid
      }
    }));
  };

  const getShiftPreferenceStatus = (shiftId: string) => {
    if (editingPreferences.shiftPreferences?.preferredShifts?.includes(shiftId)) return 'preferred';
    if (editingPreferences.shiftPreferences?.avoidShifts?.includes(shiftId)) return 'avoid';
    return 'neutral';
  };

  const getShiftPreferenceColor = (status: string) => {
    switch (status) {
      case 'preferred': return 'border-green-300 bg-green-50 text-green-800';
      case 'avoid': return 'border-red-300 bg-red-50 text-red-800';
      default: return 'border-gray-200 bg-white text-gray-700';
    }
  };

  // Loading state
  if (loading && !preferences) {
    return (
      <div className="p-6">
        <div className="bg-white rounded-lg shadow-sm p-12 text-center">
          <RefreshCw className="h-8 w-8 text-blue-600 mx-auto mb-4 animate-spin" />
          <h3 className="text-lg font-medium text-gray-900 mb-2">Loading User Preferences</h3>
          <p className="text-gray-600">Fetching your settings from server...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="p-6">
      {/* Header */}
      <div className="mb-6">
        <h2 className="text-2xl font-bold text-gray-900 flex items-center">
          <User className="h-6 w-6 mr-2 text-blue-600" />
          User Preferences
        </h2>
        <p className="mt-2 text-gray-600">
          Customize your personal settings and preferences
        </p>
      </div>

      {/* Success Message */}
      {saveSuccess && (
        <div className="mb-6 px-6 py-3 bg-green-50 border border-green-200 rounded-lg">
          <div className="flex items-center gap-2 text-green-800">
            <CheckCircle className="h-5 w-5 text-green-500" />
            <div className="font-medium">Preferences updated successfully!</div>
          </div>
        </div>
      )}

      {/* Validation Warnings */}
      {validationWarnings.length > 0 && (
        <div className="mb-6 px-6 py-3 bg-yellow-50 border border-yellow-200 rounded-lg">
          <div className="flex items-start gap-2 text-yellow-800">
            <AlertCircle className="h-5 w-5 text-yellow-500 mt-0.5" />
            <div>
              <div className="font-medium">Warning:</div>
              <ul className="text-sm list-disc list-inside">
                {validationWarnings.map((warning, index) => (
                  <li key={index}>{warning}</li>
                ))}
              </ul>
            </div>
          </div>
        </div>
      )}

      {/* Validation Errors */}
      {validationErrors.length > 0 && (
        <div className="mb-6 px-6 py-3 bg-red-50 border border-red-200 rounded-lg">
          <div className="flex items-start gap-2 text-red-800">
            <AlertCircle className="h-5 w-5 text-red-500 mt-0.5" />
            <div>
              <div className="font-medium">Validation errors:</div>
              <ul className="text-sm list-disc list-inside">
                {validationErrors.map((error, index) => (
                  <li key={index}>{error}</li>
                ))}
              </ul>
            </div>
          </div>
        </div>
      )}

      {/* Error Message */}
      {apiError && (
        <div className="mb-6 bg-white rounded-lg shadow-sm border border-red-200">
          <div className="px-6 py-4 bg-red-50 border-b border-red-200">
            <div className="flex items-center gap-2 text-red-800">
              <AlertCircle className="h-5 w-5 text-red-500" />
              <div>
                <div className="font-medium">User Preferences Error</div>
                <div className="text-sm">{apiError}</div>
              </div>
            </div>
          </div>
          <div className="p-4">
            <button
              onClick={loadUserPreferences}
              className="px-4 py-2 bg-red-600 text-white rounded-md hover:bg-red-700"
            >
              Retry
            </button>
          </div>
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-4 gap-6">
        {/* Tab Sidebar */}
        <div className="lg:col-span-1">
          <div className="bg-white rounded-lg shadow-sm border border-gray-200">
            <div className="px-4 py-3 border-b border-gray-200">
              <h3 className="text-sm font-medium text-gray-900">Settings</h3>
            </div>
            <nav className="p-2">
              {tabs.map((tab) => {
                const Icon = tab.icon;
                return (
                  <button
                    key={tab.id}
                    onClick={() => setActiveTab(tab.id)}
                    className={`w-full flex items-center px-3 py-2 text-sm rounded-md transition-colors ${
                      activeTab === tab.id
                        ? 'bg-blue-50 text-blue-700 border-blue-200'
                        : 'text-gray-600 hover:text-gray-900 hover:bg-gray-50'
                    }`}
                  >
                    <Icon className="h-4 w-4 mr-3" />
                    {tab.name}
                  </button>
                );
              })}
            </nav>
          </div>
        </div>

        {/* Content */}
        <div className="lg:col-span-3">
          <div className="bg-white rounded-lg shadow-sm border border-gray-200">
            <div className="px-6 py-4 border-b border-gray-200">
              <div className="flex justify-between items-center">
                <h3 className="text-lg font-semibold text-gray-900">
                  {tabs.find(t => t.id === activeTab)?.name}
                </h3>
                <div className="flex gap-3">
                  <button
                    onClick={handleResetPreferences}
                    className="px-4 py-2 border border-gray-300 text-gray-700 rounded-md hover:bg-gray-50"
                  >
                    <RotateCcw className="h-4 w-4 mr-2 inline" />
                    Reset All
                  </button>
                  <button
                    onClick={handleSavePreferences}
                    disabled={saving}
                    className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed flex items-center"
                  >
                    {saving ? (
                      <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
                    ) : (
                      <Save className="h-4 w-4 mr-2" />
                    )}
                    {saving ? 'Saving...' : 'Save Changes'}
                  </button>
                </div>
              </div>
            </div>

            <div className="p-6">
              {/* Notifications Tab */}
              {activeTab === 'notifications' && (
                <div className="space-y-6">
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <label className="flex items-center justify-between p-4 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors">
                      <div>
                        <div className="font-medium text-gray-900">Schedule Changes</div>
                        <div className="text-sm text-gray-600">Notifications about schedule modifications</div>
                      </div>
                      <div className="flex items-center gap-2">
                        <input
                          type="checkbox"
                          checked={editingPreferences.notifications?.scheduleChanges || false}
                          onChange={(e) => updateEditingPreferences('notifications', 'scheduleChanges', e.target.checked)}
                          className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                        />
                        <button
                          onClick={() => handleTestNotification('scheduleChanges')}
                          className="p-1 text-gray-400 hover:text-blue-600"
                          title="Test notification"
                        >
                          <TestTube className="h-4 w-4" />
                        </button>
                      </div>
                    </label>

                    <label className="flex items-center justify-between p-4 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors">
                      <div>
                        <div className="font-medium text-gray-900">Shift Reminders</div>
                        <div className="text-sm text-gray-600">Reminders before shift starts</div>
                      </div>
                      <div className="flex items-center gap-2">
                        <input
                          type="checkbox"
                          checked={editingPreferences.notifications?.shiftReminders || false}
                          onChange={(e) => updateEditingPreferences('notifications', 'shiftReminders', e.target.checked)}
                          className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                        />
                        <button
                          onClick={() => handleTestNotification('shiftReminders')}
                          className="p-1 text-gray-400 hover:text-blue-600"
                          title="Test notification"
                        >
                          <TestTube className="h-4 w-4" />
                        </button>
                      </div>
                    </label>

                    <label className="flex items-center justify-between p-4 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors">
                      <div>
                        <div className="font-medium text-gray-900">Exchange Offers</div>
                        <div className="text-sm text-gray-600">New shift exchange proposals</div>
                      </div>
                      <div className="flex items-center gap-2">
                        <input
                          type="checkbox"
                          checked={editingPreferences.notifications?.exchangeOffers || false}
                          onChange={(e) => updateEditingPreferences('notifications', 'exchangeOffers', e.target.checked)}
                          className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                        />
                        <button
                          onClick={() => handleTestNotification('exchangeOffers')}
                          className="p-1 text-gray-400 hover:text-blue-600"
                          title="Test notification"
                        >
                          <TestTube className="h-4 w-4" />
                        </button>
                      </div>
                    </label>

                    <label className="flex items-center justify-between p-4 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors">
                      <div>
                        <div className="font-medium text-gray-900">Push Notifications</div>
                        <div className="text-sm text-gray-600">Instant browser notifications</div>
                      </div>
                      <div className="flex items-center gap-2">
                        <input
                          type="checkbox"
                          checked={editingPreferences.notifications?.pushNotifications || false}
                          onChange={(e) => updateEditingPreferences('notifications', 'pushNotifications', e.target.checked)}
                          className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                        />
                        <Smartphone className="h-4 w-4 text-gray-400" />
                      </div>
                    </label>
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        Reminder Time (minutes before shift)
                      </label>
                      <select
                        value={editingPreferences.notifications?.reminderMinutes || 15}
                        onChange={(e) => updateEditingPreferences('notifications', 'reminderMinutes', parseInt(e.target.value))}
                        className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                      >
                        <option value={5}>5 minutes</option>
                        <option value={15}>15 minutes</option>
                        <option value={30}>30 minutes</option>
                        <option value={60}>1 hour</option>
                        <option value={120}>2 hours</option>
                      </select>
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        Email Digest Frequency
                      </label>
                      <select
                        value={editingPreferences.notifications?.digestFrequency || 'weekly'}
                        onChange={(e) => updateEditingPreferences('notifications', 'digestFrequency', e.target.value)}
                        className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                      >
                        <option value="daily">Daily</option>
                        <option value="weekly">Weekly</option>
                        <option value="never">Never</option>
                      </select>
                    </div>
                  </div>
                </div>
              )}

              {/* Shift Preferences Tab */}
              {activeTab === 'shifts' && (
                <div className="space-y-6">
                  <div>
                    <h4 className="font-medium text-gray-900 mb-3">Shift Types</h4>
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
                      {availableShiftTypes.map((shift) => {
                        const status = getShiftPreferenceStatus(shift.id);
                        return (
                          <div key={shift.id} className={`border-2 rounded-lg p-3 transition-colors ${getShiftPreferenceColor(status)}`}>
                            <div className="flex items-center gap-2 mb-2">
                              <span className="text-lg">{shift.icon}</span>
                              <span className="font-medium text-sm">{shift.name}</span>
                            </div>
                            <p className="text-xs text-gray-600 mb-2">{shift.description}</p>
                            
                            <div className="flex gap-2">
                              <button
                                onClick={() => handleShiftPreferenceToggle('preferredShifts', shift.id)}
                                className={`flex-1 px-2 py-1 text-xs rounded transition-colors ${
                                  status === 'preferred'
                                    ? 'bg-green-600 text-white'
                                    : 'bg-green-100 text-green-700 hover:bg-green-200'
                                }`}
                              >
                                {status === 'preferred' ? '✓ Prefer' : 'Prefer'}
                              </button>
                              
                              <button
                                onClick={() => handleShiftPreferenceToggle('avoidShifts', shift.id)}
                                className={`flex-1 px-2 py-1 text-xs rounded transition-colors ${
                                  status === 'avoid'
                                    ? 'bg-red-600 text-white'
                                    : 'bg-red-100 text-red-700 hover:bg-red-200'
                                }`}
                              >
                                {status === 'avoid' ? '✓ Avoid' : 'Avoid'}
                              </button>
                            </div>
                          </div>
                        );
                      })}
                    </div>
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        Max Consecutive Days
                      </label>
                      <select
                        value={editingPreferences.shiftPreferences?.maxConsecutiveDays || 5}
                        onChange={(e) => updateEditingPreferences('shiftPreferences', 'maxConsecutiveDays', parseInt(e.target.value))}
                        className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                      >
                        {[3, 4, 5, 6, 7].map(days => (
                          <option key={days} value={days}>{days} days</option>
                        ))}
                      </select>
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        Min Rest Hours
                      </label>
                      <select
                        value={editingPreferences.shiftPreferences?.minRestHours || 11}
                        onChange={(e) => updateEditingPreferences('shiftPreferences', 'minRestHours', parseInt(e.target.value))}
                        className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                      >
                        {[8, 10, 11, 12, 16, 24].map(hours => (
                          <option key={hours} value={hours}>{hours} hours</option>
                        ))}
                      </select>
                    </div>
                  </div>
                </div>
              )}

              {/* Personal Settings Tab */}
              {activeTab === 'personal' && (
                <div className="space-y-6">
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        Language
                      </label>
                      <select
                        value={editingPreferences.language || 'en'}
                        onChange={(e) => setEditingPreferences(prev => ({ ...prev, language: e.target.value as any }))}
                        className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                      >
                        {languages.map(lang => (
                          <option key={lang.code} value={lang.code}>
                            {lang.flag} {lang.name}
                          </option>
                        ))}
                      </select>
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        Timezone
                      </label>
                      <select
                        value={editingPreferences.timezone || 'Asia/Bishkek'}
                        onChange={(e) => setEditingPreferences(prev => ({ ...prev, timezone: e.target.value }))}
                        className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                      >
                        {timezones.map(tz => (
                          <option key={tz.value} value={tz.value}>{tz.label}</option>
                        ))}
                      </select>
                    </div>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-3">Theme</label>
                    <div className="grid grid-cols-3 gap-3">
                      {themes.map((theme) => {
                        const Icon = theme.icon;
                        return (
                          <button
                            key={theme.value}
                            onClick={() => updateEditingPreferences('personalSettings', 'theme', theme.value)}
                            className={`p-3 border-2 rounded-lg transition-colors ${
                              editingPreferences.personalSettings?.theme === theme.value
                                ? 'border-blue-500 bg-blue-50'
                                : 'border-gray-200 hover:border-gray-300'
                            }`}
                          >
                            <Icon className="h-6 w-6 mx-auto mb-2" />
                            <div className="text-sm font-medium">{theme.label}</div>
                          </button>
                        );
                      })}
                    </div>
                  </div>

                  <div className="space-y-4">
                    <label className="flex items-center">
                      <input
                        type="checkbox"
                        checked={editingPreferences.personalSettings?.compactView || false}
                        onChange={(e) => updateEditingPreferences('personalSettings', 'compactView', e.target.checked)}
                        className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                      />
                      <span className="ml-2 text-sm text-gray-700">Compact view</span>
                    </label>

                    <label className="flex items-center">
                      <input
                        type="checkbox"
                        checked={editingPreferences.personalSettings?.showWeekNumbers || false}
                        onChange={(e) => updateEditingPreferences('personalSettings', 'showWeekNumbers', e.target.checked)}
                        className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                      />
                      <span className="ml-2 text-sm text-gray-700">Show week numbers</span>
                    </label>

                    <label className="flex items-center">
                      <input
                        type="checkbox"
                        checked={editingPreferences.personalSettings?.startWeekOnMonday || true}
                        onChange={(e) => updateEditingPreferences('personalSettings', 'startWeekOnMonday', e.target.checked)}
                        className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                      />
                      <span className="ml-2 text-sm text-gray-700">Start week on Monday</span>
                    </label>
                  </div>
                </div>
              )}

              {/* Privacy Tab */}
              {activeTab === 'privacy' && (
                <div className="space-y-6">
                  <div className="space-y-4">
                    <label className="flex items-center justify-between p-4 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors">
                      <div>
                        <div className="font-medium text-gray-900">Share preferences with supervisor</div>
                        <div className="text-sm text-gray-600">Allow supervisors to see your shift preferences</div>
                      </div>
                      <div className="flex items-center gap-2">
                        <input
                          type="checkbox"
                          checked={editingPreferences.privacy?.sharePreferencesWithSupervisor || false}
                          onChange={(e) => updateEditingPreferences('privacy', 'sharePreferencesWithSupervisor', e.target.checked)}
                          className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                        />
                        {editingPreferences.privacy?.sharePreferencesWithSupervisor ? (
                          <Eye className="h-4 w-4 text-green-500" />
                        ) : (
                          <EyeOff className="h-4 w-4 text-gray-400" />
                        )}
                      </div>
                    </label>

                    <label className="flex items-center justify-between p-4 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors">
                      <div>
                        <div className="font-medium text-gray-900">Allow automatic scheduling</div>
                        <div className="text-sm text-gray-600">Enable system to automatically assign shifts based on preferences</div>
                      </div>
                      <input
                        type="checkbox"
                        checked={editingPreferences.privacy?.allowAutomaticScheduling || false}
                        onChange={(e) => updateEditingPreferences('privacy', 'allowAutomaticScheduling', e.target.checked)}
                        className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                      />
                    </label>

                    <label className="flex items-center justify-between p-4 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors">
                      <div>
                        <div className="font-medium text-gray-900">Visible to colleagues</div>
                        <div className="text-sm text-gray-600">Allow colleagues to see your basic availability</div>
                      </div>
                      <input
                        type="checkbox"
                        checked={editingPreferences.privacy?.visibleToColleagues || false}
                        onChange={(e) => updateEditingPreferences('privacy', 'visibleToColleagues', e.target.checked)}
                        className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                      />
                    </label>
                  </div>

                  {/* Privacy Notice */}
                  <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
                    <div className="flex items-start gap-3">
                      <Shield className="h-5 w-5 text-blue-600 mt-0.5" />
                      <div>
                        <h4 className="font-medium text-blue-900 mb-1">Privacy Protection</h4>
                        <p className="text-sm text-blue-800">
                          Your personal preferences are encrypted and only accessible to authorized personnel. 
                          You can change these privacy settings at any time.
                        </p>
                      </div>
                    </div>
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default UserPreferences;