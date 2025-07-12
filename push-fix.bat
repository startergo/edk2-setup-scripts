@echo off
REM Quick fix and push to test BaseTools build

echo === Pushing BaseTools fix to GitHub ===
echo.

cd "c:\Users\ivelin\Downloads\edk2-setup-scripts"

echo Adding changes...
git add -A

echo Committing fix...
git commit -m "Fix BaseTools build issue in CI - add manual build step and debug output"

echo Pushing to GitHub...
git push

if %errorlevel% equ 0 (
    echo.
    echo === Fix pushed successfully! ===
    echo.
    echo Check the workflow at:
    echo https://github.com/startergo/edk2-setup-scripts/actions
    echo.
    echo The fix includes:
    echo  - Better error handling and debug output
    echo  - Manual BaseTools build step as fallback
    echo  - More detailed logging
    echo.
) else (
    echo Push failed - check git status
)

echo Press any key to exit...
pause >nul
