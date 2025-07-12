# GitHub Actions CI Testing Guide

This guide explains how to test the EDK2 setup scripts using GitHub Actions.

## Quick Start

1. **Fork or create a repository** with these scripts
2. **Push to main branch** - The workflow will automatically trigger
3. **Check the Actions tab** in your GitHub repository to see the results

## What the CI Tests

The GitHub Actions workflow (`edk2-setup.yml`) runs three jobs:

### 1. `setup-edk2` Job
- Basic EDK2 setup and build test
- Uses standard EDK2 repository
- Falls back to MdeModulePkg if ACPIPatcherPkg is not found

### 2. `build-acpipatcher` Job  
- Specifically tests ACPIPatcherPkg building
- Checks out ACPIPatcherPkg from Goldfish64/ACPIPatcherPkg
- Builds the complete ACPIPatcherPkg
- Verifies the ACPIPatcher.efi file is created

### 3. `test-different-scenarios` Job
- Tests different script invocation methods:
  - With path argument: `setup-edk2.bat D:\edk2 --ci`
  - CI flag first: `setup-edk2.bat --ci`  
  - Environment variable: `setup-edk2.bat` (with CI=true)

## Monitoring the Build

1. Go to your repository on GitHub
2. Click the **Actions** tab
3. You'll see workflow runs for each push/PR
4. Click on a workflow run to see detailed logs
5. Each job shows step-by-step execution

## Build Artifacts

Successful builds upload artifacts:
- `edk2-build-artifacts`: General EDK2 build outputs
- `acpipatcher-build-artifacts`: ACPIPatcherPkg specific builds

## Triggering Builds

The workflow triggers on:
- **Push** to `main` or `develop` branches
- **Pull requests** to `main` branch
- **Manual trigger** via workflow_dispatch (Actions tab → Run workflow)

## Expected Results

✅ **Successful build** should show:
- All three jobs complete successfully
- BaseTools are built and verified
- ACPIPatcherPkg builds successfully (in dedicated job)
- Build artifacts are uploaded

❌ **Common failures**:
- Missing dependencies (Visual Studio, Python, NASM)
- Build errors in BaseTools
- Missing ACPIPatcherPkg repository access

## Debugging Failed Builds

1. **Check the logs**: Click on failed job → expand failed step
2. **Common issues**:
   - Network timeouts downloading NASM
   - Visual Studio setup issues
   - BaseTools compilation errors
   - Missing submodules

## Local Testing

Before pushing to GitHub, test locally:
```batch
# Test CI mode locally
setup-edk2.bat --ci

# Or use the test script
test-ci-local.bat
```

## Build Status Badge

Add this to your README.md (replace USERNAME/REPO_NAME):
```markdown
[![EDK2 Setup and Build](https://github.com/USERNAME/REPO_NAME/actions/workflows/edk2-setup.yml/badge.svg)](https://github.com/USERNAME/REPO_NAME/actions/workflows/edk2-setup.yml)
```
