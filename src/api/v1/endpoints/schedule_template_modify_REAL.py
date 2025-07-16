"""
REAL SCHEDULE TEMPLATE MODIFICATION ENDPOINT
Task 32/50: Schedule Template Editing and Version Management
"""

from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from pydantic import BaseModel
from datetime import datetime
from typing import Optional, List, Dict, Any
from uuid import UUID
import uuid
import json

from ...core.database import get_db

router = APIRouter()

class TemplateModificationRequest(BaseModel):
    template_name: Optional[str] = None
    template_type: Optional[str] = None
    shift_structure: Optional[Dict[str, Any]] = None
    working_hours_per_day: Optional[float] = None
    working_days_per_week: Optional[int] = None
    break_duration_minutes: Optional[int] = None
    lunch_break_minutes: Optional[int] = None
    cost_per_hour: Optional[float] = None
    overtime_rules: Optional[Dict[str, Any]] = None
    holiday_rules: Optional[Dict[str, Any]] = None
    modification_reason: str = "обновление_параметров"  # Russian text
    create_new_version: Optional[bool] = False

class TemplateModificationResponse(BaseModel):
    template_id: str
    original_template_id: str
    modification_type: str
    changes_summary: Dict[str, Any]
    validation_status: str
    version_info: Dict[str, Any]
    affected_schedules: List[Dict[str, Any]]
    message: str

@router.put("/schedules/templates/{template_id}/modify", response_model=TemplateModificationResponse, tags=["🔥 REAL Schedule Templates"])
async def modify_schedule_template(
    template_id: UUID,
    request: TemplateModificationRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    REAL SCHEDULE TEMPLATE MODIFICATION - NO MOCKS!
    
    Modifies existing schedule templates with version control
    Uses real schedule_templates and template_versions tables
    Supports Russian modification reasons and change tracking
    
    UNBLOCKS: Template versioning and update workflows
    """
    try:
        # Get existing template
        template_query = text("""
            SELECT 
                st.*,
                os.department_name,
                COUNT(ws.id) as active_schedules_count
            FROM schedule_templates st
            JOIN organizational_structure os ON st.department_id = os.id
            LEFT JOIN work_schedules_core ws ON ws.template_id = st.id 
                AND ws.status IN ('active', 'pending')
            WHERE st.id = :template_id
            GROUP BY st.id, os.department_name
        """)
        
        template_result = await db.execute(template_query, {"template_id": template_id})
        original_template = template_result.fetchone()
        
        if not original_template:
            raise HTTPException(
                status_code=404,
                detail=f"Шаблон {template_id} не найден"
            )
        
        # Parse existing data
        original_shift_structure = json.loads(original_template.shift_structure) if original_template.shift_structure else {}
        original_settings = json.loads(original_template.template_settings) if original_template.template_settings else {}
        
        # Prepare changes summary
        changes_summary = {
            "измененные_поля": [],
            "старые_значения": {},
            "новые_значения": {},
            "значимые_изменения": []
        }
        
        # Build updated values
        updated_values = {
            'template_name': request.template_name or original_template.template_name,
            'template_type': request.template_type or original_template.template_type,
            'working_hours_per_day': request.working_hours_per_day or original_template.working_hours_per_day,
            'working_days_per_week': request.working_days_per_week or original_template.working_days_per_week,
            'break_duration_minutes': request.break_duration_minutes if request.break_duration_minutes is not None else original_template.break_duration_minutes,
            'lunch_break_minutes': request.lunch_break_minutes if request.lunch_break_minutes is not None else original_template.lunch_break_minutes,
            'cost_per_hour': request.cost_per_hour or original_template.cost_per_hour,
            'shift_structure': request.shift_structure or original_shift_structure
        }
        
        # Track changes
        field_mapping = {
            'template_name': 'название_шаблона',
            'template_type': 'тип_шаблона',
            'working_hours_per_day': 'часы_в_день',
            'working_days_per_week': 'дни_в_неделю',
            'break_duration_minutes': 'перерыв_минуты',
            'lunch_break_minutes': 'обед_минуты',
            'cost_per_hour': 'стоимость_час'
        }
        
        for field, value in updated_values.items():
            if field == 'shift_structure':
                if json.dumps(value, sort_keys=True) != json.dumps(original_shift_structure, sort_keys=True):
                    changes_summary["измененные_поля"].append("структура_смены")
                    changes_summary["старые_значения"]["структура_смены"] = original_shift_structure
                    changes_summary["новые_значения"]["структура_смены"] = value
                    changes_summary["значимые_изменения"].append("Изменена структура смены")
            else:
                original_value = getattr(original_template, field)
                if value != original_value:
                    russian_field = field_mapping.get(field, field)
                    changes_summary["измененные_поля"].append(russian_field)
                    changes_summary["старые_значения"][russian_field] = original_value
                    changes_summary["новые_значения"][russian_field] = value
                    
                    # Detect significant changes
                    if field == 'working_hours_per_day' and abs(value - original_value) >= 1:
                        changes_summary["значимые_изменения"].append(f"Изменение рабочих часов: {original_value} → {value}")
                    elif field == 'cost_per_hour' and abs(value - original_value) >= 100:
                        changes_summary["значимые_изменения"].append(f"Изменение стоимости: {original_value} → {value}")
        
        # Validation
        validation_checks = {
            "рабочие_часы": 1 <= updated_values['working_hours_per_day'] <= 24,
            "рабочие_дни": 1 <= updated_values['working_days_per_week'] <= 7,
            "стоимость": updated_values['cost_per_hour'] > 0,
            "структура_смены": isinstance(updated_values['shift_structure'], dict)
        }
        
        validation_status = "валидный" if all(validation_checks.values()) else "требует_исправлений"
        
        if validation_status != "валидный":
            failed_checks = [check for check, passed in validation_checks.items() if not passed]
            raise HTTPException(
                status_code=422,
                detail=f"Ошибки валидации: {', '.join(failed_checks)}"
            )
        
        # Determine modification type
        has_significant_changes = len(changes_summary["значимые_изменения"]) > 0
        active_schedules_count = original_template.active_schedules_count or 0
        
        if request.create_new_version or (has_significant_changes and active_schedules_count > 0):
            modification_type = "новая_версия"
        else:
            modification_type = "обновление_на_месте"
        
        current_time = datetime.utcnow()
        
        if modification_type == "новая_версия":
            # Create new version
            new_template_id = str(uuid.uuid4())
            
            # Get current version number
            version_query = text("""
                SELECT COALESCE(MAX(version_number), 0) as max_version
                FROM template_versions 
                WHERE original_template_id = :template_id
            """)
            
            version_result = await db.execute(version_query, {"template_id": template_id})
            max_version = version_result.scalar() or 0
            new_version = max_version + 1
            
            # Insert new template version
            new_template_query = text("""
                INSERT INTO schedule_templates 
                (id, template_name, template_type, department_id, shift_structure,
                 working_hours_per_day, working_days_per_week, break_duration_minutes,
                 lunch_break_minutes, cost_per_hour, template_settings, 
                 validation_status, is_active, created_at, updated_at, parent_template_id)
                VALUES 
                (:id, :name, :type, :dept_id, :structure,
                 :hours_day, :days_week, :break_min, :lunch_min, :cost_hour, 
                 :settings, :validation, true, :created, :updated, :parent_id)
                RETURNING id
            """)
            
            # Calculate new settings
            total_weekly_hours = updated_values['working_hours_per_day'] * updated_values['working_days_per_week']
            break_time_daily = (updated_values['break_duration_minutes'] or 0) + (updated_values['lunch_break_minutes'] or 0)
            net_working_hours_daily = updated_values['working_hours_per_day'] - (break_time_daily / 60)
            
            new_settings = {
                **original_settings,
                "рабочие_часы_день": updated_values['working_hours_per_day'],
                "рабочие_дни_неделя": updated_values['working_days_per_week'],
                "общие_часы_неделя": total_weekly_hours,
                "перерывы_минуты": updated_values['break_duration_minutes'] or 0,
                "обед_минуты": updated_values['lunch_break_minutes'] or 0,
                "чистые_часы_день": net_working_hours_daily,
                "базовая_стоимость_час": updated_values['cost_per_hour'],
                "правила_переработки": request.overtime_rules or original_settings.get("правила_переработки", {}),
                "правила_праздников": request.holiday_rules or original_settings.get("правила_праздников", {})
            }
            
            await db.execute(new_template_query, {
                'id': new_template_id,
                'name': updated_values['template_name'],
                'type': updated_values['template_type'],
                'dept_id': original_template.department_id,
                'structure': json.dumps(updated_values['shift_structure']),
                'hours_day': updated_values['working_hours_per_day'],
                'days_week': updated_values['working_days_per_week'],
                'break_min': updated_values['break_duration_minutes'] or 0,
                'lunch_min': updated_values['lunch_break_minutes'] or 0,
                'cost_hour': updated_values['cost_per_hour'],
                'settings': json.dumps(new_settings),
                'validation': validation_status,
                'created': current_time,
                'updated': current_time,
                'parent_id': template_id
            })
            
            # Record version history
            version_record_query = text("""
                INSERT INTO template_versions 
                (id, original_template_id, new_template_id, version_number,
                 modification_reason, changes_summary, created_at)
                VALUES 
                (:id, :original_id, :new_id, :version,
                 :reason, :changes, :created)
            """)
            
            await db.execute(version_record_query, {
                'id': str(uuid.uuid4()),
                'original_id': template_id,
                'new_id': new_template_id,
                'version': new_version,
                'reason': request.modification_reason,
                'changes': json.dumps(changes_summary),
                'created': current_time
            })
            
            final_template_id = new_template_id
            version_info = {
                "тип_версии": "новая",
                "номер_версии": new_version,
                "родительский_шаблон": str(template_id),
                "активные_расписания_сохранены": True
            }
            
        else:
            # Update in place
            update_query = text("""
                UPDATE schedule_templates 
                SET template_name = :name,
                    template_type = :type,
                    shift_structure = :structure,
                    working_hours_per_day = :hours_day,
                    working_days_per_week = :days_week,
                    break_duration_minutes = :break_min,
                    lunch_break_minutes = :lunch_min,
                    cost_per_hour = :cost_hour,
                    template_settings = :settings,
                    validation_status = :validation,
                    updated_at = :updated
                WHERE id = :id
                RETURNING id
            """)
            
            # Calculate updated settings (same logic as above)
            total_weekly_hours = updated_values['working_hours_per_day'] * updated_values['working_days_per_week']
            break_time_daily = (updated_values['break_duration_minutes'] or 0) + (updated_values['lunch_break_minutes'] or 0)
            net_working_hours_daily = updated_values['working_hours_per_day'] - (break_time_daily / 60)
            
            updated_settings = {
                **original_settings,
                "рабочие_часы_день": updated_values['working_hours_per_day'],
                "рабочие_дни_неделя": updated_values['working_days_per_week'],
                "общие_часы_неделя": total_weekly_hours,
                "перерывы_минуты": updated_values['break_duration_minutes'] or 0,
                "обед_минуты": updated_values['lunch_break_minutes'] or 0,
                "чистые_часы_день": net_working_hours_daily,
                "базовая_стоимость_час": updated_values['cost_per_hour'],
                "дата_изменения": current_time.isoformat()
            }
            
            await db.execute(update_query, {
                'id': template_id,
                'name': updated_values['template_name'],
                'type': updated_values['template_type'],
                'structure': json.dumps(updated_values['shift_structure']),
                'hours_day': updated_values['working_hours_per_day'],
                'days_week': updated_values['working_days_per_week'],
                'break_min': updated_values['break_duration_minutes'] or 0,
                'lunch_min': updated_values['lunch_break_minutes'] or 0,
                'cost_hour': updated_values['cost_per_hour'],
                'settings': json.dumps(updated_settings),
                'validation': validation_status,
                'updated': current_time
            })
            
            final_template_id = str(template_id)
            version_info = {
                "тип_версии": "обновление",
                "номер_версии": "текущая",
                "изменения_применены": True
            }
        
        # Get affected schedules
        affected_schedules_query = text("""
            SELECT 
                ws.id,
                ws.schedule_name,
                ws.status,
                ws.effective_date,
                e.first_name,
                e.last_name
            FROM work_schedules_core ws
            JOIN employees e ON ws.employee_id = e.id
            WHERE ws.template_id = :template_id
            AND ws.status IN ('active', 'pending')
            LIMIT 10
        """)
        
        affected_result = await db.execute(affected_schedules_query, {"template_id": template_id})
        affected_schedules = []
        
        for row in affected_result.fetchall():
            affected_schedules.append({
                "schedule_id": str(row.id),
                "название": row.schedule_name,
                "статус": row.status,
                "дата_действия": row.effective_date.isoformat(),
                "сотрудник": f"{row.first_name} {row.last_name}",
                "требует_обновления": modification_type == "обновление_на_месте"
            })
        
        await db.commit()
        
        return TemplateModificationResponse(
            template_id=final_template_id,
            original_template_id=str(template_id),
            modification_type=modification_type,
            changes_summary=changes_summary,
            validation_status=validation_status,
            version_info=version_info,
            affected_schedules=affected_schedules,
            message=f"Шаблон '{original_template.template_name}' изменен ({modification_type}). Затронуто расписаний: {len(affected_schedules)}"
        )
        
    except Exception as e:
        await db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Ошибка изменения шаблона: {str(e)}"
        )

@router.get("/schedules/templates/{template_id}/versions", tags=["🔥 REAL Schedule Templates"])
async def get_template_versions(
    template_id: UUID,
    db: AsyncSession = Depends(get_db)
):
    """Get version history for a template"""
    try:
        query = text("""
            SELECT 
                tv.id,
                tv.version_number,
                tv.modification_reason,
                tv.changes_summary,
                tv.created_at,
                st_new.template_name as new_template_name,
                st_new.is_active as new_template_active,
                st_orig.template_name as original_template_name
            FROM template_versions tv
            JOIN schedule_templates st_new ON tv.new_template_id = st_new.id
            JOIN schedule_templates st_orig ON tv.original_template_id = st_orig.id
            WHERE tv.original_template_id = :template_id
            ORDER BY tv.version_number DESC
        """)
        
        result = await db.execute(query, {"template_id": template_id})
        versions = []
        
        for row in result.fetchall():
            changes = json.loads(row.changes_summary) if row.changes_summary else {}
            versions.append({
                "version_id": str(row.id),
                "номер_версии": row.version_number,
                "причина_изменения": row.modification_reason,
                "измененные_поля": changes.get("измененные_поля", []),
                "значимые_изменения": changes.get("значимые_изменения", []),
                "название_новое": row.new_template_name,
                "название_оригинал": row.original_template_name,
                "активная_версия": row.new_template_active,
                "дата_создания": row.created_at.isoformat()
            })
        
        return {
            "template_id": str(template_id),
            "version_history": versions,
            "total_versions": len(versions)
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Ошибка получения истории версий: {str(e)}"
        )