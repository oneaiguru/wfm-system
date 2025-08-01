# Endpoints

## Overview
FastAPI route functions for version 1 of the public API. Each file groups
endpoints by domain and uses services to perform business logic.

## Features
- Organized routing with dependency injection
- Automatic OpenAPI documentation
- Supports both REST and WebSocket handlers

## Usage
Run the API server and access the docs:
```bash
uvicorn src.api.main:app --reload
# Visit http://localhost:8000/docs
```

## Testing
```bash
pytest tests/api/endpoints/
```

## Related Documentation
- [API Reference](../../../docs/api/api_reference.md)
- [Services README](../services/README.md)
