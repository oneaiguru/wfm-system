# 🧪 Quick Test Check Template

**Purpose**: Simple reminder to test before claiming complete

## Before Saying "Done", Ask Yourself:

```markdown
## Quick Test Check
☐ What did I change? ________________
☐ How can I test it? ________________
☐ Did I run the test? YES / NO
☐ What happened? PASS / FAIL / ERROR

If NO → Stop and test now!
If FAIL → Fix it first!
If PASS → Share the command!
```

## Examples:

### Good:
"Added routing to App.tsx"
"Tested with: curl http://localhost:3000/new-route"
"Result: Component loads correctly ✅"

### Bad:
"Added routing to App.tsx"
"Should work" ❌

### Honest:
"Added routing to App.tsx"
"Haven't tested yet, will test now..."
[Actually tests]
"Update: Route works! curl shows component"

## Remember: We ALL Forget!
- U forgot to test routing
- A forgot to test before claiming complete
- I claimed SSO worked without testing

**Just run ONE test command before claiming done!**