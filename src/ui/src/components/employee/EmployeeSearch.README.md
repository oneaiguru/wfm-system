# EmployeeSearch Component

A React component for searching and browsing employees using the real WFM API endpoint.

## Features

✅ **Real-time Search**: Debounced search with 300ms delay  
✅ **API Integration**: Uses GET /api/v1/employees/search/query  
✅ **Filtering**: Active/inactive status, result limit  
✅ **Pagination**: Navigation between result pages  
✅ **Error Handling**: Graceful error states and retry functionality  
✅ **Click to View**: Integration with EmployeeProfile component  
✅ **Responsive**: Mobile-friendly design  
✅ **Multilingual**: Supports Russian/English content  

## API Endpoint

```
GET /api/v1/employees/search/query
```

### Parameters
- `q` (required): Search query, minimum 2 characters
- `active_only` (optional): Boolean, defaults to true
- `limit` (optional): Number of results, 1-50, defaults to 10

### Response
```typescript
interface EmployeeSearchResult {
  id: number;
  agent_code: string;
  first_name: string;
  last_name: string;
  email: string | null;
  is_active: boolean;
}
```

## Usage

### Basic Usage
```tsx
import { EmployeeSearch } from '@/components/employee';

function MyComponent() {
  return <EmployeeSearch />;
}
```

### With Selection Handler
```tsx
import { EmployeeSearch } from '@/components/employee';

function MyComponent() {
  const handleEmployeeSelect = (employeeId: number) => {
    console.log('Selected employee:', employeeId);
    // Navigate to employee profile or update state
  };

  return (
    <EmployeeSearch onEmployeeSelect={handleEmployeeSelect} />
  );
}
```

### Full Integration with Profile
```tsx
import React, { useState } from 'react';
import { EmployeeSearch, EmployeeProfile } from '@/components/employee';

function EmployeeManager() {
  const [selectedEmployeeId, setSelectedEmployeeId] = useState<number | null>(null);

  if (selectedEmployeeId) {
    return (
      <>
        <button onClick={() => setSelectedEmployeeId(null)}>
          Back to Search
        </button>
        <EmployeeProfile employeeId={selectedEmployeeId.toString()} />
      </>
    );
  }

  return (
    <EmployeeSearch onEmployeeSelect={setSelectedEmployeeId} />
  );
}
```

## Props

```typescript
interface EmployeeSearchProps {
  onEmployeeSelect?: (employeeId: number) => void;
  className?: string;
}
```

### Props Details

- **onEmployeeSelect** (optional): Callback function called when user clicks on a search result
- **className** (optional): Additional CSS classes for the component container

## Component Features

### Search Functionality
- **Minimum Query Length**: Requires 2+ characters
- **Debounced Input**: 300ms delay to reduce API calls
- **Real-time Results**: Updates as user types
- **Search Scope**: Name, email, agent code, full name

### Filters
- **Status Filter**: Active only (default) or all employees
- **Result Limit**: 5, 10, 25, or 50 results per page
- **Collapsible Panel**: Hide/show filters to save space

### Result Display
- **Employee Cards**: Name, agent code, email, status badge
- **Status Indicators**: Green (active) / Red (inactive) badges
- **Click Actions**: Eye icon and click handler for selection
- **Empty States**: Helpful messages for no results

### Error Handling
- **Network Errors**: Displays error message with retry button
- **Validation Errors**: Shows API validation messages
- **Loading States**: Spinner during search requests

### User Experience
- **Responsive Design**: Works on mobile and desktop
- **Loading Indicators**: Shows spinner during API calls
- **Pagination**: Next/Previous buttons when more results available
- **Result Counter**: Shows number of results found

## Testing

### Manual Testing Scenarios

1. **Basic Search**
   ```bash
   # Test with existing employee
   curl "http://localhost:8000/api/v1/employees/search/query?q=test"
   ```

2. **Filter Testing**
   ```bash
   # Test with inactive employees
   curl "http://localhost:8000/api/v1/employees/search/query?q=test&active_only=false"
   ```

3. **Pagination Testing**
   ```bash
   # Test with limited results
   curl "http://localhost:8000/api/v1/employees/search/query?q=a&limit=5"
   ```

4. **Error Testing**
   ```bash
   # Test validation error (too short)
   curl "http://localhost:8000/api/v1/employees/search/query?q=a"
   ```

### Unit Tests
Run the test suite:
```bash
npm run test EmployeeSearch
```

## File Structure

```
src/ui/src/components/employee/
├── EmployeeSearch.tsx           # Main component
├── EmployeeSearchDemo.tsx       # Demo with EmployeeProfile integration
├── __tests__/
│   └── EmployeeSearch.test.tsx  # Unit tests
├── index.ts                     # Exports
└── EmployeeSearch.README.md     # This documentation
```

## Integration Points

### With EmployeeProfile
```tsx
// When user clicks on search result
const handleEmployeeSelect = (employeeId: number) => {
  // Can navigate to profile page or show in modal
  setSelectedEmployee(employeeId);
};
```

### With Routing
```tsx
import { useNavigate } from 'react-router-dom';

const navigate = useNavigate();
const handleEmployeeSelect = (employeeId: number) => {
  navigate(`/employees/${employeeId}`);
};
```

### With State Management
```tsx
import { useDispatch } from 'react-redux';

const dispatch = useDispatch();
const handleEmployeeSelect = (employeeId: number) => {
  dispatch(selectEmployee(employeeId));
};
```

## Customization

### Styling
The component uses Tailwind CSS classes. Customize by:
1. Overriding classes via the `className` prop
2. Modifying the component's internal classes
3. Using CSS modules or styled-components

### API Configuration
Environment variables:
```bash
REACT_APP_API_URL=http://localhost:8000/api/v1
```

### Debounce Timing
Modify the debounce delay in the component:
```tsx
const timer = setTimeout(() => {
  setDebouncedQuery(searchQuery);
}, 300); // Change this value
```

## Performance Considerations

- **Debounced Search**: Reduces API calls during typing
- **Pagination**: Limits results to prevent large data transfers
- **Error Caching**: Prevents repeated failed requests
- **Loading States**: Provides user feedback during requests

## Browser Support

- Modern browsers with ES6+ support
- React 18+
- Requires fetch API support

## Demo

See `EmployeeSearchDemo.tsx` for a complete integration example with the EmployeeProfile component.