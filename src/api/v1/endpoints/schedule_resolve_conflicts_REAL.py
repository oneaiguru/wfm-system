"""
REAL SCHEDULE CONFLICT RESOLUTION ENDPOINT
Task 40/50: Automated and Manual Conflict Resolution
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

class ConflictResolutionRequest(BaseModel):
    conflict_detection_id: UUID
    resolution_strategy: str = "автоматическое_решение"  # Russian resolution strategies
    manual_resolutions: Optional[List[Dict[str, Any]]] = None
    apply_immediately: Optional[bool] = True

class ConflictResolutionResponse(BaseModel):
    resolution_id: str
    resolved_conflicts: List[Dict[str, Any]]
    failed_resolutions: List[Dict[str, Any]]
    resolution_summary: Dict[str, Any]
    message: str

@router.post("/schedules/conflicts/resolve", response_model=ConflictResolutionResponse, tags=["🔥 REAL Schedule Conflicts"])
async def resolve_schedule_conflicts(
    request: ConflictResolutionRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    REAL CONFLICT RESOLUTION - NO MOCKS!
    
    Resolves schedule conflicts using automated or manual strategies
    Uses real conflict_detections and work_schedules_core tables
    Supports Russian resolution strategies
    """
    try:
        # Get conflict detection results
        detection_query = text("""
            SELECT conflicts_found, resolution_suggestions, conflict_summary
            FROM conflict_detections 
            WHERE id = :detection_id
        """)
        
        detection_result = await db.execute(detection_query, {"detection_id": request.conflict_detection_id})
        detection = detection_result.fetchone()
        
        if not detection:
            raise HTTPException(
                status_code=404,
                detail=f"Результаты обнаружения конфликтов {request.conflict_detection_id} не найдены"
            )
        
        conflicts = json.loads(detection.conflicts_found) if detection.conflicts_found else []
        suggestions = json.loads(detection.resolution_suggestions) if detection.resolution_suggestions else []
        
        if not conflicts:
            raise HTTPException(
                status_code=422,
                detail="Нет конфликтов для решения"
            )
        
        resolution_id = str(uuid.uuid4())
        current_time = datetime.utcnow()
        resolved_conflicts = []
        failed_resolutions = []
        
        # Process each conflict
        for i, conflict in enumerate(conflicts):
            conflict_type = conflict.get("тип_конфликта")
            
            try:
                if request.resolution_strategy == "автоматическое_решение":
                    # Automatic resolution based on conflict type
                    if conflict_type == "пересечение_времени":
                        # Resolve time overlap by adjusting less priority schedule
                        schedule1_id = conflict["расписание1"]["id"]
                        schedule2_id = conflict["расписание2"]["id"]
                        
                        # Get schedule priorities and statuses
                        priority_query = text("""
                            SELECT id, assignment_priority, status, created_at
                            FROM work_schedules_core 
                            WHERE id IN (:id1, :id2)
                        """)
                        
                        priority_result = await db.execute(priority_query, {
                            "id1": schedule1_id,
                            "id2": schedule2_id
                        })
                        
                        schedules_priority = {str(row.id): row for row in priority_result.fetchall()}
                        
                        # Determine which schedule to adjust (newer, lower priority)
                        if (schedules_priority[schedule1_id].assignment_priority == "низкий" or
                            schedules_priority[schedule1_id].created_at > schedules_priority[schedule2_id].created_at):
                            adjust_schedule_id = schedule1_id
                            keep_schedule_id = schedule2_id
                        else:
                            adjust_schedule_id = schedule2_id
                            keep_schedule_id = schedule1_id
                        
                        # Shift the adjustable schedule by 1 day forward
                        shift_query = text("""
                            UPDATE work_schedules_core 
                            SET effective_date = effective_date + INTERVAL '1 day',
                                expiry_date = CASE 
                                    WHEN expiry_date IS NOT NULL THEN expiry_date + INTERVAL '1 day'
                                    ELSE NULL 
                                END,
                                updated_at = :updated_at,
                                resolution_note = :note
                            WHERE id = :schedule_id
                            RETURNING id, effective_date, expiry_date
                        """)
                        
                        shift_result = await db.execute(shift_query, {
                            'schedule_id': adjust_schedule_id,
                            'updated_at': current_time,
                            'note': f'Автоматическое решение конфликта времени (ID: {resolution_id})'
                        })
                        
                        updated_schedule = shift_result.fetchone()
                        
                        resolved_conflicts.append({
                            "конфликт": conflict,
                            "метод_решения": "сдвиг_по_времени",
                            "измененное_расписание": adjust_schedule_id,
                            "новый_период": f"{updated_schedule.effective_date} - {updated_schedule.expiry_date}",
                            "сохраненное_расписание": keep_schedule_id
                        })
                    
                    elif conflict_type == "превышение_часов":
                        # Resolve hour overflow by reducing hours in latest schedule
                        employee_id = conflict["employee_id"]
                        
                        # Get employee's schedules ordered by creation date
                        schedules_query = text("""
                            SELECT id, total_hours, created_at
                            FROM work_schedules_core 
                            WHERE employee_id = :employee_id
                            AND status IN ('active', 'pending', 'assigned')
                            ORDER BY created_at DESC
                            LIMIT 1
                        """)
                        
                        latest_result = await db.execute(schedules_query, {"employee_id": employee_id})
                        latest_schedule = latest_result.fetchone()
                        
                        if latest_schedule:
                            # Reduce hours to resolve overflow
                            overflow_hours = conflict["превышение"]
                            new_hours = max(latest_schedule.total_hours - overflow_hours, 20)  # Minimum 20 hours
                            
                            reduce_query = text("""
                                UPDATE work_schedules_core 
                                SET total_hours = :new_hours,
                                    updated_at = :updated_at,
                                    resolution_note = :note
                                WHERE id = :schedule_id
                                RETURNING id, total_hours
                            """)
                            
                            reduce_result = await db.execute(reduce_query, {
                                'schedule_id': latest_schedule.id,
                                'new_hours': new_hours,
                                'updated_at': current_time,
                                'note': f'Автоматическое сокращение часов для решения конфликта (ID: {resolution_id})'
                            })
                            
                            updated_schedule = reduce_result.fetchone()
                            
                            resolved_conflicts.append({
                                "конфликт": conflict,
                                "метод_решения": "сокращение_часов",
                                "измененное_расписание": str(latest_schedule.id),
                                "часы_до": latest_schedule.total_hours,
                                "часы_после": new_hours,
                                "сокращение": overflow_hours
                            })
                    
                    elif conflict_type == "ресурсный_конфликт":
                        # Resolve resource conflict by shifting time by 1 hour
                        assignments = conflict["конфликтующие_назначения"]
                        if len(assignments) > 1:
                            # Shift the second assignment by 1 hour
                            second_assignment = assignments[1]
                            schedule_id = second_assignment["расписание"]
                            
                            # Get and modify shift assignments
                            shifts_query = text("""
                                SELECT shift_assignments FROM work_schedules_core 
                                WHERE id = :schedule_id
                            """)
                            
                            shifts_result = await db.execute(shifts_query, {"schedule_id": schedule_id})
                            shifts_row = shifts_result.fetchone()
                            
                            if shifts_row and shifts_row.shift_assignments:
                                shifts = json.loads(shifts_row.shift_assignments)
                                
                                # Shift all shifts by 1 hour
                                for shift in shifts:
                                    if "время_начала" in shift and "время_окончания" in shift:
                                        start_time = datetime.strptime(shift["время_начала"], "%H:%M")
                                        end_time = datetime.strptime(shift["время_окончания"], "%H:%M")
                                        
                                        new_start = (start_time + timedelta(hours=1)).strftime("%H:%M")
                                        new_end = (end_time + timedelta(hours=1)).strftime("%H:%M")
                                        
                                        shift["время_начала"] = new_start
                                        shift["время_окончания"] = new_end
                                
                                # Update schedule
                                update_shifts_query = text("""
                                    UPDATE work_schedules_core 
                                    SET shift_assignments = :new_shifts,
                                        updated_at = :updated_at,
                                        resolution_note = :note
                                    WHERE id = :schedule_id
                                """)
                                
                                await db.execute(update_shifts_query, {
                                    'schedule_id': schedule_id,
                                    'new_shifts': json.dumps(shifts),
                                    'updated_at': current_time,
                                    'note': f'Автоматический сдвиг времени для решения ресурсного конфликта (ID: {resolution_id})'
                                })
                                
                                resolved_conflicts.append({
                                    "конфликт": conflict,
                                    "метод_решения": "сдвиг_времени",
                                    "измененное_расписание": schedule_id,
                                    "сдвиг": "+1 час"
                                })
                
                elif request.resolution_strategy == "ручное_решение" and request.manual_resolutions:
                    # Apply manual resolution if provided
                    manual_resolution = None
                    for manual in request.manual_resolutions:
                        if manual.get("конфликт_индекс") == i:
                            manual_resolution = manual
                            break
                    
                    if manual_resolution:
                        action = manual_resolution.get("действие")
                        
                        if action == "отменить_расписание":
                            schedule_id = manual_resolution.get("schedule_id")
                            cancel_query = text("""
                                UPDATE work_schedules_core 
                                SET status = 'cancelled',
                                    updated_at = :updated_at,
                                    resolution_note = :note
                                WHERE id = :schedule_id
                            """)
                            
                            await db.execute(cancel_query, {
                                'schedule_id': schedule_id,
                                'updated_at': current_time,
                                'note': f'Ручная отмена для решения конфликта (ID: {resolution_id})'
                            })
                            
                            resolved_conflicts.append({
                                "конфликт": conflict,
                                "метод_решения": "ручная_отмена",
                                "отмененное_расписание": schedule_id
                            })
                
            except Exception as e:
                failed_resolutions.append({
                    "конфликт": conflict,
                    "ошибка": str(e),
                    "индекс": i
                })
        
        # Record resolution operation
        resolution_record_query = text("""
            INSERT INTO conflict_resolutions 
            (id, detection_id, resolution_strategy, resolved_count, failed_count,
             resolved_conflicts, failed_resolutions, created_at)
            VALUES 
            (:id, :detection_id, :strategy, :resolved, :failed,
             :resolved_data, :failed_data, :created_at)
        """)
        
        await db.execute(resolution_record_query, {
            'id': resolution_id,
            'detection_id': request.conflict_detection_id,
            'strategy': request.resolution_strategy,
            'resolved': len(resolved_conflicts),
            'failed': len(failed_resolutions),
            'resolved_data': json.dumps(resolved_conflicts),
            'failed_data': json.dumps(failed_resolutions),
            'created_at': current_time
        })
        
        await db.commit()
        
        resolution_summary = {
            "всего_конфликтов": len(conflicts),
            "решено_конфликтов": len(resolved_conflicts),
            "неудачных_решений": len(failed_resolutions),
            "стратегия": request.resolution_strategy,
            "процент_успеха": round(len(resolved_conflicts) / len(conflicts) * 100, 1) if conflicts else 0,
            "применено_немедленно": request.apply_immediately
        }
        
        return ConflictResolutionResponse(
            resolution_id=resolution_id,
            resolved_conflicts=resolved_conflicts,
            failed_resolutions=failed_resolutions,
            resolution_summary=resolution_summary,
            message=f"Решение конфликтов завершено: {len(resolved_conflicts)} решено, {len(failed_resolutions)} неудачно ({resolution_summary['процент_успеха']}% успеха)"
        )
        
    except Exception as e:
        await db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Ошибка решения конфликтов: {str(e)}"
        )