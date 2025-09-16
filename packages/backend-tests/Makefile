# Makefile for SingleClin API Tests

.PHONY: help test test-watch test-coverage test-unit test-integration clean build restore

# Default target
help:
	@echo "SingleClin API Test Makefile"
	@echo "============================"
	@echo ""
	@echo "Available targets:"
	@echo "  help           Show this help message"
	@echo "  restore        Restore NuGet packages"
	@echo "  build          Build the test project"
	@echo "  test           Run all tests"
	@echo "  test-watch     Run tests in watch mode"
	@echo "  test-coverage  Run tests with code coverage"
	@echo "  test-unit      Run unit tests only"
	@echo "  test-integration Run integration tests only"
	@echo "  test-services  Run service layer tests"
	@echo "  test-controllers Run controller tests"
	@echo "  test-repositories Run repository tests"
	@echo "  test-validators Run validator tests"
	@echo "  test-extensions Run extension tests"
	@echo "  clean          Clean build artifacts and test results"
	@echo "  report         Generate HTML coverage report (requires reportgenerator)"
	@echo ""
	@echo "Examples:"
	@echo "  make test-coverage    # Run tests with coverage"
	@echo "  make test-unit        # Run unit tests only"
	@echo "  make clean test       # Clean and run all tests"

# Restore packages
restore:
	@echo "Restoring NuGet packages..."
	dotnet restore

# Build the project
build: restore
	@echo "Building test project..."
	dotnet build --configuration Release --no-restore

# Run all tests
test:
	@echo "Running all tests..."
	./run-tests.sh

# Run tests in watch mode
test-watch:
	@echo "Starting test watcher..."
	./run-tests.sh --watch --verbose

# Run tests with coverage
test-coverage:
	@echo "Running tests with coverage..."
	./run-tests.sh --coverage --verbose

# Run unit tests only (exclude integration tests)
test-unit:
	@echo "Running unit tests..."
	./run-tests.sh --filter "Category!=Integration"

# Run integration tests only
test-integration:
	@echo "Running integration tests..."
	./run-tests.sh --filter "Category=Integration"

# Run service layer tests
test-services:
	@echo "Running service layer tests..."
	./run-tests.sh --filter "Services" --verbose

# Run controller tests
test-controllers:
	@echo "Running controller tests..."
	./run-tests.sh --filter "Controllers" --verbose

# Run repository tests
test-repositories:
	@echo "Running repository tests..."
	./run-tests.sh --filter "Repositories" --verbose

# Run validator tests
test-validators:
	@echo "Running validator tests..."
	./run-tests.sh --filter "Validators" --verbose

# Run extension tests
test-extensions:
	@echo "Running extension tests..."
	./run-tests.sh --filter "Extensions" --verbose

# Clean build artifacts and test results
clean:
	@echo "Cleaning build artifacts..."
	dotnet clean
	rm -rf bin obj
	rm -rf ../coverage
	rm -rf ../TestResults
	@echo "Clean completed."

# Generate HTML coverage report (requires reportgenerator tool)
report: test-coverage
	@echo "Generating HTML coverage report..."
	@if command -v reportgenerator >/dev/null 2>&1; then \
		reportgenerator \
			"-reports:../coverage/coverage.cobertura.xml" \
			"-targetdir:../coverage/html" \
			"-reporttypes:Html;Badges" \
			"-title:SingleClin API Coverage Report" \
			"-tag:$(shell git rev-parse --short HEAD 2>/dev/null || echo 'unknown')"; \
		echo "Coverage report generated at: ../coverage/html/index.html"; \
	else \
		echo "reportgenerator tool not found. Install with:"; \
		echo "  dotnet tool install -g dotnet-reportgenerator-globaltool"; \
	fi

# Run tests in CI/CD pipeline format
test-ci:
	@echo "Running tests in CI/CD mode..."
	./run-tests.sh --coverage --logger "trx;LogFileName=TestResults.trx" --logger "console;verbosity=normal"

# Quick smoke test
test-smoke:
	@echo "Running smoke tests..."
	./run-tests.sh --filter "Category=Smoke" --no-build

# Parallel test execution
test-parallel:
	@echo "Running tests in parallel..."
	./run-tests.sh --parallel --coverage --verbose