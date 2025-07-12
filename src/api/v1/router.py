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