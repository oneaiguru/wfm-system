"""
Task 51: GET /api/v1/performance/metrics/realtime
BDD Scenario: Monitor Real-Time Performance Metrics
Based on: 15-real-time-monitoring-operational-control.feature lines 12-30

Real-time performance metrics endpoint implementing exact BDD requirements:
- Six key metrics: Operators Online %, Load Deviation, Operator Requirement, SLA Performance, ACD Rate, AHT Trend
- Real database queries from operational_metrics table
- Update frequencies and thresholds per BDD specifications
- Trend arrows and color coding per traffic light system
"""

from fastapi import APIRouter, HTTPException, Query, Depends
from sqlalchemy import text
from typing import Dict, List, Optional, Any
from pydantic import BaseModel
from datetime import datetime, timedelta
import psycopg2
import psycopg2.extras
import logging

# Database connection
def get_db_connection():
    """Get database connection for WFM Enterprise"""
    try:
        conn = psycopg2.connect(
            host="localhost",
            database="wfm_enterprise", 
            user="postgres",
            password="password"
        )
        return conn
    except Exception as e:
        logging.error(f"Database connection failed: {e}")
        raise HTTPException(status_code=500, detail="Database connection failed")

# BDD Response Models - Based on feature lines 16-29
class MetricDisplayElement(BaseModel):
    """Display elements from BDD lines 24-29"""
    current_value: float
    trend_arrow: str  # Up/Down/Stable arrows
    color_coding: str  # Traffic light system (Green/Yellow/Red)
    historical_context: List[Dict[str, Any]]  # Trend line or sparkline data

class RealTimeMetric(BaseModel):
    """Real-time metrics from BDD lines 16-23"""
    metric_name: str
    calculation: str
    thresholds: Dict[str, float]
    update_frequency: str
    display_elements: MetricDisplayElement

class RealTimeMetricsResponse(BaseModel):
    """BDD Scenario: Monitor Real-Time Performance Metrics"""
    operational_control_dashboards: List[RealTimeMetric]
    last_updated: datetime
    data_freshness: str
    bdd_scenario: str = "Monitor Real-Time Performance Metrics"

router = APIRouter()

@router.get("/performance/metrics/realtime", response_model=RealTimeMetricsResponse)
async def get_real_time_performance_metrics(
    metric_filter: Optional[str] = Query(None, description="Filter by specific metric name"),
    include_historical: bool = Query(True, description="Include historical context data")
):
    """
    Monitor Real-Time Performance Metrics
    
    BDD Implementation from 15-real-time-monitoring-operational-control.feature:
    - Scenario: View Real-time Operational Control Dashboards (lines 13-30)
    - Six key real-time metrics with exact calculations and thresholds
    - Traffic light system color coding
    - Update frequencies as specified in BDD
    """
    
    conn = get_db_connection()
    try:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            
            # BDD Query: Get six key real-time metrics from lines 17-23
            base_query = """
            SELECT 
                metric_name,
                current_value,
                target_value,
                calculation_formula,
                threshold_green_min,
                threshold_yellow_min, 
                threshold_red_max,
                status_color,
                trend_direction,
                trend_change_pct,
                update_frequency_seconds,
                historical_values,
                last_updated
            FROM operational_metrics
            WHERE 1=1
            """
            
            params = []
            if metric_filter:
                base_query += " AND metric_name = %s"
                params.append(metric_filter)
                
            base_query += " ORDER BY metric_name"
            
            cur.execute(base_query, params)
            metrics_data = cur.fetchall()
            
            if not metrics_data:
                raise HTTPException(status_code=404, detail="No real-time metrics found")
            
            # Process metrics according to BDD specifications
            operational_metrics = []
            
            for metric in metrics_data:
                # Calculate thresholds from BDD lines 17-23
                thresholds = {}
                if metric['metric_name'] == 'Operators Online %':
                    thresholds = {
                        "green": ">80%",
                        "yellow": "70-80%", 
                        "red": "<70%"
                    }
                elif metric['metric_name'] == 'Load Deviation':
                    thresholds = {
                        "green": "±10%",
                        "yellow": "±20%",
                        "red": ">20%"
                    }
                elif metric['metric_name'] == 'SLA Performance':
                    thresholds = {
                        "green": "Target ±5%",
                        "yellow": "Target ±10%", 
                        "red": ">±10%"
                    }
                else:
                    thresholds = {
                        "green": "Within target",
                        "yellow": "Approaching limits",
                        "red": "Exceeds limits"
                    }
                
                # Update frequency mapping from BDD
                frequency_map = {
                    30: "Every 30 seconds",   # Operators Online %
                    60: "Every minute",       # Load Deviation, SLA Performance
                    1: "Real-time",          # Operator Requirement, ACD Rate
                    300: "Every 5 minutes"   # AHT Trend
                }
                
                # Trend arrow from BDD lines 27-28
                trend_arrow = {
                    'Up': '↑',
                    'Down': '↓', 
                    'Stable': '→'
                }.get(metric['trend_direction'], '→')
                
                # Historical context processing
                historical_context = []
                if include_historical and metric['historical_values']:
                    historical_context = metric['historical_values'] if isinstance(metric['historical_values'], list) else []
                
                # Build display elements from BDD lines 24-29
                display_elements = MetricDisplayElement(
                    current_value=float(metric['current_value']),
                    trend_arrow=trend_arrow,
                    color_coding=metric['status_color'],  # Traffic light system
                    historical_context=historical_context
                )
                
                # Build real-time metric
                real_time_metric = RealTimeMetric(
                    metric_name=metric['metric_name'],
                    calculation=metric['calculation_formula'],
                    thresholds=thresholds,
                    update_frequency=frequency_map.get(metric['update_frequency_seconds'], "Variable"),
                    display_elements=display_elements
                )
                
                operational_metrics.append(real_time_metric)
            
            # Calculate data freshness
            if metrics_data:
                latest_update = max(metric['last_updated'] for metric in metrics_data)
                now = datetime.now()
                age_seconds = (now - latest_update).total_seconds()
                
                if age_seconds < 60:
                    freshness = "Real-time"
                elif age_seconds < 300:
                    freshness = f"{int(age_seconds)}s ago"
                else:
                    freshness = f"{int(age_seconds/60)}m ago"
            else:
                freshness = "No data"
            
            return RealTimeMetricsResponse(
                operational_control_dashboards=operational_metrics,
                last_updated=datetime.now(),
                data_freshness=freshness
            )
            
    except psycopg2.Error as e:
        logging.error(f"Database error in real-time metrics: {e}")
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
    except Exception as e:
        logging.error(f"Unexpected error in real-time metrics: {e}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")
    finally:
        conn.close()

# Additional endpoint for metric drill-down (BDD lines 31-47)
@router.get("/performance/metrics/realtime/{metric_name}/drill-down")
async def get_metric_drill_down(metric_name: str):
    """
    Drill Down into Metric Details
    
    BDD Implementation from lines 32-47:
    - Detailed breakdown by metric
    - Schedule adherence, timetable status, agent status
    - Real-time update frequencies
    """
    
    conn = get_db_connection()
    try:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            
            # Get drill-down details for specific metric
            cur.execute("""
                SELECT 
                    mdd.*,
                    arm.status as agent_status,
                    arm.schedule_adherence_status,
                    arm.actually_online_agents,
                    arm.current_activity
                FROM metric_drill_downs mdd
                LEFT JOIN agent_real_time_monitoring arm 
                    ON arm.employee_tab_n = ANY(
                        SELECT jsonb_array_elements_text(mdd.individual_agent_status->'employees')
                    )
                WHERE mdd.metric_name = %s
                ORDER BY mdd.last_updated DESC
                LIMIT 1
            """, (metric_name,))
            
            drill_down_data = cur.fetchone()
            
            if not drill_down_data:
                raise HTTPException(status_code=404, detail=f"No drill-down data found for metric: {metric_name}")
            
            # Process drill-down according to BDD lines 35-46
            detail_breakdown = {
                "schedule_adherence_24h": drill_down_data.get('schedule_adherence_24h', {}),
                "timetable_status": drill_down_data.get('timetable_status', {}),
                "actually_online_agents": drill_down_data.get('actually_online_agents', 0),
                "individual_agent_status": drill_down_data.get('individual_agent_status', {}),
                "deviation_timeline": drill_down_data.get('deviation_timeline', {})
            }
            
            # Update frequencies from BDD lines 42-46
            update_elements = {
                "agent_status": "Every 30 seconds",
                "schedule_compliance": "Real-time", 
                "historical_trends": "Every minute"
            }
            
            return {
                "metric_name": metric_name,
                "detail_breakdown": detail_breakdown,
                "update_elements": update_elements,
                "last_updated": drill_down_data['last_updated'],
                "data_source": drill_down_data.get('data_source', 'Real-time integration'),
                "bdd_scenario": "Drill Down into Metric Details"
            }
            
    except psycopg2.Error as e:
        logging.error(f"Database error in metric drill-down: {e}")
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
    except Exception as e:
        logging.error(f"Unexpected error in metric drill-down: {e}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")
    finally:
        conn.close()