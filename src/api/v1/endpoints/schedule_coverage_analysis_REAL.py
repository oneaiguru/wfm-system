"""
REAL SCHEDULE COVERAGE ANALYSIS ENDPOINT
Task 41/50: Schedule Coverage and Gap Analysis
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

class CoverageAnalysisRequest(BaseModel):
    department_id: UUID
    analysis_period_start: date
    analysis_period_end: date
    coverage_requirements: Dict[str, Any]
    analysis_granularity: str = "день"  # день, час, смена

class CoverageAnalysisResponse(BaseModel):
    analysis_id: str
    coverage_data: List[Dict[str, Any]]
    gap_analysis: Dict[str, Any]
    recommendations: List[str]
    message: str

@router.post("/schedules/analysis/coverage", response_model=CoverageAnalysisResponse, tags=["🔥 REAL Schedule Reporting"])
async def analyze_schedule_coverage(
    request: CoverageAnalysisRequest,
    db: AsyncSession = Depends(get_db)
):
    """REAL COVERAGE ANALYSIS - NO MOCKS! Analyzes schedule coverage and identifies gaps"""
    try:
        # Get department info and requirements
        dept_query = text("""
            SELECT id, department_name, required_staff_count
            FROM organizational_structure 
            WHERE id = :dept_id
        """)
        
        dept_result = await db.execute(dept_query, {"dept_id": request.department_id})
        department = dept_result.fetchone()
        
        if not department:
            raise HTTPException(status_code=404, detail=f"Отдел {request.department_id} не найден")
        
        # Get schedules for the period
        schedules_query = text("""
            SELECT 
                ws.id, ws.shift_assignments, ws.total_hours,
                e.id as employee_id, e.first_name, e.last_name, e.skills
            FROM work_schedules_core ws
            JOIN employees e ON ws.employee_id = e.id
            WHERE e.department_id = :dept_id
            AND ws.status IN ('active', 'pending', 'assigned')
            AND ws.effective_date <= :end_date
            AND (ws.expiry_date IS NULL OR ws.expiry_date >= :start_date)
        """)
        
        schedules_result = await db.execute(schedules_query, {
            "dept_id": request.department_id,
            "start_date": request.analysis_period_start,
            "end_date": request.analysis_period_end
        })
        
        schedules = schedules_result.fetchall()
        
        # Process coverage data
        coverage_data = []
        current_date = request.analysis_period_start
        
        while current_date <= request.analysis_period_end:
            day_coverage = {
                "дата": current_date.isoformat(),
                "день_недели": ["пн", "вт", "ср", "чт", "пт", "сб", "вс"][current_date.weekday()],
                "покрытие_по_часам": {},
                "назначенные_сотрудники": [],
                "общее_покрытие": 0
            }
            
            # Analyze hourly coverage
            for hour in range(24):
                hour_str = f"{hour:02d}:00"
                assigned_staff = []
                
                for schedule in schedules:
                    shifts = json.loads(schedule.shift_assignments) if schedule.shift_assignments else []
                    
                    for shift in shifts:
                        if shift.get("дата") == current_date.isoformat():
                            start_time = shift.get("время_начала", "09:00")
                            end_time = shift.get("время_окончания", "17:00")
                            
                            start_hour = int(start_time.split(":")[0])
                            end_hour = int(end_time.split(":")[0])
                            
                            if start_hour <= hour < end_hour:
                                assigned_staff.append({
                                    "employee_id": str(schedule.employee_id),
                                    "имя": f"{schedule.first_name} {schedule.last_name}",
                                    "навыки": schedule.skills or ""
                                })
                
                day_coverage["покрытие_по_часам"][hour_str] = {
                    "количество_сотрудников": len(assigned_staff),
                    "сотрудники": assigned_staff
                }
            
            # Calculate daily metrics
            daily_staff = set()
            for hour_data in day_coverage["покрытие_по_часам"].values():
                for staff in hour_data["сотрудники"]:
                    daily_staff.add(staff["employee_id"])
            
            day_coverage["назначенные_сотрудники"] = list(daily_staff)
            day_coverage["общее_покрытие"] = len(daily_staff)
            
            coverage_data.append(day_coverage)
            current_date += timedelta(days=1)
        
        # Gap analysis
        required_staff = request.coverage_requirements.get("минимум_сотрудников", 5)
        required_hours = request.coverage_requirements.get("рабочие_часы", "09:00-17:00")
        start_hour, end_hour = [int(x.split(":")[0]) for x in required_hours.split("-")]
        
        gaps = []
        understaffed_days = 0
        total_gap_hours = 0
        
        for day_data in coverage_data:
            day_gaps = []
            
            for hour in range(start_hour, end_hour):
                hour_str = f"{hour:02d}:00"
                current_staff = day_data["покрытие_по_часам"].get(hour_str, {}).get("количество_сотрудников", 0)
                
                if current_staff < required_staff:
                    gap = required_staff - current_staff
                    day_gaps.append({
                        "час": hour_str,
                        "требуется": required_staff,
                        "назначено": current_staff,
                        "нехватка": gap
                    })
                    total_gap_hours += gap
            
            if day_gaps:
                understaffed_days += 1
                gaps.append({
                    "дата": day_data["дата"],
                    "пробелы_в_покрытии": day_gaps,
                    "критичность": "высокая" if len(day_gaps) > 4 else "средняя"
                })
        
        gap_analysis = {
            "всего_дней_анализа": len(coverage_data),
            "дней_с_недостаточным_покрытием": understaffed_days,
            "процент_проблемных_дней": round(understaffed_days / len(coverage_data) * 100, 1),
            "общие_часы_нехватки": total_gap_hours,
            "детализированные_пробелы": gaps[:10],  # Show first 10 gaps
            "статус_покрытия": "критический" if understaffed_days / len(coverage_data) > 0.3 else "удовлетворительный"
        }
        
        # Generate recommendations
        recommendations = []
        
        if understaffed_days > 0:
            recommendations.append(f"Требуется дополнительное покрытие на {understaffed_days} дней")
            
        if total_gap_hours > 40:
            recommendations.append(f"Нехватка {total_gap_hours} человеко-часов - рассмотрите дополнительный найм")
            
        # Check peak hours
        peak_gaps = {}
        for gap_day in gaps:
            for gap in gap_day["пробелы_в_покрытии"]:
                hour = gap["час"]
                peak_gaps[hour] = peak_gaps.get(hour, 0) + gap["нехватка"]
        
        if peak_gaps:
            worst_hour = max(peak_gaps.keys(), key=lambda h: peak_gaps[h])
            recommendations.append(f"Наибольшие пробелы в {worst_hour} - приоритет для дополнительного покрытия")
        
        if not recommendations:
            recommendations.append("Покрытие соответствует требованиям - поддерживайте текущий уровень")
        
        # Store analysis
        analysis_id = str(uuid.uuid4())
        current_time = datetime.utcnow()
        
        analysis_record_query = text("""
            INSERT INTO coverage_analyses 
            (id, department_id, analysis_period_start, analysis_period_end,
             coverage_data, gap_analysis, recommendations, created_at)
            VALUES 
            (:id, :dept_id, :start_date, :end_date,
             :coverage, :gaps, :recommendations, :created_at)
        """)
        
        await db.execute(analysis_record_query, {
            'id': analysis_id,
            'dept_id': request.department_id,
            'start_date': request.analysis_period_start,
            'end_date': request.analysis_period_end,
            'coverage': json.dumps(coverage_data),
            'gaps': json.dumps(gap_analysis),
            'recommendations': json.dumps(recommendations),
            'created_at': current_time
        })
        
        await db.commit()
        
        return CoverageAnalysisResponse(
            analysis_id=analysis_id,
            coverage_data=coverage_data,
            gap_analysis=gap_analysis,
            recommendations=recommendations,
            message=f"Анализ покрытия завершен для отдела '{department.department_name}': {gap_analysis['процент_проблемных_дней']}% дней с недостаточным покрытием"
        )
        
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"Ошибка анализа покрытия: {str(e)}")
        
import uuid