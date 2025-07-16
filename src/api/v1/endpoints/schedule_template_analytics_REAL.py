"""
REAL SCHEDULE TEMPLATE ANALYTICS ENDPOINT
Task 35/50: Template Usage Analytics and Performance Metrics
"""

from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from pydantic import BaseModel
from datetime import datetime, timedelta
from typing import Optional, List, Dict, Any
from uuid import UUID
import json

from ...core.database import get_db

router = APIRouter()

class TemplateAnalyticsRequest(BaseModel):
    template_ids: Optional[List[UUID]] = None
    department_id: Optional[UUID] = None
    analysis_period_days: Optional[int] = 30
    include_archived: Optional[bool] = False
    metrics: List[str] = ["использование", "эффективность", "стоимость", "удовлетворенность"]

class TemplateAnalyticsResponse(BaseModel):
    analysis_period: str
    template_metrics: List[Dict[str, Any]]
    department_summary: Dict[str, Any]
    performance_rankings: Dict[str, Any]
    recommendations: List[str]
    trends_analysis: Dict[str, Any]
    message: str

@router.post("/schedules/templates/analytics", response_model=TemplateAnalyticsResponse, tags=["🔥 REAL Schedule Templates"])
async def analyze_template_performance(
    request: TemplateAnalyticsRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    REAL TEMPLATE ANALYTICS AND PERFORMANCE ANALYSIS - NO MOCKS!
    
    Analyzes template usage, efficiency, and performance metrics
    Uses real schedule_templates, work_schedules_core, and feedback tables
    Supports Russian analytics categories and recommendations
    
    UNBLOCKS: Template optimization and decision-making workflows
    """
    try:
        # Calculate analysis period
        end_date = datetime.utcnow()
        start_date = end_date - timedelta(days=request.analysis_period_days)
        
        # Build query conditions
        conditions = ["ws.created_at >= :start_date", "ws.created_at <= :end_date"]
        params = {"start_date": start_date, "end_date": end_date}
        
        if request.template_ids:
            template_ids_str = "'" + "','".join(str(tid) for tid in request.template_ids) + "'"
            conditions.append(f"st.id IN ({template_ids_str})")
        
        if request.department_id:
            conditions.append("st.department_id = :department_id")
            params["department_id"] = request.department_id
        
        if not request.include_archived:
            conditions.append("st.is_active = true")
        
        # Main analytics query
        analytics_query = text(f"""
            SELECT 
                st.id,
                st.template_name,
                st.template_type,
                st.cost_per_hour,
                st.working_hours_per_day,
                st.working_days_per_week,
                st.is_active,
                st.created_at as template_created,
                os.department_name,
                os.department_type,
                
                -- Usage metrics
                COUNT(ws.id) as total_usage,
                COUNT(CASE WHEN ws.status = 'active' THEN 1 END) as active_usage,
                COUNT(CASE WHEN ws.status = 'completed' THEN 1 END) as completed_usage,
                
                -- Time metrics
                AVG(ws.total_hours) as avg_hours_per_schedule,
                SUM(ws.total_hours) as total_hours_scheduled,
                
                -- Efficiency metrics
                AVG(ws.optimization_score) as avg_optimization_score,
                MIN(ws.optimization_score) as min_optimization_score,
                MAX(ws.optimization_score) as max_optimization_score,
                
                -- Cost metrics
                SUM(ws.total_hours * st.cost_per_hour) as total_cost,
                AVG(ws.total_hours * st.cost_per_hour) as avg_cost_per_schedule,
                
                -- Timing metrics
                MIN(ws.created_at) as first_usage,
                MAX(ws.created_at) as last_usage
                
            FROM schedule_templates st
            JOIN organizational_structure os ON st.department_id = os.id
            LEFT JOIN work_schedules_core ws ON ws.template_id = st.id 
                AND {' AND '.join(conditions)}
            GROUP BY st.id, st.template_name, st.template_type, st.cost_per_hour,
                     st.working_hours_per_day, st.working_days_per_week, st.is_active,
                     st.created_at, os.department_name, os.department_type
            ORDER BY total_usage DESC, avg_optimization_score DESC
        """)
        
        result = await db.execute(analytics_query, params)
        templates_data = result.fetchall()
        
        if not templates_data:
            raise HTTPException(
                status_code=404,
                detail="Нет данных для анализа в указанном периоде"
            )
        
        # Get user feedback data
        feedback_query = text(f"""
            SELECT 
                tf.template_id,
                AVG(tf.satisfaction_score) as avg_satisfaction,
                COUNT(tf.id) as feedback_count,
                COUNT(CASE WHEN tf.satisfaction_score >= 4 THEN 1 END) as positive_feedback,
                COUNT(CASE WHEN tf.satisfaction_score <= 2 THEN 1 END) as negative_feedback
            FROM template_feedback tf
            WHERE tf.created_at >= :start_date 
            AND tf.created_at <= :end_date
            GROUP BY tf.template_id
        """)
        
        feedback_result = await db.execute(feedback_query, params)
        feedback_data = {str(row.template_id): row for row in feedback_result.fetchall()}
        
        # Process template metrics
        template_metrics = []
        all_usage_counts = []
        all_efficiency_scores = []
        all_costs = []
        all_satisfaction_scores = []
        
        for template in templates_data:
            template_id = str(template.id)
            feedback = feedback_data.get(template_id)
            
            # Calculate efficiency metrics
            usage_count = template.total_usage or 0
            avg_optimization = template.avg_optimization_score or 0
            total_cost = template.total_cost or 0
            satisfaction = feedback.avg_satisfaction if feedback else 0
            
            # Usage efficiency
            days_since_creation = (end_date - template.template_created).days
            usage_frequency = usage_count / max(days_since_creation, 1) if days_since_creation > 0 else 0
            
            # Cost efficiency
            weekly_capacity = template.working_hours_per_day * template.working_days_per_week
            cost_efficiency = weekly_capacity / template.cost_per_hour if template.cost_per_hour > 0 else 0
            
            # Performance rating
            performance_factors = []
            if usage_count > 0:
                performance_factors.append(min(usage_count / 10, 1.0))  # Usage factor (max 1.0)
            if avg_optimization > 0:
                performance_factors.append(avg_optimization / 100)  # Optimization factor
            if satisfaction > 0:
                performance_factors.append(satisfaction / 5)  # Satisfaction factor
            
            overall_performance = sum(performance_factors) / len(performance_factors) if performance_factors else 0
            
            metrics_data = {
                "template_id": template_id,
                "название": template.template_name,
                "тип": template.template_type,
                "отдел": template.department_name,
                "активный": template.is_active,
                
                # Usage metrics
                "использование": {
                    "всего_применений": usage_count,
                    "активных_расписаний": template.active_usage or 0,
                    "завершенных_расписаний": template.completed_usage or 0,
                    "частота_использования": round(usage_frequency, 3),
                    "первое_использование": template.first_usage.isoformat() if template.first_usage else None,
                    "последнее_использование": template.last_usage.isoformat() if template.last_usage else None
                },
                
                # Efficiency metrics
                "эффективность": {
                    "средний_балл_оптимизации": round(avg_optimization, 2),
                    "диапазон_оптимизации": f"{template.min_optimization_score or 0} - {template.max_optimization_score or 0}",
                    "средние_часы_расписание": round(template.avg_hours_per_schedule or 0, 1),
                    "общие_часы": template.total_hours_scheduled or 0,
                    "коэффициент_эффективности": round(overall_performance * 100, 1)
                },
                
                # Cost metrics
                "стоимость": {
                    "общая_стоимость": round(total_cost, 2),
                    "средняя_стоимость_расписание": round(template.avg_cost_per_schedule or 0, 2),
                    "стоимость_час": template.cost_per_hour,
                    "эффективность_затрат": round(cost_efficiency, 2),
                    "недельная_мощность": weekly_capacity
                },
                
                # Satisfaction metrics
                "удовлетворенность": {
                    "средняя_оценка": round(satisfaction, 2) if satisfaction > 0 else "нет_данных",
                    "количество_отзывов": feedback.feedback_count if feedback else 0,
                    "положительных_отзывов": feedback.positive_feedback if feedback else 0,
                    "отрицательных_отзывов": feedback.negative_feedback if feedback else 0,
                    "процент_удовлетворенности": round((feedback.positive_feedback / feedback.feedback_count * 100) if feedback and feedback.feedback_count > 0 else 0, 1)
                }
            }
            
            template_metrics.append(metrics_data)
            
            # Collect data for rankings
            all_usage_counts.append((template_id, usage_count))
            all_efficiency_scores.append((template_id, avg_optimization))
            all_costs.append((template_id, total_cost))
            all_satisfaction_scores.append((template_id, satisfaction))
        
        # Calculate department summary
        total_templates = len(template_metrics)
        active_templates = sum(1 for t in template_metrics if t["активный"])
        total_usage = sum(t["использование"]["всего_применений"] for t in template_metrics)
        total_cost = sum(t["стоимость"]["общая_стоимость"] for t in template_metrics)
        avg_satisfaction = sum(t["удовлетворенность"]["средняя_оценка"] for t in template_metrics if isinstance(t["удовлетворенность"]["средняя_оценка"], (int, float))) / max(1, sum(1 for t in template_metrics if isinstance(t["удовлетворенность"]["средняя_оценка"], (int, float))))
        
        department_summary = {
            "всего_шаблонов": total_templates,
            "активных_шаблонов": active_templates,
            "архивных_шаблонов": total_templates - active_templates,
            "общее_использование": total_usage,
            "общая_стоимость": round(total_cost, 2),
            "средняя_удовлетворенность": round(avg_satisfaction, 2) if avg_satisfaction > 0 else "нет_данных",
            "анализируемый_период": f"{request.analysis_period_days} дней"
        }
        
        # Performance rankings
        performance_rankings = {
            "топ_по_использованию": [
                {"template_id": tid, "название": next(t["название"] for t in template_metrics if t["template_id"] == tid), "использований": count}
                for tid, count in sorted(all_usage_counts, key=lambda x: x[1], reverse=True)[:5]
            ],
            "топ_по_эффективности": [
                {"template_id": tid, "название": next(t["название"] for t in template_metrics if t["template_id"] == tid), "балл": score}
                for tid, score in sorted(all_efficiency_scores, key=lambda x: x[1], reverse=True)[:5]
                if score > 0
            ],
            "самые_дорогие": [
                {"template_id": tid, "название": next(t["название"] for t in template_metrics if t["template_id"] == tid), "стоимость": cost}
                for tid, cost in sorted(all_costs, key=lambda x: x[1], reverse=True)[:5]
                if cost > 0
            ],
            "лучшие_по_отзывам": [
                {"template_id": tid, "название": next(t["название"] for t in template_metrics if t["template_id"] == tid), "оценка": score}
                for tid, score in sorted(all_satisfaction_scores, key=lambda x: x[1], reverse=True)[:5]
                if score > 0
            ]
        }
        
        # Generate recommendations
        recommendations = []
        
        # Usage recommendations
        unused_templates = [t for t in template_metrics if t["использование"]["всего_применений"] == 0]
        if unused_templates:
            recommendations.append(f"Рассмотрите архивацию {len(unused_templates)} неиспользуемых шаблонов")
        
        # Efficiency recommendations
        low_efficiency = [t for t in template_metrics if t["эффективность"]["средний_балл_оптимизации"] < 70 and t["использование"]["всего_применений"] > 0]
        if low_efficiency:
            recommendations.append(f"Оптимизируйте {len(low_efficiency)} шаблонов с низкой эффективностью (< 70%)")
        
        # Cost recommendations
        high_cost_low_usage = [t for t in template_metrics if t["стоимость"]["стоимость_час"] > 1500 and t["использование"]["всего_применений"] < 5]
        if high_cost_low_usage:
            recommendations.append(f"Пересмотрите {len(high_cost_low_usage)} дорогих малоиспользуемых шаблонов")
        
        # Satisfaction recommendations
        low_satisfaction = [t for t in template_metrics if isinstance(t["удовлетворенность"]["средняя_оценка"], (int, float)) and t["удовлетворенность"]["средняя_оценка"] < 3]
        if low_satisfaction:
            recommendations.append(f"Улучшите {len(low_satisfaction)} шаблонов с низкой удовлетворенностью (< 3.0)")
        
        if not recommendations:
            recommendations.append("Шаблоны показывают хорошую производительность - продолжайте мониторинг")
        
        # Trends analysis
        recent_period = 7  # Last 7 days
        recent_start = end_date - timedelta(days=recent_period)
        
        trends_query = text(f"""
            SELECT 
                COUNT(*) as recent_usage,
                AVG(optimization_score) as recent_avg_optimization
            FROM work_schedules_core ws
            JOIN schedule_templates st ON ws.template_id = st.id
            WHERE ws.created_at >= :recent_start
            AND ws.created_at <= :end_date
            {"AND st.department_id = :department_id" if request.department_id else ""}
        """)
        
        trends_params = {"recent_start": recent_start, "end_date": end_date}
        if request.department_id:
            trends_params["department_id"] = request.department_id
        
        trends_result = await db.execute(trends_query, trends_params)
        trends_row = trends_result.fetchone()
        
        trends_analysis = {
            "последние_7_дней": {
                "использований": trends_row.recent_usage or 0,
                "средняя_эффективность": round(trends_row.recent_avg_optimization or 0, 2)
            },
            "сравнение_с_периодом": {
                "тенденция_использования": "растет" if (trends_row.recent_usage or 0) > (total_usage / request.analysis_period_days * 7) else "снижается",
                "изменение_эффективности": "улучшается" if (trends_row.recent_avg_optimization or 0) > sum(t["эффективность"]["средний_балл_оптимизации"] for t in template_metrics) / len(template_metrics) else "ухудшается"
            }
        }
        
        return TemplateAnalyticsResponse(
            analysis_period=f"{start_date.date()} - {end_date.date()}",
            template_metrics=template_metrics,
            department_summary=department_summary,
            performance_rankings=performance_rankings,
            recommendations=recommendations,
            trends_analysis=trends_analysis,
            message=f"Проанализировано {total_templates} шаблонов за {request.analysis_period_days} дней. Общее использование: {total_usage}, средняя удовлетворенность: {department_summary['средняя_удовлетворенность']}"
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Ошибка анализа шаблонов: {str(e)}"
        )

@router.get("/schedules/templates/{template_id}/analytics/detailed", tags=["🔥 REAL Schedule Templates"])
async def get_detailed_template_analytics(
    template_id: UUID,
    days_back: Optional[int] = 90,
    db: AsyncSession = Depends(get_db)
):
    """Get detailed analytics for a specific template"""
    try:
        end_date = datetime.utcnow()
        start_date = end_date - timedelta(days=days_back)
        
        # Template details
        template_query = text("""
            SELECT 
                st.*,
                os.department_name
            FROM schedule_templates st
            JOIN organizational_structure os ON st.department_id = os.id
            WHERE st.id = :template_id
        """)
        
        template_result = await db.execute(template_query, {"template_id": template_id})
        template = template_result.fetchone()
        
        if not template:
            raise HTTPException(
                status_code=404,
                detail=f"Шаблон {template_id} не найден"
            )
        
        # Usage timeline
        timeline_query = text("""
            SELECT 
                DATE(ws.created_at) as usage_date,
                COUNT(*) as daily_usage,
                AVG(ws.optimization_score) as daily_avg_score,
                SUM(ws.total_hours) as daily_hours
            FROM work_schedules_core ws
            WHERE ws.template_id = :template_id
            AND ws.created_at >= :start_date
            AND ws.created_at <= :end_date
            GROUP BY DATE(ws.created_at)
            ORDER BY usage_date
        """)
        
        timeline_result = await db.execute(timeline_query, {
            "template_id": template_id,
            "start_date": start_date,
            "end_date": end_date
        })
        
        usage_timeline = []
        for row in timeline_result.fetchall():
            usage_timeline.append({
                "дата": row.usage_date.isoformat(),
                "использований": row.daily_usage,
                "средний_балл": round(row.daily_avg_score or 0, 2),
                "часы": row.daily_hours or 0
            })
        
        return {
            "template_id": str(template_id),
            "template_details": {
                "название": template.template_name,
                "тип": template.template_type,
                "отдел": template.department_name,
                "стоимость_час": template.cost_per_hour,
                "часы_день": template.working_hours_per_day,
                "дни_неделя": template.working_days_per_week,
                "активный": template.is_active
            },
            "analysis_period": f"{start_date.date()} - {end_date.date()}",
            "usage_timeline": usage_timeline,
            "timeline_summary": {
                "всего_дней_с_использованием": len(usage_timeline),
                "общие_использования": sum(day["использований"] for day in usage_timeline),
                "средний_балл_период": round(sum(day["средний_балл"] for day in usage_timeline) / len(usage_timeline), 2) if usage_timeline else 0,
                "общие_часы": sum(day["часы"] for day in usage_timeline)
            }
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Ошибка детальной аналитики: {str(e)}"
        )