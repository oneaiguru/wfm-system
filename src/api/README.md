# WFM Enterprise Integration API

FastAPI-based integration layer for WFM Enterprise system.

## Architecture

- **FastAPI** - High-performance async web framework
- **PostgreSQL** - Primary data storage with time-series optimizations
- **Redis** - Caching layer for sub-second response times
- **Prometheus** - Performance monitoring and metrics

## Quick Start

1. Install dependencies:
```bash
pip install -r requirements.txt
```

2. Run with Docker:
```bash
docker-compose up -d
```

3. Access API documentation:
- http://localhost:8000/docs - Swagger UI
- http://localhost:8000/redoc - ReDoc

## API Endpoints

### Personnel Integration
- `GET /api/v1/personnel` - Retrieve organizational structure

### Historical Data
- `GET /api/v1/historic/serviceGroupData` - Service group metrics
- `GET /api/v1/historic/agentStatusData` - Agent status history
- `GET /api/v1/historic/agentLoginData` - Login/session data
- `GET /api/v1/historic/agentCallsData` - Call performance data
- `GET /api/v1/historic/agentChatsWorkTime` - Chat work time

### Real-Time Data
- `GET /api/v1/online/agentStatus` - Current agent status
- `GET /api/v1/online/groupsOnlineLoad` - Live group metrics
- `POST /api/v1/ccwfm/api/rest/status` - Status updates (fire-and-forget)

### Algorithm Services
- `POST /api/v1/algorithm/erlang-c` - Erlang C calculations
- `POST /api/v1/algorithm/forecast` - ML-based forecasting
- `POST /api/v1/algorithm/optimize-schedule` - Schedule optimization

## Performance Targets

- Response time: <2 seconds average
- API throughput: 1000+ requests/minute
- Cache hit ratio: 80%+
- Uptime: 99.9%

## Development

Run locally with auto-reload:
```bash
uvicorn app.main:app --reload
```

Run tests:
```bash
pytest tests/ -v --cov=app
```