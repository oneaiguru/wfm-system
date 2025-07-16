#!/bin/bash

# 🚨 QUICK BDD VERIFICATION SCRIPT
# Test if vacation request workflow actually works

echo "🚨 BDD VACATION REQUEST VERIFICATION"
echo "===================================="

echo ""
echo "STEP 1: Start API Server"
echo "Run in separate terminal:"
echo "cd /Users/m/Documents/wfm/main/project/"
echo "python -m uvicorn src.api.main_simple:app --host 0.0.0.0 --port 8000 --reload"

echo ""
echo "STEP 2: Test API Health"
echo "curl -X GET http://localhost:8000/api/v1/health"

echo ""
echo "STEP 3: Test Employee Loading (BDD Step: Load employee list)"
echo "curl -X GET http://localhost:8000/api/v1/employees"

echo ""
echo "STEP 4: Test Vacation Request Submission (BDD Core Scenario)"
echo 'curl -X POST http://localhost:8000/api/v1/requests/vacation \'
echo '  -H "Content-Type: application/json" \'
echo '  -d '\''{'
echo '    "employee_id": "1",'
echo '    "request_type": "sick_leave",'
echo '    "start_date": "2025-07-15",'
echo '    "end_date": "2025-07-16",'
echo '    "reason": "Простуда и высокая температура"'
echo '  }'\'''

echo ""
echo "STEP 5: Check Database"
echo "psql -U postgres -d wfm_enterprise"
echo "SELECT * FROM employee_requests WHERE request_type = 'sick_leave';"

echo ""
echo "STEP 6: Start UI and Test User Journey"
echo "cd /Users/m/Documents/wfm/main/project/src/ui/"
echo "npm run dev"
echo "Navigate to: http://localhost:3000"
echo "Try to complete vacation request workflow manually"

echo ""
echo "SUCCESS CRITERIA:"
echo "✅ API endpoints respond without errors"
echo "✅ Database stores request data"
echo "✅ UI form accepts Russian text"
echo "✅ User can complete full workflow"

echo ""
echo "FAILURE INDICATORS:"
echo "❌ API connection refused"
echo "❌ Database table missing"
echo "❌ Form submission fails"
echo "❌ Russian text not supported"

echo ""
echo "🎯 GOAL: Verify ONE working BDD scenario before building more components"