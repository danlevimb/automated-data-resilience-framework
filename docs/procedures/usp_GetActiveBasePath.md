# cfg.usp_GetActiveBasePath

> *Storage Layer - Resolution*

## Overview

`cfg.usp_GetActiveBasePath` is responsible for resolving the effective storage path used during backup and restore operations.

It abstracts path selection logic by determining whether the `PRIMARY` / `SECONDARY` / `TEST` storage locations should be used based on execution context and configuration parameters.

This procedure ensures consistent and centralized path resolution across the framework.

## Responsibilities

- Resolve the effective storage path (PRIMARY / SECONDARY / TESTS)  
- Provide deterministic path selection logic  
- Abstract storage decisions from execution procedures  
- Ensure consistency across backup and restore components  

## Parameters

| Parameter | Type | Description |
|----------|------|-------------|
| @PathType | VARCHAR(30) | Indicates the desired path type (`PRIMARY` / `SECONDARY` / `TESTS`). |
| @BasePath | NVARCHAR(260) OUTPUT | Returns the resolved full path |

## Execution Flow

The procedure follows a simple resolution logic:

1. Determine the full path according to requested type and active path.
2. Return the resolved base path  

## Example Usage

```sql
DECLARE @OutputPath NVARCHAR(260);

EXEC cfg.usp_GetActiveBasePath
    @PathType = 'PRIMARY',
    @BasePath = @OutputPath OUTPUT;
```
## Outputs

The procedure returns a single value representing the resolved base path:

## Related Components

- `[cfg].[usp_BackupDatabase]` → Backup execution engine
- `[cfg].[usp_GetRestoreTestBasePath]` → Restore tests directory 

## Design Notes

This procedure represents the storage resolution layer of the framework.

By isolating path selection logic into a dedicated component, the framework achieves better modularity, maintainability, and consistency across backup and restore operations.

## Source Code

[View full implementation](../../sql/cfg/usp_GetActiveBasePath.sql)
