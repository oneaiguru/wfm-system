# WFM Enterprise Testing Makefile

# Variables
PYTHON := python
PIP := pip
NPM := npm
PYTEST := pytest
JEST := npm run test:jest
CYPRESS := npm run test:e2e
LOCUST := locust

# Colors
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

# Default target
.DEFAULT_GOAL := help

.PHONY: help
help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Installation
.PHONY: install
install: install-python install-node ## Install all dependencies

.PHONY: install-python
install-python: ## Install Python dependencies
	@echo "$(GREEN)Installing Python dependencies...$(NC)"
	$(PIP) install -r requirements.txt

.PHONY: install-node
install-node: ## Install Node.js dependencies
	@echo "$(GREEN)Installing Node.js dependencies...$(NC)"
	$(NPM) install

# Testing - All
.PHONY: test
test: test-unit test-integration test-e2e ## Run all tests

.PHONY: test-fast
test-fast: test-unit-fast test-integration-fast ## Run fast tests only

# Unit Tests
.PHONY: test-unit
test-unit: test-unit-python test-unit-js ## Run all unit tests

.PHONY: test-unit-python
test-unit-python: ## Run Python unit tests
	@echo "$(GREEN)Running Python unit tests...$(NC)"
	$(PYTEST) tests/unit/backend -v -m "not slow"

.PHONY: test-unit-js
test-unit-js: ## Run JavaScript/TypeScript unit tests
	@echo "$(GREEN)Running JavaScript unit tests...$(NC)"
	$(JEST)

.PHONY: test-unit-fast
test-unit-fast: ## Run fast unit tests only
	$(PYTEST) tests/unit -v -m "not slow" -x --tb=short
	$(NPM) run test -- --bail

# Integration Tests
.PHONY: test-integration
test-integration: test-integration-api test-integration-db ## Run all integration tests

.PHONY: test-integration-api
test-integration-api: ## Run API integration tests
	@echo "$(GREEN)Running API integration tests...$(NC)"
	$(PYTEST) tests/integration/api -v

.PHONY: test-integration-db
test-integration-db: ## Run database integration tests
	@echo "$(GREEN)Running database integration tests...$(NC)"
	$(PYTEST) tests/integration/database -v

.PHONY: test-integration-fast
test-integration-fast: ## Run fast integration tests
	$(PYTEST) tests/integration -v -m "not slow" -x

# E2E Tests
.PHONY: test-e2e
test-e2e: ## Run end-to-end tests
	@echo "$(GREEN)Running E2E tests...$(NC)"
	$(CYPRESS)

.PHONY: test-e2e-open
test-e2e-open: ## Open Cypress Test Runner
	$(NPM) run test:e2e:open

.PHONY: test-e2e-headed
test-e2e-headed: ## Run E2E tests in headed mode
	$(CYPRESS) -- --headed

# BDD Tests
.PHONY: test-bdd
test-bdd: test-bdd-python test-bdd-js ## Run all BDD tests

.PHONY: test-bdd-python
test-bdd-python: ## Run Python BDD tests
	@echo "$(GREEN)Running Python BDD tests...$(NC)"
	$(PYTEST) tests/bdd -v -m "bdd"

.PHONY: test-bdd-js
test-bdd-js: ## Run JavaScript BDD tests
	@echo "$(GREEN)Running JavaScript BDD tests...$(NC)"
	$(NPM) run test:bdd

# Performance Tests
.PHONY: test-performance
test-performance: ## Run performance tests
	@echo "$(GREEN)Running performance tests...$(NC)"
	$(PYTEST) tests/performance -v -m "performance"

.PHONY: test-load
test-load: ## Run load tests with Locust
	@echo "$(GREEN)Running load tests...$(NC)"
	cd tests/performance/load && $(LOCUST) --headless --users 100 --spawn-rate 10 --run-time 60s

.PHONY: test-load-ui
test-load-ui: ## Run Locust with web UI
	cd tests/performance/load && $(LOCUST)

# Coverage
.PHONY: test-coverage
test-coverage: coverage-python coverage-js ## Generate test coverage for all

.PHONY: coverage-python
coverage-python: ## Generate Python test coverage
	@echo "$(GREEN)Generating Python coverage report...$(NC)"
	$(PYTEST) --cov=src --cov-report=html --cov-report=term-missing

.PHONY: coverage-js
coverage-js: ## Generate JavaScript test coverage
	@echo "$(GREEN)Generating JavaScript coverage report...$(NC)"
	$(NPM) run test:coverage

.PHONY: coverage-open
coverage-open: ## Open coverage reports in browser
	@echo "$(GREEN)Opening coverage reports...$(NC)"
	open htmlcov/index.html
	open coverage/lcov-report/index.html

# Specific test suites
.PHONY: test-algorithms
test-algorithms: ## Test algorithm implementations
	$(PYTEST) tests/unit/backend/algorithms -v

.PHONY: test-api
test-api: ## Test API endpoints
	$(PYTEST) tests/unit/backend/api tests/integration/api -v

.PHONY: test-websocket
test-websocket: ## Test WebSocket functionality
	$(PYTEST) tests/websocket -v -m "websocket"

.PHONY: test-components
test-components: ## Test React components
	$(JEST) -- tests/unit/frontend/components

# Watch mode
.PHONY: test-watch
test-watch: ## Run tests in watch mode
	$(PYTEST)-watch tests/unit

.PHONY: test-watch-js
test-watch-js: ## Run JavaScript tests in watch mode
	$(NPM) run test:jest:watch

# Database
.PHONY: test-db-create
test-db-create: ## Create test database
	@echo "$(GREEN)Creating test database...$(NC)"
	$(PYTHON) -m tests.helpers.create_test_db

.PHONY: test-db-seed
test-db-seed: ## Seed test database
	@echo "$(GREEN)Seeding test database...$(NC)"
	$(PYTHON) -m tests.helpers.seed_test_data

.PHONY: test-db-clean
test-db-clean: ## Clean test database
	@echo "$(GREEN)Cleaning test database...$(NC)"
	$(PYTHON) -m tests.helpers.clean_test_db

# Linting and formatting
.PHONY: lint
lint: lint-python lint-js ## Run all linters

.PHONY: lint-python
lint-python: ## Lint Python code
	@echo "$(GREEN)Linting Python code...$(NC)"
	flake8 src tests
	mypy src

.PHONY: lint-js
lint-js: ## Lint JavaScript/TypeScript code
	@echo "$(GREEN)Linting JavaScript code...$(NC)"
	$(NPM) run lint

# Test markers
.PHONY: test-critical
test-critical: ## Run critical tests only
	$(PYTEST) -m "critical" -v

.PHONY: test-slow
test-slow: ## Run slow tests
	$(PYTEST) -m "slow" -v

.PHONY: test-smoke
test-smoke: ## Run smoke tests
	$(PYTEST) -m "critical and not slow" -v --tb=short
	$(CYPRESS) -- --spec "tests/e2e/cypress/integration/smoke/**"

# Reports
.PHONY: test-report
test-report: ## Generate test report
	@echo "$(GREEN)Generating test report...$(NC)"
	$(PYTEST) --junit-xml=test-results/pytest.xml
	$(JEST) -- --reporters=jest-junit
	$(PYTHON) -m tests.helpers.generate_report

# Docker
.PHONY: test-docker
test-docker: ## Run tests in Docker
	docker-compose -f docker-compose.test.yml up --build --abort-on-container-exit

.PHONY: test-docker-build
test-docker-build: ## Build test Docker images
	docker-compose -f docker-compose.test.yml build

# Continuous Integration
.PHONY: ci
ci: lint test-coverage ## Run CI pipeline

.PHONY: ci-fast
ci-fast: lint test-fast ## Run fast CI pipeline

# Clean
.PHONY: clean
clean: ## Clean test artifacts
	@echo "$(RED)Cleaning test artifacts...$(NC)"
	rm -rf .pytest_cache
	rm -rf htmlcov
	rm -rf coverage
	rm -rf test-results
	rm -rf tests/e2e/cypress/screenshots
	rm -rf tests/e2e/cypress/videos
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete

# Utilities
.PHONY: test-debug
test-debug: ## Run tests with debugger
	$(PYTEST) -v --pdb

.PHONY: test-failed
test-failed: ## Re-run failed tests
	$(PYTEST) --lf -v

.PHONY: test-parallel
test-parallel: ## Run tests in parallel
	$(PYTEST) -n auto -v

.PHONY: test-random
test-random: ## Run tests in random order
	$(PYTEST) --random-order -v

# Development helpers
.PHONY: dev-test
dev-test: ## Run tests for current development
	@echo "$(YELLOW)Running development tests...$(NC)"
	$(PYTEST) -k "$(filter)" -v --tb=short

.PHONY: update-snapshots
update-snapshots: ## Update test snapshots
	$(JEST) -- -u
	$(CYPRESS) -- --env updateSnapshots=true