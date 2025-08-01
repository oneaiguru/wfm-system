# Algorithms

## Overview
Collection of calculation engines used by the WFM Enterprise platform. Algorithms
include Erlang C staffing, machine learning forecasting and optimisation routines.

## Features
- Pure Python implementations with NumPy/SciPy
- Pluggable architecture for new strategies
- Shared utilities for benchmarking

## Usage
Example Erlang C call:
```python
from src.algorithms.core.erlang_c import erlang_c

agents = erlang_c(calls=120, aht=300, target_sl=0.8)
```

## Testing
```bash
pytest tests/algorithms/
```

## Related Documentation
- [Erlang C Strategy](../../docs/ERLANG_C_OPTIMIZATION_STRATEGY.md)
- [Project README](../README.md)
