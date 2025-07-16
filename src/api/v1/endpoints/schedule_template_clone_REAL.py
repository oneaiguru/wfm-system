"""
REAL SCHEDULE TEMPLATE CLONING ENDPOINT
Task 33/50: Template Cloning and Customization
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

class TemplateCloneRequest(BaseModel):
    source_template_id: UUID
    new_template_name: str
    target_department_id: Optional[UUID] = None  # If None, same department
    customizations: Optional[Dict[str, Any]] = None
    clone_reason: str = "создание_вариации"  # Russian text
    inherit_settings: Optional[bool] = True
    copy_usage_history: Optional[bool] = False

class TemplateCloneResponse(BaseModel):
    new_template_id: str
    source_template_id: str
    clone_summary: Dict[str, Any]
    customizations_applied: List[str]
    validation_status: str
    compatibility_report: Dict[str, Any]
    message: str

@router.post("/schedules/templates/clone", response_model=TemplateCloneResponse, tags=["🔥 REAL Schedule Templates"])
async def clone_schedule_template(
    request: TemplateCloneRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    REAL SCHEDULE TEMPLATE CLONING - NO MOCKS!
    
    Creates new templates based on existing ones with customizations
    Uses real schedule_templates and template_clones tables
    Supports Russian clone reasons and cross-department cloning
    
    UNBLOCKS: Template replication and customization workflows
    """
    try:
        # Get source template
        source_query = text("""
            SELECT 
                st.*,
                os.department_name,
                os.department_type
            FROM schedule_templates st
            JOIN organizational_structure os ON st.department_id = os.id
            WHERE st.id = :template_id
        """)
        
        source_result = await db.execute(source_query, {"template_id": request.source_template_id})
        source_template = source_result.fetchone()
        
        if not source_template:
            raise HTTPException(
                status_code=404,
                detail=f"Исходный шаблон {request.source_template_id} не найден"
            )
        
        # Determine target department
        target_department_id = request.target_department_id or source_template.department_id
        
        # Validate target department
        if target_department_id != source_template.department_id:
            target_dept_query = text("""
                SELECT id, department_name, department_type
                FROM organizational_structure 
                WHERE id = :dept_id
            """)
            
            target_dept_result = await db.execute(target_dept_query, {"dept_id": target_department_id})
            target_department = target_dept_result.fetchone()
            
            if not target_department:
                raise HTTPException(
                    status_code=404,
                    detail=f"Целевой отдел {target_department_id} не найден"
                )
        else:
            target_department = source_template
        
        # Check for duplicate names in target department
        duplicate_check = text("""
            SELECT COUNT(*) as count
            FROM schedule_templates 
            WHERE department_id = :dept_id 
            AND template_name = :name
            AND is_active = true
        """)
        
        duplicate_result = await db.execute(duplicate_check, {
            "dept_id": target_department_id,
            "name": request.new_template_name
        })
        
        if duplicate_result.scalar() > 0:
            raise HTTPException(
                status_code=422,
                detail=f"Шаблон с названием '{request.new_template_name}' уже существует в целевом отделе"
            )
        
        # Parse source template data
        source_shift_structure = json.loads(source_template.shift_structure) if source_template.shift_structure else {}
        source_settings = json.loads(source_template.template_settings) if source_template.template_settings else {}
        
        # Initialize cloned values with source data
        cloned_values = {
            'template_name': request.new_template_name,
            'template_type': source_template.template_type,
            'department_id': target_department_id,
            'working_hours_per_day': source_template.working_hours_per_day,
            'working_days_per_week': source_template.working_days_per_week,
            'break_duration_minutes': source_template.break_duration_minutes,
            'lunch_break_minutes': source_template.lunch_break_minutes,
            'cost_per_hour': source_template.cost_per_hour,
            'shift_structure': source_shift_structure.copy(),
            'template_settings': source_settings.copy() if request.inherit_settings else {}
        }
        
        # Apply customizations
        customizations_applied = []
        
        if request.customizations:
            for key, value in request.customizations.items():
                if key == "working_hours_per_day" and isinstance(value, (int, float)):
                    cloned_values['working_hours_per_day'] = value
                    customizations_applied.append(f"Изменены рабочие часы: {source_template.working_hours_per_day} → {value}")
                
                elif key == "working_days_per_week" and isinstance(value, int):
                    cloned_values['working_days_per_week'] = value
                    customizations_applied.append(f"Изменены рабочие дни: {source_template.working_days_per_week} → {value}")
                
                elif key == "template_type" and isinstance(value, str):
                    cloned_values['template_type'] = value
                    customizations_applied.append(f"Изменен тип шаблона: {source_template.template_type} → {value}")
                
                elif key == "cost_adjustment_percentage" and isinstance(value, (int, float)):
                    new_cost = source_template.cost_per_hour * (1 + value / 100)
                    cloned_values['cost_per_hour'] = new_cost
                    customizations_applied.append(f"Скорректирована стоимость на {value}%: {source_template.cost_per_hour} → {new_cost}")
                
                elif key == "shift_structure_updates" and isinstance(value, dict):
                    cloned_values['shift_structure'].update(value)
                    customizations_applied.append(f"Обновлена структура смены: {list(value.keys())}")
                
                elif key == "break_adjustments" and isinstance(value, dict):
                    if "break_duration_minutes" in value:
                        cloned_values['break_duration_minutes'] = value["break_duration_minutes"]
                        customizations_applied.append(f"Изменен перерыв: {source_template.break_duration_minutes} → {value['break_duration_minutes']} мин")
                    if "lunch_break_minutes" in value:
                        cloned_values['lunch_break_minutes'] = value["lunch_break_minutes"]
                        customizations_applied.append(f"Изменен обед: {source_template.lunch_break_minutes} → {value['lunch_break_minutes']} мин")
        
        # Validate cloned template
        validation_checks = {
            "рабочие_часы": 1 <= cloned_values['working_hours_per_day'] <= 24,
            "рабочие_дни": 1 <= cloned_values['working_days_per_week'] <= 7,
            "стоимость": cloned_values['cost_per_hour'] > 0,
            "название_уникально": True,  # Already checked above
            "структура_смены": isinstance(cloned_values['shift_structure'], dict)
        }
        
        validation_status = "валидный" if all(validation_checks.values()) else "требует_исправлений"
        
        if validation_status != "валидный":
            failed_checks = [check for check, passed in validation_checks.items() if not passed]
            raise HTTPException(
                status_code=422,
                detail=f"Ошибки валидации клонированного шаблона: {', '.join(failed_checks)}"
            )
        
        # Compatibility analysis
        is_cross_department = target_department_id != source_template.department_id
        
        compatibility_report = {
            "межотдельное_клонирование": is_cross_department,
            "исходный_отдел": source_template.department_name,
            "целевой_отдел": target_department.department_name if is_cross_department else source_template.department_name,
            "совместимость_типа_отдела": target_department.department_type == source_template.department_type if is_cross_department else True,
            "рекомендации": []
        }
        
        if is_cross_department:
            if target_department.department_type != source_template.department_type:
                compatibility_report["рекомендации"].append("Различные типы отделов - рекомендуется дополнительная настройка")
            
            # Check if cost needs adjustment for different department
            if abs(cloned_values['cost_per_hour'] - source_template.cost_per_hour) < 50:
                compatibility_report["рекомендации"].append("Рассмотрите корректировку стоимости для другого отдела")
        
        # Calculate updated settings
        total_weekly_hours = cloned_values['working_hours_per_day'] * cloned_values['working_days_per_week']
        break_time_daily = (cloned_values['break_duration_minutes'] or 0) + (cloned_values['lunch_break_minutes'] or 0)
        net_working_hours_daily = cloned_values['working_hours_per_day'] - (break_time_daily / 60)
        
        updated_settings = {
            **cloned_values['template_settings'],
            "рабочие_часы_день": cloned_values['working_hours_per_day'],
            "рабочие_дни_неделя": cloned_values['working_days_per_week'],
            "общие_часы_неделя": total_weekly_hours,
            "перерывы_минуты": cloned_values['break_duration_minutes'] or 0,
            "обед_минуты": cloned_values['lunch_break_minutes'] or 0,
            "чистые_часы_день": net_working_hours_daily,
            "базовая_стоимость_час": cloned_values['cost_per_hour'],
            "клонирован_из": str(request.source_template_id),
            "причина_клонирования": request.clone_reason,
            "дата_клонирования": datetime.utcnow().isoformat()
        }
        
        # Create cloned template
        new_template_id = str(uuid.uuid4())
        current_time = datetime.utcnow()
        
        clone_template_query = text("""
            INSERT INTO schedule_templates 
            (id, template_name, template_type, department_id, shift_structure,
             working_hours_per_day, working_days_per_week, break_duration_minutes,
             lunch_break_minutes, cost_per_hour, template_settings, 
             validation_status, is_active, created_at, updated_at, cloned_from_id)
            VALUES 
            (:id, :name, :type, :dept_id, :structure,
             :hours_day, :days_week, :break_min, :lunch_min, :cost_hour, 
             :settings, :validation, true, :created, :updated, :cloned_from)
            RETURNING id
        """)
        
        await db.execute(clone_template_query, {
            'id': new_template_id,
            'name': cloned_values['template_name'],
            'type': cloned_values['template_type'],
            'dept_id': cloned_values['department_id'],
            'structure': json.dumps(cloned_values['shift_structure']),
            'hours_day': cloned_values['working_hours_per_day'],
            'days_week': cloned_values['working_days_per_week'],
            'break_min': cloned_values['break_duration_minutes'] or 0,
            'lunch_min': cloned_values['lunch_break_minutes'] or 0,
            'cost_hour': cloned_values['cost_per_hour'],
            'settings': json.dumps(updated_settings),
            'validation': validation_status,
            'created': current_time,
            'updated': current_time,
            'cloned_from': request.source_template_id
        })
        
        # Record clone operation
        clone_record_query = text("""
            INSERT INTO template_clones 
            (id, source_template_id, new_template_id, clone_reason,
             customizations_applied, target_department_id, created_at)
            VALUES 
            (:id, :source_id, :new_id, :reason,
             :customizations, :target_dept, :created)
        """)
        
        await db.execute(clone_record_query, {
            'id': str(uuid.uuid4()),
            'source_id': request.source_template_id,
            'new_id': new_template_id,
            'reason': request.clone_reason,
            'customizations': json.dumps(customizations_applied),
            'target_dept': target_department_id,
            'created': current_time
        })
        
        await db.commit()
        
        # Build clone summary
        clone_summary = {
            "исходный_шаблон": source_template.template_name,
            "новый_шаблон": request.new_template_name,
            "тип_клонирования": "межотдельное" if is_cross_department else "внутриотдельное",
            "наследованы_настройки": request.inherit_settings,
            "применено_кастомизаций": len(customizations_applied),
            "сохранена_история": request.copy_usage_history,
            "совместимость": compatibility_report["совместимость_типа_отдела"]
        }
        
        return TemplateCloneResponse(
            new_template_id=new_template_id,
            source_template_id=str(request.source_template_id),
            clone_summary=clone_summary,
            customizations_applied=customizations_applied,
            validation_status=validation_status,
            compatibility_report=compatibility_report,
            message=f"Шаблон '{source_template.template_name}' клонирован как '{request.new_template_name}' с {len(customizations_applied)} кастомизациями"
        )
        
    except Exception as e:
        await db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Ошибка клонирования шаблона: {str(e)}"
        )

@router.get("/schedules/templates/{template_id}/clones", tags=["🔥 REAL Schedule Templates"])
async def get_template_clones(
    template_id: UUID,
    db: AsyncSession = Depends(get_db)
):
    """Get all clones created from a source template"""
    try:
        query = text("""
            SELECT 
                tc.id,
                tc.new_template_id,
                tc.clone_reason,
                tc.customizations_applied,
                tc.created_at,
                st.template_name,
                st.is_active,
                os.department_name,
                COUNT(ws.id) as usage_count
            FROM template_clones tc
            JOIN schedule_templates st ON tc.new_template_id = st.id
            JOIN organizational_structure os ON st.department_id = os.id
            LEFT JOIN work_schedules_core ws ON ws.template_id = st.id
            WHERE tc.source_template_id = :template_id
            GROUP BY tc.id, tc.new_template_id, tc.clone_reason, tc.customizations_applied,
                     tc.created_at, st.template_name, st.is_active, os.department_name
            ORDER BY tc.created_at DESC
        """)
        
        result = await db.execute(query, {"template_id": template_id})
        clones = []
        
        for row in result.fetchall():
            customizations = json.loads(row.customizations_applied) if row.customizations_applied else []
            clones.append({
                "clone_id": str(row.id),
                "template_id": str(row.new_template_id),
                "название": row.template_name,
                "отдел": row.department_name,
                "причина_клонирования": row.clone_reason,
                "кастомизации": customizations,
                "количество_кастомизаций": len(customizations),
                "активный": row.is_active,
                "использований": row.usage_count or 0,
                "дата_создания": row.created_at.isoformat()
            })
        
        return {
            "source_template_id": str(template_id),
            "clones": clones,
            "total_clones": len(clones)
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Ошибка получения клонов шаблона: {str(e)}"
        )