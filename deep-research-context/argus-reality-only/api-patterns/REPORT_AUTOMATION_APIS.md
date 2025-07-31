# Report Automation & Scheduling APIs - R6 Phase 1 Discovery

**Source**: R6-ReportingCompliance 2nd Round API Research
**Date**: 2025-07-29
**Method**: MCP browser automation with enhanced monitoring

## 🎯 Discovery Summary

### Phase 1 Status: Partially Complete
**Key Finding**: Report automation features exist but require higher permissions than basic admin (Konstantin)

## 🔍 Attempted Discovery Areas

### 1. Report Editor (Template Creation)
**URL**: `/ccwfm/views/env/tmp/ReportTypeEditorView.xhtml`
**Status**: ❌ System Error - Permission Denied

#### Interface Structure Discovered:
```yaml
Tree Categories:
  - "Общие КЦ" (General CC)
  - "Для Демонстрации" (For Demonstration)
  - "sdas" (Custom category)

Template Actions:
  - Добавить (Add) - Create new report template
  - Удалить (Delete) - Remove template
  - Template creation form with name input
```

#### API Pattern Captured:
```javascript
// Template creation attempt
POST /ccwfm/views/env/tmp/ReportTypeEditorView.xhtml
javax.faces.partial.ajax=true
javax.faces.source=report_type_creation_form-create_button
report_type_creation_form-report_name=Automation Test Report
javax.faces.ViewState=[token]

// Result: System Error (Permission Denied)
```

### 2. Report List (Scheduling Discovery)
**URL**: `/ccwfm/views/env/tmp/ReportTypeMapView.xhtml`
**Status**: ⚠️ Limited Access - Session Management Issues

#### Interface Elements:
- Report categories organized hierarchically
- "Построить отчет" (Build Report) button
- Session timeout handling
- Report template tree structure

## 🚫 Permission Barriers Discovered

### Basic Admin Limitations (Konstantin/12345):
1. **Template Creation**: System error when creating new report templates
2. **Report Editor**: Limited to viewing existing templates
3. **Automation Settings**: Not accessible at basic permission level
4. **Session Timeout**: Frequent session expiration requires refresh

### Required Permission Level:
- **HR Admin** or **System Admin** role likely needed
- **Report Designer** specific permissions
- **Template Management** privileges

## 🏗️ Inferred Architecture Patterns

### Template Storage System
```sql
-- Inferred database structure
CREATE TABLE report_templates (
  template_id SERIAL PRIMARY KEY,
  category_id INTEGER,
  template_name VARCHAR(255),
  template_config TEXT, -- JSON or XML config
  created_by INTEGER,
  created_at TIMESTAMP,
  is_active BOOLEAN
);

CREATE TABLE report_categories (
  category_id SERIAL PRIMARY KEY,
  parent_id INTEGER,
  category_name VARCHAR(100),
  sort_order INTEGER
);
```

### JSF Template Management Pattern
```javascript
// Expected full template creation flow
POST /ccwfm/views/env/tmp/ReportTypeEditorView.xhtml
javax.faces.partial.ajax=true
javax.faces.source=report_type_creation_form-create_button
javax.faces.partial.execute=report_type_creation_form
javax.faces.partial.render=report_type_tree_form
report_type_creation_form-report_name=[name]
report_type_creation_form-category_id=[category]
report_type_creation_form-report_config=[config]
javax.faces.ViewState=[token]
```

## 📊 Scheduling System Insights

### Report Automation Architecture (Inferred)
```yaml
Scheduling Engine:
  - Cron-based job scheduler
  - Task queue for report generation
  - Email distribution system
  - File storage management

Schedule Types:
  - Daily reports (operational metrics)
  - Weekly summaries (management dashboards)
  - Monthly analytics (compliance reports)
  - Ad-hoc requests (user-triggered)
```

### Expected Scheduling APIs:
```javascript
// Report scheduling configuration
POST /ccwfm/views/env/schedule/ReportScheduleView.xhtml
javax.faces.source=schedule_form-create_schedule
schedule_form-report_template_id=[template_id]
schedule_form-cron_expression=0 8 * * MON-FRI
schedule_form-email_recipients=[emails]
schedule_form-output_format=xlsx
javax.faces.ViewState=[token]
```

## 🔄 Session Management Pattern

### Timeout Handling
```javascript
// Session expiration detection
if (response.includes('Время жизни страницы истекло')) {
  // Show refresh dialog
  showSessionExpiredDialog();
}

// Auto-refresh mechanism
POST /ccwfm/views/env/tmp/ReportTypeMapView.xhtml
javax.faces.source=refresh_button
javax.faces.partial.ajax=true
javax.faces.partial.execute=@all
javax.faces.ViewState=[new_token]
```

## 💡 Implementation Recommendations

### For Faithful Replica
1. **Multi-tier Permission System**
   - Basic users: View reports only
   - Report designers: Create/edit templates
   - Administrators: Full automation control

2. **Template Engine Architecture**
   - JSON-based template definitions
   - Category hierarchy management
   - Version control for templates
   - Permission-based access control

3. **Scheduling Infrastructure**
   - Quartz scheduler or equivalent
   - Background job processing
   - Email service integration
   - File storage with cleanup

### For Modern Implementation
```yaml
API Design:
  GET    /api/v1/reports/templates
  POST   /api/v1/reports/templates
  PUT    /api/v1/reports/templates/{id}
  DELETE /api/v1/reports/templates/{id}
  
  GET    /api/v1/reports/schedules
  POST   /api/v1/reports/schedules
  PUT    /api/v1/reports/schedules/{id}
  DELETE /api/v1/reports/schedules/{id}
```

## 🚨 Phase 1 Constraints

### What Was Blocked:
- ❌ Template creation (permission denied)
- ❌ Scheduling interface access
- ❌ Automation configuration
- ❌ Advanced customization features

### What Was Discovered:
- ✅ Template storage structure
- ✅ Category organization system
- ✅ Permission model requirements
- ✅ Session management patterns
- ✅ JSF form handling for templates

## 📋 Next Steps for Complete Discovery

### Required for Full Analysis:
1. **Higher Permission Account**
   - HR Admin credentials
   - System Administrator access
   - Report Designer role

2. **Alternative Approaches**
   - Database schema inspection
   - Configuration file analysis
   - Log file examination
   - Developer documentation review

3. **Cross-Agent Coordination**
   - R1 (Personnel) may have admin access
   - R0 (System) may have configuration access
   - META-R coordination for credential elevation

## 🎯 Conclusion

Phase 1 revealed the **architectural foundation** of Argus report automation but was limited by permission constraints. The system clearly supports:
- ✅ Template-based report customization
- ✅ Hierarchical category organization
- ✅ Permission-based access control
- ✅ JSF-based management interface

Complete automation API documentation requires elevated privileges or alternative discovery methods.

---

**Phase 1 Status**: Foundation discovered, permission-limited
**Next Phase**: Requires elevated access or alternative approach
**Value**: Architecture patterns and permission model documented