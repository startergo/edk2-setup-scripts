@echo off
REM Quick Push to GitHub Script
REM This script pushes your EDK2 setup scripts to GitHub for CI testing

echo === Quick Push to GitHub for CI Testing ===
echo Repository: https://github.com/startergo/edk2-setup-scripts.git
echo.

REM Check if git is available
git --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Git is not installed or not in PATH
    echo Please install Git from: https://git-scm.com/download/win
    pause
    exit /b 1
)

REM Initialize git if not already done
if not exist ".git" (
    echo Initializing git repository...
    git init
    echo.
)

REM Create .gitignore if it doesn't exist
if not exist ".gitignore" (
    echo Creating .gitignore...
    echo # EDK2 Setup Scripts > .gitignore
    echo. >> .gitignore
    echo # Windows >> .gitignore
    echo Thumbs.db >> .gitignore
    echo Desktop.ini >> .gitignore
    echo *.tmp >> .gitignore
    echo *.log >> .gitignore
    echo. >> .gitignore
    echo # Build outputs >> .gitignore
    echo Build/ >> .gitignore
    echo Conf/ >> .gitignore
    echo.
)

REM Add all files
echo Adding all files to git...
git add .
echo.

REM Commit
echo Creating commit...
git commit -m "Initial commit: EDK2 setup scripts with GitHub Actions CI for ACPIPatcherPkg"
echo.

REM Add remote (remove if exists)
git remote remove origin >nul 2>&1
echo Adding GitHub remote...
git remote add origin https://github.com/startergo/edk2-setup-scripts.git
echo.

REM Set main branch and push
echo Pushing to GitHub...
git branch -M main
git push -u origin main

if %errorlevel% equ 0 (
    echo.
    echo === SUCCESS! ===
    echo.
    echo Your files have been pushed to GitHub!
    echo The CI workflow will start automatically.
    echo.
    echo Check the build status at:
    echo https://github.com/startergo/edk2-setup-scripts/actions
    echo.
    echo The workflow will:
    echo  ✓ Set up Windows environment with Visual Studio, Python, NASM
    echo  ✓ Download EDK2 repository
    echo  ✓ Run your setup-edk2.bat script in CI mode
    echo  ✓ Build BaseTools
    echo  ✓ Build ACPIPatcherPkg
    echo  ✓ Upload build artifacts
    echo.
) else (
    echo.
    echo ERROR: Failed to push to GitHub
    echo Please check your credentials and network connection
    echo.
    echo If this is your first time, you may need to:
    echo 1. Configure git: git config --global user.name "Your Name"
    echo 2. Configure git: git config --global user.email "your.email@example.com"
    echo 3. Authenticate with GitHub (Personal Access Token or SSH key)
    echo.
)

echo Press any key to exit...
pause >nul
