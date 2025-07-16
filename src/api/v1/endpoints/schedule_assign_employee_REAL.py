"""
REAL SCHEDULE EMPLOYEE ASSIGNMENT ENDPOINT
Task 36/50: Direct Employee Schedule Assignment Management
"""

from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from pydantic import BaseModel
from datetime import datetime, date
from typing import Optional, List, Dict, Any
from uuid import UUID
import uuid
import json

from ...core.database import get_db

router = APIRouter()

class ScheduleAssignmentRequest(BaseModel):
    employee_id: UUID
    template_id: Optional[UUID] = None
    assignment_period_start: date
    assignment_period_end: date
    shift_assignments: List[Dict[str, Any]]
    override_conflicts: Optional[bool] = False
    assignment_priority: str = "стандартный"  # Russian priority levels
    assignment_reason: Optional[str] = "прямое_назначение"
    notify_employee: Optional[bool] = True

class ScheduleAssignmentResponse(BaseModel):
    assignment_id: str
    employee_id: str
    schedule_details: Dict[str, Any]
    conflict_analysis: Dict[str, Any]
    assignment_status: str
    notification_status: str
    message: str

@router.post("/schedules/assignments/employee", response_model=ScheduleAssignmentResponse, tags=["🔥 REAL Schedule Assignments"])
async def assign_schedule_to_employee(
    request: ScheduleAssignmentRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    REAL EMPLOYEE SCHEDULE ASSIGNMENT - NO MOCKS!
    
    Directly assigns schedules to employees with conflict detection
    Uses real work_schedules_core and employees tables
    Supports Russian priority levels and assignment reasons
    
    UNBLOCKS: Direct schedule assignment workflows
    """
    try:
        # Validate employee exists
        employee_query = text("""
            SELECT 
                e.id, e.first_name, e.last_name, e.position, e.department_id,
                e.max_hours_per_week, e.availability_pattern, e.shift_preferences,
                os.department_name
            FROM employees e
            JOIN organizational_structure os ON e.department_id = os.id
            WHERE e.id = :employee_id AND e.is_active = true
        """)
        
        employee_result = await db.execute(employee_query, {"employee_id": request.employee_id})
        employee = employee_result.fetchone()
        
        if not employee:
            raise HTTPException(
                status_code=404,
                detail=f"Активный сотрудник {request.employee_id} не найден"
            )
        
        # Validate template if provided
        template = None
        if request.template_id:
            template_query = text("""
                SELECT id, template_name, template_type, cost_per_hour, department_id
                FROM schedule_templates 
                WHERE id = :template_id AND is_active = true
            """)
            
            template_result = await db.execute(template_query, {"template_id": request.template_id})
            template = template_result.fetchone()
            
            if not template:
                raise HTTPException(
                    status_code=404,
                    detail=f"Активный шаблон {request.template_id} не найден"
                )
        
        # Check for existing schedule conflicts
        conflict_query = text("""
            SELECT 
                ws.id,
                ws.schedule_name,
                ws.effective_date,
                ws.expiry_date,
                ws.status,
                ws.assignment_priority
            FROM work_schedules_core ws
            WHERE ws.employee_id = :employee_id
            AND ws.status IN ('active', 'pending', 'approved')
            AND ws.effective_date <= :end_date
            AND (ws.expiry_date IS NULL OR ws.expiry_date >= :start_date)
        """)
        
        conflict_result = await db.execute(conflict_query, {
            "employee_id": request.employee_id,
            "start_date": request.assignment_period_start,
            "end_date": request.assignment_period_end
        })
        
        existing_schedules = conflict_result.fetchall()
        
        # Analyze conflicts
        conflict_analysis = {
            "найдено_конфликтов": len(existing_schedules),
            "конфликтующие_расписания": [],
            "тип_конфликта": [],
            "рекомендации": [],
            "можно_переопределить": request.override_conflicts
        }
        
        for existing in existing_schedules:
            conflict_info = {
                "schedule_id": str(existing.id),
                "название": existing.schedule_name,
                "период": f"{existing.effective_date} - {existing.expiry_date}" if existing.expiry_date else f"с {existing.effective_date}",
                "статус": existing.status,
                "приоритет": existing.assignment_priority
            }
            conflict_analysis["конфликтующие_расписания"].append(conflict_info)
            
            # Determine conflict severity
            if existing.assignment_priority == "высокий":
                conflict_analysis["тип_конфликта"].append("высокоприоритетный_конфликт")
            elif existing.status == "active":
                conflict_analysis["тип_конфликта"].append("активное_расписание")
            else:
                conflict_analysis["тип_конфликта"].append("ожидающее_расписание")
        
        # Generate recommendations
        if existing_schedules and not request.override_conflicts:
            conflict_analysis["рекомендации"].extend([
                "Используйте override_conflicts=true для принудительного назначения",
                "Рассмотрите изменение периода назначения",
                "Проверьте возможность объединения с существующими расписаниями"
            ])
            
            raise HTTPException(
                status_code=422,
                detail=f"Обнаружено {len(existing_schedules)} конфликтующих расписаний. {conflict_analysis['рекомендации'][0]}"
            )
        
        # Validate shift assignments
        if not request.shift_assignments:
            raise HTTPException(
                status_code=422,
                detail="Необходимо указать хотя бы одно назначение смены"
            )
        
        # Calculate total hours and validate against employee constraints
        total_hours = 0
        validated_shifts = []
        
        for i, shift in enumerate(request.shift_assignments):
            if "дата" not in shift:
                raise HTTPException(
                    status_code=422,
                    detail=f"Смена {i+1}: обязательное поле 'дата' отсутствует"
                )
            
            shift_hours = shift.get("часы", 8)
            total_hours += shift_hours
            
            validated_shift = {
                "дата": shift["дата"],
                "время_начала": shift.get("время_начала", "09:00"),
                "время_окончания": shift.get("время_окончания", "17:00"),
                "часы": shift_hours,
                "тип_смены": shift.get("тип_смены", "стандартная"),
                "описание": shift.get("описание", ""),
                "назначено": datetime.utcnow().isoformat()
            }
            validated_shifts.append(validated_shift)
        
        # Check against employee's max hours
        period_days = (request.assignment_period_end - request.assignment_period_start).days + 1
        weeks = period_days / 7
        max_weekly_hours = employee.max_hours_per_week or 40
        max_total_hours = max_weekly_hours * weeks
        
        if total_hours > max_total_hours:
            raise HTTPException(
                status_code=422,
                detail=f"Общие часы ({total_hours}) превышают максимум для сотрудника ({max_total_hours:.1f} за {weeks:.1f} недель)"
            )
        
        # Create schedule assignment
        assignment_id = str(uuid.uuid4())
        current_time = datetime.utcnow()
        
        # Determine assignment status
        if request.override_conflicts and existing_schedules:
            assignment_status = "назначено_с_переопределением"
        elif request.assignment_priority == "высокий":
            assignment_status = "назначено_приоритетно"
        else:
            assignment_status = "назначено"
        
        # Calculate cost if template provided
        cost_per_hour = template.cost_per_hour if template else 1000  # Default cost
        total_cost = total_hours * cost_per_hour
        
        assignment_query = text("""
            INSERT INTO work_schedules_core 
            (id, employee_id, template_id, schedule_name, shift_assignments,
             total_hours, assignment_priority, assignment_reason, status,
             effective_date, expiry_date, total_cost, created_at, updated_at)
            VALUES 
            (:id, :employee_id, :template_id, :schedule_name, :shift_assignments,
             :total_hours, :priority, :reason, :status,
             :effective_date, :expiry_date, :total_cost, :created_at, :updated_at)
            RETURNING id
        """)
        
        schedule_name = f"Прямое назначение для {employee.first_name} {employee.last_name}"
        if template:
            schedule_name += f" (шаблон: {template.template_name})"
        
        await db.execute(assignment_query, {
            'id': assignment_id,
            'employee_id': request.employee_id,
            'template_id': request.template_id,
            'schedule_name': schedule_name,
            'shift_assignments': json.dumps(validated_shifts),
            'total_hours': total_hours,
            'priority': request.assignment_priority,
            'reason': request.assignment_reason,
            'status': 'assigned',
            'effective_date': request.assignment_period_start,
            'expiry_date': request.assignment_period_end,
            'total_cost': total_cost,
            'created_at': current_time,
            'updated_at': current_time
        })
        
        # Handle conflict resolution if override requested
        if request.override_conflicts and existing_schedules:
            for existing in existing_schedules:
                if existing.assignment_priority != "высокий":  # Don't override high priority
                    # Mark as superseded
                    supersede_query = text("""
                        UPDATE work_schedules_core 
                        SET status = 'superseded',
                            superseded_by = :new_assignment_id,
                            updated_at = :updated_at
                        WHERE id = :existing_id
                    """)
                    
                    await db.execute(supersede_query, {
                        'new_assignment_id': assignment_id,
                        'existing_id': existing.id,
                        'updated_at': current_time
                    })
        
        # Create notification if requested
        notification_status = "отключено"
        if request.notify_employee:
            notification_query = text("""
                INSERT INTO employee_notifications 
                (id, employee_id, notification_type, title, message, created_at)
                VALUES 
                (:id, :employee_id, :type, :title, :message, :created_at)
            """)
            
            await db.execute(notification_query, {
                'id': str(uuid.uuid4()),
                'employee_id': request.employee_id,
                'type': 'schedule_assignment',
                'title': 'Новое назначение расписания',
                'message': f'Вам назначено новое расписание на период {request.assignment_period_start} - {request.assignment_period_end}. Общие часы: {total_hours}',
                'created_at': current_time
            })
            
            notification_status = "отправлено"
        
        await db.commit()
        
        # Build schedule details
        schedule_details = {
            "assignment_id": assignment_id,
            "сотрудник": {
                "имя": f"{employee.first_name} {employee.last_name}",
                "должность": employee.position,
                "отдел": employee.department_name
            },
            "период": f"{request.assignment_period_start} - {request.assignment_period_end}",
            "общие_часы": total_hours,
            "количество_смен": len(validated_shifts),
            "приоритет": request.assignment_priority,
            "причина": request.assignment_reason,
            "использованный_шаблон": template.template_name if template else "без_шаблона",
            "общая_стоимость": total_cost,
            "смены": validated_shifts
        }
        
        return ScheduleAssignmentResponse(
            assignment_id=assignment_id,
            employee_id=str(request.employee_id),
            schedule_details=schedule_details,
            conflict_analysis=conflict_analysis,
            assignment_status=assignment_status,
            notification_status=notification_status,
            message=f"Расписание назначено сотруднику {employee.first_name} {employee.last_name} на {period_days} дней ({total_hours} часов). Статус: {assignment_status}"
        )
        
    except Exception as e:
        await db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Ошибка назначения расписания: {str(e)}"
        )

@router.get("/schedules/assignments/employee/{employee_id}", tags=["🔥 REAL Schedule Assignments"])
async def get_employee_assignments(
    employee_id: UUID,
    status_filter: Optional[str] = None,
    date_from: Optional[date] = None,
    date_to: Optional[date] = None,
    db: AsyncSession = Depends(get_db)
):
    """Get schedule assignments for specific employee"""
    try:
        conditions = ["ws.employee_id = :employee_id"]
        params = {"employee_id": employee_id}
        
        if status_filter:
            conditions.append("ws.status = :status")
            params["status"] = status_filter
        
        if date_from:
            conditions.append("ws.expiry_date >= :date_from")
            params["date_from"] = date_from
        
        if date_to:
            conditions.append("ws.effective_date <= :date_to")
            params["date_to"] = date_to
        
        query = text(f"""
            SELECT 
                ws.id,
                ws.schedule_name,
                ws.status,
                ws.assignment_priority,
                ws.assignment_reason,
                ws.effective_date,
                ws.expiry_date,
                ws.total_hours,
                ws.total_cost,
                ws.shift_assignments,
                ws.created_at,
                st.template_name,
                e.first_name,
                e.last_name
            FROM work_schedules_core ws
            JOIN employees e ON ws.employee_id = e.id
            LEFT JOIN schedule_templates st ON ws.template_id = st.id
            WHERE {' AND '.join(conditions)}
            ORDER BY ws.effective_date DESC, ws.created_at DESC
        """)
        
        result = await db.execute(query, params)
        assignments = []
        
        for row in result.fetchall():
            shifts = json.loads(row.shift_assignments) if row.shift_assignments else []
            
            assignments.append({
                "assignment_id": str(row.id),
                "название": row.schedule_name,
                "статус": row.status,
                "приоритет": row.assignment_priority,
                "причина": row.assignment_reason,
                "период": f"{row.effective_date} - {row.expiry_date}" if row.expiry_date else f"с {row.effective_date}",
                "часы": row.total_hours,
                "стоимость": row.total_cost,
                "количество_смен": len(shifts),
                "шаблон": row.template_name or "без_шаблона",
                "сотрудник": f"{row.first_name} {row.last_name}",
                "дата_назначения": row.created_at.isoformat()
            })
        
        return {
            "employee_id": str(employee_id),
            "filter_status": status_filter or "все_статусы",
            "filter_period": f"{date_from or 'без_ограничений'} - {date_to or 'без_ограничений'}",
            "assignments": assignments,
            "total_assignments": len(assignments)
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Ошибка получения назначений: {str(e)}"
        )