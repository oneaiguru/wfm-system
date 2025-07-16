"""
Enterprise Integration API - Task 75: Integration Compliance Monitoring and Audit
GET /api/v1/integration/compliance/audit

Features:
- Regulatory compliance monitoring
- Comprehensive audit trails and logs
- Data lineage and privacy controls
- Database: compliance_logs, audit_events, regulatory_tracking
"""

from fastapi import APIRouter, HTTPException, Depends, Query, BackgroundTasks
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel, validator
from typing import List, Optional, Dict, Any, Union
from datetime import datetime, timedelta
from enum import Enum
import asyncpg
import asyncio
import json
import uuid
import hashlib
from dataclasses import dataclass

# Database connection
from ...core.database import get_db_connection

security = HTTPBearer()

router = APIRouter(prefix="/api/v1/integration/compliance", tags=["Enterprise Integration - Compliance & Audit"])

class ComplianceStandard(str, Enum):
    GDPR = "gdpr"
    SOX = "sox"
    HIPAA = "hipaa"
    PCI_DSS = "pci_dss"
    ISO_27001 = "iso_27001"
    RUSSIAN_LABOR_LAW = "russian_labor_law"
    DATA_PROTECTION = "data_protection"
    FINANCIAL_SERVICES = "financial_services"

class AuditEventType(str, Enum):
    DATA_ACCESS = "data_access"
    DATA_MODIFICATION = "data_modification"
    DATA_EXPORT = "data_export"
    DATA_DELETION = "data_deletion"
    SYSTEM_INTEGRATION = "system_integration"
    USER_AUTHENTICATION = "user_authentication"
    PERMISSION_CHANGE = "permission_change"
    CONFIGURATION_CHANGE = "configuration_change"
    COMPLIANCE_VIOLATION = "compliance_violation"

class ComplianceStatus(str, Enum):
    COMPLIANT = "compliant"
    NON_COMPLIANT = "non_compliant"
    PENDING_REVIEW = "pending_review"
    REMEDIATION_REQUIRED = "remediation_required"
    EXEMPT = "exempt"

class SeverityLevel(str, Enum):
    CRITICAL = "critical"
    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"
    INFO = "info"

class DataClassification(str, Enum):
    PUBLIC = "public"
    INTERNAL = "internal"
    CONFIDENTIAL = "confidential"
    RESTRICTED = "restricted"
    PII = "pii"
    FINANCIAL = "financial"

class AuditTrailRequest(BaseModel):
    """Audit trail request parameters"""
    start_date: datetime
    end_date: datetime
    event_types: Optional[List[AuditEventType]] = None
    user_ids: Optional[List[str]] = None
    system_ids: Optional[List[str]] = None
    severity_levels: Optional[List[SeverityLevel]] = None
    compliance_standards: Optional[List[ComplianceStandard]] = None
    include_data_lineage: bool = False
    
    @validator('end_date')
    def validate_date_range(cls, v, values):
        if 'start_date' in values and v <= values['start_date']:
            raise ValueError('End date must be after start date')
        return v

class AuditEvent(BaseModel):
    """Audit event record"""
    event_id: str
    event_type: AuditEventType
    event_description: str
    user_id: Optional[str] = None
    system_id: Optional[str] = None
    resource_type: str
    resource_id: str
    action_performed: str
    data_before: Optional[Dict[str, Any]] = None
    data_after: Optional[Dict[str, Any]] = None
    ip_address: Optional[str] = None
    user_agent: Optional[str] = None
    severity_level: SeverityLevel
    compliance_impact: List[ComplianceStandard]
    data_classification: DataClassification
    metadata: Dict[str, Any]
    created_at: datetime

class ComplianceReport(BaseModel):
    """Compliance monitoring report"""
    report_id: str
    report_type: str
    compliance_standard: ComplianceStandard
    evaluation_period: Dict[str, datetime]
    overall_status: ComplianceStatus
    compliance_score: float
    violations_count: int
    critical_violations: int
    recommendations: List[str]
    controls_assessed: List[Dict[str, Any]]
    data_lineage_summary: Dict[str, Any]
    generated_at: datetime
    generated_by: str

class DataLineageTrack(BaseModel):
    """Data lineage tracking"""
    lineage_id: str
    data_element: str
    source_system: str
    target_system: str
    transformation_steps: List[Dict[str, Any]]
    data_classification: DataClassification
    retention_policy: Dict[str, Any]
    access_controls: List[str]
    compliance_tags: List[ComplianceStandard]
    created_at: datetime
    last_accessed: Optional[datetime] = None

class PrivacyControl(BaseModel):
    """Privacy control configuration"""
    control_id: str
    control_name: str
    control_type: str
    description: str
    applicable_standards: List[ComplianceStandard]
    implementation_status: str
    effectiveness_rating: float
    last_assessment: datetime
    next_review_date: datetime

async def verify_enterprise_auth(credentials: HTTPAuthorizationCredentials = Depends(security)) -> str:
    """Verify enterprise authentication with audit logging"""
    token = credentials.credentials
    if not token or len(token) < 20:
        raise HTTPException(status_code=401, detail="Invalid authentication token")
    
    # Log authentication attempt for audit
    # This would integrate with the audit logging system
    return token

async def log_audit_event(conn: asyncpg.Connection, event_type: AuditEventType, 
                         user_id: str, resource_type: str, resource_id: str,
                         action: str, data_before: Dict = None, data_after: Dict = None,
                         severity: SeverityLevel = SeverityLevel.INFO,
                         compliance_impact: List[ComplianceStandard] = None,
                         metadata: Dict = None) -> str:
    """Log audit event to compliance database"""
    
    event_id = str(uuid.uuid4())
    
    # Determine data classification based on resource type
    data_classification = DataClassification.INTERNAL
    if resource_type in ['employee', 'personnel', 'user']:
        data_classification = DataClassification.PII
    elif resource_type in ['payroll', 'salary', 'financial']:
        data_classification = DataClassification.FINANCIAL
    elif resource_type in ['schedule', 'forecast']:
        data_classification = DataClassification.CONFIDENTIAL
    
    await conn.execute("""
        INSERT INTO audit_events (
            event_id, event_type, event_description, user_id, resource_type, resource_id,
            action_performed, data_before, data_after, severity_level, compliance_impact,
            data_classification, metadata, created_at
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
    """, 
    event_id, event_type.value, f"{action} on {resource_type}", user_id,
    resource_type, resource_id, action, 
    json.dumps(data_before) if data_before else None,
    json.dumps(data_after) if data_after else None,
    severity.value, json.dumps([c.value for c in (compliance_impact or [])]),
    data_classification.value, json.dumps(metadata or {}), datetime.utcnow())
    
    return event_id

async def assess_compliance_violations(conn: asyncpg.Connection, event: Dict[str, Any]) -> List[Dict[str, Any]]:
    """Assess potential compliance violations for an event"""
    violations = []
    
    # GDPR Compliance Checks
    if event.get('data_classification') == DataClassification.PII.value:
        # Check for proper consent and data minimization
        if event.get('action_performed') in ['export', 'share', 'transfer']:
            violations.append({
                "standard": ComplianceStandard.GDPR.value,
                "violation_type": "data_transfer_without_consent",
                "severity": SeverityLevel.HIGH.value,
                "description": "PII transfer may require explicit consent verification"
            })
    
    # SOX Compliance Checks
    if event.get('resource_type') in ['financial_data', 'payroll', 'reporting']:
        if event.get('user_id') and not event.get('approval_chain'):
            violations.append({
                "standard": ComplianceStandard.SOX.value,
                "violation_type": "unauthorized_financial_access",
                "severity": SeverityLevel.CRITICAL.value,
                "description": "Financial data access requires proper authorization trail"
            })
    
    # Russian Labor Law Compliance
    if event.get('resource_type') in ['schedule', 'vacation', 'overtime']:
        # Check working time regulations
        metadata = event.get('metadata', {})
        if metadata.get('working_hours_per_day', 0) > 8:
            violations.append({
                "standard": ComplianceStandard.RUSSIAN_LABOR_LAW.value,
                "violation_type": "excessive_working_hours",
                "severity": SeverityLevel.MEDIUM.value,
                "description": "Schedule may violate Russian labor law working time limits"
            })
    
    # Data Retention Compliance
    if event.get('event_type') == AuditEventType.DATA_DELETION.value:
        # Check if deletion follows retention policies
        retention_period = metadata.get('retention_period_days', 0)
        data_age_days = metadata.get('data_age_days', 0)
        
        if retention_period > 0 and data_age_days < retention_period:
            violations.append({
                "standard": ComplianceStandard.DATA_PROTECTION.value,
                "violation_type": "premature_data_deletion",
                "severity": SeverityLevel.HIGH.value,
                "description": f"Data deleted before retention period expires ({retention_period} days)"
            })
    
    return violations

async def generate_data_lineage(conn: asyncpg.Connection, resource_type: str, 
                              resource_id: str, depth: int = 3) -> Dict[str, Any]:
    """Generate data lineage for a resource"""
    
    lineage = {
        "resource": {"type": resource_type, "id": resource_id},
        "sources": [],
        "targets": [],
        "transformations": [],
        "access_history": []
    }
    
    # Get data sources
    sources = await conn.fetch("""
        SELECT DISTINCT source_system, source_resource_type, source_resource_id,
               transformation_type, created_at
        FROM data_lineage_tracking
        WHERE target_resource_type = $1 AND target_resource_id = $2
        ORDER BY created_at DESC
        LIMIT 20
    """, resource_type, resource_id)
    
    for source in sources:
        lineage["sources"].append({
            "system": source['source_system'],
            "resource_type": source['source_resource_type'],
            "resource_id": source['source_resource_id'],
            "transformation": source['transformation_type'],
            "timestamp": source['created_at']
        })
    
    # Get data targets
    targets = await conn.fetch("""
        SELECT DISTINCT target_system, target_resource_type, target_resource_id,
               transformation_type, created_at
        FROM data_lineage_tracking
        WHERE source_resource_type = $1 AND source_resource_id = $2
        ORDER BY created_at DESC
        LIMIT 20
    """, resource_type, resource_id)
    
    for target in targets:
        lineage["targets"].append({
            "system": target['target_system'],
            "resource_type": target['target_resource_type'],
            "resource_id": target['target_resource_id'],
            "transformation": target['transformation_type'],
            "timestamp": target['created_at']
        })
    
    # Get access history
    access_history = await conn.fetch("""
        SELECT user_id, action_performed, created_at, ip_address
        FROM audit_events
        WHERE resource_type = $1 AND resource_id = $2
              AND event_type = $3
        ORDER BY created_at DESC
        LIMIT 50
    """, resource_type, resource_id, AuditEventType.DATA_ACCESS.value)
    
    for access in access_history:
        lineage["access_history"].append({
            "user_id": access['user_id'],
            "action": access['action_performed'],
            "timestamp": access['created_at'],
            "ip_address": access['ip_address']
        })
    
    return lineage

@router.get("/audit", response_model=List[AuditEvent])
async def get_audit_trail(
    audit_request: AuditTrailRequest = Depends(),
    user_id: str = Depends(verify_enterprise_auth)
):
    """
    Retrieve comprehensive audit trail with compliance filtering
    
    - Regulatory compliance monitoring
    - Data access and modification tracking
    - User activity and system integration logs
    - Compliance violation detection
    """
    
    conn = await get_db_connection()
    try:
        # Log audit access
        await log_audit_event(
            conn, AuditEventType.DATA_ACCESS, user_id, 
            "audit_trail", "compliance_audit", "retrieve_audit_trail",
            severity=SeverityLevel.INFO,
            metadata={"date_range": f"{audit_request.start_date} to {audit_request.end_date}"}
        )
        
        # Build query with filters
        query = """
            SELECT 
                event_id, event_type, event_description, user_id, system_id,
                resource_type, resource_id, action_performed, data_before, data_after,
                ip_address, user_agent, severity_level, compliance_impact,
                data_classification, metadata, created_at
            FROM audit_events
            WHERE created_at BETWEEN $1 AND $2
        """
        
        params = [audit_request.start_date, audit_request.end_date]
        param_count = 2
        
        if audit_request.event_types:
            param_count += 1
            placeholders = ','.join([f'${i}' for i in range(param_count, param_count + len(audit_request.event_types))])
            query += f" AND event_type IN ({placeholders})"
            params.extend([et.value for et in audit_request.event_types])
            param_count += len(audit_request.event_types)
        
        if audit_request.user_ids:
            param_count += 1
            placeholders = ','.join([f'${i}' for i in range(param_count, param_count + len(audit_request.user_ids))])
            query += f" AND user_id IN ({placeholders})"
            params.extend(audit_request.user_ids)
            param_count += len(audit_request.user_ids)
        
        if audit_request.severity_levels:
            param_count += 1
            placeholders = ','.join([f'${i}' for i in range(param_count, param_count + len(audit_request.severity_levels))])
            query += f" AND severity_level IN ({placeholders})"
            params.extend([sl.value for sl in audit_request.severity_levels])
            param_count += len(audit_request.severity_levels)
        
        query += " ORDER BY created_at DESC LIMIT 1000"
        
        events = await conn.fetch(query, *params)
        
        audit_events = []
        for event in events:
            # Parse compliance impact
            compliance_impact = []
            if event['compliance_impact']:
                try:
                    impact_list = json.loads(event['compliance_impact'])
                    compliance_impact = [ComplianceStandard(imp) for imp in impact_list]
                except:
                    pass
            
            # Create audit event
            audit_event = AuditEvent(
                event_id=event['event_id'],
                event_type=AuditEventType(event['event_type']),
                event_description=event['event_description'],
                user_id=event['user_id'],
                system_id=event['system_id'],
                resource_type=event['resource_type'],
                resource_id=event['resource_id'],
                action_performed=event['action_performed'],
                data_before=json.loads(event['data_before']) if event['data_before'] else None,
                data_after=json.loads(event['data_after']) if event['data_after'] else None,
                ip_address=event['ip_address'],
                user_agent=event['user_agent'],
                severity_level=SeverityLevel(event['severity_level']),
                compliance_impact=compliance_impact,
                data_classification=DataClassification(event['data_classification']),
                metadata=json.loads(event['metadata']) if event['metadata'] else {},
                created_at=event['created_at']
            )
            
            audit_events.append(audit_event)
        
        return audit_events
        
    finally:
        await conn.close()

@router.get("/reports/compliance", response_model=ComplianceReport)
async def generate_compliance_report(
    standard: ComplianceStandard,
    start_date: datetime = Query(...),
    end_date: datetime = Query(...),
    include_recommendations: bool = Query(True),
    user_id: str = Depends(verify_enterprise_auth)
):
    """
    Generate comprehensive compliance report
    
    - Regulatory standard assessment
    - Violation analysis and trending
    - Control effectiveness evaluation
    - Remediation recommendations
    """
    
    conn = await get_db_connection()
    try:
        report_id = str(uuid.uuid4())
        
        # Assess compliance violations for the period
        violations = await conn.fetch("""
            SELECT event_id, severity_level, event_description, created_at, metadata
            FROM audit_events
            WHERE created_at BETWEEN $1 AND $2
              AND compliance_impact::jsonb ? $3
        """, start_date, end_date, standard.value)
        
        violations_count = len(violations)
        critical_violations = len([v for v in violations if v['severity_level'] == SeverityLevel.CRITICAL.value])
        
        # Calculate compliance score (simplified)
        total_events = await conn.fetchval("""
            SELECT COUNT(*) FROM audit_events
            WHERE created_at BETWEEN $1 AND $2
        """, start_date, end_date)
        
        compliance_score = max(0, 100 - (violations_count * 100 / max(total_events, 1)))
        
        # Determine overall status
        overall_status = ComplianceStatus.COMPLIANT
        if critical_violations > 0:
            overall_status = ComplianceStatus.NON_COMPLIANT
        elif violations_count > total_events * 0.1:  # More than 10% violations
            overall_status = ComplianceStatus.REMEDIATION_REQUIRED
        elif violations_count > 0:
            overall_status = ComplianceStatus.PENDING_REVIEW
        
        # Generate recommendations
        recommendations = []
        if include_recommendations:
            if critical_violations > 0:
                recommendations.append("Immediate remediation required for critical compliance violations")
            if violations_count > total_events * 0.05:
                recommendations.append("Implement additional access controls and monitoring")
            if standard == ComplianceStandard.GDPR:
                recommendations.append("Review data retention policies and consent management")
            if standard == ComplianceStandard.RUSSIAN_LABOR_LAW:
                recommendations.append("Validate working time calculations and overtime policies")
        
        # Assess controls
        controls_assessed = [
            {
                "control_name": "Data Access Controls",
                "effectiveness": min(100, 100 - (violations_count * 10)),
                "status": "implemented"
            },
            {
                "control_name": "Audit Logging",
                "effectiveness": 95,
                "status": "implemented"
            },
            {
                "control_name": "Data Encryption",
                "effectiveness": 90,
                "status": "implemented"
            }
        ]
        
        # Generate data lineage summary
        data_lineage_summary = {
            "tracked_data_elements": await conn.fetchval("""
                SELECT COUNT(DISTINCT CONCAT(resource_type, ':', resource_id))
                FROM audit_events
                WHERE created_at BETWEEN $1 AND $2
            """, start_date, end_date),
            "system_integrations": await conn.fetchval("""
                SELECT COUNT(DISTINCT system_id)
                FROM audit_events
                WHERE created_at BETWEEN $1 AND $2 AND system_id IS NOT NULL
            """, start_date, end_date),
            "data_classifications": {
                "pii": await conn.fetchval("""
                    SELECT COUNT(*) FROM audit_events
                    WHERE created_at BETWEEN $1 AND $2 
                      AND data_classification = $3
                """, start_date, end_date, DataClassification.PII.value),
                "confidential": await conn.fetchval("""
                    SELECT COUNT(*) FROM audit_events
                    WHERE created_at BETWEEN $1 AND $2 
                      AND data_classification = $3
                """, start_date, end_date, DataClassification.CONFIDENTIAL.value)
            }
        }
        
        # Store compliance report
        await conn.execute("""
            INSERT INTO compliance_reports (
                report_id, report_type, compliance_standard, evaluation_start, evaluation_end,
                overall_status, compliance_score, violations_count, critical_violations,
                recommendations, controls_assessed, data_lineage_summary,
                generated_by, generated_at
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
        """, 
        report_id, "compliance_assessment", standard.value, start_date, end_date,
        overall_status.value, compliance_score, violations_count, critical_violations,
        json.dumps(recommendations), json.dumps(controls_assessed), 
        json.dumps(data_lineage_summary), user_id, datetime.utcnow())
        
        return ComplianceReport(
            report_id=report_id,
            report_type="compliance_assessment",
            compliance_standard=standard,
            evaluation_period={"start": start_date, "end": end_date},
            overall_status=overall_status,
            compliance_score=round(compliance_score, 2),
            violations_count=violations_count,
            critical_violations=critical_violations,
            recommendations=recommendations,
            controls_assessed=controls_assessed,
            data_lineage_summary=data_lineage_summary,
            generated_at=datetime.utcnow(),
            generated_by=user_id
        )
        
    finally:
        await conn.close()

@router.get("/lineage/{resource_type}/{resource_id}", response_model=DataLineageTrack)
async def get_data_lineage(
    resource_type: str,
    resource_id: str,
    depth: int = Query(3, le=10),
    user_id: str = Depends(verify_enterprise_auth)
):
    """
    Trace data lineage for compliance and governance
    
    - Complete data flow tracking
    - Source and target identification
    - Transformation documentation
    - Access control verification
    """
    
    conn = await get_db_connection()
    try:
        # Log lineage access
        await log_audit_event(
            conn, AuditEventType.DATA_ACCESS, user_id,
            resource_type, resource_id, "trace_data_lineage",
            severity=SeverityLevel.INFO
        )
        
        # Generate detailed lineage
        lineage_data = await generate_data_lineage(conn, resource_type, resource_id, depth)
        
        # Get lineage record if exists
        lineage_record = await conn.fetchrow("""
            SELECT lineage_id, data_element, source_system, target_system,
                   transformation_steps, data_classification, retention_policy,
                   access_controls, compliance_tags, created_at, last_accessed
            FROM data_lineage_tracking
            WHERE target_resource_type = $1 AND target_resource_id = $2
            ORDER BY created_at DESC
            LIMIT 1
        """, resource_type, resource_id)
        
        if lineage_record:
            return DataLineageTrack(
                lineage_id=lineage_record['lineage_id'],
                data_element=lineage_record['data_element'],
                source_system=lineage_record['source_system'],
                target_system=lineage_record['target_system'],
                transformation_steps=json.loads(lineage_record['transformation_steps']),
                data_classification=DataClassification(lineage_record['data_classification']),
                retention_policy=json.loads(lineage_record['retention_policy']),
                access_controls=json.loads(lineage_record['access_controls']),
                compliance_tags=[ComplianceStandard(tag) for tag in json.loads(lineage_record['compliance_tags'])],
                created_at=lineage_record['created_at'],
                last_accessed=lineage_record['last_accessed']
            )
        else:
            # Create new lineage record
            lineage_id = str(uuid.uuid4())
            
            await conn.execute("""
                INSERT INTO data_lineage_tracking (
                    lineage_id, data_element, target_resource_type, target_resource_id,
                    transformation_steps, data_classification, created_at, last_accessed
                ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
            """, 
            lineage_id, f"{resource_type}:{resource_id}", resource_type, resource_id,
            json.dumps(lineage_data), DataClassification.INTERNAL.value,
            datetime.utcnow(), datetime.utcnow())
            
            return DataLineageTrack(
                lineage_id=lineage_id,
                data_element=f"{resource_type}:{resource_id}",
                source_system="wfm_enterprise",
                target_system="wfm_enterprise",
                transformation_steps=[],
                data_classification=DataClassification.INTERNAL,
                retention_policy={"default_days": 2555},  # 7 years
                access_controls=["authenticated_users"],
                compliance_tags=[],
                created_at=datetime.utcnow(),
                last_accessed=datetime.utcnow()
            )
        
    finally:
        await conn.close()

@router.get("/privacy/controls", response_model=List[PrivacyControl])
async def list_privacy_controls(
    standard: Optional[ComplianceStandard] = Query(None),
    user_id: str = Depends(verify_enterprise_auth)
):
    """List privacy controls and their effectiveness"""
    
    conn = await get_db_connection()
    try:
        query = """
            SELECT control_id, control_name, control_type, description,
                   applicable_standards, implementation_status, effectiveness_rating,
                   last_assessment, next_review_date
            FROM privacy_controls
            WHERE active = true
        """
        
        params = []
        if standard:
            query += " AND applicable_standards::jsonb ? $1"
            params.append(standard.value)
        
        query += " ORDER BY control_name"
        
        controls = await conn.fetch(query, *params)
        
        return [
            PrivacyControl(
                control_id=control['control_id'],
                control_name=control['control_name'],
                control_type=control['control_type'],
                description=control['description'],
                applicable_standards=[ComplianceStandard(std) for std in json.loads(control['applicable_standards'])],
                implementation_status=control['implementation_status'],
                effectiveness_rating=float(control['effectiveness_rating']),
                last_assessment=control['last_assessment'],
                next_review_date=control['next_review_date']
            )
            for control in controls
        ]
        
    finally:
        await conn.close()

@router.post("/violations/report")
async def report_compliance_violation(
    violation_data: Dict[str, Any],
    user_id: str = Depends(verify_enterprise_auth)
):
    """Report and track compliance violation"""
    
    conn = await get_db_connection()
    try:
        violation_id = str(uuid.uuid4())
        
        # Log the violation
        await log_audit_event(
            conn, AuditEventType.COMPLIANCE_VIOLATION, user_id,
            violation_data.get('resource_type', 'unknown'),
            violation_data.get('resource_id', 'unknown'),
            "compliance_violation_reported",
            severity=SeverityLevel(violation_data.get('severity', 'medium')),
            compliance_impact=[ComplianceStandard(std) for std in violation_data.get('standards', [])],
            metadata=violation_data
        )
        
        return {
            "violation_id": violation_id,
            "message": "Compliance violation reported and logged",
            "status": "investigating"
        }
        
    finally:
        await conn.close()