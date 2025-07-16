#!/usr/bin/env python3
"""
Test Script for Real Database Cost Calculator
Tests the integration with actual financial tables in wfm_enterprise database
"""

import asyncio
import logging
import sys
import os
from datetime import datetime
import uuid

# Add src to path for imports
sys.path.append(os.path.join(os.path.dirname(__file__), 'src'))

from algorithms.optimization.cost_calculator import CostCalculator
from algorithms.optimization.financial_data_service import create_financial_data_service

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

async def test_financial_service_connection():
    """Test basic connection to financial service"""
    print("🔗 Testing Financial Service Connection...")
    
    try:
        financial_service = await create_financial_data_service()
        print("✅ Financial service connected successfully")
        
        # Test payroll rates
        rates = await financial_service.get_payroll_time_code_rates()
        print(f"📊 Payroll rates loaded: Day={rates.day_work_rate}, Night={rates.night_work_rate}, OT={rates.overtime_rate}")
        
        await financial_service.close()
        return True
        
    except Exception as e:
        print(f"❌ Financial service connection failed: {e}")
        return False

async def test_real_employee_data():
    """Test with real employee data from database"""
    print("\n👥 Testing Real Employee Data...")
    
    try:
        financial_service = await create_financial_data_service()
        
        # Get first available employee from database
        query = "SELECT id FROM employees WHERE status = 'active' LIMIT 1"
        async with financial_service.async_session() as session:
            from sqlalchemy import text
            result = await session.execute(text(query))
            row = result.fetchone()
            
            if row:
                employee_id = str(row.id)
                print(f"📋 Testing with employee ID: {employee_id}")
                
                # Get employee profile
                profile = await financial_service.get_employee_financial_profile(employee_id)
                if profile:
                    print(f"✅ Employee profile loaded: {profile.position_title}")
                    print(f"   Work rate: {profile.work_rate}")
                    print(f"   Weekly hours: {profile.weekly_hours_norm}")
                    print(f"   Overtime auth: {profile.overtime_authorization}")
                    
                    # Calculate real hourly rate
                    hourly_rate = await financial_service.calculate_real_hourly_rate(profile)
                    print(f"💰 Calculated hourly rate: ${hourly_rate:.2f}")
                    
                    await financial_service.close()
                    return True, employee_id
                else:
                    print("❌ No employee profile found")
            else:
                print("❌ No active employees found in database")
        
        await financial_service.close()
        return False, None
        
    except Exception as e:
        print(f"❌ Real employee data test failed: {e}")
        return False, None

async def test_cost_calculator_with_real_data():
    """Test cost calculator with real database data"""
    print("\n🧮 Testing Cost Calculator with Real Data...")
    
    try:
        # Initialize cost calculator with database
        calculator = CostCalculator()
        
        # Get a real employee ID
        success, employee_id = await test_real_employee_data()
        if not success or not employee_id:
            print("⚠️  Using synthetic employee ID for testing")
            employee_id = str(uuid.uuid4())
        
        # Create test schedule variant
        schedule_variant = {
            'schedule_blocks': [
                {
                    'employee_id': employee_id,
                    'start_time': '08:00',
                    'end_time': '17:00',  # 9 hours (1 hour overtime)
                    'days_per_week': 5,
                    'skill_level': 'intermediate',
                    'weekend_work': False,
                    'from_site_id': 'site_001',
                    'to_site_id': 'site_002'  # Cross-site work for Mobile Workforce test
                }
            ]
        }
        
        staffing_costs = {}
        overtime_policies = {
            'max_weekly_hours': 40,
            'overtime_rate': 1.5
        }
        
        # Calculate financial impact with real data
        print("🔄 Calculating financial impact...")
        start_time = datetime.now()
        
        financial_impact = await calculator.calculate_financial_impact(
            schedule_variant, 
            staffing_costs, 
            overtime_policies
        )
        
        end_time = datetime.now()
        processing_time = (end_time - start_time).total_seconds() * 1000
        
        # Display results
        print(f"✅ Financial calculation completed in {processing_time:.1f}ms")
        print(f"💰 Total weekly cost: ${financial_impact.total_weekly_cost:.2f}")
        print(f"📊 Cost variance: {financial_impact.cost_variance:.1f}%")
        print(f"⚡ Efficiency score: {financial_impact.efficiency_metrics.get('utilization_efficiency', 0):.1f}")
        
        # Show cost breakdown
        print("\n📋 Cost Breakdown:")
        for component, amount in financial_impact.cost_by_component.items():
            print(f"   {component.value}: ${amount:.2f}")
        
        # Show savings opportunities
        print("\n💡 Savings Opportunities:")
        for opportunity in financial_impact.savings_opportunities:
            print(f"   • {opportunity}")
        
        # Test Mobile Workforce Scheduler pattern
        print("\n🚚 Testing Mobile Workforce Scheduler Pattern...")
        sites = ['site_001', 'site_002', 'site_003']
        employees = [employee_id]
        schedule_variants = [schedule_variant]
        
        optimization_results = await calculator.calculate_cross_site_optimization(
            sites, employees, schedule_variants
        )
        
        print(f"✅ Cross-site optimization completed")
        print(f"💰 Total cost savings: ${optimization_results['total_cost_savings']:.2f}")
        print(f"🏢 Site cost breakdown: {len(optimization_results['site_cost_breakdown'])} sites analyzed")
        
        # Validate BDD requirements
        validation = calculator.validate_bdd_requirements(financial_impact)
        print(f"\n✅ BDD Requirements Validation:")
        for requirement, passed in validation.items():
            status = "✅" if passed else "❌"
            print(f"   {status} {requirement}: {passed}")
        
        await calculator.close()
        return True
        
    except Exception as e:
        print(f"❌ Cost calculator test failed: {e}")
        import traceback
        traceback.print_exc()
        return False

async def test_cost_center_integration():
    """Test cost center budget integration"""
    print("\n🏢 Testing Cost Center Integration...")
    
    try:
        financial_service = await create_financial_data_service()
        
        # Get first available cost center
        query = "SELECT id FROM cost_centers WHERE is_active = true LIMIT 1"
        async with financial_service.async_session() as session:
            from sqlalchemy import text
            result = await session.execute(text(query))
            row = result.fetchone()
            
            if row:
                cost_center_id = str(row.id)
                print(f"🏢 Testing with cost center ID: {cost_center_id}")
                
                # Get budget utilization
                utilization = await financial_service.get_cost_center_budget_utilization(cost_center_id)
                print(f"✅ Budget utilization loaded:")
                print(f"   Total budget: ${utilization['total_budget']:,.2f}")
                print(f"   Utilized: ${utilization['utilized_budget']:,.2f}")
                print(f"   Utilization: {utilization['utilization_percentage']:.1f}%")
                print(f"   Employees: {utilization['employee_count']}")
                
                await financial_service.close()
                return True
            else:
                print("❌ No active cost centers found")
        
        await financial_service.close()
        return False
        
    except Exception as e:
        print(f"❌ Cost center integration test failed: {e}")
        return False

async def main():
    """Main test execution"""
    print("🧪 Starting Real Database Cost Calculator Tests")
    print("=" * 60)
    
    # Test sequence
    tests = [
        ("Financial Service Connection", test_financial_service_connection),
        ("Cost Calculator with Real Data", test_cost_calculator_with_real_data),
        ("Cost Center Integration", test_cost_center_integration)
    ]
    
    passed = 0
    total = len(tests)
    
    for test_name, test_func in tests:
        print(f"\n🔍 Running: {test_name}")
        print("-" * 40)
        
        try:
            result = await test_func()
            if result:
                passed += 1
                print(f"✅ {test_name} PASSED")
            else:
                print(f"❌ {test_name} FAILED")
        except Exception as e:
            print(f"💥 {test_name} CRASHED: {e}")
    
    print("\n" + "=" * 60)
    print(f"🏁 Test Results: {passed}/{total} tests passed")
    
    if passed == total:
        print("🎉 All tests passed! Real database integration successful.")
        return 0
    else:
        print("⚠️  Some tests failed. Check the logs above.")
        return 1

if __name__ == "__main__":
    exit_code = asyncio.run(main())
    sys.exit(exit_code)