Feature: Mobile Applications and Personal Cabinet
  As an employee
  I want to access WFM functions through mobile and personal cabinet interfaces
  So that I can manage my schedule and requests from anywhere

  Background:
    Given the mobile application and personal cabinet are available
    And I have valid employee credentials
    And the system supports responsive design for mobile devices

  @mobile @authentication
  Scenario: Mobile Application Authentication and Setup
    Given I have the WFM mobile application installed
    When I launch the application for the first time
    And I enter my credentials:
      | Field | Value |
      | Username | employee_login |
      | Password | employee_password |
    Then I should authenticate via the mobile API
    And receive a JWT token for session management
    And see the mobile-optimized interface
    And have the option to enable biometric authentication
    And receive a registration confirmation for push notifications

  @personal_cabinet @login_access
  Scenario: Personal Cabinet Login and Navigation
    Given I navigate to the personal cabinet URL
    When I enter my username and password
    Then I should be logged into the personal cabinet
    And see the responsive interface that works on mobile devices
    And have access to all personal functions:
      | Function | Purpose |
      | Calendar view | View my work schedule |
      | Request creation | Submit time-off requests |
      | Shift exchanges | Participate in shift trading |
      | Profile management | View/update personal information |
      | Notifications | Receive system alerts |
      | Preferences | Set work preferences |
      | Acknowledgments | Confirm schedule awareness |

  @calendar @schedule_viewing
  Scenario: View Personal Schedule in Calendar Interface
    Given I am logged into the personal cabinet
    When I access the calendar page
    Then I should see my work schedule with multiple view options:
      | View Mode | Display | Navigation |
      | Monthly | Full month grid | Previous/Next month |
      | Weekly | 7-day detailed view | Week navigation |
      | 4-day | 4-day compact view | Daily navigation |
      | Daily | Single day detail | Day-by-day |
    And calendar should display:
      | Schedule Element | Visualization | Information |
      | Work shifts | Colored blocks | Start/end times |
      | Breaks | Smaller blocks | Break duration |
      | Lunches | Designated blocks | Lunch periods |
      | Events | Special indicators | Training/meetings |
      | Channel types | Color coding | Different work types |

  @calendar @shift_details
  Scenario: View Detailed Shift Information
    Given I am viewing my calendar
    When I click on a specific shift
    Then I should see detailed shift information:
      | Detail | Content |
      | Shift date | Full date |
      | Start time | Shift beginning |
      | End time | Shift conclusion |
      | Duration | Total work hours |
      | Break schedule | All scheduled breaks |
      | Lunch period | Lunch timing |
      | Special notes | Any shift-specific information |
    And in weekly/daily view, I should see:
      | Intraday Detail | Purpose |
      | Channel assignments | What type of work |
      | Break placement | When breaks occur |
      | Activity schedule | Training or meetings |
      | Coverage requirements | Service expectations |

  @preferences @schedule_preferences
  Scenario: Set Work Schedule Preferences
    Given I am in preferences mode on the calendar
    When I create schedule preferences
    Then I should be able to specify:
      | Preference Type | Options | Impact |
      | Priority preference | High priority dates | Preferred scheduling |
      | Regular preference | Normal priority dates | Standard consideration |
      | Day type | Work day or day off | Schedule vs rest |
      | Time parameters | Start time, end time, duration | Shift characteristics |
    And the system should track:
      | Tracking Element | Purpose |
      | Preference counts | Number set for period |
      | Deadline information | Submission cutoff |
      | Period coverage | What timeframe preferences apply to |

  @requests @request_creation
  Scenario: Create Time-off and Leave Requests
    Given I am on the calendar or requests page
    When I click "Create" to make a new request
    Then I should be able to create requests for:
      | Request Type | Russian Term | Purpose |
      | Sick leave | больничный | Medical absence |
      | Day off | отгул | Personal time off |
      | Unscheduled vacation | внеочередной отпуск | Emergency vacation |
    And the request form should include:
      | Form Field | Type | Validation |
      | Request type | Dropdown | Required |
      | Date selection | Calendar picker | Required date range |
      | Reason/Comment | Text area | Optional explanation |
      | Duration | Auto-calculated | Based on dates |
    And after submission, the request should appear in my requests list

  @requests @request_management
  Scenario: Manage Personal Requests
    Given I have submitted various requests
    When I navigate to the requests page
    Then I should see two main sections:
      | Section | Content | Purpose |
      | My requests | Requests I created | Track my submissions |
      | Available requests | Requests from others | Respond to exchanges |
    And for my requests, I should see:
      | Request Information | Details |
      | Request type | What type of request |
      | Date range | When the request applies |
      | Status | Current approval state |
      | Submission date | When I submitted |
      | Actions | Cancel if still pending |

  @exchange @shift_trading
  Scenario: Participate in Shift Exchange System
    Given I want to trade shifts with colleagues
    When I access the shift exchange system
    Then I should be able to:
      | Exchange Action | Method | Result |
      | Offer my shift | Right-click shift → "Shift exchange" | Create exchange offer |
      | Specify trade terms | Select work date | Define what I'll work instead |
      | View available offers | Exchange → Available tab | See colleagues' offers |
      | Accept an offer | Click "Accept" | Respond to exchange |
    And the exchange process should follow:
      | Process Step | Participants | Outcome |
      | Create offer | Original shift holder | Offer becomes available |
      | Accept offer | Interested colleague | Request goes to manager |
      | Manager approval | Supervisor | Approve or reject exchange |
      | Schedule update | System | Both schedules updated |

  @notifications @alert_system
  Scenario: Receive and Manage Notifications
    Given I have notifications enabled
    When system events occur that affect me
    Then I should receive notifications for:
      | Notification Type | Trigger | Delivery Method |
      | Break reminders | 5 minutes before break | Mobile push + in-app |
      | Lunch reminders | 10 minutes before lunch | Mobile push + in-app |
      | Schedule changes | Any schedule modification | Email + in-app |
      | Request updates | Status changes on my requests | Email + in-app |
      | Exchange responses | Someone accepts my offer | Mobile push + in-app |
      | Meeting reminders | Upcoming training/meetings | Email + in-app |
    And notification management should allow:
      | Management Feature | Capability |
      | Read/unread filtering | Show only unread messages |
      | Notification history | See all past notifications |
      | Preference settings | Configure notification types |
      | Quiet hours | Disable notifications during rest |

  @profile @personal_information
  Scenario: View and Manage Personal Profile
    Given I access my profile page
    When I view my personal information
    Then I should see:
      | Profile Information | Content |
      | Full name | My complete name |
      | Department | Organizational unit |
      | Position | Job title |
      | Employee ID | Personnel number |
      | Supervisor contact | Manager's phone |
      | Time zone | My working timezone |
    And I should be able to:
      | Profile Action | Capability |
      | Subscribe to updates | Enable/disable notifications |
      | Update contact info | Modify personal details |
      | Change preferences | Adjust personal settings |
      | View work rules | See assigned work patterns |

  @vacation @vacation_preferences
  Scenario: Set Vacation Preferences and Desired Dates
    Given I am planning my vacation for the coming year
    When I access vacation preferences
    Then I should be able to:
      | Vacation Feature | Capability |
      | View vacation scheme | See my entitled vacation plan |
      | Specify desired dates | Select preferred vacation periods |
      | Set vacation priorities | Indicate most important dates |
      | View restrictions | See blackout periods or limits |
    And the system should:
      | System Function | Purpose |
      | Track vacation balance | Show remaining days |
      | Validate selections | Check against policies |
      | Save preferences | Store for planning process |
      | Show conflicts | Highlight potential issues |

  @acknowledgments @schedule_confirmation
  Scenario: Acknowledge Work Schedule Updates
    Given new work schedules have been published
    When I access the acknowledgments page
    Then I should see:
      | Acknowledgment Section | Content |
      | New acknowledgments | Schedules requiring confirmation |
      | Archive | Previously acknowledged schedules |
    And for new acknowledgments, I should be able to:
      | Action | Result |
      | Review schedule details | See complete schedule information |
      | Acknowledge receipt | Confirm I've seen the schedule |
      | Add comments | Provide feedback if needed |
    And the system should track:
      | Tracking Element | Purpose |
      | Acknowledgment status | Who has confirmed |
      | Acknowledgment timing | When confirmation occurred |
      | Outstanding items | Who hasn't yet acknowledged |

  @mobile @push_notifications
  Scenario: Configure and Receive Push Notifications
    Given I have the mobile application installed
    When I configure push notification settings
    Then I should be able to control:
      | Notification Category | Options |
      | Schedule reminders | Enable/disable shift start alerts |
      | Break reminders | Configure break and lunch alerts |
      | Request updates | Status changes on my requests |
      | Exchange notifications | Shift trading opportunities |
      | Emergency alerts | Urgent schedule changes |
    And notifications should:
      | Notification Feature | Behavior |
      | Deep link to relevant section | Direct navigation to related content |
      | Respect quiet hours | No notifications during off-hours |
      | Batch similar notifications | Group related alerts |
      | Provide quick actions | Allow immediate responses |

  @mobile @offline_capability
  Scenario: Work with Limited or No Internet Connectivity
    Given I may not always have internet access
    When I use the mobile application offline
    Then I should be able to:
      | Offline Function | Capability |
      | View downloaded schedule | See my current schedule |
      | Create draft requests | Prepare requests for later submission |
      | View cached notifications | See recent notifications |
      | Access profile information | View personal details |
    And when connectivity is restored:
      | Sync Function | Behavior |
      | Upload draft requests | Submit prepared requests |
      | Download updates | Sync latest schedule changes |
      | Refresh notifications | Get new alerts |
      | Update schedule data | Ensure current information |

  @customization @interface_personalization
  Scenario: Customize Interface Appearance and Behavior
    Given I want to personalize my experience
    When I access customization settings
    Then I should be able to modify:
      | Customization Option | Choices |
      | Theme colors | Light/dark mode, color schemes |
      | Language preference | Russian/English interface |
      | Calendar view default | Preferred initial view |
      | Notification preferences | Which alerts to receive |
      | Time format | 12-hour or 24-hour display |
    And customizations should:
      | Behavior | Effect |
      | Persist across sessions | Remember my preferences |
      | Sync across devices | Same settings on mobile and web |
      | Apply immediately | No restart required |
      | Reset to defaults | Option to restore original settings |

   @dashboard_customization @user_preferences @low
   Scenario: Dashboard display settings customization
     Given I am logged in as operator
     And I have access to personal dashboard
     When I navigate to dashboard settings
     Then I should see customization options:
       | Setting | Current Value | Options |
       | Default View | Calendar | Calendar, List, Grid |
       | Time Format | 24-hour | 12-hour, 24-hour |
       | Date Format | DD.MM.YYYY | DD.MM.YYYY, MM/DD/YYYY |
       | Language | Russian | Russian, English |
       | Theme | Light | Light, Dark, Auto |
     When I update display preferences:
       | Setting | New Value | Description |
       | Default View | Grid | Grid view preference |
       | Theme | Dark | Dark theme preference |
     And I save dashboard settings
     Then I should see confirmation: "Dashboard settings updated"
     And dashboard should reflect new preferences
     And settings should persist across sessions

  @integration @calendar_export
  Scenario: Export Schedule to Personal Calendar Applications
    Given I want my work schedule in my personal calendar
    When I request schedule export
    Then I should be able to:
      | Export Feature | Format |
      | Download calendar file | .ics format |
      | Email schedule | Send to personal email |
      | Sync with calendar app | Direct integration |
      | Subscribe to updates | Auto-updating calendar feed |
    And exported data should include:
      | Schedule Element | Detail Level |
      | Work shifts | Start/end times with location |
      | Breaks and lunches | Specific timing |
      | Training events | Meeting details |
      | Time-off periods | Vacation and leave dates |

  @accessibility @mobile_accessibility
  Scenario: Ensure Mobile Accessibility for All Users
    Given users may have accessibility needs
    When accessing mobile and personal cabinet functions
    Then the interface should support:
      | Accessibility Feature | Implementation |
      | Large text support | Scalable font sizes |
      | High contrast mode | Enhanced visibility |
      | Voice control | Screen reader compatibility |
      | Simple navigation | Easy touch targets |
      | Clear feedback | Obvious action confirmations |
    And provide assistance:
      | Assistance Type | Availability |
      | Help documentation | Context-sensitive help |
      | Tutorial mode | Guided interface walkthrough |
      | Support contact | Easy access to help desk |
      | Error recovery | Clear error messages and recovery steps |