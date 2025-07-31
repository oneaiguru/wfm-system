# Manager Dashboard & Analytics APIs

**Domain**: Manager Operational Dashboard  
**Architecture**: JSF/PrimeFaces  
**Agent**: R5-ManagerOversight

## Dashboard Home Page Load

```http
GET /ccwfm/views/env/home/HomeView.xhtml
Cookie: JSESSIONID=[session-token]

# Response
HTTP/1.1 200 OK
Content-Type: text/html;charset=UTF-8

<!-- Dashboard cards rendered server-side -->
<div class="dashboard-card">
    <span>Службы</span>
    <span class="count">9</span>
</div>
<div class="dashboard-card">
    <span>Группы</span>
    <span class="count">19</span>
</div>
<div class="dashboard-card">
    <span>Сотрудники</span>
    <span class="count">513</span>
</div>
```

## Task Count Badge API

```javascript
// Embedded in page header (server-side rendered)
<a id="top_menu_form-open_tasks_count" 
   class="ui-commandlink ui-widget topmenu-item ripplelink with-badge"
   onclick="PrimeFaces.ab({s:'top_menu_form-open_tasks_count'})">2</a>

// Click triggers JSF AJAX update
POST /ccwfm/views/env/home/HomeView.xhtml
javax.faces.partial.ajax=true&
javax.faces.source=top_menu_form-open_tasks_count&
javax.faces.ViewState=[viewstate-token]
```

## Notification Count Badge

```javascript
<a id="top_menu_form-unread_notfications_count" 
   class="ui-commandlink ui-widget topmenu-item ripplelink with-badge">1</a>

// Recent notifications dropdown
<div class="notification-dropdown">
    <div class="notification-item">
        24.07.2025 19:06 - Отчет Отчет по ролям с подразделением успешно построен
    </div>
    <div class="notification-item">
        24.07.2025 19:06 - Отчет Общий отчет по рабочему времени успешно построен  
    </div>
</div>
```

## Manager Operational Control Panel

```http
GET /ccwfm/views/env/monitoring/OperationalControlView.xhtml
Cookie: JSESSIONID=[session-token]

# Expected Response Structure:
- Real-time team metrics
- Current staffing levels
- Schedule compliance percentages
- Approval queue statistics
```

## Team Management Dashboard

```http
GET /ccwfm/views/env/monitoring/GroupManagementView.xhtml
Cookie: JSESSIONID=[session-token]

# Expected Response Structure:
- Group performance metrics
- Team schedule overview
- Absence/attendance statistics
- Productivity indicators
```

## Dashboard Data Aggregation Pattern

### Server-Side Rendering:
- All dashboard metrics rendered server-side via JSF
- No client-side API calls for dashboard data
- Page refresh required for updated metrics

### Potential AJAX Updates:
```javascript
// PrimeFaces poll component (if implemented)
<p:poll interval="30" 
        listener="#{dashboardBean.updateMetrics}" 
        update="dashboard-metrics" />
```

### Dashboard Bean Structure (Inferred):
```java
// Server-side managed bean
@ManagedBean
@ViewScoped
public class DashboardBean {
    private int serviceCount;      // 9
    private int groupCount;        // 19
    private int employeeCount;     // 513
    private int openTaskCount;     // 2
    private int unreadNotifications; // 1
    
    // Aggregation queries run server-side
    public void updateMetrics() {
        // Database queries for real-time counts
    }
}
```

## Missing Dashboard APIs

### Not Yet Discovered:
1. Real-time metric update endpoints
2. Drill-down APIs for dashboard cards
3. Custom dashboard configuration APIs
4. Manager-specific KPI endpoints
5. Team performance trend APIs

### Architecture Limitation:
- JSF server-side rendering limits API discovery
- Dashboard data aggregated during page generation
- No REST endpoints for dashboard metrics
- WebSocket/SSE not observed for real-time updates