"""
Test data fixtures and factories for WFM tests
"""
from datetime import datetime, timedelta, time
from typing import List, Dict, Any
import random
import factory
from faker import Faker
from dataclasses import dataclass, field


fake = Faker()


# Data models for test data
@dataclass
class TestEmployee:
    id: int
    name: str
    email: str
    phone: str
    skills: List[str] = field(default_factory=list)
    max_hours_per_week: int = 40
    hire_date: datetime = field(default_factory=datetime.now)
    shift_preference: str = "any"
    availability: Dict[str, List[str]] = field(default_factory=dict)


@dataclass
class TestShift:
    id: int
    employee_id: int
    date: str
    start_time: str
    end_time: str
    skill_id: int = None
    break_duration: int = 30


@dataclass
class TestSchedule:
    id: int
    name: str
    start_date: str
    end_date: str
    shifts: List[TestShift] = field(default_factory=list)
    status: str = "draft"


# Factory classes
class EmployeeFactory(factory.Factory):
    """Factory for creating test employees"""
    class Meta:
        model = TestEmployee
    
    id = factory.Sequence(lambda n: n + 1)
    name = factory.Faker('name')
    email = factory.LazyAttribute(lambda obj: f"{obj.name.lower().replace(' ', '.')}@test.com")
    phone = factory.Faker('phone_number')
    skills = factory.LazyFunction(lambda: random.sample(['sales', 'support', 'technical', 'billing'], k=random.randint(1, 3)))
    max_hours_per_week = factory.Faker('random_element', elements=[30, 35, 40])
    hire_date = factory.Faker('date_between', start_date='-2y', end_date='-1m')
    shift_preference = factory.Faker('random_element', elements=['morning', 'evening', 'night', 'any'])
    
    @factory.lazy_attribute
    def availability(self):
        """Generate realistic availability patterns"""
        days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
        availability = {}
        
        for day in days:
            if random.random() < 0.9:  # 90% chance available on any day
                if self.shift_preference == 'morning':
                    availability[day] = ['06:00-14:00', '07:00-15:00', '08:00-16:00']
                elif self.shift_preference == 'evening':
                    availability[day] = ['14:00-22:00', '15:00-23:00', '16:00-00:00']
                elif self.shift_preference == 'night':
                    availability[day] = ['22:00-06:00', '23:00-07:00']
                else:
                    availability[day] = ['06:00-14:00', '08:00-16:00', '14:00-22:00', '16:00-00:00']
        
        return availability


class ShiftFactory(factory.Factory):
    """Factory for creating test shifts"""
    class Meta:
        model = TestShift
    
    id = factory.Sequence(lambda n: n + 1)
    employee_id = factory.Faker('random_int', min=1, max=100)
    date = factory.LazyFunction(lambda: (datetime.now() + timedelta(days=random.randint(1, 30))).strftime('%Y-%m-%d'))
    start_time = factory.Faker('random_element', elements=['06:00', '08:00', '14:00', '16:00', '22:00'])
    
    @factory.lazy_attribute
    def end_time(self):
        """Calculate end time based on start time"""
        start_hour = int(self.start_time.split(':')[0])
        duration = random.choice([8, 10, 12])
        end_hour = (start_hour + duration) % 24
        return f"{end_hour:02d}:00"
    
    skill_id = factory.Faker('random_int', min=1, max=5)
    break_duration = factory.Faker('random_element', elements=[0, 30, 60])


# Helper functions for creating test data
def create_test_employee(**kwargs) -> Dict[str, Any]:
    """Create a test employee with optional overrides"""
    employee = EmployeeFactory(**kwargs)
    return {
        'id': employee.id,
        'name': employee.name,
        'email': employee.email,
        'phone': employee.phone,
        'skills': employee.skills,
        'max_hours_per_week': employee.max_hours_per_week,
        'hire_date': employee.hire_date.isoformat(),
        'shift_preference': employee.shift_preference,
        'availability': employee.availability
    }


def create_test_schedule(client, auth_headers, test_data) -> Dict[str, Any]:
    """Create a test schedule via API"""
    employees = test_data.get('employees', [])
    
    schedule_data = {
        'name': f'Test Schedule {datetime.now().strftime("%Y%m%d%H%M%S")}',
        'start_date': (datetime.now() + timedelta(days=7)).strftime('%Y-%m-%d'),
        'end_date': (datetime.now() + timedelta(days=13)).strftime('%Y-%m-%d'),
        'employee_ids': [emp.id for emp in employees[:10]]  # Use first 10 employees
    }
    
    response = client.post('/api/schedules', json=schedule_data, headers=auth_headers)
    schedule = response.json()
    
    # Add some shifts
    shifts = []
    for i, emp_id in enumerate(schedule_data['employee_ids']):
        for day in range(7):
            if random.random() < 0.7:  # 70% chance of shift on any day
                shift_date = datetime.strptime(schedule_data['start_date'], '%Y-%m-%d') + timedelta(days=day)
                shift_data = {
                    'employee_id': emp_id,
                    'date': shift_date.strftime('%Y-%m-%d'),
                    'start_time': '08:00' if i % 2 == 0 else '14:00',
                    'end_time': '16:00' if i % 2 == 0 else '22:00',
                    'skill_id': test_data['skills'][i % len(test_data['skills'])].id
                }
                
                shift_response = client.post(
                    f'/api/schedules/{schedule["id"]}/shifts',
                    json=shift_data,
                    headers=auth_headers
                )
                if shift_response.status_code == 201:
                    shifts.append(shift_response.json())
    
    schedule['shifts'] = shifts
    return schedule


def create_test_shifts(num_shifts: int = 10) -> List[Dict[str, Any]]:
    """Create multiple test shifts"""
    return [ShiftFactory().__dict__ for _ in range(num_shifts)]


# Mock data generators
def generate_forecast_data(start_date: str, end_date: str, skill_groups: List[str]) -> Dict[str, Any]:
    """Generate mock forecast data"""
    start = datetime.strptime(start_date, '%Y-%m-%d')
    end = datetime.strptime(end_date, '%Y-%m-%d')
    days = (end - start).days + 1
    
    forecast = {
        'start_date': start_date,
        'end_date': end_date,
        'skill_groups': {},
        'accuracy_metrics': {
            'mape': random.uniform(5, 15),
            'rmse': random.uniform(10, 30),
            'confidence_interval': 0.95
        }
    }
    
    for skill in skill_groups:
        daily_forecasts = []
        for day in range(days):
            date = (start + timedelta(days=day)).strftime('%Y-%m-%d')
            hourly_volumes = []
            
            # Generate realistic call volume pattern
            for hour in range(24):
                if 8 <= hour <= 20:  # Business hours
                    base_volume = random.randint(50, 150)
                    if hour in [10, 11, 14, 15]:  # Peak hours
                        volume = base_volume * 1.5
                    else:
                        volume = base_volume
                else:
                    volume = random.randint(5, 20)
                
                hourly_volumes.append({
                    'hour': hour,
                    'volume': int(volume),
                    'confidence_lower': int(volume * 0.85),
                    'confidence_upper': int(volume * 1.15)
                })
            
            daily_forecasts.append({
                'date': date,
                'hourly_volumes': hourly_volumes,
                'total_volume': sum(h['volume'] for h in hourly_volumes)
            })
        
        forecast['skill_groups'][skill] = daily_forecasts
    
    return forecast


def generate_labor_standards() -> Dict[str, Any]:
    """Generate labor standards test data"""
    standards = {}
    days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
    
    for day in days:
        day_standards = {}
        for hour in range(24):
            if 8 <= hour <= 20:  # Business hours
                day_standards[str(hour)] = {
                    'sales': random.randint(2, 8),
                    'support': random.randint(1, 5),
                    'technical': random.randint(1, 3)
                }
            else:
                day_standards[str(hour)] = {
                    'sales': random.randint(0, 2),
                    'support': random.randint(0, 1),
                    'technical': 0
                }
        standards[day] = day_standards
    
    return standards


# Test scenario generators
def generate_complex_schedule_scenario() -> Dict[str, Any]:
    """Generate a complex scheduling scenario for testing"""
    return {
        'employees': [create_test_employee() for _ in range(50)],
        'date_range': {
            'start': (datetime.now() + timedelta(days=14)).strftime('%Y-%m-%d'),
            'end': (datetime.now() + timedelta(days=28)).strftime('%Y-%m-%d')
        },
        'constraints': {
            'max_consecutive_days': 6,
            'min_rest_hours': 11,
            'max_shift_length': 12,
            'min_shift_length': 4,
            'max_weekly_hours': 48
        },
        'special_requirements': [
            {
                'date': (datetime.now() + timedelta(days=20)).strftime('%Y-%m-%d'),
                'requirement': 'Double coverage for sales',
                'multiplier': 2.0
            },
            {
                'date': (datetime.now() + timedelta(days=25)).strftime('%Y-%m-%d'),
                'requirement': 'Holiday - minimal staffing',
                'multiplier': 0.3
            }
        ],
        'pre_assigned_shifts': [
            {
                'employee_id': 1,
                'date': (datetime.now() + timedelta(days=15)).strftime('%Y-%m-%d'),
                'start_time': '08:00',
                'end_time': '16:00',
                'locked': True
            }
        ]
    }


def generate_stress_test_data(num_employees: int = 1000, num_days: int = 90) -> Dict[str, Any]:
    """Generate large-scale test data for stress testing"""
    return {
        'employees': [create_test_employee(id=i) for i in range(1, num_employees + 1)],
        'date_range': {
            'start': datetime.now().strftime('%Y-%m-%d'),
            'end': (datetime.now() + timedelta(days=num_days)).strftime('%Y-%m-%d')
        },
        'shifts_per_day': num_employees * 0.7,  # 70% coverage
        'skills': ['sales', 'support', 'technical', 'billing', 'quality'],
        'locations': [f'Location_{i}' for i in range(1, 11)]
    }


# Mock data for frontend tests
mock_schedule_data = {
    'id': 1,
    'name': 'Week 1 Schedule',
    'start_date': '2024-01-01',
    'end_date': '2024-01-07',
    'status': 'published',
    'shifts': [
        {
            'id': 1,
            'employeeId': 1,
            'date': '2024-01-01',
            'startTime': '08:00',
            'endTime': '16:00',
            'skill': 'sales'
        },
        {
            'id': 2,
            'employeeId': 2,
            'date': '2024-01-01',
            'startTime': '14:00',
            'endTime': '22:00',
            'skill': 'support'
        }
    ],
    'metrics': {
        'coverage': 0.95,
        'efficiency': 0.88,
        'cost': 12500.00
    }
}


mock_employees = [
    {
        'id': 1,
        'name': 'John Doe',
        'email': 'john.doe@test.com',
        'skills': ['sales', 'support'],
        'availability': 'full-time'
    },
    {
        'id': 2,
        'name': 'Jane Smith',
        'email': 'jane.smith@test.com',
        'skills': ['support'],
        'availability': 'part-time'
    }
]