# Scheduling Template APIs - R7 Discovery

**Date**: 2025-07-29  
**Agent**: R7-SchedulingOptimization  
**Discovery Method**: Universal API Monitor + Live Testing

## 🏗️ Architecture Confirmed: JSF/PrimeFaces

Argus scheduling uses JavaServer Faces with PrimeFaces components and ViewState management.

## 📋 Template Selection API

### Endpoint
```
POST /ccwfm/views/env/planning/SchedulePlanningView.xhtml?cid=4
```

### Request Pattern
```
javax.faces.partial.ajax=true
javax.faces.source=templates_form-templates
javax.faces.partial.execute=templates_form-templates
javax.faces.behavior.event=rowSelect
javax.faces.partial.event=rowSelect
templates_form-templates_instantSelectedRowKey=12919835
templates_form-templates_selection=12919835
templates_form-templates_scrollState=0,0
javax.faces.ViewState=2320309741788605603:-832976432499262073
```

### Key Components
- **Source**: `templates_form-templates` (DataTable component)
- **Event**: `rowSelect` (Template selection)
- **Selection**: Template ID (e.g., 12919835 for "Мультискильный кейс")
- **ViewState**: Required for JSF state management

### Response
- **Status**: 200 OK
- **Size**: ~26KB
- **Duration**: ~4 seconds
- **Content**: Partial page update with selected template details

## 📅 Schedule Creation Initiation API

### Endpoint
```
POST /ccwfm/views/env/planning/SchedulePlanningView.xhtml?cid=4
```

### Request Pattern
```
javax.faces.partial.ajax=true
javax.faces.source=commands_form-create
javax.faces.partial.execute=planning_details
javax.faces.partial.render=planning_dialog
commands_form-create=commands_form-create
options_form=options_form
options_form-options_table_selection=
javax.faces.ViewState=2320309741788605603:-832976432499262073
options_panel_collapsed=false
tasks_form=tasks_form
tasks_form-tasks_table_selection=
```

### Key Components
- **Source**: `commands_form-create` (Create button)
- **Execute**: `planning_details` (Planning form region)
- **Render**: `planning_dialog` (Dialog to display)
- **Multiple Forms**: options_form, tasks_form (related components)

### Response
- **Status**: 200 OK
- **Size**: ~11KB
- **Duration**: ~1.2 seconds
- **Content**: Planning dialog HTML

## 🔍 Discovery Insights

### Template Management Flow
1. **Template List Load**: Initial page load shows available templates
2. **Template Selection**: AJAX call with rowSelect event
3. **Create Initiation**: Button click triggers dialog render
4. **Planning Parameters**: Dialog contains date/time/resource inputs

### JSF ViewState Pattern
- ViewState token required for all POST requests
- Format: `[numeric]:[negative-numeric]`
- Maintains server-side component tree state
- Must be preserved across requests

### Performance Characteristics
- Template selection: 4+ seconds (heavy processing)
- Dialog opening: ~1.2 seconds (lighter operation)
- All operations use partial page updates (AJAX)

## 🚨 Critical Differences from REST

### Authentication
- Session-based (JSESSIONID cookie)
- No JWT tokens
- ViewState acts as CSRF protection

### Request Format
- Form-encoded, not JSON
- Component IDs drive behavior
- Event-based architecture

### State Management
- Stateful (ViewState required)
- Server maintains component tree
- Cannot replay requests without valid state

## 🎯 Next Discovery Areas

### Remaining APIs to Capture
1. **Schedule Generation**: The actual planning execution
2. **Progress Monitoring**: How long operations take
3. **Resource Allocation**: How templates apply constraints
4. **Validation**: Error handling and constraint checking

### Testing Strategy
1. Fill planning dialog parameters
2. Submit schedule generation
3. Monitor long-running operation
4. Capture completion notification

## 💡 Implementation Implications

### For WFM Development
- Cannot use simple REST patterns
- Must implement JSF-compatible endpoints
- ViewState management critical
- Component-based thinking required

### For Integration
- Stateful sessions complicate scaling
- Load balancing needs sticky sessions
- API testing requires state preservation
- No simple cURL commands possible

## 🚀 Schedule Generation Execution API

### Endpoint
```
POST /ccwfm/views/env/planning/SchedulePlanningView.xhtml?cid=4
```

### Request Pattern
```
javax.faces.partial.ajax=true
javax.faces.source=planning_form-j_idt461
javax.faces.partial.execute=@all
javax.faces.partial.render=planning_form-j_idt461+options_form+tasks_form+commands_form
planning_form-j_idt461=planning_form-j_idt461
planning_form=planning_form
planning_form-plan_start_input=
planning_form-plan_end_input=
planning_form-input_tz-input_tz_focus=
planning_form-input_tz-input_tz_input=SystemTimezone(zoneId=Asia/Yekaterinburg)
```

### Key Components
- **Source**: `planning_form-j_idt461` (Start Planning button)
- **Execute**: `@all` (Full form submission)
- **Render**: Multiple forms (planning_form, options_form, tasks_form, commands_form)
- **Timezone**: `Asia/Yekaterinburg` (Екатеринбург)

### Response
- **Status**: 200 OK
- **Size**: ~16KB
- **Duration**: ~1.3 seconds
- **Content**: Updated planning interface with results

## 💡 Session Management Discovery

### Keep-Alive API
```
POST /ccwfm/touch?cid=4
- Method: POST
- Body: null
- Status: 204 No Content
- Duration: ~2.1 seconds
- Purpose: Maintain JSF session during long operations
```

### Session Pattern
- Conversation ID (`cid=4`) consistent across all calls
- ViewState token remains constant during session
- Touch endpoint prevents session timeout
- All operations use same base URL with JSF lifecycle

---

## 🔄 Phase 1: Template Variation Analysis

### Template Comparison Results

| Template Name | Template ID | Duration (ms) | Response Size (KB) | Performance Notes |
|---------------|-------------|---------------|--------------------|--------------------|
| Мультискильный кейс | 12919835 | 4096 | 26.8 | Slowest - Complex multi-skill logic |
| График по проекту 1 | 12919828 | 1838 | 25.7 | Fast - Project-based template |
| ТП - Неравномерная нагрузка | 4397101 | 2756 | 25.5 | Medium - Uneven load pattern |

### Key Findings

#### Template ID Patterns
- **Multi-skill templates**: Higher IDs (12919835, 12919828)
- **Load pattern templates**: Lower IDs (4397101)
- IDs appear to be sequential generation identifiers

#### Performance Characteristics
- **Project templates**: Fastest processing (1.8s)
- **Load pattern templates**: Medium processing (2.8s)  
- **Multi-skill templates**: Slowest processing (4.1s)
- Response sizes similar (~25-27KB) regardless of complexity

#### API Consistency
- All templates use identical JSF request pattern
- Same ViewState management across all types
- Same endpoint and conversation ID
- Only difference: `instantSelectedRowKey` parameter

### Template-Specific Behaviors
**Multi-skill complexity** correlates with longer processing time, suggesting server-side template analysis varies significantly by type.

---

## 🚨 Phase 2: Error & Validation Analysis

### Validation Error Patterns

#### Triggered Errors
1. **"Нет данных на выбранную дату"** (No data for selected date)
2. **"Нет задач для выбранного расписания"** (No tasks for selected schedule)

#### Error Response Characteristics
- **Status**: 200 OK (errors returned as content, not HTTP errors)
- **Duration**: ~1.7 seconds (faster than successful operations)
- **Response Size**: ~15KB (smaller than successful responses)
- **Error Count**: 23 error elements found in DOM

#### Validation Strategy
- **Client-side**: JSF validation displays errors in UI
- **Server-side**: Additional validation after form submission
- **Error Display**: Multiple error messages can appear simultaneously
- **Error Format**: Russian text messages with specific error types

### Key Insights
- **Graceful Degradation**: System doesn't crash on invalid input
- **Multiple Validation Layers**: Both client and server validation
- **Error Specificity**: Different messages for different validation failures
- **Performance Impact**: Invalid requests process faster than valid ones

---

**Status**: ✅ Complete workflow + 3 template variations + validation error patterns
**Total API Calls**: 8 (6 previous + 2 error scenario tests)
**Architecture**: JSF/PrimeFaces with multi-layer validation and graceful error handling