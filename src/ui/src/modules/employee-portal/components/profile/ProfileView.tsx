import React, { useState } from 'react';
import { User, Mail, Phone, MapPin, Settings, Edit, Save, X } from 'lucide-react';

interface Employee {
  id: string;
  name: string;
  position: string;
  team: string;
  email: string;
  phone: string;
  skills: string[];
  preferences?: {
    preferredShifts: string[];
    preferredDays: string[];
    notifications: boolean;
    emailUpdates: boolean;
  };
}

interface ProfileViewProps {
  employee: Employee;
  className?: string;
}

const ProfileView: React.FC<ProfileViewProps> = ({ employee, className = '' }) => {
  const [editing, setEditing] = useState(false);
  const [formData, setFormData] = useState(employee);

  const handleSave = () => {
    // Save logic here
    setEditing(false);
  };

  const handleCancel = () => {
    setFormData(employee);
    setEditing(false);
  };

  return (
    <div className={`space-y-6 ${className}`}>
      {/* Header */}
      <div className="flex items-center justify-between">
        <h2 className="text-2xl font-bold text-gray-900">My Profile</h2>
        <div className="flex items-center gap-2">
          {editing ? (
            <>
              <button
                onClick={handleSave}
                className="flex items-center gap-2 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors"
              >
                <Save className="w-4 h-4" />
                Save
              </button>
              <button
                onClick={handleCancel}
                className="flex items-center gap-2 px-4 py-2 bg-gray-600 text-white rounded-lg hover:bg-gray-700 transition-colors"
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

      {/* Profile Card */}
      <div className="bg-white rounded-lg border p-6">
        <div className="flex items-start gap-6">
          <div className="w-24 h-24 bg-blue-100 rounded-full flex items-center justify-center">
            <User className="w-12 h-12 text-blue-600" />
          </div>
          
          <div className="flex-1">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Name</label>
                {editing ? (
                  <input
                    type="text"
                    value={formData.name}
                    onChange={(e) => setFormData({...formData, name: e.target.value})}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                ) : (
                  <p className="text-gray-900 font-medium">{employee.name}</p>
                )}
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Position</label>
                <p className="text-gray-900">{employee.position}</p>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Team</label>
                <p className="text-gray-900">{employee.team}</p>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Employee ID</label>
                <p className="text-gray-900">{employee.id}</p>
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
                value={formData.email}
                onChange={(e) => setFormData({...formData, email: e.target.value})}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            ) : (
              <div className="flex items-center gap-2 text-gray-900">
                <Mail className="w-4 h-4" />
                {employee.email}
              </div>
            )}
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Phone</label>
            {editing ? (
              <input
                type="tel"
                value={formData.phone}
                onChange={(e) => setFormData({...formData, phone: e.target.value})}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            ) : (
              <div className="flex items-center gap-2 text-gray-900">
                <Phone className="w-4 h-4" />
                {employee.phone}
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Skills */}
      <div className="bg-white rounded-lg border p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Skills & Qualifications</h3>
        <div className="flex flex-wrap gap-2">
          {employee.skills.map((skill, index) => (
            <span
              key={index}
              className="px-3 py-1 bg-blue-100 text-blue-800 rounded-full text-sm"
            >
              {skill}
            </span>
          ))}
        </div>
      </div>

      {/* Preferences */}
      <div className="bg-white rounded-lg border p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Preferences</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Preferred Shifts</label>
            <div className="space-y-2">
              {['Morning', 'Day', 'Evening', 'Night'].map(shift => (
                <label key={shift} className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    checked={employee.preferences?.preferredShifts.includes(shift)}
                    disabled={!editing}
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
              <label className="flex items-center gap-2">
                <input
                  type="checkbox"
                  checked={employee.preferences?.notifications}
                  disabled={!editing}
                  className="rounded"
                />
                <span className="text-sm">Push notifications</span>
              </label>
              <label className="flex items-center gap-2">
                <input
                  type="checkbox"
                  checked={employee.preferences?.emailUpdates}
                  disabled={!editing}
                  className="rounded"
                />
                <span className="text-sm">Email updates</span>
              </label>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ProfileView;