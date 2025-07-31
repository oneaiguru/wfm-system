# Reference Data CRUD API Patterns - R6 Discovery

**Source**: R6-ReportingCompliance API Research
**Date**: 2025-07-29
**Method**: MCP browser monitoring and testing

## 🏗️ CRUD Architecture Overview

### Framework Pattern
- **Technology**: JSF/PrimeFaces (same as reporting)
- **State Management**: ViewState-based transactions
- **Session**: Conversation ID (cid) parameter
- **AJAX**: Partial page updates for all CRUD operations

## 📥 Import Operations (Bulk Create)

### Production Calendar Import
```javascript
// Dialog triggered by button click
POST /ccwfm/views/env/schedule/ProductionCalendarView.xhtml?cid=10
javax.faces.partial.ajax=true
javax.faces.source=production_calendar_form-j_idt176
javax.faces.partial.execute=@all

// File upload component
<p:fileUpload id="calendar_import_form-select_file_input"
              accept=".xml,.csv"
              mode="advanced" />
```

### Key Characteristics:
1. **File-based import** for bulk operations
2. **XML/CSV formats** supported
3. **Modal dialog** for file selection
4. **Asynchronous processing** likely for large files

## 🔒 Access Control Patterns

### Permission Restrictions
```http
GET /ccwfm/views/env/rdb/absence/AbsenceReasonView.xhtml
HTTP/1.1 403 Forbidden

GET /ccwfm/views/env/events/SpecialEventView.xhtml  
HTTP/1.1 403 Forbidden
```

### Implications:
- **Role-based access** to reference data management
- **Basic admin** (Konstantin) has limited CRUD permissions
- **HR Admin** role likely required for full CRUD access

## 🔄 State Management Pattern

### Calendar Modification Flow
1. **Initial Load**: Calendar renders with existing data
2. **User Interaction**: Click on calendar day
3. **State Tracking**: Buttons remain disabled (no client-side state)
4. **Server Validation**: All changes validated server-side
5. **Save Operation**: Would send complete calendar state

## 📊 CRUD Patterns (Inferred)

### CREATE Pattern
```javascript
// Expected pattern based on JSF conventions
POST /ccwfm/views/env/[module]/[Entity]View.xhtml?cid=[X]
javax.faces.partial.ajax=true
javax.faces.source=[form_id]-save_button
javax.faces.partial.execute=@form
javax.faces.partial.render=[form_id] [messages_id]
[form_id]-[field1]=[value1]
[form_id]-[field2]=[value2]
javax.faces.ViewState=[token]
```

### UPDATE Pattern
```javascript
// Similar to CREATE but includes entity ID
[form_id]-entity_id=[id]
[form_id]-version=[version_number]  // Optimistic locking
```

### DELETE Pattern
```javascript
// Confirmation dialog first, then:
javax.faces.source=[form_id]-delete_button
[form_id]-selected_id=[entity_id]
```

### READ Pattern
```javascript
// Table pagination/sorting
javax.faces.source=[table_id]
[table_id]_first=[offset]
[table_id]_rows=[page_size]
[table_id]_sortBy=[column]
[table_id]_sortOrder=[asc|desc]
```

## 🎯 Reference Data Types Observed

### Accessible with Basic Admin:
1. **Production Calendar** - Holiday/workday configuration
2. **Roles** - 12 roles defined (read-only)
3. **Services** - 9 services configured
4. **Time Zones** - 4 Russian time zones

### Restricted (403 Forbidden):
1. **Absence Reasons** - Requires higher permissions
2. **Special Events** - Requires higher permissions
3. **Labor Standards** - Likely requires HR Admin role

## 💡 Implementation Insights

### JSF CRUD Lifecycle
1. **Render Response**: Initial form display
2. **Apply Request Values**: Form submission
3. **Process Validations**: Server-side validation
4. **Update Model Values**: Database updates
5. **Invoke Application**: Business logic
6. **Render Response**: Updated view

### Validation Pattern
- **Client-side**: Minimal (basic required fields)
- **Server-side**: Comprehensive business rules
- **Error Display**: JSF messages component
- **Field Highlighting**: PrimeFaces validation styling

## 🚀 Modern CRUD Alternative

### REST API Design
```javascript
// Modern approach for reference data
GET    /api/v1/reference/calendar/2025
POST   /api/v1/reference/calendar/2025/import
PUT    /api/v1/reference/calendar/2025/days/2025-01-01
DELETE /api/v1/reference/events/123

// With proper HTTP status codes
201 Created
204 No Content
400 Bad Request (validation errors)
409 Conflict (optimistic locking)
```

## 📝 Summary

Argus reference data management:
- ✅ Consistent JSF/PrimeFaces patterns
- ✅ Bulk import capabilities
- ✅ Strong access control
- ❌ Limited to server-side validation
- ❌ Full page state required for updates
- ❌ No real-time collaboration features

For a modern replica, consider:
1. REST APIs with proper HTTP verbs
2. Client-side validation for better UX
3. WebSocket notifications for concurrent edits
4. Optimistic UI updates with rollback
5. Granular permissions per operation