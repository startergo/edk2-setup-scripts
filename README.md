# EDK2 Setup Scripts

[![EDK2 Setup and Build](https://github.com/startergo/edk2-setup-scripts/actions/workflows/edk2-setup.yml/badge.svg)](https://github.com/startergo/edk2-setup-scripts/actions/workflows/edk2-setup.yml)

This package contains scripts for automated EDK2 UEFI development environment setup on Windows with GitHub Actions CI/CD support.

## Contents

- **`setup-edk2.bat`** - Main setup script (generalized for any EDK2 repository)
- **`ACPIPatcherPkg/`** - Example UEFI ACPI patcher package
- **`.github/workflows/edk2-setup.yml`** - GitHub Actions CI/CD workflow
- **`README.md`** - This file

## Quick Start

1. Copy `setup-edk2.bat` to your EDK2 repository root directory
2. Run: `setup-edk2.bat`
3. Follow the prompts and let it auto-configure your environment

## Features

✅ **Auto-Detection**: Automatically finds and configures Visual Studio, NASM, Python  
✅ **Portable**: Works with any EDK2 repository location  
✅ **Comprehensive**: Handles BaseTools build, git submodules, environment variables  
✅ **Convenient**: Creates build menu scripts for easy project compilation  
✅ **CI/CD Ready**: Supports GitHub Actions and other CI environments with `--ci` flag

## Requirements

- Windows 10/11
- Visual Studio 2019/2022 with C++ tools
- Python 3.6+
- NASM assembler (auto-detected)
- Git (optional, for submodules)

## Usage Examples

### Interactive Setup (Local Development)
```batch
git clone https://github.com/tianocore/edk2.git
cd edk2
copy path\to\setup-edk2.bat .
setup-edk2.bat
```

### CI/Automated Setup (GitHub Actions)
```batch
setup-edk2.bat C:\edk2 --ci
```

### Fresh EDK2 Setup
```batch
git clone https://github.com/tianocore/edk2.git
cd edk2
copy path\to\setup-edk2.bat .
setup-edk2.bat
```

### Existing EDK2 Directory
```batch
setup-edk2.bat C:\existing\edk2\path
```

## CI/CD Integration

The script automatically detects CI environments and disables interactive prompts. Supported CI detection:

- **GitHub Actions**: `GITHUB_ACTIONS` environment variable
- **Azure DevOps**: `SYSTEM_TEAMFOUNDATIONCOLLECTIONURI` environment variable  
- **Generic CI**: `CI` or `CONTINUOUS_INTEGRATION` environment variables
- **Manual**: `--ci` command line flag

### GitHub Actions Example

```yaml
- name: Setup EDK2 Environment
  run: |
    cd edk2
    ..\setup-scripts\setup-edk2.bat . --ci
  shell: cmd
  env:
    CI: true
```

See `.github/workflows/edk2-setup.yml` for a complete GitHub Actions workflow example.

## Command Line Options

```
setup-edk2.bat [EDK2_PATH] [--ci]

EDK2_PATH: Optional path to EDK2 repository
           If not provided, uses current directory or script directory
--ci:      Run in non-interactive CI mode (disables prompts)

Examples:
  setup-edk2.bat                    # Interactive mode, auto-detect path
  setup-edk2.bat C:\edk2            # Interactive mode, specific path
  setup-edk2.bat --ci               # CI mode, auto-detect path
  setup-edk2.bat C:\edk2 --ci       # CI mode, specific path
```

## Validation

These scripts have been tested and validated:
- ✅ Fresh EDK2 repository clone from GitHub
- ✅ BaseTools compilation with git submodules
- ✅ Multiple Visual Studio versions (2019, 2022)
- ✅ Custom package integration (ACPIPatcherPkg example)
- ✅ GitHub Actions CI/CD workflow automation
- ✅ Automated build artifact generation

## Documentation

The repository includes:
- Complete GitHub Actions workflow for automated builds
- ACPIPatcherPkg example for custom UEFI package integration
- CI/CD ready setup script with automatic environment detection

## Support

This script automates the standard EDK2 setup process and has been designed to work across different Windows environments and EDK2 repository configurations.

---
**Generated**: July 12, 2025  
**Tested With**: EDK2 master branch, Visual Studio 2019/2022, Windows 11
