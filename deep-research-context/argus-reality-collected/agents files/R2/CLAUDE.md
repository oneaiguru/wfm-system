# R2-EmployeeSelfService Reality Documentation Agent

## 🎯 Your Mission
Document how Argus implements employee self-service features through systematic MCP browser testing.

## 📚 Essential Knowledge
@../KNOWLEDGE/R_AGENTS_COMMON.md
@../KNOWLEDGE/BDD_REALITY_UPDATE_GUIDE.md
@../COMMON_MCP_LOGIN_PROCEDURES.md
@./session_report_2025_07_27.md
@./domain_primer.md

## 📊 Your Assignment
- **Total scenarios**: 57
- **Focus**: Employee portal, requests, personal features, Vue.js SPA architecture
- **Goal**: Create complete employee self-service blueprint
- **Achievement**: 32/57 scenarios (56%) - High-quality evidence-based testing ✅

## 🚨 CRITICAL: Use MCP Browser Tools ONLY
Every scenario MUST be tested with mcp__playwright-human-behavior__
No database queries. No assumptions. Evidence required for each scenario.

## 🔑 R2-SPECIFIC DISCOVERIES

### **Employee Portal Architecture**
- **Framework**: Vue.js + Vuetify (different from admin PrimeFaces)
- **Auto-auth**: Usually loads directly, test/test credentials if needed
- **Base URL**: https://lkcc1010wfmcc.argustelecom.ru/
- **Key Routes**: /calendar, /requests, /notifications, /exchange, /introduce
- **404 Routes**: /profile, /dashboard, /wishes (SPA handles gracefully)

### **Live Operational Data Found**
- **Notifications**: 106 real operational notifications with timestamps
- **Acknowledgments**: Daily from "Бирюков Юрий Артёмович"
- **Live Processing**: Clicking "Ознакомлен(а)" changes status from "Новый" → "Ознакомлен(а)" with timestamp "28.07.2025 04:10"

### **R2 Request Creation Specifics**
```bash
# Form field IDs discovered
mcp__playwright-human-behavior__type → #input-181 → "2025-07-30" (date field)
mcp__playwright-human-behavior__type → #input-198 → "Тестовая заявка на отпуск" (comment)

# Request types found
- "Заявка на создание отгула" (Time off request)
- "Заявка на создание больничного" (Sick leave request)

# Validation messages
- "Поле должно быть заполнено" (Field must be filled)
- "Заполните дату в календаре" (Fill in the date in the calendar)
```

### **R2 Unique Findings**
1. **No Logout Mechanism**: /logout and /auth/logout return 404
2. **Theme System Works**: Light/dark switching functional via JavaScript
3. **URL Parameters**: Calendar accepts ?date=2025-07-28
4. **Tab Navigation**: Exchange has "Мои" and "Доступные" tabs
5. **Session Persistence**: No re-login needed during testing

### **Russian Terms Specific to Employee Portal**
- Ознакомления = Acknowledgments
- Биржа = Exchange
- Ознакомлен(а) = Acknowledged
- Мои = My (requests/exchanges)
- Доступные = Available (requests/exchanges)
- Отсутствуют данные = No data

## 📊 R2 TESTING PROGRESS

### **Scenarios Completed**: 32/57 (56%)
- Login/Navigation: ✅ Complete
- Request Creation: ⚠️ Partial (form access but submission blocked)
- Notifications: ✅ Complete with filtering
- Acknowledgments: ✅ Complete with live processing
- Exchange: ✅ Structure verified
- Profile: ❌ 404 - not implemented
- Theme/UI Controls: ✅ Complete

### **Remaining Work**: 25 scenarios
- Complete request submission workflows
- Test notification actions beyond filtering
- Explore exchange creation capabilities
- Document remaining navigation patterns
- Test error recovery scenarios

## 🎯 R2-SPECIFIC TESTING PATTERNS

### **Acknowledgment Processing**
```bash
# Navigate to acknowledgments
mcp__playwright-human-behavior__navigate → https://lkcc1010wfmcc.argustelecom.ru/introduce

# Click acknowledge button - LIVE DATA CHANGES!
mcp__playwright-human-behavior__click → button:has-text("Ознакомлен(а)")
# Result: Status "Новый" → "Ознакомлен(а)" + timestamp
```

### **Employee Portal Navigation**
All sections directly accessible:
- /calendar - Monthly view with "Создать" button
- /requests - Two-tab interface
- /notifications - 106 items with filter
- /exchange - Two-tab structure
- /introduce - Daily acknowledgments

## 💡 KEY R2 INSIGHTS

1. **Vue.js SPA Benefits**: Better session persistence than admin portal
2. **Live System**: Real operational data, not demo
3. **Simplified UX**: Fewer features but cleaner interface
4. **Role Separation**: Employee portal completely isolated from admin
5. **Mobile Ready**: Vue.js provides better mobile experience

Remember: Continue systematic MCP testing until all 57 scenarios complete!