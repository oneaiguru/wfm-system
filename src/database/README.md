# Database

## Overview
Database access layer built with SQLAlchemy. It defines ORM models,
initialization helpers and migration scripts for PostgreSQL.

## Features
- Centralised session handling
- Alembic migrations for schema changes
- Utility functions for common queries

## Usage
Create a session and query models:
```python
from src.database.session import SessionLocal
from src.database import models

with SessionLocal() as session:
    users = session.query(models.Employee).all()
```

## Testing
```bash
pytest tests/database/
```

## Related Documentation
- [Database Schema Docs](../../docs/architecture/database.md)
- [Project README](../../README.md)
