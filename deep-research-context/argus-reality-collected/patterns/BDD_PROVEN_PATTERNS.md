# BDD Proven Patterns - From Working Vacation Request Implementation

## 🎯 Purpose
Document working BDD patterns based on successful vacation request implementation for reuse across all SPECs.

## ✅ Pattern 1: Complete CRUD Workflow

**Context**: Employee submits vacation request for manager approval
**Source**: SPEC-02 vacation request implementation

### Pattern Template:
```gherkin
Given пользователь "{role}" авторизован в системе
When {action} с параметрами "{param1}" и "{param2}"  
Then {result} отображается в {location}
```

### Working Implementation:
- **Database**: vacation_requests table with proper constraints
- **API**: POST /api/v1/requests/vacation with validation
- **UI**: VacationRequestForm.tsx with date picker
- **Verification**: Direct database query + API response

### Reuse Guidelines:
- Replace {role} with user type
- Replace {action} with specific business action
- Replace parameters with domain-specific values
- Always include verification step

## ✅ Pattern 2: Authentication Flow

**Context**: User login with credentials
**Working Elements**:
- JWT token generation
- Database user lookup  
- Session management
- Error handling

### Code Pattern:
```python
def authenticate_user(username, password):
    # 1. Validate input
    # 2. Query database
    # 3. Check password
    # 4. Generate token
    # 5. Return structured response
```

## ✅ Pattern 3: Manager Approval Workflow

**Context**: Manager reviews and approves/rejects requests
**Components**:
- Request listing component
- Approval action buttons
- Status update API
- Notification system

### UI Pattern:
```typescript
interface ApprovalComponentProps {
    requestId: number;
    onApprove: () => void;
    onReject: () => void;
}
```

## 🚀 Usage Instructions

### For New SPECs:
1. **Identify pattern match** (CRUD, Auth, Approval, etc.)
2. **Copy proven structure** from this document
3. **Replace domain variables** with SPEC-specific values
4. **Maintain verification approach** (same testing pattern)
5. **Document new variations** when successful

### Quality Assurance:
- All patterns must have working examples
- Include both success and error cases
- Provide clear adaptation guidelines
- Maintain performance benchmarks