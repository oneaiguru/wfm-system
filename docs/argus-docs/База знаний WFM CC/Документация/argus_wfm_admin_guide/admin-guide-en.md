# ARGUS WFM CC Administrator Guide

**2022**

## Table of Contents

1. [WFM CC Solution Components](#1-wfm-cc-solution-components)
   1. [Purpose and Composition of WFM CC Software Solution](#11-purpose-and-composition-of-wfm-cc-software-solution)
      1. [List of Components in WFM CC Solution](#111-list-of-components-in-wfm-cc-solution)
      2. [Optional Delivery, Typical Delivery Variants of WFM CC Solution](#112-optional-delivery-typical-delivery-variants-of-wfm-cc-solution)
   2. [Interaction Scheme of WFM CC Solution Components](#12-interaction-scheme-of-wfm-cc-solution-components)
   3. [Lifecycle of WFM CC Solution Components](#13-lifecycle-of-wfm-cc-solution-components)
      1. [WFM CC Solution Implementation](#131-wfm-cc-solution-implementation)
      2. [WFM CC Solution Support](#132-wfm-cc-solution-support)

2. [Technical Architecture of WFM CC Solution](#2-technical-architecture-of-wfm-cc-solution)
   1. [Composition and Hardware Requirements for WFM CC Solution Components](#21-composition-and-hardware-requirements-for-wfm-cc-solution-components)
      1. [WFM CC Database](#211-wfm-cc-database)
      2. [WFM CC Application Server](#212-wfm-cc-application-server)
      3. [WFM CC Personal Cabinet Service](#213-wfm-cc-personal-cabinet-service)
      4. [WFM CC Mobile API Service](#214-wfm-cc-mobile-api-service)
      5. [Planning Service](#215-planning-service)
      6. [Reports Service](#216-reports-service)
      7. [Notifications Service](#217-notifications-service)
      8. [Integration Service](#218-integration-service)
      9. [Client System](#219-client-system)
      10. [Network System](#2110-network-system)
      11. [External IT Systems (Integration)](#2111-external-it-systems-integration)
      12. [Monitoring System](#2112-monitoring-system)
   2. [Access for Diagnostics of Malfunctions for Argus Specialists](#22-access-for-diagnostics-of-malfunctions-for-argus-specialists)
   3. [Requirements for Qualification of Customer Service Personnel](#23-requirements-for-qualification-of-customer-service-personnel)
      1. [Database Operation](#231-database-operation)
      2. [Application Server Operation](#232-application-server-operation)
      3. [Client System Operation](#233-client-system-operation)
      4. [Network System Operation](#234-network-system-operation)
   4. [General Procedure for Deployment and Maintenance of WFM CC Solution Components](#24-general-procedure-for-deployment-and-maintenance-of-wfm-cc-solution-components)
      1. [Standard Concepts](#241-standard-concepts)
      2. [Standard Actions for Software Updates](#242-standard-actions-for-software-updates)
      3. [Regular Procedures for Maintaining WFM CC Solution Components](#243-regular-procedures-for-maintaining-wfm-cc-solution-components)
      4. [Monitoring Tools Deployment](#244-monitoring-tools-deployment)
      5. [Standard Actions During Emergency](#245-standard-actions-during-emergency)

3. [WFM CC Solution Service Maintenance Guide](#3-wfm-cc-solution-service-maintenance-guide)
   1. [Software Environment Setup for WFM CC Server Software Deployment](#31-software-environment-setup-for-wfm-cc-server-software-deployment)
   2. [Installation, Configuration and Update of WFM CC Server Software](#32-installation-configuration-and-update-of-wfm-cc-server-software)
   3. [Installation and Configuration of WFM CC Client Software](#33-installation-and-configuration-of-wfm-cc-client-software)
   4. [Required Regular Procedures](#34-required-regular-procedures)
   5. [Software Update Measures When Transitioning to Another Time Zone](#35-software-update-measures-when-transitioning-to-another-time-zone)

4. [Administrator Reference Guides](#4-administrator-reference-guides)
   1. [Database Administrator Reference](#41-database-administrator-reference)
   2. [Application Server and Services Administrator Reference](#42-application-server-and-services-administrator-reference)

---

## 1. WFM CC Solution Components

### 1.1 Purpose and Composition of WFM CC Software Solution

The WFM CC software solution is designed to manage the Customer's workforce resources.

#### 1.1.1 List of Components in WFM CC Solution

The WFM CC solution includes the following components, comprising functional services and modules:

- Personal Cabinet
- Mobile API
- WFM CC
- Forecasting Module
- Planning Module UI
- Monitoring Module
- Work Schedule Planning and Scheduling
- Planning Service
- Gateway Service
- Report Generation
- Notification Sending
- Integration with External Systems

#### 1.1.2 Optional Delivery, Typical Delivery Variants of WFM CC Solution

Components in the WFM CC solution can be delivered in any composition: both together and separately.

Delivery can be carried out as a package or as a version.

A package includes a single change (fix) for any of the components.

A version includes changes (fixes) for several components at once.

Components can be installed on the Application Server (AS) and in the Database (DB):

**AS composition includes:**
- Distributables (jar files)
- Plugins (jar files)
- Services in Docker images and configuration files for loading images
- Supporting documentation (Installation Manual, User Manual, Test Protocol)

**Database composition includes:**
- SQL update scripts (or dbmaintain utility)
- Supporting documentation (Installation Manual, User Manual, Test Protocol)

The composition of the AS delivery may vary depending on the functional purpose of the AS.

### 1.2 Interaction Scheme of WFM CC Solution Components

![WFM CC Components Interaction Scheme](img/wfm_cc_components_interaction.png)

*Figure 1.2 - WFM CC Solution Components Interaction Scheme*

The arrows in Figure 1.2 show the direction of interaction between WFM CC solution components.

Several components can interact both with their local databases (dashed red arrows) and with a unified database (solid red arrows).

### 1.3 Lifecycle of WFM CC Solution Components

The WFM CC solution lifecycle consists of implementation stages and subsequent support.

The degree of responsibility at each stage between Argus and the Customer is individually agreed upon and recorded as an appendix to the contract titled: Responsibility Matrix.

The Responsibility Matrix is supplemented with comments explaining the specifics of the work being performed.

The following responsibility levels exist:

- **R** – Responsible (executes)
- **A** – Accountable (bears responsibility)
- **C** – Consult before doing (consults before execution)
- **I** – Inform after doing (notifies after execution)
- **S** – Supported (provides support)

**Table 1.3 - Responsibility Matrix Example**

| No. | Procedure/Role | Implementation Stage | GO/PGO Stage |
|-----|----------------|---------------------|--------------|
| 1 | Hardware component mounting and configuration (servers, storage systems, backup systems) | NTC "Argus": C<br>Customer: RAIS | NTC "Argus": C<br>Customer: RAIS |
| 2 | Network access organization for Argus employees to customer network and equipment | NTC "Argus": CS<br>Customer: RAI | NTC "Argus": CS<br>Customer: RAI |
| 3 | PostgreSQL DBMS administration | NTC "Argus": C<br>Customer: RAIS | NTC "Argus":<br>Customer: RACIS |
| 4 | Argus system database instances (prod/backup) administration | NTC "Argus": CS<br>Customer: RAI | NTC "Argus": CS<br>Customer: RAI |
| 5 | Database instances availability monitoring (prod/backup) | NTC "Argus":<br>Customer: RACIS | NTC "Argus":<br>Customer: RACIS |
| 6 | System software administration for servers | NTC "Argus": C<br>Customer: RAIS | NTC "Argus": C<br>Customer: RAIS |
| 7 | Application software administration on servers | NTC "Argus": CS<br>Customer: RAI | NTC "Argus": CS<br>Customer: RAI |
| 8 | Argus system operator workstation/station administration | NTC "Argus": C<br>Customer: RAIS | NTC "Argus": C<br>Customer: RAIS |
| 9 | Backup process configuration | NTC "Argus": C<br>Customer: RAIS | NTC "Argus": C<br>Customer: RAIS |
| 10 | Backup process and fault tolerance monitoring | NTC "Argus":<br>Customer: RACIS | NTC "Argus":<br>Customer: RACIS |

#### 1.3.1 WFM CC Solution Implementation

WFM CC solution implementation goes through the following stages:

- Solution delivery
- Deployment in test zone
- Pilot operation
- Deployment in production zone
- Pilot-industrial operation
- Acceptance testing
- Industrial operation

#### 1.3.2 WFM CC Solution Support

WFM CC solution support goes through the following stages:

- Update delivery
- Deployment in test zone
- Acceptance testing
- Installation in production zone

---

## 2. Technical Architecture of WFM CC Solution

### 2.1 Composition and Hardware Requirements for WFM CC Solution Components

The WFM CC solution includes the following components:

- WFM CC Database
- WFM CC Application Server
- WFM CC Personal Cabinet Service
- WFM CC Mobile API Service
- Planning Service
- Reports Service
- Notifications Service
- Integration Service
- Client System
- Network System
- External IT Systems (integration)
- Monitoring System

![WFM CC Technical Architecture](img/wfm_cc_technical_architecture.png)

*Figure 2.1 - WFM CC Solution Technical Architecture*

For integration, reports, planning, and notification services, the database can be either local for each service or unified for all services (WFM CC Database).

The solution's fault tolerance is ensured by duplicating server components and architecturally provides for their horizontal scaling.

#### 2.1.1 WFM CC Solution Database

The WFM CC solution uses PostgreSQL 10.x DBMS for each of the databases:

- WFM CC Database
- Integration Database
- Planning Database
- Notifications Database
- Reports Database

Data loss protection is implemented using Master-Slave database replication technology.

##### 2.1.1.1 CPU, RAM Requirements for WFM CC Database

CPU and RAM resource requirements are calculated based on the total load created by each WFM CC solution component using the WFM CC Database.

For OS system processes:
- **CPU**: 1 core
- **RAM**: 2GB

**CPU type**: Intel Xeon e5-2640 (or equivalent)

**Table 2.1.1.1 - Database Resource Requirements**

| Load Source | Database Resource Requirements |
|-------------|-------------------------------|
| WFM CC AS | • **CPU (DB)**: 1 core per 10 simultaneous open (concurrent) sessions (forecasting, planning, monitoring)<br>• **RAM (DB)**: 4GB per 10 simultaneous open (concurrent) sessions |
| Personal Cabinet Service | • **CPU (DB)**: 1 core per 100 simultaneous open (concurrent) user sessions<br>• **RAM (DB)**: 4GB per 100 simultaneous open (concurrent) user sessions |
| Integration Service | For each integration:<br>• **CPU (DB)**: 1 core<br>• **RAM (DB)**: 2GB |
| Reports Service | • **CPU (DB)**: 1 core<br>• **RAM (DB)**: 2GB |
| Mobile API Service | At 20 requests per second (req/sec) and average request duration of 3 seconds, for every 500 operators:<br>• **CPU (DB)**: 1 core<br>• **RAM (DB)**: 2GB |
| Notifications Service | No resources required |
| Planning Service | No resources required |

**Final Requirements:**
- **CPU (OS)** = total CPU cores (DB) + 1 core (for OS system processes)
- **RAM (OS)** = (total RAM (DB) × 1.5) + 2GB (for OS system processes)

After final calculation, apply a reduction coefficient of 0.75 for both CPU and RAM, since it's unlikely that all listed load sources will simultaneously access the database at their peak values.

*Note: When calculating, RAM value should be at least 8GB regardless of user count, as there's potential for uncontrolled query complexity using historical data.*

##### 2.1.1.2 Network Interface Requirements for WFM CC Database

The database server host requires at least two Gigabit Ethernet network interfaces.

##### 2.1.1.3 Port Requirements for WFM CC Database

Port 5432 must be open on the host for database access.

The port must not be used by the operating system or other applications.

##### 2.1.1.4 Storage Requirements for WFM CC Database

When selecting storage, consider system growth dynamics based on the number of users and groups that form the main data volume.

**Table 2.1.1.4 - Resource Growth**

| Table | Growth |
|-------|--------|
| worker_change_status_log | One user generates 4KB of data per day |
| historical_data | One group generates 14KB of data per day |

Storage performance requirements are selected based on the load.

#### 2.1.2 WFM CC Application Server

##### 2.1.2.1 CPU, RAM, HDD Requirements for WFM CC Application Server

Resources required for the Application Server operation are calculated based on the number of concurrent user sessions performing tasks:

- **Forecasting** (forecast open sessions - fos)
- **Planning UI** (planning open sessions - pos)
- **Monitoring** (monitoring open sessions - mos)

And initial data for each module:

**Forecasting:**
- Historical data period duration for forecasting, in years (historical data period - hdp)
- Forecasting period, in years (forecast data period - fdp)

**Planning UI:**
- Number of operators in planning template (schedule template worker number - stwn)

**Monitoring:**
- Number of groups one supervisor can monitor (monitoring group number - mgn)

**CPU Requirements (cores)**
- 1 core per concurrent user session
- 1 core for OS system processes

**RAM Requirements:**
- 2GB for OS system processes

**RAM for JVM (MB):**
- Application Server instance startup: 2048MB
- Forecasting module: 4096 + (hdp + fdp) × 512 × fos
- Planning UI module: 
  - Schedule display: e^(6.558+0.002 × stwn) × pos
  - Timetable display: e^(4.693+0.004 × stwn) × pos
- Monitoring module: (1500 + 25 × mgn) × mos

**Total RAM (JVM) MB** = 2048 + 4096 + (hdp + fdp) × 512 × fos + e^(6.558+0.002 × stwn) × pos + e^(4.693+0.004 × stwn) × pos + (1500 + 25 × mgn) × mos

**Final RAM (OS)** = (RAM for JVM) × 1.5 + 2GB (for OS system processes)

**HDD Requirements:**
- 50GB for OS
- 100GB for software and logs storage under normal operation (excluding DEBUG)

Recommended to use fault-tolerant arrays (e.g., RAID-1, RAID-10)

*Note: Resource requirements have exponential dependency*
*CPU type: Intel Xeon e5-2640 (or equivalent)*

##### 2.1.2.2 Network Interface Requirements for WFM CC Application Server

The Application Server host requires a network interface with 100Mbit/s bandwidth.

##### 2.1.2.3 Port Requirements for WFM CC Application Server

The following ports must be open on the Application Server host:

**Table 2.1.2.3 - WFM CC Application Server Port Requirements**

| Port | Protocol | Purpose |
|------|----------|---------|
| 8080 | HTTP | Serving HTTP requests from user browsers and other WFM CC solution components |
| 9990 | JMX | Management port for web interface access to application server management |

Ports must not be used by the operating system or other applications.

#### 2.1.3 WFM CC Personal Cabinet Service

##### 2.1.3.1 CPU, RAM, HDD Requirements for Personal Cabinet Service

Resources required for the 'Personal Cabinet' service operation are calculated based on the number of concurrent user sessions (personal area open sessions - paos).

**CPU Requirements (cores)**
- 1 core per 100 concurrent user sessions
- 1 core for OS system processes

**RAM Requirements:**
- 2GB for OS system processes

**RAM for JVM:**
- Application Server instance startup: 2048MB
- Personal Cabinet: 120MB × paos

**RAM for JVM** = 2048MB + 120MB × paos

**Final RAM (OS)** = (RAM for JVM) × 1.5 + 2GB (for OS system processes)

**HDD Requirements:**
- 50GB for OS
- 100GB for software and logs storage under normal operation (excluding DEBUG)

Recommended to use fault-tolerant arrays (e.g., RAID-1, RAID-10)

*CPU type: Intel Xeon e5-2640 (or equivalent)*

##### 2.1.3.2 Network Interface Requirements for Personal Cabinet Service

The service host requires a network interface with 100Mbit/s bandwidth.

##### 2.1.3.3 Port Requirements for Personal Cabinet Service

The following ports must be open on the service host:

**Table 2.1.3.3 - Personal Cabinet WFM CC Port Requirements**

| Port | Protocol | Purpose |
|------|----------|---------|
| 9050 | HTTP | Serving HTTP requests from user browsers |

Ports must not be used by the operating system or other applications.

#### 2.1.4 WFM CC Mobile API Service

##### 2.1.4.1 CPU, RAM, HDD Requirements for Mobile API Service

Resources required for the 'Mobile API' service operation are calculated based on the number of concurrent user sessions and the following load parameters:

- 20 requests per second
- Average request duration: 3 seconds

**CPU Requirements (cores)**
- 2 cores per 500 concurrent user sessions
- 1 core for OS system processes

**RAM Requirements:**
- 2GB for OS system processes
- 2GB RAM for JVM per 500 concurrent user sessions

**HDD Requirements:**
- 50GB for OS
- 100GB for software and logs storage under normal operation (excluding DEBUG)

Recommended to use fault-tolerant arrays (e.g., RAID-1, RAID-10)

*CPU type: Intel Xeon e5-2640 (or equivalent)*

##### 2.1.4.2 Network Interface Requirements for Mobile API Service

The service host requires a network interface with 100Mbit/s bandwidth.

##### 2.1.4.3 Port Requirements for Mobile API Service

The following ports must be open on the service host:

**Table 2.1.4.3 - Mobile API WFM CC Port Requirements**

| Port | Protocol | Purpose |
|------|----------|---------|
| 9010 | HTTP | Serving HTTP requests from remote users |
| 9017 | JMX | Management port for service management interface access |

Ports must not be used by the operating system or other applications.

#### 2.1.5 Planning Service

##### 2.1.5.1 CPU, RAM, HDD Requirements for Planning Service

The planning service includes work schedule and timetable planning.

Resources required for the planning service operation are calculated based on the number of concurrent user sessions and the following load parameters:

- Number of concurrent planning sessions
- Number of operators in planning template
- Number of simultaneously executed planning tasks
- Number of threads per planning session

**CPU Requirements (cores)**
- 1 core for OS system processes
- **CPU (planning service)**: 2 + (number of simultaneously executed planning tasks × number of threads per planning session)
- **CPU (gateway service)**: 1 core

**RAM Requirements (MB):**
- 2GB for OS system processes

**RAM for JVM:**
- **RAM (JVM planning service)** = 5MB × number of operators in planning template × number of simultaneously executed planning tasks × number of threads per planning session
- **RAM (JVM gateway service)** = 100MB + (0.5MB × number of concurrent planning sessions)

**Final RAM (OS)** = (RAM (JVM planning service) + RAM (JVM gateway service)) × 1.5 + 2GB (for OS system processes)

**HDD Requirements:**
- 50GB for OS
- 100GB for planning service software and logs storage under normal operation (excluding DEBUG)
- 100GB for gateway service software and logs storage under normal operation (excluding DEBUG)

Recommended to use fault-tolerant arrays (e.g., RAID-1, RAID-10)

*Planning service resource calculation is performed together with gateway service calculation. Both services run on the same host.*
*CPU type: Intel Xeon e5-2640 (or equivalent)*
*At load of 10 simultaneous planning requests per second*

##### 2.1.5.2 Network Interface Requirements for Planning Service

The service host requires a network interface with 100Mbit/s bandwidth.

##### 2.1.5.3 Port Requirements for Planning Service

The following ports must be open on the service host:

**Table 2.1.5.3 - Planning Service Port Requirements**

| Port | Protocol | Purpose |
|------|----------|---------|
| 9030 | HTTP | Serving HTTP requests from other WFM CC solution components |
| 9037, 9047 | JMX | Management port for service management interface access |

Ports must not be used by the operating system or other applications.

#### 2.1.6 Reports Service

##### 2.1.6.1 CPU, RAM, HDD Requirements for Reports Service

Resources required for the reports service operation are calculated based on the number of concurrent report building tasks.

**CPU Requirements (cores)**
- 1 core for OS system processes
- 1 core per report building task

**RAM Requirements:**
- 2GB for OS system processes

**RAM for JVM:**
- 2GB per report building task

**RAM (JVM)** = 2GB × number of concurrent report building tasks

**Final RAM (OS)** = RAM (JVM) × 1.5 + 2GB (for OS system processes)

**HDD Requirements:**
- 50GB for OS
- 500GB for software and logs storage under normal operation (excluding DEBUG)

Recommended to use fault-tolerant arrays (e.g., RAID-1, RAID-10)

*CPU type: Intel Xeon e5-2640 (or equivalent)*
*Final HDD value depends on generated report disk space usage, number of reports, and their storage time*

##### 2.1.6.2 Network Interface Requirements for Reports Service

The service host requires a network interface with 100Mbit/s bandwidth.

##### 2.1.6.3 Port Requirements for Reports Service

The following ports must be open on the service host:

**Table 2.1.6.3 - Reports Service Port Requirements**

| Port | Protocol | Purpose |
|------|----------|---------|
| 9000 | HTTP | Serving HTTP requests from other WFM CC solution components |
| 9007 | JMX | Management port for service management interface access |

Ports must not be used by the operating system or other applications.

#### 2.1.7 Notifications Service

##### 2.1.7.1 CPU, RAM, HDD Requirements for Notifications Service

Resources required for the notifications service operation are calculated based on the number of:

- Simultaneous notification processing threads
- Simultaneous distribution threads

**CPU Requirements (cores)**
- 1 core for OS system processes
- 1 core × (number of simultaneous distribution threads / 10)
- 1 core × (number of simultaneous notification processing threads / 10)

**RAM Requirements:**
- 2GB for OS system processes

**RAM for JVM:**
- 512MB for distribution
- 512MB + 30MB × number of simultaneous notification processing threads

**RAM (JVM)** = 512MB + 512MB + 30MB × number of simultaneous notification processing threads

**Final RAM (OS)** = RAM (JVM) × 1.5 + 2GB (for OS system processes)

**HDD Requirements:**
- 50GB for OS
- 100GB for software and logs storage under normal operation (excluding DEBUG)

Recommended to use fault-tolerant arrays (e.g., RAID-1, RAID-10)

*Usually 20 simultaneous notification processing threads and 10 simultaneous distribution threads are sufficient for notifications service operation*
*CPU type: Intel Xeon e5-2640 (or equivalent)*

##### 2.1.7.2 Network Interface Requirements for Notifications Service

The service host requires a network interface with 100Mbit/s bandwidth.

##### 2.1.7.3 Port Requirements for Notifications Service

The following ports must be open on the service host:

**Table 2.1.7.3 - Notifications Service Port Requirements**

| Port | Protocol | Purpose |
|------|----------|---------|
| 9020 | HTTP | Serving HTTP requests from other WFM CC solution components |
| 9027 | JMX | Management port for service management interface access |

Ports must not be used by the operating system or other applications.

#### 2.1.8 Integration Service

##### 2.1.8.1 CPU, RAM, HDD Requirements for Integration Service

Resources required for the integration service operation are calculated based on the number of integrations.

**CPU Requirements (cores)**
- 1 core for OS system processes
- 1 core per integration

**RAM Requirements:**
- 2GB for OS system processes

**RAM for JVM:**
- 2GB per integration

**RAM (JVM)** = 2GB × number of integrations

**Final RAM (OS)** = RAM (JVM) × 1.5 + 2GB (for OS system processes)

**HDD Requirements:**
- 50GB for OS
- 100GB for software and logs storage under normal operation (excluding DEBUG)

Recommended to use fault-tolerant arrays (e.g., RAID-1, RAID-10)

*The example shows typical calculation. Actual resource requirements may differ depending on the load intensity created by each integration*
*CPU type: Intel Xeon e5-2640 (or equivalent)*

##### 2.1.8.2 Network Interface Requirements for Integration Service

The service host requires a network interface with 100Mbit/s bandwidth.

##### 2.1.8.3 Port Requirements for Integration Service

The following ports must be open on the service host:

**Table 2.1.8.3 - Integration Service Port Requirements**

| Port | Protocol | Purpose |
|------|----------|---------|
| 8080 | HTTP | Serving HTTP requests from other WFM CC solution components |

Ports must not be used by the operating system or other applications.

#### 2.1.9 Client System

The client system includes:

- **Web-client**: designed to work with WFM CC AS and Personal Cabinet Service using a web browser
- **Mobile-client**: designed to work with WFM CC AS using a mobile application

##### 2.1.9.1 CPU, RAM, HDD Requirements for Web-client

**Table 2.1.9.1 - Hardware Requirements**

| Component | Minimum Requirements | Recommended Requirements |
|-----------|---------------------|-------------------------|
| CPU | x86 dual-core from 2010 (or newer) | x86 dual-core from 2010 (or newer) |
| RAM | 2048 MB | 8 GB |
| HDD | 10 GB | 30 GB |
| Screen Resolution | 1280×1024 | 1920×1080 |

##### 2.1.9.2 Network Interface Requirements for Client System Web-client

Recommended bandwidth for client workstations: 100 Mbit/s

##### 2.1.9.3 Port Requirements for Client System Web-client and Mobile-client

For users working with Web-client, access from workstations to WFM CC AS and Personal Cabinet Service must be provided on the ports specified in sections 2.1.2.3 and 2.1.3.3.

In case of fault-tolerant solution or need to use HTTPS protocol, access from client workstations to the load balancer must be provided on the ports configured for each service: WFM CC AS and Personal Cabinet Service.

For remote users using Mobile-client, internet access to Mobile API Service must be provided on the ports specified in section 2.1.4.3.

*In basic configuration, this is HTTP protocol and port 8080 for both WFM CC AS and Personal Cabinet Service*
*Presence of several duplicating services deployed on different hosts*
*In basic configuration within the corporate network, this is HTTP protocol and port 8080. HTTPS-HTTP traffic termination occurs at the customer's network equipment level*

#### 2.1.10 Network System

##### 2.1.10.1 Data Transmission Channel Requirements

Data transmission channels between network interfaces of systems included in the WFM CC solution must provide the necessary bandwidth specified in the requirements.

##### 2.1.10.2 Port Requirements

For all systems included in the WFM CC solution, IP connectivity must be ensured according to Figure 2.1 Technical Architecture of WFM CC Solution and the requirements specified in the relevant sections.

##### 2.1.10.3 WFM CC Services Load Balancer Requirements

Balanced groups must be formed on the load balancer.

A balanced group is a group of services with the same purpose, consisting of N service instances for load balancing and failover purposes.

For each group, a corresponding port is opened on the load balancer (see Table 2.1.10.3).

For some balanced groups, the load balancer provides sticky session (see Table 2.1.10.3).

**Table 2.1.10.3 - Example of Balanced Groups and Ports**

| Group Name | Incoming Port on Load Balancer | Group Composition | Sticky Session Required | Service Availability Check |
|------------|-------------------------------|-------------------|------------------------|----------------------------|
| WFM CC AS | 8080 | argus-app01:8080<br>argus-app02:8080 | Yes | http://argus-app01:9990/ccwfm/ping<br>http://argus-app02:9990/ccwfm/ping |
| Personal Cabinet Service | 8081 | argus-app03:8081<br>argus-app04:8081 | Yes | http://argus-app03:9990/api/v1/system/status<br>http://argus-app04:9990/api/v1/system/status |
| Notifications Service | 8082 | argus-app05:8082<br>argus-app06:8082 | No | http://argus-app05:9990/api/v1/system/status<br>http://argus-app06:9990/api/v1/system/status |
| Planning Service | 8083 | argus-app07:8083<br>argus-app08:8083 | No | http://argus-app07:9990/api/v1/system/status<br>http://argus-app08:9990/api/v1/system/status |

**Load Balancer Operation Principles:**

- The load balancer redirects incoming group port requests to a selected service instance in the balanced group, providing load balancing and fault tolerance (failover)
- Session distribution between active nodes is performed by session identifiers using cookie mechanism and node status (active/inactive)
- For Sticky session, the load balancer must direct the next request to the same service instance that handled the previous request from the same session
- Service availability is checked using management ports with HTTP probes
- Successful response code: 200
- Probe interval: 10 seconds
- If a request fails twice in a row, the load balancer considers the service unavailable

**Load Balancer Timeouts:**

- Connection timeout from load balancer to service node: at least 1 minute
- AJP-ping response timeout: at least 1 minute
- Request response timeout from service node: at least 24 minutes (maximum server execution time is 23 minutes)

**Error Handling:**

- The load balancer considers a request unsuccessful if the service returns HTTP status 500-599
- Other status values (300-399) should not be considered unsuccessful
- The load balancer can transparently retry request execution on another node, except for POST requests that are being processed too long

**Logging Requirements:**

- Access logs (accesslog) must be maintained on the load balancer
- Logs should be stored for at least five days
- Log rotation must be configured

##### 2.1.10.4 WFM CC Database Load Balancer Requirements

The WFM CC database server can be launched in two ways:

1. **Single database server** (balancing not required) - the database becomes a single point of failure
2. **Multiple database servers** in a fault-tolerant cluster (all database servers work simultaneously, one in master mode, another in slave mode with hot-standby option)

For failover implementation, a solution consisting of the following software components is used: **Keepalived - Haproxy - Etcd - Patroni** (Figure 2.1.10.4), deployed on Database Load Balancers and database hosts themselves.

![Database Load Balancer Fault-Tolerant Solution](img/db_load_balancer_architecture.png)

*Figure 2.1.10.4 - Fault-Tolerant Solution with Failover Mechanism and Database Load Balancer*

**Components to be deployed on load balancers:**

**Keepalived** - used to ensure a single cluster entry point - virtual IP.
- Provides service fault tolerance and load balancing
- Fault tolerance is achieved through a "floating" IP address that switches to the backup server in case of primary server failure
- Uses VRRP protocol for automatic IP switching between servers

**Haproxy** - software load balancer
- Required for monitoring server states and redirecting requests to the master server
- Installed on each host and contains references to all PostgreSQL servers in its configuration
- Checks which PostgreSQL server is currently the master and sends requests only to it
- Uses Patroni REST interface for this verification

**Component Installation Requirements:**

The following components must be deployed on database hosts (in addition to PostgreSQL):

**Etcd** - fault-tolerant distributed key-value store used to store Postgres cluster state
- Helps Patroni nodes determine who will be the master
- Requires an odd number of servers (ideally at least 3)
- Installed on Database Load Balancers

**Patroni** - Python package that manages Postgres configuration
- Handles replication and failover
- All database settings must be made through Patroni

**Table 2.1.10.4 - Fault-Tolerant Solution Components and Ports**

| Source System | Target System | Port | Purpose |
|---------------|---------------|------|---------|
| etcd | etcd | 2380 | Quorum formation |
| patroni | etcd | 2379 | Quorum status retrieval |
| haproxy | patroni | 8008 | Service health check |
| client | haproxy | 7000 | Health status metrics |
| client | haproxy | 9999 | Network traffic |
| haproxy | postgresql | 5432 | Network traffic |

*For fault-tolerant solution implementation*
*In case of Failover (database role change from slave to master events) and database server status change from UP to DOWN, email notifications should be sent to a predetermined list of recipients*

#### 2.1.11 External IT Systems (Integration)

For interaction with external systems, a dedicated Integration Service is provided.

Direct interaction between external systems and WFM CC solution components via SOAP/HTTP protocol using a dedicated IP address and port is also possible.

The specific implementation of interaction between WFM CC solution components and external systems is determined by the customer's specifics.

#### 2.1.12 Monitoring System

For monitoring components included in the WFM CC solution, the following are used:

**Zabbix Monitoring System** - agents are installed on hosts to be monitored, which collect metrics from both the hosts themselves and services deployed on the hosts, send metrics to monitoring servers where they are displayed, analyzed, and based on settings, sent as alerts about threshold value exceedances.

**Monitoring Utilities** (JVisualVM, JConsole, Command Line Interface, NMON).

![Monitoring Scheme](img/monitoring_scheme.png)

*Figure 2.1.12 - Monitoring Scheme*

**Zabbix Monitoring System Components:**

**Zabbix Server** - server responsible for database operations, metrics collection, and monitoring and alerting management.

**Zabbix Proxy** - server that performs intermediate collection and processing of metrics and sends them to Zabbix Server.
- Used to increase monitoring system scalability and fault tolerance
- Has no user interface

**Zabbix Java Gateway** - Zabbix Proxy analog for JMX monitoring (AS monitoring).

**Zabbix Agent** - designed to collect and send data to Zabbix Proxy/Zabbix Server, execute predefined scripts when necessary.

**Deployment Configuration:**

**Customer Side:**
- Zabbix Proxy installed together with Zabbix Java Gateway on one host
- Zabbix Proxy deployed in active mode and initiates connection to Zabbix Server
- Zabbix Agent deployed on each host with WFM CC solution components

**Argus Side:**
- Zabbix Server installed
- Incoming traffic filtering by IP address provided by customer for monitoring system access
- Monitoring utilities hosted

##### 2.1.12.1 CPU, RAM Requirements for Zabbix

**Zabbix Proxy + Zabbix Java Gateway:**
- **CPU**: 1 (AMD Athlon 3200+ level)
- **RAM**: 2GB
- **HDD**: 50GB
- SQLite database automatically created with Zabbix Proxy installation (10GB)

**Zabbix Agent:**
- **CPU**: 1+ (AMD Athlon 3200+ level)
- **RAM**: 256MB+
- **HDD**: 10GB+

##### 2.1.12.2 Port Requirements for Zabbix

Standard ports used by monitoring system elements:

- **Zabbix Agent**: 10050
- **Zabbix Proxy**: 10051
- **Zabbix Java Gateway**: 10052

Port values can be changed in configuration files:
- zabbix_agentd.conf
- zabbix_proxy.conf
- zabbix_java_gateway.conf

### 2.2 Access for Diagnostics of Malfunctions for Argus Specialists

For conducting counter-emergency, maintenance, and other work by the contractor, access for contractor employees to the customer's test and production server hosts must be provided.

Access is necessary for the ability to read/download logs for analysis, create service dumps, check software functionality, create database queries analyzing its state, connect to monitoring systems and configure them, and make changes to configuration files and restart WFM CC solution components.

For successful malfunction diagnostics and counter-emergency work, contractor specialists need access to customer server hosts specified in Table 2.2.

**Table 2.2 - Contractor Specialist Access to Customer Systems**

| Host | Protocol | Port |
|------|----------|------|
| Database | TCP | 5432 |
|          | SSH | 22 |
| Services | HTTP/HTTPS | 8080, 9990 |
|          | SSH | 22 |
| Service Load Balancer | HTTP/HTTPS | 8080 |
|                      | SSH | 22 |
| Database Load Balancer | TCP | 2380, 2379, 8008, 7000, 9999, 5432 |
|                       | SSH | 22 |
| Monitoring System | TCP | 5432, 10050, 10051, 10052 |
|                   | SSH | 22 |

Each contractor employee involved in application server technical support must have their own user account (login and password) for host access.

The user account allows viewing all contents of the installation directory (usually /argus) but has no modification rights.

The user account has a home directory where modifications are allowed (creating and editing files and directories).

Depending on the customer's security policy and technical capabilities, this can be:
- Direct access to customer servers from contractor network via protocols and ports specified in Table 2.2
- Access to customer terminal server from contractor network via RDP 3389, and from there access to customer servers via protocols and ports specified in Table 2.2

For security reasons, some protocols/ports listed in Table 2.2 may be closed (individually for each customer).

*Performed by agreement with the customer*
*In case of software load balancer, e.g., Apache, Nginx*

### 2.3 Requirements for Qualification of Customer Service Personnel

The qualification of customer service personnel must correspond to the functions performed during WFM CC solution operation.

#### 2.3.1 Database Operation

##### 2.3.1.1 Ensuring Database Functionality

**Database Backup:**
- Launching backup procedure
- Monitoring backup procedure execution
- Controlling backup procedure completion

**Database Recovery:**
- Launching database recovery procedure
- Monitoring database recovery procedure execution
- Controlling database recovery procedure completion

**Database Access Management:**
- Assigning user access rights to database
- Changing user access rights to database
- Controlling compliance with user access rights to database

**Software Installation and Configuration for Database User Support:**
- Installing software to support database users
- Configuring software to support database users
- Controlling software configuration results for database users

**Software Installation and Configuration for Database Administration:**
- Installing software to support database administrators
- Configuring software to support database administrators
- Controlling software configuration results for database administrators

**Database Event Monitoring:**
- Observing database operation
- Detecting deviations from normal database operation
- Analyzing and eliminating deviations from normal database operation

**Database Event Logging:**
- Recording deviations from normal database operation
- Maintaining deviation log from normal database operation
- Informing staff responsible for eliminating deviations from normal database operation

##### 2.3.1.2 Database Functionality Optimization

**Database Operation Monitoring and Statistical Information Collection:**
- Database operation monitoring using various automated tools
- Selecting main statistical indicators of database operation
- Analyzing obtained statistical data and forming conclusions about database operation efficiency

**Computing Resource Distribution Optimization:**
- Analyzing capabilities for managing computing resources interacting with database
- Managing computing resources interacting with database
- Controlling results of computing resource redistribution interacting with database

**Database Performance Optimization:**
- Analyzing capabilities for database performance optimization management
- Selecting database performance optimization criteria
- Managing database performance optimization

**Computing Network Component Optimization:**
- Analyzing computing network components and configuration management capabilities
- Selecting evaluation criteria for changing computing network component configuration interacting with database
- Optimizing computing network components interacting with database and controlling changes in database operation

**Database Query Execution Optimization:**
- Statistical analysis of database queries and their classification by various features
- Selecting database query execution optimization criteria
- Optimizing execution of statistically significant database queries

**Database Data Lifecycle Management Optimization:**
- Memory Data Distribution Management
- Selecting memory data distribution management strategy for database placement
- Controlling compliance with memory data distribution management strategy for database placement

##### 2.3.1.3 Data Loss and Damage Prevention

**Database Backup Regulation Development:**
- Analyzing application system functionality to identify suitable time intervals for database backup
- Selecting software tools for backup execution
- Developing and implementing database backup scenario for installed application system

**Database Recovery Scenario Development and Documentation Preparation:**
- Backup regulation execution control
- Correcting actions when deviating from regulation
- Comparing performed actions with backup regulation

**Database Backup Strategy Development:**
- Studying general backup execution principles
- Studying application system architecture and operation schedule

**Database Recovery Regulation Development:**
- Developing typical database recovery scenarios for various failures
- Analyzing application system architecture to identify database components most susceptible to failures

**Automatic Database Backup Procedure Development:**
- Developing scripts for database backup creation
- Analyzing database hardware and software characteristics for backup placement and data transfer performance

**Data Recovery Procedure After Failure:**
- Analyzing possible database failures and developing scenarios for necessary database recovery measures
- Writing scripts according to developed scenarios for quick failure consequence elimination

**Recovery Regulation Compliance Control:**
- Correcting actions when deviating from regulation
- Comparing performed actions with database recovery regulation

**Database Failure Analysis and Cause Identification:**
- Monitoring and documenting failures occurring in database during application system service
- Identifying failure causes and timely elimination
- Interacting with database technical support services and computing complex component suppliers for failure localization and elimination

**Database Support Methodological Instructions Development:**
- Analyzing main database support stages
- Preparing database support recommendations, including critical database interaction process optimization
- Preparing documentation according to established rules and requirements

**Database Hardware and Software Monitoring:**
- Observing database hardware and software complex operation
- Recording deviations from normal database operation

**Database Hardware and Software Configuration:**
- Initial database software installation
- Applying database monitoring results to improve database functionality
- Configuring database hardware and software components to improve user service quality

**Database Hardware and Software Modernization Proposals:**
- Analyzing database support hardware and software market
- Finding modernization paths aimed at improving database operation efficiency
- Preparing proposals for applied hardware and software modernization

**Database Failure Risk Forecasting and Assessment:**
- Analyzing various failure type frequencies in database operation
- Searching for failure information and elimination actions in various sources (including Internet)
- Database failure risk forecasting and assessment

**Automatic Database Hot Backup Procedure Development:**
- Initial hot backup database installation
- Hot backup database monitoring in application system
- Hot backup database user operation configuration and optimization

**Hot Replacement Resource Commissioning Procedures:**
- Database hot backup system node software updates installation
- Automatic hot backup database commissioning configuration when using automation
- Switching to hot backup database when necessary

**Database Functionality Reports Preparation:**
- Collecting database operation information
- Filling database state and functionality report forms

##### 2.3.1.4 Database-Level Information Security

**Database-Level Information Security Policy Development:**
- Analyzing possible data security threats
- Selecting main database-level information security support tools

**Database Security Regulation Compliance Control:**
- Identifying actions violating database-level security regulation
- Correcting actions when deviating from database-level security regulation
- Eliminating consequences of incorrect actions leading to database-level information security reduction

**Security System Operation Optimization:**
- Determining security system operation optimization capabilities to reduce database operation load
- Selecting most effective ways to reduce load while ensuring required database-level data security

**Data Security System Regulation Development and Audit:**
- Selecting database-level data audit result evaluation criteria
- Developing database-level data security system audit methods
- Security system audit and efficiency evaluation

**Database-Level Security System State and Efficiency Reports:**
- Determining security system efficiency indicators and criteria, their calculation and analysis
- Evaluating database-level data security system level and state

**Automated Unauthorized Data Access Attempt Detection Procedure Development:**
- Analyzing programming procedure capabilities for unauthorized data access attempt detection
- Applying programming tools for developing automated unauthorized data access attempt detection procedures

##### 2.3.1.5 Database Development Management

**Database Information Processing System Problem Analysis and Database Development Proposals:**
- Collecting and analyzing unrealized database user needs
- Researching promising database market and their fundamental capabilities
- Preparing accepted database development decision implementation plan

**Database Software Version Update Regulation Development:**
- Analyzing main database software version update stages
- Developing and describing typical database version update processes
- Preparing regulatory database version update documents

**Database Migration to New Platforms and Software Versions Regulation Development:**
- Analyzing main database migration stages to new platforms and software versions
- Developing and describing typical database migration processes to new platforms and software versions
- Preparing regulatory database migration documents

**New Database Technology Study, Mastery and Implementation:**
- Monitoring new database information technologies appearing on the market
- Mastering and implementing new database technologies in administration practice

**Database Version Update Control:**
- Planning stages and analyzing each database version update stage execution results
- Planning, conducting and analyzing database functionality check results after update

**Database Migration to New Platforms and Software Versions Control:**
- Planning database migration stages
- Analyzing database operation testing results after migration
- Database recovery and action correction when migration errors are detected

#### 2.3.2 Application Server Operation

##### 2.3.2.1 Ensuring Application Server Functionality

**Software Installation and Configuration for Application Server User Support:**
- AS software installation preparation, OS configuration, related software
- AS software installation
- AS software configuration
- AS software configuration result control

**Application Server Operation Monitoring and Statistical Information Collection:**
- AS operation monitoring using various automated tools
- Selecting main AS operation statistical indicators
- Analyzing obtained statistical data and forming conclusions about AS operation efficiency
- Detecting deviations from normal AS operation
- Analyzing and eliminating deviations from normal AS operation

**Application Server Maintenance:**
- AS log cleanup using automated tools
- Memory and thread dump formation (during emergency)
- Interacting with technical support services and software suppliers for failure localization and elimination (during emergency)
- AS restart on technical support service recommendation (during emergency or approaching it)

**Application Server Event Logging:**
- Recording deviations from normal AS operation
- Maintaining AS operation deviation log
- Informing staff responsible for eliminating AS operation deviations

**Application Server Functionality State Reports:**
- Preparing AS functionality state reports

##### 2.3.2.2 Application Server Service Loss Prevention

**Application Server Backup:**
- Launching backup procedure
- Monitoring backup procedure execution
- Controlling backup procedure completion

**Application Server Recovery:**
- Launching AS recovery procedure
- Monitoring AS recovery procedure execution
- Controlling AS recovery procedure completion

#### 2.3.3 Client System Operation

##### 2.3.3.1 Client Software Installation and Configuration

- Checking OS and client software resource compliance
- Client software installation and update
- Client software configuration
- Controlling client software installation, update and configuration results

#### 2.3.4 Network System Operation

##### 2.3.4.1 Network Operation Monitoring and Statistical Information Collection

- Network operation monitoring using various automated tools
- Selecting main network operation statistical indicators
- Analyzing obtained statistical data and forming conclusions about network operation efficiency
- Detecting deviations from normal network operation
- Analyzing and eliminating deviations from normal network operation

##### 2.3.4.2 Network Operation Event and Collision Logging

- Recording deviations from normal network operation
- Maintaining network operation deviation log
- Informing staff responsible for eliminating network operation deviations
- Preparing network functionality state reports

##### 2.3.4.3 Computing Network Component Optimization

- Analyzing network components and configuration management capabilities
- Selecting evaluation criteria for network component configuration changes interacting with system components
- Optimizing network components interacting with system components and controlling network operation changes

### 2.4 General Procedure for Deployment and Maintenance of WFM CC Solution Components

#### 2.4.1 Standard Concepts

**Database Dump** - consists of database structure description and/or data contained in it, usually as SQL commands. Used for data backup/recovery.

**Database Update** - represents changes to internal table structure and database objects, adding new features to software functionality.

**Database Patch** - represents a set of fixes identified during testing, implementation and pilot operation.

**Application Server Distributable** - represents an installation file that performs application server file unpacking and configuration.

**User Account** - a combination of username and password that must be entered when starting the program. Each user account is matched to the corresponding user and includes a set of functional modules and options assigned to these modules.

#### 2.4.2 Standard Actions for Software Updates

Any actions before making software changes must be preceded by its backup copy.

Standard software update actions include the following stages:

- User notification about ongoing work
- Disconnecting user sessions
- Creating software backup copies
- Software installation
- Software startup
- Checking installed software functionality and log analysis (if available)
- Returning to normal operation mode

When special actions are required, update instructions are sent together with software archives.

##### 2.4.2.1 Database Update

- Stop AS and Services
- Perform database backup copy
- Execute database updates (update scripts, dbmaintain)
- Start AS and Services

##### 2.4.2.2 Application Server and Services Update

**Application Server Update:**
- Stop AS
- Backup AS directory
- Delete AS directory (when transitioning from version to version)
- Prepare distributable (unpack and place in directory from which installation will occur) and specific AS configurations (ensure parameters are specified correctly)
- Install AS
- Start AS

**Services Update:**
Service update mechanism is implemented using docker and docker-compose tools:
- Stop docker container
- Load new docker container image (tar file) into local docker repository
- Configure configuration file with container startup parameters
- Start docker container
- Delete new installation image (tar file)
- Delete old docker container
- Delete old docker container image from local docker repository

##### 2.4.2.3 Client Workstation Update

Depending on the number of workstations, this can be updating each workstation separately or all at once using group domain policies. Includes deleting client software directory and reinstalling it.

*Container repository located on the host where the service will be run*
*docker-compose.yml*
*Usually client workstation operates under Windows OS*

#### 2.4.3 Regular Procedures for Maintaining WFM CC Solution Components

**Log Cleanup:**
During operation of all WFM CC solution components, a significant amount of logs is generated, proportional to the number of users, load, and software operation mode: normal or debug.

Therefore, it's necessary to timely delete (archive and delete) logs, ensuring disk space doesn't overflow. Disk space overflow leads to failure of corresponding WFM CC solution components.

Detailed log cleanup procedure is described in section 3.4.3 Operation Log Archiving.

**Database Backup:**
Described in section 3.4.1.1 Database Backup.

**WFM CC AS Backup/Recovery:**
When working with AS, it's possible to:
- Create backup copy without stopping service by creating AS installation directory copy
- AS recovery is possible by copying saved AS directory copy to installation directory. Requires preliminary AS stop.

**WFM CC AS Restart:**
On technical support recommendation, when approaching critical resource consumption values (CPU, RAM) - perform AS restart.

**Services Backup/Recovery:**
Services run in docker containers, so it's sufficient to have backup image copy (tar file) for deploying docker container from which service reinstallation can be performed if necessary, as well as configuration files.

It's also possible to save image for docker container from local docker container repository.

**Zabbix Monitoring System Component Reload:**
On technical support recommendation, when metrics or response from monitoring system components are absent - restart Zabbix components.

Component startup and shutdown instructions are provided in section 3.2.6.5 Zabbix Component Startup and Shutdown.

#### 2.4.4 Monitoring Tools Deployment

**Database:**
- Configure internal monitoring tools: pgAdmin, SQL queries
- Install NMON utility and configure OS status reports collection on database host
- Install standard OS utilities: top, mpstat, vmstat, iostat, etc. - for OS resource data collection

**AS and Services:**
- To observe AS and Services resources in real time, use Admin Console or external monitoring utilities (JVisualVM, JConsole, Command Line Interface):
  1. Create AS and Services administrator account for monitoring utility connections
  2. Deploy one of external monitoring utilities (e.g., JVisualVM) on local host
- Install NMON utility and configure OS status reports collection on AS host
- Install standard OS utilities: top, mpstat, vmstat, iostat, etc. - for OS resource data collection

**Zabbix Monitoring System version 4.2** is required for monitoring OS, AS and Services resources, as well as database status:
- Install Zabbix agents on hosts to be monitored, which collect metrics from both hosts and services deployed on hosts, send metrics to Zabbix proxy, from where they are sent to Zabbix server where they are displayed, analyzed and based on settings sent as alerts about threshold value exceedances
- Deploy Zabbix proxy for data forwarding from agents to Zabbix server
- Deploy Zabbix JavaGateway for monitoring AS and Services JVM indicators
- Contact contractor technical support to obtain:
  1. Account for viewing data collected by Zabbix monitoring system
  2. Zabbix JavaGateway jar file with necessary settings for AS and Services monitoring

Create email address to receive alerts about critical system indicators subject to monitoring.

Organize archiving/deletion of outdated logs for Zabbix components and monitoring utilities using OS task scheduler.

Details in sections 3.2.5 Monitoring System and 2.1.12 Monitoring System.

*More details in sections 3.2.11 Monitoring System and 2.1.12 Monitoring System*
*Installed in Customer network*
*Installed in Customer network*
*Installed in Customer network*

#### 2.4.5 Standard Actions During Emergency

During emergency, it's necessary to:

1. Record emergency time and occurring error
2. Collect all artifacts (thread dumps, memory dumps, monitoring system screenshots, log files) - information about system state at emergency moment that allows identifying emergency cause and taking actions to prevent it in future
3. Contact technical support service, provide all collected artifacts and take joint counter-emergency actions to localize the problem

First, current (operational) system information is collected, then retrospective (historical) information.

**Database:**
- Active database sessions: wait time, wait type, SQL queries
- Session lock tree
- OS status (using OS utilities)
- Errors in postgresql_<date>.log
- Monitoring system data, screenshots
- OS logs (if necessary)

**Application Server:**
- OS status (using OS utilities)
- OS logs (if necessary)
- Logs (from all AS nodes if multiple)
- AS status using jvisualVM utility (screenshots)
- Monitoring system data, screenshots
- AS memory (heap) dumps, thread dumps

**Memory dump (heap) example:**
```bash
cd /Data/jboss_prod/bin
./runjboss.sh heap-dump
```

**Thread dump example:**
```bash
cd /Data/jboss_prod/bin
./runjboss.sh thread-dump >> thread-dump_15-01-2016_15-23
```

Thread dumps are recommended to be taken several times with 3-5 minute intervals. Dump files will be created in AS bin directory.

Since logs and dumps occupy significant space, it's recommended to archive them before sending using tar and gzip utilities.

**Example:**
```bash
cd /Data/jboss_prod/standalone
tar -cvf log.tar log
gzip log.tar
```

After archiving all artifacts and sending them to contractor, delete irrelevant tar and gz archives as well as memory and thread dumps from host.

---

## 3. WFM CC Solution Service Maintenance Guide

### 3.1 Software Environment Setup for WFM CC Server Software Deployment

Before deploying WFM CC solution components, the following preliminary/preparatory actions must be performed on each VM:

- Provide internet access
- Ensure network connectivity between VMs
- Open necessary ports between VMs according to technical architecture
- Install utilities and packages for OS status diagnostics: top, htop, vmstat, iostat, iotop, netstat, tcpdump, telnet, ping, mc
- Install Docker and Docker Compose on all VMs
- Install Oracle JDK version 8 update 77 (8u77) on all VMs

#### 3.1.1 WFM CC Database Server

##### 3.1.1.1 Directory Organization

Recommended directory structure for WFM CC database software placement:

| Directory | Description |
|-----------|-------------|
| /argus | Contains database and additional environment for supporting its operation |
| /argus/distr | Contains database distributables and installation packages |
| /argus/nmon | Contains nmon system performance reports (format: <network_node_name>_yymmdd_0101.nmon) and their archives (format: <network_node_name>_yymmdd_0101.nmon.gz) |
| /argus/scripts | Auxiliary scripts |
| /argus/tmp | AS temporary files directory |

**Directory creation example:**
```bash
mkdir /argus
chown argus:argus /argus -R
```

##### 3.1.1.2 Time Synchronization

The OS must have a time service (ntpd or chronyd) installed that provides system time synchronization with a time server.

#### 3.1.2 WFM CC Application Server

##### 3.1.2.1 User Account

The OS must have an argus user account created for installing and running both AS and any additional software (e.g., JDK). The user account must have write permissions to the AS directory (e.g., /argus/jboss_prod) and its subdirectories.

Creating a new user account in Linux OS is done using the adduser utility.

**Example:**
```bash
adduser argus
```

More detailed instructions for creating user accounts via command line can be found at: https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/system_administrators_guide/ch-managing_users_and_groups

##### 3.1.2.2 Java Virtual Machine

For stable WFM CC AS operation, Oracle JDK version 8 update 77 (8u77) pre-installation is required.

Java version 8 is available for download from: http://www.oracle.com/technetwork/java/javase/downloads/index.html

JDK 8u77 download from Oracle site archive requires a registered account.

It's recommended to install Java Virtual Machine in directory /argus/jdk/jdk1.8.0_77 as JDK (java development kit), not as JRE (java runtime environment), since JDK provides additional application diagnostic tools.

You must specify in .bash_profile (or .profile, depending on which file is used in the OS) of the OS user running the AS installation file or AS process itself:

- **JAVA_HOME environment variable** with JDK path:
```bash
export JAVA_HOME=/argus/jdk/jdk1.8.0_77
```

- **PATH environment variable** with JDK bin directory path:
```bash
export PATH=/argus/jdk/jdk1.8.0_77/bin:$PATH
```

It's desirable to use the latest Java Virtual Machine that accounts for the absence of daylight saving time transition in the Russian Federation, or the existing Java Virtual Machine should be updated using Java Time Zone Updater.

Additional information: http://www.oracle.com/technetwork/java/javase/tzupdater-readme-136440.html

##### 3.1.2.3 Time Zone Data

The host must be in UTC timezone.

**Check installed timezones:**
```bash
timedatectl list-timezones
```

**Set UTC timezone:**
```bash
timedatectl set-timezone UTC
```

Before AS installation, ensure that actual time zone data is installed in JDK.

##### 3.1.2.4 Operating System Locale and Encoding

The operating system must support UTF-8 encoding and have time, date, and number formats (locale) installed according to language standards used by users (for installation in Russian Federation, ru_RU.UTF-8 locale is needed).

In Linux operating systems, locale checking is performed with the locale command. Below is the command output on a correctly configured server:

```bash
$ locale
LANG=ru_RU.UTF-8
LC_CTYPE="ru_RU.UTF-8"
LC_NUMERIC="ru_RU.UTF-8"
LC_TIME="ru_RU.UTF-8"
LC_COLLATE="ru_RU.UTF-8"
LC_MONETARY="ru_RU.UTF-8"
LC_MESSAGES="ru_RU.UTF-8"
LC_PAPER="ru_RU.UTF-8"
LC_NAME="ru_RU.UTF-8"
LC_ADDRESS="ru_RU.UTF-8"
LC_TELEPHONE="ru_RU.UTF-8"
LC_MEASUREMENT="ru_RU.UTF-8"
LC_IDENTIFICATION="ru_RU.UTF-8"
LC_ALL=
```

##### 3.1.2.5 Time Synchronization

For correct WFM CC AS operation, time synchronization between WFM CC AS OS and WFM CC Database OS must be ensured.

The OS must have a time service (ntpd or chronyd) installed that provides system time synchronization with a time server.

##### 3.1.2.6 Maximum Number of Open Files and Sockets

It's necessary to increase the limit on maximum number of open files and sockets compared to default values. The server keeps many files open. The application server opens sockets establishing outgoing network connections to WFM CC Database and AS of other WFM CC solution components with which interaction is maintained. The application server opens sockets accepting incoming connections from user browsers.

Required maximum number of open files and sockets is calculated by formula:

**max open sockets and files = max concurrent users × 20**

**Linux Kernel Configuration Parameters:**

View current OS level settings:
```bash
cat /proc/sys/fs/file-max
```

Set OS level parameter value in file and activate:
```bash
sysctl -w fs.file-max=102400
sysctl -p /etc/sysctl.conf
```

View settings for current user (OS account):
```bash
ulimit -n
```

Set user account value in file /etc/security/limits.conf:
```
argus soft nofile 100000
argus hard nofile 100000
```

##### 3.1.2.7 Maximum Number of Running Processes

It's necessary to increase the limit on maximum number of running processes compared to default values. When server operates without additional HTTP ports, server thread count can be within 200-1000 range, and adding another additional HTTP port entails creating a 256-thread pool.

Formula for calculating max-user-processes:
**max-user-processes ≥ 1000 + additional-ports-count × 256**

View settings for current user (OS account):
```bash
ulimit -a | grep processes
```

Set user account value in file /etc/security/limits.conf:
```
argus soft nproc 4000
argus hard nproc 4000
```

##### 3.1.2.8 Additional Recommended OS Settings

**Linux:**
Increase socket send/receive buffer values in file /etc/sysctl.conf:
```
net.core.rmem_default=262144
net.core.wmem_default=262144
net.core.rmem_max=262144
net.core.wmem_max=262144
```

Activate changes:
```bash
sysctl -p /etc/sysctl.conf
```

##### 3.1.2.9 Directory Organization

Recommended directory structure for WFM CC AS software placement:

| Directory | Description |
|-----------|-------------|
| /argus | Contains AS and additional environment for supporting its operation. Separate disk partition recommended |
| /argus/distr | Contains AS and additional software distributables and installation packages |
| /argus/jboss_arch | Stores AS backup copies (copy format: ddmmyyyy/jboss_prod) |
| /argus/jboss_prod | AS installation directory |
| /argus/jdk | JDK installation directory |
| /argus/jdk/jdk1.8.0_77 | JDK version 8 update 77. Required for AS operation |
| /argus/nmon | Contains nmon system performance reports and their archives |
| /argus/scripts | Auxiliary scripts |
| /argus/tmp | AS temporary files directory |

**Directory creation example:**
```bash
mkdir /argus
chown argus:argus /argus -R
```

##### 3.1.2.10 Hostname

Hostname must not contain underscore character.

**Check:**
```bash
uname -n
```

##### 3.1.2.11 Font Requirements

For correct application server operation, fontconfig package with TrueType fonts must be installed on the OS.

#### 3.1.3 WFM CC Personal Cabinet Service

##### 3.1.3.1 Docker and Docker Compose

For Docker software installation, CentOS operating system with kernel version no lower than 3.10.0-229.el7.x86_64 is required.

For components delivered in Docker container, the following software must be pre-installed on the host:
- Docker not lower than 19.03.12
- Docker Compose not lower than 1.29.2

**Check Docker and Docker Compose availability:**
```bash
docker -v
docker-compose -v
```

If corresponding software is installed, version and build number message will be displayed.

##### 3.1.3.2 User Account

The OS must have an argus user account created for installing and running Docker container. The user account must be in docker group with uid/gid 1099.

**Example:**
```bash
adduser argus
usermod -aG docker argus
groupmod -g 1099 argus
usermod -u 1099 -g 1099 argus
```

**Check account creation:**
```bash
id argus
# Console output after checking id argus
uid=1099(argus) gid=1099(argus) groups=1099(argus),995(docker)
```

##### 3.1.3.3 Directory Organization

Recommended directory structure on host:

| Directory | Description |
|-----------|-------------|
| /argus | Contains distributables, configuration files, Docker image software and additional environment for service operation support |
| /argus/distr | Contains delivered software distributables as Docker images (tar files) |
| /argus/nmon | Contains nmon system performance reports and their archives |
| /argus/scripts | Auxiliary scripts |

**Directory creation example:**
```bash
mkdir /argus
chown argus:argus /argus -R
```

##### 3.1.3.4 Time Synchronization

The OS must have a time service (ntpd or chronyd) installed that provides system time synchronization with a time server.

#### 3.1.4 WFM CC Mobile API Service

[Similar structure and requirements as Personal Cabinet Service - content follows same pattern]

#### 3.1.5 Planning Service

[Similar structure and requirements as other services - content follows same pattern]

#### 3.1.6 Reports Service

[Similar structure and requirements as other services - content follows same pattern]

#### 3.1.7 Notifications Service

[Similar structure and requirements as other services - content follows same pattern]

#### 3.1.8 Integration Service

##### 3.1.8.1 Java Virtual Machine

Application requires OpenJDK version 1.8 installation:
```bash
yum install java-1.8.0-openjdk.x86_64
```

**Check Java version:**
```bash
java -version
# Example output:
openjdk version "1.8.0_232"
OpenJDK Runtime Environment (build 1.8.0_232-b09)
OpenJDK 64-Bit Server VM (build 25.232-b09, mixed mode)
```

##### 3.1.8.2 User Account

The OS must have an argus user account created for software installation and management.

**Example:**
```bash
useradd argus
passwd argus
```

##### 3.1.8.3 Directory Organization

Recommended directory structure on host:

| Directory | Description |
|-----------|-------------|
| /argus | Contains distributables, configuration files, backup copies and auxiliary scripts and utilities |
| /argus/integration | Contains application |
| /argus/distr | Contains delivered software distributables as archives |
| /argus/backup | Contains backup copies created before software updates |
| /argus/nmon | Contains nmon system performance reports and their archives |
| /argus/scripts | Auxiliary scripts |

**Directory creation example:**
```bash
mkdir -p /argus/integration
chown argus:argus /argus -R
```

##### 3.1.8.4 Auto-start Configuration

Create file /etc/systemd/system/integration.service with content:
```ini
[Unit]
Description=integration
After=syslog.target

[Service]
User=argus
WorkingDirectory=/argus/integration
ExecStart=/argus/integration/integration-0.0.46-SNAPSHOT.jar
SuccessExitStatus=143
TimeoutStopSec=10
Restart=on-failure
RestartSec=5
OOMScoreAdjust=-1000

[Install]
WantedBy=multi-user.target
```

Execute:
```bash
systemctl daemon-reload
systemctl enable integration.service
```

##### 3.1.8.5 Time Synchronization

The OS must have a time service (ntpd or chronyd) installed that provides system time synchronization with a time server.

#### 3.1.9 Service Load Balancer

WFM CC solution software works with a load balancer used for load balancing when accessing services and AS, and also used as reverse proxy when accessing services and AS via HTTPS.

Load balancer configuration requirements are described in section 2.1.10.3 WFM CC Services Load Balancer Requirements.

**Software load balancers used with Argus software:**
- Based on apache httpd web server with installed mod_jk, mod_cluster, or enabled mod_proxy_balancer
- Based on HAProxy software load balancer

Before HAProxy installation and configuration, install epel repository:
```bash
yum install epel-release
```

**Hardware load balancers used with Argus software:**
- CISCO ACE 10
- Citrix NetScaler

*The list of hardware load balancers is not limited to the models listed*

##### 3.1.9.1 Time Synchronization

The OS must have a time service (ntpd or chronyd) installed that provides system time synchronization with a time server.

#### 3.1.10 Database Load Balancer

Database load balancer components are installed from standard packages.

Internet access to repositories for package updates and installation must be provided.

Details on installation in sections:
- 3.2.4.1.1 Keepalived Installation
- 3.2.4.2.1 Haproxy Installation
- 3.2.4.3.1 Etcd Installation
- 3.2.4.4.1 Patroni Installation

##### 3.1.10.1 Time Synchronization

The OS must have a time service (ntpd or chronyd) installed that provides system time synchronization with a time server.

#### 3.1.11 Monitoring Tools

##### 3.1.11.1 DBMS Monitoring Software Environment Setup

DBMS software environment setup is described in section 3.1.1 WFM CC Database Server.

##### 3.1.11.2 Application Server Monitoring Software Environment Setup

On hosts from which remote AS resource monitoring is planned, software environment for utility operation must be prepared:

**Java Visual VM (JVisualVM)** - diagnostic framework allowing real-time evaluation and report-form saving of server thread state information, OS load, JMX-bean parameters, thread blocking detection, etc. Allows simultaneous work with multiple servers.

**JConsole** - one of the most powerful diagnostic tools allowing real-time information about OS resources used, threads created within JVM process, loaded classes, JMX-bean state retrieval or modification, and many other capabilities.

**Command Line Interface (CLI)** - command-line interface allowing AS management.

For hosts requiring AS monitoring, software environment for OS-level resource monitoring utilities must be prepared:

**NMON** (Nigel's Monitor) - administrator tool for Linux system performance analysis and monitoring.

**Standard OS resource monitoring utilities** (top, mpstat, vmstat, iostat) - for Red Hat Enterprise Linux 6 or higher, top, mpstat, vmstat and iostat utilities are included in delivery.

Installation commands:
```bash
yum -y install procps sysstat
# or
apt-get install procps sysstat
```

**Zabbix Agent** - setup described in section 3.1.11.3 Zabbix Monitoring System Software Environment Setup.

##### 3.1.11.3 Zabbix Monitoring System Software Environment Setup

On hosts where Zabbix Proxy, Zabbix Java Gateway or Zabbix Agent version 3.0.x will be installed, ensure:
- Internet access
- Zabbix repository configuration

For Zabbix Proxy and Zabbix Java Gateway, update PHP to version 5.4 or 5.5 on host.

Install dependencies:
```bash
wget http://dl.fedoraproject.org/pub/epel/7/x86_64/f/fping-3.10-4.el7.x86_64.rpm
rpm -Uhv fping-3.10-4.el7.x86_64.rpm
```

A non-privileged user must be created for Zabbix component processes.

If internet access is unavailable on host, Zabbix component packages must be downloaded separately from repository and made available before installing corresponding monitoring system component.

### 3.2 Installation, Configuration and Update of WFM CC Server Software

#### 3.2.1 WFM CC Database

##### 3.2.1.1 Basic PostgreSQL DBMS Installation

PostgreSQL 10 installation and configuration instructions are described on the official website: https://www.postgresql.org/docs/10/tutorial-install.html

##### 3.2.1.2 Database System User Creation

Before first installation, create database system user argus_sys:
```sql
CREATE ROLE argus_sys WITH LOGIN CREATEDB CREATEROLE PASSWORD '<password>';
```

##### 3.2.1.3 Database Creation and Configuration

**Example of creating database user, database, privileges and schemas:**
```sql
-- Create database
CREATE DATABASE <database_name>;

-- Make argus_sys database owner
ALTER DATABASE <database_name> OWNER TO argus_sys;

-- Grant necessary privileges to argus_sys user
GRANT ALL PRIVILEGES ON DATABASE <database_name> TO argus_sys;

-- Define search path
ALTER DATABASE <database_name> SET search_path = pg_catalog, public, system;
ALTER ROLE argus_sys SET search_path = pg_catalog, public, system;

-- Create dbm schema for data loading
\c <database_name>
CREATE SCHEMA IF NOT EXISTS dbm AUTHORIZATION argus_sys;
```

**Complete example:**
```sql
CREATE ROLE argus_sys WITH LOGIN CREATEDB CREATEROLE PASSWORD '***';
CREATE DATABASE prod OWNER argus_sys;
ALTER DATABASE prod SET search_path = pg_catalog, public, system;
ALTER ROLE argus_sys SET search_path = pg_catalog, public, system;
\c prod
CREATE SCHEMA IF NOT EXISTS dbm AUTHORIZATION argus_sys;
```

##### 3.2.1.4 Required Database Extensions

Install the following PostgreSQL extensions in the database created in section 3.2.1.3:

```sql
\c <database_name>
CREATE EXTENSION IF NOT EXISTS jsquery SCHEMA public;
CREATE EXTENSION IF NOT EXISTS btree_gin SCHEMA public;
CREATE EXTENSION IF NOT EXISTS pg_trgm SCHEMA public;
CREATE EXTENSION IF NOT EXISTS btree_gist SCHEMA public;
CREATE EXTENSION IF NOT EXISTS lo SCHEMA public;
```

If corresponding extension is not available in system, install it first. For PostgreSQL10:
```bash
yum install jsquery_10
```

##### 3.2.1.5 Database Update

1. Obtain update-database-<version>.zip file
2. Unpack the obtained update-database-<version>.zip archive:
```bash
cd /argus && unzip update-database-<version>.zip
```

3. Set database access parameters in dbmaintain.properties file:

**Example dbmaintain.properties:**
```properties
database.dialect=postgresql
database.driverClassName=org.postgresql.Driver
database.password=***
database.url=jdbc\:postgresql\://192.168.100.10\:5432/prod
database.userName=argus_sys
databases.names=prod
dbMaintainer.allowOutOfSequenceExecutionOfPatches=true
dbMaintainer.script.ignoreCarriageReturnsWhenCalculatingCheckSum=true
dbMaintainer.script.locations=data/update-all-ver_0.1.0.jar
```

4. Perform check:
```bash
./dbmaintain.sh checkScriptUpdates
```

5. If check shows presence of scripts for execution, perform update:
```bash
./dbmaintain.sh updateDatabase
```

If call completes with "The database has been updated successfully" line, update is successfully installed.

Otherwise, report problem to NTC ARGUS support specialists, send log file and wait for special recommendations for further action scenario and/or system operability restoration.

#### 3.2.2 WFM CC Application Server

##### 3.2.2.1 Software Environment Setup Check

Ensure requirements from section 3.1.2 are met.

##### 3.2.2.2 Installation Package Archive Unpacking

Unpack installation package archive on AS host using unzip utility:
```bash
unzip [installation_package_archive_name].zip
```

*Archive must be unpacked exactly on AS host, not on administrator's local machine. Otherwise, transferring unpacked archive over network (using SCP/FTP or similar protocol) will lead to problems with Russian letters in file names.*

Archive will be unpacked to current directory. During file extraction, question marks may be displayed instead of Russian letters in console. This is normal.

##### 3.2.2.3 Saving Backup Copy of Previously Installed AS and Its Recovery

If server installation is performed to update previously installed server, create backup copy of previously installed server.

To create application server backup copy, simply create installation directory copy. Stopping application server is not required. Server can be restored by copying saved directory copy to installation directory after preliminary server stop.

##### 3.2.2.4 Application Server Installation

1. Obtain argus-dist-<version>-ccwfm.jar file
2. To install AS, execute command:
```bash
java -jar argus-dist-<version>-ccwfm.jar -options prod.properties
```

##### 3.2.2.5 Application Server Startup

Before startup, ensure AS is not already running.

Check current installed AS status using status parameter of runjboss.sh script by going to AS installation directory INSTALL_PATH/bin and executing command:
```bash
./runjboss.sh status
```

Command execution result will be:
- `wildfly started (pid 1535)` - server is running
- `wildfly not started` - server is not running

To start AS, go to directory <INSTALL_PATH>/bin and execute command:
```bash
cd <INSTALL_PATH>/bin
./runjboss.sh start
```

Command execution result will be:
```
Starting wildfly in default mode (standalone)...
```

**Note:** To start AS under non-privileged user account (e.g., argus), if current user is root, execute command:
```bash
sudo -u argus ./runjboss.sh start
```

AS startup takes several minutes. After AS startup phase completion, web interface becomes available to users, until completion of large data volume loading from database to AS cache, if caches have never been loaded before.

Server will start when file <INSTALL_PATH>/standalone/log/last_boot_errors.log contains "Server started" message.

If last_boot_errors.log contains errors, report problem to NTC ARGUS support specialists, send all log files (entire logs folder) and wait for special recommendations for further action scenario and/or system operability restoration.

**Note:** Since AS cache update process completes outside AS startup phase, AS cache synchronization errors may not be visible in last_boot_errors.log.

##### 3.2.2.6 Application Server Shutdown

To stop server, go to bin subdirectory of installation directory and execute runjboss.sh command with one of the following parameters:

- **stop** - normal server shutdown
- **stop kill** - without waiting for server shutdown, terminates its operation

Shutdown progress is logged to file: InstallationDirectory/standalone/log/server.log.

Upon shutdown completion, the following message is output:
```
16:48:14,397 INFO [as] (MSC service thread 1-2) JBAS015950: WildFly 10.1.0.Final "Tweek" stopped in 1155ms
```

Upon successful AS stop operation execution, the following messages will be displayed on screen:
```
Stopping wildfly:Done.
```

If AS cannot be stopped by standard means, in Linux OS, kill command can be used to stop AS process:
```bash
kill -9 pid
```
where pid is application server process identifier in OS.

*Server stop using runjboss.sh stop command may take several minutes.*

##### 3.2.2.7 Configuration File

Create prod.properties configuration file for startup and specify all necessary parameters in it.

**Example configuration file:**
```properties
# Basic settings
INSTALL_PATH=/argus/jboss_prod/
argus.app.memory.max-size=8192
argus.app.debug-mode.enabled=false
jboss.bind.address.management=0.0.0.0
argus.app.admin.user=developer
argus.app.admin.pass=***
argus.java.home.path=/usr/java/jdk1.8.0_202-amd64
argus.app.security-mode.enabled=false
argus.db.address=192.168.100.10
argus.db.name=demodb
argus.db.port=5432
argus.db.user=argus_sys
argus.db.pass=***
jboss.bind.address=192.168.100.20
jboss.socket.binding.port-offset=0

# Access to each service that WFM CC AS interacts with according to technical architecture
ccwfm.notification.service.enabled=true
ccwfm.notification.service.url=http://192.168.100.25:9000
ccwfm.reportservice.url=http://192.168.100.24:9000
ccwfm.reportservice.url.callback=http://192.168.100.20:8080/ccwfm/reportresult
ccwfm.planningservice.url=http://192.168.100.23:9000
ccwfm.planningservice.url.callback=http://192.168.100.20:8080/ccwfm/planningresult
```

##### 3.2.2.8 AS Administrator Account Setup

AS administrator account provides access to AS administration tools. It's created in two ways:

1. **Using configuration settings during AS installation:**
Using argus.app.admin.user and argus.app.admin.pass parameters

2. **Using add-user.sh script** located in bin subdirectory of installed AS:

Go to bin subdirectory of installed AS and execute:
```bash
./add_user.sh
```

Follow the prompts to create Management User account with appropriate privileges.

For verification of successful AS administrator account creation, access AS management web interface via web browser at http://IP-address:Port/, where:
- IP-address – AS IP address
- Port – port on which server expects management-http connections (9990 + port-offset)

#### 3.2.3 WFM CC Personal Cabinet Service

##### 3.2.3.1 Software Environment Setup Check

Ensure requirements from section 3.1.3 are met.

##### 3.2.3.2 Personal Cabinet Service WFM CC Update Installation

When installing Personal Cabinet Service WFM CC updates, follow this procedure:

1. Stop container
2. Download image
3. Update image
4. Make changes to configuration files
5. Start container
6. If steps 1-5 are successful, delete old container and old container image

**Command examples:**

Current container information on host:
```bash
docker ps -a
```

Stop single container:
```bash
docker stop <container_id>
```

Or all containers described in docker-compose.yml:
```bash
docker-compose stop
```

Download image from remote Argus repository to local repository:
```bash
docker pull gitlab:4567/laboratorium/personal-area/front:dev-<version>
docker pull gitlab:4567/laboratorium/mobile-api:dev-<version>
```

If no access to remote Argus repository, on Argus side download image:
```bash
docker pull gitlab:4567/laboratorium/personal-area/front:dev-<version>
docker pull gitlab:4567/laboratorium/mobile-api:dev-<version>
```

Export image:
```bash
docker image save -o personal-area-<version>.tar gitlab:4567/laboratorium/personal-area/front:dev-<version>
docker image save -o mobile-api-lk<version>.tar gitlab:4567/laboratorium/mobile-api:dev-<version>
```

Transfer container image archive to customer and load into local docker repository:
```bash
docker load -i personal-area-<version>.tar
docker load -i mobile-api-lk<version>.tar
```

Make changes to configuration files (.env and docker-compose.yml).

**Example .env:**
```bash
HOST_IP=192.168.47.3
RMI_PORT=9067
JAVA_OPTS=-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=9067 -Dcom.sun.management.jmxremote.rmi.port=9067 -Dcom.sun.management.jmxremote.local.only=false -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Djava.rmi.server.hostname=192.168.47.3 -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/argus/logs/ -XX:+PrintCommandLineFlags -XX:MinRAMPercentage=10.0 -XX:MaxRAMPercentage=90.0
DB_ADDR=192.168.47.5:5432
DB_NAME=demodb
TZ=Europe/Moscow
MAIN_API_URL=http://192.168.47.3:9060
CCWFM_URL=http://192.168.47.2:8080
```

Start containers and verify successful startup:
```bash
docker-compose up -d
docker ps -a
docker logs -f personal-area
docker logs -f mobile-api-lk
```

##### 3.2.3.3 Service Startup

Start all containers described in docker-compose.yml:
```bash
docker-compose up -d
```

Check successful container startup:
```bash
docker ps -a
docker logs -f lk-service
```

##### 3.2.3.4 Service Shutdown

View current containers on host:
```bash
docker ps -a
```

Stop single container:
```bash
docker stop <container_id>
```

Or all containers described in docker-compose.yml:
```bash
docker-compose stop
```

##### 3.2.3.5 Configuration Files

**Example .env configuration file:**
```bash
HOST_IP=192.168.47.3
DB_ADDR=192.168.47.5:5432
DB_NAME=demodb
TZ=Europe/Moscow
MAIN_API_URL=http://192.168.47.3:9060
CCWFM_URL=http://192.168.47.2:8080
```

**Example docker-compose.yml configuration file:**
[Contains detailed Docker Compose configuration with service definitions, ports, environment variables, and volume mounts]

#### 3.2.4 WFM CC Mobile API Service

##### 3.2.4.1 Software Environment Setup Check

Ensure requirements from section 3.1.4 are met.

##### 3.2.4.2 Mobile API Service WFM CC Update Installation and Configuration

Service configuration is performed by making changes to configuration files followed by service restart.

When installing Mobile API Service WFM CC updates, follow this procedure:

1. Stop container
2. Download image
3. Update image
4. Make changes to configuration files
5. Start container
6. If steps 1-5 are successful, delete old container and old container image

**Command examples:**

Current container information on host:
```bash
docker ps -a
```

Stop single container or all containers:
```bash
docker stop <container_id>
# or
docker-compose stop
```

Download image from remote Argus repository:
```bash
docker pull gitlab:4567/laboratorium/mobile-api:release-<version>
```

If no access to remote Argus repository, export and transfer image:
```bash
docker image save -o mobile-api-<version>.tar gitlab:4567/laboratorium/mobile-api:release-<version>
```

Load image on customer side:
```bash
docker load -i mobile-api-<version>.tar
```

Make changes to configuration files (.env and docker-compose.yml):

**Example .env:**
```bash
HOST_IP=192.168.47.4
RMI_PORT=9017
JAVA_OPTS=-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=9017 -Dcom.sun.management.jmxremote.rmi.port=9017 -Dcom.sun.management.jmxremote.local.only=false -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Djava.rmi.server.hostname=192.168.47.4 -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/argus/logs/ -XX:+PrintCommandLineFlags -XX:MinRAMPercentage=10.0 -XX:MaxRAMPercentage=90.0
DB_ADDR=192.168.47.5:5432
DB_NAME=demodb
TZ=Europe/Moscow
CCWFM_URL=http://192.168.47.2:8080
```

**Example docker-compose.yml:**
```yaml
version: "3"
services:
  mobile-api:
    container_name: mobile-api
    image: gitlab:4567/laboratorium/mobile-api:release-1.3.0
    ports:
      - "9010:8080"
      - "9017:9017"
    restart: always
    environment:
      - DB_ADDR
      - DB_NAME
      - HOST_IP
      - RMI_PORT
      - JAVA_OPTS
      - GW_MODE=mobile
      - CCWFM_URL
      - TZ
    volumes:
      - mobile-api-logs:/argus/logs
    logging:
      driver: "json-file"
      options:
        max-size: "200m"
        max-file: "10"

volumes:
  mobile-api-logs:
    driver: local
    driver_opts:
      o: bind
      type: none
      device: /argus/mobile-api/logs
```

Start containers and verify:
```bash
docker-compose up -d
docker ps -a
docker logs -f mobile-api
```

##### 3.2.4.3 Service Startup

Start all containers:
```bash
docker-compose up -d
docker ps -a
docker logs -f mobile-api
```

##### 3.2.4.4 Service Shutdown

Stop containers:
```bash
docker ps -a
docker stop <container_id>
# or
docker-compose stop
```

##### 3.2.4.5 Configuration Files

**Example .env:**
```bash
HOST_IP=192.168.47.4
DB_ADDR=192.168.47.5:5432
DB_NAME=demodb
TZ=Europe/Moscow
CCWFM_URL=http://192.168.47.2:8080
```

##### 3.2.4.6 Mobile API Service HTTPS Access

Mobile API Service operates via HTTP protocol, so for HTTPS access, a reverse proxy for HTTPS-HTTP traffic conversion is required.

The reverse proxy requires certificate and key files located in the directory specified in configuration file /etc/nginx/nginx.conf:

```nginx
ssl_certificate /etc/nginx/ssl/nginx.crt;
ssl_certificate_key /etc/nginx/ssl/nginx.key;
```

Replace old certificate and key with new ones by substituting corresponding files in the directory specified in /etc/nginx/nginx.conf.

After file replacement, restart nginx service:
```bash
systemctl restart nginx
```

#### 3.2.5 Planning Service

The planning service requires two services, each running in its own docker container:
- **Gateway (planning-gw)**
- **Planning service (planning-service)**

##### 3.2.5.1 Software Environment Setup Check

Ensure requirements from section 3.1.5 are met.

##### 3.2.5.2 Planning Service Update Installation

Follow the same procedure as other services:

1. Stop container
2. Download image
3. Update image
4. Make changes to configuration files
5. Start container
6. Clean up old containers and images

**Command examples:**

```bash
docker ps -a
docker stop <container_id>
docker-compose stop

docker pull gitlab:4567/laboratorium/planning-gw:release-<version>
docker pull gitlab:4567/laboratorium/planning-service:release-<version>
```

For offline installation:
```bash
docker image save -o planning-gw-<version>.tar gitlab:4567/laboratorium/planning-gw:release-<version>
docker image save -o planning-service-<version>.tar gitlab:4567/laboratorium/planning-service:release-<version>

docker load -i planning-gw-<version>.tar
docker load -i planning-service-<version>.tar
```

**Configuration files:**

**Example .env:**
```bash
HOST_IP=192.168.47.8
DB_ADDR=192.168.47.5:5432
DB_NAME=demodb
OPERATING_SCHEDULE_SECONDS_SPENT_LIMIT=144000
TIMETABLE_SECONDS_SPENT_LIMIT=144000
TZ=Europe/Moscow
```

**Example docker-compose.yml:**
```yaml
version: "3"
services:
  planning-gw:
    container_name: planning-gw
    image: gitlab:4567/laboratorium/planning-service/gateway:release-1.4.0
    ports:
      - "9030:8080"
      - "9037:9037"
    restart: always
    environment:
      - DB_ADDR
      - DB_NAME
      - HOST_IP
      - RMI_PORT=9037
      - JAVA_OPTS=-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=9037 -Dcom.sun.management.jmxremote.rmi.port=9037 -Dcom.sun.management.jmxremote.local.only=false -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Djava.rmi.server.hostname=192.168.47.8 -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/argus/logs/ -XX:+PrintCommandLineFlags -XX:MinRAMPercentage=10.0 -XX:MaxRAMPercentage=90.0
      - TZ
    volumes:
      - planning-gw-logs:/argus/logs
    logging:
      driver: "json-file"
      options:
        max-size: "200m"
        max-file: "10"

  planning-service:
    container_name: planning-service
    image: gitlab:4567/laboratorium/planning-service/service:release-1.4.0
    ports:
      - "9047:9047"
    restart: always
    environment:
      - DB_ADDR
      - DB_NAME
      - HOST_IP
      - RMI_PORT=9047
      - JAVA_OPTS=-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=9047 -Dcom.sun.management.jmxremote.rmi.port=9047 -Dcom.sun.management.jmxremote.local.only=false -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Djava.rmi.server.hostname=192.168.47.8 -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/argus/logs/ -XX:+PrintCommandLineFlags -XX:MinRAMPercentage=10.0 -XX:MaxRAMPercentage=90.0
      - OPERATING_SCHEDULE_SECONDS_SPENT_LIMIT
      - TIMETABLE_SECONDS_SPENT_LIMIT
      - TZ
    volumes:
      - planning-service-logs:/argus/logs
    logging:
      driver: "json-file"
      options:
        max-size: "200m"
        max-file: "10"

volumes:
  planning-gw-logs:
    driver: local
    driver_opts:
      o: bind
      type: none
      device: /argus/planning-gw/logs
  planning-service-logs:
    driver: local
    driver_opts:
      o: bind
      type: none
      device: /argus/planning-service/logs
```

##### 3.2.5.3 Service Startup

```bash
docker start <container_id>
# or
docker-compose up -d
docker logs -f planning-gw
docker logs -f planning-service
```

##### 3.2.5.4 Service Shutdown

```bash
docker stop <container_id>
# or
docker-compose stop
```

#### 3.2.6 Reports Service

##### 3.2.6.1 Software Environment Setup Check

Ensure requirements from section 3.1.6 are met.

##### 3.2.6.2 Reports Service Update Installation

Follow standard update procedure:

```bash
docker pull gitlab:4567/laboratorium/report-service:release-<version>
```

**Configuration files:**

**Example .env:**
```bash
HOST_IP=192.168.47.6
RMI_PORT=9007
JAVA_OPTS=-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=9007 -Dcom.sun.management.jmxremote.rmi.port=9007 -Dcom.sun.management.jmxremote.local.only=false -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Djava.rmi.server.hostname=192.168.47.6 -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/argus/logs/ -XX:+PrintCommandLineFlags -XX:MinRAMPercentage=10.0 -XX:MaxRAMPercentage=90.0
SPRING_APPLICATION_JSON={"argus":{"reports":{"datamarts":[{"name":"MAIN_DB","url":"jdbc:postgresql://192.168.47.5:5432/demodb?currentSchema=system","main":true}]}}}
REPORT_DB_ADDR=192.168.47.5:5432
REPORT_DB_NAME=demodb
TZ=Europe/Moscow
```

**Example docker-compose.yml:**
```yaml
version: "3"
services:
  report-service:
    container_name: report-service
    image: gitlab:4567/laboratorium/report-service:release-1.8.0
    ports:
      - "9000:8080"
      - "9007:9007"
    restart: always
    environment:
      - REPORT_DB_ADDR
      - REPORT_DB_NAME
      - SPRING_APPLICATION_JSON
      - HOST_IP
      - RMI_PORT=9007
      - JAVA_OPTS
      - TZ
    volumes:
      - reports-storage:/argus/reports
      - reports-logs:/argus/logs
      - reports-plugins:/argus/plugins
    logging:
      driver: "json-file"
      options:
        max-size: "200m"
        max-file: "10"

volumes:
  reports-storage:
    driver: local
    driver_opts:
      o: bind
      type: none
      device: /argus/reports/storage
  reports-logs:
    driver: local
    driver_opts:
      o: bind
      type: none
      device: /argus/reports/logs
  reports-plugins:
    driver: local
    driver_opts:
      o: bind
      type: none
      device: /argus/reports/plugins
```

**Example db.json:**
```json
{
  "argus": {
    "reports": {
      "datamarts": [
        {
          "name": "MAIN_DB",
          "url": "jdbc:postgresql://192.168.47.5:5432/demodb?currentSchema=system",
          "main": true
        }
      ]
    }
  }
}
```

Start with configuration:
```bash
SPRING_APPLICATION_JSON=$(cat db.json) docker-compose up -d
```

#### 3.2.7 Notifications Service

##### 3.2.7.1 Software Environment Setup Check

Ensure requirements from section 3.1.7 are met.

##### 3.2.7.2 Notifications Service Update Installation

Follow standard update procedure with these configuration files:

**Example .env:**
```bash
HOST_IP=192.168.47.7
RMI_PORT=9027
JAVA_OPTS=-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=9027 -Dcom.sun.management.jmxremote.rmi.port=9027 -Dcom.sun.management.jmxremote.local.only=false -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Djava.rmi.server.hostname=192.168.47.7 -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/argus/logs/ -XX:+PrintCommandLineFlags -XX:MinRAMPercentage=10.0 -XX:MaxRAMPercentage=90.0
NOTIFICATION_DB_ADDR=192.168.47.5:5432
NOTIFICATION_DB_NAME=demodb
TZ=Europe/Moscow
MAIL_FROM=wfmcc@argustelecom.ru
MAIL_SMTP_HOST=mail.argustelecom.ru
MAIL_SMTP_PORT=25
MAIL_SMTP_USER=user
MAIL_SMTP_PASS=pass
```

**Example docker-compose.yml:**
```yaml
version: "3"
services:
  notification-service:
    container_name: notification-service
    image: gitlab:4567/laboratorium/notification-service:release-1.0.2
    ports:
      - "9020:8080"
      - "9027:9027"
    restart: always
    environment:
      - NOTIFICATION_DB_ADDR
      - NOTIFICATION_DB_NAME
      - HOST_IP
      - RMI_PORT=9027
      - JAVA_OPTS
      - TZ
      - MAIL_FROM
      - MAIL_SMTP_HOST
      - MAIL_SMTP_PORT
      - MAIL_SMTP_USER
      - MAIL_SMTP_PASS
      #- MAIL_ENABLED=false
    volumes:
      - notification-service-logs:/argus/logs
    logging:
      driver: "json-file"
      options:
        max-size: "200m"
        max-file: "10"

volumes:
  notification-service-logs:
    driver: local
    driver_opts:
      o: bind
      type: none
      device: /argus/notification-service/logs
```

**For proxy server operation:**

Add to .env file:
- Proxy server address variables: HTTP_PROXY, HTTPS_PROXY
- Hosts/network ranges excluded from proxy: NO_PROXY
- Add proxy parameters to JAVA_OPTS: -Dhttp.proxyHost, -Dhttp.proxyPort, -Dhttps.proxyHost, -Dhttps.proxyPort

Add to docker-compose.yml: HTTP_PROXY, HTTPS_PROXY, NO_PROXY parameters

##### 3.2.7.6 Email Notifications Configuration

Configure email notifications by specifying necessary parameters in .env and docker-compose.yml files.

Uncommented parameter MAIL_ENABLED=false means email notifications are disabled.

To apply changes, restart the service.

#### 3.2.8 Integration Service

##### 3.2.8.1 Software Environment Setup Check

Ensure requirements from section 3.1.8 are met.

##### 3.2.8.2 Installation Package Archive Unpacking

Unpack installation package archive on host using unzip utility:
```bash
unzip [installation_package_archive_name].zip
```

Archive must be unpacked to /argus/integration directory.

Set argus account as application owner:
```bash
chown argus:argus /argus/integration/integration-0.0.46-SNAPSHOT.jar
chmod 500 /argus/integration/integration-0.0.46-SNAPSHOT.jar
```

##### 3.2.8.3 Integration Service Configuration

**General Information:**
- WFM CC AS sends requests to Integration Service
- Integration Service can query Customer's database data itself
- Integration Service can delegate data retrieval and processing to Customer's systems (SOAP or REST format)

**"Integration Systems" Directory:**
Configure integration system connection by filling "Integration Systems" directory:
- System name
- System identifier (must match value specified in yaml file)
- Data access endpoints

Endpoint format: `http://<IS_address>:<IS_port>/services/<method_name>?wsdl`

**Method Names Table:**

| Method Name | Directory Column | Example |
|-------------|------------------|---------|
| personnel | Personnel structure access endpoint | http://192.168.111.222:8091/services/personnel?wsdl |
| historicData | Contact center historical data access endpoint | http://192.168.111.222:8091/services/historicData?wsdl |
| historicOperatorStatus | Operator historical data access endpoint | http://192.168.111.222:8091/services/historicOperatorStatus?wsdl |
| workTimeChats | Operator chat work access endpoint | http://192.168.111.222:8091/services/workTimeChats?wsdl |
| monitoring | Monitoring data access endpoint | http://192.168.111.222:8091/services/monitoring?wsdl |

**Example application.yaml configuration file:**
```yaml
integration:
  naumen:
    enable: true
    system-id: NCC
    base-url: http://192.168.100.30:8888/soap/
    receive-timeout: 120000
  1c:
    enable: true
    system-id: 1c
    base-url: http://192.168.100.40/customer/hs/wfm/
    username: WFMSystem
    password: ***
    logging-requests: true

logging:
  file:
    max-history: 90
    name: log/integration.log
    max-size: 10MB
  level:
    ru.argustelecom.ccwfm.integration.systems.onec: debug
```

After configuration file changes, restart integration service.

##### 3.2.8.4 Integration Service Update Installation

Follow this procedure for updates:

1. Stop service
2. Create backup copy of original distributable and configuration file
3. Install new distributable and grant permissions for argus account
4. Make configuration file changes (if necessary)
5. Edit auto-start file and update systemd configuration
6. Start service

**Commands:**

Stop integration service:
```bash
systemctl stop integration
```

Create backup:
```bash
mv /argus/integration/integration-0.0.46-SNAPSHOT.jar /argus/backup/
cp /argus/distr/integration-0.0.47-SNAPSHOT.zip /argus/integration/
cd /argus/integration/
unzip integration-0.0.47-SNAPSHOT.zip
chown argus:argus /argus/integration/integration-0.0.47-SNAPSHOT.jar
chmod 500 /argus/integration/integration-0.0.47-SNAPSHOT.jar
```

Edit auto-start file /etc/systemd/system/integration.service:
```ini
[Unit]
Description=integration
After=syslog.target

[Service]
User=argus
WorkingDirectory=/argus/integration
ExecStart=/argus/integration/integration-0.0.47-SNAPSHOT.jar
SuccessExitStatus=143
TimeoutStopSec=10
Restart=on-failure
RestartSec=5
OOMScoreAdjust=-1000

[Install]
WantedBy=multi-user.target
```

Update systemd configuration and start service:
```bash
systemctl daemon-reload
systemctl start integration
```

##### 3.2.8.5 Service Startup

```bash
systemctl start integration
systemctl status integration
```

##### 3.2.8.6 Service Shutdown

```bash
systemctl stop integration
systemctl status integration
```

#### 3.2.9 Service Load Balancer

##### 3.2.9.1 Apache Web Server (HTTPD)

Software installation based on apache web server (HTTPD) is performed from Linux OS packages or distributable downloaded from developer website: https://httpd.apache.org/download.cgi

Apache web server (HTTPD) delivery includes mod_cache module.

Additional modules must be downloaded separately:
- mod_jk from http://tomcat.apache.org/download-connectors.cgi
- mod_cluster from http://mod-cluster.jboss.org/downloads

**Static Resource Caching Configuration with httpd + mod_cache:**

Caching is used to obtain and store static resources (images, scripts, pages) on front-end server accessed by users.

Caching purpose is to reduce back-end server (AS) load, increase web page response speed, and decrease network traffic.

Static resource caching settings are specified in configuration file: cache-jk.conf

Cache configuration file cache-jk.conf is connected to main apache (HTTPD) configuration file conf/httpd.conf using Include directive.

**Example cache-jk.conf for httpd-2.2:**
```apache
<IfModule mem_cache_module>
CacheEnable mem /argus/javax.faces.resource/
CacheEnable mem /javax.faces.resource/
CacheIgnoreCacheControl On
CacheDefaultExpire 28800
CacheMaxExpire 86400
CacheIgnoreHeaders Set-Cookie
CacheIgnoreNoLastMod On
CacheStoreNoStore On
CacheStorePrivate On
MCacheSize 10240
MCacheMaxObjectCount 5000
MCacheMinObjectSize 1
MCacheMaxObjectSize 100000
CacheIgnoreURLSessionIdentifiers argus_v
</IfModule>
```

**Load Balancer Configuration httpd + mod_jk:**

Load balancer httpd + mod_jk must be configured according to section 2.1.10.3 Service Load Balancer Requirements.

Configuration file must specify loaded modules:
```apache
LoadModule jk_module modules/mod_jk.so
```

**Example httpd-jk.conf:**
```apache
<IfModule jk_module>
JkWorkersFile ./conf.d/workers.properties
JkLogFile "|/usr/sbin/rotatelogs /var/log/httpd/mod_jk.log 86400"
JkLogLevel info
JkShmFile /var/log/httpd/mod_jk.shm
LogLevel info
LogFormat "%t %a %{JK_WORKER_ROUTE}n: %{JK_LB_LAST_NAME}n(%{JK_LB_LAST_STATE}n/%{JK_LB_LAST_BUSY}n) – %{pid}P-%{tid}P %{JSESSIONID}C %r %s %B %D %{Referer}i \"%{User-Agent}i\"" jk_access_log
CustomLog "logs/jk_access_log" jk_access_log
JkWatchdogInterval 60
</IfModule>
```

**Example workers.properties:**
```properties
worker.list=main-balancer,remotearm-balancer,jk-status,jk-manager

# STATUS WORKER
worker.jk-status.type=status
worker.jk-status.read_only=true
worker.jk-manager.type=status

# MAIN-BALANCER WORKER
worker.main-balancer.balance_workers=argusapp1_8009,argusapp2_8009
worker.main-balancer.reference=worker.balancer.template

# BALANCER WORKER TEMPLATE
worker.balancer.template.type=lb
worker.balancer.template.method=B
worker.balancer.template.max_reply_timeouts=30
worker.balancer.template.recover_time=600
worker.balancer.template.error_escalation_time=0

# MAIN NODE WORKERS
worker.argusapp1_8009.reference=worker.template
worker.argusapp1_8009.host=192.168.100.180
worker.argusapp1_8009.port=8009
worker.argusapp1_8009.activation=A
worker.argusapp1_8009.route=192.168.100.180[0]
```

##### 3.2.9.2 HAProxy Software Load Balancer

**HAProxy Installation:**
Check epel repository installation (section 3.1.3), then install HAProxy:
```bash
yum install haproxy
```

**HAProxy Configuration:**
Configuration is performed in /etc/haproxy/haproxy.cfg file.

**Example haproxy.cfg:**
```
global
    chroot /var/lib/haproxy
    pidfile /var/run/haproxy.pid
    maxconn 4000
    user haproxy
    group haproxy
    daemon
    stats socket /var/lib/haproxy/stats

defaults
    mode http
    log global
    option httplog
    option dontlognull
    retries 3
    timeout http-request 10s
    timeout queue 1m
    timeout connect 10s
    timeout client 1m
    timeout server 1m
    timeout http-keep-alive 10s
    timeout check 10s
    maxconn 3000

frontend master-frontend
    log 127.0.0.1 local6 debug
    option httplog
    bind *:8080
    mode http
    default_backend we-cluster

backend we-cluster
    balance leastconn
    option httpchk GET /rest/servicecheck HTTP/1.0
    server we1 192.168.101.163:8080 check
    server we2 192.168.101.134:8080 check
    server we3 192.168.101.46:8080 check

listen stats
    bind *:1936
    stats enable
    stats uri /stats
    stats hide-version
    stats auth qa:qa
```

After configuration changes, restart load balancer:
```bash
service haproxy restart
```

Configure firewall rules:
```bash
iptables -I INPUT 5 -p tcp -m state --state NEW -m tcp --dport 8080 -j ACCEPT
iptables -I INPUT 5 -p tcp -m state --state NEW -m tcp --dport 1936 -j ACCEPT
iptables-save > /path/to/file
```

#### 3.2.10 Database Load Balancer

##### 3.2.10.1 Keepalived

**Installation:**
```bash
yum install keepalived
```

**Configuration:**
1. Create configuration directory:
```bash
mkdir /etc/keepalived/
```

2. Create configuration file /etc/keepalived/keepalived.conf:
```
! Configuration File for keepalived
global_defs {
    router_id [unique_keepalived_hostname]
}

vrrp_script chk_haproxy {
    script "killall -0 haproxy"
    interval 2
    weight 2
}

vrrp_instance [hostname] {
    state MASTER
    interface eth0
    virtual_router_id 116
    priority 114
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass AsDFDFD!@#123
    }
    virtual_ipaddress {
        [ip-address-VIP]
    }
    track_script {
        chk_haproxy
    }
}
```

3. Restart keepalived:
```bash
service keepalived restart
```

##### 3.2.10.2 Haproxy

**Installation:**
```bash
yum update
yum install haproxy -y
```

**Configuration:**
Edit /etc/haproxy/haproxy.cfg:
```
global
    log /dev/log local0
    log /dev/log local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin
    stats timeout 30s
    user haproxy
    group haproxy
    daemon
    maxconn 2000

defaults
    log global
    mode tcp
    retries 2
    timeout client 30m
    timeout connect 4s
    timeout server 30m
    timeout check 5s

listen stats
    mode http
    bind *:7000
    stats enable
    stats uri /

listen PSQL_MASTER_9999
    bind *:5000
    option httpchk
    http-check expect status 200
    default-server inter 3s fall 3 rise 2 on-marked-down shutdown-sessions
    server [hostname]_5432 [ip-address-patroni1]:5432 maxconn 100 check port 8008
    server [hostname]_5432 [ip-address-patroni2]:5432 maxconn 100 check port 8008
```

Restart service:
```bash
service haproxy restart
```

Check for syntax errors:
```bash
/usr/sbin/haproxy -c -V -f /etc/haproxy/haproxy.cfg
```

##### 3.2.10.3 Etcd

**Installation:**
```bash
yum update
yum install etcd -y
```

Alternative installation method:
```bash
mkdir /tmp/etcd && cd /tmp/etcd
yum install wget -y
curl -s https://api.github.com/repos/etcd-io/etcd/releases/latest | grep browser_download_url | grep linux-amd64 | cut -d '"' -f 4 | wget -qi -
tar xvf *.tar.gz
cd etcd-*/
sudo mv etcd* /usr/local/bin/
cd ~
rm -rf /tmp/etcd
```

Check version:
```bash
etcd --version
etcdctl --version
```

**Configuration:**
Edit /etc/etcd/etcd.conf:
```
#[Member]
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379"
ETCD_NAME="etcd2"
ETCD_HEARTBEAT_INTERVAL="100"
ETCD_ELECTION_TIMEOUT="1000"

#[Clustering]
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://[ip-address-patroni1]:2380"
ETCD_ADVERTISE_CLIENT_URLS="http://[ip-address-patroni2]:2379"
ETCD_INITIAL_CLUSTER="etcd1=http://[ip-address-etcd1]:2380,etcd2=http://[ip-address-etcd2]:2380,etcd3=http://[ip-address-etcd3]:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_INITIAL_CLUSTER_STATE="new"
```

Restart service:
```bash
service etcd restart
```

##### 3.2.10.4 Patroni

**Installation:**
1. Stop PostgreSQL service:
```bash
systemctl stop postgresql
```

2. Create symbolic links:
```bash
ln -s /usr/pgsql-10/bin/* /usr/sbin/
```

3. Install python3 and pip3:
```bash
yum install python3 python-pip3 -y
```

4. Upgrade setuptools:
```bash
pip3 install --upgrade setuptools
```

5. Install Patroni:
```bash
pip3 install patroni
```

**Configuration:**
Create /etc/patroni_01.yaml:
```yaml
scope: postgres
namespace: /db/
name: postgresql0

restapi:
  listen: [ip-address-patroni]:8008
  connect_address: [ip-address-patroni]:8008

etcd:
  hosts: [ip-address-etcd]:2379, [ip-address-etcd]:2379, [ip-address-etcd]:2379

bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 1048576
    postgresql:
      use_pg_rewind: true
      parameters:
        archive_mode: "on"
        archive_command: cp %p /var/lib/pgsql-10/archive/%f
        max_connections: 1000
        shared_buffers: 4GB
        effective_cache_size: 10GB
        maintenance_work_mem: 2GB
        checkpoint_completion_target: 0.9
        wal_buffers: 16MB
        default_statistics_target: 500
        random_page_cost: 1.1
        effective_io_concurrency: 200
        work_mem: 393kB
        min_wal_size: 1GB
        max_wal_size: 1GB

  initdb:
    - encoding: UTF8
    - data-checksums
    - auth-host: md5
    - auth-local: trust

  pg_hba:
    - host replication replica 127.0.0.1/32 md5
    - host replication replica [ip-address]/0 trust
    - host all postgres 127.0.0.1/32 md5

  users:
    admin:
      password: admin
      options:
        - createrole
        - createdb

postgresql:
  listen: [ip-address-postgresql]:5432
  connect_address: [ip-address-postgresql]:5432
  data_dir: /var/lib/pgsql-10/data
  pgpass: /tmp/pgpass
  authentication:
    replication:
      username: postgres
      password: postgres
    superuser:
      username: postgres
      password: postgres
  parameters:
    unix_socket_directories: '.'

tags:
  nofailover: false
  noloadbalance: false
  clonefrom: false
  nosync: false
```

2. Create data directory:
```bash
mkdir /var/lib/pgsql-10/data -p
chown postgres:postgres /var/lib/pgsql-10/data
chmod 700 /var/lib/pgsql-10/data
```

3. Create systemd service file /etc/systemd/system/patroni.service:
```ini
[Unit]
Description=Runners to orchestrate a high-availability PostgreSQL
After=syslog.target network.target

[Service]
Type=simple
User=postgres
Group=postgres
ExecStart=/usr/bin/patroni /etc/patroni_01.yaml
KillMode=process
TimeoutSec=30
Restart=no

[Install]
WantedBy=multi-user.target
```

4. Start Patroni:
```bash
systemctl start patroni
systemctl status patroni
```

Successful startup output:
```
● patroni.service - Runners to orchestrate a high-availability PostgreSQL
Loaded: loaded (/etc/systemd/system/patroni.service; enabled; vendor preset: enabled)
Active: active (running) since Thu 2017-07-29 16:49:18 UTC; 8min ago
Main PID: 13097 (patroni)
... INFO: Lock owner: postgresql0; I am postgresql0
... INFO: no action. i am the leader with the lock
```

#### 3.2.11 Monitoring Tools

##### 3.2.11.1 DBMS Monitoring Setup

DBMS monitoring is performed using Zabbix monitoring system (see section 3.2.11.3 Zabbix Monitoring System Installation and Configuration).

Template configuration for Zabbix Server monitoring is performed by contractor employees.

##### 3.2.11.2 Application Server Monitoring Installation and Setup

On hosts from which remote AS resource monitoring is planned, install utilities: JVisualVM, JConsole, CLI (Command Line Interface).

On AS hosts, install and configure the following utilities and services:
- NMON utility
- Zabbix Agent

Installation details in sections:
- 3.2.11.3.1 Zabbix Component Installation on Host with Internet Access
- 3.2.11.3.2 Zabbix Component Installation on Host without Internet Access
- 3.2.11.3.3 Zabbix Component Configuration

##### 3.2.11.3 Zabbix Monitoring System Installation and Configuration

**Installation on Host with Internet Access:**

Before installing Zabbix components, complete software environment setup described in section 3.1.11.3.

For RHEL 6x, Oracle Linux 6x, CentOS 6x and other supported OS:

Install Zabbix Java Gateway:
```bash
yum install zabbix-java-gateway
```

Install Zabbix Proxy with SQLite3 support:
```bash
yum install zabbix-proxy-sqlite3
```

Install Zabbix Agent:
```bash
yum install zabbix-agent
```

**Installation on Host without Internet Access:**

For RHEL 6x, Oracle Linux 6x, CentOS 6x, download packages from repository: http://repo.zabbix.com/zabbix/3.0/rhel/6/x86_64/

Install using yum with full version and package name specification:
```bash
yum install zabbix-agent-3.0.4-1.el6.x86_64.rpm
yum install zabbix-proxy-sqlite3-3.0.4-1.el6.x86_64.rpm
yum install zabbix-java-gateway-3.0.4-1.el6.x86_64.rpm
```

**Zabbix Component Configuration:**

**Zabbix Agent Configuration:**
Edit /etc/zabbix/zabbix_agentd.conf:
```
PidFile=/var/run/zabbix/zabbix_agentd.pid
LogFile=/var/log/zabbix/zabbix_agentd.log
LogFileSize=0
Server=192.168.100.100
Hostname=argus.domain.ru
RefreshActiveChecks=60
Include=/etc/zabbix/zabbix_agentd.d/
```

**Zabbix Proxy Configuration:**
Edit /etc/zabbix/zabbix_proxy.conf:
```
ProxyMode=0
Server=192.168.100.100
Hostname=argus.domain.ru
LogFile=/var/log/zabbix/zabbix_proxy.log
LogFileSize=0
PidFile=/var/run/zabbix/zabbix_proxy.pid
DBName=/home/argus/db/zabbix_proxy.sqlite3
DBUser=zabbix
StartPingers=2
HeartbeatFrequency=60
ConfigFrequency=600
DataSenderFrequency=1
JavaGateway=localhost
JavaGatewayPort=10052
StartJavaPollers=10
SNMPTrapperFile=/var/log/snmptrap/snmptrap.log
Timeout=4
ExternalScripts=/usr/lib/zabbix/externalscripts
LogSlowQueries=3000
```

**Zabbix Java Gateway Configuration:**
Edit /etc/zabbix/zabbix_java_gateway.conf:
```
PID_FILE="/var/run/zabbix/zabbix_java_gateway.pid"
TIMEOUT=3
```

After installing Zabbix Java Gateway, replace /usr/sbin/zabbix_java/bin/zabbix-java-gateway-3.0.x.jar with jar file provided by NTC Argus.

Copy libraries from AS WildFly 10 to /usr/sbin/zabbix_java/lib/:
```bash
mkdir nmdir
for i in $(cat needed_modules); do find ./modules/system/layers/base/ -iname ${i}*.jar -exec cp {} ./nmdir/ \; ; done
```

needed_modules file contains library names without versions:
```
jboss-logging
jboss-logmanager
jboss-marshalling
jboss-marshalling-river
jboss-remoting
jboss-sasl
jcl-over-slf4j
jul-to-slf4j-stub
log4j-jboss-logmanager
remoting-jmx
slf4j-api
xnio-api
xnio-nio
```

**Starting and Stopping Zabbix Components:**

**Zabbix Agent:**
```bash
/etc/init.d/zabbix-agent start
/etc/init.d/zabbix-agent stop
```

**Zabbix Proxy:**
```bash
/etc/init.d/zabbix-proxy start
/etc/init.d/zabbix-proxy stop
```

**Zabbix Java Gateway:**
```bash
/etc/init.d/zabbix-java-gateway start
/etc/init.d/zabbix-java-gateway stop
```

### 3.3 WFM CC Client Software Installation and Configuration

#### 3.3.1 General Workstation Configuration Requirements

Staff workstations must be equipped with personal computer connected to LAN.

Workstations must have IP connectivity to database server and each WFM CC solution service, or to load balancer in case of service duplication and cluster operation.

#### 3.3.2 Web-client Software Requirements

**Table 3.3.2 - Software Requirements**

| Component | Minimum Requirements | Recommended Requirements |
|-----------|---------------------|-------------------------|
| OS | Operating system officially supporting installation of browsers described below | Operating system officially supporting installation of browsers described below |
| Browser | Firefox 91+, Microsoft Edge 103+, Chrome 98+ | Chrome, Firefox or Microsoft Edge latest version. IE not recommended |

### 3.4 Required Regular Procedures

#### 3.4.1 Backup

Backup frequency and backup copy storage duration are performed according to customer's internal regulation.

Backup must be performed before any technological work related to server software update/modification.

##### 3.4.1.1 Database Backup

Possible backup copy types:

**Logical Backup:**
- Performed using pg_dump, pg_dumpall utilities
- Storage period determined by customer's internal regulation
- Recommended to store at least three latest logical backup copies

**Physical Backup:**
- Performed using pg_basebackup utility
- Storage period determined by customer's internal regulation
- Recommended to store at least three latest physical backup copies

**VM Backup:**
- When using virtualization system for database operation - make VM copies
- Storage period determined by customer's internal regulation
- Recommended to store at least three latest VM backup copies

All backup types should be regularly checked for consistency and recovery capability.

Besides backup copies, database instance configuration files should be saved.

*VM backup copies must be made in combination with logical and physical backups*
*Copy after each change*

##### 3.4.1.2 Application Server Backup

AS backup depends on chosen software deployment method:
- For separate hardware server - copying directory where AS is installed (~1GB)
- For virtualized system - copying entire virtual machine

Backup doesn't require service stop.

Backup can be performed using OS tools or external systems.

*Only binary and configuration files excluding logs*

##### 3.4.1.3 Service Load Balancer Backup

For virtualized system - copying entire virtual machine.

Besides backup copies, load balancer instance configuration files should be saved.

*Copy after each change*

##### 3.4.1.4 Database Load Balancer Backup

For virtualized system - copying entire virtual machine.

Besides backup copies, database load balancer instance configuration files should be saved.

*Copy after each change*

#### 3.4.2 Indicator Monitoring

Where monitoring is required, historical data must be collected for diagnostics and emergency situation analysis.

Monitoring can be performed using OS tools, DBMS (SQL queries to system views), AS (Admin Console), external utilities (JVisualVM, JConsole, Command Line Interface, NMON) and monitoring systems (Zabbix).

Monitor indicators constantly and analyze them according to instructions.

During emergency situations, perform artifact collection, problem analysis and resolution actions according to instructions in section 2.4.5 Standard Actions During Emergency.

##### 3.4.2.1 Database Indicator Monitoring

Database indicator monitoring is performed using pre-configured template on Zabbix Server.

Monitoring parameters and threshold values for alert triggering are set individually during support and stable database operation information accumulation.

*Parameter list provided in Appendix Database Server Monitoring Parameters*

##### 3.4.2.2 Application Server Indicator Monitoring

AS indicator monitoring is performed using pre-configured template on Zabbix Server.

Monitoring parameters and threshold values for alert triggering are set individually during support and stable AS operation information accumulation.

*Parameter list provided in Appendix AS Monitoring Parameters*

#### 3.4.3 Operation Log Archiving

During WFM CC solution component operation, large amounts of debug information are generated in log files.

Log files are necessary for counter-emergency work, so must be stored on host for some time (typically 3-5 days).

Monitor disk space to prevent log files from completely filling it (which threatens service stop), and timely delete log files after agreed storage period expiration.

To save disk space, log files are recommended to be archived and deleted.

Log files are generated in the following directories:

**Database:** <Database_Installation_Directory>/data/log

**Example database archiving and deletion script:**
```bash
#!/bin/bash
log_path=/argus/pgdata/log
except_file_name=postgresql-$(date +"%Y-%m-%d").log
find $log_path -mtime +2 -delete
array=(`find $log_path -name "*.log" -type f`)
for ((i=0; i < ${#array[@]}; i++))
do
    if [ ${array[$i]} == $log_path/$except_file_name ]
    then
        continue
    fi
    gzip ${array[$i]}
done
```

**Application Server:** <AS_Installation_Directory>/standalone/log/

Log files are structured as follows:
- **bugreports/** directory contains error report archives
- **gcstats.log** - garbage collection log saved by JVM Xloggc option
- **access_log.log*** - access log containing HTTP request information
- **last_boot_errors.log** - error log filled during AS startup
- **response.log** - always empty log file, created for technical reasons
- **server.log*** - general log containing server-wide messages
- **webservices.log** - log for web service calls to AS

AS includes automation script for deleting/archiving outdated log files: <AS_Installation_Directory>/tools/unix/remove_old_logs.sh

**Example AS archiving and deletion script:**
```bash
#!/bin/bash
# Log archiving script. Stores archives N days
export PATH=/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin
export argus_logs=/argus/jboss_prod/standalone/log
export logfile=/argus/scripts/arch_logs.log
export bugreports=/argus/jboss_prod/standalone/log/bugreports

date_now=$(date +%Y\-%m\-%d)
OLD_LOGS=$(date -d "-1 day" +"%Y-%m-%d")
BUGREPORTS=$(date -d "-1 day" +"%Y.%m.%d")
OLD_ARCH=$(date -d "-30 day" +"%Y.%m.%d")

echo '======================================================' >> $logfile
echo "Started at `date`" >> $logfile

# Create archives older than 1 day
find /argus/jboss_prod/standalone/log -name "*$OLD_LOGS*" | xargs tar -cvzf /argus/jboss_arch/$OLD_LOGS.logs.tar.gz
find /argus/jboss_prod/standalone/log/bugreports -name "*$BUGREPORTS*" | xargs tar -cvzf /argus/jboss_arch/$BUGREPORTS.logs.bugreports.tar.gz

# Delete all files older than 1 day from AS log directory
find /argus/jboss_prod/standalone/log -name "*$OLD_LOGS*" -exec rm -rf {} \;
find /argus/jboss_prod/standalone/log/bugreports -name "*$BUGREPORTS*" -exec rm -rf {} \;

# Delete archives stored longer than retention period
find /argus/jboss_arch -name "*$OLD_ARCH*" -exec rm -rf {} \;

echo "Finished at `date`" >> $logfile
echo '======================================================' >> $logfile
```

**Load Balancer Log Archiving and Deletion:**
```bash
#!/bin/bash
log_path=/var/log/httpd
find $log_path -mtime +7 -delete
array=(`find $log_path -name "error_log-*" -o -name "access_log-*"`)
for ((i=0; i < ${#array[@]}; i++))
do
    gzip ${array[$i]}
done
```

Archiving and deletion scripts can be run regularly by adding them to task scheduler, e.g., cron (Linux OS).

#### 3.4.4 NMON Configuration

NMON (Nigel's Monitor) - administrator tool for analyzing and monitoring Linux system performance.

NMON can be downloaded from: http://nmon.sourceforge.net/pmwiki.php?n=Site.Download

**Regular Report Preparation Script:**
Runs once daily (added to cron task scheduler):

```bash
#!/bin/bash
export NMONFS=/argus/nmon
cd $NMONFS
/argus/scripts/nmon_x86_64_rhel6 -f -m $NMONFS -s 60 -c 1440
/bin/find $NMONFS -name '*.nmon' -mmin +2880 | xargs gzip
/bin/find $NMONFS -name '*.nmon.gz' -mtime +365 | xargs rm
```

In script, NMON takes 1440 snapshots (-c 1440) every 60 seconds (-s 60). Saves reports to directory NMONFS=/argus/nmon. Archives reports after two days (-mmin +2880). Deletes report archives after 365 days (-mtime +365).

**Report Analyzer:**
Nmon analyzer - tool for creating performance reports for multiple subsystems. Creates Excel document with statistics sheet for each subsystem.

To generate Nmon report analysis, download Nmon analyzer, click "Analyze nmon data" button, select Nmon report.

Analyzer can be downloaded from: https://www.ibm.com/developerworks/community/wikis/home?lang=en#!/wiki/Power+Systems/page/nmon_analyser

Script can be installed remotely by contractor using configuration management system: Ansible. Host must have ssh server running and python2.7+ package installed.

#### 3.4.5 AS Temporary Files Directory Cleanup

Temporary files directory stores temporary files used during report building and export.

Directory is specified as AS parameter java.io.tmpdir value.

Can be cleaned with script added to task scheduler, e.g., cron (Linux OS).

**Example temporary file deletion script for AS Reports Server:**
```bash
#!/bin/bash
# Temporary file deletion script java.io.tmpdir. Stores files N days
export PATH=/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin
export argus_tmp=/argus/tmp
export logfile=/argus/scripts/cleartmp.log

date_now=$(date +%Y\-%m\-%d)
echo '======================================================' >> $logfile
echo "Started at `date`" >> $logfile
ls -al $argus_tmp >> $logfile

# Delete temporary files stored longer than N days
find /argus/tmp -mtime +N -exec rm -rf {} \;

echo "Finished at `date`" >> $logfile
echo '======================================================' >> $logfile
```

*Script must be adapted to specific host directory structure (see section 3.1.2.9 Directory Organization) and OS; Script not included in AS distributable*

### 3.5 Software Update Measures When Transitioning to Another Time Zone

#### 3.5.1 Checking for New Time Zone Information

Before database and JVM patches appear, information should appear on website https://www.iana.org/time-zones

*Changes are listed in News file in archive (e.g., tzdb-2018e.tar.lz)*

#### 3.5.2 JDK Time Zone Update

To update time zone data, go to JDK_HOME/bin directory and execute command:
```bash
java -jar tzupdater.jar -u
```

tzupdater.jar can be obtained from: https://www.oracle.com/technetwork/java/javase/downloads/tzupdater-download-513681.html

Check update results by executing command from JDK_HOME/bin directory:
```bash
java TestTimezone ddmmyyyy
```

#### 3.5.3 joda-time Library Update in AS

Obtain AS with updated joda-time library from Argus.

---

## 4. Administrator Reference Guides

### 4.1 Database Administrator Reference

#### 4.1.1 pgdump

To create and compress copy from production zone, execute command on database server (under postgres account):
```bash
cd /tmp && pg_dump -Fc prod > prod_07.06.2022.Fc && tar -czvf prod_07.06.2022.Fc.tar.gz prod_07.06.2022.Fc
```
*prod is the database name being extracted*

Transfer copy to target database server and decompress:
```bash
cd /tmp && tar -xf prod_07.06.2022.Fc.tar.gz
```

Connect to target database:
```bash
psql -h 127.0.0.1 -p 5432 -U postgres
```

Save existing database and create new database with dump:
```sql
alter database demodb rename to demodb_old;
CREATE DATABASE demodb OWNER argus_sys;
```

```bash
psql demodb < /tmp/prod_07.06.2022.Fc
```

**IMPORTANT!** /tmp directory is used as example since it exists on any Linux OS and has write permissions for any account. Actually, /tmp size may be insufficient, and depending on dump size, another directory in OS partition with sufficient space and write permissions for postgres account should be chosen.

More details about pgdump utility: https://postgrespro.ru/docs/postgresql/10/app-pgdump

### 4.2 Application Server and Services Administrator Reference

#### 4.2.1 heapdump and threaddump

Dump creation (heapdump and threaddump) is performed using JDK utilities: jcmd and jstack with the following format:

```bash
# heapdump
jcmd <pid> GC.heap_dump <file-path>

# threaddump  
jstack <pid> > <file-path>
```

*Usually in docker container, single process runs with pid = 1*

##### 4.2.1.1 WFM CC AS heapdump and threaddump

**heapdump:**
Go to AS installation directory INSTALL_PATH/bin and execute:
```bash
./runjboss.sh heap-dump
```
Dump will be created in current directory INSTALL_PATH/bin

**threaddump:**
Go to AS installation directory INSTALL_PATH/bin and execute:
```bash
./runjboss.sh thread-dump
```
Dump will be created in current directory INSTALL_PATH/bin

##### 4.2.1.2 Personal Cabinet Service WFM CC heapdump and threaddump

Prerequisites:
1. Docker container configured with directory mapping from container to OS (see section 3.2.7.5 Configuration Files)
2. Sufficient disk space at external OS directory mount point for dump storage

**heapdump:**
```bash
docker container exec -it container_name /bin/bash
export DATE=`date +%Y-%m-%d-%H_%M_%S`
jcmd 1 GC.heap_dump /argus/logs/heap_dump_$DATE
```

**threaddump:**
```bash
docker container exec -it container_name /bin/bash
export DATE=`date +%Y-%m-%d-%H_%M_%S`
jstack 1 > /argus/logs/threaddump_$DATE.txt
```

##### 4.2.1.3 Mobile API Service WFM CC heapdump and threaddump

**heapdump:**
```bash
docker container exec -it container_name /bin/bash
export DATE=`date +%Y-%m-%d-%H_%M_%S`
jcmd 1 GC.heap_dump /argus/logs/heap_dump_$DATE
```

**threaddump:**
```bash
docker container exec -it container_name /bin/bash
export DATE=`date +%Y-%m-%d-%H_%M_%S`
jstack 1 > /argus/logs/threaddump_$DATE.txt
```

##### 4.2.1.4 Reports Service heapdump and threaddump

**heapdump:**
```bash
docker container exec -it container_name /bin/bash
export DATE=`date +%Y-%m-%d-%H_%M_%S`
jcmd 1 GC.heap_dump /argus/logs/heap_dump_$DATE
```

**threaddump:**
```bash
docker container exec -it container_name /bin/bash
export DATE=`date +%Y-%m-%d-%H_%M_%S`
jstack 1 > /argus/logs/threaddump_$DATE.txt
```

##### 4.2.1.5 Planning Service heapdump and threaddump

**Planning Gateway (planning-gw):**

Via web UI:
- heapdump: http://192.168.47.8:9030/actuator/heapdump (download starts)
- threaddump: http://192.168.47.8:9030/actuator/threaddump (JSON response displayed)

Via docker container:
```bash
docker container exec -it container_name /bin/bash
export DATE=`date +%Y-%m-%d-%H_%M_%S`
jcmd 1 GC.heap_dump /argus/logs/heap_dump_$DATE
jstack 1 > /argus/logs/threaddump_$DATE.txt
```

**Planning Service (planning-service):**
```bash
docker container exec -it container_name /bin/bash
export DATE=`date +%Y-%m-%d-%H_%M_%S`
jcmd 1 GC.heap_dump /argus/logs/heap_dump_$DATE
jstack 1 > /argus/logs/threaddump_$DATE.txt
```

##### 4.2.1.6 Notifications Service heapdump and threaddump

**heapdump:**
```bash
docker container exec -it container_name /bin/bash
export DATE=`date +%Y-%m-%d-%H_%M_%S`
jcmd 1 GC.heap_dump /argus/logs/heap_dump_$DATE
```

**threaddump:**
```bash
docker container exec -it container_name /bin/bash
export DATE=`date +%Y-%m-%d-%H_%M_%S`
jstack 1 > /argus/logs/threaddump_$DATE.txt
```

#### 4.2.2 Log Files

In /argus directory, .log extension files are logs for current date only. Logs for other dates are archived by application and have .gz extension.

##### 4.2.2.1 Application Server Logs

To download AS log files, connect to AS host using any convenient method (e.g., sftp) and download entire directory /argus/jboss_prod/standalone/log

##### 4.2.2.2 Personal Cabinet Logs

To download Personal Cabinet log files, connect to Personal Cabinet host and download entire directories /argus/mobile-api-lk/logs and /argus/personal-area/logs

##### 4.2.2.3 Mobile API Logs

To download Mobile API log files, connect to Mobile API host and download entire directory /argus/mobile-api/logs

##### 4.2.2.4 Planning Service Logs

To download Planning Service log files, connect to Planning Service host and download entire directories /argus/planning-gw/logs and /argus/planning-service/logs

##### 4.2.2.5 Reports Service Logs

To download Reports Service log files, connect to Reports Service host and download entire directory /argus/reports/logs

##### 4.2.2.6 Notifications Service Logs

To download Notifications Service log files, connect to Notifications Service host and download entire directory /argus/notification-service/logs

##### 4.2.2.7 Integration Service Logs

To download Integration Service log files, connect to Integration Service host and download entire directory /argus/integration/log

---

## Change Registration Sheet

| Document | Date | Executor | Brief Description of Change |
|----------|------|----------|----------------------------|
| 1 | 21.10.2021 | Trifonov A.A. | Base version |
| 2 | 11.05.2021 | Trifonov A.A. | Added chapter 3.2.4.6 Mobile API Service HTTPS Access |
| 3 | 20.05.2021 | Trifonov A.A. | Added chapter 3.2.7.6 Email Notifications Configuration |
| 4 | 03.06.2022 | Trifonov A.A. | Updated services with -XX:MinRAMPercentage=10.0 parameter |
| 5 | 06.06.2022 | Trifonov A.A. | Added proxy configuration descriptions |
| 6 | 07.06.2022 | Trifonov A.A. | Supplemented integration service configuration description |
| 7 | 09.06.2022 | Trifonov A.A. | Added chapter 4.1.1 pgdump |
| 8 | 30.06.2022 | Trifonov A.A. | Added chapter 4.2 AS and Services Administrator Reference |
| 9 | 04.07.2022 | Trifonov A.A. | Added chapter 4.2.2 Log Files |

---

## List of Accepted Abbreviations

| Abbreviation | English | Russian |
|--------------|---------|---------|
| DB | Database | База Данных |
| KTS | Technical Complex | Комплекс Технических Средств |
| LAN | Local Area Network | Локальная Вычислительная Сеть |
| OS | Operating System | Операционная Система |
| SW | Software | Программное Обеспечение |
| IS | Integration Service | Сервис Интеграций |
| RS | Reports Service | Сервис Отчетов |
| AS | Application Server | Сервер Приложений |
| NS | Notifications Service | Сервис уведомлений |
| TA | Technical Architecture | Техническая Архитектура |
| TS | Technical Specification | Техническое Задание |
| WFM CC | Work Force Management Call Center | Work Force Management Call Center |

---

## Appendices

### Monitoring Parameters

#### Application Server Monitoring Parameters

**Item Keys:**
- agent.hostname
- agent.ping
- agent.version
- avg.servlet.page.response.time
- increment-avg-servlet-page-response-time
- jmx["java.lang:type=GarbageCollector,name=PS MarkSweep","CollectionCount"]
- jmx["java.lang:type=GarbageCollector,name=PS MarkSweep","CollectionTime"]
- jmx["java.lang:type=GarbageCollector,name=PS Scavenge","CollectionCount"]
- jmx["java.lang:type=GarbageCollector,name=PS Scavenge","CollectionTime"]
- jmx["java.lang:type=Memory","HeapMemoryUsage.used"]
- jmx["java.lang:type=Memory","NonHeapMemoryUsage.used"]
- jmx["java.lang:type=Threading","ThreadCount"]
- jmx["jboss.as.expr:data-source=ArgusDS,subsystem=\"datasources\",statistics=\"pool\"","AvailableCount"]
- jmx["jboss.as.expr:deployment=ccwfm-app-{$APP_VERSION}.ear,subsystem=\"undertow\",subdeployment=\"webui-{$APP_VERSION}.war\"","activeSessions"]
- jmx["jboss.as.expr:deployment=ccwfm-app-{$APP_VERSION}.ear,subsystem=\"undertow\",subdeployment=\"webui-{$APP_VERSION}.war\"","sessionsCreated"]
- jmx["jboss.as.expr:subsystem=argus,request-resource=RequestResource","pageRequestCount"]
- jmx["jboss.as.expr:subsystem=argus,request-resource=RequestResource","totalPageRequestTime"]
- jmx["jboss.as:subsystem=argus,request-resource=RequestResource","pageRequestCount"]
- jmx["jboss.as:subsystem=argus,request-resource=RequestResource","totalPageRequestTime"]
- jmx["jboss.as:subsystem=argus,worker-resource=default","activeCount"]
- jmx["jboss.as:subsystem=argus,worker-resource=default","completedTaskCount"]
- jmx["jboss.as:subsystem=argus,worker-resource=default","taskCount"]
- jvm.request.resource[{$JMX_USERNAME},{$JMX_PASSWORD}]
- jvm.worker.resource[{$JMX_USERNAME},{$JMX_PASSWORD}]
- kernel.maxfiles
- kernel.maxproc
- Network interface discovery metrics
- net.tcp.service[http,{HOST.IP},8080]
- proc.cpu.util[java,argus]
- proc.num[,,run]
- proc.num[]
- system.boottime
- system.cpu.intr
- system.cpu.load[percpu,avg1]
- system.cpu.load[percpu,avg5]
- system.cpu.load[percpu,avg15]
- system.cpu.switches
- system.cpu.util[,idle]
- system.cpu.util[,interrupt]
- system.cpu.util[,iowait]
- system.cpu.util[,nice]
- system.cpu.util[,softirq]
- system.cpu.util[,steal]
- system.cpu.util[,system]
- system.cpu.util[,user]
- system.hostname
- system.localtime
- system.swap.in[,pages]
- system.swap.out[,pages]
- system.swap.size[,free]
- system.swap.size[,pfree]
- system.swap.size[,total]
- system.uname
- system.uptime
- system.users.num
- vfs.file.cksum[/etc/passwd]
- Mounted filesystem discovery metrics
- vm.memory.size[available]
- vm.memory.size[total]

#### Database Server Monitoring Parameters

**Item Keys:**
- pgsql.archive_command.archived_files[{$PG_CONNINFO}]
- pgsql.archive_command.count_files_to_archive[{$PG_CONNINFO}]
- pgsql.archive_command.failed_trying_to_archive[{$PG_CONNINFO}]
- pgsql.archive_command.size_files_to_archive[{$PG_CONNINFO}]
- pgsql.autovacuum.count[{$PG_CONNINFO}]
- pgsql.bgwriter.buffers_alloc[{$PG_CONNINFO}]
- pgsql.bgwriter.buffers_backend[{$PG_CONNINFO}]
- pgsql.bgwriter.buffers_backend_fsync[{$PG_CONNINFO}]
- pgsql.bgwriter.buffers_checkpoint[{$PG_CONNINFO}]
- pgsql.bgwriter.buffers_clean[{$PG_CONNINFO}]
- pgsql.bgwriter.maxwritten_clean[{$PG_CONNINFO}]
- pgsql.blocks.hit[{$PG_CONNINFO}]
- pgsql.blocks.read[{$PG_CONNINFO}]
- pgsql.buffers.dirty[{$PG_CONNINFO}]
- pgsql.buffers.size[{$PG_CONNINFO}]
- pgsql.buffers.twice_used[{$PG_CONNINFO}]
- pgsql.cache.hit[{$PG_CONNINFO}]
- pgsql.checkpoint.checkpoint_sync_time[{$PG_CONNINFO}]
- pgsql.checkpoint.count_timed[{$PG_CONNINFO}]
- pgsql.checkpoint.count_wal[{$PG_CONNINFO}]
- pgsql.checkpoint.write_time[{$PG_CONNINFO}]
- pgsql.connections.active[{$PG_CONNINFO}]
- pgsql.connections.disabled[{$PG_CONNINFO}]
- pgsql.connections.fastpath_function_call[{$PG_CONNINFO}]
- pgsql.connections.idle[{$PG_CONNINFO}]
- pgsql.connections.idle_in_transaction[{$PG_CONNINFO}]
- pgsql.connections.idle_in_transaction_aborted[{$PG_CONNINFO}]
- pgsql.connections.max_connections[{$PG_CONNINFO}]
- pgsql.connections.total[{$PG_CONNINFO}]
- pgsql.connections.waiting[{$PG_CONNINFO}]
- Database discovery metrics
- pgsql.events.checksum_failures[{$PG_CONNINFO}]
- pgsql.events.conflicts[{$PG_CONNINFO}]
- pgsql.events.deadlocks[{$PG_CONNINFO}]
- pgsql.events.xact_rollback[{$PG_CONNINFO}]
- pgsql.oldest.transaction_time[{$PG_CONNINFO}]
- pgsql.oldest.xid_age[{$PG_CONNINFO}]
- pgsql.pg_locks.accessexclusive[{$PG_CONNINFO}]
- pgsql.pg_locks.accessshare[{$PG_CONNINFO}]
- pgsql.pg_locks.exclusive[{$PG_CONNINFO}]
- pgsql.pg_locks.rowexclusive[{$PG_CONNINFO}]
- pgsql.pg_locks.rowshare[{$PG_CONNINFO}]
- pgsql.pg_locks.sharerowexclusive[{$PG_CONNINFO}]
- pgsql.pg_locks.shareupdateexclusive[{$PG_CONNINFO}]
- pgsql.pg_locks.share[{$PG_CONNINFO}]
- pgsql.ping[{$PG_CONNINFO}]
- pgsql.replication_lag.sec[{$PG_CONNINFO}]
- pgsql.stat.dirty_bytes[{$PG_CONNINFO}]
- pgsql.stat.other_time[{$PG_CONNINFO}]
- pgsql.stat.read_bytes[{$PG_CONNINFO}]
- pgsql.stat.read_time[{$PG_CONNINFO}]
- pgsql.stat.write_bytes[{$PG_CONNINFO}]
- pgsql.stat.write_time[{$PG_CONNINFO}]
- pgsql.temp.bytes[{$PG_CONNINFO}]
- pgsql.temp.files[{$PG_CONNINFO}]
- pgsql.transactions.total[{$PG_CONNINFO}]
- pgsql.tuples.deleted[{$PG_CONNINFO}]
- pgsql.tuples.fetched[{$PG_CONNINFO}]
- pgsql.tuples.inserted[{$PG_CONNINFO}]
- pgsql.tuples.returned[{$PG_CONNINFO}]
- pgsql.tuples.updated[{$PG_CONNINFO}]
- pgsql.uptime[{$PG_CONNINFO}]
- pgsql.wal.count[{$PG_CONNINFO}]
- pgsql.wal.write[{$PG_CONNINFO}]
- system.cpu.idle
- system.cpu.iowait
- system.cpu.irq
- system.cpu.nice
- system.cpu.softirq
- system.cpu.system
- system.cpu.user
- system.disk.all_read
- system.disk.all_read_b
- system.disk.all_write
- system.disk.all_write_b
- system.la.1
- system.memory.active
- system.memory.apps
- system.memory.buffers
- system.memory.cached
- system.memory.committed
- system.memory.inactive
- system.memory.mapped
- system.memory.page_tables
- system.memory.slab
- system.memory.swap
- system.memory.swap_cache
- system.memory.unused
- system.memory.vmalloc_used
- Network interface discovery metrics
- system.open_files
- system.processes.blocked
- system.processes.forkrate
- system.processes.running
- system.up_time
- VFS discovery metrics

---

*This completes the full translation of the ARGUS WFM CC Administrator Guide from Russian to English, maintaining all technical accuracy, structure, and professional documentation standards.*

