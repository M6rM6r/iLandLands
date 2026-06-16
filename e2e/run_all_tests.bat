@echo off
REM End-to-End Test Runner for Gulf Lands (Windows)
REM This script runs all e2e tests across Flutter, API, and Web components

setlocal enabledelayedexpansion

echo Starting Gulf Lands E2E Test Suite...

REM Colors (Windows CMD doesn't support ANSI colors well, so using plain text)
set "INFO=[INFO]"
set "WARN=[WARN]"
set "ERROR=[ERROR]"

REM Check dependencies
echo %INFO% Checking dependencies...

where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo %ERROR% Flutter is not installed or not in PATH
    exit /b 1
)

where python >nul 2>nul
if %errorlevel% neq 0 (
    echo %ERROR% Python is not installed
    exit /b 1
)

where node >nul 2>nul
if %errorlevel% neq 0 (
    echo %ERROR% Node.js is not installed
    exit /b 1
)

where npm >nul 2>nul
if %errorlevel% neq 0 (
    echo %ERROR% npm is not installed
    exit /b 1
)

REM Verify Python version (Warning for 3.13+)
python -c "import sys; exit(0) if sys.version_info.minor < 13 else exit(1)"
if %errorlevel% neq 0 (
    echo %WARN% Python 3.13 detected. Ensure requirements.txt uses Pydantic 2.10+
)

echo %INFO% All dependencies found

REM Start services
echo %INFO% Starting backend services...

set "ROOT_DIR=%~dp0.."

REM Start Python API
cd /d "%ROOT_DIR%\backend-python"
start /B python -m uvicorn main:app --port 8000
echo %INFO% API service started

REM Start reco service if exists
if exist "%ROOT_DIR%\reco-service" (
    cd /d "%ROOT_DIR%\reco-service"
    start /B python -m uvicorn app:app --port 8001
    echo %INFO% Reco service started
)

REM Start analytics service
cd /d "%ROOT_DIR%\analytics"
start /B python app.py
echo %INFO% Analytics service started

REM Start marketing site
cd /d "%ROOT_DIR%\marketing-site"
start /B python -m http.server 3000
echo %INFO% Web server started on port 3000

cd /d "%ROOT_DIR%"

echo %INFO% Services started, waiting for startup...
set /a retry_count=0
set /a max_retries=15

:wait_for_api
curl -s http://localhost:8000/health >nul
if %errorlevel% neq 0 (
    set /a retry_count+=1
    echo %INFO% Waiting for API (Attempt !retry_count!/%max_retries%)...
    if !retry_count! geq %max_retries% (
        echo %ERROR% API failed to start in time.
        goto :cleanup
    )
    timeout /t 2 /nobreak >nul
    goto :wait_for_api
)

REM Run Flutter tests
echo %INFO% Running Flutter integration tests...

REM Install dependencies if needed
flutter pub get

set failures=0
for /l %%i in (1,1,5) do (
    echo %INFO% Flutter test run %%i/5
    flutter test integration_test\app_test.dart --verbose
    if !errorlevel! neq 0 (
        set /a failures+=1
        echo %WARN% Flutter test run %%i failed
    )
)

if %failures% gtr 1 (
    echo %ERROR% Flutter tests failed too many times (%failures%/5)
    goto :cleanup
)

echo %INFO% Flutter tests passed

REM Run API tests
echo %INFO% Running API contract tests...

cd e2e\api

REM Install dependencies
pip install -r requirements.txt

set failures=0
for /l %%i in (1,1,5) do (
    echo %INFO% API test run %%i/5
    python -m pytest test_api_contracts.py -v
    if !errorlevel! neq 0 (
        set /a failures+=1
        echo %WARN% API test run %%i failed
    )
)

if %failures% gtr 1 (
    echo %ERROR% API tests failed too many times (%failures%/5)
    goto :cleanup
)

echo %INFO% API tests passed
cd ..\..

REM Run web tests
echo %INFO% Running web smoke tests...

cd e2e\web

REM Install dependencies
npm install

REM Install Playwright browsers
npx playwright install

set failures=0
for /l %%i in (1,1,5) do (
    echo %INFO% Web test run %%i/5
    npm test
    if !errorlevel! neq 0 (
        set /a failures+=1
        echo %WARN% Web test run %%i failed
    )
)

if %failures% gtr 1 (
    echo %ERROR% Web tests failed too many times (%failures%/5)
    goto :cleanup
)

echo %INFO% Web tests passed
cd ..\..

echo %INFO% All E2E tests passed! ✅
exit /b 0

:cleanup
echo %ERROR% Some E2E tests failed ❌
taskkill /f /im python.exe >nul 2>&1
taskkill /f /im node.exe >nul 2>&1
exit /b 1