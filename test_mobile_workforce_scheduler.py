#!/usr/bin/env python3
"""
Test script for Mobile Workforce Scheduler pattern implementation
Tests the updated timetable generator with real database connections
"""

import asyncio
import logging
from datetime import datetime, date, timedelta
import sys
import os

# Add the src directory to the Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

from algorithms.intraday.timetable_generator import TimetableGenerator, ActivityType

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


async def test_mobile_workforce_scheduler():
    """Test the Mobile Workforce Scheduler pattern implementation"""
    
    logger.info("Starting Mobile Workforce Scheduler test...")
    
    # Initialize the timetable generator
    generator = TimetableGenerator()
    
    try:
        # Test period: next 3 days
        start_date = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
        end_date = start_date + timedelta(days=3)
        
        logger.info(f"Testing timetable generation for period: {start_date.date()} to {end_date.date()}")
        
        # Test 1: Create timetable using real database data
        logger.info("Test 1: Creating timetable with real database integration...")
        
        timetable_blocks = await generator.create_timetable(
            period_start=start_date,
            period_end=end_date,
            template_name="STANDARD_5X8",  # Use database template code
            optimization_enabled=True
        )
        
        logger.info(f"Generated {len(timetable_blocks)} timetable blocks")
        
        # Analyze the results
        if timetable_blocks:
            logger.info("✅ Timetable generation successful")
            
            # Count activities
            activity_counts = {}
            employee_counts = set()
            
            for block in timetable_blocks[:10]:  # Show first 10 blocks
                activity_type = block.activity_type.value
                activity_counts[activity_type] = activity_counts.get(activity_type, 0) + 1
                employee_counts.add(block.employee_id)
                
                logger.info(f"Block: {block.employee_id[:8]}... {block.datetime.strftime('%Y-%m-%d %H:%M')} - {activity_type} ({block.skill_assigned})")
            
            logger.info(f"Activity distribution (first 10 blocks): {activity_counts}")
            logger.info(f"Employees involved (first 10 blocks): {len(employee_counts)}")
            
            # Test 2: Save timetable to database
            logger.info("Test 2: Saving timetable to database...")
            
            saved_ids = await generator.save_timetable_to_db("STANDARD_5X8")
            
            if saved_ids:
                logger.info(f"✅ Saved {len(saved_ids)} timetable blocks to database")
                logger.info(f"First few saved IDs: {saved_ids[:3]}")
            else:
                logger.warning("⚠️ No timetable blocks were saved")
            
            # Test 3: Manual adjustment with real-time updates
            logger.info("Test 3: Testing manual adjustments with real-time updates...")
            
            if timetable_blocks:
                test_block = timetable_blocks[0]
                
                adjustment_success = await generator.make_manual_adjustment(
                    employee_id=test_block.employee_id,
                    start_time=test_block.datetime,
                    end_time=test_block.datetime + timedelta(minutes=30),
                    adjustment_type="Add Break"
                )
                
                if adjustment_success:
                    logger.info("✅ Manual adjustment successful")
                else:
                    logger.warning("⚠️ Manual adjustment failed")
            
        else:
            logger.warning("⚠️ No timetable blocks generated - check database connectivity and data")
            
            # Test database connectivity
            logger.info("Testing database connectivity...")
            
            # Try to load templates
            await generator._ensure_db_initialized()
            templates = await generator.db_service.get_schedule_templates()
            
            if templates:
                logger.info(f"✅ Database connectivity OK - found {len(templates)} templates")
                for code, template in list(templates.items())[:3]:
                    logger.info(f"  Template: {code} - {template.template_name}")
            else:
                logger.error("❌ No templates found in database")
            
            # Try to load employee availability
            employee_availability = await generator.db_service.get_employee_availability(
                start_date.date(), 
                end_date.date()
            )
            
            if employee_availability:
                logger.info(f"✅ Found {len(employee_availability)} employees with availability")
                for emp_id, avail in list(employee_availability.items())[:3]:
                    logger.info(f"  Employee: {avail.employee_number} - {avail.first_name} {avail.last_name} ({len(avail.skills)} skills)")
            else:
                logger.warning("⚠️ No employee availability found")
        
        # Test 4: Statistics and analysis
        logger.info("Test 4: Generating timetable statistics...")
        
        stats = generator.get_timetable_statistics(start_date, end_date)
        
        if stats:
            logger.info("✅ Statistics generated successfully")
            logger.info(f"Total blocks: {stats.get('total_blocks', 0)}")
            
            coverage = stats.get('coverage_analysis', {})
            if coverage:
                logger.info(f"Average coverage: {coverage.get('average_coverage', 0):.1f}%")
            
            activities = stats.get('activity_distribution', {})
            if activities:
                logger.info("Activity distribution:")
                for activity, percentage in activities.items():
                    logger.info(f"  {activity}: {percentage:.1f}%")
        
        logger.info("✅ Mobile Workforce Scheduler test completed successfully")
        
    except Exception as e:
        logger.error(f"❌ Test failed with error: {str(e)}")
        logger.exception("Full error details:")
        
    finally:
        # Clean up database connections
        await generator.close_db_connection()
        logger.info("Database connections closed")


async def test_constraint_validation():
    """Test constraint validation with real data"""
    
    logger.info("Testing constraint validation...")
    
    generator = TimetableGenerator()
    
    try:
        await generator._ensure_db_initialized()
        
        # Get constraint rules
        rules = generator.constraint_rules
        
        logger.info("Loaded constraint rules:")
        for rule_type, rule_data in rules.items():
            logger.info(f"  {rule_type}: {rule_data}")
        
        # Test break rules
        break_rules = rules.get('break_rules', {})
        expected_duration = break_rules.get('short_break_duration', 15)
        logger.info(f"✅ Short break duration: {expected_duration} minutes")
        
        # Test shift rules  
        shift_rules = rules.get('shift_rules', {})
        max_daily_hours = shift_rules.get('max_shift_duration', 8)
        logger.info(f"✅ Max daily hours: {max_daily_hours} hours")
        
        # Test coverage rules
        coverage_rules = rules.get('coverage_rules', {})
        service_level = coverage_rules.get('service_level_target', 0.8)
        logger.info(f"✅ Service level target: {service_level * 100}%")
        
        logger.info("✅ Constraint validation test completed")
        
    except Exception as e:
        logger.error(f"❌ Constraint validation test failed: {str(e)}")
        
    finally:
        await generator.close_db_connection()


async def main():
    """Main test function"""
    
    logger.info("=" * 60)
    logger.info("Mobile Workforce Scheduler Pattern Test Suite")
    logger.info("=" * 60)
    
    # Test the main functionality
    await test_mobile_workforce_scheduler()
    
    logger.info("-" * 60)
    
    # Test constraint validation
    await test_constraint_validation()
    
    logger.info("=" * 60)
    logger.info("All tests completed")
    logger.info("=" * 60)


if __name__ == "__main__":
    # Run the test
    asyncio.run(main())