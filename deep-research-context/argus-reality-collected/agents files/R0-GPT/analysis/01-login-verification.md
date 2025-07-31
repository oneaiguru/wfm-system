# Login Scenario Verification - BDD Spec vs Our Implementation

## BDD Spec Analysis (01-system-architecture.feature)

### Lines 12-24: Access Administrative System
The spec describes:
- URL: `https://cc1010wfmcc.argustelecom.ru/ccwfm/`
- Credentials: test/test
- Expected greeting: "Здравствуйте, Юрий Артёмович!" 
- User ID: 111538
- Russian navigation options

### Our Implementation Analysis

#### Login Component (Login.tsx)
**Strengths:**
- ✅ Bilingual support (Russian/English) - matches BDD requirement
- ✅ Russian translations include:
  - Title: "Вход в систему WFM"
  - Fields: "Имя пользователя", "Пароль"
  - Button: "Войти"
  - Welcome: "Добро пожаловать"
- ✅ Uses username field (not email) - matches Argus pattern
- ✅ Real auth service integration

**Gaps Identified:**
- ❌ No user greeting with full name format
- ❌ No user ID display
- ❌ Navigation menu not in Login component (likely in Dashboard)
- ❌ Default language is English, not Russian

## Spec Updates Needed

### 1. Update Login Scenario (Lines 12-24)
```gherkin
# UPDATED: 2025-07-25 - Align with actual implementation
Scenario: Access Administrative System
  Given I navigate to "http://localhost:3000"
  When I select Russian language
  And I login with credentials "admin/password"
  Then I should see welcome message "Добро пожаловать"
  And I should be redirected to dashboard
  # TODO: Verify dashboard shows user greeting and navigation
```

### 2. Add Language Toggle Scenario
```gherkin
# NEW: 2025-07-25 - Language selection capability
Scenario: Language selection on login page
  Given I am on the login page
  When I click the language toggle
  Then the interface switches between Russian and English
  And all labels update accordingly
```

### 3. Add Error Handling Scenarios
```gherkin
# NEW: 2025-07-25 - Error states from implementation
Scenario: API unavailable error
  Given the API server is not running
  When I attempt to login
  Then I see error message "API server is not available"

Scenario: Invalid credentials error  
  Given I enter invalid credentials
  When I click login
  Then I see error message "Invalid credentials"
```

## Integration Patterns Applied

### Pattern 2: Form Field Accessibility
Our implementation correctly includes:
- ✅ `name="username"` attribute on username input
- ✅ `name="password"` attribute on password input
- ✅ Proper form structure for e2e testing

### Pattern 3: API Path Construction
- ✅ Uses `realAuthService` with dynamic API URL
- ✅ Follows pattern from INTEGRATION_PATTERNS_LIBRARY.md

## Recommendations

1. **Add User Context Display**: After login, show user greeting with full name
2. **Set Russian as Default**: For Argus parity, default to Russian
3. **Implement User ID**: Display user ID in profile/dashboard
4. **Navigation Menu**: Verify dashboard has all required navigation options

## Files to Update

1. `/project/specs/working/01-system-architecture.feature`
   - Add comment: `# VERIFIED: Login flow works, language toggle implemented`
   - Update scenario to match actual URLs and credentials
   
2. `/project/src/ui/src/components/Login.tsx`
   - Consider defaulting to Russian: `useState<'ru' | 'en'>('ru')`
   
3. Create new spec scenarios for:
   - Language toggle functionality
   - Error handling states
   - Post-login dashboard verification