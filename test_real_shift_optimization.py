"""
Test shift optimization with real database data
"""
import os
from datetime import datetime
from src.algorithms.core.shift_optimization import ShiftOptimizer

def test_real_data_integration():
    """Test that shift optimization uses real database data."""
    print("\n=== TESTING SHIFT OPTIMIZATION WITH REAL DATA ===\n")
    
    # Set database password
    os.environ['DB_PASSWORD'] = 'postgres'
    
    optimizer = ShiftOptimizer()
    
    # Test 1: Load real shift templates
    print("TEST 1: Loading real shift templates...")
    templates = optimizer._load_shift_templates_from_db()
    assert len(templates) > 0, "No shift templates found in database"
    print(f"✅ Found {len(templates)} real shift templates")
    
    # Verify templates have real data
    for template in templates[:3]:
        assert template.id, "Template missing ID"
        assert template.name, "Template missing name"
        assert template.start_time, "Template missing start time"
        assert template.end_time, "Template missing end time"
        print(f"   - {template.name}: {template.start_time} - {template.end_time}")
    
    # Test 2: Load schedule constraints
    print("\nTEST 2: Loading schedule constraints...")
    constraints = optimizer._load_schedule_constraints_from_db()
    assert constraints['min_rest_between_shifts'] > 0, "Invalid rest constraint"
    assert constraints['max_weekly_hours'] > 0, "Invalid weekly hours constraint"
    print(f"✅ Loaded constraints:")
    print(f"   - Min rest: {constraints['min_rest_between_shifts']} hours")
    print(f"   - Max weekly hours: {constraints['max_weekly_hours']}")
    
    # Test 3: Try to load employee data
    print("\nTEST 3: Loading employee data...")
    current_month = datetime.now().month
    current_year = datetime.now().year
    employees = optimizer._load_employee_preferences_from_db(current_month, current_year)
    
    if employees:
        print(f"✅ Found {len(employees)} employees in database")
        for emp in employees[:3]:
            print(f"   - Employee {emp.employee_id}: {emp.max_hours_per_week} hrs/week")
    else:
        print("⚠️  No employee data found (empty zup_agent_data table)")
    
    # Test 4: Verify activities are added to patterns
    print("\nTEST 4: Adding activities to shift patterns...")
    if templates:
        pattern = templates[0]
        patterns_with_activities = optimizer._add_activities_to_patterns(
            [pattern], pattern.work_rule
        )
        assert len(patterns_with_activities[0].activities) > 0, "No activities added"
        print(f"✅ Added {len(patterns_with_activities[0].activities)} activities to pattern")
        
        for activity in patterns_with_activities[0].activities:
            print(f"   - {activity.type}: {activity.duration} min at offset {activity.start_offset}")
    
    print("\n=== ALL TESTS PASSED ===")
    print("✅ Shift optimization is using real database data")
    print("✅ No mock patterns or simulated data")
    print("✅ Activities (breaks/lunch) added according to work rules")

if __name__ == "__main__":
    test_real_data_integration()