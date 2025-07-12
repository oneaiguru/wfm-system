// Mobile Personal Cabinet Types - BDD Specification
// Based on: 14-mobile-personal-cabinet.feature

export interface MobileUser {
  id: string;
  name: string;
  email: string;
  role: string;
  department: string;
  photo?: string;
  biometricEnabled?: boolean;
}

export interface MobileShift {
  id: string;
  date: string;
  startTime: string;
  endTime: string;
  breakTime?: string;
  lunchTime?: string;
  type: 'work' | 'vacation' | 'sick' | 'training' | 'meeting';
  status: 'scheduled' | 'confirmed' | 'in-progress' | 'completed';
  location?: string;
}

export interface MobileRequest {
  id: string;
  type: 'sick' | 'dayoff' | 'vacation' | 'shift-exchange';
  status: 'draft' | 'pending' | 'approved' | 'rejected';
  startDate: string;
  endDate: string;
  reason?: string;
  comment?: string;
  createdAt: string;
  updatedAt: string;
}

export interface MobileNotification {
  id: string;
  type: 'schedule' | 'request' | 'announcement' | 'reminder';
  title: string;
  message: string;
  timestamp: string;
  read: boolean;
  actionUrl?: string;
  priority: 'low' | 'medium' | 'high';
}

export interface OfflineData {
  schedules: MobileShift[];
  requests: MobileRequest[];
  notifications: MobileNotification[];
  lastSync: string;
  pendingActions: any[];
}

export interface MobileSettings {
  theme: 'light' | 'dark' | 'auto';
  language: 'ru' | 'en';
  timeFormat: '12h' | '24h';
  notifications: {
    scheduleChanges: boolean;
    requestUpdates: boolean;
    reminders: boolean;
    announcements: boolean;
  };
  calendarView: 'month' | 'week' | '4day' | 'day';
}