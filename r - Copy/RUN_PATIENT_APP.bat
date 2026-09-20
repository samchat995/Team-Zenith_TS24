@echo off
title Neural Nexus - Patient App Launcher
color 0B

echo ===============================================================
echo        NEURAL NEXUS - PATIENT COGNITIVE APP LAUNCHER
echo ===============================================================
echo.

cd /d "%~dp0"

:: -------------------------------------------------------------
:: STEP 1: Check FastAPI Backend Status
:: -------------------------------------------------------------
echo [1/3] Checking Backend status on http://127.0.0.1:8000 ...
powershell -NoProfile -Command "try { $res = (Invoke-WebRequest -Uri 'http://127.0.0.1:8000/' -UseBasicParsing -TimeoutSec 2).StatusCode; if ($res -eq 200) { exit 0 } else { exit 1 } } catch { exit 1 }" >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo       Backend is already RUNNING online!
) else (
    echo       Backend not detected. Starting FastAPI backend in a new window...
    start "Neural Nexus Backend (FastAPI)" cmd /k "python -m uvicorn backend.app.main:app --host 127.0.0.1 --port 8000"
    timeout /t 3 >nul
)

:: -------------------------------------------------------------
:: STEP 2 & 3: Check whether production web build exists
:: -------------------------------------------------------------
echo.
echo [2/3] Checking Patient Web Build (mobile\build\web\index.html)...
if not exist "mobile\build\web\index.html" (
    color 0C
    echo.
    echo ===============================================================
    echo [!] PATIENT WEB BUILD NOT FOUND
    echo ===============================================================
    echo The compiled production web app was not found in:
    echo     mobile\build\web\index.html
    echo.
    echo To generate the production web build:
    echo.
    echo     cd mobile
    echo     flutter build web --release
    echo.
    echo Once built, this launcher will start instantly without Flutter!
    echo ===============================================================
    echo.
    pause
    exit /b 1
)
echo       Production web build found. Flutter runtime NOT required!

:: -------------------------------------------------------------
:: STEP 4: Resolve Port 8080 & Process Conflicts
:: -------------------------------------------------------------
echo.
echo [3/3] Resolving Patient App Web Port...
set "RESOLVER_ACTION=USE_PORT"
set "APP_PORT=8080"

for /f "tokens=1,2 delims==" %%A in ('powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0launcher_port_resolver.ps1"') do (
    if "%%A"=="ACTION" set "RESOLVER_ACTION=%%B"
    if "%%A"=="PORT" set "APP_PORT=%%B"
)

if "%APP_PORT%"=="" set "APP_PORT=8080"

:: If an existing instance of the app is already serving, reuse it
if "%RESOLVER_ACTION%"=="REUSE" (
    color 0A
    echo.
    echo ===============================================================
    echo NEURAL NEXUS PATIENT APP IS ALREADY RUNNING
    echo Patient App: http://localhost:%APP_PORT%
    echo Backend API: http://127.0.0.1:8000
    echo ===============================================================
    echo Active server detected. Browser opened without duplicate servers.
    echo.
    pause
    exit /b 0
)

:: -------------------------------------------------------------
:: STEP 5: Start Lightweight Local Server & Open Browser
:: -------------------------------------------------------------
color 0A
echo.
echo ===============================================================
echo NEURAL NEXUS PATIENT APP IS RUNNING
echo Patient App: http://localhost:%APP_PORT%
echo Backend API: http://127.0.0.1:8000
echo ===============================================================
echo Starting lightweight web server on port %APP_PORT%...
echo.

:: Automatically open the patient web app in Chrome / default browser
start "" "http://localhost:%APP_PORT%"

:: Serve compiled production bundle with lightweight Python HTTP server
python -m http.server %APP_PORT% --directory "%~dp0mobile\build\web"

if %ERRORLEVEL% neq 0 (
    color 0C
    echo.
    echo ===============================================================
    echo [!] SERVER EXITED WITH AN ERROR (Code: %ERRORLEVEL%)
    echo ===============================================================
    echo Patient App Port: %APP_PORT%
    echo Backend API: http://127.0.0.1:8000
    echo.
)

pause
