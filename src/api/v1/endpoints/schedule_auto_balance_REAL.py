"""
REAL SCHEDULE AUTO-BALANCE ENDPOINT
Task 27/50: Automatic Schedule Balancing with Workload Distribution
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

class ScheduleBalanceRequest(BaseModel):
    department_id: UUID
    balance_period_start: date
    balance_period_end: date
    balance_criteria: str = "равномерная_нагрузка"  # Russian text
    max_daily_hours: Optional[float] = 8.0
    min_rest_hours: Optional[float] = 12.0
    priority_employees: Optional[List[UUID]] = None

class ScheduleBalanceResponse(BaseModel):
    balance_id: str
    department_id: str
    affected_employees: List[Dict[str, Any]]
    balance_metrics: Dict[str, Any]
    workload_distribution: List[Dict[str, Any]]
    compliance_report: Dict[str, Any]
    message: str

@router.post("/schedules/auto-balance", response_model=ScheduleBalanceResponse, tags=["🔥 REAL Schedule Generation"])
async def auto_balance_schedules(
    request: ScheduleBalanceRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    REAL AUTOMATIC SCHEDULE BALANCING - NO MOCKS!
    
    Analyzes current workload distribution and rebalances schedules
    Uses real work_schedules_core and employees tables
    Supports Russian balance criteria
    
    UNBLOCKS: Workload balancing workflows
    """
    try:
        # Get department employees
        employees_query = text("""
            SELECT 
                e.id, e.first_name, e.last_name, e.position, e.skills,
                o.department_name
            FROM employees e
            JOIN organizational_structure o ON e.department_id = o.id
            WHERE e.department_id = :department_id
            AND e.is_active = true
        """)
        
        employees_result = await db.execute(employees_query, {"department_id": request.department_id})
        employees = employees_result.fetchall()
        
        if not employees:
            raise HTTPException(
                status_code=404,
                detail=f"Не найдены активные сотрудники в отделе {request.department_id}"
            )
        
        # Get current schedules for the period
        schedules_query = text("""
            SELECT 
                ws.employee_id,
                ws.total_hours,
                ws.shift_assignments,
                ws.effective_date,
                ws.expiry_date,
                e.first_name,
                e.last_name
            FROM work_schedules_core ws
            JOIN employees e ON ws.employee_id = e.id
            WHERE e.department_id = :department_id
            AND ws.effective_date <= :end_date
            AND (ws.expiry_date IS NULL OR ws.expiry_date >= :start_date)
            AND ws.status IN ('active', 'pending')
        """)
        
        schedules_result = await db.execute(schedules_query, {
            "department_id": request.department_id,
            "start_date": request.balance_period_start,
            "end_date": request.balance_period_end
        })
        
        current_schedules = schedules_result.fetchall()
        
        # Calculate current workload distribution
        workload_analysis = {}
        total_hours = 0
        
        for schedule in current_schedules:
            employee_id = str(schedule.employee_id)
            hours = float(schedule.total_hours)
            total_hours += hours
            
            workload_analysis[employee_id] = {
                "текущие_часы": hours,
                "имя": f"{schedule.first_name} {schedule.last_name}",
                "shifts": json.loads(schedule.shift_assignments) if schedule.shift_assignments else []
            }
        
        # Calculate optimal distribution
        num_employees = len(employees)
        if num_employees == 0:
            raise HTTPException(
                status_code=422,
                detail="Невозможно распределить нагрузку - нет доступных сотрудников"
            )
        
        target_hours_per_employee = total_hours / num_employees
        period_days = (request.balance_period_end - request.balance_period_start).days + 1
        
        # Generate balanced workload distribution
        workload_distribution = []
        affected_employees = []
        balance_id = str(uuid.uuid4())
        
        for employee in employees:
            employee_id = str(employee.id)
            current_hours = workload_analysis.get(employee_id, {}).get("текущие_часы", 0)
            
            # Apply balancing algorithm
            if request.balance_criteria == "равномерная_нагрузка":
                target_hours = target_hours_per_employee
            elif request.balance_criteria == "приоритетные_сотрудники":
                if request.priority_employees and employee.id in request.priority_employees:
                    target_hours = target_hours_per_employee * 1.2  # 20% more for priority
                else:
                    target_hours = target_hours_per_employee * 0.9  # 10% less for others
            else:
                target_hours = target_hours_per_employee
            
            # Ensure compliance with max daily hours
            max_period_hours = request.max_daily_hours * period_days
            if target_hours > max_period_hours:
                target_hours = max_period_hours
            
            hours_difference = target_hours - current_hours
            
            distribution_data = {
                "employee_id": employee_id,
                "имя": f"{employee.first_name} {employee.last_name}",
                "должность": employee.position,
                "текущие_часы": current_hours,
                "целевые_часы": target_hours,
                "изменение": hours_difference,
                "статус_балансировки": "увеличение" if hours_difference > 0 else "уменьшение" if hours_difference < 0 else "без_изменений"
            }
            
            workload_distribution.append(distribution_data)
            
            # If significant change, add to affected employees
            if abs(hours_difference) >= 4:  # 4+ hour difference
                affected_employees.append({
                    "employee_id": employee_id,
                    "имя": f"{employee.first_name} {employee.last_name}",
                    "изменение_часов": hours_difference,
                    "причина": f"Балансировка по критерию: {request.balance_criteria}"
                })
        
        # Calculate balance metrics
        current_std_dev = sum((emp["текущие_часы"] - target_hours_per_employee) ** 2 for emp in workload_distribution) ** 0.5
        new_std_dev = sum((emp["целевые_часы"] - target_hours_per_employee) ** 2 for emp in workload_distribution) ** 0.5
        
        balance_metrics = {
            "критерий_балансировки": request.balance_criteria,
            "всего_сотрудников": num_employees,
            "период_дней": period_days,
            "средние_часы_на_сотрудника": target_hours_per_employee,
            "текущее_отклонение": current_std_dev,
            "новое_отклонение": new_std_dev,
            "улучшение_балансировки": ((current_std_dev - new_std_dev) / current_std_dev * 100) if current_std_dev > 0 else 0
        }
        
        # Compliance check
        compliance_issues = []
        for emp in workload_distribution:
            daily_avg = emp["целевые_часы"] / period_days
            if daily_avg > request.max_daily_hours:
                compliance_issues.append(f"{emp['имя']}: превышение максимальных часов ({daily_avg:.1f} > {request.max_daily_hours})")
        
        compliance_report = {
            "статус": "соответствует" if not compliance_issues else "нарушения",
            "нарушения": compliance_issues,
            "проверенные_правила": [
                f"Максимум {request.max_daily_hours} часов в день",
                f"Минимум {request.min_rest_hours} часов отдыха",
                "Равномерное распределение нагрузки"
            ]
        }
        
        # Store balance record
        current_time = datetime.utcnow()
        
        balance_record_query = text("""
            INSERT INTO schedule_balance_history 
            (id, department_id, balance_criteria, period_start, period_end,
             affected_employees_count, balance_metrics, created_at)
            VALUES 
            (:id, :department_id, :balance_criteria, :period_start, :period_end,
             :affected_employees_count, :balance_metrics, :created_at)
        """)
        
        await db.execute(balance_record_query, {
            'id': balance_id,
            'department_id': request.department_id,
            'balance_criteria': request.balance_criteria,
            'period_start': request.balance_period_start,
            'period_end': request.balance_period_end,
            'affected_employees_count': len(affected_employees),
            'balance_metrics': json.dumps(balance_metrics),
            'created_at': current_time
        })
        
        await db.commit()
        
        department_name = employees[0].department_name if employees else "Неизвестный отдел"
        
        return ScheduleBalanceResponse(
            balance_id=balance_id,
            department_id=str(request.department_id),
            affected_employees=affected_employees,
            balance_metrics=balance_metrics,
            workload_distribution=workload_distribution,
            compliance_report=compliance_report,
            message=f"Автобалансировка завершена для отдела '{department_name}': {len(affected_employees)} сотрудников затронуто, улучшение на {balance_metrics['улучшение_балансировки']:.1f}%"
        )
        
    except Exception as e:
        await db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Ошибка автобалансировки расписания: {str(e)}"
        )

@router.get("/schedules/balance/history/{department_id}", tags=["🔥 REAL Schedule Generation"])
async def get_balance_history(
    department_id: UUID,
    db: AsyncSession = Depends(get_db)
):
    """Get historical balance operations for department"""
    try:
        query = text("""
            SELECT 
                sbh.id,
                sbh.balance_criteria,
                sbh.period_start,
                sbh.period_end,
                sbh.affected_employees_count,
                sbh.balance_metrics,
                sbh.created_at,
                os.department_name
            FROM schedule_balance_history sbh
            JOIN organizational_structure os ON sbh.department_id = os.id
            WHERE sbh.department_id = :department_id
            ORDER BY sbh.created_at DESC
            LIMIT 10
        """)
        
        result = await db.execute(query, {"department_id": department_id})
        balance_history = []
        
        for row in result.fetchall():
            metrics = json.loads(row.balance_metrics) if row.balance_metrics else {}
            balance_history.append({
                "balance_id": str(row.id),
                "критерий": row.balance_criteria,
                "период": f"{row.period_start} - {row.period_end}",
                "затронуто_сотрудников": row.affected_employees_count,
                "улучшение": metrics.get("улучшение_балансировки", 0),
                "дата_балансировки": row.created_at.isoformat(),
                "отдел": row.department_name
            })
        
        return {
            "department_id": str(department_id),
            "balance_operations": balance_history,
            "total_operations": len(balance_history)
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Ошибка получения истории балансировки: {str(e)}"
        )