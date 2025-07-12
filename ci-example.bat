@echo off
REM Example CI Script for EDK2 Setup
REM This demonstrates how to use setup-edk2.bat in a CI environment

echo === EDK2 CI Setup Example ===
echo.

REM Set CI environment variable to ensure non-interactive mode
set "CI=true"

REM Example 1: Setup with current directory
echo Testing CI mode with current directory...
call setup-edk2.bat --ci
if %errorlevel% neq 0 (
    echo ERROR: Setup failed with current directory
    exit /b 1
)

echo.
echo === Setup completed successfully in CI mode ===
echo.

REM Example 2: You could also specify a path
REM call setup-edk2.bat C:\path\to\edk2 --ci

echo For interactive mode, run: setup-edk2.bat
echo For CI mode, run: setup-edk2.bat --ci
echo.
