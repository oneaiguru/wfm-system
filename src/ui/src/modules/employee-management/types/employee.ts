// Employee Management Types - Translated and adapted from Naumen

export interface Employee {
  id: string;
  employeeId: string;
  personalInfo: {
    firstName: string;
    lastName: string;
    middleName?: string;
    email: string;
    phone: string;
    photo?: string;
    dateOfBirth?: Date;
    emergencyContact?: {
      name: string;
      phone: string;
      relationship: string;
    };
  };
  workInfo: {
    position: string;
    team: Team;
    manager: string;
    hireDate: Date;
    contractType: 'full-time' | 'part-time' | 'contractor';
    salary?: number;
    workLocation: string;
    department: string;
  };
  skills: Skill[];
  status: 'active' | 'inactive' | 'vacation' | 'terminated' | 'probation';
  preferences: {
    preferredShifts: string[];
    notifications: NotificationSettings;
    language: 'ru' | 'en' | 'ky';
    workingHours: {
      start: string;
      end: string;
    };
  };
  performance: {
    averageHandleTime: number;
    callsPerHour: number;
    qualityScore: number;
    adherenceScore: number;
    customerSatisfaction: number;
    lastEvaluation: Date;
  };
  certifications: Certification[];
  metadata: {
    createdAt: Date;
    updatedAt: Date;
    createdBy: string;
    lastModifiedBy: string;
    lastLogin?: Date;
  };
}

export interface Team {
  id: string;
  name: string;
  description?: string;
  color: string;
  managerId: string;
  memberCount: number;
  targetUtilization: number;
}

export interface Skill {
  id: string;
  name: string;
  category: 'technical' | 'communication' | 'product' | 'language' | 'soft-skill';
  level: 1 | 2 | 3 | 4 | 5; // 1=Beginner, 5=Expert
  verified: boolean;
  lastAssessed: Date;
  assessor: string;
  certificationRequired: boolean;
}

export interface Certification {
  id: string;
  name: string;
  issuer: string;
  issueDate: Date;
  expirationDate?: Date;
  status: 'active' | 'expired' | 'pending';
  documentUrl?: string;
}

export interface NotificationSettings {
  email: boolean;
  sms: boolean;
  push: boolean;
  scheduleChanges: boolean;
  announcements: boolean;
  reminders: boolean;
}

export interface EmployeeFilters {
  search: string;
  team: string;
  status: string;
  skill: string;
  position: string;
  sortBy: 'name' | 'position' | 'team' | 'hireDate' | 'performance';
  sortOrder: 'asc' | 'desc';
  showInactive: boolean;
}

export interface BulkAction {
  type: 'change-team' | 'bulk-edit' | 'export-selected' | 'deactivate' | 'activate';
  targetIds: string[];
  data?: any;
}

export interface ViewModes {
  current: 'grid' | 'table' | 'cards';
  available: string[];
}

export interface EmployeeStats {
  total: number;
  active: number;
  vacation: number;
  probation: number;
  inactive: number;
  terminated: number;
}