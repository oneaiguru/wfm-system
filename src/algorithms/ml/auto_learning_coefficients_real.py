#!/usr/bin/env python3
"""
Auto-Learning Event Coefficients - REAL Database Implementation
Uses PostgreSQL forecasting tables (Schema 007-008) for all data operations
NO MOCK DATA - FAILS WITHOUT DATABASE CONNECTION
"""

import numpy as np
import pandas as pd
from datetime import datetime, timedelta
from typing import Dict, List, Tuple, Optional, Any
from dataclasses import dataclass, asdict
from enum import Enum
import json
from sqlalchemy import create_engine, text, MetaData, Table, Column, Integer, Float, String, DateTime, Boolean, JSON
from sqlalchemy.orm import sessionmaker
from sqlalchemy.sql import func
from sklearn.preprocessing import StandardScaler
from sklearn.ensemble import IsolationForest
from sklearn.cluster import DBSCAN
import logging
import os
import sys

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# CRITICAL: Database connection
DB_CONNECTION_STRING = os.getenv(
    'DATABASE_URL',
    'postgresql://postgres:postgres@localhost:5432/wfm_enterprise'
)

class EventType(Enum):
    """Types of events that can be learned"""
    HOLIDAY = "holiday"
    MARKETING = "marketing"
    TECHNICAL = "technical"
    WEATHER = "weather"
    SEASONAL = "seasonal"
    OUTLIER = "outlier"
    NORMAL = "normal"

class LearningAction(Enum):
    """Actions to take with detected events"""
    LEARN = "learn"
    EXCLUDE = "exclude"
    MONITOR = "monitor"
    INVESTIGATE = "investigate"

@dataclass
class EventCoefficient:
    """Learned event coefficient"""
    event_type: EventType
    date_pattern: str  # e.g., "12-25" for Christmas
    coefficient: float
    confidence: float
    occurrences: int
    last_seen: datetime
    description: str
    automatic: bool = True
    
@dataclass
class DetectedEvent:
    """Detected event with analysis"""
    date: datetime
    actual_value: float
    expected_value: float
    deviation_percent: float
    event_type: EventType
    confidence: float
    coefficient: float
    action: LearningAction
    description: str
    metadata: Dict[str, Any]

class AutoLearningCoefficientsReal:
    """
    Production-ready auto-learning coefficient system
    100% REAL DATABASE INTEGRATION - NO MOCK DATA
    """
    
    def __init__(self):
        """Initialize with real PostgreSQL connection"""
        try:
            self.engine = create_engine(DB_CONNECTION_STRING)
            self.SessionLocal = sessionmaker(bind=self.engine)
            self._validate_database_connection()
            self._ensure_tables_exist()
        except Exception as e:
            logger.error(f"Database connection failed: {e}")
            raise ConnectionError(f"Cannot operate without real database: {e}")
        
        self.scaler = StandardScaler()
        self.outlier_detector = IsolationForest(contamination=0.1, random_state=42)
        self.learned_coefficients: Dict[str, EventCoefficient] = {}
        self.detection_history: List[DetectedEvent] = []
        
        # Configuration
        self.config = {
            'outlier_threshold_moderate': 1.5,  # IQR multiplier
            'outlier_threshold_extreme': 3.0,   # IQR multiplier
            'min_occurrences_to_learn': 2,      # Minimum occurrences to create pattern
            'confidence_threshold': 0.7,        # Minimum confidence to apply
            'max_coefficient': 5.0,             # Maximum coefficient value
            'min_coefficient': 0.1,             # Minimum coefficient value
            'learning_rate': 0.1,               # How fast to adapt coefficients
        }
        
        # Load existing coefficients from database
        self._load_coefficients()
    
    def _validate_database_connection(self):
        """Ensure we can connect to real database - FAIL if no connection"""
        try:
            with self.SessionLocal() as session:
                result = session.execute(text("SELECT 1")).fetchone()
                if not result:
                    raise ConnectionError("Database connection failed")
                
                # Verify forecasting tables exist
                tables_check = session.execute(text("""
                    SELECT COUNT(*) FROM information_schema.tables 
                    WHERE table_name IN ('forecast_models', 'forecast_calculations', 'historical_data')
                """)).scalar()
                
                if tables_check < 3:
                    raise ConnectionError("Required forecasting tables not found - need Schema 007-008")
                    
                logger.info("Database connection validated - forecasting tables available")
        except Exception as e:
            raise ConnectionError(f"Cannot operate without real database: {e}")
    
    def _ensure_tables_exist(self):
        """Create coefficient and event tables if needed"""
        with self.SessionLocal() as session:
            # Create event_coefficients table
            session.execute(text("""
                CREATE TABLE IF NOT EXISTS event_coefficients (
                    id SERIAL PRIMARY KEY,
                    event_type VARCHAR(50) NOT NULL,
                    date_pattern VARCHAR(50) NOT NULL,
                    coefficient FLOAT NOT NULL,
                    confidence FLOAT NOT NULL,
                    occurrences INTEGER NOT NULL,
                    last_seen TIMESTAMP NOT NULL,
                    description TEXT,
                    automatic BOOLEAN DEFAULT TRUE,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    UNIQUE(event_type, date_pattern)
                )
            """))
            
            # Create detected_events table
            session.execute(text("""
                CREATE TABLE IF NOT EXISTS detected_events (
                    id SERIAL PRIMARY KEY,
                    date TIMESTAMP NOT NULL,
                    actual_value FLOAT NOT NULL,
                    expected_value FLOAT NOT NULL,
                    deviation_percent FLOAT NOT NULL,
                    event_type VARCHAR(50) NOT NULL,
                    confidence FLOAT NOT NULL,
                    coefficient FLOAT NOT NULL,
                    action VARCHAR(50) NOT NULL,
                    description TEXT,
                    metadata JSONB,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """))
            
            # Create index for performance
            session.execute(text("""
                CREATE INDEX IF NOT EXISTS idx_detected_events_date 
                ON detected_events(date)
            """))
            
            session.commit()
            logger.info("Event coefficient tables created/verified")
    
    def _load_coefficients(self):
        """Load existing coefficients from database"""
        with self.SessionLocal() as session:
            result = session.execute(text("""
                SELECT event_type, date_pattern, coefficient, confidence, 
                       occurrences, last_seen, description, automatic
                FROM event_coefficients
                ORDER BY confidence DESC
            """))
            
            for row in result:
                key = f"{row.event_type}_{row.date_pattern}"
                self.learned_coefficients[key] = EventCoefficient(
                    event_type=EventType(row.event_type),
                    date_pattern=row.date_pattern,
                    coefficient=row.coefficient,
                    confidence=row.confidence,
                    occurrences=row.occurrences,
                    last_seen=row.last_seen,
                    description=row.description,
                    automatic=row.automatic
                )
            
            logger.info(f"Loaded {len(self.learned_coefficients)} coefficients from database")
    
    def analyze_historical_data(self, service_id: int, 
                              start_date: Optional[datetime] = None,
                              end_date: Optional[datetime] = None) -> List[DetectedEvent]:
        """
        Analyze real historical data from database for anomalies
        Uses forecast_calculations and historical_data tables
        """
        if not start_date:
            start_date = datetime.now() - timedelta(days=365)
        if not end_date:
            end_date = datetime.now()
        
        with self.SessionLocal() as session:
            # Get historical data from real tables
            result = session.execute(text("""
                SELECT 
                    date_trunc('day', interval_start_time) as date,
                    SUM(contact_volume) as actual_value,
                    AVG(service_level) as sl_actual
                FROM contact_statistics
                WHERE service_id = :service_id
                    AND interval_start_time >= :start_date
                    AND interval_start_time <= :end_date
                GROUP BY date_trunc('day', interval_start_time)
                ORDER BY date
            """), {
                'service_id': service_id,
                'start_date': start_date,
                'end_date': end_date
            })
            
            data = pd.DataFrame(result.fetchall(), columns=['date', 'actual_value', 'sl_actual'])
            
            if data.empty:
                logger.warning(f"No historical data found for service {service_id}")
                return []
            
            # Calculate outlier thresholds using real data
            Q1 = data['actual_value'].quantile(0.25)
            Q3 = data['actual_value'].quantile(0.75)
            IQR = Q3 - Q1
            
            moderate_threshold = Q3 + (IQR * self.config['outlier_threshold_moderate'])
            extreme_threshold = Q3 + (IQR * self.config['outlier_threshold_extreme'])
            
            detected_events = []
            
            for idx, row in data.iterrows():
                date = row['date']
                value = row['actual_value']
                
                # Calculate expected value from historical patterns
                expected = self._calculate_expected_value_real(service_id, date, session)
                
                if expected == 0:
                    continue
                
                deviation = abs(value - expected) / expected
                
                # Detect event type and determine action
                event = self._classify_event(date, value, expected, deviation, 
                                           moderate_threshold, extreme_threshold)
                
                if event:
                    detected_events.append(event)
                    self._save_detected_event(event, session)
            
            session.commit()
            logger.info(f"Detected {len(detected_events)} events from real data")
            return detected_events
    
    def _calculate_expected_value_real(self, service_id: int, date: datetime, session) -> float:
        """Calculate expected value from real database patterns"""
        # Get similar dates from history (same month/day from previous years)
        result = session.execute(text("""
            SELECT AVG(contact_volume) as avg_volume
            FROM (
                SELECT SUM(contact_volume) as contact_volume
                FROM contact_statistics
                WHERE service_id = :service_id
                    AND EXTRACT(MONTH FROM interval_start_time) = :month
                    AND EXTRACT(DAY FROM interval_start_time) = :day
                    AND EXTRACT(YEAR FROM interval_start_time) < :year
                GROUP BY date_trunc('day', interval_start_time)
            ) daily_volumes
        """), {
            'service_id': service_id,
            'month': date.month,
            'day': date.day,
            'year': date.year
        })
        
        base_value = result.scalar()
        
        if not base_value:
            # Fall back to day-of-week average
            result = session.execute(text("""
                SELECT AVG(contact_volume) as avg_volume
                FROM (
                    SELECT SUM(contact_volume) as contact_volume
                    FROM contact_statistics
                    WHERE service_id = :service_id
                        AND EXTRACT(DOW FROM interval_start_time) = :dow
                    GROUP BY date_trunc('day', interval_start_time)
                ) daily_volumes
            """), {
                'service_id': service_id,
                'dow': date.weekday()
            })
            
            base_value = result.scalar() or 0
        
        # Apply real seasonal adjustments from database
        seasonal_factor = self._get_seasonal_factor_real(service_id, date, session)
        
        return float(base_value * seasonal_factor) if base_value else 0
    
    def _get_seasonal_factor_real(self, service_id: int, date: datetime, session) -> float:
        """Get seasonal adjustment factor from real historical patterns"""
        # Calculate day-of-week factor from real data
        dow_result = session.execute(text("""
            SELECT 
                EXTRACT(DOW FROM interval_start_time) as dow,
                AVG(contact_volume) as avg_volume
            FROM contact_statistics
            WHERE service_id = :service_id
            GROUP BY EXTRACT(DOW FROM interval_start_time)
        """), {'service_id': service_id})
        
        dow_data = {int(row.dow): row.avg_volume for row in dow_result}
        overall_avg = sum(dow_data.values()) / len(dow_data) if dow_data else 1
        
        current_dow_avg = dow_data.get(date.weekday(), overall_avg)
        dow_factor = current_dow_avg / overall_avg if overall_avg > 0 else 1.0
        
        # Calculate month factor from real data
        month_result = session.execute(text("""
            SELECT 
                EXTRACT(MONTH FROM interval_start_time) as month,
                AVG(contact_volume) as avg_volume
            FROM contact_statistics
            WHERE service_id = :service_id
            GROUP BY EXTRACT(MONTH FROM interval_start_time)
        """), {'service_id': service_id})
        
        month_data = {int(row.month): row.avg_volume for row in month_result}
        month_avg = sum(month_data.values()) / len(month_data) if month_data else overall_avg
        
        current_month_avg = month_data.get(date.month, month_avg)
        month_factor = current_month_avg / month_avg if month_avg > 0 else 1.0
        
        return dow_factor * month_factor
    
    def _classify_event(self, date: datetime, value: float, expected: float, 
                       deviation: float, moderate_threshold: float, 
                       extreme_threshold: float) -> Optional[DetectedEvent]:
        """Classify detected event and determine action"""
        
        if value < moderate_threshold and deviation < 0.3:
            return None  # Normal variation
        
        # Determine event type based on date patterns and magnitude
        event_type = self._determine_event_type(date, value, expected)
        
        # Calculate coefficient
        coefficient = value / expected if expected > 0 else 1.0
        coefficient = max(self.config['min_coefficient'], 
                         min(self.config['max_coefficient'], coefficient))
        
        # Determine confidence based on historical consistency
        confidence = self._calculate_confidence_real(date, value, expected, event_type)
        
        # Determine action
        action = self._determine_action(event_type, deviation, confidence, value, extreme_threshold)
        
        description = self._generate_event_description(event_type, date, value, expected, deviation)
        
        return DetectedEvent(
            date=date,
            actual_value=value,
            expected_value=expected,
            deviation_percent=deviation * 100,
            event_type=event_type,
            confidence=confidence,
            coefficient=coefficient,
            action=action,
            description=description,
            metadata={
                'moderate_threshold': moderate_threshold,
                'extreme_threshold': extreme_threshold,
                'deviation': deviation
            }
        )
    
    def _determine_event_type(self, date: datetime, value: float, expected: float) -> EventType:
        """Determine the type of event based on date patterns"""
        # Known holidays
        if date.month == 12 and date.day == 25:
            return EventType.HOLIDAY
        elif date.month == 1 and date.day == 1:
            return EventType.HOLIDAY
        elif date.month == 7 and date.day == 4:
            return EventType.HOLIDAY
        
        # Extreme deviations
        if expected > 0:
            ratio = value / expected
            if ratio > 3.0 or ratio < 0.3:
                return EventType.OUTLIER
        
        # Seasonal patterns
        if date.month in [11, 12]:
            return EventType.SEASONAL
        elif date.month in [7, 8]:
            return EventType.SEASONAL
        
        return EventType.NORMAL
    
    def _calculate_confidence_real(self, date: datetime, value: float, 
                                  expected: float, event_type: EventType) -> float:
        """Calculate confidence based on real historical data"""
        with self.SessionLocal() as session:
            # Check how many times we've seen similar patterns
            pattern_count = session.execute(text("""
                SELECT COUNT(*) 
                FROM detected_events
                WHERE event_type = :event_type
                    AND EXTRACT(MONTH FROM date) = :month
                    AND EXTRACT(DAY FROM date) = :day
            """), {
                'event_type': event_type.value,
                'month': date.month,
                'day': date.day
            }).scalar()
            
            # Base confidence on occurrences
            if pattern_count >= 3:
                confidence = 0.9
            elif pattern_count >= 2:
                confidence = 0.7
            else:
                confidence = 0.5
            
            # Adjust based on deviation magnitude
            if expected > 0:
                deviation = abs(value - expected) / expected
                if deviation > 2.0:
                    confidence *= 0.8  # Lower confidence for extreme deviations
            
            return min(confidence, 0.95)
    
    def _determine_action(self, event_type: EventType, deviation: float, 
                         confidence: float, value: float, extreme_threshold: float) -> LearningAction:
        """Determine what action to take with the event"""
        if value > extreme_threshold and event_type == EventType.OUTLIER:
            return LearningAction.EXCLUDE
        elif confidence >= self.config['confidence_threshold']:
            return LearningAction.LEARN
        elif deviation > 0.5:
            return LearningAction.INVESTIGATE
        else:
            return LearningAction.MONITOR
    
    def _generate_event_description(self, event_type: EventType, date: datetime, 
                                   value: float, expected: float, deviation: float) -> str:
        """Generate human-readable event description"""
        if event_type == EventType.HOLIDAY:
            return f"Holiday pattern detected on {date.strftime('%B %d')}"
        elif event_type == EventType.OUTLIER:
            direction = "spike" if value > expected else "drop"
            return f"Extreme {direction} ({deviation:.0%} deviation)"
        elif event_type == EventType.SEASONAL:
            season = "winter" if date.month in [11, 12, 1, 2] else "summer"
            return f"Seasonal {season} pattern"
        else:
            return f"Pattern deviation of {deviation:.0%}"
    
    def _save_detected_event(self, event: DetectedEvent, session):
        """Save detected event to database"""
        session.execute(text("""
            INSERT INTO detected_events 
            (date, actual_value, expected_value, deviation_percent, event_type, 
             confidence, coefficient, action, description, metadata)
            VALUES (:date, :actual, :expected, :deviation, :type, 
                    :confidence, :coefficient, :action, :description, :metadata)
        """), {
            'date': event.date,
            'actual': event.actual_value,
            'expected': event.expected_value,
            'deviation': event.deviation_percent,
            'type': event.event_type.value,
            'confidence': event.confidence,
            'coefficient': event.coefficient,
            'action': event.action.value,
            'description': event.description,
            'metadata': json.dumps(event.metadata)
        })
    
    def learn_from_events(self, events: List[DetectedEvent]) -> int:
        """Learn coefficients from detected events"""
        learned_count = 0
        
        with self.SessionLocal() as session:
            for event in events:
                if event.action != LearningAction.LEARN:
                    continue
                
                date_pattern = f"{event.date.month:02d}-{event.date.day:02d}"
                key = f"{event.event_type.value}_{date_pattern}"
                
                if key in self.learned_coefficients:
                    # Update existing coefficient
                    existing = self.learned_coefficients[key]
                    # Weighted average with learning rate
                    new_coefficient = (existing.coefficient * (1 - self.config['learning_rate']) + 
                                     event.coefficient * self.config['learning_rate'])
                    
                    session.execute(text("""
                        UPDATE event_coefficients
                        SET coefficient = :coefficient,
                            confidence = :confidence,
                            occurrences = occurrences + 1,
                            last_seen = :last_seen,
                            updated_at = CURRENT_TIMESTAMP
                        WHERE event_type = :event_type AND date_pattern = :date_pattern
                    """), {
                        'coefficient': new_coefficient,
                        'confidence': event.confidence,
                        'last_seen': event.date,
                        'event_type': event.event_type.value,
                        'date_pattern': date_pattern
                    })
                    
                    existing.coefficient = new_coefficient
                    existing.confidence = event.confidence
                    existing.occurrences += 1
                    existing.last_seen = event.date
                else:
                    # Create new coefficient
                    session.execute(text("""
                        INSERT INTO event_coefficients
                        (event_type, date_pattern, coefficient, confidence, 
                         occurrences, last_seen, description)
                        VALUES (:event_type, :date_pattern, :coefficient, :confidence,
                                1, :last_seen, :description)
                    """), {
                        'event_type': event.event_type.value,
                        'date_pattern': date_pattern,
                        'coefficient': event.coefficient,
                        'confidence': event.confidence,
                        'last_seen': event.date,
                        'description': event.description
                    })
                    
                    self.learned_coefficients[key] = EventCoefficient(
                        event_type=event.event_type,
                        date_pattern=date_pattern,
                        coefficient=event.coefficient,
                        confidence=event.confidence,
                        occurrences=1,
                        last_seen=event.date,
                        description=event.description
                    )
                
                learned_count += 1
            
            session.commit()
        
        logger.info(f"Learned {learned_count} coefficients from events")
        return learned_count
    
    def apply_coefficients_to_forecast(self, service_id: int, 
                                     forecast_start: datetime,
                                     forecast_end: datetime) -> pd.DataFrame:
        """Apply learned coefficients to real forecast data"""
        with self.SessionLocal() as session:
            # Get base forecast from forecast_models table
            result = session.execute(text("""
                SELECT 
                    fc.forecast_date,
                    fc.base_value,
                    fc.confidence_interval_lower,
                    fc.confidence_interval_upper,
                    fm.model_type
                FROM forecast_calculations fc
                JOIN forecast_models fm ON fc.model_id = fm.id
                WHERE fm.service_id = :service_id
                    AND fc.forecast_date >= :start_date
                    AND fc.forecast_date <= :end_date
                ORDER BY fc.forecast_date
            """), {
                'service_id': service_id,
                'start_date': forecast_start,
                'end_date': forecast_end
            })
            
            forecast_data = pd.DataFrame(result.fetchall(), 
                                       columns=['date', 'base_value', 'ci_lower', 'ci_upper', 'model_type'])
            
            if forecast_data.empty:
                logger.warning(f"No forecast data found for service {service_id}")
                return pd.DataFrame()
            
            # Apply learned coefficients
            adjusted_values = []
            
            for idx, row in forecast_data.iterrows():
                date = row['date']
                base_value = row['base_value']
                
                # Check for applicable coefficients
                applied_coefficient = 1.0
                applied_description = "No special events"
                
                for key, coef in self.learned_coefficients.items():
                    if coef.confidence < self.config['confidence_threshold']:
                        continue
                    
                    # Check if date matches pattern
                    date_pattern = f"{date.month:02d}-{date.day:02d}"
                    if coef.date_pattern == date_pattern:
                        applied_coefficient *= coef.coefficient
                        applied_description = coef.description
                        break
                
                adjusted_value = base_value * applied_coefficient
                
                # Save adjustment to database
                session.execute(text("""
                    INSERT INTO forecast_adjustments
                    (service_id, forecast_date, original_value, adjusted_value, 
                     coefficient_applied, adjustment_reason)
                    VALUES (:service_id, :date, :original, :adjusted, 
                            :coefficient, :reason)
                    ON CONFLICT (service_id, forecast_date) DO UPDATE
                    SET adjusted_value = :adjusted,
                        coefficient_applied = :coefficient,
                        adjustment_reason = :reason,
                        updated_at = CURRENT_TIMESTAMP
                """), {
                    'service_id': service_id,
                    'date': date,
                    'original': base_value,
                    'adjusted': adjusted_value,
                    'coefficient': applied_coefficient,
                    'reason': applied_description
                })
                
                adjusted_values.append({
                    'date': date,
                    'original_value': base_value,
                    'adjusted_value': adjusted_value,
                    'coefficient': applied_coefficient,
                    'description': applied_description
                })
            
            session.commit()
            
            return pd.DataFrame(adjusted_values)
    
    def get_learning_summary(self) -> Dict[str, Any]:
        """Get comprehensive summary of learned patterns"""
        with self.SessionLocal() as session:
            # Total coefficients by type
            type_counts = session.execute(text("""
                SELECT event_type, COUNT(*) as count
                FROM event_coefficients
                GROUP BY event_type
            """)).fetchall()
            
            # Recent events
            recent_events = session.execute(text("""
                SELECT date, event_type, description, confidence, coefficient
                FROM detected_events
                ORDER BY date DESC
                LIMIT 10
            """)).fetchall()
            
            # Accuracy stats
            accuracy_stats = session.execute(text("""
                SELECT 
                    AVG(ABS(deviation_percent)) as avg_deviation,
                    MIN(ABS(deviation_percent)) as min_deviation,
                    MAX(ABS(deviation_percent)) as max_deviation,
                    COUNT(*) as total_events
                FROM detected_events
                WHERE action = 'learn'
            """)).fetchone()
            
            return {
                'total_coefficients': len(self.learned_coefficients),
                'coefficients_by_type': {row.event_type: row.count for row in type_counts},
                'recent_events': [
                    {
                        'date': row.date.strftime('%Y-%m-%d'),
                        'type': row.event_type,
                        'description': row.description,
                        'confidence': row.confidence,
                        'coefficient': row.coefficient
                    }
                    for row in recent_events
                ],
                'accuracy_stats': {
                    'avg_deviation': accuracy_stats.avg_deviation or 0,
                    'min_deviation': accuracy_stats.min_deviation or 0,
                    'max_deviation': accuracy_stats.max_deviation or 0,
                    'accuracy': 1 - (accuracy_stats.avg_deviation or 0) / 100
                },
                'total_events_analyzed': accuracy_stats.total_events or 0
            }

# Test functionality
if __name__ == "__main__":
    try:
        # Initialize the real learning system
        learner = AutoLearningCoefficientsReal()
        
        print("🚀 Auto-Learning Coefficients - REAL Database Implementation")
        print("=" * 50)
        
        # Analyze real historical data for service 1
        service_id = 1
        events = learner.analyze_historical_data(
            service_id=service_id,
            start_date=datetime.now() - timedelta(days=365),
            end_date=datetime.now()
        )
        
        print(f"✅ Analyzed real historical data from database")
        print(f"📊 Found {len(events)} events to learn from")
        
        # Learn from events
        learned = learner.learn_from_events(events)
        print(f"🧠 Learned {learned} new coefficient patterns")
        
        # Apply to future forecast
        forecast_start = datetime.now()
        forecast_end = datetime.now() + timedelta(days=90)
        
        adjusted_forecast = learner.apply_coefficients_to_forecast(
            service_id=service_id,
            forecast_start=forecast_start,
            forecast_end=forecast_end
        )
        
        if not adjusted_forecast.empty:
            print(f"📈 Applied coefficients to {len(adjusted_forecast)} forecast days")
        
        # Get summary
        summary = learner.get_learning_summary()
        print(f"\n📊 Learning Summary:")
        print(f"Total coefficients: {summary['total_coefficients']}")
        print(f"Events analyzed: {summary['total_events_analyzed']}")
        print(f"Accuracy: {summary['accuracy_stats']['accuracy']:.1%}")
        
    except ConnectionError as e:
        print(f"❌ ERROR: {e}")
        print("This algorithm requires a real PostgreSQL database connection!")
        sys.exit(1)