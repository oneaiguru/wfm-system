#!/usr/bin/env python3
"""
Debug the Reporting APIs to see what's failing
"""

import asyncio
import sys
import traceback
sys.path.append('/Users/m/Documents/wfm/main/project')

from sqlalchemy.ext.asyncio import AsyncSession
from src.api.core.database import AsyncSessionLocal
from src.api.v1.endpoints.reports_generate_REAL import generate_report, ReportGenerationType
from datetime import date

async def debug_generate_report():
    """Debug the generate report endpoint"""
    try:
        async with AsyncSessionLocal() as session:
            from fastapi import BackgroundTasks
            bg_tasks = BackgroundTasks()
            
            print("🔍 Testing generate_report function...")
            
            # Test system health report (simplest one)
            response = await generate_report(
                type=ReportGenerationType.SYSTEM_HEALTH,
                background_tasks=bg_tasks,
                report_date=None,
                include_details=True,
                db=session
            )
            
            print(f"✅ Generate Report Success: {response.message}")
            print(f"   - Status: {response.status}")
            print(f"   - Execution ID: {response.execution_id}")
            return True
            
    except Exception as e:
        print(f"❌ Generate Report Error: {e}")
        print("Full traceback:")
        traceback.print_exc()
        return False

async def debug_tables():
    """Check what tables actually exist"""
    try:
        async with AsyncSessionLocal() as session:
            from sqlalchemy import text
            
            # Check all tables
            result = await session.execute(text("""
                SELECT table_name FROM information_schema.tables 
                WHERE table_schema = 'public' 
                ORDER BY table_name
            """))
            tables = [row[0] for row in result.fetchall()]
            
            print(f"📋 Available tables ({len(tables)}):")
            for table in tables:
                print(f"   - {table}")
            
            # Check if core tables exist
            required_tables = ['report_definitions', 'report_parameters', 'export_templates', 'report_executions']
            missing = [t for t in required_tables if t not in tables]
            
            if missing:
                print(f"❌ Missing required tables: {missing}")
            else:
                print("✅ All required tables exist")
            
            return len(missing) == 0
            
    except Exception as e:
        print(f"❌ Table check error: {e}")
        return False

async def main():
    print("🐛 Debugging Reporting APIs")
    print("=" * 40)
    
    # Check tables first
    await debug_tables()
    print()
    
    # Test generate report
    await debug_generate_report()

if __name__ == "__main__":
    asyncio.run(main())