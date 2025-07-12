# API Developer Guide

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Adding New Endpoints](#adding-new-endpoints)
3. [Service Layer Patterns](#service-layer-patterns)
4. [Integration Architecture](#integration-architecture)
5. [Performance Best Practices](#performance-best-practices)
6. [Testing Guidelines](#testing-guidelines)

## Architecture Overview

The WFM Enterprise API follows a layered architecture:

```
┌─────────────────────────────────────┐
│         API Endpoints               │  ← FastAPI routers
├─────────────────────────────────────┤
│         Service Layer               │  ← Business logic
├─────────────────────────────────────┤
│     Integration Layer               │  ← Cross-module communication
├─────────────────────────────────────┤
│  Database │ Cache │ Algorithm Modules│  ← Data/computation layer
└─────────────────────────────────────┘
```

### Key Principles
1. **Separation of Concerns**: Endpoints handle HTTP, services handle business logic
2. **Dependency Injection**: Use FastAPI's `Depends()` for database sessions
3. **Async First**: All I/O operations should be async
4. **Type Safety**: Use Pydantic models for all request/response schemas

## Adding New Endpoints

### Step 1: Define the Schema
Create Pydantic models in `/src/api/v1/schemas/`:

```python
# src/api/v1/schemas/your_feature.py
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime

class YourFeatureRequest(BaseModel):
    """Request model for your feature"""
    field1: str = Field(..., description="Field description")
    field2: Optional[int] = Field(None, ge=0, description="Optional field")
    
    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "field1": "example value",
                "field2": 42
            }
        }
    )

class YourFeatureResponse(BaseModel):
    """Response model for your feature"""
    id: str
    result: Dict[str, Any]
    timestamp: datetime
```

### Step 2: Create the Service
Add business logic in `/src/api/services/`:

```python
# src/api/services/your_feature_service.py
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List, Optional
import logging

logger = logging.getLogger(__name__)

class YourFeatureService:
    """
    Service layer for your feature.
    
    This service handles:
    - Business logic implementation
    - Database operations
    - Integration with other services
    """
    
    def __init__(self, db: AsyncSession):
        self.db = db
    
    async def process_feature(self, data: YourFeatureRequest) -> YourFeatureResponse:
        """
        Process the feature request.
        
        Args:
            data: Validated request data
            
        Returns:
            Processed response
            
        Raises:
            ValueError: If validation fails
            ServiceError: If processing fails
        """
        try:
            # Implement your business logic here
            result = await self._perform_calculation(data)
            
            # Save to database if needed
            await self._save_result(result)
            
            return YourFeatureResponse(
                id=generate_id(),
                result=result,
                timestamp=datetime.utcnow()
            )
        except Exception as e:
            logger.error(f"Feature processing failed: {e}")
            raise
```

### Step 3: Create the Endpoint
Add the endpoint in `/src/api/v1/endpoints/`:

```python
# src/api/v1/endpoints/your_feature.py
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from src.api.core.database import get_db
from src.api.v1.schemas.your_feature import YourFeatureRequest, YourFeatureResponse
from src.api.services.your_feature_service import YourFeatureService
from src.api.utils.cache import cache_decorator

router = APIRouter()

@router.post("/process", response_model=YourFeatureResponse)
@cache_decorator(expire=300)  # Cache for 5 minutes
async def process_feature(
    request: YourFeatureRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    Process your feature.
    
    This endpoint:
    - Validates input data
    - Processes through service layer
    - Returns standardized response
    
    Performance target: <500ms
    """
    try:
        service = YourFeatureService(db)
        result = await service.process_feature(request)
        return result
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Endpoint error: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")
```

### Step 4: Register the Router
Update `/src/api/v1/router.py`:

```python
from .endpoints import your_feature

# Add to appropriate router group
feature_router = APIRouter(prefix="/your-feature", tags=["your-feature"])
feature_router.include_router(your_feature.router)
api_router.include_router(feature_router)
```

## Service Layer Patterns

### Pattern 1: Repository Pattern
For database operations:

```python
class YourFeatureRepository:
    """Data access layer"""
    
    def __init__(self, db: AsyncSession):
        self.db = db
    
    async def get_by_id(self, id: str) -> Optional[YourModel]:
        query = select(YourModel).where(YourModel.id == id)
        result = await self.db.execute(query)
        return result.scalar_one_or_none()
    
    async def create(self, data: dict) -> YourModel:
        obj = YourModel(**data)
        self.db.add(obj)
        await self.db.commit()
        await self.db.refresh(obj)
        return obj
```

### Pattern 2: Caching Strategy
For performance optimization:

```python
from src.api.utils.cache import cache_decorator, invalidate_cache_pattern

class CachedService:
    @cache_decorator(expire=3600)  # 1 hour
    async def get_expensive_data(self, key: str):
        # Expensive operation
        return result
    
    async def update_data(self, key: str, data: dict):
        # Update operation
        await self._save_data(data)
        # Invalidate related cache
        await invalidate_cache_pattern(f"expensive_data:{key}*")
```

### Pattern 3: Error Handling
Consistent error handling:

```python
from src.api.core.exceptions import ServiceError, ValidationError

class RobustService:
    async def process(self, data: dict):
        try:
            # Validate
            if not self._validate(data):
                raise ValidationError("Invalid data format")
            
            # Process
            result = await self._process_internal(data)
            
            # Handle specific errors
            if result is None:
                raise ServiceError("Processing failed", code="PROC_001")
                
            return result
            
        except ValidationError:
            raise  # Re-raise validation errors
        except ServiceError:
            raise  # Re-raise service errors
        except Exception as e:
            logger.error(f"Unexpected error: {e}")
            raise ServiceError("Internal error", code="INT_001")
```

## Integration Architecture

### Direct Algorithm Integration
For performance-critical paths:

```python
# Direct import from algorithm module
from src.algorithms.core.your_algorithm import YourAlgorithm

class DirectIntegrationService:
    def __init__(self):
        self.algorithm = YourAlgorithm()
    
    async def calculate(self, params: dict):
        # Direct call for maximum performance
        return self.algorithm.calculate(**params)
```

### Service-to-Service Communication
For loose coupling:

```python
# Using dependency injection
class ServiceA:
    def __init__(self, service_b: ServiceB):
        self.service_b = service_b
    
    async def process(self):
        # Delegate to another service
        result = await self.service_b.get_data()
        return self._transform(result)
```

### Event-Driven Integration
For asynchronous processing:

```python
from src.api.core.events import EventBus

class EventDrivenService:
    async def process(self, data: dict):
        # Process synchronously
        result = await self._process(data)
        
        # Emit event for async processing
        await EventBus.emit("data_processed", {
            "id": result.id,
            "timestamp": datetime.utcnow()
        })
        
        return result
```

## Performance Best Practices

### 1. Database Query Optimization
```python
# Bad: N+1 queries
agents = await db.execute(select(Agent))
for agent in agents:
    groups = await db.execute(select(Group).where(Group.agent_id == agent.id))

# Good: Eager loading
agents = await db.execute(
    select(Agent).options(selectinload(Agent.groups))
)
```

### 2. Batch Processing
```python
async def process_batch(self, items: List[dict]):
    # Process in chunks
    chunk_size = 100
    results = []
    
    for i in range(0, len(items), chunk_size):
        chunk = items[i:i + chunk_size]
        chunk_results = await asyncio.gather(*[
            self.process_item(item) for item in chunk
        ])
        results.extend(chunk_results)
    
    return results
```

### 3. Connection Pooling
```python
# In core/database.py
engine = create_async_engine(
    DATABASE_URL,
    pool_size=20,        # Number of connections
    max_overflow=10,     # Extra connections when needed
    pool_pre_ping=True,  # Verify connections before use
    pool_recycle=3600    # Recycle connections after 1 hour
)
```

### 4. Response Streaming
For large datasets:

```python
from fastapi.responses import StreamingResponse

@router.get("/large-dataset")
async def stream_large_dataset():
    async def generate():
        async for row in get_large_dataset():
            yield json.dumps(row) + "\n"
    
    return StreamingResponse(
        generate(),
        media_type="application/x-ndjson"
    )
```

## Testing Guidelines

### Unit Tests
```python
# tests/unit/test_your_service.py
import pytest
from unittest.mock import Mock, AsyncMock

@pytest.mark.asyncio
async def test_your_service_process():
    # Arrange
    mock_db = AsyncMock()
    service = YourService(mock_db)
    
    # Act
    result = await service.process({"field": "value"})
    
    # Assert
    assert result.id is not None
    mock_db.commit.assert_called_once()
```

### Integration Tests
```python
# tests/integration/test_your_endpoint.py
@pytest.mark.asyncio
async def test_endpoint_integration(client, db_session):
    # Arrange
    test_data = {"field": "value"}
    
    # Act
    response = await client.post("/api/v1/your-feature/process", json=test_data)
    
    # Assert
    assert response.status_code == 200
    assert response.json()["result"] is not None
```

### Performance Tests
```python
# tests/performance/test_your_feature_perf.py
import asyncio
import time

@pytest.mark.performance
async def test_endpoint_performance(client):
    start = time.time()
    
    # Run 100 concurrent requests
    tasks = [
        client.post("/api/v1/your-feature/process", json={"field": f"value{i}"})
        for i in range(100)
    ]
    
    responses = await asyncio.gather(*tasks)
    duration = time.time() - start
    
    # Assert performance requirements
    assert all(r.status_code == 200 for r in responses)
    assert duration < 10  # Should complete in under 10 seconds
    assert duration / 100 < 0.5  # Average < 500ms per request
```

## Common Pitfalls and Solutions

### 1. Forgetting Async Context
```python
# Bad: Blocking I/O in async function
def get_external_data():
    return requests.get("http://api.example.com/data")  # Blocks!

# Good: Use async libraries
async def get_external_data():
    async with httpx.AsyncClient() as client:
        return await client.get("http://api.example.com/data")
```

### 2. Memory Leaks
```python
# Bad: Unbounded cache
cache = {}

# Good: Bounded cache with TTL
from src.api.utils.cache import TTLCache
cache = TTLCache(max_size=1000, ttl=3600)
```

### 3. Database Connection Leaks
```python
# Bad: Manual session management
db = SessionLocal()
try:
    result = db.query(Model).all()
finally:
    db.close()  # Easy to forget!

# Good: Use dependency injection
async def endpoint(db: AsyncSession = Depends(get_db)):
    # Session automatically managed
    result = await db.execute(query)
```

## Development Workflow

1. **Create feature branch**: `git checkout -b feature/your-feature`
2. **Implement schema, service, and endpoint**
3. **Write tests** (aim for 80%+ coverage)
4. **Run linting**: `ruff check src/`
5. **Run tests**: `pytest tests/`
6. **Update documentation**
7. **Create pull request**

## Resources

- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [SQLAlchemy Async Documentation](https://docs.sqlalchemy.org/en/14/orm/extensions/asyncio.html)
- [Pydantic V2 Documentation](https://docs.pydantic.dev/latest/)
- [Project README](/README.md)
- [System Documentation](/SYSTEM_DOCUMENTATION.md)

---

Last Updated: 2024-07-11
Version: 1.0.0