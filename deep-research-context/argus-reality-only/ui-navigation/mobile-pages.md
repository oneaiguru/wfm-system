# Mobile UI Pages in Argus (from R8 Analysis)

## Personal Area Mobile View
- **URL**: `/ccwfm/views/env/personnel/PersonalAreaIncomingView.xhtml`
- **Evidence**: R8 analyzed HTML/JavaScript from this page
- **Features Found**:
  - Calendar interface (line 327)
  - Excel export button (line 322)
  - Task badge updates (line 72)
  - Notification badges (line 79)
  - Profile editing (line 264)
  - Search autocomplete (line 68)
  - Language switching (lines 127-129)
  - Vacation type selector (line 375)
  - Error reporting menu (line 110)
  - Logout functionality (line 135)
  - Timezone settings (line 255)
  - Calendar pagination (line 380)

## Key Mobile UI Patterns

All mobile interactions use PrimeFaces AJAX:
```javascript
PrimeFaces.ab({
  s: "source_id",      // Component triggering action
  e: "event",          // Event type (click, valueChange, etc)
  p: "process_id",     // Components to process
  u: "update_id",      // Components to update
  ps: true             // Partial submit
});
```

## UI Elements Confirmed
- Russian language interface ("Экспорт в Excel", "Отчёт об ошибке")
- PrimeFaces components (AutoComplete, EditableSection)
- Form-based interactions (not REST)
- Session-based state management