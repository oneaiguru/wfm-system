# API Testing Guide

## Overview

This guide covers various approaches for testing the WFM Enterprise API.

## Environment Setup

Set up your testing environment with the following variables:

```bash
# Development
export API_BASE_URL="http://localhost:8000"
export AUTH_TOKEN="your-jwt-token-here"

# Production
export API_BASE_URL="https://api.wfm-enterprise.com"
export AUTH_TOKEN="your-production-token"

```

## Authentication Testing

First, obtain an authentication token:

```bash
curl -X POST "$API_BASE_URL/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@demo.com",
    "password": "AdminPass123!"
  }'

```

## Endpoint Testing Examples

## Automated Testing

Use tools like pytest for automated API testing:

```python
import requests
import pytest

class TestWFMAPI:
    base_url = "http://localhost:8000"
    auth_token = None
    
    def setup_class(self):
        # Get auth token
        response = requests.post(f"{self.base_url}/api/v1/auth/login", 
                               json={"email": "admin@demo.com", "password": "AdminPass123!"})
        self.auth_token = response.json()["access_token"]
    
    def test_health_endpoint(self):
        response = requests.get(f"{self.base_url}/health")
        assert response.status_code == 200
    
    def test_authenticated_endpoint(self):
        headers = {"Authorization": f"Bearer {self.auth_token}"}
        response = requests.get(f"{self.base_url}/api/v1/personnel/employees", headers=headers)
        assert response.status_code == 200

```

## Load Testing

Use locust for load testing:

```python
from locust import HttpUser, task, between

class WFMAPIUser(HttpUser):
    wait_time = between(1, 3)
    
    def on_start(self):
        # Login and get token
        response = self.client.post("/api/v1/auth/login", 
                                  json={"email": "admin@demo.com", "password": "AdminPass123!"})
        self.token = response.json()["access_token"]
        self.headers = {"Authorization": f"Bearer {self.token}"}
    
    @task
    def get_employees(self):
        self.client.get("/api/v1/personnel/employees", headers=self.headers)
    
    @task
    def get_schedules(self):
        self.client.get("/api/v1/schedules", headers=self.headers)

```
