# Schedule Management - Reality Check Analysis

## What Argus ACTUALLY Has vs What We Built

### Argus Personal Cabinet - Calendar View (Reality):
```
Calendar Display:
- Monthly grid view (default)
- Each cell shows:
  - Shift time (09:00-18:00)
  - Break indicators
  - Status colors
- View toggles: Month/Week/4-day/Day
- Color legend for shift types
- Preferences mode button
```

### Our Implementation:
```
Schedule Display:
✅ Weekly view with days
✅ Shift times displayed
✅ Total hours calculation
❌ No monthly view
❌ No calendar grid
❌ No break display
❌ No color coding
❌ No preferences mode
```

## Detailed Gap Analysis

### 1. View Modes (High Priority)
**Argus Has:**
- Monthly calendar grid (30+ days visible)
- Weekly detailed view
- 4-day compressed view
- Daily hourly breakdown

**We Have:**
- Only weekly list view
- No view switching

**Reality Check:** Most employees use MONTHLY view primarily

### 2. Shift Details Display
**Argus Shows:**
```
┌─────────────────┐
│ July 25         │
│ ┌─────────────┐ │
│ │ 09:00-18:00 │ │ <- Green background
│ │ Break 13:00 │ │ <- Different color
│ │ Office      │ │
│ └─────────────┘ │
└─────────────────┘
```

**We Show:**
```
Thu 24
🕐 09:00 - 17:00
Office
scheduled 8h
```

**Gap:** No visual hierarchy, no breaks shown

### 3. Timetables vs Schedules (Critical Misunderstanding)

**BDD Spec Says:** "Timetables with activities"
**Reality:** Argus uses "timetables" to mean intraday activity planning:
```
09:00-10:00: Phone support
10:00-11:00: Email queue
11:00-13:00: Phone support
13:00-14:00: Lunch
14:00-16:00: Training
16:00-18:00: Phone support
```

**We Have:** Just shift start/end times
**Gap:** Missing entire intraday planning feature

### 4. Request Creation from Calendar

**Argus Flow:**
1. Click dates on calendar
2. Right-click → "Create request"
3. Dates auto-populate
4. Manager auto-selected

**Our Flow:**
1. No calendar interaction
2. Separate requests page
3. Manual date entry
4. No context awareness

## Updated BDD Spec Based on Reality:

```gherkin
Feature: Personal Schedule Management - Real Implementation

Background:
  Given employee uses personal cabinet at "lkcc1010wfmcc.argustelecom.ru"
  And default view is monthly calendar

Scenario: View Personal Schedule - Monthly Calendar
  When I access "Календарь" section
  Then I see monthly calendar grid
  And each day cell contains:
    | Element | Display | Interaction |
    | Shift block | Colored rectangle | Click for details |
    | Time range | 09:00-18:00 | Hover shows full info |
    | Break indicator | Different color stripe | Shows break times |
    | Status | Border color | Green=confirmed, Yellow=pending |
  
  When I hover over a shift
  Then tooltip shows:
    - Full shift: 09:00-18:00
    - Breaks: 13:00-14:00
    - Department: Customer Service
    - Timetable: [if exists]
    - Overtime: [if applicable]

Scenario: Timetable Details (Intraday Planning)
  Given I have a shift with timetable
  When I click on the shift
  Then modal shows intraday activities:
    | Time | Activity | Duration |
    | 09:00-10:00 | Inbound calls | 1h |
    | 10:00-10:15 | Break | 15m |
    | 10:15-13:00 | Email queue | 2h 45m |
    | 13:00-14:00 | Lunch | 1h |
    | 14:00-16:00 | Training: New Product | 2h |
    | 16:00-17:45 | Inbound calls | 1h 45m |
    | 17:45-18:00 | Wrap-up | 15m |

Scenario: View Switching
  When I click view selector
  Then I can choose:
    | View | Shows | Primary Use |
    | Month | Full month grid | Overview planning |
    | Week | 7 days detailed | Current week focus |
    | 4-day | Compressed week | Shift workers |
    | Day | Hourly timeline | Detailed planning |
  
  When I select "Week" view
  Then display changes to 7-column layout
  And each column shows full day schedule
  And time slots are visible (hourly grid)

Scenario: Preferences Mode (Shift Bidding)
  When I click "Режим предпочтений"
  Then calendar enters preference mode
  And I can mark shifts as:
    | Preference | Color | Meaning |
    | Preferred | Green | Want this shift |
    | Neutral | Gray | No preference |
    | Avoid | Red | Prefer not to work |
  And submit preferences for next scheduling period
```

## Implementation Priorities:

### MUST HAVE (Demo Critical):
1. **Monthly Calendar View**
   - Use a React calendar component
   - Display shifts as colored blocks
   - Show at least month view

2. **Click on Date → Request**
   - Calendar date selection
   - Context menu or button
   - Auto-populate request form

### SHOULD HAVE:
1. **View Toggle**
   - At least Month/Week
   - Maintain selection in state

2. **Visual Shift Display**
   - Color coding (green/yellow/red)
   - Time display on blocks
   - Hover tooltips

### NICE TO HAVE:
1. **Timetable Display**
   - Modal with activities
   - Can be mocked data

2. **Preferences Mode**
   - Different UI state
   - Can be visual only

## Key Realization:
The term "timetable" in Argus means "what you do during your shift" not "list of shifts". This is why BDD specs mention "intraday activity planning" - it's about planning WITHIN a shift, not the shifts themselves.

## Recommended Component Structure:
```typescript
// ScheduleCalendar.tsx
- Monthly grid view (default)
- Shift blocks with colors
- Date selection for requests

// ShiftDetailsModal.tsx  
- Shows timetable/activities
- Break times
- Department info

// ViewToggle.tsx
- Month/Week/Day selector
- Maintains state

// PreferencesMode.tsx
- Overlay for marking preferences
- Can be stub for demo
```