import React, { useState, useEffect } from 'react';
import { User, Mail, Phone, MapPin, Settings, Edit, Save, X, AlertCircle, RefreshCw } from 'lucide-react';
import realEmployeeService, { ProfileUpdateData } from '../../../../services/realEmployeeService';
import { Employee } from '../../../employee-management/types/employee';

interface ProfileViewProps {
  className?: string;
}

const ProfileView: React.FC<ProfileViewProps> = ({ className = '' }) => {
  const [employee, setEmployee] = useState<Employee | null>(null);
  const [editing, setEditing] = useState(false);
  const [formData, setFormData] = useState<ProfileUpdateData>({});
  const [isLoading, setIsLoading] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [apiError, setApiError] = useState<string>('');
  const [saveSuccess, setSaveSuccess] = useState(false);
  const [lastUpdate, setLastUpdate] = useState(new Date());

  // Load profile data from API
  const loadProfile = async () => {
    setIsLoading(true);
    setApiError('');
    
    try {
      // Check API health first
      const isApiHealthy = await realEmployeeService.checkApiHealth();
      if (!isApiHealthy) {
        throw new Error('Profile API server is not available. Please try again later.');
      }

      // Load current user profile
      const profileResult = await realEmployeeService.getMyProfile();
      
      if (profileResult.success && profileResult.data) {
        setEmployee(profileResult.data);
        console.log('[REAL PROFILE] Loaded profile:', profileResult.data);
        
        // Initialize form data
        setFormData({
          firstName: profileResult.data.personalInfo.firstName,
          lastName: profileResult.data.personalInfo.lastName,
          email: profileResult.data.personalInfo.email,
          phone: profileResult.data.personalInfo.phone,
          preferences: profileResult.data.preferences
        });
        
        setLastUpdate(new Date());
      } else {
        throw new Error(profileResult.error || 'Failed to load profile');
      }
      
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
      setApiError(errorMessage);
      console.error('[REAL PROFILE] Error loading profile:', error);
    } finally {
      setIsLoading(false);
    }
  };

  // Initial load
  useEffect(() => {
    loadProfile();
  }, []);

  // Handle refresh
  const handleRefresh = async () => {
    await loadProfile();
  };

  // Handle save profile changes
  const handleSave = async () => {
    if (!employee) return;
    
    setIsSaving(true);
    setApiError('');
    
    try {
      console.log('[REAL PROFILE] Saving profile changes:', formData);
      
      const updateResult = await realEmployeeService.updateMyProfile(formData);
      
      if (updateResult.success && updateResult.data) {
        setEmployee(updateResult.data);
        setEditing(false);
        setSaveSuccess(true);
        console.log('[REAL PROFILE] Profile updated successfully');
        
        // Hide success message after 3 seconds
        setTimeout(() => setSaveSuccess(false), 3000);
        
        setLastUpdate(new Date());
      } else {
        throw new Error(updateResult.error || 'Failed to update profile');
      }
      
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
      setApiError(errorMessage);
      console.error('[REAL PROFILE] Error saving profile:', error);
    } finally {
      setIsSaving(false);
    }
  };

  const handleCancel = () => {
    if (!employee) return;
    
    // Reset form data to original values
    setFormData({
      firstName: employee.personalInfo.firstName,
      lastName: employee.personalInfo.lastName,
      email: employee.personalInfo.email,
      phone: employee.personalInfo.phone,
      preferences: employee.preferences
    });
    setEditing(false);
    setApiError('');
  };

  const handleInputChange = (field: string, value: any) => {
    setFormData(prev => ({ ...prev, [field]: value }));
  };

  const handlePreferenceChange = (field: string, value: any) => {
    setFormData(prev => ({
      ...prev,
      preferences: {
        ...prev.preferences,
        [field]: value
      }
    }));
  };

  const handleNotificationChange = (field: string, value: boolean) => {
    setFormData(prev => ({
      ...prev,
      preferences: {
        ...prev.preferences,
        notifications: {
          ...prev.preferences?.notifications,
          [field]: value
        }
      }
    }));
  };

  // Loading state
  if (isLoading && !employee) {
    return (
      <div className={`flex items-center justify-center py-12 ${className}`}>
        <RefreshCw className="h-6 w-6 animate-spin text-blue-600 mr-3" />
        <span className="text-gray-600">Loading profile...</span>
      </div>
    );
  }

  // Error state with no data
  if (apiError && !employee) {
    return (
      <div className={`space-y-6 ${className}`}>
        <div className="bg-red-50 border border-red-200 rounded-lg p-6">
          <div className="flex items-center gap-2 text-red-800">
            <AlertCircle className="h-5 w-5 text-red-500" />
            <div>
              <div className="font-medium">Error Loading Profile</div>
              <div className="text-sm">{apiError}</div>
              <button
                onClick={handleRefresh}
                className="mt-2 text-sm text-red-600 hover:text-red-800 underline"
              >
                Try Again
              </button>
            </div>
          </div>
        </div>
      </div>
    );
  }

  if (!employee) {
    return (
      <div className={`text-center py-12 ${className}`}>
        <span className="text-gray-500">No profile data available</span>
      </div>
    );
  }

  return (
    <div className={`space-y-6 ${className}`}>
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <h2 className="text-2xl font-bold text-gray-900">My Profile</h2>
          <button
            onClick={handleRefresh}
            disabled={isLoading}
            className={`text-sm px-2 py-1 rounded-md transition-colors ${
              isLoading 
                ? 'text-blue-600 cursor-not-allowed' 
                : 'text-gray-500 hover:text-blue-600'
            }`}
          >
            <RefreshCw className={`h-4 w-4 ${isLoading ? 'animate-spin' : ''}`} />
          </button>
        </div>
        <div className="flex items-center gap-2">
          {editing ? (
            <>
              <button
                onClick={handleSave}
                disabled={isSaving}
                className="flex items-center gap-2 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors disabled:opacity-50"
              >
                {isSaving ? (
                  <>
                    <RefreshCw className="w-4 h-4 animate-spin" />
                    Saving...
                  </>
                ) : (
                  <>
                    <Save className="w-4 h-4" />
                    Save
                  </>
                )}
              </button>
              <button
                onClick={handleCancel}
                disabled={isSaving}
                className="flex items-center gap-2 px-4 py-2 bg-gray-600 text-white rounded-lg hover:bg-gray-700 transition-colors disabled:opacity-50"
              >
                <X className="w-4 h-4" />
                Cancel
              </button>
            </>
          ) : (
            <button
              onClick={() => setEditing(true)}
              className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
            >
              <Edit className="w-4 h-4" />
              Edit Profile
            </button>
          )}
        </div>
      </div>

      {/* Last Updated */}
      <div className="text-sm text-gray-500">
        Last updated: {lastUpdate.toLocaleString()}
      </div>

      {/* Success Message */}
      {saveSuccess && (
        <div className="bg-green-50 border border-green-200 rounded-lg p-4">
          <div className="flex items-center gap-2 text-green-800">
            <Save className="h-5 w-5 text-green-500" />
            <span className="font-medium">Profile updated successfully!</span>
          </div>
        </div>
      )}

      {/* API Error Display */}
      {apiError && (
        <div className="bg-red-50 border border-red-200 rounded-lg p-4">
          <div className="flex items-center gap-2 text-red-800">
            <AlertCircle className="h-5 w-5 text-red-500" />
            <div>
              <div className="font-medium">Error Updating Profile</div>
              <div className="text-sm">{apiError}</div>
            </div>
          </div>
        </div>
      )}

      {/* Profile Card */}
      <div className="bg-white rounded-lg border p-6">
        <div className="flex items-start gap-6">
          <div className="w-24 h-24 bg-blue-100 rounded-full flex items-center justify-center overflow-hidden">
            {employee.personalInfo.photo ? (
              <img 
                src={employee.personalInfo.photo} 
                alt="Profile" 
                className="w-full h-full object-cover"
              />
            ) : (
              <User className="w-12 h-12 text-blue-600" />
            )}
          </div>
          
          <div className="flex-1">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">First Name</label>
                {editing ? (
                  <input
                    type="text"
                    value={formData.firstName || ''}
                    onChange={(e) => handleInputChange('firstName', e.target.value)}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                ) : (
                  <p className="text-gray-900 font-medium">{employee.personalInfo.firstName}</p>
                )}
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Last Name</label>
                {editing ? (
                  <input
                    type="text"
                    value={formData.lastName || ''}
                    onChange={(e) => handleInputChange('lastName', e.target.value)}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                ) : (
                  <p className="text-gray-900 font-medium">{employee.personalInfo.lastName}</p>
                )}
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Position</label>
                <p className="text-gray-900">{employee.workInfo.position}</p>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Team</label>
                <span 
                  className="inline-flex items-center px-2.5 py-0.5 rounded-full text-sm font-medium"
                  style={{ backgroundColor: employee.workInfo.team.color + '20', color: employee.workInfo.team.color }}
                >
                  {employee.workInfo.team.name}
                </span>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Employee ID</label>
                <p className="text-gray-900">{employee.employeeId}</p>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Department</label>
                <p className="text-gray-900">{employee.workInfo.department}</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Contact Information */}
      <div className="bg-white rounded-lg border p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Contact Information</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Email</label>
            {editing ? (
              <input
                type="email"
                value={formData.email || ''}
                onChange={(e) => handleInputChange('email', e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            ) : (
              <div className="flex items-center gap-2 text-gray-900">
                <Mail className="w-4 h-4" />
                {employee.personalInfo.email}
              </div>
            )}
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Phone</label>
            {editing ? (
              <input
                type="tel"
                value={formData.phone || ''}
                onChange={(e) => handleInputChange('phone', e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            ) : (
              <div className="flex items-center gap-2 text-gray-900">
                <Phone className="w-4 h-4" />
                {employee.personalInfo.phone}
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Skills */}
      <div className="bg-white rounded-lg border p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Skills & Qualifications</h3>
        <div className="flex flex-wrap gap-2">
          {employee.skills && employee.skills.length > 0 ? (
            employee.skills.map((skill) => (
              <span
                key={skill.id}
                className="px-3 py-1 bg-blue-100 text-blue-800 rounded-full text-sm"
              >
                {skill.name} (Level {skill.level})
              </span>
            ))
          ) : (
            <span className="text-gray-500 text-sm">No skills configured</span>
          )}
        </div>
      </div>

      {/* Preferences */}
      <div className="bg-white rounded-lg border p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Preferences</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Language</label>
            {editing ? (
              <select
                value={formData.preferences?.language || employee.preferences.language}
                onChange={(e) => handlePreferenceChange('language', e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="ru">Русский</option>
                <option value="en">English</option>
                <option value="ky">Кыргызча</option>
              </select>
            ) : (
              <span className="text-gray-900">
                {employee.preferences.language === 'ru' ? 'Русский' : 
                 employee.preferences.language === 'en' ? 'English' : 'Кыргызча'}
              </span>
            )}
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Working Hours</label>
            <div className="text-gray-900">
              {employee.preferences.workingHours.start} - {employee.preferences.workingHours.end}
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Preferred Shifts</label>
            <div className="space-y-2">
              {['Morning', 'Day', 'Evening', 'Night'].map(shift => (
                <label key={shift} className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    checked={employee.preferences.preferredShifts.includes(shift.toLowerCase())}
                    disabled={!editing}
                    onChange={(e) => {
                      if (editing) {
                        const currentShifts = formData.preferences?.preferredShifts || employee.preferences.preferredShifts;
                        const newShifts = e.target.checked 
                          ? [...currentShifts, shift.toLowerCase()]
                          : currentShifts.filter(s => s !== shift.toLowerCase());
                        handlePreferenceChange('preferredShifts', newShifts);
                      }
                    }}
                    className="rounded"
                  />
                  <span className="text-sm">{shift}</span>
                </label>
              ))}
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Notification Settings</label>
            <div className="space-y-2">
              {[
                { key: 'email', label: 'Email notifications' },
                { key: 'sms', label: 'SMS notifications' },
                { key: 'push', label: 'Push notifications' },
                { key: 'scheduleChanges', label: 'Schedule changes' },
                { key: 'announcements', label: 'Announcements' },
                { key: 'reminders', label: 'Reminders' }
              ].map(({ key, label }) => (
                <label key={key} className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    checked={employee.preferences.notifications[key as keyof typeof employee.preferences.notifications]}
                    disabled={!editing}
                    onChange={(e) => {
                      if (editing) {
                        handleNotificationChange(key, e.target.checked);
                      }
                    }}
                    className="rounded"
                  />
                  <span className="text-sm">{label}</span>
                </label>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* Performance Metrics (Read-only) */}
      <div className="bg-white rounded-lg border p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Performance Metrics</h3>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div className="text-center">
            <div className="text-2xl font-bold text-blue-600">{employee.performance.qualityScore.toFixed(1)}%</div>
            <div className="text-sm text-gray-600">Quality Score</div>
          </div>
          <div className="text-center">
            <div className="text-2xl font-bold text-green-600">{employee.performance.adherenceScore.toFixed(1)}%</div>
            <div className="text-sm text-gray-600">Adherence</div>
          </div>
          <div className="text-center">
            <div className="text-2xl font-bold text-purple-600">{employee.performance.callsPerHour}</div>
            <div className="text-sm text-gray-600">Calls/Hour</div>
          </div>
          <div className="text-center">
            <div className="text-2xl font-bold text-orange-600">{employee.performance.customerSatisfaction.toFixed(1)}</div>
            <div className="text-sm text-gray-600">CSAT</div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ProfileView;