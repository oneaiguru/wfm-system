from fastapi import APIRouter

from .endpoints import (
    personnel,
    historic,
    online,
    status,
    forecasting,
    workflows,
    algorithms,
    integrations,
    argus_compare,
    argus_historic_enhanced,
    argus_realtime_enhanced,
    comparison,
    websocket,
    auth,
    rbac,
    bdd_system_integration,
    bdd_personnel_management,
    bdd_employee_requests,
    forecasting_ui_endpoints,
    schedule_planning_ui_endpoints,
    monthly_planning_ui_endpoints,
)

# Import comprehensive forecasting API
from .endpoints.forecasting.main import router as comprehensive_forecasting_router

# Import new personnel management endpoints
from .endpoints.personnel import (
    employees_router,
    skills_router,
    groups_router,
    organization_router,
    bulk_operations_router
)

# Import integration endpoints
from .endpoints.integrations import (
    onec_router,
    contact_center_router,
    webhooks_router,
    connections_router
)

# Import schedule management endpoints
from .endpoints.schedules import router as schedules_router

# Import database API endpoints
from .endpoints import database

api_router = APIRouter()

# Authentication and RBAC endpoints
auth_router = APIRouter(prefix="/auth", tags=["authentication"])
auth_router.include_router(auth.router)
auth_router.include_router(rbac.router, prefix="/rbac", tags=["rbac"])
api_router.include_router(auth_router)

# Core Argus compatibility endpoints
argus_router = APIRouter(prefix="/argus", tags=["argus-compatibility"])
argus_router.include_router(personnel.router, prefix="/personnel", tags=["personnel"])
argus_router.include_router(historic.router, prefix="/historic", tags=["historic"])
argus_router.include_router(online.router, prefix="/online", tags=["online"])
argus_router.include_router(status.router, prefix="/ccwfm", tags=["status"])

# New Personnel Management API (v1) - 25 endpoints
personnel_router = APIRouter(prefix="/personnel", tags=["personnel-management"])
personnel_router.include_router(employees_router)
personnel_router.include_router(skills_router)
personnel_router.include_router(groups_router)
personnel_router.include_router(organization_router)
personnel_router.include_router(bulk_operations_router)
api_router.include_router(personnel_router)

# Enhanced workflow endpoints (improvements over Argus)
workflow_router = APIRouter(prefix="/workflow", tags=["workflows"])
workflow_router.include_router(workflows.excel_import_router, prefix="/excel-import", tags=["excel-import"])
workflow_router.include_router(workflows.validation_router, prefix="/validate", tags=["validation"])

# Algorithm endpoints (competitive advantage)
algorithm_router = APIRouter(prefix="/algorithms", tags=["algorithms"])
algorithm_router.include_router(algorithms.erlang_c_router, prefix="/erlang-c", tags=["erlang-c"])
algorithm_router.include_router(algorithms.ml_models_router, prefix="/ml-models", tags=["ml-models"])
algorithm_router.include_router(forecasting.router, prefix="/forecast", tags=["forecast"])

# Comprehensive Forecasting & Planning API (25 endpoints)
api_router.include_router(comprehensive_forecasting_router)

# UI Integration Forecasting Endpoints (4 endpoints for LoadPlanningUI.tsx)
api_router.include_router(forecasting_ui_endpoints.router)

# Schedule Planning UI Endpoints (19 endpoints for ScheduleGridSystem)
api_router.include_router(schedule_planning_ui_endpoints.router)

# Monthly Activity Planning UI Endpoints (16 endpoints for Timetable Management)
from .endpoints.monthly_planning_ui_endpoints import router as monthly_planning_router
api_router.include_router(monthly_planning_router)

# Include all routers in main API
api_router.include_router(argus_router)
api_router.include_router(workflow_router)
api_router.include_router(algorithm_router)

# Integration endpoints for cross-module communication
integration_router = APIRouter(prefix="/integration", tags=["integration"])
integration_router.include_router(integrations.database_integration_router, prefix="/database", tags=["database-integration"])
integration_router.include_router(integrations.algorithm_integration_router, prefix="/algorithms", tags=["algorithm-integration"])
api_router.include_router(integration_router)

# Integration APIs - 25 endpoints for external system integration
integrations_api_router = APIRouter(prefix="/integrations", tags=["integration-apis"])
integrations_api_router.include_router(onec_router)  # 10 endpoints for 1C ZUP integration
integrations_api_router.include_router(contact_center_router)  # 15 endpoints for Contact Center integration
integrations_api_router.include_router(webhooks_router, prefix="/webhooks")  # Webhook management
integrations_api_router.include_router(connections_router, prefix="/connections")  # Connection management
api_router.include_router(integrations_api_router)

# Argus comparison endpoints for validation
comparison_router = APIRouter(prefix="/argus-compare", tags=["argus-comparison"])
comparison_router.include_router(argus_compare.router)
api_router.include_router(comparison_router)

# Enhanced Argus endpoints with improved features
enhanced_argus_router = APIRouter(prefix="/argus/enhanced", tags=["argus-enhanced"])
enhanced_argus_router.include_router(argus_historic_enhanced.router, prefix="/historic", tags=["historic-enhanced"])
enhanced_argus_router.include_router(argus_realtime_enhanced.router, prefix="/realtime", tags=["realtime-enhanced"])
api_router.include_router(enhanced_argus_router)

# Competition comparison framework - showcase our superiority
superiority_router = APIRouter(prefix="/comparison", tags=["performance-comparison"])
superiority_router.include_router(comparison.router)
api_router.include_router(superiority_router)

# Schedule Management API (35 endpoints)
api_router.include_router(schedules_router, prefix="/schedules", tags=["schedule-management"])

# WebSocket endpoints for real-time communication
websocket_router = APIRouter(prefix="/realtime", tags=["websocket"])
websocket_router.include_router(websocket.router)
api_router.include_router(websocket_router)

# Database API endpoints for direct database access
database_router = APIRouter(prefix="/db", tags=["database-access"])
database_router.include_router(database.router)
api_router.include_router(database_router)

# BDD System Integration API endpoints
bdd_integration_router = APIRouter(tags=["bdd-system-integration"])
bdd_integration_router.include_router(bdd_system_integration.router)
api_router.include_router(bdd_integration_router)

# BDD Personnel Management API endpoints
bdd_personnel_router = APIRouter(tags=["bdd-personnel-management"])
bdd_personnel_router.include_router(bdd_personnel_management.router)
api_router.include_router(bdd_personnel_router)

# BDD Employee Requests API endpoints
bdd_requests_router = APIRouter(tags=["bdd-employee-requests"])
bdd_requests_router.include_router(bdd_employee_requests.router)
api_router.include_router(bdd_requests_router)

# AL-OPUS Algorithm Integration Service
from .endpoints.algorithm_integration_service import router as algorithm_integration_router
al_opus_router = APIRouter(tags=["al-opus-algorithms"])
al_opus_router.include_router(algorithm_integration_router)
api_router.include_router(al_opus_router)

# Forecasting API endpoints (Tasks 26-30) - Real PostgreSQL implementations
from .endpoints.forecasting_accuracy_REAL import router as forecasting_accuracy_router
from .endpoints.forecasting_adjust_REAL import router as forecasting_adjust_router
from .endpoints.forecasting_compare_REAL import router as forecasting_compare_router
from .endpoints.forecasting_export_REAL import router as forecasting_export_router
from .endpoints.forecasting_import_REAL import router as forecasting_import_router

forecasting_apis_router = APIRouter(tags=["forecasting-apis"])
forecasting_apis_router.include_router(forecasting_accuracy_router)
forecasting_apis_router.include_router(forecasting_adjust_router)
forecasting_apis_router.include_router(forecasting_compare_router)
forecasting_apis_router.include_router(forecasting_export_router)
forecasting_apis_router.include_router(forecasting_import_router)
api_router.include_router(forecasting_apis_router)

# Reporting API endpoints (Tasks 31-35) - Real PostgreSQL implementations
from .endpoints.reports_generate_REAL import router as reports_generate_router
from .endpoints.reports_schedule_REAL import router as reports_schedule_router
from .endpoints.reports_custom_REAL import router as reports_custom_router
from .endpoints.reports_templates_REAL import router as reports_templates_router
from .endpoints.reports_delete_REAL import router as reports_delete_router

reporting_apis_router = APIRouter(tags=["reporting-apis"])
reporting_apis_router.include_router(reports_generate_router)
reporting_apis_router.include_router(reports_schedule_router)
reporting_apis_router.include_router(reports_custom_router)
reporting_apis_router.include_router(reports_templates_router)
reporting_apis_router.include_router(reports_delete_router)
api_router.include_router(reporting_apis_router)

# Schedule Management API endpoints (Tasks 22-25) - Real PostgreSQL implementations
from .endpoints.schedules_create_REAL import router as schedules_create_router
from .endpoints.schedules_update_REAL import router as schedules_update_router
from .endpoints.schedules_history_REAL import router as schedules_history_router
from .endpoints.schedules_copy_REAL import router as schedules_copy_router

schedule_apis_router = APIRouter(tags=["schedule-apis"])
schedule_apis_router.include_router(schedules_create_router)
schedule_apis_router.include_router(schedules_update_router)
schedule_apis_router.include_router(schedules_history_router)
schedule_apis_router.include_router(schedules_copy_router)
api_router.include_router(schedule_apis_router)

# Mobile Personal Cabinet API endpoints (Tasks 36-40) - Real PostgreSQL implementations
from .endpoints.mobile_endpoints_router import mobile_router

mobile_apis_router = APIRouter(tags=["mobile-personal-cabinet"])
mobile_apis_router.include_router(mobile_router)
api_router.include_router(mobile_apis_router)

# Business Process Workflows API endpoints (Tasks 41-45) - Real PostgreSQL implementations
from .endpoints.workflows_router import workflows_router

workflows_apis_router = APIRouter(tags=["business-process-workflows"])
workflows_apis_router.include_router(workflows_router)
api_router.include_router(workflows_apis_router)

# Enterprise Integration API endpoints (Tasks 71-75) - Real PostgreSQL implementations
from .endpoints.integration_webhooks_register import router as webhooks_register_router
from .endpoints.integration_sso_authenticate import router as sso_authenticate_router
from .endpoints.integration_external_systems import router as external_systems_router
from .endpoints.integration_data_transform import router as data_transform_router
from .endpoints.integration_compliance_audit import router as compliance_audit_router

enterprise_integration_router = APIRouter(tags=["enterprise-integration"])
enterprise_integration_router.include_router(webhooks_register_router)
enterprise_integration_router.include_router(sso_authenticate_router)
enterprise_integration_router.include_router(external_systems_router)
enterprise_integration_router.include_router(data_transform_router)
enterprise_integration_router.include_router(compliance_audit_router)
api_router.include_router(enterprise_integration_router)

# Analytics & BI API endpoints (Tasks 76-85) - Real PostgreSQL implementations
from .endpoints.analytics_custom_report import router as analytics_custom_report_router
from .endpoints.analytics_ml_insights import router as analytics_ml_insights_router
from .endpoints.analytics_dashboard_custom import router as analytics_dashboard_custom_router
from .endpoints.analytics_predictive_forecast import router as analytics_predictive_forecast_router
from .endpoints.analytics_data_mining import router as analytics_data_mining_router
from .endpoints.analytics_performance_kpi import router as analytics_performance_kpi_router
from .endpoints.analytics_export_advanced import router as analytics_export_advanced_router
from .endpoints.analytics_benchmarking_industry import router as analytics_benchmarking_industry_router
from .endpoints.analytics_alerts_intelligent import router as analytics_alerts_intelligent_router
from .endpoints.analytics_visualization_advanced import router as analytics_visualization_advanced_router

analytics_bi_router = APIRouter(tags=["analytics-bi"])
analytics_bi_router.include_router(analytics_custom_report_router)
analytics_bi_router.include_router(analytics_ml_insights_router)
analytics_bi_router.include_router(analytics_dashboard_custom_router)
analytics_bi_router.include_router(analytics_predictive_forecast_router)
analytics_bi_router.include_router(analytics_data_mining_router)
analytics_bi_router.include_router(analytics_performance_kpi_router)
analytics_bi_router.include_router(analytics_export_advanced_router)
analytics_bi_router.include_router(analytics_benchmarking_industry_router)
analytics_bi_router.include_router(analytics_alerts_intelligent_router)
analytics_bi_router.include_router(analytics_visualization_advanced_router)
api_router.include_router(analytics_bi_router)

# Forecasting API endpoints (Tasks 51-75) - Advanced Forecasting System
from .endpoints.forecast_demand_models_REAL import router as forecast_demand_models_router
from .endpoints.forecast_capacity_planning_REAL import router as forecast_capacity_planning_router
from .endpoints.forecast_optimization_engine_REAL import router as forecast_optimization_engine_router
from .endpoints.forecast_pattern_analysis_REAL import router as forecast_pattern_analysis_router
from .endpoints.forecast_seasonal_adjustments_REAL import router as forecast_seasonal_adjustments_router
from .endpoints.forecast_historical_analysis_REAL import router as forecast_historical_analysis_router
from .endpoints.forecast_data_quality_REAL import router as forecast_data_quality_router
from .endpoints.forecast_realtime_monitor_REAL import router as forecast_realtime_monitor_router
from .endpoints.forecast_realtime_adjustments_REAL import router as forecast_realtime_adjustments_router
from .endpoints.forecast_emergency_override_REAL import router as forecast_emergency_override_router
from .endpoints.forecast_accuracy_validation_REAL import router as forecast_accuracy_validation_router
from .endpoints.forecast_performance_benchmark_REAL import router as forecast_performance_benchmark_router
from .endpoints.forecast_accuracy_reports_REAL import router as forecast_accuracy_reports_router
from .endpoints.forecast_continuous_improvement_REAL import router as forecast_continuous_improvement_router
from .endpoints.forecast_ml_insights_REAL import router as forecast_ml_insights_router

# Employee Management API endpoints (Tasks 4-25) - Real PostgreSQL implementations
from .endpoints.employee_skills_get_REAL import router as employee_skills_get_router
from .endpoints.employee_skills_update_REAL import router as employee_skills_update_router
from .endpoints.employee_skills_history_REAL import router as employee_skills_history_router
from .endpoints.employee_skills_assessment_REAL import router as employee_skills_assessment_router
from .endpoints.employee_skills_certification_REAL import router as employee_skills_certification_router
from .endpoints.employee_scheduling_preferences_get_REAL import router as employee_scheduling_preferences_get_router
from .endpoints.employee_scheduling_preferences_update_REAL import router as employee_scheduling_preferences_update_router
from .endpoints.employee_availability_set_REAL import router as employee_availability_set_router
from .endpoints.employee_availability_get_REAL import router as employee_availability_get_router
from .endpoints.employee_performance_metrics_get_REAL import router as employee_performance_metrics_get_router
from .endpoints.employee_performance_evaluation_REAL import router as employee_performance_evaluation_router
from .endpoints.employee_performance_goals_REAL import router as employee_performance_goals_router
from .endpoints.employee_performance_history_REAL import router as employee_performance_history_router
from .endpoints.employee_training_records_get_REAL import router as employee_training_records_get_router
from .endpoints.employee_training_enrollment_REAL import router as employee_training_enrollment_router
from .endpoints.employee_training_completion_REAL import router as employee_training_completion_router
from .endpoints.employee_training_requirements_REAL import router as employee_training_requirements_router
from .endpoints.employee_availability_management_get_REAL import router as employee_availability_management_get_router
from .endpoints.employee_availability_management_update_REAL import router as employee_availability_management_update_router
from .endpoints.employee_time_off_request_REAL import router as employee_time_off_request_router
from .endpoints.employee_time_off_history_REAL import router as employee_time_off_history_router
from .endpoints.employee_time_off_balance_REAL import router as employee_time_off_balance_router
from .endpoints.vacation_requests_REAL import router as vacation_requests_router

employee_management_apis_router = APIRouter(tags=["employee-management-apis"])
employee_management_apis_router.include_router(employee_skills_get_router)
employee_management_apis_router.include_router(employee_skills_update_router)
employee_management_apis_router.include_router(employee_skills_history_router)
employee_management_apis_router.include_router(employee_skills_assessment_router)
employee_management_apis_router.include_router(employee_skills_certification_router)
employee_management_apis_router.include_router(employee_scheduling_preferences_get_router)
employee_management_apis_router.include_router(employee_scheduling_preferences_update_router)
employee_management_apis_router.include_router(employee_availability_set_router)
employee_management_apis_router.include_router(employee_availability_get_router)
employee_management_apis_router.include_router(employee_performance_metrics_get_router)
employee_management_apis_router.include_router(employee_performance_evaluation_router)
employee_management_apis_router.include_router(employee_performance_goals_router)
employee_management_apis_router.include_router(employee_performance_history_router)
employee_management_apis_router.include_router(employee_training_records_get_router)
employee_management_apis_router.include_router(employee_training_enrollment_router)
employee_management_apis_router.include_router(employee_training_completion_router)
employee_management_apis_router.include_router(employee_training_requirements_router)
employee_management_apis_router.include_router(employee_availability_management_get_router)
employee_management_apis_router.include_router(employee_availability_management_update_router)
employee_management_apis_router.include_router(employee_time_off_request_router)
employee_management_apis_router.include_router(employee_time_off_history_router)
employee_management_apis_router.include_router(employee_time_off_balance_router)
employee_management_apis_router.include_router(vacation_requests_router)
api_router.include_router(employee_management_apis_router)

# Advanced Forecasting API endpoints (Tasks 51-75) - ML & AI-powered forecasting
advanced_forecasting_router = APIRouter(tags=["advanced-forecasting"])
advanced_forecasting_router.include_router(forecast_demand_models_router)
advanced_forecasting_router.include_router(forecast_capacity_planning_router)
advanced_forecasting_router.include_router(forecast_optimization_engine_router)
advanced_forecasting_router.include_router(forecast_pattern_analysis_router)
advanced_forecasting_router.include_router(forecast_seasonal_adjustments_router)
advanced_forecasting_router.include_router(forecast_historical_analysis_router)
advanced_forecasting_router.include_router(forecast_data_quality_router)
advanced_forecasting_router.include_router(forecast_realtime_monitor_router)
advanced_forecasting_router.include_router(forecast_realtime_adjustments_router)
advanced_forecasting_router.include_router(forecast_emergency_override_router)
advanced_forecasting_router.include_router(forecast_accuracy_validation_router)
advanced_forecasting_router.include_router(forecast_performance_benchmark_router)
advanced_forecasting_router.include_router(forecast_accuracy_reports_router)
advanced_forecasting_router.include_router(forecast_continuous_improvement_router)
advanced_forecasting_router.include_router(forecast_ml_insights_router)
api_router.include_router(advanced_forecasting_router)

# FINAL MASS DEPLOYMENT: Reporting API endpoints (Tasks 76-100) - Real PostgreSQL implementations
from .endpoints.report_executive_dashboard_REAL import router as report_executive_dashboard_router
from .endpoints.report_operational_metrics_REAL import router as report_operational_metrics_router
from .endpoints.report_performance_analytics_REAL import router as report_performance_analytics_router
from .endpoints.report_compliance_audit_REAL import router as report_compliance_audit_router
from .endpoints.report_custom_builder_REAL import router as report_custom_builder_router
from .endpoints.report_financial_metrics_REAL import router as report_financial_metrics_router
from .endpoints.report_workforce_analytics_REAL import router as report_workforce_analytics_router
from .endpoints.report_operational_dashboards_REAL import router as report_operational_dashboards_router
from .endpoints.report_predictive_insights_REAL import router as report_predictive_insights_router

# Executive Dashboard & KPI Reporting (Tasks 76-80)
executive_reporting_router = APIRouter(tags=["executive-reporting"])
executive_reporting_router.include_router(report_executive_dashboard_router)
executive_reporting_router.include_router(report_operational_metrics_router)
executive_reporting_router.include_router(report_performance_analytics_router)
executive_reporting_router.include_router(report_compliance_audit_router)
executive_reporting_router.include_router(report_custom_builder_router)
api_router.include_router(executive_reporting_router)

# Financial & Business Intelligence Reporting (Tasks 81-85)
financial_reporting_router = APIRouter(tags=["financial-reporting"])
financial_reporting_router.include_router(report_financial_metrics_router)
api_router.include_router(financial_reporting_router)

# Workforce & HR Analytics Reporting (Tasks 86-90)
workforce_reporting_router = APIRouter(tags=["workforce-reporting"])
workforce_reporting_router.include_router(report_workforce_analytics_router)
api_router.include_router(workforce_reporting_router)

# Operational Dashboards & Real-time Monitoring (Tasks 91-95)
operational_dashboards_router = APIRouter(tags=["operational-dashboards"])
operational_dashboards_router.include_router(report_operational_dashboards_router)
api_router.include_router(operational_dashboards_router)

# Predictive Analytics & AI Insights (Tasks 96-100)
predictive_reporting_router = APIRouter(tags=["predictive-reporting"])
predictive_reporting_router.include_router(report_predictive_insights_router)
api_router.include_router(predictive_reporting_router)