"""
Common test helper utilities for Python tests
"""
import asyncio
import json
import os
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional
from contextlib import asynccontextmanager
import pytest
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from httpx import AsyncClient


class TestDatabase:
    """Test database helper for managing test data"""
    
    def __init__(self, database_url: str):
        self.engine = create_async_engine(database_url, echo=False)
        self.async_session = sessionmaker(
            self.engine, class_=AsyncSession, expire_on_commit=False
        )
    
    @asynccontextmanager
    async def get_session(self):
        """Get database session for tests"""
        async with self.async_session() as session:
            try:
                yield session
                await session.commit()
            except Exception:
                await session.rollback()
                raise
            finally:
                await session.close()
    
    async def setup(self):
        """Setup test database"""
        # Create tables
        from src.database.models import Base
        async with self.engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
    
    async def teardown(self):
        """Teardown test database"""
        # Drop all tables
        from src.database.models import Base
        async with self.engine.begin() as conn:
            await conn.run_sync(Base.metadata.drop_all)
        
        await self.engine.dispose()
    
    async def seed_basic_data(self):
        """Seed basic test data"""
        async with self.get_session() as session:
            # Add skills
            from src.database.models import Skill
            skills = [
                Skill(name="sales", description="Sales skill"),
                Skill(name="support", description="Customer support"),
                Skill(name="technical", description="Technical support")
            ]
            session.add_all(skills)
            
            # Add employees
            from src.database.models import Employee
            employees = []
            for i in range(10):
                emp = Employee(
                    name=f"Test Employee {i+1}",
                    email=f"test{i+1}@example.com",
                    phone=f"+1234567890{i}",
                    hire_date=datetime.now() - timedelta(days=365)
                )
                emp.skills = [skills[i % len(skills)]]
                employees.append(emp)
            
            session.add_all(employees)
            await session.commit()


class APITestClient:
    """Enhanced test client for API testing"""
    
    def __init__(self, app, base_url: str = "http://test"):
        self.app = app
        self.base_url = base_url
        self.client: Optional[AsyncClient] = None
        self.auth_token: Optional[str] = None
    
    async def __aenter__(self):
        self.client = AsyncClient(app=self.app, base_url=self.base_url)
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        await self.client.aclose()
    
    async def login(self, email: str = "admin@test.com", password: str = "password123"):
        """Login and store auth token"""
        response = await self.client.post("/api/auth/login", json={
            "email": email,
            "password": password
        })
        
        if response.status_code == 200:
            self.auth_token = response.json()["access_token"]
            return self.auth_token
        else:
            raise Exception(f"Login failed: {response.status_code}")
    
    @property
    def auth_headers(self) -> Dict[str, str]:
        """Get authorization headers"""
        if not self.auth_token:
            raise Exception("Not authenticated. Call login() first.")
        return {"Authorization": f"Bearer {self.auth_token}"}
    
    async def get(self, url: str, **kwargs):
        """GET request with auth headers"""
        headers = kwargs.pop("headers", {})
        headers.update(self.auth_headers)
        return await self.client.get(url, headers=headers, **kwargs)
    
    async def post(self, url: str, **kwargs):
        """POST request with auth headers"""
        headers = kwargs.pop("headers", {})
        headers.update(self.auth_headers)
        return await self.client.post(url, headers=headers, **kwargs)
    
    async def put(self, url: str, **kwargs):
        """PUT request with auth headers"""
        headers = kwargs.pop("headers", {})
        headers.update(self.auth_headers)
        return await self.client.put(url, headers=headers, **kwargs)
    
    async def delete(self, url: str, **kwargs):
        """DELETE request with auth headers"""
        headers = kwargs.pop("headers", {})
        headers.update(self.auth_headers)
        return await self.client.delete(url, headers=headers, **kwargs)


class PerformanceTracker:
    """Track performance metrics during tests"""
    
    def __init__(self):
        self.metrics: List[Dict[str, Any]] = []
    
    def track(self, operation: str, duration: float, metadata: Dict[str, Any] = None):
        """Track a performance metric"""
        self.metrics.append({
            "operation": operation,
            "duration": duration,
            "timestamp": datetime.now().isoformat(),
            "metadata": metadata or {}
        })
    
    def get_stats(self, operation: Optional[str] = None) -> Dict[str, float]:
        """Get statistics for tracked metrics"""
        if operation:
            durations = [m["duration"] for m in self.metrics if m["operation"] == operation]
        else:
            durations = [m["duration"] for m in self.metrics]
        
        if not durations:
            return {"count": 0}
        
        return {
            "count": len(durations),
            "total": sum(durations),
            "average": sum(durations) / len(durations),
            "min": min(durations),
            "max": max(durations)
        }
    
    def assert_performance(self, operation: str, max_duration: float):
        """Assert that operation meets performance requirements"""
        stats = self.get_stats(operation)
        if stats["count"] > 0:
            assert stats["average"] <= max_duration, \
                f"{operation} average duration {stats['average']:.2f}s exceeds {max_duration}s"


def compare_schedules(actual: Dict[str, Any], expected: Dict[str, Any]) -> Dict[str, Any]:
    """Compare two schedules and return differences"""
    differences = {
        "shifts": [],
        "coverage": [],
        "metrics": {}
    }
    
    # Compare shifts
    actual_shifts = {(s["employee_id"], s["date"]): s for s in actual.get("shifts", [])}
    expected_shifts = {(s["employee_id"], s["date"]): s for s in expected.get("shifts", [])}
    
    # Find missing shifts
    for key in expected_shifts:
        if key not in actual_shifts:
            differences["shifts"].append({
                "type": "missing",
                "shift": expected_shifts[key]
            })
    
    # Find extra shifts
    for key in actual_shifts:
        if key not in expected_shifts:
            differences["shifts"].append({
                "type": "extra",
                "shift": actual_shifts[key]
            })
    
    # Compare matching shifts
    for key in set(actual_shifts) & set(expected_shifts):
        actual_shift = actual_shifts[key]
        expected_shift = expected_shifts[key]
        
        if actual_shift["start_time"] != expected_shift["start_time"] or \
           actual_shift["end_time"] != expected_shift["end_time"]:
            differences["shifts"].append({
                "type": "different",
                "actual": actual_shift,
                "expected": expected_shift
            })
    
    return differences


def validate_schedule_constraints(schedule: Dict[str, Any], constraints: Dict[str, Any]) -> List[str]:
    """Validate schedule against constraints"""
    violations = []
    shifts = schedule.get("shifts", [])
    
    # Group shifts by employee
    employee_shifts = {}
    for shift in shifts:
        emp_id = shift["employee_id"]
        if emp_id not in employee_shifts:
            employee_shifts[emp_id] = []
        employee_shifts[emp_id].append(shift)
    
    # Check constraints for each employee
    for emp_id, emp_shifts in employee_shifts.items():
        # Sort shifts by date
        emp_shifts.sort(key=lambda s: s["date"])
        
        # Check consecutive days
        if "max_consecutive_days" in constraints:
            consecutive = 1
            for i in range(1, len(emp_shifts)):
                prev_date = datetime.strptime(emp_shifts[i-1]["date"], "%Y-%m-%d")
                curr_date = datetime.strptime(emp_shifts[i]["date"], "%Y-%m-%d")
                
                if (curr_date - prev_date).days == 1:
                    consecutive += 1
                    if consecutive > constraints["max_consecutive_days"]:
                        violations.append(
                            f"Employee {emp_id} works {consecutive} consecutive days"
                        )
                else:
                    consecutive = 1
        
        # Check weekly hours
        if "max_weekly_hours" in constraints:
            weekly_hours = {}
            for shift in emp_shifts:
                week = datetime.strptime(shift["date"], "%Y-%m-%d").isocalendar()[1]
                start = datetime.strptime(shift["start_time"], "%H:%M")
                end = datetime.strptime(shift["end_time"], "%H:%M")
                hours = (end - start).seconds / 3600
                
                weekly_hours[week] = weekly_hours.get(week, 0) + hours
            
            for week, hours in weekly_hours.items():
                if hours > constraints["max_weekly_hours"]:
                    violations.append(
                        f"Employee {emp_id} scheduled for {hours}h in week {week}"
                    )
    
    return violations


def generate_test_report(test_results: List[Dict[str, Any]], output_file: str = "test_report.json"):
    """Generate a test report"""
    report = {
        "timestamp": datetime.now().isoformat(),
        "summary": {
            "total": len(test_results),
            "passed": sum(1 for r in test_results if r["status"] == "passed"),
            "failed": sum(1 for r in test_results if r["status"] == "failed"),
            "skipped": sum(1 for r in test_results if r["status"] == "skipped")
        },
        "results": test_results,
        "performance": {
            "slowest_tests": sorted(
                [r for r in test_results if "duration" in r],
                key=lambda x: x["duration"],
                reverse=True
            )[:10]
        }
    }
    
    with open(output_file, "w") as f:
        json.dump(report, f, indent=2)
    
    return report


# Pytest fixtures
@pytest.fixture
async def test_db():
    """Test database fixture"""
    db = TestDatabase(os.getenv("TEST_DATABASE_URL", "sqlite+aiosqlite:///:memory:"))
    await db.setup()
    await db.seed_basic_data()
    
    yield db
    
    await db.teardown()


@pytest.fixture
async def api_client(app):
    """API test client fixture"""
    async with APITestClient(app) as client:
        await client.login()
        yield client


@pytest.fixture
def performance_tracker():
    """Performance tracker fixture"""
    return PerformanceTracker()


# Decorators
def track_performance(operation: str):
    """Decorator to track test performance"""
    def decorator(func):
        async def wrapper(*args, **kwargs):
            import time
            start = time.time()
            
            result = await func(*args, **kwargs)
            
            duration = time.time() - start
            if "performance_tracker" in kwargs:
                kwargs["performance_tracker"].track(operation, duration)
            
            return result
        
        return wrapper
    return decorator