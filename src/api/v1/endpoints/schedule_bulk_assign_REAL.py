"""
REAL BULK SCHEDULE ASSIGNMENT ENDPOINT
Task 38/50: Bulk Schedule Assignment for Multiple Employees
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

class BulkAssignmentRequest(BaseModel):
    employee_ids: List[UUID]
    template_id: UUID
    assignment_period_start: date
    assignment_period_end: date
    assignment_strategy: str = "равномерное_распределение"  # Russian strategy
    override_conflicts: Optional[bool] = False

class BulkAssignmentResponse(BaseModel):
    bulk_operation_id: str
    successful_assignments: List[Dict[str, Any]]
    failed_assignments: List[Dict[str, Any]]
    operation_summary: Dict[str, Any]
    message: str

@router.post("/schedules/assignments/bulk", response_model=BulkAssignmentResponse, tags=["🔥 REAL Schedule Assignments"])
async def bulk_assign_schedules(
    request: BulkAssignmentRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    REAL BULK SCHEDULE ASSIGNMENT - NO MOCKS!
    
    Assigns schedules to multiple employees simultaneously
    Uses real work_schedules_core with batch processing
    Supports Russian assignment strategies
    """
    try:
        # Validate template
        template_query = text("""
            SELECT id, template_name, shift_structure, cost_per_hour
            FROM schedule_templates 
            WHERE id = :template_id AND is_active = true
        """)
        
        template_result = await db.execute(template_query, {"template_id": request.template_id})
        template = template_result.fetchone()
        
        if not template:
            raise HTTPException(status_code=404, detail=f"Шаблон {request.template_id} не найден")
        
        shift_structure = json.loads(template.shift_structure) if template.shift_structure else {}
        
        # Get employees info
        employee_ids_str = "'" + "','".join(str(eid) for eid in request.employee_ids) + "'"
        employees_query = text(f"""
            SELECT e.id, e.first_name, e.last_name, e.max_hours_per_week, e.department_id
            FROM employees e 
            WHERE e.id IN ({employee_ids_str}) AND e.is_active = true
        """)
        
        employees_result = await db.execute(employees_query)
        employees = {str(emp.id): emp for emp in employees_result.fetchall()}
        
        # Process assignments
        bulk_operation_id = str(uuid.uuid4())
        current_time = datetime.utcnow()
        successful_assignments = []
        failed_assignments = []
        
        for employee_id in request.employee_ids:
            employee_id_str = str(employee_id)
            
            if employee_id_str not in employees:
                failed_assignments.append({
                    "employee_id": employee_id_str,
                    "ошибка": "Сотрудник не найден или неактивен"
                })
                continue
            
            employee = employees[employee_id_str]
            
            try:
                # Check conflicts
                conflict_query = text("""
                    SELECT COUNT(*) as conflicts
                    FROM work_schedules_core 
                    WHERE employee_id = :employee_id
                    AND status IN ('active', 'pending')
                    AND effective_date <= :end_date
                    AND (expiry_date IS NULL OR expiry_date >= :start_date)
                """)
                
                conflict_result = await db.execute(conflict_query, {
                    "employee_id": employee_id,
                    "start_date": request.assignment_period_start,
                    "end_date": request.assignment_period_end
                })
                
                conflicts = conflict_result.scalar()
                
                if conflicts > 0 and not request.override_conflicts:
                    failed_assignments.append({
                        "employee_id": employee_id_str,
                        "имя": f"{employee.first_name} {employee.last_name}",
                        "ошибка": f"Конфликт с {conflicts} существующими расписаниями"
                    })
                    continue
                
                # Generate shifts based on strategy
                shifts = []
                if request.assignment_strategy == "равномерное_распределение":
                    # Create standard 5-day work schedule
                    current_date = request.assignment_period_start
                    while current_date <= request.assignment_period_end:
                        if current_date.weekday() < 5:  # Monday-Friday
                            shifts.append({
                                "дата": current_date.isoformat(),
                                "время_начала": "09:00",
                                "время_окончания": "17:00",
                                "часы": 8,
                                "тип_смены": "стандартная"
                            })
                        current_date += timedelta(days=1)
                
                total_hours = sum(shift["часы"] for shift in shifts)
                
                # Create assignment
                assignment_id = str(uuid.uuid4())
                
                assignment_query = text("""
                    INSERT INTO work_schedules_core 
                    (id, employee_id, template_id, schedule_name, shift_assignments,
                     total_hours, status, effective_date, expiry_date, 
                     bulk_operation_id, created_at, updated_at)
                    VALUES 
                    (:id, :employee_id, :template_id, :schedule_name, :shifts,
                     :total_hours, :status, :effective_date, :expiry_date,
                     :bulk_id, :created_at, :updated_at)
                """)
                
                await db.execute(assignment_query, {
                    'id': assignment_id,
                    'employee_id': employee_id,
                    'template_id': request.template_id,
                    'schedule_name': f"Массовое назначение - {template.template_name}",
                    'shifts': json.dumps(shifts),
                    'total_hours': total_hours,
                    'status': 'assigned',
                    'effective_date': request.assignment_period_start,
                    'expiry_date': request.assignment_period_end,
                    'bulk_id': bulk_operation_id,
                    'created_at': current_time,
                    'updated_at': current_time
                })
                
                successful_assignments.append({
                    "assignment_id": assignment_id,
                    "employee_id": employee_id_str,
                    "имя": f"{employee.first_name} {employee.last_name}",
                    "часы": total_hours,
                    "количество_смен": len(shifts),
                    "конфликты_переопределены": conflicts > 0
                })
                
            except Exception as e:
                failed_assignments.append({
                    "employee_id": employee_id_str,
                    "имя": f"{employee.first_name} {employee.last_name}" if employee_id_str in employees else "Неизвестен",
                    "ошибка": str(e)
                })
        
        # Record bulk operation
        bulk_record_query = text("""
            INSERT INTO bulk_operations 
            (id, operation_type, template_id, target_count, successful_count, 
             failed_count, operation_details, created_at)
            VALUES 
            (:id, :type, :template_id, :target, :successful, :failed, :details, :created_at)
        """)
        
        await db.execute(bulk_record_query, {
            'id': bulk_operation_id,
            'type': 'bulk_schedule_assignment',
            'template_id': request.template_id,
            'target': len(request.employee_ids),
            'successful': len(successful_assignments),
            'failed': len(failed_assignments),
            'details': json.dumps({"strategy": request.assignment_strategy}),
            'created_at': current_time
        })
        
        await db.commit()
        
        operation_summary = {
            "всего_сотрудников": len(request.employee_ids),
            "успешных_назначений": len(successful_assignments),
            "неудачных_назначений": len(failed_assignments),
            "шаблон": template.template_name,
            "стратегия": request.assignment_strategy,
            "период": f"{request.assignment_period_start} - {request.assignment_period_end}",
            "процент_успеха": round(len(successful_assignments) / len(request.employee_ids) * 100, 1)
        }
        
        return BulkAssignmentResponse(
            bulk_operation_id=bulk_operation_id,
            successful_assignments=successful_assignments,
            failed_assignments=failed_assignments,
            operation_summary=operation_summary,
            message=f"Массовое назначение завершено: {len(successful_assignments)} успешно, {len(failed_assignments)} неудачно"
        )
        
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"Ошибка массового назначения: {str(e)}")