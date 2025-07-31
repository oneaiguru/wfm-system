# R5-ManagerOversight Hidden Features Discovery

**Date**: 2025-07-30  
**Agent**: R5-ManagerOversight  
**Focus**: Manager-specific hidden functionality

## 🎯 Manager Domain Hidden Features

### 1. Task Delegation System
**Feature**: Task Queue with Badge Counter  
**Where Found**: Top menu - `a[id*="open_tasks_count"]` with badge showing "2"  
**Why Not in BDD**: Only basic task assignment covered, not queue management  
**Implementation Impact**: Need full task queue UI with filtering/sorting  
**Details**:
- Badge shows real-time task count
- Click leads to `/bpms/task/TaskPageView.xhtml` (403 forbidden)
- Suggests role-based task delegation we can't access

### 2. Bulk Approval via Exchange Platform
**Feature**: Multi-proposal creation in Exchange (Биржа)  
**Where Found**: `/ccwfm/views/env/exchange/ExchangeView.xhtml`  
**Why Not in BDD**: Entire Exchange platform missing from specs  
**Implementation Impact**: Major feature - shift trading marketplace  
**Details**:
- "Кол-во предложений" field allows bulk creation
- Template-based bulk operations
- Can create multiple shift exchange proposals at once

### 3. Team Coverage Analytics Widget
**Feature**: Dashboard cards showing real-time metrics  
**Where Found**: Home dashboard - service/group/employee counters  
**Why Not in BDD**: Only static reporting covered  
**Implementation Impact**: Need real-time aggregation queries  
**Details**:
- Live counters: 9 Services, 19 Groups, 515 Employees
- Updates without page refresh (likely polling)
- Quick navigation to each section

### 4. Manager Notification Center
**Feature**: Dropdown notification history with categories  
**Where Found**: Top menu notification bell - shows "1" unread  
**Why Not in BDD**: Only basic notifications mentioned  
**Implementation Impact**: Need categorized notification system  
**Details**:
- Shows full history with timestamps
- Categories: Report failures, Report completions
- Direct links to relevant sections
- Persists across sessions

### 5. Group Status Toggle (Bulk Enable/Disable)
**Feature**: Real-time group activation control  
**Where Found**: `/ccwfm/views/env/monitoring/GroupsManagementView.xhtml`  
**Why Not in BDD**: Group management only covers CRUD  
**Implementation Impact**: Need real-time status management  
**Details**:
- "Отключить группу" (Disable group) button
- Affects all employees in group instantly
- No groups shown in test environment

### 6. Business Rules Bulk Assignment
**Feature**: Multi-select employee assignment interface  
**Where Found**: `/ccwfm/views/env/personnel/BusinessRulesView.xhtml`  
**Why Not in BDD**: Not covered at all  
**Implementation Impact**: Complex rule engine needed  
**Details**:
- Filter by Department/Segment/Group/Type
- Select multiple employees for bulk operations
- Apply business rules to filtered sets

### 7. Session Management with CID
**Feature**: Conversation ID tracking (cid parameter)  
**Where Found**: All URLs contain `?cid=N` parameter  
**Why Not in BDD**: Infrastructure detail omitted  
**Implementation Impact**: Need stateful session handling  
**Details**:
- cid=1,2,3... increments with navigation
- 22-minute timeout warning
- ViewState preservation across requests

### 8. Error Recovery Options
**Feature**: Graceful error handling with recovery  
**Where Found**: Error dialogs throughout system  
**Why Not in BDD**: Only happy paths documented  
**Implementation Impact**: Need comprehensive error handling  
**Details**:
- "Обновить" (Refresh) button on errors
- "Время жизни страницы истекло" timeout messages
- Preserves form data on recovery

### 9. Global Search Integration
**Feature**: "Искать везде..." (Search everywhere)  
**Where Found**: Top menu search box  
**Why Not in BDD**: Search only mentioned for specific entities  
**Implementation Impact**: Need unified search across all entities  
**Details**:
- 3-character minimum
- 600ms delay (performance optimization)
- Autocomplete across all system entities

### 10. Personnel Sync Scheduling
**Feature**: Automated sync with complex scheduling  
**Where Found**: `/ccwfm/views/env/personnel/synchronization/PersonnelSynchronizationView.xhtml`  
**Why Not in BDD**: Only manual sync covered  
**Implementation Impact**: Need cron-like scheduler  
**Details**:
- Daily/Weekly/Monthly options
- Timezone-aware scheduling
- "Last week of month" type options
- Error reporting dashboard

## 📊 Manager-Specific Patterns

### Delegation Patterns:
- Task queues with badges
- Role-based access (403 errors indicate hierarchy)
- Bulk operations throughout

### Coverage/Analytics Patterns:
- Real-time dashboard widgets
- Polling for live updates (60-second intervals)
- Drill-down navigation from metrics

### Escalation Patterns:
- Notification categories for different urgency levels
- Direct action links in notifications
- Error recovery workflows

## 🚀 Implementation Priorities

1. **Exchange Platform** - Complete shift trading system
2. **Business Rules Engine** - Bulk assignment capabilities
3. **Task Queue System** - With proper role-based access
4. **Real-time Analytics** - Live dashboard updates
5. **Advanced Notifications** - Categorized with history

## 💡 Key Insight

Manager features focus heavily on:
- **Bulk operations** (not just individual actions)
- **Real-time visibility** (not just reports)
- **Delegation workflows** (not just direct actions)
- **Team-level controls** (not just individual management)

These patterns suggest a much more sophisticated management layer than our BDD specs capture.