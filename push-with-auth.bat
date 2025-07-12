@echo off
REM GitHub Push Script with Authentication Handling
REM This script helps with GitHub authentication and pushing

echo === GitHub Push for EDK2 Setup Scripts ===
echo Repository: https://github.com/startergo/edk2-setup-scripts.git
echo.

REM Check if git is available
git --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Git is not installed or not in PATH
    pause
    exit /b 1
)

REM Check if we're in a git repository
if not exist ".git" (
    echo Initializing git repository...
    git init
    echo.
)

REM Configure git if not already done
git config user.name >nul 2>&1
if %errorlevel% neq 0 (
    echo Setting up git configuration...
    set /p username="Enter your GitHub username: "
    set /p email="Enter your email: "
    git config --global user.name "!username!"
    git config --global user.email "!email!"
    echo.
)

REM Create .gitignore if needed
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

echo Adding files to git...
git add .

echo Creating commit...
git commit -m "Initial commit: EDK2 setup scripts with GitHub Actions CI for ACPIPatcherPkg"

REM Remove existing remote if present
git remote remove origin >nul 2>&1

echo Adding GitHub remote...
git remote add origin https://github.com/startergo/edk2-setup-scripts.git

echo Setting main branch...
git branch -M main

echo.
echo === Pushing to GitHub ===
echo.
echo If this is your first time pushing to GitHub, you may see a browser window
echo for authentication. Please sign in to GitHub when prompted.
echo.
echo If you see a localhost URL like http://127.0.0.1:51573/?code=...
echo this is normal - it means authentication was successful.
echo.

REM Try to push
git push -u origin main

if %errorlevel% equ 0 (
    echo.
    echo === SUCCESS! Files pushed to GitHub ===
    echo.
    echo Your repository: https://github.com/startergo/edk2-setup-scripts
    echo Actions page: https://github.com/startergo/edk2-setup-scripts/actions
    echo.
    echo The CI workflow should start automatically!
    echo Check the Actions tab to see the build progress.
    echo.
) else (
    echo.
    echo === Push failed or authentication needed ===
    echo.
    echo If authentication failed, try one of these options:
    echo.
    echo Option 1: Use GitHub CLI
    echo   1. Install GitHub CLI: https://cli.github.com/
    echo   2. Run: gh auth login
    echo   3. Run this script again
    echo.
    echo Option 2: Use Personal Access Token
    echo   1. Go to GitHub Settings ^> Developer settings ^> Personal access tokens
    echo   2. Generate new token with 'repo' scope
    echo   3. Use token as password when prompted
    echo.
    echo Option 3: Use SSH
    echo   1. Set up SSH key: https://docs.github.com/en/authentication/connecting-to-github-with-ssh
    echo   2. Change remote to SSH: git remote set-url origin git@github.com:startergo/edk2-setup-scripts.git
    echo   3. Run: git push -u origin main
    echo.
)

echo Press any key to exit...
pause >nul
