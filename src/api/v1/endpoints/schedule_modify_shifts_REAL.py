"""
REAL SCHEDULE SHIFT MODIFICATION ENDPOINT
Task 37/50: Live Schedule Modification and Shift Updates
"""

from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from pydantic import BaseModel
from datetime import datetime, date
from typing import Optional, List, Dict, Any
from uuid import UUID
import uuid
import json

from ...core.database import get_db

router = APIRouter()

class ShiftModificationRequest(BaseModel):
    schedule_id: UUID
    modifications: List[Dict[str, Any]]  # List of shift changes
    modification_reason: str = "корректировка_расписания"  # Russian text
    effective_immediately: Optional[bool] = True
    notify_affected: Optional[bool] = True

class ShiftModificationResponse(BaseModel):
    modification_id: str
    schedule_id: str
    applied_changes: List[Dict[str, Any]]
    schedule_summary: Dict[str, Any]
    validation_results: Dict[str, Any]
    message: str

@router.put("/schedules/modify/shifts", response_model=ShiftModificationResponse, tags=["🔥 REAL Schedule Assignments"])
async def modify_schedule_shifts(
    request: ShiftModificationRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    REAL SCHEDULE SHIFT MODIFICATION - NO MOCKS!
    
    Modifies existing schedule shifts with validation and history tracking
    Uses real work_schedules_core and schedule_modifications tables
    Supports Russian modification reasons and immediate updates
    
    UNBLOCKS: Live schedule editing workflows
    """
    try:
        # Get existing schedule
        schedule_query = text("""
            SELECT 
                ws.*,
                e.first_name, e.last_name, e.max_hours_per_week,
                st.template_name
            FROM work_schedules_core ws
            JOIN employees e ON ws.employee_id = e.id
            LEFT JOIN schedule_templates st ON ws.template_id = st.id
            WHERE ws.id = :schedule_id
        """)
        
        schedule_result = await db.execute(schedule_query, {"schedule_id": request.schedule_id})
        schedule = schedule_result.fetchone()
        
        if not schedule:
            raise HTTPException(
                status_code=404,
                detail=f"Расписание {request.schedule_id} не найдено"
            )
        
        if schedule.status not in ['active', 'pending', 'assigned']:
            raise HTTPException(
                status_code=422,
                detail=f"Нельзя изменить расписание со статусом '{schedule.status}'"
            )
        
        # Parse existing shifts
        existing_shifts = json.loads(schedule.shift_assignments) if schedule.shift_assignments else []
        modified_shifts = existing_shifts.copy()
        applied_changes = []
        
        # Apply modifications
        for mod in request.modifications:
            mod_type = mod.get("тип", "")
            
            if mod_type == "обновить_смену":
                shift_date = mod.get("дата")
                if not shift_date:
                    continue
                
                # Find and update existing shift
                for i, shift in enumerate(modified_shifts):
                    if shift.get("дата") == shift_date:
                        old_shift = shift.copy()
                        
                        # Apply updates
                        if "время_начала" in mod:
                            shift["время_начала"] = mod["время_начала"]
                        if "время_окончания" in mod:
                            shift["время_окончания"] = mod["время_окончания"]
                        if "часы" in mod:
                            shift["часы"] = mod["часы"]
                        if "тип_смены" in mod:
                            shift["тип_смены"] = mod["тип_смены"]
                        
                        shift["изменено"] = datetime.utcnow().isoformat()
                        
                        applied_changes.append({
                            "тип": "обновление_смены",
                            "дата": shift_date,
                            "старые_значения": old_shift,
                            "новые_значения": shift
                        })
                        break
            
            elif mod_type == "добавить_смену":
                new_shift = {
                    "дата": mod.get("дата"),
                    "время_начала": mod.get("время_начала", "09:00"),
                    "время_окончания": mod.get("время_окончания", "17:00"),
                    "часы": mod.get("часы", 8),
                    "тип_смены": mod.get("тип_смены", "дополнительная"),
                    "добавлено": datetime.utcnow().isoformat()
                }
                
                modified_shifts.append(new_shift)
                applied_changes.append({
                    "тип": "добавление_смены",
                    "новая_смена": new_shift
                })
            
            elif mod_type == "удалить_смену":
                shift_date = mod.get("дата")
                original_count = len(modified_shifts)
                modified_shifts = [s for s in modified_shifts if s.get("дата") != shift_date]
                
                if len(modified_shifts) < original_count:
                    applied_changes.append({
                        "тип": "удаление_смены",
                        "дата": shift_date
                    })
        
        # Validate modifications
        validation_results = {
            "общие_проверки": {},
            "часовые_ограничения": {},
            "конфликты_времени": [],
            "статус": "валидно"
        }
        
        # Calculate new totals
        new_total_hours = sum(shift.get("часы", 0) for shift in modified_shifts)
        hours_change = new_total_hours - (schedule.total_hours or 0)
        
        # Check hours constraints
        period_days = (schedule.expiry_date - schedule.effective_date).days + 1 if schedule.expiry_date else 7
        weeks = period_days / 7
        max_weekly_hours = schedule.max_hours_per_week or 40
        max_total_hours = max_weekly_hours * weeks
        
        validation_results["часовые_ограничения"] = {
            "новые_общие_часы": new_total_hours,
            "изменение_часов": hours_change,
            "максимум_для_сотрудника": max_total_hours,
            "соответствует_ограничениям": new_total_hours <= max_total_hours
        }
        
        # Check for time conflicts within the same day
        date_groups = {}
        for shift in modified_shifts:
            shift_date = shift.get("дата")
            if shift_date not in date_groups:
                date_groups[shift_date] = []
            date_groups[shift_date].append(shift)
        
        for date_str, day_shifts in date_groups.items():
            if len(day_shifts) > 1:
                # Check for overlapping times
                for i, shift1 in enumerate(day_shifts):
                    for j, shift2 in enumerate(day_shifts[i+1:], i+1):
                        start1 = shift1.get("время_начала", "00:00")
                        end1 = shift1.get("время_окончания", "23:59")
                        start2 = shift2.get("время_начала", "00:00") 
                        end2 = shift2.get("время_окончания", "23:59")
                        
                        if start1 < end2 and start2 < end1:  # Overlap detected
                            validation_results["конфликты_времени"].append({
                                "дата": date_str,
                                "смена1": f"{start1}-{end1}",
                                "смена2": f"{start2}-{end2}",
                                "описание": "Пересечение времени смен"
                            })
        
        validation_results["общие_проверки"] = {
            "количество_смен": len(modified_shifts),
            "изменений_применено": len(applied_changes),
            "есть_конфликты_времени": len(validation_results["конфликты_времени"]) > 0
        }
        
        # Check overall validation
        if (not validation_results["часовые_ограничения"]["соответствует_ограничениям"] or 
            validation_results["общие_проверки"]["есть_конфликты_времени"]):
            validation_results["статус"] = "требует_исправлений"
            
            error_details = []
            if not validation_results["часовые_ограничения"]["соответствует_ограничениям"]:
                error_details.append(f"Превышение лимита часов: {new_total_hours} > {max_total_hours}")
            if validation_results["общие_проверки"]["есть_конфликты_времени"]:
                error_details.append(f"Конфликты времени: {len(validation_results['конфликты_времени'])}")
            
            raise HTTPException(
                status_code=422,
                detail=f"Ошибки валидации: {'; '.join(error_details)}"
            )
        
        # Apply modifications to database
        modification_id = str(uuid.uuid4())
        current_time = datetime.utcnow()
        
        # Update schedule
        update_query = text("""
            UPDATE work_schedules_core 
            SET shift_assignments = :new_shifts,
                total_hours = :new_hours,
                last_modified = :modified_time,
                updated_at = :updated_at
            WHERE id = :schedule_id
            RETURNING id
        """)
        
        await db.execute(update_query, {
            'schedule_id': request.schedule_id,
            'new_shifts': json.dumps(modified_shifts),
            'new_hours': new_total_hours,
            'modified_time': current_time,
            'updated_at': current_time
        })
        
        # Record modification history
        history_query = text("""
            INSERT INTO schedule_modifications 
            (id, schedule_id, modification_type, modification_reason,
             changes_applied, old_total_hours, new_total_hours, created_at)
            VALUES 
            (:id, :schedule_id, :type, :reason,
             :changes, :old_hours, :new_hours, :created_at)
        """)
        
        await db.execute(history_query, {
            'id': modification_id,
            'schedule_id': request.schedule_id,
            'type': 'shift_modification',
            'reason': request.modification_reason,
            'changes': json.dumps(applied_changes),
            'old_hours': schedule.total_hours,
            'new_hours': new_total_hours,
            'created_at': current_time
        })
        
        # Send notifications if requested
        if request.notify_affected:
            notification_query = text("""
                INSERT INTO employee_notifications 
                (id, employee_id, notification_type, title, message, created_at)
                VALUES 
                (:id, :employee_id, :type, :title, :message, :created_at)
            """)
            
            await db.execute(notification_query, {
                'id': str(uuid.uuid4()),
                'employee_id': schedule.employee_id,
                'type': 'schedule_modification',
                'title': 'Изменение расписания',
                'message': f'Ваше расписание было изменено. Применено изменений: {len(applied_changes)}. Новые часы: {new_total_hours}',
                'created_at': current_time
            })
        
        await db.commit()
        
        # Build schedule summary
        schedule_summary = {
            "schedule_id": str(request.schedule_id),
            "сотрудник": f"{schedule.first_name} {schedule.last_name}",
            "период": f"{schedule.effective_date} - {schedule.expiry_date}" if schedule.expiry_date else f"с {schedule.effective_date}",
            "шаблон": schedule.template_name or "без_шаблона",
            "статус": schedule.status,
            "часы_до": schedule.total_hours,
            "часы_после": new_total_hours,
            "изменение": hours_change,
            "количество_смен": len(modified_shifts),
            "последнее_изменение": current_time.isoformat()
        }
        
        return ShiftModificationResponse(
            modification_id=modification_id,
            schedule_id=str(request.schedule_id),
            applied_changes=applied_changes,
            schedule_summary=schedule_summary,
            validation_results=validation_results,
            message=f"Расписание изменено: {len(applied_changes)} изменений применено. Часы: {schedule.total_hours} → {new_total_hours}"
        )
        
    except Exception as e:
        await db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Ошибка изменения расписания: {str(e)}"
        )