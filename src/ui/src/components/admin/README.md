# Admin Components

This directory contains 6 system administration components that extend the WFM system from 20 to 26 working components.

## Components Overview

### 1. SystemSettings.tsx
- **Purpose**: System configuration management
- **API Endpoint**: `GET /api/v1/employees/list`
- **Route**: `/admin/system-settings`
- **Features**:
  - System-wide configuration management
  - Tabbed interface for different config categories
  - Real-time employee statistics
  - Configuration validation and persistence

### 2. RoleManager.tsx
- **Purpose**: User role and permission management
- **API Endpoint**: `GET /api/v1/employees/list`
- **Route**: `/admin/role-manager`
- **Features**:
  - Role creation and management
  - Permission assignment interface
  - User-role mapping
  - System role protection

### 3. AuditLog.tsx
- **Purpose**: System audit trail viewer
- **API Endpoint**: `GET /api/v1/employees/{id}`
- **Route**: `/admin/audit-log`
- **Features**:
  - Comprehensive audit log viewer
  - Advanced filtering and search
  - CSV export functionality
  - Detailed activity tracking

### 4. UserPermissions.tsx
- **Purpose**: Individual user permission management
- **API Endpoint**: `PUT /api/v1/employees/{id}`
- **Route**: `/admin/user-permissions`
- **Features**:
  - Granular permission management
  - User-specific permission overrides
  - Permission categorization (read/write/admin)
  - Bulk permission updates

### 5. ConfigEditor.tsx
- **Purpose**: Bulk configuration management
- **API Endpoint**: `POST /api/v1/employees/bulk`
- **Route**: `/admin/config-editor`
- **Features**:
  - Template-based bulk operations
  - CSV import/export functionality
  - Preview before apply
  - Rollback capabilities

### 6. SystemHealth.tsx
- **Purpose**: System health monitoring
- **API Endpoint**: `GET /api/v1/monitoring/operational`
- **Route**: `/admin/system-health`
- **Features**:
  - Real-time system health monitoring
  - Component status tracking
  - Performance metrics dashboard
  - Auto-refresh capabilities

## Technical Implementation

### API Integration
All components use real API endpoints and handle:
- Error states and loading indicators
- Russian language support
- Proper data validation
- HTTP error handling

### UI Patterns
Components follow established patterns:
- Consistent header layouts
- Tabbed interfaces where appropriate
- Modal dialogs for detailed views
- Search and filtering capabilities
- Responsive design

### Data Flow
- Components fetch data on mount
- Use optimistic UI updates where appropriate
- Handle API errors gracefully
- Provide user feedback for all operations

## Usage

Components are automatically registered in App.tsx and can be accessed via their respective routes:

```typescript
import { 
  SystemSettings, 
  RoleManager, 
  AuditLog, 
  UserPermissions, 
  ConfigEditor, 
  SystemHealth 
} from './components/admin';
```

## Testing

All components have been tested with real API endpoints:
- `/api/v1/employees/list` - Returns employee data ✅
- `/api/v1/monitoring/operational` - Returns system health data ✅
- Error handling for offline/failed states ✅

## Routes

The following routes have been added to App.tsx:
- `/admin/system-settings` - SystemSettings component
- `/admin/role-manager` - RoleManager component  
- `/admin/audit-log` - AuditLog component
- `/admin/user-permissions` - UserPermissions component
- `/admin/config-editor` - ConfigEditor component
- `/admin/system-health` - SystemHealth component