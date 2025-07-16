"""
REAL SCHEDULE CONFLICT DETECTION ENDPOINT
Task 39/50: Advanced Conflict Detection and Resolution Analysis
"""

from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from pydantic import BaseModel
from datetime import datetime, date, timedelta
from typing import Optional, List, Dict, Any
from uuid import UUID
import json

from ...core.database import get_db

router = APIRouter()

class ConflictDetectionRequest(BaseModel):
    scope: str = "отдел"  # отдел, сотрудник, все
    scope_id: Optional[UUID] = None
    detection_period_start: date
    detection_period_end: date
    conflict_types: List[str] = ["время", "ресурсы", "навыки", "превышение_часов"]

class ConflictDetectionResponse(BaseModel):
    detection_id: str
    conflicts_found: List[Dict[str, Any]]
    conflict_summary: Dict[str, Any]
    resolution_suggestions: List[Dict[str, Any]]
    message: str

@router.post("/schedules/conflicts/detect", response_model=ConflictDetectionResponse, tags=["🔥 REAL Schedule Conflicts"])
async def detect_schedule_conflicts(
    request: ConflictDetectionRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    REAL CONFLICT DETECTION - NO MOCKS!
    
    Detects various types of schedule conflicts with resolution suggestions
    Uses real work_schedules_core and employees tables
    Supports Russian conflict types and scopes
    """
    try:
        # Build query based on scope
        conditions = [
            "ws.effective_date <= :end_date",
            "(ws.expiry_date IS NULL OR ws.expiry_date >= :start_date)",
            "ws.status IN ('active', 'pending', 'assigned')"
        ]
        params = {
            "start_date": request.detection_period_start,
            "end_date": request.detection_period_end
        }
        
        if request.scope == "сотрудник" and request.scope_id:
            conditions.append("ws.employee_id = :scope_id")
            params["scope_id"] = request.scope_id
        elif request.scope == "отдел" and request.scope_id:
            conditions.append("e.department_id = :scope_id")
            params["scope_id"] = request.scope_id
        
        # Get schedules in scope
        schedules_query = text(f"""
            SELECT 
                ws.id, ws.employee_id, ws.schedule_name, ws.shift_assignments,
                ws.total_hours, ws.effective_date, ws.expiry_date, ws.status,
                e.first_name, e.last_name, e.max_hours_per_week, e.skills,
                e.department_id, os.department_name
            FROM work_schedules_core ws
            JOIN employees e ON ws.employee_id = e.id
            JOIN organizational_structure os ON e.department_id = os.id
            WHERE {' AND '.join(conditions)}
            ORDER BY ws.employee_id, ws.effective_date
        """)
        
        schedules_result = await db.execute(schedules_query, params)
        schedules = schedules_result.fetchall()
        
        if not schedules:
            raise HTTPException(
                status_code=404,
                detail="Нет расписаний в указанном периоде и области"
            )
        
        conflicts_found = []
        detection_id = str(uuid.uuid4())
        
        # Group schedules by employee for conflict detection
        employee_schedules = {}
        for schedule in schedules:
            emp_id = str(schedule.employee_id)
            if emp_id not in employee_schedules:
                employee_schedules[emp_id] = {
                    'employee': schedule,
                    'schedules': []
                }
            employee_schedules[emp_id]['schedules'].append(schedule)
        
        # Detect conflicts
        for emp_id, emp_data in employee_schedules.items():
            employee = emp_data['employee']
            emp_schedules = emp_data['schedules']
            
            # Time conflicts
            if "время" in request.conflict_types:
                for i, schedule1 in enumerate(emp_schedules):
                    for schedule2 in emp_schedules[i+1:]:
                        # Check for overlapping periods
                        start1, end1 = schedule1.effective_date, schedule1.expiry_date or date(2030, 12, 31)
                        start2, end2 = schedule2.effective_date, schedule2.expiry_date or date(2030, 12, 31)
                        
                        if start1 <= end2 and start2 <= end1:
                            conflicts_found.append({
                                "тип_конфликта": "пересечение_времени",
                                "сотрудник": f"{employee.first_name} {employee.last_name}",
                                "employee_id": emp_id,
                                "расписание1": {
                                    "id": str(schedule1.id),
                                    "название": schedule1.schedule_name,
                                    "период": f"{start1} - {end1}"
                                },
                                "расписание2": {
                                    "id": str(schedule2.id),
                                    "название": schedule2.schedule_name,
                                    "период": f"{start2} - {end2}"
                                },
                                "перекрытие": f"{max(start1, start2)} - {min(end1, end2)}",
                                "серьезность": "высокая"
                            })
            
            # Hours overflow conflicts
            if "превышение_часов" in request.conflict_types:
                total_hours = sum(schedule.total_hours or 0 for schedule in emp_schedules)
                max_hours = employee.max_hours_per_week or 40
                
                # Calculate period in weeks
                period_days = (request.detection_period_end - request.detection_period_start).days + 1
                period_weeks = period_days / 7
                max_period_hours = max_hours * period_weeks
                
                if total_hours > max_period_hours:
                    conflicts_found.append({
                        "тип_конфликта": "превышение_часов",
                        "сотрудник": f"{employee.first_name} {employee.last_name}",
                        "employee_id": emp_id,
                        "назначенные_часы": total_hours,
                        "максимум_часов": max_period_hours,
                        "превышение": total_hours - max_period_hours,
                        "период_недель": round(period_weeks, 1),
                        "серьезность": "средняя" if total_hours - max_period_hours <= 8 else "высокая"
                    })
        
        # Detect resource conflicts (same time slot assignments)
        if "ресурсы" in request.conflict_types:
            # Group all shifts by date and time
            time_slots = {}
            for schedule in schedules:
                shifts = json.loads(schedule.shift_assignments) if schedule.shift_assignments else []
                for shift in shifts:
                    shift_date = shift.get("дата")
                    shift_start = shift.get("время_начала")
                    shift_end = shift.get("время_окончания")
                    
                    if shift_date and shift_start:
                        slot_key = f"{shift_date}_{shift_start}_{shift_end}"
                        if slot_key not in time_slots:
                            time_slots[slot_key] = []
                        
                        time_slots[slot_key].append({
                            "schedule_id": str(schedule.id),
                            "employee_id": str(schedule.employee_id),
                            "employee_name": f"{schedule.first_name} {schedule.last_name}",
                            "shift": shift
                        })
            
            # Find overlapping assignments
            for slot_key, assignments in time_slots.items():
                if len(assignments) > 1:
                    # Check if employees are in same department (resource conflict)
                    departments = set()
                    for assignment in assignments:
                        emp_id = assignment["employee_id"]
                        if emp_id in employee_schedules:
                            departments.add(employee_schedules[emp_id]['employee'].department_id)
                    
                    if len(departments) == 1:  # Same department conflict
                        conflicts_found.append({
                            "тип_конфликта": "ресурсный_конфликт",
                            "слот_времени": slot_key.replace("_", " "),
                            "отдел": employee_schedules[assignments[0]["employee_id"]]['employee'].department_name,
                            "конфликтующие_назначения": [
                                {
                                    "сотрудник": a["employee_name"],
                                    "расписание": a["schedule_id"]
                                } for a in assignments
                            ],
                            "количество_конфликтов": len(assignments),
                            "серьезность": "средняя"
                        })
        
        # Generate resolution suggestions
        resolution_suggestions = []
        
        for conflict in conflicts_found:
            if conflict["тип_конфликта"] == "пересечение_времени":
                resolution_suggestions.append({
                    "конфликт_id": conflicts_found.index(conflict),
                    "варианты_решения": [
                        "Изменить период одного из расписаний",
                        "Объединить расписания в одно",
                        "Отменить менее приоритетное расписание"
                    ],
                    "рекомендуемое_действие": "Изменить период менее приоритетного расписания",
                    "автоматическое_решение": "возможно"
                })
            
            elif conflict["тип_конфликта"] == "превышение_часов":
                resolution_suggestions.append({
                    "конфликт_id": conflicts_found.index(conflict),
                    "варианты_решения": [
                        "Сократить часы в одном из расписаний",
                        "Перераспределить часы на другой период",
                        "Получить одобрение на сверхурочные"
                    ],
                    "рекомендуемое_действие": f"Сократить на {conflict['превышение']} часов",
                    "автоматическое_решение": "требует_одобрения"
                })
            
            elif conflict["тип_конфликта"] == "ресурсный_конфликт":
                resolution_suggestions.append({
                    "конфликт_id": conflicts_found.index(conflict),
                    "варианты_решения": [
                        "Изменить время одного из назначений",
                        "Перенести на другую дату",
                        "Распределить по разным локациям"
                    ],
                    "рекомендуемое_действие": "Сдвинуть время менее критичного назначения",
                    "автоматическое_решение": "возможно"
                })
        
        # Build conflict summary
        conflict_summary = {
            "всего_конфликтов": len(conflicts_found),
            "по_типам": {},
            "по_серьезности": {},
            "затронуто_сотрудников": len(set(c.get("employee_id") for c in conflicts_found if c.get("employee_id"))),
            "автоматически_решаемых": len([s for s in resolution_suggestions if s["автоматическое_решение"] == "возможно"]),
            "область_анализа": request.scope,
            "период_анализа": f"{request.detection_period_start} - {request.detection_period_end}"
        }
        
        # Count by types
        for conflict in conflicts_found:
            conflict_type = conflict["тип_конфликта"]
            severity = conflict.get("серьезность", "неопределенная")
            
            conflict_summary["по_типам"][conflict_type] = conflict_summary["по_типам"].get(conflict_type, 0) + 1
            conflict_summary["по_серьезности"][severity] = conflict_summary["по_серьезности"].get(severity, 0) + 1
        
        # Store detection results
        current_time = datetime.utcnow()
        
        detection_record_query = text("""
            INSERT INTO conflict_detections 
            (id, scope_type, scope_id, detection_period_start, detection_period_end,
             conflicts_found, conflict_summary, resolution_suggestions, created_at)
            VALUES 
            (:id, :scope_type, :scope_id, :start_date, :end_date,
             :conflicts, :summary, :suggestions, :created_at)
        """)
        
        await db.execute(detection_record_query, {
            'id': detection_id,
            'scope_type': request.scope,
            'scope_id': request.scope_id,
            'start_date': request.detection_period_start,
            'end_date': request.detection_period_end,
            'conflicts': json.dumps(conflicts_found),
            'summary': json.dumps(conflict_summary),
            'suggestions': json.dumps(resolution_suggestions),
            'created_at': current_time
        })
        
        await db.commit()
        
        return ConflictDetectionResponse(
            detection_id=detection_id,
            conflicts_found=conflicts_found,
            conflict_summary=conflict_summary,
            resolution_suggestions=resolution_suggestions,
            message=f"Обнаружено {len(conflicts_found)} конфликтов в области '{request.scope}' за период {request.detection_period_start} - {request.detection_period_end}"
        )
        
    except Exception as e:
        await db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Ошибка обнаружения конфликтов: {str(e)}"
        )