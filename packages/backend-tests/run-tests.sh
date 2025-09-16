#!/bin/bash

# Shell script for running .NET tests with coverage on Unix-based systems

# Default values
CONFIGURATION="Release"
COVERAGE=false
WATCH=false
FILTER=""
PARALLEL=false
VERBOSE=false
LOGGER=""
NO_BUILD=false

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

# Function to display usage
show_usage() {
    echo -e "${GREEN}SingleClin API Test Runner${NC}"
    echo -e "${GREEN}=========================${NC}"
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -c, --configuration <config>  Build configuration (Default: Release)"
    echo "  --coverage                    Enable code coverage collection"
    echo "  --watch                       Run tests in watch mode"
    echo "  -f, --filter <filter>         Test filter expression"
    echo "  --parallel                    Enable parallel test execution"
    echo "  -v, --verbose                 Verbose output"
    echo "  --logger <logger>             Specify logger (default: trx and console)"
    echo "  --no-build                    Skip build before running tests"
    echo "  -h, --help                    Show this help message"
    echo
    echo "Examples:"
    echo "  $0 --coverage                 # Run tests with coverage"
    echo "  $0 --watch --verbose          # Run in watch mode with verbose output"
    echo "  $0 --filter 'Services'        # Run only service tests"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--configuration)
            CONFIGURATION="$2"
            shift 2
            ;;
        --coverage)
            COVERAGE=true
            shift
            ;;
        --watch)
            WATCH=true
            shift
            ;;
        -f|--filter)
            FILTER="$2"
            shift 2
            ;;
        --parallel)
            PARALLEL=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        --logger)
            LOGGER="$2"
            shift 2
            ;;
        --no-build)
            NO_BUILD=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

echo -e "${GREEN}SingleClin API Test Runner${NC}"
echo -e "${GREEN}=========================${NC}"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Create output directories
mkdir -p "../coverage"
mkdir -p "../TestResults"

# Build test command
TEST_CMD="dotnet test"

# Add configuration
TEST_CMD="$TEST_CMD --configuration $CONFIGURATION"

# Add no-build flag
if [ "$NO_BUILD" = true ]; then
    TEST_CMD="$TEST_CMD --no-build"
fi

# Add verbosity
if [ "$VERBOSE" = true ]; then
    TEST_CMD="$TEST_CMD --verbosity detailed"
else
    TEST_CMD="$TEST_CMD --verbosity normal"
fi

# Add filter
if [ -n "$FILTER" ]; then
    TEST_CMD="$TEST_CMD --filter \"$FILTER\""
fi

# Add logger
if [ -n "$LOGGER" ]; then
    TEST_CMD="$TEST_CMD --logger $LOGGER"
else
    TEST_CMD="$TEST_CMD --logger trx --logger console"
fi

# Add settings file
TEST_CMD="$TEST_CMD --settings test.runsettings"

# Add coverage collection
if [ "$COVERAGE" = true ]; then
    echo -e "${YELLOW}Enabling code coverage collection...${NC}"
    TEST_CMD="$TEST_CMD --collect:\"XPlat Code Coverage\""
    TEST_CMD="$TEST_CMD /p:CollectCoverage=true"
    TEST_CMD="$TEST_CMD \"/p:CoverletOutputFormat=opencover\""
    TEST_CMD="$TEST_CMD /p:CoverletOutput=../coverage/"
    TEST_CMD="$TEST_CMD \"/p:Exclude=[xunit.*]*,[*.Tests]*,[SingleClin.API.Tests]*\""
    TEST_CMD="$TEST_CMD \"/p:Include=[SingleClin.API]*\""
    TEST_CMD="$TEST_CMD \"/p:ThresholdType=line\""
    TEST_CMD="$TEST_CMD \"/p:Threshold=80\""
fi

# Add parallel execution
if [ "$PARALLEL" = true ]; then
    TEST_CMD="$TEST_CMD -- xUnit.ParallelizeTestCollections=true"
fi

# Display command
echo -e "${CYAN}Executing: $TEST_CMD${NC}"

# Execute based on watch mode
if [ "$WATCH" = true ]; then
    echo -e "${YELLOW}Starting test watcher...${NC}"
    WATCH_CMD=$(echo "$TEST_CMD" | sed 's/dotnet test/dotnet watch test/')
    eval $WATCH_CMD
else
    # Run tests
    START_TIME=$(date +%s)
    eval $TEST_CMD
    EXIT_CODE=$?
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))

    echo
    echo -e "${GREEN}Test execution completed in ${DURATION} seconds${NC}"

    # Display coverage information if generated
    if [ "$COVERAGE" = true ]; then
        echo
        echo -e "${YELLOW}Coverage Reports Generated:${NC}"
        find ../coverage -name "*.xml" -o -name "*.json" -o -name "*.info" | while read file; do
            echo -e "  - ${GRAY}$file${NC}"
        done

        # Try to display coverage summary
        COVERAGE_JSON=$(find ../coverage -name "coverage.json" | head -n 1)
        if [ -n "$COVERAGE_JSON" ] && [ -f "$COVERAGE_JSON" ]; then
            echo
            echo -e "${YELLOW}Coverage Summary:${NC}"
            # Simple extraction - for production use jq for proper JSON parsing
            if command -v jq &> /dev/null; then
                LINE_RATE=$(jq -r '.summary.lineRate' "$COVERAGE_JSON" 2>/dev/null)
                BRANCH_RATE=$(jq -r '.summary.branchRate' "$COVERAGE_JSON" 2>/dev/null)
                if [ "$LINE_RATE" != "null" ] && [ "$BRANCH_RATE" != "null" ]; then
                    LINE_PERCENT=$(echo "$LINE_RATE * 100" | bc -l 2>/dev/null | cut -d'.' -f1)
                    BRANCH_PERCENT=$(echo "$BRANCH_RATE * 100" | bc -l 2>/dev/null | cut -d'.' -f1)
                    echo -e "  Line Coverage: ${LINE_PERCENT}%"
                    echo -e "  Branch Coverage: ${BRANCH_PERCENT}%"
                fi
            else
                echo -e "${GRAY}  (Install 'jq' for detailed coverage summary)${NC}"
            fi
        fi
    fi

    # Display test results location
    echo
    echo -e "${YELLOW}Test Results Location:${NC}"
    echo -e "  ${GRAY}../TestResults/${NC}"

    if [ -d "../TestResults" ]; then
        find ../TestResults -name "*.trx" | while read file; do
            echo -e "  - ${GRAY}$(basename "$file")${NC}"
        done
    fi

    exit $EXIT_CODE
fi