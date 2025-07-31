# 📋 Batch Assignment Template V2 - With Integrated V-Stage

**Purpose**: Standard template including V-stage requirements upfront (fixing the gap)

## 🚀 BATCH ASSIGNMENT - [Agent Name]

**Batch ID**: [Batch Number]  
**SPECs**: [Range, e.g., 073-090]  
**Domain**: [e.g., Reporting, Analytics]

## 📊 STAGE REQUIREMENTS

### **Investigation First** (Mandatory)
- Apply discovery paradigm to all SPECs
- Document reuse percentages

### **Implementation Stages**
- **B**: Define scenarios and requirements
- **D**: Create/verify database schemas  
- **I**: Build/adapt API endpoints
- **U**: Implement/reuse UI components
- **A**: Deploy/verify algorithms

### **V-Stage Requirements** (NEW - Built-in from start)
```yaml
For each SPEC:
  Test Commands:
    - UI: npm test [spec-component]
    - API: curl [endpoint] with real data
    - DB: SELECT queries showing data flow
    - E2E: Full journey test script
  
  Expected Results:
    - Response time: <100ms
    - Data accuracy: Real, not mocked
    - Integration: All layers connected
    
  Pass Criteria:
    - All test commands execute successfully
    - Performance targets met
    - No mock data in production paths
```

## 🎯 SUCCESS METRICS
- Investigation saves 70%+ development time
- V-stage passes on first attempt
- Zero rework from missing requirements

## 📅 TIMELINE
- Full batch: ~2 weeks
- Report only blockers or completion

---

**This template ensures V-stage is never an afterthought**