# Working BDD Specifications - EDITABLE

## Purpose
This directory contains **editable copies** of the Argus BDD specifications that can be modified based on demo feedback and implementation improvements.

## Contents
- **32 BDD Feature Files**: Copied from argus-original/ for editing
- **Supporting Documentation**: Modifiable versions of API docs and guides
- **Implementation Notes**: Added during development

## Usage Guidelines
✅ **Edit freely** - These files are meant to be improved
✅ **Add demo feedback** - Update scenarios based on user testing  
✅ **Enhance requirements** - Improve clarity and implementation details
✅ **Add Russian localization** - Customize for Russian market needs

## Workflow
1. **Start with originals**: Files copied from `../argus-original/`
2. **Demo-driven improvements**: Update based on user feedback
3. **Implementation-driven changes**: Adjust based on technical constraints
4. **Document changes**: Use git commits to track improvements

## Comparison
To see what changed from originals:
```bash
diff -r ../argus-original/ . 
```

## Version Control
All changes are tracked in git to show evolution from original Argus specs to our improved implementation.

## Demo Integration
These specifications should align with:
- Our implemented UI components
- Our database schema (761 tables)
- Our API endpoints (147 real endpoints)
- Our algorithms (87 implemented)

The goal is specifications that are both **technically accurate** and **demo-ready**.