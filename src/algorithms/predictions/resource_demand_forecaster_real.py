#!/usr/bin/env python3
"""
Resource Demand Forecaster Real - Zero Mock Dependencies
Transformed from: subagents/agent-8/prediction_engine.py (lines 697-928)
Database: PostgreSQL Schema 001 + auto-created resource tables
Performance: <3s demand forecasting, real agent utilization data
"""

import time
import logging
import numpy as np
import pandas as pd
import json
from datetime import datetime, timedelta, date
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass
from enum import Enum
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
import os

# Statistical libraries for demand forecasting
try:
    from scipy.optimize import minimize
    from scipy.stats import poisson, gamma
    from sklearn.ensemble import RandomForestRegressor
    from sklearn.preprocessing import StandardScaler
except ImportError:
    raise ImportError("scipy and sklearn required: pip install scipy scikit-learn")

logger = logging.getLogger(__name__)

class ForecastHorizon(Enum):
    """Forecast time horizons"""
    IMMEDIATE = "immediate"      # Next 30 minutes
    SHORT_TERM = "short_term"    # Next 4 hours
    MEDIUM_TERM = "medium_term"  # Next 24 hours
    LONG_TERM = "long_term"      # Next 7 days

class ResourceType(Enum):
    """Types of resources to forecast"""
    AGENTS = "agents"
    CAPACITY = "capacity"
    SKILLS = "skills"
    SUPERVISORS = "supervisors"

class DemandUrgency(Enum):
    """Demand urgency levels"""
    CRITICAL = "critical"     # Immediate action required
    HIGH = "high"            # Action needed within hour
    MEDIUM = "medium"        # Plan for next shift
    LOW = "low"             # Long-term planning

@dataclass
class RealResourceDemandForecast:
    """Real resource demand forecast from agent utilization analysis"""
    forecast_id: str
    prediction_timestamp: datetime
    service_id: int
    resource_type: ResourceType
    forecast_horizon: ForecastHorizon
    forecast_period_start: datetime
    forecast_period_end: datetime
    
    # Demand predictions
    predicted_demand: Dict[str, float]  # hour -> demand
    demand_confidence: Dict[str, float]  # hour -> confidence
    peak_periods: List[Tuple[datetime, datetime, float]]  # (start, end, demand)
    
    # Capacity analysis
    current_capacity: float
    capacity_gap: float
    utilization_target: float
    recommended_capacity: float
    
    # Agent requirements
    base_agents_needed: int
    peak_agents_needed: int
    skill_requirements: Dict[str, int]
    
    # Uncertainty and risk
    uncertainty_bounds: Tuple[float, float]  # (lower, upper)
    demand_volatility: float
    confidence_score: float
    
    # Recommendations
    capacity_actions: List[str]
    staffing_recommendations: List[str]
    risk_mitigation: List[str]
    
    data_source: str = "REAL_DATABASE"

class ResourceDemandForecasterReal:
    """Real-time Resource Demand Forecaster using PostgreSQL Schema 001 + Agent Activity"""
    
    def __init__(self, database_url: Optional[str] = None):
        self.processing_target = 3.0  # 3 seconds for demand forecasting
        
        # Database connection - REAL DATA ONLY
        if not database_url:
            database_url = os.getenv('DATABASE_URL', 'postgresql://postgres:postgres@localhost:5432/wfm_enterprise')
        
        self.engine = create_engine(database_url)
        self.SessionLocal = sessionmaker(bind=self.engine)
        
        # ML models for demand prediction
        self.demand_model = RandomForestRegressor(n_estimators=50, random_state=42)
        self.scaler = StandardScaler()
        self.is_trained = False
        
        # Demand patterns cache
        self.demand_patterns = {}  # service_id -> patterns
        self.capacity_history = {}  # service_id -> historical capacity data
        
        # Validate database connection and create tables
        self._validate_database_connection()
        self._ensure_resource_tables()
    
    def _validate_database_connection(self):
        """Ensure we can connect to real database - FAIL if no connection"""
        try:
            with self.SessionLocal() as session:
                result = session.execute(text("SELECT 1")).fetchone()
                if not result:
                    raise ConnectionError("Database connection failed")
                
                # Validate Schema 001 tables exist
                tables_check = session.execute(text("""
                    SELECT COUNT(*) FROM information_schema.tables 
                    WHERE table_name IN ('contact_statistics', 'agent_activity', 'services')
                """)).scalar()
                
                if tables_check < 3:
                    raise ConnectionError("PostgreSQL Schema 001 tables missing")
                
                logger.info("✅ REAL DATABASE CONNECTION ESTABLISHED - Schema 001 validated")
        except Exception as e:
            logger.error(f"❌ REAL DATABASE CONNECTION FAILED: {e}")
            raise ConnectionError(f"Cannot operate without real database: {e}")
    
    def _ensure_resource_tables(self):
        """Create resource-specific tables if they don't exist"""
        with self.SessionLocal() as session:
            # Create resource_forecasts table
            session.execute(text("""
                CREATE TABLE IF NOT EXISTS resource_forecasts (
                    forecast_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                    service_id INTEGER NOT NULL,
                    resource_type VARCHAR(50) NOT NULL,
                    forecast_timestamp TIMESTAMPTZ DEFAULT NOW(),
                    forecast_period_start TIMESTAMPTZ NOT NULL,
                    forecast_period_end TIMESTAMPTZ NOT NULL,
                    predicted_demand JSONB NOT NULL,
                    demand_confidence JSONB,
                    peak_periods JSONB,
                    current_capacity DECIMAL(10,2),
                    capacity_gap DECIMAL(10,2),
                    recommended_capacity DECIMAL(10,2),
                    base_agents_needed INTEGER,
                    peak_agents_needed INTEGER,
                    confidence_score DECIMAL(3,2),
                    demand_volatility DECIMAL(3,2)
                )
            """))
            
            # Create capacity_utilization table
            session.execute(text("""
                CREATE TABLE IF NOT EXISTS capacity_utilization (
                    id SERIAL PRIMARY KEY,
                    service_id INTEGER NOT NULL,
                    measurement_time TIMESTAMPTZ DEFAULT NOW(),
                    total_capacity INTEGER NOT NULL,
                    utilized_capacity DECIMAL(10,2),
                    utilization_rate DECIMAL(5,2),
                    available_agents INTEGER,
                    active_agents INTEGER,
                    queue_depth INTEGER DEFAULT 0,
                    avg_wait_time DECIMAL(10,2) DEFAULT 0
                )
            """))
            
            # Create agent_skill_capacity table
            session.execute(text("""
                CREATE TABLE IF NOT EXISTS agent_skill_capacity (
                    id SERIAL PRIMARY KEY,
                    service_id INTEGER NOT NULL,
                    skill_name VARCHAR(100) NOT NULL,
                    available_agents INTEGER DEFAULT 0,
                    total_agents_with_skill INTEGER DEFAULT 0,
                    skill_utilization_rate DECIMAL(5,2) DEFAULT 0,
                    skill_demand_score DECIMAL(5,2) DEFAULT 0,
                    last_updated TIMESTAMPTZ DEFAULT NOW(),
                    UNIQUE(service_id, skill_name)
                )
            """))
            
            # Create demand_patterns table
            session.execute(text("""
                CREATE TABLE IF NOT EXISTS demand_patterns (
                    pattern_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                    service_id INTEGER NOT NULL,
                    pattern_type VARCHAR(50) NOT NULL, -- hourly, daily, weekly
                    pattern_data JSONB NOT NULL,
                    pattern_strength DECIMAL(3,2),
                    data_points_used INTEGER,
                    accuracy_score DECIMAL(3,2),
                    created_at TIMESTAMPTZ DEFAULT NOW(),
                    is_active BOOLEAN DEFAULT true
                )
            """))
            
            session.commit()
            logger.info("✅ Resource forecasting tables created/validated")
    
    def forecast_resource_demand_real(self, 
                                     service_id: int,
                                     resource_type: ResourceType,
                                     forecast_horizon: ForecastHorizon,
                                     target_utilization: float = 0.85) -> RealResourceDemandForecast:
        """Generate real resource demand forecast using actual agent utilization data"""
        start_time = time.time()
        
        try:
            # Update demand patterns if needed
            self._update_demand_patterns(service_id)
            
            # Get current capacity and utilization
            current_capacity_data = self._get_current_capacity(service_id)
            
            # Get historical demand patterns
            historical_demand = self._get_historical_demand(service_id, resource_type)
            
            if not current_capacity_data or len(historical_demand) < 10:
                raise ValueError(f"Insufficient data for demand forecasting: {len(historical_demand)} historical points")
            
            # Generate forecast based on horizon
            forecast_period = self._calculate_forecast_period(forecast_horizon)
            
            # Predict demand using multiple methods
            predicted_demand = self._predict_demand_real(service_id, resource_type, historical_demand, forecast_period)
            
            # Calculate demand confidence
            demand_confidence = self._calculate_demand_confidence(predicted_demand, historical_demand)
            
            # Identify peak periods
            peak_periods = self._identify_peak_periods(predicted_demand)
            
            # Calculate capacity requirements
            capacity_analysis = self._analyze_capacity_requirements(
                predicted_demand, current_capacity_data, target_utilization
            )
            
            # Generate agent requirements
            agent_requirements = self._calculate_agent_requirements(
                service_id, predicted_demand, resource_type
            )
            
            # Calculate uncertainty and risk
            uncertainty_analysis = self._calculate_uncertainty_bounds(predicted_demand, historical_demand)
            
            # Generate recommendations
            recommendations = self._generate_capacity_recommendations(
                capacity_analysis, agent_requirements, peak_periods
            )
            
            # Create forecast object
            forecast = RealResourceDemandForecast(
                forecast_id=f"RDF_{service_id}_{resource_type.value}_{int(time.time())}",
                prediction_timestamp=datetime.now(),
                service_id=service_id,
                resource_type=resource_type,
                forecast_horizon=forecast_horizon,
                forecast_period_start=forecast_period[0],
                forecast_period_end=forecast_period[1],
                
                predicted_demand=predicted_demand,
                demand_confidence=demand_confidence,
                peak_periods=peak_periods,
                
                current_capacity=capacity_analysis['current_capacity'],
                capacity_gap=capacity_analysis['capacity_gap'],
                utilization_target=target_utilization,
                recommended_capacity=capacity_analysis['recommended_capacity'],
                
                base_agents_needed=agent_requirements['base_agents'],
                peak_agents_needed=agent_requirements['peak_agents'],
                skill_requirements=agent_requirements['skill_requirements'],
                
                uncertainty_bounds=uncertainty_analysis['bounds'],
                demand_volatility=uncertainty_analysis['volatility'],
                confidence_score=uncertainty_analysis['confidence'],
                
                capacity_actions=recommendations['capacity_actions'],
                staffing_recommendations=recommendations['staffing_recommendations'],
                risk_mitigation=recommendations['risk_mitigation']
            )
            
            # Save forecast to database
            self._save_resource_forecast(forecast)
            
            # Validate processing time
            processing_time = time.time() - start_time
            if processing_time >= self.processing_target:
                logger.warning(f"Processing time {processing_time:.3f}s exceeds {self.processing_target}s target")
            
            logger.info(f"✅ Generated resource demand forecast for service {service_id}, {resource_type.value}")
            return forecast
            
        except Exception as e:
            logger.error(f"❌ Real resource demand forecasting failed: {e}")
            raise ValueError(f"Resource demand forecasting failed for service {service_id}: {e}")
    
    def _update_demand_patterns(self, service_id: int):
        """Update demand patterns from real historical data"""
        with self.SessionLocal() as session:
            # Get historical demand data from contact_statistics and agent_activity
            historical_data = session.execute(text("""
                SELECT 
                    cs.interval_start_time,
                    cs.received_calls,
                    cs.treated_calls,
                    cs.service_level,
                    COUNT(aa.agent_id) as active_agents,
                    AVG(aa.login_time::float / 3600000) as avg_login_hours
                FROM contact_statistics cs
                LEFT JOIN agent_activity aa ON 
                    aa.interval_start_time = cs.interval_start_time
                WHERE cs.service_id = :service_id
                AND cs.interval_start_time >= NOW() - INTERVAL '30 days'
                AND cs.received_calls IS NOT NULL
                GROUP BY cs.interval_start_time, cs.received_calls, cs.treated_calls, cs.service_level
                ORDER BY cs.interval_start_time ASC
            """), {'service_id': service_id}).fetchall()
            
            if len(historical_data) < 10:
                logger.warning(f"Insufficient historical data for patterns: {len(historical_data)} points")
                return
            
            # Convert to DataFrame for analysis
            df = pd.DataFrame([
                {
                    'timestamp': row.interval_start_time,
                    'received_calls': float(row.received_calls),
                    'treated_calls': float(row.treated_calls),
                    'service_level': float(row.service_level) if row.service_level else 0,
                    'active_agents': int(row.active_agents) if row.active_agents else 0,
                    'avg_login_hours': float(row.avg_login_hours) if row.avg_login_hours else 0
                }
                for row in historical_data
            ])
            
            df['timestamp'] = pd.to_datetime(df['timestamp'])
            df['hour'] = df['timestamp'].dt.hour
            df['day_of_week'] = df['timestamp'].dt.dayofweek
            df['demand_score'] = df['received_calls'] / (df['active_agents'] + 1)  # Demand per agent
            
            # Calculate hourly patterns
            hourly_pattern = df.groupby('hour').agg({
                'demand_score': ['mean', 'std'],
                'received_calls': 'mean',
                'active_agents': 'mean'
            }).round(2)
            
            # Calculate daily patterns
            daily_pattern = df.groupby('day_of_week').agg({
                'demand_score': ['mean', 'std'],
                'received_calls': 'mean',
                'active_agents': 'mean'
            }).round(2)
            
            # Store patterns in memory
            if service_id not in self.demand_patterns:
                self.demand_patterns[service_id] = {}
            
            self.demand_patterns[service_id]['hourly'] = hourly_pattern.to_dict()
            self.demand_patterns[service_id]['daily'] = daily_pattern.to_dict()
            
            # Save patterns to database
            for pattern_type, pattern_data in [('hourly', hourly_pattern), ('daily', daily_pattern)]:
                # Convert pattern data to simple JSON-serializable format
                simple_pattern = {
                    'summary': f'{pattern_type} demand pattern',
                    'data_points': len(df),
                    'avg_demand': float(df['demand_score'].mean()) if 'demand_score' in df.columns else 0,
                    'max_demand': float(df['demand_score'].max()) if 'demand_score' in df.columns else 0,
                    'pattern_type': pattern_type,
                    'created_at': datetime.now().isoformat()
                }
                
                session.execute(text("""
                    INSERT INTO demand_patterns (
                        service_id, pattern_type, pattern_data, data_points_used
                    ) VALUES (
                        :service_id, :pattern_type, :pattern_data, :data_points
                    )
                """), {
                    'service_id': service_id,
                    'pattern_type': pattern_type,
                    'pattern_data': json.dumps(simple_pattern),
                    'data_points': len(df)
                })
            
            session.commit()
            logger.info(f"✅ Updated demand patterns for service {service_id}")
    
    def _get_current_capacity(self, service_id: int) -> Dict[str, Any]:
        """Get current capacity and utilization data"""
        with self.SessionLocal() as session:
            # Get current agent status and capacity
            capacity_data = session.execute(text("""
                SELECT 
                    COUNT(DISTINCT aa.agent_id) as total_agents,
                    AVG(aa.login_time::float / 3600000) as avg_utilization,
                    MAX(cs.received_calls) as current_call_volume,
                    AVG(cs.service_level) as current_service_level
                FROM agent_activity aa
                JOIN contact_statistics cs ON 
                    cs.interval_start_time >= aa.interval_start_time
                    AND cs.interval_start_time < aa.interval_end_time
                WHERE cs.service_id = :service_id
                AND aa.interval_start_time >= NOW() - INTERVAL '2 hours'
                AND cs.interval_start_time >= NOW() - INTERVAL '1 hour'
            """), {'service_id': service_id}).fetchone()
            
            if not capacity_data:
                return {}
            
            return {
                'total_agents': int(capacity_data.total_agents) if capacity_data.total_agents else 0,
                'avg_utilization': float(capacity_data.avg_utilization) if capacity_data.avg_utilization else 0,
                'current_call_volume': float(capacity_data.current_call_volume) if capacity_data.current_call_volume else 0,
                'current_service_level': float(capacity_data.current_service_level) if capacity_data.current_service_level else 0
            }
    
    def _get_historical_demand(self, service_id: int, resource_type: ResourceType, days: int = 21) -> pd.DataFrame:
        """Get historical demand data for forecasting"""
        with self.SessionLocal() as session:
            # Query depends on resource type
            if resource_type == ResourceType.AGENTS:
                demand_query = """
                    SELECT 
                        cs.interval_start_time,
                        cs.received_calls,
                        cs.treated_calls,
                        cs.service_level,
                        COUNT(aa.agent_id) as agents_active,
                        cs.received_calls::float / NULLIF(COUNT(aa.agent_id), 0) as demand_per_agent
                    FROM contact_statistics cs
                    LEFT JOIN agent_activity aa ON 
                        aa.interval_start_time = cs.interval_start_time
                    WHERE cs.service_id = :service_id
                    AND cs.interval_start_time >= NOW() - INTERVAL ':days days'
                    AND cs.received_calls IS NOT NULL
                    GROUP BY cs.interval_start_time, cs.received_calls, cs.treated_calls, cs.service_level
                    ORDER BY cs.interval_start_time ASC
                """
            else:  # CAPACITY, SKILLS, SUPERVISORS
                demand_query = """
                    SELECT 
                        interval_start_time,
                        received_calls,
                        treated_calls,
                        service_level,
                        received_calls as demand_metric
                    FROM contact_statistics
                    WHERE service_id = :service_id
                    AND interval_start_time >= NOW() - INTERVAL ':days days'
                    AND received_calls IS NOT NULL
                    ORDER BY interval_start_time ASC
                """
            
            historical_data = session.execute(text(demand_query), {
                'service_id': service_id, 
                'days': days
            }).fetchall()
            
            if not historical_data:
                return pd.DataFrame()
            
            # Convert to DataFrame
            df = pd.DataFrame([
                {
                    'timestamp': row.interval_start_time,
                    'received_calls': float(row.received_calls),
                    'treated_calls': float(row.treated_calls),
                    'service_level': float(row.service_level) if row.service_level else 0,
                    'demand_metric': getattr(row, 'demand_per_agent', row.received_calls) or 0
                }
                for row in historical_data
            ])
            
            df['timestamp'] = pd.to_datetime(df['timestamp'])
            df['hour'] = df['timestamp'].dt.hour
            df['day_of_week'] = df['timestamp'].dt.dayofweek
            
            return df
    
    def _calculate_forecast_period(self, horizon: ForecastHorizon) -> Tuple[datetime, datetime]:
        """Calculate forecast period based on horizon"""
        now = datetime.now()
        
        if horizon == ForecastHorizon.IMMEDIATE:
            end_time = now + timedelta(minutes=30)
        elif horizon == ForecastHorizon.SHORT_TERM:
            end_time = now + timedelta(hours=4)
        elif horizon == ForecastHorizon.MEDIUM_TERM:
            end_time = now + timedelta(hours=24)
        else:  # LONG_TERM
            end_time = now + timedelta(days=7)
        
        return (now, end_time)
    
    def _predict_demand_real(self, 
                            service_id: int,
                            resource_type: ResourceType,
                            historical_data: pd.DataFrame,
                            forecast_period: Tuple[datetime, datetime]) -> Dict[str, float]:
        """Predict demand using real historical patterns and ML"""
        
        start_time, end_time = forecast_period
        predictions = {}
        
        # Get hourly patterns if available
        hourly_patterns = self.demand_patterns.get(service_id, {}).get('hourly', {})
        
        # Generate hourly predictions
        current = start_time
        while current <= end_time:
            hour_key = current.strftime("%Y-%m-%d %H:00")
            hour = current.hour
            day_of_week = current.weekday()
            
            # Base prediction from historical patterns
            if hourly_patterns and ('demand_score', 'mean') in hourly_patterns:
                pattern_data = hourly_patterns.get(('demand_score', 'mean'), {})
                base_demand = pattern_data.get(hour, historical_data['demand_metric'].mean())
            else:
                # Fallback to time-based heuristics
                base_demand = self._calculate_heuristic_demand(hour, day_of_week, historical_data)
            
            # Apply day-of-week adjustments
            if day_of_week in [5, 6]:  # Weekend
                base_demand *= 0.7
            elif day_of_week == 0:  # Monday
                base_demand *= 1.1
            
            # Apply seasonal adjustments based on recent trends
            recent_trend = self._calculate_recent_trend(historical_data)
            base_demand *= (1 + recent_trend)
            
            predictions[hour_key] = max(0, base_demand)
            current += timedelta(hours=1)
        
        return predictions
    
    def _calculate_heuristic_demand(self, hour: int, day_of_week: int, historical_data: pd.DataFrame) -> float:
        """Calculate heuristic demand when patterns are not available"""
        # Filter historical data for similar time periods
        similar_hour_data = historical_data[historical_data['hour'] == hour]
        
        if len(similar_hour_data) >= 5:
            return similar_hour_data['demand_metric'].mean()
        
        # Fallback to overall average with time-of-day adjustment
        base_avg = historical_data['demand_metric'].mean()
        
        # Peak hour adjustments
        if 9 <= hour <= 11 or 14 <= hour <= 16:  # Peak hours
            return base_avg * 1.3
        elif hour < 8 or hour > 18:  # Off hours
            return base_avg * 0.6
        else:
            return base_avg
    
    def _calculate_recent_trend(self, historical_data: pd.DataFrame) -> float:
        """Calculate recent trend factor"""
        if len(historical_data) < 14:
            return 0.0
        
        # Compare recent week to previous week
        recent_week = historical_data.tail(168)['demand_metric'].mean()  # Last 7 days * 24 hours
        previous_week = historical_data.iloc[-336:-168]['demand_metric'].mean()  # Previous 7 days
        
        if previous_week > 0:
            trend = (recent_week - previous_week) / previous_week
            return np.clip(trend, -0.2, 0.2)  # Limit trend impact to ±20%
        
        return 0.0
    
    def _calculate_demand_confidence(self, 
                                   predicted_demand: Dict[str, float],
                                   historical_data: pd.DataFrame) -> Dict[str, float]:
        """Calculate confidence scores for demand predictions"""
        confidence = {}
        
        # Base confidence on data availability and variance
        data_quality = min(len(historical_data) / 336, 1.0)  # 2 weeks of hourly data
        demand_variance = historical_data['demand_metric'].std() / historical_data['demand_metric'].mean() if historical_data['demand_metric'].mean() > 0 else 1.0
        
        base_confidence = data_quality * (1 - min(demand_variance, 0.5))
        
        for hour_key, demand in predicted_demand.items():
            # Adjust confidence based on prediction magnitude
            prediction_time = datetime.strptime(hour_key, "%Y-%m-%d %H:00")
            hours_ahead = (prediction_time - datetime.now()).total_seconds() / 3600
            
            # Confidence decreases with time distance
            time_decay = max(0.5, 1 - hours_ahead / 168)  # Decay over 7 days
            
            confidence[hour_key] = base_confidence * time_decay
        
        return confidence
    
    def _identify_peak_periods(self, predicted_demand: Dict[str, float]) -> List[Tuple[datetime, datetime, float]]:
        """Identify peak demand periods"""
        if not predicted_demand:
            return []
        
        # Calculate peak threshold (75th percentile)
        demands = list(predicted_demand.values())
        peak_threshold = np.percentile(demands, 75)
        
        peak_periods = []
        peak_start = None
        
        for hour_key, demand in sorted(predicted_demand.items()):
            timestamp = datetime.strptime(hour_key, "%Y-%m-%d %H:00")
            
            if demand >= peak_threshold:
                if peak_start is None:
                    peak_start = timestamp
            else:
                if peak_start is not None:
                    peak_periods.append((peak_start, timestamp, peak_threshold))
                    peak_start = None
        
        # Close any open peak period
        if peak_start is not None:
            last_time = max(datetime.strptime(k, "%Y-%m-%d %H:00") for k in predicted_demand.keys())
            peak_periods.append((peak_start, last_time, peak_threshold))
        
        return peak_periods
    
    def _analyze_capacity_requirements(self, 
                                     predicted_demand: Dict[str, float],
                                     current_capacity: Dict[str, Any],
                                     target_utilization: float) -> Dict[str, float]:
        """Analyze capacity requirements vs predicted demand"""
        
        max_demand = max(predicted_demand.values()) if predicted_demand else 0
        avg_demand = np.mean(list(predicted_demand.values())) if predicted_demand else 0
        current_cap = current_capacity.get('total_agents', 0)
        
        # Calculate required capacity
        required_capacity = max_demand / target_utilization if target_utilization > 0 else max_demand
        capacity_gap = max(0, required_capacity - current_cap)
        
        return {
            'current_capacity': float(current_cap),
            'max_demand': max_demand,
            'avg_demand': avg_demand,
            'required_capacity': required_capacity,
            'capacity_gap': capacity_gap,
            'recommended_capacity': required_capacity * 1.1,  # 10% buffer
            'utilization_projection': max_demand / current_cap if current_cap > 0 else 0
        }
    
    def _calculate_agent_requirements(self, 
                                    service_id: int,
                                    predicted_demand: Dict[str, float],
                                    resource_type: ResourceType) -> Dict[str, Any]:
        """Calculate specific agent requirements"""
        
        if not predicted_demand:
            return {'base_agents': 0, 'peak_agents': 0, 'skill_requirements': {}}
        
        max_demand = max(predicted_demand.values())
        avg_demand = np.mean(list(predicted_demand.values()))
        
        # Convert demand to agent requirements (assuming average productivity)
        # This is a simplified model - in production, would use Erlang C
        avg_calls_per_agent_per_hour = 12  # Configurable parameter
        
        base_agents = int(np.ceil(avg_demand / avg_calls_per_agent_per_hour))
        peak_agents = int(np.ceil(max_demand / avg_calls_per_agent_per_hour))
        
        # Skill requirements (simplified)
        skill_requirements = {
            'general': base_agents,
            'specialized': max(1, peak_agents - base_agents),
            'supervisory': max(1, peak_agents // 10)  # 1 supervisor per 10 agents
        }
        
        return {
            'base_agents': base_agents,
            'peak_agents': peak_agents,
            'skill_requirements': skill_requirements
        }
    
    def _calculate_uncertainty_bounds(self, 
                                    predicted_demand: Dict[str, float],
                                    historical_data: pd.DataFrame) -> Dict[str, Any]:
        """Calculate uncertainty bounds and risk metrics"""
        
        if not predicted_demand or len(historical_data) < 10:
            return {'bounds': (0, 0), 'volatility': 0, 'confidence': 0.5}
        
        # Calculate historical volatility
        demand_std = historical_data['demand_metric'].std()
        demand_mean = historical_data['demand_metric'].mean()
        volatility = demand_std / demand_mean if demand_mean > 0 else 0
        
        # Calculate prediction bounds (confidence interval)
        avg_prediction = np.mean(list(predicted_demand.values()))
        margin = demand_std * 1.96  # 95% confidence interval
        
        lower_bound = max(0, avg_prediction - margin)
        upper_bound = avg_prediction + margin
        
        # Overall confidence based on data quality and volatility
        confidence = max(0.3, 1 - volatility) * min(len(historical_data) / 336, 1.0)
        
        return {
            'bounds': (lower_bound, upper_bound),
            'volatility': volatility,
            'confidence': confidence
        }
    
    def _generate_capacity_recommendations(self, 
                                         capacity_analysis: Dict[str, float],
                                         agent_requirements: Dict[str, Any],
                                         peak_periods: List[Tuple[datetime, datetime, float]]) -> Dict[str, List[str]]:
        """Generate actionable capacity recommendations"""
        
        capacity_actions = []
        staffing_recommendations = []
        risk_mitigation = []
        
        # Capacity actions
        capacity_gap = capacity_analysis['capacity_gap']
        if capacity_gap > 0:
            capacity_actions.append(f"Increase capacity by {capacity_gap:.0f} agents")
            capacity_actions.append("Activate overflow protocols during peak periods")
        
        utilization_proj = capacity_analysis['utilization_projection']
        if utilization_proj > 0.9:
            capacity_actions.append("High utilization risk - consider additional buffer capacity")
        
        # Staffing recommendations
        base_agents = agent_requirements['base_agents']
        peak_agents = agent_requirements['peak_agents']
        
        if peak_agents > base_agents:
            staffing_recommendations.append(f"Schedule {base_agents} base agents with {peak_agents - base_agents} flex agents")
        
        if len(peak_periods) > 0:
            staffing_recommendations.append(f"Plan for {len(peak_periods)} peak periods requiring additional resources")
        
        # Risk mitigation
        if capacity_gap > capacity_analysis['current_capacity'] * 0.2:
            risk_mitigation.append("Significant capacity gap - implement callback options")
        
        if len(peak_periods) > 3:
            risk_mitigation.append("Multiple peak periods - consider workforce optimization")
        
        return {
            'capacity_actions': capacity_actions,
            'staffing_recommendations': staffing_recommendations,
            'risk_mitigation': risk_mitigation
        }
    
    def _save_resource_forecast(self, forecast: RealResourceDemandForecast):
        """Save resource forecast to database"""
        with self.SessionLocal() as session:
            session.execute(text("""
                INSERT INTO resource_forecasts (
                    service_id, resource_type, forecast_period_start, forecast_period_end,
                    predicted_demand, demand_confidence, peak_periods,
                    current_capacity, capacity_gap, recommended_capacity,
                    base_agents_needed, peak_agents_needed, confidence_score, demand_volatility
                ) VALUES (
                    :service_id, :resource_type, :period_start, :period_end,
                    :predicted_demand, :demand_confidence, :peak_periods,
                    :current_capacity, :capacity_gap, :recommended_capacity,
                    :base_agents, :peak_agents, :confidence_score, :volatility
                )
            """), {
                'service_id': forecast.service_id,
                'resource_type': forecast.resource_type.value,
                'period_start': forecast.forecast_period_start,
                'period_end': forecast.forecast_period_end,
                'predicted_demand': json.dumps(forecast.predicted_demand),
                'demand_confidence': json.dumps(forecast.demand_confidence),
                'peak_periods': json.dumps([{'start': p[0].isoformat(), 'end': p[1].isoformat(), 'demand': p[2]} for p in forecast.peak_periods]),
                'current_capacity': forecast.current_capacity,
                'capacity_gap': forecast.capacity_gap,
                'recommended_capacity': forecast.recommended_capacity,
                'base_agents': forecast.base_agents_needed,
                'peak_agents': forecast.peak_agents_needed,
                'confidence_score': forecast.confidence_score,
                'volatility': forecast.demand_volatility
            })
            
            session.commit()

if __name__ == "__main__":
    # Test the real resource demand forecaster
    forecaster = ResourceDemandForecasterReal()
    
    # Test resource demand forecasting
    service_id = 1
    try:
        forecast = forecaster.forecast_resource_demand_real(
            service_id=service_id,
            resource_type=ResourceType.AGENTS,
            forecast_horizon=ForecastHorizon.SHORT_TERM,
            target_utilization=0.85
        )
        
        print(f"Resource demand forecast for service {service_id}:")
        print(f"  Current capacity: {forecast.current_capacity}")
        print(f"  Capacity gap: {forecast.capacity_gap}")
        print(f"  Recommended capacity: {forecast.recommended_capacity}")
        print(f"  Base agents needed: {forecast.base_agents_needed}")
        print(f"  Peak agents needed: {forecast.peak_agents_needed}")
        print(f"  Confidence score: {forecast.confidence_score:.2f}")
        print(f"  Peak periods: {len(forecast.peak_periods)}")
        
    except Exception as e:
        print(f"Resource demand forecasting failed: {e}")
