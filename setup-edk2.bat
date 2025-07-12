@echo off
REM EDK2 Comprehensive Setup Script (Generalized Version)
REM This script sets up the complete EDK2 environment for any EDK2 repository
REM Usage: setup-edk2.bat [EDK2_PATH] [--ci]
REM   If EDK2_PATH is not provided, uses current directory or script directory
REM   Use --ci flag for non-interactive CI mode

setlocal enabledelayedexpansion

REM Detect CI environment (GitHub Actions, Azure DevOps, etc.)
set "IS_CI=0"
if defined GITHUB_ACTIONS set "IS_CI=1"
if defined SYSTEM_TEAMFOUNDATIONCOLLECTIONURI set "IS_CI=1"
if defined CI set "IS_CI=1"
if defined CONTINUOUS_INTEGRATION set "IS_CI=1"
if "%~2"=="--ci" set "IS_CI=1"
if "%~1"=="--ci" set "IS_CI=1"

if "%IS_CI%"=="1" (
    echo Running in CI mode - interactive prompts disabled
) else (
    echo Running in interactive mode
)

echo === EDK2 Comprehensive Setup Script (Generalized) ===
echo Starting EDK2 environment setup...
echo.
echo This script will:
echo  1. Auto-detect and configure NASM assembler
echo  2. Find and configure Visual Studio 2019/2022
echo  3. Check for development tools (Cygwin/MSYS2)
echo  4. Detect Python interpreter
echo  5. Set EDK2 environment variables
echo  6. Initialize git submodules (if applicable)
echo  7. Build BaseTools from source
echo  8. Create convenience build scripts
echo.
echo Requirements:
echo  - Visual Studio 2019/2022 with C++ tools or Build Tools
echo  - Python 3.6+
echo  - NASM assembler (will be auto-detected)
echo.
if "%~1"=="--help" (
    echo Usage: %~nx0 [EDK2_PATH] [--ci]
    echo   EDK2_PATH: Optional path to EDK2 repository
    echo              If not provided, uses current directory or script directory
    echo   --ci:      Run in non-interactive CI mode (disables prompts)
    echo.
    echo Examples:
    echo   %~nx0
    echo   %~nx0 C:\edk2
    echo   %~nx0 D:\projects\edk2-clean
    echo   %~nx0 --ci                    ^(CI mode^)
    echo   %~nx0 C:\edk2 --ci            ^(CI mode with path^)
    goto end
)
echo.

REM Determine EDK2 root directory
REM Parse arguments to handle --ci flag anywhere
set "PROVIDED_PATH="
for %%a in (%*) do (
    if /i not "%%a"=="--ci" (
        if not defined PROVIDED_PATH set "PROVIDED_PATH=%%a"
    )
)

if "%PROVIDED_PATH%"=="" (
    REM No path argument provided, check if we're in an EDK2 directory
    if exist "%CD%\edksetup.bat" (
        set "EDK2_ROOT=%CD%"
        echo Using current directory as EDK2 root
    ) else if exist "%~dp0edksetup.bat" (
        REM Use script directory
        set "EDK2_ROOT=%~dp0"
        set "EDK2_ROOT=!EDK2_ROOT:~0,-1!"
        echo Using script directory as EDK2 root
    ) else (
        echo ERROR: Cannot find EDK2 repository!
        echo Please run this script from an EDK2 directory or provide the path as argument
        echo Usage: %~nx0 [EDK2_PATH] [--ci]
        if "%IS_CI%"=="0" pause
        goto end
    )
) else (
    REM Use provided path
    set "EDK2_ROOT=%PROVIDED_PATH%"
    if not exist "!EDK2_ROOT!\edksetup.bat" (
        echo ERROR: Invalid EDK2 path provided: !EDK2_ROOT!
        echo edksetup.bat not found in the specified directory
        if "%IS_CI%"=="0" pause
        goto end
    )
    echo Using provided EDK2 path
)

set "BASETOOLS_PATH=%EDK2_ROOT%\BaseTools"
echo EDK2 Root: %EDK2_ROOT%

call :detect_python
call :check_nasm
call :check_vs
call :check_cygwin
call :set_edk2_vars
call :init_submodules
call :build_basetools
call :create_convenience_script
goto summary

REM Function to detect Python interpreter
:detect_python
echo.
echo === Python Detection ===
set "PYTHON_CMD="

REM Try different Python commands in order of preference
for %%P in ("python" "py" "python3" "py -3") do (
    %%P --version >nul 2>&1
    if !errorlevel! equ 0 (
        set "PYTHON_CMD=%%~P"
        echo Found Python: %%~P
        goto python_found
    )
)

echo WARNING: Python not found in PATH
echo Please install Python 3.6+ and ensure it's in your PATH
echo Download from: https://www.python.org/downloads/
goto python_found

:python_found
if defined PYTHON_CMD (
    setx PYTHON_COMMAND "%PYTHON_CMD%" >nul 2>&1
    if !errorlevel! neq 0 (
        echo WARNING: Could not set system PYTHON_COMMAND variable (requires admin rights)
    )
    echo Set PYTHON_COMMAND=%PYTHON_CMD%
)
exit /b

REM Function to check if NASM exists
:check_nasm
echo.
echo === Step 1: NASM Setup ===
set "NASM_FOUND=0"

REM Check common NASM locations
if exist "C:\NASM\nasm.exe" (
    set "NASM_DIR=C:\NASM"
    set "NASM_FOUND=1"
    echo Found NASM at: C:\NASM
    goto nasm_found
)

if exist "C:\Program Files\NASM\nasm.exe" (
    set "NASM_DIR=C:\Program Files\NASM"
    set "NASM_FOUND=1"
    echo Found NASM at: C:\Program Files\NASM
    goto nasm_found
)

if exist "C:\Program Files (x86)\NASM\nasm.exe" (
    set "NASM_DIR=C:\Program Files (x86)\NASM"
    set "NASM_FOUND=1"
    echo Found NASM at: C:\Program Files (x86)\NASM
    goto nasm_found
)

REM Check if NASM is in PATH
nasm -v >nul 2>&1
if !errorlevel! equ 0 (
    for %%i in (nasm.exe) do set "NASM_DIR=%%~dpi"
    set "NASM_DIR=!NASM_DIR:~0,-1!"
    set "NASM_FOUND=1"
    echo Found NASM in PATH: !NASM_DIR!
    goto nasm_found
)

echo WARNING: NASM not found. Please install NASM manually and place it in C:\NASM
echo Download from: https://www.nasm.us/pub/nasm/releasebuilds/
echo.
if "%IS_CI%"=="0" (
    echo Press any key to continue without NASM...
    pause >nul
)
exit /b

:nasm_found
REM Set NASM environment variables
echo Setting NASM_PREFIX environment variable...
setx NASM_PREFIX "%NASM_DIR%\" >nul 2>&1
if !errorlevel! neq 0 (
    echo WARNING: Could not set system NASM_PREFIX variable (requires admin rights)
    echo Setting user-level NASM_PREFIX instead...
    setx NASM_PREFIX "%NASM_DIR%\" >nul 2>&1
)
set "NASM_PREFIX=%NASM_DIR%\"

REM Add NASM to PATH if not already there
echo %PATH% | find /i "%NASM_DIR%" >nul
if !errorlevel! neq 0 (
    echo Adding NASM to PATH...
    setx PATH "%PATH%;%NASM_DIR%" >nul 2>&1
    if !errorlevel! neq 0 (
        echo WARNING: Could not modify system PATH (requires admin rights)
        echo NASM directory: %NASM_DIR%
        echo Please add this to your PATH manually or run script as Administrator
    )
)

echo NASM setup complete!
exit /b

:check_vs
echo.
echo === Step 2: Visual Studio Setup ===

REM Check for Visual Studio installations (2019, 2022, Build Tools)
set "VS_FOUND=0"
set "VS_VERSIONS=2022 2019"
set "VS_EDITIONS=Enterprise Professional Community BuildTools"

for %%V in (%VS_VERSIONS%) do (
    for %%E in (%VS_EDITIONS%) do (
        if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\%%V\%%E\Common7\IDE\devenv.exe" (
            set "VS_PATH=%ProgramFiles(x86)%\Microsoft Visual Studio\%%V\%%E"
            set "VS_FOUND=1"
            echo Found Visual Studio %%V %%E
            goto vs_found
        )
        REM Also check for Build Tools which don't have devenv.exe
        if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\%%V\%%E\VC\Auxiliary\Build\vcvars32.bat" (
            set "VS_PATH=%ProgramFiles(x86)%\Microsoft Visual Studio\%%V\%%E"
            set "VS_FOUND=1"
            echo Found Visual Studio %%V %%E Build Tools
            goto vs_found
        )
    )
)

REM Try using vswhere for any version
if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" (
    for /f "tokens=*" %%i in ('"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -version "[16.0,)" -property installationPath') do (
        if exist "%%i\VC\Auxiliary\Build\vcvars32.bat" (
            set "VS_PATH=%%i"
            set "VS_FOUND=1"
            echo Found Visual Studio using vswhere: %%i
            goto vs_found
        )
    )
)

echo WARNING: Visual Studio not found!
echo Please install Visual Studio 2019/2022 with C++ development tools or Build Tools
echo Download from: https://visualstudio.microsoft.com/downloads/
echo.
if "%IS_CI%"=="0" (
    echo Press any key to continue without Visual Studio...
    pause >nul
)
exit /b

:vs_found
REM Determine VS toolchain version
set "VS_TOOLCHAIN=VS2019"
echo "%VS_PATH%" | find "2022" >nul
if !errorlevel! equ 0 set "VS_TOOLCHAIN=VS2022"

echo Visual Studio setup complete! Using toolchain: %VS_TOOLCHAIN%
exit /b

:check_cygwin
echo.
echo === Step 3: Development Tools Check ===

set "CYGWIN_FOUND=0"
set "MSYS2_FOUND=0"

REM Check for Cygwin
for %%D in ("C:\cygwin64" "C:\cygwin" "%USERPROFILE%\cygwin64" "%USERPROFILE%\cygwin") do (
    if exist "%%D\bin\bash.exe" (
        set "CYGWIN_HOME=%%D"
        set "CYGWIN_FOUND=1"
        echo Found Cygwin at: %%D
        goto cygwin_found
    )
)

REM Check for MSYS2
for %%D in ("C:\msys64" "C:\msys32" "%USERPROFILE%\msys64" "%USERPROFILE%\msys32") do (
    if exist "%%D\usr\bin\bash.exe" (
        set "MSYS2_HOME=%%D"
        set "MSYS2_FOUND=1"
        echo Found MSYS2 at: %%D
        goto msys2_found
    )
)

echo INFO: Neither Cygwin nor MSYS2 found. Using Windows native tools only.
echo Consider installing MSYS2 for better compatibility: https://www.msys2.org/
exit /b

:cygwin_found
echo Setting CYGWIN_HOME environment variable...
setx CYGWIN_HOME "%CYGWIN_HOME%" >nul 2>&1
if !errorlevel! neq 0 (
    echo WARNING: Could not set system CYGWIN_HOME variable (requires admin rights)
)

REM Add Cygwin to PATH if not already there
echo %PATH% | find /i "%CYGWIN_HOME%\bin" >nul
if !errorlevel! neq 0 (
    echo Adding Cygwin to PATH...
    setx PATH "%PATH%;%CYGWIN_HOME%\bin" >nul 2>&1
    if !errorlevel! neq 0 (
        echo WARNING: Could not modify PATH (requires admin rights)
        echo Cygwin directory: %CYGWIN_HOME%\bin
        echo Please add this to your PATH manually or run script as Administrator
    )
)
echo Cygwin setup complete!
exit /b

:msys2_found
echo Setting MSYS2_HOME environment variable...
setx MSYS2_HOME "%MSYS2_HOME%" >nul 2>&1
if !errorlevel! neq 0 (
    echo WARNING: Could not set system MSYS2_HOME variable (requires admin rights)
)
echo MSYS2 setup complete!
exit /b

:set_edk2_vars
echo.
echo === Step 4: EDK2 Environment Variables ===

echo Setting EDK2 environment variables...
setx WORKSPACE "%EDK2_ROOT%" >nul 2>&1
setx EDK_TOOLS_PATH "%BASETOOLS_PATH%" >nul 2>&1  
setx BASE_TOOLS_PATH "%BASETOOLS_PATH%" >nul 2>&1

if !errorlevel! neq 0 (
    echo WARNING: Could not set system environment variables (requires admin rights)
    echo Setting user-level environment variables instead...
    setx WORKSPACE "%EDK2_ROOT%" >nul 2>&1
    setx EDK_TOOLS_PATH "%BASETOOLS_PATH%" >nul 2>&1
    setx BASE_TOOLS_PATH "%BASETOOLS_PATH%" >nul 2>&1
)

echo EDK2 environment variables set!
exit /b

:build_basetools
echo.
echo === Step 6: Building BaseTools ===

cd /d "%EDK2_ROOT%"

REM Check if critical submodules are available before building
if not exist "%EDK2_ROOT%\BaseTools\Source\C\BrotliCompress\brotli\c\include\brotli\encode.h" (
    echo WARNING: Brotli submodule not found or incomplete!
    echo This is required for BaseTools compilation.
    if exist "%EDK2_ROOT%\.git" (
        echo Attempting to initialize submodules...
        git submodule update --init
    ) else (
        echo ERROR: Not a git repository and Brotli submodule missing!
        echo Please manually extract Brotli library to BaseTools\Source\C\BrotliCompress\brotli\
        if "%IS_CI%"=="0" pause
        goto end
    )
)

REM First try using make with Cygwin (preferred method)
if defined CYGWIN_HOME (
    echo Attempting to build BaseTools using Cygwin make...
    
    REM Check if make exists
    if exist "%CYGWIN_HOME%\bin\make.exe" (
        echo Found make.exe in Cygwin
        
        REM Convert Windows path to Cygwin path format
        set "CYGWIN_EDK2_PATH=!EDK2_ROOT!"
        set "CYGWIN_EDK2_PATH=!CYGWIN_EDK2_PATH:\=/!"
        set "CYGWIN_EDK2_PATH=!CYGWIN_EDK2_PATH:C:=/cygdrive/c!"
        set "CYGWIN_EDK2_PATH=!CYGWIN_EDK2_PATH:D:=/cygdrive/d!"
        set "CYGWIN_EDK2_PATH=!CYGWIN_EDK2_PATH:E:=/cygdrive/e!"
        
        REM Try building with make using proper environment
        "%CYGWIN_HOME%\bin\bash.exe" -l -c "cd !CYGWIN_EDK2_PATH! && make -C BaseTools"
        
        if !errorlevel! equ 0 (
            echo BaseTools built successfully with make!
            goto verify_basetools
        ) else (
            echo Warning: Cygwin make failed with error !errorlevel!, trying Windows nmake fallback...
        )
    ) else (
        echo Make not found in Cygwin, trying Windows nmake fallback...
    )
)

REM Fallback to Windows nmake method
echo Setting up Visual Studio environment and building with nmake...
set "VSCMD_ARG_TGT_ARCH=x86"
call "%VS_PATH%\VC\Auxiliary\Build\vcvars32.bat" >nul 2>&1

REM Set required environment variables for EDK2
set "EDK_TOOLS_PATH=%BASETOOLS_PATH%"
set "BASE_TOOLS_PATH=%BASETOOLS_PATH%"
if defined PYTHON_CMD set "PYTHON_COMMAND=%PYTHON_CMD%"

echo Building BaseTools with nmake...
cd /d "%BASETOOLS_PATH%\Source\C"

REM Build antlr and dlg first to ensure they're available
echo Building antlr and dlg tools first...
cd /d "%BASETOOLS_PATH%\Source\C\VfrCompile\Pccts\antlr"
nmake -f AntlrMS.mak >nul 2>&1
cd /d "%BASETOOLS_PATH%\Source\C\VfrCompile\Pccts\dlg"
nmake -f DlgMS.mak >nul 2>&1

REM Return to BaseTools\Source\C and build everything
cd /d "%BASETOOLS_PATH%\Source\C"

REM Add BaseTools\Bin\Win32 to PATH for antlr.exe during build
set "ORIGINAL_PATH=%PATH%"
set "PATH=%BASETOOLS_PATH%\Bin\Win32;%PATH%"

nmake -f Makefile

REM Restore original PATH
set "PATH=%ORIGINAL_PATH%"

if !errorlevel! neq 0 (
    echo ERROR: BaseTools build failed with nmake!
    echo.
    echo Troubleshooting suggestions:
    echo 1. Install Cygwin with make package for better compatibility
    echo 2. Ensure Visual Studio 2019 C++ tools are installed
    echo 3. Check that NASM is properly installed
    echo 4. Check if antlr.exe exists in %BASETOOLS_PATH%\Bin\Win32\
    if "%IS_CI%"=="0" pause
    goto end
)

echo BaseTools built successfully with nmake!

:verify_basetools

REM Verify BaseTools were created
set "BASETOOLS_BIN=%BASETOOLS_PATH%\Bin\Win32"
set "REQUIRED_TOOLS=GenFv.exe GenFfs.exe GenFw.exe GenSec.exe"

echo Verifying essential BaseTools...
set "MISSING_TOOLS="
for %%T in (%REQUIRED_TOOLS%) do (
    if not exist "%BASETOOLS_BIN%\%%T" (
        set "MISSING_TOOLS=!MISSING_TOOLS! %%T"
    ) else (
        echo   Found: %%T
    )
)

if defined MISSING_TOOLS (
    echo ERROR: Required BaseTools missing:!MISSING_TOOLS!
    echo.
    echo Troubleshooting:
    echo 1. Check if Visual Studio C++ tools are properly installed
    echo 2. Ensure NASM is in PATH or at C:\NASM\
    echo 3. Try running this script as Administrator
    echo 4. Check build logs in %BASETOOLS_PATH%\Source\C\
    if "%IS_CI%"=="0" pause
    goto end
)

echo BaseTools built and verified successfully!
exit /b

:init_submodules
echo.
echo === Step 5: Git Submodules ===

REM Check if this is a git repository
if exist "%EDK2_ROOT%\.git" (
    echo Checking git submodules...
    
    REM Check if submodules are initialized
    git -C "%EDK2_ROOT%" submodule status | find "^-" >nul
    if !errorlevel! equ 0 (
        echo Found uninitialized submodules. Initializing...
        git -C "%EDK2_ROOT%" submodule update --init
        if !errorlevel! equ 0 (
            echo Git submodules initialized successfully!
        ) else (
            echo WARNING: Failed to initialize git submodules
            echo You may need to run: git submodule update --init
        )
    ) else (
        echo Git submodules already initialized.
    )
) else (
    echo Not a git repository, skipping submodule initialization.
)
exit /b

:create_convenience_script
echo.
echo === Step 7: Creating Convenience Scripts ===

REM Create a convenience script for future builds
set "BUILD_SCRIPT=%EDK2_ROOT%\build-edk2.bat"

echo @echo off > "%BUILD_SCRIPT%"
echo REM EDK2 Build Environment Setup (Auto-generated) >> "%BUILD_SCRIPT%"
echo setlocal enabledelayedexpansion >> "%BUILD_SCRIPT%"
echo. >> "%BUILD_SCRIPT%"
echo cd /d "%EDK2_ROOT%" >> "%BUILD_SCRIPT%"
echo. >> "%BUILD_SCRIPT%"
echo REM Set environment variables explicitly >> "%BUILD_SCRIPT%"
echo set "WORKSPACE=%EDK2_ROOT%" >> "%BUILD_SCRIPT%"
echo set "EDK_TOOLS_PATH=%BASETOOLS_PATH%" >> "%BUILD_SCRIPT%"
echo set "BASE_TOOLS_PATH=%BASETOOLS_PATH%" >> "%BUILD_SCRIPT%"
echo set "EDK_TOOLS_BIN=%BASETOOLS_PATH%\Bin\Win32" >> "%BUILD_SCRIPT%"
if defined PYTHON_CMD echo set "PYTHON_COMMAND=%PYTHON_CMD%" >> "%BUILD_SCRIPT%"
if defined NASM_PREFIX echo set "NASM_PREFIX=%NASM_PREFIX%" >> "%BUILD_SCRIPT%"
echo. >> "%BUILD_SCRIPT%"
echo REM Initialize EDK2 environment >> "%BUILD_SCRIPT%"
echo call edksetup.bat ^>nul 2^>^&1 >> "%BUILD_SCRIPT%"
echo if ^^!errorlevel^^! neq 0 ( >> "%BUILD_SCRIPT%"
echo     echo ERROR: Failed to initialize EDK2 environment >> "%BUILD_SCRIPT%"
echo     echo Please check BaseTools installation >> "%BUILD_SCRIPT%"
echo     pause >> "%BUILD_SCRIPT%"
echo     exit /b 1 >> "%BUILD_SCRIPT%"
echo ^) >> "%BUILD_SCRIPT%"
echo. >> "%BUILD_SCRIPT%"
echo echo === EDK2 Build Environment Ready === >> "%BUILD_SCRIPT%"
echo echo. >> "%BUILD_SCRIPT%"
echo echo Available Projects: >> "%BUILD_SCRIPT%"

REM Scan for available .dsc files and create menu options
set "MENU_OPTION=1"

echo echo Available Projects: >> "%BUILD_SCRIPT%"
echo echo   1^) Custom command >> "%BUILD_SCRIPT%"
set /a MENU_OPTION+=1

REM Look for common packages and create simple if-else structure
for %%P in ("ACPIPatcherPkg" "MdeModulePkg" "OvmfPkg" "EmulatorPkg" "ArmVirtPkg") do (
    if exist "%EDK2_ROOT%\%%P" (
        for %%F in ("%EDK2_ROOT%\%%P\*.dsc") do (
            set "DSC_FILE=%%~nxF"
            echo echo   !MENU_OPTION!^) %%P ^(!DSC_FILE!^) >> "%BUILD_SCRIPT%"
            set /a MENU_OPTION+=1
        )
    )
)

echo echo. >> "%BUILD_SCRIPT%"
echo set /p CHOICE="Select project to build (1-!MENU_OPTION!): " >> "%BUILD_SCRIPT%"
echo. >> "%BUILD_SCRIPT%"

echo if "%%CHOICE%%"=="1" ( >> "%BUILD_SCRIPT%"
echo     echo. >> "%BUILD_SCRIPT%"
echo     echo Manual build commands: >> "%BUILD_SCRIPT%"
if exist "%EDK2_ROOT%\ACPIPatcherPkg\ACPIPatcherPkg.dsc" (
    echo     echo   build -a X64 -t %VS_TOOLCHAIN% -p ACPIPatcherPkg/ACPIPatcherPkg.dsc >> "%BUILD_SCRIPT%"
)
echo     echo   build -a X64 -t %VS_TOOLCHAIN% -p MdeModulePkg/MdeModulePkg.dsc >> "%BUILD_SCRIPT%"
echo     echo   build -a X64 -t %VS_TOOLCHAIN% -p OvmfPkg/OvmfPkgX64.dsc >> "%BUILD_SCRIPT%"
echo     echo   build --help ^(for more options^) >> "%BUILD_SCRIPT%"
echo     echo. >> "%BUILD_SCRIPT%"

REM Add individual build commands for each option
set "CHOICE_NUM=2"
for %%P in ("ACPIPatcherPkg" "MdeModulePkg" "OvmfPkg" "EmulatorPkg" "ArmVirtPkg") do (
    if exist "%EDK2_ROOT%\%%P" (
        for %%F in ("%EDK2_ROOT%\%%P\*.dsc") do (
            echo ^) else if "%%CHOICE%%"=="!CHOICE_NUM!" ^( >> "%BUILD_SCRIPT%"
            echo     echo Building %%P\%%~nxF for X64... >> "%BUILD_SCRIPT%"
            echo     build -a X64 -t %VS_TOOLCHAIN% -p %%P/%%~nxF >> "%BUILD_SCRIPT%"
            echo     if ^^!errorlevel^^! equ 0 ( >> "%BUILD_SCRIPT%"
            echo         echo Build successful^^! >> "%BUILD_SCRIPT%"
            echo         echo Built files in: Build\%%P\ >> "%BUILD_SCRIPT%"
            echo     ^) else ( >> "%BUILD_SCRIPT%"
            echo         echo Build failed with error ^^!errorlevel^^! >> "%BUILD_SCRIPT%"
            echo     ^) >> "%BUILD_SCRIPT%"
            set /a CHOICE_NUM+=1
        )
    )
)

echo ^) else ( >> "%BUILD_SCRIPT%"
echo     echo Invalid choice: %%CHOICE%% >> "%BUILD_SCRIPT%"
echo     echo Please select a number between 1 and !MENU_OPTION! >> "%BUILD_SCRIPT%"
echo ^) >> "%BUILD_SCRIPT%"
echo. >> "%BUILD_SCRIPT%"
echo echo. >> "%BUILD_SCRIPT%"
echo echo Build completed. Press any key to exit or close window... >> "%BUILD_SCRIPT%"
echo pause ^>nul >> "%BUILD_SCRIPT%"

echo Created convenience script: %BUILD_SCRIPT%
exit /b

:summary
echo.
echo === EDK2 Setup Complete! ===
echo.
echo Repository: %EDK2_ROOT%
echo Toolchain: %VS_TOOLCHAIN%
echo.
echo Environment variables set:
echo   WORKSPACE = %EDK2_ROOT%
echo   EDK_TOOLS_PATH = %BASETOOLS_PATH%
if defined NASM_PREFIX echo   NASM_PREFIX = %NASM_PREFIX%
if defined CYGWIN_HOME echo   CYGWIN_HOME = %CYGWIN_HOME%
if defined MSYS2_HOME echo   MSYS2_HOME = %MSYS2_HOME%
if defined PYTHON_CMD echo   PYTHON_COMMAND = %PYTHON_CMD%
echo.
echo Usage:
echo   1. Run convenience script: %BUILD_SCRIPT%
echo   2. Manual setup: cd "%EDK2_ROOT%" ^&^& edksetup.bat
echo   3. Build example: build -a X64 -t %VS_TOOLCHAIN% -p MdeModulePkg/MdeModulePkg.dsc
echo.
if "%IS_CI%"=="0" (
    echo Press any key to exit...
    pause >nul
) else (
    echo Setup completed in CI mode.
)

:end
endlocal
