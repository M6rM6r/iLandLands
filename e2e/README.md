# Gulf Lands End-to-End Test Suite

This directory contains comprehensive end-to-end tests for the Gulf Lands application, covering Flutter mobile app, Python API backend, and web marketing site.

## Test Coverage

### Flutter Integration Tests (`flutter/`)
- **User Journey**: Browse → Filter → Open → Favorite → Return
- **Search Functionality**: Text-based listing search
- **Sort Functionality**: Price and other sorting options
- **UI Interactions**: Taps, scrolls, form inputs

### API Contract Tests (`api/`)
- **Listing Endpoints**: `/v1/listings` with filtering and search
- **Individual Listings**: `/v1/listings/{id}`
- **Analytics Events**: `/v1/analytics/events`
- **Recommendations**: External reco-service integration
- **Contract Validation**: Ensures API responses match expected schemas

### Web Smoke Tests (`web/`)
- **Landing Page**: Content loading and navigation
- **Analytics Dispatch**: Event tracking verification
- **Responsive Design**: Mobile and desktop layouts
- **Form Submissions**: Contact and interaction forms

## Prerequisites

- Flutter SDK (with integration_test package)
- Python 3.8+ (with pytest, requests)
- Node.js 16+ (with npm)
- Playwright browsers installed

## Running Tests

### All Tests (Recommended for CI)
```bash
# Linux/Mac
./e2e/run_all_tests.sh

# Windows
e2e\run_all_tests.bat
```

### Individual Test Suites

#### Flutter Tests
```bash
cd e2e/flutter
flutter pub get
flutter test integration_test/app_test.dart
```

#### API Tests
```bash
cd e2e/api
pip install -r requirements.txt
python -m pytest test_api_contracts.py -v
```

#### Web Tests
```bash
cd e2e/web
npm install
npx playwright install
npm test
```

## CI Integration

The test suite is designed for CI environments with:
- **Flake Tolerance**: Tests run 5 times with <2 failures allowed
- **Service Management**: Automatic startup/shutdown of backend services
- **Parallel Execution**: Components can run independently
- **Exit Codes**: Proper error reporting for CI pipelines

### GitHub Actions Example
```yaml
name: E2E Tests
on: [push, pull_request]
jobs:
  e2e:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - uses: actions/setup-python@v4
      - uses: actions/setup-node@v3
      - name: Run E2E Tests
        run: ./e2e/run_all_tests.sh
```

## Test Stability

- **Flake Rate Target**: <2% across 20 reruns
- **Retry Logic**: Built-in retry mechanisms for transient failures
- **Isolation**: Each test run is independent
- **Timeouts**: Reasonable timeouts to prevent hanging

## Architecture

```
e2e/
├── flutter/           # Flutter integration tests
│   └── app_test.dart
├── api/              # API contract tests
│   ├── test_api_contracts.py
│   └── requirements.txt
├── web/              # Web smoke tests
│   ├── smoke_tests.spec.ts
│   └── package.json
├── run_all_tests.sh  # Linux/Mac runner
└── run_all_tests.bat # Windows runner
```

## Adding New Tests

### Flutter
1. Add test cases to `e2e/flutter/app_test.dart`
2. Use `IntegrationTestWidgetsFlutterBinding`
3. Follow `pumpAndSettle()` pattern for async operations

### API
1. Add test methods to `e2e/api/test_api_contracts.py`
2. Use pytest fixtures for setup
3. Validate against contract models

### Web
1. Add test cases to `e2e/web/smoke_tests.spec.ts`
2. Use Playwright's page object model
3. Mock external dependencies as needed

## Troubleshooting

### Common Issues

1. **Services not starting**: Check port conflicts (8000, 8001, 3000)
2. **Flutter tests failing**: Ensure device/emulator is available
3. **API tests failing**: Verify backend services are running
4. **Web tests failing**: Check Playwright browser installation

### Debug Mode
```bash
# Flutter debug
flutter test integration_test/app_test.dart --debug

# Web debug
npm run test:debug

# API debug
python -m pytest test_api_contracts.py -v -s
```

## Contributing

When adding new tests:
1. Follow existing patterns and naming conventions
2. Add appropriate assertions and error handling
3. Update this README with new test descriptions
4. Ensure tests pass in CI before merging