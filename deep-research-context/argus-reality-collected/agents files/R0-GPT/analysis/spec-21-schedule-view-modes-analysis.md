# SPEC-21: Schedule View Modes - Reality Check

## BDD Spec Says (Based on Documentation):
According to operator-cabinet-guide-en.md lines 69-75:
- Monthly view (default)
- Weekly view 
- 4-day view
- Daily view
- Shift details with breaks
- Color coding for different shift types
- Preferences mode for schedule preferences

## Argus Reality:
Unable to access Argus, but documentation indicates:
- Calendar grid with multiple view modes
- Each shift shows time, breaks, status
- Color-coded shifts (green=confirmed, etc.)
- Preferences mode for shift bidding
- Intraday timetables (activities within shifts)

## Our Implementation Has:
✅ Schedule view at `/schedule`
✅ Weekly view implemented
✅ Date navigation (previous/next week)
✅ Shift times displayed (09:00-17:00)
✅ Department and role shown
✅ Location displayed (Call Center Floor 2)
✅ Weekly summary (5 days, 40 hours)
✅ Real API integration (loads 5 shifts)
✅ Request Shift Swap button

## Gaps Found:
❌ No Monthly view (most important according to docs)
❌ No 4-day view
❌ No Daily view
❌ View mode selector exists but not functional
❌ No break times displayed within shifts
❌ No color coding for shift status
❌ No preferences mode
❌ No intraday timetables
❌ Shows "Week View" but can't change it

## Parity: 40%

## Recommended Tags:
```gherkin
@schedule_view @baseline @demo-critical @needs-enhancement
Feature: Schedule View Modes
  # REALITY: Only weekly view implemented
  # TODO: Add monthly view (primary), 4-day, daily views
  # TODO: Make view selector functional
  # TODO: Add break display within shifts
  # TODO: Add color coding for shift status
  # TODO: Add preferences mode for shift bidding
```

## Implementation Priority:
1. **Demo Critical** (2 hours): Add monthly calendar grid view
2. **High Priority** (1 hour): Make view mode selector functional
3. **Medium Priority** (1 hour): Add break times to shift display
4. **Nice to Have** (30 min): Color coding for shift status
5. **Future** (2 hours): Preferences mode for shift bidding