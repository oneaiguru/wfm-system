#!/usr/bin/env python3
"""
Test Runner for Real Reports Integration Tests

This script runs BDD tests for the 5 real report components:
1. ReportsPortal.tsx
2. ReportBuilder.tsx 
3. AnalyticsDashboard.tsx
4. ExportManager.tsx
5. ReportScheduler.tsx

All tests verify REAL API integration with NO MOCK FALLBACKS.
"""

import subprocess
import sys
import time
import requests
import argparse
from pathlib import Path

# Configuration
API_BASE_URL = "http://localhost:8000"
UI_BASE_URL = "http://localhost:3000"

def check_api_server():
    """Check if the API server is running"""
    try:
        response = requests.get(f"{API_BASE_URL}/api/v1/health", timeout=5)
        return response.status_code == 200
    except requests.exceptions.RequestException:
        return False

def check_ui_server():
    """Check if the UI server is running"""
    try:
        response = requests.get(UI_BASE_URL, timeout=5)
        return response.status_code == 200
    except requests.exceptions.RequestException:
        return False

def wait_for_servers(max_wait_time=60):
    """Wait for both servers to be ready"""
    print("Waiting for servers to be ready...")
    
    start_time = time.time()
    api_ready = False
    ui_ready = False
    
    while time.time() - start_time < max_wait_time:
        if not api_ready:
            api_ready = check_api_server()
            if api_ready:
                print("✅ API server is ready")
        
        if not ui_ready:
            ui_ready = check_ui_server()
            if ui_ready:
                print("✅ UI server is ready")
        
        if api_ready and ui_ready:
            return True
        
        time.sleep(2)
    
    return False

def run_behave_tests(tags=None, scenarios=None):
    """Run behave tests with optional filtering"""
    test_dir = Path(__file__).parent
    
    # Build behave command
    cmd = ["behave", str(test_dir / "features")]
    
    if tags:
        cmd.extend(["--tags", tags])
    
    if scenarios:
        cmd.extend(["--name", scenarios])
    
    # Add formatting and output options
    cmd.extend([
        "--format", "pretty",
        "--format", "json",
        "--outfile", str(test_dir / "results" / "test_results.json"),
        "--no-capture",  # Show print statements
        "--logging-level", "INFO"
    ])
    
    print(f"Running command: {' '.join(cmd)}")
    
    try:
        result = subprocess.run(cmd, capture_output=False, text=True)
        return result.returncode == 0
    except subprocess.CalledProcessError as e:
        print(f"❌ Tests failed with error: {e}")
        return False

def run_component_specific_tests():
    """Run tests for each component individually"""
    components = [
        ("ReportsPortal", "@reports-portal"),
        ("ReportBuilder", "@report-builder"),
        ("AnalyticsDashboard", "@analytics-dashboard"),
        ("ExportManager", "@export-manager"),
        ("ReportScheduler", "@report-scheduler")
    ]
    
    results = {}
    
    for component_name, tag in components:
        print(f"\n{'='*60}")
        print(f"Testing {component_name}")
        print(f"{'='*60}")
        
        success = run_behave_tests(tags=tag)
        results[component_name] = success
        
        if success:
            print(f"✅ {component_name} tests PASSED")
        else:
            print(f"❌ {component_name} tests FAILED")
    
    return results

def print_test_summary(results):
    """Print a summary of test results"""
    print(f"\n{'='*60}")
    print("REAL REPORTS INTEGRATION TEST SUMMARY")
    print(f"{'='*60}")
    
    total_components = len(results)
    passed_components = sum(1 for success in results.values() if success)
    
    for component, success in results.items():
        status = "✅ PASSED" if success else "❌ FAILED"
        print(f"{component:<20} {status}")
    
    print(f"\nTotal: {passed_components}/{total_components} components passed")
    
    if passed_components == total_components:
        print("\n🎉 ALL REPORT COMPONENTS HAVE REAL API INTEGRATION!")
        print("✅ No mock data fallbacks detected")
        print("✅ Real backend integration confirmed")
        return True
    else:
        print(f"\n⚠️  {total_components - passed_components} components need fixes")
        print("❌ Some components may still have mock fallbacks")
        return False

def setup_test_environment():
    """Set up the test environment"""
    test_dir = Path(__file__).parent
    results_dir = test_dir / "results"
    results_dir.mkdir(exist_ok=True)
    
    print("🔧 Setting up test environment...")
    print(f"Test directory: {test_dir}")
    print(f"Results directory: {results_dir}")

def main():
    parser = argparse.ArgumentParser(description="Run Real Reports Integration Tests")
    parser.add_argument("--component", help="Test specific component only")
    parser.add_argument("--tags", help="Run tests with specific tags")
    parser.add_argument("--scenario", help="Run specific scenario")
    parser.add_argument("--skip-server-check", action="store_true", help="Skip server availability check")
    parser.add_argument("--wait-time", type=int, default=60, help="Max wait time for servers (seconds)")
    
    args = parser.parse_args()
    
    print("🧪 REAL REPORTS INTEGRATION TEST RUNNER")
    print("=====================================")
    print("Testing 5 report components with REAL API integration")
    print("NO MOCK DATA FALLBACKS ALLOWED")
    
    setup_test_environment()
    
    # Check server availability
    if not args.skip_server_check:
        if not wait_for_servers(args.wait_time):
            print("\n❌ SERVERS NOT READY")
            print(f"API Server ({API_BASE_URL}): {'✅' if check_api_server() else '❌'}")
            print(f"UI Server ({UI_BASE_URL}): {'✅' if check_ui_server() else '❌'}")
            print("\nPlease start the servers and try again:")
            print("  API: python -m uvicorn src.api.main_simple:app --port 8000")
            print("  UI:  npm run dev")
            sys.exit(1)
    
    # Run tests based on arguments
    if args.component:
        component_tags = {
            "reportsportal": "@reports-portal",
            "reportbuilder": "@report-builder", 
            "analyticsdashboard": "@analytics-dashboard",
            "exportmanager": "@export-manager",
            "reportscheduler": "@report-scheduler"
        }
        
        tag = component_tags.get(args.component.lower())
        if not tag:
            print(f"❌ Unknown component: {args.component}")
            print(f"Available components: {', '.join(component_tags.keys())}")
            sys.exit(1)
        
        success = run_behave_tests(tags=tag)
        sys.exit(0 if success else 1)
    
    elif args.tags or args.scenario:
        success = run_behave_tests(tags=args.tags, scenarios=args.scenario)
        sys.exit(0 if success else 1)
    
    else:
        # Run all component tests
        results = run_component_specific_tests()
        
        # Also run integration and error handling tests
        print(f"\n{'='*60}")
        print("Running Integration & Error Handling Tests")
        print(f"{'='*60}")
        
        integration_success = run_behave_tests(tags="@real-integration and (@authentication or @error-handling or @performance)")
        results["Integration"] = integration_success
        
        # Print summary
        all_passed = print_test_summary(results)
        
        if all_passed:
            print("\n🏆 MISSION ACCOMPLISHED!")
            print("All 5 report components successfully converted to REAL API integration")
            print("Ready for production deployment")
        else:
            print("\n🔧 WORK REMAINING")
            print("Some components need additional work to achieve real integration")
        
        sys.exit(0 if all_passed else 1)

if __name__ == "__main__":
    main()