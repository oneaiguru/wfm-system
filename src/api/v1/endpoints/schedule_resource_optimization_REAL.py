"""
REAL SCHEDULE RESOURCE OPTIMIZATION ENDPOINT
Task 48/50: Resource Optimization and Capacity Planning
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

class ResourceOptimizationRequest(BaseModel):
    optimization_scope: str = "отдел"
    scope_id: UUID
    optimization_period_start: date
    optimization_period_end: date
    optimization_goals: List[str] = ["минимизация_затрат", "максимизация_покрытия", "балансировка_нагрузки"]
    constraints: Optional[Dict[str, Any]] = None

class ResourceOptimizationResponse(BaseModel):
    optimization_id: str
    current_state: Dict[str, Any]
    optimized_allocation: Dict[str, Any]
    improvement_metrics: Dict[str, Any]
    implementation_plan: List[Dict[str, Any]]
    message: str

@router.post("/schedules/optimization/resources", response_model=ResourceOptimizationResponse, tags=["🔥 REAL Schedule Analytics"])
async def optimize_resource_allocation(
    request: ResourceOptimizationRequest,
    db: AsyncSession = Depends(get_db)
):
    """REAL RESOURCE OPTIMIZATION - NO MOCKS! Optimizes resource allocation"""
    try:
        # Get current resource allocation
        current_query = text("""
            SELECT 
                ws.id, ws.employee_id, ws.total_hours, ws.shift_assignments,
                ws.optimization_score, ws.status,
                e.first_name, e.last_name, e.position, e.skills,
                e.max_hours_per_week, e.hourly_rate,
                st.cost_per_hour, st.template_name,
                os.department_name
            FROM work_schedules_core ws
            JOIN employees e ON ws.employee_id = e.id
            JOIN organizational_structure os ON e.department_id = os.id
            LEFT JOIN schedule_templates st ON ws.template_id = st.id
            WHERE e.department_id = :scope_id
            AND ws.effective_date <= :end_date
            AND (ws.expiry_date IS NULL OR ws.expiry_date >= :start_date)
            AND ws.status IN ('active', 'pending', 'assigned')
        """)
        
        current_result = await db.execute(current_query, {
            "scope_id": request.scope_id,
            "start_date": request.optimization_period_start,
            "end_date": request.optimization_period_end
        })
        
        current_schedules = current_result.fetchall()
        
        if not current_schedules:
            raise HTTPException(
                status_code=404,
                detail="Нет текущих расписаний для оптимизации"
            )
        
        # Analyze current state
        total_current_hours = sum(s.total_hours or 0 for s in current_schedules)
        total_capacity_hours = sum(s.max_hours_per_week or 40 for s in current_schedules)
        avg_utilization = (total_current_hours / total_capacity_hours * 100) if total_capacity_hours > 0 else 0
        
        current_costs = []
        for schedule in current_schedules:
            cost_per_hour = schedule.cost_per_hour or schedule.hourly_rate or 1000
            schedule_cost = (schedule.total_hours or 0) * cost_per_hour
            current_costs.append(schedule_cost)
        
        total_current_cost = sum(current_costs)
        avg_optimization_score = sum(s.optimization_score or 0 for s in current_schedules) / len(current_schedules)
        
        current_state = {
            "всего_расписаний": len(current_schedules),
            "общие_часы": total_current_hours,
            "общая_мощность": total_capacity_hours,
            "утилизация_%": round(avg_utilization, 2),
            "общие_затраты": round(total_current_cost, 2),
            "средний_балл_оптимизации": round(avg_optimization_score, 2),
            "анализируемый_период": f"{request.optimization_period_start} - {request.optimization_period_end}"
        }
        
        # Optimization algorithms
        optimized_allocation = {"оптимизированные_ресурсы": []}
        
        # Group employees by skills for optimal allocation
        skill_groups = {}
        for schedule in current_schedules:
            skills = schedule.skills or "общие"
            if skills not in skill_groups:
                skill_groups[skills] = []
            skill_groups[skills].append(schedule)
        
        # Apply optimization goals
        optimization_results = {
            "минимизация_затрат": {},
            "максимизация_покрытия": {},
            "балансировка_нагрузки": {}
        }
        
        # Cost minimization optimization
        if "минимизация_затрат" in request.optimization_goals:
            # Sort by cost efficiency (skills/cost ratio)
            cost_efficient_allocation = []
            
            for skill_group, employees in skill_groups.items():
                # Sort by cost per hour (ascending for cost efficiency)
                sorted_employees = sorted(employees, 
                    key=lambda e: (e.cost_per_hour or e.hourly_rate or 1000))
                
                # Redistribute hours to most cost-efficient employees first
                total_group_hours = sum(emp.total_hours or 0 for emp in employees)
                
                optimized_hours = []
                remaining_hours = total_group_hours
                
                for emp in sorted_employees:
                    max_hours = emp.max_hours_per_week or 40
                    allocated_hours = min(remaining_hours, max_hours)
                    remaining_hours -= allocated_hours
                    
                    if allocated_hours > 0:
                        cost_per_hour = emp.cost_per_hour or emp.hourly_rate or 1000
                        optimized_hours.append({
                            "employee_id": str(emp.employee_id),
                            "имя": f"{emp.first_name} {emp.last_name}",
                            "текущие_часы": emp.total_hours or 0,
                            "оптимизированные_часы": allocated_hours,
                            "стоимость_час": cost_per_hour,
                            "экономия": (emp.total_hours or 0 - allocated_hours) * cost_per_hour,
                            "группа_навыков": skill_group
                        })
                
                cost_efficient_allocation.extend(optimized_hours)
            
            # Calculate cost savings
            new_total_cost = sum(emp["оптимизированные_часы"] * emp["стоимость_час"] 
                               for emp in cost_efficient_allocation)
            cost_savings = total_current_cost - new_total_cost
            
            optimization_results["минимизация_затрат"] = {
                "новые_затраты": round(new_total_cost, 2),
                "экономия": round(cost_savings, 2),
                "процент_экономии": round((cost_savings / total_current_cost * 100) if total_current_cost > 0 else 0, 2),
                "перераспределенные_сотрудники": len(cost_efficient_allocation)
            }
        
        # Coverage maximization
        if "максимизация_покрытия" in request.optimization_goals:
            # Identify coverage gaps and optimize allocation
            period_days = (request.optimization_period_end - request.optimization_period_start).days + 1
            
            # Analyze current coverage by parsing shift assignments
            daily_coverage = {}
            for schedule in current_schedules:
                shifts = json.loads(schedule.shift_assignments) if schedule.shift_assignments else []
                for shift in shifts:
                    shift_date = shift.get("дата")
                    if shift_date:
                        if shift_date not in daily_coverage:
                            daily_coverage[shift_date] = 0
                        daily_coverage[shift_date] += 1
            
            # Find days with low coverage
            min_required_coverage = len(current_schedules) // 3  # At least 1/3 of staff
            coverage_gaps = [date for date, count in daily_coverage.items() 
                           if count < min_required_coverage]
            
            optimization_results["максимизация_покрытия"] = {
                "текущее_среднее_покрытие": round(sum(daily_coverage.values()) / len(daily_coverage), 1) if daily_coverage else 0,
                "дней_с_недостаточным_покрытием": len(coverage_gaps),
                "минимальное_требуемое_покрытие": min_required_coverage,
                "рекомендация": "Перераспределить смены для улучшения покрытия" if coverage_gaps else "Покрытие адекватное"
            }
        
        # Load balancing
        if "балансировка_нагрузки" in request.optimization_goals:
            # Calculate standard deviation of hours
            hours_distribution = [s.total_hours or 0 for s in current_schedules]
            mean_hours = sum(hours_distribution) / len(hours_distribution)
            variance = sum((h - mean_hours) ** 2 for h in hours_distribution) / len(hours_distribution)
            std_deviation = variance ** 0.5
            
            # Propose balanced allocation
            target_hours_per_employee = total_current_hours / len(current_schedules)
            balanced_allocation = []
            
            for schedule in current_schedules:
                current_hours = schedule.total_hours or 0
                max_hours = schedule.max_hours_per_week or 40
                
                # Balance towards target, respecting constraints
                balanced_hours = min(target_hours_per_employee, max_hours)
                hours_change = balanced_hours - current_hours
                
                balanced_allocation.append({
                    "employee_id": str(schedule.employee_id),
                    "имя": f"{schedule.first_name} {schedule.last_name}",
                    "текущие_часы": current_hours,
                    "сбалансированные_часы": balanced_hours,
                    "изменение": hours_change,
                    "отклонение_от_среднего": abs(current_hours - mean_hours)
                })
            
            # Calculate new standard deviation
            new_hours = [emp["сбалансированные_часы"] for emp in balanced_allocation]
            new_std = (sum((h - target_hours_per_employee) ** 2 for h in new_hours) / len(new_hours)) ** 0.5
            
            optimization_results["балансировка_нагрузки"] = {
                "текущее_стандартное_отклонение": round(std_deviation, 2),
                "новое_стандартное_отклонение": round(new_std, 2),
                "улучшение_балансировки": round(((std_deviation - new_std) / std_deviation * 100) if std_deviation > 0 else 0, 2),
                "целевые_часы_на_сотрудника": round(target_hours_per_employee, 1),
                "сотрудники_требующие_корректировки": len([emp for emp in balanced_allocation if abs(emp["изменение"]) > 2])
            }
        
        # Compile optimized allocation
        optimized_allocation = {
            "оптимизированные_ресурсы": balanced_allocation if "балансировка_нагрузки" in request.optimization_goals else cost_efficient_allocation if "минимизация_затрат" in request.optimization_goals else [],
            "цели_оптимизации": request.optimization_goals,
            "результаты_по_целям": optimization_results
        }
        
        # Calculate improvement metrics
        potential_cost_savings = optimization_results.get("минимизация_затрат", {}).get("экономия", 0)
        coverage_improvement = len(coverage_gaps) if "максимизация_покрытия" in optimization_results else 0
        balance_improvement = optimization_results.get("балансировка_нагрузки", {}).get("улучшение_балансировки", 0)
        
        improvement_metrics = {
            "потенциальная_экономия": round(potential_cost_savings, 2),
            "улучшение_покрытия": f"Устранение {coverage_improvement} пробелов" if coverage_improvement > 0 else "Покрытие оптимально",
            "улучшение_балансировки": f"{balance_improvement:.1f}%" if balance_improvement > 0 else "Балансировка оптимальна",
            "общий_балл_улучшения": round((
                min(100, potential_cost_savings / total_current_cost * 100 * 10) + 
                min(100, balance_improvement) + 
                (50 if coverage_improvement == 0 else max(0, 50 - coverage_improvement * 10))
            ) / 3, 1)
        }
        
        # Generate implementation plan
        implementation_plan = []
        
        if potential_cost_savings > total_current_cost * 0.05:  # >5% savings
            implementation_plan.append({
                "приоритет": 1,
                "действие": "Перераспределение для экономии затрат",
                "описание": f"Реализация оптимизации затрат для экономии {potential_cost_savings:.0f} руб.",
                "срок": "1-2 недели",
                "ответственный": "менеджер_планирования"
            })
        
        if coverage_improvement > 0:
            implementation_plan.append({
                "приоритет": 2,
                "действие": "Улучшение покрытия",
                "описание": f"Устранение {coverage_improvement} пробелов в покрытии",
                "срок": "немедленно",
                "ответственный": "супервайзер_смен"
            })
        
        if balance_improvement > 10:
            implementation_plan.append({
                "приоритет": 3,
                "действие": "Балансировка нагрузки",
                "описание": f"Улучшение распределения нагрузки на {balance_improvement:.1f}%",
                "срок": "1 неделя",
                "ответственный": "hr_менеджер"
            })
        
        if not implementation_plan:
            implementation_plan.append({
                "приоритет": 1,
                "действие": "Мониторинг текущего состояния",
                "описание": "Ресурсы оптимально распределены - продолжить мониторинг",
                "срок": "постоянно",
                "ответственный": "аналитик"
            })
        
        # Store optimization record
        optimization_id = str(uuid.uuid4())
        current_time = datetime.utcnow()
        
        optimization_record_query = text("""
            INSERT INTO resource_optimizations 
            (id, optimization_scope, scope_id, period_start, period_end,
             current_state, optimized_allocation, improvement_metrics, created_at)
            VALUES 
            (:id, :scope, :scope_id, :start_date, :end_date,
             :current, :optimized, :improvements, :created_at)
        """)
        
        await db.execute(optimization_record_query, {
            'id': optimization_id,
            'scope': request.optimization_scope,
            'scope_id': request.scope_id,
            'start_date': request.optimization_period_start,
            'end_date': request.optimization_period_end,
            'current': json.dumps(current_state),
            'optimized': json.dumps(optimized_allocation),
            'improvements': json.dumps(improvement_metrics),
            'created_at': current_time
        })
        
        await db.commit()
        
        return ResourceOptimizationResponse(
            optimization_id=optimization_id,
            current_state=current_state,
            optimized_allocation=optimized_allocation,
            improvement_metrics=improvement_metrics,
            implementation_plan=implementation_plan,
            message=f"Оптимизация ресурсов завершена: общий балл улучшения {improvement_metrics['общий_балл_улучшения']:.1f}%, потенциальная экономия {potential_cost_savings:.0f} руб."
        )
        
    except Exception as e:
        await db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Ошибка оптимизации ресурсов: {str(e)}"
        )