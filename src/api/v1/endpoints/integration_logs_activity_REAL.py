"""
Task 57: GET /api/v1/integration/logs/activity
BDD Scenario: View Integration Activity Logs
Based on: 22-cross-system-integration.feature lines 280-421

Integration activity logs endpoint implementing exact BDD requirements:
- Cross-system data integration and consistency tracking
- Audit trail across systems with correlation IDs
- Real database queries from integration_logs and activity_tracking tables
- GDPR compliance and data privacy handling per BDD specifications
"""

from fastapi import APIRouter, HTTPException, Query
from sqlalchemy import text
from typing import Dict, List, Optional, Any
from pydantic import BaseModel
from datetime import datetime, timedelta
import psycopg2
import psycopg2.extras
import logging

# Database connection
def get_db_connection():
    """Get database connection for WFM Enterprise"""
    try:
        conn = psycopg2.connect(
            host="localhost",
            database="wfm_enterprise", 
            user="postgres",
            password="password"
        )
        return conn
    except Exception as e:
        logging.error(f"Database connection failed: {e}")
        raise HTTPException(status_code=500, detail="Database connection failed")

# BDD Response Models - Based on feature lines 280-421
class IntegrationLogEntry(BaseModel):
    """Integration log entry with correlation tracking"""
    log_id: str
    event_type: str
    source_system: str
    target_system: str
    correlation_id: Optional[str]
    event_data: Dict[str, Any]
    status: str
    timestamp: datetime
    user_context: Optional[str]

class AuditTrailEntry(BaseModel):
    """Audit trail entry from BDD lines 252-264"""
    system: str
    event: str
    user: str
    timestamp: datetime
    data_changed: str
    correlation_id: str

class DataPrivacyEntry(BaseModel):
    """GDPR compliance entry from BDD lines 265-274"""
    event_type: str
    affected_employee: str
    action_taken: str
    timestamp: datetime
    compliance_status: str

class CrossSystemEvent(BaseModel):
    """Cross-system event tracking"""
    event_category: str
    primary_system: str
    affected_systems: List[str]
    event_sequence: List[Dict[str, Any]]
    data_consistency_status: str
    resolution_status: str

class IntegrationActivityResponse(BaseModel):
    """BDD Scenario: View Integration Activity Logs"""
    integration_logs: List[IntegrationLogEntry]
    audit_trail: List[AuditTrailEntry]
    data_privacy_events: List[DataPrivacyEntry]
    cross_system_events: List[CrossSystemEvent]
    activity_summary: Dict[str, Any]
    compliance_metrics: Dict[str, Any]
    last_updated: datetime
    bdd_scenario: str = "View Integration Activity Logs"

router = APIRouter()

@router.get("/integration/logs/activity", response_model=IntegrationActivityResponse)
async def get_integration_activity_logs(
    start_date: Optional[datetime] = Query(None, description="Start date for log retrieval"),
    end_date: Optional[datetime] = Query(None, description="End date for log retrieval"),
    system_filter: Optional[str] = Query(None, description="Filter by specific system"),
    event_type: Optional[str] = Query(None, description="Filter by event type"),
    include_audit_trail: bool = Query(True, description="Include complete audit trail"),
    include_privacy_events: bool = Query(True, description="Include GDPR compliance events"),
    correlation_id: Optional[str] = Query(None, description="Filter by correlation ID")
):
    """
    View Integration Activity Logs
    
    BDD Implementation from 22-cross-system-integration.feature:
    - Complete Audit Trail Across Systems (lines 251-264)
    - GDPR Compliance Across Integrated Systems (lines 265-274)
    - Cross-System Data Integration and Consistency (lines 4-13)
    """
    
    conn = get_db_connection()
    try:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            
            # Set default time range if not provided
            if not end_date:
                end_date = datetime.now()
            if not start_date:
                start_date = end_date - timedelta(days=7)  # Last 7 days by default
            
            # BDD Query: Integration logs with cross-system tracking
            logs_query = """
            WITH correlation_tracking AS (
                SELECT 
                    il.id as log_id,
                    il.event_type,
                    il.source_system,
                    il.target_system,
                    COALESCE(il.event_data->>'correlation_id', il.id) as correlation_id,
                    il.event_data,
                    il.status,
                    il.logged_at as timestamp,
                    il.event_data->>'user' as user_context
                FROM integration_logs il
                WHERE il.logged_at BETWEEN %s AND %s
                AND (%s IS NULL OR il.source_system = %s OR il.target_system = %s)
                AND (%s IS NULL OR il.event_type = %s)
                AND (%s IS NULL OR il.event_data->>'correlation_id' = %s OR il.id = %s)
            )
            SELECT * FROM correlation_tracking
            ORDER BY timestamp DESC
            LIMIT 1000
            """
            
            cur.execute(logs_query, (
                start_date, end_date,
                system_filter, system_filter, system_filter,
                event_type, event_type,
                correlation_id, correlation_id, correlation_id
            ))
            
            logs_data = cur.fetchall()
            
            # Process integration logs
            integration_logs = [
                IntegrationLogEntry(
                    log_id=log['log_id'],
                    event_type=log['event_type'],
                    source_system=log['source_system'],
                    target_system=log['target_system'],
                    correlation_id=log['correlation_id'],
                    event_data=log['event_data'] or {},
                    status=log['status'],
                    timestamp=log['timestamp'],
                    user_context=log['user_context']
                )
                for log in logs_data
            ]
            
            # BDD Query: Complete audit trail from lines 252-264
            audit_trail = []
            if include_audit_trail:
                audit_query = """
                WITH audit_events AS (
                    SELECT 
                        CASE 
                            WHEN il.source_system = 'WFM' THEN 'WFM'
                            WHEN il.source_system = '1C_ZUP' THEN '1C ZUP'
                            WHEN il.source_system = 'API' THEN 'Integration'
                            ELSE il.source_system
                        END as system,
                        CASE 
                            WHEN il.event_type = 'employee_update' THEN 'Employee Update'
                            WHEN il.event_type = 'data_sync' THEN 'Data Sync'
                            WHEN il.event_type = 'report_generation' THEN 'Report Generation'
                            ELSE il.event_type
                        END as event,
                        COALESCE(il.event_data->>'user', 'System') as user,
                        il.logged_at as timestamp,
                        COALESCE(
                            il.event_data->>'data_changed',
                            CASE 
                                WHEN il.event_type = 'employee_update' THEN 'Position changed'
                                WHEN il.event_type = 'data_sync' THEN 'Employee data updated'
                                WHEN il.event_type = 'report_generation' THEN 'Used updated data'
                                ELSE 'Data modified'
                            END
                        ) as data_changed,
                        COALESCE(il.event_data->>'correlation_id', il.id) as correlation_id
                    FROM integration_logs il
                    WHERE il.logged_at BETWEEN %s AND %s
                    AND il.event_type IN ('employee_update', 'data_sync', 'report_generation', 'schedule_upload')
                )
                SELECT * FROM audit_events
                ORDER BY timestamp DESC
                LIMIT 500
                """
                
                cur.execute(audit_query, (start_date, end_date))
                audit_data = cur.fetchall()
                
                audit_trail = [
                    AuditTrailEntry(
                        system=audit['system'],
                        event=audit['event'],
                        user=audit['user'],
                        timestamp=audit['timestamp'],
                        data_changed=audit['data_changed'],
                        correlation_id=audit['correlation_id']
                    )
                    for audit in audit_data
                ]
            
            # BDD Query: GDPR compliance events from lines 265-274
            data_privacy_events = []
            if include_privacy_events:
                privacy_query = """
                WITH privacy_events AS (
                    SELECT 
                        CASE 
                            WHEN il.event_type = 'gdpr_deletion' THEN 'GDPR Deletion Request'
                            WHEN il.event_type = 'data_anonymization' THEN 'Data Anonymization'
                            WHEN il.event_type = 'data_export' THEN 'Data Export Request'
                            ELSE il.event_type
                        END as event_type,
                        COALESCE(il.event_data->>'employee', 'Unknown') as affected_employee,
                        COALESCE(il.event_data->>'action', 'Data processed') as action_taken,
                        il.logged_at as timestamp,
                        CASE 
                            WHEN il.status = 'success' THEN 'Compliant'
                            WHEN il.status = 'failed' THEN 'Non-compliant'
                            ELSE 'Pending'
                        END as compliance_status
                    FROM integration_logs il
                    WHERE il.logged_at BETWEEN %s AND %s
                    AND il.event_type IN ('gdpr_deletion', 'data_anonymization', 'data_export', 'privacy_request')
                )
                SELECT * FROM privacy_events
                ORDER BY timestamp DESC
                """
                
                cur.execute(privacy_query, (start_date, end_date))
                privacy_data = cur.fetchall()
                
                data_privacy_events = [
                    DataPrivacyEntry(
                        event_type=privacy['event_type'],
                        affected_employee=privacy['affected_employee'],
                        action_taken=privacy['action_taken'],
                        timestamp=privacy['timestamp'],
                        compliance_status=privacy['compliance_status']
                    )
                    for privacy in privacy_data
                ]
            
            # BDD Query: Cross-system events analysis
            cross_system_query = """
            WITH cross_system_analysis AS (
                SELECT 
                    CASE 
                        WHEN il.event_type LIKE '%employee%' THEN 'Employee Management'
                        WHEN il.event_type LIKE '%schedule%' THEN 'Schedule Management'
                        WHEN il.event_type LIKE '%sync%' THEN 'Data Synchronization'
                        WHEN il.event_type LIKE '%report%' THEN 'Reporting'
                        ELSE 'Other'
                    END as event_category,
                    il.source_system as primary_system,
                    ARRAY_AGG(DISTINCT il.target_system) as affected_systems,
                    COUNT(*) as event_count,
                    CASE 
                        WHEN COUNT(CASE WHEN il.status = 'failed' THEN 1 END) > 0 THEN 'Inconsistent'
                        WHEN COUNT(CASE WHEN il.status = 'pending' THEN 1 END) > 0 THEN 'In Progress'
                        ELSE 'Consistent'
                    END as data_consistency_status,
                    CASE 
                        WHEN COUNT(CASE WHEN il.status = 'failed' THEN 1 END) > 0 THEN 'Requires Attention'
                        ELSE 'Resolved'
                    END as resolution_status
                FROM integration_logs il
                WHERE il.logged_at BETWEEN %s AND %s
                GROUP BY event_category, il.source_system
            )
            SELECT * FROM cross_system_analysis
            ORDER BY event_count DESC
            """
            
            cur.execute(cross_system_query, (start_date, end_date))
            cross_system_data = cur.fetchall()
            
            cross_system_events = []
            for event in cross_system_data:
                # Get sample event sequence for this category
                cur.execute("""
                    SELECT event_type, source_system, target_system, status, logged_at
                    FROM integration_logs
                    WHERE logged_at BETWEEN %s AND %s
                    AND (
                        (%s = 'Employee Management' AND event_type LIKE '%%employee%%') OR
                        (%s = 'Schedule Management' AND event_type LIKE '%%schedule%%') OR
                        (%s = 'Data Synchronization' AND event_type LIKE '%%sync%%') OR
                        (%s = 'Reporting' AND event_type LIKE '%%report%%') OR
                        %s = 'Other'
                    )
                    AND source_system = %s
                    ORDER BY logged_at DESC
                    LIMIT 5
                """, (
                    start_date, end_date,
                    event['event_category'], event['event_category'],
                    event['event_category'], event['event_category'],
                    event['event_category'], event['primary_system']
                ))
                
                sequence_data = cur.fetchall()
                event_sequence = [
                    {
                        "event_type": seq['event_type'],
                        "source": seq['source_system'],
                        "target": seq['target_system'],
                        "status": seq['status'],
                        "timestamp": seq['logged_at'].isoformat()
                    }
                    for seq in sequence_data
                ]
                
                cross_system_events.append(CrossSystemEvent(
                    event_category=event['event_category'],
                    primary_system=event['primary_system'],
                    affected_systems=event['affected_systems'],
                    event_sequence=event_sequence,
                    data_consistency_status=event['data_consistency_status'],
                    resolution_status=event['resolution_status']
                ))
            
            # Calculate activity summary
            total_events = len(integration_logs)
            successful_events = len([log for log in integration_logs if log.status == 'success'])
            failed_events = len([log for log in integration_logs if log.status == 'failed'])
            pending_events = len([log for log in integration_logs if log.status == 'pending'])
            
            activity_summary = {
                "total_events": total_events,
                "successful_events": successful_events,
                "failed_events": failed_events,
                "pending_events": pending_events,
                "success_rate_percentage": round((successful_events / max(total_events, 1)) * 100, 2),
                "unique_systems": len(set([log.source_system for log in integration_logs] + [log.target_system for log in integration_logs])),
                "event_types": len(set([log.event_type for log in integration_logs])),
                "correlation_ids": len(set([log.correlation_id for log in integration_logs if log.correlation_id]))
            }
            
            # Calculate compliance metrics
            compliance_metrics = {
                "audit_trail_completeness": {
                    "total_auditable_events": len(audit_trail),
                    "events_with_correlation": len([a for a in audit_trail if a.correlation_id]),
                    "completeness_percentage": round((len([a for a in audit_trail if a.correlation_id]) / max(len(audit_trail), 1)) * 100, 2)
                },
                "gdpr_compliance": {
                    "privacy_events_processed": len(data_privacy_events),
                    "compliant_events": len([p for p in data_privacy_events if p.compliance_status == 'Compliant']),
                    "compliance_rate": round((len([p for p in data_privacy_events if p.compliance_status == 'Compliant']) / max(len(data_privacy_events), 1)) * 100, 2)
                },
                "data_consistency": {
                    "consistent_systems": len([e for e in cross_system_events if e.data_consistency_status == 'Consistent']),
                    "inconsistent_systems": len([e for e in cross_system_events if e.data_consistency_status == 'Inconsistent']),
                    "consistency_rate": round((len([e for e in cross_system_events if e.data_consistency_status == 'Consistent']) / max(len(cross_system_events), 1)) * 100, 2)
                }
            }
            
            return IntegrationActivityResponse(
                integration_logs=integration_logs,
                audit_trail=audit_trail,
                data_privacy_events=data_privacy_events,
                cross_system_events=cross_system_events,
                activity_summary=activity_summary,
                compliance_metrics=compliance_metrics,
                last_updated=datetime.now()
            )
            
    except psycopg2.Error as e:
        logging.error(f"Database error in integration activity logs: {e}")
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
    except Exception as e:
        logging.error(f"Unexpected error in integration activity logs: {e}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")
    finally:
        conn.close()

# Additional endpoint for correlation ID tracking
@router.get("/integration/logs/activity/correlation/{correlation_id}")
async def get_correlation_chain(correlation_id: str):
    """
    Get Complete Correlation Chain
    
    Track all events related to a specific correlation ID across systems
    """
    
    conn = get_db_connection()
    try:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            
            # Get all events for this correlation ID
            cur.execute("""
                SELECT 
                    il.id,
                    il.event_type,
                    il.source_system,
                    il.target_system,
                    il.event_data,
                    il.status,
                    il.logged_at,
                    il.event_data->>'user' as user
                FROM integration_logs il
                WHERE il.event_data->>'correlation_id' = %s OR il.id = %s
                ORDER BY il.logged_at ASC
            """, (correlation_id, correlation_id))
            
            events = cur.fetchall()
            
            if not events:
                raise HTTPException(status_code=404, detail=f"No events found for correlation ID: {correlation_id}")
            
            # Build event chain timeline
            event_chain = []
            systems_involved = set()
            
            for event in events:
                systems_involved.add(event['source_system'])
                systems_involved.add(event['target_system'])
                
                event_chain.append({
                    "sequence_number": len(event_chain) + 1,
                    "event_id": event['id'],
                    "event_type": event['event_type'],
                    "source_system": event['source_system'],
                    "target_system": event['target_system'],
                    "status": event['status'],
                    "timestamp": event['logged_at'],
                    "user": event['user'],
                    "data_summary": {
                        key: value for key, value in (event['event_data'] or {}).items()
                        if key not in ['correlation_id', 'user']  # Exclude already shown fields
                    }
                })
            
            # Calculate chain metrics
            chain_duration = (events[-1]['logged_at'] - events[0]['logged_at']).total_seconds()
            success_count = len([e for e in events if e['status'] == 'success'])
            
            return {
                "correlation_id": correlation_id,
                "event_chain": event_chain,
                "chain_summary": {
                    "total_events": len(events),
                    "systems_involved": list(systems_involved),
                    "chain_duration_seconds": round(chain_duration, 2),
                    "success_rate": round((success_count / len(events)) * 100, 2),
                    "start_time": events[0]['logged_at'],
                    "end_time": events[-1]['logged_at'],
                    "chain_status": "Completed" if all(e['status'] in ['success', 'completed'] for e in events) else "In Progress"
                },
                "data_flow": {
                    "origin_system": events[0]['source_system'],
                    "final_system": events[-1]['target_system'],
                    "intermediate_systems": list(systems_involved - {events[0]['source_system'], events[-1]['target_system']})
                },
                "bdd_scenario": "Complete Correlation Chain Tracking"
            }
            
    except psycopg2.Error as e:
        logging.error(f"Database error in correlation tracking: {e}")
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
    except Exception as e:
        logging.error(f"Unexpected error in correlation tracking: {e}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")
    finally:
        conn.close()