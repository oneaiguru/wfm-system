export { default as EmployeeProfile } from './EmployeeProfile';
export { default as EmployeeProfileDemo } from './EmployeeProfileDemo';
export { default as EmployeeSearch } from './EmployeeSearch';
export { default as EmployeeSearchDemo } from './EmployeeSearchDemo';
export type { EmployeeProfileProps } from './EmployeeProfile';
export type { EmployeeSearchProps } from './EmployeeSearch';

// Type definitions for API response (matches actual endpoint structure)
export interface ApiEmployee {
  id: number;
  agent_code: string;
  first_name: string;
  last_name: string;
  email: string;
  employee_id: string | null;
  is_active: boolean;
  primary_group_id: number | null;
  primary_group_name: string | null;
  hire_date: string | null;
  time_zone: string;
  default_shift_start: string | null;
  default_shift_end: string | null;
}