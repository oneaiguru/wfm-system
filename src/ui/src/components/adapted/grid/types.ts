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
  department?: string;
  email?: string;
  phone?: string;
}

export interface Shift {
  id: string;
  employeeId: string;
  date: string;
  startTime: string;
  endTime: string;
  shiftTypeId: 'day' | 'night' | 'overtime' | 'custom';
  status: 'scheduled' | 'confirmed' | 'cancelled' | 'pending';
  duration: number; // in minutes
  color?: string;
  breakDuration?: number;
  notes?: string;
  skills?: string[];
}

export interface GridDate {
  day: number;
  month: number;
  year: number;
  dayName: string;
  isWeekend: boolean;
  isToday: boolean;
  isHoliday?: boolean;
  dateString: string; // YYYY-MM-DD format
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

export interface SchedulePattern {
  id: string;
  name: string;
  pattern: number[]; // e.g., [1,1,1,1,1,0,0] for 5/2
  cycleDays: number;
  description: string;
}

export interface GridSelection {
  cells: Set<string>;
  startCell?: string;
  endCell?: string;
  isSelecting: boolean;
}

export interface GridFilter {
  skills?: string[];
  departments?: string[];
  roles?: string[];
  shiftTypes?: string[];
  searchTerm?: string;
}