"""
Performance tests for WFM Enterprise System using Locust
"""
from locust import HttpUser, task, between, tag
from locust.exception import RescheduleTask
import json
import random
from datetime import datetime, timedelta


class WFMUser(HttpUser):
    """Base class for WFM system users"""
    wait_time = between(1, 3)
    
    def on_start(self):
        """Login and setup before testing"""
        self.login()
        self.setup_test_data()
    
    def login(self):
        """Authenticate user"""
        response = self.client.post("/api/auth/login", json={
            "email": f"user{random.randint(1, 100)}@test.com",
            "password": "password123"
        })
        
        if response.status_code == 200:
            self.token = response.json()["access_token"]
            self.headers = {"Authorization": f"Bearer {self.token}"}
        else:
            raise RescheduleTask()
    
    def setup_test_data(self):
        """Setup user-specific test data"""
        self.employee_id = random.randint(1, 100)
        self.skill_ids = [random.randint(1, 5) for _ in range(2)]
        self.current_date = datetime.now().strftime("%Y-%m-%d")


class EmployeeUser(WFMUser):
    """Employee user behavior"""
    weight = 8  # 80% of users are employees
    
    @task(3)
    @tag('critical')
    def view_schedule(self):
        """View current schedule - most common operation"""
        with self.client.get(
            f"/api/schedules/my-schedule?date={self.current_date}",
            headers=self.headers,
            catch_response=True
        ) as response:
            if response.elapsed.total_seconds() > 2:
                response.failure("Schedule load too slow")
    
    @task(2)
    def view_calendar(self):
        """View monthly calendar"""
        month = datetime.now().strftime("%Y-%m")
        self.client.get(
            f"/api/calendar/month/{month}",
            headers=self.headers,
            name="/api/calendar/month/[month]"
        )
    
    @task(1)
    def create_time_off_request(self):
        """Create time off request"""
        future_date = (datetime.now() + timedelta(days=random.randint(7, 30))).strftime("%Y-%m-%d")
        
        self.client.post(
            "/api/requests",
            json={
                "type": "time_off",
                "date": future_date,
                "hours": random.choice([4, 8]),
                "reason": "Personal"
            },
            headers=self.headers
        )
    
    @task(1)
    def view_shift_marketplace(self):
        """Browse available shifts"""
        self.client.get(
            "/api/shifts/marketplace",
            headers=self.headers
        )
    
    @task(1)
    def check_notifications(self):
        """Check notifications"""
        self.client.get(
            "/api/notifications",
            headers=self.headers
        )


class ManagerUser(WFMUser):
    """Manager user behavior"""
    weight = 2  # 20% of users are managers
    
    @task(2)
    @tag('critical')
    def view_team_schedule(self):
        """View team schedule"""
        with self.client.get(
            f"/api/schedules/team?date={self.current_date}",
            headers=self.headers,
            catch_response=True
        ) as response:
            if response.elapsed.total_seconds() > 3:
                response.failure("Team schedule load too slow")
    
    @task(3)
    @tag('critical')
    def generate_schedule(self):
        """Generate new schedule - resource intensive"""
        start_date = (datetime.now() + timedelta(days=7)).strftime("%Y-%m-%d")
        end_date = (datetime.now() + timedelta(days=13)).strftime("%Y-%m-%d")
        
        with self.client.post(
            "/api/schedules/generate",
            json={
                "start_date": start_date,
                "end_date": end_date,
                "employee_ids": list(range(1, 21)),  # 20 employees
                "optimization_goal": "balanced"
            },
            headers=self.headers,
            catch_response=True
        ) as response:
            if response.elapsed.total_seconds() > 10:
                response.failure("Schedule generation too slow")
            elif response.status_code != 201:
                response.failure(f"Schedule generation failed: {response.status_code}")
    
    @task(2)
    def review_pending_requests(self):
        """Review pending approval requests"""
        self.client.get(
            "/api/approvals/pending",
            headers=self.headers
        )
    
    @task(1)
    def approve_request(self):
        """Approve a random pending request"""
        # First get pending requests
        pending = self.client.get(
            "/api/approvals/pending",
            headers=self.headers
        ).json()
        
        if pending and len(pending) > 0:
            request_id = random.choice(pending)["id"]
            self.client.post(
                f"/api/approvals/{request_id}/approve",
                json={"comment": "Approved via load test"},
                headers=self.headers,
                name="/api/approvals/[id]/approve"
            )
    
    @task(1)
    def run_coverage_report(self):
        """Run coverage analysis report"""
        with self.client.post(
            "/api/reports/coverage",
            json={
                "start_date": self.current_date,
                "end_date": (datetime.now() + timedelta(days=7)).strftime("%Y-%m-%d"),
                "skill_groups": ["sales", "support"]
            },
            headers=self.headers,
            catch_response=True
        ) as response:
            if response.elapsed.total_seconds() > 5:
                response.failure("Report generation too slow")


class ForecastingUser(WFMUser):
    """Specialized user for testing forecasting endpoints"""
    weight = 1
    
    @task
    @tag('algorithm')
    def generate_forecast(self):
        """Test forecast generation with various parameters"""
        params = {
            "start_date": (datetime.now() + timedelta(days=30)).strftime("%Y-%m-%d"),
            "end_date": (datetime.now() + timedelta(days=60)).strftime("%Y-%m-%d"),
            "skill_groups": random.sample(["sales", "support", "technical", "billing"], 2),
            "algorithm": random.choice(["prophet", "arima", "neural"]),
            "confidence_level": 0.95
        }
        
        with self.client.post(
            "/api/forecasts/generate",
            json=params,
            headers=self.headers,
            catch_response=True
        ) as response:
            if response.elapsed.total_seconds() > 15:
                response.failure("Forecast generation exceeded 15s timeout")
            
            if response.status_code == 201:
                forecast_data = response.json()
                # Validate forecast accuracy metrics
                if forecast_data.get("accuracy", {}).get("mape", 100) > 20:
                    response.failure("Forecast accuracy too low (MAPE > 20%)")


class WebSocketUser(HttpUser):
    """Test WebSocket connections for real-time updates"""
    weight = 1
    wait_time = between(5, 10)
    
    def on_start(self):
        """Establish WebSocket connection"""
        # This would typically use a WebSocket client library
        # For demonstration, we'll simulate with HTTP long-polling
        self.login()
    
    def login(self):
        """Authenticate for WebSocket"""
        response = self.client.post("/api/auth/login", json={
            "email": "ws_user@test.com",
            "password": "password123"
        })
        
        if response.status_code == 200:
            self.token = response.json()["access_token"]
            self.headers = {"Authorization": f"Bearer {self.token}"}
    
    @task
    def simulate_websocket_updates(self):
        """Simulate receiving real-time updates"""
        # Subscribe to updates
        self.client.post(
            "/api/realtime/subscribe",
            json={"channels": ["schedule_updates", "notifications"]},
            headers=self.headers
        )
        
        # Poll for updates
        for _ in range(5):
            self.client.get(
                "/api/realtime/poll",
                headers=self.headers,
                name="/api/realtime/poll"
            )
            self.wait()  # Wait between polls


class StressTestUser(WFMUser):
    """User for stress testing specific endpoints"""
    
    @task
    @tag('stress')
    def stress_erlang_calculation(self):
        """Stress test Erlang C calculations"""
        params = {
            "call_volume": random.randint(1000, 5000),
            "average_handle_time": random.randint(180, 600),
            "service_level_target": 0.8,
            "service_level_seconds": 20,
            "skills": random.sample(["sales", "support", "technical"], 2)
        }
        
        with self.client.post(
            "/api/algorithms/erlang-c/calculate",
            json=params,
            headers=self.headers,
            catch_response=True
        ) as response:
            if response.elapsed.total_seconds() > 0.5:
                response.failure("Erlang C calculation too slow")
    
    @task
    @tag('stress')
    def bulk_schedule_validation(self):
        """Validate large schedule"""
        # Create a large schedule payload
        shifts = []
        for day in range(7):
            for emp in range(50):
                shifts.append({
                    "employee_id": emp,
                    "date": (datetime.now() + timedelta(days=day)).strftime("%Y-%m-%d"),
                    "start_time": "08:00",
                    "end_time": "16:00"
                })
        
        with self.client.post(
            "/api/schedules/validate-bulk",
            json={"shifts": shifts},
            headers=self.headers,
            catch_response=True
        ) as response:
            if response.elapsed.total_seconds() > 3:
                response.failure("Bulk validation too slow")


# Custom test scenarios
class PeakLoadScenario(HttpUser):
    """Simulate peak load conditions (e.g., shift bidding window)"""
    wait_time = between(0.5, 1.5)
    
    @task
    def aggressive_shift_bidding(self):
        """Simulate multiple users bidding for same shifts"""
        available_shifts = self.client.get("/api/shifts/available").json()
        
        if available_shifts:
            target_shift = random.choice(available_shifts)
            
            response = self.client.post(
                f"/api/shifts/{target_shift['id']}/bid",
                json={"bid_priority": random.randint(1, 10)},
                name="/api/shifts/[id]/bid"
            )
            
            # Track success rate
            if response.status_code == 409:
                # Conflict - someone else got it first
                pass
            elif response.status_code == 201:
                # Success
                pass