# 📋 SUBAGENT TASK: Fix Vacation Schedule Exporter

## 🎯 Task Information
- **Task ID**: FIX_VACATION_PROCESSOR
- **File**: src/algorithms/russian/vacation_schedule_exporter.py
- **Priority**: Critical
- **Pattern**: Mobile Workforce Scheduler fix

## 🚨 Current Problem
- Likely uses mock vacation data
- May not connect to real vacation_requests table
- Returns simulated 1C export data

## 🔧 Fix Pattern (From Mobile Workforce Success)
1. **Find Real Tables**: 
   ```bash
   psql -U postgres -d wfm_enterprise -c "\dt" | grep -E "(vacation|holiday|leave|absence)"
   ```
2. **Check Current Queries**: See what vacation tables exist
3. **Map to Real Schema**: 
   - vacation_requests
   - vacation_schemes
   - employee_vacation_balances
   - vacation_planning_periods
4. **Test with Real Data**: Verify exports real vacation schedules
5. **1C Integration**: This can remain mocked per policy

## 📊 Expected Real Tables to Use
- vacation_requests (employee vacation requests)
- vacation_schemes (business rules)
- employee_vacation_preferences
- public_holidays / production_calendar
- vacation_approvals

## ✅ Success Criteria
- [ ] Reads real vacation requests from database
- [ ] Processes actual employee vacation balances
- [ ] Applies real business rules (min/max days)
- [ ] Exports in correct 1C format (can be mocked)
- [ ] Handles Russian labor law requirements

## 🧪 Verification Commands
```python
# Test algorithm with real data
from src.algorithms.russian.vacation_schedule_exporter import VacationScheduleExporter
exporter = VacationScheduleExporter()

# Get real vacation data
vacations = exporter.get_approved_vacations()
assert len(vacations) > 0  # Should find real vacation records
assert all(v.get('employee_id') for v in vacations)  # Real employees

# Test export generation
export_data = exporter.generate_export()
assert export_data['vacation_count'] > 0
assert '1C_FORMAT' in export_data  # 1C format can be mocked
print(f"Exported {export_data['vacation_count']} real vacation schedules")
```

## 🔍 Common Issues to Fix
1. Replace mock vacation generator with real vacation_requests query
2. Connect to real employee and department data
3. Apply actual vacation scheme rules
4. Use real production calendar for holidays
5. Keep 1C API simulation (allowed exception)

## 📋 Russian Specifics
- Vacation types: Основной (main), Дополнительный (additional)
- Minimum 28 calendar days per year
- Carryover rules and expiration
- Integration with TK RF requirements