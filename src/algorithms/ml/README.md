# ML Algorithms

## Overview
Machine learning models used for workload forecasting. Implemented with
scikit‑learn and NumPy.

## Features
- Support for multiple regression models
- Tools for time series preprocessing
- Benchmark utilities for accuracy comparison

## Usage
```python
from src.algorithms.ml.forecast import forecast_demand

y = forecast_demand(history)
```

## Testing
```bash
pytest tests/algorithms/ml/
```

## Related Documentation
- [Algorithms README](../README.md)
- [Forecasting API Guide](../../../docs/FORECASTING_API_IMPLEMENTATION_SUMMARY.md)
