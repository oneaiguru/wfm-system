"""
REAL SCHEDULE PREDICTIVE ANALYTICS ENDPOINT
Task 47/50: Predictive Analytics and Forecasting for Schedule Planning
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
import statistics

from ...core.database import get_db

router = APIRouter()

class PredictiveAnalyticsRequest(BaseModel):
    prediction_scope: str = "отдел"
    scope_id: UUID
    prediction_horizon_days: int = 30
    analysis_models: List[str] = ["загрузка", "эффективность", "конфликты", "затраты"]
    historical_period_days: int = 90

class PredictiveAnalyticsResponse(BaseModel):
    prediction_id: str
    predictions: Dict[str, Any]
    confidence_levels: Dict[str, float]
    trend_analysis: Dict[str, Any]
    recommendations: List[str]
    message: str

@router.post("/schedules/analytics/predictive", response_model=PredictiveAnalyticsResponse, tags=["🔥 REAL Schedule Analytics"])
async def generate_predictive_analytics(
    request: PredictiveAnalyticsRequest,
    db: AsyncSession = Depends(get_db)
):
    """REAL PREDICTIVE ANALYTICS - NO MOCKS! Generates predictions based on historical data"""
    try:
        # Define analysis periods
        today = date.today()
        historical_start = today - timedelta(days=request.historical_period_days)
        prediction_end = today + timedelta(days=request.prediction_horizon_days)
        
        # Get historical data for analysis
        historical_query = text("""
            SELECT 
                ws.id, ws.total_hours, ws.optimization_score, ws.status,
                ws.created_at, ws.effective_date, ws.expiry_date,
                e.id as employee_id, e.max_hours_per_week,
                st.cost_per_hour, os.department_name,
                DATE_PART('week', ws.created_at) as week_number,
                DATE_PART('month', ws.created_at) as month_number
            FROM work_schedules_core ws
            JOIN employees e ON ws.employee_id = e.id
            JOIN organizational_structure os ON e.department_id = os.id
            LEFT JOIN schedule_templates st ON ws.template_id = st.id
            WHERE e.department_id = :scope_id
            AND ws.created_at >= :historical_start
            AND ws.created_at <= :today
            ORDER BY ws.created_at
        """)
        
        historical_result = await db.execute(historical_query, {
            "scope_id": request.scope_id,
            "historical_start": historical_start,
            "today": today
        })
        
        historical_data = historical_result.fetchall()
        
        if not historical_data:
            raise HTTPException(
                status_code=404,
                detail="Недостаточно исторических данных для прогнозирования"
            )
        
        # Initialize predictions structure
        predictions = {}
        confidence_levels = {}
        
        # Workload prediction
        if "загрузка" in request.analysis_models:
            # Analyze historical workload patterns
            weekly_hours = {}
            weekly_schedule_counts = {}
            
            for record in historical_data:
                week_key = f"{record.created_at.year}-W{int(record.week_number)}"
                
                if week_key not in weekly_hours:
                    weekly_hours[week_key] = 0
                    weekly_schedule_counts[week_key] = 0
                
                weekly_hours[week_key] += record.total_hours or 0
                weekly_schedule_counts[week_key] += 1
            
            # Calculate trends
            recent_weeks = sorted(weekly_hours.keys())[-4:]  # Last 4 weeks
            if len(recent_weeks) >= 2:
                hours_values = [weekly_hours[week] for week in recent_weeks]
                schedule_counts = [weekly_schedule_counts[week] for week in recent_weeks]
                
                # Simple linear trend calculation
                hours_trend = (hours_values[-1] - hours_values[0]) / len(hours_values)
                schedule_trend = (schedule_counts[-1] - schedule_counts[0]) / len(schedule_counts)
                
                # Predict future workload
                current_avg_hours = statistics.mean(hours_values)
                current_avg_schedules = statistics.mean(schedule_counts)
                
                future_weeks = request.prediction_horizon_days // 7
                predicted_hours = current_avg_hours + (hours_trend * future_weeks)
                predicted_schedules = current_avg_schedules + (schedule_trend * future_weeks)
                
                predictions["загрузка"] = {
                    "прогнозируемые_часы_неделя": round(max(0, predicted_hours), 1),
                    "прогнозируемые_расписания_неделя": round(max(0, predicted_schedules), 1),
                    "тенденция_часов": "рост" if hours_trend > 0 else "снижение" if hours_trend < 0 else "стабильность",
                    "тенденция_расписаний": "рост" if schedule_trend > 0 else "снижение" if schedule_trend < 0 else "стабильность",
                    "изменение_часов_в_неделю": round(hours_trend, 1),
                    "текущая_средняя_неделя": round(current_avg_hours, 1)
                }
                
                # Confidence based on data consistency
                hours_variance = statistics.variance(hours_values) if len(hours_values) > 1 else 0
                confidence_levels["загрузка"] = max(0.5, min(0.95, 1 - (hours_variance / (current_avg_hours + 1)) * 0.5))
        
        # Efficiency prediction
        if "эффективность" in request.analysis_models:
            optimization_scores = [r.optimization_score for r in historical_data if r.optimization_score]
            
            if optimization_scores:
                # Group by time periods to see trends
                monthly_scores = {}
                for record in historical_data:
                    if record.optimization_score:
                        month_key = f"{record.created_at.year}-{int(record.month_number):02d}"
                        if month_key not in monthly_scores:
                            monthly_scores[month_key] = []
                        monthly_scores[month_key].append(record.optimization_score)
                
                # Calculate monthly averages
                monthly_averages = {month: statistics.mean(scores) for month, scores in monthly_scores.items()}
                recent_months = sorted(monthly_averages.keys())[-3:]  # Last 3 months
                
                if len(recent_months) >= 2:
                    score_values = [monthly_averages[month] for month in recent_months]
                    efficiency_trend = (score_values[-1] - score_values[0]) / len(score_values)
                    current_efficiency = statistics.mean(score_values)
                    
                    predicted_efficiency = current_efficiency + efficiency_trend
                    
                    predictions["эффективность"] = {
                        "прогнозируемый_балл_оптимизации": round(max(0, min(100, predicted_efficiency)), 2),
                        "текущий_средний_балл": round(current_efficiency, 2),
                        "тенденция": "улучшение" if efficiency_trend > 0 else "ухудшение" if efficiency_trend < 0 else "стабильность",
                        "изменение_в_месяц": round(efficiency_trend, 2),
                        "прогноз_категории": "отлично" if predicted_efficiency >= 80 else "хорошо" if predicted_efficiency >= 60 else "требует_улучшения"
                    }
                    
                    score_variance = statistics.variance(score_values) if len(score_values) > 1 else 0
                    confidence_levels["эффективность"] = max(0.6, min(0.9, 1 - (score_variance / 100)))
        
        # Conflict prediction
        if "конфликты" in request.analysis_models:
            # Get conflict history
            conflicts_query = text("""
                SELECT 
                    cd.created_at, cd.conflict_summary,
                    DATE_PART('week', cd.created_at) as week_number
                FROM conflict_detections cd
                WHERE cd.scope_id = :scope_id
                AND cd.created_at >= :historical_start
                ORDER BY cd.created_at
            """)
            
            conflicts_result = await db.execute(conflicts_query, {
                "scope_id": request.scope_id,
                "historical_start": historical_start
            })
            
            conflicts_data = conflicts_result.fetchall()
            
            # Count conflicts per week
            weekly_conflicts = {}
            for conflict in conflicts_data:
                week_key = f"{conflict.created_at.year}-W{int(conflict.week_number)}"
                if week_key not in weekly_conflicts:
                    weekly_conflicts[week_key] = 0
                
                # Parse conflict summary to count actual conflicts
                if conflict.conflict_summary:
                    summary = json.loads(conflict.conflict_summary)
                    weekly_conflicts[week_key] += summary.get("всего_конфликтов", 1)
                else:
                    weekly_conflicts[week_key] += 1
            
            if weekly_conflicts:
                recent_conflict_weeks = sorted(weekly_conflicts.keys())[-4:]
                conflict_values = [weekly_conflicts.get(week, 0) for week in recent_conflict_weeks]
                
                avg_conflicts = statistics.mean(conflict_values)
                conflict_trend = (conflict_values[-1] - conflict_values[0]) / len(conflict_values) if len(conflict_values) > 1 else 0
                
                future_weeks = request.prediction_horizon_days // 7
                predicted_conflicts = max(0, avg_conflicts + (conflict_trend * future_weeks))
                
                predictions["конфликты"] = {
                    "прогнозируемые_конфликты_неделя": round(predicted_conflicts, 1),
                    "текущая_средняя_неделя": round(avg_conflicts, 1),
                    "тенденция": "рост" if conflict_trend > 0 else "снижение" if conflict_trend < 0 else "стабильность",
                    "изменение_в_неделю": round(conflict_trend, 1),
                    "риск_уровень": "высокий" if predicted_conflicts > 5 else "средний" if predicted_conflicts > 2 else "низкий"
                }
                
                conflict_variance = statistics.variance(conflict_values) if len(conflict_values) > 1 else 0
                confidence_levels["конфликты"] = max(0.5, min(0.85, 1 - (conflict_variance / (avg_conflicts + 1)) * 0.3))
        
        # Cost prediction
        if "затраты" in request.analysis_models:
            # Calculate historical costs
            weekly_costs = {}
            for record in historical_data:
                week_key = f"{record.created_at.year}-W{int(record.week_number)}"
                if week_key not in weekly_costs:
                    weekly_costs[week_key] = 0
                
                cost_per_hour = record.cost_per_hour or 1000
                weekly_costs[week_key] += (record.total_hours or 0) * cost_per_hour
            
            if weekly_costs:
                recent_weeks = sorted(weekly_costs.keys())[-4:]
                cost_values = [weekly_costs[week] for week in recent_weeks]
                
                avg_cost = statistics.mean(cost_values)
                cost_trend = (cost_values[-1] - cost_values[0]) / len(cost_values) if len(cost_values) > 1 else 0
                
                future_weeks = request.prediction_horizon_days // 7
                predicted_weekly_cost = avg_cost + (cost_trend * future_weeks)
                predicted_monthly_cost = predicted_weekly_cost * 4.33  # Average weeks per month
                
                predictions["затраты"] = {
                    "прогнозируемые_затраты_неделя": round(max(0, predicted_weekly_cost), 2),
                    "прогнозируемые_затраты_месяц": round(max(0, predicted_monthly_cost), 2),
                    "текущая_средняя_неделя": round(avg_cost, 2),
                    "тенденция": "рост" if cost_trend > 0 else "снижение" if cost_trend < 0 else "стабильность",
                    "изменение_в_неделю": round(cost_trend, 2),
                    "бюджетный_статус": "превышение" if predicted_monthly_cost > avg_cost * 4.33 * 1.1 else "в_рамках"
                }
                
                cost_variance = statistics.variance(cost_values) if len(cost_values) > 1 else 0
                confidence_levels["затраты"] = max(0.6, min(0.9, 1 - (cost_variance / (avg_cost + 1)) * 0.0001))
        
        # Trend analysis summary
        trend_analysis = {
            "общие_тенденции": [],
            "период_анализа": f"{historical_start} - {today}",
            "горизонт_прогноза": f"{today} - {prediction_end}",
            "качество_данных": "хорошее" if len(historical_data) > 20 else "ограниченное",
            "рекомендуемые_действия": []
        }
        
        # Analyze overall trends
        for model, prediction in predictions.items():
            if "тенденция" in prediction:
                trend_analysis["общие_тенденции"].append(f"{model}: {prediction['тенденция']}")
        
        # Generate recommendations
        recommendations = []
        
        if "загрузка" in predictions and predictions["загрузка"]["тенденция"] == "рост":
            recommendations.append("Ожидается рост нагрузки - подготовьте дополнительные ресурсы")
        
        if "эффективность" in predictions and predictions["эффективность"]["прогнозируемый_балл_оптимизации"] < 70:
            recommendations.append("Прогнозируется снижение эффективности - пересмотрите шаблоны расписаний")
        
        if "конфликты" in predictions and predictions["конфликты"]["риск_уровень"] == "высокий":
            recommendations.append("Высокий риск конфликтов - усильте контроль планирования")
        
        if "затраты" in predictions and predictions["затраты"]["тенденция"] == "рост":
            recommendations.append("Ожидается рост затрат - оптимизируйте использование ресурсов")
        
        if not recommendations:
            recommendations.append("Прогнозы стабильны - продолжайте текущую стратегию")
        
        # Store prediction record
        prediction_id = str(uuid.uuid4())
        current_time = datetime.utcnow()
        
        prediction_record_query = text("""
            INSERT INTO predictive_analytics 
            (id, prediction_scope, scope_id, prediction_horizon_days,
             predictions, confidence_levels, trend_analysis, created_at)
            VALUES 
            (:id, :scope, :scope_id, :horizon,
             :predictions, :confidence, :trends, :created_at)
        """)
        
        await db.execute(prediction_record_query, {
            'id': prediction_id,
            'scope': request.prediction_scope,
            'scope_id': request.scope_id,
            'horizon': request.prediction_horizon_days,
            'predictions': json.dumps(predictions),
            'confidence': json.dumps(confidence_levels),
            'trends': json.dumps(trend_analysis),
            'created_at': current_time
        })
        
        await db.commit()
        
        # Calculate average confidence
        avg_confidence = statistics.mean(confidence_levels.values()) if confidence_levels else 0.7
        
        return PredictiveAnalyticsResponse(
            prediction_id=prediction_id,
            predictions=predictions,
            confidence_levels=confidence_levels,
            trend_analysis=trend_analysis,
            recommendations=recommendations,
            message=f"Прогнозная аналитика сформирована на {request.prediction_horizon_days} дней. Средняя достоверность: {avg_confidence:.1%}. Проанализировано {len(request.analysis_models)} моделей"
        )
        
    except Exception as e:
        await db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Ошибка прогнозной аналитики: {str(e)}"
        )