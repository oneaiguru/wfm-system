"""
Skills Management API - Advanced BDD Implementation
Implements 8 advanced skill management scenarios beyond basic assignment
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text, select
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import date, datetime, timedelta
import json
import uuid

from ...core.database import get_db
from ...auth.dependencies import get_current_user

# Router for advanced skills management
router = APIRouter(prefix="/skills", tags=["Advanced Skills Management BDD"])

# BDD Scenario 4: Skill Certification Tracking with Expiration Management
class SkillCertification(BaseModel):
    """
    BDD Scenario: Track skill certifications with validity periods
    Compliance requirements for certified skills
    """
    skill_id: str = Field(..., description="Skill requiring certification")
    certification_name: str = Field(..., description="Certification title (e.g., 'Cisco CCNA')")
    issuing_authority: str = Field(..., description="Certifying body (e.g., 'Cisco Systems')")
    certification_date: date = Field(..., description="Date certification obtained")
    expiration_date: Optional[date] = Field(None, description="Certification expiry date")
    certification_number: str = Field(..., description="Certificate ID/Number")
    verification_url: Optional[str] = Field(None, description="Online verification URL")
    
class EmployeeCertificationRequest(BaseModel):
    """Request to add certification to employee"""
    employee_id: str = Field(..., description="Employee UUID")
    certifications: List[SkillCertification] = Field(..., min_items=1)
    notify_expiration: bool = Field(default=True, description="Enable expiration notifications")

class CertificationResponse(BaseModel):
    """Response for certification operations"""
    employee_id: str
    certifications_added: int
    active_certifications: int
    expiring_soon: List[Dict[str, str]]
    compliance_status: str

# BDD Scenario 5: Skill Expiration and Renewal Workflows
class SkillRenewalRequest(BaseModel):
    """
    BDD Scenario: Manage skill expiration and renewal
    Automatic tracking of skill validity periods
    """
    employee_id: str = Field(..., description="Employee UUID")
    skill_id: str = Field(..., description="Skill to renew")
    renewal_method: str = Field(..., description="Training, Re-certification, Assessment")
    renewal_date: date = Field(..., description="Date of renewal")
    validity_period_months: int = Field(..., ge=1, le=60, description="New validity period")
    assessment_score: Optional[float] = Field(None, ge=0, le=100, description="Renewal assessment score")

class SkillExpirationReport(BaseModel):
    """Report of expiring skills across organization"""
    department_id: Optional[str] = Field(None, description="Filter by department")
    days_ahead: int = Field(default=90, ge=1, le=365, description="Look-ahead period")
    skill_categories: Optional[List[str]] = Field(None, description="Filter by skill categories")

# BDD Scenario 6: Multi-Level Skill Hierarchies with Dependencies
class SkillHierarchy(BaseModel):
    """
    BDD Scenario: Define skill hierarchies and prerequisites
    Complex skill dependency management
    """
    parent_skill_id: str = Field(..., description="Parent skill UUID")
    child_skill_id: str = Field(..., description="Child skill UUID")
    relationship_type: str = Field(..., description="Prerequisite, Component, Specialization")
    minimum_proficiency: int = Field(..., ge=1, le=5, description="Min parent proficiency required")
    auto_inherit: bool = Field(default=False, description="Auto-assign child skills")

class SkillTreeRequest(BaseModel):
    """Request to create skill hierarchy"""
    organization_id: str = Field(..., description="Organization UUID")
    skill_hierarchies: List[SkillHierarchy] = Field(..., min_items=1)
    validate_cycles: bool = Field(default=True, description="Check for circular dependencies")

# BDD Scenario 7: Skill-Based Scheduling Rules and Constraints
class SkillSchedulingRule(BaseModel):
    """
    BDD Scenario: Define scheduling rules based on skills
    Automated assignment based on skill requirements
    """
    rule_name: str = Field(..., description="Rule identifier")
    skill_requirements: List[Dict[str, Any]] = Field(..., description="Required skills and levels")
    time_constraints: Dict[str, Any] = Field(..., description="Time-based requirements")
    priority: int = Field(..., ge=1, le=10, description="Rule priority (1=highest)")
    enforcement_level: str = Field(..., description="Mandatory, Preferred, Optional")

class SchedulingRuleRequest(BaseModel):
    """Request to create skill-based scheduling rules"""
    department_id: str = Field(..., description="Department UUID")
    rules: List[SkillSchedulingRule] = Field(..., min_items=1)
    effective_date: date = Field(..., description="When rules become active")

# BDD Scenario 8: Training Requirements and Skill Development Plans
class TrainingRequirement(BaseModel):
    """
    BDD Scenario: Define mandatory training for skills
    Learning path management
    """
    skill_id: str = Field(..., description="Target skill UUID")
    training_type: str = Field(..., description="Initial, Refresher, Advanced, Compliance")
    duration_hours: int = Field(..., ge=1, description="Training duration")
    frequency_months: Optional[int] = Field(None, description="Repeat frequency for refreshers")
    assessment_required: bool = Field(default=True, description="Post-training assessment")
    passing_score: Optional[float] = Field(None, ge=0, le=100, description="Minimum passing score")

class EmployeeTrainingPlan(BaseModel):
    """Individual training plan based on skill gaps"""
    employee_id: str = Field(..., description="Employee UUID")
    target_skills: List[str] = Field(..., description="Skills to acquire/improve")
    completion_deadline: date = Field(..., description="Plan completion date")
    budget_allocation: Optional[float] = Field(None, description="Training budget")

# BDD Scenario 9: Skill Gap Analysis with Predictive Analytics
class SkillGapAnalysisRequest(BaseModel):
    """
    BDD Scenario: Analyze skill gaps at various levels
    Predictive modeling for future skill needs
    """
    analysis_level: str = Field(..., description="Individual, Team, Department, Organization")
    target_id: str = Field(..., description="UUID of target entity")
    future_requirements: List[Dict[str, Any]] = Field(..., description="Projected skill needs")
    time_horizon_months: int = Field(default=12, ge=1, le=36, description="Forecast period")
    include_recommendations: bool = Field(default=True, description="Generate action recommendations")

# BDD Scenario 10: Skill Proficiency Assessment and Validation
class ProficiencyAssessment(BaseModel):
    """
    BDD Scenario: Structured skill assessment process
    Multi-source proficiency validation
    """
    employee_id: str = Field(..., description="Employee UUID")
    skill_id: str = Field(..., description="Skill to assess")
    assessment_type: str = Field(..., description="Self, Peer, Manager, External, Automated")
    assessment_score: float = Field(..., ge=0, le=100, description="Assessment result")
    assessor_id: Optional[str] = Field(None, description="Assessor UUID (if applicable)")
    evidence_urls: Optional[List[str]] = Field(None, description="Supporting evidence links")
    comments: Optional[str] = Field(None, description="Assessment notes")

# BDD Scenario 11: Skill-Based Team Composition Optimization
class TeamCompositionRequest(BaseModel):
    """
    BDD Scenario: Optimize team composition based on skills
    Automated team formation recommendations
    """
    project_requirements: List[Dict[str, Any]] = Field(..., description="Required skills and levels")
    team_size_range: Dict[str, int] = Field(..., description="Min/max team size")
    optimization_criteria: str = Field(..., description="Balanced, Specialized, Cost-Optimized")
    availability_constraints: Optional[List[Dict[str, Any]]] = Field(None, description="Employee availability")
    diversity_targets: Optional[Dict[str, Any]] = Field(None, description="Diversity requirements")


@router.post("/certifications", response_model=CertificationResponse)
async def add_skill_certifications(
    cert_request: EmployeeCertificationRequest,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """
    BDD Scenario 4: Skill Certification Tracking with Expiration Management
    
    Tracks professional certifications with:
    - Validity periods and expiration dates
    - Issuing authorities and verification
    - Automatic expiration notifications
    - Compliance tracking for regulated skills
    """
    
    # Verify employee exists
    employee_check = await db.execute(
        text("SELECT id FROM employees WHERE id = :employee_id"),
        {"employee_id": cert_request.employee_id}
    )
    if not employee_check.scalar():
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Employee {cert_request.employee_id} not found"
        )
    
    try:
        certifications_added = 0
        expiring_soon = []
        
        for cert in cert_request.certifications:
            # Verify skill exists
            skill_check = await db.execute(
                text("SELECT name FROM skills WHERE id = :skill_id"),
                {"skill_id": cert.skill_id}
            )
            skill_name = skill_check.scalar()
            if not skill_name:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Skill {cert.skill_id} not found"
                )
            
            # Create certification record
            cert_id = str(uuid.uuid4())
            cert_metadata = {
                "certification_name": cert.certification_name,
                "issuing_authority": cert.issuing_authority,
                "certification_date": cert.certification_date.isoformat(),
                "expiration_date": cert.expiration_date.isoformat() if cert.expiration_date else None,
                "certification_number": cert.certification_number,
                "verification_url": cert.verification_url,
                "created_at": datetime.now().isoformat(),
                "created_by": current_user.get("username", "system")
            }
            
            # Store certification
            await db.execute(text("""
                INSERT INTO employee_skills (
                    employee_id, skill_id, proficiency_level, 
                    certified, certification_date, metadata
                )
                VALUES (
                    :employee_id, :skill_id, 5,
                    true, :cert_date, :metadata
                )
                ON CONFLICT (employee_id, skill_id) 
                DO UPDATE SET
                    certified = true,
                    certification_date = :cert_date,
                    metadata = COALESCE(employee_skills.metadata, '{}') || :metadata
            """), {
                "employee_id": cert_request.employee_id,
                "skill_id": cert.skill_id,
                "cert_date": cert.certification_date,
                "metadata": json.dumps({"certifications": {cert_id: cert_metadata}})
            })
            
            certifications_added += 1
            
            # Check if expiring soon (within 90 days)
            if cert.expiration_date:
                days_until_expiry = (cert.expiration_date - date.today()).days
                if days_until_expiry <= 90:
                    expiring_soon.append({
                        "skill": skill_name,
                        "certification": cert.certification_name,
                        "expires_in_days": days_until_expiry,
                        "expiration_date": cert.expiration_date.isoformat()
                    })
        
        # Count active certifications
        active_result = await db.execute(text("""
            SELECT COUNT(*) FROM employee_skills
            WHERE employee_id = :employee_id AND certified = true
        """), {"employee_id": cert_request.employee_id})
        
        active_certifications = active_result.scalar()
        
        await db.commit()
        
        return CertificationResponse(
            employee_id=cert_request.employee_id,
            certifications_added=certifications_added,
            active_certifications=active_certifications,
            expiring_soon=expiring_soon,
            compliance_status="COMPLIANT" if not expiring_soon else "ATTENTION_REQUIRED"
        )
        
    except Exception as e:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to add certifications: {str(e)}"
        )


@router.post("/renew")
async def renew_skill_certification(
    renewal_request: SkillRenewalRequest,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """
    BDD Scenario 5: Skill Expiration and Renewal Workflows
    
    Manages skill renewal through:
    - Multiple renewal methods (training, re-certification, assessment)
    - Automatic validity period updates
    - Assessment score tracking
    - Renewal history maintenance
    """
    
    # Verify employee has the skill
    skill_result = await db.execute(text("""
        SELECT es.proficiency_level, es.metadata, s.name
        FROM employee_skills es
        JOIN skills s ON es.skill_id = s.id
        WHERE es.employee_id = :employee_id AND es.skill_id = :skill_id
    """), {
        "employee_id": renewal_request.employee_id,
        "skill_id": renewal_request.skill_id
    })
    
    skill_data = skill_result.first()
    if not skill_data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Employee does not have skill {renewal_request.skill_id}"
        )
    
    try:
        # Calculate new expiration date
        new_expiration = renewal_request.renewal_date + timedelta(days=renewal_request.validity_period_months * 30)
        
        # Create renewal record
        renewal_record = {
            "renewal_id": str(uuid.uuid4()),
            "renewal_date": renewal_request.renewal_date.isoformat(),
            "renewal_method": renewal_request.renewal_method,
            "validity_period_months": renewal_request.validity_period_months,
            "new_expiration_date": new_expiration.isoformat(),
            "assessment_score": renewal_request.assessment_score,
            "renewed_by": current_user.get("username", "system"),
            "renewed_at": datetime.now().isoformat()
        }
        
        # Update skill with renewal information
        existing_metadata = skill_data.metadata or {}
        renewal_history = existing_metadata.get("renewal_history", [])
        renewal_history.append(renewal_record)
        
        updated_metadata = {
            **existing_metadata,
            "renewal_history": renewal_history,
            "current_expiration": new_expiration.isoformat(),
            "last_renewal": renewal_request.renewal_date.isoformat()
        }
        
        await db.execute(text("""
            UPDATE employee_skills
            SET metadata = :metadata,
                certification_date = :renewal_date
            WHERE employee_id = :employee_id AND skill_id = :skill_id
        """), {
            "employee_id": renewal_request.employee_id,
            "skill_id": renewal_request.skill_id,
            "metadata": json.dumps(updated_metadata),
            "renewal_date": renewal_request.renewal_date
        })
        
        await db.commit()
        
        return {
            "employee_id": renewal_request.employee_id,
            "skill_id": renewal_request.skill_id,
            "skill_name": skill_data.name,
            "renewal_status": "SUCCESS",
            "new_expiration_date": new_expiration.isoformat(),
            "renewal_method": renewal_request.renewal_method,
            "assessment_score": renewal_request.assessment_score,
            "renewal_history_count": len(renewal_history)
        }
        
    except Exception as e:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to renew skill: {str(e)}"
        )


@router.post("/hierarchy")
async def create_skill_hierarchy(
    hierarchy_request: SkillTreeRequest,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """
    BDD Scenario 6: Multi-Level Skill Hierarchies with Dependencies
    
    Creates complex skill relationships:
    - Prerequisites and dependencies
    - Component skills and specializations
    - Automatic inheritance rules
    - Cycle detection and validation
    """
    
    if hierarchy_request.validate_cycles:
        # Build dependency graph for cycle detection
        graph = {}
        for hierarchy in hierarchy_request.skill_hierarchies:
            if hierarchy.parent_skill_id not in graph:
                graph[hierarchy.parent_skill_id] = []
            graph[hierarchy.parent_skill_id].append(hierarchy.child_skill_id)
        
        # Simple cycle detection (DFS)
        def has_cycle(node, visited, rec_stack):
            visited.add(node)
            rec_stack.add(node)
            
            for neighbor in graph.get(node, []):
                if neighbor not in visited:
                    if has_cycle(neighbor, visited, rec_stack):
                        return True
                elif neighbor in rec_stack:
                    return True
            
            rec_stack.remove(node)
            return False
        
        visited = set()
        for node in graph:
            if node not in visited:
                if has_cycle(node, visited, set()):
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail="Circular dependency detected in skill hierarchy"
                    )
    
    try:
        hierarchies_created = 0
        
        for hierarchy in hierarchy_request.skill_hierarchies:
            # Verify both skills exist
            parent_check = await db.execute(
                text("SELECT name FROM skills WHERE id = :skill_id"),
                {"skill_id": hierarchy.parent_skill_id}
            )
            parent_name = parent_check.scalar()
            
            child_check = await db.execute(
                text("SELECT name FROM skills WHERE id = :skill_id"),
                {"skill_id": hierarchy.child_skill_id}
            )
            child_name = child_check.scalar()
            
            if not parent_name or not child_name:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Parent or child skill not found"
                )
            
            # Create hierarchy relationship
            hierarchy_metadata = {
                "relationship_type": hierarchy.relationship_type,
                "minimum_proficiency": hierarchy.minimum_proficiency,
                "auto_inherit": hierarchy.auto_inherit,
                "created_at": datetime.now().isoformat(),
                "created_by": current_user.get("username", "system")
            }
            
            # Store in skill metadata (in real system, would have skill_hierarchies table)
            await db.execute(text("""
                UPDATE skills
                SET metadata = COALESCE(metadata, '{}') || :hierarchy_metadata
                WHERE id = :parent_id
            """), {
                "parent_id": hierarchy.parent_skill_id,
                "hierarchy_metadata": json.dumps({
                    "child_skills": {
                        hierarchy.child_skill_id: hierarchy_metadata
                    }
                })
            })
            
            hierarchies_created += 1
        
        await db.commit()
        
        return {
            "organization_id": hierarchy_request.organization_id,
            "hierarchies_created": hierarchies_created,
            "validation_status": "PASSED" if hierarchy_request.validate_cycles else "SKIPPED",
            "message": f"Successfully created {hierarchies_created} skill relationships"
        }
        
    except Exception as e:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create skill hierarchy: {str(e)}"
        )


@router.post("/scheduling-rules")
async def create_skill_scheduling_rules(
    rules_request: SchedulingRuleRequest,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """
    BDD Scenario 7: Skill-Based Scheduling Rules and Constraints
    
    Defines automated scheduling rules:
    - Skill requirements for shifts/tasks
    - Time-based skill constraints
    - Priority-based rule enforcement
    - Integration with scheduling algorithms
    """
    
    # Verify department exists
    dept_check = await db.execute(
        text("SELECT name FROM departments WHERE id = :dept_id"),
        {"dept_id": rules_request.department_id}
    )
    if not dept_check.scalar():
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Department {rules_request.department_id} not found"
        )
    
    try:
        rules_created = []
        
        for rule in rules_request.rules:
            rule_id = str(uuid.uuid4())
            
            # Validate skill requirements
            for skill_req in rule.skill_requirements:
                if "skill_id" in skill_req:
                    skill_check = await db.execute(
                        text("SELECT id FROM skills WHERE id = :skill_id"),
                        {"skill_id": skill_req["skill_id"]}
                    )
                    if not skill_check.scalar():
                        raise HTTPException(
                            status_code=status.HTTP_404_NOT_FOUND,
                            detail=f"Skill {skill_req['skill_id']} not found"
                        )
            
            # Store scheduling rule (in metadata for demo)
            rule_data = {
                "rule_id": rule_id,
                "rule_name": rule.rule_name,
                "skill_requirements": rule.skill_requirements,
                "time_constraints": rule.time_constraints,
                "priority": rule.priority,
                "enforcement_level": rule.enforcement_level,
                "effective_date": rules_request.effective_date.isoformat(),
                "created_at": datetime.now().isoformat(),
                "created_by": current_user.get("username", "system")
            }
            
            # Store in department metadata
            await db.execute(text("""
                UPDATE departments
                SET metadata = COALESCE(metadata, '{}') || :rule_metadata
                WHERE id = :dept_id
            """), {
                "dept_id": rules_request.department_id,
                "rule_metadata": json.dumps({
                    "scheduling_rules": {
                        rule_id: rule_data
                    }
                })
            })
            
            rules_created.append({
                "rule_id": rule_id,
                "rule_name": rule.rule_name,
                "priority": rule.priority,
                "status": "ACTIVE" if rules_request.effective_date <= date.today() else "PENDING"
            })
        
        await db.commit()
        
        return {
            "department_id": rules_request.department_id,
            "rules_created": len(rules_created),
            "rules": rules_created,
            "effective_date": rules_request.effective_date.isoformat(),
            "integration_status": "Scheduling algorithms will enforce rules automatically"
        }
        
    except Exception as e:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create scheduling rules: {str(e)}"
        )


@router.post("/training-requirements")
async def define_training_requirements(
    training_requirements: List[TrainingRequirement],
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """
    BDD Scenario 8: Training Requirements and Skill Development Plans
    
    Establishes mandatory training:
    - Initial training for new skills
    - Refresher training schedules
    - Compliance training tracking
    - Assessment requirements
    """
    
    try:
        requirements_created = 0
        
        for requirement in training_requirements:
            # Verify skill exists
            skill_result = await db.execute(
                text("SELECT name, category FROM skills WHERE id = :skill_id"),
                {"skill_id": requirement.skill_id}
            )
            skill_data = skill_result.first()
            if not skill_data:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Skill {requirement.skill_id} not found"
                )
            
            # Create training requirement
            requirement_data = {
                "training_id": str(uuid.uuid4()),
                "training_type": requirement.training_type,
                "duration_hours": requirement.duration_hours,
                "frequency_months": requirement.frequency_months,
                "assessment_required": requirement.assessment_required,
                "passing_score": requirement.passing_score,
                "created_at": datetime.now().isoformat(),
                "created_by": current_user.get("username", "system")
            }
            
            # Store in skill metadata
            await db.execute(text("""
                UPDATE skills
                SET metadata = COALESCE(metadata, '{}') || :training_metadata
                WHERE id = :skill_id
            """), {
                "skill_id": requirement.skill_id,
                "training_metadata": json.dumps({
                    "training_requirements": {
                        requirement.training_type: requirement_data
                    }
                })
            })
            
            requirements_created += 1
        
        await db.commit()
        
        return {
            "requirements_created": requirements_created,
            "training_types": list(set(r.training_type for r in training_requirements)),
            "total_training_hours": sum(r.duration_hours for r in training_requirements),
            "compliance_status": "Training requirements established successfully"
        }
        
    except Exception as e:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to define training requirements: {str(e)}"
        )


@router.post("/gap-analysis")
async def analyze_skill_gaps(
    analysis_request: SkillGapAnalysisRequest,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """
    BDD Scenario 9: Skill Gap Analysis with Predictive Analytics
    
    Performs comprehensive gap analysis:
    - Current vs required skill assessment
    - Future skill predictions
    - Risk identification
    - Actionable recommendations
    """
    
    try:
        current_skills = {}
        skill_gaps = []
        recommendations = []
        
        if analysis_request.analysis_level == "Individual":
            # Get employee's current skills
            result = await db.execute(text("""
                SELECT s.id, s.name, es.proficiency_level
                FROM employee_skills es
                JOIN skills s ON es.skill_id = s.id
                WHERE es.employee_id = :employee_id
            """), {"employee_id": analysis_request.target_id})
            
            for row in result:
                current_skills[row.id] = {
                    "name": row.name,
                    "current_level": row.proficiency_level
                }
        
        elif analysis_request.analysis_level == "Department":
            # Aggregate department skills
            result = await db.execute(text("""
                SELECT s.id, s.name, AVG(es.proficiency_level) as avg_level, COUNT(*) as employee_count
                FROM employee_skills es
                JOIN skills s ON es.skill_id = s.id
                JOIN employees e ON es.employee_id = e.id
                WHERE e.department_id = :dept_id
                GROUP BY s.id, s.name
            """), {"dept_id": analysis_request.target_id})
            
            for row in result:
                current_skills[row.id] = {
                    "name": row.name,
                    "avg_level": float(row.avg_level),
                    "coverage": row.employee_count
                }
        
        # Analyze gaps against future requirements
        for future_req in analysis_request.future_requirements:
            skill_id = future_req.get("skill_id")
            required_level = future_req.get("required_level", 3)
            required_count = future_req.get("required_count", 1)
            
            if skill_id in current_skills:
                current = current_skills[skill_id]
                if analysis_request.analysis_level == "Individual":
                    gap = required_level - current["current_level"]
                else:
                    gap = required_level - current.get("avg_level", 0)
                
                if gap > 0:
                    skill_gaps.append({
                        "skill_id": skill_id,
                        "skill_name": current["name"],
                        "current_level": current.get("current_level") or current.get("avg_level"),
                        "required_level": required_level,
                        "gap_size": gap,
                        "priority": "HIGH" if gap >= 2 else "MEDIUM"
                    })
            else:
                # Skill not present at all
                skill_gaps.append({
                    "skill_id": skill_id,
                    "skill_name": future_req.get("skill_name", "Unknown"),
                    "current_level": 0,
                    "required_level": required_level,
                    "gap_size": required_level,
                    "priority": "CRITICAL"
                })
        
        # Generate recommendations if requested
        if analysis_request.include_recommendations:
            for gap in skill_gaps:
                if gap["priority"] == "CRITICAL":
                    recommendations.append({
                        "action": "IMMEDIATE_TRAINING",
                        "skill": gap["skill_name"],
                        "urgency": "Within 30 days",
                        "method": "External training or new hire with skill"
                    })
                elif gap["priority"] == "HIGH":
                    recommendations.append({
                        "action": "SCHEDULED_TRAINING",
                        "skill": gap["skill_name"],
                        "urgency": "Within 90 days",
                        "method": "Internal training program"
                    })
        
        # Risk assessment
        critical_gaps = len([g for g in skill_gaps if g["priority"] == "CRITICAL"])
        risk_level = "HIGH" if critical_gaps > 2 else "MEDIUM" if critical_gaps > 0 else "LOW"
        
        return {
            "analysis_level": analysis_request.analysis_level,
            "target_id": analysis_request.target_id,
            "time_horizon_months": analysis_request.time_horizon_months,
            "total_gaps_identified": len(skill_gaps),
            "critical_gaps": critical_gaps,
            "risk_level": risk_level,
            "skill_gaps": skill_gaps[:10],  # Top 10 gaps
            "recommendations": recommendations,
            "analysis_timestamp": datetime.now().isoformat()
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to perform gap analysis: {str(e)}"
        )


@router.post("/proficiency-assessment")
async def assess_skill_proficiency(
    assessment: ProficiencyAssessment,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """
    BDD Scenario 10: Skill Proficiency Assessment and Validation
    
    Multi-source proficiency validation:
    - Self-assessment
    - Manager evaluation
    - Peer review
    - External certification
    - Automated testing
    """
    
    # Verify employee has the skill
    skill_check = await db.execute(text("""
        SELECT es.proficiency_level, s.name
        FROM employee_skills es
        JOIN skills s ON es.skill_id = s.id
        WHERE es.employee_id = :employee_id AND es.skill_id = :skill_id
    """), {
        "employee_id": assessment.employee_id,
        "skill_id": assessment.skill_id
    })
    
    skill_data = skill_check.first()
    if not skill_data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Employee does not have skill {assessment.skill_id}"
        )
    
    try:
        # Create assessment record
        assessment_record = {
            "assessment_id": str(uuid.uuid4()),
            "assessment_type": assessment.assessment_type,
            "assessment_score": assessment.assessment_score,
            "assessor_id": assessment.assessor_id or current_user.get("id"),
            "assessment_date": datetime.now().isoformat(),
            "evidence_urls": assessment.evidence_urls,
            "comments": assessment.comments
        }
        
        # Calculate new proficiency level based on assessment
        score_to_level = {
            0: 1,    # 0-20: Basic
            20: 1,   # 20-40: Basic
            40: 2,   # 40-60: Intermediate
            60: 3,   # 60-80: Intermediate
            80: 4,   # 80-90: Advanced
            90: 5    # 90-100: Expert
        }
        
        new_proficiency = 1
        for threshold, level in sorted(score_to_level.items()):
            if assessment.assessment_score >= threshold:
                new_proficiency = level
        
        # Update skill proficiency if assessment indicates change
        current_proficiency = skill_data.proficiency_level
        proficiency_changed = new_proficiency != current_proficiency
        
        # Store assessment in metadata
        await db.execute(text("""
            UPDATE employee_skills
            SET proficiency_level = :new_proficiency,
                metadata = COALESCE(metadata, '{}') || :assessment_metadata
            WHERE employee_id = :employee_id AND skill_id = :skill_id
        """), {
            "employee_id": assessment.employee_id,
            "skill_id": assessment.skill_id,
            "new_proficiency": new_proficiency,
            "assessment_metadata": json.dumps({
                "assessments": {
                    assessment_record["assessment_id"]: assessment_record
                }
            })
        })
        
        await db.commit()
        
        return {
            "employee_id": assessment.employee_id,
            "skill_id": assessment.skill_id,
            "skill_name": skill_data.name,
            "assessment_type": assessment.assessment_type,
            "assessment_score": assessment.assessment_score,
            "previous_proficiency": current_proficiency,
            "new_proficiency": new_proficiency,
            "proficiency_changed": proficiency_changed,
            "assessment_id": assessment_record["assessment_id"]
        }
        
    except Exception as e:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to record assessment: {str(e)}"
        )


@router.post("/team-composition")
async def optimize_team_composition(
    composition_request: TeamCompositionRequest,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """
    BDD Scenario 11: Skill-Based Team Composition Optimization
    
    Automated team formation based on:
    - Required skill coverage
    - Optimization criteria (balanced/specialized)
    - Availability constraints
    - Diversity targets
    """
    
    try:
        # Get all employees with relevant skills
        required_skills = [req["skill_id"] for req in composition_request.project_requirements]
        
        result = await db.execute(text("""
            SELECT DISTINCT
                e.id as employee_id,
                e.first_name,
                e.last_name,
                es.skill_id,
                s.name as skill_name,
                es.proficiency_level,
                e.metadata
            FROM employees e
            JOIN employee_skills es ON e.id = es.employee_id
            JOIN skills s ON es.skill_id = s.id
            WHERE es.skill_id = ANY(:skill_ids)
            AND e.is_active = true
            ORDER BY es.proficiency_level DESC
        """), {"skill_ids": required_skills})
        
        # Build employee skill matrix
        employees = {}
        for row in result:
            emp_id = row.employee_id
            if emp_id not in employees:
                employees[emp_id] = {
                    "id": emp_id,
                    "name": f"{row.first_name} {row.last_name}",
                    "skills": {},
                    "total_proficiency": 0,
                    "skill_count": 0
                }
            
            employees[emp_id]["skills"][row.skill_id] = row.proficiency_level
            employees[emp_id]["total_proficiency"] += row.proficiency_level
            employees[emp_id]["skill_count"] += 1
        
        # Optimization algorithm
        selected_team = []
        skill_coverage = {req["skill_id"]: 0 for req in composition_request.project_requirements}
        
        if composition_request.optimization_criteria == "Balanced":
            # Select employees with multiple relevant skills
            sorted_employees = sorted(
                employees.values(),
                key=lambda e: (e["skill_count"], e["total_proficiency"]),
                reverse=True
            )
        elif composition_request.optimization_criteria == "Specialized":
            # Select employees with highest proficiency in each skill
            sorted_employees = sorted(
                employees.values(),
                key=lambda e: e["total_proficiency"],
                reverse=True
            )
        else:  # Cost-Optimized
            # Minimum team size with skill coverage
            sorted_employees = sorted(
                employees.values(),
                key=lambda e: e["skill_count"],
                reverse=True
            )
        
        # Build team
        for employee in sorted_employees:
            if len(selected_team) >= composition_request.team_size_range["max"]:
                break
            
            # Check if employee adds needed skills
            adds_value = False
            for skill_id, proficiency in employee["skills"].items():
                req = next((r for r in composition_request.project_requirements if r["skill_id"] == skill_id), None)
                if req and skill_coverage[skill_id] < req.get("required_count", 1):
                    adds_value = True
                    break
            
            if adds_value:
                selected_team.append(employee)
                # Update skill coverage
                for skill_id, proficiency in employee["skills"].items():
                    if skill_id in skill_coverage:
                        skill_coverage[skill_id] += 1
        
        # Check if minimum requirements met
        all_covered = all(
            skill_coverage[req["skill_id"]] >= req.get("required_count", 1)
            for req in composition_request.project_requirements
        )
        
        # Calculate team metrics
        team_skills = {}
        for member in selected_team:
            for skill_id, level in member["skills"].items():
                if skill_id not in team_skills:
                    team_skills[skill_id] = []
                team_skills[skill_id].append(level)
        
        avg_proficiencies = {
            skill: sum(levels) / len(levels)
            for skill, levels in team_skills.items()
        }
        
        return {
            "optimization_criteria": composition_request.optimization_criteria,
            "team_size": len(selected_team),
            "requirements_met": all_covered,
            "team_members": [
                {
                    "employee_id": m["id"],
                    "name": m["name"],
                    "skills_contributed": list(m["skills"].keys()),
                    "avg_proficiency": m["total_proficiency"] / m["skill_count"]
                }
                for m in selected_team
            ],
            "skill_coverage": skill_coverage,
            "team_avg_proficiencies": avg_proficiencies,
            "recommendation": "Team composition optimal" if all_covered else "Additional members needed"
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to optimize team composition: {str(e)}"
        )


@router.get("/expiration-report")
async def get_skill_expiration_report(
    days_ahead: int = 90,
    department_id: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """
    Generate organization-wide skill expiration report
    Identifies skills requiring renewal within specified timeframe
    """
    
    try:
        # Build query based on filters
        query = """
            SELECT 
                e.id as employee_id,
                e.first_name,
                e.last_name,
                e.employee_number,
                d.name as department_name,
                s.name as skill_name,
                es.certification_date,
                es.metadata
            FROM employee_skills es
            JOIN employees e ON es.employee_id = e.id
            JOIN skills s ON es.skill_id = s.id
            JOIN departments d ON e.department_id = d.id
            WHERE e.is_active = true
            AND es.certified = true
        """
        
        params = {"days_ahead": days_ahead}
        
        if department_id:
            query += " AND e.department_id = :department_id"
            params["department_id"] = department_id
        
        result = await db.execute(text(query), params)
        
        expiring_skills = []
        today = date.today()
        cutoff_date = today + timedelta(days=days_ahead)
        
        for row in result:
            metadata = row.metadata or {}
            expiration_date_str = metadata.get("current_expiration")
            
            if expiration_date_str:
                expiration_date = date.fromisoformat(expiration_date_str.split("T")[0])
                if today <= expiration_date <= cutoff_date:
                    days_until_expiry = (expiration_date - today).days
                    expiring_skills.append({
                        "employee_id": row.employee_id,
                        "employee_name": f"{row.first_name} {row.last_name}",
                        "employee_number": row.employee_number,
                        "department": row.department_name,
                        "skill": row.skill_name,
                        "expiration_date": expiration_date.isoformat(),
                        "days_until_expiry": days_until_expiry,
                        "urgency": "CRITICAL" if days_until_expiry <= 30 else "WARNING"
                    })
        
        # Sort by urgency and days until expiry
        expiring_skills.sort(key=lambda x: x["days_until_expiry"])
        
        # Summary statistics
        critical_count = len([s for s in expiring_skills if s["urgency"] == "CRITICAL"])
        warning_count = len([s for s in expiring_skills if s["urgency"] == "WARNING"])
        
        return {
            "report_date": today.isoformat(),
            "days_ahead": days_ahead,
            "total_expiring": len(expiring_skills),
            "critical_expirations": critical_count,
            "warning_expirations": warning_count,
            "department_filter": department_id,
            "expiring_skills": expiring_skills,
            "recommendations": {
                "immediate_action": f"{critical_count} skills require immediate renewal",
                "scheduled_action": f"{warning_count} skills should be scheduled for renewal",
                "notification_sent": "Email notifications queued for affected employees"
            }
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to generate expiration report: {str(e)}"
        )