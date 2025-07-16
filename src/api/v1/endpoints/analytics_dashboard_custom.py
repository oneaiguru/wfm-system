"""
Analytics & BI API - Task 78: POST /api/v1/analytics/dashboard/custom
Custom dashboard creation with interactive widgets
Features: Drag-drop interface, real-time data, custom visualizations, filtering
Database: dashboard_definitions, widget_configs, user_preferences
"""

from fastapi import APIRouter, HTTPException, Depends, Query
from pydantic import BaseModel, Field
from typing import Dict, Any, List, Optional, Union
from datetime import datetime, timedelta
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
import json
import uuid

from src.api.core.database import get_db
from src.api.middleware.auth import api_key_header

router = APIRouter()

class WidgetPosition(BaseModel):
    x: int = Field(..., ge=0)
    y: int = Field(..., ge=0)
    width: int = Field(..., ge=1, le=12)
    height: int = Field(..., ge=1, le=20)

class DataSource(BaseModel):
    type: str = Field(..., regex="^(sql_query|api_endpoint|real_time_stream)$")
    source: str  # SQL query, API endpoint URL, or stream name
    refresh_interval_seconds: int = Field(30, ge=5, le=3600)
    parameters: Optional[Dict[str, Any]] = {}

class VisualizationConfig(BaseModel):
    chart_type: str = Field(..., regex="^(line|bar|pie|donut|scatter|heatmap|gauge|table|kpi|map)$")
    x_axis: Optional[str] = None
    y_axis: Optional[str] = None
    color_field: Optional[str] = None
    aggregation: Optional[str] = Field(None, regex="^(sum|avg|count|min|max)$")
    chart_options: Optional[Dict[str, Any]] = {}

class FilterConfig(BaseModel):
    field: str
    type: str = Field(..., regex="^(select|date_range|number_range|text_search|multi_select)$")
    options: Optional[List[str]] = []
    default_value: Optional[Union[str, List[str], Dict[str, Any]]] = None

class WidgetConfig(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    title: str = Field(..., min_length=1, max_length=200)
    type: str = Field(..., regex="^(chart|kpi|table|text|filter|map)$")
    position: WidgetPosition
    data_source: DataSource
    visualization: Optional[VisualizationConfig] = None
    filters: Optional[List[FilterConfig]] = []
    styling: Optional[Dict[str, Any]] = {}
    interactions: Optional[Dict[str, Any]] = {}

class DashboardLayout(BaseModel):
    theme: str = Field("light", regex="^(light|dark|auto)$")
    grid_columns: int = Field(12, ge=6, le=24)
    auto_refresh: bool = Field(True)
    refresh_interval_seconds: int = Field(60, ge=10, le=3600)
    responsive: bool = Field(True)

class CustomDashboardRequest(BaseModel):
    name: str = Field(..., min_length=1, max_length=200)
    description: Optional[str] = None
    layout: DashboardLayout
    widgets: List[WidgetConfig] = Field(..., min_items=1, max_items=50)
    is_public: bool = Field(False)
    tags: Optional[List[str]] = []

class DashboardMetadata(BaseModel):
    dashboard_id: str
    name: str
    description: Optional[str]
    created_at: datetime
    updated_at: datetime
    created_by: str
    widgets_count: int
    is_public: bool
    tags: List[str]

class CustomDashboardResponse(BaseModel):
    dashboard: DashboardMetadata
    layout: DashboardLayout
    widgets: List[WidgetConfig]
    real_time_endpoints: List[str]
    export_options: List[str]

# Predefined data sources for dashboards
DASHBOARD_DATA_SOURCES = {
    "agent_performance": {
        "sql": """
        SELECT 
            af.agent_id,
            za.full_name,
            af.avg_handle_time_30d,
            af.occupancy_rate_30d,
            af.schedule_adherence_30d,
            af.feature_date
        FROM ml_agent_features af
        JOIN zup_agent_data za ON af.agent_id::text = za.tab_n
        WHERE af.feature_date >= CURRENT_DATE - INTERVAL '30 days'
        ORDER BY af.feature_date DESC
        """,
        "refresh_interval": 300  # 5 minutes
    },
    "queue_metrics": {
        "sql": """
        SELECT 
            queue_id,
            interval_start,
            call_volume_ma_15min,
            call_volume_ma_1h,
            hour_of_day,
            day_of_week
        FROM ml_queue_features
        WHERE interval_start >= CURRENT_TIMESTAMP - INTERVAL '24 hours'
        ORDER BY interval_start DESC
        """,
        "refresh_interval": 60  # 1 minute
    },
    "schedule_adherence": {
        "sql": """
        SELECT 
            am.employee_tab_n,
            za.full_name,
            am.report_date,
            am.individual_adherence_pct,
            am.adherence_color,
            am.planned_schedule_time,
            am.actual_worked_time
        FROM adherence_metrics am
        JOIN zup_agent_data za ON am.employee_tab_n = za.tab_n
        WHERE am.report_date >= CURRENT_DATE - INTERVAL '7 days'
        ORDER BY am.report_date DESC, am.individual_adherence_pct ASC
        """,
        "refresh_interval": 900  # 15 minutes
    },
    "real_time_volume": {
        "sql": """
        SELECT 
            DATE_TRUNC('hour', interval_start) as hour,
            SUM(call_volume_ma_15min) as total_volume,
            AVG(call_volume_ma_15min) as avg_volume,
            COUNT(*) as data_points
        FROM ml_queue_features
        WHERE interval_start >= CURRENT_DATE
        GROUP BY DATE_TRUNC('hour', interval_start)
        ORDER BY hour DESC
        """,
        "refresh_interval": 60  # 1 minute
    },
    "department_kpis": {
        "sql": """
        SELECT 
            za.department,
            COUNT(DISTINCT za.tab_n) as total_agents,
            AVG(af.schedule_adherence_30d) as avg_adherence,
            AVG(af.occupancy_rate_30d) as avg_occupancy,
            AVG(af.avg_handle_time_30d) as avg_handle_time
        FROM zup_agent_data za
        LEFT JOIN ml_agent_features af ON za.tab_n = af.agent_id::text
        WHERE za.is_active = true
        GROUP BY za.department
        ORDER BY avg_adherence DESC
        """,
        "refresh_interval": 1800  # 30 minutes
    }
}

# Widget templates for common use cases
WIDGET_TEMPLATES = {
    "agent_performance_chart": {
        "title": "Agent Performance Trends",
        "type": "chart",
        "data_source": "agent_performance",
        "visualization": {
            "chart_type": "line",
            "x_axis": "feature_date",
            "y_axis": "schedule_adherence_30d",
            "color_field": "full_name"
        }
    },
    "queue_volume_gauge": {
        "title": "Current Queue Volume",
        "type": "chart",
        "data_source": "real_time_volume",
        "visualization": {
            "chart_type": "gauge",
            "value_field": "total_volume",
            "min_value": 0,
            "max_value": 1000
        }
    },
    "adherence_heatmap": {
        "title": "Schedule Adherence Heatmap",
        "type": "chart",
        "data_source": "schedule_adherence",
        "visualization": {
            "chart_type": "heatmap",
            "x_axis": "report_date",
            "y_axis": "full_name",
            "value_field": "individual_adherence_pct"
        }
    },
    "department_kpis_table": {
        "title": "Department KPIs",
        "type": "table",
        "data_source": "department_kpis",
        "visualization": {
            "columns": ["department", "total_agents", "avg_adherence", "avg_occupancy"]
        }
    }
}

@router.post("/api/v1/analytics/dashboard/custom", response_model=CustomDashboardResponse)
async def create_custom_dashboard(
    request: CustomDashboardRequest,
    db: AsyncSession = Depends(get_db),
    api_key: str = Depends(api_key_header)
):
    """
    Create custom dashboard with interactive widgets.
    
    Features:
    - Drag-and-drop widget positioning
    - Real-time data updates with configurable refresh rates
    - Multiple visualization types (charts, KPIs, tables, maps)
    - Interactive filtering and drill-down capabilities
    - Responsive layout for different screen sizes
    - Export options (PDF, PNG, CSV)
    - User permission management
    
    Args:
        request: Dashboard configuration with layout and widgets
        
    Returns:
        CustomDashboardResponse: Created dashboard with metadata
    """
    
    try:
        dashboard_id = str(uuid.uuid4())
        created_at = datetime.utcnow()
        
        # Validate widget positions don't overlap
        positions = [(w.position.x, w.position.y, w.position.width, w.position.height) for w in request.widgets]
        for i, pos1 in enumerate(positions):
            for j, pos2 in enumerate(positions[i+1:], i+1):
                if widgets_overlap(pos1, pos2):
                    raise HTTPException(
                        status_code=400,
                        detail=f"Widgets {i} and {j} have overlapping positions"
                    )
        
        # Validate data sources
        for widget in request.widgets:
            if widget.data_source.type == "sql_query":
                # Validate SQL is safe (basic check)
                if not is_safe_sql(widget.data_source.source):
                    raise HTTPException(
                        status_code=400,
                        detail=f"Unsafe SQL detected in widget '{widget.title}'"
                    )
        
        # Store dashboard definition
        dashboard_query = """
        INSERT INTO dashboard_definitions (
            id, name, description, layout_config, created_by, is_public, tags, created_at, updated_at
        ) VALUES (
            :id, :name, :description, :layout_config, :created_by, :is_public, :tags, :created_at, :updated_at
        )
        """
        
        await db.execute(text(dashboard_query), {
            "id": dashboard_id,
            "name": request.name,
            "description": request.description,
            "layout_config": json.dumps(request.layout.dict()),
            "created_by": api_key[:10],
            "is_public": request.is_public,
            "tags": json.dumps(request.tags or []),
            "created_at": created_at,
            "updated_at": created_at
        })
        
        # Store widget configurations
        for widget in request.widgets:
            widget_query = """
            INSERT INTO widget_configs (
                id, dashboard_id, title, type, position_config, data_source_config,
                visualization_config, filters_config, styling_config, interactions_config
            ) VALUES (
                :id, :dashboard_id, :title, :type, :position_config, :data_source_config,
                :visualization_config, :filters_config, :styling_config, :interactions_config
            )
            """
            
            await db.execute(text(widget_query), {
                "id": widget.id,
                "dashboard_id": dashboard_id,
                "title": widget.title,
                "type": widget.type,
                "position_config": json.dumps(widget.position.dict()),
                "data_source_config": json.dumps(widget.data_source.dict()),
                "visualization_config": json.dumps(widget.visualization.dict() if widget.visualization else {}),
                "filters_config": json.dumps([f.dict() for f in (widget.filters or [])]),
                "styling_config": json.dumps(widget.styling or {}),
                "interactions_config": json.dumps(widget.interactions or {})
            })
        
        await db.commit()
        
        # Generate real-time endpoints for widgets with real-time data
        real_time_endpoints = []
        for widget in request.widgets:
            if widget.data_source.refresh_interval_seconds <= 60:  # Real-time threshold
                endpoint = f"/api/v1/analytics/dashboard/{dashboard_id}/widget/{widget.id}/data"
                real_time_endpoints.append(endpoint)
        
        # Create response
        dashboard_metadata = DashboardMetadata(
            dashboard_id=dashboard_id,
            name=request.name,
            description=request.description,
            created_at=created_at,
            updated_at=created_at,
            created_by=api_key[:10],
            widgets_count=len(request.widgets),
            is_public=request.is_public,
            tags=request.tags or []
        )
        
        response = CustomDashboardResponse(
            dashboard=dashboard_metadata,
            layout=request.layout,
            widgets=request.widgets,
            real_time_endpoints=real_time_endpoints,
            export_options=["pdf", "png", "csv", "json"]
        )
        
        return response
        
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"Dashboard creation failed: {str(e)}")

def widgets_overlap(pos1, pos2):
    """Check if two widget positions overlap"""
    x1, y1, w1, h1 = pos1
    x2, y2, w2, h2 = pos2
    
    # Check if rectangles don't overlap
    if (x1 >= x2 + w2 or x2 >= x1 + w1 or y1 >= y2 + h2 or y2 >= y1 + h1):
        return False
    
    return True

def is_safe_sql(sql_query: str) -> bool:
    """Basic SQL safety check"""
    dangerous_keywords = [
        "DROP", "DELETE", "UPDATE", "INSERT", "ALTER", "CREATE", "TRUNCATE",
        "EXEC", "EXECUTE", "GRANT", "REVOKE", "--", "/*", "*/"
    ]
    
    upper_query = sql_query.upper()
    for keyword in dangerous_keywords:
        if keyword in upper_query:
            return False
    
    return True

@router.get("/api/v1/analytics/dashboard/{dashboard_id}/widget/{widget_id}/data")
async def get_widget_data(
    dashboard_id: str,
    widget_id: str,
    refresh: bool = Query(False),
    db: AsyncSession = Depends(get_db),
    api_key: str = Depends(api_key_header)
):
    """
    Get data for a specific dashboard widget.
    
    Args:
        dashboard_id: Dashboard identifier
        widget_id: Widget identifier
        refresh: Force refresh data (ignore cache)
        
    Returns:
        Dict: Widget data and metadata
    """
    
    try:
        # Get widget configuration
        widget_query = """
        SELECT data_source_config, visualization_config
        FROM widget_configs
        WHERE id = :widget_id AND dashboard_id = :dashboard_id
        """
        
        result = await db.execute(text(widget_query), {
            "widget_id": widget_id,
            "dashboard_id": dashboard_id
        })
        
        widget_row = result.fetchone()
        if not widget_row:
            raise HTTPException(status_code=404, detail="Widget not found")
        
        data_source_config = json.loads(widget_row.data_source_config)
        visualization_config = json.loads(widget_row.visualization_config)
        
        # Execute data source query
        if data_source_config["type"] == "sql_query":
            sql_query = data_source_config["source"]
            
            # Add parameters if provided
            parameters = data_source_config.get("parameters", {})
            
            # Execute query
            data_result = await db.execute(text(sql_query), parameters)
            rows = data_result.fetchall()
            
            # Convert to list of dictionaries
            columns = data_result.keys()
            data = [dict(zip(columns, row)) for row in rows]
            
        elif data_source_config["type"] == "api_endpoint":
            # For API endpoints, we would make HTTP requests
            data = {"message": "API endpoint data source not implemented in this demo"}
            
        else:  # real_time_stream
            # For real-time streams, we would connect to WebSocket or SSE
            data = {"message": "Real-time stream data source not implemented in this demo"}
        
        return {
            "widget_id": widget_id,
            "dashboard_id": dashboard_id,
            "data": data,
            "visualization_config": visualization_config,
            "last_updated": datetime.utcnow(),
            "refresh_interval": data_source_config.get("refresh_interval_seconds", 60)
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Widget data retrieval failed: {str(e)}")

@router.get("/api/v1/analytics/dashboard/templates")
async def get_dashboard_templates(
    api_key: str = Depends(api_key_header)
):
    """
    Get available dashboard and widget templates.
    
    Returns:
        Dict: Available templates and data sources
    """
    
    return {
        "widget_templates": WIDGET_TEMPLATES,
        "data_sources": DASHBOARD_DATA_SOURCES,
        "chart_types": [
            "line", "bar", "pie", "donut", "scatter", "heatmap", 
            "gauge", "table", "kpi", "map"
        ],
        "filter_types": [
            "select", "date_range", "number_range", "text_search", "multi_select"
        ],
        "themes": ["light", "dark", "auto"]
    }

@router.get("/api/v1/analytics/dashboard/list")
async def list_dashboards(
    is_public: Optional[bool] = Query(None),
    tags: Optional[str] = Query(None),
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
    api_key: str = Depends(api_key_header)
):
    """
    List available dashboards.
    
    Args:
        is_public: Filter by public/private dashboards
        tags: Filter by tags (comma-separated)
        limit: Maximum number of dashboards to return
        offset: Number of dashboards to skip
        
    Returns:
        Dict: List of dashboards with metadata
    """
    
    where_conditions = []
    params = {"limit": limit, "offset": offset}
    
    if is_public is not None:
        where_conditions.append("is_public = :is_public")
        params["is_public"] = is_public
    
    if tags:
        tag_list = [tag.strip() for tag in tags.split(",")]
        where_conditions.append("tags::jsonb ?| :tags")
        params["tags"] = tag_list
    
    where_clause = "WHERE " + " AND ".join(where_conditions) if where_conditions else ""
    
    query = f"""
    SELECT 
        dd.id, dd.name, dd.description, dd.created_at, dd.updated_at,
        dd.created_by, dd.is_public, dd.tags,
        COUNT(wc.id) as widgets_count
    FROM dashboard_definitions dd
    LEFT JOIN widget_configs wc ON dd.id = wc.dashboard_id
    {where_clause}
    GROUP BY dd.id, dd.name, dd.description, dd.created_at, dd.updated_at,
             dd.created_by, dd.is_public, dd.tags
    ORDER BY dd.updated_at DESC
    LIMIT :limit OFFSET :offset
    """
    
    result = await db.execute(text(query), params)
    dashboards = result.fetchall()
    
    # Get total count
    count_query = f"SELECT COUNT(*) as total FROM dashboard_definitions dd {where_clause}"
    count_params = {k: v for k, v in params.items() if k not in ["limit", "offset"]}
    count_result = await db.execute(text(count_query), count_params)
    total = count_result.scalar()
    
    # Convert rows to dictionaries and parse JSON fields
    dashboard_list = []
    for row in dashboards:
        dashboard_dict = dict(row._mapping)
        dashboard_dict["tags"] = json.loads(dashboard_dict["tags"] or "[]")
        dashboard_list.append(dashboard_dict)
    
    return {
        "dashboards": dashboard_list,
        "total": total,
        "limit": limit,
        "offset": offset
    }

@router.get("/api/v1/analytics/dashboard/{dashboard_id}")
async def get_dashboard(
    dashboard_id: str,
    db: AsyncSession = Depends(get_db),
    api_key: str = Depends(api_key_header)
):
    """
    Get a specific dashboard with all its widgets.
    
    Args:
        dashboard_id: Dashboard identifier
        
    Returns:
        CustomDashboardResponse: Complete dashboard configuration
    """
    
    try:
        # Get dashboard definition
        dashboard_query = """
        SELECT id, name, description, layout_config, created_by, is_public, 
               tags, created_at, updated_at
        FROM dashboard_definitions
        WHERE id = :dashboard_id
        """
        
        result = await db.execute(text(dashboard_query), {"dashboard_id": dashboard_id})
        dashboard_row = result.fetchone()
        
        if not dashboard_row:
            raise HTTPException(status_code=404, detail="Dashboard not found")
        
        # Get widget configurations
        widgets_query = """
        SELECT id, title, type, position_config, data_source_config,
               visualization_config, filters_config, styling_config, interactions_config
        FROM widget_configs
        WHERE dashboard_id = :dashboard_id
        ORDER BY position_config->>'y', position_config->>'x'
        """
        
        widgets_result = await db.execute(text(widgets_query), {"dashboard_id": dashboard_id})
        widget_rows = widgets_result.fetchall()
        
        # Convert to Pydantic models
        layout = DashboardLayout(**json.loads(dashboard_row.layout_config))
        
        widgets = []
        real_time_endpoints = []
        
        for widget_row in widget_rows:
            position = WidgetPosition(**json.loads(widget_row.position_config))
            data_source = DataSource(**json.loads(widget_row.data_source_config))
            
            visualization_data = json.loads(widget_row.visualization_config)
            visualization = VisualizationConfig(**visualization_data) if visualization_data else None
            
            filters_data = json.loads(widget_row.filters_config)
            filters = [FilterConfig(**f) for f in filters_data] if filters_data else []
            
            widget = WidgetConfig(
                id=widget_row.id,
                title=widget_row.title,
                type=widget_row.type,
                position=position,
                data_source=data_source,
                visualization=visualization,
                filters=filters,
                styling=json.loads(widget_row.styling_config),
                interactions=json.loads(widget_row.interactions_config)
            )
            
            widgets.append(widget)
            
            # Add real-time endpoint if applicable
            if data_source.refresh_interval_seconds <= 60:
                endpoint = f"/api/v1/analytics/dashboard/{dashboard_id}/widget/{widget.id}/data"
                real_time_endpoints.append(endpoint)
        
        # Create metadata
        dashboard_metadata = DashboardMetadata(
            dashboard_id=dashboard_row.id,
            name=dashboard_row.name,
            description=dashboard_row.description,
            created_at=dashboard_row.created_at,
            updated_at=dashboard_row.updated_at,
            created_by=dashboard_row.created_by,
            widgets_count=len(widgets),
            is_public=dashboard_row.is_public,
            tags=json.loads(dashboard_row.tags or "[]")
        )
        
        response = CustomDashboardResponse(
            dashboard=dashboard_metadata,
            layout=layout,
            widgets=widgets,
            real_time_endpoints=real_time_endpoints,
            export_options=["pdf", "png", "csv", "json"]
        )
        
        return response
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Dashboard retrieval failed: {str(e)}")

# Create required database tables
async def create_dashboard_tables(db: AsyncSession):
    """Create dashboard tables if they don't exist"""
    
    tables_sql = """
    -- Dashboard definitions
    CREATE TABLE IF NOT EXISTS dashboard_definitions (
        id UUID PRIMARY KEY,
        name VARCHAR(200) NOT NULL,
        description TEXT,
        layout_config JSONB NOT NULL,
        created_by VARCHAR(50) NOT NULL,
        is_public BOOLEAN DEFAULT false,
        tags JSONB DEFAULT '[]',
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Widget configurations
    CREATE TABLE IF NOT EXISTS widget_configs (
        id VARCHAR(255) PRIMARY KEY,
        dashboard_id UUID NOT NULL REFERENCES dashboard_definitions(id) ON DELETE CASCADE,
        title VARCHAR(200) NOT NULL,
        type VARCHAR(50) NOT NULL,
        position_config JSONB NOT NULL,
        data_source_config JSONB NOT NULL,
        visualization_config JSONB DEFAULT '{}',
        filters_config JSONB DEFAULT '[]',
        styling_config JSONB DEFAULT '{}',
        interactions_config JSONB DEFAULT '{}',
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- User preferences for dashboards
    CREATE TABLE IF NOT EXISTS user_preferences (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        user_id VARCHAR(50) NOT NULL,
        dashboard_id UUID NOT NULL REFERENCES dashboard_definitions(id) ON DELETE CASCADE,
        preferences JSONB NOT NULL DEFAULT '{}',
        is_favorite BOOLEAN DEFAULT false,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id, dashboard_id)
    );
    
    CREATE INDEX IF NOT EXISTS idx_dashboard_definitions_public ON dashboard_definitions(is_public);
    CREATE INDEX IF NOT EXISTS idx_dashboard_definitions_created_by ON dashboard_definitions(created_by);
    CREATE INDEX IF NOT EXISTS idx_widget_configs_dashboard ON widget_configs(dashboard_id);
    CREATE INDEX IF NOT EXISTS idx_user_preferences_user ON user_preferences(user_id);
    """
    
    await db.execute(text(tables_sql))
    await db.commit()