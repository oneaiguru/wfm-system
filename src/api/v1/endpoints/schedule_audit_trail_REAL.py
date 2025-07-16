"""
REAL SCHEDULE AUDIT TRAIL ENDPOINT
Task 50/50: Comprehensive Audit Trail and Change Tracking
"""

from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from pydantic import BaseModel
from datetime import datetime, date, timedelta
from typing import Optional, List, Dict, Any
from uuid import UUID
import uuid
import json

from ...core.database import get_db

router = APIRouter()

class AuditTrailRequest(BaseModel):
    audit_scope: str = "все_изменения"  # все_изменения, расписание, сотрудник, отдел
    scope_id: Optional[UUID] = None
    audit_period_start: date
    audit_period_end: date
    change_types: Optional[List[str]] = None  # создание, изменение, удаление, утверждение
    include_details: Optional[bool] = True

class AuditTrailResponse(BaseModel):
    audit_id: str
    audit_records: List[Dict[str, Any]]
    audit_summary: Dict[str, Any]
    change_patterns: Dict[str, Any]
    compliance_indicators: Dict[str, Any]
    message: str

@router.post("/schedules/audit/trail", response_model=AuditTrailResponse, tags=["🔥 REAL Schedule Management"])
async def generate_audit_trail(
    request: AuditTrailRequest,
    db: AsyncSession = Depends(get_db)
):
    """REAL AUDIT TRAIL - NO MOCKS! Generates comprehensive audit trail for schedule changes"""
    try:
        # Build audit query based on scope
        conditions = [
            "al.created_at >= :start_date",
            "al.created_at <= :end_date"
        ]
        params = {
            "start_date": request.audit_period_start,
            "end_date": request.audit_period_end
        }
        
        # Add scope-specific conditions
        if request.audit_scope == "расписание" and request.scope_id:
            conditions.append("al.entity_id = :scope_id AND al.entity_type = 'schedule'")
            params["scope_id"] = request.scope_id
        elif request.audit_scope == "сотрудник" and request.scope_id:
            conditions.append("al.entity_id = :scope_id AND al.entity_type = 'employee'")
            params["scope_id"] = request.scope_id
        elif request.audit_scope == "отдел" and request.scope_id:
            # Need to get all employees in department first
            dept_employees_query = text("""
                SELECT id FROM employees WHERE department_id = :dept_id
            """)
            dept_result = await db.execute(dept_employees_query, {"dept_id": request.scope_id})
            employee_ids = [str(row.id) for row in dept_result.fetchall()]
            
            if employee_ids:
                employee_ids_str = "'" + "','".join(employee_ids) + "'"
                conditions.append(f"(al.entity_id IN ({employee_ids_str}) AND al.entity_type = 'employee')")
        
        # Add change type filter
        if request.change_types:
            change_types_str = "'" + "','".join(request.change_types) + "'"
            conditions.append(f"al.action_type IN ({change_types_str})")
        
        # Main audit log query
        audit_query = text(f"""
            SELECT 
                al.id as log_id,
                al.entity_type,
                al.entity_id,
                al.action_type,
                al.action_description,
                al.user_id,
                al.ip_address,
                al.user_agent,
                al.old_values,
                al.new_values,
                al.created_at,
                u.first_name as user_first_name,
                u.last_name as user_last_name,
                CASE 
                    WHEN al.entity_type = 'schedule' THEN (
                        SELECT ws.schedule_name 
                        FROM work_schedules_core ws 
                        WHERE ws.id = al.entity_id::uuid
                    )
                    WHEN al.entity_type = 'employee' THEN (
                        SELECT CONCAT(e.first_name, ' ', e.last_name)
                        FROM employees e 
                        WHERE e.id = al.entity_id::uuid
                    )
                    ELSE 'Неизвестно'
                END as entity_name
            FROM audit_logs al
            LEFT JOIN employees u ON al.user_id = u.id
            WHERE {' AND '.join(conditions)}
            ORDER BY al.created_at DESC
            LIMIT 1000
        """)
        
        audit_result = await db.execute(audit_query, params)
        audit_data = audit_result.fetchall()
        
        if not audit_data:
            # If no audit_logs table data, create from schedule modifications
            fallback_query = text(f"""
                SELECT 
                    sm.id,
                    'schedule' as entity_type,
                    sm.schedule_id as entity_id,
                    sm.modification_type as action_type,
                    sm.modification_reason as action_description,
                    'system' as user_id,
                    '127.0.0.1' as ip_address,
                    'system' as user_agent,
                    '{{}}' as old_values,
                    sm.changes_applied as new_values,
                    sm.created_at,
                    'Система' as user_first_name,
                    'Автоматически' as user_last_name,
                    ws.schedule_name as entity_name
                FROM schedule_modifications sm
                JOIN work_schedules_core ws ON sm.schedule_id = ws.id
                WHERE sm.created_at >= :start_date AND sm.created_at <= :end_date
                ORDER BY sm.created_at DESC
                LIMIT 500
            """)
            
            audit_result = await db.execute(fallback_query, params)
            audit_data = audit_result.fetchall()
        
        # Process audit records
        audit_records = []
        change_stats = {
            "создание": 0,
            "изменение": 0,
            "удаление": 0,
            "утверждение": 0,
            "отмена": 0
        }
        
        users_activity = {}
        hourly_activity = {}
        
        for record in audit_data:
            # Parse old and new values
            old_values = {}
            new_values = {}
            
            try:
                if record.old_values and record.old_values != '{}':
                    old_values = json.loads(record.old_values)
            except (json.JSONDecodeError, TypeError):
                old_values = {}
            
            try:
                if record.new_values and record.new_values != '{}':
                    new_values = json.loads(record.new_values)
            except (json.JSONDecodeError, TypeError):
                new_values = {}
            
            # Determine change significance
            change_significance = "незначительное"
            if record.action_type in ["создание", "удаление"]:
                change_significance = "критическое"
            elif record.action_type in ["утверждение", "отмена"]:
                change_significance = "важное"
            elif old_values and new_values:
                # Check for significant field changes
                significant_fields = ["total_hours", "status", "employee_id", "effective_date"]
                for field in significant_fields:
                    if field in old_values and field in new_values:
                        if old_values[field] != new_values[field]:
                            change_significance = "важное"
                            break
            
            # Build audit record
            audit_record = {
                "log_id": str(record.log_id),
                "тип_сущности": record.entity_type,
                "id_сущности": str(record.entity_id),
                "название_сущности": record.entity_name or "Неизвестно",
                "тип_действия": record.action_type,
                "описание_действия": record.action_description or "",
                "пользователь": f"{record.user_first_name} {record.user_last_name}",
                "ip_адрес": record.ip_address or "неизвестно",
                "пользовательский_агент": record.user_agent or "неизвестно",
                "дата_время": record.created_at.isoformat(),
                "значимость_изменения": change_significance
            }
            
            # Add detailed changes if requested
            if request.include_details:
                changes_details = []
                
                if old_values or new_values:
                    all_fields = set(old_values.keys()) | set(new_values.keys())
                    
                    for field in all_fields:
                        old_val = old_values.get(field, "не_установлено")
                        new_val = new_values.get(field, "не_установлено")
                        
                        if old_val != new_val:
                            changes_details.append({
                                "поле": field,
                                "старое_значение": str(old_val),
                                "новое_значение": str(new_val)
                            })
                
                audit_record["детали_изменений"] = changes_details
            
            audit_records.append(audit_record)
            
            # Update statistics
            action_type = record.action_type
            if action_type in change_stats:
                change_stats[action_type] += 1
            else:
                change_stats["изменение"] += 1  # Default to modification
            
            # Track user activity
            user_key = f"{record.user_first_name} {record.user_last_name}"
            if user_key not in users_activity:
                users_activity[user_key] = 0
            users_activity[user_key] += 1
            
            # Track hourly activity
            hour_key = record.created_at.strftime("%H:00")
            if hour_key not in hourly_activity:
                hourly_activity[hour_key] = 0
            hourly_activity[hour_key] += 1
        
        # Generate audit summary
        total_changes = len(audit_records)
        period_days = (request.audit_period_end - request.audit_period_start).days + 1
        
        audit_summary = {
            "всего_записей": total_changes,
            "период_аудита": f"{request.audit_period_start} - {request.audit_period_end}",
            "дней_в_периоде": period_days,
            "изменений_в_день": round(total_changes / period_days, 2) if period_days > 0 else 0,
            "область_аудита": request.audit_scope,
            "статистика_по_типам": change_stats,
            "наиболее_активные_пользователи": dict(sorted(users_activity.items(), key=lambda x: x[1], reverse=True)[:5])
        }
        
        # Analyze change patterns
        change_patterns = {
            "пиковые_часы_активности": dict(sorted(hourly_activity.items(), key=lambda x: x[1], reverse=True)[:3]),
            "частота_изменений": {
                "высокая": total_changes > period_days * 5,  # >5 changes per day
                "средняя": period_days * 2 < total_changes <= period_days * 5,  # 2-5 per day
                "низкая": total_changes <= period_days * 2  # <=2 per day
            },
            "тенденции": {
                "преобладающий_тип": max(change_stats.keys(), key=lambda k: change_stats[k]) if change_stats else "неопределено",
                "автоматизация_уровень": "высокий" if users_activity.get("Система Автоматически", 0) > total_changes * 0.5 else "низкий"
            }
        }
        
        # Calculate compliance indicators
        critical_changes = len([r for r in audit_records if r["значимость_изменения"] == "критическое"])
        unauthorized_ips = len(set(r["ip_адрес"] for r in audit_records if r["ip_адрес"] not in ["127.0.0.1", "неизвестно"]))
        
        compliance_indicators = {
            "критических_изменений": critical_changes,
            "процент_критических": round((critical_changes / total_changes * 100) if total_changes > 0 else 0, 2),
            "уникальных_ip_адресов": unauthorized_ips,
            "соблюдение_процедур": "хорошее" if critical_changes < total_changes * 0.1 else "требует_внимания",
            "полнота_аудита": "полная" if total_changes > 0 else "неполная",
            "индикаторы_риска": {
                "подозрительная_активность": unauthorized_ips > 5,
                "массовые_изменения": any(count > total_changes * 0.3 for count in users_activity.values()),
                "внерабочие_изменения": sum(hourly_activity.get(f"{h:02d}:00", 0) for h in [22, 23, 0, 1, 2, 3, 4, 5]) > total_changes * 0.2
            }
        }
        
        # Store audit trail record
        audit_id = str(uuid.uuid4())
        current_time = datetime.utcnow()
        
        audit_trail_query = text("""
            INSERT INTO audit_trails 
            (id, audit_scope, scope_id, period_start, period_end,
             total_records, audit_summary, change_patterns, compliance_indicators, created_at)
            VALUES 
            (:id, :scope, :scope_id, :start_date, :end_date,
             :total, :summary, :patterns, :compliance, :created_at)
        """)
        
        await db.execute(audit_trail_query, {
            'id': audit_id,
            'scope': request.audit_scope,
            'scope_id': request.scope_id,
            'start_date': request.audit_period_start,
            'end_date': request.audit_period_end,
            'total': total_changes,
            'summary': json.dumps(audit_summary),
            'patterns': json.dumps(change_patterns),
            'compliance': json.dumps(compliance_indicators),
            'created_at': current_time
        })
        
        await db.commit()
        
        return AuditTrailResponse(
            audit_id=audit_id,
            audit_records=audit_records,
            audit_summary=audit_summary,
            change_patterns=change_patterns,
            compliance_indicators=compliance_indicators,
            message=f"Аудиторский след сформирован: {total_changes} записей за {period_days} дней. Соблюдение процедур: {compliance_indicators['соблюдение_процедур']}"
        )
        
    except Exception as e:
        await db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Ошибка формирования аудиторского следа: {str(e)}"
        )

@router.get("/schedules/audit/changes/{entity_id}", tags=["🔥 REAL Schedule Management"])
async def get_entity_change_history(
    entity_id: UUID,
    entity_type: str = "schedule",  # schedule, employee, template
    limit: Optional[int] = 20,
    db: AsyncSession = Depends(get_db)
):
    """Get change history for specific entity"""
    try:
        # Get change history from multiple sources
        if entity_type == "schedule":
            changes_query = text("""
                SELECT 
                    sm.id,
                    sm.modification_type as change_type,
                    sm.modification_reason as reason,
                    sm.changes_applied,
                    sm.old_total_hours,
                    sm.new_total_hours,
                    sm.created_at,
                    'schedule_modification' as source
                FROM schedule_modifications sm
                WHERE sm.schedule_id = :entity_id
                
                UNION ALL
                
                SELECT 
                    al.id,
                    al.action_type as change_type,
                    al.action_description as reason,
                    al.new_values as changes_applied,
                    NULL as old_total_hours,
                    NULL as new_total_hours,
                    al.created_at,
                    'audit_log' as source
                FROM audit_logs al
                WHERE al.entity_id = :entity_id::text AND al.entity_type = 'schedule'
                
                ORDER BY created_at DESC
                LIMIT :limit
            """)
        else:
            changes_query = text("""
                SELECT 
                    al.id,
                    al.action_type as change_type,
                    al.action_description as reason,
                    al.new_values as changes_applied,
                    NULL as old_total_hours,
                    NULL as new_total_hours,
                    al.created_at,
                    'audit_log' as source
                FROM audit_logs al
                WHERE al.entity_id = :entity_id::text AND al.entity_type = :entity_type
                ORDER BY al.created_at DESC
                LIMIT :limit
            """)
        
        params = {"entity_id": entity_id, "limit": limit}
        if entity_type != "schedule":
            params["entity_type"] = entity_type
        
        changes_result = await db.execute(changes_query, params)
        changes = []
        
        for row in changes_result.fetchall():
            change_data = {
                "change_id": str(row.id),
                "тип_изменения": row.change_type,
                "причина": row.reason or "не_указана",
                "дата_изменения": row.created_at.isoformat(),
                "источник": row.source
            }
            
            # Parse change details
            if row.changes_applied:
                try:
                    changes_applied = json.loads(row.changes_applied)
                    change_data["детали_изменений"] = changes_applied
                except (json.JSONDecodeError, TypeError):
                    change_data["детали_изменений"] = row.changes_applied
            
            if row.old_total_hours is not None and row.new_total_hours is not None:
                change_data["изменение_часов"] = {
                    "старое_значение": row.old_total_hours,
                    "новое_значение": row.new_total_hours,
                    "разница": row.new_total_hours - row.old_total_hours
                }
            
            changes.append(change_data)
        
        return {
            "entity_id": str(entity_id),
            "entity_type": entity_type,
            "change_history": changes,
            "total_changes": len(changes),
            "latest_change": changes[0]["дата_изменения"] if changes else "нет_изменений"
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Ошибка получения истории изменений: {str(e)}"
        )