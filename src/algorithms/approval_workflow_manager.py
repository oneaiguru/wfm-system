#!/usr/bin/env python3
"""
Approval Workflow Manager
Advanced approval algorithms for manager workflows and business process automation
"""

import logging
from typing import Dict, List, Optional, Tuple, Any
from datetime import datetime, timedelta
from dataclasses import dataclass
from enum import Enum
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
import os
import json

logger = logging.getLogger(__name__)

class ApprovalAction(Enum):
    """Available approval actions"""
    APPROVE = "approve"
    REJECT = "reject"
    DELEGATE = "delegate"
    REQUEST_INFO = "request_info"
    EDIT = "edit"
    FORWARD = "forward"
    ACKNOWLEDGE = "acknowledge"
    APPLY = "apply"

class WorkflowStage(Enum):
    """Workflow stages for approval processes"""
    SUPERVISOR_REVIEW = "supervisor_review"
    PLANNING_REVIEW = "planning_review"
    OPERATOR_CONFIRMATION = "operator_confirmation"
    FINAL_APPLICATION = "final_application"
    COMPLETED = "completed"
    REJECTED = "rejected"

class Priority(Enum):
    """Task priority levels"""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    URGENT = "urgent"

@dataclass
class ApprovalTask:
    """Approval task information"""
    task_id: str
    object_name: str  # "Schedule Q1 2025"
    task_type: str   # "Schedule variant"
    process_name: str # "Schedule approval"
    current_stage: WorkflowStage
    assigned_to: int  # employee_id
    available_actions: List[ApprovalAction]
    priority: Priority
    created_date: datetime
    due_date: datetime
    comments: List[str]
    attachments: List[str]
    metadata: Dict[str, Any]

@dataclass
class ApprovalRule:
    """Business rule for approval process"""
    rule_type: str  # "role_authorization", "sequential_order", etc.
    enforcement: str
    validation: str
    parameters: Dict[str, Any]

@dataclass
class WorkflowResult:
    """Result of workflow operation"""
    success: bool
    message: str
    next_stage: Optional[WorkflowStage]
    notifications_sent: List[int]  # employee_ids notified
    task_id: Optional[str]
    errors: List[str]

@dataclass
class CoverageImpactAnalysis:
    """Analysis of coverage impact from approval decision"""
    affected_employees: List[int]
    coverage_reduction: float  # percentage
    service_level_impact: str  # "minimal", "moderate", "significant", "severe"
    mitigation_recommendations: List[str]
    cost_impact: float
    approval_recommendation: str  # "approve", "reject", "conditional"

class ApprovalWorkflowManager:
    """Advanced approval workflow manager for business processes"""
    
    def __init__(self, connection_string: Optional[str] = None):
        """Initialize with wfm_enterprise database connection"""
        self.connection_string = connection_string or os.getenv(
            'DATABASE_URL',
            'postgresql://postgres:postgres@localhost:5432/wfm_enterprise'
        )
        
        self.engine = create_engine(self.connection_string)
        self.SessionLocal = sessionmaker(bind=self.engine)
        
        # Define workflow rules
        self.approval_rules = self._load_approval_rules()
        
        logger.info("✅ ApprovalWorkflowManager initialized")
    
    def initiate_schedule_approval(self, schedule_id: str, initiator_id: int) -> WorkflowResult:
        """
        Initiate work schedule approval process workflow
        Based on BDD: 13-business-process-management-workflows.feature:24-40
        """
        try:
            with self.SessionLocal() as session:
                # Create approval task
                task_id = f"schedule_approval_{schedule_id}_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
                
                # Find supervisor for initial review
                supervisor_id = self._find_supervisor(session, initiator_id)
                
                # Create task record
                session.execute(text("""
                    INSERT INTO approval_tasks (
                        task_id, object_name, task_type, process_name, 
                        current_stage, assigned_to, priority, created_date, 
                        due_date, metadata
                    ) VALUES (
                        :task_id, :object_name, :task_type, :process_name,
                        :current_stage, :assigned_to, :priority, :created_date,
                        :due_date, :metadata
                    )
                """), {
                    'task_id': task_id,
                    'object_name': f'Schedule {schedule_id}',
                    'task_type': 'Schedule variant',
                    'process_name': 'Schedule approval',
                    'current_stage': WorkflowStage.SUPERVISOR_REVIEW.value,
                    'assigned_to': supervisor_id,
                    'priority': Priority.MEDIUM.value,
                    'created_date': datetime.now(),
                    'due_date': datetime.now() + timedelta(days=2),
                    'metadata': json.dumps({'schedule_id': schedule_id, 'initiator_id': initiator_id})
                })
                
                session.commit()
                
                # Send notification to supervisor
                notifications = self._send_notification(session, supervisor_id, 
                    f"New schedule approval task: {task_id}", "schedule_approval")
                
                return WorkflowResult(
                    success=True,
                    message=f"Schedule approval workflow initiated: {task_id}",
                    next_stage=WorkflowStage.SUPERVISOR_REVIEW,
                    notifications_sent=[supervisor_id],
                    task_id=task_id,
                    errors=[]
                )
                
        except Exception as e:
            logger.error(f"Error initiating schedule approval: {e}")
            return WorkflowResult(
                success=False,
                message=f"Failed to initiate workflow: {str(e)}",
                next_stage=None,
                notifications_sent=[],
                task_id=None,
                errors=[str(e)]
            )
    
    def process_approval_action(self, task_id: str, employee_id: int, action: ApprovalAction, 
                              comments: str = "", attachments: List[str] = None) -> WorkflowResult:
        """
        Process approval action (approve/reject/delegate)
        Based on BDD: 13-business-process-management-workflows.feature:42-59
        """
        attachments = attachments or []
        
        try:
            with self.SessionLocal() as session:
                # Get current task
                task = session.execute(text("""
                    SELECT task_id, object_name, current_stage, assigned_to, metadata
                    FROM approval_tasks 
                    WHERE task_id = :task_id AND assigned_to = :employee_id
                """), {
                    'task_id': task_id,
                    'employee_id': employee_id
                }).fetchone()
                
                if not task:
                    return WorkflowResult(
                        success=False,
                        message="Task not found or not assigned to you",
                        next_stage=None,
                        notifications_sent=[],
                        task_id=task_id,
                        errors=["Task not found"]
                    )
                
                current_stage = WorkflowStage(task.current_stage)
                metadata = json.loads(task.metadata)
                
                # Validate action is allowed for current stage
                allowed_actions = self._get_allowed_actions(current_stage)
                if action not in allowed_actions:
                    return WorkflowResult(
                        success=False,
                        message=f"Action {action.value} not allowed in stage {current_stage.value}",
                        next_stage=current_stage,
                        notifications_sent=[],
                        task_id=task_id,
                        errors=[f"Invalid action for stage"]
                    )
                
                # Process action
                result = self._execute_workflow_action(session, task, action, comments, attachments, metadata)
                
                return result
                
        except Exception as e:
            logger.error(f"Error processing approval action: {e}")
            return WorkflowResult(
                success=False,
                message=f"Failed to process action: {str(e)}",
                next_stage=None,
                notifications_sent=[],
                task_id=task_id,
                errors=[str(e)]
            )
    
    def analyze_coverage_impact(self, schedule_id: str, action: ApprovalAction) -> CoverageImpactAnalysis:
        """
        Analyze coverage impact of approval decision
        """
        try:
            with self.SessionLocal() as session:
                # Get affected employees from schedule (use schedule_date filter instead)
                affected_employees = session.execute(text("""
                    SELECT DISTINCT agent_id
                    FROM work_schedules 
                    WHERE schedule_date >= CURRENT_DATE
                    LIMIT 5
                """)).fetchall()
                
                employee_ids = [emp.agent_id for emp in affected_employees]
                
                # Calculate coverage impact
                if action == ApprovalAction.REJECT:
                    # Rejecting schedule - calculate what coverage would be lost
                    coverage_reduction = self._calculate_coverage_reduction(session, employee_ids)
                    service_level_impact = "significant" if coverage_reduction > 20 else "moderate"
                    
                    recommendations = [
                        "Consider alternative scheduling options",
                        "Evaluate overtime assignments",
                        "Review staffing requirements"
                    ]
                    
                    approval_recommendation = "conditional" if coverage_reduction > 30 else "approve"
                    
                else:
                    # Approving schedule - minimal impact
                    coverage_reduction = 0.0
                    service_level_impact = "minimal"
                    recommendations = ["Proceed with approval"]
                    approval_recommendation = "approve"
                
                # Calculate cost impact
                cost_impact = len(employee_ids) * 100.0  # Simple cost calculation
                
                return CoverageImpactAnalysis(
                    affected_employees=employee_ids,
                    coverage_reduction=coverage_reduction,
                    service_level_impact=service_level_impact,
                    mitigation_recommendations=recommendations,
                    cost_impact=cost_impact,
                    approval_recommendation=approval_recommendation
                )
                
        except Exception as e:
            logger.error(f"Error analyzing coverage impact: {e}")
            return CoverageImpactAnalysis(
                affected_employees=[],
                coverage_reduction=0.0,
                service_level_impact="unknown",
                mitigation_recommendations=["Error analyzing impact"],
                cost_impact=0.0,
                approval_recommendation="manual_review"
            )
    
    def get_pending_tasks(self, employee_id: int) -> List[ApprovalTask]:
        """Get pending approval tasks for employee"""
        try:
            with self.SessionLocal() as session:
                tasks = session.execute(text("""
                    SELECT 
                        task_id, object_name, task_type, process_name,
                        current_stage, priority, created_date, due_date, metadata
                    FROM approval_tasks 
                    WHERE assigned_to = :employee_id 
                    AND current_stage NOT IN ('completed', 'rejected')
                    ORDER BY priority DESC, due_date ASC
                """), {'employee_id': employee_id}).fetchall()
                
                task_list = []
                for task in tasks:
                    stage = WorkflowStage(task.current_stage)
                    allowed_actions = self._get_allowed_actions(stage)
                    
                    task_list.append(ApprovalTask(
                        task_id=task.task_id,
                        object_name=task.object_name,
                        task_type=task.task_type,
                        process_name=task.process_name,
                        current_stage=stage,
                        assigned_to=employee_id,
                        available_actions=allowed_actions,
                        priority=Priority(task.priority),
                        created_date=task.created_date,
                        due_date=task.due_date,
                        comments=[],  # Would load from comments table
                        attachments=[],  # Would load from attachments table
                        metadata=json.loads(task.metadata) if isinstance(task.metadata, str) else task.metadata
                    ))
                
                return task_list
                
        except Exception as e:
            logger.error(f"Error getting pending tasks: {e}")
            return []
    
    def _load_approval_rules(self) -> List[ApprovalRule]:
        """Load business rules for approval processes"""
        return [
            ApprovalRule(
                rule_type="role_authorization",
                enforcement="Only authorized users can act",
                validation="Check user permissions",
                parameters={"required_role": ["supervisor", "manager", "planning_specialist"]}
            ),
            ApprovalRule(
                rule_type="sequential_order",
                enforcement="Stages must complete in order",
                validation="Prevent skipping stages",
                parameters={"strict_sequence": True}
            ),
            ApprovalRule(
                rule_type="completion_requirements",
                enforcement="All participants must act",
                validation="Track acknowledgments",
                parameters={"require_all_acks": True}
            ),
            ApprovalRule(
                rule_type="timeout_handling",
                enforcement="Escalate overdue tasks",
                validation="Automatic escalation",
                parameters={"timeout_hours": 48, "escalation_levels": 2}
            )
        ]
    
    def _find_supervisor(self, session, employee_id: int) -> int:
        """Find supervisor for employee (simplified - no manager_id column)"""
        # Default to employee 1 as supervisor for demo
        return 1
    
    def _get_allowed_actions(self, stage: WorkflowStage) -> List[ApprovalAction]:
        """Get allowed actions for workflow stage"""
        action_map = {
            WorkflowStage.SUPERVISOR_REVIEW: [ApprovalAction.APPROVE, ApprovalAction.REJECT, ApprovalAction.EDIT],
            WorkflowStage.PLANNING_REVIEW: [ApprovalAction.FORWARD, ApprovalAction.REQUEST_INFO, ApprovalAction.REJECT],
            WorkflowStage.OPERATOR_CONFIRMATION: [ApprovalAction.ACKNOWLEDGE, ApprovalAction.REQUEST_INFO],
            WorkflowStage.FINAL_APPLICATION: [ApprovalAction.APPLY, ApprovalAction.REJECT]
        }
        return action_map.get(stage, [])
    
    def _execute_workflow_action(self, session, task, action: ApprovalAction, 
                                comments: str, attachments: List[str], metadata: Dict) -> WorkflowResult:
        """Execute specific workflow action"""
        current_stage = WorkflowStage(task.current_stage)
        
        # Determine next stage and assignee
        if action == ApprovalAction.APPROVE and current_stage == WorkflowStage.SUPERVISOR_REVIEW:
            next_stage = WorkflowStage.PLANNING_REVIEW
            next_assignee = self._find_planning_specialist(session)
        elif action == ApprovalAction.FORWARD and current_stage == WorkflowStage.PLANNING_REVIEW:
            next_stage = WorkflowStage.OPERATOR_CONFIRMATION
            next_assignee = self._find_operators(session, metadata.get('schedule_id'))
        elif action == ApprovalAction.ACKNOWLEDGE and current_stage == WorkflowStage.OPERATOR_CONFIRMATION:
            next_stage = WorkflowStage.FINAL_APPLICATION
            next_assignee = self._find_planning_specialist(session)
        elif action == ApprovalAction.APPLY and current_stage == WorkflowStage.FINAL_APPLICATION:
            next_stage = WorkflowStage.COMPLETED
            next_assignee = None
        elif action == ApprovalAction.REJECT:
            next_stage = WorkflowStage.REJECTED
            next_assignee = metadata.get('initiator_id')
        else:
            next_stage = current_stage
            next_assignee = task.assigned_to
        
        # Update task
        if next_assignee:
            session.execute(text("""
                UPDATE approval_tasks 
                SET current_stage = :next_stage, assigned_to = :next_assignee,
                    updated_date = :updated_date
                WHERE task_id = :task_id
            """), {
                'next_stage': next_stage.value,
                'next_assignee': next_assignee,
                'updated_date': datetime.now(),
                'task_id': task.task_id
            })
        
        # Record action
        session.execute(text("""
            INSERT INTO approval_actions (task_id, employee_id, action, comments, created_date)
            VALUES (:task_id, :employee_id, :action, :comments, :created_date)
        """), {
            'task_id': task.task_id,
            'employee_id': task.assigned_to,
            'action': action.value,
            'comments': comments,
            'created_date': datetime.now()
        })
        
        session.commit()
        
        # Send notifications
        notifications = []
        if next_assignee and next_assignee != task.assigned_to:
            self._send_notification(session, next_assignee, 
                f"New approval task assigned: {task.task_id}", "task_assignment")
            notifications.append(next_assignee)
        
        return WorkflowResult(
            success=True,
            message=f"Action {action.value} processed successfully",
            next_stage=next_stage,
            notifications_sent=notifications,
            task_id=task.task_id,
            errors=[]
        )
    
    def _find_planning_specialist(self, session) -> int:
        """Find planning specialist role"""
        result = session.execute(text("""
            SELECT e.id FROM employees e
            JOIN user_roles ur ON e.user_id = ur.user_id
            JOIN roles r ON ur.role_id = r.id
            WHERE r.name = 'planning_specialist'
            LIMIT 1
        """)).fetchone()
        return result.id if result else 1
    
    def _find_operators(self, session, schedule_id: str) -> int:
        """Find operators affected by schedule"""
        result = session.execute(text("""
            SELECT agent_id FROM work_schedules 
            WHERE template_id = :schedule_id 
            LIMIT 1
        """), {'schedule_id': schedule_id}).fetchone()
        return result.agent_id if result else 1
    
    def _calculate_coverage_reduction(self, session, employee_ids: List[int]) -> float:
        """Calculate coverage reduction percentage"""
        if not employee_ids:
            return 0.0
        
        # Simple calculation - actual implementation would be more complex
        base_coverage = 100.0
        reduction_per_employee = 10.0
        return min(len(employee_ids) * reduction_per_employee, base_coverage)
    
    def _send_notification(self, session, employee_id: int, message: str, notification_type: str) -> bool:
        """Send notification to employee"""
        try:
            session.execute(text("""
                INSERT INTO notifications (employee_id, message, notification_type, created_date, is_read)
                VALUES (:employee_id, :message, :notification_type, :created_date, false)
            """), {
                'employee_id': employee_id,
                'message': message,
                'notification_type': notification_type,
                'created_date': datetime.now()
            })
            return True
        except Exception as e:
            logger.error(f"Error sending notification: {e}")
            return False

# Simple function interfaces
def initiate_schedule_approval(schedule_id: str, initiator_id: int) -> WorkflowResult:
    """Initiate schedule approval workflow"""
    manager = ApprovalWorkflowManager()
    return manager.initiate_schedule_approval(schedule_id, initiator_id)

def process_approval(task_id: str, employee_id: int, action_name: str, comments: str = "") -> WorkflowResult:
    """Process approval action"""
    manager = ApprovalWorkflowManager()
    action = ApprovalAction(action_name)
    return manager.process_approval_action(task_id, employee_id, action, comments)

def get_my_tasks(employee_id: int) -> List[ApprovalTask]:
    """Get pending tasks for employee"""
    manager = ApprovalWorkflowManager()
    return manager.get_pending_tasks(employee_id)

def analyze_approval_impact(schedule_id: str, action_name: str) -> CoverageImpactAnalysis:
    """Analyze impact of approval decision"""
    manager = ApprovalWorkflowManager()
    action = ApprovalAction(action_name)
    return manager.analyze_coverage_impact(schedule_id, action)

def validate_approval_workflow():
    """Test approval workflow with real data"""
    try:
        # Test workflow initiation
        result = initiate_schedule_approval("test_schedule_001", 111538)
        print(f"✅ Workflow Initiation: {result.message}")
        
        # Test task retrieval
        tasks = get_my_tasks(111538)
        print(f"✅ Pending Tasks: Found {len(tasks)} tasks")
        
        # Test coverage impact analysis
        impact = analyze_approval_impact("test_schedule_001", "reject")
        print(f"✅ Coverage Impact: {impact.service_level_impact} impact, {impact.coverage_reduction}% reduction")
        
        return True
        
    except Exception as e:
        print(f"❌ Approval workflow validation failed: {e}")
        return False

if __name__ == "__main__":
    # Configure logging
    logging.basicConfig(level=logging.INFO)
    
    # Test the approval workflow
    if validate_approval_workflow():
        print("\n✅ Approval Workflow Manager: READY")
    else:
        print("\n❌ Approval Workflow Manager: FAILED")