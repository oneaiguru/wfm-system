"""Test performance tracking implementation"""

from src.algorithms.workflows.approval_workflow_engine import ApprovalWorkflowEngine, ApprovalAction
from src.algorithms.reports.performance_summary import generate_performance_report
import logging

# Configure logging to see tracking messages
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

def test_performance_tracking():
    """Test that performance tracking is working"""
    
    print("🧪 Testing Performance Tracking System...")
    print("-" * 60)
    
    # Initialize the engine (this will also test DB connection)
    print("\n1. Initializing ApprovalWorkflowEngine...")
    engine = ApprovalWorkflowEngine()
    
    # Test 1: Submit a request (should be tracked)
    print("\n2. Testing request submission with tracking...")
    try:
        request = engine.submit_request_for_approval(
            request_type="vacation",
            employee_id="1",
            request_data={
                "start_date": "2025-08-15",
                "end_date": "2025-08-20",
                "reason": "Performance tracking test"
            },
            urgency_level="normal"
        )
        print(f"✅ Request submitted: {request.request_id}")
        print(f"   Status: {request.status.value}")
    except Exception as e:
        print(f"❌ Failed to submit request: {e}")
    
    # Test 2: Get pending approvals (should be tracked)
    print("\n3. Testing pending approvals query with tracking...")
    try:
        approver_id = "0a32e7d3-fcee-4f2e-aeb1-c8ca093d7212"
        pending = engine.get_pending_approvals(approver_id)
        print(f"✅ Found {len(pending)} pending approvals")
    except Exception as e:
        print(f"❌ Failed to get pending approvals: {e}")
    
    # Test 3: Get dashboard data (should be tracked)
    print("\n4. Testing dashboard data retrieval...")
    try:
        dashboard_data = engine.get_approval_dashboard_data(approver_id)
        print(f"✅ Dashboard data retrieved:")
        print(f"   Pending: {dashboard_data['statistics']['pending_count']}")
        print(f"   Approved this week: {dashboard_data['statistics']['approved_this_week']}")
        print(f"   Rejected this week: {dashboard_data['statistics']['rejected_this_week']}")
    except Exception as e:
        print(f"❌ Failed to get dashboard data: {e}")
    
    # Generate performance report
    print("\n5. Generating performance report...")
    print("-" * 60)
    
    try:
        # Short report for last hour to see our test data
        report = generate_performance_report(days=1/24, threshold_ms=100)  # 1 hour, 100ms threshold
        print(report)
    except Exception as e:
        print(f"❌ Failed to generate report: {e}")
    
    print("\n✅ Performance tracking test complete!")


if __name__ == "__main__":
    test_performance_tracking()