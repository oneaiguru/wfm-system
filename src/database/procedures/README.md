# Procedures

## Overview
SQL stored procedures and helper functions used by the application. They are
wrapped by Python utilities for ease of use.

## Features
- Parameterised SQL scripts
- Convenience wrappers for calling procedures
- Version controlled alongside the codebase

## Usage
Example of executing a procedure:
```python
from src.database.procedures import sync_work_time

await sync_work_time(start_date="2024-01-01", end_date="2024-01-31")
```

## Testing
```bash
pytest tests/procedures/
```

## Related Documentation
- [Database README](../README.md)
- [Architecture Docs](../../../docs/architecture/database.md)
