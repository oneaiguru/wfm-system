# Coverage Reports - CLAUDE.md
Agent Instructions for Parallel BDD Coverage Verification

## 🎯 **Mission**
Systematically verify BDD coverage for all ARGUS WFM checklist files and create implementation guides for coding agents.

---

## 📁 **Directory Structure**
```
coverage-reports/
├── CLAUDE.md                                    # This file - Agent instructions
├── _TEMPLATE-COVERAGE.md                        # Coverage analysis template
├── _TEMPLATE-IMPROVEMENTS.md                    # Missing scenarios template  
├── _TEMPLATE-DIFF.md                           # Implementation guide template
├── 1c-integration-COVERAGE.md                  # ✅ COMPLETED - Example
├── 1c-integration-IMPROVEMENTS.md              # ✅ COMPLETED - Example
├── 1c-integration-DIFF.md                      # ✅ COMPLETED - Example
└── [AGENT OUTPUTS - TO BE CREATED]
    ├── database-structure-COVERAGE.md          # 🔄 ASSIGNED: Agent-DB
    ├── database-structure-IMPROVEMENTS.md      # 🔄 ASSIGNED: Agent-DB
    ├── database-structure-DIFF.md              # 🔄 ASSIGNED: Agent-DB
    ├── rest-api-integration-COVERAGE.md        # 🔄 ASSIGNED: Agent-API
    ├── rest-api-integration-IMPROVEMENTS.md    # 🔄 ASSIGNED: Agent-API
    ├── rest-api-integration-DIFF.md            # 🔄 ASSIGNED: Agent-API
    ├── planning-workflows-COVERAGE.md          # 🔄 ASSIGNED: Agent-PLAN
    ├── planning-workflows-IMPROVEMENTS.md      # 🔄 ASSIGNED: Agent-PLAN
    ├── planning-workflows-DIFF.md              # 🔄 ASSIGNED: Agent-PLAN
    ├── admin-guide-COVERAGE.md                 # 🔄 ASSIGNED: Agent-ADMIN
    ├── admin-guide-IMPROVEMENTS.md             # 🔄 ASSIGNED: Agent-ADMIN
    ├── admin-guide-DIFF.md                     # 🔄 ASSIGNED: Agent-ADMIN
    ├── manual-part1-COVERAGE.md                # 🔄 ASSIGNED: Agent-MANUAL1
    ├── manual-part1-IMPROVEMENTS.md            # 🔄 ASSIGNED: Agent-MANUAL1
    ├── manual-part1-DIFF.md                    # 🔄 ASSIGNED: Agent-MANUAL1
    ├── manual-part2-COVERAGE.md                # 🔄 ASSIGNED: Agent-MANUAL2
    ├── manual-part2-IMPROVEMENTS.md            # 🔄 ASSIGNED: Agent-MANUAL2
    └── manual-part2-DIFF.md                    # 🔄 ASSIGNED: Agent-MANUAL2
```

---

## 🤖 **Agent Assignment Matrix**

### **Agent-DB: Database Structure**
**Checklist File**: `../database-structure-checklist.md`
**Output Files**: 
- `database-structure-COVERAGE.md`
- `database-structure-IMPROVEMENTS.md` 
- `database-structure-DIFF.md`
**Primary BDD Files to Search**: 
- `../01-system-architecture.feature`
- `../18-system-administration-configuration.feature`
- `../17-reference-data-management-configuration.feature`

### **Agent-API: REST API Integration**  
**Checklist File**: `../rest-api-integration-checklist.md`
**Output Files**:
- `rest-api-integration-COVERAGE.md`
- `rest-api-integration-IMPROVEMENTS.md`
- `rest-api-integration-DIFF.md`
**Primary BDD Files to Search**:
- `../11-system-integration-api-management.feature`
- `../22-cross-system-integration.feature`
- `../21-1c-zup-integration.feature`

### **Agent-PLAN: Planning Workflows**
**Checklist File**: `../planning-workflows-checklist.md`
**Output Files**:
- `planning-workflows-COVERAGE.md`
- `planning-workflows-IMPROVEMENTS.md`
- `planning-workflows-DIFF.md`
**Primary BDD Files to Search**:
- `../08-load-forecasting-demand-planning.feature`
- `../09-work-schedule-vacation-planning.feature`
- `../10-monthly-intraday-activity-planning.feature`
- `../19-planning-module-detailed-workflows.feature`

### **Agent-ADMIN: Administration Guide**
**Checklist File**: `../admin-guide-checklist.md`
**Output Files**:
- `admin-guide-COVERAGE.md`
- `admin-guide-IMPROVEMENTS.md`
- `admin-guide-DIFF.md`
**Primary BDD Files to Search**:
- `../18-system-administration-configuration.feature`
- `../17-reference-data-management-configuration.feature`
- `../16-personnel-management-organizational-structure.feature`

### **Agent-MANUAL1: Manual Part 1 (Core Features)**
**Checklist Files**: 
- `../manual-part1-checklist.md`
- `../manual-part1-checklist-cont1.md`
- `../manual-part1-checklist-cont2.md`
- `../manual-part1-checklist-cont3.md`
**Output Files**:
- `manual-part1-COVERAGE.md`
- `manual-part1-IMPROVEMENTS.md`
- `manual-part1-DIFF.md`
**Primary BDD Files to Search**: All files (comprehensive manual)

### **Agent-MANUAL2: Manual Part 2 (Extended Features)**
**Checklist Files**:
- `../manual-part2-checklist.md`
- `../manual-part2-checklist-cont1.md`
- `../manual-part2-checklist-cont2.md`
- `../manual-part2-checklist-cont3.md`
**Output Files**:
- `manual-part2-COVERAGE.md`
- `manual-part2-IMPROVEMENTS.md`
- `manual-part2-DIFF.md`
**Primary BDD Files to Search**: All files (comprehensive manual)

---

## 📋 **Step-by-Step Agent Process**

### **Step 1: Read Your Assignment**
```bash
# Each agent reads their assigned checklist file(s)
# Example for Agent-DB:
cat ../database-structure-checklist.md

# Extract all features with keywords and priorities
# Note line numbers and feature descriptions
```

### **Step 2: Search BDD Coverage**
```bash
# Search assigned BDD files for coverage
# Use keywords from checklist features
# Example search commands:
grep -r "database\|storage\|schema" ../*.feature
grep -r "table\|column\|index" ../*.feature

# For each feature, determine:
# ✅ Complete - Fully covered with scenarios
# ⚠️ Partial - Basic mention, needs enhancement  
# ❌ Missing - No coverage found
```

### **Step 3: Create Coverage Report**
Use template: `_TEMPLATE-COVERAGE.md`
- Copy template and rename to your output file
- Fill in all sections with your findings
- Include exact BDD file locations and line numbers
- Calculate coverage percentages

### **Step 4: Create Improvements Specification**
Use template: `_TEMPLATE-IMPROVEMENTS.md`
- Document BEFORE state (current gaps)
- Design AFTER state (complete BDD scenarios)
- Include full Gherkin syntax for new scenarios
- Specify business logic and validation requirements

### **Step 5: Create Implementation Diff**
Use template: `_TEMPLATE-DIFF.md`
- Provide exact file modification instructions
- Include line numbers for insertions
- Use proper diff format with + additions
- Add validation checklist

---

## 🔍 **BDD Search Strategy**

### **Search Locations:**
```
../                                    # Main BDD directory
├── *.feature                         # Root level files (01-20)
├── argus-replica/*.feature           # Replica specifications  
└── 1010-custom/*.feature            # Custom implementations
```

### **Search Keywords by Category:**

#### **Database/Storage:**
- `database`, `table`, `schema`, `column`, `index`, `storage`, `data structure`
- `PostgreSQL`, `query`, `performance`, `backup`, `migration`

#### **API/Integration:**  
- `REST`, `API`, `endpoint`, `HTTP`, `JSON`, `integration`, `service`
- `authentication`, `authorization`, `error handling`, `response`

#### **Planning/Scheduling:**
- `schedule`, `planning`, `forecast`, `shift`, `vacation`, `workload`
- `calendar`, `template`, `optimization`, `resource`, `capacity`

#### **Administration:**
- `admin`, `configuration`, `settings`, `user management`, `permissions`
- `roles`, `access control`, `system setup`, `reference data`

#### **Employee Management:**
- `employee`, `personnel`, `operator`, `staff`, `department`, `position`
- `skills`, `groups`, `time tracking`, `attendance`, `performance`

---

## 📊 **Coverage Analysis Guidelines**

### **Coverage Classifications:**

#### **✅ Complete Coverage:**
- Feature has dedicated BDD scenario(s)
- All business rules documented
- Error handling included
- Data validation specified
- Examples and edge cases covered

#### **⚠️ Partial Coverage:**
- Feature mentioned in BDD but incomplete
- Missing business rules or validation
- No error handling scenarios
- Limited examples or edge cases

#### **❌ Missing Coverage:**
- No BDD scenarios found for feature
- No mention in any BDD file
- Critical gap in specifications

### **Priority Classification:**
- **Critical**: Core business functionality, must-have features
- **High**: Important functionality, significant impact
- **Medium**: Useful functionality, moderate impact  
- **Low**: Nice-to-have, minimal impact

---

## 📝 **Output Quality Standards**

### **Coverage Report Requirements:**
- [ ] All checklist features analyzed
- [ ] Coverage percentages calculated
- [ ] Exact BDD file references with line numbers
- [ ] Clear gap identification
- [ ] Priority-ranked missing features list
- [ ] Specific recommendations

### **Improvements Specification Requirements:**
- [ ] Clear BEFORE/AFTER documentation
- [ ] Complete Gherkin scenarios for missing features
- [ ] Proper BDD syntax and formatting
- [ ] Business logic and validation rules
- [ ] Russian terminology where appropriate

### **Implementation Diff Requirements:**
- [ ] Exact line numbers for insertions
- [ ] Proper diff format with + additions
- [ ] Complete scenarios ready for copy-paste
- [ ] Validation checklist included
- [ ] File backup instructions

---

## 🎯 **Success Criteria**

### **For Each Agent:**
- [ ] 3 output files created (COVERAGE, IMPROVEMENTS, DIFF)
- [ ] All assigned checklist features analyzed
- [ ] Coverage percentage >= 85% OR clear implementation plan
- [ ] Missing features have complete BDD scenarios ready
- [ ] Implementation guide ready for coding agents

### **Overall Project:**
- [ ] All 13 checklist files verified
- [ ] Complete BDD coverage analysis for ARGUS WFM
- [ ] Implementation roadmap for 98%+ coverage
- [ ] Parallel execution completed efficiently

---

## 🔧 **Tools and Commands**

### **File Analysis:**
```bash
# Count features in checklist
grep -c "Feature:" ../[checklist-file].md

# Extract keywords
grep "Keywords:" ../[checklist-file].md

# Check file sizes for progress tracking
ls -la ../*.md | sort -k5 -n
```

### **BDD Search:**
```bash
# Search all BDD files
grep -r "keyword" ../*.feature

# Search specific directories
grep -r "keyword" ../argus-replica/*.feature
grep -r "keyword" ../1010-custom/*.feature

# Search with context
grep -A5 -B5 "keyword" ../*.feature
```

### **Coverage Calculation:**
```bash
# Count total features
TOTAL=$(grep -c "Feature:" ../[checklist].md)

# Count covered features (from your analysis)
COVERED=[your-count]

# Calculate percentage
echo "scale=1; $COVERED * 100 / $TOTAL" | bc
```

---

## 📚 **Reference Materials**

### **Study These Examples:**
1. **1c-integration-COVERAGE.md** - Perfect coverage analysis format
2. **1c-integration-IMPROVEMENTS.md** - Complete improvement specifications
3. **1c-integration-DIFF.md** - Exact implementation instructions

### **BDD Standards:**
- Proper Gherkin syntax (Given/When/Then)
- Russian terminology preservation
- Data tables with pipes (|)
- Appropriate tags (@tag1 @tag2)
- Business context in comments

### **Documentation Sources:**
```
../../../docs-consolidated/База знаний WFM CC/Документация/
├── Source documents for each checklist
├── Original Russian documentation  
└── English translations used for checklists
```

---

## ⚡ **Parallel Execution Coordination**

### **Agent Independence:**
- Each agent works on separate checklist files
- No file conflicts or dependencies
- Independent output directories
- Self-contained analysis process

### **Progress Tracking:**
- Agents update their assignment status
- File creation indicates progress
- Coverage percentages show completion
- Final validation confirms quality

### **Coordination Points:**
1. **Startup**: Each agent confirms assignment
2. **Midpoint**: Progress check and coordination
3. **Completion**: Quality validation and integration

This structure enables efficient parallel processing while maintaining quality and consistency across all coverage verifications.