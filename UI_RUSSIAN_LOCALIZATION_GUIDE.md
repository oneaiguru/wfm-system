# UI RUSSIAN LOCALIZATION GUIDE

## 🎯 **LOCALIZATION OVERVIEW**
This comprehensive guide provides detailed specifications for Russian language implementation across all 5 BDD-compliant UI components, ensuring cultural appropriateness, technical accuracy, and compliance with BDD specifications.

---

## 📋 **LOCALIZATION STRATEGY SUMMARY**

### **Core Principles**:
```typescript
interface LocalizationPrinciples {
  bddCompliance: {
    priority: "HIGHEST";
    requirement: "Exact Russian terms from BDD specifications";
    validation: "Must match line-by-line BDD text";
  };
  
  userExperience: {
    defaultLanguage: "Russian"; // Per BDD requirement
    languageSwitching: "Real-time without reload";
    persistence: "localStorage preservation";
    fallback: "English for missing translations";
  };
  
  technicalImplementation: {
    encoding: "UTF-8";
    fontSupport: "Cyrillic character set";
    inputValidation: "Cyrillic-only patterns where required";
    sorting: "Russian alphabetical order";
  };
  
  culturalAdaptation: {
    dateFormat: "DD.MM.YYYY"; // Russian standard
    timeFormat: "24-hour"; // European standard
    numberFormat: "Space thousands separator (1 000 000)";
    currency: "RUB with proper symbol placement";
  };
}
```

### **Translation Architecture**:
```typescript
interface TranslationArchitecture {
  structure: {
    pattern: "Nested object structure per component";
    keys: "Descriptive English keys for maintainability";
    values: "Native Russian translations";
    namespacing: "Component-specific translation objects";
  };
  
  implementation: {
    library: "React i18next (recommended) or custom translation hook";
    loading: "Lazy loading for large translation files";
    caching: "Browser localStorage for performance";
    updates: "Hot-reload in development environment";
  };
  
  maintenance: {
    validation: "Automated checks for missing translations";
    consistency: "Style guide for Russian technical terms";
    review: "Native speaker review process";
    versioning: "Translation versioning with component updates";
  };
}
```

---

## 🔐 **LOGIN COMPONENT RUSSIAN LOCALIZATION**

### **Authentication Interface**:
```typescript
const loginTranslations = {
  ru: {
    // Main interface elements (BDD lines 28-31)
    title: 'Вход в систему WFM',
    subtitle: 'Введите ваши учетные данные для доступа к системе',
    
    // Form fields (exact BDD specification)
    email: 'Имя пользователя',        // BDD line 29
    password: 'Пароль',               // BDD line 30
    login: 'Войти',                   // BDD line 31
    
    // Status messages
    logging: 'Вход в систему...',
    welcome: 'Добро пожаловать',
    redirecting: 'Перенаправление на панель управления...',
    
    // Error messages (BDD lines 32-35)
    errors: {
      required: 'Пожалуйста, введите имя пользователя и пароль',
      apiUnavailable: 'Сервер API недоступен. Попробуйте позже.',
      authFailed: 'Ошибка аутентификации. Проверьте ваши учетные данные.',
      unexpected: 'Произошла неожиданная ошибка. Попробуйте еще раз.',
      networkError: 'Ошибка сети. Проверьте подключение к интернету.',
      timeout: 'Время ожидания истекло. Попробуйте еще раз.'
    },
    
    // Language switching
    languageSwitch: 'English',        // Shows opposite language
    
    // Accessibility labels
    accessibility: {
      emailField: 'Поле ввода имени пользователя',
      passwordField: 'Поле ввода пароля',
      loginButton: 'Кнопка входа в систему',
      languageButton: 'Переключение языка интерфейса',
      errorAlert: 'Сообщение об ошибке'
    }
  }
};
```

### **Authentication Process Terminology**:
```typescript
const authProcessTerms = {
  // Technical terms
  credentials: 'учетные данные',
  authentication: 'аутентификация',
  authorization: 'авторизация',
  session: 'сессия',
  token: 'токен',
  
  // User feedback
  successful: 'успешно',
  failed: 'неудачно',
  pending: 'выполняется',
  timeout: 'время истекло',
  
  // Security terms
  biometric: 'биометрическая аутентификация',
  fingerprint: 'отпечаток пальца',
  faceId: 'распознавание лица',
  securityKey: 'ключ безопасности'
};
```

---

## 📊 **DASHBOARD COMPONENT RUSSIAN LOCALIZATION**

### **Real-time Monitoring Interface**:
```typescript
const dashboardTranslations = {
  ru: {
    // Main title (exact BDD specification)
    title: 'Мониторинг операций в реальном времени',
    subtitle: 'Операционный контроль',
    
    // Six key metrics (exact BDD labels)
    metrics: {
      operatorsOnline: 'Операторы онлайн %',           // BDD line 18
      loadDeviation: 'Отклонение нагрузки',            // BDD line 19
      operatorRequirement: 'Требуется операторов',     // BDD line 20
      slaPerformance: 'Производительность SLA',        // BDD line 21
      acdRate: 'Коэффициент ACD',                      // BDD line 22
      ahtTrend: 'Тренд AHT'                           // BDD line 23
    },
    
    // Metric calculations (in Russian)
    calculations: {
      operatorsOnline: '(Фактически онлайн / Запланировано) × 100',
      loadDeviation: '(Фактическая нагрузка - Прогноз) / Прогноз',
      slaPerformance: 'Формат 80/20 (80% звонков за 20 секунд)',
      acdRate: '(Отвеченные/Предложенные) × 100',
      ahtTrend: 'Взвешенное среднее время обработки'
    },
    
    // Traffic light thresholds (exact BDD text)
    thresholds: {
      operatorsOnline: 'Зелёный >80%, Жёлтый 70-80%, Красный <70%',
      loadDeviation: '±10% Зелёный, ±20% Жёлтый, >20% Красный',
      slaPerformance: 'Цель ±5% отклонения'
    },
    
    // Status indicators
    status: {
      lastUpdate: 'Последнее обновление',
      updateFrequency: 'Обновляется каждые 30 секунд',
      connecting: 'Подключение...',
      error: 'Ошибка загрузки данных',
      offline: 'Автономный режим'
    },
    
    // Color coding descriptions
    colors: {
      green: 'Нормально',
      yellow: 'Предупреждение', 
      red: 'Критично',
      gray: 'Нет данных'
    },
    
    // Time units
    timeUnits: {
      seconds: 'секунд',
      minutes: 'минут',
      hours: 'часов',
      days: 'дней'
    }
  }
};
```

### **Technical Metrics Terminology**:
```typescript
const metricsTerminology = {
  // Call center specific terms
  operators: 'операторы',
  online: 'онлайн',
  offline: 'офлайн',
  available: 'доступен',
  busy: 'занят',
  
  // Performance indicators
  performance: 'производительность',
  efficiency: 'эффективность',
  utilization: 'использование',
  throughput: 'пропускная способность',
  
  // Load and forecasting
  load: 'нагрузка',
  forecast: 'прогноз',
  actual: 'фактический',
  planned: 'запланированный',
  deviation: 'отклонение',
  
  // Service level terms
  serviceLevel: 'уровень сервиса',
  sla: 'SLA',
  acd: 'ACD',
  aht: 'AHT',
  answered: 'отвеченные',
  offered: 'предложенные',
  abandoned: 'пропущенные'
};
```

---

## 👥 **EMPLOYEE COMPONENT RUSSIAN LOCALIZATION**

### **Personnel Management Interface**:
```typescript
const employeeTranslations = {
  ru: {
    // Main interface
    title: 'Управление персоналом',
    subtitle: 'Сотрудники',
    
    // Action buttons
    buttons: {
      createEmployee: 'Создать сотрудника',
      search: 'Поиск',
      filter: 'Фильтр',
      export: 'Экспорт',
      import: 'Импорт',
      edit: 'Редактировать',
      delete: 'Удалить',
      save: 'Сохранить',
      cancel: 'Отменить'
    },
    
    // Form labels (exact BDD specification)
    labels: {
      lastName: 'Фамилия',              // BDD line 26
      firstName: 'Имя',                 // BDD line 27
      patronymic: 'Отчество',           // BDD line 28
      personnelNumber: 'Табельный номер', // BDD line 29
      department: 'Подразделение',       // BDD line 30
      position: 'Должность',             // BDD line 31
      hireDate: 'Дата приема',          // BDD line 32
      timeZone: 'Часовой пояс',         // BDD line 33
      
      // Additional fields
      email: 'Электронная почта',
      phone: 'Телефон',
      skills: 'Навыки',
      workRule: 'Правило работы',
      performance: 'Норма выработки'
    },
    
    // Department hierarchy (exact BDD names)
    departments: {
      callCenter: 'Колл-центр',                      // Level 1
      technicalSupport: 'Техническая поддержка',     // Level 2
      sales: 'Отдел продаж',                         // Level 2
      level1Support: 'Поддержка 1-го уровня',        // Level 3
      level2Support: 'Поддержка 2-го уровня'         // Level 3
    },
    
    // Positions
    positions: {
      operator: 'Оператор',
      supervisor: 'Супервизор',
      manager: 'Менеджер',
      specialist: 'Специалист',
      teamLead: 'Руководитель группы',
      administrator: 'Администратор'
    },
    
    // Validation messages
    validation: {
      required: 'Обязательное поле',
      cyrillicRequired: 'Используйте только кириллические символы',
      uniquePersonnelNumber: 'Табельный номер должен быть уникальным',
      emailFormat: 'Некорректный формат электронной почты',
      phoneFormat: 'Некорректный формат телефона',
      dateFormat: 'Некорректный формат даты'
    },
    
    // Status messages
    status: {
      loading: 'Загрузка сотрудников...',
      saving: 'Сохранение...',
      error: 'Ошибка загрузки данных',
      success: 'Сотрудник успешно создан',
      noEmployees: 'Сотрудники не найдены',
      employeesFound: 'сотрудников найдено',
      lastUpdate: 'Последнее обновление'
    },
    
    // Search and filtering
    search: {
      placeholder: 'Поиск по фамилии, имени или табельному номеру...',
      allDepartments: 'Все подразделения',
      allPositions: 'Все должности',
      clearFilters: 'Очистить фильтры',
      resultsCount: 'Найдено результатов'
    }
  }
};
```

### **Cyrillic Validation Implementation**:
```typescript
const cyrillicValidation = {
  // Exact pattern from BDD specification
  pattern: /^[а-яё\s\-]+$/i,
  
  // Character sets
  cyrillicLowercase: 'абвгдеёжзийклмнопрстуфхцчшщъыьэюя',
  cyrillicUppercase: 'АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ',
  allowedSymbols: [' ', '-'], // Space and hyphen for compound names
  
  // Validation function
  validate: (value: string): boolean => {
    return /^[а-яё\s\-]+$/i.test(value);
  },
  
  // Error messages by field
  errorMessages: {
    lastName: 'Фамилия должна содержать только кириллические символы',
    firstName: 'Имя должно содержать только кириллические символы',
    patronymic: 'Отчество должно содержать только кириллические символы'
  },
  
  // Examples for user guidance
  examples: {
    valid: ['Иванов', 'Петрова-Сидорова', 'О\'Коннор'],
    invalid: ['Smith', 'Petrov123', 'Иванов_А']
  }
};
```

---

## 📅 **SCHEDULE COMPONENT RUSSIAN LOCALIZATION**

### **Schedule Planning Interface**:
```typescript
const scheduleTranslations = {
  ru: {
    // Main interface
    title: 'Планирование рабочих расписаний',
    subtitle: 'Создание расписаний с интеграцией отпусков',
    
    // Action buttons
    buttons: {
      save: 'Сохранить',
      reset: 'Сбросить',
      export: 'Экспорт',
      import: 'Импорт',
      addShift: 'Добавить смену',
      deleteShift: 'Удалить смену',
      extendShift: 'Продлить смену',        // BDD line 236
      moveShift: 'Переместить смену',       // BDD line 238
      generateVacations: 'Генерировать отпуска',  // BDD line 176
      addVacation: 'Добавить отпуск',       // BDD line 177
      vacationPriority: 'Приоритет отпуска', // BDD line 178
      fixedVacation: 'Фиксированный отпуск'  // BDD line 179
    },
    
    // Employee names (exact BDD specification)
    employees: {
      'ivanov': 'Иванов И.И.',     // BDD line 17
      'petrov': 'Петров П.П.',     // BDD line 18
      'sidorova': 'Сидорова А.А.'  // BDD line 19
    },
    
    // Performance standards
    performance: {
      monthly: 'Часов в месяц',     // 168 hours per BDD
      annual: 'Часов в год',        // 2080 hours per BDD
      weekly: 'Часов в неделю',     // 40 hours per BDD
      standard: 'Норма выработки'
    },
    
    // Work rules (BDD specification)
    workRules: {
      'standard_week': '5/2 Стандартная неделя',  // BDD line 31
      'flexible': 'Гибкий график',
      'split_shift': 'Раздельная смена',
      'night_shift': 'Ночная смена'
    },
    
    // Schedule elements
    schedule: {
      shift: 'Смена',
      break: 'Перерыв',
      lunch: 'Обед',
      overtime: 'Сверхурочные',
      restDay: 'Выходной',
      holiday: 'Праздник',
      sickLeave: 'Больничный',
      vacation: 'Отпуск'
    },
    
    // Vacation types (BDD lines 250-252)
    vacationTypes: {
      desired_period: 'Желаемый (период)',           // BDD line 250
      desired_calendar: 'Желаемый (календарные дни)', // BDD line 251
      extraordinary: 'Внеочередной'                  // BDD line 252
    },
    
    // Compliance constraints (exact BDD text)
    constraints: {
      minRestBetweenShifts: 'Мин. отдых между сменами: 11 часов', // BDD line 43
      maxConsecutiveHours: 'Макс. непрерывных часов: 40',         // BDD line 44
      maxConsecutiveDays: 'Макс. рабочих дней подряд: 5',         // BDD line 45
      overtimeLimit: 'Лимит сверхурочных: 120 часов/год'
    },
    
    // Status messages
    status: {
      loading: 'Загрузка расписания...',
      saving: 'Сохранение...',
      error: 'Ошибка',
      success: 'Успешно сохранено',
      conflict: 'Конфликт расписания',
      compliance: 'Соответствие нормам',
      violation: 'Нарушение норм'
    }
  }
};
```

### **Schedule Management Terminology**:
```typescript
const scheduleTerminology = {
  // Time periods
  timeUnits: {
    hour: 'час',
    hours2_4: 'часа',      // 2-4 hours
    hours5plus: 'часов',   // 5+ hours
    day: 'день',
    days2_4: 'дня',        // 2-4 days
    days5plus: 'дней',     // 5+ days
    week: 'неделя',
    weeks2_4: 'недели',
    weeks5plus: 'недель',
    month: 'месяц',
    year: 'год'
  },
  
  // Work patterns
  patterns: {
    fullTime: 'полная занятость',
    partTime: 'частичная занятость',
    flexible: 'гибкий график',
    remote: 'удаленная работа',
    shift: 'сменная работа'
  },
  
  // Rotation patterns (BDD line 40)
  rotation: {
    'W': 'Работа',    // Work day
    'R': 'Отдых',     // Rest day
    'WWWWWRR': '5 рабочих, 2 выходных'
  }
};
```

---

## 📱 **MOBILE COMPONENT RUSSIAN LOCALIZATION**

### **Mobile Personal Cabinet Interface**:
```typescript
const mobileTranslations = {
  ru: {
    // Main interface
    title: 'Личный кабинет',
    subtitle: 'Мобильная версия',
    
    // Navigation (BDD lines 33-39)
    navigation: {
      calendar: 'Календарь',          // BDD line 33
      requests: 'Заявки',            // BDD line 34
      profile: 'Профиль',            // BDD line 36
      notifications: 'Уведомления',   // BDD line 37
      settings: 'Настройки'          // BDD line 38
    },
    
    // Calendar views (BDD lines 46-50)
    calendar: {
      monthly: 'Месяц',              // BDD line 47
      weekly: 'Неделя',              // BDD line 48
      fourDay: '4 дня',              // BDD line 49
      daily: 'День',                 // BDD line 50
      workShifts: 'Рабочие смены',
      breaks: 'Перерывы',
      lunches: 'Обеды',
      events: 'События',
      shiftDetails: 'Детали смены'
    },
    
    // Request types (exact BDD terms)
    requests: {
      myRequests: 'Мои заявки',         // BDD line 118
      availableRequests: 'Доступные заявки', // BDD line 119
      createRequest: 'Создать заявку',
      sickLeave: 'больничный',          // BDD line 101
      dayOff: 'отгул',                  // BDD line 102
      vacation: 'внеочередной отпуск',  // BDD line 103
      
      // Form fields
      requestType: 'Тип заявки',
      dateSelection: 'Выбор даты',
      reason: 'Причина/комментарий',
      duration: 'Продолжительность',
      
      // Status
      status: 'Статус',
      pending: 'На рассмотрении',
      approved: 'Одобрено',
      rejected: 'Отклонено'
    },
    
    // Notifications (BDD lines 151-156)
    notifications: {
      breakReminder: 'Напоминание о перерыве',    // BDD line 151
      lunchReminder: 'Напоминание об обеде',      // BDD line 152
      scheduleChange: 'Изменение расписания',     // BDD line 153
      requestUpdate: 'Обновление заявки',         // BDD line 154
      exchangeResponse: 'Ответ на обмен',         // BDD line 155
      meetingReminder: 'Напоминание о встрече',   // BDD line 156
      markAsRead: 'Отметить как прочитанное',
      markAsUnread: 'Отметить как непрочитанное'
    },
    
    // Profile information (BDD lines 169-175)
    profile: {
      fullName: 'Полное имя',           // BDD line 170
      department: 'Подразделение',      // BDD line 171
      position: 'Должность',            // BDD line 172
      employeeId: 'Табельный номер',    // BDD line 173
      supervisor: 'Руководитель',       // BDD line 174
      timeZone: 'Часовой пояс',         // BDD line 175
      updateContact: 'Обновить контакты',
      changePreferences: 'Изменить настройки'
    },
    
    // Settings (BDD lines 255-270)
    settings: {
      biometricAuth: 'Биометрическая аутентификация', // BDD line 22
      offlineSync: 'Автономная синхронизация',    // BDD lines 238-252
      language: 'Язык интерфейса',        // BDD line 261
      theme: 'Тема оформления',            // BDD line 260
      timeFormat: 'Формат времени',        // BDD line 264
      dateFormat: 'Формат даты',
      notifications: 'Уведомления',
      quietHours: 'Тихие часы',            // BDD line 233
      autoSync: 'Автоматическая синхронизация',
      cacheSize: 'Размер кэша'
    },
    
    // Status indicators
    status: {
      online: 'В сети',
      offline: 'Автономный режим',         // BDD offline mode
      syncing: 'Синхронизация...',
      syncComplete: 'Синхронизация завершена',
      biometricEnabled: 'Биометрия включена',
      biometricDisabled: 'Биометрия отключена',
      lastSync: 'Последняя синхронизация'
    },
    
    // Theme options
    themes: {
      light: 'Светлая',
      dark: 'Темная',
      auto: 'Автоматически'
    },
    
    // Time format options
    timeFormats: {
      '12': '12-часовой',
      '24': '24-часовой'
    }
  }
};
```

### **Mobile-Specific Terminology**:
```typescript
const mobileTerminology = {
  // Device capabilities
  device: {
    biometric: 'биометрия',
    fingerprint: 'отпечаток пальца',
    faceId: 'Face ID',
    touchId: 'Touch ID',
    camera: 'камера',
    microphone: 'микрофон',
    gps: 'GPS',
    push: 'push-уведомления'
  },
  
  // Network states
  network: {
    online: 'онлайн',
    offline: 'офлайн',
    syncing: 'синхронизация',
    cached: 'кэшировано',
    downloading: 'загрузка',
    uploading: 'отправка'
  },
  
  // Interaction terms
  interaction: {
    tap: 'нажмите',
    swipe: 'проведите',
    pinch: 'сведите пальцы',
    longPress: 'удерживайте',
    doubleTab: 'двойное нажатие'
  }
};
```

---

## 🔤 **TYPOGRAPHY AND FORMATTING STANDARDS**

### **Font and Character Support**:
```css
/* Russian font stack with Cyrillic support */
@font-face {
  font-family: 'WFM-Regular';
  src: url('./fonts/WFM-Regular.woff2') format('woff2');
  unicode-range: U+0400-04FF, U+0500-052F; /* Cyrillic blocks */
}

.russian-text {
  font-family: 'WFM-Regular', 'Segoe UI', 'Roboto', 'Arial', sans-serif;
  font-variant-numeric: lining-nums;
  text-rendering: optimizeLegibility;
}

/* Cyrillic character spacing adjustments */
.cyrillic-names {
  letter-spacing: 0.02em;
  word-spacing: 0.1em;
}
```

### **Text Direction and Alignment**:
```css
/* Russian text formatting */
.russian-content {
  direction: ltr; /* Left-to-right for Russian */
  text-align: left;
  hyphens: auto;
  hyphenate-limit-chars: 6 3 3;
  lang: 'ru';
}

/* Number formatting for Russian locale */
.russian-numbers {
  font-variant-numeric: tabular-nums;
}
```

### **Date and Time Formatting**:
```typescript
const russianDateTimeFormats = {
  // Standard Russian date format
  dateFormat: 'DD.MM.YYYY',
  
  // Time format (24-hour preferred)
  timeFormat: 'HH:mm',
  
  // DateTime combinations
  dateTimeFormat: 'DD.MM.YYYY HH:mm',
  
  // Relative time expressions
  relativeTime: {
    now: 'сейчас',
    minuteAgo: 'минуту назад',
    minutesAgo: (n: number) => `${n} ${getPluralForm(n, 'минуту', 'минуты', 'минут')} назад`,
    hourAgo: 'час назад',
    hoursAgo: (n: number) => `${n} ${getPluralForm(n, 'час', 'часа', 'часов')} назад`,
    dayAgo: 'день назад',
    daysAgo: (n: number) => `${n} ${getPluralForm(n, 'день', 'дня', 'дней')} назад`
  },
  
  // Month names
  months: [
    'январь', 'февраль', 'март', 'апрель', 'май', 'июнь',
    'июль', 'август', 'сентябрь', 'октябрь', 'ноябрь', 'декабрь'
  ],
  
  // Day names
  weekdays: [
    'воскресенье', 'понедельник', 'вторник', 'среда', 'четверг', 'пятница', 'суббота'
  ],
  
  // Short day names
  weekdaysShort: ['Вс', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб']
};
```

---

## 🔢 **NUMERICAL AND PLURALIZATION RULES**

### **Russian Pluralization Logic**:
```typescript
// Russian plural forms: 1, 2-4, 5+
function getPluralForm(count: number, form1: string, form2: string, form5: string): string {
  const lastDigit = count % 10;
  const lastTwoDigits = count % 100;
  
  // Special cases for 11-14
  if (lastTwoDigits >= 11 && lastTwoDigits <= 14) {
    return form5;
  }
  
  // Regular rules
  if (lastDigit === 1) {
    return form1; // 1, 21, 31, etc.
  } else if (lastDigit >= 2 && lastDigit <= 4) {
    return form2; // 2-4, 22-24, 32-34, etc.
  } else {
    return form5; // 0, 5-20, 25-30, etc.
  }
}

// Usage examples
const employeeCount = (count: number) => 
  `${count} ${getPluralForm(count, 'сотрудник', 'сотрудника', 'сотрудников')}`;

const hoursCount = (count: number) =>
  `${count} ${getPluralForm(count, 'час', 'часа', 'часов')}`;

const daysCount = (count: number) =>
  `${count} ${getPluralForm(count, 'день', 'дня', 'дней')}`;
```

### **Number Formatting**:
```typescript
const russianNumberFormat = {
  // Thousands separator (space in Russian)
  thousands: ' ',
  
  // Decimal separator (comma in Russian)
  decimal: ',',
  
  // Format function
  formatNumber: (num: number): string => {
    return new Intl.NumberFormat('ru-RU').format(num);
  },
  
  // Currency formatting
  formatCurrency: (amount: number): string => {
    return new Intl.NumberFormat('ru-RU', {
      style: 'currency',
      currency: 'RUB'
    }).format(amount);
  },
  
  // Percentage formatting
  formatPercentage: (value: number): string => {
    return new Intl.NumberFormat('ru-RU', {
      style: 'percent',
      minimumFractionDigits: 1,
      maximumFractionDigits: 1
    }).format(value / 100);
  }
};
```

---

## 🎨 **CULTURAL ADAPTATION GUIDELINES**

### **User Interface Conventions**:
```typescript
const culturalAdaptations = {
  // Form field ordering (Russian convention)
  nameFieldOrder: ['lastName', 'firstName', 'patronymic'],
  
  // Address format
  addressFormat: [
    'Индекс',      // Postal code
    'Страна',      // Country
    'Регион',      // Region/State
    'Город',       // City
    'Улица',       // Street
    'Дом',         // Building
    'Квартира'     // Apartment
  ],
  
  // Phone number format
  phoneFormat: '+7 (999) 999-99-99',
  
  // Business hours notation
  businessHours: '9:00–18:00',
  
  // Formal/informal address
  formalAddress: {
    you: 'Вы',          // Formal "you"
    your: 'Ваш/Ваша',   // Formal "your"
    please: 'пожалуйста' // Polite form
  },
  
  // Error message tone
  errorTone: 'polite_informative', // Russian preference for polite error messages
  
  // Success message style
  successTone: 'professional_positive'
};
```

### **Content Guidelines**:
```typescript
const contentGuidelines = {
  // Technical terminology preferences
  terminology: {
    // Prefer Russian equivalents when available
    'login': 'вход',
    'password': 'пароль',
    'dashboard': 'панель управления',
    'settings': 'настройки',
    
    // Keep English for widely adopted tech terms
    'email': 'email',
    'SMS': 'SMS',
    'Wi-Fi': 'Wi-Fi',
    'API': 'API'
  },
  
  // Message style
  messageStyle: {
    informative: 'Clear, direct communication',
    respectful: 'Formal tone for business context',
    helpful: 'Provide actionable guidance',
    consistent: 'Uniform terminology across interface'
  },
  
  // Call-to-action phrases
  callToAction: {
    save: 'Сохранить',
    cancel: 'Отменить',
    delete: 'Удалить',
    edit: 'Редактировать',
    add: 'Добавить',
    remove: 'Удалить',
    confirm: 'Подтвердить',
    retry: 'Повторить'
  }
};
```

---

## 🔧 **IMPLEMENTATION BEST PRACTICES**

### **Translation Management**:
```typescript
// Recommended translation hook implementation
const useTranslation = () => {
  const [language, setLanguage] = useState<'ru' | 'en'>(() => {
    return localStorage.getItem('language') as 'ru' | 'en' || 'ru';
  });
  
  const t = (key: string, params?: Record<string, any>) => {
    const translation = getNestedProperty(translations[language], key);
    
    if (params) {
      return interpolateParams(translation, params);
    }
    
    return translation || key;
  };
  
  const changeLanguage = (newLanguage: 'ru' | 'en') => {
    setLanguage(newLanguage);
    localStorage.setItem('language', newLanguage);
    document.documentElement.lang = newLanguage;
  };
  
  return { t, language, changeLanguage };
};

// Usage in components
const MyComponent = () => {
  const { t, language, changeLanguage } = useTranslation();
  
  return (
    <div>
      <h1>{t('dashboard.title')}</h1>
      <button onClick={() => changeLanguage(language === 'ru' ? 'en' : 'ru')}>
        {language === 'ru' ? 'English' : 'Русский'}
      </button>
    </div>
  );
};
```

### **Performance Optimizations**:
```typescript
const localizationOptimizations = {
  // Lazy loading for large translation files
  lazyLoading: {
    loadTranslations: async (language: string) => {
      const module = await import(`./translations/${language}.json`);
      return module.default;
    }
  },
  
  // Caching strategy
  caching: {
    storageKey: 'wfm_translations',
    cacheVersion: '1.0.0',
    maxAge: 24 * 60 * 60 * 1000 // 24 hours
  },
  
  // Bundle optimization
  bundleOptimization: {
    splitByRoute: true,
    compressJson: true,
    treeShaking: true
  }
};
```

---

## ✅ **QUALITY ASSURANCE CHECKLIST**

### **Translation Quality Checklist**:
```typescript
interface TranslationQualityChecklist {
  bddCompliance: {
    exactTerms: "✅ All BDD-specified terms match exactly";
    employeeNames: "✅ Russian names match BDD specification";
    metricLabels: "✅ Dashboard metrics use exact BDD Russian labels";
    requestTypes: "✅ больничный, отгул, внеочередной отпуск per BDD";
  };
  
  linguisticQuality: {
    grammar: "✅ Proper Russian grammar and syntax";
    terminology: "✅ Consistent technical term usage";
    formality: "✅ Appropriate business formality level";
    pluralization: "✅ Correct Russian plural forms";
  };
  
  technicalImplementation: {
    encoding: "✅ UTF-8 encoding for Cyrillic characters";
    fontSupport: "✅ Cyrillic font rendering";
    validation: "✅ Cyrillic input validation patterns";
    formatting: "✅ Russian date/number format";
  };
  
  userExperience: {
    languageSwitching: "✅ Real-time language switching";
    defaultLanguage: "✅ Russian default per BDD requirement";
    persistence: "✅ Language preference persistence";
    accessibility: "✅ Screen reader support for Russian";
  };
  
  culturalAdaptation: {
    conventions: "✅ Russian UI conventions followed";
    businessContext: "✅ Appropriate business terminology";
    errorMessages: "✅ Polite, helpful error messaging";
    dateTime: "✅ Russian date/time formats";
  };
}
```

### **Testing Requirements**:
```typescript
const localizationTesting = {
  // Visual testing
  visualRegression: [
    "Screenshot comparison for Russian vs English layouts",
    "Text overflow testing with longer Russian text",
    "Font rendering verification for Cyrillic characters"
  ],
  
  // Functional testing
  functionalTests: [
    "Language switching without page reload",
    "Form validation with Cyrillic input",
    "Date picker with Russian locale",
    "Number formatting verification"
  ],
  
  // Content validation
  contentValidation: [
    "BDD term compliance verification",
    "Translation completeness check",
    "Terminology consistency audit",
    "Native speaker review"
  ],
  
  // Accessibility testing
  accessibilityTests: [
    "Screen reader compatibility with Russian text",
    "Keyboard navigation with Cyrillic layout",
    "Color contrast for Russian text",
    "Focus indicators visibility"
  ]
};
```

---

## 🚀 **DEPLOYMENT CONSIDERATIONS**

### **Production Deployment Checklist**:
```typescript
interface ProductionDeploymentChecklist {
  characterEncoding: "✅ UTF-8 encoding configured on server";
  fontDelivery: "✅ Cyrillic fonts loaded efficiently";
  caching: "✅ Translation files cached appropriately";
  fallbacks: "✅ English fallback for missing translations";
  performance: "✅ Lazy loading implemented for translations";
  seo: "✅ Language meta tags configured correctly";
  analytics: "✅ Language usage tracking implemented";
}
```

---

**This comprehensive Russian localization guide ensures that all UI components meet BDD specification requirements while providing excellent user experience for Russian-speaking users, with proper cultural adaptation and technical implementation standards.**