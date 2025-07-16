# Employee Profile Component

A React component for displaying detailed employee information from the WFM system.

## Overview

The `EmployeeProfile` component fetches and displays employee data from the real API endpoint `/api/v1/employees/{id}`. It provides a clean, professional interface for viewing employee details with proper loading and error states.

## Features

- ✅ **Real API Integration** - Uses actual `/api/v1/employees/{id}` endpoint
- ✅ **Loading States** - Shows skeleton loading animation while fetching data
- ✅ **Error Handling** - Graceful error handling with retry functionality
- ✅ **Russian Localization** - All text and date formatting in Russian
- ✅ **Responsive Design** - Mobile-friendly responsive layout
- ✅ **TypeScript Support** - Fully typed with proper interfaces
- ✅ **Edit Button** - Optional edit functionality for future enhancements

## Usage

```tsx
import { EmployeeProfile } from '@components/employee';

// Basic usage
<EmployeeProfile employeeId="1" />

// With edit functionality
<EmployeeProfile 
  employeeId="1" 
  onEdit={() => console.log('Edit employee')} 
/>
```

## API Response Structure

The component expects the following response structure from `GET /api/v1/employees/{id}`:

```typescript
interface ApiEmployee {
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
```

## Component States

### Loading State
- Shows animated skeleton loading placeholders
- Displays while API request is in progress

### Success State
- Displays employee information in organized sections:
  - Personal Information (name, email, employee ID)
  - Work Information (group, timezone, hire date)
  - Schedule Information (shift times, if available)

### Error State
- Shows error message with retry button
- Handles various error scenarios:
  - Network errors
  - Employee not found (404)
  - Server errors

## Testing

The component includes comprehensive tests covering:
- Loading states
- Successful data display
- Error handling
- Date formatting in Russian locale
- Edit functionality

Run tests with:
```bash
npm test -- EmployeeProfile
```

## Demo

A demo component is available at `EmployeeProfileDemo.tsx` which shows:
- Employee profile for ID 1 (existing employee)
- Error handling for non-existent employee (ID 999)

## Integration Notes

- No authentication required for the `/employees/{id}` endpoint
- Component handles API base URL from environment variables
- Dates are formatted using Russian locale (`ru-RU`)
- All text is in Russian for consistency with the system

## Future Enhancements

- Employee photo display
- Skills and certifications sections
- Performance metrics display
- Schedule visualization
- Edit form integration