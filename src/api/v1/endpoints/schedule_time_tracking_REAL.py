"""
REAL SCHEDULE TIME TRACKING ENDPOINT
Task 45/50: Real-time Schedule Adherence and Time Tracking
"""

from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from pydantic import BaseModel
from datetime import datetime, date, time
from typing import Optional, List, Dict, Any
from uuid import UUID
import uuid
import json

from ...core.database import get_db

router = APIRouter()

class TimeTrackingRequest(BaseModel):
    schedule_id: UUID
    employee_id: UUID
    tracking_date: date
    actual_start_time: Optional[time] = None
    actual_end_time: Optional[time] = None
    break_times: Optional[List[Dict[str, Any]]] = None
    tracking_status: str = "в_процессе"  # в_процессе, завершено, отклонение

class TimeTrackingResponse(BaseModel):
    tracking_id: str
    adherence_analysis: Dict[str, Any]
    schedule_compliance: Dict[str, Any]
    time_variances: Dict[str, Any]
    recommendations: List[str]
    message: str

@router.post("/schedules/time-tracking", response_model=TimeTrackingResponse, tags=["🔥 REAL Schedule Analytics"])
async def track_schedule_adherence(
    request: TimeTrackingRequest,
    db: AsyncSession = Depends(get_db)
):
    """REAL TIME TRACKING - NO MOCKS! Tracks actual vs scheduled time adherence"""
    try:
        # Get scheduled shift details
        schedule_query = text("""
            SELECT 
                ws.id, ws.shift_assignments, ws.schedule_name,
                e.first_name, e.last_name
            FROM work_schedules_core ws
            JOIN employees e ON ws.employee_id = e.id
            WHERE ws.id = :schedule_id AND ws.employee_id = :employee_id
        """)
        
        schedule_result = await db.execute(schedule_query, {
            "schedule_id": request.schedule_id,
            "employee_id": request.employee_id
        })
        
        schedule = schedule_result.fetchone()
        if not schedule:
            raise HTTPException(
                status_code=404,
                detail=f"Расписание {request.schedule_id} для сотрудника {request.employee_id} не найдено"
            )
        
        # Find scheduled shift for the tracking date
        shifts = json.loads(schedule.shift_assignments) if schedule.shift_assignments else []
        target_shift = None
        
        for shift in shifts:
            if shift.get("дата") == request.tracking_date.isoformat():
                target_shift = shift
                break
        
        if not target_shift:
            raise HTTPException(
                status_code=404,
                detail=f"Смена на дату {request.tracking_date} не найдена в расписании"
            )
        
        # Parse scheduled times
        scheduled_start = datetime.strptime(target_shift.get("время_начала", "09:00"), "%H:%M").time()
        scheduled_end = datetime.strptime(target_shift.get("время_окончания", "17:00"), "%H:%M").time()
        scheduled_hours = target_shift.get("часы", 8)
        
        # Calculate adherence if actual times provided
        adherence_analysis = {
            "запланированное_время": {
                "начало": scheduled_start.strftime("%H:%M"),
                "окончание": scheduled_end.strftime("%H:%M"),
                "часы": scheduled_hours
            },
            "фактическое_время": {
                "начало": request.actual_start_time.strftime("%H:%M") if request.actual_start_time else "не_зафиксировано",
                "окончание": request.actual_end_time.strftime("%H:%M") if request.actual_end_time else "не_зафиксировано",
                "статус": request.tracking_status
            }
        }
        
        # Calculate variances
        time_variances = {
            "отклонение_начала_минуты": 0,
            "отклонение_окончания_минуты": 0,
            "отклонение_общих_часов": 0,
            "соблюдение_расписания": "точно"
        }
        
        if request.actual_start_time:
            start_diff = (datetime.combine(date.today(), request.actual_start_time) - 
                         datetime.combine(date.today(), scheduled_start)).total_seconds() / 60
            time_variances["отклонение_начала_минуты"] = int(start_diff)
        
        if request.actual_end_time:
            end_diff = (datetime.combine(date.today(), request.actual_end_time) - 
                       datetime.combine(date.today(), scheduled_end)).total_seconds() / 60
            time_variances["отклонение_окончания_минуты"] = int(end_diff)
        
        if request.actual_start_time and request.actual_end_time:
            actual_duration = (datetime.combine(date.today(), request.actual_end_time) - 
                             datetime.combine(date.today(), request.actual_start_time)).total_seconds() / 3600
            time_variances["отклонение_общих_часов"] = round(actual_duration - scheduled_hours, 2)
            
            # Determine adherence level
            total_variance_minutes = abs(time_variances["отклонение_начала_минуты"]) + abs(time_variances["отклонение_окончания_минуты"])
            
            if total_variance_minutes <= 5:
                time_variances["соблюдение_расписания"] = "отличное"
            elif total_variance_minutes <= 15:
                time_variances["соблюдение_расписания"] = "хорошее"
            elif total_variance_minutes <= 30:
                time_variances["соблюдение_расписания"] = "удовлетворительное"
            else:
                time_variances["соблюдение_расписания"] = "неудовлетворительное"
        
        # Schedule compliance analysis
        schedule_compliance = {
            "точность_прихода": "в_норме",
            "точность_ухода": "в_норме",
            "соблюдение_перерывов": "не_отслеживается",
            "общая_оценка": "соответствует"
        }
        
        if abs(time_variances["отклонение_начала_минуты"]) > 15:
            schedule_compliance["точность_прихода"] = "нарушение"
        
        if abs(time_variances["отклонение_окончания_минуты"]) > 15:
            schedule_compliance["точность_ухода"] = "нарушение"
        
        if request.break_times:
            total_break_minutes = sum(
                (datetime.strptime(br.get("конец", "00:00"), "%H:%M") - 
                 datetime.strptime(br.get("начало", "00:00"), "%H:%M")).total_seconds() / 60
                for br in request.break_times
            )
            
            if total_break_minutes > 90:  # More than 1.5 hours of breaks
                schedule_compliance["соблюдение_перерывов"] = "превышение"
            elif total_break_minutes < 30:  # Less than 30 minutes
                schedule_compliance["соблюдение_перерывов"] = "недостаточно"
            else:
                schedule_compliance["соблюдение_перерывов"] = "в_норме"
        
        # Overall compliance
        violations = [v for v in schedule_compliance.values() if v in ["нарушение", "превышение", "недостаточно"]]
        if len(violations) > 1:
            schedule_compliance["общая_оценка"] = "серьезные_нарушения"
        elif len(violations) == 1:
            schedule_compliance["общая_оценка"] = "незначительные_нарушения"
        
        # Generate recommendations
        recommendations = []
        
        if time_variances["отклонение_начала_минуты"] > 15:
            recommendations.append("Рекомендуется приходить на работу вовремя")
        elif time_variances["отклонение_начала_минуты"] < -15:
            recommendations.append("Раннее прибытие - хорошо, но следите за переработкой")
        
        if abs(time_variances["отклонение_общих_часов"]) > 1:
            recommendations.append(f"Отклонение рабочих часов на {time_variances['отклонение_общих_часов']} ч требует внимания")
        
        if schedule_compliance["соблюдение_перерывов"] == "превышение":
            recommendations.append("Сократите время перерывов до установленных норм")
        
        if not recommendations:
            recommendations.append("Отличное соблюдение расписания - продолжайте в том же духе")
        
        # Store tracking record
        tracking_id = str(uuid.uuid4())
        current_time = datetime.utcnow()
        
        tracking_record_query = text("""
            INSERT INTO time_tracking 
            (id, schedule_id, employee_id, tracking_date, 
             scheduled_start, scheduled_end, actual_start, actual_end,
             break_times, time_variances, compliance_status, created_at)
            VALUES 
            (:id, :schedule_id, :employee_id, :tracking_date,
             :scheduled_start, :scheduled_end, :actual_start, :actual_end,
             :break_times, :variances, :compliance, :created_at)
        """)
        
        await db.execute(tracking_record_query, {
            'id': tracking_id,
            'schedule_id': request.schedule_id,
            'employee_id': request.employee_id,
            'tracking_date': request.tracking_date,
            'scheduled_start': scheduled_start,
            'scheduled_end': scheduled_end,
            'actual_start': request.actual_start_time,
            'actual_end': request.actual_end_time,
            'break_times': json.dumps(request.break_times) if request.break_times else None,
            'variances': json.dumps(time_variances),
            'compliance': schedule_compliance["общая_оценка"],
            'created_at': current_time
        })
        
        await db.commit()
        
        return TimeTrackingResponse(
            tracking_id=tracking_id,
            adherence_analysis=adherence_analysis,
            schedule_compliance=schedule_compliance,
            time_variances=time_variances,
            recommendations=recommendations,
            message=f"Отслеживание времени зафиксировано для {schedule.first_name} {schedule.last_name} на {request.tracking_date}. Соблюдение: {time_variances['соблюдение_расписания']}"
        )
        
    except Exception as e:
        await db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Ошибка отслеживания времени: {str(e)}"
        )

@router.get("/schedules/time-tracking/employee/{employee_id}", tags=["🔥 REAL Schedule Analytics"])
async def get_employee_time_tracking(
    employee_id: UUID,
    days_back: Optional[int] = 7,
    db: AsyncSession = Depends(get_db)
):
    """Get time tracking history for employee"""
    try:
        end_date = date.today()
        start_date = end_date - timedelta(days=days_back)
        
        tracking_query = text("""
            SELECT 
                tt.tracking_date, tt.scheduled_start, tt.scheduled_end,
                tt.actual_start, tt.actual_end, tt.time_variances,
                tt.compliance_status, ws.schedule_name
            FROM time_tracking tt
            JOIN work_schedules_core ws ON tt.schedule_id = ws.id
            WHERE tt.employee_id = :employee_id
            AND tt.tracking_date >= :start_date
            AND tt.tracking_date <= :end_date
            ORDER BY tt.tracking_date DESC
        """)
        
        tracking_result = await db.execute(tracking_query, {
            "employee_id": employee_id,
            "start_date": start_date,
            "end_date": end_date
        })
        
        tracking_records = []
        for row in tracking_result.fetchall():
            variances = json.loads(row.time_variances) if row.time_variances else {}
            tracking_records.append({
                "дата": row.tracking_date.isoformat(),
                "расписание": row.schedule_name,
                "запланированное_время": f"{row.scheduled_start} - {row.scheduled_end}",
                "фактическое_время": f"{row.actual_start or 'не_зафиксировано'} - {row.actual_end or 'не_зафиксировано'}",
                "отклонения": variances,
                "статус_соблюдения": row.compliance_status
            })
        
        return {
            "employee_id": str(employee_id),
            "analysis_period": f"{start_date} - {end_date}",
            "tracking_records": tracking_records,
            "total_tracked_days": len(tracking_records)
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Ошибка получения данных отслеживания: {str(e)}"
        )

from datetime import timedelta