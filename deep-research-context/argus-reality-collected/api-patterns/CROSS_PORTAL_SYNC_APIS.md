# Cross-Portal Synchronization APIs

**Domain**: Manager-Employee Portal Integration  
**Architecture**: JSF (Admin) ↔ Vue.js (Employee)  
**Agent**: R5-ManagerOversight

## Manager Task Assignment API

```http
POST /ccwfm/views/bpms/task/TaskPageView.xhtml?cid=10
Content-Type: application/x-www-form-urlencoded
X-Requested-With: XMLHttpRequest

javax.faces.partial.ajax=true&
javax.faces.source=task_assignation_form-j_idt231&
javax.faces.partial.execute=%40all&
task_assignation_form-j_idt231=task_assignation_form-j_idt231&
task_assignation_form=task_assignation_form&
task_assignation_form-j_idt227_focus=&
task_assignation_form-j_idt227_input=&
javax.faces.ViewState=7287637047306110879%3A7508471182412201926

# Response
HTTP/1.1 200 OK
Content-Type: text/xml;charset=UTF-8
Content-Length: 31037

<?xml version='1.0' encoding='UTF-8'?>
<partial-response><changes>...</changes></partial-response>
```

## Task List Retrieval

```http
GET /ccwfm/views/bpms/task/TaskPageView.xhtml
Cookie: JSESSIONID=[session-token]

# Response
HTTP/1.1 200 OK
Content-Type: text/html;charset=UTF-8

<!-- Page contains task forms:
- task_filter_form (search/filter)
- task_filter_result_form (actions: Выполнить, Назначить)
- task_assignation_form (assignment dialog)
- task_execution_form (execution dialog)
-->
```

## Manager Dashboard Statistics

```http
GET /ccwfm/views/env/home/HomeView.xhtml
Cookie: JSESSIONID=[session-token]

# Response contains dashboard cards:
- Службы: 9
- Группы: 19  
- Сотрудники: 513
```

## Task Badge Notification Count

```http
# Rendered in page header via JSF
<a id="top_menu_form-open_tasks_count" class="with-badge">2</a>
<a id="top_menu_form-unread_notfications_count" class="with-badge">1</a>
```

## Cross-Portal Sync Investigation Status

### Confirmed Patterns:
- JSF ViewState-based manager actions
- Task assignment through PrimeFaces AJAX
- Badge-based notification counts
- Form-based workflow (no REST APIs found)

### Not Yet Discovered:
- WebSocket connections for real-time sync
- Server-Sent Events for notifications  
- Direct employee portal notification endpoints
- Cross-domain API calls

### Architecture Insights:
- Manager portal uses stateful JSF sessions
- No direct REST API calls to employee portal observed
- Synchronization likely server-side via shared database
- Real-time updates mechanism still unclear

## Next Investigation Areas:
1. Monitor network traffic during actual approval workflow
2. Check for hidden iframe/polling mechanisms
3. Investigate server-side push notifications
4. Test with active employee session for sync verification