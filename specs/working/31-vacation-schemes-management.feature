 @vacation_schemes @hr_management @vacation_planning @critical
 Feature: Vacation Schemes Management
   As an HR administrator
   I want to manage vacation schemes for employees
   So that vacation entitlements and planning can be properly controlled
 
   Background:
     Given I am authenticated as HR administrator
     And the vacation schemes management system is available
 
   @vacation_duration @scheme_configuration
   Scenario: Vacation duration and number configuration
     Given I need to create a vacation scheme
     When I configure vacation parameters
     Then the system should support scheme types:
       | Scheme Type | Description | Vacation Days | Periods |
       | Standard | Regular employees | 28 days | 2 periods |
       | Senior | Senior employees | 35 days | 3 periods |
       | Management | Management level | 42 days | 4 periods |
       | Probation | New employees | 14 days | 1 period |
     And vacation period configuration:
       | Period Parameter | Type | Range | Purpose |
       | Min duration | Integer | 7-21 days | Minimum vacation length |
       | Max duration | Integer | 14-28 days | Maximum vacation length |
       | Min gap | Integer | 30-90 days | Time between vacations |
       | Carry over | Boolean | Yes/No | Allow unused days |
       | Expiry period | Integer | 6-18 months | Unused days expiry |
   @multi_language @localization @interface
   Scenario: Multi-language interface support
     Given the system supports multiple languages
     When a user selects their preferred language
     Then the interface should be available in:
       | Language | Code | Coverage | Default |
       | Russian | ru | 100% | Yes |
       | English | en | 100% | No |
     And language switching should affect:
       | Interface Element | Behavior | Validation |
       | Menu items | Translate immediately | All menus |
       | Form labels | Translate all labels | All forms |
       | Error messages | Show localized errors | All errors |
       | Help text | Show localized help | All help |
       | Date formats | Use locale format | DD.MM.YYYY (RU) |
       | Number formats | Use locale format | 1 234,56 (RU) |
     And preserve user preferences:
       | Preference | Storage | Persistence |
       | Language choice | User profile | Permanent |
       | Regional settings | Browser/profile | Per session |
       | Date/time format | User preference | Configurable |

   @browser_compatibility @multi_browser
   Scenario: Multi-browser web-based access compatibility
     Given the system supports multiple browsers
     When users access the system from different browsers
     Then the system should work correctly with:
       | Browser | Version | Compatibility | Features |
       | Mozilla Firefox | 90+ | Full | All features |
       | Microsoft Edge | 88+ | Full | All features |
       | Google Chrome | 90+ | Full | All features |
       | Opera | 76+ | Full | All features |
     And browser-specific testing should verify:
       | Test Category | Firefox | Edge | Chrome | Opera |
       | Authentication | Pass | Pass | Pass | Pass |
       | Form submission | Pass | Pass | Pass | Pass |
       | File upload | Pass | Pass | Pass | Pass |
       | Date pickers | Pass | Pass | Pass | Pass |
       | Responsive design | Pass | Pass | Pass | Pass |

   @event_regularity @recurring_events @event_scheduling
   Scenario: Event regularity configuration
     Given I am creating a recurring event
     When I configure event regularity
     Then the system should support frequency options:
       | Frequency | Description | Configuration |
       | Daily | Every day | Days of week selection |
       | Weekly | Every week | Week interval, weekday |
       | Monthly | Every month | Month interval, day of month |
       | Yearly | Every year | Year interval, month and day |
     And frequency-specific settings:
       | Frequency | Additional Settings | Example |
       | Daily | Skip weekends, holidays | Monday-Friday only |
       | Weekly | Week interval (1-4) | Every 2 weeks |
       | Monthly | Day of month (1-31) | 15th of each month |
       | Yearly | Month (1-12), day (1-31) | January 1st |
     And recurrence limits:
       | Limit Type | Options | Purpose |
       | End date | Specific date | Fixed end |
       | Occurrence count | Number of times | Limited repetition |
       | No end | Infinite | Ongoing events |

   @weekday_selection @event_days
   Scenario: Weekday selection for events
     Given I am configuring a recurring event
     When I select specific weekdays
     Then the system should allow selection:
       | Weekday | Code | Business Day |
       | Monday | MON | Yes |
       | Tuesday | TUE | Yes |
       | Wednesday | WED | Yes |
       | Thursday | THU | Yes |
       | Friday | FRI | Yes |
       | Saturday | SAT | No |
       | Sunday | SUN | No |
     And validate selections:
       | Validation | Rule | Error Message |
       | At least one day | Must select ≥1 day | "Select at least one day" |
       | Valid combination | Logical selection | "Invalid day combination" |
       | Business hours | Match business days | "Non-business day selected" |

   @event_type_selection @event_categories
   Scenario: Event type selection
     Given I am creating a new event
     When I select the event type
     Then the system should provide type options:
       | Event Type | Description | Default Duration | Participants |
       | Training | Training session | 120 minutes | Group |
       | Meeting | Team meeting | 60 minutes | Group |
       | Break | Rest period | 15 minutes | Individual |
       | Lunch | Lunch break | 60 minutes | Individual |
       | Project | Project work | 480 minutes | Group |
       | Call Center | Intraday activity | Variable | Group |
     And type-specific configuration:
       | Type | Required Fields | Optional Fields |
       | Training | Duration, Participants | Room, Materials |
       | Meeting | Duration, Participants | Agenda, Location |
       | Break | Duration | None |
       | Lunch | Duration | None |
       | Project | Duration, Participants | Priority, Resources |
       | Call Center | Duration, Service | Skills, Queue |

