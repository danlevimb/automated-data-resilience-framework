# cfg.BackupPaths

## Overview
The `[cfg].[BackupPaths]` table defines the **base storage locations** used by the framework for backup and restore operations. It centralizes path configuration by type, enabling flexible and consistent file management.

## Purpose
This table enables a **configurable storage layer** by:

- Defining base paths for different backup purposes (e.g., PRIMARY, SECONDARY, RESTORE_TEST)  
- Allowing dynamic resolution of file locations during backup and restore processes  
- Supporting environment standardization without hardcoded paths  

It acts as the **abstraction layer for physical storage**, improving portability and maintainability.

## Structure

| Name | Data Type | Description |
|------|----------|-------------|
| PathID | INT | Unique identifier for the path configuration |
| PathType | VARCHAR(30) | Logical type of the path (e.g., PRIMARY, SECONDARY, RESTORE_TEST) |
| BasePath | NVARCHAR(260) | Base directory path used for storing or restoring backup files |
| IsActive | BIT | Indicates whether the path is active and available for use |
| CreatedAt | DATETIME2(7) | Timestamp when the path was registered |

## Data Example

| PathID | PathType | BasePath | IsActive |
|--------|----------|---------------------------|----------|
| 1 | PRIMARY | C:\BD\Backup\PRIMARY\ | 1 |
| 2 | SECONDARY | C:\BD\Backup\SECONDARY\ | 1 |
| 3 | RESTORE_TEST | C:\BD\Backup\RESTORE_TEST\ | 1 |
