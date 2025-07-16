"""
REAL SCHEDULE REPORTING DASHBOARD ENDPOINT
Task 43/50: Comprehensive Schedule Reporting and Dashboard Data
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

class DashboardRequest(BaseModel):
    dashboard_scope: str = "организация"  # организация, отдел, менеджер
    scope_id: Optional[UUID] = None
    report_period: str = "текущая_неделя"  # текущая_неделя, текущий_месяц, произвольный
    custom_start: Optional[date] = None
    custom_end: Optional[date] = None

class DashboardResponse(BaseModel):
    dashboard_id: str
    summary_cards: Dict[str, Any]
    charts_data: Dict[str, Any]
    tables_data: Dict[str, Any]
    alerts: List[Dict[str, Any]]
    last_updated: str
    message: str

@router.post("/schedules/reporting/dashboard", response_model=DashboardResponse, tags=["🔥 REAL Schedule Reporting"])
async def generate_schedule_dashboard(
    request: DashboardRequest,
    db: AsyncSession = Depends(get_db)
):
    """REAL SCHEDULE DASHBOARD - NO MOCKS! Generates comprehensive dashboard data"""
    try:
        # Determine report period
        if request.report_period == "текущая_неделя":
            today = date.today()
            start_date = today - timedelta(days=today.weekday())
            end_date = start_date + timedelta(days=6)
        elif request.report_period == "текущий_месяц":
            today = date.today()
            start_date = today.replace(day=1)
            end_date = (start_date + timedelta(days=32)).replace(day=1) - timedelta(days=1)
        else:
            start_date = request.custom_start or date.today()
            end_date = request.custom_end or date.today()
        
        # Build scope conditions
        scope_conditions = []
        params = {"start_date": start_date, "end_date": end_date}
        
        if request.dashboard_scope == "отдел" and request.scope_id:
            scope_conditions.append("e.department_id = :scope_id")
            params["scope_id"] = request.scope_id
        elif request.dashboard_scope == "менеджер" and request.scope_id:
            scope_conditions.append("e.manager_id = :scope_id")
            params["scope_id"] = request.scope_id
        
        where_clause = "WHERE " + " AND ".join([
            "ws.effective_date <= :end_date",
            "(ws.expiry_date IS NULL OR ws.expiry_date >= :start_date)"
        ] + scope_conditions) if scope_conditions else "WHERE ws.effective_date <= :end_date AND (ws.expiry_date IS NULL OR ws.expiry_date >= :start_date)"
        
        # Summary metrics query
        summary_query = text(f"""
            SELECT 
                COUNT(DISTINCT ws.id) as total_schedules,
                COUNT(DISTINCT ws.employee_id) as total_employees,
                COUNT(DISTINCT e.department_id) as total_departments,
                SUM(ws.total_hours) as total_hours,
                AVG(ws.total_hours) as avg_hours_per_schedule,
                COUNT(CASE WHEN ws.status = 'active' THEN 1 END) as active_schedules,
                COUNT(CASE WHEN ws.status = 'pending' THEN 1 END) as pending_schedules,
                COUNT(CASE WHEN ws.status = 'completed' THEN 1 END) as completed_schedules,
                AVG(ws.optimization_score) as avg_optimization_score
            FROM work_schedules_core ws
            JOIN employees e ON ws.employee_id = e.id
            {where_clause}
        """)
        
        summary_result = await db.execute(summary_query, params)
        summary_row = summary_result.fetchone()
        
        # Department breakdown
        dept_query = text(f"""
            SELECT 
                os.department_name,
                COUNT(ws.id) as schedule_count,
                SUM(ws.total_hours) as total_hours,
                COUNT(DISTINCT ws.employee_id) as employee_count,
                AVG(ws.optimization_score) as avg_score
            FROM work_schedules_core ws
            JOIN employees e ON ws.employee_id = e.id
            JOIN organizational_structure os ON e.department_id = os.id
            {where_clause}
            GROUP BY os.id, os.department_name
            ORDER BY schedule_count DESC
            LIMIT 10
        """)
        
        dept_result = await db.execute(dept_query, params)
        dept_data = dept_result.fetchall()
        
        # Status distribution over time
        daily_query = text(f"""
            SELECT 
                DATE(ws.created_at) as creation_date,
                ws.status,
                COUNT(*) as count
            FROM work_schedules_core ws
            JOIN employees e ON ws.employee_id = e.id
            {where_clause}
            AND ws.created_at >= :start_date
            GROUP BY DATE(ws.created_at), ws.status
            ORDER BY creation_date
        """)
        
        daily_result = await db.execute(daily_query, params)
        daily_data = daily_result.fetchall()
        
        # Template usage
        template_query = text(f"""
            SELECT 
                COALESCE(st.template_name, 'Без шаблона') as template_name,
                COUNT(ws.id) as usage_count,
                AVG(ws.optimization_score) as avg_score
            FROM work_schedules_core ws
            JOIN employees e ON ws.employee_id = e.id
            LEFT JOIN schedule_templates st ON ws.template_id = st.id
            {where_clause}
            GROUP BY st.id, st.template_name
            ORDER BY usage_count DESC
            LIMIT 5
        """)
        
        template_result = await db.execute(template_query, params)
        template_data = template_result.fetchall()
        
        # Recent conflicts
        conflicts_query = text(f"""
            SELECT 
                cd.id,
                cd.scope_type,
                cd.conflict_summary,
                cd.created_at
            FROM conflict_detections cd
            WHERE cd.created_at >= :start_date
            ORDER BY cd.created_at DESC
            LIMIT 5
        """)
        
        conflicts_result = await db.execute(conflicts_query, params)
        conflicts_data = conflicts_result.fetchall()
        
        # Build summary cards
        summary_cards = {
            "общая_статистика": {
                "всего_расписаний": summary_row.total_schedules or 0,
                "задействовано_сотрудников": summary_row.total_employees or 0,
                "охваченных_отделов": summary_row.total_departments or 0,
                "общие_часы": summary_row.total_hours or 0
            },
            "статусы_расписаний": {
                "активные": summary_row.active_schedules or 0,
                "ожидающие": summary_row.pending_schedules or 0,
                "завершенные": summary_row.completed_schedules or 0
            },
            "показатели_качества": {
                "средний_балл_оптимизации": round(summary_row.avg_optimization_score or 0, 2),
                "средние_часы_на_расписание": round(summary_row.avg_hours_per_schedule or 0, 1),
                "процент_активных": round((summary_row.active_schedules or 0) / max(summary_row.total_schedules or 1, 1) * 100, 1)
            },
            "период_отчета": {
                "начало": start_date.isoformat(),
                "конец": end_date.isoformat(),
                "дней": (end_date - start_date).days + 1
            }
        }
        
        # Build charts data
        charts_data = {
            "распределение_по_отделам": [
                {
                    "отдел": row.department_name,
                    "расписаний": row.schedule_count,
                    "часы": row.total_hours or 0,
                    "сотрудники": row.employee_count,
                    "средний_балл": round(row.avg_score or 0, 2)
                } for row in dept_data
            ],
            "использование_шаблонов": [
                {
                    "шаблон": row.template_name,
                    "использований": row.usage_count,
                    "средний_балл": round(row.avg_score or 0, 2)
                } for row in template_data
            ],
            "динамика_создания": []
        }
        
        # Process daily data for time series
        daily_grouped = {}
        for row in daily_data:
            date_str = row.creation_date.isoformat()
            if date_str not in daily_grouped:
                daily_grouped[date_str] = {"дата": date_str, "активные": 0, "ожидающие": 0, "завершенные": 0}
            
            daily_grouped[date_str][row.status] = row.count
        
        charts_data["динамика_создания"] = list(daily_grouped.values())
        
        # Build tables data
        top_employees_query = text(f"""
            SELECT 
                e.first_name, e.last_name,
                COUNT(ws.id) as schedule_count,
                SUM(ws.total_hours) as total_hours,
                AVG(ws.optimization_score) as avg_score
            FROM work_schedules_core ws
            JOIN employees e ON ws.employee_id = e.id
            {where_clause}
            GROUP BY e.id, e.first_name, e.last_name
            ORDER BY schedule_count DESC
            LIMIT 10
        """)
        
        top_employees_result = await db.execute(top_employees_query, params)
        top_employees_data = top_employees_result.fetchall()
        
        tables_data = {
            "топ_сотрудники_по_расписаниям": [
                {
                    "сотрудник": f"{row.first_name} {row.last_name}",
                    "количество_расписаний": row.schedule_count,
                    "общие_часы": row.total_hours or 0,
                    "средний_балл": round(row.avg_score or 0, 2)
                } for row in top_employees_data
            ],
            "отделы_детально": charts_data["распределение_по_отделам"]
        }
        
        # Generate alerts
        alerts = []
        
        # Low optimization score alert
        if (summary_row.avg_optimization_score or 0) < 70:
            alerts.append({
                "тип": "низкая_оптимизация",
                "серьезность": "средняя",
                "сообщение": f"Средний балл оптимизации {summary_row.avg_optimization_score:.1f} ниже рекомендуемого уровня 70",
                "рекомендация": "Рассмотрите пересмотр шаблонов расписаний"
            })
        
        # High pending schedules alert
        pending_ratio = (summary_row.pending_schedules or 0) / max(summary_row.total_schedules or 1, 1)
        if pending_ratio > 0.3:
            alerts.append({
                "тип": "много_ожидающих_расписаний",
                "серьезность": "высокая",
                "сообщение": f"{summary_row.pending_schedules} расписаний ожидают утверждения ({pending_ratio*100:.1f}%)",
                "рекомендация": "Ускорьте процесс утверждения расписаний"
            })
        
        # Recent conflicts alert
        if len(conflicts_data) > 2:
            recent_conflicts = sum(len(json.loads(c.conflict_summary).get("конфликты", [])) if c.conflict_summary else 0 for c in conflicts_data)
            alerts.append({
                "тип": "обнаружены_конфликты",
                "серьезность": "средняя",
                "сообщение": f"Обнаружено {recent_conflicts} конфликтов в расписаниях за период",
                "рекомендация": "Проверьте и устраните конфликты расписаний"
            })
        
        if not alerts:
            alerts.append({
                "тип": "все_в_порядке",
                "серьезность": "информация",
                "сообщение": "Все показатели в пределах нормы",
                "рекомендация": "Продолжайте текущую работу"
            })
        
        # Store dashboard data
        dashboard_id = str(uuid.uuid4())
        current_time = datetime.utcnow()
        
        dashboard_record_query = text("""
            INSERT INTO dashboard_reports 
            (id, dashboard_scope, scope_id, report_period_start, report_period_end,
             summary_cards, charts_data, tables_data, alerts, created_at)
            VALUES 
            (:id, :scope, :scope_id, :start_date, :end_date,
             :summary, :charts, :tables, :alerts, :created_at)
        """)
        
        await db.execute(dashboard_record_query, {
            'id': dashboard_id,
            'scope': request.dashboard_scope,
            'scope_id': request.scope_id,
            'start_date': start_date,
            'end_date': end_date,
            'summary': json.dumps(summary_cards),
            'charts': json.dumps(charts_data),
            'tables': json.dumps(tables_data),
            'alerts': json.dumps(alerts),
            'created_at': current_time
        })
        
        await db.commit()
        
        return DashboardResponse(
            dashboard_id=dashboard_id,
            summary_cards=summary_cards,
            charts_data=charts_data,
            tables_data=tables_data,
            alerts=alerts,
            last_updated=current_time.isoformat(),
            message=f"Дашборд сформирован для области '{request.dashboard_scope}' за период {start_date} - {end_date}. Всего расписаний: {summary_row.total_schedules}, сотрудников: {summary_row.total_employees}"
        )
        
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"Ошибка формирования дашборда: {str(e)}")