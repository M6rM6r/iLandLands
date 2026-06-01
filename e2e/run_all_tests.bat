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

echo %INFO% All dependencies found

REM Start services
echo %INFO% Starting backend services...

REM Start Python API
cd backend-python
start /B python main.py >nul 2>&1
echo %INFO% API service started
cd ..

REM Start reco service if exists
if exist reco-service (
    cd reco-service
    start /B python app.py >nul 2>&1
    echo %INFO% Reco service started
    cd ..
)

REM Start analytics service
cd analytics
start /B python app.py >nul 2>&1
echo %INFO% Analytics service started
cd ..

REM Start marketing site
cd marketing-site
start /B python -m http.server 3000 >nul 2>&1
echo %INFO% Web server started on port 3000
cd ..

echo %INFO% Services started, waiting for startup...
timeout /t 10 /nobreak >nul

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
exit /b 1