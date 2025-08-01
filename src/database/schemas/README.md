# Schemas

## Overview
Pydantic models describing the data structures stored in the database and
exchanged by the API.

## Features
- Typed request and response models
- Reuse across API and services
- Validation of incoming data

## Usage
Example schema definition:
```python
from pydantic import BaseModel

class EmployeeCreate(BaseModel):
    name: str
    role: str
```

## Testing
```bash
pytest tests/schemas/
```

## Related Documentation
- [Database README](../README.md)
- [API Reference](../../../docs/api/api_reference.md)
