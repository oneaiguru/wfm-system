import React, { useState, useEffect } from 'react';
import { AlertCircle, RefreshCw, Save, X, CheckCircle } from 'lucide-react';
import realUserPreferencesService, { EmployeeProfile } from '../../../../services/realUserPreferencesService';

interface ProfileManagerProps {
  employeeId: string;
}

interface EmployeeProfile {
  id: string;
  personalInfo: {
    firstName: string;
    lastName: string;
    email: string;
    phone: string;
    birthDate: string;
    address: string;
    emergencyContact: {
      name: string;
      relationship: string;
      phone: string;
    };
  };
  workInfo: {
    position: string;
    department: string;
    team: string;
    startDate: string;
    employeeId: string;
    skills: string[];
    certifications: string[];
  };
  preferences: {
    notifications: {
      email: boolean;
      sms: boolean;
      pushNotifications: boolean;
    };
    schedule: {
      preferredShifts: string[];
      availableDays: string[];
      timeOff: {
        preferredMonths: string[];
        maxConsecutiveDays: number;
      };
    };
  };
}

const ProfileManager: React.FC<ProfileManagerProps> = ({ employeeId }) => {
  const [activeTab, setActiveTab] = useState<'personal' | 'work' | 'preferences'>('personal');
  const [profile, setProfile] = useState<EmployeeProfile | null>(null);
  const [editingProfile, setEditingProfile] = useState<EmployeeProfile | null>(null);
  const [isEditing, setIsEditing] = useState(false);
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [apiError, setApiError] = useState<string>('');
  const [saveSuccess, setSaveSuccess] = useState(false);
  const [availableSkills, setAvailableSkills] = useState<string[]>([]);
  const [availableCertifications, setAvailableCertifications] = useState<string[]>([]);

  useEffect(() => {
    loadUserProfile();
    loadAvailableOptions();
  }, [employeeId]);

  const loadUserProfile = async () => {
    setLoading(true);
    setApiError('');
    
    try {
      // Check API health first
      const isApiHealthy = await realUserPreferencesService.checkApiHealth();
      if (!isApiHealthy) {
        throw new Error('API server is not available. Please try again later.');
      }

      const result = await realUserPreferencesService.getUserProfile();
      
      if (result.success && result.data) {
        console.log('[REAL COMPONENT] Loaded user profile:', result.data);
        setProfile(result.data);
        setEditingProfile(result.data);
      } else {
        setApiError(result.error || 'Failed to load user profile');
      }
      
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
      setApiError(errorMessage);
      console.error('[REAL COMPONENT] Failed to load user profile:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadAvailableOptions = async () => {
    try {
      const [skillsResult, certsResult] = await Promise.all([
        realUserPreferencesService.getAvailableSkills(),
        realUserPreferencesService.getAvailableCertifications()
      ]);
      
      if (skillsResult.success && skillsResult.data) {
        setAvailableSkills(skillsResult.data);
      }
      
      if (certsResult.success && certsResult.data) {
        setAvailableCertifications(certsResult.data);
      }
    } catch (error) {
      console.error('[REAL COMPONENT] Failed to load available options:', error);
    }
  };

  const handleSave = async () => {
    if (!editingProfile) return;
    
    setSaving(true);
    setApiError('');
    setSaveSuccess(false);
    
    try {
      // Validate settings first
      const validationResult = await realUserPreferencesService.validateUserSettings(editingProfile);
      
      if (!validationResult.success) {
        throw new Error(validationResult.error || 'Validation failed');
      }
      
      if (validationResult.data && !validationResult.data.valid) {
        throw new Error(validationResult.data.errors.join(', '));
      }

      // Save the complete profile
      const result = await realUserPreferencesService.updateUserProfile(editingProfile);
      
      if (result.success && result.data) {
        console.log('[REAL COMPONENT] Profile updated successfully:', result.data);
        setProfile(result.data);
        setEditingProfile(result.data);
        setIsEditing(false);
        setSaveSuccess(true);
        
        // Hide success message after 3 seconds
        setTimeout(() => setSaveSuccess(false), 3000);
      } else {
        setApiError(result.error || 'Failed to update profile');
      }
      
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Save failed';
      setApiError(errorMessage);
      console.error('[REAL COMPONENT] Failed to save profile:', error);
    } finally {
      setSaving(false);
    }
  };

  const handleCancel = () => {
    if (profile) {
      setEditingProfile(profile);
    }
    setIsEditing(false);
    setApiError('');
    setSaveSuccess(false);
  };

  const updatePersonalInfo = (field: string, value: string) => {
    if (!editingProfile) return;
    
    setEditingProfile(prev => prev ? ({
      ...prev,
      personalInfo: {
        ...prev.personalInfo,
        [field]: value
      }
    }) : null);
  };

  const updateWorkInfo = (field: string, value: string | string[]) => {
    if (!editingProfile) return;
    
    setEditingProfile(prev => prev ? ({
      ...prev,
      workInfo: {
        ...prev.workInfo,
        [field]: value
      }
    }) : null);
  };

  const updatePreferences = (category: string, field: string, value: any) => {
    if (!editingProfile) return;
    
    setEditingProfile(prev => prev ? ({
      ...prev,
      preferences: {
        ...prev.preferences,
        [category]: {
          ...prev.preferences[category as keyof typeof prev.preferences],
          [field]: value
        }
      }
    }) : null);
  };

  const handleResetToDefaults = async () => {
    setApiError('');
    setSaving(true);
    
    try {
      const result = await realUserPreferencesService.resetToDefaults();
      
      if (result.success && result.data && profile) {
        const updatedProfile = {
          ...profile,
          preferences: result.data
        };
        setProfile(updatedProfile);
        setEditingProfile(updatedProfile);
        setSaveSuccess(true);
        setTimeout(() => setSaveSuccess(false), 3000);
      } else {
        setApiError(result.error || 'Failed to reset preferences');
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Reset failed';
      setApiError(errorMessage);
    } finally {
      setSaving(false);
    }
  };

  const renderPersonalInfo = () => (
    <div className="space-y-6">
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">First Name</label>
          <input
            type="text"
            value={isEditing ? (editingProfile?.personalInfo.firstName || '') : (profile?.personalInfo.firstName || '')}
            onChange={(e) => updatePersonalInfo('firstName', e.target.value)}
            disabled={!isEditing}
            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 disabled:bg-gray-50"
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Last Name</label>
          <input
            type="text"
            value={isEditing ? (editingProfile?.personalInfo.lastName || '') : (profile?.personalInfo.lastName || '')}
            onChange={(e) => updatePersonalInfo('lastName', e.target.value)}
            disabled={!isEditing}
            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 disabled:bg-gray-50"
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Email</label>
          <input
            type="email"
            value={isEditing ? (editingProfile?.personalInfo.email || '') : (profile?.personalInfo.email || '')}
            onChange={(e) => updatePersonalInfo('email', e.target.value)}
            disabled={!isEditing}
            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 disabled:bg-gray-50"
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Phone</label>
          <input
            type="tel"
            value={isEditing ? (editingProfile?.personalInfo.phone || '') : (profile?.personalInfo.phone || '')}
            onChange={(e) => updatePersonalInfo('phone', e.target.value)}
            disabled={!isEditing}
            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 disabled:bg-gray-50"
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Birth Date</label>
          <input
            type="date"
            value={isEditing ? (editingProfile?.personalInfo.birthDate || '') : (profile?.personalInfo.birthDate || '')}
            onChange={(e) => updatePersonalInfo('birthDate', e.target.value)}
            disabled={!isEditing}
            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 disabled:bg-gray-50"
          />
        </div>
      </div>
      
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">Address</label>
        <textarea
          value={isEditing ? (editingProfile?.personalInfo.address || '') : (profile?.personalInfo.address || '')}
          onChange={(e) => updatePersonalInfo('address', e.target.value)}
          disabled={!isEditing}
          rows={3}
          className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 disabled:bg-gray-50"
        />
      </div>

      <div className="border-t pt-6">
        <h3 className="text-lg font-medium text-gray-900 mb-4">Emergency Contact</h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Name</label>
            <input
              type="text"
              value={isEditing ? (editingProfile?.personalInfo.emergencyContact.name || '') : (profile?.personalInfo.emergencyContact.name || '')}
              onChange={(e) => setEditingProfile(prev => prev ? ({
                ...prev,
                personalInfo: {
                  ...prev.personalInfo,
                  emergencyContact: {
                    ...prev.personalInfo.emergencyContact,
                    name: e.target.value
                  }
                }
              }) : null)}
              disabled={!isEditing}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 disabled:bg-gray-50"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Relationship</label>
            <input
              type="text"
              value={isEditing ? (editingProfile?.personalInfo.emergencyContact.relationship || '') : (profile?.personalInfo.emergencyContact.relationship || '')}
              onChange={(e) => setEditingProfile(prev => prev ? ({
                ...prev,
                personalInfo: {
                  ...prev.personalInfo,
                  emergencyContact: {
                    ...prev.personalInfo.emergencyContact,
                    relationship: e.target.value
                  }
                }
              }) : null)}
              disabled={!isEditing}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 disabled:bg-gray-50"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Phone</label>
            <input
              type="tel"
              value={isEditing ? (editingProfile?.personalInfo.emergencyContact.phone || '') : (profile?.personalInfo.emergencyContact.phone || '')}
              onChange={(e) => setEditingProfile(prev => prev ? ({
                ...prev,
                personalInfo: {
                  ...prev.personalInfo,
                  emergencyContact: {
                    ...prev.personalInfo.emergencyContact,
                    phone: e.target.value
                  }
                }
              }) : null)}
              disabled={!isEditing}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 disabled:bg-gray-50"
            />
          </div>
        </div>
      </div>
    </div>
  );

  const renderWorkInfo = () => (
    <div className="space-y-6">
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Position</label>
          <input
            type="text"
            value={profile?.workInfo.position || ''}
            disabled
            className="w-full px-3 py-2 border border-gray-300 rounded-lg bg-gray-50"
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Department</label>
          <input
            type="text"
            value={profile?.workInfo.department || ''}
            disabled
            className="w-full px-3 py-2 border border-gray-300 rounded-lg bg-gray-50"
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Team</label>
          <input
            type="text"
            value={profile?.workInfo.team || ''}
            disabled
            className="w-full px-3 py-2 border border-gray-300 rounded-lg bg-gray-50"
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Start Date</label>
          <input
            type="date"
            value={profile?.workInfo.startDate || ''}
            disabled
            className="w-full px-3 py-2 border border-gray-300 rounded-lg bg-gray-50"
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Employee ID</label>
          <input
            type="text"
            value={profile?.workInfo.employeeId || ''}
            disabled
            className="w-full px-3 py-2 border border-gray-300 rounded-lg bg-gray-50"
          />
        </div>
      </div>

      <div>
        <label className="block text-sm font-medium text-gray-700 mb-2">Skills</label>
        <div className="flex flex-wrap gap-2">
          {(profile?.workInfo.skills || []).map((skill, index) => (
            <span
              key={index}
              className="px-3 py-1 bg-blue-100 text-blue-800 rounded-full text-sm"
            >
              {skill}
            </span>
          ))}
        </div>
      </div>

      <div>
        <label className="block text-sm font-medium text-gray-700 mb-2">Certifications</label>
        <div className="flex flex-wrap gap-2">
          {(profile?.workInfo.certifications || []).map((cert, index) => (
            <span
              key={index}
              className="px-3 py-1 bg-green-100 text-green-800 rounded-full text-sm"
            >
              {cert}
            </span>
          ))}
        </div>
      </div>
    </div>
  );

  const renderPreferences = () => (
    <div className="space-y-6">
      <div>
        <h3 className="text-lg font-medium text-gray-900 mb-4">Notification Preferences</h3>
        <div className="space-y-3">
          <label className="flex items-center">
            <input
              type="checkbox"
              checked={isEditing ? (editingProfile?.preferences.notifications.email || false) : (profile?.preferences.notifications.email || false)}
              onChange={(e) => updatePreferences('notifications', 'email', e.target.checked)}
              disabled={!isEditing}
              className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
            />
            <span className="ml-2 text-sm text-gray-700">Email notifications</span>
          </label>
          <label className="flex items-center">
            <input
              type="checkbox"
              checked={isEditing ? (editingProfile?.preferences.notifications.sms || false) : (profile?.preferences.notifications.sms || false)}
              onChange={(e) => updatePreferences('notifications', 'sms', e.target.checked)}
              disabled={!isEditing}
              className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
            />
            <span className="ml-2 text-sm text-gray-700">SMS notifications</span>
          </label>
          <label className="flex items-center">
            <input
              type="checkbox"
              checked={isEditing ? (editingProfile?.preferences.notifications.pushNotifications || false) : (profile?.preferences.notifications.pushNotifications || false)}
              onChange={(e) => updatePreferences('notifications', 'pushNotifications', e.target.checked)}
              disabled={!isEditing}
              className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
            />
            <span className="ml-2 text-sm text-gray-700">Push notifications</span>
          </label>
        </div>
      </div>

      <div>
        <h3 className="text-lg font-medium text-gray-900 mb-4">Schedule Preferences</h3>
        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Preferred Shifts</label>
            <div className="flex flex-wrap gap-2">
              {['morning', 'day', 'evening', 'night'].map(shift => (
                <label key={shift} className="flex items-center">
                  <input
                    type="checkbox"
                    checked={isEditing ? 
                      (editingProfile?.preferences.schedule.preferredShifts || []).includes(shift) : 
                      (profile?.preferences.schedule.preferredShifts || []).includes(shift)
                    }
                    onChange={(e) => {
                      const current = isEditing ? (editingProfile?.preferences.schedule.preferredShifts || []) : (profile?.preferences.schedule.preferredShifts || []);
                      const updated = e.target.checked 
                        ? [...current, shift]
                        : current.filter(s => s !== shift);
                      updatePreferences('schedule', 'preferredShifts', updated);
                    }}
                    disabled={!isEditing}
                    className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                  />
                  <span className="ml-2 text-sm text-gray-700 capitalize">{shift}</span>
                </label>
              ))}
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Available Days</label>
            <div className="flex flex-wrap gap-2">
              {['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'].map(day => (
                <label key={day} className="flex items-center">
                  <input
                    type="checkbox"
                    checked={isEditing ? 
                      (editingProfile?.preferences.schedule.availableDays || []).includes(day) : 
                      (profile?.preferences.schedule.availableDays || []).includes(day)
                    }
                    onChange={(e) => {
                      const current = isEditing ? (editingProfile?.preferences.schedule.availableDays || []) : (profile?.preferences.schedule.availableDays || []);
                      const updated = e.target.checked 
                        ? [...current, day]
                        : current.filter(d => d !== day);
                      updatePreferences('schedule', 'availableDays', updated);
                    }}
                    disabled={!isEditing}
                    className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                  />
                  <span className="ml-2 text-sm text-gray-700 capitalize">{day}</span>
                </label>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );

  // Loading state
  if (loading) {
    return (
      <div className="p-6">
        <div className="bg-white rounded-lg shadow-sm p-12 text-center">
          <RefreshCw className="h-8 w-8 text-blue-600 mx-auto mb-4 animate-spin" />
          <h3 className="text-lg font-medium text-gray-900 mb-2">Loading Profile</h3>
          <p className="text-gray-600">Fetching user information from server...</p>
        </div>
      </div>
    );
  }

  // Error state
  if (apiError && !profile) {
    return (
      <div className="p-6">
        <div className="bg-white rounded-lg shadow-sm border border-red-200">
          <div className="px-6 py-4 bg-red-50 border-b border-red-200">
            <div className="flex items-center gap-2 text-red-800">
              <AlertCircle className="h-5 w-5 text-red-500" />
              <div>
                <div className="font-medium">Profile Loading Error</div>
                <div className="text-sm">{apiError}</div>
              </div>
            </div>
          </div>
          <div className="p-4">
            <button
              onClick={loadUserProfile}
              className="px-4 py-2 bg-red-600 text-white rounded-md hover:bg-red-700"
            >
              Retry
            </button>
          </div>
        </div>
      </div>
    );
  }

  if (!profile) {
    return (
      <div className="p-6">
        <div className="bg-white rounded-lg shadow-sm p-12 text-center">
          <AlertCircle className="h-12 w-12 text-gray-400 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-gray-900 mb-2">No Profile Data</h3>
          <p className="text-gray-600">Unable to load profile information.</p>
        </div>
      </div>
    );
  }

  return (
    <div className="p-6">
      <div className="bg-white rounded-lg shadow-sm">
        {/* Success Message */}
        {saveSuccess && (
          <div className="px-6 py-3 bg-green-50 border-b border-green-200">
            <div className="flex items-center gap-2 text-green-800">
              <CheckCircle className="h-5 w-5 text-green-500" />
              <div className="font-medium">Profile updated successfully!</div>
            </div>
          </div>
        )}

        {/* Error Message */}
        {apiError && (
          <div className="px-6 py-3 bg-red-50 border-b border-red-200">
            <div className="flex items-center gap-2 text-red-800">
              <AlertCircle className="h-5 w-5 text-red-500" />
              <div>
                <div className="font-medium">Profile Update Error</div>
                <div className="text-sm">{apiError}</div>
              </div>
            </div>
          </div>
        )}

        {/* Header */}
        <div className="border-b border-gray-200 p-6">
          <div className="flex justify-between items-center">
            <div>
              <h2 className="text-2xl font-semibold text-gray-900">My Profile</h2>
              <p className="text-sm text-gray-500 mt-1">Manage your personal information and preferences</p>
            </div>
            <div className="flex gap-3">
              {isEditing ? (
                <>
                  <button
                    onClick={handleCancel}
                    disabled={saving}
                    className="px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    <X className="h-4 w-4 mr-2 inline" />
                    Cancel
                  </button>
                  <button
                    onClick={handleSave}
                    disabled={saving}
                    className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center"
                  >
                    {saving ? (
                      <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
                    ) : (
                      <Save className="h-4 w-4 mr-2" />
                    )}
                    {saving ? 'Saving...' : 'Save Changes'}
                  </button>
                </>
              ) : (
                <>
                  <button
                    onClick={() => setIsEditing(true)}
                    disabled={loading}
                    className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    Edit Profile
                  </button>
                  {activeTab === 'preferences' && (
                    <button
                      onClick={handleResetToDefaults}
                      disabled={saving}
                      className="px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                    >
                      Reset to Defaults
                    </button>
                  )}
                </>
              )}
            </div>
          </div>

          {/* Tabs */}
          <div className="flex gap-1 mt-6 bg-gray-100 rounded-lg p-1">
            {(['personal', 'work', 'preferences'] as const).map((tab) => (
              <button
                key={tab}
                onClick={() => setActiveTab(tab)}
                className={`px-4 py-2 rounded-md text-sm font-medium transition-colors flex-1 ${
                  activeTab === tab
                    ? 'bg-white text-blue-600 shadow-sm'
                    : 'text-gray-600 hover:text-gray-900'
                }`}
              >
                {tab === 'personal' && '👤 Personal Info'}
                {tab === 'work' && '💼 Work Info'}
                {tab === 'preferences' && '� Preferences'}
              </button>
            ))}
          </div>
        </div>

        {/* Content */}
        <div className="p-6">
          {activeTab === 'personal' && renderPersonalInfo()}
          {activeTab === 'work' && renderWorkInfo()}
          {activeTab === 'preferences' && renderPreferences()}
        </div>
      </div>
    </div>
  );
};

export default ProfileManager;