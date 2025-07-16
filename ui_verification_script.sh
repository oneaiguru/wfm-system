#!/bin/bash
# UI-OPUS Verification Script

echo "🧪 UI-OPUS VERIFICATION RESULTS"
echo "==============================="
echo

# 1. Component count verification
echo "📊 Component Count Verification:"
COMPONENT_COUNT=$(find src/ui/src/components -name "*.tsx" | wc -l | xargs)
echo "Actual components found: $COMPONENT_COUNT"
echo "Claimed components: 119"
if [ "$COMPONENT_COUNT" -eq 119 ]; then
    echo "✅ Component count MATCHES claim"
else
    echo "❌ Component count MISMATCH"
fi
echo

# 2. API server status
echo "🔗 API Server Status:"
API_HEALTH=$(curl -s http://localhost:8000/health)
if [ $? -eq 0 ]; then
    echo "✅ API server responding"
    echo "Response: $API_HEALTH"
else
    echo "❌ API server not responding"
fi
echo

# 3. Test claimed working components
echo "🧪 Testing Claimed Working Components:"

echo "Testing Login endpoint..."
LOGIN_RESULT=$(curl -s -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"test"}')
echo "Login test result: $LOGIN_RESULT"

echo "Testing vacation request endpoint..."
VACATION_RESULT=$(curl -s -X POST http://localhost:8000/api/v1/requests/vacation \
  -H "Content-Type: application/json" \
  -d '{"employee_id":"1","start_date":"2025-08-01","end_date":"2025-08-05","description":"Test"}')
echo "Vacation request result: $VACATION_RESULT"

echo "Testing dashboard endpoint..."
DASHBOARD_RESULT=$(curl -s http://localhost:8000/api/v1/metrics/dashboard)
echo "Dashboard test result: $DASHBOARD_RESULT"

echo "Testing employee list endpoint..."
EMPLOYEE_RESULT=$(curl -s http://localhost:8000/api/v1/employees/list)
echo "Employee list result: $EMPLOYEE_RESULT"
echo

# 4. Check for mock patterns
echo "🔍 Mock Pattern Analysis:"
MOCK_COUNT=$(grep -r "mock\|fake\|hardcoded\|dummy" src/ui/src/ 2>/dev/null | wc -l | xargs)
echo "Mock patterns found: $MOCK_COUNT"
if [ "$MOCK_COUNT" -lt 100 ]; then
    echo "✅ Low mock usage indicates real integration"
else
    echo "⚠️  High mock usage - may indicate claims inflation"
fi
echo

# 5. Check actual working endpoints
echo "📡 Available API Endpoints:"
curl -s http://localhost:8000/openapi.json | jq '.paths | keys[]' 2>/dev/null || echo "OpenAPI spec not available"
echo

# 6. Component structure analysis
echo "📁 Component Structure Analysis:"
echo "Total components by category:"
find src/ui/src/components -type d | while read dir; do
    count=$(find "$dir" -maxdepth 1 -name "*.tsx" | wc -l | xargs)
    if [ "$count" -gt 0 ]; then
        echo "$(basename "$dir"): $count components"
    fi
done
echo

echo "🎯 VERIFICATION SUMMARY"
echo "======================="
echo "Component Count: $COMPONENT_COUNT (claimed: 119)"
echo "API Server: $([ $? -eq 0 ] && echo "✅ Working" || echo "❌ Failed")"
echo "Mock Patterns: $MOCK_COUNT found"
echo "Testing endpoints individually..."