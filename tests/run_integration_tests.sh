#!/bin/bash
# =============================================================================
# run_integration_tests.sh
# Execute Day 2 integration tests in proper sequence
# =============================================================================

echo "================================================================================"
echo "DAY 2: INTEGRATION TESTING FOR DEMO"
echo "================================================================================"
echo ""

# Check if we need to use postgres database or create test db
DB_NAME="${1:-postgres}"
DB_USER="${2:-postgres}"

echo "Using database: $DB_NAME as user: $DB_USER"
echo ""

# Function to run SQL file
run_sql() {
    local file=$1
    local desc=$2
    echo "🔴 Running: $desc"
    echo "File: $file"
    echo "--------------------------------------------------------------------------------"
    psql -U $DB_USER -d $DB_NAME -f $file 2>&1
    echo ""
}

# Initialize test database (if needed)
echo "📊 Initializing test environment..."
run_sql "tests/init_test_db.sql" "Database initialization"

# Apply fixes
echo "🔧 Applying integration fixes..."
run_sql "src/database/fixes/fix_time_code_dashboard_link.sql" "Time code to dashboard link"
run_sql "src/database/fixes/fix_forecast_optimization_link.sql" "Forecast to optimization link"

# Generate demo data
echo "🏢 Generating Russian call center data..."
run_sql "src/database/demo/russian_call_center.sql" "ООО ТехноСервис demo scenario"

# Run tests
echo "🧪 Running integration tests..."
run_sql "tests/test_critical_integration_path.sql" "Critical path integration"
run_sql "tests/test_foreign_key_cascade.sql" "Foreign key integrity"
run_sql "tests/test_russian_call_center.sql" "Russian call center scenario"

# Verify everything works
echo "✅ Verifying complete integration..."
run_sql "tests/verify_integration_works.sql" "End-to-end verification"

echo ""
echo "================================================================================"
echo "INTEGRATION TESTING COMPLETE!"
echo "Check results above for any failures"
echo "================================================================================"