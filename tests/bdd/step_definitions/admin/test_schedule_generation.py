"""
Step definitions for schedule generation feature
"""
import pytest
from pytest_bdd import scenarios, given, when, then, parsers
from datetime import datetime, timedelta
from src.services import ScheduleService, EmployeeService
from src.algorithms import ScheduleOptimizer
from tests.fixtures.test_data import create_test_employee


# Load scenarios from feature file
scenarios('../../features/admin/schedule-generation.feature')


# Fixtures
@pytest.fixture
def schedule_service():
    return ScheduleService()


@pytest.fixture
def employee_service():
    return EmployeeService()


@pytest.fixture
def schedule_context():
    """Context to store data between steps"""
    return {
        'employees': [],
        'schedule': None,
        'labor_standards': {},
        'result': None,
        'warnings': [],
        'constraints': {}
    }


# Background steps
@given('I am logged in as a manager')
def logged_in_as_manager(auth_context):
    auth_context['user'] = {
        'id': 1,
        'role': 'manager',
        'permissions': ['schedule.create', 'schedule.edit', 'schedule.publish']
    }


@given(parsers.parse('the following employees exist:\n{employees_table}'))
def create_employees(employee_service, schedule_context, employees_table):
    """Create test employees from table data"""
    employees = []
    for row in parse_table(employees_table):
        employee = employee_service.create_employee({
            'name': row['name'],
            'skills': row['skills'].split(','),
            'max_hours_per_week': int(row['max_hours']),
            'shift_preference': row['preferred_shifts']
        })
        employees.append(employee)
    
    schedule_context['employees'] = employees


@given(parsers.parse('the following labor standards are configured:\n{standards_table}'))
def configure_labor_standards(schedule_context, standards_table):
    """Configure labor standards from table data"""
    standards = {}
    for row in parse_table(standards_table):
        key = f"{row['day']}_{row['hour']}"
        standards[key] = {
            'sales_required': int(row['sales_required']),
            'support_required': int(row['support_required'])
        }
    
    schedule_context['labor_standards'] = standards


# When steps
@when(parsers.parse('I create a new schedule for "{start_date}" to "{end_date}"'))
def create_new_schedule(schedule_context, start_date, end_date):
    """Initialize new schedule creation"""
    schedule_context['schedule_params'] = {
        'start_date': start_date,
        'end_date': end_date,
        'status': 'draft'
    }


@when('I select all available employees')
def select_all_employees(schedule_context):
    """Select all employees for scheduling"""
    schedule_context['schedule_params']['employee_ids'] = [
        emp.id for emp in schedule_context['employees']
    ]


@when(parsers.parse('I set the optimization goal to "{goal}"'))
def set_optimization_goal(schedule_context, goal):
    """Set optimization goal"""
    schedule_context['schedule_params']['optimization_goal'] = goal


@when('I generate the schedule')
def generate_schedule(schedule_service, schedule_context):
    """Generate the schedule with current parameters"""
    try:
        result = schedule_service.generate_schedule(
            **schedule_context['schedule_params'],
            labor_standards=schedule_context['labor_standards'],
            constraints=schedule_context.get('constraints', {})
        )
        schedule_context['result'] = result
        schedule_context['schedule'] = result['schedule']
        schedule_context['warnings'] = result.get('warnings', [])
    except Exception as e:
        schedule_context['error'] = str(e)


@when(parsers.parse('I enable "{option}" option'))
def enable_option(schedule_context, option):
    """Enable specific scheduling option"""
    if 'options' not in schedule_context['schedule_params']:
        schedule_context['schedule_params']['options'] = {}
    
    schedule_context['schedule_params']['options'][option] = True


@when(parsers.parse('I add the following constraints:\n{constraints_table}'))
def add_constraints(schedule_context, constraints_table):
    """Add scheduling constraints"""
    constraints = {}
    for row in parse_table(constraints_table):
        constraints[row['constraint_type']] = int(row['value'])
    
    schedule_context['constraints'] = constraints


@when('only 2 employees are available')
def limit_available_employees(schedule_context):
    """Limit available employees to simulate understaffing"""
    schedule_context['employees'] = schedule_context['employees'][:2]
    schedule_context['schedule_params']['employee_ids'] = [
        emp.id for emp in schedule_context['employees'][:2]
    ]


# Then steps
@then('the schedule should be created successfully')
def verify_schedule_created(schedule_context):
    """Verify schedule was created"""
    assert schedule_context['schedule'] is not None
    assert 'error' not in schedule_context
    assert schedule_context['schedule']['id'] is not None


@then('all labor standard requirements should be met')
def verify_labor_standards_met(schedule_context):
    """Verify all labor standards are satisfied"""
    schedule = schedule_context['schedule']
    coverage_analysis = analyze_coverage(
        schedule['shifts'],
        schedule_context['labor_standards']
    )
    
    for period, coverage in coverage_analysis.items():
        assert coverage['sales_actual'] >= coverage['sales_required'], \
            f"Sales coverage not met for {period}"
        assert coverage['support_actual'] >= coverage['support_required'], \
            f"Support coverage not met for {period}"


@then('no employee should work more than their maximum hours')
def verify_max_hours_respected(schedule_context):
    """Verify employee hour limits are respected"""
    schedule = schedule_context['schedule']
    employee_hours = calculate_employee_hours(schedule['shifts'])
    
    for employee in schedule_context['employees']:
        hours = employee_hours.get(employee.id, 0)
        assert hours <= employee.max_hours_per_week, \
            f"{employee.name} scheduled for {hours} hours, max is {employee.max_hours_per_week}"


@then(parsers.parse('the coverage percentage should be at least {min_coverage:d}%'))
def verify_coverage_percentage(schedule_context, min_coverage):
    """Verify minimum coverage percentage"""
    metrics = schedule_context['result']['metrics']
    assert metrics['coverage_percentage'] >= min_coverage


@then('employees with morning preference should have mostly morning shifts')
def verify_morning_preferences(schedule_context):
    """Verify morning shift preferences are respected"""
    preference_analysis = analyze_shift_preferences(
        schedule_context['schedule']['shifts'],
        schedule_context['employees']
    )
    
    for employee in schedule_context['employees']:
        if employee.shift_preference == 'morning':
            morning_percentage = preference_analysis[employee.id]['morning_percentage']
            assert morning_percentage >= 70, \
                f"{employee.name} only has {morning_percentage}% morning shifts"


@then('I should see a warning about insufficient staffing')
def verify_staffing_warning(schedule_context):
    """Verify understaffing warning is present"""
    warnings = schedule_context['warnings']
    staffing_warnings = [w for w in warnings if 'insufficient staffing' in w.lower()]
    assert len(staffing_warnings) > 0


@then(parsers.parse('the system should suggest hiring recommendations:\n{recommendations_table}'))
def verify_hiring_recommendations(schedule_context, recommendations_table):
    """Verify hiring recommendations match expected values"""
    recommendations = schedule_context['result'].get('hiring_recommendations', {})
    
    for row in parse_table(recommendations_table):
        skill = row['skill']
        expected = int(row['additional_needed'])
        actual = recommendations.get(skill, 0)
        assert actual == expected, \
            f"Expected {expected} additional {skill} employees, got {actual}"


@then('all shifts should respect the defined constraints')
def verify_constraints_respected(schedule_context):
    """Verify all constraints are satisfied"""
    schedule = schedule_context['schedule']
    constraints = schedule_context['constraints']
    
    validation_result = validate_schedule_constraints(
        schedule['shifts'],
        constraints
    )
    
    assert validation_result['valid'], \
        f"Constraint violations: {validation_result['violations']}"


# Helper functions
def parse_table(table_string):
    """Parse BDD table string into list of dicts"""
    lines = table_string.strip().split('\n')
    headers = [h.strip() for h in lines[0].split('|')[1:-1]]
    
    rows = []
    for line in lines[1:]:
        values = [v.strip() for v in line.split('|')[1:-1]]
        rows.append(dict(zip(headers, values)))
    
    return rows


def analyze_coverage(shifts, labor_standards):
    """Analyze schedule coverage against standards"""
    coverage = {}
    
    for shift in shifts:
        # Implementation would analyze actual vs required coverage
        pass
    
    return coverage


def calculate_employee_hours(shifts):
    """Calculate total hours per employee"""
    hours = {}
    
    for shift in shifts:
        employee_id = shift['employee_id']
        shift_hours = (shift['end_time'] - shift['start_time']).total_seconds() / 3600
        hours[employee_id] = hours.get(employee_id, 0) + shift_hours
    
    return hours


def analyze_shift_preferences(shifts, employees):
    """Analyze how well shift preferences are met"""
    analysis = {}
    
    for employee in employees:
        employee_shifts = [s for s in shifts if s['employee_id'] == employee.id]
        morning_shifts = sum(1 for s in employee_shifts if s['start_time'].hour < 12)
        
        analysis[employee.id] = {
            'morning_percentage': (morning_shifts / len(employee_shifts) * 100) if employee_shifts else 0
        }
    
    return analysis


def validate_schedule_constraints(shifts, constraints):
    """Validate schedule against constraints"""
    violations = []
    
    # Check consecutive days
    if 'max_consecutive_days' in constraints:
        # Implementation would check consecutive working days
        pass
    
    # Check shift lengths
    if 'max_shift_length' in constraints:
        for shift in shifts:
            length = (shift['end_time'] - shift['start_time']).total_seconds() / 3600
            if length > constraints['max_shift_length']:
                violations.append(f"Shift exceeds max length: {length} hours")
    
    return {
        'valid': len(violations) == 0,
        'violations': violations
    }