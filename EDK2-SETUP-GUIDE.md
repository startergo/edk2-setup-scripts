# EDK2 Comprehensive Setup Script (Generalized)

This script provides a complete automated setup for the EDK2 UEFI development environment on Windows.

## Features

- **Auto-Detection**: Automatically detects and configures development tools
- **Multiple Tool Support**: Supports Visual Studio 2019/2022, NASM, Python
- **Flexible Paths**: Works with any EDK2 repository location
- **Comprehensive Setup**: Handles environment variables, BaseTools building, and submodules
- **Build Integration**: Creates convenience scripts for common build tasks

## Prerequisites

1. **Visual Studio 2019 or 2022** with C++ development tools (or Build Tools for Visual Studio)
2. **Python 3.6+** (automatically detected)
3. **NASM assembler** (automatically detected or can be installed to `C:\NASM\`)
4. **Git** (for submodule initialization, optional)

## Usage

### Basic Usage
```batch
# Run from within an EDK2 directory
setup-edk2.bat

# Or specify an EDK2 path
setup-edk2.bat C:\path\to\edk2

# Show help
setup-edk2.bat --help
```

### What the Script Does

1. **Python Detection**: Finds Python interpreter and sets PYTHON_COMMAND
2. **NASM Setup**: Auto-detects NASM in common locations and sets environment variables
3. **Visual Studio Detection**: Finds VS 2019/2022 installations and configures toolchain
4. **Development Tools**: Checks for Cygwin/MSYS2 (optional but recommended)
5. **Environment Variables**: Sets WORKSPACE, EDK_TOOLS_PATH, and other EDK2 variables
6. **Git Submodules**: Initializes submodules if in a git repository (critical for BaseTools)
7. **BaseTools Building**: Compiles BaseTools using nmake or make (if available)
8. **Convenience Scripts**: Creates `build-edk2.bat` for easy future builds

### Output Files

After successful setup, you'll have:

- **Environment variables** set system-wide
- **BaseTools** compiled in `BaseTools\Bin\Win32\`
- **build-edk2.bat** - convenience script for building projects
- **Git submodules** initialized (if applicable)

## Building Projects

### Using the Convenience Script
```batch
# Run the generated build script
build-edk2.bat
```

This will show a menu of available projects to build.

### Manual Building
```batch
# Set up environment
cd C:\path\to\edk2
call edksetup.bat

# Build specific projects
build -a X64 -t VS2019 -p MdeModulePkg\MdeModulePkg.dsc
build -a X64 -t VS2022 -p OvmfPkg\OvmfPkgX64.dsc
build -a X64 -t VS2019 -p ACPIPatcherPkg\ACPIPatcherPkg.dsc
```

## Architecture Support

The script configures for X64 by default, but you can build for other architectures:

- **X64**: `-a X64` (default)
- **IA32**: `-a IA32`
- **ARM**: `-a ARM`
- **AARCH64**: `-a AARCH64`

## Toolchain Support

The script automatically detects and configures:

- **VS2019**: Visual Studio 2019
- **VS2022**: Visual Studio 2022

## Troubleshooting

### BaseTools Build Fails
1. Ensure Visual Studio C++ tools are installed
2. Check that NASM is properly installed
3. Run script as Administrator
4. Check build logs in `BaseTools\Source\C\`

### Environment Variables Not Set
1. Run script as Administrator
2. Restart command prompt/PowerShell after setup
3. Check system environment variables in Windows settings

### Git Submodules Fail
1. Ensure Git is installed and in PATH
2. Check internet connectivity
3. Manually run: `git submodule update --init`

### Python Not Found
1. Install Python 3.6+ from python.org
2. Ensure Python is added to PATH during installation
3. Restart command prompt after Python installation

## Examples

### Setting up a fresh EDK2 clone
```batch
git clone https://github.com/tianocore/edk2.git
cd edk2
setup-edk2.bat
```

### Setting up an existing EDK2 directory
```batch
setup-edk2.bat C:\existing\edk2\path
```

### Testing the Setup from Scratch
To verify the script works in any environment:
```batch
# Create a completely fresh test environment
git clone https://github.com/tianocore/edk2.git edk2-test
cd edk2-test
# Copy your setup script and run it
copy path\to\setup-edk2.bat .
setup-edk2.bat
```

This will show only the standard EDK2 packages in the convenience script menu.

### Adding Custom Packages to Fresh Repository
To test with custom packages:
```batch
# After initial setup, copy custom packages
xcopy /E /I C:\original\edk2\ACPIPatcherPkg C:\edk2-test\ACPIPatcherPkg

# Re-run setup to update the convenience script menu
setup-edk2.bat

# Now ACPIPatcherPkg will appear in the build menu
build-edk2.bat
```

### Building OVMF firmware
```batch
cd C:\edk2
call edksetup.bat
build -a X64 -t VS2019 -p OvmfPkg/OvmfPkgX64.dsc
```

### Building custom packages

**Step 1**: Copy your custom package to the EDK2 repository:
```batch
# Copy your custom package directory to EDK2 root
xcopy /E /I C:\path\to\YourPackage C:\edk2\YourPackage
# Or for ACPIPatcherPkg example:
xcopy /E /I C:\original\edk2\ACPIPatcherPkg C:\fresh\edk2\ACPIPatcherPkg
```

**Step 2**: Build the custom package:
```batch
cd C:\edk2
call edksetup.bat
build -a X64 -t VS2019 -p YourPackage/YourPackage.dsc
```

**Step 3**: Re-run setup script to update convenience menu:
```batch
setup-edk2.bat
```

**Note**: The convenience script automatically detects available packages in your EDK2 repository. Custom packages (like ACPIPatcherPkg) will only appear in the menu if they exist in your specific repository.

## File Locations

After setup:
- **BaseTools**: `BaseTools\Bin\Win32\`
- **Build Output**: `Build\[PackageName]\DEBUG_[Toolchain]\[Arch]\`
- **Log Files**: `Build\BuildReport.txt`, `Build\BuildReport.log`

## Advanced Usage

### Custom Build Configurations
```batch
# Debug build (default)
build -a X64 -t VS2019 -b DEBUG -p Package/Package.dsc

# Release build
build -a X64 -t VS2019 -b RELEASE -p Package/Package.dsc

# Custom target
build -a X64 -t VS2019 -b DEBUG -p Package/Package.dsc -D CUSTOM_FLAG=TRUE
```

### Multiple Architecture Build
```batch
build -a "IA32 X64" -t VS2019 -p Package/Package.dsc
```

This generalized script makes EDK2 setup portable and reusable across different machines and repository locations.
