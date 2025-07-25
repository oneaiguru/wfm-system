Feature: Business Process Management and Workflow Automation
  As a business process manager
  I want to configure and manage automated workflows
  So that business processes follow defined procedures and approval chains

  Background:
    Given the BPMS (Business Process Management System) is configured
    And workflow definitions are loaded into the system
    And users have appropriate roles for process participation

  @bpms @process_definition
  Scenario: Load Business Process Definitions
    Given I need to implement standardized approval workflows
    When I upload a business process definition file (.zip or .rar archive)
    Then the system should parse the process definition containing:
      | Process Component | Content | Purpose |
      | Process stages | Sequential workflow steps | Define approval flow |
      | Participant roles | Who can perform each stage | Role-based authorization |
      | Available actions | What can be done at each stage | Stage-specific permissions |
      | Transition rules | Conditions for moving between stages | Workflow logic |
      | Notification settings | Who gets notified when | Communication automation |
    And the business process should be activated and ready for use

  @bpms @schedule_approval_workflow
  Scenario: Work Schedule Approval Process Workflow
    Given a work schedule variant has been created
    When the schedule approval business process is initiated
    Then the workflow should execute the following stages:
      | Stage | Participants | Available Actions | Next Stage |
      | Supervisor Review | Department heads | Edit/Approve/Reject | Planning Specialist |
      | Planning Review | Planning specialist | Update/Return/Forward | Operators |
      | Operator Confirmation | All affected operators | View/Acknowledge | Final Application |
      | Apply Schedule | Planning specialist | Apply/Send to 1C ZUP via sendSchedule API | Process Complete |
    And each stage should enforce the following rules:
      | Rule Type | Enforcement | Validation |
      | Role authorization | Only authorized users can act | Check user permissions |
      | Sequential order | Stages must complete in order | Prevent skipping stages |
      | Completion requirements | All participants must act | Track acknowledgments |
      | Timeout handling | Escalate overdue tasks | Automatic escalation |

  @bpms @task_management
  Scenario: Handle Approval Tasks in Workflow
    Given I have pending approval tasks assigned to me
    When I access the task management interface
    Then I should see task details:
      | Task Field | Content | Purpose |
      | Object | Schedule Q1 2025 | What needs approval |
      | Type | Schedule variant | Category of work item |
      | Process | Schedule approval | Which workflow |
      | Task | Supervisor confirmation | Current stage |
      | Actions | Approve/Return/Delegate | Available options |
      | Comments | Text input field | Add explanatory notes |
      | Attachments | File upload capability | Supporting documents |
    And I should be able to perform task actions:
      | Action | Result | Notification |
      | Approve | Move to next stage | Notify next participant |
      | Reject | Return to previous stage | Notify initiator |
      | Delegate | Assign to another user | Notify delegate |
      | Request info | Hold pending clarification | Notify initiator |

  @bpms @notification_system
  Scenario: Process Notification Management
    Given business processes are active with participants
    When workflow events occur
    Then notifications should be sent via configured channels:
      | Notification Channel | Condition | Content |
      | System notification | Always | Task details and required action |
      | Email notification | If configured in user profile | Full task information |
      | Mobile push | If mobile app installed | Summary and direct link |
      | SMS notification | If critical priority | Brief alert message |
    And notification content should include:
      | Information | Purpose | Format |
      | Process name | Identify workflow | "Schedule Approval Process" |
      | Task description | Explain required action | "Review and approve Q1 schedule" |
      | Due date | Set expectations | "Due by: 2025-01-15" |
      | Direct link | Quick access | URL to task interface |
      | Escalation warning | Urgency indicator | "Escalates in 2 days" |

  @bpms @vacation_approval_workflow
  Scenario: Employee Vacation Request Approval Workflow
    Given an employee has submitted a vacation request
    When the vacation approval process initiates
    Then the workflow should route through stages:
      | Stage | Participant | Criteria | Action Options |
      | Initial Review | Direct supervisor | Check team coverage | Approve/Reject/Request changes |
      | Coverage Planning | Planning specialist | Verify replacement plan | Confirm coverage/Request adjustments |
      | HR Approval | HR representative | Validate entitlements | Approve/Flag issues |
      | Final Confirmation | Original supervisor | Final authorization | Approve/Deny |
    And business rules should be enforced:
      | Business Rule | Validation | Error Handling |
      | Sufficient vacation days | Check accumulated balance | Block if insufficient |
      | Notice period | Minimum advance notice | Warn if too short |
      | Team coverage | Minimum staffing levels | Reject if understaffed |
      | Blackout periods | Restricted vacation times | Block prohibited dates |

  @bpms @shift_exchange_workflow
  Scenario: Shift Exchange Approval Workflow
    Given two employees have agreed to exchange shifts
    When the shift exchange process is initiated
    Then the workflow should validate and process:
      | Validation Step | Check | Requirement |
      | Shift compatibility | Same duration/skill requirements | Must match exactly |
      | Employee eligibility | Both employees qualified | Skills and availability |
      | Schedule impact | No coverage gaps created | Maintain service levels |
      | Labor compliance | Overtime and rest rules | Meet regulatory requirements |
    And route through approval stages:
      | Approval Stage | Participant | Validation Focus |
      | Operational review | Team lead | Immediate impact assessment |
      | Schedule validation | Planning specialist | Long-term schedule integrity |
      | Final authorization | Department manager | Business impact approval |

  @bpms @escalation_management
  Scenario: Handle Workflow Escalations and Timeouts
    Given business processes have defined timeouts
    When tasks exceed their due dates
    Then escalation procedures should activate:
      | Escalation Level | Trigger | Action |
      | Level 1 | 24 hours overdue | Reminder to assigned user |
      | Level 2 | 48 hours overdue | Notify supervisor |
      | Level 3 | 72 hours overdue | Auto-assign to backup approver |
      | Level 4 | 96 hours overdue | Executive escalation |
    And escalation should include:
      | Escalation Feature | Implementation | Purpose |
      | Automatic reassignment | Transfer to backup user | Prevent workflow blockage |
      | Escalation notifications | Alert management chain | Ensure visibility |
      | Audit trail | Log all escalation events | Compliance tracking |
      | Emergency override | Manual intervention capability | Crisis management |

  @bpms @delegation_management
  Scenario: Delegate Tasks and Manage Substitutions
    Given I need to delegate my approval responsibilities
    When I configure delegation settings
    Then the system should support:
      | Delegation Type | Configuration | Effect |
      | Temporary delegation | Date range specified | All tasks during period |
      | Specific process | Selected workflows only | Limited scope delegation |
      | Emergency delegation | Immediate transfer | Crisis response |
      | Automatic delegation | Out-of-office triggers | Vacation/absence coverage |
    And delegation should maintain:
      | Audit Requirement | Implementation | Compliance |
      | Original accountability | Track actual decision maker | Responsibility clarity |
      | Delegation authorization | Approve delegation scope | Prevent unauthorized transfers |
      | Audit trail | Log all delegated actions | Complete decision history |
      | Revocation capability | End delegation early | Flexible management |

  @bpms @parallel_approval
  Scenario: Handle Parallel Approval Workflows
    Given some processes require multiple simultaneous approvals
    When parallel approval stages are reached
    Then the system should manage:
      | Parallel Requirement | Logic | Completion Criteria |
      | All must approve | Unanimous consent | 100% approval required |
      | Majority approval | Democratic decision | >50% approval sufficient |
      | Quorum with majority | Minimum participation | Quorum + majority of participants |
      | Any can approve | Single approval sufficient | First approval completes stage |
    And track parallel progress:
      | Progress Indicator | Display | Purpose |
      | Individual status | Per-approver status | Show individual responses |
      | Overall progress | Percentage complete | Summary view |
      | Remaining approvers | Outstanding approvals | Action items |
      | Time remaining | Countdown to deadline | Urgency indicator |

  @bpms @process_monitoring
  Scenario: Monitor Business Process Performance
    Given multiple business processes are running
    When I analyze process performance
    Then monitoring should provide:
      | Performance Metric | Calculation | Target |
      | Average cycle time | Start to completion duration | Within SLA |
      | Stage bottlenecks | Time spent per stage | Identify delays |
      | Approval rates | Approve vs reject ratio | Track decision patterns |
      | Escalation frequency | Percentage requiring escalation | Minimize escalations |
      | Participant utilization | Workload distribution | Balance assignments |
    And support process optimization:
      | Optimization Area | Analysis | Improvement Action |
      | Bottleneck stages | Identify slow stages | Streamline or add resources |
      | Approval patterns | Decision consistency | Training or clarification |
      | Resource allocation | Workload imbalances | Redistribute assignments |
      | Process efficiency | End-to-end timing | Eliminate unnecessary steps |

  @bpms @process_customization
  Scenario: Customize Workflows for Different Business Units
    Given different departments have varying approval requirements
    When configuring business processes
    Then customization should support:
      | Customization Level | Flexibility | Examples |
      | Process templates | Standard patterns | Common approval flows |
      | Department variants | Dept-specific rules | Different approval levels |
      | Role customization | Position-based rules | Manager vs director approval |
      | Geographic variations | Location-specific rules | Regional compliance differences |
    And maintain consistency through:
      | Consistency Mechanism | Implementation | Benefit |
      | Core process standards | Non-negotiable steps | Compliance assurance |
      | Configurable parameters | Adjustable thresholds | Flexibility within bounds |
      | Template inheritance | Base plus customizations | Standardization with flexibility |
      | Change management | Controlled modifications | Prevent unauthorized changes |

  @bpms @compliance_tracking
  Scenario: Ensure Process Compliance and Audit Support
    Given regulatory compliance requirements exist
    When business processes execute
    Then compliance tracking should capture:
      | Compliance Element | Tracking | Purpose |
      | Decision authority | Who made each decision | Authority validation |
      | Decision rationale | Comments and justification | Audit support |
      | Timing compliance | Within required timeframes | Regulatory adherence |
      | Documentation completeness | All required information | Complete audit trail |
      | Approval sequence | Correct approval order | Process integrity |
    And support audit requirements:
      | Audit Support | Capability | Compliance Benefit |
      | Complete audit trails | Full decision history | Regulatory reporting |
      | Tamper-proof records | Immutable logs | Evidence integrity |
      | Searchable archives | Quick audit response | Efficient compliance |
      | Retention management | Automatic archiving | Legal requirement adherence |

  @bpms @emergency_procedures
  Scenario: Handle Emergency Override and Crisis Management
    Given emergency situations may require process bypassing
    When crisis situations occur
    Then emergency procedures should provide:
      | Emergency Feature | Capability | Safeguards |
      | Emergency override | Skip normal approvals | Executive authorization required |
      | Crisis escalation | Immediate top-level routing | Automatic executive notification |
      | Expedited processing | Compressed timelines | Maintain minimum validation |
      | Post-emergency review | Retroactive validation | Audit emergency decisions |
    And maintain accountability:
      | Accountability Measure | Implementation | Purpose |
      | Emergency justification | Required explanation | Document necessity |
      | Executive approval | High-level authorization | Prevent misuse |
      | Retroactive review | Post-crisis analysis | Learn and improve |
      | Audit trail | Complete emergency record | Compliance maintenance |

  @bpms @1c_zup_integration @critical
  Scenario: Schedule Approval Workflow with 1C ZUP sendSchedule Integration
    Given a work schedule has completed the full approval workflow
    And all operators have acknowledged their schedule
    When the planning specialist clicks "Apply Schedule"
    Then the system should execute 1C ZUP integration:
      | Integration Step | API Call | Expected Result |
      | Data preparation | Format schedule data per 1C ZUP requirements | JSON with employee schedules and time types |
      | API invocation | POST sendSchedule with schedule data | HTTP 200 response from 1C ZUP |
      | Document creation | 1C ZUP creates individual schedule documents | Time types I(Я), H(Н), B(В) assigned |
      | Confirmation | Receive success confirmation | Schedule upload confirmed |
    And handle 1C ZUP integration errors:
      | Error Scenario | 1C ZUP Response | Workflow Action |
      | Production calendar missing | "Production calendar missing" error | Display error, queue for retry |
      | Employee not found | "Employee not found" error | Display specific employee error |
      | API unavailable | Network timeout | Queue upload, continue with applied status |
      | Invalid schedule data | "Invalid schedule format" error | Return to Planning Review stage |
    And update workflow status based on integration result:
      | Integration Result | Workflow Status | User Notification |
      | Success | Process Complete | "Schedule applied and uploaded to 1C ZUP" |
      | Queued for retry | Process Complete with warning | "Schedule applied, 1C upload pending" |
      | Failed | Process paused | "Schedule approved but 1C upload failed" |

  @bpms @integration_workflows
  Scenario: Integrate Workflows with External Systems
    Given workflows need to interact with external systems
    When process stages require external validation
    Then integration should support:
      | Integration Type | External System | Purpose |
      | 1C ZUP schedule integration | 1C ZUP system | Schedule approval triggers sendSchedule API call to create individual schedule documents |
      | Calendar integration | Exchange/Outlook | Meeting scheduling for approvals |
      | Document management | SharePoint/ECM | Attach supporting documentation |
      | Notification integration | Email/SMS systems | Multi-channel notifications |
    And handle integration failures:
      | Failure Scenario | Response | Recovery |
      | System unavailable | Queue for retry | Automatic retry with backoff |
      | Data synchronization | Manual intervention | Alert administrators |
      | Authentication failure | Process pause | Restore connection |
      | Timeout errors | Alternative path | Fallback procedures |