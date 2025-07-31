# R2-EmployeeSelfService Employee Portal Russian UI Glossary

**Purpose**: Russian terminology specific to Vue.js employee portal interface  
**Framework**: Vue.js + Vuetify (vs admin PrimeFaces interface)  
**Portal**: https://lkcc1010wfmcc.argustelecom.ru/  
**User Context**: test/test (employee permissions)  
**Last Updated**: 2025-07-28

## 🏠 PORTAL IDENTITY & AUTHENTICATION

| Russian Term | English Translation | Context | Vue.js Component |
|--------------|-------------------|---------|------------------|
| Личный кабинет | Personal Cabinet | Portal title | Header component |
| Войти | Login/Enter | Login button | Authentication form |
| Автоматическая авторизация | Automatic authorization | Auto-login behavior | Session management |

## 📅 CALENDAR & DATE MANAGEMENT

| Russian Term | English Translation | Context | Vue.js Component |
|--------------|-------------------|---------|------------------|
| Календарь | Calendar | Main navigation menu | v-navigation-drawer |
| juillet 2025 | July 2025 (French) | Month display | Calendar header |
| Создать | Create | Request creation button | Calendar interface |
| Дата | Date | Date fields | v-date-picker |

## 📋 REQUEST MANAGEMENT

| Russian Term | English Translation | Context | Vue.js Component |
|--------------|-------------------|---------|------------------|
| Заявки | Requests | Main navigation menu | v-navigation-drawer |
| Мои | My/Mine | My requests tab | v-tabs |
| Доступные | Available | Available requests tab | v-tabs |
| Заявки, в которых вы принимаете участие | Requests in which you participate | Tab description | Tab content |
| Заявки, в которых вы можете принять участие | Requests in which you can participate | Tab description | Tab content |
| Тип заявки | Request type | Table header | v-data-table |
| Дата создания | Creation date | Table header | v-data-table |
| Желаемая дата | Desired date | Table header | v-data-table |
| Статус | Status | Table header/field | v-data-table |

### REQUEST TYPES & FORMS

| Russian Term | English Translation | Context | Vue.js Component |
|--------------|-------------------|---------|------------------|
| Заявка на создание отгула | Time off request | Request type option | v-select |
| Заявка на создание больничного | Sick leave request | Request type option | v-select |
| Причина | Reason | Form field label | v-text-field |
| Комментарий | Comment | Form field label | v-textarea |
| Добавить | Add | Submit button | v-btn |

### FORM VALIDATION MESSAGES

| Russian Term | English Translation | Context | Vue.js Component |
|--------------|-------------------|---------|------------------|
| Поле должно быть заполнено | Field must be filled | Validation message | v-messages |
| Заполните дату в календаре | Fill in the date in calendar | Date validation | v-messages |

## 🔔 NOTIFICATION SYSTEM

| Russian Term | English Translation | Context | Vue.js Component |
|--------------|-------------------|---------|------------------|
| Оповещения | Notifications | Main navigation menu | v-navigation-drawer |
| Новое | New | Notification status | Status indicator |
| Просмотрено | Viewed | Notification status | Status indicator |

## 📝 ACKNOWLEDGMENT SYSTEM

| Russian Term | English Translation | Context | Vue.js Component |
|--------------|-------------------|---------|------------------|
| Ознакомления | Acknowledgments | Main navigation menu | v-navigation-drawer |
| Ознакомлен(а) | Acknowledged | Action button/status | v-btn/status |
| Новый | New | Acknowledgment status | Status indicator |
| Бирюков Юрий Артёмович | Biryukov Yury Artemovich | Real user name | Live data |

### ACKNOWLEDGMENT INTERACTIONS

| Russian Term | English Translation | Context | Vue.js Component |
|--------------|-------------------|---------|------------------|
| Просьба сообщить о своей готовности | Please report your readiness | Notification content | Notification item |

## 🔄 EXCHANGE SYSTEM

| Russian Term | English Translation | Context | Vue.js Component |
|--------------|-------------------|---------|------------------|
| Биржа | Exchange | Main navigation menu | v-navigation-drawer |
| Мои | My | My exchanges tab | v-tabs |
| Доступные | Available | Available exchanges tab | v-tabs |
| Отсутствуют данные | No data | Empty state message | Empty state component |

## 👤 PROFILE & SETTINGS

| Russian Term | English Translation | Context | Vue.js Component |
|--------------|-------------------|---------|------------------|
| Профиль | Profile | Navigation menu item | v-navigation-drawer |
| Пожелания | Wishes | Navigation menu item | v-navigation-drawer |

**Note**: Profile and Wishes return 404 - not implemented for employee portal

## 🎨 THEME SYSTEM

| Russian Term | English Translation | Context | Vue.js Component |
|--------------|-------------------|---------|------------------|
| Светлая тема | Light theme | Theme selector | Theme button |
| Темная тема | Dark theme | Theme selector | Theme button |

## ⚠️ ERROR MESSAGES & SYSTEM RESPONSES

| Russian Term | English Translation | Context | Vue.js Component |
|--------------|-------------------|---------|------------------|
| Упс..Вы попали на несуществующую страницу | Oops..You've reached a non-existent page | 404 error (SPA) | Error component |

**Note**: SPA routing handles 404s gracefully vs traditional page errors

## 🗓️ TEMPORAL EXPRESSIONS

| Russian Term | English Translation | Context | Vue.js Component |
|--------------|-------------------|---------|------------------|
| 28.07.2025 04:10 | 28.07.2025 04:10 | Timestamp format | Date display |
| +05:00 | UTC+5 timezone | Timezone indicator | Timestamp |

## 🏗️ ARCHITECTURAL TERMINOLOGY

| Russian Term | English Translation | Context | Technical Note |
|--------------|-------------------|---------|----------------|
| SPA | Single Page Application | Vue.js architecture | Client-side routing |
| Реактивность | Reactivity | Vue.js data binding | Component updates |
| Маршрутизация | Routing | Navigation system | Fragment-based URLs |

## 📊 DATA STATES & INDICATORS

| Russian Term | English Translation | Context | Vue.js Component |
|--------------|-------------------|---------|------------------|
| Загрузка | Loading | Loading state | v-progress-circular |
| Пусто | Empty | No data state | Empty state component |
| Ошибка | Error | Error state | Error component |

## 🔗 URL ROUTING PATTERNS

| Pattern | Translation | Context | Vue.js Router |
|---------|-------------|---------|---------------|
| /calendar | Calendar page | Direct routing | Route component |
| /requests | Requests page | Direct routing | Route component |
| /notifications | Notifications page | Direct routing | Route component |
| /exchange | Exchange page | Direct routing | Route component |
| /introduce | Acknowledgments page | Direct routing | Route component |
| #tabs-available-offers | Available tab fragment | Fragment routing | Tab navigation |

## 🆔 FIELD IDENTIFIERS (Form Testing)

| Field ID | Russian Label | English Translation | Vue.js Component |
|----------|---------------|-------------------|------------------|
| #input-181 | Дата | Date | v-text-field |
| #input-198 | Комментарий | Comment | v-textarea |
| #input-245 | Причина | Reason | v-text-field |

## 🚨 LIVE OPERATIONAL DATA EXAMPLES

| Data Type | Russian Example | English Translation | Context |
|-----------|-----------------|-------------------|---------|
| User acknowledgment | Бирюков Юрий Артёмович | Biryukov Yury Artemovich | Real employee name |
| Status change | "Новый" → "Ознакомлен(а)" | "New" → "Acknowledged" | Live state change |
| Timestamp | 28.07.2025 04:10 | 28.07.2025 04:10 | Real system time |
| Notification count | 106+ уведомлений | 106+ notifications | Operational volume |

## 📝 USAGE NOTES FOR R2 TESTING

### Vue.js vs PrimeFaces Differences
- **Component Structure**: v-* prefixed components vs traditional HTML
- **Reactivity**: Real-time UI updates vs page reloads
- **Validation**: Inline validation messages vs form submission validation
- **Navigation**: SPA routing vs traditional page navigation

### Employee Portal Specific Patterns
- **Auto-authentication**: ~90% success rate vs manual login
- **Session Persistence**: Better than admin portal PrimeFaces
- **404 Handling**: Graceful SPA 404s vs traditional error pages
- **Live Data Integration**: Real operational data vs demo data

### Documentation Standards for R2
- **Quote exact Russian text** from Vue.js components
- **Include Vue.js component types** when identifiable
- **Note SPA behavior differences** from traditional pages
- **Record live operational data** examples
- **Document permission limitations** for test/test user

### Update Process During MCP Testing
1. **Capture new terms** immediately during testing
2. **Include Vue.js context** - component type, reactivity
3. **Note live data examples** - real user names, timestamps
4. **Document permission boundaries** - what test user can/cannot access
5. **Compare with admin portal** terminology when relevant

This glossary focuses specifically on the Vue.js employee portal interface and is continuously updated during systematic R2 testing to ensure complete Russian UI documentation for the employee self-service domain.