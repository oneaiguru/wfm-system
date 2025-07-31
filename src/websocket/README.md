# WebSocket

## Overview
Real-time communication layer built on top of FastAPI's WebSocket support. It is
used by the UI to receive schedule updates and live metrics.

## Features
- Connection management with authentication
- Event dispatcher for broadcasting messages
- Typed message definitions

## Usage
Start the server and connect from the browser:
```bash
uvicorn src.api.main:app --reload
```
In JavaScript:
```javascript
const ws = new WebSocket('ws://localhost:8000/ws');
ws.onmessage = e => console.log(e.data);
```

## Testing
```bash
pytest tests/websocket/
```

## Related Documentation
- [API README](../api/README.md)
- [Project README](../README.md)
