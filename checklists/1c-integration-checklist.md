Document: 1c-integration-requirements-en.md

Line 118: Feature: Work schedule loading and synchronization
Keywords: work schedules, график работы, schedule, shift, смена, individual schedule, employee schedules
Priority: Critical

Line 122: Feature: Vacation schedule upload from WFM  
Keywords: vacation schedules, график отпусков, leave schedule, отпуск, holiday, Excel format
Priority: Critical

Line 140: Feature: Employee time norm calculation by production calendar
Keywords: time norm, норма времени, production calendar, производственный календарь, normative, норматив
Priority: High

Line 144: Feature: Vacation balance calculation and retrieval
Keywords: vacation balances, остатки отпусков, leave balance, vacation days, дни отпуска, remaining days
Priority: Critical

Line 148: Feature: Timesheet generation and synchronization
Keywords: timesheet, табель, time tracking, учет времени, attendance, work time accounting
Priority: Critical

Line 154: Feature: Time type determination on 1C side (I, N, B)
Keywords: time types, типы времени, I type, N type, B type, time classification
Priority: High

Line 156: Feature: Deviation management with time types (RV, RVN, NV, C)
Keywords: deviations, отклонения, overtime, сверхурочные, absence, отсутствие, RV, RVN, NV, C
Priority: High

Line 158: Feature: Automatic time type determination based on plan vs fact
Keywords: time type determination, определение типа времени, plan vs fact, план факт
Priority: High

Line 160: Feature: Automatic document creation based on time type
Keywords: automatic document creation, автоматическое создание документов, time type documents
Priority: Medium

Line 194: Feature: Employee and leave balance data retrieval
Keywords: employee data, данные сотрудников, personnel, кадры, staff information, leave data
Priority: Critical

Line 196: Feature: Employee master data synchronization
Keywords: employee master data, основные данные сотрудников, hire date, position, department
Priority: Critical

Line 232: Feature: Organizational structure (subdivision) data sync
Keywords: subdivision, подразделение, department, отдел, organizational structure, hierarchy
Priority: High

Line 238: Feature: Vacation entitlement accrual algorithm
Keywords: vacation accrual, начисление отпуска, entitlement, право на отпуск, calculation algorithm
Priority: High

Line 296: Feature: Agents method for employee and department data exchange
Keywords: agents method, метод agents, employee sync, синхронизация сотрудников, API endpoint
Priority: Critical

Line 314: Feature: Agents method implementation with JSON response
Keywords: agents method implementation, JSON response, employee array, department array
Priority: Critical

Line 365: Feature: Production calendar time norm retrieval (getNormHours)
Keywords: getNormHours, time standard, стандарт времени, working hours, рабочие часы, production calendar
Priority: High

Line 371: Feature: Time norm calculation formula implementation
Keywords: calculation formula, формула расчета, weekly norm, working days, holiday reduction
Priority: High

Line 412: Feature: getNormHours method API exchange
Keywords: getNormHours API, method exchange, WFM to 1C, calculation mode, period calculation
Priority: High

Line 428: Feature: getNormHours method with calculation modes
Keywords: calculation mode, режим расчета, month mode, quarter mode, year mode, period norm
Priority: Medium

Line 465: Feature: Time standards actualization on employee changes
Keywords: actualization, актуализация, update, обновление, synchronize norms, employee changes
Priority: Medium

Line 475: Feature: Weekly time rate management
Keywords: weekly time rate, норма в неделю, time standard per week, working week duration
Priority: Medium

Line 487: Feature: Individual employee schedule creation (sendSchedule)
Keywords: sendSchedule, individual schedule, индивидуальный график, shift upload, work schedule
Priority: Critical

Line 507: Feature: Transitional shift accounting algorithm
Keywords: night shift, ночная смена, transitional shift, переходящая смена, shift date calculation
Priority: High

Line 513: Feature: Time type rules for shifts (H, I, B)
Keywords: shift time types, H type, I type, B type, night hours, day hours, time intervals
Priority: High

Line 523: Feature: sendSchedule method API exchange
Keywords: sendSchedule API, WFM to 1C, schedule upload, shift data, work periods
Priority: Critical

Line 566: Feature: sendSchedule method with shift data structure
Keywords: sendSchedule implementation, shift array, daily hours, night hours, ISO8601 format
Priority: Critical

Line 600: Feature: Time type information retrieval (getTimetypeInfo)
Keywords: getTimetypeInfo, time type, тип времени, timesheet data, данные табеля
Priority: Critical

Line 606: Feature: Time type determination algorithm with priorities
Keywords: time type algorithm, priority rules, displacement rules, sick leave priority
Priority: High

Line 614: Feature: getTimetypeInfo method for timesheet generation
Keywords: getTimetypeInfo API, timesheet generation, deviation types, worked hours
Priority: Critical

Line 638: Feature: getTimetypeInfo method with timesheet block data
Keywords: getTimetypeInfo implementation, absence reasons, worked hours, first half, second half
Priority: High

Line 679: Feature: Operator work monitoring integration (sendFactWorkTime)
Keywords: sendFactWorkTime, work monitoring, мониторинг работы, actual time, фактическое время
Priority: High

Line 693: Feature: Deviation document creation for work monitoring
Keywords: deviation documents, документы отклонений, work monitoring, operator control
Priority: High

Line 711: Feature: Time type determination algorithm for deviations
Keywords: deviation algorithm, plan vs actual, time type calculation, RV, RVN, NN, C types
Priority: High

Line 725: Feature: sendFactWorkTime method API exchange
Keywords: sendFactWorkTime API, WFM to 1C, deviation periods, actual work time
Priority: High

Line 737: Feature: sendFactWorkTime with 15-minute interval tracking
Keywords: sendFactWorkTime implementation, 15 minutes, 15 минут, intervals, time tracking precision
Priority: Low

Line 777: Feature: Automatic document field population
Keywords: document fields, поля документов, automatic population, organization, month, comment
Priority: Medium

Line 793: Feature: Holiday and weekend work document creation
Keywords: holiday work, работа в выходные, weekend work, compensation method, employee consent
Priority: Medium

Line 801: Feature: Absence document creation with reason classification
Keywords: absence documents, документы отсутствия, unexplained absence, part shift absence
Priority: Medium

Line 815: Feature: Overtime work document creation
Keywords: overtime documents, документы сверхурочных, compensation method, overtime consent
Priority: Medium

Line 821: Feature: Document execution in Personnel subsystem
Keywords: document execution, проведение документов, Personnel subsystem, Salary subsystem
Priority: Medium

Line 825: Feature: Initial data upload process
Keywords: initial upload, первичная загрузка, data migration, миграция данных, setup process
Priority: High

Line 835: Feature: 1C ZUP configuration extensions
Keywords: configuration extensions, расширения конфигурации, HTTP service, metadata objects
Priority: High

Line 845: Feature: Integration user access rights configuration
Keywords: access rights, права доступа, permissions, разрешения, security, user rights
Priority: High

Line 854: Feature: 1C Salary and Personnel Management customization
Keywords: customization, настройка, configuration, конфигурация, setup requirements, ZUP settings
Priority: Medium

Line 858: Feature: Time type accrual configuration requirements
Keywords: time type configuration, настройка типов времени, accrual types, priority rules
Priority: Medium

Line 860: Feature: Payroll composition configuration
Keywords: payroll composition, состав начислений, accruals, withholdings, salary calculation
Priority: Medium

Line 862: Feature: Employee work schedule setup requirements
Keywords: work schedule setup, настройка графика работы, production calendar, summarized timekeeping
Priority: Medium

Line 863: Feature: Customer Service subdivision requirement
Keywords: Customer Service, подразделение обслуживания, subdivision code CFR000260
Priority: Low

Line 864: Feature: WFM system user creation requirement
Keywords: WFMSystem user, пользователь WFM, database permissions, full access
Priority: Medium

Line 868: Feature: 1C to JSON field mapping
Keywords: JSON fields, поля JSON, field mapping, соответствие полей, data structure
Priority: Low

Line 894: Feature: Time type to 1C document correspondence
Keywords: time types, типы времени, document mapping, соответствие документов, document types
Priority: Medium

Line 166: Feature: 1C ZUP database web publication
Keywords: web server, веб сервер, database publication, HTTP service, web extension
Priority: High

Line 174: Feature: HTTP service API implementation
Keywords: HTTP service, HTTP сервис, JSON format, POST requests, GET requests, API endpoints
Priority: Critical

Line 180: Feature: Server response status handling
Keywords: response status, статус ответа, HTTP 200, HTTP 500, error handling
Priority: High

Line 188: Feature: Single API endpoint access pattern
Keywords: API endpoint, точка доступа API, single address, uniform access, hs/apiname
Priority: Medium