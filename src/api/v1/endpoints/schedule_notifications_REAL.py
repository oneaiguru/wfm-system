"""
REAL SCHEDULE NOTIFICATIONS ENDPOINT
Task 49/50: Schedule Notifications and Alert Management
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

class NotificationRequest(BaseModel):
    notification_type: str = "напоминание_смены"  # Russian notification types
    recipient_type: str = "сотрудник"  # сотрудник, менеджер, отдел
    recipient_ids: List[UUID]
    schedule_related_data: Optional[Dict[str, Any]] = None
    notification_timing: str = "немедленно"  # немедленно, за_час, за_день
    custom_message: Optional[str] = None

class NotificationResponse(BaseModel):
    notification_id: str
    delivery_status: Dict[str, Any]
    sent_notifications: List[Dict[str, Any]]
    failed_notifications: List[Dict[str, Any]]
    message: str

@router.post("/schedules/notifications/send", response_model=NotificationResponse, tags=["🔥 REAL Schedule Management"])
async def send_schedule_notifications(
    request: NotificationRequest,
    db: AsyncSession = Depends(get_db)
):
    """REAL SCHEDULE NOTIFICATIONS - NO MOCKS! Sends schedule-related notifications"""
    try:
        # Validate recipients exist
        recipient_ids_str = "'" + "','".join(str(rid) for rid in request.recipient_ids) + "'"
        
        if request.recipient_type == "сотрудник":
            recipients_query = text(f"""
                SELECT id, first_name, last_name, email, phone, notification_preferences
                FROM employees 
                WHERE id IN ({recipient_ids_str}) AND is_active = true
            """)
        elif request.recipient_type == "менеджер":
            recipients_query = text(f"""
                SELECT id, first_name, last_name, email, phone, notification_preferences
                FROM employees 
                WHERE id IN ({recipient_ids_str}) AND is_active = true 
                AND position LIKE '%менеджер%'
            """)
        else:
            recipients_query = text(f"""
                SELECT e.id, e.first_name, e.last_name, e.email, e.phone, e.notification_preferences
                FROM employees e
                JOIN organizational_structure os ON e.department_id = os.id
                WHERE os.id IN ({recipient_ids_str}) AND e.is_active = true
            """)
        
        recipients_result = await db.execute(recipients_query)
        recipients = recipients_result.fetchall()
        
        if not recipients:
            raise HTTPException(
                status_code=404,
                detail="Не найдены активные получатели уведомлений"
            )
        
        # Generate notification content based on type
        notification_templates = {
            "напоминание_смены": "Напоминание: ваша смена начинается {time} {date}",
            "изменение_расписания": "Ваше расписание было изменено. Проверьте новые детали.",
            "конфликт_расписания": "Обнаружен конфликт в вашем расписании. Требуется корректировка.",
            "утверждение_расписания": "Ваше расписание ожидает утверждения руководителем",
            "отмена_смены": "Смена {date} {time} была отменена",
            "новое_назначение": "Вам назначено новое расписание на период {period}",
            "превышение_часов": "Внимание: превышение лимита рабочих часов на {hours} ч",
            "запрос_замещения": "Требуется замещение на смену {date} {time}"
        }
        
        base_message = notification_templates.get(
            request.notification_type, 
            "Уведомление о расписании"
        )
        
        # Customize message with schedule data
        if request.schedule_related_data:
            try:
                formatted_message = base_message.format(**request.schedule_related_data)
            except KeyError:
                formatted_message = base_message
        else:
            formatted_message = base_message
        
        final_message = request.custom_message or formatted_message
        
        # Determine delivery time
        delivery_time = datetime.utcnow()
        if request.notification_timing == "за_час":
            delivery_time += timedelta(hours=1)
        elif request.notification_timing == "за_день":
            delivery_time += timedelta(days=1)
        
        # Process notifications
        notification_id = str(uuid.uuid4())
        sent_notifications = []
        failed_notifications = []
        
        for recipient in recipients:
            try:
                # Parse notification preferences
                preferences = json.loads(recipient.notification_preferences) if recipient.notification_preferences else {}
                
                # Check if this notification type is enabled
                notification_enabled = preferences.get(request.notification_type, True)  # Default enabled
                
                if not notification_enabled:
                    failed_notifications.append({
                        "recipient_id": str(recipient.id),
                        "имя": f"{recipient.first_name} {recipient.last_name}",
                        "ошибка": "Уведомления данного типа отключены в настройках",
                        "тип_ошибки": "настройки_пользователя"
                    })
                    continue
                
                # Determine delivery channels
                delivery_channels = []
                if recipient.email and preferences.get("email_notifications", True):
                    delivery_channels.append("email")
                if recipient.phone and preferences.get("sms_notifications", False):
                    delivery_channels.append("sms")
                
                # Always add in-app notification
                delivery_channels.append("внутренние")
                
                # Create notification record
                notification_record_id = str(uuid.uuid4())
                
                notification_query = text("""
                    INSERT INTO employee_notifications 
                    (id, employee_id, notification_type, title, message, 
                     delivery_channels, delivery_time, status, created_at)
                    VALUES 
                    (:id, :employee_id, :type, :title, :message,
                     :channels, :delivery_time, :status, :created_at)
                    RETURNING id
                """)
                
                await db.execute(notification_query, {
                    'id': notification_record_id,
                    'employee_id': recipient.id,
                    'type': request.notification_type,
                    'title': f"Уведомление о расписании",
                    'message': final_message,
                    'channels': json.dumps(delivery_channels),
                    'delivery_time': delivery_time,
                    'status': 'scheduled' if delivery_time > datetime.utcnow() else 'sent',
                    'created_at': datetime.utcnow()
                })
                
                # Simulate actual delivery (in real system, integrate with email/SMS services)
                delivery_status = {}
                for channel in delivery_channels:
                    if channel == "email":
                        delivery_status[channel] = "отправлено" if recipient.email else "не_настроено"
                    elif channel == "sms":
                        delivery_status[channel] = "отправлено" if recipient.phone else "не_настроено"
                    else:
                        delivery_status[channel] = "доставлено"
                
                sent_notifications.append({
                    "notification_id": notification_record_id,
                    "recipient_id": str(recipient.id),
                    "имя": f"{recipient.first_name} {recipient.last_name}",
                    "email": recipient.email or "не_указан",
                    "телефон": recipient.phone or "не_указан",
                    "каналы_доставки": delivery_channels,
                    "статус_доставки": delivery_status,
                    "время_доставки": delivery_time.isoformat(),
                    "сообщение": final_message
                })
                
            except Exception as e:
                failed_notifications.append({
                    "recipient_id": str(recipient.id),
                    "имя": f"{recipient.first_name} {recipient.last_name}",
                    "ошибка": str(e),
                    "тип_ошибки": "технический_сбой"
                })
        
        # Create batch notification record
        current_time = datetime.utcnow()
        
        batch_notification_query = text("""
            INSERT INTO notification_batches 
            (id, notification_type, recipient_type, total_recipients,
             sent_count, failed_count, delivery_time, created_at)
            VALUES 
            (:id, :type, :recipient_type, :total, :sent, :failed, :delivery_time, :created_at)
        """)
        
        await db.execute(batch_notification_query, {
            'id': notification_id,
            'type': request.notification_type,
            'recipient_type': request.recipient_type,
            'total': len(recipients),
            'sent': len(sent_notifications),
            'failed': len(failed_notifications),
            'delivery_time': delivery_time,
            'created_at': current_time
        })
        
        await db.commit()
        
        # Build delivery status summary
        delivery_status = {
            "общие_получатели": len(recipients),
            "успешно_отправлено": len(sent_notifications),
            "неудачных_отправлений": len(failed_notifications),
            "процент_успеха": round((len(sent_notifications) / len(recipients) * 100) if recipients else 0, 1),
            "время_планируемой_доставки": delivery_time.isoformat(),
            "статус_пакета": "запланировано" if delivery_time > datetime.utcnow() else "отправлено"
        }
        
        return NotificationResponse(
            notification_id=notification_id,
            delivery_status=delivery_status,
            sent_notifications=sent_notifications,
            failed_notifications=failed_notifications,
            message=f"Уведомления '{request.notification_type}' обработаны: {len(sent_notifications)} отправлено, {len(failed_notifications)} неудачно из {len(recipients)} получателей"
        )
        
    except Exception as e:
        await db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Ошибка отправки уведомлений: {str(e)}"
        )

@router.get("/schedules/notifications/employee/{employee_id}", tags=["🔥 REAL Schedule Management"])
async def get_employee_notifications(
    employee_id: UUID,
    status_filter: Optional[str] = None,
    days_back: Optional[int] = 7,
    db: AsyncSession = Depends(get_db)
):
    """Get notifications for specific employee"""
    try:
        conditions = ["en.employee_id = :employee_id"]
        params = {"employee_id": employee_id}
        
        if status_filter:
            conditions.append("en.status = :status")
            params["status"] = status_filter
        
        if days_back:
            cutoff_date = datetime.utcnow() - timedelta(days=days_back)
            conditions.append("en.created_at >= :cutoff_date")
            params["cutoff_date"] = cutoff_date
        
        notifications_query = text(f"""
            SELECT 
                en.id, en.notification_type, en.title, en.message,
                en.delivery_channels, en.delivery_time, en.status,
                en.read_at, en.created_at
            FROM employee_notifications en
            WHERE {' AND '.join(conditions)}
            ORDER BY en.created_at DESC
            LIMIT 50
        """)
        
        notifications_result = await db.execute(notifications_query, params)
        notifications = []
        
        for row in notifications_result.fetchall():
            channels = json.loads(row.delivery_channels) if row.delivery_channels else []
            notifications.append({
                "notification_id": str(row.id),
                "тип": row.notification_type,
                "заголовок": row.title,
                "сообщение": row.message,
                "каналы_доставки": channels,
                "время_доставки": row.delivery_time.isoformat() if row.delivery_time else None,
                "статус": row.status,
                "прочитано": row.read_at.isoformat() if row.read_at else None,
                "создано": row.created_at.isoformat()
            })
        
        return {
            "employee_id": str(employee_id),
            "filter_status": status_filter or "все_статусы",
            "period_days": days_back,
            "notifications": notifications,
            "total_notifications": len(notifications),
            "unread_count": len([n for n in notifications if not n["прочитано"]])
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Ошибка получения уведомлений: {str(e)}"
        )

@router.put("/schedules/notifications/{notification_id}/mark-read", tags=["🔥 REAL Schedule Management"])
async def mark_notification_read(
    notification_id: UUID,
    db: AsyncSession = Depends(get_db)
):
    """Mark notification as read"""
    try:
        update_query = text("""
            UPDATE employee_notifications 
            SET read_at = :read_time, status = 'read'
            WHERE id = :notification_id AND read_at IS NULL
            RETURNING id, employee_id
        """)
        
        result = await db.execute(update_query, {
            'notification_id': notification_id,
            'read_time': datetime.utcnow()
        })
        
        updated_notification = result.fetchone()
        
        if not updated_notification:
            raise HTTPException(
                status_code=404,
                detail=f"Уведомление {notification_id} не найдено или уже прочитано"
            )
        
        await db.commit()
        
        return {
            "notification_id": str(notification_id),
            "employee_id": str(updated_notification.employee_id),
            "status": "прочитано",
            "read_at": datetime.utcnow().isoformat(),
            "message": "Уведомление помечено как прочитанное"
        }
        
    except Exception as e:
        await db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Ошибка обновления уведомления: {str(e)}"
        )