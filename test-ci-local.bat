@echo off
REM Local CI Test Script
REM This simulates the GitHub Actions environment locally

echo === Local CI Test for EDK2 Setup ===
echo.

REM Set CI environment variables to simulate GitHub Actions
set "CI=true"
set "GITHUB_ACTIONS=true"
set "RUNNER_OS=Windows"

echo Environment variables set:
echo   CI=%CI%
echo   GITHUB_ACTIONS=%GITHUB_ACTIONS%
echo   RUNNER_OS=%RUNNER_OS%
echo.

REM Test the setup script in CI mode
echo Testing setup-edk2.bat in CI mode...
echo.

REM Assuming we're in the edk2-setup-scripts directory
if exist "setup-edk2.bat" (
    echo Found setup-edk2.bat, testing CI mode...
    call setup-edk2.bat --ci
    
    if %errorlevel% equ 0 (
        echo.
        echo === CI Test PASSED ===
        echo Setup script completed successfully in CI mode
    ) else (
        echo.
        echo === CI Test FAILED ===
        echo Setup script failed with error code %errorlevel%
        exit /b 1
    )
) else (
    echo ERROR: setup-edk2.bat not found in current directory
    echo Please run this script from the edk2-setup-scripts directory
    exit /b 1
)

echo.
echo Press any key to exit...
pause >nul
