# Core Algorithms

## Overview
Low-level building blocks for more advanced scheduling and forecasting algorithms.
Includes Erlang C probability functions and helper utilities.

## Features
- Optimised numerical routines
- Shared data structures used across algorithms
- Unit tested for accuracy

## Usage
```python
from src.algorithms.core.erlang_c import erlang_c_probability

p = erlang_c_probability(agents=10, traffic=7.2)
```

## Testing
```bash
pytest tests/algorithms/core/
```

## Related Documentation
- [Algorithms README](../README.md)
- [Project README](../../README.md)
