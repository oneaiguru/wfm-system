"""
WFM Enterprise Load Testing Suite
=================================
Simulates 1000+ concurrent users to prove enterprise scalability

Usage:
    locust -f locustfile.py --host http://localhost:8000 --users 1000 --spawn-rate 50
    
    Or with web UI:
    locust -f locustfile.py --host http://localhost:8000
"""

import random
import json
import time
from datetime import datetime, timedelta
from locust import HttpUser, task, between, events
from locust.contrib.fasthttp import FastHttpUser
import numpy as np

# Performance tracking
response_times = {
    "erlang_c": [],
    "historic_data": [],
    "real_time": [],
    "bulk_upload": []
}

class WFMEnterpriseUser(FastHttpUser):
    """Simulates a typical WFM Enterprise API user"""
    
    wait_time = between(0.5, 2.0)  # Realistic user behavior
    
    def on_start(self):
        """Initialize user session"""
        self.api_key = "demo-api-key-2024"
        self.headers = {
            "X-API-Key": self.api_key,
            "Content-Type": "application/json"
        }
        
        # Get initial data
        self.get_personnel()
    
    @task(10)
    def get_personnel(self):
        """Most common operation - get organizational structure"""
        with self.client.get(
            "/api/v1/argus/personnel",
            headers=self.headers,
            catch_response=True
        ) as response:
            if response.status_code == 200:
                response.success()
                self.personnel_data = response.json()
            else:
                response.failure(f"Got status code {response.status_code}")
    
    @task(20)
    def calculate_erlang_c(self):
        """High-frequency operation - Erlang C calculations"""
        params = {
            "arrival_rate": random.randint(50, 300),
            "service_time": random.randint(180, 420),
            "target_service_level": random.choice([0.7, 0.8, 0.85, 0.9]),
            "target_answer_time": random.choice([15, 20, 30]),
            "shrinkage": random.uniform(0.2, 0.35)
        }
        
        start_time = time.time()
        
        with self.client.post(
            "/api/v1/algorithms/erlang-c/calculate",
            json=params,
            headers=self.headers,
            catch_response=True
        ) as response:
            if response.status_code == 200:
                response.success()
                response_times["erlang_c"].append(response.elapsed.total_seconds() * 1000)
                
                # Verify response time is under 50ms
                if response.elapsed.total_seconds() * 1000 > 50:
                    response.failure(f"Response too slow: {response.elapsed.total_seconds() * 1000:.0f}ms")
            else:
                response.failure(f"Got status code {response.status_code}")
    
    @task(15)
    def query_historical_data(self):
        """Common operation - query historical data"""
        end_date = datetime.now()
        start_date = end_date - timedelta(days=random.randint(1, 30))
        
        params = {
            "startDate": start_date.isoformat() + "Z",
            "endDate": end_date.isoformat() + "Z",
            "step": 900000,  # 15 minutes
            "groupId": random.choice(["1", "2", "3", "1,2", "1,2,3"])
        }
        
        with self.client.get(
            "/api/v1/argus/historic/serviceGroupData",
            params=params,
            headers=self.headers,
            catch_response=True
        ) as response:
            if response.status_code == 200:
                response.success()
                response_times["historic_data"].append(response.elapsed.total_seconds() * 1000)
            elif response.status_code == 404:
                response.success()  # No data is valid
            else:
                response.failure(f"Got status code {response.status_code}")
    
    @task(10)
    def get_real_time_status(self):
        """Real-time operation - get current agent status"""
        with self.client.get(
            "/api/v1/argus/online/agentStatus",
            headers=self.headers,
            catch_response=True
        ) as response:
            if response.status_code == 200:
                response.success()
                response_times["real_time"].append(response.elapsed.total_seconds() * 1000)
                
                # Verify response time is under 500ms for real-time
                if response.elapsed.total_seconds() * 1000 > 500:
                    response.failure(f"Real-time too slow: {response.elapsed.total_seconds() * 1000:.0f}ms")
            else:
                response.failure(f"Got status code {response.status_code}")
    
    @task(5)
    def post_status_update(self):
        """Fire-and-forget status update"""
        data = {
            "workerId": str(random.randint(1, 500)),
            "stateName": random.choice(["Available", "Break", "Lunch", "Meeting"]),
            "stateCode": random.choice(["AVAIL", "BREAK", "LUNCH", "MEET"]),
            "systemId": "LoadTest",
            "actionTime": int(time.time()),
            "action": random.choice([0, 1])
        }
        
        with self.client.post(
            "/api/v1/argus/ccwfm/api/rest/status",
            json=data,
            headers=self.headers,
            catch_response=True
        ) as response:
            if response.status_code in [200, 201, 202]:
                response.success()
            else:
                response.failure(f"Got status code {response.status_code}")
    
    @task(8)
    def forecast_calculation(self):
        """ML-enhanced forecasting"""
        historical_data = []
        for i in range(168):  # 1 week of hourly data
            historical_data.append({
                "timestamp": (datetime.now() - timedelta(hours=i)).isoformat() + "Z",
                "value": random.randint(20, 200) + (50 if i % 24 in [9,10,11,14,15,16] else 0)
            })
        
        params = {
            "historical_data": historical_data,
            "forecast_horizon": 24,
            "use_ml": True
        }
        
        with self.client.post(
            "/api/v1/algorithms/forecast/ml-enhanced",
            json=params,
            headers=self.headers,
            catch_response=True
        ) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Got status code {response.status_code}")
    
    @task(3)
    def multi_skill_optimization(self):
        """Complex multi-skill calculation"""
        params = {
            "skills": ["English", "Spanish", "Technical", "Sales"],
            "agents": random.randint(30, 100),
            "skill_distribution": {
                "English_only": random.randint(5, 20),
                "Spanish_only": random.randint(3, 10),
                "English_Spanish": random.randint(5, 15),
                "English_Technical": random.randint(5, 15),
                "All_skills": random.randint(3, 10)
            },
            "demand_forecast": {
                "English": random.randint(30, 60),
                "Spanish": random.randint(10, 30),
                "Technical": random.randint(10, 25),
                "Sales": random.randint(15, 35)
            }
        }
        
        with self.client.post(
            "/api/v1/algorithms/erlang-c/multi-skill",
            json=params,
            headers=self.headers,
            catch_response=True
        ) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Got status code {response.status_code}")
    
    @task(2)
    def bulk_data_upload(self):
        """Simulate bulk data upload"""
        # Generate realistic bulk data
        intervals = []
        base_time = datetime.now() - timedelta(hours=24)
        
        for i in range(96):  # 24 hours of 15-minute intervals
            interval_time = base_time + timedelta(minutes=15*i)
            intervals.append({
                "start_time": interval_time.isoformat() + "Z",
                "end_time": (interval_time + timedelta(minutes=15)).isoformat() + "Z",
                "received_calls": random.randint(10, 50),
                "answered_calls": random.randint(8, 45),
                "aht": random.randint(180, 420),
                "service_level": random.uniform(0.6, 0.95)
            })
        
        data = {
            "service_groups": [
                {"id": "1", "name": "Customer Support"},
                {"id": "2", "name": "Technical Support"}
            ],
            "intervals": intervals
        }
        
        with self.client.post(
            "/api/v1/argus/enhanced/historic/bulk-upload",
            json=data,
            headers=self.headers,
            catch_response=True
        ) as response:
            if response.status_code in [200, 201]:
                response.success()
                response_times["bulk_upload"].append(response.elapsed.total_seconds() * 1000)
            else:
                response.failure(f"Got status code {response.status_code}")
    
    @task(5)
    def comparison_benchmark(self):
        """Run performance comparison"""
        params = {
            "scenario": "typical_weekday",
            "iterations": 10
        }
        
        with self.client.post(
            "/api/v1/comparison/benchmark",
            json=params,
            headers=self.headers,
            catch_response=True
        ) as response:
            if response.status_code == 200:
                response.success()
                result = response.json()
                
                # Log superiority metrics
                if "speed_advantage" in result:
                    print(f"Speed advantage: {result['speed_advantage']}x")
            else:
                response.failure(f"Got status code {response.status_code}")


class AdminUser(FastHttpUser):
    """Simulates admin/reporting users with heavier queries"""
    
    wait_time = between(5, 10)  # Less frequent but heavier operations
    weight = 1  # 10% of users are admins
    
    def on_start(self):
        self.api_key = "admin-key-2024"
        self.headers = {
            "X-API-Key": self.api_key,
            "Content-Type": "application/json"
        }
    
    @task
    def generate_monthly_report(self):
        """Heavy operation - full month of data"""
        end_date = datetime.now()
        start_date = end_date - timedelta(days=30)
        
        params = {
            "startDate": start_date.isoformat() + "Z",
            "endDate": end_date.isoformat() + "Z",
            "step": 3600000,  # Hourly
            "groupId": "all"
        }
        
        with self.client.get(
            "/api/v1/argus/historic/serviceGroupData",
            params=params,
            headers=self.headers,
            catch_response=True,
            timeout=30  # Allow longer timeout for heavy queries
        ) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Got status code {response.status_code}")
    
    @task
    def export_agent_performance(self):
        """Export all agent performance data"""
        params = {
            "startDate": (datetime.now() - timedelta(days=7)).isoformat() + "Z",
            "endDate": datetime.now().isoformat() + "Z",
            "agentId": ",".join([str(i) for i in range(1, 101)])  # 100 agents
        }
        
        with self.client.get(
            "/api/v1/argus/historic/agentCallsData",
            params=params,
            headers=self.headers,
            catch_response=True,
            timeout=30
        ) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Got status code {response.status_code}")


# Event handlers for reporting
@events.test_start.add_listener
def on_test_start(environment, **kwargs):
    print("Load test starting...")
    print(f"Target host: {environment.host}")
    print(f"Users: {environment.parsed_options.num_users}")


@events.request.add_listener
def on_request(request_type, name, response_time, response_length, response, 
               context, exception, **kwargs):
    """Track detailed metrics for reporting"""
    if response and response.status_code < 400:
        # Track successful response times by endpoint type
        if "erlang-c" in name:
            response_times["erlang_c"].append(response_time)
        elif "historic" in name:
            response_times["historic_data"].append(response_time)
        elif "online" in name:
            response_times["real_time"].append(response_time)


@events.test_stop.add_listener
def on_test_stop(environment, **kwargs):
    """Generate performance report"""
    print("\n" + "="*60)
    print("WFM ENTERPRISE LOAD TEST REPORT")
    print("="*60)
    
    # Calculate statistics
    for endpoint_type, times in response_times.items():
        if times:
            print(f"\n{endpoint_type.upper()} Performance:")
            print(f"  Samples: {len(times)}")
            print(f"  Min: {min(times):.1f}ms")
            print(f"  Max: {max(times):.1f}ms")
            print(f"  Avg: {np.mean(times):.1f}ms")
            print(f"  Median: {np.median(times):.1f}ms")
            print(f"  95th percentile: {np.percentile(times, 95):.1f}ms")
            print(f"  99th percentile: {np.percentile(times, 99):.1f}ms")
    
    # Overall statistics
    total_stats = environment.stats.total
    print(f"\nOVERALL STATISTICS:")
    print(f"  Total Requests: {total_stats.num_requests}")
    print(f"  Failure Rate: {total_stats.fail_ratio:.2%}")
    print(f"  Avg Response Time: {total_stats.avg_response_time:.1f}ms")
    print(f"  Requests/sec: {total_stats.current_rps:.1f}")
    
    # Performance targets
    print(f"\nPERFORMANCE TARGETS:")
    erlang_avg = np.mean(response_times["erlang_c"]) if response_times["erlang_c"] else 0
    print(f"  ✓ Erlang C < 50ms: {'PASS' if erlang_avg < 50 else 'FAIL'} ({erlang_avg:.1f}ms)")
    
    realtime_avg = np.mean(response_times["real_time"]) if response_times["real_time"] else 0
    print(f"  ✓ Real-time < 500ms: {'PASS' if realtime_avg < 500 else 'FAIL'} ({realtime_avg:.1f}ms)")
    
    print(f"  ✓ Error rate < 1%: {'PASS' if total_stats.fail_ratio < 0.01 else 'FAIL'} ({total_stats.fail_ratio:.2%})")
    
    print(f"  ✓ Throughput > 1000 req/s: {'PASS' if total_stats.current_rps > 1000 else 'FAIL'} ({total_stats.current_rps:.0f} req/s)")
    
    print("\n" + "="*60)
    
    # Save detailed report
    with open("load_test_report.json", "w") as f:
        json.dump({
            "summary": {
                "total_requests": total_stats.num_requests,
                "failure_rate": total_stats.fail_ratio,
                "avg_response_time": total_stats.avg_response_time,
                "requests_per_second": total_stats.current_rps
            },
            "endpoint_performance": {
                endpoint: {
                    "samples": len(times),
                    "min": min(times) if times else 0,
                    "max": max(times) if times else 0,
                    "avg": np.mean(times) if times else 0,
                    "median": np.median(times) if times else 0,
                    "p95": np.percentile(times, 95) if times else 0,
                    "p99": np.percentile(times, 99) if times else 0
                }
                for endpoint, times in response_times.items()
            },
            "timestamp": datetime.now().isoformat()
        }, f, indent=2)
    
    print(f"\nDetailed report saved to: load_test_report.json")