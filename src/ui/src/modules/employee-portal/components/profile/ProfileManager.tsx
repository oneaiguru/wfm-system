import React, { useState } from 'react';

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
  const [profile, setProfile] = useState<EmployeeProfile>({
    id: employeeId,
    personalInfo: {
      firstName: 'John',
      lastName: 'Smith',
      email: 'john.smith@company.com',
      phone: '+1 (555) 123-4567',
      birthDate: '1990-05-15',
      address: '123 Main St, City, State 12345',
      emergencyContact: {
        name: 'Jane Smith',
        relationship: 'Spouse',
        phone: '+1 (555) 987-6543'
      }
    },
    workInfo: {
      position: 'Customer Service Agent',
      department: 'Customer Support',
      team: 'Team Alpha',
      startDate: '2023-01-15',
      employeeId: 'EMP001',
      skills: ['Customer Service', 'Problem Solving', 'Communication', 'Microsoft Office'],
      certifications: ['First Aid', 'Customer Service Excellence']
    },
    preferences: {
      notifications: {
        email: true,
        sms: false,
        pushNotifications: true
      },
      schedule: {
        preferredShifts: ['morning', 'day'],
        availableDays: ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
        timeOff: {
          preferredMonths: ['july', 'august', 'december'],
          maxConsecutiveDays: 14
        }
      }
    }
  });

  const [isEditing, setIsEditing] = useState(false);
  const [editingProfile, setEditingProfile] = useState<EmployeeProfile>(profile);

  const handleSave = () => {
    setProfile(editingProfile);
    setIsEditing(false);
    // In real app, would save to API
    console.log('Profile updated:', editingProfile);
  };

  const handleCancel = () => {
    setEditingProfile(profile);
    setIsEditing(false);
  };

  const updatePersonalInfo = (field: string, value: string) => {
    setEditingProfile(prev => ({
      ...prev,
      personalInfo: {
        ...prev.personalInfo,
        [field]: value
      }
    }));
  };

  const updateWorkInfo = (field: string, value: string | string[]) => {
    setEditingProfile(prev => ({
      ...prev,
      workInfo: {
        ...prev.workInfo,
        [field]: value
      }
    }));
  };

  const updatePreferences = (category: string, field: string, value: any) => {
    setEditingProfile(prev => ({
      ...prev,
      preferences: {
        ...prev.preferences,
        [category]: {
          ...prev.preferences[category as keyof typeof prev.preferences],
          [field]: value
        }
      }
    }));
  };

  const renderPersonalInfo = () => (
    <div className="space-y-6">
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">First Name</label>
          <input
            type="text"
            value={isEditing ? editingProfile.personalInfo.firstName : profile.personalInfo.firstName}
            onChange={(e) => updatePersonalInfo('firstName', e.target.value)}
            disabled={!isEditing}
            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 disabled:bg-gray-50"
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Last Name</label>
          <input
            type="text"
            value={isEditing ? editingProfile.personalInfo.lastName : profile.personalInfo.lastName}
            onChange={(e) => updatePersonalInfo('lastName', e.target.value)}
            disabled={!isEditing}
            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 disabled:bg-gray-50"
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Email</label>
          <input
            type="email"
            value={isEditing ? editingProfile.personalInfo.email : profile.personalInfo.email}
            onChange={(e) => updatePersonalInfo('email', e.target.value)}
            disabled={!isEditing}
            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 disabled:bg-gray-50"
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Phone</label>
          <input
            type="tel"
            value={isEditing ? editingProfile.personalInfo.phone : profile.personalInfo.phone}
            onChange={(e) => updatePersonalInfo('phone', e.target.value)}
            disabled={!isEditing}
            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 disabled:bg-gray-50"
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Birth Date</label>
          <input
            type="date"
            value={isEditing ? editingProfile.personalInfo.birthDate : profile.personalInfo.birthDate}
            onChange={(e) => updatePersonalInfo('birthDate', e.target.value)}
            disabled={!isEditing}
            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 disabled:bg-gray-50"
          />
        </div>
      </div>
      
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">Address</label>
        <textarea
          value={isEditing ? editingProfile.personalInfo.address : profile.personalInfo.address}
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
              value={isEditing ? editingProfile.personalInfo.emergencyContact.name : profile.personalInfo.emergencyContact.name}
              onChange={(e) => setEditingProfile(prev => ({
                ...prev,
                personalInfo: {
                  ...prev.personalInfo,
                  emergencyContact: {
                    ...prev.personalInfo.emergencyContact,
                    name: e.target.value
                  }
                }
              }))}
              disabled={!isEditing}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 disabled:bg-gray-50"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Relationship</label>
            <input
              type="text"
              value={isEditing ? editingProfile.personalInfo.emergencyContact.relationship : profile.personalInfo.emergencyContact.relationship}
              onChange={(e) => setEditingProfile(prev => ({
                ...prev,
                personalInfo: {
                  ...prev.personalInfo,
                  emergencyContact: {
                    ...prev.personalInfo.emergencyContact,
                    relationship: e.target.value
                  }
                }
              }))}
              disabled={!isEditing}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 disabled:bg-gray-50"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Phone</label>
            <input
              type="tel"
              value={isEditing ? editingProfile.personalInfo.emergencyContact.phone : profile.personalInfo.emergencyContact.phone}
              onChange={(e) => setEditingProfile(prev => ({
                ...prev,
                personalInfo: {
                  ...prev.personalInfo,
                  emergencyContact: {
                    ...prev.personalInfo.emergencyContact,
                    phone: e.target.value
                  }
                }
              }))}
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
            value={profile.workInfo.position}
            disabled
            className="w-full px-3 py-2 border border-gray-300 rounded-lg bg-gray-50"
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Department</label>
          <input
            type="text"
            value={profile.workInfo.department}
            disabled
            className="w-full px-3 py-2 border border-gray-300 rounded-lg bg-gray-50"
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Team</label>
          <input
            type="text"
            value={profile.workInfo.team}
            disabled
            className="w-full px-3 py-2 border border-gray-300 rounded-lg bg-gray-50"
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Start Date</label>
          <input
            type="date"
            value={profile.workInfo.startDate}
            disabled
            className="w-full px-3 py-2 border border-gray-300 rounded-lg bg-gray-50"
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Employee ID</label>
          <input
            type="text"
            value={profile.workInfo.employeeId}
            disabled
            className="w-full px-3 py-2 border border-gray-300 rounded-lg bg-gray-50"
          />
        </div>
      </div>

      <div>
        <label className="block text-sm font-medium text-gray-700 mb-2">Skills</label>
        <div className="flex flex-wrap gap-2">
          {profile.workInfo.skills.map((skill, index) => (
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
          {profile.workInfo.certifications.map((cert, index) => (
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
              checked={isEditing ? editingProfile.preferences.notifications.email : profile.preferences.notifications.email}
              onChange={(e) => updatePreferences('notifications', 'email', e.target.checked)}
              disabled={!isEditing}
              className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
            />
            <span className="ml-2 text-sm text-gray-700">Email notifications</span>
          </label>
          <label className="flex items-center">
            <input
              type="checkbox"
              checked={isEditing ? editingProfile.preferences.notifications.sms : profile.preferences.notifications.sms}
              onChange={(e) => updatePreferences('notifications', 'sms', e.target.checked)}
              disabled={!isEditing}
              className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
            />
            <span className="ml-2 text-sm text-gray-700">SMS notifications</span>
          </label>
          <label className="flex items-center">
            <input
              type="checkbox"
              checked={isEditing ? editingProfile.preferences.notifications.pushNotifications : profile.preferences.notifications.pushNotifications}
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
                      editingProfile.preferences.schedule.preferredShifts.includes(shift) : 
                      profile.preferences.schedule.preferredShifts.includes(shift)
                    }
                    onChange={(e) => {
                      const current = isEditing ? editingProfile.preferences.schedule.preferredShifts : profile.preferences.schedule.preferredShifts;
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
                      editingProfile.preferences.schedule.availableDays.includes(day) : 
                      profile.preferences.schedule.availableDays.includes(day)
                    }
                    onChange={(e) => {
                      const current = isEditing ? editingProfile.preferences.schedule.availableDays : profile.preferences.schedule.availableDays;
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

  return (
    <div className="p-6">
      <div className="bg-white rounded-lg shadow-sm">
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
                    className="px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors"
                  >
                    Cancel
                  </button>
                  <button
                    onClick={handleSave}
                    className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
                  >
                    Save Changes
                  </button>
                </>
              ) : (
                <button
                  onClick={() => setIsEditing(true)}
                  className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
                >
                  Edit Profile
                </button>
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
                {tab === 'personal' && '=d Personal Info'}
                {tab === 'work' && '=¼ Work Info'}
                {tab === 'preferences' && '™ Preferences'}
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