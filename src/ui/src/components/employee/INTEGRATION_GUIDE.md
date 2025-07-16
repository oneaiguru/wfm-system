# EmployeeProfile Component Integration Guide

## Quick Start

The EmployeeProfile component is now ready for use in your WFM application.

### 1. Import the Component

```tsx
// Import from the employee module
import { EmployeeProfile } from '@components/employee';

// Or import directly
import EmployeeProfile from './components/employee/EmployeeProfile';
```

### 2. Basic Usage

```tsx
function EmployeePage() {
  return (
    <div>
      <h1>Employee Details</h1>
      <EmployeeProfile employeeId="1" />
    </div>
  );
}
```

### 3. With Edit Functionality

```tsx
function EmployeeManagement() {
  const handleEdit = () => {
    // Navigate to edit form or open modal
    console.log('Open edit dialog');
  };

  return (
    <EmployeeProfile 
      employeeId="1" 
      onEdit={handleEdit} 
    />
  );
}
```

## Integration Points

### Router Integration

Add to your React Router:

```tsx
import { EmployeeProfile } from '@components/employee';

// In your router configuration
<Route 
  path="/employees/:id" 
  element={<EmployeeProfile employeeId={params.id} />} 
/>
```

### Modal Integration

Use in a modal dialog:

```tsx
import { Modal } from '@components/common';
import { EmployeeProfile } from '@components/employee';

function EmployeeModal({ employeeId, isOpen, onClose }) {
  return (
    <Modal isOpen={isOpen} onClose={onClose}>
      <EmployeeProfile employeeId={employeeId} />
    </Modal>
  );
}
```

## API Requirements

### Endpoint
- **URL**: `GET /api/v1/employees/{id}`
- **Authentication**: None required (public endpoint)
- **Response**: JSON object with employee data

### Expected Response Format
```json
{
  "id": 1,
  "agent_code": "AGT001",
  "first_name": "Анна",
  "last_name": "Кузнецова",
  "email": "anna.updated@wfm.com",
  "employee_id": null,
  "is_active": true,
  "primary_group_id": null,
  "primary_group_name": null,
  "hire_date": null,
  "time_zone": "Europe/Moscow",
  "default_shift_start": null,
  "default_shift_end": null
}
```

## Styling & Customization

The component uses Tailwind CSS classes. To customize:

### Override Styles
```tsx
// Wrap in a custom container
<div className="custom-employee-profile">
  <EmployeeProfile employeeId="1" />
</div>
```

### Custom CSS
```css
.custom-employee-profile {
  /* Your custom styles */
}

.custom-employee-profile .bg-gradient-to-r {
  /* Override header gradient */
  background: linear-gradient(to right, #your-color-1, #your-color-2);
}
```

## Error Handling

The component handles common error scenarios:

- **Network errors**: Shows retry button
- **404 Not Found**: Employee not found message
- **500 Server Error**: Generic error message
- **Loading timeout**: Automatic retry after delay

## Testing in Development

### Demo Page
Access the demo at: `http://localhost:3002/employee-profile-demo`

### Test with Real Data
```bash
# Test API endpoint directly
curl http://localhost:8000/api/v1/employees/1

# Test with different employee IDs
curl http://localhost:8000/api/v1/employees/2
curl http://localhost:8000/api/v1/employees/999  # Should return 404
```

## Performance Considerations

- Component fetches data on mount and when employeeId changes
- Uses React.useState for local state management
- No caching implemented (consider adding if needed)
- Optimized for mobile with responsive design

## Future Enhancements

Ready for extension with:
- Employee photo upload/display
- Skills matrix visualization  
- Performance metrics charts
- Schedule timeline view
- Edit form integration
- Audit trail display

## Troubleshooting

### Common Issues

**Component not rendering:**
- Check that API server is running on port 8000
- Verify employee ID exists in database
- Check browser console for errors

**Styling issues:**
- Ensure Tailwind CSS is properly configured
- Check that Lucide React icons are installed

**TypeScript errors:**
- Verify all type definitions are imported correctly
- Check that React types are installed

### Debug Mode

Enable debug logging:
```tsx
// The component already includes console.log statements
// Check browser developer tools console for API calls
```