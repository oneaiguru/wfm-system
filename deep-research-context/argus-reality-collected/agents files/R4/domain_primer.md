# R4-IntegrationGateway Domain Primer

## 🎯 Your Domain: Cross-System Integration
- **Scenarios**: 128 total (4 demo-critical)
- **Features**: External sync, Zup integration, end-to-end flows

## 📊 Domain-Specific Details

### Primary Components
- `ExternalSyncService.tsx` - Sync management
- `ZupIntegrationAdapter.tsx` - Zup connector
- `IntegrationMonitor.tsx` - Status tracking
- `DataMapper.tsx` - Format conversions

### Primary APIs
- `/api/v1/zup/*`
- `/api/v1/external/sync`
- `/api/v1/integration/status`
- `/api/v1/webhooks/*`

### Expected New Patterns
- **Pattern 9**: Multi-system transactions
- **Pattern 10**: Data consistency
- Webhook handling
- Async acknowledgments

### Quick Wins (Start Here)
- SPEC-22-001: Check integration status
- SPEC-22-002: Manual sync trigger
- SPEC-03-020: End-to-end flow test

## 🔄 Dependencies
- **Depends on**: All domains (integrates everything)
- **Most complex coordination**

## 💡 Domain Tips
1. End-to-end tests are your specialty
2. Use fixtures for external systems
3. Document any new integration patterns
4. Timing/async handling critical