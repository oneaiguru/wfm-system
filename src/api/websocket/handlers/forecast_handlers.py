"""
Forecast Event Handlers
Handles forecast-related WebSocket events
"""

import logging
from typing import Dict, Any, Optional
from datetime import datetime, timedelta
from sqlalchemy.orm import Session

from .base import BaseEventHandler, EventPayload
from ..models.event_models import ForecastUpdatePayload, ForecastCalculatedPayload
from ...core.database import get_db
from ...services.forecasting_service import ForecastingService
from ...services.algorithm_service import AlgorithmService
from ...services.websocket import ws_manager, WebSocketEventType

logger = logging.getLogger(__name__)


class ForecastUpdatedHandler(BaseEventHandler):
    """Handler for FORECAST_UPDATED events"""
    
    def __init__(self):
        super().__init__('forecast.updated')
        self.forecasting_service = ForecastingService()
        self.algorithm_service = AlgorithmService()
    
    async def validate(self, payload: EventPayload) -> bool:
        """Validate forecast update payload"""
        try:
            # Validate required fields
            data = payload.data
            required_fields = ['forecast_id', 'interval_start', 'call_volume', 'aht']
            
            if not all(field in data for field in required_fields):
                logger.warning(f"Missing required fields in forecast update: {data}")
                return False
            
            # Validate data types and ranges
            forecast_payload = ForecastUpdatePayload(**data)
            
            # Business validation
            if forecast_payload.call_volume < 0:
                logger.warning(f"Invalid call_volume: {forecast_payload.call_volume}")
                return False
            
            if forecast_payload.aht < 0:
                logger.warning(f"Invalid aht: {forecast_payload.aht}")
                return False
            
            # Validate time is not too far in the past
            if forecast_payload.interval_start < datetime.utcnow() - timedelta(hours=24):
                logger.warning(f"Forecast interval too far in the past: {forecast_payload.interval_start}")
                return False
            
            return True
            
        except Exception as e:
            logger.error(f"Error validating forecast update payload: {str(e)}")
            return False
    
    async def handle(self, payload: EventPayload) -> Optional[Dict[str, Any]]:
        """Handle forecast update event"""
        try:
            # Parse payload
            forecast_data = ForecastUpdatePayload(**payload.data)
            
            # Get database session
            db = next(get_db())
            
            try:
                # Update forecast in database
                await self.forecasting_service.update_forecast(
                    db=db,
                    forecast_id=forecast_data.forecast_id,
                    interval_start=forecast_data.interval_start,
                    call_volume=forecast_data.call_volume,
                    aht=forecast_data.aht,
                    service_level=forecast_data.service_level,
                    metadata=forecast_data.metadata
                )
                
                # Trigger dependent calculations
                await self._trigger_dependent_calculations(db, forecast_data)
                
                # Emit notification event
                await ws_manager.emit_event(
                    WebSocketEventType.FORECAST_UPDATED,
                    {
                        'forecast_id': forecast_data.forecast_id,
                        'status': 'updated',
                        'timestamp': datetime.utcnow().isoformat()
                    }
                )
                
                logger.info(f"Successfully updated forecast {forecast_data.forecast_id}")
                
                return {
                    'status': 'success',
                    'forecast_id': forecast_data.forecast_id,
                    'updated_at': datetime.utcnow().isoformat()
                }
                
            finally:
                db.close()
                
        except Exception as e:
            logger.error(f"Error handling forecast update: {str(e)}")
            return {
                'status': 'error',
                'error': str(e)
            }
    
    async def _trigger_dependent_calculations(self, db: Session, forecast_data: ForecastUpdatePayload):
        """Trigger dependent calculations based on forecast update"""
        try:
            # Trigger staff requirement calculation
            await self.algorithm_service.calculate_staff_requirements(
                db=db,
                forecast_id=forecast_data.forecast_id,
                call_volume=forecast_data.call_volume,
                aht=forecast_data.aht,
                service_level=forecast_data.service_level or 0.8
            )
            
            # Trigger schedule optimization if needed
            await self.algorithm_service.trigger_schedule_optimization(
                db=db,
                forecast_id=forecast_data.forecast_id
            )
            
        except Exception as e:
            logger.warning(f"Error triggering dependent calculations: {str(e)}")


class ForecastCalculatedHandler(BaseEventHandler):
    """Handler for FORECAST_CALCULATED events"""
    
    def __init__(self):
        super().__init__('forecast.calculated')
        self.forecasting_service = ForecastingService()
    
    async def validate(self, payload: EventPayload) -> bool:
        """Validate forecast calculation payload"""
        try:
            data = payload.data
            required_fields = ['forecast_id', 'periods', 'accuracy']
            
            if not all(field in data for field in required_fields):
                logger.warning(f"Missing required fields in forecast calculation: {data}")
                return False
            
            # Validate with Pydantic model
            forecast_payload = ForecastCalculatedPayload(**data)
            
            # Business validation
            if not forecast_payload.periods:
                logger.warning("Empty periods in forecast calculation")
                return False
            
            if forecast_payload.accuracy < 0 or forecast_payload.accuracy > 100:
                logger.warning(f"Invalid accuracy: {forecast_payload.accuracy}")
                return False
            
            return True
            
        except Exception as e:
            logger.error(f"Error validating forecast calculation payload: {str(e)}")
            return False
    
    async def handle(self, payload: EventPayload) -> Optional[Dict[str, Any]]:
        """Handle forecast calculation event"""
        try:
            # Parse payload
            forecast_data = ForecastCalculatedPayload(**payload.data)
            
            # Get database session
            db = next(get_db())
            
            try:
                # Store forecast calculation results
                await self.forecasting_service.store_forecast_calculation(
                    db=db,
                    forecast_id=forecast_data.forecast_id,
                    periods=forecast_data.periods,
                    accuracy=forecast_data.accuracy,
                    algorithm_version=forecast_data.algorithm_version,
                    metadata=forecast_data.metadata
                )
                
                # Update forecast accuracy metrics
                await self.forecasting_service.update_accuracy_metrics(
                    db=db,
                    forecast_id=forecast_data.forecast_id,
                    accuracy=forecast_data.accuracy
                )
                
                # Trigger schedule recalculation if needed
                await self._trigger_schedule_recalculation(db, forecast_data)
                
                # Emit notification to UI
                await ws_manager.emit_event(
                    WebSocketEventType.FORECAST_CALCULATED,
                    {
                        'forecast_id': forecast_data.forecast_id,
                        'periods_count': len(forecast_data.periods),
                        'accuracy': forecast_data.accuracy,
                        'timestamp': datetime.utcnow().isoformat()
                    }
                )
                
                logger.info(f"Successfully processed forecast calculation {forecast_data.forecast_id}")
                
                return {
                    'status': 'success',
                    'forecast_id': forecast_data.forecast_id,
                    'periods_processed': len(forecast_data.periods),
                    'accuracy': forecast_data.accuracy
                }
                
            finally:
                db.close()
                
        except Exception as e:
            logger.error(f"Error handling forecast calculation: {str(e)}")
            return {
                'status': 'error',
                'error': str(e)
            }
    
    async def _trigger_schedule_recalculation(self, db: Session, forecast_data: ForecastCalculatedPayload):
        """Trigger schedule recalculation based on new forecast"""
        try:
            # Check if schedule needs recalculation based on forecast accuracy
            if forecast_data.accuracy >= 75:  # High accuracy threshold
                await self.algorithm_service.trigger_schedule_recalculation(
                    db=db,
                    forecast_id=forecast_data.forecast_id,
                    reason="high_accuracy_forecast"
                )
            else:
                logger.info(f"Forecast accuracy {forecast_data.accuracy}% below threshold, skipping schedule recalculation")
                
        except Exception as e:
            logger.warning(f"Error triggering schedule recalculation: {str(e)}")


class ForecastErrorHandler(BaseEventHandler):
    """Handler for FORECAST_ERROR events"""
    
    def __init__(self):
        super().__init__('forecast.error')
        self.forecasting_service = ForecastingService()
    
    async def validate(self, payload: EventPayload) -> bool:
        """Validate forecast error payload"""
        try:
            data = payload.data
            required_fields = ['forecast_id', 'error_type', 'error_message']
            
            if not all(field in data for field in required_fields):
                logger.warning(f"Missing required fields in forecast error: {data}")
                return False
            
            return True
            
        except Exception as e:
            logger.error(f"Error validating forecast error payload: {str(e)}")
            return False
    
    async def handle(self, payload: EventPayload) -> Optional[Dict[str, Any]]:
        """Handle forecast error event"""
        try:
            data = payload.data
            
            # Log error details
            logger.error(f"Forecast error for {data['forecast_id']}: {data['error_message']}")
            
            # Get database session
            db = next(get_db())
            
            try:
                # Record error in database
                await self.forecasting_service.record_forecast_error(
                    db=db,
                    forecast_id=data['forecast_id'],
                    error_type=data['error_type'],
                    error_message=data['error_message'],
                    error_details=data.get('error_details')
                )
                
                # Trigger fallback procedures
                await self._trigger_fallback_procedures(db, data)
                
                # Notify administrators
                await ws_manager.emit_event(
                    WebSocketEventType.FORECAST_ERROR,
                    {
                        'forecast_id': data['forecast_id'],
                        'error_type': data['error_type'],
                        'error_message': data['error_message'],
                        'timestamp': datetime.utcnow().isoformat()
                    },
                    room='administrators'
                )
                
                return {
                    'status': 'error_recorded',
                    'forecast_id': data['forecast_id'],
                    'error_type': data['error_type']
                }
                
            finally:
                db.close()
                
        except Exception as e:
            logger.error(f"Error handling forecast error: {str(e)}")
            return {
                'status': 'error',
                'error': str(e)
            }
    
    async def _trigger_fallback_procedures(self, db: Session, error_data: Dict[str, Any]):
        """Trigger fallback procedures when forecast fails"""
        try:
            # Use historical data as fallback
            await self.forecasting_service.use_historical_fallback(
                db=db,
                forecast_id=error_data['forecast_id']
            )
            
            logger.info(f"Triggered fallback procedures for forecast {error_data['forecast_id']}")
            
        except Exception as e:
            logger.warning(f"Error triggering fallback procedures: {str(e)}")


# Export handlers for registration
__all__ = [
    'ForecastUpdatedHandler',
    'ForecastCalculatedHandler', 
    'ForecastErrorHandler',
    'ForecastWebSocketHandler'
]


class ForecastWebSocketHandler:
    """WebSocket handler for forecast-related events - Static methods for compatibility."""
    
    @staticmethod
    async def notify_forecast_created(forecast_id):
        """Notify clients about forecast creation."""
        try:
            await ws_manager.emit_event(
                WebSocketEventType.FORECAST_UPDATED,
                {
                    "event": "forecast.created",
                    "forecast_id": str(forecast_id),
                    "timestamp": datetime.utcnow().isoformat()
                }
            )
            logger.info(f"WebSocket notification: forecast created {forecast_id}")
        except Exception as e:
            logger.error(f"Error notifying forecast creation: {str(e)}")
    
    @staticmethod
    async def notify_forecast_updated(forecast_id):
        """Notify clients about forecast updates."""
        try:
            await ws_manager.emit_event(
                WebSocketEventType.FORECAST_UPDATED,
                {
                    "event": "forecast.updated",
                    "forecast_id": str(forecast_id),
                    "timestamp": datetime.utcnow().isoformat()
                }
            )
            logger.info(f"WebSocket notification: forecast updated {forecast_id}")
        except Exception as e:
            logger.error(f"Error notifying forecast update: {str(e)}")
    
    @staticmethod
    async def notify_forecast_deleted(forecast_id):
        """Notify clients about forecast deletion."""
        try:
            await ws_manager.emit_event(
                WebSocketEventType.FORECAST_UPDATED,
                {
                    "event": "forecast.deleted",
                    "forecast_id": str(forecast_id),
                    "timestamp": datetime.utcnow().isoformat()
                }
            )
            logger.info(f"WebSocket notification: forecast deleted {forecast_id}")
        except Exception as e:
            logger.error(f"Error notifying forecast deletion: {str(e)}")
    
    @staticmethod
    async def notify_forecast_generation_started(forecast_id):
        """Notify clients that forecast generation has started."""
        try:
            await ws_manager.emit_event(
                WebSocketEventType.FORECAST_CALCULATED,
                {
                    "event": "forecast.generation.started",
                    "forecast_id": str(forecast_id),
                    "status": "generating",
                    "timestamp": datetime.utcnow().isoformat()
                }
            )
            logger.info(f"WebSocket notification: forecast generation started {forecast_id}")
        except Exception as e:
            logger.error(f"Error notifying forecast generation start: {str(e)}")
    
    @staticmethod
    async def notify_forecast_generation_completed(forecast_id, result):
        """Notify clients that forecast generation has completed."""
        try:
            await ws_manager.emit_event(
                WebSocketEventType.FORECAST_CALCULATED,
                {
                    "event": "forecast.generation.completed",
                    "forecast_id": str(forecast_id),
                    "status": "completed",
                    "result": result,
                    "timestamp": datetime.utcnow().isoformat()
                }
            )
            logger.info(f"WebSocket notification: forecast generation completed {forecast_id}")
        except Exception as e:
            logger.error(f"Error notifying forecast generation completion: {str(e)}")
    
    @staticmethod
    async def notify_staffing_calculation_started(staffing_plan_id):
        """Notify clients that staffing calculation has started."""
        try:
            await ws_manager.emit_event(
                WebSocketEventType.FORECAST_CALCULATED,
                {
                    "event": "staffing.calculation.started",
                    "staffing_plan_id": str(staffing_plan_id),
                    "status": "calculating",
                    "timestamp": datetime.utcnow().isoformat()
                }
            )
            logger.info(f"WebSocket notification: staffing calculation started {staffing_plan_id}")
        except Exception as e:
            logger.error(f"Error notifying staffing calculation start: {str(e)}")
    
    @staticmethod
    async def notify_model_training_started(model_id):
        """Notify clients that ML model training has started."""
        try:
            await ws_manager.emit_event(
                WebSocketEventType.FORECAST_CALCULATED,
                {
                    "event": "ml.training.started",
                    "model_id": str(model_id),
                    "status": "training",
                    "timestamp": datetime.utcnow().isoformat()
                }
            )
            logger.info(f"WebSocket notification: ML model training started {model_id}")
        except Exception as e:
            logger.error(f"Error notifying ML model training start: {str(e)}")
    
    @staticmethod
    async def notify_scenario_created(scenario_id):
        """Notify clients about scenario creation."""
        try:
            await ws_manager.emit_event(
                WebSocketEventType.FORECAST_UPDATED,
                {
                    "event": "scenario.created",
                    "scenario_id": str(scenario_id),
                    "timestamp": datetime.utcnow().isoformat()
                }
            )
            logger.info(f"WebSocket notification: scenario created {scenario_id}")
        except Exception as e:
            logger.error(f"Error notifying scenario creation: {str(e)}")