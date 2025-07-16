-- API Contracts for realtime_metrics table
-- Comprehensive API documentation with Russian language support for operational monitoring

-- 1. GET /api/v1/metrics/realtime - List current metrics with filtering and thresholds
INSERT INTO api_contracts (
    endpoint_path,
    http_method,
    table_name,
    request_schema,
    response_schema,
    database_dependencies,
    example_request,
    example_response,
    validation_query
) VALUES (
    '/api/v1/metrics/realtime',
    'GET',
    'realtime_metrics',
    '{
        "type": "object",
        "properties": {
            "dashboard_category": {"type": "string", "enum": ["general", "operations", "quality", "performance"], "description": "Категория дашборда"},
            "metric_names": {"type": "array", "items": {"type": "string"}, "description": "Конкретные метрики"},
            "trend_direction": {"type": "string", "enum": ["up", "down", "stable"], "description": "Направление тренда"},
            "threshold_status": {"type": "string", "enum": ["normal", "warning", "critical"], "description": "Статус по порогам"},
            "include_inactive": {"type": "boolean", "default": false, "description": "Включить неактивные метрики"},
            "sort_by": {"type": "string", "enum": ["name", "value", "updated", "display_order"], "default": "display_order"},
            "limit": {"type": "integer", "default": 50, "maximum": 200}
        }
    }'::jsonb,
    '{
        "type": "object",
        "properties": {
            "data": {
                "type": "array",
                "items": {
                    "type": "object",
                    "properties": {
                        "id": {"type": "string", "format": "uuid"},
                        "metric_name": {"type": "string"},
                        "metric_value": {"type": "number"},
                        "metric_unit": {"type": "string"},
                        "previous_value": {"type": "number"},
                        "trend_direction": {"type": "string"},
                        "display_color": {"type": "string"},
                        "target_value": {"type": "number"},
                        "warning_threshold": {"type": "number"},
                        "critical_threshold": {"type": "number"},
                        "threshold_status": {"type": "string"},
                        "last_updated": {"type": "string", "format": "date-time"},
                        "calculation_time_ms": {"type": "integer"},
                        "dashboard_category": {"type": "string"},
                        "display_order": {"type": "integer"}
                    }
                }
            },
            "total": {"type": "integer"},
            "summary": {
                "type": "object",
                "properties": {
                    "normal_count": {"type": "integer"},
                    "warning_count": {"type": "integer"},
                    "critical_count": {"type": "integer"},
                    "last_update": {"type": "string", "format": "date-time"}
                }
            }
        }
    }'::jsonb,
    ARRAY['realtime_metrics'],
    '{
        "dashboard_category": "operations",
        "threshold_status": "warning",
        "sort_by": "value",
        "limit": 20
    }'::jsonb,
    '{
        "data": [
            {
                "id": "550e8400-e29b-41d4-a716-446655440000",
                "metric_name": "Звонки в очереди",
                "metric_value": 12,
                "metric_unit": "шт",
                "previous_value": 8,
                "trend_direction": "up",
                "display_color": "#FF9800",
                "target_value": 5,
                "warning_threshold": 10,
                "critical_threshold": 20,
                "threshold_status": "warning",
                "last_updated": "2025-07-15T16:45:00Z",
                "calculation_time_ms": 45,
                "dashboard_category": "operations",
                "display_order": 1
            },
            {
                "id": "660e8400-e29b-41d4-a716-446655440001",
                "metric_name": "Среднее время ожидания",
                "metric_value": 125,
                "metric_unit": "сек",
                "previous_value": 98,
                "trend_direction": "up",
                "display_color": "#F44336",
                "target_value": 60,
                "warning_threshold": 120,
                "critical_threshold": 180,
                "threshold_status": "critical",
                "last_updated": "2025-07-15T16:45:00Z",
                "calculation_time_ms": 32,
                "dashboard_category": "operations",
                "display_order": 2
            }
        ],
        "total": 15,
        "summary": {
            "normal_count": 8,
            "warning_count": 4,
            "critical_count": 3,
            "last_update": "2025-07-15T16:45:00Z"
        }
    }'::jsonb,
    'SELECT COUNT(*) FROM realtime_metrics WHERE is_visible = true'
);

-- 2. GET /api/v1/metrics/realtime/{id} - Get specific metric with history
INSERT INTO api_contracts (
    endpoint_path,
    http_method,
    table_name,
    request_schema,
    response_schema,
    database_dependencies,
    example_request,
    example_response,
    validation_query
) VALUES (
    '/api/v1/metrics/realtime/{id}',
    'GET',
    'realtime_metrics',
    '{
        "type": "object",
        "properties": {
            "id": {"type": "string", "format": "uuid", "description": "ID метрики"},
            "include_history": {"type": "boolean", "default": false, "description": "Включить историю изменений"},
            "history_hours": {"type": "integer", "default": 24, "maximum": 168, "description": "Часов истории"},
            "include_thresholds": {"type": "boolean", "default": true, "description": "Включить пороговые значения"}
        },
        "required": ["id"]
    }'::jsonb,
    '{
        "type": "object",
        "properties": {
            "id": {"type": "string", "format": "uuid"},
            "metric_name": {"type": "string"},
            "metric_value": {"type": "number"},
            "metric_unit": {"type": "string"},
            "previous_value": {"type": "number"},
            "trend_direction": {"type": "string"},
            "display_color": {"type": "string"},
            "target_value": {"type": "number"},
            "warning_threshold": {"type": "number"},
            "critical_threshold": {"type": "number"},
            "threshold_status": {"type": "string"},
            "last_updated": {"type": "string", "format": "date-time"},
            "calculation_time_ms": {"type": "integer"},
            "dashboard_category": {"type": "string"},
            "display_order": {"type": "integer"},
            "is_visible": {"type": "boolean"},
            "history": {"type": "array", "description": "История значений (если include_history=true)"},
            "threshold_breaches": {"type": "array", "description": "Нарушения порогов"}
        }
    }'::jsonb,
    ARRAY['realtime_metrics', 'metric_history', 'threshold_alerts'],
    '{"id": "550e8400-e29b-41d4-a716-446655440000", "include_history": true, "history_hours": 12}'::jsonb,
    '{
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "metric_name": "Звонки в очереди",
        "metric_value": 12,
        "metric_unit": "шт",
        "previous_value": 8,
        "trend_direction": "up",
        "display_color": "#FF9800",
        "target_value": 5,
        "warning_threshold": 10,
        "critical_threshold": 20,
        "threshold_status": "warning",
        "last_updated": "2025-07-15T16:45:00Z",
        "calculation_time_ms": 45,
        "dashboard_category": "operations",
        "display_order": 1,
        "is_visible": true,
        "history": [
            {"timestamp": "2025-07-15T16:00:00Z", "value": 8, "status": "normal"},
            {"timestamp": "2025-07-15T16:15:00Z", "value": 11, "status": "warning"},
            {"timestamp": "2025-07-15T16:30:00Z", "value": 12, "status": "warning"}
        ],
        "threshold_breaches": [
            {"timestamp": "2025-07-15T16:12:00Z", "threshold": "warning", "value": 10.5, "duration_seconds": 1980}
        ]
    }'::jsonb,
    'SELECT 1 FROM realtime_metrics WHERE id = $1'
);

-- 3. POST /api/v1/metrics/realtime - Create new metric
INSERT INTO api_contracts (
    endpoint_path,
    http_method,
    table_name,
    request_schema,
    response_schema,
    database_dependencies,
    example_request,
    example_response,
    validation_query
) VALUES (
    '/api/v1/metrics/realtime',
    'POST',
    'realtime_metrics',
    '{
        "type": "object",
        "properties": {
            "metric_name": {"type": "string", "description": "Название метрики"},
            "metric_value": {"type": "number", "description": "Текущее значение"},
            "metric_unit": {"type": "string", "description": "Единица измерения"},
            "target_value": {"type": "number", "description": "Целевое значение"},
            "warning_threshold": {"type": "number", "description": "Порог предупреждения"},
            "critical_threshold": {"type": "number", "description": "Критический порог"},
            "dashboard_category": {"type": "string", "enum": ["general", "operations", "quality", "performance"], "default": "general"},
            "display_order": {"type": "integer", "default": 100},
            "display_color": {"type": "string", "pattern": "^#[0-9A-Fa-f]{6}$", "default": "#2196F3"},
            "is_visible": {"type": "boolean", "default": true}
        },
        "required": ["metric_name", "metric_value"]
    }'::jsonb,
    '{
        "type": "object",
        "properties": {
            "id": {"type": "string", "format": "uuid"},
            "metric_name": {"type": "string"},
            "metric_value": {"type": "number"},
            "metric_unit": {"type": "string"},
            "previous_value": {"type": "number"},
            "trend_direction": {"type": "string"},
            "display_color": {"type": "string"},
            "target_value": {"type": "number"},
            "warning_threshold": {"type": "number"},
            "critical_threshold": {"type": "number"},
            "threshold_status": {"type": "string"},
            "last_updated": {"type": "string", "format": "date-time"},
            "calculation_time_ms": {"type": "integer"},
            "dashboard_category": {"type": "string"},
            "display_order": {"type": "integer"},
            "is_visible": {"type": "boolean"}
        }
    }'::jsonb,
    ARRAY['realtime_metrics'],
    '{
        "metric_name": "Удовлетворенность клиентов",
        "metric_value": 4.2,
        "metric_unit": "балл",
        "target_value": 4.5,
        "warning_threshold": 4.0,
        "critical_threshold": 3.5,
        "dashboard_category": "quality",
        "display_order": 5,
        "display_color": "#4CAF50"
    }'::jsonb,
    '{
        "id": "770e8400-e29b-41d4-a716-446655440002",
        "metric_name": "Удовлетворенность клиентов",
        "metric_value": 4.2,
        "metric_unit": "балл",
        "previous_value": null,
        "trend_direction": "stable",
        "display_color": "#4CAF50",
        "target_value": 4.5,
        "warning_threshold": 4.0,
        "critical_threshold": 3.5,
        "threshold_status": "warning",
        "last_updated": "2025-07-15T17:00:00Z",
        "calculation_time_ms": 0,
        "dashboard_category": "quality",
        "display_order": 5,
        "is_visible": true
    }'::jsonb,
    'SELECT NOT EXISTS(SELECT 1 FROM realtime_metrics WHERE metric_name = $1)'
);

-- 4. PUT /api/v1/metrics/realtime/{id} - Update metric value or configuration
INSERT INTO api_contracts (
    endpoint_path,
    http_method,
    table_name,
    request_schema,
    response_schema,
    database_dependencies,
    example_request,
    example_response,
    validation_query
) VALUES (
    '/api/v1/metrics/realtime/{id}',
    'PUT',
    'realtime_metrics',
    '{
        "type": "object",
        "properties": {
            "id": {"type": "string", "format": "uuid", "description": "ID метрики"},
            "metric_value": {"type": "number", "description": "Новое значение"},
            "target_value": {"type": "number", "description": "Новое целевое значение"},
            "warning_threshold": {"type": "number", "description": "Новый порог предупреждения"},
            "critical_threshold": {"type": "number", "description": "Новый критический порог"},
            "display_color": {"type": "string", "pattern": "^#[0-9A-Fa-f]{6}$", "description": "Цвет отображения"},
            "display_order": {"type": "integer", "description": "Порядок отображения"},
            "is_visible": {"type": "boolean", "description": "Видимость на дашборде"},
            "calculation_time_ms": {"type": "integer", "description": "Время расчета в мс"}
        },
        "required": ["id"]
    }'::jsonb,
    '{
        "type": "object",
        "properties": {
            "id": {"type": "string", "format": "uuid"},
            "metric_name": {"type": "string"},
            "metric_value": {"type": "number"},
            "metric_unit": {"type": "string"},
            "previous_value": {"type": "number"},
            "trend_direction": {"type": "string"},
            "display_color": {"type": "string"},
            "target_value": {"type": "number"},
            "warning_threshold": {"type": "number"},
            "critical_threshold": {"type": "number"},
            "threshold_status": {"type": "string"},
            "last_updated": {"type": "string", "format": "date-time"},
            "calculation_time_ms": {"type": "integer"},
            "dashboard_category": {"type": "string"},
            "display_order": {"type": "integer"},
            "is_visible": {"type": "boolean"}
        }
    }'::jsonb,
    ARRAY['realtime_metrics'],
    '{
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "metric_value": 8,
        "calculation_time_ms": 38,
        "display_color": "#4CAF50"
    }'::jsonb,
    '{
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "metric_name": "Звонки в очереди",
        "metric_value": 8,
        "metric_unit": "шт",
        "previous_value": 12,
        "trend_direction": "down",
        "display_color": "#4CAF50",
        "target_value": 5,
        "warning_threshold": 10,
        "critical_threshold": 20,
        "threshold_status": "normal",
        "last_updated": "2025-07-15T17:15:00Z",
        "calculation_time_ms": 38,
        "dashboard_category": "operations",
        "display_order": 1,
        "is_visible": true
    }'::jsonb,
    'SELECT EXISTS(SELECT 1 FROM realtime_metrics WHERE id = $1)'
);

-- 5. DELETE /api/v1/metrics/realtime/{id} - Delete metric
INSERT INTO api_contracts (
    endpoint_path,
    http_method,
    table_name,
    request_schema,
    response_schema,
    database_dependencies,
    example_request,
    example_response,
    validation_query
) VALUES (
    '/api/v1/metrics/realtime/{id}',
    'DELETE',
    'realtime_metrics',
    '{
        "type": "object",
        "properties": {
            "id": {"type": "string", "format": "uuid", "description": "ID метрики для удаления"},
            "archive_history": {"type": "boolean", "default": true, "description": "Архивировать историю"},
            "force": {"type": "boolean", "default": false, "description": "Принудительное удаление"}
        },
        "required": ["id"]
    }'::jsonb,
    '{
        "type": "object",
        "properties": {
            "success": {"type": "boolean"},
            "message": {"type": "string"},
            "deleted_id": {"type": "string", "format": "uuid"},
            "archived_history_records": {"type": "integer"}
        }
    }'::jsonb,
    ARRAY['realtime_metrics', 'metric_history', 'dashboard_configurations'],
    '{"id": "770e8400-e29b-41d4-a716-446655440002", "archive_history": true}'::jsonb,
    '{
        "success": true,
        "message": "Метрика успешно удалена, история архивирована",
        "deleted_id": "770e8400-e29b-41d4-a716-446655440002",
        "archived_history_records": 156
    }'::jsonb,
    'SELECT EXISTS(SELECT 1 FROM realtime_metrics WHERE id = $1)'
);

-- 6. GET /api/v1/metrics/dashboard/{category} - Get dashboard configuration for category
INSERT INTO api_contracts (
    endpoint_path,
    http_method,
    table_name,
    request_schema,
    response_schema,
    database_dependencies,
    example_request,
    example_response,
    validation_query
) VALUES (
    '/api/v1/metrics/dashboard/{category}',
    'GET',
    'realtime_metrics',
    '{
        "type": "object",
        "properties": {
            "category": {"type": "string", "enum": ["general", "operations", "quality", "performance"], "description": "Категория дашборда"},
            "include_inactive": {"type": "boolean", "default": false, "description": "Включить неактивные метрики"},
            "layout": {"type": "string", "enum": ["grid", "list", "tiles"], "default": "grid", "description": "Макет отображения"}
        },
        "required": ["category"]
    }'::jsonb,
    '{
        "type": "object",
        "properties": {
            "category": {"type": "string"},
            "layout": {"type": "string"},
            "metrics": {
                "type": "array",
                "items": {
                    "type": "object",
                    "properties": {
                        "id": {"type": "string", "format": "uuid"},
                        "metric_name": {"type": "string"},
                        "metric_value": {"type": "number"},
                        "metric_unit": {"type": "string"},
                        "trend_direction": {"type": "string"},
                        "display_color": {"type": "string"},
                        "threshold_status": {"type": "string"},
                        "display_order": {"type": "integer"},
                        "widget_config": {"type": "object"}
                    }
                }
            },
            "summary": {
                "type": "object",
                "properties": {
                    "total_metrics": {"type": "integer"},
                    "active_metrics": {"type": "integer"},
                    "alerts_count": {"type": "integer"},
                    "last_refresh": {"type": "string", "format": "date-time"}
                }
            }
        }
    }'::jsonb,
    ARRAY['realtime_metrics', 'dashboard_configurations'],
    '{"category": "operations", "layout": "grid"}'::jsonb,
    '{
        "category": "operations",
        "layout": "grid",
        "metrics": [
            {
                "id": "550e8400-e29b-41d4-a716-446655440000",
                "metric_name": "Звонки в очереди",
                "metric_value": 8,
                "metric_unit": "шт",
                "trend_direction": "down",
                "display_color": "#4CAF50",
                "threshold_status": "normal",
                "display_order": 1,
                "widget_config": {
                    "widget_type": "gauge",
                    "size": "medium",
                    "show_trend": true
                }
            },
            {
                "id": "660e8400-e29b-41d4-a716-446655440001",
                "metric_name": "Среднее время ожидания",
                "metric_value": 125,
                "metric_unit": "сек",
                "trend_direction": "up",
                "display_color": "#F44336",
                "threshold_status": "critical",
                "display_order": 2,
                "widget_config": {
                    "widget_type": "line_chart",
                    "size": "large",
                    "show_history": 24
                }
            }
        ],
        "summary": {
            "total_metrics": 8,
            "active_metrics": 6,
            "alerts_count": 2,
            "last_refresh": "2025-07-15T17:15:00Z"
        }
    }'::jsonb,
    'SELECT COUNT(*) FROM realtime_metrics WHERE dashboard_category = $1'
);

-- Helper queries for realtime_metrics API endpoints
INSERT INTO api_helper_queries (
    endpoint_path,
    http_method,
    query_name,
    query_sql,
    parameters,
    description
) VALUES 
-- Query for GET /api/v1/metrics/realtime
('/api/v1/metrics/realtime', 'GET', 'list_realtime_metrics_with_status',
'SELECT 
    rm.id,
    rm.metric_name,
    rm.metric_value,
    rm.metric_unit,
    rm.previous_value,
    rm.trend_direction,
    rm.display_color,
    rm.target_value,
    rm.warning_threshold,
    rm.critical_threshold,
    CASE 
        WHEN rm.critical_threshold IS NOT NULL AND rm.metric_value >= rm.critical_threshold THEN ''critical''
        WHEN rm.warning_threshold IS NOT NULL AND rm.metric_value >= rm.warning_threshold THEN ''warning''
        ELSE ''normal''
    END as threshold_status,
    rm.last_updated,
    rm.calculation_time_ms,
    rm.dashboard_category,
    rm.display_order,
    COUNT(*) OVER() as total_count
FROM realtime_metrics rm
WHERE ($1::text IS NULL OR rm.dashboard_category = $1)
  AND ($2::text[] IS NULL OR rm.metric_name = ANY($2))
  AND ($3::text IS NULL OR rm.trend_direction = $3)
  AND ($4::text IS NULL OR 
       CASE 
           WHEN rm.critical_threshold IS NOT NULL AND rm.metric_value >= rm.critical_threshold THEN ''critical''
           WHEN rm.warning_threshold IS NOT NULL AND rm.metric_value >= rm.warning_threshold THEN ''warning''
           ELSE ''normal''
       END = $4)
  AND ($5::boolean IS NULL OR $5 = true OR rm.is_visible = true)
ORDER BY 
    CASE $6::text
        WHEN ''name'' THEN rm.metric_name
        WHEN ''updated'' THEN rm.last_updated::text
        ELSE rm.display_order::text
    END,
    CASE $6::text
        WHEN ''value'' THEN rm.metric_value
        ELSE 0
    END DESC
LIMIT $7;',
'["dashboard_category", "metric_names", "trend_direction", "threshold_status", "include_inactive", "sort_by", "limit"]'::jsonb,
'Список метрик реального времени с расчетом статуса порогов'),

-- Query for summary statistics
('/api/v1/metrics/realtime', 'GET', 'get_metrics_summary',
'SELECT 
    COUNT(*) FILTER (WHERE 
        CASE 
            WHEN critical_threshold IS NOT NULL AND metric_value >= critical_threshold THEN ''critical''
            WHEN warning_threshold IS NOT NULL AND metric_value >= warning_threshold THEN ''warning''
            ELSE ''normal''
        END = ''normal''
    ) as normal_count,
    COUNT(*) FILTER (WHERE 
        CASE 
            WHEN critical_threshold IS NOT NULL AND metric_value >= critical_threshold THEN ''critical''
            WHEN warning_threshold IS NOT NULL AND metric_value >= warning_threshold THEN ''warning''
            ELSE ''normal''
        END = ''warning''
    ) as warning_count,
    COUNT(*) FILTER (WHERE 
        CASE 
            WHEN critical_threshold IS NOT NULL AND metric_value >= critical_threshold THEN ''critical''
            WHEN warning_threshold IS NOT NULL AND metric_value >= warning_threshold THEN ''warning''
            ELSE ''normal''
        END = ''critical''
    ) as critical_count,
    MAX(last_updated) as last_update
FROM realtime_metrics
WHERE is_visible = true;',
'[]'::jsonb,
'Сводная статистика по метрикам'),

-- Query for GET /api/v1/metrics/realtime/{id}
('/api/v1/metrics/realtime/{id}', 'GET', 'get_metric_with_details',
'SELECT 
    rm.id,
    rm.metric_name,
    rm.metric_value,
    rm.metric_unit,
    rm.previous_value,
    rm.trend_direction,
    rm.display_color,
    rm.target_value,
    rm.warning_threshold,
    rm.critical_threshold,
    CASE 
        WHEN rm.critical_threshold IS NOT NULL AND rm.metric_value >= rm.critical_threshold THEN ''critical''
        WHEN rm.warning_threshold IS NOT NULL AND rm.metric_value >= rm.warning_threshold THEN ''warning''
        ELSE ''normal''
    END as threshold_status,
    rm.last_updated,
    rm.calculation_time_ms,
    rm.dashboard_category,
    rm.display_order,
    rm.is_visible
FROM realtime_metrics rm
WHERE rm.id = $1;',
'["id"]'::jsonb,
'Детальная информация о метрике с расчетом статуса'),

-- Query for POST /api/v1/metrics/realtime validation
('/api/v1/metrics/realtime', 'POST', 'validate_metric_creation',
'SELECT 
    NOT EXISTS(SELECT 1 FROM realtime_metrics WHERE metric_name = $1) as name_available,
    ($2::numeric IS NOT NULL) as has_value,
    ($4::numeric IS NULL OR $5::numeric IS NULL OR $4 < $5) as valid_thresholds;',
'["metric_name", "metric_value", "target_value", "warning_threshold", "critical_threshold"]'::jsonb,
'Валидация данных для создания метрики'),

-- Query for PUT /api/v1/metrics/realtime/{id}
('/api/v1/metrics/realtime/{id}', 'PUT', 'update_realtime_metric',
'UPDATE realtime_metrics 
SET 
    previous_value = CASE 
        WHEN $2::numeric IS NOT NULL AND $2 != metric_value THEN metric_value 
        ELSE previous_value 
    END,
    metric_value = COALESCE($2, metric_value),
    target_value = COALESCE($3, target_value),
    warning_threshold = COALESCE($4, warning_threshold),
    critical_threshold = COALESCE($5, critical_threshold),
    display_color = COALESCE($6, display_color),
    display_order = COALESCE($7, display_order),
    is_visible = COALESCE($8, is_visible),
    calculation_time_ms = COALESCE($9, calculation_time_ms),
    trend_direction = CASE
        WHEN $2::numeric IS NOT NULL AND previous_value IS NOT NULL THEN
            CASE 
                WHEN $2 > previous_value THEN ''up''
                WHEN $2 < previous_value THEN ''down''
                ELSE ''stable''
            END
        ELSE trend_direction
    END,
    last_updated = CURRENT_TIMESTAMP
WHERE id = $1
RETURNING *;',
'["id", "metric_value", "target_value", "warning_threshold", "critical_threshold", "display_color", "display_order", "is_visible", "calculation_time_ms"]'::jsonb,
'Обновление метрики с автоматическим расчетом трендов'),

-- Query for DELETE /api/v1/metrics/realtime/{id}
('/api/v1/metrics/realtime/{id}', 'DELETE', 'check_metric_dependencies',
'SELECT 
    rm.id,
    rm.metric_name,
    rm.dashboard_category,
    COALESCE(
        (SELECT COUNT(*) FROM metric_history mh WHERE mh.metric_id = rm.id),
        0
    ) as history_records_count,
    EXISTS(SELECT 1 FROM dashboard_configurations dc WHERE dc.metric_ids @> ARRAY[rm.id::text]) as used_in_dashboards
FROM realtime_metrics rm
WHERE rm.id = $1;',
'["id"]'::jsonb,
'Проверка зависимостей перед удалением метрики'),

-- Query for GET /api/v1/metrics/dashboard/{category}
('/api/v1/metrics/dashboard/{category}', 'GET', 'get_dashboard_metrics',
'SELECT 
    rm.id,
    rm.metric_name,
    rm.metric_value,
    rm.metric_unit,
    rm.trend_direction,
    rm.display_color,
    CASE 
        WHEN rm.critical_threshold IS NOT NULL AND rm.metric_value >= rm.critical_threshold THEN ''critical''
        WHEN rm.warning_threshold IS NOT NULL AND rm.metric_value >= rm.warning_threshold THEN ''warning''
        ELSE ''normal''
    END as threshold_status,
    rm.display_order,
    jsonb_build_object(
        ''widget_type'', CASE rm.dashboard_category
            WHEN ''operations'' THEN ''gauge''
            WHEN ''quality'' THEN ''line_chart''
            WHEN ''performance'' THEN ''bar_chart''
            ELSE ''number''
        END,
        ''size'', ''medium'',
        ''show_trend'', true
    ) as widget_config
FROM realtime_metrics rm
WHERE rm.dashboard_category = $1
  AND ($2::boolean IS NULL OR $2 = true OR rm.is_visible = true)
ORDER BY rm.display_order;',
'["category", "include_inactive"]'::jsonb,
'Метрики для дашборда с конфигурацией виджетов');

-- Test data for realtime_metrics (Russian language support)
INSERT INTO integration_test_data (
    table_name,
    test_scenario,
    record_identifier,
    test_data,
    bdd_scenario_reference,
    is_active
) VALUES 
('realtime_metrics', 'operations_queue_metrics',
'{"id": "550e8400-e29b-41d4-a716-446655440000"}'::jsonb,
'{
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "metric_name": "Звонки в очереди",
    "metric_value": 12,
    "metric_unit": "шт",
    "previous_value": 8,
    "trend_direction": "up",
    "display_color": "#FF9800",
    "target_value": 5,
    "warning_threshold": 10,
    "critical_threshold": 20,
    "last_updated": "2025-07-15T16:45:00Z",
    "calculation_time_ms": 45,
    "dashboard_category": "operations",
    "display_order": 1,
    "is_visible": true
}'::jsonb,
'realtime-monitoring.feature:25', true),

('realtime_metrics', 'quality_satisfaction_metrics',
'{"id": "660e8400-e29b-41d4-a716-446655440001"}'::jsonb,
'{
    "id": "660e8400-e29b-41d4-a716-446655440001",
    "metric_name": "Удовлетворенность клиентов",
    "metric_value": 4.2,
    "metric_unit": "балл",
    "previous_value": 4.1,
    "trend_direction": "up",
    "display_color": "#4CAF50",
    "target_value": 4.5,
    "warning_threshold": 4.0,
    "critical_threshold": 3.5,
    "last_updated": "2025-07-15T16:45:00Z",
    "calculation_time_ms": 120,
    "dashboard_category": "quality",
    "display_order": 1,
    "is_visible": true
}'::jsonb,
'realtime-monitoring.feature:55', true),

('realtime_metrics', 'performance_efficiency_metrics',
'{"id": "770e8400-e29b-41d4-a716-446655440002"}'::jsonb,
'{
    "id": "770e8400-e29b-41d4-a716-446655440002",
    "metric_name": "Эффективность агентов",
    "metric_value": 87.5,
    "metric_unit": "%",
    "previous_value": 85.2,
    "trend_direction": "up",
    "display_color": "#2196F3",
    "target_value": 90,
    "warning_threshold": 80,
    "critical_threshold": 70,
    "last_updated": "2025-07-15T16:45:00Z",
    "calculation_time_ms": 89,
    "dashboard_category": "performance",
    "display_order": 1,
    "is_visible": true
}'::jsonb,
'realtime-monitoring.feature:85', true),

('realtime_metrics', 'threshold_configuration_examples',
'{"type": "thresholds"}'::jsonb,
'{
    "threshold_examples": {
        "call_queue": {
            "normal": "0-5 звонков",
            "warning": "6-15 звонков", 
            "critical": "16+ звонков"
        },
        "wait_time": {
            "normal": "0-60 секунд",
            "warning": "61-120 секунд",
            "critical": "121+ секунд"
        },
        "satisfaction": {
            "normal": "4.0+ баллов",
            "warning": "3.5-3.9 баллов",
            "critical": "< 3.5 баллов"
        },
        "efficiency": {
            "normal": "85%+",
            "warning": "70-84%",
            "critical": "< 70%"
        }
    },
    "color_scheme": {
        "normal": "#4CAF50",
        "warning": "#FF9800", 
        "critical": "#F44336",
        "info": "#2196F3"
    }
}'::jsonb,
'realtime-thresholds.feature:15', true);

\echo ''
\echo '======================================'
\echo 'REALTIME METRICS API CONTRACTS SUMMARY'
\echo '======================================'
\echo 'Updated tables: api_contracts, api_helper_queries, integration_test_data'
\echo 'Total API endpoints: 6'
\echo 'Total helper queries: 7' 
\echo 'Total test scenarios: 4'
\echo ''
\echo 'API Endpoints Created:'
\echo '- GET /api/v1/metrics/realtime (list with thresholds)'
\echo '- GET /api/v1/metrics/realtime/{id} (get with history)' 
\echo '- POST /api/v1/metrics/realtime (create new metric)'
\echo '- PUT /api/v1/metrics/realtime/{id} (update metric)'
\echo '- DELETE /api/v1/metrics/realtime/{id} (delete metric)'
\echo '- GET /api/v1/metrics/dashboard/{category} (dashboard config)'
\echo ''