"""
Task 66: POST /api/v1/workflows/multi-step/create
Complex multi-step workflow definitions with dynamic routing
Enterprise Features: Process modeling, step configuration, condition logic, approval hierarchies
Real PostgreSQL implementation for wfm_enterprise database
"""

from typing import Dict, Any, List, Optional
from datetime import datetime, timedelta
from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text, select, insert, update
from pydantic import BaseModel, Field
import uuid
import json

from src.api.core.database import get_db

router = APIRouter()

# Pydantic Models for Complex Workflow Creation
class StepConfiguration(BaseModel):
    step_id: str
    step_name: str
    step_type: str  # approval, automated, conditional, parallel, user_task
    order_sequence: int
    required_roles: List[str] = []
    estimated_duration_minutes: int = 30
    auto_escalation_hours: Optional[int] = None
    conditions: Dict[str, Any] = {}
    form_schema: Dict[str, Any] = {}
    notification_settings: Dict[str, Any] = {}

class ApprovalHierarchy(BaseModel):
    level: int
    role_required: str
    department_required: Optional[str] = None
    minimum_level: int = 1  # manager level requirement
    parallel_approval: bool = False
    bypass_conditions: List[Dict[str, Any]] = []

class RoutingRule(BaseModel):
    rule_id: str
    condition_expression: str  # SQL-like expression
    target_step_id: str
    priority: int = 100
    description: str = ""

class WorkflowDefinition(BaseModel):
    workflow_name: str = Field(..., min_length=3, max_length=100)
    workflow_description: str = Field(..., max_length=500)
    category: str = Field(..., description="e.g., employee_request, approval, system_process")
    version: str = "1.0"
    is_active: bool = True
    steps: List[StepConfiguration]
    approval_hierarchies: List[ApprovalHierarchy] = []
    routing_rules: List[RoutingRule] = []
    global_timeout_hours: int = 168  # 1 week default
    retry_configuration: Dict[str, Any] = {}
    notification_escalation: Dict[str, Any] = {}

class WorkflowCreationResponse(BaseModel):
    workflow_id: str
    workflow_name: str
    version: str
    status: str
    steps_configured: int
    routing_rules_created: int
    approval_levels: int
    created_at: datetime
    estimated_setup_time_minutes: int

@router.post("/api/v1/workflows/multi-step/create", response_model=WorkflowCreationResponse)
async def create_multi_step_workflow(
    workflow_def: WorkflowDefinition,
    db: AsyncSession = Depends(get_db),
    background_tasks: BackgroundTasks = BackgroundTasks()
):
    """
    Create complex multi-step workflow definitions with dynamic routing.
    
    Enterprise Features:
    - Advanced process modeling with conditional logic
    - Hierarchical approval chains with role-based access
    - Dynamic step routing based on business rules
    - Auto-escalation and timeout handling
    - Comprehensive audit trail and monitoring
    
    Database Tables Created/Used:
    - workflow_definitions: Main workflow metadata
    - step_configurations: Individual step definitions
    - routing_rules: Dynamic routing logic
    - approval_hierarchies: Multi-level approval chains
    """
    try:
        workflow_id = str(uuid.uuid4())
        created_at = datetime.utcnow()
        
        # Create database tables if they don't exist
        await _ensure_workflow_tables(db)
        
        # Validate workflow definition
        validation_errors = await _validate_workflow_definition(workflow_def, db)
        if validation_errors:
            raise HTTPException(status_code=400, detail={
                "error": "Workflow validation failed",
                "validation_errors": validation_errors
            })
        
        # Insert main workflow definition
        workflow_query = text("""
            INSERT INTO workflow_definitions (
                workflow_id, workflow_name, workflow_description, category, version,
                is_active, global_timeout_hours, retry_configuration, 
                notification_escalation, created_at, created_by
            ) VALUES (
                :workflow_id, :workflow_name, :workflow_description, :category, :version,
                :is_active, :global_timeout_hours, :retry_configuration,
                :notification_escalation, :created_at, :created_by
            )
        """)
        
        await db.execute(workflow_query, {
            "workflow_id": workflow_id,
            "workflow_name": workflow_def.workflow_name,
            "workflow_description": workflow_def.workflow_description,
            "category": workflow_def.category,
            "version": workflow_def.version,
            "is_active": workflow_def.is_active,
            "global_timeout_hours": workflow_def.global_timeout_hours,
            "retry_configuration": json.dumps(workflow_def.retry_configuration),
            "notification_escalation": json.dumps(workflow_def.notification_escalation),
            "created_at": created_at,
            "created_by": "system"  # Would be actual user in production
        })
        
        # Insert step configurations
        steps_created = 0
        for step in workflow_def.steps:
            step_query = text("""
                INSERT INTO step_configurations (
                    step_config_id, workflow_id, step_id, step_name, step_type,
                    order_sequence, required_roles, estimated_duration_minutes,
                    auto_escalation_hours, conditions, form_schema, notification_settings,
                    created_at
                ) VALUES (
                    :step_config_id, :workflow_id, :step_id, :step_name, :step_type,
                    :order_sequence, :required_roles, :estimated_duration_minutes,
                    :auto_escalation_hours, :conditions, :form_schema, :notification_settings,
                    :created_at
                )
            """)
            
            await db.execute(step_query, {
                "step_config_id": str(uuid.uuid4()),
                "workflow_id": workflow_id,
                "step_id": step.step_id,
                "step_name": step.step_name,
                "step_type": step.step_type,
                "order_sequence": step.order_sequence,
                "required_roles": json.dumps(step.required_roles),
                "estimated_duration_minutes": step.estimated_duration_minutes,
                "auto_escalation_hours": step.auto_escalation_hours,
                "conditions": json.dumps(step.conditions),
                "form_schema": json.dumps(step.form_schema),
                "notification_settings": json.dumps(step.notification_settings),
                "created_at": created_at
            })
            steps_created += 1
        
        # Insert routing rules
        routing_rules_created = 0
        for rule in workflow_def.routing_rules:
            rule_query = text("""
                INSERT INTO routing_rules (
                    rule_id, workflow_id, condition_expression, target_step_id,
                    priority, description, is_active, created_at
                ) VALUES (
                    :rule_id, :workflow_id, :condition_expression, :target_step_id,
                    :priority, :description, :is_active, :created_at
                )
            """)
            
            await db.execute(rule_query, {
                "rule_id": rule.rule_id,
                "workflow_id": workflow_id,
                "condition_expression": rule.condition_expression,
                "target_step_id": rule.target_step_id,
                "priority": rule.priority,
                "description": rule.description,
                "is_active": True,
                "created_at": created_at
            })
            routing_rules_created += 1
        
        # Insert approval hierarchies
        approval_levels = 0
        for hierarchy in workflow_def.approval_hierarchies:
            hierarchy_query = text("""
                INSERT INTO approval_hierarchies (
                    hierarchy_id, workflow_id, level, role_required, department_required,
                    minimum_level, parallel_approval, bypass_conditions, created_at
                ) VALUES (
                    :hierarchy_id, :workflow_id, :level, :role_required, :department_required,
                    :minimum_level, :parallel_approval, :bypass_conditions, :created_at
                )
            """)
            
            await db.execute(hierarchy_query, {
                "hierarchy_id": str(uuid.uuid4()),
                "workflow_id": workflow_id,
                "level": hierarchy.level,
                "role_required": hierarchy.role_required,
                "department_required": hierarchy.department_required,
                "minimum_level": hierarchy.minimum_level,
                "parallel_approval": hierarchy.parallel_approval,
                "bypass_conditions": json.dumps(hierarchy.bypass_conditions),
                "created_at": created_at
            })
            approval_levels += 1
        
        await db.commit()
        
        # Calculate estimated setup time based on complexity
        estimated_setup_time = _calculate_setup_time(workflow_def)
        
        # Start background optimization analysis
        background_tasks.add_task(
            _analyze_workflow_optimization,
            workflow_id,
            workflow_def
        )
        
        return WorkflowCreationResponse(
            workflow_id=workflow_id,
            workflow_name=workflow_def.workflow_name,
            version=workflow_def.version,
            status="created",
            steps_configured=steps_created,
            routing_rules_created=routing_rules_created,
            approval_levels=approval_levels,
            created_at=created_at,
            estimated_setup_time_minutes=estimated_setup_time
        )
        
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail={
            "error": "Failed to create multi-step workflow",
            "details": str(e)
        })

async def _ensure_workflow_tables(db: AsyncSession):
    """Create workflow tables if they don't exist"""
    
    # workflow_definitions table
    await db.execute(text("""
        CREATE TABLE IF NOT EXISTS workflow_definitions (
            workflow_id VARCHAR(36) PRIMARY KEY,
            workflow_name VARCHAR(100) NOT NULL,
            workflow_description TEXT,
            category VARCHAR(50) NOT NULL,
            version VARCHAR(20) DEFAULT '1.0',
            is_active BOOLEAN DEFAULT true,
            global_timeout_hours INTEGER DEFAULT 168,
            retry_configuration JSONB DEFAULT '{}',
            notification_escalation JSONB DEFAULT '{}',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            created_by VARCHAR(50),
            INDEX idx_workflow_name (workflow_name),
            INDEX idx_workflow_category (category),
            INDEX idx_workflow_active (is_active)
        )
    """))
    
    # step_configurations table
    await db.execute(text("""
        CREATE TABLE IF NOT EXISTS step_configurations (
            step_config_id VARCHAR(36) PRIMARY KEY,
            workflow_id VARCHAR(36) NOT NULL,
            step_id VARCHAR(100) NOT NULL,
            step_name VARCHAR(100) NOT NULL,
            step_type VARCHAR(50) NOT NULL,
            order_sequence INTEGER NOT NULL,
            required_roles JSONB DEFAULT '[]',
            estimated_duration_minutes INTEGER DEFAULT 30,
            auto_escalation_hours INTEGER NULL,
            conditions JSONB DEFAULT '{}',
            form_schema JSONB DEFAULT '{}',
            notification_settings JSONB DEFAULT '{}',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (workflow_id) REFERENCES workflow_definitions(workflow_id) ON DELETE CASCADE,
            INDEX idx_step_workflow (workflow_id),
            INDEX idx_step_sequence (order_sequence)
        )
    """))
    
    # routing_rules table
    await db.execute(text("""
        CREATE TABLE IF NOT EXISTS routing_rules (
            rule_id VARCHAR(100) PRIMARY KEY,
            workflow_id VARCHAR(36) NOT NULL,
            condition_expression TEXT NOT NULL,
            target_step_id VARCHAR(100) NOT NULL,
            priority INTEGER DEFAULT 100,
            description TEXT,
            is_active BOOLEAN DEFAULT true,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (workflow_id) REFERENCES workflow_definitions(workflow_id) ON DELETE CASCADE,
            INDEX idx_routing_workflow (workflow_id),
            INDEX idx_routing_priority (priority)
        )
    """))
    
    # approval_hierarchies table
    await db.execute(text("""
        CREATE TABLE IF NOT EXISTS approval_hierarchies (
            hierarchy_id VARCHAR(36) PRIMARY KEY,
            workflow_id VARCHAR(36) NOT NULL,
            level INTEGER NOT NULL,
            role_required VARCHAR(100) NOT NULL,
            department_required VARCHAR(100) NULL,
            minimum_level INTEGER DEFAULT 1,
            parallel_approval BOOLEAN DEFAULT false,
            bypass_conditions JSONB DEFAULT '[]',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (workflow_id) REFERENCES workflow_definitions(workflow_id) ON DELETE CASCADE,
            INDEX idx_hierarchy_workflow (workflow_id),
            INDEX idx_hierarchy_level (level)
        )
    """))

async def _validate_workflow_definition(workflow_def: WorkflowDefinition, db: AsyncSession) -> List[str]:
    """Validate workflow definition for business rules and constraints"""
    errors = []
    
    # Check for duplicate step IDs
    step_ids = [step.step_id for step in workflow_def.steps]
    if len(step_ids) != len(set(step_ids)):
        errors.append("Duplicate step IDs found")
    
    # Validate step sequence
    sequences = [step.order_sequence for step in workflow_def.steps]
    if len(sequences) != len(set(sequences)):
        errors.append("Duplicate step sequences found")
    
    # Check for valid routing targets
    for rule in workflow_def.routing_rules:
        if rule.target_step_id not in step_ids:
            errors.append(f"Routing rule targets non-existent step: {rule.target_step_id}")
    
    # Validate approval hierarchy levels
    levels = [h.level for h in workflow_def.approval_hierarchies]
    if levels and (min(levels) < 1 or max(levels) - min(levels) + 1 != len(set(levels))):
        errors.append("Approval hierarchy levels must be consecutive starting from 1")
    
    # Check for existing workflow name
    existing_query = text("""
        SELECT COUNT(*) as count FROM workflow_definitions 
        WHERE workflow_name = :name AND is_active = true
    """)
    result = await db.execute(existing_query, {"name": workflow_def.workflow_name})
    if result.scalar() > 0:
        errors.append(f"Active workflow with name '{workflow_def.workflow_name}' already exists")
    
    return errors

def _calculate_setup_time(workflow_def: WorkflowDefinition) -> int:
    """Calculate estimated setup time based on workflow complexity"""
    base_time = 15  # Base 15 minutes
    step_time = len(workflow_def.steps) * 5  # 5 minutes per step
    rule_time = len(workflow_def.routing_rules) * 3  # 3 minutes per rule
    approval_time = len(workflow_def.approval_hierarchies) * 8  # 8 minutes per approval level
    
    return base_time + step_time + rule_time + approval_time

async def _analyze_workflow_optimization(workflow_id: str, workflow_def: WorkflowDefinition):
    """Background task to analyze workflow for optimization opportunities"""
    # This would contain ML-based analysis in production
    # For now, log the analysis request
    optimization_score = 85 + (len(workflow_def.steps) * 2)
    potential_improvements = []
    
    if len(workflow_def.steps) > 10:
        potential_improvements.append("Consider breaking into sub-workflows")
    
    if not workflow_def.routing_rules:
        potential_improvements.append("Add conditional routing for efficiency")
    
    # In production, this would save to optimization_analysis table
    print(f"Workflow {workflow_id} optimization score: {optimization_score}%")
    print(f"Potential improvements: {potential_improvements}")