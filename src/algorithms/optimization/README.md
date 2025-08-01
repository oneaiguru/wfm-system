# Optimization Algorithms

## Overview
Routines for schedule and resource optimisation. Implemented using linear
programming and heuristic approaches.

## Features
- Mixed Integer Programming models
- Heuristics for large scale problems
- Interfaces for plugging in custom constraints

## Usage
```python
from src.algorithms.optimization.scheduler import optimize_schedule

result = optimize_schedule(data)
```

## Testing
```bash
pytest tests/algorithms/optimization/
```

## Related Documentation
- [Algorithms README](../README.md)
- [Optimization API Summary](../../../docs/INTEGRATED_WORKFORCE_OPTIMIZATION_IMPLEMENTATION_SUMMARY.md)
