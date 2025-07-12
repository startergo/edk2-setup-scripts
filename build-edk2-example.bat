@echo off 
REM EDK2 Build Environment Setup (Auto-generated) 
setlocal enabledelayedexpansion 
 
cd /d "C:\Users\ivelin\Downloads\edk2" 
 
REM Set environment variables explicitly 
set "WORKSPACE=C:\Users\ivelin\Downloads\edk2" 
set "EDK_TOOLS_PATH=C:\Users\ivelin\Downloads\edk2\BaseTools" 
set "BASE_TOOLS_PATH=C:\Users\ivelin\Downloads\edk2\BaseTools" 
set "EDK_TOOLS_BIN=C:\Users\ivelin\Downloads\edk2\BaseTools\Bin\Win32" 
set "PYTHON_COMMAND=python" 
set "NASM_PREFIX=C:\NASM\" 
 
REM Initialize EDK2 environment 
call edksetup.bat >nul 2>&1 
if !errorlevel! neq 0 ( 
    echo ERROR: Failed to initialize EDK2 environment 
    echo Please check BaseTools installation 
    pause 
    exit /b 1 
) 
 
echo === EDK2 Build Environment Ready === 
echo. 
echo Available Projects: 
echo Available Projects: 
echo   1) Custom command 
echo   2) "ACPIPatcherPkg" (ACPIPatcherPkg.dsc) 
echo   3) "MdeModulePkg" (MdeModulePkg.dsc) 
echo   4) "OvmfPkg" (OvmfPkgIa32.dsc) 
echo   5) "OvmfPkg" (OvmfPkgIa32X64.dsc) 
echo   6) "OvmfPkg" (OvmfPkgX64.dsc) 
echo   7) "OvmfPkg" (OvmfXen.dsc) 
echo   8) "EmulatorPkg" (EmulatorPkg.dsc) 
echo   9) "ArmVirtPkg" (ArmVirtCloudHv.dsc) 
echo   10) "ArmVirtPkg" (ArmVirtKvmTool.dsc) 
echo   11) "ArmVirtPkg" (ArmVirtQemu.dsc) 
echo   12) "ArmVirtPkg" (ArmVirtQemuKernel.dsc) 
echo   13) "ArmVirtPkg" (ArmVirtXen.dsc) 
echo. 
set /p CHOICE="Select project to build (1-14): " 
 
if "%CHOICE%"=="1" ( 
    echo. 
    echo Manual build commands: 
    echo   build -a X64 -t VS2019 -p ACPIPatcherPkg/ACPIPatcherPkg.dsc 
    echo   build -a X64 -t VS2019 -p MdeModulePkg/MdeModulePkg.dsc 
    echo   build -a X64 -t VS2019 -p OvmfPkg/OvmfPkgX64.dsc 
    echo   build --help (for more options) 
    echo. 
) else if "%CHOICE%"=="2" ( 
    echo Building "ACPIPatcherPkg"\ACPIPatcherPkg.dsc for X64... 
    build -a X64 -t VS2019 -p "ACPIPatcherPkg"/ACPIPatcherPkg.dsc 
    if !errorlevel! equ 0 ( 
        echo Build successful! 
        echo Built files in: Build\"ACPIPatcherPkg"\ 
    ) else ( 
        echo Build failed with error !errorlevel! 
    ) 
) else if "%CHOICE%"=="3" ( 
    echo Building "MdeModulePkg"\MdeModulePkg.dsc for X64... 
    build -a X64 -t VS2019 -p "MdeModulePkg"/MdeModulePkg.dsc 
    if !errorlevel! equ 0 ( 
        echo Build successful! 
        echo Built files in: Build\"MdeModulePkg"\ 
    ) else ( 
        echo Build failed with error !errorlevel! 
    ) 
) else if "%CHOICE%"=="4" ( 
    echo Building "OvmfPkg"\OvmfPkgIa32.dsc for X64... 
    build -a X64 -t VS2019 -p "OvmfPkg"/OvmfPkgIa32.dsc 
    if !errorlevel! equ 0 ( 
        echo Build successful! 
        echo Built files in: Build\"OvmfPkg"\ 
    ) else ( 
        echo Build failed with error !errorlevel! 
    ) 
) else if "%CHOICE%"=="5" ( 
    echo Building "OvmfPkg"\OvmfPkgIa32X64.dsc for X64... 
    build -a X64 -t VS2019 -p "OvmfPkg"/OvmfPkgIa32X64.dsc 
    if !errorlevel! equ 0 ( 
        echo Build successful! 
        echo Built files in: Build\"OvmfPkg"\ 
    ) else ( 
        echo Build failed with error !errorlevel! 
    ) 
) else if "%CHOICE%"=="6" ( 
    echo Building "OvmfPkg"\OvmfPkgX64.dsc for X64... 
    build -a X64 -t VS2019 -p "OvmfPkg"/OvmfPkgX64.dsc 
    if !errorlevel! equ 0 ( 
        echo Build successful! 
        echo Built files in: Build\"OvmfPkg"\ 
    ) else ( 
        echo Build failed with error !errorlevel! 
    ) 
) else if "%CHOICE%"=="7" ( 
    echo Building "OvmfPkg"\OvmfXen.dsc for X64... 
    build -a X64 -t VS2019 -p "OvmfPkg"/OvmfXen.dsc 
    if !errorlevel! equ 0 ( 
        echo Build successful! 
        echo Built files in: Build\"OvmfPkg"\ 
    ) else ( 
        echo Build failed with error !errorlevel! 
    ) 
) else if "%CHOICE%"=="8" ( 
    echo Building "EmulatorPkg"\EmulatorPkg.dsc for X64... 
    build -a X64 -t VS2019 -p "EmulatorPkg"/EmulatorPkg.dsc 
    if !errorlevel! equ 0 ( 
        echo Build successful! 
        echo Built files in: Build\"EmulatorPkg"\ 
    ) else ( 
        echo Build failed with error !errorlevel! 
    ) 
) else if "%CHOICE%"=="9" ( 
    echo Building "ArmVirtPkg"\ArmVirtCloudHv.dsc for X64... 
    build -a X64 -t VS2019 -p "ArmVirtPkg"/ArmVirtCloudHv.dsc 
    if !errorlevel! equ 0 ( 
        echo Build successful! 
        echo Built files in: Build\"ArmVirtPkg"\ 
    ) else ( 
        echo Build failed with error !errorlevel! 
    ) 
) else if "%CHOICE%"=="10" ( 
    echo Building "ArmVirtPkg"\ArmVirtKvmTool.dsc for X64... 
    build -a X64 -t VS2019 -p "ArmVirtPkg"/ArmVirtKvmTool.dsc 
    if !errorlevel! equ 0 ( 
        echo Build successful! 
        echo Built files in: Build\"ArmVirtPkg"\ 
    ) else ( 
        echo Build failed with error !errorlevel! 
    ) 
) else if "%CHOICE%"=="11" ( 
    echo Building "ArmVirtPkg"\ArmVirtQemu.dsc for X64... 
    build -a X64 -t VS2019 -p "ArmVirtPkg"/ArmVirtQemu.dsc 
    if !errorlevel! equ 0 ( 
        echo Build successful! 
        echo Built files in: Build\"ArmVirtPkg"\ 
    ) else ( 
        echo Build failed with error !errorlevel! 
    ) 
) else if "%CHOICE%"=="12" ( 
    echo Building "ArmVirtPkg"\ArmVirtQemuKernel.dsc for X64... 
    build -a X64 -t VS2019 -p "ArmVirtPkg"/ArmVirtQemuKernel.dsc 
    if !errorlevel! equ 0 ( 
        echo Build successful! 
        echo Built files in: Build\"ArmVirtPkg"\ 
    ) else ( 
        echo Build failed with error !errorlevel! 
    ) 
) else if "%CHOICE%"=="13" ( 
    echo Building "ArmVirtPkg"\ArmVirtXen.dsc for X64... 
    build -a X64 -t VS2019 -p "ArmVirtPkg"/ArmVirtXen.dsc 
    if !errorlevel! equ 0 ( 
        echo Build successful! 
        echo Built files in: Build\"ArmVirtPkg"\ 
    ) else ( 
        echo Build failed with error !errorlevel! 
    ) 
) else ( 
    echo Invalid choice: %CHOICE% 
    echo Please select a number between 1 and 14 
) 
 
echo. 
echo Build completed. Press any key to exit or close window... 
pause >nul 
