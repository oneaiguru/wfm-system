#!/usr/bin/env python3
"""
Notification Engine for Monthly Intraday Activity Planning
BDD File: 10-monthly-intraday-activity-planning.feature
Scenarios: Event/Schedule Notifications, System-Wide Settings
"""

import asyncio
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any, Set, Tuple
from dataclasses import dataclass, field
from enum import Enum
import logging
from collections import defaultdict
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

logger = logging.getLogger(__name__)

class NotificationType(Enum):
    """Types of notifications"""
    BREAK_REMINDER = "break_reminder"
    LUNCH_REMINDER = "lunch_reminder"
    MEETING_REMINDER = "meeting_reminder"
    TRAINING_START = "training_start"
    SCHEDULE_CHANGE = "schedule_change"
    SHIFT_START = "shift_start"
    SYSTEM_ALERT = "system_alert"

class NotificationMethod(Enum):
    """Notification delivery methods"""
    EMAIL = "email"
    SYSTEM = "system"
    MOBILE = "mobile"
    SMS = "sms"
    WEBHOOK = "webhook"

class NotificationPriority(Enum):
    """Notification priority levels"""
    CRITICAL = "critical"
    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"

@dataclass
class NotificationConfig:
    """Configuration for specific notification type"""
    event_type: NotificationType
    recipients: str  # Individual Employee, Participants, etc.
    methods: List[NotificationMethod]
    timing_minutes: int  # Minutes before event
    enabled: bool = True
    quiet_hours_respected: bool = True

@dataclass
class SystemNotificationSettings:
    """System-wide notification configuration"""
    email_server: str
    sms_gateway: str
    mobile_push_service: str
    retention_days: int
    max_retry_attempts: int
    quiet_hours_start: str
    quiet_hours_end: str
    escalation_enabled: bool = True

@dataclass
class Notification:
    """Individual notification instance"""
    notification_id: str
    event_type: NotificationType
    recipient_id: str
    recipient_email: Optional[str]
    recipient_phone: Optional[str]
    scheduled_time: datetime
    event_time: datetime
    methods: List[NotificationMethod]
    content: Dict[str, str]
    priority: NotificationPriority
    attempts: int = 0
    sent: bool = False
    sent_time: Optional[datetime] = None
    error_message: Optional[str] = None

@dataclass
class NotificationHistory:
    """Notification history for compliance tracking"""
    notification_id: str
    event_type: NotificationType
    recipient_id: str
    scheduled_time: datetime
    sent_time: Optional[datetime]
    delivery_status: str
    delivery_method: NotificationMethod
    attempts: int
    error_details: Optional[str] = None

class NotificationEngine:
    """Core notification engine for event and schedule reminders"""
    
    def __init__(self):
        self.notification_configs: Dict[NotificationType, NotificationConfig] = {}
        self.system_settings: Optional[SystemNotificationSettings] = None
        self.pending_notifications: List[Notification] = []
        self.notification_history: List[NotificationHistory] = []
        self.delivery_handlers: Dict[NotificationMethod, Any] = {}
        self._initialize_default_configs()
        
    def _initialize_default_configs(self):
        """Initialize default notification configurations from BDD"""
        # From BDD Scenario: Configure Event and Schedule Notifications
        default_configs = [
            NotificationConfig(
                event_type=NotificationType.BREAK_REMINDER,
                recipients="Individual Employee",
                methods=[NotificationMethod.SYSTEM, NotificationMethod.MOBILE],
                timing_minutes=5
            ),
            NotificationConfig(
                event_type=NotificationType.LUNCH_REMINDER,
                recipients="Individual Employee",
                methods=[NotificationMethod.SYSTEM, NotificationMethod.MOBILE],
                timing_minutes=10
            ),
            NotificationConfig(
                event_type=NotificationType.MEETING_REMINDER,
                recipients="Participants",
                methods=[NotificationMethod.EMAIL, NotificationMethod.SYSTEM],
                timing_minutes=15
            ),
            NotificationConfig(
                event_type=NotificationType.TRAINING_START,
                recipients="Trainees + Instructor",
                methods=[NotificationMethod.SYSTEM],
                timing_minutes=30
            ),
            NotificationConfig(
                event_type=NotificationType.SCHEDULE_CHANGE,
                recipients="Affected Employees",
                methods=[NotificationMethod.EMAIL, NotificationMethod.SYSTEM],
                timing_minutes=0  # Immediate
            ),
            NotificationConfig(
                event_type=NotificationType.SHIFT_START,
                recipients="Individual Employee",
                methods=[NotificationMethod.MOBILE],
                timing_minutes=30
            )
        ]
        
        for config in default_configs:
            self.notification_configs[config.event_type] = config
    
    def configure_system_settings(self, settings: SystemNotificationSettings) -> bool:
        """Configure system-wide notification settings"""
        try:
            # Validate settings
            if not self._validate_system_settings(settings):
                return False
            
            self.system_settings = settings
            
            # Initialize delivery handlers
            self._initialize_delivery_handlers()
            
            # Test delivery methods
            if not self._test_delivery_methods():
                logger.warning("Some delivery methods failed testing")
            
            return True
            
        except Exception as e:
            logger.error(f"Failed to configure system settings: {str(e)}")
            return False
    
    def configure_notification(self, config: NotificationConfig) -> bool:
        """Configure notification settings for specific event type"""
        try:
            # Validate configuration
            if not self._validate_notification_config(config):
                return False
            
            # Save configuration
            self.notification_configs[config.event_type] = config
            
            logger.info(f"Configured notification for {config.event_type.value}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to configure notification: {str(e)}")
            return False
    
    def schedule_notification(self,
                            event_type: NotificationType,
                            event_time: datetime,
                            recipient_ids: List[str],
                            event_details: Dict[str, Any]) -> List[str]:
        """Schedule notifications for an event"""
        notification_ids = []
        
        config = self.notification_configs.get(event_type)
        if not config or not config.enabled:
            return notification_ids
        
        # Calculate scheduled time
        scheduled_time = event_time - timedelta(minutes=config.timing_minutes)
        
        # Create notifications for each recipient
        for recipient_id in recipient_ids:
            notification = self._create_notification(
                event_type=event_type,
                recipient_id=recipient_id,
                scheduled_time=scheduled_time,
                event_time=event_time,
                event_details=event_details,
                config=config
            )
            
            if notification:
                self.pending_notifications.append(notification)
                notification_ids.append(notification.notification_id)
        
        return notification_ids
    
    async def process_pending_notifications(self) -> Dict[str, Any]:
        """Process all pending notifications"""
        current_time = datetime.now()
        results = {
            'processed': 0,
            'sent': 0,
            'failed': 0,
            'skipped': 0
        }
        
        notifications_to_send = [
            n for n in self.pending_notifications
            if n.scheduled_time <= current_time and not n.sent
        ]
        
        for notification in notifications_to_send:
            # Check quiet hours
            if self._in_quiet_hours(current_time) and notification.priority != NotificationPriority.CRITICAL:
                results['skipped'] += 1
                continue
            
            # Send notification
            success = await self._send_notification(notification)
            
            if success:
                notification.sent = True
                notification.sent_time = current_time
                results['sent'] += 1
            else:
                notification.attempts += 1
                
                # Handle retry logic
                if notification.attempts < self.system_settings.max_retry_attempts:
                    # Reschedule for retry
                    notification.scheduled_time = current_time + timedelta(minutes=5)
                else:
                    results['failed'] += 1
            
            results['processed'] += 1
            
            # Record history
            self._record_history(notification)
        
        # Clean up old sent notifications
        self._cleanup_sent_notifications()
        
        return results
    
    def get_notification_history(self,
                               start_date: Optional[datetime] = None,
                               end_date: Optional[datetime] = None,
                               event_type: Optional[NotificationType] = None,
                               recipient_id: Optional[str] = None) -> List[NotificationHistory]:
        """Get notification history for compliance tracking"""
        history = self.notification_history
        
        if start_date:
            history = [h for h in history if h.scheduled_time >= start_date]
        
        if end_date:
            history = [h for h in history if h.scheduled_time <= end_date]
        
        if event_type:
            history = [h for h in history if h.event_type == event_type]
        
        if recipient_id:
            history = [h for h in history if h.recipient_id == recipient_id]
        
        return history
    
    def cancel_notification(self, notification_id: str) -> bool:
        """Cancel a pending notification"""
        for notification in self.pending_notifications:
            if notification.notification_id == notification_id and not notification.sent:
                self.pending_notifications.remove(notification)
                return True
        return False
    
    def update_recipient_preferences(self,
                                   recipient_id: str,
                                   preferences: Dict[NotificationType, Dict[str, Any]]) -> bool:
        """Update notification preferences for a recipient"""
        # This would integrate with user preference storage
        # For now, we'll store in memory
        return True
    
    # Private helper methods
    
    def _validate_system_settings(self, settings: SystemNotificationSettings) -> bool:
        """Validate system notification settings"""
        # Validate email server
        if settings.email_server and not self._validate_email_server(settings.email_server):
            return False
        
        # Validate quiet hours format
        try:
            datetime.strptime(settings.quiet_hours_start, "%H:%M")
            datetime.strptime(settings.quiet_hours_end, "%H:%M")
        except ValueError:
            logger.error("Invalid quiet hours format")
            return False
        
        # Validate retention and retry settings
        if settings.retention_days < 1 or settings.retention_days > 365:
            logger.error("Retention days must be between 1 and 365")
            return False
        
        if settings.max_retry_attempts < 1 or settings.max_retry_attempts > 10:
            logger.error("Max retry attempts must be between 1 and 10")
            return False
        
        return True
    
    def _validate_notification_config(self, config: NotificationConfig) -> bool:
        """Validate notification configuration"""
        if config.timing_minutes < 0:
            logger.error("Timing minutes cannot be negative")
            return False
        
        if not config.methods:
            logger.error("At least one notification method must be specified")
            return False
        
        return True
    
    def _validate_email_server(self, server: str) -> bool:
        """Validate email server connectivity"""
        try:
            # Basic validation - in production would test connection
            return '.' in server
        except Exception:
            return False
    
    def _initialize_delivery_handlers(self):
        """Initialize handlers for different delivery methods"""
        if self.system_settings:
            # Email handler
            if self.system_settings.email_server:
                self.delivery_handlers[NotificationMethod.EMAIL] = {
                    'server': self.system_settings.email_server,
                    'enabled': True
                }
            
            # SMS handler
            if self.system_settings.sms_gateway:
                self.delivery_handlers[NotificationMethod.SMS] = {
                    'gateway': self.system_settings.sms_gateway,
                    'enabled': True
                }
            
            # Mobile push handler
            if self.system_settings.mobile_push_service:
                self.delivery_handlers[NotificationMethod.MOBILE] = {
                    'service': self.system_settings.mobile_push_service,
                    'enabled': True
                }
            
            # System notification is always available
            self.delivery_handlers[NotificationMethod.SYSTEM] = {
                'enabled': True
            }
    
    def _test_delivery_methods(self) -> bool:
        """Test configured delivery methods"""
        all_passed = True
        
        for method, handler in self.delivery_handlers.items():
            if handler.get('enabled'):
                # In production, would actually test each method
                logger.info(f"Testing {method.value} delivery method")
                # For now, we'll assume they work
                
        return all_passed
    
    def _create_notification(self,
                           event_type: NotificationType,
                           recipient_id: str,
                           scheduled_time: datetime,
                           event_time: datetime,
                           event_details: Dict[str, Any],
                           config: NotificationConfig) -> Optional[Notification]:
        """Create a notification instance"""
        try:
            # Generate unique ID
            notification_id = f"{event_type.value}_{recipient_id}_{int(event_time.timestamp())}"
            
            # Prepare content
            content = self._prepare_notification_content(
                event_type, event_details, event_time
            )
            
            # Determine priority
            priority = self._determine_priority(event_type)
            
            # Get recipient contact info (would come from user database)
            recipient_email = event_details.get('recipient_email', f"{recipient_id}@company.com")
            recipient_phone = event_details.get('recipient_phone')
            
            notification = Notification(
                notification_id=notification_id,
                event_type=event_type,
                recipient_id=recipient_id,
                recipient_email=recipient_email,
                recipient_phone=recipient_phone,
                scheduled_time=scheduled_time,
                event_time=event_time,
                methods=config.methods,
                content=content,
                priority=priority
            )
            
            return notification
            
        except Exception as e:
            logger.error(f"Failed to create notification: {str(e)}")
            return None
    
    def _prepare_notification_content(self,
                                    event_type: NotificationType,
                                    event_details: Dict[str, Any],
                                    event_time: datetime) -> Dict[str, str]:
        """Prepare notification content for different channels"""
        content = {}
        
        # Format event time
        time_str = event_time.strftime("%H:%M")
        date_str = event_time.strftime("%Y-%m-%d")
        
        if event_type == NotificationType.BREAK_REMINDER:
            content['subject'] = "Break Reminder"
            content['message'] = f"Your break is scheduled at {time_str}"
            content['short'] = f"Break at {time_str}"
            
        elif event_type == NotificationType.LUNCH_REMINDER:
            content['subject'] = "Lunch Break Reminder"
            content['message'] = f"Your lunch break is scheduled at {time_str}"
            content['short'] = f"Lunch at {time_str}"
            
        elif event_type == NotificationType.MEETING_REMINDER:
            meeting_name = event_details.get('meeting_name', 'Meeting')
            content['subject'] = f"Meeting Reminder: {meeting_name}"
            content['message'] = f"{meeting_name} is scheduled at {time_str} on {date_str}"
            content['short'] = f"{meeting_name} at {time_str}"
            
        elif event_type == NotificationType.TRAINING_START:
            training_name = event_details.get('training_name', 'Training')
            content['subject'] = f"Training Starting Soon: {training_name}"
            content['message'] = f"{training_name} starts at {time_str} on {date_str}"
            content['short'] = f"{training_name} at {time_str}"
            
        elif event_type == NotificationType.SCHEDULE_CHANGE:
            change_details = event_details.get('change_details', 'Schedule updated')
            content['subject'] = "Schedule Change Notification"
            content['message'] = f"Your schedule has been updated: {change_details}"
            content['short'] = "Schedule changed"
            
        elif event_type == NotificationType.SHIFT_START:
            content['subject'] = "Shift Starting Soon"
            content['message'] = f"Your shift starts at {time_str}"
            content['short'] = f"Shift at {time_str}"
        
        return content
    
    def _determine_priority(self, event_type: NotificationType) -> NotificationPriority:
        """Determine notification priority based on event type"""
        priority_map = {
            NotificationType.SCHEDULE_CHANGE: NotificationPriority.HIGH,
            NotificationType.SHIFT_START: NotificationPriority.HIGH,
            NotificationType.MEETING_REMINDER: NotificationPriority.MEDIUM,
            NotificationType.TRAINING_START: NotificationPriority.MEDIUM,
            NotificationType.LUNCH_REMINDER: NotificationPriority.LOW,
            NotificationType.BREAK_REMINDER: NotificationPriority.LOW
        }
        
        return priority_map.get(event_type, NotificationPriority.MEDIUM)
    
    def _in_quiet_hours(self, check_time: datetime) -> bool:
        """Check if current time is within quiet hours"""
        if not self.system_settings:
            return False
        
        current_time = check_time.strftime("%H:%M")
        quiet_start = self.system_settings.quiet_hours_start
        quiet_end = self.system_settings.quiet_hours_end
        
        # Handle overnight quiet hours
        if quiet_start > quiet_end:
            return current_time >= quiet_start or current_time <= quiet_end
        else:
            return quiet_start <= current_time <= quiet_end
    
    async def _send_notification(self, notification: Notification) -> bool:
        """Send notification through configured methods"""
        success = False
        
        for method in notification.methods:
            if method in self.delivery_handlers and self.delivery_handlers[method].get('enabled'):
                try:
                    if method == NotificationMethod.EMAIL:
                        success = await self._send_email(notification)
                    elif method == NotificationMethod.SMS:
                        success = await self._send_sms(notification)
                    elif method == NotificationMethod.MOBILE:
                        success = await self._send_push(notification)
                    elif method == NotificationMethod.SYSTEM:
                        success = await self._send_system(notification)
                    
                    if success:
                        break  # One successful delivery is enough
                        
                except Exception as e:
                    logger.error(f"Failed to send {method.value} notification: {str(e)}")
                    notification.error_message = str(e)
        
        return success
    
    async def _send_email(self, notification: Notification) -> bool:
        """Send email notification"""
        # In production, would use actual email service
        logger.info(f"Sending email to {notification.recipient_email}: {notification.content['subject']}")
        return True
    
    async def _send_sms(self, notification: Notification) -> bool:
        """Send SMS notification"""
        # In production, would use actual SMS gateway
        logger.info(f"Sending SMS to {notification.recipient_phone}: {notification.content['short']}")
        return True
    
    async def _send_push(self, notification: Notification) -> bool:
        """Send mobile push notification"""
        # In production, would use actual push service
        logger.info(f"Sending push to {notification.recipient_id}: {notification.content['short']}")
        return True
    
    async def _send_system(self, notification: Notification) -> bool:
        """Send system notification"""
        # This would integrate with the application's notification system
        logger.info(f"System notification for {notification.recipient_id}: {notification.content['message']}")
        return True
    
    def _record_history(self, notification: Notification):
        """Record notification in history for compliance"""
        for method in notification.methods:
            history_entry = NotificationHistory(
                notification_id=notification.notification_id,
                event_type=notification.event_type,
                recipient_id=notification.recipient_id,
                scheduled_time=notification.scheduled_time,
                sent_time=notification.sent_time,
                delivery_status="sent" if notification.sent else "failed",
                delivery_method=method,
                attempts=notification.attempts,
                error_details=notification.error_message
            )
            self.notification_history.append(history_entry)
    
    def _cleanup_sent_notifications(self):
        """Remove old sent notifications"""
        if not self.system_settings:
            return
        
        cutoff_date = datetime.now() - timedelta(days=self.system_settings.retention_days)
        
        # Remove old sent notifications
        self.pending_notifications = [
            n for n in self.pending_notifications
            if not n.sent or n.scheduled_time > cutoff_date
        ]
        
        # Remove old history
        self.notification_history = [
            h for h in self.notification_history
            if h.scheduled_time > cutoff_date
        ]

# Escalation Manager for failed notifications
class EscalationManager:
    """Handles escalation for failed notifications"""
    
    def __init__(self, notification_engine: NotificationEngine):
        self.notification_engine = notification_engine
        self.escalation_rules: Dict[NotificationType, List[str]] = {}
        
    def configure_escalation(self,
                           event_type: NotificationType,
                           escalation_chain: List[str]):
        """Configure escalation chain for notification type"""
        self.escalation_rules[event_type] = escalation_chain
    
    async def handle_failed_notification(self,
                                       notification: Notification,
                                       failure_count: int) -> bool:
        """Handle escalation for failed notification"""
        escalation_chain = self.escalation_rules.get(notification.event_type, [])
        
        if failure_count <= len(escalation_chain):
            # Escalate to next level
            escalation_recipient = escalation_chain[failure_count - 1]
            
            # Create escalation notification
            escalation_ids = self.notification_engine.schedule_notification(
                event_type=NotificationType.SYSTEM_ALERT,
                event_time=datetime.now(),
                recipient_ids=[escalation_recipient],
                event_details={
                    'original_notification': notification.notification_id,
                    'failure_reason': notification.error_message,
                    'original_recipient': notification.recipient_id
                }
            )
            
            return len(escalation_ids) > 0
        
        return False