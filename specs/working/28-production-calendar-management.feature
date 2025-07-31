 # REALITY: 2025-07-27 - Comprehensive Russian compliance and ZUP integration system for production calendar
 # Database includes: russian_compliance_requirements (labor law), zup_time_types, zup_actual_work_time
 # Legal framework: Real Russian Labor Code data - "Статья 91" (working time), "Статья 92" (40-hour week)
 # ZUP integration: Upload sessions, sync flags, overtime tracking, vacation balance management
 # Time management: time_type_code, time_type_name_ru for Russian time classification
 # Infrastructure ready for working days, holidays, pre-holidays calendar management
 # R4-INTEGRATION-REALITY: SPEC-111 Production Calendar Integration
 # Status: ⚠️ PARTIALLY VERIFIED - ZUP integration exists
 # Evidence: ZUP time types and actual work time sync found
 # Reality: Integration with 1C ZUP for time management
 # Architecture: ZUP upload sessions and sync flags
 # @partially-verified - 1C ZUP calendar integration
 @production_calendar @calendar_management @critical
 Feature: Production Calendar Management
   As a system administrator
   I want to manage production calendar data
   So that vacation planning and holiday considerations work correctly
 
   Background:
     Given I am authenticated as administrator
     And the production calendar system is available
 
   @xml_import @russian_calendar
   Scenario: Russian Federation calendar XML import
     # R4-INTEGRATION-REALITY: SPEC-027 Production Calendar Testing
     # Status: ✅ INDIRECTLY VERIFIED - "Производственный календарь" in menu
     # Context: Production calendar confirmed in admin portal Справочники section
     # Evidence: Menu navigation shows "Производственный календарь" option
     # Navigation: Справочники → Производственный календарь path available
     # @verified-menu-visible - Production calendar management exists
     Given I have a Russian Federation calendar XML file
     When I import the calendar file
     Then the system should process the XML structure:
       | Field | Type | Content | Purpose |
       | year | Integer | 2025 | Calendar year |
       | work_days | Array | Working days list | Business days |
       | holidays | Array | Holiday dates | Non-working days |
       | pre_holidays | Array | Pre-holiday dates | Shortened days |
     And the calendar should be validated for:
       | Validation Type | Rule | Error Response |
       | Date Format | ISO 8601 | "Invalid date format" |
       | Year Range | 2020-2030 | "Year out of range" |
       | Holiday Names | Russian names | "Invalid holiday name" |
     And the import should handle edge cases:
       | Edge Case | Handling | Result |
       | Duplicate dates | Merge entries | Single entry kept |
       | Missing weekends | Auto-generate | Weekends added |
       | Invalid XML | Validation error | Import rejected |
 
   @calendar_display @year_view
   Scenario: Production calendar year display
     Given the production calendar is imported
     When I view the calendar for year 2025
     Then the system should display:
       | Display Element | Content | Format |
       | Working days | 247 days | Green highlight |
       | Holidays | 12 days | Red highlight |
       | Pre-holidays | 4 days | Yellow highlight |
       | Weekends | 104 days | Gray highlight |
     And I should be able to toggle display options:
       | Toggle Option | Default | Purpose |
       | Show holidays | Enabled | Holiday visibility |
       | Show weekends | Enabled | Weekend visibility |
       | Show pre-holidays | Enabled | Pre-holiday visibility |
 
   @day_type_editing @calendar_editing
   Scenario: Production calendar day type editing
     Given the production calendar is displayed
     When I edit a day type from "working" to "holiday"
     Then the system should update the day type
     And validate the change:
       | Validation | Rule | Response |
       | Impact check | Schedules using date | "X schedules affected" |
       | Confirmation | User approval | "Confirm change?" |
       | Rollback | Undo capability | "Change reverted" |
     And save the changes to the calendar database
 
   @holiday_events @holiday_specification
   Scenario: Holiday event specification
     Given I am editing a holiday in the calendar
     When I specify holiday details
     Then the system should allow entry of:
       | Field | Type | Required | Example |
       | Holiday name | String | Yes | "New Year" |
       | Date | Date | Yes | "2025-01-01" |
       | Type | Enum | Yes | "Federal/Regional" |
       | Description | Text | No | "National holiday" |
     And validate the holiday event:
       | Validation | Rule | Error Message |
       | Unique name | Per year | "Holiday name exists" |
       | Valid date | Calendar year | "Invalid date" |
       | Type selection | Enum values | "Invalid type" |
 
   @vacation_planning @calendar_integration
   Scenario: Production calendar vacation planning integration
     Given the production calendar is configured
     When the system plans vacation schedules
     Then vacation periods should consider:
       | Calendar Factor | Impact | Behavior |
       | Holidays | Extend vacation | Auto-extend periods |
       | Pre-holidays | Shorten workday | Adjust calculation |
       | Weekends | Skip counting | Not counted as vacation |
     And vacation extension should follow rules:
       | Rule | Condition | Action |
       | Holiday overlap | Vacation includes holiday | Extend by 1 day |
       | Weekend bridge | Holiday-weekend gap | Fill gap automatically |
       | Pre-holiday | Vacation starts pre-holiday | Include in vacation |
