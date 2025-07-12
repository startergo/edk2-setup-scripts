# EDK2 Setup CI Integration Guide

This document explains how to integrate the EDK2 setup scripts with various CI/CD platforms.

## Overview

The `setup-edk2.bat` script has been enhanced to support automated CI/CD environments by:

1. **Automatic CI Detection**: Detects common CI environment variables
2. **Non-Interactive Mode**: Disables all interactive prompts when CI is detected
3. **Error Handling**: Provides clear error messages and appropriate exit codes
4. **Flexible Path Handling**: Supports both relative and absolute paths

## CI Environment Detection

The script automatically detects CI environments using these environment variables:

- `GITHUB_ACTIONS` - GitHub Actions
- `SYSTEM_TEAMFOUNDATIONCOLLECTIONURI` - Azure DevOps
- `CI` - Generic CI indicator
- `CONTINUOUS_INTEGRATION` - Generic CI indicator

You can also force CI mode using the `--ci` command line flag.

## GitHub Actions Integration

### Complete Workflow Example

```yaml
name: EDK2 Build

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: windows-latest
    
    steps:
    - name: Checkout Repository
      uses: actions/checkout@v4
      with:
        submodules: true
    
    - name: Checkout ACPIPatcherPkg (if needed)
      uses: actions/checkout@v4
      with:
        repository: Goldfish64/ACPIPatcherPkg
        path: ACPIPatcherPkg
    
    - name: Setup Python
      uses: actions/setup-python@v5
      with:
        python-version: '3.11'
    
    - name: Setup Visual Studio
      uses: microsoft/setup-msbuild@v2
      with:
        vs-version: '17.0'
    
    - name: Install NASM
      run: |
        $nasmUrl = "https://www.nasm.us/pub/nasm/releasebuilds/2.16.01/win64/nasm-2.16.01-win64.zip"
        $nasmZip = "$env:TEMP\nasm.zip"
        $nasmDir = "C:\NASM"
        
        Invoke-WebRequest -Uri $nasmUrl -OutFile $nasmZip
        Expand-Archive -Path $nasmZip -DestinationPath $env:TEMP
        New-Item -ItemType Directory -Path $nasmDir -Force
        Copy-Item -Path "$env:TEMP\nasm-2.16.01\*" -Destination $nasmDir -Recurse -Force
        echo "C:\NASM" | Out-File -FilePath $env:GITHUB_PATH -Encoding utf8 -Append
      shell: pwsh
    
    - name: Setup EDK2 Environment
      run: setup-edk2.bat . --ci
      shell: cmd
    
    - name: Build ACPIPatcherPkg
      run: |
        call edksetup.bat
        build -a X64 -t VS2022 -p ACPIPatcherPkg/ACPIPatcherPkg.dsc
      shell: cmd
```

### Minimal Example

```yaml
- name: Setup EDK2
  run: setup-edk2.bat --ci
  shell: cmd
  env:
    CI: true
```

## Azure DevOps Integration

```yaml
steps:
- task: PowerShell@2
  displayName: 'Install NASM'
  inputs:
    targetType: 'inline'
    script: |
      $nasmUrl = "https://www.nasm.us/pub/nasm/releasebuilds/2.16.01/win64/nasm-2.16.01-win64.zip"
      $nasmZip = "$env:TEMP\nasm.zip"
      $nasmDir = "C:\NASM"
      
      Invoke-WebRequest -Uri $nasmUrl -OutFile $nasmZip
      Expand-Archive -Path $nasmZip -DestinationPath $env:TEMP
      New-Item -ItemType Directory -Path $nasmDir -Force
      Copy-Item -Path "$env:TEMP\nasm-2.16.01\*" -Destination $nasmDir -Recurse -Force
      echo "##vso[task.prependpath]C:\NASM"

- task: CmdLine@2
  displayName: 'Setup EDK2'
  inputs:
    script: 'setup-edk2.bat --ci'

- task: CmdLine@2
  displayName: 'Build EDK2'
  inputs:
    script: |
      call edksetup.bat
      build -a X64 -t VS2022 -p MdeModulePkg/MdeModulePkg.dsc
```

## Jenkins Integration

```groovy
pipeline {
    agent { label 'windows' }
    
    environment {
        CI = 'true'
    }
    
    stages {
        stage('Setup') {
            steps {
                bat 'setup-edk2.bat --ci'
            }
        }
        
        stage('Build') {
            steps {
                bat '''
                call edksetup.bat
                build -a X64 -t VS2022 -p MdeModulePkg/MdeModulePkg.dsc
                '''
            }
        }
    }
}
```

## GitLab CI Integration

```yaml
build:
  stage: build
  tags:
    - windows
  variables:
    CI: "true"
  script:
    - setup-edk2.bat --ci
    - call edksetup.bat
    - build -a X64 -t VS2022 -p MdeModulePkg/MdeModulePkg.dsc
```

## Building Specific Packages

### ACPIPatcherPkg

The ACPIPatcherPkg is a third-party UEFI package that can be built with the standard EDK2 setup:

```yaml
- name: Checkout EDK2 Repository
  uses: actions/checkout@v4
  with:
    repository: tianocore/edk2
    path: edk2
    submodules: true

- name: Checkout ACPIPatcherPkg
  uses: actions/checkout@v4
  with:
    repository: Goldfish64/ACPIPatcherPkg
    path: edk2/ACPIPatcherPkg

- name: Setup EDK2 Environment
  run: |
    cd edk2
    ..\setup-scripts\setup-edk2.bat . --ci
  shell: cmd

- name: Build ACPIPatcherPkg
  run: |
    cd edk2
    call edksetup.bat
    build -a X64 -t VS2022 -p ACPIPatcherPkg/ACPIPatcherPkg.dsc
  shell: cmd
```

### Other Common Packages

```yaml
# OvmfPkg (for QEMU/Virtual Machines)
- name: Build OvmfPkg
  run: |
    call edksetup.bat
    build -a X64 -t VS2022 -p OvmfPkg/OvmfPkgX64.dsc
  shell: cmd

# MdeModulePkg (Core modules)
- name: Build MdeModulePkg
  run: |
    call edksetup.bat
    build -a X64 -t VS2022 -p MdeModulePkg/MdeModulePkg.dsc
  shell: cmd

# EmulatorPkg (for development/testing)
- name: Build EmulatorPkg
  run: |
    call edksetup.bat
    build -a X64 -t VS2022 -p EmulatorPkg/EmulatorPkg.dsc
  shell: cmd
```

## Local CI Testing

To test CI mode locally:

```batch
# Method 1: Use CI flag
setup-edk2.bat --ci

# Method 2: Set environment variable
set CI=true
setup-edk2.bat

# Method 3: Use the example script
ci-example.bat
```

## Troubleshooting CI Issues

### Common Problems

1. **Missing Tools**: Ensure Visual Studio, Python, and NASM are installed
2. **Path Issues**: Use absolute paths when possible
3. **Permissions**: Some operations may require elevated permissions
4. **Submodules**: Ensure git submodules are initialized

### Debug Mode

For debugging CI issues, you can add verbose output by modifying the script temporarily:

```batch
@echo on  # Add this at the top of setup-edk2.bat for verbose output
```

### Error Codes

The script returns these exit codes:
- `0` - Success
- `1` - General error (missing files, build failures, etc.)

### Environment Verification

Add this step to verify the environment before running setup:

```yaml
- name: Verify Environment
  run: |
    echo "Python version:"
    python --version
    echo "VS Installation:"
    dir "C:\Program Files (x86)\Microsoft Visual Studio" /b
    echo "Current directory:"
    dir
  shell: cmd
```

## Best Practices

1. **Cache Dependencies**: Cache NASM and other downloads between builds
2. **Parallel Builds**: Use build system parallelization options
3. **Artifact Management**: Upload build artifacts for debugging
4. **Matrix Builds**: Test multiple configurations (x86, x64, ARM64)
5. **Resource Limits**: Be aware of CI resource limits and timeouts

## Support

For CI-specific issues:
1. Check the GitHub Actions workflow logs
2. Verify all required tools are installed
3. Test locally with `--ci` flag
4. Check environment variables are set correctly
