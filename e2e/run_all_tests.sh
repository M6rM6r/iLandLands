#!/bin/bash

# End-to-End Test Runner for Gulf Lands
# This script runs all e2e tests across Flutter, API, and Web components

set -e

echo "Starting Gulf Lands E2E Test Suite..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if required tools are installed
check_dependencies() {
    print_status "Checking dependencies..."

    if ! command -v flutter &> /dev/null; then
        print_error "Flutter is not installed or not in PATH"
        exit 1
    fi

    if ! command -v python3 &> /dev/null; then
        print_error "Python3 is not installed"
        exit 1
    fi

    if ! command -v node &> /dev/null; then
        print_error "Node.js is not installed"
        exit 1
    fi

    if ! command -v npm &> /dev/null; then
        print_error "npm is not installed"
        exit 1
    fi

    print_status "All dependencies found"
}

# Start backend services
start_services() {
    print_status "Starting backend services..."

    # Start Python API
    cd backend-python
    python3 main.py &
    API_PID=$!
    echo $API_PID > ../api.pid
    cd ..

    # Start reco service (if exists)
    if [ -d "reco-service" ]; then
        cd reco-service
        python3 app.py &
        RECO_PID=$!
        echo $RECO_PID > ../reco.pid
        cd ..
    fi

    # Start analytics service
    cd analytics
    python3 app.py &
    ANALYTICS_PID=$!
    echo $ANALYTICS_PID > ../analytics.pid
    cd ..

    # Start marketing site (simple HTTP server)
    cd marketing-site
    python3 -m http.server 3000 &
    WEB_PID=$!
    echo $WEB_PID > ../web.pid
    cd ..

    print_status "Services started, waiting for startup..."
    sleep 10
}

# Stop services
stop_services() {
    print_status "Stopping services..."

    if [ -f api.pid ]; then
        kill $(cat api.pid) 2>/dev/null || true
        rm api.pid
    fi

    if [ -f reco.pid ]; then
        kill $(cat reco.pid) 2>/dev/null || true
        rm reco.pid
    fi

    if [ -f analytics.pid ]; then
        kill $(cat analytics.pid) 2>/dev/null || true
        rm analytics.pid
    fi

    if [ -f web.pid ]; then
        kill $(cat web.pid) 2>/dev/null || true
        rm web.pid
    fi
}

# Run Flutter integration tests
run_flutter_tests() {
    print_status "Running Flutter integration tests..."

    # Install dependencies if needed
    flutter pub get

    # Run tests multiple times to check for flakes
    local failures=0
    for i in {1..5}; do
        print_status "Flutter test run $i/5"
        if ! flutter test integration_test/app_test.dart --verbose; then
            ((failures++))
            print_warning "Flutter test run $i failed"
        fi
    done

    if [ $failures -gt 1 ]; then  # Allow 1 failure for flake tolerance
        print_error "Flutter tests failed too many times ($failures/5)"
        return 1
    fi

    print_status "Flutter tests passed"
}

# Run API tests
run_api_tests() {
    print_status "Running API contract tests..."

    cd e2e/api

    # Install dependencies
    pip3 install -r requirements.txt

    # Run tests multiple times
    local failures=0
    for i in {1..5}; do
        print_status "API test run $i/5"
        if ! python3 -m pytest test_api_contracts.py -v; then
            ((failures++))
            print_warning "API test run $i failed"
        fi
    done

    if [ $failures -gt 1 ]; then
        print_error "API tests failed too many times ($failures/5)"
        return 1
    fi

    print_status "API tests passed"
    cd ../..
}

# Run web tests
run_web_tests() {
    print_status "Running web smoke tests..."

    cd e2e/web

    # Install dependencies
    npm install

    # Install Playwright browsers
    npx playwright install

    # Run tests multiple times
    local failures=0
    for i in {1..5}; do
        print_status "Web test run $i/5"
        if ! npm test; then
            ((failures++))
            print_warning "Web test run $i failed"
        fi
    done

    if [ $failures -gt 1 ]; then
        print_error "Web tests failed too many times ($failures/5)"
        return 1
    fi

    print_status "Web tests passed"
    cd ../..
}

# Main execution
main() {
    trap stop_services EXIT

    check_dependencies
    start_services

    local exit_code=0

    if ! run_flutter_tests; then
        exit_code=1
    fi

    if ! run_api_tests; then
        exit_code=1
    fi

    if ! run_web_tests; then
        exit_code=1
    fi

    if [ $exit_code -eq 0 ]; then
        print_status "All E2E tests passed! ✅"
    else
        print_error "Some E2E tests failed ❌"
    fi

    exit $exit_code
}

main "$@"