#!/usr/bin/env python3
"""
Real Employee Integration Test Runner
Runs BDD tests for converted employee components with real API integration
"""

import os
import sys
import subprocess
import time
import requests
import argparse
from pathlib import Path

def check_api_server(base_url="http://localhost:8000"):
    """Check if the API server is running"""
    try:
        response = requests.get(f"{base_url}/api/v1/health", timeout=5)
        if response.status_code == 200:
            print(f"✅ API server is running at {base_url}")
            return True
        else:
            print(f"❌ API server returned status {response.status_code}")
            return False
    except requests.exceptions.RequestException as e:
        print(f"❌ API server is not accessible at {base_url}: {e}")
        return False

def check_ui_server(base_url="http://localhost:3000"):
    """Check if the UI server is running"""
    try:
        response = requests.get(base_url, timeout=5)
        if response.status_code == 200:
            print(f"✅ UI server is running at {base_url}")
            return True
        else:
            print(f"❌ UI server returned status {response.status_code}")
            return False
    except requests.exceptions.RequestException as e:
        print(f"❌ UI server is not accessible at {base_url}: {e}")
        return False

def setup_test_environment():
    """Setup test environment and dependencies"""
    print("🔧 Setting up test environment...")
    
    # Create test results directory
    results_dir = Path("test_results")
    results_dir.mkdir(exist_ok=True)
    
    # Install test dependencies if needed
    try:
        import behave
        import selenium
        print("✅ Test dependencies are available")
    except ImportError as e:
        print(f"❌ Missing test dependency: {e}")
        print("Install with: pip install behave selenium requests")
        return False
    
    return True

def run_behave_tests(tags=None, headless=False, api_url=None, ui_url=None):
    """Run the BDD tests using behave"""
    cmd = ["behave"]
    
    # Add tag filters
    if tags:
        cmd.extend(["--tags", tags])
    
    # Add user data for configuration
    if headless:
        cmd.extend(["--define", "headless=true"])
    
    if api_url:
        cmd.extend(["--define", f"api_base_url={api_url}"])
    
    if ui_url:
        cmd.extend(["--define", f"ui_base_url={ui_url}"])
    
    # Run tests
    print(f"🧪 Running BDD tests: {' '.join(cmd)}")
    result = subprocess.run(cmd, cwd="tests")
    
    return result.returncode == 0

def main():
    parser = argparse.ArgumentParser(description="Run Real Employee Integration Tests")
    parser.add_argument("--tags", help="Behave tags to run (e.g., 'real-integration')")
    parser.add_argument("--headless", action="store_true", help="Run browser tests in headless mode")
    parser.add_argument("--api-url", default="http://localhost:8000", help="API server URL")
    parser.add_argument("--ui-url", default="http://localhost:3000", help="UI server URL")
    parser.add_argument("--skip-server-check", action="store_true", help="Skip server availability checks")
    
    args = parser.parse_args()
    
    print("🚀 Real Employee Integration Test Runner")
    print("=" * 50)
    
    # Setup test environment
    if not setup_test_environment():
        sys.exit(1)
    
    # Check server availability
    if not args.skip_server_check:
        print("\n📡 Checking server availability...")
        
        if not check_api_server(args.api_url):
            print("\n❌ API server is not running!")
            print("Start the API server with: python -m uvicorn src.api.main_simple:app --port 8000")
            sys.exit(1)
        
        if not check_ui_server(args.ui_url):
            print("\n❌ UI server is not running!")
            print("Start the UI server with: npm run dev")
            sys.exit(1)
    
    # Run tests
    print("\n🧪 Running Real Employee Integration Tests...")
    print("-" * 50)
    
    success = run_behave_tests(
        tags=args.tags,
        headless=args.headless,
        api_url=args.api_url,
        ui_url=args.ui_url
    )
    
    if success:
        print("\n✅ All tests passed!")
        print("🎉 Real employee components are working with actual backend APIs!")
    else:
        print("\n❌ Some tests failed!")
        print("Check test_results/ directory for detailed output")
        sys.exit(1)

if __name__ == "__main__":
    main()