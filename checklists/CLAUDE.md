# Documentation Analysis Checklists - CLAUDE.md

## 🎯 **Purpose**
This folder contains feature checklists extracted from ARGUS WFM documentation to verify BDD specification coverage.

---

## 🤖 **Agent Instructions**

### **Primary Task:**
Analyze ARGUS documentation and create comprehensive feature checklists for coverage verification against BDD specifications.

### **Workflow:**
1. **Receive Document** → Analyze for features
2. **Create Checklist** → Structured markdown format
3. **Organize by Module** → Proper file naming
4. **Tag for Search** → Keywords for coverage check

---

## 📁 **Current Folder Structure**

### **Checklist Files → Source Document Mapping:**
```
checklists/
├── 1c-integration-checklist.md              # → 1c-integration-requirements-en.md ✅ VERIFIED
├── database-structure-checklist.md          # → Описание структуры хранения данных БД Аргус WFMCC
├── rest-api-integration-checklist.md        # → rest-api-integration-en.md
├── planning-workflows-checklist.md          # → planning-workflows-en.md
├── admin-guide-checklist.md                 # → admin-guide-en.md
├── manual-part1-checklist.md                # → argus-wfm-manual-part1-en.md (Lines 1-857)
├── manual-part1-checklist-cont1.md          # → argus-wfm-manual-part1-en.md (Lines 1004+)
├── manual-part1-checklist-cont2.md          # → argus-wfm-manual-part1-en.md (continuation)
├── manual-part1-checklist-cont3.md          # → argus-wfm-manual-part1-en.md (continuation)
├── manual-part2-checklist.md                # → argus-wfm-manual-part2-en.md
├── manual-part2-checklist-cont1.md          # → argus-wfm-manual-part2-en.md (continuation)
├── manual-part2-checklist-cont2.md          # → argus-wfm-manual-part2-en.md (continuation)
├── manual-part2-checklist-cont3.md          # → argus-wfm-manual-part2-en.md (continuation)
└── coverage-reports/                        # 📊 Coverage verification results
    ├── 1c-integration-COVERAGE.md           # ✅ 89% coverage analysis
    ├── 1c-integration-IMPROVEMENTS.md       # 📝 Missing scenarios to add  
    └── 1c-integration-DIFF.md               # 🔧 Implementation guide
```

### **Source Documents Location:**
```
../../../docs-consolidated/База знаний WFM CC/Документация/
├── Описание структуры хранения данных БД Аргус WFMCC (ред. 04.2024)/
│   └── Translated copy of Описание структуры хранения данных БД Аргус WFMCC (ред. 04.2024).md
├── Описание требований к интеграции с системой 1СЗУП.../
│   └── 1c-integration-requirements-en.md
├── Описание интеграции с системой WFM CC по активному REST API, 10.2024/
│   └── rest-api-integration-en.md
├── Планирование_графиков_работ_и_расписания_АРГУС_WFMCC/
│   └── planning-workflows-en.md
├── argus_wfm_admin_guide/
│   └── admin-guide-en.md
└── РП_WFMCC_апрель_2025/
    ├── argus-wfm-manual-part1-en.md
    └── argus-wfm-manual-part2-en.md
```

---

## 🤖 **Agent Usage Instructions**

### **Working with Checklist Files:**

1. **Finding Source Documents:**
   - All checklists are extracted from English docs in `../../../docs-consolidated/База знаний WFM CC/Документация/`
   - Each checklist file name directly corresponds to its source document
   - Use the mapping above to find the original document for context

2. **Coverage Checking Workflow:**
   ```bash
   # For each checklist item:
   1. Take keywords from checklist
   2. Search in ../bdd-specifications/ BDD files
   3. Mark coverage status: Missing/Partial/Complete
   4. Note which BDD file contains the feature
   ```

3. **Multi-part Document Handling:**
   - **manual-part1-checklist.md** = Main part (lines 1-857)
   - **manual-part1-checklist-cont1.md** = Lines 1004+ (gap indicates missing content)
   - **manual-part1-checklist-cont2.md** = Further continuation
   - **manual-part1-checklist-cont3.md** = Final continuation
   - **manual-part2-checklist.md** = Separate document, different content

4. **Gap Analysis:**
   - Note: Gap from line 857 to 1004 in manual-part1 indicates missing content
   - This may represent unreported features or processing gaps
   - Check source document for complete coverage

### **Priority for Coverage Checking:**
```
1. 1c-integration-checklist.md           # Critical 1C ZUP integration ✅ COMPLETED
2. database-structure-checklist.md       # Database and storage features  
3. rest-api-integration-checklist.md     # REST API features
4. planning-workflows-checklist.md       # Core planning functionality
5. admin-guide-checklist.md              # Administrative features
6. manual-part1-checklist.md             # Core system features
7. manual-part2-checklist.md             # Extended functionality
```

---

## 📊 **Coverage Verification Process**

### **Completed Verification:**

#### **1c-integration-checklist.md** ✅ COMPLETE
- **Coverage**: 89% (47/53 features)
- **Missing**: 4 features (7%)
- **Partial**: 2 features (4%) 
- **BDD File**: 21-1c-zup-integration.feature
- **Status**: Implementation guide ready

**Results:**
- ✅ All critical APIs covered (sendSchedule, getTimetypeInfo, getNormHours, sendFactWorkTime)
- ✅ Complete time type logic with Russian codes (I/Я, H/Н, B/В, RV/РВ, etc.)
- ✅ Comprehensive error handling and performance specs
- ❌ Missing: Time standards actualization, document execution, initial setup
- ⚠️ Partial: Vacation schedule upload format, vacation accrual algorithm

**Files Created:**
- `coverage-reports/1c-integration-COVERAGE.md` - Detailed coverage analysis
- `coverage-reports/1c-integration-IMPROVEMENTS.md` - Missing scenarios specification  
- `coverage-reports/1c-integration-DIFF.md` - Implementation guide for coding agents

### **Template Established:**
The 1C integration verification serves as the **template pattern** for all remaining checklists:

1. **Systematic Search** - Keywords from checklist → BDD files
2. **Coverage Classification** - ✅ Complete / ⚠️ Partial / ❌ Missing
3. **Detailed Analysis** - Exact file locations, line numbers, scenario names
4. **Gap Documentation** - Clear specifications for missing features
5. **Implementation Guide** - Ready-to-add BDD scenarios with exact insertion points

### **Next Steps:**
Apply the same process to remaining 12 checklist files:
```
□ database-structure-checklist.md       
□ rest-api-integration-checklist.md     
□ planning-workflows-checklist.md       
□ admin-guide-checklist.md              
□ manual-part1-checklist.md             
□ manual-part1-checklist-cont1.md       
□ manual-part1-checklist-cont2.md       
□ manual-part1-checklist-cont3.md       
□ manual-part2-checklist.md             
□ manual-part2-checklist-cont1.md       
□ manual-part2-checklist-cont2.md       
□ manual-part2-checklist-cont3.md       
```

---

## 🔧 **Working with Coverage Reports**

### **Using Coverage Reports:**

#### **For Analysis:**
```bash
# Review coverage analysis
cat coverage-reports/1c-integration-COVERAGE.md

# Check specific feature coverage
grep -A5 -B5 "Feature: Work schedule loading" coverage-reports/1c-integration-COVERAGE.md
```

#### **For Implementation:**
```bash
# Get implementation instructions
cat coverage-reports/1c-integration-IMPROVEMENTS.md

# Get exact diff for coding
cat coverage-reports/1c-integration-DIFF.md

# Apply changes to BDD file
# Follow line-by-line instructions in DIFF file
```

### **Coverage Report Structure:**
```
coverage-reports/
├── [checklist-name]-COVERAGE.md     # Analysis: what's covered/missing
├── [checklist-name]-IMPROVEMENTS.md # Specifications: what to add  
└── [checklist-name]-DIFF.md         # Implementation: how to add
```

### **Coverage Analysis Template:**
Each coverage report contains:
- **Summary Statistics** (Total/Covered/Missing/Partial percentages)
- **Feature-by-Feature Analysis** with exact BDD locations
- **Missing Features Priority List** 
- **Specific Recommendations** for improvements

### **Implementation Template:**
Each implementation guide contains:
- **BEFORE State** - Current gaps documented
- **AFTER State** - Complete new scenarios to add
- **Step-by-Step Instructions** for coding agents
- **Validation Checklist** to verify changes

---

## 📋 **Checklist Format Template**

```markdown
# [Module Name] Feature Checklist
Source Document: [Document Name]
Analysis Date: [Date]
Total Features: [Count]

## Module Overview
[Brief description of module functionality]

## Feature Checklist

### Section: [Section Name] (Page X-Y)

#### Feature: [Feature Name]
- **Description**: [What it does]
- **Keywords**: `keyword1`, `keyword2`, `keyword3`
- **Priority**: High/Medium/Low
- **Doc Reference**: Page X, Line Y
- **BDD Coverage**: 
  - [ ] Not Checked
  - [ ] Missing
  - [ ] Partial (File: ___)
  - [ ] Complete (File: ___)
- **Notes**: [Any special considerations]

[Repeat for each feature...]

## Summary Statistics
- Total Features: [#]
- High Priority: [#]
- Medium Priority: [#]
- Low Priority: [#]
```

---

## 🔍 **Feature Extraction Guidelines**

### **What to Extract:**
1. **Functional Capabilities** - What the system does
2. **Business Rules** - How it behaves
3. **Configuration Options** - What can be customized
4. **Integration Points** - External connections
5. **Reports & Analytics** - Data outputs
6. **User Workflows** - Step-by-step processes

### **What to Skip:**
- UI layout details (unless functional)
- Color schemes and styling
- Generic navigation (unless unique)
- Standard CRUD operations (unless special)

### **Priority Levels:**
- **High**: Core business functionality, promised features
- **Medium**: Important but not critical
- **Low**: Nice-to-have, future enhancements

---

## 🏷️ **Keyword Tagging**

### **Purpose**: Enable efficient coverage checking

### **Good Keywords:**
- Specific feature names: `vacation-planning`, `service-level`
- Business terms: `forecast`, `schedule`, `shift`
- Russian terms: `отпуск`, `график`, `смена`
- Integration points: `1c-zup`, `oktell`, `okk`

### **Keyword Format:**
```
**Keywords**: `vacation`, `planning`, `auto-approval`, `отпуск`
```

---

## 📊 **Module Categories**

### **1. Forecasting (Прогнозирование)**
- Demand forecasting
- Trend analysis
- Absenteeism calculation
- Zero-history handling (1010 specific)

### **2. Scheduling (Планирование)**
- Work schedules
- Vacation planning ⚠️ MISSING
- Shift management
- Schema/patterns

### **3. Employees (Сотрудники)**
- Employee profiles
- Organizational structure
- Skills/qualifications
- Workload tracking

### **4. Integration (Интеграция)**
- 1C ZUP connection
- API framework
- OKK integration (1010)
- Web Statistics (1010)

### **5. Reporting (Отчетность)**
- Operational reports
- Analytics dashboards
- Real-time monitoring
- Custom reports

### **6. Administration (Администрирование)**
- System configuration
- User management
- Reference data
- Security settings

---

## 🚀 **Next Steps After Checklist Creation**

### **1. Coverage Verification**
```bash
# Use swarm agents with checklist keywords
For each checklist item:
- Search in /bdd-specifications/argus-replica/
- Search in /bdd-specifications/1010-custom/
- Mark coverage status
```

### **2. Gap Analysis**
```bash
# Create gap report
- List all MISSING items
- List all PARTIAL items
- Prioritize by importance
```

### **3. BDD Updates**
```bash
# For each gap:
- Determine target file
- Add missing scenarios
- Apply appropriate tags
```

---

## 📝 **File Naming Convention**

### **Individual Checklists:**
```
[priority]-[module]-[feature]-checklist.md

Examples:
01-forecasting-demand-planning-checklist.md
02-scheduling-vacation-planning-checklist.md
03-employees-skills-management-checklist.md
```

### **Module Summaries:**
```
[module]-SUMMARY-checklist.md

Examples:
forecasting-SUMMARY-checklist.md
scheduling-SUMMARY-checklist.md
```

---

## ⚠️ **Critical Missing Features**

Based on client feedback, prioritize finding:
1. **Vacation Planning Module** - Auto-suggestion features
2. **Service Level X/Y Format** - Not percentage
3. **50+ Schedule Patterns** - Russian-specific
4. **OKK Integration Details** - Quality system sync
5. **Calculated Metrics** - What Oktell doesn't provide

---

## 🎯 **Success Criteria**

### **Checklist Quality:**
- Every functional feature captured
- Clear keywords for searching
- Accurate priority assignment
- Proper module categorization

### **Coverage Goals:**
- 100% of documented features checked
- All gaps clearly identified
- Priority list for implementation
- Clear path to completion

---

## 📌 **Agent Prompts for Document Analysis**

### **Initial Analysis:**
```
Analyze [document_name] and extract all functional features.
Create a checklist following the template in CLAUDE.md.
Group by modules: Forecasting, Scheduling, Employees, Integration, Reporting, Admin.
Include keywords, page references, and priority levels.
```

### **Checklist Organization:**
```
Review all checklists in this folder.
Organize into module subfolders.
Create a MEGA-CHECKLIST.md combining all features.
Add summary statistics and gap analysis.
```

### **Coverage Check:**
```
Take [checklist_file] and check each feature against BDD specifications.
Search using the keywords provided.
Mark coverage as: Missing/Partial/Complete.
Note which BDD file contains the feature.
```

---

**Last Updated**: July 9, 2025
**Next Review**: After first document analysis