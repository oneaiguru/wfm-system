# UI COMPONENT API CONTRACTS

## 🎯 **INTEGRATION OVERVIEW**
This document defines the API contracts for all 5 BDD-compliant UI components, providing specifications for INTEGRATION-OPUS to implement the required endpoints for full system integration.

---

## 📋 **SUMMARY OF REQUIRED ENDPOINTS**

### **HIGH PRIORITY ENDPOINTS (Required for Core Functionality)**:
```typescript
// Authentication (Login Component)
POST /api/v1/auth/login                    // ✅ WORKING
POST /api/v1/auth/biometric/setup          // 🟡 NEEDED
POST /api/v1/auth/biometric/verify         // 🟡 NEEDED

// Dashboard (Dashboard Component)  
GET  /api/v1/metrics/dashboard             // ✅ CREATED

// Employee Management (Employee Component)
GET  /api/v1/employees                     // ✅ WORKING (with transformation)
POST /api/v1/employees                     // 🟡 NEEDED

// Schedule Management (Schedule Component)
GET  /api/v1/schedules/current             // 🟡 NEEDED
POST /api/v1/schedules/save                // 🟡 NEEDED
GET  /api/v1/work-rules                    // 🟡 NEEDED

// Mobile Sync (Mobile Component)
GET  /api/v1/mobile/schedule/download      // 🟡 NEEDED
POST /api/v1/mobile/requests/sync          // 🟡 NEEDED
```

### **MEDIUM PRIORITY ENDPOINTS (Enhanced Features)**:
```typescript
// Vacation Management
GET  /api/v1/vacation-schemes              // 🟡 NEEDED
POST /api/v1/vacation/assign               // 🟡 NEEDED

// Notifications
POST /api/v1/notifications/register        // 🟡 NEEDED
PUT  /api/v1/notifications/preferences     // 🟡 NEEDED

// Request Management
POST /api/v1/requests/vacation             // 🟡 NEEDED
GET  /api/v1/requests/employee/{id}        // 🟡 NEEDED
```

---

## 🔐 **AUTHENTICATION API CONTRACTS**

### **Standard Login (✅ WORKING)**
```typescript
interface LoginContract {
  endpoint: "POST /api/v1/auth/login";
  
  request: {
    username: string;    // "admin"
    password: string;    // "AdminPass123!"
  };
  
  response: {
    status: "success" | "error";
    access_token?: string;
    user?: {
      id: string;
      username: string;
      role: string;
      name?: string;
    };
    message?: string;
  };
  
  // Current working credentials: admin/AdminPass123!
  testCredentials: {
    username: "admin";
    password: "AdminPass123!";
  };
}
```

### **Biometric Authentication (🟡 NEEDED)**
```typescript
interface BiometricAuthContract {
  setupEndpoint: "POST /api/v1/auth/biometric/setup";
  verifyEndpoint: "POST /api/v1/auth/biometric/verify";
  
  setupRequest: {
    employeeId: string;
    credentialId: string;      // WebAuthn credential ID (base64)
    publicKey: string;         // Public key from WebAuthn (base64)
    deviceInfo: {
      platform: string;       // "web", "ios", "android"
      userAgent: string;
      deviceName?: string;
    };
  };
  
  verifyRequest: {
    employeeId: string;
    assertion: string;         // WebAuthn assertion (base64)
    credentialId: string;
  };
  
  response: {
    status: "success" | "error";
    access_token?: string;
    user?: UserProfile;
    message?: string;
  };
  
  // Implementation: Store credential in database, verify using WebAuthn
  securityRequirements: [
    "FIDO2/WebAuthn standard compliance",
    "Secure credential storage with encryption",
    "Replay attack protection",
    "User verification requirement"
  ];
}
```

---

## 📊 **DASHBOARD API CONTRACTS**

### **Dashboard Metrics (✅ CREATED)**
```typescript
interface DashboardMetricsContract {
  endpoint: "GET /api/v1/metrics/dashboard";
  
  response: {
    dashboard_title: "Мониторинг операций в реальном времени";
    update_frequency: "30_seconds";
    
    // Six key metrics per BDD specification
    operators_online_percent: {
      value: number;                    // 85.3
      label: "Операторы онлайн %";
      color: "green" | "yellow" | "red"; // >80% green, 70-80% yellow, <70% red
      trend: "up" | "down" | "stable";
      calculation: "(Фактически онлайн / Запланировано) × 100";
      threshold: "Зелёный >80%, Жёлтый 70-80%, Красный <70%";
    };
    
    load_deviation: {
      value: number;                    // -8.2
      label: "Отклонение нагрузки";
      color: "green" | "yellow" | "red"; // ±10% green, ±20% yellow, >20% red
      calculation: "(Фактическая нагрузка - Прогноз) / Прогноз";
      threshold: "±10% Зелёный, ±20% Жёлтый, >20% Красный";
    };
    
    operator_requirement: {
      value: number;                    // 24
      label: "Требуется операторов";
      color: "green" | "yellow" | "red";
      calculation: "Erlang C для текущей нагрузки";
    };
    
    sla_performance: {
      value: number;                    // 79.8
      label: "Производительность SLA";
      color: "green" | "yellow" | "red"; // Target ±5% variations
      calculation: "Формат 80/20 (80% звонков за 20 секунд)";
      threshold: "Цель ±5% отклонения";
    };
    
    acd_rate: {
      value: number;                    // 94.1
      label: "Коэффициент ACD";
      color: "green" | "yellow" | "red";
      calculation: "(Answered/Offered) × 100";
    };
    
    aht_trend: {
      value: number;                    // 285
      label: "Тренд AHT";
      color: "green" | "yellow" | "red";
      calculation: "Взвешенное среднее время обработки";
      unit: "секунд";
    };
    
    bdd_compliance: {
      scenario: "View Real-time Operational Control Dashboards";
      feature_file: "15-real-time-monitoring-operational-control.feature";
      status: "FULLY_COMPLIANT";
    };
  };
  
  // Update frequency: Every 30 seconds per BDD requirement
  caching: {
    maxAge: 30; // seconds
    staleWhileRevalidate: 10; // seconds
  };
  
  // Traffic light color calculation functions required
  colorLogic: {
    operators_online: "green: >80%, yellow: 70-80%, red: <70%";
    load_deviation: "green: ±10%, yellow: ±20%, red: >20%";
    sla_performance: "Target with ±5% variation tolerance";
  };
}
```

---

## 👥 **EMPLOYEE MANAGEMENT API CONTRACTS**

### **Employee List (✅ WORKING with transformation)**
```typescript
interface EmployeeListContract {
  endpoint: "GET /api/v1/employees";
  
  currentResponse: {
    employees: Array<{
      id: string;
      name: string;           // "Full Name" - needs parsing
      employee_id: string;    // Personnel number
      department: string;
      position?: string;
    }>;
    total: number;
  };
  
  // UI transforms to BDD format:
  transformedFormat: {
    id: string;
    lastName: string;         // Parsed from name - Cyrillic validation
    firstName: string;        // Parsed from name - Cyrillic validation  
    patronymic?: string;      // Optional - Cyrillic validation
    personnelNumber: string;  // From employee_id
    department: string;       // Must match hierarchy
    position: string;
    hireDate: string;        // ISO date format
    timeZone: string;        // Default "Europe/Moscow"
  };
  
  // Search and filtering supported
  queryParameters: {
    search?: string;         // Search in name, personnel number
    department?: string;     // Filter by department
    position?: string;       // Filter by position
    limit?: number;          // Pagination
    offset?: number;         // Pagination
  };
}
```

### **Employee Creation (🟡 NEEDED)**
```typescript
interface EmployeeCreationContract {
  endpoint: "POST /api/v1/employees";
  
  request: {
    lastName: string;         // Required, Cyrillic only: /^[а-яё\s\-]+$/i
    firstName: string;        // Required, Cyrillic only: /^[а-яё\s\-]+$/i
    patronymic?: string;      // Optional, Cyrillic only if provided
    personnelNumber: string;  // Required, unique across all employees
    department: string;       // Must exist in department hierarchy
    position: string;         // Must exist in positions list
    hireDate: string;         // Required, ISO date, past or present
    timeZone: string;         // Required, default "Europe/Moscow"
    
    // Optional fields for future expansion
    email?: string;
    phone?: string;
    skills?: string[];
  };
  
  response: {
    status: "success" | "error";
    employee?: {
      id: string;
      lastName: string;
      firstName: string;
      patronymic?: string;
      personnelNumber: string;
      department: string;
      position: string;
      hireDate: string;
      timeZone: string;
      name: string;           // Computed: "lastName firstName patronymic"
      employee_id: string;    // Same as personnelNumber
    };
    message?: string;
  };
  
  validation: {
    cyrillicPattern: "/^[а-яё\s\-]+$/i";
    requiredFields: ["lastName", "firstName", "personnelNumber", "department", "position", "hireDate"];
    uniqueFields: ["personnelNumber"];
    departmentHierarchy: [
      "Колл-центр",              // Level 1
      "Техническая поддержка",   // Level 2 (parent: Колл-центр)
      "Отдел продаж",           // Level 2 (parent: Колл-центр)
      "Поддержка 1-го уровня",   // Level 3 (parent: Техническая поддержка)
      "Поддержка 2-го уровня"    // Level 3 (parent: Техническая поддержка)
    ];
    positions: ["Оператор", "Супервизор", "Менеджер", "Специалист", "Руководитель группы"];
  };
}
```

---

## 📅 **SCHEDULE MANAGEMENT API CONTRACTS**

### **Schedule Data (🟡 NEEDED)**
```typescript
interface ScheduleContract {
  getCurrentEndpoint: "GET /api/v1/schedules/current";
  saveEndpoint: "POST /api/v1/schedules/save";
  
  getCurrentResponse: {
    scheduleName: string;
    year: number;
    month: number;
    employees: Array<{
      id: string;
      name: string;              // Russian names: "Иванов И.И.", "Петров П.П.", "Сидорова А.А."
      position: string;
      workRuleId: string;
      performanceStandard: {
        type: "monthly" | "annual" | "weekly";
        value: number;           // 168 hours, 2080 hours, 40 hours per BDD
        period: string;
      };
    }>;
    scheduleGrid: Array<Array<{
      employeeId: string;
      date: string;              // ISO date format
      shiftId?: string;
      vacationId?: string;
      type: "work" | "vacation" | "rest" | "holiday" | "sick";
      startTime?: string;        // "09:00"
      endTime?: string;          // "18:00"
      overtime?: boolean;
      violations?: string[];     // Labor compliance violations
    }>>;
    vacationAssignments: Array<{
      id: string;
      employeeId: string;
      type: "desired_period" | "desired_calendar" | "extraordinary";
      startDate: string;         // ISO format
      endDate: string;           // ISO format
      priority: "normal" | "priority" | "fixed";
      status: "planned" | "approved" | "conflict";
    }>;
  };
  
  saveRequest: {
    scheduleName: string;
    scheduleGrid: ScheduleCell[][];
    vacationAssignments: VacationAssignment[];
    performanceValidation: boolean;  // Check against employee standards
    complianceCheck: boolean;       // Validate labor law compliance
  };
  
  saveResponse: {
    status: "success" | "error";
    violations?: string[];         // Any compliance violations found
    complianceScore?: number;      // Percentage compliance (0-100)
    affectedEmployees?: string[];  // Employees with changes
    message?: string;
  };
}
```

### **Work Rules (🟡 NEEDED)**
```typescript
interface WorkRulesContract {
  endpoint: "GET /api/v1/work-rules";
  
  response: {
    workRules: Array<{
      id: string;
      name: string;              // "5/2 Стандартная неделя", "Гибкий график"
      mode: "with_rotation" | "without_rotation";
      timezone: string;          // "Europe/Moscow"
      shifts: Array<{
        id: string;
        name: string;            // "Work Day 1", "Work Day 2"
        startTime: string;       // "09:00" or "08:00-10:00" for flexible
        duration: number;        // 8 hours
        type: "standard" | "flexible" | "split";
        breaks?: Array<{
          type: "lunch" | "short" | "technical";
          duration: number;      // 60 minutes, 15 minutes, 10 minutes
          timing: string;        // "13:00-14:00", "11:00", "As needed"
          paid: boolean;
        }>;
      }>;
      constraints: {
        minHoursBetweenShifts: number;    // 11 per BDD line 43
        maxConsecutiveHours: number;      // 40 per BDD line 44
        maxConsecutiveDays: number;       // 5 per BDD line 45
      };
      rotationPattern?: string;   // "WWWWWRR" per BDD line 40
    }>;
  };
  
  // Predefined work rules per BDD specification
  requiredWorkRules: [
    {
      name: "5/2 Стандартная неделя";
      pattern: "WWWWWRR";
      shifts: ["09:00-17:00", "14:00-22:00"];
    },
    {
      name: "Гибкий график";
      startRange: "08:00-10:00";
      duration: "07:00-09:00";
      coreHours: "10:00-15:00";
    },
    {
      name: "Раздельная смена";
      parts: ["08:00-12:00", "16:00-20:00"];
      unpaidBreak: "12:00-16:00";
    }
  ];
}
```

---

## 📱 **MOBILE API CONTRACTS**

### **Mobile Schedule Download (🟡 NEEDED)**
```typescript
interface MobileScheduleContract {
  downloadEndpoint: "GET /api/v1/mobile/schedule/download";
  syncEndpoint: "POST /api/v1/mobile/requests/sync";
  
  downloadRequest: {
    employeeId: string;
    dateRange: {
      start: string;           // ISO date
      end: string;             // ISO date
    };
    includeNotifications: boolean;
    cacheSize: number;         // MB limit for mobile storage
  };
  
  downloadResponse: {
    schedule: Array<{
      id: string;
      date: string;
      startTime: string;
      endTime: string;
      duration: number;
      breakSchedule: string[];     // ["11:00-11:15", "15:00-15:15"]
      lunchPeriod: string;         // "13:00-14:00"
      channelType: string;         // "Technical Support", "Sales Support"
      specialNotes?: string;       // "Training session at 16:00"
    }>;
    requests: Array<{
      id: string;
      type: "sick_leave" | "day_off" | "vacation";
      dateRange: { start: string; end: string; };
      reason?: string;
      status: "pending" | "approved" | "rejected";
      submissionDate: string;
      duration: number;
    }>;
    notifications: Array<{
      id: string;
      type: "break_reminder" | "lunch_reminder" | "schedule_change" | "request_update";
      title: string;               // In Russian
      message: string;             // In Russian
      timestamp: string;
      isRead: boolean;
      deepLink?: string;
    }>;
    cacheExpiry: string;           // ISO timestamp
  };
  
  syncRequest: {
    drafts: Array<{
      id: string;                  // Temporary local ID
      type: "sick_leave" | "day_off" | "vacation";
      dateRange: { start: string; end: string; };
      reason?: string;
      createdOffline: string;      // ISO timestamp
    }>;
    readNotifications: string[];   // Notification IDs marked as read
    lastSyncTimestamp: string;     // For incremental sync
  };
  
  syncResponse: {
    uploadedDrafts: Array<{
      localId: string;             // Original draft ID
      serverId: string;            // New server-assigned ID
      status: "success" | "error";
      message?: string;
    }>;
    newNotifications: Notification[];
    scheduleUpdates: ScheduleUpdate[];
    nextSyncRecommended: string;   // ISO timestamp
  };
}
```

### **Push Notifications (🟡 NEEDED)**
```typescript
interface PushNotificationContract {
  registerEndpoint: "POST /api/v1/notifications/register";
  preferencesEndpoint: "PUT /api/v1/notifications/preferences";
  
  registerRequest: {
    deviceToken: string;           // FCM/APNS token
    platform: "web" | "ios" | "android";
    employeeId: string;
    deviceInfo: {
      userAgent: string;
      timezone: string;
      language: "ru" | "en";
    };
  };
  
  preferencesRequest: {
    employeeId: string;
    preferences: {
      breakReminders: boolean;      // 5 minutes before break (BDD line 151)
      lunchReminders: boolean;      // 10 minutes before lunch (BDD line 152)
      scheduleChanges: boolean;     // Any schedule modification (BDD line 153)
      requestUpdates: boolean;      // Status changes on requests (BDD line 154)
      exchangeNotifications: boolean; // Shift trading opportunities (BDD line 155)
      meetingReminders: boolean;    // Training/meetings (BDD line 156)
      quietHours: {
        enabled: boolean;
        start: string;              // "22:00"
        end: string;                // "07:00"
      };
    };
  };
  
  // Notification payload structure
  notificationPayload: {
    title: string;                  // In Russian
    body: string;                   // In Russian
    data: {
      type: "break_reminder" | "lunch_reminder" | "schedule_change" | "request_update" | "exchange_response" | "meeting_reminder";
      deepLink?: string;            // Navigation target in app
      employeeId: string;
      timestamp: string;
    };
    android?: {
      color: "#007bff";             // Blue theme
      icon: "notification_icon";
    };
    apns?: {
      sound: "default";
      badge: number;
    };
  };
}
```

---

## 🎯 **VALIDATION REQUIREMENTS**

### **Data Validation Standards**:
```typescript
interface ValidationStandards {
  cyrillic: {
    pattern: "/^[а-яё\s\-]+$/i";
    fields: ["lastName", "firstName", "patronymic"];
    errorMessage: "Используйте только кириллические символы";
  };
  
  dateFormat: {
    format: "YYYY-MM-DD";          // ISO 8601
    timezone: "Europe/Moscow";
    validation: "Past or present dates only for hire dates";
  };
  
  timeFormat: {
    format: "HH:MM";               // 24-hour format
    range: "00:00-23:59";
    validation: "Must be valid time";
  };
  
  personnelNumber: {
    pattern: "/^[0-9]+$/";         // Numeric only
    unique: true;                  // Must be unique across all employees
    required: true;
  };
  
  performance: {
    monthly: { min: 120, max: 200, unit: "hours" };     // 168 hours standard
    annual: { min: 1800, max: 2400, unit: "hours" };    // 2080 hours standard
    weekly: { min: 20, max: 50, unit: "hours" };        // 40 hours standard
  };
}
```

### **Labor Compliance Rules**:
```typescript
interface LaborComplianceRules {
  restPeriods: {
    minHoursBetweenShifts: 11;     // BDD line 43
    maxConsecutiveHours: 40;       // BDD line 44
    maxConsecutiveDays: 5;         // BDD line 45
  };
  
  overtime: {
    dailyLimit: 4;                 // Hours per day
    weeklyLimit: 20;               // Hours per week
    annualLimit: 120;              // Hours per year
  };
  
  breaks: {
    lunchDuration: 60;             // Minutes
    lunchTiming: "11:00-15:00";    // Allowed window
    shortBreakDuration: 15;        // Minutes
    shortBreakInterval: 120;       // Every 2 hours
    maxBreakOverlap: 20;           // Percent of team
  };
  
  vacation: {
    minBlockDays: 7;               // Minimum vacation block
    maxBlockDays: 21;              // Maximum vacation block
    noticePeriodDays: 14;          // Required notice
    blackoutPeriods: ["2024-12-15/2024-12-31", "2025-06-01/2025-06-15"];
  };
}
```

---

## 🔄 **ERROR HANDLING STANDARDS**

### **HTTP Status Codes**:
```typescript
interface ErrorHandlingStandards {
  success: {
    200: "OK - Request successful";
    201: "Created - Resource created successfully";
  };
  
  clientErrors: {
    400: "Bad Request - Invalid data format or validation failed";
    401: "Unauthorized - Invalid or missing authentication";
    403: "Forbidden - Insufficient permissions";
    404: "Not Found - Resource not found";
    409: "Conflict - Duplicate personnel number or constraint violation";
    422: "Unprocessable Entity - Valid format but business rule violation";
  };
  
  serverErrors: {
    500: "Internal Server Error - Server processing error";
    503: "Service Unavailable - Temporary service unavailable";
  };
  
  // Standard error response format
  errorResponse: {
    status: "error";
    code: number;                  // HTTP status code
    message: string;               // Human-readable message in Russian
    details?: {
      field?: string;              // Field that caused error
      constraint?: string;         // Violated constraint
      suggestion?: string;         // How to fix
    };
    timestamp: string;             // ISO timestamp
  };
}
```

---

## 📈 **PERFORMANCE REQUIREMENTS**

### **Response Time Targets**:
```typescript
interface PerformanceTargets {
  authentication: {
    standard: "< 2 seconds";
    biometric: "< 3 seconds";
  };
  
  dataRetrieval: {
    dashboard: "< 1 second (cached 30s)";
    employeeList: "< 2 seconds (up to 1000 employees)";
    schedule: "< 3 seconds (50 employees × 31 days)";
  };
  
  dataModification: {
    createEmployee: "< 2 seconds";
    saveSchedule: "< 5 seconds";
    vacation: "< 1 second";
  };
  
  mobile: {
    download: "< 10 seconds (30 days data)";
    sync: "< 5 seconds (typical sync)";
    notification: "< 1 second delivery";
  };
}
```

### **Concurrency Requirements**:
```typescript
interface ConcurrencyRequirements {
  authentication: "100 concurrent logins";
  dashboard: "50 concurrent dashboard viewers";
  scheduleEditing: "10 concurrent schedule editors";
  mobile: "200 concurrent mobile users";
  
  // Database connection pooling
  connections: {
    min: 10;
    max: 50;
    idle: 30; // seconds
  };
}
```

---

## 🚀 **IMPLEMENTATION PRIORITIES**

### **Phase 1: Core Functionality (Immediate)**
1. **Employee Creation** - POST /api/v1/employees
2. **Schedule Management** - GET/POST /api/v1/schedules/*
3. **Work Rules** - GET /api/v1/work-rules

### **Phase 2: Enhanced Features (Next Sprint)**
1. **Biometric Authentication** - POST /api/v1/auth/biometric/*
2. **Mobile Sync** - GET/POST /api/v1/mobile/*
3. **Push Notifications** - POST /api/v1/notifications/*

### **Phase 3: Advanced Integration (Future)**
1. **Vacation Schemes** - GET/POST /api/v1/vacation-schemes/*
2. **Request Management** - Enhanced request workflows
3. **Analytics Integration** - Performance metrics APIs

---

**This comprehensive API contract specification provides INTEGRATION-OPUS with all necessary details to implement the backend endpoints required for full UI component functionality, ensuring seamless integration between frontend BDD-compliant components and backend services.**