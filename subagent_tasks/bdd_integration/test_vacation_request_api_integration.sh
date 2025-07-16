#!/bin/bash
# BDD Integration Test: Complete Vacation Request Flow

echo "🧪 BDD Integration Test: Complete Vacation Request Flow"
echo "======================================================"

# Get test employee UUID
EMPLOYEE_UUID=$(psql -U postgres -d wfm_enterprise -t -c "
SELECT id FROM employees 
WHERE first_name = 'Иван' AND last_name = 'Иванов' 
LIMIT 1" | tr -d ' ')

if [ -z "$EMPLOYEE_UUID" ]; then
    echo "❌ FAIL: Test employee 'Иван Иванов' not found"
    exit 1
fi

echo "✅ Employee found: $EMPLOYEE_UUID"

# Test 1: Create vacation request via API
echo "🔄 Testing vacation request creation..."
RESPONSE=$(curl -s -X POST http://localhost:8000/api/v1/requests/vacation \
  -H "Content-Type: application/json" \
  -d "{
    \"employee_id\": \"$EMPLOYEE_UUID\",
    \"start_date\": \"2025-08-15\",
    \"end_date\": \"2025-08-29\",
    \"reason\": \"BDD Integration Test - Семейный отпуск\"
  }")

REQUEST_ID=$(echo "$RESPONSE" | jq -r '.request_id')

if [ "$REQUEST_ID" != "null" ] && [ ! -z "$REQUEST_ID" ]; then
    echo "✅ PASS: Vacation request created - ID: $REQUEST_ID"
else
    echo "❌ FAIL: Vacation request creation failed"
    echo "Response: $RESPONSE"
    exit 1
fi

# Test 2: Check request appears in pending queue
echo "🔄 Testing pending requests visibility..."
PENDING_RESPONSE=$(curl -s http://localhost:8000/api/v1/requests/pending)
FOUND_REQUEST=$(echo "$PENDING_RESPONSE" | jq ".[] | select(.request_id == \"$REQUEST_ID\")")

if [ ! -z "$FOUND_REQUEST" ]; then
    echo "✅ PASS: Request visible in pending queue"
    EMPLOYEE_NAME=$(echo "$FOUND_REQUEST" | jq -r '.employee_name')
    echo "   Employee: $EMPLOYEE_NAME"
else
    echo "❌ FAIL: Request not found in pending queue"
    echo "Pending requests: $PENDING_RESPONSE"
    exit 1
fi

# Test 3: Manager approves request
echo "🔄 Testing request approval..."
APPROVAL_RESPONSE=$(curl -s -X PUT "http://localhost:8000/api/v1/requests/approve/$REQUEST_ID" \
  -H "Content-Type: application/json" \
  -d '{"action": "approve", "comments": "Одобрено - BDD Test"}')

APPROVAL_STATUS=$(echo "$APPROVAL_RESPONSE" | jq -r '.status')

if [ "$APPROVAL_STATUS" = "approved" ]; then
    echo "✅ PASS: Request approved successfully"
else
    echo "❌ FAIL: Request approval failed"
    echo "Response: $APPROVAL_RESPONSE"
    exit 1
fi

# Test 4: Verify employee can see approved request
echo "🔄 Testing employee request history..."
HISTORY_RESPONSE=$(curl -s "http://localhost:8000/api/v1/requests/vacation/employee/$EMPLOYEE_UUID")
APPROVED_REQUEST=$(echo "$HISTORY_RESPONSE" | jq ".requests[] | select(.request_id == \"$REQUEST_ID\" and .status == \"approved\")")

if [ ! -z "$APPROVED_REQUEST" ]; then
    echo "✅ PASS: Employee can see approved request in history"
    DURATION=$(echo "$APPROVED_REQUEST" | jq -r '.duration_days')
    echo "   Duration: $DURATION days"
else
    echo "❌ FAIL: Approved request not found in employee history"
    exit 1
fi

# Test 5: Database consistency check
echo "🔄 Testing database consistency..."
DB_CHECK=$(psql -U postgres -d wfm_enterprise -t -c "
SELECT COUNT(*) FROM vacation_requests vr
JOIN employees e ON vr.employee_id = e.id
WHERE vr.id = $REQUEST_ID
AND vr.status = 'approved'
AND e.first_name = 'Иван'
AND e.last_name = 'Иванов'
AND vr.reason LIKE '%BDD Integration Test%'" | tr -d ' ')

if [ "$DB_CHECK" = "1" ]; then
    echo "✅ PASS: Database consistency verified"
else
    echo "❌ FAIL: Database consistency check failed"
    exit 1
fi

echo ""
echo "🎊 BDD INTEGRATION TEST COMPLETE - ALL TESTS PASSED!"
echo "=============================================="
echo "✅ Vacation request creation: WORKING"
echo "✅ Manager pending queue: WORKING" 
echo "✅ Request approval workflow: WORKING"
echo "✅ Employee request history: WORKING"
echo "✅ Database consistency: VERIFIED"
echo "✅ Russian text support: VERIFIED"
echo ""
echo "🎯 BDD Scenario 'Employee submits vacation request' is FULLY IMPLEMENTED"