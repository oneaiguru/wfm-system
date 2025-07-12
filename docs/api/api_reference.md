---
title: "WFM Enterprise API Reference"
description: "Complete API documentation for WFM Enterprise"
version: "1.0.0"
last_updated: "2025-07-12T07:21:10.901502"
---

# WFM Enterprise API Reference

## Overview

The WFM Enterprise API provides comprehensive workforce management capabilities including employee scheduling, forecasting, and optimization algorithms.

## Authentication

All API endpoints require JWT authentication. Include the token in the Authorization header: `Bearer <token>`

## Base URL

```
https://api.wfm-enterprise.com/api/v1
```

## Error Handling

The API uses standard HTTP status codes and returns error details in JSON format:

```json
{
  "detail": "Error description",
  "error_code": "VALIDATION_ERROR",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

## Rate Limiting

API requests are limited to 1000 requests per hour per authenticated user. Rate limit headers are included in all responses:

```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1642248600
```
