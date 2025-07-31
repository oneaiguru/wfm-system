# Deep Research Request: Create Domain Packages from REAL Argus System

## 



### ONLY Analyze These Folders:
- ✅ `argus-reality-only/` - Contains ONLY verified findings from real Argus system
- ✅ `bdd-specs/` - Feature specifications (when available)

### COMPLETELY IGNORE These:
- ❌ `our-implementation/` - Our WFM replica code (NOT Argus)
- ❌ `verified-knowledge/` - Old polluted data
- ❌ Any files containing `/api/v1/*` REST endpoints
- ❌ React components (.tsx files)
- ❌ FastAPI routes

## 📁 Repository Structure You'll Find

```
/project/deep-research-context/
├── argus-reality-only/         # ONLY ANALYZE THIS
│   ├── ui-navigation/          # Real Argus .xhtml pages
│   ├── api-behavior/           # JSF patterns (NO REST APIs)
│   ├── architecture/           # JSF/PrimeFaces documentation
│   └── algorithms/             # (May be empty)
├── our-implementation/         # IGNORE COMPLETELY
└── README-CRITICAL.md          # Read this first!
```

## 🎯 Your Task

Create domain packages for R1-R8 agents based ONLY on verified Argus findings. Each package should help agents understand what actually exists in Argus (not what we plan to build).

## 📋 Expected Domain Package Structure

```json
{
  "domain": "R1-SecurityAdmin",
  "package_version": "2.0-clean",
  "based_on": "REAL ARGUS ONLY",
  
  "argus_pages": {
    "login": {
      "url": "/ccwfm/login.xhtml",
      "type": "JSF page",
      "verified": true
    },
    "security_admin": {
      "url": "/ccwfm/admin/security/roles.xhtml",
      "type": "JSF page",
      "verified": true
    }
  },
  
  "interaction_patterns": {
    "framework": "JSF/PrimeFaces",
    "ajax_method": "PrimeFaces.ab()",
    "state_management": "ViewState parameter",
    "session_timeout": "22 minutes",
    "rest_apis": "NONE - Argus doesn't use REST"
  },
  
  "ui_elements": {
    "language": "Russian",
    "component_library": "PrimeFaces",
    "not_react": true
  },
  
  "scenarios_to_verify": [
    // List BDD scenarios this domain should verify
  ],
  
  "known_gaps": [
    // What we know is missing or unclear
  ]
}
```

## 🚫 What NOT to Include

- NO `/api/v1/*` endpoints (they don't exist in Argus)
- NO React components (Argus uses PrimeFaces)
- NO REST API patterns (Argus uses JSF POST)
- NO modern SPA architecture (Argus is server-side JSF)

## ✅ What to Include

- Real .xhtml page URLs from argus-reality-only/
- PrimeFaces.ab() AJAX patterns
- JSF form submission patterns
- ViewState management
- Russian UI elements
- Actual verified findings only

## 📊 Success Criteria

1. Domain packages contain ZERO REST API references
2. All URLs end with .xhtml
3. Interaction patterns reflect JSF/PrimeFaces
4. Based only on argus-reality-only/ folder contents
5. Help agents understand Argus reality (not our plans)

## 🎯 Deliverables

Create 8 domain packages:
1. R1-SecurityAdmin
2. R2-EmployeeSelfService  
3. R3-SchedulingOperations
4. R4-ForecastingAnalytics
5. R5-ManagerOversight
6. R6-SystemIntegration
7. R7-ReportingAnalytics
8. R8-MobileExperience

Each package should be <80KB and contain only verified Argus findings.

Remember: We're documenting what EXISTS in Argus, not what we're building!