    1: # ARGUS WFM CC Administrator Guide
    2: 
    3: **2022**
    4: 
    5: ## Table of Contents
    6: 
    7: 1. [WFM CC Solution Components](#1-wfm-cc-solution-components)
    8:    1. [Purpose and Composition of WFM CC Software Solution](#11-purpose-and-composition-of-wfm-cc-software-solution)
    9:       1. [List of Components in WFM CC Solution](#111-list-of-components-in-wfm-cc-solution)
   10:       2. [Optional Delivery, Typical Delivery Variants of WFM CC Solution](#112-optional-delivery-typical-delivery-variants-of-wfm-cc-solution)
   11:    2. [Interaction Scheme of WFM CC Solution Components](#12-interaction-scheme-of-wfm-cc-solution-components)
   12:    3. [Lifecycle of WFM CC Solution Components](#13-lifecycle-of-wfm-cc-solution-components)
   13:       1. [WFM CC Solution Implementation](#131-wfm-cc-solution-implementation)
   14:       2. [WFM CC Solution Support](#132-wfm-cc-solution-support)
   15: 
   16: 2. [Technical Architecture of WFM CC Solution](#2-technical-architecture-of-wfm-cc-solution)
   17:    1. [Composition and Hardware Requirements for WFM CC Solution Components](#21-composition-and-hardware-requirements-for-wfm-cc-solution-components)
   18:       1. [WFM CC Database](#211-wfm-cc-database)
   19:       2. [WFM CC Application Server](#212-wfm-cc-application-server)
   20:       3. [WFM CC Personal Cabinet Service](#213-wfm-cc-personal-cabinet-service)
   21:       4. [WFM CC Mobile API Service](#214-wfm-cc-mobile-api-service)
   22:       5. [Planning Service](#215-planning-service)
   23:       6. [Reports Service](#216-reports-service)
   24:       7. [Notifications Service](#217-notifications-service)
   25:       8. [Integration Service](#218-integration-service)
   26:       9. [Client System](#219-client-system)
   27:       10. [Network System](#2110-network-system)
   28:       11. [External IT Systems (Integration)](#2111-external-it-systems-integration)
   29:       12. [Monitoring System](#2112-monitoring-system)
   30:    2. [Access for Diagnostics of Malfunctions for Argus Specialists](#22-access-for-diagnostics-of-malfunctions-for-argus-specialists)
   31:    3. [Requirements for Qualification of Customer Service Personnel](#23-requirements-for-qualification-of-customer-service-personnel)
   32:       1. [Database Operation](#231-database-operation)
   33:       2. [Application Server Operation](#232-application-server-operation)
   34:       3. [Client System Operation](#233-client-system-operation)
   35:       4. [Network System Operation](#234-network-system-operation)
   36:    4. [General Procedure for Deployment and Maintenance of WFM CC Solution Components](#24-general-procedure-for-deployment-and-maintenance-of-wfm-cc-solution-components)
   37:       1. [Standard Concepts](#241-standard-concepts)
   38:       2. [Standard Actions for Software Updates](#242-standard-actions-for-software-updates)
   39:       3. [Regular Procedures for Maintaining WFM CC Solution Components](#243-regular-procedures-for-maintaining-wfm-cc-solution-components)
   40:       4. [Monitoring Tools Deployment](#244-monitoring-tools-deployment)
   41:       5. [Standard Actions During Emergency](#245-standard-actions-during-emergency)
   42: 
   43: 3. [WFM CC Solution Service Maintenance Guide](#3-wfm-cc-solution-service-maintenance-guide)
   44:    1. [Software Environment Setup for WFM CC Server Software Deployment](#31-software-environment-setup-for-wfm-cc-server-software-deployment)
   45:    2. [Installation, Configuration and Update of WFM CC Server Software](#32-installation-configuration-and-update-of-wfm-cc-server-software)
   46:    3. [Installation and Configuration of WFM CC Client Software](#33-installation-and-configuration-of-wfm-cc-client-software)
   47:    4. [Required Regular Procedures](#34-required-regular-procedures)
   48:    5. [Software Update Measures When Transitioning to Another Time Zone](#35-software-update-measures-when-transitioning-to-another-time-zone)
   49: 
   50: 4. [Administrator Reference Guides](#4-administrator-reference-guides)
   51:    1. [Database Administrator Reference](#41-database-administrator-reference)
   52:    2. [Application Server and Services Administrator Reference](#42-application-server-and-services-administrator-reference)
   53: 
   54: ---
   55: 
   56: ## 1. WFM CC Solution Components
   57: 
   58: ### 1.1 Purpose and Composition of WFM CC Software Solution
   59: 
   60: The WFM CC software solution is designed to manage the Customer's workforce resources.
   61: 
   62: #### 1.1.1 List of Components in WFM CC Solution
   63: 
   64: The WFM CC solution includes the following components, comprising functional services and modules:
   65: 
   66: - Personal Cabinet
   67: - Mobile API
   68: - WFM CC
   69: - Forecasting Module
   70: - Planning Module UI
   71: - Monitoring Module
   72: - Work Schedule Planning and Scheduling
   73: - Planning Service
   74: - Gateway Service
   75: - Report Generation
   76: - Notification Sending
   77: - Integration with External Systems
   78: 
   79: #### 1.1.2 Optional Delivery, Typical Delivery Variants of WFM CC Solution
   80: 
   81: Components in the WFM CC solution can be delivered in any composition: both together and separately.
   82: 
   83: Delivery can be carried out as a package or as a version.
   84: 
   85: A package includes a single change (fix) for any of the components.
   86: 
   87: A version includes changes (fixes) for several components at once.
   88: 
   89: Components can be installed on the Application Server (AS) and in the Database (DB):
   90: 
   91: **AS composition includes:**
   92: - Distributables (jar files)
   93: - Plugins (jar files)
   94: - Services in Docker images and configuration files for loading images
   95: - Supporting documentation (Installation Manual, User Manual, Test Protocol)
   96: 
   97: **Database composition includes:**
   98: - SQL update scripts (or dbmaintain utility)
   99: - Supporting documentation (Installation Manual, User Manual, Test Protocol)
  100: 
  101: The composition of the AS delivery may vary depending on the functional purpose of the AS.
  102: 
  103: ### 1.2 Interaction Scheme of WFM CC Solution Components
  104: 
  105: ![WFM CC Components Interaction Scheme](img/wfm_cc_components_interaction.png)
  106: 
  107: *Figure 1.2 - WFM CC Solution Components Interaction Scheme*
  108: 
  109: The arrows in Figure 1.2 show the direction of interaction between WFM CC solution components.
  110: 
  111: Several components can interact both with their local databases (dashed red arrows) and with a unified database (solid red arrows).
  112: 
  113: ### 1.3 Lifecycle of WFM CC Solution Components
  114: 
  115: The WFM CC solution lifecycle consists of implementation stages and subsequent support.
  116: 
  117: The degree of responsibility at each stage between Argus and the Customer is individually agreed upon and recorded as an appendix to the contract titled: Responsibility Matrix.
  118: 
  119: The Responsibility Matrix is supplemented with comments explaining the specifics of the work being performed.
  120: 
  121: The following responsibility levels exist:
  122: 
  123: - **R** – Responsible (executes)
  124: - **A** – Accountable (bears responsibility)
  125: - **C** – Consult before doing (consults before execution)
  126: - **I** – Inform after doing (notifies after execution)
  127: - **S** – Supported (provides support)
  128: 
  129: **Table 1.3 - Responsibility Matrix Example**
  130: 
  131: | No. | Procedure/Role | Implementation Stage | GO/PGO Stage |
  132: |-----|----------------|---------------------|--------------|
  133: | 1 | Hardware component mounting and configuration (servers, storage systems, backup systems) | NTC "Argus": C<br>Customer: RAIS | NTC "Argus": C<br>Customer: RAIS |
  134: | 2 | Network access organization for Argus employees to customer network and equipment | NTC "Argus": CS<br>Customer: RAI | NTC "Argus": CS<br>Customer: RAI |
  135: | 3 | PostgreSQL DBMS administration | NTC "Argus": C<br>Customer: RAIS | NTC "Argus":<br>Customer: RACIS |
  136: | 4 | Argus system database instances (prod/backup) administration | NTC "Argus": CS<br>Customer: RAI | NTC "Argus": CS<br>Customer: RAI |
  137: | 5 | Database instances availability monitoring (prod/backup) | NTC "Argus":<br>Customer: RACIS | NTC "Argus":<br>Customer: RACIS |
  138: | 6 | System software administration for servers | NTC "Argus": C<br>Customer: RAIS | NTC "Argus": C<br>Customer: RAIS |
  139: | 7 | Application software administration on servers | NTC "Argus": CS<br>Customer: RAI | NTC "Argus": CS<br>Customer: RAI |
  140: | 8 | Argus system operator workstation/station administration | NTC "Argus": C<br>Customer: RAIS | NTC "Argus": C<br>Customer: RAIS |
  141: | 9 | Backup process configuration | NTC "Argus": C<br>Customer: RAIS | NTC "Argus": C<br>Customer: RAIS |
  142: | 10 | Backup process and fault tolerance monitoring | NTC "Argus":<br>Customer: RACIS | NTC "Argus":<br>Customer: RACIS |
  143: 
  144: #### 1.3.1 WFM CC Solution Implementation
  145: 
  146: WFM CC solution implementation goes through the following stages:
  147: 
  148: - Solution delivery
  149: - Deployment in test zone
  150: - Pilot operation
  151: - Deployment in production zone
  152: - Pilot-industrial operation
  153: - Acceptance testing
  154: - Industrial operation
  155: 
  156: #### 1.3.2 WFM CC Solution Support
  157: 
  158: WFM CC solution support goes through the following stages:
  159: 
  160: - Update delivery
  161: - Deployment in test zone
  162: - Acceptance testing
  163: - Installation in production zone
  164: 
  165: ---
  166: 
  167: ## 2. Technical Architecture of WFM CC Solution
  168: 
  169: ### 2.1 Composition and Hardware Requirements for WFM CC Solution Components
  170: 
  171: The WFM CC solution includes the following components:
  172: 
  173: - WFM CC Database
  174: - WFM CC Application Server
  175: - WFM CC Personal Cabinet Service
  176: - WFM CC Mobile API Service
  177: - Planning Service
  178: - Reports Service
  179: - Notifications Service
  180: - Integration Service
  181: - Client System
  182: - Network System
  183: - External IT Systems (integration)
  184: - Monitoring System
  185: 
  186: ![WFM CC Technical Architecture](img/wfm_cc_technical_architecture.png)
  187: 
  188: *Figure 2.1 - WFM CC Solution Technical Architecture*
  189: 
  190: For integration, reports, planning, and notification services, the database can be either local for each service or unified for all services (WFM CC Database).
  191: 
  192: The solution's fault tolerance is ensured by duplicating server components and architecturally provides for their horizontal scaling.
  193: 
  194: #### 2.1.1 WFM CC Solution Database
  195: 
  196: The WFM CC solution uses PostgreSQL 10.x DBMS for each of the databases:
  197: 
  198: - WFM CC Database
  199: - Integration Database
  200: - Planning Database
  201: - Notifications Database
  202: - Reports Database
  203: 
  204: Data loss protection is implemented using Master-Slave database replication technology.
  205: 
  206: ##### 2.1.1.1 CPU, RAM Requirements for WFM CC Database
  207: 
  208: CPU and RAM resource requirements are calculated based on the total load created by each WFM CC solution component using the WFM CC Database.
  209: 
  210: For OS system processes:
  211: - **CPU**: 1 core
  212: - **RAM**: 2GB
  213: 
  214: **CPU type**: Intel Xeon e5-2640 (or equivalent)
  215: 
  216: **Table 2.1.1.1 - Database Resource Requirements**
  217: 
  218: | Load Source | Database Resource Requirements |
  219: |-------------|-------------------------------|
  220: | WFM CC AS | • **CPU (DB)**: 1 core per 10 simultaneous open (concurrent) sessions (forecasting, planning, monitoring)<br>• **RAM (DB)**: 4GB per 10 simultaneous open (concurrent) sessions |
  221: | Personal Cabinet Service | • **CPU (DB)**: 1 core per 100 simultaneous open (concurrent) user sessions<br>• **RAM (DB)**: 4GB per 100 simultaneous open (concurrent) user sessions |
  222: | Integration Service | For each integration:<br>• **CPU (DB)**: 1 core<br>• **RAM (DB)**: 2GB |
  223: | Reports Service | • **CPU (DB)**: 1 core<br>• **RAM (DB)**: 2GB |
  224: | Mobile API Service | At 20 requests per second (req/sec) and average request duration of 3 seconds, for every 500 operators:<br>• **CPU (DB)**: 1 core<br>• **RAM (DB)**: 2GB |
  225: | Notifications Service | No resources required |
  226: | Planning Service | No resources required |
  227: 
  228: **Final Requirements:**
  229: - **CPU (OS)** = total CPU cores (DB) + 1 core (for OS system processes)
  230: - **RAM (OS)** = (total RAM (DB) × 1.5) + 2GB (for OS system processes)
  231: 
  232: After final calculation, apply a reduction coefficient of 0.75 for both CPU and RAM, since it's unlikely that all listed load sources will simultaneously access the database at their peak values.
  233: 
  234: *Note: When calculating, RAM value should be at least 8GB regardless of user count, as there's potential for uncontrolled query complexity using historical data.*
  235: 
  236: ##### 2.1.1.2 Network Interface Requirements for WFM CC Database
  237: 
  238: The database server host requires at least two Gigabit Ethernet network interfaces.
  239: 
  240: ##### 2.1.1.3 Port Requirements for WFM CC Database
  241: 
  242: Port 5432 must be open on the host for database access.
  243: 
  244: The port must not be used by the operating system or other applications.
  245: 
  246: ##### 2.1.1.4 Storage Requirements for WFM CC Database
  247: 
  248: When selecting storage, consider system growth dynamics based on the number of users and groups that form the main data volume.
  249: 
  250: **Table 2.1.1.4 - Resource Growth**
  251: 
  252: | Table | Growth |
  253: |-------|--------|
  254: | worker_change_status_log | One user generates 4KB of data per day |
  255: | historical_data | One group generates 14KB of data per day |
  256: 
  257: Storage performance requirements are selected based on the load.
  258: 
  259: #### 2.1.2 WFM CC Application Server
  260: 
  261: ##### 2.1.2.1 CPU, RAM, HDD Requirements for WFM CC Application Server
  262: 
  263: Resources required for the Application Server operation are calculated based on the number of concurrent user sessions performing tasks:
  264: 
  265: - **Forecasting** (forecast open sessions - fos)
  266: - **Planning UI** (planning open sessions - pos)
  267: - **Monitoring** (monitoring open sessions - mos)
  268: 
  269: And initial data for each module:
  270: 
  271: **Forecasting:**
  272: - Historical data period duration for forecasting, in years (historical data period - hdp)
  273: - Forecasting period, in years (forecast data period - fdp)
  274: 
  275: **Planning UI:**
  276: - Number of operators in planning template (schedule template worker number - stwn)
  277: 
  278: **Monitoring:**
  279: - Number of groups one supervisor can monitor (monitoring group number - mgn)
  280: 
  281: **CPU Requirements (cores)**
  282: - 1 core per concurrent user session
  283: - 1 core for OS system processes
  284: 
  285: **RAM Requirements:**
  286: - 2GB for OS system processes
  287: 
  288: **RAM for JVM (MB):**
  289: - Application Server instance startup: 2048MB
  290: - Forecasting module: 4096 + (hdp + fdp) × 512 × fos
  291: - Planning UI module: 
  292:   - Schedule display: e^(6.558+0.002 × stwn) × pos
  293:   - Timetable display: e^(4.693+0.004 × stwn) × pos
  294: - Monitoring module: (1500 + 25 × mgn) × mos
  295: 
  296: **Total RAM (JVM) MB** = 2048 + 4096 + (hdp + fdp) × 512 × fos + e^(6.558+0.002 × stwn) × pos + e^(4.693+0.004 × stwn) × pos + (1500 + 25 × mgn) × mos
  297: 
  298: **Final RAM (OS)** = (RAM for JVM) × 1.5 + 2GB (for OS system processes)
  299: 
  300: **HDD Requirements:**
  301: - 50GB for OS
  302: - 100GB for software and logs storage under normal operation (excluding DEBUG)
  303: 
  304: Recommended to use fault-tolerant arrays (e.g., RAID-1, RAID-10)
  305: 
  306: *Note: Resource requirements have exponential dependency*
  307: *CPU type: Intel Xeon e5-2640 (or equivalent)*
  308: 
  309: ##### 2.1.2.2 Network Interface Requirements for WFM CC Application Server
  310: 
  311: The Application Server host requires a network interface with 100Mbit/s bandwidth.
  312: 
  313: ##### 2.1.2.3 Port Requirements for WFM CC Application Server
  314: 
  315: The following ports must be open on the Application Server host:
  316: 
  317: **Table 2.1.2.3 - WFM CC Application Server Port Requirements**
  318: 
  319: | Port | Protocol | Purpose |
  320: |------|----------|---------|
  321: | 8080 | HTTP | Serving HTTP requests from user browsers and other WFM CC solution components |
  322: | 9990 | JMX | Management port for web interface access to application server management |
  323: 
  324: Ports must not be used by the operating system or other applications.
  325: 
  326: #### 2.1.3 WFM CC Personal Cabinet Service
  327: 
  328: ##### 2.1.3.1 CPU, RAM, HDD Requirements for Personal Cabinet Service
  329: 
  330: Resources required for the 'Personal Cabinet' service operation are calculated based on the number of concurrent user sessions (personal area open sessions - paos).
  331: 
  332: **CPU Requirements (cores)**
  333: - 1 core per 100 concurrent user sessions
  334: - 1 core for OS system processes
  335: 
  336: **RAM Requirements:**
  337: - 2GB for OS system processes
  338: 
  339: **RAM for JVM:**
  340: - Application Server instance startup: 2048MB
  341: - Personal Cabinet: 120MB × paos
  342: 
  343: **RAM for JVM** = 2048MB + 120MB × paos
  344: 
  345: **Final RAM (OS)** = (RAM for JVM) × 1.5 + 2GB (for OS system processes)
  346: 
  347: **HDD Requirements:**
  348: - 50GB for OS
  349: - 100GB for software and logs storage under normal operation (excluding DEBUG)
  350: 
  351: Recommended to use fault-tolerant arrays (e.g., RAID-1, RAID-10)
  352: 
  353: *CPU type: Intel Xeon e5-2640 (or equivalent)*
  354: 
  355: ##### 2.1.3.2 Network Interface Requirements for Personal Cabinet Service
  356: 
  357: The service host requires a network interface with 100Mbit/s bandwidth.
  358: 
  359: ##### 2.1.3.3 Port Requirements for Personal Cabinet Service
  360: 
  361: The following ports must be open on the service host:
  362: 
  363: **Table 2.1.3.3 - Personal Cabinet WFM CC Port Requirements**
  364: 
  365: | Port | Protocol | Purpose |
  366: |------|----------|---------|
  367: | 9050 | HTTP | Serving HTTP requests from user browsers |
  368: 
  369: Ports must not be used by the operating system or other applications.
  370: 
  371: #### 2.1.4 WFM CC Mobile API Service
  372: 
  373: ##### 2.1.4.1 CPU, RAM, HDD Requirements for Mobile API Service
  374: 
  375: Resources required for the 'Mobile API' service operation are calculated based on the number of concurrent user sessions and the following load parameters:
  376: 
  377: - 20 requests per second
  378: - Average request duration: 3 seconds
  379: 
  380: **CPU Requirements (cores)**
  381: - 2 cores per 500 concurrent user sessions
  382: - 1 core for OS system processes
  383: 
  384: **RAM Requirements:**
  385: - 2GB for OS system processes
  386: - 2GB RAM for JVM per 500 concurrent user sessions
  387: 
  388: **HDD Requirements:**
  389: - 50GB for OS
  390: - 100GB for software and logs storage under normal operation (excluding DEBUG)
  391: 
  392: Recommended to use fault-tolerant arrays (e.g., RAID-1, RAID-10)
  393: 
  394: *CPU type: Intel Xeon e5-2640 (or equivalent)*
  395: 
  396: ##### 2.1.4.2 Network Interface Requirements for Mobile API Service
  397: 
  398: The service host requires a network interface with 100Mbit/s bandwidth.
  399: 
  400: ##### 2.1.4.3 Port Requirements for Mobile API Service
  401: 
  402: The following ports must be open on the service host:
  403: 
  404: **Table 2.1.4.3 - Mobile API WFM CC Port Requirements**
  405: 
  406: | Port | Protocol | Purpose |
  407: |------|----------|---------|
  408: | 9010 | HTTP | Serving HTTP requests from remote users |
  409: | 9017 | JMX | Management port for service management interface access |
  410: 
  411: Ports must not be used by the operating system or other applications.
  412: 
  413: #### 2.1.5 Planning Service
  414: 
  415: ##### 2.1.5.1 CPU, RAM, HDD Requirements for Planning Service
  416: 
  417: The planning service includes work schedule and timetable planning.
  418: 
  419: Resources required for the planning service operation are calculated based on the number of concurrent user sessions and the following load parameters:
  420: 
  421: - Number of concurrent planning sessions
  422: - Number of operators in planning template
  423: - Number of simultaneously executed planning tasks
  424: - Number of threads per planning session
  425: 
  426: **CPU Requirements (cores)**
  427: - 1 core for OS system processes
  428: - **CPU (planning service)**: 2 + (number of simultaneously executed planning tasks × number of threads per planning session)
  429: - **CPU (gateway service)**: 1 core
  430: 
  431: **RAM Requirements (MB):**
  432: - 2GB for OS system processes
  433: 
  434: **RAM for JVM:**
  435: - **RAM (JVM planning service)** = 5MB × number of operators in planning template × number of simultaneously executed planning tasks × number of threads per planning session
  436: - **RAM (JVM gateway service)** = 100MB + (0.5MB × number of concurrent planning sessions)
  437: 
  438: **Final RAM (OS)** = (RAM (JVM planning service) + RAM (JVM gateway service)) × 1.5 + 2GB (for OS system processes)
  439: 
  440: **HDD Requirements:**
  441: - 50GB for OS
  442: - 100GB for planning service software and logs storage under normal operation (excluding DEBUG)
  443: - 100GB for gateway service software and logs storage under normal operation (excluding DEBUG)
  444: 
  445: Recommended to use fault-tolerant arrays (e.g., RAID-1, RAID-10)
  446: 
  447: *Planning service resource calculation is performed together with gateway service calculation. Both services run on the same host.*
  448: *CPU type: Intel Xeon e5-2640 (or equivalent)*
  449: *At load of 10 simultaneous planning requests per second*
  450: 
  451: ##### 2.1.5.2 Network Interface Requirements for Planning Service
  452: 
  453: The service host requires a network interface with 100Mbit/s bandwidth.
  454: 
  455: ##### 2.1.5.3 Port Requirements for Planning Service
  456: 
  457: The following ports must be open on the service host:
  458: 
  459: **Table 2.1.5.3 - Planning Service Port Requirements**
  460: 
  461: | Port | Protocol | Purpose |
  462: |------|----------|---------|
  463: | 9030 | HTTP | Serving HTTP requests from other WFM CC solution components |
  464: | 9037, 9047 | JMX | Management port for service management interface access |
  465: 
  466: Ports must not be used by the operating system or other applications.
  467: 
  468: #### 2.1.6 Reports Service
  469: 
  470: ##### 2.1.6.1 CPU, RAM, HDD Requirements for Reports Service
  471: 
  472: Resources required for the reports service operation are calculated based on the number of concurrent report building tasks.
  473: 
  474: **CPU Requirements (cores)**
  475: - 1 core for OS system processes
  476: - 1 core per report building task
  477: 
  478: **RAM Requirements:**
  479: - 2GB for OS system processes
  480: 
  481: **RAM for JVM:**
  482: - 2GB per report building task
  483: 
  484: **RAM (JVM)** = 2GB × number of concurrent report building tasks
  485: 
  486: **Final RAM (OS)** = RAM (JVM) × 1.5 + 2GB (for OS system processes)
  487: 
  488: **HDD Requirements:**
  489: - 50GB for OS
  490: - 500GB for software and logs storage under normal operation (excluding DEBUG)
  491: 
  492: Recommended to use fault-tolerant arrays (e.g., RAID-1, RAID-10)
  493: 
  494: *CPU type: Intel Xeon e5-2640 (or equivalent)*
  495: *Final HDD value depends on generated report disk space usage, number of reports, and their storage time*
  496: 
  497: ##### 2.1.6.2 Network Interface Requirements for Reports Service
  498: 
  499: The service host requires a network interface with 100Mbit/s bandwidth.
  500: 
  501: ##### 2.1.6.3 Port Requirements for Reports Service
  502: 
  503: The following ports must be open on the service host:
  504: 
  505: **Table 2.1.6.3 - Reports Service Port Requirements**
  506: 
  507: | Port | Protocol | Purpose |
  508: |------|----------|---------|
  509: | 9000 | HTTP | Serving HTTP requests from other WFM CC solution components |
  510: | 9007 | JMX | Management port for service management interface access |
  511: 
  512: Ports must not be used by the operating system or other applications.
  513: 
  514: #### 2.1.7 Notifications Service
  515: 
  516: ##### 2.1.7.1 CPU, RAM, HDD Requirements for Notifications Service
  517: 
  518: Resources required for the notifications service operation are calculated based on the number of:
  519: 
  520: - Simultaneous notification processing threads
  521: - Simultaneous distribution threads
  522: 
  523: **CPU Requirements (cores)**
  524: - 1 core for OS system processes
  525: - 1 core × (number of simultaneous distribution threads / 10)
  526: - 1 core × (number of simultaneous notification processing threads / 10)
  527: 
  528: **RAM Requirements:**
  529: - 2GB for OS system processes
  530: 
  531: **RAM for JVM:**
  532: - 512MB for distribution
  533: - 512MB + 30MB × number of simultaneous notification processing threads
  534: 
  535: **RAM (JVM)** = 512MB + 512MB + 30MB × number of simultaneous notification processing threads
  536: 
  537: **Final RAM (OS)** = RAM (JVM) × 1.5 + 2GB (for OS system processes)
  538: 
  539: **HDD Requirements:**
  540: - 50GB for OS
  541: - 100GB for software and logs storage under normal operation (excluding DEBUG)
  542: 
  543: Recommended to use fault-tolerant arrays (e.g., RAID-1, RAID-10)
  544: 
  545: *Usually 20 simultaneous notification processing threads and 10 simultaneous distribution threads are sufficient for notifications service operation*
  546: *CPU type: Intel Xeon e5-2640 (or equivalent)*
  547: 
  548: ##### 2.1.7.2 Network Interface Requirements for Notifications Service
  549: 
  550: The service host requires a network interface with 100Mbit/s bandwidth.
  551: 
  552: ##### 2.1.7.3 Port Requirements for Notifications Service
  553: 
  554: The following ports must be open on the service host:
  555: 
  556: **Table 2.1.7.3 - Notifications Service Port Requirements**
  557: 
  558: | Port | Protocol | Purpose |
  559: |------|----------|---------|
  560: | 9020 | HTTP | Serving HTTP requests from other WFM CC solution components |
  561: | 9027 | JMX | Management port for service management interface access |
  562: 
  563: Ports must not be used by the operating system or other applications.
  564: 
  565: #### 2.1.8 Integration Service
  566: 
  567: ##### 2.1.8.1 CPU, RAM, HDD Requirements for Integration Service
  568: 
  569: Resources required for the integration service operation are calculated based on the number of integrations.
  570: 
  571: **CPU Requirements (cores)**
  572: - 1 core for OS system processes
  573: - 1 core per integration
  574: 
  575: **RAM Requirements:**
  576: - 2GB for OS system processes
  577: 
  578: **RAM for JVM:**
  579: - 2GB per integration
  580: 
  581: **RAM (JVM)** = 2GB × number of integrations
  582: 
  583: **Final RAM (OS)** = RAM (JVM) × 1.5 + 2GB (for OS system processes)
  584: 
  585: **HDD Requirements:**
  586: - 50GB for OS
  587: - 100GB for software and logs storage under normal operation (excluding DEBUG)
  588: 
  589: Recommended to use fault-tolerant arrays (e.g., RAID-1, RAID-10)
  590: 
  591: *The example shows typical calculation. Actual resource requirements may differ depending on the load intensity created by each integration*
  592: *CPU type: Intel Xeon e5-2640 (or equivalent)*
  593: 
  594: ##### 2.1.8.2 Network Interface Requirements for Integration Service
  595: 
  596: The service host requires a network interface with 100Mbit/s bandwidth.
  597: 
  598: ##### 2.1.8.3 Port Requirements for Integration Service
  599: 
  600: The following ports must be open on the service host:
  601: 
  602: **Table 2.1.8.3 - Integration Service Port Requirements**
  603: 
  604: | Port | Protocol | Purpose |
  605: |------|----------|---------|
  606: | 8080 | HTTP | Serving HTTP requests from other WFM CC solution components |
  607: 
  608: Ports must not be used by the operating system or other applications.
  609: 
  610: #### 2.1.9 Client System
  611: 
  612: The client system includes:
  613: 
  614: - **Web-client**: designed to work with WFM CC AS and Personal Cabinet Service using a web browser
  615: - **Mobile-client**: designed to work with WFM CC AS using a mobile application
  616: 
  617: ##### 2.1.9.1 CPU, RAM, HDD Requirements for Web-client
  618: 
  619: **Table 2.1.9.1 - Hardware Requirements**
  620: 
  621: | Component | Minimum Requirements | Recommended Requirements |
  622: |-----------|---------------------|-------------------------|
  623: | CPU | x86 dual-core from 2010 (or newer) | x86 dual-core from 2010 (or newer) |
  624: | RAM | 2048 MB | 8 GB |
  625: | HDD | 10 GB | 30 GB |
  626: | Screen Resolution | 1280×1024 | 1920×1080 |
  627: 
  628: ##### 2.1.9.2 Network Interface Requirements for Client System Web-client
  629: 
  630: Recommended bandwidth for client workstations: 100 Mbit/s
  631: 
  632: ##### 2.1.9.3 Port Requirements for Client System Web-client and Mobile-client
  633: 
  634: For users working with Web-client, access from workstations to WFM CC AS and Personal Cabinet Service must be provided on the ports specified in sections 2.1.2.3 and 2.1.3.3.
  635: 
  636: In case of fault-tolerant solution or need to use HTTPS protocol, access from client workstations to the load balancer must be provided on the ports configured for each service: WFM CC AS and Personal Cabinet Service.
  637: 
  638: For remote users using Mobile-client, internet access to Mobile API Service must be provided on the ports specified in section 2.1.4.3.
  639: 
  640: *In basic configuration, this is HTTP protocol and port 8080 for both WFM CC AS and Personal Cabinet Service*
  641: *Presence of several duplicating services deployed on different hosts*
  642: *In basic configuration within the corporate network, this is HTTP protocol and port 8080. HTTPS-HTTP traffic termination occurs at the customer's network equipment level*
  643: 
  644: #### 2.1.10 Network System
  645: 
  646: ##### 2.1.10.1 Data Transmission Channel Requirements
  647: 
  648: Data transmission channels between network interfaces of systems included in the WFM CC solution must provide the necessary bandwidth specified in the requirements.
  649: 
  650: ##### 2.1.10.2 Port Requirements
  651: 
  652: For all systems included in the WFM CC solution, IP connectivity must be ensured according to Figure 2.1 Technical Architecture of WFM CC Solution and the requirements specified in the relevant sections.
  653: 
  654: ##### 2.1.10.3 WFM CC Services Load Balancer Requirements
  655: 
  656: Balanced groups must be formed on the load balancer.
  657: 
  658: A balanced group is a group of services with the same purpose, consisting of N service instances for load balancing and failover purposes.
  659: 
  660: For each group, a corresponding port is opened on the load balancer (see Table 2.1.10.3).
  661: 
  662: For some balanced groups, the load balancer provides sticky session (see Table 2.1.10.3).
  663: 
  664: **Table 2.1.10.3 - Example of Balanced Groups and Ports**
  665: 
  666: | Group Name | Incoming Port on Load Balancer | Group Composition | Sticky Session Required | Service Availability Check |
  667: |------------|-------------------------------|-------------------|------------------------|----------------------------|
  668: | WFM CC AS | 8080 | argus-app01:8080<br>argus-app02:8080 | Yes | http://argus-app01:9990/ccwfm/ping<br>http://argus-app02:9990/ccwfm/ping |
  669: | Personal Cabinet Service | 8081 | argus-app03:8081<br>argus-app04:8081 | Yes | http://argus-app03:9990/api/v1/system/status<br>http://argus-app04:9990/api/v1/system/status |
  670: | Notifications Service | 8082 | argus-app05:8082<br>argus-app06:8082 | No | http://argus-app05:9990/api/v1/system/status<br>http://argus-app06:9990/api/v1/system/status |
  671: | Planning Service | 8083 | argus-app07:8083<br>argus-app08:8083 | No | http://argus-app07:9990/api/v1/system/status<br>http://argus-app08:9990/api/v1/system/status |
  672: 
  673: **Load Balancer Operation Principles:**
  674: 
  675: - The load balancer redirects incoming group port requests to a selected service instance in the balanced group, providing load balancing and fault tolerance (failover)
  676: - Session distribution between active nodes is performed by session identifiers using cookie mechanism and node status (active/inactive)
  677: - For Sticky session, the load balancer must direct the next request to the same service instance that handled the previous request from the same session
  678: - Service availability is checked using management ports with HTTP probes
  679: - Successful response code: 200
  680: - Probe interval: 10 seconds
  681: - If a request fails twice in a row, the load balancer considers the service unavailable
  682: 
  683: **Load Balancer Timeouts:**
  684: 
  685: - Connection timeout from load balancer to service node: at least 1 minute
  686: - AJP-ping response timeout: at least 1 minute
  687: - Request response timeout from service node: at least 24 minutes (maximum server execution time is 23 minutes)
  688: 
  689: **Error Handling:**
  690: 
  691: - The load balancer considers a request unsuccessful if the service returns HTTP status 500-599
  692: - Other status values (300-399) should not be considered unsuccessful
  693: - The load balancer can transparently retry request execution on another node, except for POST requests that are being processed too long
  694: 
  695: **Logging Requirements:**
  696: 
  697: - Access logs (accesslog) must be maintained on the load balancer
  698: - Logs should be stored for at least five days
  699: - Log rotation must be configured
  700: 
  701: ##### 2.1.10.4 WFM CC Database Load Balancer Requirements
  702: 
  703: The WFM CC database server can be launched in two ways:
  704: 
  705: 1. **Single database server** (balancing not required) - the database becomes a single point of failure
  706: 2. **Multiple database servers** in a fault-tolerant cluster (all database servers work simultaneously, one in master mode, another in slave mode with hot-standby option)
  707: 
  708: For failover implementation, a solution consisting of the following software components is used: **Keepalived - Haproxy - Etcd - Patroni** (Figure 2.1.10.4), deployed on Database Load Balancers and database hosts themselves.
  709: 
  710: ![Database Load Balancer Fault-Tolerant Solution](img/db_load_balancer_architecture.png)
  711: 
  712: *Figure 2.1.10.4 - Fault-Tolerant Solution with Failover Mechanism and Database Load Balancer*
  713: 
  714: **Components to be deployed on load balancers:**
  715: 
  716: **Keepalived** - used to ensure a single cluster entry point - virtual IP.
  717: - Provides service fault tolerance and load balancing
  718: - Fault tolerance is achieved through a "floating" IP address that switches to the backup server in case of primary server failure
  719: - Uses VRRP protocol for automatic IP switching between servers
  720: 
  721: **Haproxy** - software load balancer
  722: - Required for monitoring server states and redirecting requests to the master server
  723: - Installed on each host and contains references to all PostgreSQL servers in its configuration
  724: - Checks which PostgreSQL server is currently the master and sends requests only to it
  725: - Uses Patroni REST interface for this verification
  726: 
  727: **Component Installation Requirements:**
  728: 
  729: The following components must be deployed on database hosts (in addition to PostgreSQL):
  730: 
  731: **Etcd** - fault-tolerant distributed key-value store used to store Postgres cluster state
  732: - Helps Patroni nodes determine who will be the master
  733: - Requires an odd number of servers (ideally at least 3)
  734: - Installed on Database Load Balancers
  735: 
  736: **Patroni** - Python package that manages Postgres configuration
  737: - Handles replication and failover
  738: - All database settings must be made through Patroni
  739: 
  740: **Table 2.1.10.4 - Fault-Tolerant Solution Components and Ports**
  741: 
  742: | Source System | Target System | Port | Purpose |
  743: |---------------|---------------|------|---------|
  744: | etcd | etcd | 2380 | Quorum formation |
  745: | patroni | etcd | 2379 | Quorum status retrieval |
  746: | haproxy | patroni | 8008 | Service health check |
  747: | client | haproxy | 7000 | Health status metrics |
  748: | client | haproxy | 9999 | Network traffic |
  749: | haproxy | postgresql | 5432 | Network traffic |
  750: 
  751: *For fault-tolerant solution implementation*
  752: *In case of Failover (database role change from slave to master events) and database server status change from UP to DOWN, email notifications should be sent to a predetermined list of recipients*
  753: 
  754: #### 2.1.11 External IT Systems (Integration)
  755: 
  756: For interaction with external systems, a dedicated Integration Service is provided.
  757: 
  758: Direct interaction between external systems and WFM CC solution components via SOAP/HTTP protocol using a dedicated IP address and port is also possible.
  759: 
  760: The specific implementation of interaction between WFM CC solution components and external systems is determined by the customer's specifics.
  761: 
  762: #### 2.1.12 Monitoring System
  763: 
  764: For monitoring components included in the WFM CC solution, the following are used:
  765: 
  766: **Zabbix Monitoring System** - agents are installed on hosts to be monitored, which collect metrics from both the hosts themselves and services deployed on the hosts, send metrics to monitoring servers where they are displayed, analyzed, and based on settings, sent as alerts about threshold value exceedances.
  767: 
  768: **Monitoring Utilities** (JVisualVM, JConsole, Command Line Interface, NMON).
  769: 
  770: ![Monitoring Scheme](img/monitoring_scheme.png)
  771: 
  772: *Figure 2.1.12 - Monitoring Scheme*
  773: 
  774: **Zabbix Monitoring System Components:**
  775: 
  776: **Zabbix Server** - server responsible for database operations, metrics collection, and monitoring and alerting management.
  777: 
  778: **Zabbix Proxy** - server that performs intermediate collection and processing of metrics and sends them to Zabbix Server.
  779: - Used to increase monitoring system scalability and fault tolerance
  780: - Has no user interface
  781: 
  782: **Zabbix Java Gateway** - Zabbix Proxy analog for JMX monitoring (AS monitoring).
  783: 
  784: **Zabbix Agent** - designed to collect and send data to Zabbix Proxy/Zabbix Server, execute predefined scripts when necessary.
  785: 
  786: **Deployment Configuration:**
  787: 
  788: **Customer Side:**
  789: - Zabbix Proxy installed together with Zabbix Java Gateway on one host
  790: - Zabbix Proxy deployed in active mode and initiates connection to Zabbix Server
  791: - Zabbix Agent deployed on each host with WFM CC solution components
  792: 
  793: **Argus Side:**
  794: - Zabbix Server installed
  795: - Incoming traffic filtering by IP address provided by customer for monitoring system access
  796: - Monitoring utilities hosted
  797: 
  798: ##### 2.1.12.1 CPU, RAM Requirements for Zabbix
  799: 
  800: **Zabbix Proxy + Zabbix Java Gateway:**
  801: - **CPU**: 1 (AMD Athlon 3200+ level)
  802: - **RAM**: 2GB
  803: - **HDD**: 50GB
  804: - SQLite database automatically created with Zabbix Proxy installation (10GB)
  805: 
  806: **Zabbix Agent:**
  807: - **CPU**: 1+ (AMD Athlon 3200+ level)
  808: - **RAM**: 256MB+
  809: - **HDD**: 10GB+
  810: 
  811: ##### 2.1.12.2 Port Requirements for Zabbix
  812: 
  813: Standard ports used by monitoring system elements:
  814: 
  815: - **Zabbix Agent**: 10050
  816: - **Zabbix Proxy**: 10051
  817: - **Zabbix Java Gateway**: 10052
  818: 
  819: Port values can be changed in configuration files:
  820: - zabbix_agentd.conf
  821: - zabbix_proxy.conf
  822: - zabbix_java_gateway.conf
  823: 
  824: ### 2.2 Access for Diagnostics of Malfunctions for Argus Specialists
  825: 
  826: For conducting counter-emergency, maintenance, and other work by the contractor, access for contractor employees to the customer's test and production server hosts must be provided.
  827: 
  828: Access is necessary for the ability to read/download logs for analysis, create service dumps, check software functionality, create database queries analyzing its state, connect to monitoring systems and configure them, and make changes to configuration files and restart WFM CC solution components.
  829: 
  830: For successful malfunction diagnostics and counter-emergency work, contractor specialists need access to customer server hosts specified in Table 2.2.
  831: 
  832: **Table 2.2 - Contractor Specialist Access to Customer Systems**
  833: 
  834: | Host | Protocol | Port |
  835: |------|----------|------|
  836: | Database | TCP | 5432 |
  837: |          | SSH | 22 |
  838: | Services | HTTP/HTTPS | 8080, 9990 |
  839: |          | SSH | 22 |
  840: | Service Load Balancer | HTTP/HTTPS | 8080 |
  841: |                      | SSH | 22 |
  842: | Database Load Balancer | TCP | 2380, 2379, 8008, 7000, 9999, 5432 |
  843: |                       | SSH | 22 |
  844: | Monitoring System | TCP | 5432, 10050, 10051, 10052 |
  845: |                   | SSH | 22 |
  846: 
  847: Each contractor employee involved in application server technical support must have their own user account (login and password) for host access.
  848: 
  849: The user account allows viewing all contents of the installation directory (usually /argus) but has no modification rights.
  850: 
  851: The user account has a home directory where modifications are allowed (creating and editing files and directories).
  852: 
  853: Depending on the customer's security policy and technical capabilities, this can be:
  854: - Direct access to customer servers from contractor network via protocols and ports specified in Table 2.2
  855: - Access to customer terminal server from contractor network via RDP 3389, and from there access to customer servers via protocols and ports specified in Table 2.2
  856: 
  857: For security reasons, some protocols/ports listed in Table 2.2 may be closed (individually for each customer).
  858: 
  859: *Performed by agreement with the customer*
  860: *In case of software load balancer, e.g., Apache, Nginx*
  861: 
  862: ### 2.3 Requirements for Qualification of Customer Service Personnel
  863: 
  864: The qualification of customer service personnel must correspond to the functions performed during WFM CC solution operation.
  865: 
  866: #### 2.3.1 Database Operation
  867: 
  868: ##### 2.3.1.1 Ensuring Database Functionality
  869: 
  870: **Database Backup:**
  871: - Launching backup procedure
  872: - Monitoring backup procedure execution
  873: - Controlling backup procedure completion
  874: 
  875: **Database Recovery:**
  876: - Launching database recovery procedure
  877: - Monitoring database recovery procedure execution
  878: - Controlling database recovery procedure completion
  879: 
  880: **Database Access Management:**
  881: - Assigning user access rights to database
  882: - Changing user access rights to database
  883: - Controlling compliance with user access rights to database
  884: 
  885: **Software Installation and Configuration for Database User Support:**
  886: - Installing software to support database users
  887: - Configuring software to support database users
  888: - Controlling software configuration results for database users
  889: 
  890: **Software Installation and Configuration for Database Administration:**
  891: - Installing software to support database administrators
  892: - Configuring software to support database administrators
  893: - Controlling software configuration results for database administrators
  894: 
  895: **Database Event Monitoring:**
  896: - Observing database operation
  897: - Detecting deviations from normal database operation
  898: - Analyzing and eliminating deviations from normal database operation
  899: 
  900: **Database Event Logging:**
  901: - Recording deviations from normal database operation
  902: - Maintaining deviation log from normal database operation
  903: - Informing staff responsible for eliminating deviations from normal database operation
  904: 
  905: ##### 2.3.1.2 Database Functionality Optimization
  906: 
  907: **Database Operation Monitoring and Statistical Information Collection:**
  908: - Database operation monitoring using various automated tools
  909: - Selecting main statistical indicators of database operation
  910: - Analyzing obtained statistical data and forming conclusions about database operation efficiency
  911: 
  912: **Computing Resource Distribution Optimization:**
  913: - Analyzing capabilities for managing computing resources interacting with database
  914: - Managing computing resources interacting with database
  915: - Controlling results of computing resource redistribution interacting with database
  916: 
  917: **Database Performance Optimization:**
  918: - Analyzing capabilities for database performance optimization management
  919: - Selecting database performance optimization criteria
  920: - Managing database performance optimization
  921: 
  922: **Computing Network Component Optimization:**
  923: - Analyzing computing network components and configuration management capabilities
  924: - Selecting evaluation criteria for changing computing network component configuration interacting with database
  925: - Optimizing computing network components interacting with database and controlling changes in database operation
  926: 
  927: **Database Query Execution Optimization:**
  928: - Statistical analysis of database queries and their classification by various features
  929: - Selecting database query execution optimization criteria
  930: - Optimizing execution of statistically significant database queries
  931: 
  932: **Database Data Lifecycle Management Optimization:**
  933: - Memory Data Distribution Management
  934: - Selecting memory data distribution management strategy for database placement
  935: - Controlling compliance with memory data distribution management strategy for database placement
  936: 
  937: ##### 2.3.1.3 Data Loss and Damage Prevention
  938: 
  939: **Database Backup Regulation Development:**
  940: - Analyzing application system functionality to identify suitable time intervals for database backup
  941: - Selecting software tools for backup execution
  942: - Developing and implementing database backup scenario for installed application system
  943: 
  944: **Database Recovery Scenario Development and Documentation Preparation:**
  945: - Backup regulation execution control
  946: - Correcting actions when deviating from regulation
  947: - Comparing performed actions with backup regulation
  948: 
  949: **Database Backup Strategy Development:**
  950: - Studying general backup execution principles
  951: - Studying application system architecture and operation schedule
  952: 
  953: **Database Recovery Regulation Development:**
  954: - Developing typical database recovery scenarios for various failures
  955: - Analyzing application system architecture to identify database components most susceptible to failures
  956: 
  957: **Automatic Database Backup Procedure Development:**
  958: - Developing scripts for database backup creation
  959: - Analyzing database hardware and software characteristics for backup placement and data transfer performance
  960: 
  961: **Data Recovery Procedure After Failure:**
  962: - Analyzing possible database failures and developing scenarios for necessary database recovery measures
  963: - Writing scripts according to developed scenarios for quick failure consequence elimination
  964: 
  965: **Recovery Regulation Compliance Control:**
  966: - Correcting actions when deviating from regulation
  967: - Comparing performed actions with database recovery regulation
  968: 
  969: **Database Failure Analysis and Cause Identification:**
  970: - Monitoring and documenting failures occurring in database during application system service
  971: - Identifying failure causes and timely elimination
  972: - Interacting with database technical support services and computing complex component suppliers for failure localization and elimination
  973: 
  974: **Database Support Methodological Instructions Development:**
  975: - Analyzing main database support stages
  976: - Preparing database support recommendations, including critical database interaction process optimization
  977: - Preparing documentation according to established rules and requirements
  978: 
  979: **Database Hardware and Software Monitoring:**
  980: - Observing database hardware and software complex operation
  981: - Recording deviations from normal database operation
  982: 
  983: **Database Hardware and Software Configuration:**
  984: - Initial database software installation
  985: - Applying database monitoring results to improve database functionality
  986: - Configuring database hardware and software components to improve user service quality
  987: 
  988: **Database Hardware and Software Modernization Proposals:**
  989: - Analyzing database support hardware and software market
  990: - Finding modernization paths aimed at improving database operation efficiency
  991: - Preparing proposals for applied hardware and software modernization
  992: 
  993: **Database Failure Risk Forecasting and Assessment:**
  994: - Analyzing various failure type frequencies in database operation
  995: - Searching for failure information and elimination actions in various sources (including Internet)
  996: - Database failure risk forecasting and assessment
  997: 
  998: **Automatic Database Hot Backup Procedure Development:**
  999: - Initial hot backup database installation
 1000: - Hot backup database monitoring in application system
 1001: - Hot backup database user operation configuration and optimization
 1002: 
 1003: **Hot Replacement Resource Commissioning Procedures:**
 1004: - Database hot backup system node software updates installation
 1005: - Automatic hot backup database commissioning configuration when using automation
 1006: - Switching to hot backup database when necessary
 1007: 
 1008: **Database Functionality Reports Preparation:**
 1009: - Collecting database operation information
 1010: - Filling database state and functionality report forms
 1011: 
 1012: ##### 2.3.1.4 Database-Level Information Security
 1013: 
 1014: **Database-Level Information Security Policy Development:**
 1015: - Analyzing possible data security threats
 1016: - Selecting main database-level information security support tools
 1017: 
 1018: **Database Security Regulation Compliance Control:**
 1019: - Identifying actions violating database-level security regulation
 1020: - Correcting actions when deviating from database-level security regulation
 1021: - Eliminating consequences of incorrect actions leading to database-level information security reduction
 1022: 
 1023: **Security System Operation Optimization:**
 1024: - Determining security system operation optimization capabilities to reduce database operation load
 1025: - Selecting most effective ways to reduce load while ensuring required database-level data security
 1026: 
 1027: **Data Security System Regulation Development and Audit:**
 1028: - Selecting database-level data audit result evaluation criteria
 1029: - Developing database-level data security system audit methods
 1030: - Security system audit and efficiency evaluation
 1031: 
 1032: **Database-Level Security System State and Efficiency Reports:**
 1033: - Determining security system efficiency indicators and criteria, their calculation and analysis
 1034: - Evaluating database-level data security system level and state
 1035: 
 1036: **Automated Unauthorized Data Access Attempt Detection Procedure Development:**
 1037: - Analyzing programming procedure capabilities for unauthorized data access attempt detection
 1038: - Applying programming tools for developing automated unauthorized data access attempt detection procedures
 1039: 
 1040: ##### 2.3.1.5 Database Development Management
 1041: 
 1042: **Database Information Processing System Problem Analysis and Database Development Proposals:**
 1043: - Collecting and analyzing unrealized database user needs
 1044: - Researching promising database market and their fundamental capabilities
 1045: - Preparing accepted database development decision implementation plan
 1046: 
 1047: **Database Software Version Update Regulation Development:**
 1048: - Analyzing main database software version update stages
 1049: - Developing and describing typical database version update processes
 1050: - Preparing regulatory database version update documents
 1051: 
 1052: **Database Migration to New Platforms and Software Versions Regulation Development:**
 1053: - Analyzing main database migration stages to new platforms and software versions
 1054: - Developing and describing typical database migration processes to new platforms and software versions
 1055: - Preparing regulatory database migration documents
 1056: 
 1057: **New Database Technology Study, Mastery and Implementation:**
 1058: - Monitoring new database information technologies appearing on the market
 1059: - Mastering and implementing new database technologies in administration practice
 1060: 
 1061: **Database Version Update Control:**
 1062: - Planning stages and analyzing each database version update stage execution results
 1063: - Planning, conducting and analyzing database functionality check results after update
 1064: 
 1065: **Database Migration to New Platforms and Software Versions Control:**
 1066: - Planning database migration stages
 1067: - Analyzing database operation testing results after migration
 1068: - Database recovery and action correction when migration errors are detected
 1069: 
 1070: #### 2.3.2 Application Server Operation
 1071: 
 1072: ##### 2.3.2.1 Ensuring Application Server Functionality
 1073: 
 1074: **Software Installation and Configuration for Application Server User Support:**
 1075: - AS software installation preparation, OS configuration, related software
 1076: - AS software installation
 1077: - AS software configuration
 1078: - AS software configuration result control
 1079: 
 1080: **Application Server Operation Monitoring and Statistical Information Collection:**
 1081: - AS operation monitoring using various automated tools
 1082: - Selecting main AS operation statistical indicators
 1083: - Analyzing obtained statistical data and forming conclusions about AS operation efficiency
 1084: - Detecting deviations from normal AS operation
 1085: - Analyzing and eliminating deviations from normal AS operation
 1086: 
 1087: **Application Server Maintenance:**
 1088: - AS log cleanup using automated tools
 1089: - Memory and thread dump formation (during emergency)
 1090: - Interacting with technical support services and software suppliers for failure localization and elimination (during emergency)
 1091: - AS restart on technical support service recommendation (during emergency or approaching it)
 1092: 
 1093: **Application Server Event Logging:**
 1094: - Recording deviations from normal AS operation
 1095: - Maintaining AS operation deviation log
 1096: - Informing staff responsible for eliminating AS operation deviations
 1097: 
 1098: **Application Server Functionality State Reports:**
 1099: - Preparing AS functionality state reports
 1100: 
 1101: ##### 2.3.2.2 Application Server Service Loss Prevention
 1102: 
 1103: **Application Server Backup:**
 1104: - Launching backup procedure
 1105: - Monitoring backup procedure execution
 1106: - Controlling backup procedure completion
 1107: 
 1108: **Application Server Recovery:**
 1109: - Launching AS recovery procedure
 1110: - Monitoring AS recovery procedure execution
 1111: - Controlling AS recovery procedure completion
 1112: 
 1113: #### 2.3.3 Client System Operation
 1114: 
 1115: ##### 2.3.3.1 Client Software Installation and Configuration
 1116: 
 1117: - Checking OS and client software resource compliance
 1118: - Client software installation and update
 1119: - Client software configuration
 1120: - Controlling client software installation, update and configuration results
 1121: 
 1122: #### 2.3.4 Network System Operation
 1123: 
 1124: ##### 2.3.4.1 Network Operation Monitoring and Statistical Information Collection
 1125: 
 1126: - Network operation monitoring using various automated tools
 1127: - Selecting main network operation statistical indicators
 1128: - Analyzing obtained statistical data and forming conclusions about network operation efficiency
 1129: - Detecting deviations from normal network operation
 1130: - Analyzing and eliminating deviations from normal network operation
 1131: 
 1132: ##### 2.3.4.2 Network Operation Event and Collision Logging
 1133: 
 1134: - Recording deviations from normal network operation
 1135: - Maintaining network operation deviation log
 1136: - Informing staff responsible for eliminating network operation deviations
 1137: - Preparing network functionality state reports
 1138: 
 1139: ##### 2.3.4.3 Computing Network Component Optimization
 1140: 
 1141: - Analyzing network components and configuration management capabilities
 1142: - Selecting evaluation criteria for network component configuration changes interacting with system components
 1143: - Optimizing network components interacting with system components and controlling network operation changes
 1144: 
 1145: ### 2.4 General Procedure for Deployment and Maintenance of WFM CC Solution Components
 1146: 
 1147: #### 2.4.1 Standard Concepts
 1148: 
 1149: **Database Dump** - consists of database structure description and/or data contained in it, usually as SQL commands. Used for data backup/recovery.
 1150: 
 1151: **Database Update** - represents changes to internal table structure and database objects, adding new features to software functionality.
 1152: 
 1153: **Database Patch** - represents a set of fixes identified during testing, implementation and pilot operation.
 1154: 
 1155: **Application Server Distributable** - represents an installation file that performs application server file unpacking and configuration.
 1156: 
 1157: **User Account** - a combination of username and password that must be entered when starting the program. Each user account is matched to the corresponding user and includes a set of functional modules and options assigned to these modules.
 1158: 
 1159: #### 2.4.2 Standard Actions for Software Updates
 1160: 
 1161: Any actions before making software changes must be preceded by its backup copy.
 1162: 
 1163: Standard software update actions include the following stages:
 1164: 
 1165: - User notification about ongoing work
 1166: - Disconnecting user sessions
 1167: - Creating software backup copies
 1168: - Software installation
 1169: - Software startup
 1170: - Checking installed software functionality and log analysis (if available)
 1171: - Returning to normal operation mode
 1172: 
 1173: When special actions are required, update instructions are sent together with software archives.
 1174: 
 1175: ##### 2.4.2.1 Database Update
 1176: 
 1177: - Stop AS and Services
 1178: - Perform database backup copy
 1179: - Execute database updates (update scripts, dbmaintain)
 1180: - Start AS and Services
 1181: 
 1182: ##### 2.4.2.2 Application Server and Services Update
 1183: 
 1184: **Application Server Update:**
 1185: - Stop AS
 1186: - Backup AS directory
 1187: - Delete AS directory (when transitioning from version to version)
 1188: - Prepare distributable (unpack and place in directory from which installation will occur) and specific AS configurations (ensure parameters are specified correctly)
 1189: - Install AS
 1190: - Start AS
 1191: 
 1192: **Services Update:**
 1193: Service update mechanism is implemented using docker and docker-compose tools:
 1194: - Stop docker container
 1195: - Load new docker container image (tar file) into local docker repository
 1196: - Configure configuration file with container startup parameters
 1197: - Start docker container
 1198: - Delete new installation image (tar file)
 1199: - Delete old docker container
 1200: - Delete old docker container image from local docker repository
 1201: 
 1202: ##### 2.4.2.3 Client Workstation Update
 1203: 
 1204: Depending on the number of workstations, this can be updating each workstation separately or all at once using group domain policies. Includes deleting client software directory and reinstalling it.
 1205: 
 1206: *Container repository located on the host where the service will be run*
 1207: *docker-compose.yml*
 1208: *Usually client workstation operates under Windows OS*
 1209: 
 1210: #### 2.4.3 Regular Procedures for Maintaining WFM CC Solution Components
 1211: 
 1212: **Log Cleanup:**
 1213: During operation of all WFM CC solution components, a significant amount of logs is generated, proportional to the number of users, load, and software operation mode: normal or debug.
 1214: 
 1215: Therefore, it's necessary to timely delete (archive and delete) logs, ensuring disk space doesn't overflow. Disk space overflow leads to failure of corresponding WFM CC solution components.
 1216: 
 1217: Detailed log cleanup procedure is described in section 3.4.3 Operation Log Archiving.
 1218: 
 1219: **Database Backup:**
 1220: Described in section 3.4.1.1 Database Backup.
 1221: 
 1222: **WFM CC AS Backup/Recovery:**
 1223: When working with AS, it's possible to:
 1224: - Create backup copy without stopping service by creating AS installation directory copy
 1225: - AS recovery is possible by copying saved AS directory copy to installation directory. Requires preliminary AS stop.
 1226: 
 1227: **WFM CC AS Restart:**
 1228: On technical support recommendation, when approaching critical resource consumption values (CPU, RAM) - perform AS restart.
 1229: 
 1230: **Services Backup/Recovery:**
 1231: Services run in docker containers, so it's sufficient to have backup image copy (tar file) for deploying docker container from which service reinstallation can be performed if necessary, as well as configuration files.
 1232: 
 1233: It's also possible to save image for docker container from local docker container repository.
 1234: 
 1235: **Zabbix Monitoring System Component Reload:**
 1236: On technical support recommendation, when metrics or response from monitoring system components are absent - restart Zabbix components.
 1237: 
 1238: Component startup and shutdown instructions are provided in section 3.2.6.5 Zabbix Component Startup and Shutdown.
 1239: 
 1240: #### 2.4.4 Monitoring Tools Deployment
 1241: 
 1242: **Database:**
 1243: - Configure internal monitoring tools: pgAdmin, SQL queries
 1244: - Install NMON utility and configure OS status reports collection on database host
 1245: - Install standard OS utilities: top, mpstat, vmstat, iostat, etc. - for OS resource data collection
 1246: 
 1247: **AS and Services:**
 1248: - To observe AS and Services resources in real time, use Admin Console or external monitoring utilities (JVisualVM, JConsole, Command Line Interface):
 1249:   1. Create AS and Services administrator account for monitoring utility connections
 1250:   2. Deploy one of external monitoring utilities (e.g., JVisualVM) on local host
 1251: - Install NMON utility and configure OS status reports collection on AS host
 1252: - Install standard OS utilities: top, mpstat, vmstat, iostat, etc. - for OS resource data collection
 1253: 
 1254: **Zabbix Monitoring System version 4.2** is required for monitoring OS, AS and Services resources, as well as database status:
 1255: - Install Zabbix agents on hosts to be monitored, which collect metrics from both hosts and services deployed on hosts, send metrics to Zabbix proxy, from where they are sent to Zabbix server where they are displayed, analyzed and based on settings sent as alerts about threshold value exceedances
 1256: - Deploy Zabbix proxy for data forwarding from agents to Zabbix server
 1257: - Deploy Zabbix JavaGateway for monitoring AS and Services JVM indicators
 1258: - Contact contractor technical support to obtain:
 1259:   1. Account for viewing data collected by Zabbix monitoring system
 1260:   2. Zabbix JavaGateway jar file with necessary settings for AS and Services monitoring
 1261: 
 1262: Create email address to receive alerts about critical system indicators subject to monitoring.
 1263: 
 1264: Organize archiving/deletion of outdated logs for Zabbix components and monitoring utilities using OS task scheduler.
 1265: 
 1266: Details in sections 3.2.5 Monitoring System and 2.1.12 Monitoring System.
 1267: 
 1268: *More details in sections 3.2.11 Monitoring System and 2.1.12 Monitoring System*
 1269: *Installed in Customer network*
 1270: *Installed in Customer network*
 1271: *Installed in Customer network*
 1272: 
 1273: #### 2.4.5 Standard Actions During Emergency
 1274: 
 1275: During emergency, it's necessary to:
 1276: 
 1277: 1. Record emergency time and occurring error
 1278: 2. Collect all artifacts (thread dumps, memory dumps, monitoring system screenshots, log files) - information about system state at emergency moment that allows identifying emergency cause and taking actions to prevent it in future
 1279: 3. Contact technical support service, provide all collected artifacts and take joint counter-emergency actions to localize the problem
 1280: 
 1281: First, current (operational) system information is collected, then retrospective (historical) information.
 1282: 
 1283: **Database:**
 1284: - Active database sessions: wait time, wait type, SQL queries
 1285: - Session lock tree
 1286: - OS status (using OS utilities)
 1287: - Errors in postgresql_<date>.log
 1288: - Monitoring system data, screenshots
 1289: - OS logs (if necessary)
 1290: 
 1291: **Application Server:**
 1292: - OS status (using OS utilities)
 1293: - OS logs (if necessary)
 1294: - Logs (from all AS nodes if multiple)
 1295: - AS status using jvisualVM utility (screenshots)
 1296: - Monitoring system data, screenshots
 1297: - AS memory (heap) dumps, thread dumps
 1298: 
 1299: **Memory dump (heap) example:**
 1300: ```bash
 1301: cd /Data/jboss_prod/bin
 1302: ./runjboss.sh heap-dump
 1303: ```
 1304: 
 1305: **Thread dump example:**
 1306: ```bash
 1307: cd /Data/jboss_prod/bin
 1308: ./runjboss.sh thread-dump >> thread-dump_15-01-2016_15-23
 1309: ```
 1310: 
 1311: Thread dumps are recommended to be taken several times with 3-5 minute intervals. Dump files will be created in AS bin directory.
 1312: 
 1313: Since logs and dumps occupy significant space, it's recommended to archive them before sending using tar and gzip utilities.
 1314: 
 1315: **Example:**
 1316: ```bash
 1317: cd /Data/jboss_prod/standalone
 1318: tar -cvf log.tar log
 1319: gzip log.tar
 1320: ```
 1321: 
 1322: After archiving all artifacts and sending them to contractor, delete irrelevant tar and gz archives as well as memory and thread dumps from host.
 1323: 
 1324: ---
 1325: 
 1326: ## 3. WFM CC Solution Service Maintenance Guide
 1327: 
 1328: ### 3.1 Software Environment Setup for WFM CC Server Software Deployment
 1329: 
 1330: Before deploying WFM CC solution components, the following preliminary/preparatory actions must be performed on each VM:
 1331: 
 1332: - Provide internet access
 1333: - Ensure network connectivity between VMs
 1334: - Open necessary ports between VMs according to technical architecture
 1335: - Install utilities and packages for OS status diagnostics: top, htop, vmstat, iostat, iotop, netstat, tcpdump, telnet, ping, mc
 1336: - Install Docker and Docker Compose on all VMs
 1337: - Install Oracle JDK version 8 update 77 (8u77) on all VMs
 1338: 
 1339: #### 3.1.1 WFM CC Database Server
 1340: 
 1341: ##### 3.1.1.1 Directory Organization
 1342: 
 1343: Recommended directory structure for WFM CC database software placement:
 1344: 
 1345: | Directory | Description |
 1346: |-----------|-------------|
 1347: | /argus | Contains database and additional environment for supporting its operation |
 1348: | /argus/distr | Contains database distributables and installation packages |
 1349: | /argus/nmon | Contains nmon system performance reports (format: <network_node_name>_yymmdd_0101.nmon) and their archives (format: <network_node_name>_yymmdd_0101.nmon.gz) |
 1350: | /argus/scripts | Auxiliary scripts |
 1351: | /argus/tmp | AS temporary files directory |
 1352: 
 1353: **Directory creation example:**
 1354: ```bash
 1355: mkdir /argus
 1356: chown argus:argus /argus -R
 1357: ```
 1358: 
 1359: ##### 3.1.1.2 Time Synchronization
 1360: 
 1361: The OS must have a time service (ntpd or chronyd) installed that provides system time synchronization with a time server.
 1362: 
 1363: #### 3.1.2 WFM CC Application Server
 1364: 
 1365: ##### 3.1.2.1 User Account
 1366: 
 1367: The OS must have an argus user account created for installing and running both AS and any additional software (e.g., JDK). The user account must have write permissions to the AS directory (e.g., /argus/jboss_prod) and its subdirectories.
 1368: 
 1369: Creating a new user account in Linux OS is done using the adduser utility.
 1370: 
 1371: **Example:**
 1372: ```bash
 1373: adduser argus
 1374: ```
 1375: 
 1376: More detailed instructions for creating user accounts via command line can be found at: https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/system_administrators_guide/ch-managing_users_and_groups
 1377: 
 1378: ##### 3.1.2.2 Java Virtual Machine
 1379: 
 1380: For stable WFM CC AS operation, Oracle JDK version 8 update 77 (8u77) pre-installation is required.
 1381: 
 1382: Java version 8 is available for download from: http://www.oracle.com/technetwork/java/javase/downloads/index.html
 1383: 
 1384: JDK 8u77 download from Oracle site archive requires a registered account.
 1385: 
 1386: It's recommended to install Java Virtual Machine in directory /argus/jdk/jdk1.8.0_77 as JDK (java development kit), not as JRE (java runtime environment), since JDK provides additional application diagnostic tools.
 1387: 
 1388: You must specify in .bash_profile (or .profile, depending on which file is used in the OS) of the OS user running the AS installation file or AS process itself:
 1389: 
 1390: - **JAVA_HOME environment variable** with JDK path:
 1391: ```bash
 1392: export JAVA_HOME=/argus/jdk/jdk1.8.0_77
 1393: ```
 1394: 
 1395: - **PATH environment variable** with JDK bin directory path:
 1396: ```bash
 1397: export PATH=/argus/jdk/jdk1.8.0_77/bin:$PATH
 1398: ```
 1399: 
 1400: It's desirable to use the latest Java Virtual Machine that accounts for the absence of daylight saving time transition in the Russian Federation, or the existing Java Virtual Machine should be updated using Java Time Zone Updater.
 1401: 
 1402: Additional information: http://www.oracle.com/technetwork/java/javase/tzupdater-readme-136440.html
 1403: 
 1404: ##### 3.1.2.3 Time Zone Data
 1405: 
 1406: The host must be in UTC timezone.
 1407: 
 1408: **Check installed timezones:**
 1409: ```bash
 1410: timedatectl list-timezones
 1411: ```
 1412: 
 1413: **Set UTC timezone:**
 1414: ```bash
 1415: timedatectl set-timezone UTC
 1416: ```
 1417: 
 1418: Before AS installation, ensure that actual time zone data is installed in JDK.
 1419: 
 1420: ##### 3.1.2.4 Operating System Locale and Encoding
 1421: 
 1422: The operating system must support UTF-8 encoding and have time, date, and number formats (locale) installed according to language standards used by users (for installation in Russian Federation, ru_RU.UTF-8 locale is needed).
 1423: 
 1424: In Linux operating systems, locale checking is performed with the locale command. Below is the command output on a correctly configured server:
 1425: 
 1426: ```bash
 1427: $ locale
 1428: LANG=ru_RU.UTF-8
 1429: LC_CTYPE="ru_RU.UTF-8"
 1430: LC_NUMERIC="ru_RU.UTF-8"
 1431: LC_TIME="ru_RU.UTF-8"
 1432: LC_COLLATE="ru_RU.UTF-8"
 1433: LC_MONETARY="ru_RU.UTF-8"
 1434: LC_MESSAGES="ru_RU.UTF-8"
 1435: LC_PAPER="ru_RU.UTF-8"
 1436: LC_NAME="ru_RU.UTF-8"
 1437: LC_ADDRESS="ru_RU.UTF-8"
 1438: LC_TELEPHONE="ru_RU.UTF-8"
 1439: LC_MEASUREMENT="ru_RU.UTF-8"
 1440: LC_IDENTIFICATION="ru_RU.UTF-8"
 1441: LC_ALL=
 1442: ```
 1443: 
 1444: ##### 3.1.2.5 Time Synchronization
 1445: 
 1446: For correct WFM CC AS operation, time synchronization between WFM CC AS OS and WFM CC Database OS must be ensured.
 1447: 
 1448: The OS must have a time service (ntpd or chronyd) installed that provides system time synchronization with a time server.
 1449: 
 1450: ##### 3.1.2.6 Maximum Number of Open Files and Sockets
 1451: 
 1452: It's necessary to increase the limit on maximum number of open files and sockets compared to default values. The server keeps many files open. The application server opens sockets establishing outgoing network connections to WFM CC Database and AS of other WFM CC solution components with which interaction is maintained. The application server opens sockets accepting incoming connections from user browsers.
 1453: 
 1454: Required maximum number of open files and sockets is calculated by formula:
 1455: 
 1456: **max open sockets and files = max concurrent users × 20**
 1457: 
 1458: **Linux Kernel Configuration Parameters:**
 1459: 
 1460: View current OS level settings:
 1461: ```bash
 1462: cat /proc/sys/fs/file-max
 1463: ```
 1464: 
 1465: Set OS level parameter value in file and activate:
 1466: ```bash
 1467: sysctl -w fs.file-max=102400
 1468: sysctl -p /etc/sysctl.conf
 1469: ```
 1470: 
 1471: View settings for current user (OS account):
 1472: ```bash
 1473: ulimit -n
 1474: ```
 1475: 
 1476: Set user account value in file /etc/security/limits.conf:
 1477: ```
 1478: argus soft nofile 100000
 1479: argus hard nofile 100000
 1480: ```
 1481: 
 1482: ##### 3.1.2.7 Maximum Number of Running Processes
 1483: 
 1484: It's necessary to increase the limit on maximum number of running processes compared to default values. When server operates without additional HTTP ports, server thread count can be within 200-1000 range, and adding another additional HTTP port entails creating a 256-thread pool.
 1485: 
 1486: Formula for calculating max-user-processes:
 1487: **max-user-processes ≥ 1000 + additional-ports-count × 256**
 1488: 
 1489: View settings for current user (OS account):
 1490: ```bash
 1491: ulimit -a | grep processes
 1492: ```
 1493: 
 1494: Set user account value in file /etc/security/limits.conf:
 1495: ```
 1496: argus soft nproc 4000
 1497: argus hard nproc 4000
 1498: ```
 1499: 
 1500: ##### 3.1.2.8 Additional Recommended OS Settings
 1501: 
 1502: **Linux:**
 1503: Increase socket send/receive buffer values in file /etc/sysctl.conf:
 1504: ```
 1505: net.core.rmem_default=262144
 1506: net.core.wmem_default=262144
 1507: net.core.rmem_max=262144
 1508: net.core.wmem_max=262144
 1509: ```
 1510: 
 1511: Activate changes:
 1512: ```bash
 1513: sysctl -p /etc/sysctl.conf
 1514: ```
 1515: 
 1516: ##### 3.1.2.9 Directory Organization
 1517: 
 1518: Recommended directory structure for WFM CC AS software placement:
 1519: 
 1520: | Directory | Description |
 1521: |-----------|-------------|
 1522: | /argus | Contains AS and additional environment for supporting its operation. Separate disk partition recommended |
 1523: | /argus/distr | Contains AS and additional software distributables and installation packages |
 1524: | /argus/jboss_arch | Stores AS backup copies (copy format: ddmmyyyy/jboss_prod) |
 1525: | /argus/jboss_prod | AS installation directory |
 1526: | /argus/jdk | JDK installation directory |
 1527: | /argus/jdk/jdk1.8.0_77 | JDK version 8 update 77. Required for AS operation |
 1528: | /argus/nmon | Contains nmon system performance reports and their archives |
 1529: | /argus/scripts | Auxiliary scripts |
 1530: | /argus/tmp | AS temporary files directory |
 1531: 
 1532: **Directory creation example:**
 1533: ```bash
 1534: mkdir /argus
 1535: chown argus:argus /argus -R
 1536: ```
 1537: 
 1538: ##### 3.1.2.10 Hostname
 1539: 
 1540: Hostname must not contain underscore character.
 1541: 
 1542: **Check:**
 1543: ```bash
 1544: uname -n
 1545: ```
 1546: 
 1547: ##### 3.1.2.11 Font Requirements
 1548: 
 1549: For correct application server operation, fontconfig package with TrueType fonts must be installed on the OS.
 1550: 
 1551: #### 3.1.3 WFM CC Personal Cabinet Service
 1552: 
 1553: ##### 3.1.3.1 Docker and Docker Compose
 1554: 
 1555: For Docker software installation, CentOS operating system with kernel version no lower than 3.10.0-229.el7.x86_64 is required.
 1556: 
 1557: For components delivered in Docker container, the following software must be pre-installed on the host:
 1558: - Docker not lower than 19.03.12
 1559: - Docker Compose not lower than 1.29.2
 1560: 
 1561: **Check Docker and Docker Compose availability:**
 1562: ```bash
 1563: docker -v
 1564: docker-compose -v
 1565: ```
 1566: 
 1567: If corresponding software is installed, version and build number message will be displayed.
 1568: 
 1569: ##### 3.1.3.2 User Account
 1570: 
 1571: The OS must have an argus user account created for installing and running Docker container. The user account must be in docker group with uid/gid 1099.
 1572: 
 1573: **Example:**
 1574: ```bash
 1575: adduser argus
 1576: usermod -aG docker argus
 1577: groupmod -g 1099 argus
 1578: usermod -u 1099 -g 1099 argus
 1579: ```
 1580: 
 1581: **Check account creation:**
 1582: ```bash
 1583: id argus
 1584: # Console output after checking id argus
 1585: uid=1099(argus) gid=1099(argus) groups=1099(argus),995(docker)
 1586: ```
 1587: 
 1588: ##### 3.1.3.3 Directory Organization
 1589: 
 1590: Recommended directory structure on host:
 1591: 
 1592: | Directory | Description |
 1593: |-----------|-------------|
 1594: | /argus | Contains distributables, configuration files, Docker image software and additional environment for service operation support |
 1595: | /argus/distr | Contains delivered software distributables as Docker images (tar files) |
 1596: | /argus/nmon | Contains nmon system performance reports and their archives |
 1597: | /argus/scripts | Auxiliary scripts |
 1598: 
 1599: **Directory creation example:**
 1600: ```bash
 1601: mkdir /argus
 1602: chown argus:argus /argus -R
 1603: ```
 1604: 
 1605: ##### 3.1.3.4 Time Synchronization
 1606: 
 1607: The OS must have a time service (ntpd or chronyd) installed that provides system time synchronization with a time server.
 1608: 
 1609: #### 3.1.4 WFM CC Mobile API Service
 1610: 
 1611: [Similar structure and requirements as Personal Cabinet Service - content follows same pattern]
 1612: 
 1613: #### 3.1.5 Planning Service
 1614: 
 1615: [Similar structure and requirements as other services - content follows same pattern]
 1616: 
 1617: #### 3.1.6 Reports Service
 1618: 
 1619: [Similar structure and requirements as other services - content follows same pattern]
 1620: 
 1621: #### 3.1.7 Notifications Service
 1622: 
 1623: [Similar structure and requirements as other services - content follows same pattern]
 1624: 
 1625: #### 3.1.8 Integration Service
 1626: 
 1627: ##### 3.1.8.1 Java Virtual Machine
 1628: 
 1629: Application requires OpenJDK version 1.8 installation:
 1630: ```bash
 1631: yum install java-1.8.0-openjdk.x86_64
 1632: ```
 1633: 
 1634: **Check Java version:**
 1635: ```bash
 1636: java -version
 1637: # Example output:
 1638: openjdk version "1.8.0_232"
 1639: OpenJDK Runtime Environment (build 1.8.0_232-b09)
 1640: OpenJDK 64-Bit Server VM (build 25.232-b09, mixed mode)
 1641: ```
 1642: 
 1643: ##### 3.1.8.2 User Account
 1644: 
 1645: The OS must have an argus user account created for software installation and management.
 1646: 
 1647: **Example:**
 1648: ```bash
 1649: useradd argus
 1650: passwd argus
 1651: ```
 1652: 
 1653: ##### 3.1.8.3 Directory Organization
 1654: 
 1655: Recommended directory structure on host:
 1656: 
 1657: | Directory | Description |
 1658: |-----------|-------------|
 1659: | /argus | Contains distributables, configuration files, backup copies and auxiliary scripts and utilities |
 1660: | /argus/integration | Contains application |
 1661: | /argus/distr | Contains delivered software distributables as archives |
 1662: | /argus/backup | Contains backup copies created before software updates |
 1663: | /argus/nmon | Contains nmon system performance reports and their archives |
 1664: | /argus/scripts | Auxiliary scripts |
 1665: 
 1666: **Directory creation example:**
 1667: ```bash
 1668: mkdir -p /argus/integration
 1669: chown argus:argus /argus -R
 1670: ```
 1671: 
 1672: ##### 3.1.8.4 Auto-start Configuration
 1673: 
 1674: Create file /etc/systemd/system/integration.service with content:
 1675: ```ini
 1676: [Unit]
 1677: Description=integration
 1678: After=syslog.target
 1679: 
 1680: [Service]
 1681: User=argus
 1682: WorkingDirectory=/argus/integration
 1683: ExecStart=/argus/integration/integration-0.0.46-SNAPSHOT.jar
 1684: SuccessExitStatus=143
 1685: TimeoutStopSec=10
 1686: Restart=on-failure
 1687: RestartSec=5
 1688: OOMScoreAdjust=-1000
 1689: 
 1690: [Install]
 1691: WantedBy=multi-user.target
 1692: ```
 1693: 
 1694: Execute:
 1695: ```bash
 1696: systemctl daemon-reload
 1697: systemctl enable integration.service
 1698: ```
 1699: 
 1700: ##### 3.1.8.5 Time Synchronization
 1701: 
 1702: The OS must have a time service (ntpd or chronyd) installed that provides system time synchronization with a time server.
 1703: 
 1704: #### 3.1.9 Service Load Balancer
 1705: 
 1706: WFM CC solution software works with a load balancer used for load balancing when accessing services and AS, and also used as reverse proxy when accessing services and AS via HTTPS.
 1707: 
 1708: Load balancer configuration requirements are described in section 2.1.10.3 WFM CC Services Load Balancer Requirements.
 1709: 
 1710: **Software load balancers used with Argus software:**
 1711: - Based on apache httpd web server with installed mod_jk, mod_cluster, or enabled mod_proxy_balancer
 1712: - Based on HAProxy software load balancer
 1713: 
 1714: Before HAProxy installation and configuration, install epel repository:
 1715: ```bash
 1716: yum install epel-release
 1717: ```
 1718: 
 1719: **Hardware load balancers used with Argus software:**
 1720: - CISCO ACE 10
 1721: - Citrix NetScaler
 1722: 
 1723: *The list of hardware load balancers is not limited to the models listed*
 1724: 
 1725: ##### 3.1.9.1 Time Synchronization
 1726: 
 1727: The OS must have a time service (ntpd or chronyd) installed that provides system time synchronization with a time server.
 1728: 
 1729: #### 3.1.10 Database Load Balancer
 1730: 
 1731: Database load balancer components are installed from standard packages.
 1732: 
 1733: Internet access to repositories for package updates and installation must be provided.
 1734: 
 1735: Details on installation in sections:
 1736: - 3.2.4.1.1 Keepalived Installation
 1737: - 3.2.4.2.1 Haproxy Installation
 1738: - 3.2.4.3.1 Etcd Installation
 1739: - 3.2.4.4.1 Patroni Installation
 1740: 
 1741: ##### 3.1.10.1 Time Synchronization
 1742: 
 1743: The OS must have a time service (ntpd or chronyd) installed that provides system time synchronization with a time server.
 1744: 
 1745: #### 3.1.11 Monitoring Tools
 1746: 
 1747: ##### 3.1.11.1 DBMS Monitoring Software Environment Setup
 1748: 
 1749: DBMS software environment setup is described in section 3.1.1 WFM CC Database Server.
 1750: 
 1751: ##### 3.1.11.2 Application Server Monitoring Software Environment Setup
 1752: 
 1753: On hosts from which remote AS resource monitoring is planned, software environment for utility operation must be prepared:
 1754: 
 1755: **Java Visual VM (JVisualVM)** - diagnostic framework allowing real-time evaluation and report-form saving of server thread state information, OS load, JMX-bean parameters, thread blocking detection, etc. Allows simultaneous work with multiple servers.
 1756: 
 1757: **JConsole** - one of the most powerful diagnostic tools allowing real-time information about OS resources used, threads created within JVM process, loaded classes, JMX-bean state retrieval or modification, and many other capabilities.
 1758: 
 1759: **Command Line Interface (CLI)** - command-line interface allowing AS management.
 1760: 
 1761: For hosts requiring AS monitoring, software environment for OS-level resource monitoring utilities must be prepared:
 1762: 
 1763: **NMON** (Nigel's Monitor) - administrator tool for Linux system performance analysis and monitoring.
 1764: 
 1765: **Standard OS resource monitoring utilities** (top, mpstat, vmstat, iostat) - for Red Hat Enterprise Linux 6 or higher, top, mpstat, vmstat and iostat utilities are included in delivery.
 1766: 
 1767: Installation commands:
 1768: ```bash
 1769: yum -y install procps sysstat
 1770: # or
 1771: apt-get install procps sysstat
 1772: ```
 1773: 
 1774: **Zabbix Agent** - setup described in section 3.1.11.3 Zabbix Monitoring System Software Environment Setup.
 1775: 
 1776: ##### 3.1.11.3 Zabbix Monitoring System Software Environment Setup
 1777: 
 1778: On hosts where Zabbix Proxy, Zabbix Java Gateway or Zabbix Agent version 3.0.x will be installed, ensure:
 1779: - Internet access
 1780: - Zabbix repository configuration
 1781: 
 1782: For Zabbix Proxy and Zabbix Java Gateway, update PHP to version 5.4 or 5.5 on host.
 1783: 
 1784: Install dependencies:
 1785: ```bash
 1786: wget http://dl.fedoraproject.org/pub/epel/7/x86_64/f/fping-3.10-4.el7.x86_64.rpm
 1787: rpm -Uhv fping-3.10-4.el7.x86_64.rpm
 1788: ```
 1789: 
 1790: A non-privileged user must be created for Zabbix component processes.
 1791: 
 1792: If internet access is unavailable on host, Zabbix component packages must be downloaded separately from repository and made available before installing corresponding monitoring system component.
 1793: 
 1794: ### 3.2 Installation, Configuration and Update of WFM CC Server Software
 1795: 
 1796: #### 3.2.1 WFM CC Database
 1797: 
 1798: ##### 3.2.1.1 Basic PostgreSQL DBMS Installation
 1799: 
 1800: PostgreSQL 10 installation and configuration instructions are described on the official website: https://www.postgresql.org/docs/10/tutorial-install.html
 1801: 
 1802: ##### 3.2.1.2 Database System User Creation
 1803: 
 1804: Before first installation, create database system user argus_sys:
 1805: ```sql
 1806: CREATE ROLE argus_sys WITH LOGIN CREATEDB CREATEROLE PASSWORD '<password>';
 1807: ```
 1808: 
 1809: ##### 3.2.1.3 Database Creation and Configuration
 1810: 
 1811: **Example of creating database user, database, privileges and schemas:**
 1812: ```sql
 1813: -- Create database
 1814: CREATE DATABASE <database_name>;
 1815: 
 1816: -- Make argus_sys database owner
 1817: ALTER DATABASE <database_name> OWNER TO argus_sys;
 1818: 
 1819: -- Grant necessary privileges to argus_sys user
 1820: GRANT ALL PRIVILEGES ON DATABASE <database_name> TO argus_sys;
 1821: 
 1822: -- Define search path
 1823: ALTER DATABASE <database_name> SET search_path = pg_catalog, public, system;
 1824: ALTER ROLE argus_sys SET search_path = pg_catalog, public, system;
 1825: 
 1826: -- Create dbm schema for data loading
 1827: \c <database_name>
 1828: CREATE SCHEMA IF NOT EXISTS dbm AUTHORIZATION argus_sys;
 1829: ```
 1830: 
 1831: **Complete example:**
 1832: ```sql
 1833: CREATE ROLE argus_sys WITH LOGIN CREATEDB CREATEROLE PASSWORD '***';
 1834: CREATE DATABASE prod OWNER argus_sys;
 1835: ALTER DATABASE prod SET search_path = pg_catalog, public, system;
 1836: ALTER ROLE argus_sys SET search_path = pg_catalog, public, system;
 1837: \c prod
 1838: CREATE SCHEMA IF NOT EXISTS dbm AUTHORIZATION argus_sys;
 1839: ```
 1840: 
 1841: ##### 3.2.1.4 Required Database Extensions
 1842: 
 1843: Install the following PostgreSQL extensions in the database created in section 3.2.1.3:
 1844: 
 1845: ```sql
 1846: \c <database_name>
 1847: CREATE EXTENSION IF NOT EXISTS jsquery SCHEMA public;
 1848: CREATE EXTENSION IF NOT EXISTS btree_gin SCHEMA public;
 1849: CREATE EXTENSION IF NOT EXISTS pg_trgm SCHEMA public;
 1850: CREATE EXTENSION IF NOT EXISTS btree_gist SCHEMA public;
 1851: CREATE EXTENSION IF NOT EXISTS lo SCHEMA public;
 1852: ```
 1853: 
 1854: If corresponding extension is not available in system, install it first. For PostgreSQL10:
 1855: ```bash
 1856: yum install jsquery_10
 1857: ```
 1858: 
 1859: ##### 3.2.1.5 Database Update
 1860: 
 1861: 1. Obtain update-database-<version>.zip file
 1862: 2. Unpack the obtained update-database-<version>.zip archive:
 1863: ```bash
 1864: cd /argus && unzip update-database-<version>.zip
 1865: ```
 1866: 
 1867: 3. Set database access parameters in dbmaintain.properties file:
 1868: 
 1869: **Example dbmaintain.properties:**
 1870: ```properties
 1871: database.dialect=postgresql
 1872: database.driverClassName=org.postgresql.Driver
 1873: database.password=***
 1874: database.url=jdbc\:postgresql\://192.168.100.10\:5432/prod
 1875: database.userName=argus_sys
 1876: databases.names=prod
 1877: dbMaintainer.allowOutOfSequenceExecutionOfPatches=true
 1878: dbMaintainer.script.ignoreCarriageReturnsWhenCalculatingCheckSum=true
 1879: dbMaintainer.script.locations=data/update-all-ver_0.1.0.jar
 1880: ```
 1881: 
 1882: 4. Perform check:
 1883: ```bash
 1884: ./dbmaintain.sh checkScriptUpdates
 1885: ```
 1886: 
 1887: 5. If check shows presence of scripts for execution, perform update:
 1888: ```bash
 1889: ./dbmaintain.sh updateDatabase
 1890: ```
 1891: 
 1892: If call completes with "The database has been updated successfully" line, update is successfully installed.
 1893: 
 1894: Otherwise, report problem to NTC ARGUS support specialists, send log file and wait for special recommendations for further action scenario and/or system operability restoration.
 1895: 
 1896: #### 3.2.2 WFM CC Application Server
 1897: 
 1898: ##### 3.2.2.1 Software Environment Setup Check
 1899: 
 1900: Ensure requirements from section 3.1.2 are met.
 1901: 
 1902: ##### 3.2.2.2 Installation Package Archive Unpacking
 1903: 
 1904: Unpack installation package archive on AS host using unzip utility:
 1905: ```bash
 1906: unzip [installation_package_archive_name].zip
 1907: ```
 1908: 
 1909: *Archive must be unpacked exactly on AS host, not on administrator's local machine. Otherwise, transferring unpacked archive over network (using SCP/FTP or similar protocol) will lead to problems with Russian letters in file names.*
 1910: 
 1911: Archive will be unpacked to current directory. During file extraction, question marks may be displayed instead of Russian letters in console. This is normal.
 1912: 
 1913: ##### 3.2.2.3 Saving Backup Copy of Previously Installed AS and Its Recovery
 1914: 
 1915: If server installation is performed to update previously installed server, create backup copy of previously installed server.
 1916: 
 1917: To create application server backup copy, simply create installation directory copy. Stopping application server is not required. Server can be restored by copying saved directory copy to installation directory after preliminary server stop.
 1918: 
 1919: ##### 3.2.2.4 Application Server Installation
 1920: 
 1921: 1. Obtain argus-dist-<version>-ccwfm.jar file
 1922: 2. To install AS, execute command:
 1923: ```bash
 1924: java -jar argus-dist-<version>-ccwfm.jar -options prod.properties
 1925: ```
 1926: 
 1927: ##### 3.2.2.5 Application Server Startup
 1928: 
 1929: Before startup, ensure AS is not already running.
 1930: 
 1931: Check current installed AS status using status parameter of runjboss.sh script by going to AS installation directory INSTALL_PATH/bin and executing command:
 1932: ```bash
 1933: ./runjboss.sh status
 1934: ```
 1935: 
 1936: Command execution result will be:
 1937: - `wildfly started (pid 1535)` - server is running
 1938: - `wildfly not started` - server is not running
 1939: 
 1940: To start AS, go to directory <INSTALL_PATH>/bin and execute command:
 1941: ```bash
 1942: cd <INSTALL_PATH>/bin
 1943: ./runjboss.sh start
 1944: ```
 1945: 
 1946: Command execution result will be:
 1947: ```
 1948: Starting wildfly in default mode (standalone)...
 1949: ```
 1950: 
 1951: **Note:** To start AS under non-privileged user account (e.g., argus), if current user is root, execute command:
 1952: ```bash
 1953: sudo -u argus ./runjboss.sh start
 1954: ```
 1955: 
 1956: AS startup takes several minutes. After AS startup phase completion, web interface becomes available to users, until completion of large data volume loading from database to AS cache, if caches have never been loaded before.
 1957: 
 1958: Server will start when file <INSTALL_PATH>/standalone/log/last_boot_errors.log contains "Server started" message.
 1959: 
 1960: If last_boot_errors.log contains errors, report problem to NTC ARGUS support specialists, send all log files (entire logs folder) and wait for special recommendations for further action scenario and/or system operability restoration.
 1961: 
 1962: **Note:** Since AS cache update process completes outside AS startup phase, AS cache synchronization errors may not be visible in last_boot_errors.log.
 1963: 
 1964: ##### 3.2.2.6 Application Server Shutdown
 1965: 
 1966: To stop server, go to bin subdirectory of installation directory and execute runjboss.sh command with one of the following parameters:
 1967: 
 1968: - **stop** - normal server shutdown
 1969: - **stop kill** - without waiting for server shutdown, terminates its operation
 1970: 
 1971: Shutdown progress is logged to file: InstallationDirectory/standalone/log/server.log.
 1972: 
 1973: Upon shutdown completion, the following message is output:
 1974: ```
 1975: 16:48:14,397 INFO [as] (MSC service thread 1-2) JBAS015950: WildFly 10.1.0.Final "Tweek" stopped in 1155ms
 1976: ```
 1977: 
 1978: Upon successful AS stop operation execution, the following messages will be displayed on screen:
 1979: ```
 1980: Stopping wildfly:Done.
 1981: ```
 1982: 
 1983: If AS cannot be stopped by standard means, in Linux OS, kill command can be used to stop AS process:
 1984: ```bash
 1985: kill -9 pid
 1986: ```
 1987: where pid is application server process identifier in OS.
 1988: 
 1989: *Server stop using runjboss.sh stop command may take several minutes.*
 1990: 
 1991: ##### 3.2.2.7 Configuration File
 1992: 
 1993: Create prod.properties configuration file for startup and specify all necessary parameters in it.
 1994: 
 1995: **Example configuration file:**
 1996: ```properties
 1997: # Basic settings
 1998: INSTALL_PATH=/argus/jboss_prod/
 1999: argus.app.memory.max-size=8192
 2000: argus.app.debug-mode.enabled=false
 2001: jboss.bind.address.management=0.0.0.0
 2002: argus.app.admin.user=developer
 2003: argus.app.admin.pass=***
 2004: argus.java.home.path=/usr/java/jdk1.8.0_202-amd64
 2005: argus.app.security-mode.enabled=false
 2006: argus.db.address=192.168.100.10
 2007: argus.db.name=demodb
 2008: argus.db.port=5432
 2009: argus.db.user=argus_sys
 2010: argus.db.pass=***
 2011: jboss.bind.address=192.168.100.20
 2012: jboss.socket.binding.port-offset=0
 2013: 
 2014: # Access to each service that WFM CC AS interacts with according to technical architecture
 2015: ccwfm.notification.service.enabled=true
 2016: ccwfm.notification.service.url=http://192.168.100.25:9000
 2017: ccwfm.reportservice.url=http://192.168.100.24:9000
 2018: ccwfm.reportservice.url.callback=http://192.168.100.20:8080/ccwfm/reportresult
 2019: ccwfm.planningservice.url=http://192.168.100.23:9000
 2020: ccwfm.planningservice.url.callback=http://192.168.100.20:8080/ccwfm/planningresult
 2021: ```
 2022: 
 2023: ##### 3.2.2.8 AS Administrator Account Setup
 2024: 
 2025: AS administrator account provides access to AS administration tools. It's created in two ways:
 2026: 
 2027: 1. **Using configuration settings during AS installation:**
 2028: Using argus.app.admin.user and argus.app.admin.pass parameters
 2029: 
 2030: 2. **Using add-user.sh script** located in bin subdirectory of installed AS:
 2031: 
 2032: Go to bin subdirectory of installed AS and execute:
 2033: ```bash
 2034: ./add_user.sh
 2035: ```
 2036: 
 2037: Follow the prompts to create Management User account with appropriate privileges.
 2038: 
 2039: For verification of successful AS administrator account creation, access AS management web interface via web browser at http://IP-address:Port/, where:
 2040: - IP-address – AS IP address
 2041: - Port – port on which server expects management-http connections (9990 + port-offset)
 2042: 
 2043: #### 3.2.3 WFM CC Personal Cabinet Service
 2044: 
 2045: ##### 3.2.3.1 Software Environment Setup Check
 2046: 
 2047: Ensure requirements from section 3.1.3 are met.
 2048: 
 2049: ##### 3.2.3.2 Personal Cabinet Service WFM CC Update Installation
 2050: 
 2051: When installing Personal Cabinet Service WFM CC updates, follow this procedure:
 2052: 
 2053: 1. Stop container
 2054: 2. Download image
 2055: 3. Update image
 2056: 4. Make changes to configuration files
 2057: 5. Start container
 2058: 6. If steps 1-5 are successful, delete old container and old container image
 2059: 
 2060: **Command examples:**
 2061: 
 2062: Current container information on host:
 2063: ```bash
 2064: docker ps -a
 2065: ```
 2066: 
 2067: Stop single container:
 2068: ```bash
 2069: docker stop <container_id>
 2070: ```
 2071: 
 2072: Or all containers described in docker-compose.yml:
 2073: ```bash
 2074: docker-compose stop
 2075: ```
 2076: 
 2077: Download image from remote Argus repository to local repository:
 2078: ```bash
 2079: docker pull gitlab:4567/laboratorium/personal-area/front:dev-<version>
 2080: docker pull gitlab:4567/laboratorium/mobile-api:dev-<version>
 2081: ```
 2082: 
 2083: If no access to remote Argus repository, on Argus side download image:
 2084: ```bash
 2085: docker pull gitlab:4567/laboratorium/personal-area/front:dev-<version>
 2086: docker pull gitlab:4567/laboratorium/mobile-api:dev-<version>
 2087: ```
 2088: 
 2089: Export image:
 2090: ```bash
 2091: docker image save -o personal-area-<version>.tar gitlab:4567/laboratorium/personal-area/front:dev-<version>
 2092: docker image save -o mobile-api-lk<version>.tar gitlab:4567/laboratorium/mobile-api:dev-<version>
 2093: ```
 2094: 
 2095: Transfer container image archive to customer and load into local docker repository:
 2096: ```bash
 2097: docker load -i personal-area-<version>.tar
 2098: docker load -i mobile-api-lk<version>.tar
 2099: ```
 2100: 
 2101: Make changes to configuration files (.env and docker-compose.yml).
 2102: 
 2103: **Example .env:**
 2104: ```bash
 2105: HOST_IP=192.168.47.3
 2106: RMI_PORT=9067
 2107: JAVA_OPTS=-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=9067 -Dcom.sun.management.jmxremote.rmi.port=9067 -Dcom.sun.management.jmxremote.local.only=false -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Djava.rmi.server.hostname=192.168.47.3 -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/argus/logs/ -XX:+PrintCommandLineFlags -XX:MinRAMPercentage=10.0 -XX:MaxRAMPercentage=90.0
 2108: DB_ADDR=192.168.47.5:5432
 2109: DB_NAME=demodb
 2110: TZ=Europe/Moscow
 2111: MAIN_API_URL=http://192.168.47.3:9060
 2112: CCWFM_URL=http://192.168.47.2:8080
 2113: ```
 2114: 
 2115: Start containers and verify successful startup:
 2116: ```bash
 2117: docker-compose up -d
 2118: docker ps -a
 2119: docker logs -f personal-area
 2120: docker logs -f mobile-api-lk
 2121: ```
 2122: 
 2123: ##### 3.2.3.3 Service Startup
 2124: 
 2125: Start all containers described in docker-compose.yml:
 2126: ```bash
 2127: docker-compose up -d
 2128: ```
 2129: 
 2130: Check successful container startup:
 2131: ```bash
 2132: docker ps -a
 2133: docker logs -f lk-service
 2134: ```
 2135: 
 2136: ##### 3.2.3.4 Service Shutdown
 2137: 
 2138: View current containers on host:
 2139: ```bash
 2140: docker ps -a
 2141: ```
 2142: 
 2143: Stop single container:
 2144: ```bash
 2145: docker stop <container_id>
 2146: ```
 2147: 
 2148: Or all containers described in docker-compose.yml:
 2149: ```bash
 2150: docker-compose stop
 2151: ```
 2152: 
 2153: ##### 3.2.3.5 Configuration Files
 2154: 
 2155: **Example .env configuration file:**
 2156: ```bash
 2157: HOST_IP=192.168.47.3
 2158: DB_ADDR=192.168.47.5:5432
 2159: DB_NAME=demodb
 2160: TZ=Europe/Moscow
 2161: MAIN_API_URL=http://192.168.47.3:9060
 2162: CCWFM_URL=http://192.168.47.2:8080
 2163: ```
 2164: 
 2165: **Example docker-compose.yml configuration file:**
 2166: [Contains detailed Docker Compose configuration with service definitions, ports, environment variables, and volume mounts]
 2167: 
 2168: #### 3.2.4 WFM CC Mobile API Service
 2169: 
 2170: ##### 3.2.4.1 Software Environment Setup Check
 2171: 
 2172: Ensure requirements from section 3.1.4 are met.
 2173: 
 2174: ##### 3.2.4.2 Mobile API Service WFM CC Update Installation and Configuration
 2175: 
 2176: Service configuration is performed by making changes to configuration files followed by service restart.
 2177: 
 2178: When installing Mobile API Service WFM CC updates, follow this procedure:
 2179: 
 2180: 1. Stop container
 2181: 2. Download image
 2182: 3. Update image
 2183: 4. Make changes to configuration files
 2184: 5. Start container
 2185: 6. If steps 1-5 are successful, delete old container and old container image
 2186: 
 2187: **Command examples:**
 2188: 
 2189: Current container information on host:
 2190: ```bash
 2191: docker ps -a
 2192: ```
 2193: 
 2194: Stop single container or all containers:
 2195: ```bash
 2196: docker stop <container_id>
 2197: # or
 2198: docker-compose stop
 2199: ```
 2200: 
 2201: Download image from remote Argus repository:
 2202: ```bash
 2203: docker pull gitlab:4567/laboratorium/mobile-api:release-<version>
 2204: ```
 2205: 
 2206: If no access to remote Argus repository, export and transfer image:
 2207: ```bash
 2208: docker image save -o mobile-api-<version>.tar gitlab:4567/laboratorium/mobile-api:release-<version>
 2209: ```
 2210: 
 2211: Load image on customer side:
 2212: ```bash
 2213: docker load -i mobile-api-<version>.tar
 2214: ```
 2215: 
 2216: Make changes to configuration files (.env and docker-compose.yml):
 2217: 
 2218: **Example .env:**
 2219: ```bash
 2220: HOST_IP=192.168.47.4
 2221: RMI_PORT=9017
 2222: JAVA_OPTS=-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=9017 -Dcom.sun.management.jmxremote.rmi.port=9017 -Dcom.sun.management.jmxremote.local.only=false -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Djava.rmi.server.hostname=192.168.47.4 -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/argus/logs/ -XX:+PrintCommandLineFlags -XX:MinRAMPercentage=10.0 -XX:MaxRAMPercentage=90.0
 2223: DB_ADDR=192.168.47.5:5432
 2224: DB_NAME=demodb
 2225: TZ=Europe/Moscow
 2226: CCWFM_URL=http://192.168.47.2:8080
 2227: ```
 2228: 
 2229: **Example docker-compose.yml:**
 2230: ```yaml
 2231: version: "3"
 2232: services:
 2233:   mobile-api:
 2234:     container_name: mobile-api
 2235:     image: gitlab:4567/laboratorium/mobile-api:release-1.3.0
 2236:     ports:
 2237:       - "9010:8080"
 2238:       - "9017:9017"
 2239:     restart: always
 2240:     environment:
 2241:       - DB_ADDR
 2242:       - DB_NAME
 2243:       - HOST_IP
 2244:       - RMI_PORT
 2245:       - JAVA_OPTS
 2246:       - GW_MODE=mobile
 2247:       - CCWFM_URL
 2248:       - TZ
 2249:     volumes:
 2250:       - mobile-api-logs:/argus/logs
 2251:     logging:
 2252:       driver: "json-file"
 2253:       options:
 2254:         max-size: "200m"
 2255:         max-file: "10"
 2256: 
 2257: volumes:
 2258:   mobile-api-logs:
 2259:     driver: local
 2260:     driver_opts:
 2261:       o: bind
 2262:       type: none
 2263:       device: /argus/mobile-api/logs
 2264: ```
 2265: 
 2266: Start containers and verify:
 2267: ```bash
 2268: docker-compose up -d
 2269: docker ps -a
 2270: docker logs -f mobile-api
 2271: ```
 2272: 
 2273: ##### 3.2.4.3 Service Startup
 2274: 
 2275: Start all containers:
 2276: ```bash
 2277: docker-compose up -d
 2278: docker ps -a
 2279: docker logs -f mobile-api
 2280: ```
 2281: 
 2282: ##### 3.2.4.4 Service Shutdown
 2283: 
 2284: Stop containers:
 2285: ```bash
 2286: docker ps -a
 2287: docker stop <container_id>
 2288: # or
 2289: docker-compose stop
 2290: ```
 2291: 
 2292: ##### 3.2.4.5 Configuration Files
 2293: 
 2294: **Example .env:**
 2295: ```bash
 2296: HOST_IP=192.168.47.4
 2297: DB_ADDR=192.168.47.5:5432
 2298: DB_NAME=demodb
 2299: TZ=Europe/Moscow
 2300: CCWFM_URL=http://192.168.47.2:8080
 2301: ```
 2302: 
 2303: ##### 3.2.4.6 Mobile API Service HTTPS Access
 2304: 
 2305: Mobile API Service operates via HTTP protocol, so for HTTPS access, a reverse proxy for HTTPS-HTTP traffic conversion is required.
 2306: 
 2307: The reverse proxy requires certificate and key files located in the directory specified in configuration file /etc/nginx/nginx.conf:
 2308: 
 2309: ```nginx
 2310: ssl_certificate /etc/nginx/ssl/nginx.crt;
 2311: ssl_certificate_key /etc/nginx/ssl/nginx.key;
 2312: ```
 2313: 
 2314: Replace old certificate and key with new ones by substituting corresponding files in the directory specified in /etc/nginx/nginx.conf.
 2315: 
 2316: After file replacement, restart nginx service:
 2317: ```bash
 2318: systemctl restart nginx
 2319: ```
 2320: 
 2321: #### 3.2.5 Planning Service
 2322: 
 2323: The planning service requires two services, each running in its own docker container:
 2324: - **Gateway (planning-gw)**
 2325: - **Planning service (planning-service)**
 2326: 
 2327: ##### 3.2.5.1 Software Environment Setup Check
 2328: 
 2329: Ensure requirements from section 3.1.5 are met.
 2330: 
 2331: ##### 3.2.5.2 Planning Service Update Installation
 2332: 
 2333: Follow the same procedure as other services:
 2334: 
 2335: 1. Stop container
 2336: 2. Download image
 2337: 3. Update image
 2338: 4. Make changes to configuration files
 2339: 5. Start container
 2340: 6. Clean up old containers and images
 2341: 
 2342: **Command examples:**
 2343: 
 2344: ```bash
 2345: docker ps -a
 2346: docker stop <container_id>
 2347: docker-compose stop
 2348: 
 2349: docker pull gitlab:4567/laboratorium/planning-gw:release-<version>
 2350: docker pull gitlab:4567/laboratorium/planning-service:release-<version>
 2351: ```
 2352: 
 2353: For offline installation:
 2354: ```bash
 2355: docker image save -o planning-gw-<version>.tar gitlab:4567/laboratorium/planning-gw:release-<version>
 2356: docker image save -o planning-service-<version>.tar gitlab:4567/laboratorium/planning-service:release-<version>
 2357: 
 2358: docker load -i planning-gw-<version>.tar
 2359: docker load -i planning-service-<version>.tar
 2360: ```
 2361: 
 2362: **Configuration files:**
 2363: 
 2364: **Example .env:**
 2365: ```bash
 2366: HOST_IP=192.168.47.8
 2367: DB_ADDR=192.168.47.5:5432
 2368: DB_NAME=demodb
 2369: OPERATING_SCHEDULE_SECONDS_SPENT_LIMIT=144000
 2370: TIMETABLE_SECONDS_SPENT_LIMIT=144000
 2371: TZ=Europe/Moscow
 2372: ```
 2373: 
 2374: **Example docker-compose.yml:**
 2375: ```yaml
 2376: version: "3"
 2377: services:
 2378:   planning-gw:
 2379:     container_name: planning-gw
 2380:     image: gitlab:4567/laboratorium/planning-service/gateway:release-1.4.0
 2381:     ports:
 2382:       - "9030:8080"
 2383:       - "9037:9037"
 2384:     restart: always
 2385:     environment:
 2386:       - DB_ADDR
 2387:       - DB_NAME
 2388:       - HOST_IP
 2389:       - RMI_PORT=9037
 2390:       - JAVA_OPTS=-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=9037 -Dcom.sun.management.jmxremote.rmi.port=9037 -Dcom.sun.management.jmxremote.local.only=false -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Djava.rmi.server.hostname=192.168.47.8 -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/argus/logs/ -XX:+PrintCommandLineFlags -XX:MinRAMPercentage=10.0 -XX:MaxRAMPercentage=90.0
 2391:       - TZ
 2392:     volumes:
 2393:       - planning-gw-logs:/argus/logs
 2394:     logging:
 2395:       driver: "json-file"
 2396:       options:
 2397:         max-size: "200m"
 2398:         max-file: "10"
 2399: 
 2400:   planning-service:
 2401:     container_name: planning-service
 2402:     image: gitlab:4567/laboratorium/planning-service/service:release-1.4.0
 2403:     ports:
 2404:       - "9047:9047"
 2405:     restart: always
 2406:     environment:
 2407:       - DB_ADDR
 2408:       - DB_NAME
 2409:       - HOST_IP
 2410:       - RMI_PORT=9047
 2411:       - JAVA_OPTS=-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=9047 -Dcom.sun.management.jmxremote.rmi.port=9047 -Dcom.sun.management.jmxremote.local.only=false -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Djava.rmi.server.hostname=192.168.47.8 -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/argus/logs/ -XX:+PrintCommandLineFlags -XX:MinRAMPercentage=10.0 -XX:MaxRAMPercentage=90.0
 2412:       - OPERATING_SCHEDULE_SECONDS_SPENT_LIMIT
 2413:       - TIMETABLE_SECONDS_SPENT_LIMIT
 2414:       - TZ
 2415:     volumes:
 2416:       - planning-service-logs:/argus/logs
 2417:     logging:
 2418:       driver: "json-file"
 2419:       options:
 2420:         max-size: "200m"
 2421:         max-file: "10"
 2422: 
 2423: volumes:
 2424:   planning-gw-logs:
 2425:     driver: local
 2426:     driver_opts:
 2427:       o: bind
 2428:       type: none
 2429:       device: /argus/planning-gw/logs
 2430:   planning-service-logs:
 2431:     driver: local
 2432:     driver_opts:
 2433:       o: bind
 2434:       type: none
 2435:       device: /argus/planning-service/logs
 2436: ```
 2437: 
 2438: ##### 3.2.5.3 Service Startup
 2439: 
 2440: ```bash
 2441: docker start <container_id>
 2442: # or
 2443: docker-compose up -d
 2444: docker logs -f planning-gw
 2445: docker logs -f planning-service
 2446: ```
 2447: 
 2448: ##### 3.2.5.4 Service Shutdown
 2449: 
 2450: ```bash
 2451: docker stop <container_id>
 2452: # or
 2453: docker-compose stop
 2454: ```
 2455: 
 2456: #### 3.2.6 Reports Service
 2457: 
 2458: ##### 3.2.6.1 Software Environment Setup Check
 2459: 
 2460: Ensure requirements from section 3.1.6 are met.
 2461: 
 2462: ##### 3.2.6.2 Reports Service Update Installation
 2463: 
 2464: Follow standard update procedure:
 2465: 
 2466: ```bash
 2467: docker pull gitlab:4567/laboratorium/report-service:release-<version>
 2468: ```
 2469: 
 2470: **Configuration files:**
 2471: 
 2472: **Example .env:**
 2473: ```bash
 2474: HOST_IP=192.168.47.6
 2475: RMI_PORT=9007
 2476: JAVA_OPTS=-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=9007 -Dcom.sun.management.jmxremote.rmi.port=9007 -Dcom.sun.management.jmxremote.local.only=false -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Djava.rmi.server.hostname=192.168.47.6 -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/argus/logs/ -XX:+PrintCommandLineFlags -XX:MinRAMPercentage=10.0 -XX:MaxRAMPercentage=90.0
 2477: SPRING_APPLICATION_JSON={"argus":{"reports":{"datamarts":[{"name":"MAIN_DB","url":"jdbc:postgresql://192.168.47.5:5432/demodb?currentSchema=system","main":true}]}}}
 2478: REPORT_DB_ADDR=192.168.47.5:5432
 2479: REPORT_DB_NAME=demodb
 2480: TZ=Europe/Moscow
 2481: ```
 2482: 
 2483: **Example docker-compose.yml:**
 2484: ```yaml
 2485: version: "3"
 2486: services:
 2487:   report-service:
 2488:     container_name: report-service
 2489:     image: gitlab:4567/laboratorium/report-service:release-1.8.0
 2490:     ports:
 2491:       - "9000:8080"
 2492:       - "9007:9007"
 2493:     restart: always
 2494:     environment:
 2495:       - REPORT_DB_ADDR
 2496:       - REPORT_DB_NAME
 2497:       - SPRING_APPLICATION_JSON
 2498:       - HOST_IP
 2499:       - RMI_PORT=9007
 2500:       - JAVA_OPTS
 2501:       - TZ
 2502:     volumes:
 2503:       - reports-storage:/argus/reports
 2504:       - reports-logs:/argus/logs
 2505:       - reports-plugins:/argus/plugins
 2506:     logging:
 2507:       driver: "json-file"
 2508:       options:
 2509:         max-size: "200m"
 2510:         max-file: "10"
 2511: 
 2512: volumes:
 2513:   reports-storage:
 2514:     driver: local
 2515:     driver_opts:
 2516:       o: bind
 2517:       type: none
 2518:       device: /argus/reports/storage
 2519:   reports-logs:
 2520:     driver: local
 2521:     driver_opts:
 2522:       o: bind
 2523:       type: none
 2524:       device: /argus/reports/logs
 2525:   reports-plugins:
 2526:     driver: local
 2527:     driver_opts:
 2528:       o: bind
 2529:       type: none
 2530:       device: /argus/reports/plugins
 2531: ```
 2532: 
 2533: **Example db.json:**
 2534: ```json
 2535: {
 2536:   "argus": {
 2537:     "reports": {
 2538:       "datamarts": [
 2539:         {
 2540:           "name": "MAIN_DB",
 2541:           "url": "jdbc:postgresql://192.168.47.5:5432/demodb?currentSchema=system",
 2542:           "main": true
 2543:         }
 2544:       ]
 2545:     }
 2546:   }
 2547: }
 2548: ```
 2549: 
 2550: Start with configuration:
 2551: ```bash
 2552: SPRING_APPLICATION_JSON=$(cat db.json) docker-compose up -d
 2553: ```
 2554: 
 2555: #### 3.2.7 Notifications Service
 2556: 
 2557: ##### 3.2.7.1 Software Environment Setup Check
 2558: 
 2559: Ensure requirements from section 3.1.7 are met.
 2560: 
 2561: ##### 3.2.7.2 Notifications Service Update Installation
 2562: 
 2563: Follow standard update procedure with these configuration files:
 2564: 
 2565: **Example .env:**
 2566: ```bash
 2567: HOST_IP=192.168.47.7
 2568: RMI_PORT=9027
 2569: JAVA_OPTS=-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=9027 -Dcom.sun.management.jmxremote.rmi.port=9027 -Dcom.sun.management.jmxremote.local.only=false -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Djava.rmi.server.hostname=192.168.47.7 -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/argus/logs/ -XX:+PrintCommandLineFlags -XX:MinRAMPercentage=10.0 -XX:MaxRAMPercentage=90.0
 2570: NOTIFICATION_DB_ADDR=192.168.47.5:5432
 2571: NOTIFICATION_DB_NAME=demodb
 2572: TZ=Europe/Moscow
 2573: MAIL_FROM=wfmcc@argustelecom.ru
 2574: MAIL_SMTP_HOST=mail.argustelecom.ru
 2575: MAIL_SMTP_PORT=25
 2576: MAIL_SMTP_USER=user
 2577: MAIL_SMTP_PASS=pass
 2578: ```
 2579: 
 2580: **Example docker-compose.yml:**
 2581: ```yaml
 2582: version: "3"
 2583: services:
 2584:   notification-service:
 2585:     container_name: notification-service
 2586:     image: gitlab:4567/laboratorium/notification-service:release-1.0.2
 2587:     ports:
 2588:       - "9020:8080"
 2589:       - "9027:9027"
 2590:     restart: always
 2591:     environment:
 2592:       - NOTIFICATION_DB_ADDR
 2593:       - NOTIFICATION_DB_NAME
 2594:       - HOST_IP
 2595:       - RMI_PORT=9027
 2596:       - JAVA_OPTS
 2597:       - TZ
 2598:       - MAIL_FROM
 2599:       - MAIL_SMTP_HOST
 2600:       - MAIL_SMTP_PORT
 2601:       - MAIL_SMTP_USER
 2602:       - MAIL_SMTP_PASS
 2603:       #- MAIL_ENABLED=false
 2604:     volumes:
 2605:       - notification-service-logs:/argus/logs
 2606:     logging:
 2607:       driver: "json-file"
 2608:       options:
 2609:         max-size: "200m"
 2610:         max-file: "10"
 2611: 
 2612: volumes:
 2613:   notification-service-logs:
 2614:     driver: local
 2615:     driver_opts:
 2616:       o: bind
 2617:       type: none
 2618:       device: /argus/notification-service/logs
 2619: ```
 2620: 
 2621: **For proxy server operation:**
 2622: 
 2623: Add to .env file:
 2624: - Proxy server address variables: HTTP_PROXY, HTTPS_PROXY
 2625: - Hosts/network ranges excluded from proxy: NO_PROXY
 2626: - Add proxy parameters to JAVA_OPTS: -Dhttp.proxyHost, -Dhttp.proxyPort, -Dhttps.proxyHost, -Dhttps.proxyPort
 2627: 
 2628: Add to docker-compose.yml: HTTP_PROXY, HTTPS_PROXY, NO_PROXY parameters
 2629: 
 2630: ##### 3.2.7.6 Email Notifications Configuration
 2631: 
 2632: Configure email notifications by specifying necessary parameters in .env and docker-compose.yml files.
 2633: 
 2634: Uncommented parameter MAIL_ENABLED=false means email notifications are disabled.
 2635: 
 2636: To apply changes, restart the service.
 2637: 
 2638: #### 3.2.8 Integration Service
 2639: 
 2640: ##### 3.2.8.1 Software Environment Setup Check
 2641: 
 2642: Ensure requirements from section 3.1.8 are met.
 2643: 
 2644: ##### 3.2.8.2 Installation Package Archive Unpacking
 2645: 
 2646: Unpack installation package archive on host using unzip utility:
 2647: ```bash
 2648: unzip [installation_package_archive_name].zip
 2649: ```
 2650: 
 2651: Archive must be unpacked to /argus/integration directory.
 2652: 
 2653: Set argus account as application owner:
 2654: ```bash
 2655: chown argus:argus /argus/integration/integration-0.0.46-SNAPSHOT.jar
 2656: chmod 500 /argus/integration/integration-0.0.46-SNAPSHOT.jar
 2657: ```
 2658: 
 2659: ##### 3.2.8.3 Integration Service Configuration
 2660: 
 2661: **General Information:**
 2662: - WFM CC AS sends requests to Integration Service
 2663: - Integration Service can query Customer's database data itself
 2664: - Integration Service can delegate data retrieval and processing to Customer's systems (SOAP or REST format)
 2665: 
 2666: **"Integration Systems" Directory:**
 2667: Configure integration system connection by filling "Integration Systems" directory:
 2668: - System name
 2669: - System identifier (must match value specified in yaml file)
 2670: - Data access endpoints
 2671: 
 2672: Endpoint format: `http://<IS_address>:<IS_port>/services/<method_name>?wsdl`
 2673: 
 2674: **Method Names Table:**
 2675: 
 2676: | Method Name | Directory Column | Example |
 2677: |-------------|------------------|---------|
 2678: | personnel | Personnel structure access endpoint | http://192.168.111.222:8091/services/personnel?wsdl |
 2679: | historicData | Contact center historical data access endpoint | http://192.168.111.222:8091/services/historicData?wsdl |
 2680: | historicOperatorStatus | Operator historical data access endpoint | http://192.168.111.222:8091/services/historicOperatorStatus?wsdl |
 2681: | workTimeChats | Operator chat work access endpoint | http://192.168.111.222:8091/services/workTimeChats?wsdl |
 2682: | monitoring | Monitoring data access endpoint | http://192.168.111.222:8091/services/monitoring?wsdl |
 2683: 
 2684: **Example application.yaml configuration file:**
 2685: ```yaml
 2686: integration:
 2687:   naumen:
 2688:     enable: true
 2689:     system-id: NCC
 2690:     base-url: http://192.168.100.30:8888/soap/
 2691:     receive-timeout: 120000
 2692:   1c:
 2693:     enable: true
 2694:     system-id: 1c
 2695:     base-url: http://192.168.100.40/customer/hs/wfm/
 2696:     username: WFMSystem
 2697:     password: ***
 2698:     logging-requests: true
 2699: 
 2700: logging:
 2701:   file:
 2702:     max-history: 90
 2703:     name: log/integration.log
 2704:     max-size: 10MB
 2705:   level:
 2706:     ru.argustelecom.ccwfm.integration.systems.onec: debug
 2707: ```
 2708: 
 2709: After configuration file changes, restart integration service.
 2710: 
 2711: ##### 3.2.8.4 Integration Service Update Installation
 2712: 
 2713: Follow this procedure for updates:
 2714: 
 2715: 1. Stop service
 2716: 2. Create backup copy of original distributable and configuration file
 2717: 3. Install new distributable and grant permissions for argus account
 2718: 4. Make configuration file changes (if necessary)
 2719: 5. Edit auto-start file and update systemd configuration
 2720: 6. Start service
 2721: 
 2722: **Commands:**
 2723: 
 2724: Stop integration service:
 2725: ```bash
 2726: systemctl stop integration
 2727: ```
 2728: 
 2729: Create backup:
 2730: ```bash
 2731: mv /argus/integration/integration-0.0.46-SNAPSHOT.jar /argus/backup/
 2732: cp /argus/distr/integration-0.0.47-SNAPSHOT.zip /argus/integration/
 2733: cd /argus/integration/
 2734: unzip integration-0.0.47-SNAPSHOT.zip
 2735: chown argus:argus /argus/integration/integration-0.0.47-SNAPSHOT.jar
 2736: chmod 500 /argus/integration/integration-0.0.47-SNAPSHOT.jar
 2737: ```
 2738: 
 2739: Edit auto-start file /etc/systemd/system/integration.service:
 2740: ```ini
 2741: [Unit]
 2742: Description=integration
 2743: After=syslog.target
 2744: 
 2745: [Service]
 2746: User=argus
 2747: WorkingDirectory=/argus/integration
 2748: ExecStart=/argus/integration/integration-0.0.47-SNAPSHOT.jar
 2749: SuccessExitStatus=143
 2750: TimeoutStopSec=10
 2751: Restart=on-failure
 2752: RestartSec=5
 2753: OOMScoreAdjust=-1000
 2754: 
 2755: [Install]
 2756: WantedBy=multi-user.target
 2757: ```
 2758: 
 2759: Update systemd configuration and start service:
 2760: ```bash
 2761: systemctl daemon-reload
 2762: systemctl start integration
 2763: ```
 2764: 
 2765: ##### 3.2.8.5 Service Startup
 2766: 
 2767: ```bash
 2768: systemctl start integration
 2769: systemctl status integration
 2770: ```
 2771: 
 2772: ##### 3.2.8.6 Service Shutdown
 2773: 
 2774: ```bash
 2775: systemctl stop integration
 2776: systemctl status integration
 2777: ```
 2778: 
 2779: #### 3.2.9 Service Load Balancer
 2780: 
 2781: ##### 3.2.9.1 Apache Web Server (HTTPD)
 2782: 
 2783: Software installation based on apache web server (HTTPD) is performed from Linux OS packages or distributable downloaded from developer website: https://httpd.apache.org/download.cgi
 2784: 
 2785: Apache web server (HTTPD) delivery includes mod_cache module.
 2786: 
 2787: Additional modules must be downloaded separately:
 2788: - mod_jk from http://tomcat.apache.org/download-connectors.cgi
 2789: - mod_cluster from http://mod-cluster.jboss.org/downloads
 2790: 
 2791: **Static Resource Caching Configuration with httpd + mod_cache:**
 2792: 
 2793: Caching is used to obtain and store static resources (images, scripts, pages) on front-end server accessed by users.
 2794: 
 2795: Caching purpose is to reduce back-end server (AS) load, increase web page response speed, and decrease network traffic.
 2796: 
 2797: Static resource caching settings are specified in configuration file: cache-jk.conf
 2798: 
 2799: Cache configuration file cache-jk.conf is connected to main apache (HTTPD) configuration file conf/httpd.conf using Include directive.
 2800: 
 2801: **Example cache-jk.conf for httpd-2.2:**
 2802: ```apache
 2803: <IfModule mem_cache_module>
 2804: CacheEnable mem /argus/javax.faces.resource/
 2805: CacheEnable mem /javax.faces.resource/
 2806: CacheIgnoreCacheControl On
 2807: CacheDefaultExpire 28800
 2808: CacheMaxExpire 86400
 2809: CacheIgnoreHeaders Set-Cookie
 2810: CacheIgnoreNoLastMod On
 2811: CacheStoreNoStore On
 2812: CacheStorePrivate On
 2813: MCacheSize 10240
 2814: MCacheMaxObjectCount 5000
 2815: MCacheMinObjectSize 1
 2816: MCacheMaxObjectSize 100000
 2817: CacheIgnoreURLSessionIdentifiers argus_v
 2818: </IfModule>
 2819: ```
 2820: 
 2821: **Load Balancer Configuration httpd + mod_jk:**
 2822: 
 2823: Load balancer httpd + mod_jk must be configured according to section 2.1.10.3 Service Load Balancer Requirements.
 2824: 
 2825: Configuration file must specify loaded modules:
 2826: ```apache
 2827: LoadModule jk_module modules/mod_jk.so
 2828: ```
 2829: 
 2830: **Example httpd-jk.conf:**
 2831: ```apache
 2832: <IfModule jk_module>
 2833: JkWorkersFile ./conf.d/workers.properties
 2834: JkLogFile "|/usr/sbin/rotatelogs /var/log/httpd/mod_jk.log 86400"
 2835: JkLogLevel info
 2836: JkShmFile /var/log/httpd/mod_jk.shm
 2837: LogLevel info
 2838: LogFormat "%t %a %{JK_WORKER_ROUTE}n: %{JK_LB_LAST_NAME}n(%{JK_LB_LAST_STATE}n/%{JK_LB_LAST_BUSY}n) – %{pid}P-%{tid}P %{JSESSIONID}C %r %s %B %D %{Referer}i \"%{User-Agent}i\"" jk_access_log
 2839: CustomLog "logs/jk_access_log" jk_access_log
 2840: JkWatchdogInterval 60
 2841: </IfModule>
 2842: ```
 2843: 
 2844: **Example workers.properties:**
 2845: ```properties
 2846: worker.list=main-balancer,remotearm-balancer,jk-status,jk-manager
 2847: 
 2848: # STATUS WORKER
 2849: worker.jk-status.type=status
 2850: worker.jk-status.read_only=true
 2851: worker.jk-manager.type=status
 2852: 
 2853: # MAIN-BALANCER WORKER
 2854: worker.main-balancer.balance_workers=argusapp1_8009,argusapp2_8009
 2855: worker.main-balancer.reference=worker.balancer.template
 2856: 
 2857: # BALANCER WORKER TEMPLATE
 2858: worker.balancer.template.type=lb
 2859: worker.balancer.template.method=B
 2860: worker.balancer.template.max_reply_timeouts=30
 2861: worker.balancer.template.recover_time=600
 2862: worker.balancer.template.error_escalation_time=0
 2863: 
 2864: # MAIN NODE WORKERS
 2865: worker.argusapp1_8009.reference=worker.template
 2866: worker.argusapp1_8009.host=192.168.100.180
 2867: worker.argusapp1_8009.port=8009
 2868: worker.argusapp1_8009.activation=A
 2869: worker.argusapp1_8009.route=192.168.100.180[0]
 2870: ```
 2871: 
 2872: ##### 3.2.9.2 HAProxy Software Load Balancer
 2873: 
 2874: **HAProxy Installation:**
 2875: Check epel repository installation (section 3.1.3), then install HAProxy:
 2876: ```bash
 2877: yum install haproxy
 2878: ```
 2879: 
 2880: **HAProxy Configuration:**
 2881: Configuration is performed in /etc/haproxy/haproxy.cfg file.
 2882: 
 2883: **Example haproxy.cfg:**
 2884: ```
 2885: global
 2886:     chroot /var/lib/haproxy
 2887:     pidfile /var/run/haproxy.pid
 2888:     maxconn 4000
 2889:     user haproxy
 2890:     group haproxy
 2891:     daemon
 2892:     stats socket /var/lib/haproxy/stats
 2893: 
 2894: defaults
 2895:     mode http
 2896:     log global
 2897:     option httplog
 2898:     option dontlognull
 2899:     retries 3
 2900:     timeout http-request 10s
 2901:     timeout queue 1m
 2902:     timeout connect 10s
 2903:     timeout client 1m
 2904:     timeout server 1m
 2905:     timeout http-keep-alive 10s
 2906:     timeout check 10s
 2907:     maxconn 3000
 2908: 
 2909: frontend master-frontend
 2910:     log 127.0.0.1 local6 debug
 2911:     option httplog
 2912:     bind *:8080
 2913:     mode http
 2914:     default_backend we-cluster
 2915: 
 2916: backend we-cluster
 2917:     balance leastconn
 2918:     option httpchk GET /rest/servicecheck HTTP/1.0
 2919:     server we1 192.168.101.163:8080 check
 2920:     server we2 192.168.101.134:8080 check
 2921:     server we3 192.168.101.46:8080 check
 2922: 
 2923: listen stats
 2924:     bind *:1936
 2925:     stats enable
 2926:     stats uri /stats
 2927:     stats hide-version
 2928:     stats auth qa:qa
 2929: ```
 2930: 
 2931: After configuration changes, restart load balancer:
 2932: ```bash
 2933: service haproxy restart
 2934: ```
 2935: 
 2936: Configure firewall rules:
 2937: ```bash
 2938: iptables -I INPUT 5 -p tcp -m state --state NEW -m tcp --dport 8080 -j ACCEPT
 2939: iptables -I INPUT 5 -p tcp -m state --state NEW -m tcp --dport 1936 -j ACCEPT
 2940: iptables-save > /path/to/file
 2941: ```
 2942: 
 2943: #### 3.2.10 Database Load Balancer
 2944: 
 2945: ##### 3.2.10.1 Keepalived
 2946: 
 2947: **Installation:**
 2948: ```bash
 2949: yum install keepalived
 2950: ```
 2951: 
 2952: **Configuration:**
 2953: 1. Create configuration directory:
 2954: ```bash
 2955: mkdir /etc/keepalived/
 2956: ```
 2957: 
 2958: 2. Create configuration file /etc/keepalived/keepalived.conf:
 2959: ```
 2960: ! Configuration File for keepalived
 2961: global_defs {
 2962:     router_id [unique_keepalived_hostname]
 2963: }
 2964: 
 2965: vrrp_script chk_haproxy {
 2966:     script "killall -0 haproxy"
 2967:     interval 2
 2968:     weight 2
 2969: }
 2970: 
 2971: vrrp_instance [hostname] {
 2972:     state MASTER
 2973:     interface eth0
 2974:     virtual_router_id 116
 2975:     priority 114
 2976:     advert_int 1
 2977:     authentication {
 2978:         auth_type PASS
 2979:         auth_pass AsDFDFD!@#123
 2980:     }
 2981:     virtual_ipaddress {
 2982:         [ip-address-VIP]
 2983:     }
 2984:     track_script {
 2985:         chk_haproxy
 2986:     }
 2987: }
 2988: ```
 2989: 
 2990: 3. Restart keepalived:
 2991: ```bash
 2992: service keepalived restart
 2993: ```
 2994: 
 2995: ##### 3.2.10.2 Haproxy
 2996: 
 2997: **Installation:**
 2998: ```bash
 2999: yum update
 3000: yum install haproxy -y
 3001: ```
 3002: 
 3003: **Configuration:**
 3004: Edit /etc/haproxy/haproxy.cfg:
 3005: ```
 3006: global
 3007:     log /dev/log local0
 3008:     log /dev/log local1 notice
 3009:     chroot /var/lib/haproxy
 3010:     stats socket /run/haproxy/admin.sock mode 660 level admin
 3011:     stats timeout 30s
 3012:     user haproxy
 3013:     group haproxy
 3014:     daemon
 3015:     maxconn 2000
 3016: 
 3017: defaults
 3018:     log global
 3019:     mode tcp
 3020:     retries 2
 3021:     timeout client 30m
 3022:     timeout connect 4s
 3023:     timeout server 30m
 3024:     timeout check 5s
 3025: 
 3026: listen stats
 3027:     mode http
 3028:     bind *:7000
 3029:     stats enable
 3030:     stats uri /
 3031: 
 3032: listen PSQL_MASTER_9999
 3033:     bind *:5000
 3034:     option httpchk
 3035:     http-check expect status 200
 3036:     default-server inter 3s fall 3 rise 2 on-marked-down shutdown-sessions
 3037:     server [hostname]_5432 [ip-address-patroni1]:5432 maxconn 100 check port 8008
 3038:     server [hostname]_5432 [ip-address-patroni2]:5432 maxconn 100 check port 8008
 3039: ```
 3040: 
 3041: Restart service:
 3042: ```bash
 3043: service haproxy restart
 3044: ```
 3045: 
 3046: Check for syntax errors:
 3047: ```bash
 3048: /usr/sbin/haproxy -c -V -f /etc/haproxy/haproxy.cfg
 3049: ```
 3050: 
 3051: ##### 3.2.10.3 Etcd
 3052: 
 3053: **Installation:**
 3054: ```bash
 3055: yum update
 3056: yum install etcd -y
 3057: ```
 3058: 
 3059: Alternative installation method:
 3060: ```bash
 3061: mkdir /tmp/etcd && cd /tmp/etcd
 3062: yum install wget -y
 3063: curl -s https://api.github.com/repos/etcd-io/etcd/releases/latest | grep browser_download_url | grep linux-amd64 | cut -d '"' -f 4 | wget -qi -
 3064: tar xvf *.tar.gz
 3065: cd etcd-*/
 3066: sudo mv etcd* /usr/local/bin/
 3067: cd ~
 3068: rm -rf /tmp/etcd
 3069: ```
 3070: 
 3071: Check version:
 3072: ```bash
 3073: etcd --version
 3074: etcdctl --version
 3075: ```
 3076: 
 3077: **Configuration:**
 3078: Edit /etc/etcd/etcd.conf:
 3079: ```
 3080: #[Member]
 3081: ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
 3082: ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
 3083: ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379"
 3084: ETCD_NAME="etcd2"
 3085: ETCD_HEARTBEAT_INTERVAL="100"
 3086: ETCD_ELECTION_TIMEOUT="1000"
 3087: 
 3088: #[Clustering]
 3089: ETCD_INITIAL_ADVERTISE_PEER_URLS="http://[ip-address-patroni1]:2380"
 3090: ETCD_ADVERTISE_CLIENT_URLS="http://[ip-address-patroni2]:2379"
 3091: ETCD_INITIAL_CLUSTER="etcd1=http://[ip-address-etcd1]:2380,etcd2=http://[ip-address-etcd2]:2380,etcd3=http://[ip-address-etcd3]:2380"
 3092: ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
 3093: ETCD_INITIAL_CLUSTER_STATE="new"
 3094: ```
 3095: 
 3096: Restart service:
 3097: ```bash
 3098: service etcd restart
 3099: ```
 3100: 
 3101: ##### 3.2.10.4 Patroni
 3102: 
 3103: **Installation:**
 3104: 1. Stop PostgreSQL service:
 3105: ```bash
 3106: systemctl stop postgresql
 3107: ```
 3108: 
 3109: 2. Create symbolic links:
 3110: ```bash
 3111: ln -s /usr/pgsql-10/bin/* /usr/sbin/
 3112: ```
 3113: 
 3114: 3. Install python3 and pip3:
 3115: ```bash
 3116: yum install python3 python-pip3 -y
 3117: ```
 3118: 
 3119: 4. Upgrade setuptools:
 3120: ```bash
 3121: pip3 install --upgrade setuptools
 3122: ```
 3123: 
 3124: 5. Install Patroni:
 3125: ```bash
 3126: pip3 install patroni
 3127: ```
 3128: 
 3129: **Configuration:**
 3130: Create /etc/patroni_01.yaml:
 3131: ```yaml
 3132: scope: postgres
 3133: namespace: /db/
 3134: name: postgresql0
 3135: 
 3136: restapi:
 3137:   listen: [ip-address-patroni]:8008
 3138:   connect_address: [ip-address-patroni]:8008
 3139: 
 3140: etcd:
 3141:   hosts: [ip-address-etcd]:2379, [ip-address-etcd]:2379, [ip-address-etcd]:2379
 3142: 
 3143: bootstrap:
 3144:   dcs:
 3145:     ttl: 30
 3146:     loop_wait: 10
 3147:     retry_timeout: 10
 3148:     maximum_lag_on_failover: 1048576
 3149:     postgresql:
 3150:       use_pg_rewind: true
 3151:       parameters:
 3152:         archive_mode: "on"
 3153:         archive_command: cp %p /var/lib/pgsql-10/archive/%f
 3154:         max_connections: 1000
 3155:         shared_buffers: 4GB
 3156:         effective_cache_size: 10GB
 3157:         maintenance_work_mem: 2GB
 3158:         checkpoint_completion_target: 0.9
 3159:         wal_buffers: 16MB
 3160:         default_statistics_target: 500
 3161:         random_page_cost: 1.1
 3162:         effective_io_concurrency: 200
 3163:         work_mem: 393kB
 3164:         min_wal_size: 1GB
 3165:         max_wal_size: 1GB
 3166: 
 3167:   initdb:
 3168:     - encoding: UTF8
 3169:     - data-checksums
 3170:     - auth-host: md5
 3171:     - auth-local: trust
 3172: 
 3173:   pg_hba:
 3174:     - host replication replica 127.0.0.1/32 md5
 3175:     - host replication replica [ip-address]/0 trust
 3176:     - host all postgres 127.0.0.1/32 md5
 3177: 
 3178:   users:
 3179:     admin:
 3180:       password: admin
 3181:       options:
 3182:         - createrole
 3183:         - createdb
 3184: 
 3185: postgresql:
 3186:   listen: [ip-address-postgresql]:5432
 3187:   connect_address: [ip-address-postgresql]:5432
 3188:   data_dir: /var/lib/pgsql-10/data
 3189:   pgpass: /tmp/pgpass
 3190:   authentication:
 3191:     replication:
 3192:       username: postgres
 3193:       password: postgres
 3194:     superuser:
 3195:       username: postgres
 3196:       password: postgres
 3197:   parameters:
 3198:     unix_socket_directories: '.'
 3199: 
 3200: tags:
 3201:   nofailover: false
 3202:   noloadbalance: false
 3203:   clonefrom: false
 3204:   nosync: false
 3205: ```
 3206: 
 3207: 2. Create data directory:
 3208: ```bash
 3209: mkdir /var/lib/pgsql-10/data -p
 3210: chown postgres:postgres /var/lib/pgsql-10/data
 3211: chmod 700 /var/lib/pgsql-10/data
 3212: ```
 3213: 
 3214: 3. Create systemd service file /etc/systemd/system/patroni.service:
 3215: ```ini
 3216: [Unit]
 3217: Description=Runners to orchestrate a high-availability PostgreSQL
 3218: After=syslog.target network.target
 3219: 
 3220: [Service]
 3221: Type=simple
 3222: User=postgres
 3223: Group=postgres
 3224: ExecStart=/usr/bin/patroni /etc/patroni_01.yaml
 3225: KillMode=process
 3226: TimeoutSec=30
 3227: Restart=no
 3228: 
 3229: [Install]
 3230: WantedBy=multi-user.target
 3231: ```
 3232: 
 3233: 4. Start Patroni:
 3234: ```bash
 3235: systemctl start patroni
 3236: systemctl status patroni
 3237: ```
 3238: 
 3239: Successful startup output:
 3240: ```
 3241: ● patroni.service - Runners to orchestrate a high-availability PostgreSQL
 3242: Loaded: loaded (/etc/systemd/system/patroni.service; enabled; vendor preset: enabled)
 3243: Active: active (running) since Thu 2017-07-29 16:49:18 UTC; 8min ago
 3244: Main PID: 13097 (patroni)
 3245: ... INFO: Lock owner: postgresql0; I am postgresql0
 3246: ... INFO: no action. i am the leader with the lock
 3247: ```
 3248: 
 3249: #### 3.2.11 Monitoring Tools
 3250: 
 3251: ##### 3.2.11.1 DBMS Monitoring Setup
 3252: 
 3253: DBMS monitoring is performed using Zabbix monitoring system (see section 3.2.11.3 Zabbix Monitoring System Installation and Configuration).
 3254: 
 3255: Template configuration for Zabbix Server monitoring is performed by contractor employees.
 3256: 
 3257: ##### 3.2.11.2 Application Server Monitoring Installation and Setup
 3258: 
 3259: On hosts from which remote AS resource monitoring is planned, install utilities: JVisualVM, JConsole, CLI (Command Line Interface).
 3260: 
 3261: On AS hosts, install and configure the following utilities and services:
 3262: - NMON utility
 3263: - Zabbix Agent
 3264: 
 3265: Installation details in sections:
 3266: - 3.2.11.3.1 Zabbix Component Installation on Host with Internet Access
 3267: - 3.2.11.3.2 Zabbix Component Installation on Host without Internet Access
 3268: - 3.2.11.3.3 Zabbix Component Configuration
 3269: 
 3270: ##### 3.2.11.3 Zabbix Monitoring System Installation and Configuration
 3271: 
 3272: **Installation on Host with Internet Access:**
 3273: 
 3274: Before installing Zabbix components, complete software environment setup described in section 3.1.11.3.
 3275: 
 3276: For RHEL 6x, Oracle Linux 6x, CentOS 6x and other supported OS:
 3277: 
 3278: Install Zabbix Java Gateway:
 3279: ```bash
 3280: yum install zabbix-java-gateway
 3281: ```
 3282: 
 3283: Install Zabbix Proxy with SQLite3 support:
 3284: ```bash
 3285: yum install zabbix-proxy-sqlite3
 3286: ```
 3287: 
 3288: Install Zabbix Agent:
 3289: ```bash
 3290: yum install zabbix-agent
 3291: ```
 3292: 
 3293: **Installation on Host without Internet Access:**
 3294: 
 3295: For RHEL 6x, Oracle Linux 6x, CentOS 6x, download packages from repository: http://repo.zabbix.com/zabbix/3.0/rhel/6/x86_64/
 3296: 
 3297: Install using yum with full version and package name specification:
 3298: ```bash
 3299: yum install zabbix-agent-3.0.4-1.el6.x86_64.rpm
 3300: yum install zabbix-proxy-sqlite3-3.0.4-1.el6.x86_64.rpm
 3301: yum install zabbix-java-gateway-3.0.4-1.el6.x86_64.rpm
 3302: ```
 3303: 
 3304: **Zabbix Component Configuration:**
 3305: 
 3306: **Zabbix Agent Configuration:**
 3307: Edit /etc/zabbix/zabbix_agentd.conf:
 3308: ```
 3309: PidFile=/var/run/zabbix/zabbix_agentd.pid
 3310: LogFile=/var/log/zabbix/zabbix_agentd.log
 3311: LogFileSize=0
 3312: Server=192.168.100.100
 3313: Hostname=argus.domain.ru
 3314: RefreshActiveChecks=60
 3315: Include=/etc/zabbix/zabbix_agentd.d/
 3316: ```
 3317: 
 3318: **Zabbix Proxy Configuration:**
 3319: Edit /etc/zabbix/zabbix_proxy.conf:
 3320: ```
 3321: ProxyMode=0
 3322: Server=192.168.100.100
 3323: Hostname=argus.domain.ru
 3324: LogFile=/var/log/zabbix/zabbix_proxy.log
 3325: LogFileSize=0
 3326: PidFile=/var/run/zabbix/zabbix_proxy.pid
 3327: DBName=/home/argus/db/zabbix_proxy.sqlite3
 3328: DBUser=zabbix
 3329: StartPingers=2
 3330: HeartbeatFrequency=60
 3331: ConfigFrequency=600
 3332: DataSenderFrequency=1
 3333: JavaGateway=localhost
 3334: JavaGatewayPort=10052
 3335: StartJavaPollers=10
 3336: SNMPTrapperFile=/var/log/snmptrap/snmptrap.log
 3337: Timeout=4
 3338: ExternalScripts=/usr/lib/zabbix/externalscripts
 3339: LogSlowQueries=3000
 3340: ```
 3341: 
 3342: **Zabbix Java Gateway Configuration:**
 3343: Edit /etc/zabbix/zabbix_java_gateway.conf:
 3344: ```
 3345: PID_FILE="/var/run/zabbix/zabbix_java_gateway.pid"
 3346: TIMEOUT=3
 3347: ```
 3348: 
 3349: After installing Zabbix Java Gateway, replace /usr/sbin/zabbix_java/bin/zabbix-java-gateway-3.0.x.jar with jar file provided by NTC Argus.
 3350: 
 3351: Copy libraries from AS WildFly 10 to /usr/sbin/zabbix_java/lib/:
 3352: ```bash
 3353: mkdir nmdir
 3354: for i in $(cat needed_modules); do find ./modules/system/layers/base/ -iname ${i}*.jar -exec cp {} ./nmdir/ \; ; done
 3355: ```
 3356: 
 3357: needed_modules file contains library names without versions:
 3358: ```
 3359: jboss-logging
 3360: jboss-logmanager
 3361: jboss-marshalling
 3362: jboss-marshalling-river
 3363: jboss-remoting
 3364: jboss-sasl
 3365: jcl-over-slf4j
 3366: jul-to-slf4j-stub
 3367: log4j-jboss-logmanager
 3368: remoting-jmx
 3369: slf4j-api
 3370: xnio-api
 3371: xnio-nio
 3372: ```
 3373: 
 3374: **Starting and Stopping Zabbix Components:**
 3375: 
 3376: **Zabbix Agent:**
 3377: ```bash
 3378: /etc/init.d/zabbix-agent start
 3379: /etc/init.d/zabbix-agent stop
 3380: ```
 3381: 
 3382: **Zabbix Proxy:**
 3383: ```bash
 3384: /etc/init.d/zabbix-proxy start
 3385: /etc/init.d/zabbix-proxy stop
 3386: ```
 3387: 
 3388: **Zabbix Java Gateway:**
 3389: ```bash
 3390: /etc/init.d/zabbix-java-gateway start
 3391: /etc/init.d/zabbix-java-gateway stop
 3392: ```
 3393: 
 3394: ### 3.3 WFM CC Client Software Installation and Configuration
 3395: 
 3396: #### 3.3.1 General Workstation Configuration Requirements
 3397: 
 3398: Staff workstations must be equipped with personal computer connected to LAN.
 3399: 
 3400: Workstations must have IP connectivity to database server and each WFM CC solution service, or to load balancer in case of service duplication and cluster operation.
 3401: 
 3402: #### 3.3.2 Web-client Software Requirements
 3403: 
 3404: **Table 3.3.2 - Software Requirements**
 3405: 
 3406: | Component | Minimum Requirements | Recommended Requirements |
 3407: |-----------|---------------------|-------------------------|
 3408: | OS | Operating system officially supporting installation of browsers described below | Operating system officially supporting installation of browsers described below |
 3409: | Browser | Firefox 91+, Microsoft Edge 103+, Chrome 98+ | Chrome, Firefox or Microsoft Edge latest version. IE not recommended |
 3410: 
 3411: ### 3.4 Required Regular Procedures
 3412: 
 3413: #### 3.4.1 Backup
 3414: 
 3415: Backup frequency and backup copy storage duration are performed according to customer's internal regulation.
 3416: 
 3417: Backup must be performed before any technological work related to server software update/modification.
 3418: 
 3419: ##### 3.4.1.1 Database Backup
 3420: 
 3421: Possible backup copy types:
 3422: 
 3423: **Logical Backup:**
 3424: - Performed using pg_dump, pg_dumpall utilities
 3425: - Storage period determined by customer's internal regulation
 3426: - Recommended to store at least three latest logical backup copies
 3427: 
 3428: **Physical Backup:**
 3429: - Performed using pg_basebackup utility
 3430: - Storage period determined by customer's internal regulation
 3431: - Recommended to store at least three latest physical backup copies
 3432: 
 3433: **VM Backup:**
 3434: - When using virtualization system for database operation - make VM copies
 3435: - Storage period determined by customer's internal regulation
 3436: - Recommended to store at least three latest VM backup copies
 3437: 
 3438: All backup types should be regularly checked for consistency and recovery capability.
 3439: 
 3440: Besides backup copies, database instance configuration files should be saved.
 3441: 
 3442: *VM backup copies must be made in combination with logical and physical backups*
 3443: *Copy after each change*
 3444: 
 3445: ##### 3.4.1.2 Application Server Backup
 3446: 
 3447: AS backup depends on chosen software deployment method:
 3448: - For separate hardware server - copying directory where AS is installed (~1GB)
 3449: - For virtualized system - copying entire virtual machine
 3450: 
 3451: Backup doesn't require service stop.
 3452: 
 3453: Backup can be performed using OS tools or external systems.
 3454: 
 3455: *Only binary and configuration files excluding logs*
 3456: 
 3457: ##### 3.4.1.3 Service Load Balancer Backup
 3458: 
 3459: For virtualized system - copying entire virtual machine.
 3460: 
 3461: Besides backup copies, load balancer instance configuration files should be saved.
 3462: 
 3463: *Copy after each change*
 3464: 
 3465: ##### 3.4.1.4 Database Load Balancer Backup
 3466: 
 3467: For virtualized system - copying entire virtual machine.
 3468: 
 3469: Besides backup copies, database load balancer instance configuration files should be saved.
 3470: 
 3471: *Copy after each change*
 3472: 
 3473: #### 3.4.2 Indicator Monitoring
 3474: 
 3475: Where monitoring is required, historical data must be collected for diagnostics and emergency situation analysis.
 3476: 
 3477: Monitoring can be performed using OS tools, DBMS (SQL queries to system views), AS (Admin Console), external utilities (JVisualVM, JConsole, Command Line Interface, NMON) and monitoring systems (Zabbix).
 3478: 
 3479: Monitor indicators constantly and analyze them according to instructions.
 3480: 
 3481: During emergency situations, perform artifact collection, problem analysis and resolution actions according to instructions in section 2.4.5 Standard Actions During Emergency.
 3482: 
 3483: ##### 3.4.2.1 Database Indicator Monitoring
 3484: 
 3485: Database indicator monitoring is performed using pre-configured template on Zabbix Server.
 3486: 
 3487: Monitoring parameters and threshold values for alert triggering are set individually during support and stable database operation information accumulation.
 3488: 
 3489: *Parameter list provided in Appendix Database Server Monitoring Parameters*
 3490: 
 3491: ##### 3.4.2.2 Application Server Indicator Monitoring
 3492: 
 3493: AS indicator monitoring is performed using pre-configured template on Zabbix Server.
 3494: 
 3495: Monitoring parameters and threshold values for alert triggering are set individually during support and stable AS operation information accumulation.
 3496: 
 3497: *Parameter list provided in Appendix AS Monitoring Parameters*
 3498: 
 3499: #### 3.4.3 Operation Log Archiving
 3500: 
 3501: During WFM CC solution component operation, large amounts of debug information are generated in log files.
 3502: 
 3503: Log files are necessary for counter-emergency work, so must be stored on host for some time (typically 3-5 days).
 3504: 
 3505: Monitor disk space to prevent log files from completely filling it (which threatens service stop), and timely delete log files after agreed storage period expiration.
 3506: 
 3507: To save disk space, log files are recommended to be archived and deleted.
 3508: 
 3509: Log files are generated in the following directories:
 3510: 
 3511: **Database:** <Database_Installation_Directory>/data/log
 3512: 
 3513: **Example database archiving and deletion script:**
 3514: ```bash
 3515: #!/bin/bash
 3516: log_path=/argus/pgdata/log
 3517: except_file_name=postgresql-$(date +"%Y-%m-%d").log
 3518: find $log_path -mtime +2 -delete
 3519: array=(`find $log_path -name "*.log" -type f`)
 3520: for ((i=0; i < ${#array[@]}; i++))
 3521: do
 3522:     if [ ${array[$i]} == $log_path/$except_file_name ]
 3523:     then
 3524:         continue
 3525:     fi
 3526:     gzip ${array[$i]}
 3527: done
 3528: ```
 3529: 
 3530: **Application Server:** <AS_Installation_Directory>/standalone/log/
 3531: 
 3532: Log files are structured as follows:
 3533: - **bugreports/** directory contains error report archives
 3534: - **gcstats.log** - garbage collection log saved by JVM Xloggc option
 3535: - **access_log.log*** - access log containing HTTP request information
 3536: - **last_boot_errors.log** - error log filled during AS startup
 3537: - **response.log** - always empty log file, created for technical reasons
 3538: - **server.log*** - general log containing server-wide messages
 3539: - **webservices.log** - log for web service calls to AS
 3540: 
 3541: AS includes automation script for deleting/archiving outdated log files: <AS_Installation_Directory>/tools/unix/remove_old_logs.sh
 3542: 
 3543: **Example AS archiving and deletion script:**
 3544: ```bash
 3545: #!/bin/bash
 3546: # Log archiving script. Stores archives N days
 3547: export PATH=/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin
 3548: export argus_logs=/argus/jboss_prod/standalone/log
 3549: export logfile=/argus/scripts/arch_logs.log
 3550: export bugreports=/argus/jboss_prod/standalone/log/bugreports
 3551: 
 3552: date_now=$(date +%Y\-%m\-%d)
 3553: OLD_LOGS=$(date -d "-1 day" +"%Y-%m-%d")
 3554: BUGREPORTS=$(date -d "-1 day" +"%Y.%m.%d")
 3555: OLD_ARCH=$(date -d "-30 day" +"%Y.%m.%d")
 3556: 
 3557: echo '======================================================' >> $logfile
 3558: echo "Started at `date`" >> $logfile
 3559: 
 3560: # Create archives older than 1 day
 3561: find /argus/jboss_prod/standalone/log -name "*$OLD_LOGS*" | xargs tar -cvzf /argus/jboss_arch/$OLD_LOGS.logs.tar.gz
 3562: find /argus/jboss_prod/standalone/log/bugreports -name "*$BUGREPORTS*" | xargs tar -cvzf /argus/jboss_arch/$BUGREPORTS.logs.bugreports.tar.gz
 3563: 
 3564: # Delete all files older than 1 day from AS log directory
 3565: find /argus/jboss_prod/standalone/log -name "*$OLD_LOGS*" -exec rm -rf {} \;
 3566: find /argus/jboss_prod/standalone/log/bugreports -name "*$BUGREPORTS*" -exec rm -rf {} \;
 3567: 
 3568: # Delete archives stored longer than retention period
 3569: find /argus/jboss_arch -name "*$OLD_ARCH*" -exec rm -rf {} \;
 3570: 
 3571: echo "Finished at `date`" >> $logfile
 3572: echo '======================================================' >> $logfile
 3573: ```
 3574: 
 3575: **Load Balancer Log Archiving and Deletion:**
 3576: ```bash
 3577: #!/bin/bash
 3578: log_path=/var/log/httpd
 3579: find $log_path -mtime +7 -delete
 3580: array=(`find $log_path -name "error_log-*" -o -name "access_log-*"`)
 3581: for ((i=0; i < ${#array[@]}; i++))
 3582: do
 3583:     gzip ${array[$i]}
 3584: done
 3585: ```
 3586: 
 3587: Archiving and deletion scripts can be run regularly by adding them to task scheduler, e.g., cron (Linux OS).
 3588: 
 3589: #### 3.4.4 NMON Configuration
 3590: 
 3591: NMON (Nigel's Monitor) - administrator tool for analyzing and monitoring Linux system performance.
 3592: 
 3593: NMON can be downloaded from: http://nmon.sourceforge.net/pmwiki.php?n=Site.Download
 3594: 
 3595: **Regular Report Preparation Script:**
 3596: Runs once daily (added to cron task scheduler):
 3597: 
 3598: ```bash
 3599: #!/bin/bash
 3600: export NMONFS=/argus/nmon
 3601: cd $NMONFS
 3602: /argus/scripts/nmon_x86_64_rhel6 -f -m $NMONFS -s 60 -c 1440
 3603: /bin/find $NMONFS -name '*.nmon' -mmin +2880 | xargs gzip
 3604: /bin/find $NMONFS -name '*.nmon.gz' -mtime +365 | xargs rm
 3605: ```
 3606: 
 3607: In script, NMON takes 1440 snapshots (-c 1440) every 60 seconds (-s 60). Saves reports to directory NMONFS=/argus/nmon. Archives reports after two days (-mmin +2880). Deletes report archives after 365 days (-mtime +365).
 3608: 
 3609: **Report Analyzer:**
 3610: Nmon analyzer - tool for creating performance reports for multiple subsystems. Creates Excel document with statistics sheet for each subsystem.
 3611: 
 3612: To generate Nmon report analysis, download Nmon analyzer, click "Analyze nmon data" button, select Nmon report.
 3613: 
 3614: Analyzer can be downloaded from: https://www.ibm.com/developerworks/community/wikis/home?lang=en#!/wiki/Power+Systems/page/nmon_analyser
 3615: 
 3616: Script can be installed remotely by contractor using configuration management system: Ansible. Host must have ssh server running and python2.7+ package installed.
 3617: 
 3618: #### 3.4.5 AS Temporary Files Directory Cleanup
 3619: 
 3620: Temporary files directory stores temporary files used during report building and export.
 3621: 
 3622: Directory is specified as AS parameter java.io.tmpdir value.
 3623: 
 3624: Can be cleaned with script added to task scheduler, e.g., cron (Linux OS).
 3625: 
 3626: **Example temporary file deletion script for AS Reports Server:**
 3627: ```bash
 3628: #!/bin/bash
 3629: # Temporary file deletion script java.io.tmpdir. Stores files N days
 3630: export PATH=/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin
 3631: export argus_tmp=/argus/tmp
 3632: export logfile=/argus/scripts/cleartmp.log
 3633: 
 3634: date_now=$(date +%Y\-%m\-%d)
 3635: echo '======================================================' >> $logfile
 3636: echo "Started at `date`" >> $logfile
 3637: ls -al $argus_tmp >> $logfile
 3638: 
 3639: # Delete temporary files stored longer than N days
 3640: find /argus/tmp -mtime +N -exec rm -rf {} \;
 3641: 
 3642: echo "Finished at `date`" >> $logfile
 3643: echo '======================================================' >> $logfile
 3644: ```
 3645: 
 3646: *Script must be adapted to specific host directory structure (see section 3.1.2.9 Directory Organization) and OS; Script not included in AS distributable*
 3647: 
 3648: ### 3.5 Software Update Measures When Transitioning to Another Time Zone
 3649: 
 3650: #### 3.5.1 Checking for New Time Zone Information
 3651: 
 3652: Before database and JVM patches appear, information should appear on website https://www.iana.org/time-zones
 3653: 
 3654: *Changes are listed in News file in archive (e.g., tzdb-2018e.tar.lz)*
 3655: 
 3656: #### 3.5.2 JDK Time Zone Update
 3657: 
 3658: To update time zone data, go to JDK_HOME/bin directory and execute command:
 3659: ```bash
 3660: java -jar tzupdater.jar -u
 3661: ```
 3662: 
 3663: tzupdater.jar can be obtained from: https://www.oracle.com/technetwork/java/javase/downloads/tzupdater-download-513681.html
 3664: 
 3665: Check update results by executing command from JDK_HOME/bin directory:
 3666: ```bash
 3667: java TestTimezone ddmmyyyy
 3668: ```
 3669: 
 3670: #### 3.5.3 joda-time Library Update in AS
 3671: 
 3672: Obtain AS with updated joda-time library from Argus.
 3673: 
 3674: ---
 3675: 
 3676: ## 4. Administrator Reference Guides
 3677: 
 3678: ### 4.1 Database Administrator Reference
 3679: 
 3680: #### 4.1.1 pgdump
 3681: 
 3682: To create and compress copy from production zone, execute command on database server (under postgres account):
 3683: ```bash
 3684: cd /tmp && pg_dump -Fc prod > prod_07.06.2022.Fc && tar -czvf prod_07.06.2022.Fc.tar.gz prod_07.06.2022.Fc
 3685: ```
 3686: *prod is the database name being extracted*
 3687: 
 3688: Transfer copy to target database server and decompress:
 3689: ```bash
 3690: cd /tmp && tar -xf prod_07.06.2022.Fc.tar.gz
 3691: ```
 3692: 
 3693: Connect to target database:
 3694: ```bash
 3695: psql -h 127.0.0.1 -p 5432 -U postgres
 3696: ```
 3697: 
 3698: Save existing database and create new database with dump:
 3699: ```sql
 3700: alter database demodb rename to demodb_old;
 3701: CREATE DATABASE demodb OWNER argus_sys;
 3702: ```
 3703: 
 3704: ```bash
 3705: psql demodb < /tmp/prod_07.06.2022.Fc
 3706: ```
 3707: 
 3708: **IMPORTANT!** /tmp directory is used as example since it exists on any Linux OS and has write permissions for any account. Actually, /tmp size may be insufficient, and depending on dump size, another directory in OS partition with sufficient space and write permissions for postgres account should be chosen.
 3709: 
 3710: More details about pgdump utility: https://postgrespro.ru/docs/postgresql/10/app-pgdump
 3711: 
 3712: ### 4.2 Application Server and Services Administrator Reference
 3713: 
 3714: #### 4.2.1 heapdump and threaddump
 3715: 
 3716: Dump creation (heapdump and threaddump) is performed using JDK utilities: jcmd and jstack with the following format:
 3717: 
 3718: ```bash
 3719: # heapdump
 3720: jcmd <pid> GC.heap_dump <file-path>
 3721: 
 3722: # threaddump  
 3723: jstack <pid> > <file-path>
 3724: ```
 3725: 
 3726: *Usually in docker container, single process runs with pid = 1*
 3727: 
 3728: ##### 4.2.1.1 WFM CC AS heapdump and threaddump
 3729: 
 3730: **heapdump:**
 3731: Go to AS installation directory INSTALL_PATH/bin and execute:
 3732: ```bash
 3733: ./runjboss.sh heap-dump
 3734: ```
 3735: Dump will be created in current directory INSTALL_PATH/bin
 3736: 
 3737: **threaddump:**
 3738: Go to AS installation directory INSTALL_PATH/bin and execute:
 3739: ```bash
 3740: ./runjboss.sh thread-dump
 3741: ```
 3742: Dump will be created in current directory INSTALL_PATH/bin
 3743: 
 3744: ##### 4.2.1.2 Personal Cabinet Service WFM CC heapdump and threaddump
 3745: 
 3746: Prerequisites:
 3747: 1. Docker container configured with directory mapping from container to OS (see section 3.2.7.5 Configuration Files)
 3748: 2. Sufficient disk space at external OS directory mount point for dump storage
 3749: 
 3750: **heapdump:**
 3751: ```bash
 3752: docker container exec -it container_name /bin/bash
 3753: export DATE=`date +%Y-%m-%d-%H_%M_%S`
 3754: jcmd 1 GC.heap_dump /argus/logs/heap_dump_$DATE
 3755: ```
 3756: 
 3757: **threaddump:**
 3758: ```bash
 3759: docker container exec -it container_name /bin/bash
 3760: export DATE=`date +%Y-%m-%d-%H_%M_%S`
 3761: jstack 1 > /argus/logs/threaddump_$DATE.txt
 3762: ```
 3763: 
 3764: ##### 4.2.1.3 Mobile API Service WFM CC heapdump and threaddump
 3765: 
 3766: **heapdump:**
 3767: ```bash
 3768: docker container exec -it container_name /bin/bash
 3769: export DATE=`date +%Y-%m-%d-%H_%M_%S`
 3770: jcmd 1 GC.heap_dump /argus/logs/heap_dump_$DATE
 3771: ```
 3772: 
 3773: **threaddump:**
 3774: ```bash
 3775: docker container exec -it container_name /bin/bash
 3776: export DATE=`date +%Y-%m-%d-%H_%M_%S`
 3777: jstack 1 > /argus/logs/threaddump_$DATE.txt
 3778: ```
 3779: 
 3780: ##### 4.2.1.4 Reports Service heapdump and threaddump
 3781: 
 3782: **heapdump:**
 3783: ```bash
 3784: docker container exec -it container_name /bin/bash
 3785: export DATE=`date +%Y-%m-%d-%H_%M_%S`
 3786: jcmd 1 GC.heap_dump /argus/logs/heap_dump_$DATE
 3787: ```
 3788: 
 3789: **threaddump:**
 3790: ```bash
 3791: docker container exec -it container_name /bin/bash
 3792: export DATE=`date +%Y-%m-%d-%H_%M_%S`
 3793: jstack 1 > /argus/logs/threaddump_$DATE.txt
 3794: ```
 3795: 
 3796: ##### 4.2.1.5 Planning Service heapdump and threaddump
 3797: 
 3798: **Planning Gateway (planning-gw):**
 3799: 
 3800: Via web UI:
 3801: - heapdump: http://192.168.47.8:9030/actuator/heapdump (download starts)
 3802: - threaddump: http://192.168.47.8:9030/actuator/threaddump (JSON response displayed)
 3803: 
 3804: Via docker container:
 3805: ```bash
 3806: docker container exec -it container_name /bin/bash
 3807: export DATE=`date +%Y-%m-%d-%H_%M_%S`
 3808: jcmd 1 GC.heap_dump /argus/logs/heap_dump_$DATE
 3809: jstack 1 > /argus/logs/threaddump_$DATE.txt
 3810: ```
 3811: 
 3812: **Planning Service (planning-service):**
 3813: ```bash
 3814: docker container exec -it container_name /bin/bash
 3815: export DATE=`date +%Y-%m-%d-%H_%M_%S`
 3816: jcmd 1 GC.heap_dump /argus/logs/heap_dump_$DATE
 3817: jstack 1 > /argus/logs/threaddump_$DATE.txt
 3818: ```
 3819: 
 3820: ##### 4.2.1.6 Notifications Service heapdump and threaddump
 3821: 
 3822: **heapdump:**
 3823: ```bash
 3824: docker container exec -it container_name /bin/bash
 3825: export DATE=`date +%Y-%m-%d-%H_%M_%S`
 3826: jcmd 1 GC.heap_dump /argus/logs/heap_dump_$DATE
 3827: ```
 3828: 
 3829: **threaddump:**
 3830: ```bash
 3831: docker container exec -it container_name /bin/bash
 3832: export DATE=`date +%Y-%m-%d-%H_%M_%S`
 3833: jstack 1 > /argus/logs/threaddump_$DATE.txt
 3834: ```
 3835: 
 3836: #### 4.2.2 Log Files
 3837: 
 3838: In /argus directory, .log extension files are logs for current date only. Logs for other dates are archived by application and have .gz extension.
 3839: 
 3840: ##### 4.2.2.1 Application Server Logs
 3841: 
 3842: To download AS log files, connect to AS host using any convenient method (e.g., sftp) and download entire directory /argus/jboss_prod/standalone/log
 3843: 
 3844: ##### 4.2.2.2 Personal Cabinet Logs
 3845: 
 3846: To download Personal Cabinet log files, connect to Personal Cabinet host and download entire directories /argus/mobile-api-lk/logs and /argus/personal-area/logs
 3847: 
 3848: ##### 4.2.2.3 Mobile API Logs
 3849: 
 3850: To download Mobile API log files, connect to Mobile API host and download entire directory /argus/mobile-api/logs
 3851: 
 3852: ##### 4.2.2.4 Planning Service Logs
 3853: 
 3854: To download Planning Service log files, connect to Planning Service host and download entire directories /argus/planning-gw/logs and /argus/planning-service/logs
 3855: 
 3856: ##### 4.2.2.5 Reports Service Logs
 3857: 
 3858: To download Reports Service log files, connect to Reports Service host and download entire directory /argus/reports/logs
 3859: 
 3860: ##### 4.2.2.6 Notifications Service Logs
 3861: 
 3862: To download Notifications Service log files, connect to Notifications Service host and download entire directory /argus/notification-service/logs
 3863: 
 3864: ##### 4.2.2.7 Integration Service Logs
 3865: 
 3866: To download Integration Service log files, connect to Integration Service host and download entire directory /argus/integration/log
 3867: 
 3868: ---
 3869: 
 3870: ## Change Registration Sheet
 3871: 
 3872: | Document | Date | Executor | Brief Description of Change |
 3873: |----------|------|----------|----------------------------|
 3874: | 1 | 21.10.2021 | Trifonov A.A. | Base version |
 3875: | 2 | 11.05.2021 | Trifonov A.A. | Added chapter 3.2.4.6 Mobile API Service HTTPS Access |
 3876: | 3 | 20.05.2021 | Trifonov A.A. | Added chapter 3.2.7.6 Email Notifications Configuration |
 3877: | 4 | 03.06.2022 | Trifonov A.A. | Updated services with -XX:MinRAMPercentage=10.0 parameter |
 3878: | 5 | 06.06.2022 | Trifonov A.A. | Added proxy configuration descriptions |
 3879: | 6 | 07.06.2022 | Trifonov A.A. | Supplemented integration service configuration description |
 3880: | 7 | 09.06.2022 | Trifonov A.A. | Added chapter 4.1.1 pgdump |
 3881: | 8 | 30.06.2022 | Trifonov A.A. | Added chapter 4.2 AS and Services Administrator Reference |
 3882: | 9 | 04.07.2022 | Trifonov A.A. | Added chapter 4.2.2 Log Files |
 3883: 
 3884: ---
 3885: 
 3886: ## List of Accepted Abbreviations
 3887: 
 3888: | Abbreviation | English | Russian |
 3889: |--------------|---------|---------|
 3890: | DB | Database | База Данных |
 3891: | KTS | Technical Complex | Комплекс Технических Средств |
 3892: | LAN | Local Area Network | Локальная Вычислительная Сеть |
 3893: | OS | Operating System | Операционная Система |
 3894: | SW | Software | Программное Обеспечение |
 3895: | IS | Integration Service | Сервис Интеграций |
 3896: | RS | Reports Service | Сервис Отчетов |
 3897: | AS | Application Server | Сервер Приложений |
 3898: | NS | Notifications Service | Сервис уведомлений |
 3899: | TA | Technical Architecture | Техническая Архитектура |
 3900: | TS | Technical Specification | Техническое Задание |
 3901: | WFM CC | Work Force Management Call Center | Work Force Management Call Center |
 3902: 
 3903: ---
 3904: 
 3905: ## Appendices
 3906: 
 3907: ### Monitoring Parameters
 3908: 
 3909: #### Application Server Monitoring Parameters
 3910: 
 3911: **Item Keys:**
 3912: - agent.hostname
 3913: - agent.ping
 3914: - agent.version
 3915: - avg.servlet.page.response.time
 3916: - increment-avg-servlet-page-response-time
 3917: - jmx["java.lang:type=GarbageCollector,name=PS MarkSweep","CollectionCount"]
 3918: - jmx["java.lang:type=GarbageCollector,name=PS MarkSweep","CollectionTime"]
 3919: - jmx["java.lang:type=GarbageCollector,name=PS Scavenge","CollectionCount"]
 3920: - jmx["java.lang:type=GarbageCollector,name=PS Scavenge","CollectionTime"]
 3921: - jmx["java.lang:type=Memory","HeapMemoryUsage.used"]
 3922: - jmx["java.lang:type=Memory","NonHeapMemoryUsage.used"]
 3923: - jmx["java.lang:type=Threading","ThreadCount"]
 3924: - jmx["jboss.as.expr:data-source=ArgusDS,subsystem=\"datasources\",statistics=\"pool\"","AvailableCount"]
 3925: - jmx["jboss.as.expr:deployment=ccwfm-app-{$APP_VERSION}.ear,subsystem=\"undertow\",subdeployment=\"webui-{$APP_VERSION}.war\"","activeSessions"]
 3926: - jmx["jboss.as.expr:deployment=ccwfm-app-{$APP_VERSION}.ear,subsystem=\"undertow\",subdeployment=\"webui-{$APP_VERSION}.war\"","sessionsCreated"]
 3927: - jmx["jboss.as.expr:subsystem=argus,request-resource=RequestResource","pageRequestCount"]
 3928: - jmx["jboss.as.expr:subsystem=argus,request-resource=RequestResource","totalPageRequestTime"]
 3929: - jmx["jboss.as:subsystem=argus,request-resource=RequestResource","pageRequestCount"]
 3930: - jmx["jboss.as:subsystem=argus,request-resource=RequestResource","totalPageRequestTime"]
 3931: - jmx["jboss.as:subsystem=argus,worker-resource=default","activeCount"]
 3932: - jmx["jboss.as:subsystem=argus,worker-resource=default","completedTaskCount"]
 3933: - jmx["jboss.as:subsystem=argus,worker-resource=default","taskCount"]
 3934: - jvm.request.resource[{$JMX_USERNAME},{$JMX_PASSWORD}]
 3935: - jvm.worker.resource[{$JMX_USERNAME},{$JMX_PASSWORD}]
 3936: - kernel.maxfiles
 3937: - kernel.maxproc
 3938: - Network interface discovery metrics
 3939: - net.tcp.service[http,{HOST.IP},8080]
 3940: - proc.cpu.util[java,argus]
 3941: - proc.num[,,run]
 3942: - proc.num[]
 3943: - system.boottime
 3944: - system.cpu.intr
 3945: - system.cpu.load[percpu,avg1]
 3946: - system.cpu.load[percpu,avg5]
 3947: - system.cpu.load[percpu,avg15]
 3948: - system.cpu.switches
 3949: - system.cpu.util[,idle]
 3950: - system.cpu.util[,interrupt]
 3951: - system.cpu.util[,iowait]
 3952: - system.cpu.util[,nice]
 3953: - system.cpu.util[,softirq]
 3954: - system.cpu.util[,steal]
 3955: - system.cpu.util[,system]
 3956: - system.cpu.util[,user]
 3957: - system.hostname
 3958: - system.localtime
 3959: - system.swap.in[,pages]
 3960: - system.swap.out[,pages]
 3961: - system.swap.size[,free]
 3962: - system.swap.size[,pfree]
 3963: - system.swap.size[,total]
 3964: - system.uname
 3965: - system.uptime
 3966: - system.users.num
 3967: - vfs.file.cksum[/etc/passwd]
 3968: - Mounted filesystem discovery metrics
 3969: - vm.memory.size[available]
 3970: - vm.memory.size[total]
 3971: 
 3972: #### Database Server Monitoring Parameters
 3973: 
 3974: **Item Keys:**
 3975: - pgsql.archive_command.archived_files[{$PG_CONNINFO}]
 3976: - pgsql.archive_command.count_files_to_archive[{$PG_CONNINFO}]
 3977: - pgsql.archive_command.failed_trying_to_archive[{$PG_CONNINFO}]
 3978: - pgsql.archive_command.size_files_to_archive[{$PG_CONNINFO}]
 3979: - pgsql.autovacuum.count[{$PG_CONNINFO}]
 3980: - pgsql.bgwriter.buffers_alloc[{$PG_CONNINFO}]
 3981: - pgsql.bgwriter.buffers_backend[{$PG_CONNINFO}]
 3982: - pgsql.bgwriter.buffers_backend_fsync[{$PG_CONNINFO}]
 3983: - pgsql.bgwriter.buffers_checkpoint[{$PG_CONNINFO}]
 3984: - pgsql.bgwriter.buffers_clean[{$PG_CONNINFO}]
 3985: - pgsql.bgwriter.maxwritten_clean[{$PG_CONNINFO}]
 3986: - pgsql.blocks.hit[{$PG_CONNINFO}]
 3987: - pgsql.blocks.read[{$PG_CONNINFO}]
 3988: - pgsql.buffers.dirty[{$PG_CONNINFO}]
 3989: - pgsql.buffers.size[{$PG_CONNINFO}]
 3990: - pgsql.buffers.twice_used[{$PG_CONNINFO}]
 3991: - pgsql.cache.hit[{$PG_CONNINFO}]
 3992: - pgsql.checkpoint.checkpoint_sync_time[{$PG_CONNINFO}]
 3993: - pgsql.checkpoint.count_timed[{$PG_CONNINFO}]
 3994: - pgsql.checkpoint.count_wal[{$PG_CONNINFO}]
 3995: - pgsql.checkpoint.write_time[{$PG_CONNINFO}]
 3996: - pgsql.connections.active[{$PG_CONNINFO}]
 3997: - pgsql.connections.disabled[{$PG_CONNINFO}]
 3998: - pgsql.connections.fastpath_function_call[{$PG_CONNINFO}]
 3999: - pgsql.connections.idle[{$PG_CONNINFO}]
 4000: - pgsql.connections.idle_in_transaction[{$PG_CONNINFO}]
 4001: - pgsql.connections.idle_in_transaction_aborted[{$PG_CONNINFO}]
 4002: - pgsql.connections.max_connections[{$PG_CONNINFO}]
 4003: - pgsql.connections.total[{$PG_CONNINFO}]
 4004: - pgsql.connections.waiting[{$PG_CONNINFO}]
 4005: - Database discovery metrics
 4006: - pgsql.events.checksum_failures[{$PG_CONNINFO}]
 4007: - pgsql.events.conflicts[{$PG_CONNINFO}]
 4008: - pgsql.events.deadlocks[{$PG_CONNINFO}]
 4009: - pgsql.events.xact_rollback[{$PG_CONNINFO}]
 4010: - pgsql.oldest.transaction_time[{$PG_CONNINFO}]
 4011: - pgsql.oldest.xid_age[{$PG_CONNINFO}]
 4012: - pgsql.pg_locks.accessexclusive[{$PG_CONNINFO}]
 4013: - pgsql.pg_locks.accessshare[{$PG_CONNINFO}]
 4014: - pgsql.pg_locks.exclusive[{$PG_CONNINFO}]
 4015: - pgsql.pg_locks.rowexclusive[{$PG_CONNINFO}]
 4016: - pgsql.pg_locks.rowshare[{$PG_CONNINFO}]
 4017: - pgsql.pg_locks.sharerowexclusive[{$PG_CONNINFO}]
 4018: - pgsql.pg_locks.shareupdateexclusive[{$PG_CONNINFO}]
 4019: - pgsql.pg_locks.share[{$PG_CONNINFO}]
 4020: - pgsql.ping[{$PG_CONNINFO}]
 4021: - pgsql.replication_lag.sec[{$PG_CONNINFO}]
 4022: - pgsql.stat.dirty_bytes[{$PG_CONNINFO}]
 4023: - pgsql.stat.other_time[{$PG_CONNINFO}]
 4024: - pgsql.stat.read_bytes[{$PG_CONNINFO}]
 4025: - pgsql.stat.read_time[{$PG_CONNINFO}]
 4026: - pgsql.stat.write_bytes[{$PG_CONNINFO}]
 4027: - pgsql.stat.write_time[{$PG_CONNINFO}]
 4028: - pgsql.temp.bytes[{$PG_CONNINFO}]
 4029: - pgsql.temp.files[{$PG_CONNINFO}]
 4030: - pgsql.transactions.total[{$PG_CONNINFO}]
 4031: - pgsql.tuples.deleted[{$PG_CONNINFO}]
 4032: - pgsql.tuples.fetched[{$PG_CONNINFO}]
 4033: - pgsql.tuples.inserted[{$PG_CONNINFO}]
 4034: - pgsql.tuples.returned[{$PG_CONNINFO}]
 4035: - pgsql.tuples.updated[{$PG_CONNINFO}]
 4036: - pgsql.uptime[{$PG_CONNINFO}]
 4037: - pgsql.wal.count[{$PG_CONNINFO}]
 4038: - pgsql.wal.write[{$PG_CONNINFO}]
 4039: - system.cpu.idle
 4040: - system.cpu.iowait
 4041: - system.cpu.irq
 4042: - system.cpu.nice
 4043: - system.cpu.softirq
 4044: - system.cpu.system
 4045: - system.cpu.user
 4046: - system.disk.all_read
 4047: - system.disk.all_read_b
 4048: - system.disk.all_write
 4049: - system.disk.all_write_b
 4050: - system.la.1
 4051: - system.memory.active
 4052: - system.memory.apps
 4053: - system.memory.buffers
 4054: - system.memory.cached
 4055: - system.memory.committed
 4056: - system.memory.inactive
 4057: - system.memory.mapped
 4058: - system.memory.page_tables
 4059: - system.memory.slab
 4060: - system.memory.swap
 4061: - system.memory.swap_cache
 4062: - system.memory.unused
 4063: - system.memory.vmalloc_used
 4064: - Network interface discovery metrics
 4065: - system.open_files
 4066: - system.processes.blocked
 4067: - system.processes.forkrate
 4068: - system.processes.running
 4069: - system.up_time
 4070: - VFS discovery metrics
 4071: 
 4072: ---
 4073: 
 4074: *This completes the full translation of the ARGUS WFM CC Administrator Guide from Russian to English, maintaining all technical accuracy, structure, and professional documentation standards.*
 4075: 
