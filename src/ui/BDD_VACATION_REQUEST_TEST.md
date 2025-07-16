# 🚨 BDD VACATION REQUEST WORKFLOW TEST

## **IMMEDIATE ACTION**: Test ONE working BDD scenario

### **BDD Scenario**: Create Request for Time Off (02-employee-requests.feature:12-24)

```gherkin
Given I am logged into the employee portal as an operator
When I navigate to the "Календарь" tab
And I click the "Создать" button  
And I select request type "больничный"
And I fill in the corresponding fields
And I submit the request
Then the request should be created
And I should see the request status on the "Заявки" page
```

## **STEP 1 (TODAY)**: Test vacation request flow

### **Start Development Environment**:
```bash
# Terminal 1: Start UI
cd /Users/m/Documents/wfm/main/project/src/ui/
npm run dev

# Terminal 2: Start API  
cd /Users/m/Documents/wfm/main/project/
python -m uvicorn src.api.main_simple:app --host 0.0.0.0 --port 8000 --reload

# Terminal 3: Check Database
psql -U postgres -d wfm_enterprise
\dt  # List tables
```

### **Quick API Verification**:
```bash
# Test employee loading
curl -X GET http://localhost:8000/api/v1/employees

# Test vacation request endpoint
curl -X POST http://localhost:8000/api/v1/requests/vacation \
  -H "Content-Type: application/json" \
  -d '{
    "employee_id": "1",
    "request_type": "sick_leave", 
    "start_date": "2025-07-15",
    "end_date": "2025-07-16",
    "reason": "Простуда и высокая температура"
  }'
```

## **VERIFICATION CHECKLIST**:

- [ ] RequestForm.tsx loads without errors
- [ ] API endpoints respond (GET /employees, POST /requests/vacation)
- [ ] Database tables exist (employee_requests, employees)
- [ ] Form accepts Russian text input
- [ ] Submission creates database record
- [ ] User can see request status

## **EXPECTED OUTCOME**:
**IF WORKING**: Document evidence and move to next BDD scenario
**IF BROKEN**: Stop scaling, fix integration issues first

## **KEY FILES TO CHECK**:
- `/modules/employee-portal/components/requests/RequestForm.tsx` (Component)
- `/services/realRequestService.ts` (API integration)
- BDD spec: `/intelligence/argus/bdd-specifications/02-employee-requests.feature`

**STATUS**: 🚨 **START HERE** - Test this workflow RIGHT NOW