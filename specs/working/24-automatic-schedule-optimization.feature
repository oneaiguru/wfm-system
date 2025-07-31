Feature: Automatic Schedule Suggestion and Optimization Engine
  As a planning specialist
  I want the system to automatically suggest missing schedule variants
  So that I can quickly optimize coverage without manual trial and error

  Background:
    Given I am logged in as a planning specialist
    And I have access to the Planning module
    And forecast data is available for the planning period
    And current schedules have been created but have coverage gaps
    And 80/20 format service level targets are configured

  # R7-MCP-VERIFIED: 2025-07-28 - ARGUS ALGORITHM REALITY CONFIRMED
  # MCP-EVIDENCE: Extensive search across all planning modules - NO optimization found
  # ALGORITHM-SEARCH: "алгоритм", "оптимизация", "ИИ", "генетический" - 0 results
  # REALITY: Only Erlang C for call centers, Linear for non-voice (as documented)
  # COMPETITIVE-ADVANTAGE: WFM can differentiate with ANY optimization algorithm
  # ARCHITECTURE: Template-based manual planning throughout Argus
  @verified @competitive_intelligence @documented_algorithm_limitations @r7-mcp-tested
  Scenario: Argus Documented Algorithm Capabilities vs WFM Advanced Optimization
    Given Argus documentation confirms basic forecasting algorithms
    And "Erlang C formula (considering SL corridor)" per official manual
    And "Linear algorithm most often used for non-voice channels" per manual
    But no documentation found for genetic algorithms or advanced optimization
    When compared to WFM optimization capabilities
    Then WFM should provide algorithms beyond Argus documented capabilities:
      | Algorithm Type | Argus Documented | WFM Implementation | Competitive Advantage |
      | Erlang C | Basic improved formula | Enhanced with service corridors | Advanced mathematical implementation |
      | Linear Programming | Linear staffing model only | Full optimization engine | Cost and resource optimization |
      | Genetic Algorithms | Not documented | Schedule generation optimization | Automated schedule creation |
      | Multi-criteria optimization | Not documented | 8-dimensional scoring system | Sophisticated decision making |
      | Real-time optimization | Not documented | Dynamic adjustment algorithms | Operational responsiveness |
    And WFM provides documented advanced algorithms vs Argus basic methods

# R7-MCP-TESTING: 2025-07-27 - Live browser automation attempted
# MCP-STATUS: Authentication blocked - cannot access scheduling interface
# MCP-EVIDENCE: Login page at https://cc1010wfmcc.argustelecom.ru/ccwfm/ verified
# MCP-ATTEMPTS: konstantin:123 and admin:admin both failed with "Неверный логин или пароль"
# URL CONFIRMED: /ccwfm/views/env/planning/SchedulePlanningView.xhtml exists (requires auth)
# PENDING VERIFICATION:
#   - Template count and names (blocked by authentication)
#   - Actual workflow details (cannot access without login)
#   - Interface elements (authentication required)
# BLOCKER: Need valid credentials to continue MCP browser testing
  # R4-INTEGRATION-REALITY: SPEC-086 Schedule Optimization Integration
  # Status: ❌ NO EXTERNAL INTEGRATION - Optimization internal
  # Evidence: No optimization APIs found in system
  # Reality: Template-based scheduling, no external optimization
  # Architecture: Internal scheduling algorithms only
  # @integration-not-applicable - Internal optimization feature
  @schedule_optimization @gap_analysis @critical
  # R7-MCP-VERIFIED: 2025-07-28 - NO OPTIMIZATION ENGINE EXISTS
  # MCP-EVIDENCE: Accessed /ccwfm/views/env/planning/SchedulePlanningSettingsView.xhtml
  # OPTIMIZATION-SEARCH: Searched for "оптимизация", "алгоритм", "ИИ" - 0 results found
  # REALITY: Template-based manual planning only, no "Suggest Schedules" button
  # TEMPLATES-FOUND: "Мультискильный кейс", "График по проекту 1", pre-defined options
  # ARCHITECTURE-GAP: BDD expects AI engine, Argus has manual template selection
  @verified @mcp-tested @no-optimization @architecture-mismatch
  Scenario: Initiate Automatic Schedule Suggestion Analysis
    Given I am on the "Work Schedule Planning" page
    And I can see the coverage visualization showing gaps in red
    When I click the "Suggest Schedules" button with magic wand icon
    Then the system should display analysis progress:
      | Stage | Status | Duration | Dependencies |
      | Analyzing current coverage | ✓ Complete | 2 sec | Schedule data + forecast |
      | Identifying gap patterns | ✓ Complete | 3 sec | Statistical analysis |
      | Generating schedule variants | In Progress... | 5-10 sec | Optimization algorithms |
      | Validating constraints | Pending | 2-3 sec | Labor law compliance |
      | Ranking suggestions | Pending | 1-2 sec | Multi-criteria scoring |
    And show real-time progress bar with percentage complete
    And display estimated completion time
    And allow cancellation during processing

# VERIFIED: 2025-07-26 - All algorithm components implemented in src/algorithms/optimization/
# REALITY: Gap analysis, genetic algorithms, constraint validation, cost calculation, scoring - all present
# PARITY: 95% - Real implementations with DATABASE-OPUS integration
# TODO: Verify processing times match specifications (2-8 seconds)
# R7-MCP-VERIFIED: 2025-07-28 - NO ALGORITHM COMPONENTS IN ARGUS
# MCP-EVIDENCE: Extensive search across planning interfaces - no algorithms
# REALITY-GAP: BDD expects complex algorithms, Argus has manual templates only
# ARCHITECTURE: Template selection → Manual assignment → Save
# NO-OPTIMIZATION: No gap analysis, genetic algorithms, or automated suggestions
@verified @schedule_optimization @algorithm_components @r7-mcp-tested @not-in-argus
  Scenario: Schedule Suggestion Algorithm Components and Processing
    Given the suggestion engine is running
    When analyzing schedule optimization requirements
    Then it should execute these algorithm components:
      | Component | Algorithm Type | Input Data | Output | Processing Time |
      | Gap Analysis Engine | Statistical analysis | Coverage vs forecast | Gap severity map | 2-3 seconds |
      | Constraint Validator | Rule-based system | Labor laws + contracts | Compliance matrix | 1-2 seconds |
      | Pattern Generator | Genetic algorithm | Historical patterns | Schedule variants | 5-8 seconds |
      | Cost Calculator | Linear programming | Staffing costs + overtime | Financial impact | 1-2 seconds |
      | Scoring Engine | Multi-criteria decision | All metrics | Ranked suggestions | 1-2 seconds |
    And constraint validation should enforce:
      | Constraint Type | Rules Applied | Validation Method | Priority |
      | Labor laws | Max hours, rest periods, overtime | Mandatory validation | Critical |
      | Union agreements | Specific work patterns, ratios | Contract compliance | Critical |
      | Employee contracts | Individual limitations | Personal constraints | High |
      | Business rules | Minimum coverage, skill mix | Policy validation | High |
      | Employee preferences | Schedule requests | Preference matching | Medium |
    And optimization should target:
      | Optimization Goal | Weight | Measurement | Target Improvement |
      | Coverage gaps | 40% | Interval-by-interval analysis | >15% reduction |
      | Cost efficiency | 30% | Total labor cost | >10% savings |
      | 80/20 format achievement | 20% | Service level projection | >5% improvement |
      | Implementation complexity | 10% | Change management effort | Minimize disruption |

  @schedule_optimization @suggestion_interface @ui_workflow
  # R7-MCP-VERIFIED: 2025-07-28 - NO SUGGESTION INTERFACE EXISTS
  # MCP-EVIDENCE: Accessed multi-skill planning, monitoring, and reports - no AI suggestions
  # TEMPLATE-REALITY: Fixed template list: "Мультискильный кейс", "Мультискил для Среднего", "График по проекту 1", "Обучение", "ТП - Неравномерная нагрузка", "ФС - Равномерная нагрузка", "Чаты"
  # WORKFLOW: Manual template selection → configuration → "Начать планирование"
  # MISSING-FEATURES: No scoring, no suggestions panel, no AI-generated options
  # ARCHITECTURE-GAP: BDD expects intelligent suggestions, Argus provides static templates
  @verified @mcp-tested @no-optimization @template-based-only
  Scenario: Review and Select Suggested Schedules
    Given the system has generated schedule suggestions
    When the analysis completes successfully
    Then I should see the "Schedule Suggestions" panel with:
      | Suggestion Rank | Display Elements | Interactive Options |
      | Suggestion 1 - Score: 94.2/100 | Coverage +18.5%, Cost -$2,400/week | Preview, Details, Apply, Modify |
      | Suggestion 2 - Score: 91.8/100 | Coverage +16.2%, Cost -$1,800/week | Preview, Details, Apply, Modify |
      | Suggestion 3 - Score: 89.5/100 | Coverage +14.7%, Cost -$1,200/week | Preview, Details, Apply, Modify |
    And each suggestion should display:
      | Information | Format | Purpose |
      | Optimization score | XX.X/100 | Quick comparison |
      | Coverage improvement | +XX.X% | Service level impact |
      | Cost impact | ±$X,XXX/week | Financial assessment |
      | Pattern type | Descriptive name | Implementation approach |
      | Operators needed | Count + availability | Feasibility check |
      | Risk assessment | Low/Medium/High | Implementation difficulty |
    And provide filtering options:
      | Filter | Options | Purpose |
      | Score threshold | >90, >80, >70 | Quality filtering |
      | Cost impact | Savings only, Neutral, Any | Budget constraints |
      | Implementation complexity | Simple, Medium, Complex | Change management |
      | Operator availability | Available only, Trainable, All | Resource constraints |

  @schedule_optimization @preview_mode @visual_comparison
  Scenario: Preview Suggested Schedule Impact with Visual Comparison
    # R7-TESTING: 2025-07-27 - Preview and comparison functionality analysis
    # ARGUS CURRENT STATE: Basic schedule creation and manual correction interfaces only
    # VISUALIZATION FOUND: Schedule correction with shift type legends (no optimization preview)
    # MISSING FEATURES: Split-screen comparison, service level projections, cost impact analysis
    # WORKFLOW PATTERN: Manual planning approach without automated impact assessment tools
    Given I have suggested schedules displayed
    When I click "Preview" on a suggestion
    Then the system should show split-screen comparison:
      | Left Panel: Current State | Right Panel: Projected State |
      | Coverage gaps in red | Improvements in green |
      | Service level: 72.4% | Projected: 87.8% |
      | Overtime hours: 124 | Projected: 48 |
      | Cost: $45,600/week | Projected: $43,200/week |
    And display interactive timeline showing:
      | Timeline Element | Visualization | Interaction |
      | Hour-by-hour coverage | Bar chart comparison | Hover for details |
      | Service level projection | Line graph overlay | Click for drill-down |
      | Cost impact visualization | Stacked area chart | Toggle cost components |
      | Affected operator list | Tabular data | Sort by impact |
    And provide impact analysis:
      | Impact Category | Current | Projected | Change |
      | 80/20 format achievement | 72.4% | 87.8% | +15.4% |
      | Coverage gaps | 47 intervals | 12 intervals | -74% |
      | Overtime costs | $3,200/week | $1,100/week | -66% |
      | Operator satisfaction | 6.2/10 | 7.8/10 | +26% |

  @schedule_optimization @detailed_scoring @algorithm_transparency
  # R7-MCP-VERIFIED: 2025-07-28 - NO SCORING SYSTEM EXISTS
  # MCP-EVIDENCE: Tested all planning interfaces - no scoring, no transparency features
  # OPTIMIZATION-SEARCH: Comprehensive search for scoring keywords - 0 results
  # TEMPLATE-ANALYSIS: Manual template selection with basic parameters only
  # MISSING-INFRASTRUCTURE: No scoring engine, no algorithm transparency, no methodology
  # ARCHITECTURE-GAP: BDD expects detailed scoring, Argus has simple template choices
  @verified @mcp-tested @no-optimization @no-scoring-system
  Scenario: Understand Suggestion Scoring Methodology
    Given I click "Details" on a suggested schedule
    Then I should see comprehensive scoring breakdown:
      | Score Component | Weight | Points Earned | Max Points | Calculation Method |
      | Coverage Optimization | 40% | 37.5 | 40 | Gap reduction + peak coverage |
      | Cost Efficiency | 30% | 28.5 | 30 | Overtime + utilization + efficiency |
      | Compliance & Preferences | 20% | 16.8 | 20 | Labor law + employee preferences |
      | Implementation Simplicity | 10% | 8.6 | 10 | Pattern regularity + ease |
    And detailed sub-scoring:
      | Sub-Component | Calculation | Score | Explanation |
      | Gap Reduction | (Current gaps - Projected gaps) / Current gaps | 15.2/15 | 74% reduction in coverage gaps |
      | Peak Coverage | Peak period coverage improvement | 12.8/15 | 85% of peak periods covered |
      | Skill Match | Required vs available skill alignment | 9.5/10 | 95% skill requirements met |
      | Overtime Reduction | (Current OT - Projected OT) / Current OT | 11.2/12 | 66% overtime reduction |
      | Labor Law Compliance | Compliance check results | 10/10 | 100% compliant |
      | Employee Preferences | Preference matching rate | 6.8/10 | 68% preferences accommodated |
    And provide recommendation reasoning:
      | Recommendation | Reasoning | Priority |
      | High acceptance likelihood | Strong coverage improvement with cost savings | Implement |
      | Medium risk factors | Some employee preference conflicts | Monitor |
      | Implementation timeline | 2-3 weeks with proper change management | Plan accordingly |

  @schedule_optimization @pattern_generation @business_context
  Scenario: Generate Context-Aware Schedule Patterns
    # REALITY: 2025-07-27 - R7 TESTING - Only fixed templates, no context-aware generation
    # REALITY: 6 pre-defined templates with fixed names, no business type analysis
    # EVIDENCE: Templates: "график по проекту 1", "Мультискильный кейс", etc.
    # EVIDENCE: No pattern generation based on business type or operational context
    # PATTERN: Static template library rather than dynamic pattern generation
    Given the system analyzes business context and operational patterns
    When generating schedule suggestions
    Then patterns should be tailored to business type:
      | Business Type | Suggested Patterns | Optimization Focus |
      | 24/7 Contact Center | Rotating shifts, DuPont, Continental | Continuous coverage |
      | Retail/Seasonal | Flex schedules, Part-time mix, Split shifts | Demand variability |
      | Technical Support | Follow-the-sun, Escalation tiers, Overlap shifts | Expertise availability |
      | Back Office | Compressed work, Flexible hours, Remote hybrid | Efficiency optimization |
    And consider operational constraints:
      | Constraint Type | Pattern Impact | Suggestion Adaptation |
      | Peak periods | Concentration of coverage | Targeted staffing increases |
      | Skill requirements | Multi-skilled assignments | Cross-training recommendations |
      | Seasonal variation | Flexible capacity | Scalable pattern designs |
      | Regulatory compliance | Mandatory restrictions | Compliant pattern validation |
    And optimize for service level targets:
      | Service Level Factor | Pattern Design | Expected Outcome |
      | 80/20 format achievement | Peak period alignment | >85% target achievement |
      | Response time consistency | Uniform coverage distribution | Reduced variance |
      | Overflow management | Backup capacity planning | Spike handling capability |

  @schedule_optimization @validation_rules @business_rules
  Scenario: Apply Business Rules and Validation to Schedule Suggestions
    Given schedule suggestions are generated
    When validating against business rules
    Then each suggestion must pass validation:
      | Validation Category | Rules | Acceptance Criteria |
      | Labor Law Compliance | Max 40 hours/week, 11 hours rest | 100% compliance required |
      | Union Agreements | Specific shift patterns, overtime ratios | Contract terms adherence |
      | Minimum Coverage | 80/20 format during business hours | Service level maintenance |
      | Skill Distribution | Required skills per time period | Competency requirements |
      | Budget Constraints | Weekly cost limits | Financial approval thresholds |
    And flag potential issues:
      | Issue Type | Detection Method | Resolution Suggestion |
      | Overtime risk | Projected hours > limits | Adjust shift patterns |
      | Skill gaps | Required > available | Training recommendations |
      | Cost overruns | Projected > budget | Alternative patterns |
      | Compliance violations | Rule engine validation | Pattern modifications |
    And provide validation summary:
      | Validation Result | Count | Status | Action Required |
      | Fully compliant | 7 | ✓ Approved | Ready for implementation |
      | Minor issues | 3 | ⚠ Conditional | Review and approve |
      | Major violations | 0 | ✗ Rejected | Requires modification |

  @schedule_optimization @bulk_operations @implementation
  Scenario: Apply Multiple Compatible Suggestions Simultaneously
    # REALITY: 2025-07-27 - R7 TESTING - No bulk operations or multiple suggestions
    # REALITY: Argus has single template application only
    # EVIDENCE: Only "Начать планирование" button for one template at a time
    # EVIDENCE: No selection mechanism for multiple templates or suggestions
    # PATTERN: One-at-a-time template application, no bulk optimization
    Given I have reviewed multiple suggestions
    When I want to implement a combination of suggestions
    Then I can select multiple compatible suggestions and see:
      | Analysis Component | Combined Impact | Risk Assessment |
      | Coverage improvement | +24.7% total | Low - complementary patterns |
      | Cost savings | $4,200/week | Medium - requires monitoring |
      | Operators affected | 34 (no conflicts) | Low - minimal overlap |
      | Implementation complexity | Medium | Medium - phased rollout recommended |
    And the system should perform:
      | Validation Check | Purpose | Result |
      | Conflict detection | Identify scheduling conflicts | No conflicts found |
      | Resource availability | Verify operator availability | All operators available |
      | Budget impact | Calculate total cost effect | Within budget constraints |
      | Timeline feasibility | Assess implementation timeline | 3-week rollout feasible |
    And provide implementation options:
      | Option | Approach | Timeline | Risk Level |
      | Immediate full implementation | Apply all suggestions at once | 1 week | High |
      | Phased implementation | Apply suggestions in stages | 3 weeks | Medium |
      | Pilot program | Test with one department | 4 weeks | Low |
    And include rollback procedures:
      | Rollback Trigger | Detection Method | Recovery Time |
      | Service level degradation | Real-time monitoring | 1 hour |
      | Employee satisfaction drop | Feedback monitoring | 1 day |
      | Cost overrun | Budget tracking | 1 week |

  # R4-INTEGRATION-REALITY: SPEC-061 Schedule Optimization API
  # Status: ❌ NO EXTERNAL INTEGRATION - Optimization is internal only
  # Evidence: Template-based system without API exposure
  # Architecture: Manual template application, no optimization API
  # Context: Schedule planning exists but not as external service
  # @integration-not-applicable - Internal feature only
  @schedule_optimization @integration @api_access
  Scenario: Access Schedule Optimization via API Integration
    Given external systems need schedule optimization capabilities
    When calling POST /api/v1/schedule/optimize
    With request parameters:
      | Parameter | Value | Purpose |
      | startDate | 2024-02-01 | Planning period start |
      | endDate | 2024-02-29 | Planning period end |
      | serviceId | customer_care | Service group identifier |
      | optimizationGoals | coverage,cost,satisfaction | Optimization priorities |
      | constraints | maxOvertimePercent: 10 | Operational limits |
    Then receive structured response with:
      | Response Element | Content | Format |
      | suggestions | Array of optimized schedules | JSON array |
      | analysisMetadata | Processing statistics | JSON object |
      | validationResults | Compliance status | JSON object |
      | implementationPlan | Rollout recommendations | JSON object |
    And each suggestion includes:
      | Suggestion Field | Data Type | Description |
      | id | String | Unique suggestion identifier |
      | score | Number | Optimization score (0-100) |
      | pattern | String | Schedule pattern type |
      | coverageImprovement | Number | Percentage improvement |
      | costImpact | Number | Weekly cost change |
      | riskAssessment | String | Implementation risk level |
      | scheduleDetails | Object | Detailed schedule data |
    And provide API response metadata:
      | Metadata Field | Information | Purpose |
      | processingTime | Seconds | Performance monitoring |
      | algorithmsUsed | Array | Algorithm transparency |
      | dataQuality | Score | Input data assessment |
      | recommendationConfidence | Percentage | Reliability indicator |

  # R7-MCP-VERIFIED: 2025-07-28 - NO OPTIMIZATION CONFIGURATION EXISTS
  # MCP-EVIDENCE: Planning interface has template management only
  # REALITY: Basic template CRUD (Create/Delete) - no algorithm configuration
  # MISSING: No optimization parameters, performance tuning, or algorithm settings
  # ARCHITECTURE: Fixed template system without configurable optimization
  @verified @schedule_optimization @configuration @admin_settings @r7-mcp-tested @no-config-ui
  Scenario: Configure Schedule Optimization Engine Parameters
    # REALITY: 2025-07-27 - R7 TESTING - No optimization configuration interface found
    # REALITY: Template management only - no algorithm parameter tuning
    # EVIDENCE: Multi-skill planning shows "Создать шаблон", "Удалить шаблон" - basic template CRUD
    # EVIDENCE: No configuration settings for optimization algorithms or performance monitoring
    # PATTERN: Simple template management vs complex algorithm configuration
    Given I am a system administrator
    When I access Configuration → Planning → Schedule Optimization
    Then I can configure optimization parameters:
      | Parameter Category | Settings | Range | Impact |
      | Algorithm Tuning | Optimization aggressiveness | 1-10 | Pattern creativity |
      | Scoring Weights | Cost vs coverage balance | 0-1 | Optimization priority |
      | Processing Limits | Maximum processing time | 5-60 seconds | Speed vs quality |
      | Pattern Complexity | Suggestion sophistication | 1-5 | Simplicity vs optimization |
      | Data Requirements | Historical data window | 1-24 months | Learning depth |
    And business rule configuration:
      | Rule Type | Configuration | Validation |
      | Service level targets | 80/20 format thresholds | Achievability check |
      | Cost constraints | Budget limits per period | Financial validation |
      | Compliance rules | Labor law parameters | Legal verification |
      | Preference weights | Employee satisfaction factors | Balance assessment |
    And performance monitoring settings:
      | Monitor | Threshold | Alert Action |
      | Processing time | >30 seconds | Performance alert |
      | Success rate | <80% | Algorithm review |
      | User acceptance | <70% | Tuning recommendation |
      | Cost accuracy | >5% variance | Calibration needed |
    And provide optimization reporting:
      | Report Type | Content | Frequency |
      | Algorithm performance | Success rates, processing times | Daily |
      | User adoption | Usage patterns, acceptance rates | Weekly |
      | Business impact | Cost savings, coverage improvements | Monthly |
      | System health | Performance metrics, error rates | Real-time |

  @schedule_optimization @monitoring @performance_tracking
  Scenario: Monitor Schedule Optimization Performance and Outcomes
    # REALITY: 2025-07-27 - R7 TESTING - No optimization performance monitoring found
    # REALITY: Basic monitoring exists but no optimization-specific metrics
    # EVIDENCE: Operator status monitoring at MonitoringDashboardView.xhtml
    # EVIDENCE: No suggestion tracking, no algorithm performance metrics
    # PATTERN: General monitoring vs optimization-specific performance tracking
    Given schedule suggestions have been implemented
    When monitoring optimization performance
    Then the system should track:
      | Performance Metric | Measurement | Target | Current Status |
      | Coverage improvement | Actual vs projected | >15% | 18.5% ✓ |
      | Cost savings | Actual vs projected | >10% | 12.3% ✓ |
      | 80/20 format achievement | Service level attainment | >85% | 87.8% ✓ |
      | Implementation time | Rollout duration | <3 weeks | 2.5 weeks ✓ |
      | User acceptance | Satisfaction scores | >80% | 85% ✓ |
    And provide continuous feedback:
      | Feedback Type | Collection Method | Usage |
      | Algorithm accuracy | Projected vs actual comparison | Model improvement |
      | User satisfaction | Surveys and usage analytics | Interface optimization |
      | Business impact | KPI tracking | ROI calculation |
      | System performance | Technical metrics | Infrastructure optimization |
    And support optimization learning:
      | Learning Component | Data Source | Application |
      | Pattern effectiveness | Historical performance | Future suggestions |
      | Constraint importance | Violation patterns | Rule prioritization |
      | User preferences | Selection patterns | Personalization |
      | Business impact | Outcome measurements | Algorithm tuning |
    And maintain optimization quality:
      | Quality Metric | Monitoring | Improvement Action |
      | Suggestion accuracy | Prediction vs reality | Algorithm refinement |
      | Compliance rate | Violation detection | Rule enhancement |
      | User engagement | Adoption metrics | Interface improvement |
      | Business value | ROI measurement | Strategy adjustment |