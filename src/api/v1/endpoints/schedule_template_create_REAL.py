"""
REAL SCHEDULE TEMPLATE CREATION ENDPOINT
Task 31/50: Schedule Template Creation and Management
"""

from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from pydantic import BaseModel
from datetime import datetime, time
from typing import Optional, List, Dict, Any
from uuid import UUID
import uuid
import json

from ...core.database import get_db

router = APIRouter()

class ScheduleTemplateCreate(BaseModel):
    template_name: str
    template_type: str = "стандартный"  # Russian template types
    department_id: UUID
    shift_structure: Dict[str, Any]
    working_hours_per_day: float = 8.0
    working_days_per_week: int = 5
    break_duration_minutes: Optional[int] = 60
    lunch_break_minutes: Optional[int] = 30
    overtime_rules: Optional[Dict[str, Any]] = None
    holiday_rules: Optional[Dict[str, Any]] = None
    rotation_pattern: Optional[str] = None

class ScheduleTemplateResponse(BaseModel):
    template_id: str
    template_name: str
    template_type: str
    department_id: str
    shift_structure: Dict[str, Any]
    template_settings: Dict[str, Any]
    validation_status: str
    usage_statistics: Dict[str, Any]
    message: str

@router.post("/schedules/templates/create", response_model=ScheduleTemplateResponse, tags=["🔥 REAL Schedule Templates"])
async def create_schedule_template(
    request: ScheduleTemplateCreate,
    db: AsyncSession = Depends(get_db)
):
    """
    REAL SCHEDULE TEMPLATE CREATION - NO MOCKS!
    
    Creates reusable schedule templates for departments
    Uses real schedule_templates and organizational_structure tables
    Supports Russian template types and shift structures
    
    UNBLOCKS: Template-based scheduling workflows
    """
    try:
        # Validate department exists
        dept_check = text("""
            SELECT id, department_name, department_type
            FROM organizational_structure 
            WHERE id = :department_id
        """)
        
        dept_result = await db.execute(dept_check, {"department_id": request.department_id})
        department = dept_result.fetchone()
        
        if not department:
            raise HTTPException(
                status_code=404,
                detail=f"Отдел {request.department_id} не найден"
            )
        
        # Check for duplicate template names in department
        duplicate_check = text("""
            SELECT COUNT(*) as count
            FROM schedule_templates 
            WHERE department_id = :department_id 
            AND template_name = :template_name
            AND is_active = true
        """)
        
        duplicate_result = await db.execute(duplicate_check, {
            "department_id": request.department_id,
            "template_name": request.template_name
        })
        
        if duplicate_result.scalar() > 0:
            raise HTTPException(
                status_code=422,
                detail=f"Шаблон с названием '{request.template_name}' уже существует в отделе '{department.department_name}'"
            )
        
        # Validate shift structure
        required_shift_fields = ["рабочие_дни", "время_начала", "время_окончания"]
        shift_validation = {
            "обязательные_поля": all(field in request.shift_structure for field in required_shift_fields),
            "недостающие_поля": [field for field in required_shift_fields if field not in request.shift_structure]
        }
        
        if not shift_validation["обязательные_поля"]:
            raise HTTPException(
                status_code=422,
                detail=f"Недостающие обязательные поля в структуре смены: {shift_validation['недостающие_поля']}"
            )
        
        # Validate working hours
        if request.working_hours_per_day < 1 or request.working_hours_per_day > 24:
            raise HTTPException(
                status_code=422,
                detail="Рабочие часы в день должны быть от 1 до 24"
            )
        
        if request.working_days_per_week < 1 or request.working_days_per_week > 7:
            raise HTTPException(
                status_code=422,
                detail="Рабочие дни в неделю должны быть от 1 до 7"
            )
        
        # Calculate template metrics
        total_weekly_hours = request.working_hours_per_day * request.working_days_per_week
        break_time_daily = (request.break_duration_minutes or 0) + (request.lunch_break_minutes or 0)
        net_working_hours_daily = request.working_hours_per_day - (break_time_daily / 60)
        
        # Determine cost per hour based on template type and department
        cost_mapping = {
            "стандартный": 1000,
            "сменный": 1200,
            "гибкий": 1100,
            "выходной": 1500,
            "праздничный": 1800
        }
        base_cost_per_hour = cost_mapping.get(request.template_type, 1000)
        
        # Build template settings
        template_settings = {
            "рабочие_часы_день": request.working_hours_per_day,
            "рабочие_дни_неделя": request.working_days_per_week,
            "общие_часы_неделя": total_weekly_hours,
            "перерывы_минуты": request.break_duration_minutes or 0,
            "обед_минуты": request.lunch_break_minutes or 0,
            "чистые_часы_день": net_working_hours_daily,
            "базовая_стоимость_час": base_cost_per_hour,
            "паттерн_ротации": request.rotation_pattern,
            "правила_переработки": request.overtime_rules or {},
            "правила_праздников": request.holiday_rules or {}
        }
        
        # Validation status
        validation_checks = {
            "структура_смены": shift_validation["обязательные_поля"],
            "рабочие_часы": 1 <= request.working_hours_per_day <= 24,
            "рабочие_дни": 1 <= request.working_days_per_week <= 7,
            "отдел_существует": bool(department),
            "уникальное_название": True  # Already checked above
        }
        
        validation_status = "валидный" if all(validation_checks.values()) else "требует_исправлений"
        
        # Create template record
        template_id = str(uuid.uuid4())
        current_time = datetime.utcnow()
        
        template_query = text("""
            INSERT INTO schedule_templates 
            (id, template_name, template_type, department_id, shift_structure,
             working_hours_per_day, working_days_per_week, break_duration_minutes,
             lunch_break_minutes, cost_per_hour, template_settings, 
             validation_status, is_active, created_at, updated_at)
            VALUES 
            (:id, :name, :type, :dept_id, :structure,
             :hours_day, :days_week, :break_min,
             :lunch_min, :cost_hour, :settings,
             :validation, :active, :created, :updated)
            RETURNING id
        """)
        
        await db.execute(template_query, {
            'id': template_id,
            'name': request.template_name,
            'type': request.template_type,
            'dept_id': request.department_id,
            'structure': json.dumps(request.shift_structure),
            'hours_day': request.working_hours_per_day,
            'days_week': request.working_days_per_week,
            'break_min': request.break_duration_minutes or 0,
            'lunch_min': request.lunch_break_minutes or 0,
            'cost_hour': base_cost_per_hour,
            'settings': json.dumps(template_settings),
            'validation': validation_status,
            'active': validation_status == "валидный",
            'created': current_time,
            'updated': current_time
        })
        
        await db.commit()
        
        # Initialize usage statistics
        usage_statistics = {
            "использований": 0,
            "активных_расписаний": 0,
            "средняя_эффективность": 0,
            "отзывы_пользователей": 0,
            "дата_создания": current_time.isoformat(),
            "статус": "новый"
        }
        
        return ScheduleTemplateResponse(
            template_id=template_id,
            template_name=request.template_name,
            template_type=request.template_type,
            department_id=str(request.department_id),
            shift_structure=request.shift_structure,
            template_settings=template_settings,
            validation_status=validation_status,
            usage_statistics=usage_statistics,
            message=f"Шаблон расписания '{request.template_name}' создан для отдела '{department.department_name}'. Статус: {validation_status}"
        )
        
    except Exception as e:
        await db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Ошибка создания шаблона расписания: {str(e)}"
        )

@router.get("/schedules/templates/department/{department_id}", tags=["🔥 REAL Schedule Templates"])
async def get_department_templates(
    department_id: UUID,
    template_type: Optional[str] = None,
    active_only: Optional[bool] = True,
    db: AsyncSession = Depends(get_db)
):
    """Get all schedule templates for a department"""
    try:
        query_conditions = ["st.department_id = :department_id"]
        params = {"department_id": department_id}
        
        if template_type:
            query_conditions.append("st.template_type = :template_type")
            params["template_type"] = template_type
            
        if active_only:
            query_conditions.append("st.is_active = true")
        
        query = text(f"""
            SELECT 
                st.id,
                st.template_name,
                st.template_type,
                st.working_hours_per_day,
                st.working_days_per_week,
                st.cost_per_hour,
                st.validation_status,
                st.is_active,
                st.created_at,
                st.updated_at,
                os.department_name,
                COUNT(ws.id) as usage_count
            FROM schedule_templates st
            JOIN organizational_structure os ON st.department_id = os.id
            LEFT JOIN work_schedules_core ws ON ws.template_id = st.id
            WHERE {' AND '.join(query_conditions)}
            GROUP BY st.id, st.template_name, st.template_type, st.working_hours_per_day,
                     st.working_days_per_week, st.cost_per_hour, st.validation_status,
                     st.is_active, st.created_at, st.updated_at, os.department_name
            ORDER BY st.created_at DESC
        """)
        
        result = await db.execute(query, params)
        templates = []
        
        for row in result.fetchall():
            total_weekly_hours = row.working_hours_per_day * row.working_days_per_week
            
            templates.append({
                "template_id": str(row.id),
                "название": row.template_name,
                "тип": row.template_type,
                "часы_день": row.working_hours_per_day,
                "дни_неделя": row.working_days_per_week,
                "часы_неделя": total_weekly_hours,
                "стоимость_час": row.cost_per_hour,
                "статус_валидации": row.validation_status,
                "активный": row.is_active,
                "использований": row.usage_count,
                "отдел": row.department_name,
                "создан": row.created_at.isoformat(),
                "обновлен": row.updated_at.isoformat()
            })
        
        return {
            "department_id": str(department_id),
            "filter_type": template_type or "все_типы",
            "active_only": active_only,
            "templates": templates,
            "total_templates": len(templates)
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Ошибка получения шаблонов отдела: {str(e)}"
        )

@router.get("/schedules/templates/{template_id}/details", tags=["🔥 REAL Schedule Templates"])
async def get_template_details(
    template_id: UUID,
    db: AsyncSession = Depends(get_db)
):
    """Get detailed information about a specific template"""
    try:
        query = text("""
            SELECT 
                st.*,
                os.department_name,
                COUNT(ws.id) as current_usage,
                AVG(ws.optimization_score) as avg_optimization_score
            FROM schedule_templates st
            JOIN organizational_structure os ON st.department_id = os.id
            LEFT JOIN work_schedules_core ws ON ws.template_id = st.id 
                AND ws.status IN ('active', 'pending')
            WHERE st.id = :template_id
            GROUP BY st.id, os.department_name
        """)
        
        result = await db.execute(query, {"template_id": template_id})
        template = result.fetchone()
        
        if not template:
            raise HTTPException(
                status_code=404,
                detail=f"Шаблон {template_id} не найден"
            )
        
        shift_structure = json.loads(template.shift_structure) if template.shift_structure else {}
        template_settings = json.loads(template.template_settings) if template.template_settings else {}
        
        return {
            "template_id": str(template.id),
            "название": template.template_name,
            "тип": template.template_type,
            "отдел": template.department_name,
            "структура_смены": shift_structure,
            "настройки": template_settings,
            "часы_день": template.working_hours_per_day,
            "дни_неделя": template.working_days_per_week,
            "перерыв_минуты": template.break_duration_minutes,
            "обед_минуты": template.lunch_break_minutes,
            "стоимость_час": template.cost_per_hour,
            "статус_валидации": template.validation_status,
            "активный": template.is_active,
            "статистика_использования": {
                "текущие_использования": template.current_usage or 0,
                "средний_балл_оптимизации": round(template.avg_optimization_score or 0, 2),
                "статус_популярности": "популярный" if (template.current_usage or 0) > 5 else "обычный"
            },
            "создан": template.created_at.isoformat(),
            "обновлен": template.updated_at.isoformat()
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Ошибка получения деталей шаблона: {str(e)}"
        )