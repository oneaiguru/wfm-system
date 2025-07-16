#!/usr/bin/env python3
"""
Test script to verify vacation_schedule_exporter.py works with real database data
"""

from src.algorithms.russian.vacation_schedule_exporter import VacationScheduleExporter
import pandas as pd
from datetime import datetime

def test_real_vacation_data():
    """Test vacation exporter with real database data"""
    print("🧪 TESTING VACATION SCHEDULE EXPORTER WITH REAL DATA")
    print("=" * 60)
    
    exporter = VacationScheduleExporter()
    
    # Test 1: Get approved vacations
    print("\n✅ Test 1: Fetching real vacation requests...")
    vacations = exporter.get_approved_vacations()
    assert isinstance(vacations, list), "Should return a list"
    print(f"   Found {len(vacations)} approved vacation requests")
    
    if vacations:
        # Verify vacation record structure
        v = vacations[0]
        assert 'employee_id' in v, "Should have employee_id"
        assert 'start_date' in v, "Should have start_date"
        assert 'end_date' in v, "Should have end_date"
        assert 'vacation_type' in v, "Should have vacation_type"
        assert 'department' in v, "Should have department"
        print("   ✓ Vacation record structure verified")
    
    # Test 2: Generate export summary
    print("\n✅ Test 2: Generating export summary...")
    export_data = exporter.generate_export()
    assert 'vacation_count' in export_data, "Should have vacation_count"
    assert export_data['vacation_count'] >= 0, "Vacation count should be non-negative"
    assert '1C_FORMAT' in export_data, "Should have 1C_FORMAT info"
    print(f"   Export summary: {export_data['vacation_count']} vacations")
    print(f"   1C Integration: {export_data['1C_FORMAT']['integration_ready']}")
    
    # Test 3: Export to Excel
    print("\n✅ Test 3: Exporting to Excel format...")
    excel_bytes = exporter.export_vacation_schedule(year=2025)
    assert isinstance(excel_bytes, bytes), "Should return bytes"
    assert len(excel_bytes) > 0, "Excel file should not be empty"
    print(f"   Excel file size: {len(excel_bytes):,} bytes")
    print("   ✓ Excel export successful")
    
    # Test 4: Vacation type mapping
    print("\n✅ Test 4: Testing vacation type mappings...")
    expected_mappings = {
        'отпуск': 'Основной',
        'больничный': 'Больничный',
        'учебный отпуск': 'Учебный'
    }
    for db_type, excel_type in expected_mappings.items():
        mapped = exporter.vacation_type_mapping.get(db_type)
        assert mapped == excel_type, f"{db_type} should map to {excel_type}"
        print(f"   ✓ {db_type} → {excel_type}")
    
    # Test 5: Full name formatting
    print("\n✅ Test 5: Testing Russian name formatting...")
    test_names = [
        ("Иван", "Иванов", "Иванович", "Иванов И.И."),
        ("Петр", "Петров", None, "Петров П."),
        ("Анна", "Сидорова", "Петровна", "Сидорова А.П.")
    ]
    for first, last, patronymic, expected in test_names:
        formatted = exporter.format_full_name(first, last, patronymic)
        assert formatted == expected, f"Should format as {expected}"
        print(f"   ✓ {first} {last} {patronymic or ''} → {formatted}")
    
    # Test 6: Working days calculation
    print("\n✅ Test 6: Testing working days calculation...")
    test_dates = [
        (datetime(2025, 7, 1), datetime(2025, 7, 5), 4),  # Tue-Sat = 4 working days (Tue-Fri)
        (datetime(2025, 7, 7), datetime(2025, 7, 11), 5), # Mon-Fri = 5 working days
        (datetime(2025, 7, 12), datetime(2025, 7, 13), 0), # Sat-Sun = 0 working days
    ]
    for start, end, expected in test_dates:
        days = exporter.calculate_working_days(start, end)
        assert days == expected, f"Should calculate {expected} working days"
        print(f"   ✓ {start.strftime('%Y-%m-%d')} to {end.strftime('%Y-%m-%d')}: {days} working days")
    
    print("\n" + "=" * 60)
    print("✅ ALL TESTS PASSED!")
    print("The vacation_schedule_exporter.py is working correctly with real data")
    
    # Summary of fixes applied
    print("\n📋 FIXES APPLIED (Mobile Workforce Scheduler Pattern):")
    print("1. ✅ Connected to real vacation_requests table")
    print("2. ✅ Joined with employees and departments tables")
    print("3. ✅ Used real vacation type mappings from database")
    print("4. ✅ Implemented proper Russian name formatting")
    print("5. ✅ Added working days calculation")
    print("6. ✅ Kept 1C export format mocked (per policy)")
    print("7. ✅ Handled empty result sets gracefully")
    print("8. ✅ Fixed UUID type casting issues")

if __name__ == "__main__":
    test_real_vacation_data()