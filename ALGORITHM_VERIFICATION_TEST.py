#!/usr/bin/env python3
"""
ALGORITHM-OPUS Verification Test Suite
Tests all claimed real algorithms for actual execution and performance
"""

import sys
import time
import traceback
import psycopg2
from pathlib import Path

# Add project root to path
project_root = Path(__file__).parent
sys.path.insert(0, str(project_root))

def test_database_connection():
    """Test basic database connection"""
    try:
        conn = psycopg2.connect(
            host="localhost",
            database="wfm_enterprise",
            user="postgres",
            password="password"
        )
        with conn.cursor() as cursor:
            cursor.execute("SELECT COUNT(*) FROM information_schema.tables")
            table_count = cursor.fetchone()[0]
        conn.close()
        return True, f"Database connected: {table_count} tables"
    except Exception as e:
        return False, f"Database connection failed: {e}"

def test_algorithm_execution():
    """Test execution of key algorithms that were claimed to be fixed"""
    results = []
    
    # Test 1: Mobile Workforce Scheduler
    try:
        from src.algorithms.mobile.mobile_workforce_scheduler_real import MobileWorkforceScheduler
        scheduler = MobileWorkforceScheduler()
        result = scheduler.schedule_mobile_workforce()
        success = result.get('success', False) and result.get('workers_count', 0) > 0
        results.append({
            'name': 'Mobile Workforce Scheduler',
            'success': success,
            'details': f"Workers: {result.get('workers_count', 0)}, Assignments: {result.get('assigned_count', 0)}"
        })
    except Exception as e:
        results.append({
            'name': 'Mobile Workforce Scheduler',
            'success': False,
            'details': f"Error: {str(e)}"
        })
    
    # Test 2: Gap Analysis Engine (claimed to be real)
    try:
        from src.algorithms.optimization.gap_analysis_engine_real import RealGapAnalysisEngine
        gap_engine = RealGapAnalysisEngine()
        from datetime import date
        result = gap_engine.analyze_coverage_gaps_real(service_id=1, target_date=date.today())
        success = len(result.get('gaps', [])) >= 0  # Should execute without error
        results.append({
            'name': 'Gap Analysis Engine',
            'success': success,
            'details': f"Gaps found: {len(result.get('gaps', []))}"
        })
    except Exception as e:
        results.append({
            'name': 'Gap Analysis Engine',
            'success': False,
            'details': f"Error: {str(e)}"
        })
    
    # Test 3: Enhanced Erlang C (claimed to use real forecast data)
    try:
        from src.algorithms.core.erlang_c_enhanced import ErlangCEnhanced
        erlang = ErlangCEnhanced()
        start_time = time.time()
        result = erlang.calculate_staffing(
            date='2024-07-15',
            interval='15min',
            service_level_target=0.8,
            target_time_seconds=20
        )
        end_time = time.time()
        performance_ms = (end_time - start_time) * 1000
        success = result.get('required_agents', 0) > 0 and performance_ms < 100
        results.append({
            'name': 'Enhanced Erlang C',
            'success': success,
            'details': f"Agents: {result.get('required_agents', 0)}, Performance: {performance_ms:.1f}ms"
        })
    except Exception as e:
        results.append({
            'name': 'Enhanced Erlang C',
            'success': False,
            'details': f"Error: {str(e)}"
        })
    
    # Test 4: Approval Engine (claimed to process real approvals)
    try:
        from src.algorithms.workflows.approval_engine import ApprovalEngine
        approval = ApprovalEngine()
        pending = approval.get_pending_approvals()
        success = isinstance(pending, list)  # Should return a list
        results.append({
            'name': 'Approval Engine',
            'success': success,
            'details': f"Pending approvals: {len(pending) if pending else 0}"
        })
    except Exception as e:
        results.append({
            'name': 'Approval Engine',
            'success': False,
            'details': f"Error: {str(e)}"
        })
    
    # Test 5: Mobile App Integration (just fixed import)
    try:
        from src.algorithms.mobile.mobile_app_integration import MobileWorkforceSchedulerIntegration
        mobile_app = MobileWorkforceSchedulerIntegration()
        sessions = mobile_app.get_active_mobile_sessions_with_device_data()
        success = isinstance(sessions, list)
        results.append({
            'name': 'Mobile App Integration',
            'success': success,
            'details': f"Mobile sessions found: {len(sessions)}"
        })
    except Exception as e:
        results.append({
            'name': 'Mobile App Integration',
            'success': False,
            'details': f"Error: {str(e)}"
        })
    
    # Test 6: Vacation Schedule Exporter (claimed to use real vacation data)
    try:
        from src.algorithms.russian.vacation_schedule_exporter import VacationScheduleExporter
        exporter = VacationScheduleExporter()
        result = exporter.generate_export()
        success = result.get('vacation_count', 0) >= 0
        results.append({
            'name': 'Vacation Schedule Exporter',
            'success': success,
            'details': f"Vacations: {result.get('vacation_count', 0)}"
        })
    except Exception as e:
        results.append({
            'name': 'Vacation Schedule Exporter',
            'success': False,
            'details': f"Error: {str(e)}"
        })
    
    return results

def check_remaining_mock_patterns():
    """Check for remaining mock patterns in algorithm files"""
    import os
    import re
    
    mock_patterns = []
    algorithms_dir = project_root / "src" / "algorithms"
    
    # Common mock patterns to look for
    mock_indicators = [
        r'random\.uniform\(',
        r'mock.*=.*True',
        r'fake.*data',
        r'mock.*generator',
        r'simulated.*data',
        r'hardcoded.*data',
        r'# TODO.*mock',
        r'# MOCK.*',
        r'Mock[A-Z]\w*',
        r'fake_\w+',
        r'simulate_\w+'
    ]
    
    for root, dirs, files in os.walk(algorithms_dir):
        for file in files:
            if file.endswith('.py') and not file.startswith('test_'):
                file_path = Path(root) / file
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                        for i, line in enumerate(content.split('\n'), 1):
                            for pattern in mock_indicators:
                                if re.search(pattern, line, re.IGNORECASE):
                                    mock_patterns.append({
                                        'file': str(file_path.relative_to(project_root)),
                                        'line': i,
                                        'pattern': pattern,
                                        'content': line.strip()[:100]
                                    })
                except Exception:
                    continue
    
    return mock_patterns

def run_verification():
    """Run complete verification suite"""
    print("🔧 ALGORITHM-OPUS VERIFICATION TEST SUITE")
    print("=" * 60)
    
    # Test 1: Database Connection
    print("\n1. DATABASE CONNECTION TEST")
    db_success, db_message = test_database_connection()
    print(f"   {'✅ PASS' if db_success else '❌ FAIL'}: {db_message}")
    
    # Test 2: Algorithm Execution
    print("\n2. ALGORITHM EXECUTION TESTS")
    algorithm_results = test_algorithm_execution()
    
    passed = 0
    total = len(algorithm_results)
    
    for result in algorithm_results:
        status = "✅ PASS" if result['success'] else "❌ FAIL"
        print(f"   {status}: {result['name']}")
        print(f"      {result['details']}")
        if result['success']:
            passed += 1
    
    print(f"\n   Algorithm Tests: {passed}/{total} PASSED ({passed/total*100:.1f}%)")
    
    # Test 3: Mock Pattern Detection
    print("\n3. MOCK PATTERN DETECTION")
    mock_patterns = check_remaining_mock_patterns()
    
    if mock_patterns:
        print(f"   ❌ FOUND {len(mock_patterns)} MOCK PATTERNS:")
        
        # Group by file
        by_file = {}
        for pattern in mock_patterns:
            file = pattern['file']
            if file not in by_file:
                by_file[file] = []
            by_file[file].append(pattern)
        
        for file, patterns in list(by_file.items())[:10]:  # Show first 10 files
            print(f"      📄 {file}: {len(patterns)} patterns")
            for pattern in patterns[:3]:  # Show first 3 patterns per file
                print(f"         Line {pattern['line']}: {pattern['content']}")
        
        if len(by_file) > 10:
            print(f"      ... and {len(by_file) - 10} more files")
    else:
        print("   ✅ NO MOCK PATTERNS FOUND")
    
    # Summary
    print("\n4. VERIFICATION SUMMARY")
    print("=" * 60)
    
    overall_success = db_success and passed == total and len(mock_patterns) == 0
    
    print(f"Database Connection: {'✅ PASS' if db_success else '❌ FAIL'}")
    print(f"Algorithm Execution: {passed}/{total} ({'✅ PASS' if passed == total else '❌ FAIL'})")
    print(f"Mock Pattern Check: {'✅ PASS' if len(mock_patterns) == 0 else f'❌ FAIL ({len(mock_patterns)} patterns)'}")
    print(f"\nOVERALL VERIFICATION: {'✅ PASS' if overall_success else '❌ FAIL'}")
    
    return overall_success, {
        'database': db_success,
        'algorithms_passed': passed,
        'algorithms_total': total,
        'mock_patterns': len(mock_patterns),
        'algorithm_results': algorithm_results
    }

if __name__ == "__main__":
    success, details = run_verification()
    sys.exit(0 if success else 1)