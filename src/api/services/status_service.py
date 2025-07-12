from sqlalchemy.orm import Session
from sqlalchemy import and_, func
from datetime import datetime, timedelta
from typing import List, Optional, Dict, Any
import asyncio
import logging
from queue import Queue
from threading import Thread
import time

from ..db.models import AgentCurrentStatus, AgentStatusHistory, Agent
from ..core.database import get_db
from ..utils.validators import validate_agent_id, validate_status_code

logger = logging.getLogger(__name__)


class StatusService:
    """
    PHASE 1: Core Argus-Compatible Status Service
    
    Implements fire-and-forget pattern for status updates.
    Handles queue buffering for reliability and high-throughput scenarios (1000+ req/min).
    """
    
    def __init__(self, db: Session):
        self.db = db
        self.status_queue = Queue(maxsize=10000)  # Buffer for high-throughput
        self.processing_thread = None
        self.is_running = False
        self._start_background_processor()
    
    def _start_background_processor(self):
        """Start background thread for processing status updates."""
        if not self.is_running:
            self.is_running = True
            self.processing_thread = Thread(target=self._process_status_queue, daemon=True)
            self.processing_thread.start()
            logger.info("Status service background processor started")
    
    def _process_status_queue(self):
        """Background processor for status updates."""
        batch_size = 100
        batch_timeout = 5  # seconds
        current_batch = []
        last_process_time = time.time()
        
        while self.is_running:
            try:
                # Try to get an item from queue with timeout
                try:
                    item = self.status_queue.get(timeout=1)
                    current_batch.append(item)
                except:
                    # Queue empty, continue
                    pass
                
                # Process batch if it's full or timeout reached
                current_time = time.time()
                should_process = (
                    len(current_batch) >= batch_size or 
                    (current_batch and (current_time - last_process_time) >= batch_timeout)
                )
                
                if should_process and current_batch:
                    self._process_batch(current_batch)
                    current_batch = []
                    last_process_time = current_time
                
            except Exception as e:
                logger.error(f"Error in status queue processor: {str(e)}")
                time.sleep(1)  # Brief pause before retrying
    
    def _process_batch(self, batch: List[Dict[str, Any]]):
        """Process a batch of status updates."""
        try:
            # Get new database session for background processing
            with get_db() as db:
                success_count = 0
                error_count = 0
                
                for update in batch:
                    try:
                        self._process_single_update(db, update)
                        success_count += 1
                    except Exception as e:
                        error_count += 1
                        logger.error(f"Error processing status update: {str(e)}")
                
                # Commit batch
                db.commit()
                logger.info(f"Processed batch: {success_count} successful, {error_count} errors")
                
        except Exception as e:
            logger.error(f"Error processing status batch: {str(e)}")
    
    def _process_single_update(self, db: Session, update: Dict[str, Any]):
        """Process a single status update."""
        agent_id = update["agent_id"]
        new_state_code = update["state_code"]
        new_state_name = update["state_name"]
        timestamp = update["timestamp"]
        
        # Get current status
        current_status = db.query(AgentCurrentStatus).filter(
            AgentCurrentStatus.agent_id == agent_id
        ).first()
        
        if current_status:
            # Create history record for previous status
            if current_status.state_code != new_state_code:
                history_record = AgentStatusHistory(
                    agent_id=agent_id,
                    start_date=current_status.start_date,
                    end_date=timestamp,
                    state_code=current_status.state_code,
                    state_name=current_status.state_name
                )
                db.add(history_record)
            
            # Update current status
            current_status.state_code = new_state_code
            current_status.state_name = new_state_name
            current_status.start_date = timestamp
            current_status.updated_at = datetime.utcnow()
        else:
            # Create new current status
            new_status = AgentCurrentStatus(
                agent_id=agent_id,
                state_code=new_state_code,
                state_name=new_state_name,
                start_date=timestamp,
                updated_at=datetime.utcnow()
            )
            db.add(new_status)
    
    async def process_status_update(
        self, 
        agent_id: str, 
        state_code: str, 
        state_name: str,
        timestamp: Optional[datetime] = None
    ) -> Dict[str, Any]:
        """
        Process status update using fire-and-forget pattern.
        
        Args:
            agent_id: Agent identifier
            state_code: New status code
            state_name: New status name
            timestamp: Optional timestamp (defaults to now)
            
        Returns:
            Response indicating if update was queued
        """
        try:
            # Validate inputs
            if not validate_agent_id(agent_id):
                raise ValueError(f"Invalid agent_id: {agent_id}")
            
            if not validate_status_code(state_code):
                raise ValueError(f"Invalid state_code: {state_code}")
            
            if not timestamp:
                timestamp = datetime.utcnow()
            
            # Queue the update (fire-and-forget)
            update_data = {
                "agent_id": agent_id,
                "state_code": state_code,
                "state_name": state_name,
                "timestamp": timestamp
            }
            
            # Non-blocking queue add
            try:
                self.status_queue.put_nowait(update_data)
                return {
                    "status": "queued",
                    "message": "Status update queued for processing",
                    "agent_id": agent_id,
                    "state_code": state_code,
                    "queue_size": self.status_queue.qsize(),
                    "timestamp": datetime.utcnow().isoformat()
                }
            except:
                # Queue full, try to process some items immediately
                logger.warning("Status queue full, attempting immediate processing")
                return await self._process_immediate_update(agent_id, state_code, state_name, timestamp)
            
        except Exception as e:
            logger.error(f"Error queuing status update: {str(e)}")
            return {
                "status": "error",
                "message": str(e),
                "agent_id": agent_id,
                "timestamp": datetime.utcnow().isoformat()
            }
    
    async def _process_immediate_update(
        self, 
        agent_id: str, 
        state_code: str, 
        state_name: str,
        timestamp: datetime
    ) -> Dict[str, Any]:
        """Fallback immediate processing when queue is full."""
        try:
            update_data = {
                "agent_id": agent_id,
                "state_code": state_code,
                "state_name": state_name,
                "timestamp": timestamp
            }
            
            self._process_single_update(self.db, update_data)
            self.db.commit()
            
            return {
                "status": "processed",
                "message": "Status update processed immediately",
                "agent_id": agent_id,
                "state_code": state_code,
                "timestamp": datetime.utcnow().isoformat()
            }
            
        except Exception as e:
            logger.error(f"Error in immediate processing: {str(e)}")
            return {
                "status": "error",
                "message": str(e),
                "agent_id": agent_id,
                "timestamp": datetime.utcnow().isoformat()
            }
    
    async def bulk_status_update(self, updates: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        Process multiple status updates at once.
        
        Args:
            updates: List of status update dictionaries
            
        Returns:
            Bulk update response
        """
        try:
            queued_count = 0
            error_count = 0
            errors = []
            
            for update in updates:
                try:
                    # Validate and queue each update
                    agent_id = update.get("agent_id")
                    state_code = update.get("state_code")
                    state_name = update.get("state_name")
                    timestamp = update.get("timestamp")
                    
                    if not timestamp:
                        timestamp = datetime.utcnow()
                    elif isinstance(timestamp, str):
                        timestamp = datetime.fromisoformat(timestamp)
                    
                    # Validate
                    if not validate_agent_id(agent_id):
                        raise ValueError(f"Invalid agent_id: {agent_id}")
                    
                    if not validate_status_code(state_code):
                        raise ValueError(f"Invalid state_code: {state_code}")
                    
                    # Queue update
                    update_data = {
                        "agent_id": agent_id,
                        "state_code": state_code,
                        "state_name": state_name,
                        "timestamp": timestamp
                    }
                    
                    self.status_queue.put_nowait(update_data)
                    queued_count += 1
                    
                except Exception as e:
                    error_count += 1
                    errors.append(f"Update {update}: {str(e)}")
            
            return {
                "status": "bulk_queued",
                "message": f"Bulk status updates queued: {queued_count} successful, {error_count} errors",
                "queued_count": queued_count,
                "error_count": error_count,
                "errors": errors[:10],  # Limit error details
                "queue_size": self.status_queue.qsize(),
                "timestamp": datetime.utcnow().isoformat()
            }
            
        except Exception as e:
            logger.error(f"Error in bulk status update: {str(e)}")
            return {
                "status": "error",
                "message": str(e),
                "timestamp": datetime.utcnow().isoformat()
            }
    
    async def get_queue_status(self) -> Dict[str, Any]:
        """
        Get current status of the processing queue.
        
        Returns:
            Queue status information
        """
        try:
            return {
                "status": "success",
                "data": {
                    "queue_size": self.status_queue.qsize(),
                    "max_queue_size": self.status_queue.maxsize,
                    "queue_utilization": (self.status_queue.qsize() / self.status_queue.maxsize * 100),
                    "processor_running": self.is_running,
                    "processor_thread_alive": self.processing_thread.is_alive() if self.processing_thread else False
                },
                "timestamp": datetime.utcnow().isoformat()
            }
            
        except Exception as e:
            logger.error(f"Error getting queue status: {str(e)}")
            return {
                "status": "error",
                "message": str(e),
                "timestamp": datetime.utcnow().isoformat()
            }
    
    async def get_processing_stats(self) -> Dict[str, Any]:
        """
        Get processing statistics for monitoring.
        
        Returns:
            Processing statistics
        """
        try:
            # Get recent status updates count
            one_minute_ago = datetime.utcnow() - timedelta(minutes=1)
            recent_updates = self.db.query(AgentCurrentStatus).filter(
                AgentCurrentStatus.updated_at >= one_minute_ago
            ).count()
            
            # Get total active agents
            total_agents = self.db.query(AgentCurrentStatus).count()
            
            return {
                "status": "success",
                "data": {
                    "recent_updates_per_minute": recent_updates,
                    "total_active_agents": total_agents,
                    "current_queue_size": self.status_queue.qsize(),
                    "throughput_capacity": "1000+ req/min" if self.status_queue.maxsize >= 1000 else f"{self.status_queue.maxsize} req/buffer",
                    "processing_health": "HEALTHY" if self.is_running and self.status_queue.qsize() < self.status_queue.maxsize * 0.8 else "WARNING"
                },
                "timestamp": datetime.utcnow().isoformat()
            }
            
        except Exception as e:
            logger.error(f"Error getting processing stats: {str(e)}")
            return {
                "status": "error",
                "message": str(e),
                "timestamp": datetime.utcnow().isoformat()
            }
    
    def shutdown(self):
        """Gracefully shutdown the status service."""
        logger.info("Shutting down status service...")
        self.is_running = False
        
        # Process remaining items in queue
        remaining_items = []
        while not self.status_queue.empty():
            try:
                item = self.status_queue.get_nowait()
                remaining_items.append(item)
            except:
                break
        
        if remaining_items:
            logger.info(f"Processing {len(remaining_items)} remaining items...")
            self._process_batch(remaining_items)
        
        # Wait for thread to finish
        if self.processing_thread and self.processing_thread.is_alive():
            self.processing_thread.join(timeout=5)
        
        logger.info("Status service shutdown complete")