export interface Employee {
  id: string;
  employeeId: string;
  firstName: string;
  lastName: string;
  fullName: string;
  role: string;
  scheduledHours: number;
  plannedHours: number;
  photo: string;
  skills: string[];
  isActive: boolean;
}

export interface Shift {
  id: string;
  employeeId: string;
  date: string;
  startTime: string;
  endTime: string;
  shiftTypeId: string;
  status: 'scheduled' | 'confirmed' | 'cancelled';
  duration: number;
  color: string;
}

export interface ShiftTemplate {
  id: string;
  name: string;
  startTime: string;
  endTime: string;
  duration: number;
  breakDuration: number;
  color: string;
  type: 'day' | 'night' | 'overtime';
  workPattern: string; // e.g., "5/2", "2/2", "6/1"
  isActive: boolean;
}

export interface ScheduleSchema {
  id: string;
  name: string;
  description: string;
  rules: SchemaRule[];
  isActive: boolean;
  createdAt: string;
}

export interface SchemaRule {
  id: string;
  type: 'minStaff' | 'maxStaff' | 'skillRequired' | 'timeConstraint';
  description: string;
  conditions: Record<string, any>;
  isActive: boolean;
}

export interface ScheduleException {
  id: string;
  date: string;
  type: 'holiday' | 'special' | 'maintenance';
  description: string;
  affectedEmployees: string[];
  isActive: boolean;
}