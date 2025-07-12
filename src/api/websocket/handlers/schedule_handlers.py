"""
Schedule Event Handlers
Handles schedule-related WebSocket events
"""

import logging
from typing import Dict, Any, Optional, List
from datetime import datetime, timedelta
from sqlalchemy.orm import Session

from .base import BaseEventHandler, EventPayload
from ..models.event_models import (
    ScheduleChangePayload, 
    ScheduleOptimizedPayload, 
    ShiftAssignedPayload,
    ScheduleChangeType,
    AssignmentType
)
from ...core.database import get_db
from ...services.algorithm_service import AlgorithmService
from ...services.websocket import ws_manager, WebSocketEventType
from ...db.models import Agent, Service, Group

logger = logging.getLogger(__name__)


class ScheduleChangedHandler(BaseEventHandler):
    """Handler for SCHEDULE_CHANGED events"""
    
    def __init__(self):
        super().__init__('schedule.changed')
        self.algorithm_service = AlgorithmService()
    
    async def validate(self, payload: EventPayload) -> bool:
        """Validate schedule change payload"""
        try:
            data = payload.data
            required_fields = ['schedule_id', 'agent_id', 'change_type']
            
            if not all(field in data for field in required_fields):
                logger.warning(f"Missing required fields in schedule change: {data}")
                return False
            
            # Validate with Pydantic model
            schedule_payload = ScheduleChangePayload(**data)
            
            # Business validation
            if schedule_payload.change_type in [ScheduleChangeType.SHIFT_ADDED, ScheduleChangeType.SHIFT_MODIFIED]:
                if not schedule_payload.new_shift:
                    logger.warning(f"new_shift required for {schedule_payload.change_type}")
                    return False
            
            return True
            
        except Exception as e:
            logger.error(f"Error validating schedule change payload: {str(e)}")
            return False
    
    async def handle(self, payload: EventPayload) -> Optional[Dict[str, Any]]:
        """Handle schedule change event"""
        try:
            # Parse payload
            schedule_data = ScheduleChangePayload(**payload.data)
            
            # Get database session
            db = next(get_db())
            
            try:
                # Validate agent exists
                agent = db.query(Agent).filter(Agent.id == schedule_data.agent_id).first()
                if not agent:
                    logger.warning(f"Agent {schedule_data.agent_id} not found")
                    return {'status': 'error', 'error': 'Agent not found'}
                
                # Update schedule in database
                await self._update_schedule_in_db(db, schedule_data)
                
                # Check for conflicts and compliance
                conflicts = await self._check_schedule_conflicts(db, schedule_data)
                if conflicts:
                    logger.warning(f"Schedule conflicts detected: {conflicts}")
                    # Still process but flag conflicts
                
                # Notify affected agents
                await self._notify_affected_agents(db, schedule_data)
                
                # Trigger dependent optimizations
                await self._trigger_dependent_optimizations(db, schedule_data)
                
                # Emit notification event
                await ws_manager.emit_event(
                    WebSocketEventType.SCHEDULE_CHANGED,
                    {
                        'schedule_id': schedule_data.schedule_id,
                        'agent_id': schedule_data.agent_id,
                        'change_type': schedule_data.change_type,
                        'conflicts': conflicts,
                        'timestamp': datetime.utcnow().isoformat()
                    }
                )
                
                logger.info(f"Successfully processed schedule change {schedule_data.schedule_id}")
                
                return {
                    'status': 'success',
                    'schedule_id': schedule_data.schedule_id,
                    'agent_id': schedule_data.agent_id,
                    'change_type': schedule_data.change_type,
                    'conflicts': conflicts
                }
                
            finally:
                db.close()
                
        except Exception as e:
            logger.error(f"Error handling schedule change: {str(e)}")
            return {
                'status': 'error',
                'error': str(e)
            }
    
    async def _update_schedule_in_db(self, db: Session, schedule_data: ScheduleChangePayload):
        """Update schedule in database"""
        try:
            # Implementation would depend on your schedule model
            # For now, we'll log the change
            logger.info(f"Updating schedule {schedule_data.schedule_id} for agent {schedule_data.agent_id}")
            
            # TODO: Implement actual database update based on your schedule model
            # This would involve:
            # 1. Creating/updating schedule records
            # 2. Updating agent shift assignments
            # 3. Recording change history
            
        except Exception as e:
            logger.error(f"Error updating schedule in database: {str(e)}")
            raise
    
    async def _check_schedule_conflicts(self, db: Session, schedule_data: ScheduleChangePayload) -> List[str]:
        """Check for schedule conflicts"""
        conflicts = []
        
        try:
            if schedule_data.new_shift:
                # Check for overlapping shifts
                # Check for skill conflicts
                # Check for compliance violations
                # TODO: Implement actual conflict detection
                pass
                
        except Exception as e:
            logger.warning(f"Error checking schedule conflicts: {str(e)}")
            
        return conflicts
    
    async def _notify_affected_agents(self, db: Session, schedule_data: ScheduleChangePayload):
        """Notify affected agents of schedule changes"""
        try:
            # Send notification to the specific agent
            await ws_manager.emit_event(
                WebSocketEventType.SCHEDULE_CHANGED,
                {
                    'type': 'personal_schedule_change',
                    'schedule_id': schedule_data.schedule_id,
                    'change_type': schedule_data.change_type,
                    'reason': schedule_data.reason,
                    'timestamp': datetime.utcnow().isoformat()
                },
                room=f'agent_{schedule_data.agent_id}'
            )
            
        except Exception as e:
            logger.warning(f"Error notifying affected agents: {str(e)}")
    
    async def _trigger_dependent_optimizations(self, db: Session, schedule_data: ScheduleChangePayload):
        """Trigger dependent schedule optimizations"""
        try:
            # Trigger optimization for affected time periods
            await self.algorithm_service.trigger_schedule_optimization(
                db=db,
                schedule_id=schedule_data.schedule_id,
                reason=f"schedule_change_{schedule_data.change_type}"
            )
            
        except Exception as e:
            logger.warning(f"Error triggering dependent optimizations: {str(e)}")


class ScheduleOptimizedHandler(BaseEventHandler):
    """Handler for SCHEDULE_OPTIMIZED events"""
    
    def __init__(self):
        super().__init__('schedule.optimized')
        self.algorithm_service = AlgorithmService()
    
    async def validate(self, payload: EventPayload) -> bool:
        """Validate schedule optimization payload"""
        try:
            data = payload.data
            required_fields = ['schedule_id', 'optimization_id', 'improvement_percentage', 'changes']
            
            if not all(field in data for field in required_fields):
                logger.warning(f"Missing required fields in schedule optimization: {data}")
                return False
            
            # Validate with Pydantic model
            optimization_payload = ScheduleOptimizedPayload(**data)
            
            # Business validation
            if optimization_payload.improvement_percentage < 0:
                logger.warning(f"Invalid improvement percentage: {optimization_payload.improvement_percentage}")
                return False
            
            return True
            
        except Exception as e:
            logger.error(f"Error validating schedule optimization payload: {str(e)}")
            return False
    
    async def handle(self, payload: EventPayload) -> Optional[Dict[str, Any]]:
        """Handle schedule optimization event"""
        try:
            # Parse payload
            optimization_data = ScheduleOptimizedPayload(**payload.data)
            
            # Get database session
            db = next(get_db())
            
            try:
                # Apply approved optimization changes
                applied_changes = await self._apply_optimization_changes(db, optimization_data)
                
                # Update schedule efficiency metrics
                await self._update_efficiency_metrics(db, optimization_data)
                
                # Notify managers of optimization results
                await self._notify_managers(db, optimization_data)
                
                # Generate optimization report
                report = await self._generate_optimization_report(db, optimization_data)
                
                # Emit notification event
                await ws_manager.emit_event(
                    WebSocketEventType.SCHEDULE_OPTIMIZED,
                    {
                        'schedule_id': optimization_data.schedule_id,
                        'optimization_id': optimization_data.optimization_id,
                        'improvement_percentage': optimization_data.improvement_percentage,
                        'changes_applied': len(applied_changes),
                        'timestamp': datetime.utcnow().isoformat()
                    }
                )
                
                logger.info(f"Successfully processed schedule optimization {optimization_data.optimization_id}")
                
                return {
                    'status': 'success',
                    'optimization_id': optimization_data.optimization_id,
                    'improvement_percentage': optimization_data.improvement_percentage,
                    'changes_applied': len(applied_changes),
                    'report': report
                }
                
            finally:
                db.close()
                
        except Exception as e:
            logger.error(f"Error handling schedule optimization: {str(e)}")
            return {
                'status': 'error',
                'error': str(e)
            }
    
    async def _apply_optimization_changes(self, db: Session, optimization_data: ScheduleOptimizedPayload) -> List[str]:
        """Apply approved optimization changes"""
        applied_changes = []
        
        try:
            for change in optimization_data.changes:
                # Apply each optimization change
                # TODO: Implement actual change application
                applied_changes.append(f"Applied {change.change_type} for agent {change.agent_id}")
                
        except Exception as e:
            logger.error(f"Error applying optimization changes: {str(e)}")
            
        return applied_changes
    
    async def _update_efficiency_metrics(self, db: Session, optimization_data: ScheduleOptimizedPayload):
        """Update schedule efficiency metrics"""
        try:
            # Update efficiency metrics in database
            # TODO: Implement actual metrics update
            pass
            
        except Exception as e:
            logger.warning(f"Error updating efficiency metrics: {str(e)}")
    
    async def _notify_managers(self, db: Session, optimization_data: ScheduleOptimizedPayload):
        """Notify managers of optimization results"""
        try:
            await ws_manager.emit_event(
                WebSocketEventType.SCHEDULE_OPTIMIZED,
                {
                    'type': 'optimization_complete',
                    'schedule_id': optimization_data.schedule_id,
                    'optimization_id': optimization_data.optimization_id,
                    'improvement_percentage': optimization_data.improvement_percentage,
                    'changes_count': len(optimization_data.changes),
                    'timestamp': datetime.utcnow().isoformat()
                },
                room='managers'
            )
            
        except Exception as e:
            logger.warning(f"Error notifying managers: {str(e)}")
    
    async def _generate_optimization_report(self, db: Session, optimization_data: ScheduleOptimizedPayload) -> Dict[str, Any]:
        """Generate optimization report"""
        try:
            return {
                'optimization_id': optimization_data.optimization_id,
                'improvement_percentage': optimization_data.improvement_percentage,
                'changes_summary': {
                    'total_changes': len(optimization_data.changes),
                    'agents_affected': len(set(change.agent_id for change in optimization_data.changes)),
                    'change_types': list(set(change.change_type for change in optimization_data.changes))
                },
                'metrics': optimization_data.metrics,
                'generated_at': datetime.utcnow().isoformat()
            }
            
        except Exception as e:
            logger.warning(f"Error generating optimization report: {str(e)}")
            return {}


class ShiftAssignedHandler(BaseEventHandler):
    """Handler for SHIFT_ASSIGNED events"""
    
    def __init__(self):
        super().__init__('shift.assigned')
        self.algorithm_service = AlgorithmService()
    
    async def validate(self, payload: EventPayload) -> bool:
        """Validate shift assignment payload"""
        try:
            data = payload.data
            required_fields = ['shift_id', 'agent_id', 'shift', 'assignment_type']
            
            if not all(field in data for field in required_fields):
                logger.warning(f"Missing required fields in shift assignment: {data}")
                return False
            
            # Validate with Pydantic model
            assignment_payload = ShiftAssignedPayload(**data)
            
            # Business validation
            if assignment_payload.priority is not None:
                if assignment_payload.priority < 1 or assignment_payload.priority > 5:
                    logger.warning(f"Invalid priority: {assignment_payload.priority}")
                    return False
            
            return True
            
        except Exception as e:
            logger.error(f"Error validating shift assignment payload: {str(e)}")
            return False
    
    async def handle(self, payload: EventPayload) -> Optional[Dict[str, Any]]:
        """Handle shift assignment event"""
        try:
            # Parse payload
            assignment_data = ShiftAssignedPayload(**payload.data)
            
            # Get database session
            db = next(get_db())
            
            try:
                # Validate agent exists and is available
                agent = db.query(Agent).filter(Agent.id == assignment_data.agent_id).first()
                if not agent:
                    logger.warning(f"Agent {assignment_data.agent_id} not found")
                    return {'status': 'error', 'error': 'Agent not found'}
                
                # Check for schedule conflicts
                conflicts = await self._check_assignment_conflicts(db, assignment_data)
                if conflicts:
                    logger.warning(f"Assignment conflicts detected: {conflicts}")
                    return {'status': 'conflict', 'conflicts': conflicts}
                
                # Update agent schedule in database
                await self._update_agent_schedule(db, assignment_data)
                
                # Notify agent of assignment
                await self._notify_agent(db, assignment_data)
                
                # Update capacity planning metrics
                await self._update_capacity_metrics(db, assignment_data)
                
                # Emit notification event
                await ws_manager.emit_event(
                    WebSocketEventType.SHIFT_ASSIGNED,
                    {
                        'shift_id': assignment_data.shift_id,
                        'agent_id': assignment_data.agent_id,
                        'assignment_type': assignment_data.assignment_type,
                        'shift_start': assignment_data.shift.start_time.isoformat(),
                        'shift_end': assignment_data.shift.end_time.isoformat(),
                        'timestamp': datetime.utcnow().isoformat()
                    }
                )
                
                logger.info(f"Successfully processed shift assignment {assignment_data.shift_id}")
                
                return {
                    'status': 'success',
                    'shift_id': assignment_data.shift_id,
                    'agent_id': assignment_data.agent_id,
                    'assignment_type': assignment_data.assignment_type
                }
                
            finally:
                db.close()
                
        except Exception as e:
            logger.error(f"Error handling shift assignment: {str(e)}")
            return {
                'status': 'error',
                'error': str(e)
            }
    
    async def _check_assignment_conflicts(self, db: Session, assignment_data: ShiftAssignedPayload) -> List[str]:
        """Check for assignment conflicts"""
        conflicts = []
        
        try:
            # Check for time conflicts
            # Check for skill requirements
            # Check for compliance rules
            # TODO: Implement actual conflict detection
            pass
            
        except Exception as e:
            logger.warning(f"Error checking assignment conflicts: {str(e)}")
            
        return conflicts
    
    async def _update_agent_schedule(self, db: Session, assignment_data: ShiftAssignedPayload):
        """Update agent schedule in database"""
        try:
            # TODO: Implement actual schedule update
            logger.info(f"Updating schedule for agent {assignment_data.agent_id} with shift {assignment_data.shift_id}")
            
        except Exception as e:
            logger.error(f"Error updating agent schedule: {str(e)}")
            raise
    
    async def _notify_agent(self, db: Session, assignment_data: ShiftAssignedPayload):
        """Notify agent of shift assignment"""
        try:
            await ws_manager.emit_event(
                WebSocketEventType.SHIFT_ASSIGNED,
                {
                    'type': 'personal_shift_assignment',
                    'shift_id': assignment_data.shift_id,
                    'shift_start': assignment_data.shift.start_time.isoformat(),
                    'shift_end': assignment_data.shift.end_time.isoformat(),
                    'skills': assignment_data.shift.skills,
                    'assignment_type': assignment_data.assignment_type,
                    'priority': assignment_data.priority,
                    'timestamp': datetime.utcnow().isoformat()
                },
                room=f'agent_{assignment_data.agent_id}'
            )
            
        except Exception as e:
            logger.warning(f"Error notifying agent: {str(e)}")
    
    async def _update_capacity_metrics(self, db: Session, assignment_data: ShiftAssignedPayload):
        """Update capacity planning metrics"""
        try:
            # Update capacity metrics based on new assignment
            # TODO: Implement actual metrics update
            pass
            
        except Exception as e:
            logger.warning(f"Error updating capacity metrics: {str(e)}")


# Export handlers for registration
__all__ = [
    'ScheduleChangedHandler',
    'ScheduleOptimizedHandler',
    'ShiftAssignedHandler'
]