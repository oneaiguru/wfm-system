"""
Integration tests for Schedule API endpoints
"""
import pytest
from httpx import AsyncClient
from datetime import datetime, timedelta
from sqlalchemy.ext.asyncio import AsyncSession
from src.main import app
from src.database.models import Employee, Schedule, Shift, Skill
from tests.fixtures.test_data import (
    create_test_employee,
    create_test_schedule,
    create_test_shifts
)


@pytest.mark.integration
@pytest.mark.asyncio
class TestScheduleAPIIntegration:
    """Test suite for schedule API integration"""
    
    @pytest.fixture
    async def client(self):
        """Create test client"""
        async with AsyncClient(app=app, base_url="http://test") as client:
            yield client
    
    @pytest.fixture
    async def auth_headers(self, client):
        """Get authentication headers"""
        response = await client.post("/api/auth/login", json={
            "email": "admin@test.com",
            "password": "testpass123"
        })
        token = response.json()["access_token"]
        return {"Authorization": f"Bearer {token}"}
    
    @pytest.fixture
    async def test_data(self, db_session: AsyncSession):
        """Create test data"""
        # Create skills
        skills = [
            Skill(name="sales", description="Sales skill"),
            Skill(name="support", description="Support skill")
        ]
        db_session.add_all(skills)
        
        # Create employees
        employees = []
        for i in range(5):
            employee = Employee(
                name=f"Employee {i+1}",
                email=f"employee{i+1}@test.com",
                phone=f"+1234567890{i}",
                hire_date=datetime.now() - timedelta(days=365)
            )
            employee.skills = [skills[i % 2]]  # Alternate skills
            employees.append(employee)
            db_session.add(employee)
        
        await db_session.commit()
        
        return {
            "employees": employees,
            "skills": skills
        }
    
    async def test_create_schedule_complete_flow(self, client, auth_headers, test_data):
        """Test complete schedule creation flow"""
        # Step 1: Get available employees
        response = await client.get(
            "/api/employees/available",
            params={
                "start_date": "2024-01-01",
                "end_date": "2024-01-07"
            },
            headers=auth_headers
        )
        assert response.status_code == 200
        available_employees = response.json()
        assert len(available_employees) == 5
        
        # Step 2: Check labor standards
        response = await client.get(
            "/api/labor-standards/requirements",
            params={
                "date": "2024-01-01",
                "skill": "sales"
            },
            headers=auth_headers
        )
        assert response.status_code == 200
        requirements = response.json()
        
        # Step 3: Generate forecast
        response = await client.post(
            "/api/forecasts/generate",
            json={
                "start_date": "2024-01-01",
                "end_date": "2024-01-07",
                "skill_groups": ["sales", "support"],
                "historical_weeks": 4
            },
            headers=auth_headers
        )
        assert response.status_code == 201
        forecast = response.json()
        assert "forecast_id" in forecast
        
        # Step 4: Create schedule with forecast
        response = await client.post(
            "/api/schedules",
            json={
                "name": "Week 1 Schedule",
                "start_date": "2024-01-01",
                "end_date": "2024-01-07",
                "forecast_id": forecast["forecast_id"],
                "employee_ids": [emp["id"] for emp in available_employees],
                "optimization_params": {
                    "min_coverage": 0.8,
                    "max_consecutive_days": 5,
                    "min_rest_hours": 8
                }
            },
            headers=auth_headers
        )
        assert response.status_code == 201
        schedule = response.json()
        assert schedule["status"] == "draft"
        schedule_id = schedule["id"]
        
        # Step 5: Review generated shifts
        response = await client.get(
            f"/api/schedules/{schedule_id}/shifts",
            headers=auth_headers
        )
        assert response.status_code == 200
        shifts = response.json()
        assert len(shifts) > 0
        
        # Verify shift constraints
        for shift in shifts:
            assert shift["duration_hours"] <= 12
            assert shift["duration_hours"] >= 4
        
        # Step 6: Validate schedule
        response = await client.post(
            f"/api/schedules/{schedule_id}/validate",
            headers=auth_headers
        )
        assert response.status_code == 200
        validation = response.json()
        assert validation["is_valid"] == True
        
        # Step 7: Publish schedule
        response = await client.post(
            f"/api/schedules/{schedule_id}/publish",
            headers=auth_headers
        )
        assert response.status_code == 200
        published = response.json()
        assert published["status"] == "published"
        
        # Step 8: Verify notifications sent
        response = await client.get(
            f"/api/schedules/{schedule_id}/notifications",
            headers=auth_headers
        )
        assert response.status_code == 200
        notifications = response.json()
        assert len(notifications) == len(available_employees)
    
    async def test_schedule_modification_with_conflicts(self, client, auth_headers, test_data):
        """Test schedule modification with conflict detection"""
        # Create initial schedule
        create_response = await client.post(
            "/api/schedules",
            json={
                "name": "Test Schedule",
                "start_date": "2024-01-01",
                "end_date": "2024-01-07"
            },
            headers=auth_headers
        )
        schedule_id = create_response.json()["id"]
        
        # Add first shift
        shift1_response = await client.post(
            f"/api/schedules/{schedule_id}/shifts",
            json={
                "employee_id": test_data["employees"][0].id,
                "date": "2024-01-01",
                "start_time": "08:00",
                "end_time": "16:00",
                "skill_id": test_data["skills"][0].id
            },
            headers=auth_headers
        )
        assert shift1_response.status_code == 201
        
        # Try to add overlapping shift (should fail)
        shift2_response = await client.post(
            f"/api/schedules/{schedule_id}/shifts",
            json={
                "employee_id": test_data["employees"][0].id,
                "date": "2024-01-01",
                "start_time": "14:00",
                "end_time": "22:00",
                "skill_id": test_data["skills"][0].id
            },
            headers=auth_headers
        )
        assert shift2_response.status_code == 409
        assert "overlap" in shift2_response.json()["detail"].lower()
        
        # Add non-overlapping shift (should succeed)
        shift3_response = await client.post(
            f"/api/schedules/{schedule_id}/shifts",
            json={
                "employee_id": test_data["employees"][0].id,
                "date": "2024-01-02",
                "start_time": "08:00",
                "end_time": "16:00",
                "skill_id": test_data["skills"][0].id
            },
            headers=auth_headers
        )
        assert shift3_response.status_code == 201
    
    async def test_schedule_swap_request_workflow(self, client, auth_headers, test_data):
        """Test shift swap request workflow"""
        # Create schedule with shifts
        schedule = await create_test_schedule(client, auth_headers, test_data)
        
        # Employee requests shift swap
        swap_response = await client.post(
            "/api/shift-swaps",
            json={
                "requester_id": test_data["employees"][0].id,
                "shift_id": schedule["shifts"][0]["id"],
                "reason": "Personal appointment"
            },
            headers=auth_headers
        )
        assert swap_response.status_code == 201
        swap_request = swap_response.json()
        
        # Get eligible employees for swap
        eligible_response = await client.get(
            f"/api/shift-swaps/{swap_request['id']}/eligible-employees",
            headers=auth_headers
        )
        assert eligible_response.status_code == 200
        eligible = eligible_response.json()
        assert len(eligible) > 0
        
        # Another employee accepts the swap
        accept_response = await client.post(
            f"/api/shift-swaps/{swap_request['id']}/accept",
            json={
                "acceptor_id": eligible[0]["id"]
            },
            headers=auth_headers
        )
        assert accept_response.status_code == 200
        
        # Manager approves the swap
        approve_response = await client.post(
            f"/api/shift-swaps/{swap_request['id']}/approve",
            headers=auth_headers
        )
        assert approve_response.status_code == 200
        
        # Verify schedule is updated
        updated_schedule = await client.get(
            f"/api/schedules/{schedule['id']}/shifts",
            headers=auth_headers
        )
        updated_shifts = updated_schedule.json()
        
        # Find the swapped shift
        swapped_shift = next(
            s for s in updated_shifts 
            if s["id"] == schedule["shifts"][0]["id"]
        )
        assert swapped_shift["employee_id"] == eligible[0]["id"]
    
    async def test_schedule_performance_metrics(self, client, auth_headers, test_data):
        """Test schedule performance metrics calculation"""
        # Create and publish a schedule
        schedule = await create_test_schedule(client, auth_headers, test_data)
        
        # Get schedule metrics
        metrics_response = await client.get(
            f"/api/schedules/{schedule['id']}/metrics",
            headers=auth_headers
        )
        assert metrics_response.status_code == 200
        metrics = metrics_response.json()
        
        # Verify metrics structure
        assert "coverage" in metrics
        assert "labor_cost" in metrics
        assert "efficiency" in metrics
        assert "fairness" in metrics
        
        # Check coverage metrics
        assert metrics["coverage"]["average"] >= 0
        assert metrics["coverage"]["minimum"] >= 0
        assert metrics["coverage"]["by_hour"] is not None
        
        # Check fairness metrics
        assert metrics["fairness"]["hours_variance"] >= 0
        assert metrics["fairness"]["shift_distribution"] is not None
    
    @pytest.mark.slow
    async def test_large_scale_schedule_generation(self, client, auth_headers, db_session):
        """Test schedule generation with many employees"""
        # Create 100 employees
        employees = []
        for i in range(100):
            emp = Employee(
                name=f"Large Scale Employee {i}",
                email=f"ls_employee{i}@test.com",
                phone=f"+199999{i:04d}",
                hire_date=datetime.now() - timedelta(days=30)
            )
            employees.append(emp)
            db_session.add(emp)
        
        await db_session.commit()
        
        # Generate schedule for all employees
        response = await client.post(
            "/api/schedules",
            json={
                "name": "Large Scale Schedule",
                "start_date": "2024-01-01",
                "end_date": "2024-01-07",
                "employee_ids": [emp.id for emp in employees],
                "auto_generate": True
            },
            headers=auth_headers,
            timeout=30.0  # Longer timeout for large operation
        )
        
        assert response.status_code == 201
        schedule = response.json()
        
        # Verify reasonable generation time
        assert schedule["generation_time_seconds"] < 10
        
        # Check shifts were created
        shifts_response = await client.get(
            f"/api/schedules/{schedule['id']}/shifts",
            headers=auth_headers
        )
        shifts = shifts_response.json()
        assert len(shifts) > 0
        
        # Verify fair distribution
        employee_hours = {}
        for shift in shifts:
            emp_id = shift["employee_id"]
            hours = shift["duration_hours"]
            employee_hours[emp_id] = employee_hours.get(emp_id, 0) + hours
        
        avg_hours = sum(employee_hours.values()) / len(employee_hours)
        variance = sum((h - avg_hours) ** 2 for h in employee_hours.values()) / len(employee_hours)
        
        # Hours should be fairly distributed (low variance)
        assert variance < 100  # Reasonable threshold


@pytest.mark.integration
@pytest.mark.asyncio
class TestScheduleWebSocketIntegration:
    """Test real-time schedule updates via WebSocket"""
    
    async def test_real_time_schedule_updates(self, client, auth_headers):
        """Test WebSocket notifications for schedule changes"""
        # This would typically use a WebSocket client
        # For now, we'll test the notification endpoints
        
        # Subscribe to schedule updates
        response = await client.post(
            "/api/notifications/subscribe",
            json={
                "channel": "schedule_updates",
                "schedule_id": 1
            },
            headers=auth_headers
        )
        assert response.status_code == 200
        subscription = response.json()
        
        # Simulate schedule change
        # In real test, this would trigger WebSocket message
        
        # Get notification history
        notifications = await client.get(
            "/api/notifications",
            params={"subscription_id": subscription["id"]},
            headers=auth_headers
        )
        assert notifications.status_code == 200