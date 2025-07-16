#!/usr/bin/env python3
"""
Quick test of the new Reporting APIs (Tasks 31-35)
Tests database connectivity and endpoint functionality
"""

import asyncio
import sys
sys.path.append('/Users/m/Documents/wfm/main/project')

from sqlalchemy.ext.asyncio import AsyncSession
from src.api.core.database import engine, AsyncSessionLocal
from src.api.v1.endpoints.reports_generate_REAL import generate_report, ReportGenerationType
from src.api.v1.endpoints.reports_schedule_REAL import get_report_schedules
from datetime import date

async def test_database_connection():
    """Test basic database connectivity"""
    try:
        async with AsyncSessionLocal() as session:
            from sqlalchemy import text
            result = await session.execute(text("SELECT 1 as test"))
            test_value = result.scalar()
            print(f"✅ Database connection successful: {test_value}")
            return True
    except Exception as e:
        print(f"❌ Database connection failed: {e}")
        return False

async def test_generate_report_endpoint():
    """Test the generate report endpoint"""
    try:
        async with AsyncSessionLocal() as session:
            from fastapi import BackgroundTasks
            bg_tasks = BackgroundTasks()
            
            # Test login/logout report generation
            response = await generate_report(
                type=ReportGenerationType.LOGIN_LOGOUT,
                background_tasks=bg_tasks,
                report_date=date.today(),
                include_details=True,
                db=session
            )
            
            print(f"✅ Generate Report API: {response.message}")
            print(f"   - Execution ID: {response.execution_id}")
            print(f"   - Status: {response.status}")
            print(f"   - Data sources: {response.data_sources}")
            return True
            
    except Exception as e:
        print(f"❌ Generate Report API failed: {e}")
        return False

async def test_schedule_report_endpoint():
    """Test the schedule report endpoint"""
    try:
        async with AsyncSessionLocal() as session:
            
            # Test get schedules
            schedules = await get_report_schedules(
                status=None,
                frequency=None,
                report_type=None,
                created_by=None,
                next_24h_only=False,
                limit=5,
                offset=0,
                db=session
            )
            
            print(f"✅ Schedule Report API: Found {len(schedules)} schedules")
            if schedules:
                print(f"   - First schedule: {schedules[0].report_name}")
                print(f"   - Status: {schedules[0].status}")
                print(f"   - Frequency: {schedules[0].frequency}")
            return True
            
    except Exception as e:
        print(f"❌ Schedule Report API failed: {e}")
        return False

async def test_reporting_schema():
    """Test that reporting schema tables exist"""
    try:
        async with AsyncSessionLocal() as session:
            from sqlalchemy import text
            
            # Check for key reporting tables
            tables_to_check = [
                'report_definitions',
                'report_parameters', 
                'export_templates',
                'report_executions'
            ]
            
            existing_tables = []
            for table in tables_to_check:
                query = text("""
                    SELECT EXISTS (
                        SELECT FROM information_schema.tables 
                        WHERE table_schema = 'public' 
                        AND table_name = :table_name
                    )
                """)
                result = await session.execute(query, {"table_name": table})
                exists = result.scalar()
                if exists:
                    existing_tables.append(table)
            
            print(f"✅ Reporting schema: {len(existing_tables)}/{len(tables_to_check)} tables exist")
            print(f"   - Available: {existing_tables}")
            
            # Check if we have any reports defined
            if 'report_definitions' in existing_tables:
                count_query = text("SELECT COUNT(*) FROM report_definitions")
                result = await session.execute(count_query)
                report_count = result.scalar()
                print(f"   - {report_count} reports defined in system")
            
            return len(existing_tables) >= 3  # Need at least core tables
            
    except Exception as e:
        print(f"❌ Reporting schema check failed: {e}")
        return False

async def main():
    """Run all tests"""
    print("🧪 Testing Reporting APIs (Tasks 31-35)")
    print("=" * 50)
    
    tests = [
        ("Database Connection", test_database_connection),
        ("Reporting Schema", test_reporting_schema),
        ("Generate Report API", test_generate_report_endpoint),
        ("Schedule Report API", test_schedule_report_endpoint),
    ]
    
    results = []
    for test_name, test_func in tests:
        print(f"\n🔍 Testing {test_name}...")
        success = await test_func()
        results.append(success)
    
    print("\n" + "=" * 50)
    print("📊 Test Results:")
    successful = sum(results)
    total = len(results)
    print(f"✅ {successful}/{total} tests passed")
    
    if successful == total:
        print("🎉 All Reporting APIs are working correctly!")
    else:
        print("⚠️  Some tests failed - check database connection and schema")
    
    return successful == total

if __name__ == "__main__":
    asyncio.run(main())