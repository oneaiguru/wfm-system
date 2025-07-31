# Verified Argus Navigation Pages

These pages have been tested and confirmed working in the real Argus system by R-agents using MCP browser tools.

## ✅ Verified Working Pages (from R5 testing)

### Exchange Platform
- **URL**: `/ccwfm/views/env/exchange/ExchangeView.xhtml`
- **Method**: JSF navigation
- **Verified**: 2025-07-31 by R5

### Operational Control Dashboard  
- **URL**: `/ccwfm/views/env/monitoring/MonitoringDashboardView.xhtml`
- **Method**: JSF with ViewState
- **Verified**: 2025-07-31 by R5

### Request Management System
- **URL**: `/ccwfm/views/env/personnel/request/UserRequestView.xhtml`
- **Method**: JSF form submission
- **Verified**: 2025-07-31 by R5

### Login Page
- **URL**: `/ccwfm/login.xhtml`
- **Method**: JSF POST with credentials
- **Note**: Uses ViewState parameter

### Security Admin
- **URL**: `/ccwfm/admin/security/roles.xhtml`
- **Method**: JSF admin portal
- **Note**: Requires admin privileges

## 📝 Navigation Patterns

All Argus pages follow these patterns:
1. URLs end with `.xhtml` extension
2. Full view names included (e.g., `MonitoringDashboardView.xhtml`)
3. Path structure: `/ccwfm/views/env/[module]/[ViewName].xhtml`
4. Session management through ViewState parameter
5. Navigation via JSF lifecycle, not REST calls