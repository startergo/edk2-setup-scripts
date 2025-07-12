@echo off
REM Check Git and GitHub Status

echo === Git Status Check ===
echo.

REM Check if we're in a git repo
if exist ".git" (
    echo Git repository: YES
    
    echo.
    echo Current branch:
    git branch --show-current
    
    echo.
    echo Remote repositories:
    git remote -v
    
    echo.
    echo Last commit:
    git log --oneline -1
    
    echo.
    echo Files status:
    git status --short
    
    echo.
    echo === Checking GitHub Repository ===
    echo Repository should be at: https://github.com/startergo/edk2-setup-scripts
    echo Actions page: https://github.com/startergo/edk2-setup-scripts/actions
    echo.
    
    REM Try to fetch from remote to check if it exists
    echo Checking if repository exists on GitHub...
    git ls-remote origin >nul 2>&1
    if %errorlevel% equ 0 (
        echo ✓ Repository exists and is accessible
        echo.
        echo To check if files are pushed:
        echo https://github.com/startergo/edk2-setup-scripts
        echo.
        echo To check CI status:
        echo https://github.com/startergo/edk2-setup-scripts/actions
    ) else (
        echo ✗ Repository not accessible or doesn't exist
        echo You may need to push your files first.
    )
    
) else (
    echo Git repository: NO
    echo Run setup-github-repo.bat or push-with-auth.bat first
)

echo.
echo Press any key to exit...
pause >nul
