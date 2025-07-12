// Employee Management Module - Admin CRUD Operations
export { default as EmployeeManagementPortal } from './components/EmployeeManagementPortal';

// CRUD Components
export { default as EmployeeListContainer } from './components/crud/EmployeeListContainer';
export { default as QuickAddEmployee } from './components/crud/QuickAddEmployee';

// Admin Components  
export { default as EmployeePhotoGallery } from './components/admin/EmployeePhotoGallery';
export { default as EmployeeStatusManager } from './components/admin/EmployeeStatusManager';
export { default as CertificationTracker } from './components/admin/CertificationTracker';

// Analytics Components
export { default as PerformanceMetricsView } from './components/analytics/PerformanceMetricsView';

// Types
export * from './types/employee';

// Module exports for easy integration
export * from './components/EmployeeManagementPortal';
export * from './components/crud/EmployeeListContainer';
export * from './components/crud/QuickAddEmployee';
export * from './components/admin/EmployeePhotoGallery';
export * from './components/admin/EmployeeStatusManager';
export * from './components/admin/CertificationTracker';
export * from './components/analytics/PerformanceMetricsView';