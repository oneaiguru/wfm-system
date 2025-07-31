# R1-AdminSecurity Russian UI Terminology Glossary

**Purpose**: Comprehensive glossary of all Russian terms encountered in Argus admin interfaces  
**Status**: 50+ terms documented, continuously updated during testing  
**Last Updated**: 2025-07-28

## 🔑 AUTHENTICATION & LOGIN

| Russian Term | English Translation | Context | Screen/Feature |
|--------------|-------------------|---------|----------------|
| Войти | Login/Enter | Login button | Login form |
| Пароль | Password | Password field label | Login form |
| Аргус WFM CC | Argus WFM CC | System title | Admin portal header |
| Личный кабинет | Personal Cabinet | System title | Employee portal |
| Время жизни страницы истекло | Page lifetime expired | Session timeout | Error message |
| Истекает срок действия пароля | Password is expiring | Password warning | Login dialog |
| Не сейчас | Not now | Dismiss password warning | Dialog button |
| Обновить | Refresh/Update | Refresh page after timeout | Error dialog |

## 🛡️ SECURITY & ROLES

| Russian Term | English Translation | Context | Screen/Feature |
|--------------|-------------------|---------|----------------|
| Роли | Roles | Security roles section | Admin menu |
| Создать новую роль | Create new role | Add role button | Role management |
| Название | Name/Title | Role name field | Role form |
| Описание | Description | Role description field | Role form |
| Сохранить | Save | Save button | Forms |
| Права доступа | Access rights | Permissions section | Role form |
| Разрешения | Permissions | Permission settings | Role form |
| Активна | Active | Role status | Role list |
| Редактировать | Edit | Edit button | Role list |
| Удалить | Delete | Delete button | Role list |

## 👥 EMPLOYEE MANAGEMENT

| Russian Term | English Translation | Context | Screen/Feature |
|--------------|-------------------|---------|----------------|
| Сотрудники | Employees | Employee section | Admin menu |
| Список | List | Employee list view | Navigation |
| Добавить нового сотрудника | Add new employee | Add employee button | Employee management |
| Имя | First name | Name field | Employee form |
| Фамилия | Last name | Surname field | Employee form |
| Email | Email | Email field | Employee form |
| Отдел | Department | Department field | Employee form |
| Должность | Position | Job title field | Employee form |
| Телефон | Phone | Phone number field | Employee form |
| Статус | Status | Employee status | Employee list |

## 🔧 SYSTEM & CONFIGURATION

| Russian Term | English Translation | Context | Screen/Feature |
|--------------|-------------------|---------|----------------|
| Система | System | System section | Admin menu |
| Настройки | Settings | Settings section | Admin menu |
| Конфигурация | Configuration | System config | Admin interface |
| Мониторинг | Monitoring | Monitoring section | Admin menu |
| Отчеты | Reports | Reports section | Admin menu |
| Экспорт | Export | Export function | Various screens |
| Импорт | Import | Import function | Various screens |
| Поиск | Search | Search function | List views |

## ⚠️ ERROR MESSAGES & SYSTEM RESPONSES

| Russian Term | English Translation | Context | Screen/Feature |
|--------------|-------------------|---------|----------------|
| Ошибка системы | System error | 500 error page | Error screen |
| Произошла ошибка | An error occurred | Error message | Error dialog |
| Пожалуйста, обратитесь к системному администратору | Please contact system administrator | Error instruction | Error page |
| Упс..Вы попали на несуществующую страницу | Oops..You've reached a non-existent page | 404 error | Employee portal |
| Доступ запрещен | Access forbidden | 403 error | Admin restrictions |
| Страница не найдена | Page not found | 404 error | Missing resources |

## 📊 DATA & INTERFACE ELEMENTS

| Russian Term | English Translation | Context | Screen/Feature |
|--------------|-------------------|---------|----------------|
| Таблица | Table | Data table | List views |
| Фильтр | Filter | Filter controls | List views |
| Сортировка | Sorting | Sort controls | Table headers |
| Страница | Page | Pagination | List views |
| Всего | Total | Record count | List footers |
| Записей | Records | Data entries | Count displays |
| Выбрать все | Select all | Bulk selection | Checkboxes |
| Действия | Actions | Action menu | List rows |

## 🗓️ SCHEDULE & TIME MANAGEMENT

| Russian Term | English Translation | Context | Screen/Feature |
|--------------|-------------------|---------|----------------|
| Расписание | Schedule | Schedule section | Time management |
| График | Schedule/Graph | Work schedule | Planning |
| Смена | Shift | Work shift | Schedule planning |
| Время | Time | Time fields | Various forms |
| Дата | Date | Date fields | Calendar inputs |
| Календарь | Calendar | Calendar view | Date selection |
| Рабочие дни | Working days | Work schedule | Calendar config |
| Выходные | Weekends | Non-working days | Calendar config |

## 🔐 PERMISSIONS & ACCESS CONTROL

| Russian Term | English Translation | Context | Screen/Feature |
|--------------|-------------------|---------|----------------|
| Просмотр | View | View permission | Permission settings |
| Изменение | Modification | Edit permission | Permission settings |
| Создание | Creation | Create permission | Permission settings |
| Удаление | Deletion | Delete permission | Permission settings |
| Администратор | Administrator | Admin role | User management |
| Пользователь | User | Regular user | User management |
| Группа | Group | User group | Access control |

## 📋 FORMS & VALIDATION

| Russian Term | English Translation | Context | Screen/Feature |
|--------------|-------------------|---------|----------------|
| Поле обязательно для заполнения | Field is required | Validation message | Form validation |
| Неверный формат | Invalid format | Format error | Input validation |
| Данные сохранены | Data saved | Success message | Form submission |
| Отмена | Cancel | Cancel button | Form dialogs |
| Подтвердить | Confirm | Confirm button | Confirmation dialogs |

## 🆔 UNIQUE IDENTIFIERS PATTERNS

| Pattern | Example | Context | Generation Rule |
|---------|---------|---------|-----------------|
| Role-XXXXXXX | Role-12919834 | Auto-generated role ID | Role creation |
| Worker-XXXXXXX | Worker-12919853 | Auto-generated employee ID | Employee creation |
| User-XXXXXXX | User-12919xxx | User account ID | User management |

## 📝 USAGE NOTES

### Documentation Standards
- **Always quote exact Russian text** from interface
- **Include English translation** for each term
- **Note specific context** where term appears
- **Record screen/feature location** for reference

### Update Process
- **During MCP testing**: Capture all new Russian terms
- **Add immediately**: Don't wait until session end
- **Include context**: Where and how the term is used
- **Verify spelling**: Exact match to interface text

### Special Characters & Formatting
- **Cyrillic encoding**: UTF-8 proper display
- **Punctuation**: Include exact punctuation from interface
- **Case sensitivity**: Match original capitalization
- **Spacing**: Preserve exact spacing in multi-word terms

This glossary is continuously updated during systematic testing to ensure complete Russian UI documentation.