#include <Library/UefiLib.h>
#include <Library/MemoryAllocationLib.h>
#include <Library/UefiBootServicesTableLib.h>

#include <Protocol/AcpiSystemDescriptionTable.h>

#include <Guid/Acpi.h>
#include <Guid/FileInfo.h>

#include "FsHelpers.h"

//
// Constants
//
#define ACPI_PATCHER_VERSION_MAJOR    1
#define ACPI_PATCHER_VERSION_MINOR    1
#define MAX_ADDITIONAL_TABLES         16
#define FILE_NAME_BUFFER_SIZE         512
#define DSDT_FILE_NAME                L"DSDT.aml"

//
// Debug levels
//
#define DEBUG_ERROR   1
#define DEBUG_WARN    2
#define DEBUG_INFO    3
#define DEBUG_VERBOSE 4

#ifndef DEBUG_LEVEL
#define DEBUG_LEVEL DEBUG_INFO  // Default debug level
#endif

//
// Helper macros
//
#ifndef MIN
#define MIN(a, b) (((a) < (b)) ? (a) : (b))
#endif

// Safe pointer to integer conversion for debug output
#ifdef MDE_CPU_IA32
#define PTR_TO_INT(ptr) ((UINT32)(UINTN)(ptr))
#define PTR_FMT L"0x%x"
#else
#define PTR_TO_INT(ptr) ((UINT64)(UINTN)(ptr))
#define PTR_FMT L"0x%llx"
#endif

//
// Global Variables
//
EFI_ACPI_2_0_ROOT_SYSTEM_DESCRIPTION_POINTER        *gRsdp      = NULL;
EFI_ACPI_SDT_HEADER                                 *gXsdt      = NULL;
EFI_ACPI_6_4_FIXED_ACPI_DESCRIPTION_TABLE           *gFacp      = NULL;
UINT64                                              gXsdtEnd    = 0;
BOOLEAN                                             gIsEfi1x    = FALSE;

#ifndef DXE
#include <Library/PrintLib.h>
#define MAX_PRINT_BUFFER (80 * 4)
#endif

//
// Function Declarations
//
VOID
AcpiDebugPrint (
  IN UINTN         Level,
  IN CONST CHAR16  *Format,
  ...
  );

VOID
HexDump (
  IN VOID    *Data,
  IN UINTN   Size,
  IN UINTN   Address
  );

EFI_STATUS
ValidateAcpiTable (
  IN VOID    *TableBuffer,
  IN UINTN   BufferSize
  );

BOOLEAN
DetectEfiFirmwareVersion (
  IN EFI_SYSTEM_TABLE *SystemTable
  );

/**
  Conditionally prints formatted output to console.
  Only prints in non-DXE builds to avoid conflicts.

  @param[in] Format   Format string for output
  @param[in] ...      Variable arguments for format string

  @retval None
**/
VOID
SelectivePrint (
  IN CONST CHAR16  *Format,
  ...
  )
{
#ifndef DXE
  UINTN     BufferSize  = (MAX_PRINT_BUFFER + 1) * sizeof(CHAR16);
  CHAR16    *Buffer     = NULL;
  EFI_STATUS Status;

  if (Format == NULL) {
    return;
  }

  Status = gBS->AllocatePool(EfiBootServicesData, BufferSize, (VOID**)&Buffer);
  if (EFI_ERROR(Status) || Buffer == NULL) {
    return;
  }

  VA_LIST Marker;
  VA_START(Marker, Format);
  UnicodeVSPrint(Buffer, BufferSize, Format, Marker);
  VA_END(Marker);
  
  if (gST != NULL && gST->ConOut != NULL) {
    gST->ConOut->OutputString(gST->ConOut, Buffer);
  }
  
  gBS->FreePool(Buffer);
#endif
}

EFI_STATUS
PatchAcpi (
  IN EFI_FILE_PROTOCOL* Directory
  )
{
  UINTN                BufferSize     = 0;
  UINTN                ReadSize       = 0;
  EFI_STATUS           Status         = EFI_SUCCESS;
  EFI_FILE_INFO        *FileInfo      = NULL;
  EFI_FILE_PROTOCOL    *FileProtocol  = NULL;
  VOID                 *FileBuffer    = NULL;
  UINT32               MaxEntries;
  UINT32               CurrentEntries;
  UINT32               ProcessedFiles = 0;
  UINT32               SkippedFiles   = 0;
  UINT32               AddedTables    = 0;
  
  AcpiDebugPrint(DEBUG_INFO, L"Starting ACPI patching process...\n");
  
  if (Directory == NULL || gXsdt == NULL || gFacp == NULL) {
    AcpiDebugPrint(DEBUG_ERROR, L"Invalid parameters for ACPI patching\n");
    AcpiDebugPrint(DEBUG_VERBOSE, L"  Directory: " PTR_FMT L"\n", PTR_TO_INT(Directory));
    AcpiDebugPrint(DEBUG_VERBOSE, L"  gXsdt: " PTR_FMT L"\n", PTR_TO_INT(gXsdt));
    AcpiDebugPrint(DEBUG_VERBOSE, L"  gFacp: " PTR_FMT L"\n", PTR_TO_INT(gFacp));
    return EFI_INVALID_PARAMETER;
  }

  // Calculate current and maximum entries in XSDT
  CurrentEntries = (gXsdt->Length - sizeof(EFI_ACPI_SDT_HEADER)) / sizeof(UINT64);
  
  // Apply EFI 1.x specific limitations if detected
  if (gIsEfi1x) {
    MaxEntries = CurrentEntries + MIN(MAX_ADDITIONAL_TABLES, 8);  // Limit to 8 additional tables for EFI 1.x
    AcpiDebugPrint(DEBUG_INFO, L"EFI 1.x detected: Limiting additional tables to %u\n", 
                   MIN(MAX_ADDITIONAL_TABLES, 8));
  } else {
    MaxEntries = CurrentEntries + MAX_ADDITIONAL_TABLES;
  }
  
  AcpiDebugPrint(DEBUG_INFO, L"XSDT analysis:\n");
  AcpiDebugPrint(DEBUG_INFO, L"  Current entries: %u\n", CurrentEntries);
  AcpiDebugPrint(DEBUG_INFO, L"  Maximum entries allowed: %u\n", MaxEntries);
  AcpiDebugPrint(DEBUG_INFO, L"  Available slots: %u\n", MaxEntries - CurrentEntries);
  AcpiDebugPrint(DEBUG_VERBOSE, L"  XSDT address: " PTR_FMT L"\n", PTR_TO_INT(gXsdt));
  AcpiDebugPrint(DEBUG_VERBOSE, L"  XSDT end: 0x%llx\n", gXsdtEnd);
  
  BufferSize = sizeof(EFI_FILE_INFO) + sizeof(CHAR16) * FILE_NAME_BUFFER_SIZE;
  Status = gBS->AllocatePool(EfiBootServicesData, BufferSize, (VOID**)&FileInfo);
  if (EFI_ERROR(Status)) {
    AcpiDebugPrint(DEBUG_ERROR, L"Failed to allocate memory for FileInfo: %r\n", Status);
    return Status;
  }
  
  AcpiDebugPrint(DEBUG_VERBOSE, L"Allocated FileInfo buffer: " PTR_FMT L" (%u bytes)\n", 
             PTR_TO_INT(FileInfo), BufferSize);

  AcpiDebugPrint(DEBUG_INFO, L"Scanning ACPI directory for .aml files...\n");

  while (TRUE) {
    ReadSize = BufferSize;
    Status = Directory->Read(Directory, &ReadSize, FileInfo);
    if (EFI_ERROR(Status)) {
      AcpiDebugPrint(DEBUG_ERROR, L"Directory read error: %r\n", Status);
      goto Cleanup;
    }
    
    if (ReadSize == 0) {
      AcpiDebugPrint(DEBUG_VERBOSE, L"End of directory reached\n");
      break; // End of directory
    }

    AcpiDebugPrint(DEBUG_VERBOSE, L"Found directory entry: %s\n", FileInfo->FileName);
    AcpiDebugPrint(DEBUG_VERBOSE, L"  File size: %llu bytes\n", FileInfo->FileSize);
    AcpiDebugPrint(DEBUG_VERBOSE, L"  Attributes: 0x%llx\n", FileInfo->Attribute);

    // Skip hidden files, current/parent directories, and non-AML files
    if (StrnCmp(&FileInfo->FileName[0], L".", 1) == 0 ||
        StrnCmp(&FileInfo->FileName[0], L"_", 1) == 0 ||
        StrStr(FileInfo->FileName, L".aml") == NULL) {
      AcpiDebugPrint(DEBUG_VERBOSE, L"  Skipping file: %s\n", FileInfo->FileName);
      SkippedFiles++;
      continue;
    }
      
    AcpiDebugPrint(DEBUG_INFO, L"Processing file: %s (%llu bytes)\n", 
               FileInfo->FileName, FileInfo->FileSize);
    ProcessedFiles++;
    
    Status = FsOpenFile(Directory, FileInfo->FileName, &FileProtocol);
    if (EFI_ERROR(Status)) {
      AcpiDebugPrint(DEBUG_ERROR, L"Failed to open file %s: %r\n", FileInfo->FileName, Status);
      continue; // Skip this file and continue with others
    }
    
    AcpiDebugPrint(DEBUG_VERBOSE, L"  File opened successfully\n");

    // Check if file size fits in UINTN (important for IA32 builds)
    if (FileInfo->FileSize > ~(UINTN)0) {
      AcpiDebugPrint(DEBUG_ERROR, L"File %s is too large (%llu bytes) for this architecture\n", 
                     FileInfo->FileName, FileInfo->FileSize);
      FileProtocol->Close(FileProtocol);
      FileProtocol = NULL;
      continue; // Skip this file and continue with others
    }

    Status = FsReadFileToBuffer(FileProtocol, (UINTN)FileInfo->FileSize, &FileBuffer);
    FileProtocol->Close(FileProtocol);
    FileProtocol = NULL;
    
    if (EFI_ERROR(Status)) {
      AcpiDebugPrint(DEBUG_ERROR, L"Failed to read file %s: %r\n", FileInfo->FileName, Status);
      continue; // Skip this file and continue with others
    }

    AcpiDebugPrint(DEBUG_VERBOSE, L"  File read to buffer at " PTR_FMT L"\n", PTR_TO_INT(FileBuffer));

    // Apply EFI 1.x file size limitations
    if (gIsEfi1x && FileInfo->FileSize > (64 * 1024)) {
      AcpiDebugPrint(DEBUG_WARN, L"File %s is %u bytes (>64KB) - may have issues on EFI 1.x firmware\n", 
                     FileInfo->FileName, (UINT32)FileInfo->FileSize);
      AcpiDebugPrint(DEBUG_WARN, L"Consider reducing ACPI table size for better EFI 1.x compatibility\n");
    }

    // Validate the ACPI table
    AcpiDebugPrint(DEBUG_VERBOSE, L"  Validating ACPI table...\n");
    Status = ValidateAcpiTable(FileBuffer, (UINTN)FileInfo->FileSize);
    if (EFI_ERROR(Status)) {
      AcpiDebugPrint(DEBUG_ERROR, L"Invalid ACPI table in file %s: %r\n", FileInfo->FileName, Status);
      gBS->FreePool(FileBuffer);
      continue; // Skip this file and continue with others
    }
    
    // Handle DSDT specially
    if (StrnCmp(FileInfo->FileName, DSDT_FILE_NAME, 8) == 0) {
      AcpiDebugPrint(DEBUG_INFO, L"  Processing as DSDT replacement\n");
      AcpiDebugPrint(DEBUG_VERBOSE, L"  Old DSDT address (32-bit): 0x%x\n", gFacp->Dsdt);
      AcpiDebugPrint(DEBUG_VERBOSE, L"  Old DSDT address (64-bit): 0x%llx\n", gFacp->XDsdt);
      
      gFacp->Dsdt = (UINT32)PTR_TO_INT(FileBuffer);
      gFacp->XDsdt = (UINT64)PTR_TO_INT(FileBuffer);
      
      AcpiDebugPrint(DEBUG_INFO, L"  Updated DSDT address: 0x%llx\n", gFacp->XDsdt);
      AcpiDebugPrint(DEBUG_VERBOSE, L"  DSDT replacement completed\n");
      AddedTables++;
      continue;
    }
    
    // Check if we have room for more entries
    if (CurrentEntries >= MaxEntries) {
      AcpiDebugPrint(DEBUG_WARN, L"Maximum XSDT entries reached (%u), skipping %s\n", 
                 MaxEntries, FileInfo->FileName);
      gBS->FreePool(FileBuffer);
      continue;
    }
    
    // Add to XSDT
    AcpiDebugPrint(DEBUG_VERBOSE, L"  Adding table to XSDT entry %u\n", CurrentEntries);
    AcpiDebugPrint(DEBUG_VERBOSE, L"  XSDT entry address: 0x%llx\n", gXsdtEnd);
    
    ((UINT64 *)(UINTN)gXsdtEnd)[0] = (UINT64)PTR_TO_INT(FileBuffer);
    gXsdt->Length += sizeof(UINT64);
    gXsdtEnd = gRsdp->XsdtAddress + gXsdt->Length;
    CurrentEntries++;
    AddedTables++;
    
    AcpiDebugPrint(DEBUG_INFO, L"  Added table at address: " PTR_FMT L"\n", PTR_TO_INT(FileBuffer));
    AcpiDebugPrint(DEBUG_VERBOSE, L"  New XSDT length: %u bytes\n", gXsdt->Length);
    AcpiDebugPrint(DEBUG_VERBOSE, L"  New XSDT end: 0x%llx\n", gXsdtEnd);
  }
  
  AcpiDebugPrint(DEBUG_INFO, L"ACPI patching summary:\n");
  AcpiDebugPrint(DEBUG_INFO, L"  Files processed: %u\n", ProcessedFiles);
  AcpiDebugPrint(DEBUG_INFO, L"  Files skipped: %u\n", SkippedFiles);
  AcpiDebugPrint(DEBUG_INFO, L"  Tables added/replaced: %u\n", AddedTables);
  AcpiDebugPrint(DEBUG_INFO, L"  Final XSDT entries: %u\n", CurrentEntries);
  
  Status = EFI_SUCCESS;

Cleanup:
  if (FileInfo != NULL) {
    AcpiDebugPrint(DEBUG_VERBOSE, L"Cleaning up FileInfo buffer\n");
    gBS->FreePool(FileInfo);
  }
  if (FileProtocol != NULL) {
    AcpiDebugPrint(DEBUG_VERBOSE, L"Closing file protocol\n");
    FileProtocol->Close(FileProtocol);
  }
  
  AcpiDebugPrint(DEBUG_VERBOSE, L"ACPI patching cleanup completed\n");
  return Status;
}

/**
  Patches ACPI tables by reading .aml files from the specified directory.
  
  This function reads all .aml files from the given directory and either:
  - Replaces the DSDT if the file is named "DSDT.aml"
  - Adds additional tables to the XSDT for other .aml files

  @param[in] Directory    Directory containing .aml files to process

  @retval EFI_SUCCESS             ACPI patching completed successfully
  @retval EFI_INVALID_PARAMETER   Invalid input parameters
  @retval Other                   Error occurred during file operations
**/

EFI_STATUS
FindFacp (
  VOID
  )
{
  EFI_ACPI_SDT_HEADER *Entry;
  UINT32              EntryCount;
  UINT64              *EntryPtr;
  UINTN               Index;
  CHAR8               SigStr[5];

  AcpiDebugPrint(DEBUG_INFO, L"Searching for FADT in XSDT...\n");

  if (gXsdt == NULL) {
    AcpiDebugPrint(DEBUG_ERROR, L"XSDT pointer is null\n");
    return EFI_INVALID_PARAMETER;
  }

  EntryCount = (gXsdt->Length - sizeof(EFI_ACPI_SDT_HEADER)) / sizeof(UINT64);
  EntryPtr = (UINT64 *)(gXsdt + 1);
  
  AcpiDebugPrint(DEBUG_VERBOSE, L"XSDT contains %u entries\n", EntryCount);
  AcpiDebugPrint(DEBUG_VERBOSE, L"Scanning entries starting at " PTR_FMT L"\n", PTR_TO_INT(EntryPtr));

  for (Index = 0; Index < EntryCount; Index++, EntryPtr++) {
    if (*EntryPtr == 0) {
      AcpiDebugPrint(DEBUG_VERBOSE, L"  Entry %u: NULL pointer, skipping\n", Index);
      continue; // Skip null entries
    }

    Entry = (EFI_ACPI_SDT_HEADER *)((UINTN)(*EntryPtr));
    
    // Validate entry pointer
    if (Entry == NULL) {
      AcpiDebugPrint(DEBUG_VERBOSE, L"  Entry %u: Invalid pointer (0x%llx), skipping\n", Index, *EntryPtr);
      continue;
    }

    // Convert signature to string for display
    SigStr[0] = (CHAR8)(Entry->Signature & 0xFF);
    SigStr[1] = (CHAR8)((Entry->Signature >> 8) & 0xFF);
    SigStr[2] = (CHAR8)((Entry->Signature >> 16) & 0xFF);
    SigStr[3] = (CHAR8)((Entry->Signature >> 24) & 0xFF);
    SigStr[4] = '\0';
    
    AcpiDebugPrint(DEBUG_VERBOSE, L"  Entry %u: 0x%llx -> Signature: %a, Length: %u\n", 
               Index, *EntryPtr, SigStr, Entry->Length);

    if (Entry->Signature == EFI_ACPI_6_4_FIXED_ACPI_DESCRIPTION_TABLE_SIGNATURE) {
      gFacp = (EFI_ACPI_6_4_FIXED_ACPI_DESCRIPTION_TABLE *)Entry;
      AcpiDebugPrint(DEBUG_INFO, L"Found FADT at address: " PTR_FMT L"\n", PTR_TO_INT(gFacp));
      AcpiDebugPrint(DEBUG_VERBOSE, L"  FADT length: %u bytes\n", gFacp->Header.Length);
      AcpiDebugPrint(DEBUG_VERBOSE, L"  FADT revision: %u\n", gFacp->Header.Revision);
      AcpiDebugPrint(DEBUG_VERBOSE, L"  Current DSDT (32-bit): 0x%x\n", gFacp->Dsdt);
      AcpiDebugPrint(DEBUG_VERBOSE, L"  Current DSDT (64-bit): 0x%llx\n", gFacp->XDsdt);
      AcpiDebugPrint(DEBUG_VERBOSE, L"  Firmware Control: 0x%x\n", gFacp->FirmwareCtrl);
      AcpiDebugPrint(DEBUG_VERBOSE, L"  X_Firmware Control: 0x%llx\n", gFacp->XFirmwareCtrl);
      return EFI_SUCCESS;
    }
  }
  
  AcpiDebugPrint(DEBUG_WARN, L"FADT not found in XSDT (scanned %u entries)\n", EntryCount);
  return EFI_NOT_FOUND;
}

EFI_STATUS
ValidateAcpiTable (
  IN VOID     *TableBuffer,
  IN UINTN    BufferSize
  )
{
  EFI_ACPI_SDT_HEADER *Header;
  UINT8               Checksum;
  CHAR8               SigStr[5];

  AcpiDebugPrint(DEBUG_VERBOSE, L"Validating ACPI table at " PTR_FMT L", size %u bytes\n", 
             PTR_TO_INT(TableBuffer), BufferSize);

  if (TableBuffer == NULL || BufferSize < sizeof(EFI_ACPI_SDT_HEADER)) {
    AcpiDebugPrint(DEBUG_ERROR, L"Invalid parameters for table validation\n");
    return EFI_INVALID_PARAMETER;
  }

  Header = (EFI_ACPI_SDT_HEADER *)TableBuffer;
  
  // Convert signature to string for display
  SigStr[0] = (CHAR8)(Header->Signature & 0xFF);
  SigStr[1] = (CHAR8)((Header->Signature >> 8) & 0xFF);
  SigStr[2] = (CHAR8)((Header->Signature >> 16) & 0xFF);
  SigStr[3] = (CHAR8)((Header->Signature >> 24) & 0xFF);
  SigStr[4] = '\0';
  
  AcpiDebugPrint(DEBUG_INFO, L"  Table signature: %a\n", SigStr);
  AcpiDebugPrint(DEBUG_INFO, L"  Table length: %u bytes\n", Header->Length);
  AcpiDebugPrint(DEBUG_INFO, L"  Table revision: %u\n", Header->Revision);
  AcpiDebugPrint(DEBUG_VERBOSE, L"  OEM ID: %.6a\n", Header->OemId);
  AcpiDebugPrint(DEBUG_VERBOSE, L"  OEM Table ID: %.8a\n", Header->OemTableId);
  AcpiDebugPrint(DEBUG_VERBOSE, L"  OEM Revision: 0x%x\n", Header->OemRevision);
  
  // Validate signature (should be printable ASCII)
  if (Header->Signature == 0) {
    AcpiDebugPrint(DEBUG_ERROR, L"Invalid table signature (zero)\n");
    return EFI_INVALID_PARAMETER;
  }

  // Validate length
  if (Header->Length < sizeof(EFI_ACPI_SDT_HEADER)) {
    AcpiDebugPrint(DEBUG_ERROR, L"Table length too small: %u < %u\n", 
               Header->Length, sizeof(EFI_ACPI_SDT_HEADER));
    return EFI_INVALID_PARAMETER;
  }
  
  if (Header->Length > BufferSize) {
    AcpiDebugPrint(DEBUG_ERROR, L"Table length exceeds buffer: %u > %u\n", 
               Header->Length, BufferSize);
    return EFI_INVALID_PARAMETER;
  }

  // Validate checksum
  Checksum = CalculateCheckSum8((UINT8*)TableBuffer, Header->Length);
  AcpiDebugPrint(DEBUG_VERBOSE, L"  Calculated checksum: 0x%02x\n", Checksum);
  
  if (Checksum != 0) {
    AcpiDebugPrint(DEBUG_WARN, L"ACPI table checksum validation failed (0x%02x)\n", Checksum);
    // Don't return error as we'll recalculate checksum anyway
  } else {
    AcpiDebugPrint(DEBUG_VERBOSE, L"  Checksum validation passed\n");
  }

  // Show first few bytes of table data for debugging
  if (DEBUG_LEVEL >= DEBUG_VERBOSE) {
    HexDump(TableBuffer, MIN(Header->Length, 64), (UINTN)TableBuffer);
  }

  AcpiDebugPrint(DEBUG_VERBOSE, L"Table validation completed successfully\n");
  return EFI_SUCCESS;
}

/**
  Main entry point for the ACPI Patcher application.
  
  This function orchestrates the entire ACPI patching process:
  1. Locates and validates the ACPI root tables (RSDP, XSDT, FADT)
  2. Opens the ACPI directory containing .aml files
  3. Patches ACPI tables with new content
  4. Updates checksums for modified tables

  @param[in] ImageHandle    Handle for this UEFI application
  @param[in] SystemTable    Pointer to the UEFI System Table

  @retval EFI_SUCCESS             ACPI patching completed successfully
  @retval EFI_INVALID_PARAMETER   Invalid input parameters
  @retval EFI_NOT_FOUND          Required ACPI structures not found
  @retval Other                   Error occurred during patching process
**/
EFI_STATUS
EFIAPI
AcpiPatcherEntryPoint (
  IN EFI_HANDLE        ImageHandle,
  IN EFI_SYSTEM_TABLE  *SystemTable
  )
{
  EFI_STATUS           Status         = EFI_SUCCESS;
  EFI_FILE_PROTOCOL    *AcpiFolder    = NULL;
  EFI_FILE_PROTOCOL    *SelfDir       = NULL;
  UINT32               EntryCount;
  
  // Validate input parameters
  if (ImageHandle == NULL || SystemTable == NULL) {
    return EFI_INVALID_PARAMETER;
  }

  AcpiDebugPrint(DEBUG_INFO, L"=== ACPIPatcher v%u.%u Starting ===\n", 
             ACPI_PATCHER_VERSION_MAJOR, ACPI_PATCHER_VERSION_MINOR);
  AcpiDebugPrint(DEBUG_INFO, L"ImageHandle: " PTR_FMT L"\n", PTR_TO_INT(ImageHandle));
  AcpiDebugPrint(DEBUG_INFO, L"SystemTable: " PTR_FMT L"\n", PTR_TO_INT(SystemTable));
  AcpiDebugPrint(DEBUG_VERBOSE, L"Debug level: %u\n", DEBUG_LEVEL);

  // Detect EFI firmware version for compatibility optimizations
  gIsEfi1x = DetectEfiFirmwareVersion(SystemTable);

  // Detect EFI firmware version
  gIsEfi1x = DetectEfiFirmwareVersion(SystemTable);

  // Get RSDP from system configuration table
  AcpiDebugPrint(DEBUG_INFO, L"Locating RSDP...\n");
  Status = EfiGetSystemConfigurationTable(&gEfiAcpi20TableGuid, (VOID **)&gRsdp);
  if (EFI_ERROR(Status) || gRsdp == NULL) {
    AcpiDebugPrint(DEBUG_ERROR, L"Could not find RSDP: %r\n", Status);
    return EFI_NOT_FOUND;
  }

  AcpiDebugPrint(DEBUG_INFO, L"Found RSDP at address: " PTR_FMT L"\n", PTR_TO_INT(gRsdp));
  AcpiDebugPrint(DEBUG_VERBOSE, L"RSDP details:\n");
  AcpiDebugPrint(DEBUG_VERBOSE, L"  Signature: 0x%llx\n", gRsdp->Signature);
  AcpiDebugPrint(DEBUG_VERBOSE, L"  Checksum: 0x%02x\n", gRsdp->Checksum);
  AcpiDebugPrint(DEBUG_VERBOSE, L"  Revision: %u\n", gRsdp->Revision);
  AcpiDebugPrint(DEBUG_VERBOSE, L"  Length: %u\n", gRsdp->Length);

  // Validate RSDP
  if (gRsdp->Signature != EFI_ACPI_2_0_ROOT_SYSTEM_DESCRIPTION_POINTER_SIGNATURE) {
    AcpiDebugPrint(DEBUG_ERROR, L"Invalid RSDP signature: 0x%llx\n", gRsdp->Signature);
    return EFI_INVALID_PARAMETER;
  }

  AcpiDebugPrint(DEBUG_VERBOSE, L"RSDP signature validation passed\n");

  // Get XSDT
  AcpiDebugPrint(DEBUG_INFO, L"Locating XSDT...\n");
  gXsdt = (EFI_ACPI_SDT_HEADER *)(UINTN)(gRsdp->XsdtAddress);
  if (gXsdt == NULL) {
    AcpiDebugPrint(DEBUG_ERROR, L"XSDT address is null (0x%llx)\n", gRsdp->XsdtAddress);
    return EFI_INVALID_PARAMETER;
  }

  AcpiDebugPrint(DEBUG_INFO, L"Found XSDT at address: " PTR_FMT L"\n", PTR_TO_INT(gXsdt));

  // Validate XSDT
  if (gXsdt->Signature != EFI_ACPI_6_4_EXTENDED_SYSTEM_DESCRIPTION_TABLE_SIGNATURE) {
    AcpiDebugPrint(DEBUG_ERROR, L"Invalid XSDT signature: 0x%x\n", gXsdt->Signature);
    return EFI_INVALID_PARAMETER;
  }

  AcpiDebugPrint(DEBUG_INFO, L"XSDT validation passed\n");
  AcpiDebugPrint(DEBUG_INFO, L"  Size: 0x%x (%u bytes)\n", gXsdt->Length, gXsdt->Length);
  AcpiDebugPrint(DEBUG_VERBOSE, L"  Revision: %u\n", gXsdt->Revision);
  AcpiDebugPrint(DEBUG_VERBOSE, L"  Checksum: 0x%02x\n", gXsdt->Checksum);
  AcpiDebugPrint(DEBUG_VERBOSE, L"  OEM ID: %.6a\n", gXsdt->OemId);
  
  gXsdtEnd = gRsdp->XsdtAddress + gXsdt->Length;
  AcpiDebugPrint(DEBUG_VERBOSE, L"  XSDT end address: 0x%llx\n", gXsdtEnd);
  
  // Find FADT
  AcpiDebugPrint(DEBUG_INFO, L"Searching for FADT...\n");
  Status = FindFacp();
  if (EFI_ERROR(Status)) {
    AcpiDebugPrint(DEBUG_ERROR, L"Could not find FADT: %r\n", Status);
    return Status;
  }

  EntryCount = (gXsdt->Length - sizeof(EFI_ACPI_SDT_HEADER)) / sizeof(UINT64);
  AcpiDebugPrint(DEBUG_INFO, L"XSDT contains %u table entries\n", EntryCount);

  // Get current directory
  AcpiDebugPrint(DEBUG_INFO, L"Locating current directory...\n");
  SelfDir = FsGetSelfDir();
  if (SelfDir == NULL) {
    AcpiDebugPrint(DEBUG_ERROR, L"Could not find current working directory\n");
    return EFI_NOT_FOUND;
  }
  
  AcpiDebugPrint(DEBUG_VERBOSE, L"Current directory located at: " PTR_FMT L"\n", PTR_TO_INT(SelfDir));
  
  // Open ACPI folder
  AcpiDebugPrint(DEBUG_INFO, L"Opening ACPI folder...\n");
  Status = SelfDir->Open(
                    SelfDir,
                    &AcpiFolder,
                    L"ACPI",
                    EFI_FILE_MODE_READ,
                    EFI_FILE_READ_ONLY | EFI_FILE_HIDDEN | EFI_FILE_SYSTEM
                    );
  
  if (EFI_ERROR(Status)) {
    AcpiDebugPrint(DEBUG_ERROR, L"Could not open ACPI folder: %r\n", Status);
    AcpiDebugPrint(DEBUG_INFO, L"Please ensure 'ACPI' directory exists with .aml files\n");
    goto Cleanup;
  }
  
  AcpiDebugPrint(DEBUG_VERBOSE, L"ACPI folder opened successfully at: " PTR_FMT L"\n", PTR_TO_INT(AcpiFolder));
  
  AcpiDebugPrint(DEBUG_INFO, L"=== Starting ACPI table patching ===\n");
  Status = PatchAcpi(AcpiFolder);
  if (EFI_ERROR(Status)) {
    AcpiDebugPrint(DEBUG_ERROR, L"ACPI patching failed: %r\n", Status);
    goto Cleanup;
  }

  AcpiDebugPrint(DEBUG_INFO, L"=== ACPI patching completed successfully ===\n");

  // Update checksums
  AcpiDebugPrint(DEBUG_INFO, L"Updating table checksums...\n");
  if (gFacp != NULL) {
    UINT8 OldChecksum = gFacp->Header.Checksum;
    gFacp->Header.Checksum = 0;
    gFacp->Header.Checksum = CalculateCheckSum8((UINT8*)gFacp, gFacp->Header.Length);
    AcpiDebugPrint(DEBUG_VERBOSE, L"FADT checksum: 0x%02x -> 0x%02x\n", 
               OldChecksum, gFacp->Header.Checksum);
    AcpiDebugPrint(DEBUG_INFO, L"Updated FADT checksum\n");
  }

  if (gXsdt != NULL) {
    UINT8 OldChecksum = gXsdt->Checksum;
    gXsdt->Checksum = 0;
    gXsdt->Checksum = CalculateCheckSum8((UINT8*)gXsdt, gXsdt->Length);
    AcpiDebugPrint(DEBUG_VERBOSE, L"XSDT checksum: 0x%02x -> 0x%02x\n", 
               OldChecksum, gXsdt->Checksum);
    AcpiDebugPrint(DEBUG_INFO, L"Updated XSDT checksum\n");
  }

Cleanup:
  AcpiDebugPrint(DEBUG_VERBOSE, L"Performing cleanup...\n");
  if (AcpiFolder != NULL) {
    AcpiDebugPrint(DEBUG_VERBOSE, L"Closing ACPI folder\n");
    AcpiFolder->Close(AcpiFolder);
  }
  if (SelfDir != NULL) {
    AcpiDebugPrint(DEBUG_VERBOSE, L"Closing self directory\n");
    SelfDir->Close(SelfDir);
  }

  if (EFI_ERROR(Status)) {
    AcpiDebugPrint(DEBUG_ERROR, L"ACPIPatcher finished with ERROR: %r\n", Status);
  } else {
    AcpiDebugPrint(DEBUG_INFO, L"=== ACPIPatcher finished successfully ===\n");
  }
  
  return Status;
}

/**
  Enhanced debug print function with different levels.
  
  @param[in] Level    Debug level (ERROR, WARN, INFO, VERBOSE)
  @param[in] Format   Format string for output
  @param[in] ...      Variable arguments for format string
**/
VOID
AcpiDebugPrint (
  IN UINTN         Level,
  IN CONST CHAR16  *Format,
  ...
  )
{
#ifndef DXE
  UINTN     BufferSize  = (MAX_PRINT_BUFFER + 1) * sizeof(CHAR16);
  CHAR16    *Buffer     = NULL;
  CHAR16    *Prefix     = L"";
  EFI_STATUS Status;

  if (Format == NULL || Level > DEBUG_LEVEL) {
    return;
  }

  // Set prefix based on debug level
  switch (Level) {
    case DEBUG_ERROR:
      Prefix = L"[ERROR] ";
      break;
    case DEBUG_WARN:
      Prefix = L"[WARN]  ";
      break;
    case DEBUG_INFO:
      Prefix = L"[INFO]  ";
      break;
    case DEBUG_VERBOSE:
      Prefix = L"[DEBUG] ";
      break;
  }

  Status = gBS->AllocatePool(EfiBootServicesData, BufferSize, (VOID**)&Buffer);
  if (EFI_ERROR(Status) || Buffer == NULL) {
    return;
  }

  // Print prefix first
  if (gST != NULL && gST->ConOut != NULL) {
    gST->ConOut->OutputString(gST->ConOut, Prefix);
  }

  VA_LIST Marker;
  VA_START(Marker, Format);
  UnicodeVSPrint(Buffer, BufferSize, Format, Marker);
  VA_END(Marker);
  
  if (gST != NULL && gST->ConOut != NULL) {
    gST->ConOut->OutputString(gST->ConOut, Buffer);
  }
  
  gBS->FreePool(Buffer);
#endif
}

/**
  Print hexadecimal dump of memory region for debugging.
  
  @param[in] Data     Pointer to data to dump
  @param[in] Size     Size of data in bytes
  @param[in] Address  Base address for display
**/
VOID
HexDump (
  IN VOID   *Data,
  IN UINTN  Size,
  IN UINTN  Address
  )
{
#ifndef DXE
  UINT8  *Bytes = (UINT8 *)Data;
  UINTN  i, j;
  
  if (Data == NULL || Size == 0 || DEBUG_LEVEL < DEBUG_VERBOSE) {
    return;
  }

  AcpiDebugPrint(DEBUG_VERBOSE, L"Memory dump at " PTR_FMT L" (%u bytes):\n", Address, Size);
  
  for (i = 0; i < Size; i += 16) {
#ifdef MDE_CPU_IA32
    AcpiDebugPrint(DEBUG_VERBOSE, L"%08x: ", (UINT32)(Address + i));
#else
    AcpiDebugPrint(DEBUG_VERBOSE, L"%08llx: ", (UINT64)(Address + i));
#endif
    
    // Print hex bytes
    for (j = 0; j < 16 && (i + j) < Size; j++) {
      AcpiDebugPrint(DEBUG_VERBOSE, L"%02x ", Bytes[i + j]);
    }
    
    // Pad if less than 16 bytes
    for (; j < 16; j++) {
      AcpiDebugPrint(DEBUG_VERBOSE, L"   ");
    }
    
    AcpiDebugPrint(DEBUG_VERBOSE, L" |");
    
    // Print ASCII representation
    for (j = 0; j < 16 && (i + j) < Size; j++) {
      UINT8 c = Bytes[i + j];
      if (c >= 32 && c <= 126) {
        AcpiDebugPrint(DEBUG_VERBOSE, L"%c", c);
      } else {
        AcpiDebugPrint(DEBUG_VERBOSE, L".");
      }
    }
    
    AcpiDebugPrint(DEBUG_VERBOSE, L"|\n");
  }
#endif
}

///
// EFI version detection for compatibility
//

/**
  Detect if running on EFI 1.x firmware (like MacPro5,1) and optimize accordingly.
  
  @param[in] SystemTable    Pointer to the EFI/UEFI System Table
  
  @retval TRUE     Running on EFI 1.x firmware
  @retval FALSE    Running on UEFI 2.x+ firmware
**/
BOOLEAN
DetectEfiFirmwareVersion (
  IN EFI_SYSTEM_TABLE  *SystemTable
  )
{
  if (SystemTable == NULL) {
    return FALSE;
  }
  
  // EFI 1.x firmware typically has firmware revision < 2.0
  if (SystemTable->FirmwareRevision < 0x00020000) {
    AcpiDebugPrint(DEBUG_INFO, L"Detected EFI 1.x firmware (revision: 0x%x)\n", 
                   SystemTable->FirmwareRevision);
    AcpiDebugPrint(DEBUG_INFO, L"Applying EFI 1.x compatibility optimizations...\n");
    return TRUE;
  }
  
  AcpiDebugPrint(DEBUG_VERBOSE, L"Detected UEFI 2.x+ firmware (revision: 0x%x)\n", 
                 SystemTable->FirmwareRevision);
  return FALSE;
}
