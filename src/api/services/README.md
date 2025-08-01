# Services

## Overview
Business logic layer used by the FastAPI endpoints. Services coordinate database
access and algorithm execution so handlers remain thin.

## Features
- Asynchronous database operations via SQLAlchemy
- Input validation with Pydantic models
- Integration with the algorithm modules

## Usage
Example of calling a service from an endpoint:
```python
from src.api.services.schedule_service import create_schedule

schedule = await create_schedule(request_data)
```

## Testing
```bash
pytest tests/api/services/
```

## Related Documentation
- [API README](../README.md)
- [Project README](../../README.md)
