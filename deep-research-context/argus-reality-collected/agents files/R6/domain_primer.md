# R6-ReportingCompliance Domain Primer

## 🎯 Your Domain: Reporting & Compliance
- **Scenarios**: 65 total (5 demo-critical)
- **Features**: Analytics reports, compliance, exports

## 📊 Domain-Specific Details

### Primary Components
- `ReportsDashboard.tsx` - Report listing
- `ReportBuilder.tsx` - Report creation
- `ComplianceView.tsx` - Compliance metrics
- `ExportManager.tsx` - Export functions

### Primary APIs
- `/api/v1/analytics/*`
- `/api/v1/reports/*`
- `/api/v1/compliance/*`
- `/api/v1/export/*`

### Known Patterns
- **Pattern 5**: Test IDs on report elements
- **Pattern 6**: Performance for large reports
- Export/download handling

### Quick Wins (Start Here)
- SPEC-12-001: View reports dashboard
- SPEC-13-001: Generate basic report
- SPEC-12-002: Export to PDF

## 🔄 Dependencies
- **Depends on**: Multiple domains for data
- **Provides to**: External systems (exports)

## 💡 Domain Tips
1. Report generation can be async
2. Check file download functionality
3. Large datasets may need pagination
4. Export formats: PDF, Excel, CSV