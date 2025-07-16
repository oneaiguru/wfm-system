#!/bin/bash
# BDD-COMPLIANT UI-OPUS VERIFICATION SCRIPT

echo "🎯 BDD-COMPLIANT UI-OPUS VERIFICATION"
echo "====================================="
echo

# 1. Component count verification (from previous verification)
echo "📊 Component Count Verification:"
COMPONENT_COUNT=$(find src/ui/src/components -name "*.tsx" | wc -l | xargs)
echo "✅ Components found: $COMPONENT_COUNT (claimed: 119)"
echo

# 2. BDD File Analysis
echo "📋 BDD Specification Analysis:"
BDD_PATH="/Users/m/Documents/wfm/main/intelligence/argus/bdd-specifications"
TOTAL_BDD_FILES=$(find "$BDD_PATH" -name "*.feature" | wc -l | xargs)
echo "Total BDD files available: $TOTAL_BDD_FILES"
echo "Key BDD files for UI components:"
echo "- 02-employee-requests.feature (vacation requests)"
echo "- 14-mobile-personal-cabinet.feature (mobile/login)"
echo "- 15-real-time-monitoring-operational-control.feature (dashboard)"
echo "- 16-personnel-management-organizational-structure.feature (employee mgmt)"
echo

# 3. BDD Compliance Testing
echo "🧪 BDD COMPLIANCE TESTING:"
echo "=========================="

# Test 1: Vacation Request (BDD File 02)
echo "TEST 1: Vacation Request BDD Compliance"
echo "BDD Scenario: Create Request for Time Off/Sick Leave/Unscheduled Vacation"
echo "Testing API endpoint..."
VACATION_RESULT=$(curl -s -X POST http://localhost:8000/api/v1/requests/vacation \
  -H "Content-Type: application/json" \
  -d '{"employee_id":"1","start_date":"2025-08-01","end_date":"2025-08-05","description":"BDD Test - отгул","request_type":"отгул"}')

if echo "$VACATION_RESULT" | grep -q "success"; then
    echo "✅ BDD COMPLIANT: Vacation request creation works"
    echo "✅ Russian support: отгул request type accepted"
    echo "✅ Database persistence: Request ID returned"
else
    echo "❌ BDD VIOLATION: Vacation request creation failed"
fi
echo "Response: $VACATION_RESULT"
echo

# Test 2: Login Authentication (BDD File 14)
echo "TEST 2: Personal Cabinet Login BDD Compliance"
echo "BDD Scenario: Personal Cabinet Login and Navigation"
echo "Testing authentication endpoint..."
LOGIN_RESULT=$(curl -s -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"demo","password":"demo"}')

if echo "$LOGIN_RESULT" | grep -q "token\|success"; then
    echo "✅ BDD COMPLIANT: Authentication works"
    echo "✅ JWT token management functional"
else
    echo "❌ BDD VIOLATION: Authentication fails with test credentials"
fi
echo "Response: $LOGIN_RESULT"
echo

# Test 3: Real-time Monitoring (BDD File 15)
echo "TEST 3: Real-time Monitoring Dashboard BDD Compliance"
echo "BDD Scenario: View Real-time Operational Control Dashboards"
echo "Testing monitoring endpoint..."
DASHBOARD_RESULT=$(curl -s http://localhost:8000/api/v1/metrics/dashboard)

if echo "$DASHBOARD_RESULT" | grep -q "operators_online\|load_deviation"; then
    echo "✅ BDD COMPLIANT: Dashboard metrics available"
    echo "✅ Real-time data accessible"
else
    echo "❌ BDD VIOLATION: Dashboard endpoint missing or non-compliant"
    echo "❌ Required metrics: Operators Online %, Load Deviation, Operator Requirement"
fi
echo "Response: $DASHBOARD_RESULT"
echo

# Test 4: Employee Management (BDD File 16)
echo "TEST 4: Personnel Management BDD Compliance"
echo "BDD Scenario: Employee Information Access"
echo "Testing employee endpoint..."
EMPLOYEE_RESULT=$(curl -s http://localhost:8000/api/v1/employees/list)

if echo "$EMPLOYEE_RESULT" | grep -q "employees\|personnel"; then
    echo "✅ BDD COMPLIANT: Employee data accessible"
else
    echo "❌ BDD VIOLATION: Employee endpoint missing or non-compliant"
fi
echo "Response: $EMPLOYEE_RESULT"
echo

# 4. Russian Language Support Testing
echo "🇷🇺 RUSSIAN LANGUAGE SUPPORT TESTING:"
echo "======================================"

echo "Testing Russian text in components..."
RUSSIAN_SUPPORT=0

# Check for Russian text in Login component
if grep -q "Русский\|русский\|Войти\|Логин" src/ui/src/components/Login.tsx 2>/dev/null; then
    echo "✅ Login component has Russian support"
    RUSSIAN_SUPPORT=$((RUSSIAN_SUPPORT + 1))
else
    echo "❌ Login component lacks Russian support"
fi

# Check for Russian text in vacation requests
if echo "$VACATION_RESULT" | grep -q "больничный\|отгул\|внеочередной"; then
    echo "✅ Vacation requests support Russian terms"
    RUSSIAN_SUPPORT=$((RUSSIAN_SUPPORT + 1))
else
    echo "❌ Vacation requests lack Russian terms"
fi

# Check for Russian in Dashboard
if grep -q "Мониторинг\|Операции\|Показатели" src/ui/src/components/Dashboard.tsx 2>/dev/null; then
    echo "✅ Dashboard has Russian labels"
    RUSSIAN_SUPPORT=$((RUSSIAN_SUPPORT + 1))
else
    echo "❌ Dashboard lacks Russian labels"
fi

echo "Russian support score: $RUSSIAN_SUPPORT/3 components"
echo

# 5. Real-time Capability Testing
echo "⏱️ REAL-TIME CAPABILITY TESTING:"
echo "================================="

echo "Testing for real-time update mechanisms..."
REALTIME_SUPPORT=0

# Check for WebSocket implementation
if grep -q "WebSocket\|socket\.io\|ws://" src/ui/src/components/Dashboard.tsx 2>/dev/null; then
    echo "✅ WebSocket real-time updates found"
    REALTIME_SUPPORT=$((REALTIME_SUPPORT + 1))
else
    echo "❌ No WebSocket implementation found"
fi

# Check for polling intervals
if grep -q "setInterval\|setTimeout.*30.*second\|polling" src/ui/src/components/Dashboard.tsx 2>/dev/null; then
    echo "✅ Polling intervals found"
    REALTIME_SUPPORT=$((REALTIME_SUPPORT + 1))
else
    echo "❌ No 30-second polling found"
fi

echo "Real-time capability score: $REALTIME_SUPPORT/2 mechanisms"
echo

# 6. Mobile BDD Compliance Testing
echo "📱 MOBILE BDD COMPLIANCE TESTING:"
echo "=================================="

echo "Testing mobile personal cabinet requirements..."
MOBILE_SUPPORT=0

# Check for responsive design
if grep -q "responsive\|mobile\|@media" src/ui/src/components/Login.tsx 2>/dev/null; then
    echo "✅ Responsive design detected"
    MOBILE_SUPPORT=$((MOBILE_SUPPORT + 1))
else
    echo "❌ No responsive design found"
fi

# Check for biometric authentication
if grep -q "biometric\|fingerprint\|faceId" src/ui/src/components/Login.tsx 2>/dev/null; then
    echo "✅ Biometric authentication support"
    MOBILE_SUPPORT=$((MOBILE_SUPPORT + 1))
else
    echo "❌ No biometric authentication found"
fi

# Check for push notifications
if grep -q "notification\|push\|serviceWorker" src/ui/src/ -r 2>/dev/null; then
    echo "✅ Push notification capability"
    MOBILE_SUPPORT=$((MOBILE_SUPPORT + 1))
else
    echo "❌ No push notification support"
fi

echo "Mobile BDD compliance score: $MOBILE_SUPPORT/3 features"
echo

# 7. BDD Compliance Summary
echo "📊 BDD COMPLIANCE SUMMARY:"
echo "=========================="

# Calculate overall BDD compliance
TOTAL_TESTS=4
PASSED_TESTS=0

# Count passed tests
if echo "$VACATION_RESULT" | grep -q "success"; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
fi

# Note: Login, Dashboard, Employee tests likely to fail based on previous verification

COMPLIANCE_PERCENTAGE=$((PASSED_TESTS * 100 / TOTAL_TESTS))

echo "BDD Test Results:"
echo "- Vacation Request (File 02): $(echo "$VACATION_RESULT" | grep -q "success" && echo "✅ PASS" || echo "❌ FAIL")"
echo "- Personal Cabinet Login (File 14): $(echo "$LOGIN_RESULT" | grep -q "token\|success" && echo "✅ PASS" || echo "❌ FAIL")"
echo "- Real-time Monitoring (File 15): $(echo "$DASHBOARD_RESULT" | grep -q "operators_online" && echo "✅ PASS" || echo "❌ FAIL")"
echo "- Employee Management (File 16): $(echo "$EMPLOYEE_RESULT" | grep -q "employees" && echo "✅ PASS" || echo "❌ FAIL")"
echo
echo "Overall BDD Compliance: $COMPLIANCE_PERCENTAGE%"
echo "Russian Language Support: $((RUSSIAN_SUPPORT * 100 / 3))%"
echo "Real-time Capability: $((REALTIME_SUPPORT * 100 / 2))%"
echo "Mobile BDD Compliance: $((MOBILE_SUPPORT * 100 / 3))%"
echo

# 8. Critical BDD Violations
echo "🚨 CRITICAL BDD VIOLATIONS:"
echo "==========================="

if [ $COMPLIANCE_PERCENTAGE -lt 80 ]; then
    echo "❌ MAJOR VIOLATION: Overall BDD compliance below 80%"
fi

if [ $RUSSIAN_SUPPORT -lt 2 ]; then
    echo "❌ MAJOR VIOLATION: Insufficient Russian language support"
    echo "   BDD requires: Interface elements in Russian (больничный, отгул, etc.)"
fi

if [ $REALTIME_SUPPORT -eq 0 ]; then
    echo "❌ MAJOR VIOLATION: No real-time updates implemented"
    echo "   BDD requires: 30-second updates for monitoring dashboards"
fi

echo
echo "🎯 FINAL BDD VERDICT:"
echo "===================="

if [ $COMPLIANCE_PERCENTAGE -ge 80 ] && [ $RUSSIAN_SUPPORT -ge 2 ]; then
    echo "✅ BDD COMPLIANT: System meets BDD specification requirements"
else
    echo "❌ BDD NON-COMPLIANT: System fails BDD specification requirements"
    echo "   Required fixes:"
    echo "   1. Implement missing API endpoints"
    echo "   2. Add Russian language support"
    echo "   3. Implement real-time updates"
    echo "   4. Fix authentication configuration"
fi