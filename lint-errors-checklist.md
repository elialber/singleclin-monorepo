# Lint Errors Checklist

## Summary
- **Original Problems**: 334 (188 errors, 146 warnings)
- **Current Problems**: 313 (172 errors, 141 warnings)
- **Fixed So Far**: 21 problems (16 errors, 5 warnings)
- **Backend Package**: ✅ Lint script added
- **Web Admin Package**: Errors listed below (progress shown with checkmarks)

## Backend Package
- [x] **packages/backend/package.json**: Missing lint script

## Web Admin Package Errors

### ClinicFormDialog.tsx
- [x] **Line 204:26**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [x] **Line 232:26**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [x] **Line 245:49**: Unnecessary escape character: \- (no-useless-escape)
- [x] **Line 248:34**: Unnecessary escape character: \( (no-useless-escape)
- [x] **Line 248:36**: Unnecessary escape character: \) (no-useless-escape)

### GoogleLoginButton.tsx
- [x] **Line 29:19**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)

### MobileTestComponent.tsx
- [x] **Line 29:5**: 'isDesktop' is assigned a value but never used (@typescript-eslint/no-unused-vars)

### PatientFormDialog.tsx
- [x] **Line 26:15**: 'BusinessIcon' is defined but never used (@typescript-eslint/no-unused-vars)
- [x] **Line 212:26**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [x] **Line 232:26**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [x] **Line 372:41**: Unnecessary escape character: \( (no-useless-escape)
- [x] **Line 372:43**: Unnecessary escape character: \) (no-useless-escape)
- [x] **Line 372:45**: Unnecessary escape character: \. (no-useless-escape)

### PlanFormDialog.tsx
- [ ] **Line 155:26**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 176:26**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)

### TransactionErrorBoundary.tsx
- [ ] **Line 23:10**: 'TransactionErrorHandler' is defined but never used (@typescript-eslint/no-unused-vars)

### ImageCarousel.tsx
- [ ] **Line 11:3**: 'Button' is defined but never used (@typescript-eslint/no-unused-vars)

### ClinicStepper.test.tsx
- [ ] **Line 2:26**: 'fireEvent' is defined but never used (@typescript-eslint/no-unused-vars)
- [ ] **Line 209:11**: 'user' is assigned a value but never used (@typescript-eslint/no-unused-vars)

### performance.test.ts
- [ ] **Line 2:22**: 'render' is defined but never used (@typescript-eslint/no-unused-vars)
- [ ] **Line 19:59**: 'callback' is defined but never used. Allowed unused args must match /^_/u (@typescript-eslint/no-unused-vars)
- [ ] **Line 85:25**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 86:26**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 112:25**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 113:26**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 160:13**: 'throttledFn' is assigned a value but never used (@typescript-eslint/no-unused-vars)
- [ ] **Line 161:13**: 'debouncedFn' is assigned a value but never used (@typescript-eslint/no-unused-vars)
- [ ] **Line 250:25**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 251:26**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 277:25**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 278:26**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)

### api/authApi.ts
- [ ] **Line 52:17**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 53:18**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 90:17**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 91:18**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)

### api/clinicApi.ts
- [ ] **Line 43:17**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 44:18**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 81:17**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 82:18**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 119:17**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 120:18**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 154:17**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 155:18**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 189:17**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 190:18**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 224:17**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 225:18**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)

### api/dashboardApi.ts
- [ ] **Line 20:17**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 21:18**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)

### api/patientApi.ts
- [ ] **Line 43:17**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 44:18**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 81:17**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 82:18**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 119:17**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 120:18**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 154:17**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 155:18**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)

### api/planApi.ts
- [ ] **Line 43:17**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 44:18**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 81:17**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 82:18**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 119:17**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 120:18**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 154:17**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 155:18**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)

### api/transactionApi.ts
- [ ] **Line 44:17**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 45:18**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 82:17**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 83:18**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 120:17**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 121:18**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 155:17**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 156:18**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 190:17**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 191:18**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)

### auth/AuthContext.tsx
- [ ] **Line 18:3**: 'role' is defined but never used (@typescript-eslint/no-unused-vars)
- [ ] **Line 19:3**: 'permissions' is defined but never used (@typescript-eslint/no-unused-vars)

### auth/firebase.ts
- [ ] **Line 86:37**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)

### auth/protectedRoutes.tsx
- [ ] **Line 28:13**: 'hasAccess' is assigned a value but never used (@typescript-eslint/no-unused-vars)

### hooks/useAuth.ts
- [ ] **Line 110:17**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)

### hooks/useAuthState.ts
- [ ] **Line 91:40**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)

### hooks/useClinics.ts
- [ ] **Line 58:17**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 87:17**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 118:17**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 147:17**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)

### hooks/useDashboard.ts
- [ ] **Line 30:17**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)

### hooks/usePatients.ts
- [ ] **Line 58:17**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 87:17**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 118:17**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 147:17**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)

### hooks/usePlans.ts
- [ ] **Line 58:17**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 87:17**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 118:17**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 147:17**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)

### hooks/useTransactions.ts
- [ ] **Line 58:17**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 87:17**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 118:17**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 147:17**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 176:17**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)

### pages/AuthPage.tsx
- [ ] **Line 1:10**: 'React' is defined but never used (@typescript-eslint/no-unused-vars)

### pages/ClinicsPage.tsx
- [ ] **Line 9:3**: 'Delete' is defined but never used (@typescript-eslint/no-unused-vars)
- [ ] **Line 31:21**: 'setClinics' is assigned a value but never used (@typescript-eslint/no-unused-vars)

### pages/Dashboard.tsx
- [ ] **Line 5:3**: 'Typography' is defined but never used (@typescript-eslint/no-unused-vars)

### pages/PatientsPage.tsx
- [ ] **Line 29:20**: 'setPatients' is assigned a value but never used (@typescript-eslint/no-unused-vars)

### pages/PlansPage.tsx
- [ ] **Line 29:17**: 'setPlans' is assigned a value but never used (@typescript-eslint/no-unused-vars)

### pages/TransactionsPage.tsx
- [ ] **Line 6:3**: 'Delete' is defined but never used (@typescript-eslint/no-unused-vars)
- [ ] **Line 34:25**: 'setTransactions' is assigned a value but never used (@typescript-eslint/no-unused-vars)

### services/authService.ts
- [ ] **Line 20:17**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 45:17**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 70:17**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)

### services/notificationService.ts
- [ ] **Line 106:25**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)

### types/auth.ts
- [ ] **Line 15:3**: 'permissions' is defined but never used (@typescript-eslint/no-unused-vars)

### utils/errorHandler.ts
- [ ] **Line 11:44**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 50:42**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 59:45**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 68:40**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 77:40**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)

### utils/imageValidation.ts
- [ ] **Line 385:11**: 'length' is assigned a value but never used (@typescript-eslint/no-unused-vars)

### utils/maps.ts
- [ ] **Line 117:36**: 'reject' is defined but never used. Allowed unused args must match /^_/u (@typescript-eslint/no-unused-vars)
- [ ] **Line 155:36**: 'reject' is defined but never used. Allowed unused args must match /^_/u (@typescript-eslint/no-unused-vars)
- [ ] **Line 293:17**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 294:25**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)

### utils/transactionErrorHandler.ts
- [ ] **Line 1:10**: 'AxiosError' is defined but never used (@typescript-eslint/no-unused-vars)
- [ ] **Line 142:24**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 213:41**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 213:87**: 'context' is defined but never used. Allowed unused args must match /^_/u (@typescript-eslint/no-unused-vars)
- [ ] **Line 251:39**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 297:40**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 305:29**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 313:30**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 325:51**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 328:52**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 331:47**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)

### utils/uploadService.ts
- [ ] **Line 375:51**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)

### utils/validation.ts
- [x] **Line 8:28**: Unnecessary escape character: \. (no-useless-escape)
- [x] **Line 14:47**: Unnecessary escape character: \- (no-useless-escape)
- [x] **Line 20:40**: Unnecessary escape character: \- (no-useless-escape)
- [x] **Line 26:25**: Unnecessary escape character: \- (no-useless-escape)
- [ ] **Line 206:39**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [x] **Line 231:3**: 'excludeId' is defined but never used. Allowed unused args must match /^_/u (@typescript-eslint/no-unused-vars)
- [x] **Line 254:3**: 'excludeId' is defined but never used. Allowed unused args must match /^_/u (@typescript-eslint/no-unused-vars)
- [ ] **Line 309:46**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)
- [ ] **Line 309:56**: Unexpected any. Specify a different type (@typescript-eslint/no-explicit-any)

## Quick Fix Commands

Some errors can be automatically fixed with:
```bash
npm run lint --workspace=@singleclin/web-admin -- --fix
```

## Error Categories

### Most Common Issues:
1. **Unexpected any types** (146 warnings): Replace `any` with proper TypeScript types
2. **Unused variables/imports** (42+ errors): Remove unused code or prefix with underscore
3. **Unnecessary escape characters** (10+ errors): Remove backslashes in regex patterns

### Priorities:
1. Fix unused imports and variables (quick wins)
2. Add lint script to backend package
3. Replace `any` types with proper types
4. Fix regex escape characters