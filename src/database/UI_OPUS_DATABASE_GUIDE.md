# 🎨 DATABASE GUIDE FOR UI-OPUS

## 🚨 CRITICAL: Data Types Matter!

**THE PROBLEM:**
```jsx
// ❌ WRONG - Hardcoded employee IDs
const [employeeId, setEmployeeId] = useState("123");  // Database has UUIDs!
```

**THE FIX:**
```jsx
// ✅ CORRECT - Use actual UUIDs from API
const [employeeId, setEmployeeId] = useState("");  // Will be UUID string like "ead4aaaf-5fcf-4661-aa08-cef7d9132b86"
```

## 📊 What Data You'll Get from API

### GET /api/v1/employees response:
```json
[
  {
    "id": "ead4aaaf-5fcf-4661-aa08-cef7d9132b86",
    "name": "Иван Иванов",
    "email": "ivan.ivanov@test.ru"
  },
  {
    "id": "0a32e7d3-fcee-4f2e-aeb1-c8ca093d7212", 
    "name": "Петр Петров",
    "email": "petr.petrov@test.ru"
  }
]
```

### POST /api/v1/requests/vacation expects:
```json
{
  "employee_id": "ead4aaaf-5fcf-4661-aa08-cef7d9132b86",  // UUID string!
  "start_date": "2025-02-01",  // YYYY-MM-DD format
  "end_date": "2025-02-07"
}
```

## 🔧 Correct UI Implementation

### 1. Vacation Request Form (Working Example)
```tsx
import React, { useState, useEffect } from 'react';

interface Employee {
  id: string;  // UUID as string
  name: string;
  email: string;
}

const VacationRequestForm: React.FC = () => {
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [selectedEmployeeId, setSelectedEmployeeId] = useState<string>('');
  const [startDate, setStartDate] = useState<string>('');
  const [endDate, setEndDate] = useState<string>('');
  const [loading, setLoading] = useState<boolean>(false);
  const [error, setError] = useState<string>('');
  const [success, setSuccess] = useState<string>('');

  // Load real employees on mount
  useEffect(() => {
    fetch('/api/v1/employees')
      .then(res => {
        if (!res.ok) throw new Error(`Failed to load employees: ${res.status}`);
        return res.json();
      })
      .then((data: Employee[]) => {
        setEmployees(data);
        // Don't hardcode - wait for user selection
      })
      .catch(err => {
        setError(`Ошибка загрузки сотрудников: ${err.message}`);
      });
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setSuccess('');
    setLoading(true);

    try {
      const response = await fetch('/api/v1/requests/vacation', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          employee_id: selectedEmployeeId,  // UUID string from dropdown
          start_date: startDate,
          end_date: endDate
        })
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.detail || `Ошибка: ${response.status}`);
      }

      const result = await response.json();
      setSuccess(`Заявка на отпуск создана успешно! ID: ${result.id}`);
      
      // Reset form
      setSelectedEmployeeId('');
      setStartDate('');
      setEndDate('');
      
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Неизвестная ошибка');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="vacation-request-form">
      <h2>Заявка на отпуск</h2>

      {error && (
        <div className="alert alert-danger">{error}</div>
      )}

      {success && (
        <div className="alert alert-success">{success}</div>
      )}

      <form onSubmit={handleSubmit}>
        <div className="form-group">
          <label htmlFor="employee">Сотрудник:</label>
          <select
            id="employee"
            value={selectedEmployeeId}
            onChange={(e) => setSelectedEmployeeId(e.target.value)}
            required
            className="form-control"
          >
            <option value="">-- Выберите сотрудника --</option>
            {employees.map(emp => (
              <option key={emp.id} value={emp.id}>
                {emp.name} ({emp.email})
              </option>
            ))}
          </select>
        </div>

        <div className="form-group">
          <label htmlFor="startDate">Дата начала:</label>
          <input
            type="date"
            id="startDate"
            value={startDate}
            onChange={(e) => setStartDate(e.target.value)}
            min={new Date().toISOString().split('T')[0]}
            required
            className="form-control"
          />
        </div>

        <div className="form-group">
          <label htmlFor="endDate">Дата окончания:</label>
          <input
            type="date"
            id="endDate"
            value={endDate}
            onChange={(e) => setEndDate(e.target.value)}
            min={startDate || new Date().toISOString().split('T')[0]}
            required
            className="form-control"
          />
        </div>

        <button 
          type="submit" 
          disabled={loading}
          className="btn btn-primary"
        >
          {loading ? 'Отправка...' : 'Отправить заявку'}
        </button>
      </form>
    </div>
  );
};

export default VacationRequestForm;
```

### 2. Employee Selector Component
```tsx
interface EmployeeSelectorProps {
  value: string;  // UUID string
  onChange: (employeeId: string) => void;
  required?: boolean;
}

const EmployeeSelector: React.FC<EmployeeSelectorProps> = ({ 
  value, 
  onChange, 
  required = false 
}) => {
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch('/api/v1/employees')
      .then(res => res.json())
      .then(setEmployees)
      .finally(() => setLoading(false));
  }, []);

  if (loading) return <div>Загрузка сотрудников...</div>;

  return (
    <select 
      value={value} 
      onChange={(e) => onChange(e.target.value)}
      required={required}
    >
      <option value="">-- Выберите сотрудника --</option>
      {employees.map(emp => (
        <option key={emp.id} value={emp.id}>
          {emp.name}
        </option>
      ))}
    </select>
  );
};
```

## 📋 Data Format Reference

### Employee Data:
- **id**: UUID string (36 characters) - "ead4aaaf-5fcf-4661-aa08-cef7d9132b86"
- **name**: Full name with Russian text - "Иван Иванов"
- **email**: Valid email format - "ivan.ivanov@test.ru"

### Date Formats:
- **Always use**: YYYY-MM-DD (ISO format)
- **Example**: "2025-02-01"
- **Input type="date"** handles this automatically

### Status Values:
- pending - В ожидании
- approved - Одобрено
- rejected - Отклонено
- cancelled - Отменено

## 🧪 Testing Your Components

### Manual Testing Checklist:
```markdown
- [ ] Employee dropdown loads real employees
- [ ] Russian names display correctly (Иван, Мария, etc.)
- [ ] Form submits with UUID employee_id
- [ ] Success message shows after submission
- [ ] Error messages display for invalid data
- [ ] Date validation works (end > start)
- [ ] Form resets after successful submission
```

### Test Data Available:
```javascript
// Use these real employee IDs for testing
const testEmployees = [
  {
    id: "ead4aaaf-5fcf-4661-aa08-cef7d9132b86",
    name: "Иван Иванов"
  },
  {
    id: "0a32e7d3-fcee-4f2e-aeb1-c8ca093d7212",
    name: "Петр Петров"
  }
];
```

## ❌ Common UI Mistakes to Avoid

1. **Hardcoding employee IDs** - Always load from API
2. **Using number inputs for IDs** - Employee IDs are UUID strings
3. **Wrong date format** - Use YYYY-MM-DD, not DD/MM/YYYY
4. **Missing error handling** - Always handle API failures
5. **No loading states** - Show loading while fetching data
6. **Ignoring Russian text** - Ensure UTF-8 support

## 🎨 UI Best Practices

### 1. Always Test API First:
```javascript
// Before building UI, test API manually
fetch('/api/v1/employees')
  .then(res => res.json())
  .then(console.log);  // See actual data structure
```

### 2. Handle All States:
- Loading state while fetching
- Error state for failures  
- Success state after submission
- Empty state if no data

### 3. Validate Before Submit:
```javascript
const validateForm = () => {
  if (!selectedEmployeeId) {
    setError('Выберите сотрудника');
    return false;
  }
  if (new Date(endDate) <= new Date(startDate)) {
    setError('Дата окончания должна быть после даты начала');
    return false;
  }
  return true;
};
```

## 📊 Complete Data Flow

1. **User opens form** → Load employees from API
2. **User selects employee** → Store UUID string in state
3. **User picks dates** → Validate end > start
4. **User submits** → POST with UUID employee_id
5. **API responds** → Show success/error message
6. **Success** → Reset form for next request

## 💡 Key Takeaways

1. **Employee IDs are UUIDs**, not numbers
2. **Load real data from API**, don't hardcode
3. **Support Russian text** throughout
4. **Handle all error cases** gracefully
5. **Test with real employee IDs** from database

The database has 20+ real employees with Russian names. Your UI just needs to display and submit them correctly!