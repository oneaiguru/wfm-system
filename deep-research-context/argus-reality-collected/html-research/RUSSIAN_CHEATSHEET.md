# Russian UI Cheat Sheet - Essential Terms for Argus Navigation

## 🎯 Top 20 Most Critical Terms

### Main Menu Navigation
| Russian | English | Priority | Context |
|---------|---------|----------|---------|
| **Мой кабинет** | My Cabinet | ⭐⭐⭐ | Primary admin menu |
| **Заявки** | Requests | ⭐⭐⭐ | Request management |
| **Персонал** | Personnel | ⭐⭐⭐ | Employee functions |
| **Мониторинг** | Monitoring | ⭐⭐⭐ | Real-time dashboards |
| **Планирование** | Planning | ⭐⭐⭐ | Schedule creation |

### Common Actions  
| Russian | English | Priority | Context |
|---------|---------|----------|---------|
| **Сохранить** | Save | ⭐⭐⭐ | Triggers session timeout! |
| **Применить** | Apply | ⭐⭐⭐ | Used in forecast forms |
| **Создать заявку** | Create request | ⭐⭐⭐ | Vacation requests |
| **Доступные** | Available | ⭐⭐⭐ | Approval queue |
| **Подтвержден** | Approved | ⭐⭐ | Approval action |

### Request Types (Employee Portal)
| Russian | English | Priority | Context |
|---------|---------|----------|---------|
| **отгул** | Time off | ⭐⭐⭐ | Most common request |
| **больничный** | Sick leave | ⭐⭐ | Medical absence |
| **внеочередной отпуск** | Unscheduled vacation | ⭐⭐ | Emergency vacation |

### Navigation Terms
| Russian | English | Priority | Context |
|---------|---------|----------|---------|
| **Календарь** | Calendar | ⭐⭐⭐ | Both portals |
| **Сотрудники** | Employees | ⭐⭐⭐ | 513 total in system |
| **Группы** | Groups | ⭐⭐ | 19 total groups |
| **Службы** | Services | ⭐⭐ | 9 total services |

### Status & States
| Russian | English | Priority | Context |
|---------|---------|----------|---------|
| **Выполнена** | Completed | ⭐⭐ | Report status |
| **Отсутствует** | Absent | ⭐⭐ | Operator state |
| **Активности расписания** | Schedule Activities | ⭐⭐ | Monitoring column |

## 🚨 Critical Error Messages

### Session Management
| Russian | English | Action |
|---------|---------|--------|
| **Время жизни страницы истекло** | Page lifetime expired | Refresh page |
| **Ошибка системы** | System Error | Navigate back |

### Access Issues  
| Russian | English | Action |
|---------|---------|--------|
| **resolved to hidden** | Element hidden | Use direct URL |

## 📱 Mobile-Specific Terms
| Russian | English | Context |
|---------|---------|---------|
| **Открыть личный кабинет** | Open personal cabinet | Mobile menu |
| **Мой** | My (requests) | Employee tab |

## 🔧 Technical Terms

### Integration Module
| Russian | English | Context |
|---------|---------|---------|
| **Синхронизация персонала** | Personnel Synchronization | R4 domain |
| **Ручное сопоставление учёток** | Manual Account Mapping | Integration tab |
| **Интеграционные системы** | Integration Systems | Dropdown |
| **MCE** | MCE External System | Integration option |

### Forecasting Module  
| Russian | English | Context |
|---------|---------|---------|
| **Спрогнозировать нагрузку** | Forecast Load | 7-tab workflow |
| **Анализ пиков** | Peak Analysis | Forecast tab |
| **Коррекция исторических данных** | Historical Data Correction | First tab |

### Time & Frequency
| Russian | English | Context |
|---------|---------|---------|
| **Ежедневно** | Daily | Sync frequency |
| **Еженедельно** | Weekly | Sync frequency |
| **Ежемесячно** | Monthly | Sync frequency |
| **Часовой пояс** | Time Zone | Configuration |

## 💡 Pro Tips for R-Agents

### 1. **Menu Recognition**
- Look for **Мой кабинет** = You're in admin portal
- Look for **Календарь** only = You're in employee portal

### 2. **Request Flow**
- **Создать заявку** → **отгул/больничный/внеочередной отпуск** → **Сохранить**
- **Доступные** → **Подтвержден/Отказано**

### 3. **Error Handling**
- **Время жизни страницы истекло** = Session expired, refresh page
- **resolved to hidden** = Use direct URL instead of menu

### 4. **Data Validation**
- **513 Сотрудников** = Correct employee count
- **19 Групп** = Correct group count  
- **9 Служб** = Correct service count

## 🎯 Quick Copy-Paste for MCP

```javascript
// Common Russian terms for element detection
const russianTerms = {
  'Мой кабинет': 'My Cabinet',
  'Заявки': 'Requests', 
  'Персонал': 'Personnel',
  'Сохранить': 'Save',
  'Применить': 'Apply',
  'Доступные': 'Available',
  'Календарь': 'Calendar'
};

// Check for Russian page content
const isRussianPage = document.body.textContent.includes('Мой кабинет');
```

---
**Source**: Compiled from 600+ line navigation map contributions by R0, R2, R3, R4, R8
**Usage**: Essential for all R-agent Argus testing