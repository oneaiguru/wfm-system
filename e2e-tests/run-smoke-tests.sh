#!/bin/bash

echo "🚀 Starting E2E Smoke Tests for WFM System"
echo "=========================================="

# Check if servers are running
echo "✅ Checking API server..."
curl -s http://localhost:8001/health > /dev/null
if [ $? -ne 0 ]; then
    echo "❌ API server not running on http://localhost:8001"
    echo "Please start the API server first"
    exit 1
fi

echo "✅ Checking UI server..."
curl -s http://localhost:3000 > /dev/null
if [ $? -ne 0 ]; then
    echo "❌ UI server not running on http://localhost:3000"
    echo "Please start the UI server first"
    exit 1
fi

# Run smoke tests
echo ""
echo "🧪 Running critical path tests..."
echo ""

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

# Run the smoke test suite
npm run test:smoke

# Check exit code
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Smoke tests passed! System is ready for full E2E testing."
    echo ""
    echo "Next steps:"
    echo "1. Run full test suite: npm test"
    echo "2. Run specific scenarios: npm run verify:spec-XX"
    echo "3. View test report: npm run report"
else
    echo ""
    echo "❌ Smoke tests failed. Please fix issues before running full suite."
fi