<p align="center">
<a href="/README.md">Home</a> |
<a href="../../sql/01_Tables.md">Tables</a> |
<a href="../../sql/02_Procedures.md">Procedures</a>
</p>

---

# log.RestoreStepExecution

## Overview
The `[log].[RestoreStepExecution]` table stores the step-by-step execution details of each restore test run. It captures the restore chain sequence, backup metadata, recovery boundaries, executed T-SQL, and execution result for every restore step.

## Purpose
This table provides the **detailed execution trace** for restore operations, allowing the framework to:

- Record each step in the restore chain  
- Preserve backup metadata used during execution  
- Track point-in-time and marker-based restore boundaries  
- Store the generated restore command for each step  
- Capture execution timing and step-level errors  

It acts as the **granular evidence layer** for restore chain reconstruction and troubleshooting.

## Structure

| Name | Data Type | Description |
|------|----------|-------------|
| RestoreStepExecutionID | BIGINT | Unique identifier for the restore step execution record |
| RestoreRunID | BIGINT | Identifier of the parent restore test run |
| StepOrder | INT | Sequential order of the step within the restore chain |
| backup_set_id | INT | Identifier of the backup set associated with the step |
| BackupType | VARCHAR(10) | Type of backup applied in the step (e.g., FULL, DIFF, LOG) |
| BackupFileName | NVARCHAR(4000) | Full path of the backup file used in the step |
| FirstLSN | NUMERIC(25,0) | First LSN of the backup set |
| LastLSN | NUMERIC(25,0) | Last LSN of the backup set |
| CheckpointLSN | NUMERIC(25,0) | Checkpoint LSN recorded in the backup set |
| DatabaseBackupLSN | NUMERIC(25,0) | Base database backup LSN used for restore chain alignment |
| StartDate | DATETIME2(3) | Backup start date of the file used in the step |
| FinishDate | DATETIME2(3) | Backup finish date of the file used in the step |
| IsStopAtDate | BIT | Indicates whether the step uses a point-in-time restore boundary |
| StopDate | DATETIME2(3) | Point-in-time value applied to the restore step when applicable |
| MinCommitTime | DATETIME2(3) | Minimum commit time found in the transaction log backup |
| MaxCommitTime | DATETIME2(3) | Maximum commit time found in the transaction log backup |
| IsStopAtMarker | BIT | Indicates whether the step uses a marked transaction boundary |
| Marker | NVARCHAR(128) | Name of the marked transaction used as restore boundary |
| MarkLSN | NUMERIC(25,0) | LSN associated with the marked transaction |
| TSQL | NVARCHAR(MAX) | Restore command generated and executed for the step |
| Executed | BIT | Indicates whether the step was executed |
| ExecStartedAt | DATETIME2(3) | Timestamp when step execution started |
| ExecEndedAt | DATETIME2(3) | Timestamp when step execution ended |
| ExecErrorNum | INT | SQL Server error number captured at step level |
| ExecErrorMsg | NVARCHAR(4000) | Error message captured at step level |

## Data Example

| RestoreStepExecutionID | RestoreRunID | StepOrder | BackupType | BackupFileName | IsStopAtDate | IsStopAtMarker | Executed | ExecErrorNum |
|------------------------|--------------|-----------|------------|----------------|--------------|----------------|----------|--------------|
| 1001 | 201 | 1 | FULL | C:\BD\Backup\PRIMARY\LabCriticalDB_FULL_20260324_120000.bak | 0 | 0 | 1 | NULL |
| 1002 | 201 | 2 | LOG | C:\BD\Backup\PRIMARY\LabCriticalDB_LOG_20260324_120500.trn | 0 | 0 | 1 | NULL |
| 1003 | 201 | 3 | LOG | C:\BD\Backup\PRIMARY\LabCriticalDB_LOG_20260324_121000.trn | 1 | 0 | 1 | NULL |
| 1004 | 202 | 1 | FULL | C:\BD\Backup\PRIMARY\LabCriticalDB_FULL_20260324_120000.bak | 0 | 0 | 1 | NULL |
| 1005 | 202 | 2 | LOG | C:\BD\Backup\PRIMARY\LabCriticalDB_LOG_MARK_20260324_121500_01.trn | 0 | 1 | 1 | NULL |
| 1006 | 204 | 3 | LOG | C:\BD\Backup\PRIMARY\LabCriticalDB_LOG_20260324_143000.trn | 1 | 0 | 0 | 4330 |

--- 

<p align="center">
<a href="/README.md">Home</a> |
<a href="../../sql/01_Tables.md">Tables</a> |
<a href="../../sql/02_Procedures.md">Procedures</a>
</p>
