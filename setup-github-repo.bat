@echo off
REM GitHub Repository Setup Script
REM This script helps you push the EDK2 setup scripts to GitHub for CI testing

echo === GitHub Repository Setup for CI Testing ===
echo.

REM Check if git is available
git --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Git is not installed or not in PATH
    echo Please install Git from: https://git-scm.com/download/win
    pause
    exit /b 1
)

echo Git is available. Proceeding with repository setup...
echo.

REM Check if we're already in a git repository
if exist ".git" (
    echo Found existing .git directory.
    echo Current git status:
    git status --porcelain
    echo.
) else (
    echo Initializing new git repository...
    git init
    echo.
)

REM Create .gitignore if it doesn't exist
if not exist ".gitignore" (
    echo Creating .gitignore file...
    echo # EDK2 Setup Scripts > .gitignore
    echo. >> .gitignore
    echo # Windows >> .gitignore
    echo Thumbs.db >> .gitignore
    echo ehthumbs.db >> .gitignore
    echo Desktop.ini >> .gitignore
    echo. >> .gitignore
    echo # Temporary files >> .gitignore
    echo *.tmp >> .gitignore
    echo *.temp >> .gitignore
    echo *.log >> .gitignore
    echo. >> .gitignore
    echo # Build outputs >> .gitignore
    echo Build/ >> .gitignore
    echo Conf/build_rule.txt >> .gitignore
    echo Conf/target.txt >> .gitignore
    echo Conf/tools_def.txt >> .gitignore
    echo.
)

REM Add all files to git
echo Adding files to git...
git add .
echo.

REM Check what will be committed
echo Files to be committed:
git status --cached --porcelain
echo.

REM Commit the files
echo Creating initial commit...
git commit -m "Initial commit: EDK2 setup scripts with GitHub Actions CI"
echo.

echo === Repository Setup Complete ===
echo.
echo Next steps:
echo 1. Your repository URL: https://github.com/startergo/edk2-setup-scripts.git
echo 2. Run these commands to push to GitHub:
echo.
echo    git remote add origin https://github.com/startergo/edk2-setup-scripts.git
echo    git branch -M main
echo    git push -u origin main
echo.
echo 3. The GitHub Actions workflow will automatically run!
echo 4. Check: https://github.com/startergo/edk2-setup-scripts/actions
echo.
echo Press any key to exit...
pause >nul
