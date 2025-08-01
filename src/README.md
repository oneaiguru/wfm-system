# Source Package

## Overview
The `src` directory contains the Python backend for WFM Enterprise.  Major packages include:

- **`api`** – FastAPI application exposing REST and WebSocket endpoints.
- **`algorithms`** – Erlang C calculations, ML forecasting and schedule optimisation code.
- **`database`** – SQLAlchemy models and helpers for PostgreSQL.
- **`websocket`** – real‑time server used by the UI for live updates.

## Features
- Modular architecture for easy extension
- Type hinted codebase with Pydantic models
- Compatible with the UI and automated test suites

## Usage
Start the development server:
```bash
python -m uvicorn src.api.main:app --reload
```
See the individual sub‑module READMEs for more details.

## Testing
```bash
pytest tests/
```

## Related Documentation
- [Project README](../README.md)
- [API Documentation](../docs/api/api_reference.md)
