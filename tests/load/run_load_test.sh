#!/bin/bash
# WFM Enterprise Load Testing Runner
# Simulates 1000 concurrent users and generates performance report

set -e

echo "🚀 WFM ENTERPRISE LOAD TESTING SUITE"
echo "===================================="
echo ""

# Check dependencies
if ! command -v locust &> /dev/null; then
    echo "Installing Locust..."
    pip install locust numpy
fi

# Configuration
HOST="${API_HOST:-http://localhost:8000}"
USERS="${LOAD_USERS:-1000}"
SPAWN_RATE="${SPAWN_RATE:-50}"
RUN_TIME="${RUN_TIME:-300}"  # 5 minutes default

echo "Configuration:"
echo "  API Host: $HOST"
echo "  Target Users: $USERS"
echo "  Spawn Rate: $SPAWN_RATE users/second"
echo "  Run Time: $RUN_TIME seconds"
echo ""

# Create results directory
mkdir -p results
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULT_DIR="results/load_test_$TIMESTAMP"
mkdir -p $RESULT_DIR

# Run different load scenarios
echo "Running load test scenarios..."

# Scenario 1: Gradual ramp-up
echo ""
echo "Scenario 1: Gradual Ramp-up Test"
echo "---------------------------------"
locust -f locustfile.py \
    --host $HOST \
    --users $USERS \
    --spawn-rate 10 \
    --run-time $RUN_TIME \
    --headless \
    --html $RESULT_DIR/gradual_rampup.html \
    --csv $RESULT_DIR/gradual_rampup \
    --only-summary

# Scenario 2: Spike test
echo ""
echo "Scenario 2: Spike Test"
echo "----------------------"
locust -f locustfile.py \
    --host $HOST \
    --users $((USERS * 2)) \
    --spawn-rate 100 \
    --run-time 60 \
    --headless \
    --html $RESULT_DIR/spike_test.html \
    --csv $RESULT_DIR/spike_test \
    --only-summary

# Scenario 3: Sustained load
echo ""
echo "Scenario 3: Sustained Load Test"
echo "-------------------------------"
locust -f locustfile.py \
    --host $HOST \
    --users $USERS \
    --spawn-rate $SPAWN_RATE \
    --run-time $((RUN_TIME * 2)) \
    --headless \
    --html $RESULT_DIR/sustained_load.html \
    --csv $RESULT_DIR/sustained_load \
    --only-summary

# Generate consolidated report
echo ""
echo "Generating performance report..."
python generate_performance_report.py $RESULT_DIR

echo ""
echo "✅ Load testing complete!"
echo "📊 Results saved to: $RESULT_DIR"
echo "📈 Open $RESULT_DIR/performance_report.html to view the report"

# Display summary
echo ""
echo "PERFORMANCE SUMMARY"
echo "==================="
tail -n 20 $RESULT_DIR/performance_summary.txt

# Check if targets were met
if grep -q "ALL TARGETS MET" $RESULT_DIR/performance_summary.txt; then
    echo ""
    echo "🎉 SUCCESS: WFM Enterprise meets all performance targets!"
    exit 0
else
    echo ""
    echo "⚠️  WARNING: Some performance targets were not met"
    exit 1
fi