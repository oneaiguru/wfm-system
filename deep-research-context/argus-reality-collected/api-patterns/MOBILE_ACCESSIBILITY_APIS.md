# Mobile Accessibility APIs - Employee Portal

**Agent**: R8-UXMobileEnhancements  
**Portal**: Employee (Vue.js WFMCC1.24.0)  
**Standard**: WCAG 2.1 AA (Target)  
**Current**: 13.7% compliance (from testing)  
**Date**: 2025-07-29

## 🔍 Accessibility Status Detection

### Initial Accessibility Check
```http
GET /gw/api/v1/accessibility/user-preferences
Response: {
  "screenReader": false,
  "highContrast": false,
  "reducedMotion": false,
  "fontSize": "medium",
  "colorBlindMode": null,
  "keyboardOnly": false
}
```

### Update Accessibility Preferences
```http
PUT /gw/api/v1/accessibility/preferences
Request: {
  "screenReader": true,
  "fontSize": "large",
  "reducedMotion": true,
  "announcements": "verbose"
}
Response: {
  "saved": true,
  "appliedTheme": "high-contrast",
  "cssOverrides": [
    "font-size: 1.2em",
    "animation-duration: 0s"
  ]
}
```

## 📱 Screen Reader APIs

### ARIA Live Regions
```javascript
// Dynamic content announcements
POST /gw/api/v1/accessibility/announce
Request: {
  "message": "Запрос на отпуск отправлен",
  "priority": "polite", // or "assertive"
  "clearAfter": 5000
}

// Vue.js implementation
this.$announcer.polite('Запрос на отпуск отправлен');
this.$announcer.assertive('Ошибка: заполните все поля');
```

### Focus Management API
```http
POST /gw/api/v1/accessibility/focus-trap
Request: {
  "component": "vacation-request-modal",
  "action": "activate",
  "returnFocusTo": "button#request-vacation"
}
```

## 🎨 Visual Accessibility

### Color Contrast Validation
```http
POST /gw/api/v1/accessibility/validate-contrast
Request: {
  "foreground": "#46BBB1",
  "background": "#FFFFFF",
  "fontSize": 16,
  "fontWeight": 400
}
Response: {
  "ratio": 2.89,
  "passesAA": false,
  "passesAAA": false,
  "recommendation": {
    "foreground": "#2B7A72",
    "ratio": 4.51,
    "passesAA": true
  }
}
```

### Theme Adjustments
```javascript
// Mobile-specific theme API
GET /gw/api/v1/themes/accessible-mobile
Response: {
  "themes": [
    {
      "id": "high-contrast",
      "name": "Высокая контрастность",
      "css": "/css/themes/high-contrast-mobile.css",
      "preview": "/images/theme-preview-hc.png"
    },
    {
      "id": "dark-mode",
      "name": "Тёмная тема",
      "css": "/css/themes/dark-mobile.css",
      "reducesEyeStrain": true
    }
  ]
}
```

## ⌨️ Keyboard Navigation

### Touch Alternative APIs
```javascript
// Keyboard shortcuts registration
POST /gw/api/v1/accessibility/keyboard-shortcuts
Request: {
  "shortcuts": [
    {
      "key": "Alt+C",
      "action": "open-calendar",
      "description": "Открыть календарь"
    },
    {
      "key": "Alt+R",
      "action": "create-request",
      "description": "Создать запрос"
    }
  ]
}

// Get available shortcuts
GET /gw/api/v1/accessibility/shortcuts/mobile
Response: {
  "navigation": [
    { "key": "Tab", "action": "Next element" },
    { "key": "Shift+Tab", "action": "Previous element" }
  ],
  "actions": [
    { "key": "Enter", "action": "Activate" },
    { "key": "Space", "action": "Select" }
  ]
}
```

### Focus Indicators
```http
# Get focus styles for current theme
GET /gw/api/v1/accessibility/focus-styles
Response: {
  "defaultOutline": "2px solid #46BBB1",
  "highContrastOutline": "3px solid #000000",
  "offset": "2px",
  "animations": false
}
```

## 🔊 Audio Accessibility

### Voice Guidance API
```http
POST /gw/api/v1/accessibility/voice-guidance
Request: {
  "action": "navigate",
  "target": "calendar-week-view",
  "language": "ru"
}
Response: {
  "audioUrl": "/audio/guidance/calendar-navigation-ru.mp3",
  "transcript": "Календарь недели. Используйте стрелки для навигации.",
  "duration": 3500
}
```

### Sound Effects Control
```http
PUT /gw/api/v1/accessibility/sounds
Request: {
  "enabled": true,
  "volume": 0.5,
  "categories": {
    "notifications": true,
    "interactions": false,
    "errors": true
  }
}
```

## 📊 Form Accessibility

### Field Validation Messages
```javascript
// Accessible error reporting
POST /gw/api/v1/forms/validate-accessible
Request: {
  "formId": "vacation-request",
  "fields": {
    "startDate": "2025-07-29",
    "endDate": "2025-07-28"
  }
}
Response: {
  "valid": false,
  "errors": [
    {
      "field": "endDate",
      "message": "Дата окончания должна быть после даты начала",
      "ariaLabel": "Ошибка в поле Дата окончания",
      "severity": "error"
    }
  ],
  "announcement": "Форма содержит 1 ошибку"
}
```

### Input Assistance
```http
GET /gw/api/v1/accessibility/input-help/{fieldType}
Response: {
  "fieldType": "date",
  "instructions": "Введите дату в формате ДД.ММ.ГГГГ",
  "example": "29.07.2025",
  "keyboardTips": [
    "Используйте стрелки для изменения дня",
    "Page Up/Down для изменения месяца"
  ]
}
```

## 🔄 Motion & Animation Control

### Reduced Motion API
```javascript
// Check user preference
if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
  // Disable animations
  fetch('/gw/api/v1/accessibility/motion', {
    method: 'PUT',
    body: JSON.stringify({ reducedMotion: true })
  });
}

// Server response adjusts CSS
Response Headers:
  X-Reduced-Motion: true
  Link: </css/no-animations.css>; rel=stylesheet
```

### Animation Controls
```http
POST /gw/api/v1/accessibility/animation-settings
Request: {
  "enableTransitions": false,
  "enableParallax": false,
  "autoplayVideos": false,
  "animationSpeed": 0
}
```

## 🎯 Mobile-Specific Accessibility

### Touch Target Sizing
```http
GET /gw/api/v1/accessibility/touch-targets
Response: {
  "minimumSize": 44,
  "recommendedSize": 48,
  "unit": "px",
  "spacing": 8,
  "guidelines": "WCAG 2.1 Success Criterion 2.5.5"
}
```

### Gesture Alternatives
```javascript
// Register alternative interactions
POST /gw/api/v1/accessibility/gesture-alternatives
Request: {
  "component": "calendar-week",
  "gestures": [
    {
      "gesture": "swipe-left",
      "alternative": "button#next-week",
      "keyboardShortcut": "Alt+Right"
    },
    {
      "gesture": "pinch-zoom",
      "alternative": "button#zoom-controls",
      "keyboardShortcut": "Ctrl+Plus"
    }
  ]
}
```

## 📱 Assistive Technology Detection

### AT Detection API
```javascript
// Detect assistive technology
navigator.permissions.query({ name: 'accessibility-events' })
  .then(result => {
    if (result.state === 'granted') {
      fetch('/gw/api/v1/accessibility/at-detected', {
        method: 'POST',
        body: JSON.stringify({
          screenReader: true,
          voiceControl: false
        })
      });
    }
  });
```

## 🔍 Accessibility Testing APIs

### Automated Testing Endpoint
```http
POST /gw/api/v1/accessibility/audit
Request: {
  "url": "/calendar",
  "standards": ["WCAG21AA"],
  "viewport": { "width": 375, "height": 667 }
}
Response: {
  "score": 0.137,
  "violations": [
    {
      "rule": "color-contrast",
      "impact": "serious",
      "elements": 23,
      "fix": "Increase contrast ratio to 4.5:1"
    },
    {
      "rule": "label",
      "impact": "critical",
      "elements": 8,
      "fix": "Add labels to form inputs"
    }
  ]
}
```

## 📋 Implementation Priority

### Critical (Week 1)
- [ ] Color contrast fixes
- [ ] Form labels and errors
- [ ] Focus indicators
- [ ] Touch target sizing

### Important (Week 2-3)
- [ ] Screen reader announcements
- [ ] Keyboard navigation
- [ ] Reduced motion support
- [ ] ARIA landmarks

### Enhancement (Month 2)
- [ ] Voice guidance
- [ ] Custom themes
- [ ] Gesture alternatives
- [ ] Full WCAG compliance

## 🔗 Related Documentation
- See VUE_MOBILE_PATTERNS.md for component implementation
- See PWA_OFFLINE_APIS.md for offline accessibility
- See MOBILE_DATA_OPTIMIZATION.md for performance impact