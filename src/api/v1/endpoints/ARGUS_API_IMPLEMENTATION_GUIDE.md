# Argus API Replication and Comparison Framework - Implementation Guide

## Overview

This document provides a comprehensive guide to the enhanced Argus API implementation, featuring three major components:

1. **Historic Data Endpoints Enhancement** (`argus_historic_enhanced.py`)
2. **Real-time/Online Endpoints Enhancement** (`argus_realtime_enhanced.py`)
3. **Comparison Framework Implementation** (`comparison.py`)

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    WFM Enterprise API Layer                  │
├─────────────────┬───────────────────┬───────────────────────┤
│  Historic Data  │  Real-time Data   │  Comparison Framework │
│   (Enhanced)    │  (WebSocket/REST) │   (Superiority Demo)  │
├─────────────────┼───────────────────┼───────────────────────┤
│ • BDD Compliant │ • <500ms Response │ • 85% vs 70% Accuracy│
│ • Bulk Upload   │ • WebSocket Push  │ • 10x Speed Improve   │
│ • Data Valid.   │ • Connection Pool │ • Visual Dashboards   │
└─────────────────┴───────────────────┴───────────────────────┘
```

## 1. Historic Data Endpoints Enhancement

### Features
- **Full BDD Compliance**: Exact request/response structures matching Argus API specifications
- **Bulk Data Operations**: High-performance bulk upload capabilities
- **Enhanced Error Handling**: Comprehensive 400/404/500 status codes with detailed error messages
- **Data Validation**: Business rule enforcement per BDD specifications

### Key Endpoints

#### GET /api/v1/historic/serviceGroupData
Retrieves historical metrics by service groups with interval-based data.

**Request Parameters:**
- `startDate` (ISO 8601 with timezone): Start of analysis period
- `endDate` (ISO 8601 with timezone): End of analysis period  
- `step` (milliseconds): Time interval (minimum 60000ms/1 minute)
- `groupId` (comma-separated): Group identifiers

**Response Structure:**
```json
[
  {
    "serviceId": "1",
    "groupId": "1",
    "historicData": [
      {
        "startInterval": "2024-01-01T09:00:00Z",
        "endInterval": "2024-01-01T09:15:00Z",
        "notUniqueReceived": 45,
        "notUniqueTreated": 42,
        "notUniqueMissed": 3,
        "receivedCalls": 38,
        "treatedCalls": 36,
        "missCalls": 2,
        "aht": 180000,
        "postProcessing": 30000
      }
    ]
  }
]
```

#### POST /api/v1/historic/bulk-upload
Enables bulk upload of historic data with validation and conflict resolution.

**Request Body:**
```json
{
  "dataType": "serviceGroup",
  "startDate": "2024-01-01T00:00:00Z",
  "endDate": "2024-01-01T23:59:59Z",
  "overwriteExisting": false,
  "data": [...]
}
```

### Business Rules Implementation
- **Uniqueness Calculation**: Customer/device identifier within day determines unique contacts
- **AHT Formula**: Total handle time / non-unique processed contacts
- **Contact Classification**: Based on start time for interval assignment
- **Exclusions**: Bot-closed chats, system-generated contacts, test data

## 2. Real-time/Online Endpoints Enhancement

### Performance Features
- **Sub-500ms Response Time**: Optimized for real-time operations
- **WebSocket Support**: Streaming updates for agent status and queue metrics
- **Connection Pooling**: Handles high-throughput scenarios
- **Fire-and-Forget Pattern**: Status updates processed asynchronously

### Key Endpoints

#### POST /api/v1/ccwfm/api/rest/status
Real-time agent status transmission using fire-and-forget pattern.

**Request Body:**
```json
{
  "workerId": "101",
  "stateName": "Technical Break",
  "stateCode": "BREAK_TECH",
  "systemId": "External system",
  "actionTime": 1704110400,
  "action": 1
}
```

#### WebSocket /api/v1/ws/agent-status/{agent_id}
Real-time agent status streaming with automatic updates.

**Connection Protocol:**
1. Connect to WebSocket endpoint
2. Receive initial status
3. Get real-time updates on state changes
4. Heartbeat every 30 seconds

#### GET /api/v1/online/groupsOnlineLoad
Current group metrics with real-time queue statistics.

**Update Frequencies:**
- Queue metrics: Real-time
- Agent counts: Real-time
- Daily totals: Hourly
- AHT: Every 5 minutes

### Performance Optimizations
- **Caching**: 5-10 second cache for frequently accessed data
- **Async Processing**: Non-blocking status updates
- **Batch Updates**: Support for multiple status updates in single request
- **Connection Management**: Automatic cleanup of dead WebSocket connections

## 3. Comparison Framework

### Superiority Demonstrations

#### Accuracy Comparison (85% vs 70%)
**POST /api/v1/comparison/accuracy**

Demonstrates WFM Enterprise's superior accuracy through:
- Enhanced Erlang C with real-world adjustments
- ML-based corrections
- Dynamic parameter tuning

**Visualization Output:**
```json
{
  "chartType": "accuracy_comparison",
  "overallComparison": {
    "wfm": 85.2,
    "argus": 71.5,
    "improvement": 13.7
  }
}
```

#### Performance Comparison (<10ms vs 100ms+)
**POST /api/v1/comparison/performance**

Shows 10x+ speed improvements through:
- Optimized algorithms with caching
- Parallel processing
- Pre-computed lookup tables

**Visualization Output:**
```json
{
  "speedometer": {
    "wfmSpeed": 115.2,
    "argusSpeed": 10.5,
    "improvement": "11x faster"
  }
}
```

#### Comprehensive Benchmarking
**POST /api/v1/comparison/benchmark**

Runs complete test suites including:
- Multiple algorithms
- Various data sizes
- Accuracy and performance tests
- Executive summary generation

### Visualization Support

All comparison endpoints provide UI-ready visualization data:
- **Radar Charts**: Multi-metric comparisons
- **Bar Charts**: Side-by-side metrics
- **Speedometer**: Performance indicators
- **Time Series**: Historical trends
- **Dashboards**: Executive summaries

## Testing with Sample Data

Sample test data is provided in `/tests/sample_data/`:
- `argus_historic_test_data.json`: Historic endpoint test cases
- `argus_realtime_test_data.json`: Real-time endpoint test cases
- `comparison_test_data.json`: Comparison framework test scenarios

### Running Tests

```bash
# Test historic endpoints
curl -X GET "http://localhost:8000/api/v1/historic/serviceGroupData?startDate=2024-01-01T00:00:00Z&endDate=2024-01-01T23:59:59Z&step=900000&groupId=1,2"

# Test real-time status update
curl -X POST "http://localhost:8000/api/v1/ccwfm/api/rest/status" \
  -H "Content-Type: application/json" \
  -d '{"workerId":"101","stateName":"Available","stateCode":"AVAILABLE","systemId":"External system","actionTime":1704110400,"action":1}'

# Test accuracy comparison
curl -X POST "http://localhost:8000/api/v1/comparison/accuracy" \
  -H "Content-Type: application/json" \
  -d @tests/sample_data/comparison_test_data.json
```

## Error Handling

All endpoints implement comprehensive error handling:

### HTTP Status Codes
- **200**: Successful operation with data
- **201**: Resource created successfully
- **204**: No content (fire-and-forget operations)
- **400**: Bad request with validation details
- **404**: No data found for parameters
- **500**: Server error with detailed message

### Error Response Format
```json
{
  "detail": {
    "field": "startDate",
    "message": "Invalid date format",
    "description": "Date must be ISO 8601 format with timezone"
  }
}
```

## Performance Monitoring

Built-in performance tracking provides:
- Average response times
- Request throughput
- Active connections
- Performance warnings (>500ms)

Access metrics via: `GET /api/v1/online/performance-metrics`

## Integration Notes

### Database Requirements
- AsyncSession support for high concurrency
- Connection pooling configured
- Optimized indexes for time-series queries

### Service Layer Integration
- `HistoricService`: Enhanced with bulk operations
- `OnlineService`: Real-time data handling
- `AlgorithmService`: Comparison calculations

### Middleware Requirements
- `monitor_endpoint_performance`: Performance tracking
- `cache_decorator`: Response caching
- Error handling middleware

## Deployment Considerations

1. **Connection Pool Size**: Adjust based on expected load
2. **WebSocket Scaling**: Consider Redis for multi-instance deployments
3. **Cache Configuration**: Tune expiration times based on data volatility
4. **Performance Thresholds**: Monitor and adjust 500ms warning threshold

## Future Enhancements

1. **GraphQL Support**: Alternative query interface
2. **gRPC Integration**: High-performance binary protocol
3. **Event Sourcing**: Complete audit trail
4. **Multi-tenant Support**: Isolated data per client
5. **Advanced Analytics**: Predictive insights API